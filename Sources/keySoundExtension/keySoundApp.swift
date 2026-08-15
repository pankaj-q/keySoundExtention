import SwiftUI
import AppKit

private func dbg(_ msg: String) {
    FileHandle.standardError.write(Data("[keySound] \(msg)\n".utf8))
}

private func writeStatus(_ text: String) {
    try? text.write(toFile: "/tmp/ks_status.txt", atomically: true, encoding: .utf8)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    lazy var state = AppState()
    var accessibilityCheckTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        dbg("applicationDidFinishLaunching")
        NSApplication.shared.setActivationPolicy(.accessory)
        dbg("activation policy set to accessory")

        state.onUpdate = { [weak self] in
            DispatchQueue.main.async { self?.updateMenu() }
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "keySound")
        }
        updateMenu()
        dbg("status bar item created")
        dbg("accessibility at launch: \(PermissionsHelper.isAccessibilityGranted)")
        writeStatus("launch: granted=\(PermissionsHelper.isAccessibilityGranted) pid=\(ProcessInfo.processInfo.processIdentifier)")

        var promptShown = false
        let initialGranted = PermissionsHelper.isAccessibilityGranted
        if initialGranted != self.state.accessibilityGranted {
            self.state.accessibilityGranted = initialGranted
            self.updateMenu()
            dbg("accessibility checked at launch: \(initialGranted)")
            writeStatus("launch-check: granted=\(initialGranted) pid=\(ProcessInfo.processInfo.processIdentifier)")
            if initialGranted && !self.state.isListening {
                self.state.toggleListening()
            }
        }

        accessibilityCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            let granted = PermissionsHelper.isAccessibilityGranted
            if granted != self.state.accessibilityGranted {
                self.state.accessibilityGranted = granted
                self.updateMenu()
                dbg("accessibility changed to: \(granted)")
                writeStatus("change: granted=\(granted) pid=\(ProcessInfo.processInfo.processIdentifier)")
                if granted && !self.state.isListening {
                    t.invalidate()
                    self.state.toggleListening()
                }
            }
            writeStatus("tick: granted=\(granted) listening=\(self.state.isListening) pid=\(ProcessInfo.processInfo.processIdentifier)")
            if !granted && !self.state.isListening && !promptShown {
                promptShown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self = self, !PermissionsHelper.isAccessibilityGranted else { return }
                    let alert = NSAlert()
                    alert.messageText = "keySound needs Accessibility"
                    alert.informativeText = "Enable it in System Settings → Privacy & Security → Accessibility, then click Refresh Status."
                    alert.addButton(withTitle: "Open System Settings")
                    alert.addButton(withTitle: "Later")
                    if alert.runModal() == .alertFirstButtonReturn {
                        PermissionsHelper.requestAccessibility()
                    }
                }
            }
        }
    }

    func updateMenu() {
        let menu = NSMenu()

        let statusText: String
        if state.isListening {
            statusText = "✅ Listening..."
        } else if state.accessibilityGranted {
            statusText = "⏸ Ready"
        } else {
            statusText = "⛔ No Access"
        }
        let item = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)

        menu.addItem(.separator())

        if state.accessibilityGranted {
            menu.addItem(NSMenuItem(title: state.isListening ? "Stop Listening" : "Start Listening",
                                    action: #selector(toggleListening), keyEquivalent: ""))
        }

        let mutedItem = NSMenuItem(title: "Muted", action: #selector(toggleMuted), keyEquivalent: "m")
        mutedItem.state = state.isMuted ? .on : .off
        menu.addItem(mutedItem)

        menu.addItem(.separator())

        let themeMenu = NSMenu(title: "Sound Theme")
        for theme in state.themes {
            let t = NSMenuItem(title: theme, action: #selector(selectTheme(_:)), keyEquivalent: "")
            t.representedObject = theme
            t.state = theme == state.selectedTheme ? .on : .off
            themeMenu.addItem(t)
        }
        let themeMenuItem = NSMenuItem(title: "Sound Theme", action: nil, keyEquivalent: "")
        themeMenuItem.submenu = themeMenu
        menu.addItem(themeMenuItem)

        if !state.accessibilityGranted {
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "⚠️ Enable Accessibility",
                                    action: #selector(requestPermission), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "🔄 Refresh Status",
                                    action: #selector(refreshAccessibility), keyEquivalent: "r"))
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func toggleListening() {
        state.toggleListening()
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: state.isListening ? "keyboard.fill" : "keyboard",
                                   accessibilityDescription: "keySound")
        }
        updateMenu()
    }

    @objc func toggleMuted() {
        state.setMuted(!state.isMuted)
        updateMenu()
    }

    @objc func selectTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? String else { return }
        state.selectTheme(theme)
        updateMenu()
    }

    @objc func requestPermission() {
        state.requestPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.refreshAccessibility()
        }
    }

    @objc func refreshAccessibility() {
        let granted = PermissionsHelper.isAccessibilityGranted
        dbg("refreshAccessibility: \(granted)")
        state.accessibilityGranted = granted
        if granted && !state.isListening {
            state.toggleListening()
        }
        updateMenu()
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

@main
struct keySoundApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
