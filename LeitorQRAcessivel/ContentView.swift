/*
 * Copyright (C) 2026 Ani-s-balbino
 *
 * Este arquivo é parte do Leitor QR Acessível.
 *
 * Leitor QR Acessível é software livre: você pode redistribuí-lo e/ou modificá-lo
 * sob os termos da GNU General Public License versão 3, publicada pela
 * Free Software Foundation. Este programa é distribuído na esperança de que seja
 * útil, mas SEM NENHUMA GARANTIA. Veja o arquivo LICENSE para mais detalhes.
 */
import AVFoundation
import SwiftUI

/// Tela principal. A ordem de foco do VoiceOver segue a ordem dos elementos, de cima para baixo.
struct ContentView: View {
    @StateObject private var vm = LeitorViewModel()
    @Environment(\.scenePhase) private var fase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    cabecalho

                    if !vm.permissaoConcedida {
                        Text("Precisamos da câmera para achar o QR code. Toque no botão Permitir uso da câmera e, na janela do sistema, escolha Permitir durante o uso do app.")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("O aplicativo usa a câmera traseira só para procurar o QR code na tela e guiar você por voz e bips. Nenhuma foto ou vídeo é gravado ou enviado.")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        botaoPermissao
                    }

                    cartaoStatus

                    if let resultado = vm.resultado {
                        cartaoResultado(resultado)
                    }

                    if vm.permissaoConcedida {
                        controlesDaBusca
                    }

                    botoesAcao

                    CameraPreview(sessao: vm.escaneador.sessao)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.accentColor, lineWidth: 3))
                        .accessibilityHidden(true)
                        .opacity(vm.permissaoConcedida && vm.resultado == nil ? 1 : 0)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear { vm.verificarPermissao() }
        .onChange(of: fase) { novaFase in
            if novaFase != .active {
                vm.pausarBusca(avisar: false)
            }
        }
    }

    // MARK: - Partes da tela

    private var cabecalho: some View {
        HStack(spacing: 12) {
            Image(systemName: "qrcode.viewfinder")
                .font(.title)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
                .foregroundColor(.accentColor)
                .accessibilityHidden(true)
            Text("Leitor QR Acessível")
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var botaoPermissao: some View {
        Button {
            if vm.permissaoBloqueada {
                abrirConfiguracoes()
            } else {
                vm.pedirPermissao()
            }
        } label: {
            Label(
                vm.permissaoBloqueada ? "Abrir configurações do aplicativo" : "Permitir uso da câmera",
                systemImage: vm.permissaoBloqueada ? "gearshape" : "camera"
            )
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
    }

    private var cartaoStatus: some View {
        Text(vm.textoStatus)
            .font(.title3.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.accentColor.opacity(0.12)))
    }

    private func cartaoResultado(_ resultado: LeitorViewModel.Resultado) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resultado.tipo)
                .font(.headline)
                .foregroundColor(.accentColor)
            Text(resultado.conteudo)
                .font(.body)
                .lineLimit(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.accentColor, lineWidth: 2))
    }

    private var controlesDaBusca: some View {
        VStack(spacing: 10) {
            if vm.resultado == nil {
                Button {
                    vm.alternarLanterna()
                } label: {
                    Label(vm.lanternaLigada ? "Lanterna: ligada" : "Lanterna: desligada", systemImage: "flashlight.on.fill")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .disabled(!vm.temLanterna)

                Button {
                    vm.alternarBusca()
                } label: {
                    Label(
                        vm.buscaPausada ? "Retomar busca" : "Parar busca",
                        systemImage: vm.buscaPausada ? "play.fill" : "pause.fill"
                    )
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var botoesAcao: some View {
        VStack(spacing: 10) {
            if let resultado = vm.resultado {
                if let link = resultado.link {
                    Button {
                        UIApplication.shared.open(link)
                    } label: {
                        Label("Abrir QR code: \(resultado.tipo)", systemImage: "safari")
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                }
                ShareLink(item: resultado.conteudo) {
                    Label("Compartilhar QR code", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)

                Button {
                    UIPasteboard.general.string = resultado.conteudo
                    vm.anunciar("Conteúdo copiado.", urgente: true)
                } label: {
                    Label("Copiar conteúdo", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)

                Button {
                    vm.feedback.falar("Conteúdo: \(resultado.conteudo.prefix(300))")
                } label: {
                    Label("Ouvir novamente", systemImage: "speaker.wave.2")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)

                Button {
                    vm.escanearOutro()
                } label: {
                    Label("Escanear outro QR code", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
            }

            NavigationLink {
                DicasView()
            } label: {
                Label("Dicas para captura de QR code", systemImage: "lightbulb")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.bordered)

            NavigationLink {
                ConfiguracoesView(vm: vm)
            } label: {
                Label("Configurações do aplicativo", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.bordered)
        }
    }

    private func abrirConfiguracoes() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
