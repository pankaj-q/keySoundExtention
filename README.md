# keySound

macOS menu bar app that plays unique mechanical keyboard sounds for each key press.

## Installation

### Prerequisites
- macOS 13+
- [ffmpeg](https://ffmpeg.org/) (only needed if extracting from Mechvibes packs)

### Quick Start
```bash
git clone <repo-url>
cd keySoundExtension
swift build -c release
```

### Build the .app bundle
```bash
mkdir -p /Applications/keySoundExtension.app/Contents/MacOS /Applications/keySoundExtension.app/Contents/Resources
cp .build/arm64-apple-macosx/release/keySoundExtension /Applications/keySoundExtension.app/Contents/MacOS/
cp -R .build/arm64-apple-macosx/release/keySoundExtension_keySoundExtension.bundle /Applications/keySoundExtension.app/Contents/Resources/
```

Create `Info.plist` at `/Applications/keySoundExtension.app/Contents/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>keySoundExtension</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.keySoundExtension</string>
    <key>CFBundleName</key>
    <string>keySoundExtension</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

Ad-hoc sign and launch:
```bash
codesign --force --sign - /Applications/keySoundExtension.app/Contents/MacOS/keySoundExtension
codesign --force --sign - /Applications/keySoundExtension.app
open /Applications/keySoundExtension.app
```

> **Note:** Launch via `open` may not properly grant accessibility. If you don't hear sounds, launch directly:
> ```bash
> /Applications/keySoundExtension.app/Contents/MacOS/keySoundExtension &
> disown
> ```

### Grant Accessibility Permission
1. Click the keyboard icon in the menu bar
2. Click **Enable Accessibility**
3. Open **System Settings → Privacy & Security → Accessibility**
4. Click **+** → press `Cmd+Shift+G` → paste `/Applications/keySoundExtension.app` → **Open**
5. Enable the toggle
6. Click **Refresh Status** in the app menu

## Usage

- **Keyboard icon (⌨️)** in menu bar — click to open the menu
- **Start/Stop Listening** — toggle key capture
- **Muted** — silence all sounds
- **Sound Theme** — switch between installed themes
- **Refresh Status** — re-check accessibility permission

### Starting at Login
Add the app in **System Settings → General → Login Items**, or use:
```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/keySoundExtension.app", hidden:true}'
```

## Sound Themes

Themes are stored in `Sources/keySoundExtension/Themes/<ThemeName>/`.

Each theme directory contains individual `.wav` files. The app comes with a **Classic** theme (CherryMX Black keycaps).

### Changing a Single Key's Sound

Each key maps to a `.wav` file by name. Replace the file for the key you want to change:

| Key | File |
|-----|------|
| A | `a.wav` |
| B | `b.wav` |
| Space | `space.wav` |
| Enter | `enter.wav` |
| Return | `return.wav` |
| Delete | `delete.wav` |
| Shift | `shift.wav` |
| Control | `control.wav` |
| Option | `option.wav` |
| Command | `command.wav` |
| Caps Lock | `caps_lock.wav` |
| Tab | `tab.wav` |
| Escape | `escape.wav` |
| Arrow Up | `up.wav` |
| Arrow Down | `down.wav` |
| Arrow Left | `left.wav` |
| Arrow Right | `right.wav` |
| F1–F26 | `f1.wav` … `f26.wav` |
| Keypad 0–9 | `keypad_0.wav` … `keypad_9.wav` |
| Mouse Left | `mouse_left.wav` |
| Mouse Right | `mouse_right.wav` |
| *Any other key* | `default.wav` |

To change a sound:
1. Find the theme directory by running the app once, then check its bundle:
   ```
   find /tmp -name "*.wav" 2>/dev/null | head -5
   ```
   Or look in `.build/arm64-apple-macosx/release/keySoundExtension_keySoundExtension.bundle/Themes/`
2. Replace the `.wav` file with your own (must be 16-bit WAV, any sample rate)
3. Restart the app

### Creating a New Theme
1. Copy an existing theme: `cp -R Sources/keySoundExtension/Themes/Classic Sources/keySoundExtension/Themes/MyTheme`
2. Replace `.wav` files with your sounds
3. Rebuild: `swift build -c release`
4. Select "MyTheme" from the **Sound Theme** menu

### Key Aliases (Remapping Sounds)
Some keys can be aliased to play another key's sound. Edit `SoundManager.swift`:
```swift
private let keyAliases: [String: String] = [
    "delete": "return"  // delete plays the return sound
]
```

### Extracting from Mechvibes Packs
```bash
python3 scripts/extract_sounds.py /path/to/mechvibes/pack /path/to/output
```
This extracts the Mechvibes `sound.ogg` sprite into individual `.wav` files per key.

## Development

```bash
swift build
swift run  # runs directly without .app bundle (menu bar may not appear)
```

For live debugging:
```bash
tail -f /tmp/ks_*.log
```
 