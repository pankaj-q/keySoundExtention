import Foundation

class ThemeManager {
    let themesURL: URL

    var availableThemes: [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: themesURL,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return contents
            .filter { $0.hasDirectoryPath }
            .map { $0.lastPathComponent }
            .sorted()
    }

    init() {
        if let found = Self.findThemesDirectory() {
            themesURL = found
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            let dir = appSupport.appendingPathComponent("keySoundExtension/Themes")
            try? FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true
            )
            themesURL = dir
        }
    }

    func soundFiles(for theme: String) -> [String: URL] {
        let themeDir = themesURL.appendingPathComponent(theme)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: themeDir, includingPropertiesForKeys: nil
        ) else {
            return [:]
        }
        var result: [String: URL] = [:]
        for file in contents where file.pathExtension == "wav" {
            let name = file.deletingPathExtension().lastPathComponent.lowercased()
            result[name] = file
        }
        return result
    }

    func ensureDefaultTheme() {
        let classicDir = themesURL.appendingPathComponent("Classic")
        if !FileManager.default.fileExists(atPath: classicDir.path) {
            try? FileManager.default.createDirectory(
                at: classicDir, withIntermediateDirectories: true
            )
        }
    }

    private static func findThemesDirectory() -> URL? {
        let execURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let execDir = execURL.deletingLastPathComponent()

        let candidates = [
            execDir.appendingPathComponent("Themes"),
            execDir.appendingPathComponent("Resources/Themes"),
            execDir.deletingLastPathComponent().appendingPathComponent("Resources/Themes"),
            Bundle.main.resourceURL?.appendingPathComponent("Themes"),
        ]

        for url in candidates {
            if let url = url, FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }
}
