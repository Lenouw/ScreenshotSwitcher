import Foundation

// Enum representant les deux modes de capture d'ecran
enum ScreenshotMode: String, CaseIterable {
    case retina
    case vibe

    // Label affiche dans le menu
    var label: String {
        switch self {
        case .retina: return "Retina (PNG)"
        case .vibe: return "Vibe (JPG \u{2264}1700px)"
        }
    }

    // Emoji affiche dans la menu bar
    var icon: String {
        switch self {
        case .retina: return "📷"
        case .vibe: return "⚡"
        }
    }

    // Type de fichier pour screencapture
    var screencaptureType: String {
        switch self {
        case .retina: return "png"
        case .vibe: return "jpg"
        }
    }

    // Mode oppose
    var opposite: ScreenshotMode {
        switch self {
        case .retina: return .vibe
        case .vibe: return .retina
        }
    }

    // Message de notification apres le switch
    var notificationMessage: String {
        switch self {
        case .retina: return "Screenshots en mode Retina (PNG)"
        case .vibe: return "Screenshots en mode Vibe (JPG \u{2264}1700px)"
        }
    }

    // Applique le mode en modifiant les defaults systeme
    func apply() {
        // Ecrire le type de capture
        run("/usr/bin/defaults", arguments: ["write", "com.apple.screencapture", "type", screencaptureType])

        switch self {
        case .retina:
            // Supprimer la compression si elle existait
            run("/usr/bin/defaults", arguments: ["delete", "com.apple.screencapture", "compression"])
        case .vibe:
            // Qualite JPG maximale (pas de compression)
            run("/usr/bin/defaults", arguments: ["write", "com.apple.screencapture", "compression", "-float", "1.0"])
        }

        // Redemarrer SystemUIServer pour appliquer les changements
        run("/usr/bin/killall", arguments: ["SystemUIServer"])
    }

    // Detecte le mode actuel en lisant les defaults systeme
    static func current() -> ScreenshotMode {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "com.apple.screencapture", "type"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if output == "jpg" || output == "jpeg" {
                return .vibe
            }
        } catch {
            // En cas d'erreur, on considere le mode par defaut (png)
        }
        return .retina
    }

    // Execute une commande systeme
    @discardableResult
    private func run(_ path: String, arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Silencieux — ex: delete d'une cle qui n'existe pas
        }
        return process.terminationStatus
    }
}
