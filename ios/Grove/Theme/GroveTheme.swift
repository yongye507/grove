import SwiftUI

enum GroveTheme {
    /// Warm linen paper
    static let paperTop = Color(hex: "F4EFE6")
    static let paperBottom = Color(hex: "E7E0D4")
    static let ink = Color(hex: "2A3328")
    static let inkMuted = Color(hex: "6B7368")
    static let moss = Color(hex: "3D6B4F")
    static let mossDeep = Color(hex: "2F5640")
    static let leaf = Color(hex: "5A8F68")
    static let leafLight = Color(hex: "8FBF91")
    static let soil = Color(hex: "6B4F3A")
    static let pot = Color(hex: "C4A484")
    static let potRim = Color(hex: "A8845E")
    static let wiltLeaf = Color(hex: "9A9E8E")
    static let wiltSoil = Color(hex: "8A7B6A")
    static let warmGlow = Color(hex: "E8C9A0").opacity(0.35)
    static let chipFill = Color.white.opacity(0.55)
    static let chipSelected = Color(hex: "3D6B4F")

    static let displayFont: Font = .system(.largeTitle, design: .serif).weight(.semibold)
    static let timerFont: Font = .system(size: 44, weight: .light, design: .rounded)
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
