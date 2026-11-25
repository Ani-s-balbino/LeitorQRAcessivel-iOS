import AVFoundation
import Vision

/// Resultado de um quadro analisado pela câmera.
struct DeteccaoQR {
    /// Conteúdo lido, se o QR code foi decodificado.
    let conteudo: String?
    /// Retângulo normalizado (0 a 1), origem no canto inferior esquerdo, como o Vision devolve.
    let caixa: CGRect
    /// Cantos normalizados: topo esquerdo, topo direito, base direita, base esquerda.
    let cantos: [CGPoint]
}

/// Câmera traseira + Vision: procura QR codes em cada quadro.
final class Escaneador: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let sessao = AVCaptureSession()
    private let saidaVideo = AVCaptureVideoDataOutput()
    private let filaVideo = DispatchQueue(label: "br.com.leitorqr.video")
    private var ultimoQuadro = Date.distantPast
    private var lanterna: AVCaptureDevice?

    /// Pausado = não processa quadros (a pessoa parou a busca ou saiu da tela).
    private var pausado = false
    private let trava = NSLock()

    /// Chamado na thread principal: detecção (ou nil) e luminância média de 0 a 255.
    var aoAnalisar: ((DeteccaoQR?, Int) -> Void)?

    var temLanterna: Bool { lanterna?.hasTorch ?? false }
    var lanternaLigada: Bool { lanterna?.torchMode == .on }

    func configurar() -> Bool {
        sessao.beginConfiguration()
        sessao.sessionPreset = .high
        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let entrada = try? AVCaptureDeviceInput(device: camera),
            sessao.canAddInput(entrada)
        else {
            sessao.commitConfiguration()
            return false
        }
        sessao.addInput(entrada)
        lanterna = camera

        saidaVideo.alwaysDiscardsLateVideoFrames = true
        saidaVideo.setSampleBufferDelegate(self, queue: filaVideo)
        guard sessao.canAddOutput(saidaVideo) else {
            sessao.commitConfiguration()
            return false
        }
        sessao.addOutput(saidaVideo)
        if let conexao = saidaVideo.connection(with: .video), conexao.isVideoOrientationSupported {
            conexao.videoOrientation = .portrait
        }
        sessao.commitConfiguration()
        return true
    }

    func iniciar() {
        filaVideo.async { [sessao] in
            if !sessao.isRunning { sessao.startRunning() }
        }
    }

    func parar() {
        filaVideo.async { [sessao] in
            if sessao.isRunning { sessao.stopRunning() }
        }
    }

    func definirPausado(_ valor: Bool) {
        trava.lock()
        pausado = valor
        trava.unlock()
    }

    private var estaPausado: Bool {
        trava.lock()
        defer { trava.unlock() }
        return pausado
    }

    func definirLanterna(_ ligada: Bool) {
        guard let dispositivo = lanterna, dispositivo.hasTorch else { return }
        try? dispositivo.lockForConfiguration()
        dispositivo.torchMode = ligada ? .on : .off
        dispositivo.unlockForConfiguration()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Analisa cerca de 6 quadros por segundo: o suficiente para orientar, sem gastar bateria.
        let agora = Date()
        guard !estaPausado, agora.timeIntervalSince(ultimoQuadro) > 0.16 else { return }
        ultimoQuadro = agora

        guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let luz = luminanciaMedia(pixels)

        let pedido = VNDetectBarcodesRequest { [weak self] requisicao, _ in
            let observacoes = (requisicao.results as? [VNBarcodeObservation]) ?? []
            let qr = observacoes.first { $0.boundingBox.width > 0 }
            let deteccao = qr.map { observacao in
                DeteccaoQR(
                    conteudo: observacao.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                    caixa: observacao.boundingBox,
                    cantos: [observacao.topLeft, observacao.topRight, observacao.bottomRight, observacao.bottomLeft]
                )
            }
            DispatchQueue.main.async {
                self?.aoAnalisar?(deteccao, luz)
            }
        }
        pedido.symbologies = [.qr]

        // Quadros do sensor vêm deitados: .right deixa as coordenadas no sentido do celular em pé.
        let manipulador = VNImageRequestHandler(cvPixelBuffer: pixels, orientation: .right, options: [:])
        try? manipulador.perform([pedido])
    }

    /// Brilho médio amostrado do canal de luminância (0 a 255).
    private func luminanciaMedia(_ buffer: CVPixelBuffer) -> Int {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard CVPixelBufferIsPlanar(buffer), let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else {
            return 255
        }
        let largura = CVPixelBufferGetWidthOfPlane(buffer, 0)
        let altura = CVPixelBufferGetHeightOfPlane(buffer, 0)
        let bytesPorLinha = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        let ponteiro = base.assumingMemoryBound(to: UInt8.self)

        var soma = 0
        var amostras = 0
        var y = 0
        while y < altura {
            var x = 0
            while x < largura {
                soma += Int(ponteiro[y * bytesPorLinha + x])
                amostras += 1
                x += 16
            }
            y += 16
        }
        return amostras == 0 ? 255 : soma / amostras
    }
}
