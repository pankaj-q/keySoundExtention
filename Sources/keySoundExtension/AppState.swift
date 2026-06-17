import Foundation

private func dbg(_ msg: String) {
    FileHandle.standardError.write(Data("[keySound] \(msg)\n".utf8))
}

extension Notification.Name {
    static let keyPressed = Notification.Name("keyPressed")
}

class AppState {
    var isListening = false
    var selectedTheme = "Classic"
    var isMuted = false
    var themes: [String] = []
    var accessibilityGranted = false
    var onUpdate: (() -> Void)?

    let keyListener = KeyListener()
    let themeManager = ThemeManager()
    lazy var soundManager = SoundManager(themeManager: themeManager)

    init() {
        dbg("AppState init")
        dbg("Bundle.module.bundleURL: \(Bundle.module.bundleURL.path)")
        dbg("Bundle.main.bundlePath: \(Bundle.main.bundlePath)")

        themes = themeManager.availableThemes
        dbg("Found themes: \(themes)")

        if themes.isEmpty {
            dbg("No themes found, creating default")
            themeManager.ensureDefaultTheme()
            themes = themeManager.availableThemes
            dbg("After ensureDefault, themes: \(themes)")
        }
        if let first = themes.first {
            selectedTheme = first
            dbg("Selected theme: \(first)")
        }

        _ = soundManager
        accessibilityGranted = PermissionsHelper.isAccessibilityGranted
        dbg("Initial accessibility: \(accessibilityGranted)")

        keyListener.onStatusChange = { [weak self] running in
            DispatchQueue.main.async {
                self?.isListening = running
                self?.onUpdate?()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.autoStart()
        }
    }

    private func autoStart() {
        accessibilityGranted = PermissionsHelper.isAccessibilityGranted
        if accessibilityGranted {
            dbg("autoStart: accessibility granted, starting...")
            _ = keyListener.start()
        } else {
            dbg("autoStart: accessibility not granted yet")
        }
    }

    func requestPermission() {
        PermissionsHelper.requestAccessibility()
        // Check every 1 second for up to 10 seconds for permission grant
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            attempts += 1
            self?.accessibilityGranted = PermissionsHelper.isAccessibilityGranted
            if self?.accessibilityGranted == true {
                timer.invalidate()
                self?.autoStart()
            } else if attempts >= 10 {
                timer.invalidate()
            }
        }
    }

    func toggleListening() {
        if isListening {
            keyListener.stop()
        } else {
            accessibilityGranted = PermissionsHelper.isAccessibilityGranted
            if accessibilityGranted {
                _ = keyListener.start()
            } else {
                requestPermission()
            }
        }
    }

    func selectTheme(_ name: String) {
        selectedTheme = name
        soundManager.loadTheme(name)
        dbg("Theme changed to: \(name)")
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        soundManager.setMuted(muted)
        dbg("Muted: \(muted)")
    }
}
