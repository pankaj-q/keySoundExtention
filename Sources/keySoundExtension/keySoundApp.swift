import SwiftUI

@main
struct keySoundApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            Button(state.isListening ? "Stop Listening" : "Start Listening") {
                state.toggleListening()
            }
            .keyboardShortcut(state.isListening ? .escape : .space, modifiers: .command)

            Toggle(isOn: Binding(
                get: { state.isMuted },
                set: { state.setMuted($0) }
            )) {
                Text("Muted")
            }

            Divider()

            Menu("Sound Theme") {
                ForEach(state.themes, id: \.self) { theme in
                    Button(theme) {
                        state.selectTheme(theme)
                    }
                    .disabled(theme == state.selectedTheme)
                }
            }

            Divider()

            Button("Accessibility Permission...") {
                PermissionsHelper.requestAccessibility()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: state.isListening ? "keyboard.fill" : "keyboard")
        }
    }
}
