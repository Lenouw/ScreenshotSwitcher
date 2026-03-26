import AppKit
import ServiceManagement

class PreferencesWindowController: NSWindowController {

    private var launchAtLoginCheckbox: NSButton!
    private var notificationsCheckbox: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Titre de section
        let titleLabel = NSTextField(labelWithString: "General")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Checkbox : Lancer au demarrage
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Lancer au demarrage du Mac", target: self, action: #selector(toggleLaunchAtLogin))
        launchAtLoginCheckbox.translatesAutoresizingMaskIntoConstraints = false
        launchAtLoginCheckbox.state = isLaunchAtLoginEnabled() ? .on : .off
        contentView.addSubview(launchAtLoginCheckbox)

        // Checkbox : Notifications
        notificationsCheckbox = NSButton(checkboxWithTitle: "Afficher une notification apres le switch", target: self, action: #selector(toggleNotifications))
        notificationsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        notificationsCheckbox.state = UserDefaults.standard.object(forKey: "notificationsEnabled") == nil
            ? .on  // Active par defaut
            : (UserDefaults.standard.bool(forKey: "notificationsEnabled") ? .on : .off)
        contentView.addSubview(notificationsCheckbox)

        // Separateur
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        // Info compression
        let infoLabel = NSTextField(labelWithString: "Mode Vibe : compression JPG a 50%")
        infoLabel.font = NSFont.systemFont(ofSize: 11)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoLabel)

        // Contraintes Auto Layout
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            launchAtLoginCheckbox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            launchAtLoginCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            notificationsCheckbox.topAnchor.constraint(equalTo: launchAtLoginCheckbox.bottomAnchor, constant: 10),
            notificationsCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            separator.topAnchor.constraint(equalTo: notificationsCheckbox.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            infoLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
        ])
    }

    // MARK: - Actions

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        let enabled = sender.state == .on
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Si l'enregistrement echoue, remettre l'etat precedent
            sender.state = enabled ? .off : .on
        }
    }

    @objc private func toggleNotifications(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "notificationsEnabled")
    }

    // Verifie si l'app est dans les Login Items
    private func isLaunchAtLoginEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }

    // Affiche et met au premier plan la fenetre
    func showWindow() {
        // Mettre a jour l'etat des checkboxes a chaque ouverture
        launchAtLoginCheckbox.state = isLaunchAtLoginEnabled() ? .on : .off
        let notifEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "notificationsEnabled")
        notificationsCheckbox.state = notifEnabled ? .on : .off

        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
