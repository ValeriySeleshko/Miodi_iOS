//
//  MiodiTheme.swift
//  Plan4U_iOS
//
//  Accent theme configurations and active theme environment.
//

import SwiftUI

public struct AccentThemeConfig: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let primary: Color
    public let primaryDark: Color
    public let marginLine: Color
    public let sectionBg: Color
    public let sectionBorder: Color
    public let sectionText: Color
    public let darkSectionBg: Color
    public let darkSectionBorder: Color
    public let darkSectionText: Color

    public init(
        id: String,
        name: String,
        primary: Color,
        primaryDark: Color,
        marginLine: Color,
        sectionBg: Color,
        sectionBorder: Color,
        sectionText: Color,
        darkSectionBg: Color = Color(hex: 0x261D2B),
        darkSectionBorder: Color = Color(hex: 0x4A3449),
        darkSectionText: Color = Color(hex: 0xFFFFB6D9)
    ) {
        self.id = id
        self.name = name
        self.primary = primary
        self.primaryDark = primaryDark
        self.marginLine = marginLine
        self.sectionBg = sectionBg
        self.sectionBorder = sectionBorder
        self.sectionText = sectionText
        self.darkSectionBg = darkSectionBg
        self.darkSectionBorder = darkSectionBorder
        self.darkSectionText = darkSectionText
    }
}

public enum AccentThemes {
    public static let all: [AccentThemeConfig] = [
        AccentThemeConfig(
            id: "magenta",
            name: "Малиновый",
            primary: Color(hex: 0xD83A88),
            primaryDark: Color(hex: 0x580C35),
            marginLine: Color(hex: 0xF4A5C0),
            sectionBg: Color(hex: 0xFDF0F5),
            sectionBorder: Color(hex: 0xF4C9DB),
            sectionText: Color(hex: 0x70133C),
            darkSectionBg: Color(hex: 0x2A1627),
            darkSectionBorder: Color(hex: 0x4D2044),
            darkSectionText: Color(hex: 0xF472B6)
        ),
        AccentThemeConfig(
            id: "purple",
            name: "Фиолетовый",
            primary: Color(hex: 0x8B5CF6),
            primaryDark: Color(hex: 0x3B0764),
            marginLine: Color(hex: 0xC4B5FD),
            sectionBg: Color(hex: 0xF5F3FF),
            sectionBorder: Color(hex: 0xDDD6FE),
            sectionText: Color(hex: 0x5B21B6),
            darkSectionBg: Color(hex: 0x231838),
            darkSectionBorder: Color(hex: 0x4A2B7E),
            darkSectionText: Color(hex: 0xC4B5FD)
        ),
        AccentThemeConfig(
            id: "blue",
            name: "Океан",
            primary: Color(hex: 0x0284C7),
            primaryDark: Color(hex: 0x0C4A6E),
            marginLine: Color(hex: 0x7DD3FC),
            sectionBg: Color(hex: 0xF0F9FF),
            sectionBorder: Color(hex: 0xBAE6FD),
            sectionText: Color(hex: 0x0369A1),
            darkSectionBg: Color(hex: 0x132438),
            darkSectionBorder: Color(hex: 0x1C4A73),
            darkSectionText: Color(hex: 0x7DD3FC)
        ),
        AccentThemeConfig(
            id: "emerald",
            name: "Изумруд",
            primary: Color(hex: 0x10B981),
            primaryDark: Color(hex: 0x064E3B),
            marginLine: Color(hex: 0x6EE7B7),
            sectionBg: Color(hex: 0xECFDF5),
            sectionBorder: Color(hex: 0xA7F3D0),
            sectionText: Color(hex: 0x047857),
            darkSectionBg: Color(hex: 0x122820),
            darkSectionBorder: Color(hex: 0x1C5440),
            darkSectionText: Color(hex: 0x6EE7B7)
        ),
        AccentThemeConfig(
            id: "amber",
            name: "Янтарь",
            primary: Color(hex: 0xF59E0B),
            primaryDark: Color(hex: 0x78350F),
            marginLine: Color(hex: 0xFCD34D),
            sectionBg: Color(hex: 0xFFFBEB),
            sectionBorder: Color(hex: 0xFDE68A),
            sectionText: Color(hex: 0xB45309),
            darkSectionBg: Color(hex: 0x2D2314),
            darkSectionBorder: Color(hex: 0x5C431B),
            darkSectionText: Color(hex: 0xFCD34D)
        ),
        AccentThemeConfig(
            id: "crimson",
            name: "Рубин",
            primary: Color(hex: 0xEF4444),
            primaryDark: Color(hex: 0x7F1D1D),
            marginLine: Color(hex: 0xFCA5A5),
            sectionBg: Color(hex: 0xFEF2F2),
            sectionBorder: Color(hex: 0xFECACA),
            sectionText: Color(hex: 0xB91C1C),
            darkSectionBg: Color(hex: 0x2D181C),
            darkSectionBorder: Color(hex: 0x5C222A),
            darkSectionText: Color(hex: 0xFCA5A5)
        ),
        AccentThemeConfig(
            id: "slate",
            name: "Графит",
            primary: Color(hex: 0x475569),
            primaryDark: Color(hex: 0x0F172A),
            marginLine: Color(hex: 0xCBD5E1),
            sectionBg: Color(hex: 0xF8FAFC),
            sectionBorder: Color(hex: 0xCBD5E1),
            sectionText: Color(hex: 0x334155),
            darkSectionBg: Color(hex: 0x1C2230),
            darkSectionBorder: Color(hex: 0x344159),
            darkSectionText: Color(hex: 0xCBD5E1)
        ),
        AccentThemeConfig(
            id: "indigo",
            name: "Индиго",
            primary: Color(hex: 0x6366F1),
            primaryDark: Color(hex: 0x312E81),
            marginLine: Color(hex: 0xA5B4FC),
            sectionBg: Color(hex: 0xEEF2FF),
            sectionBorder: Color(hex: 0xC7D2FE),
            sectionText: Color(hex: 0x3730A3),
            darkSectionBg: Color(hex: 0x1E1F3D),
            darkSectionBorder: Color(hex: 0x373B75),
            darkSectionText: Color(hex: 0xA5B4FC)
        ),
        AccentThemeConfig(
            id: "teal",
            name: "Бирюзовый",
            primary: Color(hex: 0x0D9488),
            primaryDark: Color(hex: 0x134E4A),
            marginLine: Color(hex: 0x5EEAD4),
            sectionBg: Color(hex: 0xF0FDFA),
            sectionBorder: Color(hex: 0x99F6E4),
            sectionText: Color(hex: 0x115E59),
            darkSectionBg: Color(hex: 0x132B29),
            darkSectionBorder: Color(hex: 0x1E5954),
            darkSectionText: Color(hex: 0x5EEAD4)
        ),
        AccentThemeConfig(
            id: "rose_gold",
            name: "Пыльная роза",
            primary: Color(hex: 0xF43F5E),
            primaryDark: Color(hex: 0x881337),
            marginLine: Color(hex: 0xFDA4AF),
            sectionBg: Color(hex: 0xFFF1F2),
            sectionBorder: Color(hex: 0xFECDD3),
            sectionText: Color(hex: 0x9F1239),
            darkSectionBg: Color(hex: 0x30161D),
            darkSectionBorder: Color(hex: 0x5C2331),
            darkSectionText: Color(hex: 0xFDA4AF)
        ),
        AccentThemeConfig(
            id: "coral",
            name: "Коралл",
            primary: Color(hex: 0xEA580C),
            primaryDark: Color(hex: 0x7C2D12),
            marginLine: Color(hex: 0xFDBA74),
            sectionBg: Color(hex: 0xFFF7ED),
            sectionBorder: Color(hex: 0xFED7AA),
            sectionText: Color(hex: 0x9A3412),
            darkSectionBg: Color(hex: 0x2F1E14),
            darkSectionBorder: Color(hex: 0x5E341F),
            darkSectionText: Color(hex: 0xFDBA74)
        ),
        AccentThemeConfig(
            id: "mint",
            name: "Мята",
            primary: Color(hex: 0x14B8A6),
            primaryDark: Color(hex: 0x115E59),
            marginLine: Color(hex: 0x5EEAD4),
            sectionBg: Color(hex: 0xF0FDFA),
            sectionBorder: Color(hex: 0x99F6E4),
            sectionText: Color(hex: 0x115E59),
            darkSectionBg: Color(hex: 0x132B29),
            darkSectionBorder: Color(hex: 0x1B5650),
            darkSectionText: Color(hex: 0x5EEAD4)
        ),
        AccentThemeConfig(
            id: "lavender",
            name: "Лаванда",
            primary: Color(hex: 0xA78BFA),
            primaryDark: Color(hex: 0x581C87),
            marginLine: Color(hex: 0xD8B4FE),
            sectionBg: Color(hex: 0xFAF5FF),
            sectionBorder: Color(hex: 0xE9D5FF),
            sectionText: Color(hex: 0x6B21A8),
            darkSectionBg: Color(hex: 0x261536),
            darkSectionBorder: Color(hex: 0x4C1D70),
            darkSectionText: Color(hex: 0xD8B4FE)
        )
    ]
}

@Observable
public final class MiodiThemeManager {
    public static let shared = MiodiThemeManager()

    public var activeAccentIndex: Int {
        didSet {
            UserDefaults.standard.set(activeAccentIndex, forKey: "miodi_accent_index")
        }
    }

    public var isDarkThemeOverride: Bool? {
        didSet {
            if let val = isDarkThemeOverride {
                UserDefaults.standard.set(val, forKey: "miodi_dark_theme")
            } else {
                UserDefaults.standard.removeObject(forKey: "miodi_dark_theme")
            }
        }
    }

    public var currentAccent: AccentThemeConfig {
        guard activeAccentIndex >= 0 && activeAccentIndex < AccentThemes.all.count else {
            return AccentThemes.all[0]
        }
        return AccentThemes.all[activeAccentIndex]
    }

    public init() {
        let savedIndex = UserDefaults.standard.integer(forKey: "miodi_accent_index")
        self.activeAccentIndex = (savedIndex >= 0 && savedIndex < AccentThemes.all.count) ? savedIndex : 0
        if UserDefaults.standard.object(forKey: "miodi_dark_theme") != nil {
            self.isDarkThemeOverride = UserDefaults.standard.bool(forKey: "miodi_dark_theme")
        } else {
            self.isDarkThemeOverride = nil
        }
    }

    public func sectionBackground(isDark: Bool) -> Color {
        isDark ? currentAccent.darkSectionBg : currentAccent.sectionBg
    }

    public func sectionBorder(isDark: Bool) -> Color {
        isDark ? currentAccent.darkSectionBorder : currentAccent.sectionBorder
    }

    public func sectionText(isDark: Bool) -> Color {
        isDark ? currentAccent.darkSectionText : currentAccent.sectionText
    }

    public func marginLine(isDark: Bool) -> Color {
        isDark ? currentAccent.darkSectionText.opacity(0.35) : currentAccent.marginLine
    }

    public func paperBackground(isDark: Bool) -> Color {
        isDark ? MiodiStaticColors.darkPaperBg : MiodiStaticColors.paperLightBg
    }

    public func ruledLine(isDark: Bool) -> Color {
        isDark ? MiodiStaticColors.darkRuledLine : MiodiStaticColors.ruledLineColor
    }
}
