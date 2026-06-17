import Cocoa
import CoreGraphics

private func dbg(_ msg: String) {
    FileHandle.standardError.write(Data("[keySound] \(msg)\n".utf8))
}

class KeyListener {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false

    var onStatusChange: ((Bool) -> Void)?
    var isActive: Bool { isRunning }

    func start() -> Bool {
        guard !isRunning else {
            dbg("start: already running")
            return true
        }

        dbg("start: creating event tap...")

        let eventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
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
            dbg("start: CGEvent.tapCreate returned nil — access likely denied")
            isRunning = false
            DispatchQueue.main.async { self.onStatusChange?(false) }
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        dbg("start: tap and source created")

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        DispatchQueue.main.async { self.onStatusChange?(true) }
        dbg("start: event tap active on main run loop")

        return true
    }

    func stop() {
        guard isRunning else {
            dbg("stop: not running")
            return
        }
        dbg("stop: stopping event tap")
        isRunning = false
        DispatchQueue.main.async { self.onStatusChange?(false) }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        dbg("stop: event tap stopped")
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) {
        switch type {
        case .keyDown:
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            let raw = event.getIntegerValueField(.keyboardEventKeycode)
            let name = KeyCodeMap.name(for: Int(raw))
            dbg("keyDown: code=\(Int(raw)) name='\(name)' repeat=\(isRepeat)")
            if !isRepeat {
                NotificationCenter.default.post(name: .keyPressed, object: name)
            }

        case .flagsChanged:
            let raw = event.getIntegerValueField(.keyboardEventKeycode)
            let name = KeyCodeMap.name(for: Int(raw))
            let flags = event.flags
            let isPressed: Bool
            switch Int(raw) {
            case 55: isPressed = flags.contains(.maskCommand)
            case 56, 60: isPressed = flags.contains(.maskShift)
            case 57: isPressed = true
            case 58, 61: isPressed = flags.contains(.maskAlternate)
            case 59, 62: isPressed = flags.contains(.maskControl)
            default: isPressed = false
            }
            dbg("flagsChanged: code=\(Int(raw)) name='\(name)' isPressed=\(isPressed)")
            if isPressed {
                NotificationCenter.default.post(name: .keyPressed, object: name)
            }

        case .leftMouseDown:
            dbg("leftMouseDown")
            NotificationCenter.default.post(name: .keyPressed, object: "mouse_left")

        case .rightMouseDown:
            dbg("rightMouseDown")
            NotificationCenter.default.post(name: .keyPressed, object: "mouse_right")

        case .tapDisabledByTimeout:
            dbg("tap disabled by timeout — re-enabling")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }

        case .tapDisabledByUserInput:
            dbg("tap disabled by user input — re-enabling")
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
