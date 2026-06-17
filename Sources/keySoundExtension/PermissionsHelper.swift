import Cocoa

struct PermissionsHelper {
    static var isAccessibilityGranted: Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
