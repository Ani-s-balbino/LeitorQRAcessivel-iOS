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
import CoreGraphics
import Foundation

/// Resultado de uma avaliação: o que falar e o quão bem enquadrado está o QR code.
struct Orientacao {
    let fala: String
    /// 0 = muito errado, 1 = ajuste médio, 2 = ajuste fino, 3 = perfeito
    let nivel: Int
}

/// Regras de orientação, iguais às do Android: distância, centro e inclinação.
enum AvaliadorQR {
    static let tolerancia: CGFloat = 0.15
    static let muitoLonge: CGFloat = 0.18
    static let umPoucoLonge: CGFloat = 0.30
    static let umPoucoPerto: CGFloat = 0.70
    static let muitoPerto: CGFloat = 0.80
    static let limiteInclinacao: CGFloat = 0.18

    /// - tamanho: lado maior do QR / lado menor do quadro.
    /// - dx, dy: centro do QR em relação ao centro do quadro (-0.5 a 0.5). dy negativo = QR acima do centro.
    static func avaliar(tamanho: CGFloat, dx: CGFloat, dy: CGFloat, inclinacao: CGFloat) -> Orientacao {
        if tamanho > muitoPerto {
            return Orientacao(fala: "QR code muito perto. Afaste o celular.", nivel: 0)
        }

        var direcoes: [String] = []
        if dx < -tolerancia { direcoes.append("a esquerda") }
        if dx > tolerancia { direcoes.append("a direita") }
        if dy < -tolerancia { direcoes.append("cima") }
        if dy > tolerancia { direcoes.append("baixo") }
        if !direcoes.isEmpty {
            let muitoFora = abs(dx) > 0.30 || abs(dy) > 0.30
            return Orientacao(
                fala: "QR code encontrado, fora do centro. Mova o celular para " + direcoes.joined(separator: " e para "),
                nivel: muitoFora ? 0 : 1
            )
        }

        if tamanho < muitoLonge {
            return Orientacao(fala: "QR code muito longe. Aproxime o celular.", nivel: 0)
        }
        if tamanho < umPoucoLonge {
            return Orientacao(fala: "Um pouco longe. Aproxime mais um pouco.", nivel: 1)
        }
        if tamanho > umPoucoPerto {
            return Orientacao(fala: "Um pouco perto. Afaste um pouco.", nivel: 1)
        }

        if inclinacao > limiteInclinacao {
            return Orientacao(fala: "Celular inclinado. Deixe o celular paralelo à tela.", nivel: 2)
        }

        return Orientacao(fala: "QR code bem enquadrado. Segure parado.", nivel: 3)
    }

    /// Inclinação pela perspectiva: lados opostos com tamanhos diferentes indicam celular torto. 0 = de frente.
    static func inclinacao(topo: CGFloat, base: CGFloat, esquerda: CGFloat, direita: CGFloat) -> CGFloat {
        let horizontal = abs(topo - base) / max(max(topo, base), 0.0001)
        let vertical = abs(esquerda - direita) / max(max(esquerda, direita), 0.0001)
        return max(horizontal, vertical)
    }
}
