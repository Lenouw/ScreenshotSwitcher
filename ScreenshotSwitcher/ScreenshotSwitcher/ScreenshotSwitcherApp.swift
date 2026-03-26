import AppKit

// Point d'entree de l'application
@main
struct ScreenshotSwitcherApp {
    static func main() {
        let app = NSApplication.shared
        // Pas d'icone dans le Dock
        app.setActivationPolicy(.accessory)

        let delegate = AppDelegate()
        app.delegate = delegate

        app.run()
    }
}
