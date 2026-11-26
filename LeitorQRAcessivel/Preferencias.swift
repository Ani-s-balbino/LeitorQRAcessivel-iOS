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
import Foundation

/// Preferências do usuário, guardadas só neste aparelho (UserDefaults).
enum Preferencias {
    private static let chaveVibracao = "feedback_vibracao"
    private static let chaveBips = "feedback_bips"
    private static let chaveVozDoApp = "voz_do_aplicativo"

    /// Vibração durante a busca e ao ler o QR code. Padrão: ligada.
    static var vibracao: Bool {
        get { UserDefaults.standard.object(forKey: chaveVibracao) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: chaveVibracao) }
    }

    /// Bips durante a busca e ao ler o QR code. Padrão: ligados.
    static var bips: Bool {
        get { UserDefaults.standard.object(forKey: chaveBips) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: chaveBips) }
    }

    /// Voz do aplicativo. Padrão: desligada, porque o VoiceOver já lê a tela e as duas vozes se atrapalham.
    static var vozDoApp: Bool {
        get { UserDefaults.standard.bool(forKey: chaveVozDoApp) }
        set { UserDefaults.standard.set(newValue, forKey: chaveVozDoApp) }
    }
}

/// Como o app avisa durante a busca. Os três modos são as opções da tela de configurações.
enum ModoFeedback: String, CaseIterable, Identifiable {
    case nenhum, vibracao, bips, ambos

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .nenhum: return "Nenhum (sem bips e sem vibração)"
        case .vibracao: return "Vibração"
        case .bips: return "Bips"
        case .ambos: return "Vibração e bips"
        }
    }

    static var atual: ModoFeedback {
        get {
            switch (Preferencias.vibracao, Preferencias.bips) {
            case (true, true): return .ambos
            case (true, false): return .vibracao
            case (false, true): return .bips
            default: return .nenhum
            }
        }
        set {
            switch newValue {
            case .nenhum: Preferencias.vibracao = false; Preferencias.bips = false
            case .vibracao: Preferencias.vibracao = true; Preferencias.bips = false
            case .bips: Preferencias.vibracao = false; Preferencias.bips = true
            case .ambos: Preferencias.vibracao = true; Preferencias.bips = true
            }
        }
    }
}
