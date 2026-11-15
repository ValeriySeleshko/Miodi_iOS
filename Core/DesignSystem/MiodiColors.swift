//
//  MiodiColors.swift
//  Plan4U_iOS
//
//  Pixel-perfect matching of Miodi Android Design System tokens.
//

import SwiftUI

extension Color {
    public init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    public init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Static UI & Paper Tokens (1-in-1 from Color.kt)
public enum MiodiStaticColors {
    public static let ruledLineColor = Color(hex: 0xEBDCE4)
    public static let widgetBorderColor = Color(hex: 0x636873)
    public static let darkText = Color(hex: 0x000000)
    public static let mutedHeader = Color(hex: 0x8A2757)
    public static let tabBarBg = Color(hex: 0xECE8DF)
    public static let tabInactiveBg = Color(hex: 0xDED9CF)
    public static let tabInactiveText = Color(hex: 0x737780)
    public static let badgeInactiveBg = Color(hex: 0xBCC0C7)
    public static let badgeInactiveText = Color(hex: 0x4E535E)
    public static let frameBorderColor = Color(hex: 0x38316C)
    public static let appViewportBg = Color(hex: 0xF0F1F5)
    public static let paperLightBg = Color(hex: 0xFFFFFF)

    // Macro Colors (БЖУ)
    public static let macroProtein = Color(hex: 0x3B82F6)
    public static let macroFat = Color(hex: 0xF59E0B)
    public static let macroCarb = Color(hex: 0x10B981)

    // Dark Theme Palette (06_dark_theme.css)
    public static let darkBackground = Color(hex: 0x0B0D14)
    public static let darkFrameBg = Color(hex: 0x14171F)
    public static let darkFrameBorder = Color(hex: 0x2E3547)
    public static let darkTopBarBg = Color(hex: 0x14171F)
    public static let darkTopBarBorder = Color(hex: 0x232836)
    public static let darkTextPrimary = Color(hex: 0xF1F5F9)
    public static let darkTextSecondary = Color(hex: 0x94A3B8)
    public static let darkWeekCircleBg = Color(hex: 0x1E2433)
    public static let darkTabsSubstrate = Color(hex: 0x0F131A)
    public static let darkTabInactiveBg = Color(hex: 0x1C2230)
    public static let darkTabInactiveText = Color(hex: 0x8892B0)
    public static let darkPaperBg = Color(hex: 0x161A24)
    public static let darkCardBg = Color(hex: 0x161A24)
    public static let darkRuledLine = Color(hex: 0x262C3D)
    public static let darkMarginLine = Color(hex: 0x4A3449)
}
