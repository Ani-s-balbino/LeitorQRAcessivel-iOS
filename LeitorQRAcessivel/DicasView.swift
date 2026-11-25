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
import SwiftUI

/// Dicas para encontrar e ler melhor um QR code. Cada dica é um elemento separado para o VoiceOver.
struct DicasView: View {
    private struct Secao: Identifiable {
        let titulo: String
        let dicas: [String]
        var id: String { titulo }
    }

    private let secoes: [Secao] = [
        Secao(titulo: "Em papel ou documento", dicas: [
            "Use o papel em modo paisagem. Modo paisagem é quando a folha fica deitada, mais larga do que alta, como uma tela de cinema. Se o QR code estiver numa folha em pé, gire a folha.",
            "Deixe a folha lisa, sem dobras, e evite sombras sobre o QR code. Um papel bem esticado sobre a mesa facilita.",
            "Segure o celular a cerca de 30 centímetros da folha. Se não achar o QR code, mova o celular devagar para os lados e depois para cima e para baixo."
        ]),
        Secao(titulo: "Na tela de computador ou de outro celular", dicas: [
            "Posicione o celular na altura da linha da barra de espaço do teclado, apontado para a tela, para ficar na mesma altura do QR code.",
            "Afaste o celular cerca de 30 centímetros da tela. Não precisa encostar.",
            "Não mude o zoom da tela enquanto escaneia. Mudar o zoom pode deixar o QR code ilegível.",
            "Não precisa deixar o celular paralelo à tela. A leitura funciona com uma leve inclinação, e o app avisa se estiver torto demais."
        ]),
        Secao(titulo: "Distância e movimento", dicas: [
            "A distância ideal é de cerca de 30 centímetros, uma distância de braço esticado. O app avisa se estiver perto ou longe demais.",
            "Mova o celular devagar, em varredura: primeiro para os lados, depois para cima e para baixo. Movimentos rápidos atrapalham a leitura.",
            "Se o QR code estiver muito longe, aproxime o celular aos poucos. Quando estiver bem enquadrado, o app pede para segurar parado."
        ]),
        Secao(titulo: "Luz e reflexo", dicas: [
            "Evite luz direta sobre a tela ou sobre o papel, porque ela causa reflexo. Um ambiente com luz suave funciona melhor.",
            "Aumente o brilho da tela que mostra o QR code. Use a lanterna do app só se o ambiente estiver escuro, porque ela pode causar reflexo em papel brilhante."
        ]),
        Secao(titulo: "Se o QR code não ler", dicas: [
            "O app avisa quando acha um QR code que não consegue ler. Ele pode estar borrado, cortado ou danificado. Tente aproximar ou afastar um pouco e deixe o celular parado por um instante.",
            "Se continuar sem ler, peça para gerar outro QR code ou tente com outro celular."
        ]),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Dicas para captura de QR code")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)

                ForEach(secoes) { secao in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(secao.titulo)
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                        ForEach(secao.dicas, id: \.self) { dica in
                            Text(dica)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemGroupedBackground)))
                }

                Text("Dicas baseadas em guias de acessibilidade, como o da Mississippi State University e o do Axess Lab, e em relatos de pessoas que usam leitores de tela. Se algo não funcionar no seu aparelho, use o botão de feedback em Configurações do aplicativo.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dicas")
        .navigationBarTitleDisplayMode(.inline)
    }
}
