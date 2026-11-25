import AVFoundation
import SwiftUI

/// Prévia da câmera. Só ilustra a tela: o VoiceOver não lê a imagem.
struct CameraPreview: UIViewRepresentable {
    let sessao: AVCaptureSession

    func makeUIView(context: Context) -> VisualizacaoCamera {
        let vista = VisualizacaoCamera()
        vista.camada.session = sessao
        vista.camada.videoGravity = .resizeAspectFill
        return vista
    }

    func updateUIView(_ vista: VisualizacaoCamera, context: Context) {
        vista.camada.session = sessao
    }
}

final class VisualizacaoCamera: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var camada: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }
}
