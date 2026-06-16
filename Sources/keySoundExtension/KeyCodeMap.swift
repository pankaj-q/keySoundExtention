import CoreGraphics

let keyCodeMap: [Int: String] = [
    0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x",
    8: "c", 9: "v", 10: "b", 11: "q", 12: "w", 13: "e", 14: "r", 15: "y",
    16: "t", 17: "1", 18: "2", 19: "3", 20: "4", 21: "6", 22: "5", 23: "equal",
    24: "9", 25: "7", 26: "minus", 27: "8", 28: "0", 29: "right_bracket",
    30: "o", 31: "u", 32: "left_bracket", 33: "i", 34: "p",
    35: "return", 36: "l", 37: "j", 38: "apostrophe", 39: "k",
    40: "semicolon", 41: "backslash", 42: "comma", 43: "slash",
    44: "n", 45: "m", 46: "period",
    47: "tab", 48: "space", 49: "backtick",
    50: "delete", 51: "enter", 53: "escape",
    55: "command", 56: "shift", 57: "caps_lock", 58: "option", 59: "control",
    60: "right_shift", 61: "right_option", 62: "right_control",
    63: "function", 64: "f17", 65: "keypad_decimal", 67: "keypad_multiply",
    69: "keypad_plus", 71: "keypad_clear", 75: "keypad_divide", 76: "keypad_enter",
    78: "keypad_minus", 79: "keypad_equals", 80: "keypad_0", 81: "keypad_1",
    82: "keypad_2", 83: "keypad_3", 84: "keypad_4", 85: "keypad_5",
    86: "keypad_6", 87: "keypad_7", 88: "keypad_8", 89: "keypad_9",
    96: "f5", 97: "f6", 98: "f7", 99: "f3", 100: "f8", 101: "f9",
    102: "f11", 103: "f10", 104: "f12", 105: "f13", 106: "f14", 107: "f15",
    108: "f16", 109: "f17", 110: "f18", 111: "f19", 112: "f20",
    113: "f21", 114: "f22", 115: "f23", 116: "f24",
    117: "f25", 118: "f4", 119: "f2", 120: "f1", 121: "f26",
    122: "f1", 123: "left", 124: "right", 125: "down", 126: "up",
]

struct KeyCodeMap {
    static func name(for code: Int) -> String {
        keyCodeMap[code] ?? "key_\(code)"
    }
}
