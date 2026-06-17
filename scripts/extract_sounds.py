import json
import subprocess
import os

SOUND_DIR = "/Users/pankaj/Downloads/cherrymx-black-pbt"
CONFIG_PATH = os.path.join(SOUND_DIR, "config.json")
OGG_PATH = os.path.join(SOUND_DIR, "sound.ogg")
OUTPUT_DIR = "/Users/pankaj/keySoundExtension/Sources/keySoundExtension/Resources/Themes/Classic"

MECH_ID_TO_KEY = {
    # Letters (standard)
    30: "a", 31: "s", 32: "d", 33: "f", 34: "g", 35: "h",
    36: "j", 37: "k", 38: "l", 18: "e", 19: "r", 20: "t",
    21: "y", 22: "u", 23: "i", 24: "o", 25: "p",
    16: "q", 17: "w", 44: "z", 45: "x", 46: "c",
    47: "v", 48: "b", 49: "n", 50: "m",

    # Numbers
    2: "1", 3: "2", 4: "3", 5: "4", 6: "5",
    7: "6", 8: "7", 9: "8", 10: "9", 11: "0",

    # Symbols
    12: "minus", 13: "equal",
    26: "left_bracket", 27: "right_bracket",
    39: "semicolon", 40: "apostrophe",
    41: "backtick", 43: "backslash",
    51: "comma", 52: "period", 53: "slash",

    # Special keys
    1: "escape",
    14: "delete",
    15: "tab",
    28: "return",
    57: "space",
    58: "caps_lock",

    # Modifiers (darwin)
    29: "control",
    42: "shift",
    54: "right_shift",
    56: "option",
    3640: "right_option",
    3613: "right_control",
    3675: "command",
    3676: "command",
    3666: "function",

    # Function keys
    59: "f1", 60: "f2", 61: "f3", 62: "f4",
    63: "f5", 64: "f6", 65: "f7", 66: "f8",
    67: "f9", 68: "f10", 87: "f11", 88: "f12",
    91: "f13", 92: "f14", 93: "f15",

    # Navigation cluster (standard)
    3639: "print_screen",
    70: "scroll_lock",
    3653: "pause",
    3667: "forward_delete",
    3655: "home",
    3663: "end",
    3657: "page_up",
    3665: "page_down",
    3677: "menu",

    # Arrows (standard)
    57416: "up",
    57419: "left",
    57421: "right",
    57424: "down",

    # Numpad (standard + darwin: 69 → Clear)
    69: "keypad_clear",
    71: "keypad_7", 72: "keypad_8", 73: "keypad_9",
    75: "keypad_4", 76: "keypad_5", 77: "keypad_6",
    79: "keypad_1", 80: "keypad_2", 81: "keypad_3",
    82: "keypad_0",
    83: "keypad_decimal",
    55: "keypad_multiply",
    74: "keypad_minus",
    78: "keypad_plus",
    3637: "keypad_slash",
    3612: "keypad_enter",

    # Windows extras (present in config, map anyway)
    60999: "home",
    61000: "up",
    61001: "page_up",
    61003: "left",
    61005: "right",
    61007: "end",
    61008: "down",
    61009: "page_down",
    61010: "insert",
    61011: "forward_delete",
}

with open(CONFIG_PATH) as f:
    config = json.load(f)

defines = config["defines"]
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Remove old wavs
for old in os.listdir(OUTPUT_DIR):
    if old.endswith(".wav"):
        os.remove(os.path.join(OUTPUT_DIR, old))

extracted = 0
skipped = 0

for raw_id, (offset_ms, duration_ms) in defines.items():
    mech_id = int(raw_id)
    key_name = MECH_ID_TO_KEY.get(mech_id)

    if key_name is None:
        skipped += 1
        continue

    dur = max(duration_ms, 10)
    out_path = os.path.join(OUTPUT_DIR, f"key_{key_name}.wav")

    print(f"  {raw_id:>6}  →  key_{key_name}.wav  ({offset_ms}ms + {dur}ms)")
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error",
        "-i", OGG_PATH,
        "-ss", f"{offset_ms/1000:.3f}",
        "-t", f"{dur/1000:.3f}",
        "-acodec", "pcm_s16le",
        "-ar", "44100",
        "-ac", "1",
        out_path,
    ], check=True)
    extracted += 1

print(f"\nDone: {extracted} sounds extracted, {skipped} unmapped IDs skipped")
