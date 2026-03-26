import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var currentMode: ScreenshotMode = .retina

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Lire le mode actuel du systeme (priorite sur UserDefaults)
        currentMode = ScreenshotMode.current()
        UserDefaults.standard.set(currentMode.rawValue, forKey: "screenshotMode")

        // Creer l'item dans la menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItem()

        // Demander l'autorisation pour les notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // Met a jour l'icone et reconstruit le menu
    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        button.title = currentMode.icon

        let menu = NSMenu()

        // Mode actuel (non cliquable)
        let currentItem = NSMenuItem(title: "Mode actuel : \(currentMode.label)", action: nil, keyEquivalent: "")
        currentItem.isEnabled = false
        menu.addItem(currentItem)

        // Option pour switcher
        let switchItem = NSMenuItem(
            title: "Passer en \(currentMode.opposite.label) \(currentMode.opposite.icon)",
            action: #selector(switchMode),
            keyEquivalent: ""
        )
        switchItem.target = self
        menu.addItem(switchItem)

        menu.addItem(NSMenuItem.separator())

        // Quitter
        let quitItem = NSMenuItem(title: "Quitter", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func switchMode() {
        // Passer au mode oppose
        currentMode = currentMode.opposite
        currentMode.apply()

        // Persister le choix
        UserDefaults.standard.set(currentMode.rawValue, forKey: "screenshotMode")

        // Mettre a jour l'interface
        updateStatusItem()

        // Envoyer une notification
        sendNotification()
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ScreenshotSwitcher"
        content.body = currentMode.notificationMessage
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "mode-switch-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
