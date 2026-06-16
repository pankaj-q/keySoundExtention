import Cocoa
import CoreGraphics

class KeyListener {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false

    var onStatusChange: ((Bool) -> Void)?

    var isActive: Bool { isRunning }

    func start() -> Bool {
        guard !isRunning else { return true }

        let eventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue)
        )

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let listener = Unmanaged<KeyListener>.fromOpaque(refcon).takeUnretainedValue()
                listener.handleEvent(proxy: proxy, type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = tap else {
            isRunning = false
            onStatusChange?(false)
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        onStatusChange?(true)

        DispatchQueue.global(qos: .userInteractive).async {
            CFRunLoopRun()
        }

        return true
    }

    func stop() {
        guard isRunning else { return }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        onStatusChange?(false)
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) {
        switch type {
        case .keyDown:
            if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                let raw = event.getIntegerValueField(.keyboardEventKeycode)
                let name = KeyCodeMap.name(for: Int(raw))
                NotificationCenter.default.post(name: .keyPressed, object: name)
            }
        case .leftMouseDown:
            NotificationCenter.default.post(name: .keyPressed, object: "mouse_left")
        case .rightMouseDown:
            NotificationCenter.default.post(name: .keyPressed, object: "mouse_right")
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        default:
            break
        }
    }

    deinit {
        stop()
    }
}
