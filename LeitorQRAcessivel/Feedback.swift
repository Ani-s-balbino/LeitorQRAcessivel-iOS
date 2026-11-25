import AVFoundation
import AudioToolbox
import UIKit

/// Vibração, bips e voz do aplicativo. A voz só fala se a pessoa tiver ligado a opção.
@MainActor
final class Feedback {
    private let impacto = UIImpactFeedbackGenerator(style: .light)
    private let notificacao = UINotificationFeedbackGenerator()
    private let sintetizador = AVSpeechSynthesizer()

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    /// Um sinal da busca: pulso de vibração e/ou bip, conforme a configuração.
    func pulsoDeBusca() {
        if Preferencias.vibracao { impacto.impactOccurred(intensity: 0.6) }
        if Preferencias.bips { AudioServicesPlaySystemSound(1104) }
    }

    /// Confirmação forte, quando o QR code é lido.
    func confirmacao() {
        if Preferencias.vibracao { notificacao.notificationOccurred(.success) }
        if Preferencias.bips { AudioServicesPlaySystemSound(1057) }
    }

    func falar(_ texto: String) {
        guard Preferencias.vozDoApp else { return }
        sintetizador.stopSpeaking(at: .immediate)
        let fala = AVSpeechUtterance(string: texto)
        fala.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        sintetizador.speak(fala)
    }

    func pararFala() {
        sintetizador.stopSpeaking(at: .immediate)
    }
}
