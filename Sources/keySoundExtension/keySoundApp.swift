import SwiftUI
import AppKit

private func dbg(_ msg: String) {
    FileHandle.standardError.write(Data("[keySound] \(msg)\n".utf8))
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

        // Poll for accessibility grant every 2 seconds for 30 seconds
        accessibilityCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            let granted = PermissionsHelper.isAccessibilityGranted
            if granted != self.state.accessibilityGranted {
                self.state.accessibilityGranted = granted
                self.updateMenu()
                dbg("accessibility changed to: \(granted)")
                if granted {
                    t.invalidate()
                    self.state.toggleListening()
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.accessibilityCheckTimer?.invalidate()
            self?.accessibilityCheckTimer = nil
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
