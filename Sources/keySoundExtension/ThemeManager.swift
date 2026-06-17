import Foundation

private func dbg(_ msg: String) {
    FileHandle.standardError.write(Data("[keySound] \(msg)\n".utf8))
}

class ThemeManager {
    let themesURL: URL

    var availableThemes: [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: themesURL,
            includingPropertiesForKeys: nil
        ) else {
            dbg("availableThemes: can't read \(themesURL.path)")
            return []
        }
        let dirs = contents.filter { $0.hasDirectoryPath }
        dbg("availableThemes: \(dirs.map { $0.lastPathComponent })")
        return dirs.map { $0.lastPathComponent }.sorted()
    }

    init() {
        let bundleURL = Bundle.module.bundleURL
        let candidate = bundleURL.appendingPathComponent("Themes")
        dbg("ThemeManager init")
        dbg("Bundle.module.bundleURL: \(bundleURL.path)")
        dbg("Checking Themes at: \(candidate.path)")

        if FileManager.default.fileExists(atPath: candidate.path) {
            themesURL = candidate
            dbg("Found Themes directory at: \(candidate.path)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: candidate.path) {
                dbg("Themes contents: \(contents)")
            }
        } else {
            dbg("Themes NOT found at \(candidate.path), trying fallback...")
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            let dir = appSupport.appendingPathComponent("keySoundExtension/Themes")
            try? FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true
            )
            themesURL = dir
            dbg("Fallback Themes at: \(dir.path)")
        }
    }

    func soundFiles(for theme: String) -> [String: URL] {
        let themeDir = themesURL.appendingPathComponent(theme)
        dbg("soundFiles for '\(theme)' at: \(themeDir.path)")

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: themeDir, includingPropertiesForKeys: nil
        ) else {
            dbg("  directory not found or unreadable")
            return [:]
        }

        var result: [String: URL] = [:]
        for file in contents where file.pathExtension == "wav" {
            var name = file.deletingPathExtension().lastPathComponent.lowercased()
            name = name.replacingOccurrences(of: "^key_", with: "", options: .regularExpression)
            result[name] = file
            dbg("  found: \(name) → \(file.lastPathComponent)")
        }
        dbg("  total wav files: \(result.count)")
        return result
    }

    func ensureDefaultTheme() {
        let classicDir = themesURL.appendingPathComponent("Classic")
        if !FileManager.default.fileExists(atPath: classicDir.path) {
            try? FileManager.default.createDirectory(
                at: classicDir, withIntermediateDirectories: true
            )
            dbg("Created Classic theme directory")
        }
    }
}
