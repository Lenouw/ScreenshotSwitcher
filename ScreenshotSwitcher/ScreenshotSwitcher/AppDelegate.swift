import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    private var statusItem: NSStatusItem!
    private var currentMode: ScreenshotMode = .retina
    private lazy var preferencesWindowController = PreferencesWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Lire le mode actuel du systeme (priorite sur UserDefaults)
        currentMode = ScreenshotMode.current()
        UserDefaults.standard.set(currentMode.rawValue, forKey: "screenshotMode")

        // Creer l'item dans la menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItem()

        // Configurer les notifications (delegate pour affichage meme si app au premier plan)
        let notifCenter = UNUserNotificationCenter.current()
        notifCenter.delegate = self
        notifCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // Permet d'afficher la notification meme quand l'app est active
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Met a jour l'icone et reconstruit le menu
    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        // Utiliser SF Symbols pour un rendu natif dans la menu bar
        let symbolName = currentMode == .retina ? "camera.fill" : "bolt.fill"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: currentMode.label) {
            image.isTemplate = true // S'adapte au theme clair/sombre
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = currentMode.icon
        }

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

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

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

        // Envoyer une notification (si activees dans les preferences)
        let notifEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if notifEnabled {
            sendNotification()
        }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ScreenshotSwitcher"
        content.body = currentMode.notificationMessage
        content.sound = .default

        // Utiliser un trigger avec delai court pour fiabiliser la livraison
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)

        let request = UNNotificationRequest(
            identifier: "mode-switch",
            content: content,
            trigger: trigger
        )

        // Supprimer les notifications precedentes avant d'en envoyer une nouvelle
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        center.add(request) { _ in }
    }

    @objc private func openPreferences() {
        preferencesWindowController.showWindow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
