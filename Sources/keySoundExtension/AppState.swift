import Combine
import Foundation

class AppState: ObservableObject {
    @Published var isListening = false
    @Published var selectedTheme = "Classic"
    @Published var isMuted = false
    @Published var themes: [String] = []

    let keyListener = KeyListener()
    let themeManager = ThemeManager()
    lazy var soundManager = SoundManager(themeManager: themeManager)

    init() {
        themes = themeManager.availableThemes
        if themes.isEmpty {
            themeManager.ensureDefaultTheme()
            themes = themeManager.availableThemes
        }
        if let first = themes.first {
            selectedTheme = first
        }
    }

    func toggleListening() {
        if isListening {
            keyListener.stop()
            isListening = false
        } else {
            let granted = PermissionsHelper.isAccessibilityGranted
            if !granted {
                PermissionsHelper.requestAccessibility()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let success = self.keyListener.start()
                DispatchQueue.main.async {
                    self.isListening = success
                }
            }
        }
    }

    func selectTheme(_ name: String) {
        selectedTheme = name
        soundManager.loadTheme(name)
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        soundManager.setMuted(muted)
    }
}
