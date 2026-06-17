import AVFoundation
import AppKit

private func dbg(_ msg: String) {
    FileHandle.standardError.write(Data("[keySound] \(msg)\n".utf8))
}

class SoundManager {
    private var soundCache: [String: Data] = [:]
    private(set) var currentTheme: String = "Classic"
    private weak var themeManager: ThemeManager?
    private var isMuted = false

    var themeName: String { currentTheme }

    init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        themeManager.ensureDefaultTheme()
        loadTheme("Classic")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyPress),
            name: .keyPressed,
            object: nil
        )
    }

    func loadTheme(_ name: String) {
        currentTheme = name
        soundCache.removeAll()
        guard let manager = themeManager else {
            dbg("loadTheme: no themeManager")
            return
        }
        let files = manager.soundFiles(for: name)
        dbg("loadTheme '\(name)': found \(files.count) files")
        for (key, url) in files {
            if let data = try? Data(contentsOf: url) {
                soundCache[key] = data
                dbg("  loaded \(key) (\(data.count) bytes)")
            } else {
                dbg("  FAILED to load \(key) from \(url.path)")
            }
        }
        dbg("total sounds cached: \(soundCache.count)")
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    @objc private func handleKeyPress(_ notification: Notification) {
        guard let keyName = notification.object as? String else {
            dbg("keyPress: no key name in notification")
            return
        }
        dbg("keyPress received: '\(keyName)', muted=\(isMuted)")

        guard !isMuted else { return }
        let lowerKey = keyName.lowercased()
        let data = soundCache[lowerKey] ?? soundCache["default"]
        guard let soundData = data else {
            dbg("  no sound data for '\(lowerKey)' or default")
            return
        }

        do {
            let player = try AVAudioPlayer(data: soundData)
            player.volume = 1.0
            player.prepareToPlay()
            if player.play() {
                dbg("  playing sound for '\(lowerKey)'")
            } else {
                dbg("  play() returned false for '\(lowerKey)'")
            }
        } catch {
            dbg("  AVAudioPlayer error: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
