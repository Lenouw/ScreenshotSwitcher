# Contexte du projet

## Projet
ScreenshotSwitcher - Menu bar app macOS native qui permet de switcher le format des screenshots entre Retina (PNG full res) et Vibe (JPG compresse a 50% pour usage IA/vibe coding). Reduit la taille des screenshots par 3.

## Stack technique
- Swift 5, AppKit (pas de SwiftUI)
- macOS 13+ minimum
- Xcode project manuel (pas de SPM)
- Frameworks : UserNotifications, ServiceManagement (SMAppService pour Login Items)
- Pas de dependances externes

## Derniere mise a jour
27 mars 2026 - 00h30

## Ce qu'on a fait
- 27/03/2026 : Ajout fenetre Preferences (lancer au demarrage, toggle notifications)
- 27/03/2026 : Ajout icone app (AppIcon.icns genere via Pillow, degrade violet/bleu avec eclair)
- 27/03/2026 : Remplacement emojis menu bar par SF Symbols natifs (camera.fill / bolt.fill)
- 27/03/2026 : Tentative notifications via UNUserNotificationCenter — non fonctionnel (permission OK mais bannieres n'apparaissent pas, probablement lie au signing ad-hoc)
- 26/03/2026 : Creation complete de l'app (ScreenshotMode, AppDelegate, entry point, Info.plist, project.pbxproj)
- 26/03/2026 : Repo GitHub cree : https://github.com/Lenouw/ScreenshotSwitcher
- 26/03/2026 : Initialisation du projet (git init, .gitignore, CONTEXT.md)

## Ou on en est
L'app fonctionne et est installee dans /Applications. Elle est dans les Login Items pour lancement au demarrage. Le menu bar affiche un SF Symbol (camera ou bolt) qui change selon le mode actif. Le menu propose : mode actuel, switch, preferences, quitter. La fenetre Preferences permet de toggler le lancement au demarrage et les notifications. Les notifications ne fonctionnent pas (probleme non resolu, laisse de cote).

## Architecture et decisions
- **AppKit pur** : pas de SwiftUI car app minimaliste menu bar, AppKit plus adapte
- **SF Symbols** pour la menu bar : `camera.fill` (Retina) et `bolt.fill` (Vibe) — rendu natif, s'adapte au theme clair/sombre via `isTemplate = true`
- **SMAppService.mainApp** pour les Login Items : API moderne macOS 13+ (pas de helper app)
- **Process()** pour les commandes systeme : appels directs a `/usr/bin/defaults` et `/usr/bin/killall` avec arguments en array (pas de shell, securise)
- **LSUIElement = true** : pas d'icone dans le Dock
- **Compression JPG a 50%** : sweet spot pour le vibe coding — en dessous de 30% le texte dans les screenshots devient illisible pour Claude
- **Notifications abandonnees** : UNUserNotificationCenter ne delivre pas les bannieres malgre permission granted=1, probablement lie au code signing local

## Fichiers cles
- `ScreenshotSwitcher/ScreenshotSwitcher/ScreenshotMode.swift` — enum des 2 modes, apply() via defaults write, current() via defaults read
- `ScreenshotSwitcher/ScreenshotSwitcher/AppDelegate.swift` — NSStatusItem, menu, switch, notifications, preferences
- `ScreenshotSwitcher/ScreenshotSwitcher/PreferencesWindowController.swift` — fenetre preferences (launch at login, notifications toggle)
- `ScreenshotSwitcher/ScreenshotSwitcher/ScreenshotSwitcherApp.swift` — @main entry point, NSApp.setActivationPolicy(.accessory)
- `ScreenshotSwitcher/ScreenshotSwitcher/Info.plist` — LSUIElement, CFBundleIconFile
- `ScreenshotSwitcher/ScreenshotSwitcher/AppIcon.icns` — icone de l'app

## Problemes connus
- Les notifications macOS ne s'affichent pas malgre les permissions activees. Probablement un probleme de code signing (app signee "Sign to Run Locally"). A investiguer si necessaire.

## Ce qu'il reste a faire
- [x] Creer l'app de base (modes, menu bar, switch)
- [x] Installer dans /Applications
- [x] Ajouter au Login Items
- [x] Fenetre Preferences
- [x] Icone de l'app
- [x] SF Symbols dans la menu bar
- [x] Repo GitHub
- [ ] Investiguer les notifications (optionnel)
- [ ] Signer l'app avec un Developer ID pour distribution
