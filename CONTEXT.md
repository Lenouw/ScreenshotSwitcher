# Contexte du projet

## Projet
ScreenshotSwitcher - Menu bar app macOS native qui permet de switcher le format des screenshots entre Retina (PNG full res) et Vibe (JPG 100% qualite, redimensionne a max 1700px, 300 DPI). Optimise pour le vibe coding avec Claude Code.

## Stack technique
- Swift 5, AppKit (pas de SwiftUI)
- macOS 13+ minimum
- Xcode project manuel (pas de SPM)
- Frameworks : UserNotifications, ServiceManagement (SMAppService pour Login Items)
- Pas de dependances externes
- Outils natifs utilises : `sips` (resize/DPI), `defaults` (screencapture settings), `killall` (SystemUIServer)

## Derniere mise a jour
28 mars 2026 - 10h40

## Ce qu'on a fait
- 28/03/2026 : Ajout auto-resize des screenshots en mode Vibe (ScreenshotWatcher.swift) — surveille le dossier screenshots, redimensionne a max 1700px via sips, met le DPI a 300
- 28/03/2026 : Compression JPG passee de 50% a 100% (qualite max) — les fichiers restent legers grace au resize a 1700px
- 28/03/2026 : Nettoyage du code (suppression logs de debug, fonction log())
- 27/03/2026 : Ajout fenetre Preferences (lancer au demarrage, toggle notifications)
- 27/03/2026 : Ajout icone app (AppIcon.icns genere via Pillow, degrade violet/bleu avec eclair)
- 27/03/2026 : Remplacement emojis menu bar par SF Symbols natifs (camera.fill / bolt.fill)
- 27/03/2026 : Tentative notifications via UNUserNotificationCenter — non fonctionnel
- 26/03/2026 : Creation complete de l'app (ScreenshotMode, AppDelegate, entry point, Info.plist, project.pbxproj)
- 26/03/2026 : Repo GitHub cree : https://github.com/Lenouw/ScreenshotSwitcher
- 26/03/2026 : Initialisation du projet (git init, .gitignore, CONTEXT.md)

## Ou on en est
L'app fonctionne et est installee dans /Applications. En mode Vibe, les screenshots sont : JPG qualite 100%, redimensionnes automatiquement a max 1700px (bord le plus large), 300 DPI. Le watcher (ScreenshotWatcher) surveille le dossier Desktop et traite les nouveaux JPG via sips. En mode Retina, les screenshots restent en PNG pleine resolution sans traitement. Teste et verifie : un screenshot plein ecran (2560px natif) est bien reduit a 1700px.

## Architecture et decisions
- **AppKit pur** : pas de SwiftUI car app minimaliste menu bar, AppKit plus adapte
- **SF Symbols** pour la menu bar : `camera.fill` (Retina) et `bolt.fill` (Vibe) — rendu natif, s'adapte au theme clair/sombre via `isTemplate = true`
- **SMAppService.mainApp** pour les Login Items : API moderne macOS 13+ (pas de helper app)
- **Process()** pour les commandes systeme : appels directs a `/usr/bin/defaults`, `/usr/bin/killall`, `/usr/bin/sips` avec arguments en array (pas de shell, securise)
- **LSUIElement = true** : pas d'icone dans le Dock
- **JPG 100% qualite + resize 1700px** : la reduction de taille vient du resize, pas de la compression. Lisibilite maximale pour Claude Code tout en restant sous la limite API (8000px max, 2000px pour 20+ images)
- **300 DPI** : meilleure nettete pour le texte dans les screenshots
- **DispatchSource file watcher** : surveille le dossier screenshots avec `makeFileSystemObjectSource`, detecte les nouveaux fichiers JPG, attend 0.8s que le fichier soit ecrit, puis redimensionne via sips
- **sips natif** : `--resampleHeightWidthMax 1700` pour le resize, `-s dpiWidth/dpiHeight 300` pour le DPI — zero dependance externe
- **Notifications abandonnees** : UNUserNotificationCenter ne delivre pas les bannieres malgre permission granted=1, probablement lie au code signing local

## Fichiers cles
- `ScreenshotSwitcher/ScreenshotSwitcher/ScreenshotMode.swift` — enum des 2 modes, apply() via defaults write, current() via defaults read
- `ScreenshotSwitcher/ScreenshotSwitcher/AppDelegate.swift` — NSStatusItem, menu, switch, watcher start/stop, notifications, preferences
- `ScreenshotSwitcher/ScreenshotSwitcher/ScreenshotWatcher.swift` — file watcher sur le dossier screenshots, auto-resize via sips (max 1700px, 300 DPI)
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
- [x] Auto-resize screenshots en mode Vibe (max 1700px, 300 DPI)
- [ ] Investiguer les notifications (optionnel)
- [ ] Signer l'app avec un Developer ID pour distribution
