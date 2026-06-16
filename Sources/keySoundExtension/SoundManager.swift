import AVFoundation
import AppKit

extension Notification.Name {
    static let keyPressed = Notification.Name("keyPressed")
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
        guard let manager = themeManager else { return }
        let files = manager.soundFiles(for: name)
        for (key, url) in files {
            if let data = try? Data(contentsOf: url) {
                soundCache[key] = data
            }
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    @objc private func handleKeyPress(_ notification: Notification) {
        guard !isMuted, let keyName = notification.object as? String else { return }
        let lowerKey = keyName.lowercased()
        let data = soundCache[lowerKey] ?? soundCache["default"]
        guard let soundData = data else { return }

        do {
            let player = try AVAudioPlayer(data: soundData)
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
        } catch {
            NSSound.beep()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
