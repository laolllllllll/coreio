import SwiftUI

extension Color {
    /// Accepts "#RRGGBB", "RRGGBB", "#AARRGGBB".
    init(hex: String, fallback: Color = Color.gray) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 || cleaned.count == 8,
              let value = UInt64(cleaned, radix: 16) else {
            self = fallback
            return
        }
        let hasAlpha = cleaned.count == 8
        let alpha = hasAlpha ? Double((value >> 24) & 0xFF) / 255.0 : 1.0
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
