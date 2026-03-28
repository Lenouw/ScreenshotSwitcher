import Foundation

/// Surveille le dossier screenshots et redimensionne automatiquement
/// les nouvelles captures pour que le bord le plus large ne depasse pas maxDimension pixels.
class ScreenshotWatcher {

    private let maxDimension = 1700
    private var source: DispatchSourceFileSystemObject?
    private var knownFiles: Set<String> = []
    private var directoryFD: Int32 = -1

    /// Demarre la surveillance du dossier screenshots
    func start() {
        stop()

        let dir = screenshotDirectory()
        knownFiles = currentJPGs(in: dir)

        directoryFD = open(dir, O_EVTONLY)
        guard directoryFD >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryFD,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .utility)
        )

        src.setEventHandler { [weak self] in
            self?.handleDirectoryChange()
        }

        src.setCancelHandler { [weak self] in
            if let fd = self?.directoryFD, fd >= 0 {
                close(fd)
                self?.directoryFD = -1
            }
        }

        source = src
        src.resume()
    }

    /// Arrete la surveillance
    func stop() {
        source?.cancel()
        source = nil
    }

    // MARK: - Private

    private func handleDirectoryChange() {
        let dir = screenshotDirectory()
        let current = currentJPGs(in: dir)
        let newFiles = current.subtracting(knownFiles)
        knownFiles = current

        for file in newFiles {
            let path = (dir as NSString).appendingPathComponent(file)
            // Attendre que le fichier soit completement ecrit
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.resizeIfNeeded(path)
            }
        }
    }

    private func resizeIfNeeded(_ path: String) {
        // Verifier que le fichier existe encore
        guard FileManager.default.fileExists(atPath: path) else { return }

        // Lire les dimensions avec sips
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-g", "pixelWidth", "-g", "pixelHeight", path]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // Parser "pixelWidth: 2880" et "pixelHeight: 1800"
        var width = 0
        var height = 0
        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("pixelWidth:") {
                width = Int(trimmed.replacingOccurrences(of: "pixelWidth:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            } else if trimmed.hasPrefix("pixelHeight:") {
                height = Int(trimmed.replacingOccurrences(of: "pixelHeight:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }

        let maxSide = max(width, height)
        guard maxSide > maxDimension else { return }

        // Redimensionner avec sips
        let resize = Process()
        resize.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        resize.arguments = ["--resampleHeightWidthMax", "\(maxDimension)", path]
        resize.standardOutput = FileHandle.nullDevice
        resize.standardError = FileHandle.nullDevice

        do {
            try resize.run()
            resize.waitUntilExit()
        } catch {
            return
        }

        // Passer en 300 DPI
        let dpi = Process()
        dpi.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        dpi.arguments = ["-s", "dpiWidth", "300", "-s", "dpiHeight", "300", path]
        dpi.standardOutput = FileHandle.nullDevice
        dpi.standardError = FileHandle.nullDevice

        do {
            try dpi.run()
            dpi.waitUntilExit()
        } catch {
            // Silencieux
        }
    }

    /// Retourne le dossier ou macOS sauvegarde les screenshots
    private func screenshotDirectory() -> String {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "com.apple.screencapture", "location"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !path.isEmpty && FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
        } catch {
            // Fallback
        }

        return (NSHomeDirectory() as NSString).appendingPathComponent("Desktop")
    }

    /// Liste les fichiers JPG actuels dans le dossier
    private func currentJPGs(in directory: String) -> Set<String> {
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
        return Set(contents.filter { $0.lowercased().hasSuffix(".jpg") || $0.lowercased().hasSuffix(".jpeg") })
    }
}
