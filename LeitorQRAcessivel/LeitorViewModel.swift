import AVFoundation
import Combine
import SwiftUI
import UIKit

/// Coração do app: liga a câmera, interpreta o QR code, avisa por voz/bips/vibração e controla parar/retomar.
@MainActor
final class LeitorViewModel: ObservableObject {
    // Tempos (em segundos), iguais aos do Android
    private let pausaEntreAvisos: TimeInterval = 1.5
    private let repetirAviso: TimeInterval = 5
    private let tempoEnquadrado: TimeInterval = 0.6
    private let tempoLimiteEnquadrar: TimeInterval = 8
    private let luzMinima = 45

    @Published var permissaoConcedida = false
    @Published var permissaoBloqueada = false
    @Published var textoStatus = ""
    @Published var buscaPausada = false
    @Published var leituraConcluida = false
    @Published var resultado: Resultado?
    @Published var lanternaLigada = false
    @Published var temLanterna = false

    struct Resultado {
        let tipo: String
        let conteudo: String
        let link: URL?
        let fala: String
    }

    let escaneador = Escaneador()
    let feedback = Feedback()

    private var configurado = false
    private var timerBip: Timer?
    private var intervaloBip: TimeInterval = 1.5
    private var inicioDeteccao: Date?
    private var inicioEnquadrado: Date?
    private var inicioEscuro: Date?
    private var ultimaDeteccao = Date.distantPast

    // Fila de avisos: um por vez, com pausa, para o leitor de tela não se atropelar
    private var pendente: String?
    private var pendenteUrgente = false
    private var ultimaMensagem = ""
    private var ultimaMensagemTempo = Date.distantPast
    private var timerFila: Timer?

    // MARK: - Permissão e câmera

    func verificarPermissao() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissaoConcedida = true
            permissaoBloqueada = false
            iniciarCamera()
        case .notDetermined:
            permissaoConcedida = false
            permissaoBloqueada = false
            textoStatus = "Permissão da câmera necessária para começar."
        default:
            permissaoConcedida = false
            permissaoBloqueada = true
            textoStatus = "Câmera bloqueada. Toque em Abrir configurações do aplicativo para liberar."
        }
    }

    func pedirPermissao() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] concedida in
            Task { @MainActor in
                guard let self else { return }
                if concedida {
                    self.verificarPermissao()
                } else {
                    self.verificarPermissao()
                    self.anunciar("Câmera não liberada. Você pode liberar nas configurações do iPhone.", urgente: true)
                }
            }
        }
    }

    private func iniciarCamera() {
        if !configurado {
            configurado = escaneador.configurar()
            escaneador.aoAnalisar = { [weak self] deteccao, luz in
                self?.processar(deteccao, luz: luz)
            }
        }
        guard configurado else {
            anunciar("Não consegui abrir a câmera neste aparelho.", urgente: true)
            return
        }
        temLanterna = escaneador.temLanterna
        escaneador.iniciar()
        escaneador.definirPausado(false)
        buscaPausada = false
        iniciarBusca()
        anunciar("Procurando QR code. Mova o celular lentamente.", urgente: true)
    }

    // MARK: - Parar e retomar

    func pausarBusca(avisar: Bool) {
        buscaPausada = true
        escaneador.definirPausado(true)
        timerBip?.invalidate()
        timerBip = nil
        feedback.pararFala()
        if avisar { anunciar("Busca parada. Toque em Retomar busca quando quiser continuar.", urgente: true) }
    }

    func retomarBusca() {
        guard !leituraConcluida else { return }
        buscaPausada = false
        escaneador.definirPausado(false)
        iniciarBusca()
        anunciar("Busca retomada. Procurando QR code.", urgente: true)
    }

    func alternarBusca() {
        if buscaPausada { retomarBusca() } else { pausarBusca(avisar: true) }
    }

    func alternarLanterna() {
        guard temLanterna else {
            anunciar("Este aparelho não tem lanterna disponível.", urgente: true)
            return
        }
        lanternaLigada.toggle()
        escaneador.definirLanterna(lanternaLigada)
        anunciar(lanternaLigada ? "Lanterna ligada" : "Lanterna desligada", urgente: true)
    }

    private func iniciarBusca() {
        guard !leituraConcluida, !buscaPausada, permissaoConcedida else { return }
        timerBip?.invalidate()
        timerBip = Timer.scheduledTimer(withTimeInterval: intervaloBip, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tocarSinalDeBusca() }
        }
    }

    private func tocarSinalDeBusca() {
        guard !buscaPausada, !leituraConcluida else { return }
        feedback.pulsoDeBusca()
    }

    private func trocarIntervaloBip(_ novo: TimeInterval) {
        guard abs(novo - intervaloBip) > 0.01 else { return }
        intervaloBip = novo
        iniciarBusca()
    }

    // MARK: - Interpretação dos quadros

    private func processar(_ deteccao: DeteccaoQR?, luz: Int) {
        guard !leituraConcluida, !buscaPausada else { return }
        let agora = Date()

        guard let deteccao else {
            // Sem QR code neste quadro. Tolerância curta, para um quadro ruim não zerar a orientação.
            if agora.timeIntervalSince(ultimaDeteccao) < 1 { return }
            zerarEnquadramento()
            if luz < luzMinima {
                if inicioEscuro == nil { inicioEscuro = agora }
                if let escuro = inicioEscuro, agora.timeIntervalSince(escuro) > 2.5, !lanternaLigada {
                    trocarIntervaloBip(1.5)
                    anunciar("Ambiente escuro. Ligue a lanterna no botão Lanterna.")
                    return
                }
            } else {
                inicioEscuro = nil
            }
            trocarIntervaloBip(1.5)
            let dicas = [
                "Procurando QR code. Mova o celular lentamente.",
                "Nenhum QR code encontrado. Afaste o celular da tela, cerca de trinta centímetros.",
                "Ainda procurando. Aumente o brilho da tela e evite reflexos."
            ]
            let indice = Int(agora.timeIntervalSince1970 / 6) % dicas.count
            anunciar(dicas[indice])
            return
        }

        ultimaDeteccao = agora
        if inicioDeteccao == nil { inicioDeteccao = agora }
        inicioEscuro = nil

        // Achou um QR code, mas não conseguiu ler: geralmente borrado, cortado ou danificado.
        guard let conteudo = deteccao.conteudo, !conteudo.isEmpty else {
            anunciar("Achei um QR code, mas não consegui ler. Ele pode estar borrado, cortado ou danificado. Tente aproximar ou afastar o celular e deixe-o parado por um instante.")
            return
        }

        let caixa = deteccao.caixa
        let tamanho = max(caixa.width, caixa.height)
        let centroX = caixa.midX - 0.5
        // Vision tem a origem embaixo: convertendo para "de cima para baixo", negativo = acima do centro.
        let centroY = (1 - caixa.midY) - 0.5
        let c = deteccao.cantos
        let inclinacao = c.count == 4
            ? AvaliadorQR.inclinacao(
                topo: distancia(c[0], c[1]),
                base: distancia(c[3], c[2]),
                esquerda: distancia(c[3], c[0]),
                direita: distancia(c[2], c[1])
            )
            : 0

        let orientacao = AvaliadorQR.avaliar(
            tamanho: tamanho,
            dx: centroX,
            dy: centroY,
            inclinacao: inclinacao
        )

        switch orientacao.nivel {
        case 0: trocarIntervaloBip(1.0)
        case 1: trocarIntervaloBip(0.5)
        case 2: trocarIntervaloBip(0.25)
        default: trocarIntervaloBip(0.12)
        }
        anunciar(orientacao.fala)

        if orientacao.nivel == 3 {
            if inicioEnquadrado == nil { inicioEnquadrado = agora }
            if let inicio = inicioEnquadrado, agora.timeIntervalSince(inicio) >= tempoEnquadrado {
                concluir(conteudo: conteudo)
            }
        } else {
            inicioEnquadrado = nil
            if let inicio = inicioDeteccao, agora.timeIntervalSince(inicio) > tempoLimiteEnquadrar {
                concluir(conteudo: conteudo)
            }
        }
    }

    private func zerarEnquadramento() {
        inicioDeteccao = nil
        inicioEnquadrado = nil
    }

    private func distancia(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func concluir(conteudo: String) {
        leituraConcluida = true
        timerBip?.invalidate()
        timerBip = nil
        if lanternaLigada {
            escaneador.definirLanterna(false)
            lanternaLigada = false
        }
        feedback.confirmacao()

        let acao = classificar(conteudo)
        resultado = acao
        let conteudoFalado = acao.tipo == "Rede Wi-Fi" ? "" : " Conteúdo: \(conteudo.prefix(300))"
        anunciar("QR code lido. \(acao.fala)\(conteudoFalado)", urgente: true)
    }

    /// Recomeça a busca depois de uma leitura.
    func escanearOutro() {
        leituraConcluida = false
        resultado = nil
        inicioDeteccao = nil
        inicioEnquadrado = nil
        inicioEscuro = nil
        escaneador.definirPausado(false)
        buscaPausada = false
        iniciarBusca()
        anunciar("Procurando QR code. Mova o celular lentamente.", urgente: true)
    }

    /// Diz o que o QR code é, sem abrir nada. Endereços bloqueados não são abertos.
    private func classificar(_ conteudo: String) -> Resultado {
        let texto = conteudo.trimmingCharacters(in: .whitespacesAndNewlines)
        let minusculo = texto.lowercased()

        if minusculo.hasPrefix("http://") || minusculo.hasPrefix("https://") {
            let url = URL(string: texto)
            let site = url?.host?.replacingOccurrences(of: "www.", with: "") ?? ""
            let aviso = minusculo.hasPrefix("http://") ? " Atenção: este endereço não usa conexão segura." : ""
            return Resultado(
                tipo: "Link da internet" + (site.isEmpty ? "" : " · \(site)"),
                conteudo: texto,
                link: url,
                fala: "É um link." + (site.isEmpty ? "" : " Site: \(site).") + aviso
            )
        }
        if minusculo.hasPrefix("tel:") {
            let numero = String(texto.dropFirst(4))
            return Resultado(tipo: "Telefone", conteudo: numero, link: URL(string: texto), fala: "É um número de telefone: \(numero).")
        }
        if minusculo.hasPrefix("mailto:") {
            let endereco = String(texto.dropFirst(7))
            return Resultado(tipo: "E-mail", conteudo: endereco, link: URL(string: texto), fala: "É um e-mail para \(endereco).")
        }
        if minusculo.hasPrefix("wifi:") {
            return Resultado(
                tipo: "Rede Wi-Fi",
                conteudo: "Dados de Wi-Fi. O iPhone não abre este tipo de QR code: você pode copiar o conteúdo.",
                link: nil,
                fala: "É uma rede Wi-Fi. O iPhone não abre este tipo de QR code. Você pode copiar o conteúdo."
            )
        }
        return Resultado(tipo: "Texto", conteudo: texto, link: nil, fala: "É um texto. Não há o que abrir; você pode copiar ou compartilhar.")
    }

    // MARK: - Fila de avisos

    /// Único caminho para o que o app diz: texto na tela, leitura do VoiceOver e voz do app, com pausa entre avisos.
    func anunciar(_ texto: String, urgente: Bool = false) {
        let agora = Date()
        if !urgente, texto == ultimaMensagem, agora.timeIntervalSince(ultimaMensagemTempo) < repetirAviso { return }
        if !urgente, pendenteUrgente { return }
        pendente = texto
        pendenteUrgente = urgente
        if timerFila?.isValid == true { return }
        let espera = max(0, pausaEntreAvisos - agora.timeIntervalSince(ultimaMensagemTempo))
        timerFila = Timer.scheduledTimer(withTimeInterval: espera, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.mostrarProximo() }
        }
    }

    private func mostrarProximo() {
        guard let texto = pendente else { return }
        pendente = nil
        pendenteUrgente = false
        ultimaMensagem = texto
        ultimaMensagemTempo = Date()
        textoStatus = texto
        // O VoiceOver lê o aviso sem tirar o foco de quem está navegando.
        UIAccessibility.post(notification: .announcement, argument: texto)
        feedback.falar(texto)
    }
}
