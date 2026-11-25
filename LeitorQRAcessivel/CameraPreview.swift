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
