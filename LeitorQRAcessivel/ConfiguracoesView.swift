import AVFoundation
import SwiftUI

/// Configurações do aplicativo: feedback, voz do app, câmera, privacidade e contato.
struct ConfiguracoesView: View {
    @ObservedObject var vm: LeitorViewModel
    @State private var modo: ModoFeedback = ModoFeedback.atual
    @State private var vozDoApp: Bool = Preferencias.vozDoApp
    @State private var cameraLiberada = AVCaptureDevice.authorizationStatus(for: .video) == .authorized

    private let emailFeedback = "aniclersb@gmail.com"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Configurações do aplicativo")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)

                secao(titulo: "Como o app avisa durante a busca") {
                    Text("Escolha um. Vibração, bips ou os dois.")
                        .font(.callout)
                    Picker("Como o app avisa", selection: $modo) {
                        ForEach(ModoFeedback.allCases) { opcao in
                            Text(opcao.titulo).tag(opcao)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: modo) { novo in
                        ModoFeedback.atual = novo
                    }
                }

                secao(titulo: "Voz do aplicativo") {
                    Toggle("Usar a voz do aplicativo", isOn: $vozDoApp)
                        .onChange(of: vozDoApp) { ligado in
                            Preferencias.vozDoApp = ligado
                        }
                    Text("Deixe esta opção desligada se o VoiceOver estiver ligado. Com o VoiceOver e a voz do app juntos, as duas falam ao mesmo tempo. Para usar a voz do app, desligue o VoiceOver antes de começar.")
                        .font(.callout)
                    if UIAccessibility.isVoiceOverRunning {
                        Text("Atenção: o VoiceOver está ligado agora. Se houver sobreposição de falas entre a voz do aplicativo e o VoiceOver, desligue o leitor enquanto o aplicativo estiver buscando um QR code.")
                            .font(.callout.bold())
                    }
                    Text("Depois de ler o QR code, se quiser ouvir a tela com o leitor de tela, ligue o VoiceOver manualmente em Ajustes > Acessibilidade. O aplicativo não liga o leitor sozinho.")
                        .font(.callout)
                }

                secao(titulo: "Permissões") {
                    Text(cameraLiberada ? "Câmera: permitida" : "Câmera: não permitida")
                        .font(.body.bold())
                    if !cameraLiberada {
                        Button("Permitir câmera") {
                            AVCaptureDevice.requestAccess(for: .video) { _ in
                                Task { @MainActor in
                                    cameraLiberada = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
                                    vm.verificarPermissao()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Abrir configurações do aplicativo para liberar") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                secao(titulo: "Privacidade e contato") {
                    NavigationLink {
                        PoliticaView()
                    } label: {
                        Label("Política de privacidade e termos de uso", systemImage: "shield")
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        enviarFeedback()
                    } label: {
                        Label("Enviar feedback por e-mail", systemImage: "envelope")
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Configurações")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cameraLiberada = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        }
    }

    private func secao<Conteudo: View>(titulo: String, @ViewBuilder conteudo: () -> Conteudo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            conteudo()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemGroupedBackground)))
    }

    /// Abre o e-mail com o endereço já preenchido. O endereço não aparece na tela.
    private func enviarFeedback() {
        let assunto = "Feedback - Leitor QR Acessível"
        let codificado = assunto.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(emailFeedback)?subject=\(codificado)") else { return }
        UIApplication.shared.open(url)
    }
}
