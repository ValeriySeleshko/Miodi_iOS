//
//  DiaryRichText.swift
//  Plan4U_iOS
//
//  Rich-text formatting engine and spans serialization matching Android DiaryRichText.kt.
//

import SwiftUI

public enum DiaryFontFamily: String, CaseIterable, Identifiable, Sendable {
    case ptSerif = "pt_serif"
    case caveat = "caveat"
    case comfortaa = "comfortaa"
    case roboto = "roboto"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ptSerif: return "PT Serif (Книжный)"
        case .caveat: return "Caveat (От руки)"
        case .comfortaa: return "Comfortaa (Округлый)"
        case .roboto: return "Roboto (Современный)"
        }
    }

    public var design: Font.Design {
        switch self {
        case .ptSerif: return .serif
        case .caveat: return .serif // or handwritten styling
        case .comfortaa: return .rounded
        case .roboto: return .default
        }
    }

    public var isHandwritten: Bool {
        self == .caveat
    }
}

public struct DiaryStyleSpan: Codable, Equatable, Hashable, Sendable {
    public var start: Int
    public var end: Int
    public var bold: Bool
    public var underline: Bool
    public var strikethrough: Bool
    public var colorHex: String?

    enum CodingKeys: String, CodingKey {
        case start = "s"
        case end = "e"
        case bold = "b"
        case underline = "u"
        case strikethrough = "st"
        case colorHex = "c"
    }

    public init(
        start: Int,
        end: Int,
        bold: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        colorHex: String? = nil
    ) {
        self.start = start
        self.end = end
        self.bold = bold
        self.underline = underline
        self.strikethrough = strikethrough
        self.colorHex = colorHex
    }

    public var isPlain: Bool {
        !bold && !underline && !strikethrough && (colorHex == nil || colorHex?.trimmingCharacters(in: .whitespaces).isEmpty == true)
    }
}

public struct DiaryCharStyle: Equatable, Sendable {
    public var bold: Bool = false
    public var underline: Bool = false
    public var strikethrough: Bool = false
    public var colorHex: String? = nil

    public init(
        bold: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        colorHex: String? = nil
    ) {
        self.bold = bold
        self.underline = underline
        self.strikethrough = strikethrough
        self.colorHex = colorHex
    }

    public var isPlain: Bool {
        !bold && !underline && !strikethrough && (colorHex == nil || colorHex?.trimmingCharacters(in: .whitespaces).isEmpty == true)
    }
}

public struct DiaryTextColorOption: Identifiable, Sendable {
    public var id: String { hex ?? "default" }
    public let hex: String?
    public let lightColor: Color
    public let darkColor: Color
    public let name: String

    public init(hex: String?, lightColor: Color, darkColor: Color, name: String) {
        self.hex = hex
        self.lightColor = lightColor
        self.darkColor = darkColor
        self.name = name
    }
}

public enum DiaryRichTextEngine {

    public static let colorPalette: [DiaryTextColorOption] = [
        DiaryTextColorOption(
            hex: nil,
            lightColor: Color(hex: 0x2D231A),
            darkColor: Color(hex: 0xEAE2D6),
            name: "Чернила"
        ),
        DiaryTextColorOption(
            hex: "#9333EA",
            lightColor: Color(hex: 0x9333EA),
            darkColor: Color(hex: 0xC084FC),
            name: "Маджента"
        ),
        DiaryTextColorOption(
            hex: "#EF4444",
            lightColor: Color(hex: 0xDC2626),
            darkColor: Color(hex: 0xF87171),
            name: "Красный"
        ),
        DiaryTextColorOption(
            hex: "#EC4899",
            lightColor: Color(hex: 0xDB2777),
            darkColor: Color(hex: 0xF472B6),
            name: "Розовый"
        ),
        DiaryTextColorOption(
            hex: "#F97316",
            lightColor: Color(hex: 0xEA580C),
            darkColor: Color(hex: 0xFB923C),
            name: "Оранжевый"
        ),
        DiaryTextColorOption(
            hex: "#B45309",
            lightColor: Color(hex: 0xB45309),
            darkColor: Color(hex: 0xFBBF24),
            name: "Янтарный"
        ),
        DiaryTextColorOption(
            hex: "#10B981",
            lightColor: Color(hex: 0x059669),
            darkColor: Color(hex: 0x34D399),
            name: "Изумрудный"
        ),
        DiaryTextColorOption(
            hex: "#0D9488",
            lightColor: Color(hex: 0x0D9488),
            darkColor: Color(hex: 0x2DD4BF),
            name: "Морской"
        ),
        DiaryTextColorOption(
            hex: "#2563EB",
            lightColor: Color(hex: 0x2563EB),
            darkColor: Color(hex: 0x60A5FA),
            name: "Королевский синий"
        ),
        DiaryTextColorOption(
            hex: "#4F46E5",
            lightColor: Color(hex: 0x4F46E5),
            darkColor: Color(hex: 0x818CF8),
            name: "Индиго"
        )
    ]

    public static func resolveColor(hex: String?, defaultColor: Color, isDark: Bool) -> Color {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else {
            return defaultColor
        }
        if let match = colorPalette.first(where: { $0.hex?.caseInsensitiveCompare(hex) == .orderedSame }) {
            return isDark ? match.darkColor : match.lightColor
        }
        return Color(hexString: hex)
    }

    public static func parseSpans(from json: String?, maxTextLen: Int = Int.max) -> [DiaryStyleSpan] {
        guard let json = json, !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = json.data(using: .utf8) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode([DiaryStyleSpan].self, from: data)
            return decoded.compactMap { span in
                guard span.start >= 0, span.end > span.start else { return nil }
                let clampedStart = min(span.start, maxTextLen)
                let clampedEnd = min(span.end, maxTextLen)
                guard clampedEnd > clampedStart else { return nil }
                let cleaned = DiaryStyleSpan(
                    start: clampedStart,
                    end: clampedEnd,
                    bold: span.bold,
                    underline: span.underline,
                    strikethrough: span.strikethrough,
                    colorHex: span.colorHex?.trimmingCharacters(in: .whitespaces).isEmpty == true ? nil : span.colorHex
                )
                return cleaned.isPlain ? nil : cleaned
            }
        } catch {
            return []
        }
    }

    public static func serializeSpans(_ spans: [DiaryStyleSpan]) -> String? {
        let valid = spans.filter { $0.end > $0.start && !$0.isPlain }
        guard !valid.isEmpty else { return nil }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(valid)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    public static func buildAttributedString(
        text: String,
        spans: [DiaryStyleSpan],
        isDark: Bool,
        fontSize: CGFloat = 16.0,
        fontFamily: DiaryFontFamily = .ptSerif,
        defaultColor: Color? = nil
    ) -> AttributedString {
        let baseColor = defaultColor ?? (isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))
        var attributed = AttributedString(text)

        // Base font styling
        let baseFont: Font
        switch fontFamily {
        case .ptSerif:
            baseFont = .system(size: fontSize, weight: .regular, design: .serif)
        case .caveat:
            // Cursive / handwritten feel
            baseFont = .system(size: fontSize + 1.0, weight: .regular, design: .serif).italic()
        case .comfortaa:
            baseFont = .system(size: fontSize, weight: .regular, design: .rounded)
        case .roboto:
            baseFont = .system(size: fontSize, weight: .regular, design: .default)
        }

        attributed.font = baseFont
        attributed.foregroundColor = baseColor

        guard !text.isEmpty, !spans.isEmpty else { return attributed }

        let count = text.count
        for span in spans {
            let clampedStart = max(0, min(span.start, count))
            let clampedEnd = max(clampedStart, min(span.end, count))
            guard clampedEnd > clampedStart else { continue }

            let charView = attributed.characters
            guard let startIdx = charView.index(charView.startIndex, offsetBy: clampedStart, limitedBy: charView.endIndex),
                  let endIdx = charView.index(charView.startIndex, offsetBy: clampedEnd, limitedBy: charView.endIndex) else {
                continue
            }

            let sliceRange = startIdx..<endIdx

            if span.bold {
                attributed[sliceRange].font = .system(
                    size: fontSize,
                    weight: .bold,
                    design: fontFamily.design
                )
            }
            if span.underline {
                attributed[sliceRange].underlineStyle = .single
            }
            if span.strikethrough {
                attributed[sliceRange].strikethroughStyle = .single
            }
            if let hex = span.colorHex {
                let resolved = resolveColor(hex: hex, defaultColor: baseColor, isDark: isDark)
                attributed[sliceRange].foregroundColor = resolved
            }
        }

        return attributed
    }

    // MARK: - Formatting Modifications

    public static func toggleBold(
        textLength: Int,
        spans: [DiaryStyleSpan],
        start: Int,
        end: Int
    ) -> [DiaryStyleSpan] {
        guard textLength > 0, end > start else { return spans }
        var styles = toCharStyles(textLength: textLength, spans: spans)
        let s = max(0, min(start, textLength))
        let e = max(s, min(end, textLength))

        let allBold = (s..<e).allSatisfy { styles[$0].bold }
        let newBold = !allBold
        for i in s..<e {
            styles[i].bold = newBold
        }
        return fromCharStyles(styles)
    }

    public static func toggleUnderline(
        textLength: Int,
        spans: [DiaryStyleSpan],
        start: Int,
        end: Int
    ) -> [DiaryStyleSpan] {
        guard textLength > 0, end > start else { return spans }
        var styles = toCharStyles(textLength: textLength, spans: spans)
        let s = max(0, min(start, textLength))
        let e = max(s, min(end, textLength))

        let allUnderline = (s..<e).allSatisfy { styles[$0].underline }
        let newUnderline = !allUnderline
        for i in s..<e {
            styles[i].underline = newUnderline
        }
        return fromCharStyles(styles)
    }

    public static func toggleStrikethrough(
        textLength: Int,
        spans: [DiaryStyleSpan],
        start: Int,
        end: Int
    ) -> [DiaryStyleSpan] {
        guard textLength > 0, end > start else { return spans }
        var styles = toCharStyles(textLength: textLength, spans: spans)
        let s = max(0, min(start, textLength))
        let e = max(s, min(end, textLength))

        let allStrike = (s..<e).allSatisfy { styles[$0].strikethrough }
        let newStrike = !allStrike
        for i in s..<e {
            styles[i].strikethrough = newStrike
        }
        return fromCharStyles(styles)
    }

    public static func applyColor(
        textLength: Int,
        spans: [DiaryStyleSpan],
        start: Int,
        end: Int,
        colorHex: String?
    ) -> [DiaryStyleSpan] {
        guard textLength > 0, end > start else { return spans }
        var styles = toCharStyles(textLength: textLength, spans: spans)
        let s = max(0, min(start, textLength))
        let e = max(s, min(end, textLength))
        for i in s..<e {
            styles[i].colorHex = colorHex
        }
        return fromCharStyles(styles)
    }

    public static func clearFormatting(
        textLength: Int,
        spans: [DiaryStyleSpan],
        start: Int,
        end: Int
    ) -> [DiaryStyleSpan] {
        guard textLength > 0, end > start else { return spans }
        var styles = toCharStyles(textLength: textLength, spans: spans)
        let s = max(0, min(start, textLength))
        let e = max(s, min(end, textLength))
        for i in s..<e {
            styles[i] = DiaryCharStyle()
        }
        return fromCharStyles(styles)
    }

    public static func getRangeStyle(
        textLength: Int,
        spans: [DiaryStyleSpan],
        start: Int,
        end: Int
    ) -> DiaryCharStyle {
        guard textLength > 0 else { return DiaryCharStyle() }
        let styles = toCharStyles(textLength: textLength, spans: spans)
        let s = max(0, min(start, textLength))
        let e = max(s, min(end, textLength))
        if s >= e {
            let cursor = max(0, min(s, textLength - 1))
            return cursor < styles.count ? styles[cursor] : DiaryCharStyle()
        }
        var bold = true
        var underline = true
        var strikethrough = true
        var colorHex: String? = nil
        var first = true

        for i in s..<e {
            let cur = styles[i]
            bold = bold && cur.bold
            underline = underline && cur.underline
            strikethrough = strikethrough && cur.strikethrough
            if first {
                colorHex = cur.colorHex
                first = false
            } else if colorHex != cur.colorHex {
                colorHex = nil
            }
        }
        return DiaryCharStyle(
            bold: bold,
            underline: underline,
            strikethrough: strikethrough,
            colorHex: colorHex
        )
    }

    private static func toCharStyles(textLength: Int, spans: [DiaryStyleSpan]) -> [DiaryCharStyle] {
        if textLength <= 0 { return [] }
        var arr = Array(repeating: DiaryCharStyle(), count: textLength)
        for sp in spans {
            let s = max(0, min(sp.start, textLength))
            let e = max(s, min(sp.end, textLength))
            for i in s..<e {
                var cur = arr[i]
                cur.bold = cur.bold || sp.bold
                cur.underline = cur.underline || sp.underline
                cur.strikethrough = cur.strikethrough || sp.strikethrough
                cur.colorHex = sp.colorHex ?? cur.colorHex
                arr[i] = cur
            }
        }
        return arr
    }

    private static func fromCharStyles(_ styles: [DiaryCharStyle]) -> [DiaryStyleSpan] {
        guard !styles.isEmpty else { return [] }
        var result: [DiaryStyleSpan] = []
        var runStart = 0
        var runStyle = styles[0]

        for i in 1..<styles.count {
            let s = styles[i]
            if s != runStyle {
                if !runStyle.isPlain {
                    result.append(DiaryStyleSpan(
                        start: runStart,
                        end: i,
                        bold: runStyle.bold,
                        underline: runStyle.underline,
                        strikethrough: runStyle.strikethrough,
                        colorHex: runStyle.colorHex
                    ))
                }
                runStart = i
                runStyle = s
            }
        }
        if !runStyle.isPlain {
            result.append(DiaryStyleSpan(
                start: runStart,
                end: styles.count,
                bold: runStyle.bold,
                underline: runStyle.underline,
                strikethrough: runStyle.strikethrough,
                colorHex: runStyle.colorHex
            ))
        }
        return result
    }

    // MARK: - Word, Phrase, Paragraph Selection Helpers

    public static func findWordRange(in text: String, at index: Int) -> NSRange? {
        guard !text.isEmpty else { return nil }
        let nsText = text as NSString
        let clamped = max(0, min(index, text.count - 1))
        var start = clamped
        while start > 0 && !CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(nsText.character(at: start - 1))!) {
            start -= 1
        }
        var end = clamped
        while end < text.count && !CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(nsText.character(at: end))!) {
            end += 1
        }
        return end > start ? NSRange(location: start, length: end - start) : nil
    }

    public static func wordCount(of text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    public static func charCount(of text: String) -> Int {
        text.count
    }
}
