import SwiftUI

/// Política de privacidade e termos de uso, lidos na própria tela (funciona sem internet).
struct PoliticaView: View {
    private let privacidade = [
        "O Leitor QR Acessível não coleta, não guarda em servidores e não envia dados pessoais. Não pedimos cadastro, nome, e-mail nem senha.",
        "Câmera: a câmera traseira é usada só para achar o QR code na tela, em tempo real, e guiar você por voz e bips. Nenhuma foto ou vídeo é gravado ou enviado.",
        "Leitura do QR code: é feita no próprio aparelho, com o recurso de leitura da Apple (Vision), que funciona sem internet.",
        "Configurações: suas escolhas, como vibração, bips e voz do aplicativo, ficam salvas somente neste aparelho.",
        "Conteúdo do QR code: o app mostra, copia e compartilha o conteúdo somente quando você pedir. Ao abrir um link, ele é aberto no navegador ou no aplicativo que você escolher, e nesse aplicativo valem as regras dele.",
        "Feedback: o e-mail só é enviado se você tocar no botão de feedback, e ele é aberto no seu aplicativo de e-mail.",
        "Seus dados: para apagar o que ficou salvo, desinstale o aplicativo."
    ]

    private let termos = [
        "1. Finalidade: o aplicativo ajuda pessoas com deficiência visual a encontrar e ler QR codes. Ele não substitui a atenção à segurança.",
        "2. Segurança: confira antes de abrir links, pagar algo, conectar em Wi-Fi ou salvar contatos. O app não garante que o conteúdo de um QR code seja seguro.",
        "3. Responsabilidade: o aplicativo é oferecido como está. Não nos responsabilizamos por danos causados pelo conteúdo de QR codes, por sites ou aplicativos de terceiros, nem por falhas de leitura.",
        "4. Sem vínculo: o aplicativo não tem ligação com as empresas ou serviços cujos QR codes ele lê.",
        "5. Alterações: estes termos podem ser atualizados. Vale sempre a versão que está no aplicativo.",
        "6. Contato: dúvidas e sugestões pelo botão Enviar feedback por e-mail, em Configurações do aplicativo."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacidade e termos")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Última atualização: 25/11/2026")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Text("Política de privacidade")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                ForEach(privacidade, id: \.self) { paragrafo in
                    Text(paragrafo)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Termos de uso")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 12)
                ForEach(termos, id: \.self) { item in
                    Text(item)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Privacidade e termos")
        .navigationBarTitleDisplayMode(.inline)
    }
}
