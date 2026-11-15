//
//  DiaryDoodlesLayer.swift
//  Plan4U_iOS
//
//  16 authentic handwritten margin doodles & stamps matching Android DiaryPaperSurface.kt.
//

import SwiftUI

public enum DiaryDoodleType: String, CaseIterable, Identifiable, Sendable {
    case heartOutline = "heart_outline"
    case heartFilled = "heart_filled"
    case heartHatched = "heart_hatched"
    case star4Pt = "star_4pt"
    case star5PtOutline = "star_5pt_outline"
    case star5PtFilled = "star_5pt_filled"
    case ribbonBow = "ribbon_bow"
    case flower = "flower"
    case catPaw = "cat_paw"
    case cloud = "cloud"
    case crescentMoon = "crescent_moon"
    case butterfly = "butterfly"
    case musicNote = "music_note"
    case clover = "clover"
    case diamond = "diamond"
    case sparkles = "sparkles"
    case coffeeCup = "coffee_cup"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .heartOutline: return "Сердечко"
        case .heartFilled: return "Полное сердце"
        case .heartHatched: return "Штрих-сердце"
        case .star4Pt: return "Искорка 4-луча"
        case .star5PtOutline: return "Звезда контур"
        case .star5PtFilled: return "Звезда заливка"
        case .ribbonBow: return "Бантик"
        case .flower: return "Цветочек"
        case .catPaw: return "Лапка котика"
        case .cloud: return "Облачко"
        case .crescentMoon: return "Полумесяц"
        case .butterfly: return "Бабочка"
        case .musicNote: return "Нота"
        case .clover: return "Клевер"
        case .diamond: return "Кристалл"
        case .sparkles: return "Блестки"
        case .coffeeCup: return "Чашка кофе"
        }
    }

    public static let defaultSelected: Set<String> = [
        "heart_outline", "star_4pt", "cat_paw", "ribbon_bow", "coffee_cup"
    ]
}

public enum DiaryDoodleInks {
    public static let palette: [Color] = [
        Color(hex: 0xDC687A), // Pastel Dusty Rose
        Color(hex: 0xA670BD), // Muted Lavender
        Color(hex: 0x5691BD), // Soft Powder Blue
        Color(hex: 0xC78F32), // Warm Honey Gold
        Color(hex: 0x5EA374), // Pastel Sage Mint
        Color(hex: 0xD4795B), // Soft Terracotta Peach
        Color(hex: 0x3E3125)  // Soft Graphite Espresso
    ]

    public static func ink(for index: Int) -> Color {
        palette[abs(index) % palette.count]
    }
}

// MARK: - Standalone Doodle Icon

public struct DiaryDoodleIconView: View {
    public let type: DiaryDoodleType
    public var size: CGFloat = 24.0
    public var color: Color = Color(hex: 0x9333EA)
    public var strokeWidth: CGFloat = 1.6

    public init(type: DiaryDoodleType, size: CGFloat = 24.0, color: Color = Color(hex: 0x9333EA), strokeWidth: CGFloat = 1.6) {
        self.type = type
        self.size = size
        self.color = color
        self.strokeWidth = strokeWidth
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let cx = canvasSize.width / 2.0
            let cy = canvasSize.height / 2.0
            let r = min(canvasSize.width, canvasSize.height) * 0.42
            DiaryDoodleRenderer.drawDoodle(
                type: type,
                cx: cx,
                cy: cy,
                r: r,
                rotationDeg: 0,
                color: color,
                strokeWidth: strokeWidth,
                in: &context
            )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Doodle Renderer

public enum DiaryDoodleRenderer {

    public static func drawDoodle(
        type: DiaryDoodleType,
        cx: CGFloat,
        cy: CGFloat,
        r: CGFloat,
        rotationDeg: Double,
        color: Color,
        strokeWidth: CGFloat,
        in context: inout GraphicsContext
    ) {
        var localContext = context
        if rotationDeg != 0 {
            localContext.translateBy(x: cx, y: cy)
            localContext.rotate(by: Angle(degrees: rotationDeg))
            localContext.translateBy(x: -cx, y: -cy)
        }

        let strokeStyle = StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        let thinStroke = StrokeStyle(lineWidth: strokeWidth * 0.75, lineCap: .round, lineJoin: .round)

        switch type {
        case .heartOutline:
            let path = heartPath(cx: cx, cy: cy, r: r)
            localContext.stroke(path, with: .color(color), style: strokeStyle)

        case .heartFilled:
            let path = heartPath(cx: cx, cy: cy, r: r * 0.95)
            localContext.fill(path, with: .color(color.opacity(0.85)))
            localContext.stroke(path, with: .color(color), style: strokeStyle)

        case .heartHatched:
            let path = heartPath(cx: cx, cy: cy, r: r)
            localContext.stroke(path, with: .color(color), style: strokeStyle)
            // Hatch lines
            var clipCtx = localContext
            clipCtx.clip(to: path)
            let step = max(r * 0.35, 3.0)
            let half = r * 1.2
            var off = -half
            while off <= half {
                var line = Path()
                line.move(to: CGPoint(x: cx - half + off, y: cy - half))
                line.addLine(to: CGPoint(x: cx + half + off, y: cy + half))
                clipCtx.stroke(line, with: .color(color.opacity(0.8)), style: StrokeStyle(lineWidth: strokeWidth * 0.7, lineCap: .round))
                off += step
            }

        case .star4Pt:
            let path = fourPointStarPath(cx: cx, cy: cy, outerR: r * 1.05, innerR: r * 0.28)
            localContext.fill(path, with: .color(color.opacity(0.75)))
            localContext.stroke(path, with: .color(color), style: thinStroke)
            let dot = Path(ellipseIn: CGRect(x: cx - strokeWidth * 0.8, y: cy - r * 1.25 - strokeWidth * 0.8, width: strokeWidth * 1.6, height: strokeWidth * 1.6))
            localContext.fill(dot, with: .color(color))

        case .star5PtOutline:
            let path = fivePointStarPath(cx: cx, cy: cy, outerR: r, innerR: r * 0.45)
            localContext.stroke(path, with: .color(color), style: strokeStyle)
            let centerDot = Path(ellipseIn: CGRect(x: cx - strokeWidth * 0.75, y: cy - strokeWidth * 0.75, width: strokeWidth * 1.5, height: strokeWidth * 1.5))
            localContext.fill(centerDot, with: .color(color))

        case .star5PtFilled:
            let path = fivePointStarPath(cx: cx, cy: cy, outerR: r * 0.95, innerR: r * 0.44)
            localContext.fill(path, with: .color(color.opacity(0.85)))
            localContext.stroke(path, with: .color(color), style: strokeStyle)

        case .ribbonBow:
            var p = Path()
            // Left loop
            p.move(to: CGPoint(x: cx, y: cy))
            p.addCurve(to: CGPoint(x: cx, y: cy),
                       control1: CGPoint(x: cx - r * 0.95, y: cy - r * 0.75),
                       control2: CGPoint(x: cx - r * 0.95, y: cy + r * 0.55))
            // Right loop
            p.move(to: CGPoint(x: cx, y: cy))
            p.addCurve(to: CGPoint(x: cx, y: cy),
                       control1: CGPoint(x: cx + r * 0.95, y: cy - r * 0.75),
                       control2: CGPoint(x: cx + r * 0.95, y: cy + r * 0.55))
            // Left tail
            p.move(to: CGPoint(x: cx - r * 0.1, y: cy + r * 0.1))
            p.addQuadCurve(to: CGPoint(x: cx - r * 0.65, y: cy + r * 0.95), control: CGPoint(x: cx - r * 0.45, y: cy + r * 0.55))
            // Right tail
            p.move(to: CGPoint(x: cx + r * 0.1, y: cy + r * 0.1))
            p.addQuadCurve(to: CGPoint(x: cx + r * 0.65, y: cy + r * 0.95), control: CGPoint(x: cx + r * 0.45, y: cy + r * 0.55))
            localContext.stroke(p, with: .color(color), style: strokeStyle)
            let knot = Path(ellipseIn: CGRect(x: cx - r * 0.16, y: cy - r * 0.16, width: r * 0.32, height: r * 0.32))
            localContext.fill(knot, with: .color(color))

        case .flower:
            let petalDist = r * 0.48
            let petalRadius = r * 0.34
            for i in 0..<5 {
                let a = Double(i) * 72.0 * .pi / 180.0
                let px = cx + CGFloat(cos(a)) * petalDist
                let py = cy + CGFloat(sin(a)) * petalDist
                let petal = Path(ellipseIn: CGRect(x: px - petalRadius, y: py - petalRadius, width: petalRadius * 2, height: petalRadius * 2))
                localContext.stroke(petal, with: .color(color), style: thinStroke)
            }
            let centerCircle = Path(ellipseIn: CGRect(x: cx - r * 0.22, y: cy - r * 0.22, width: r * 0.44, height: r * 0.44))
            localContext.fill(centerCircle, with: .color(color))

        case .catPaw:
            // Main bottom pad
            let pad = Path(ellipseIn: CGRect(x: cx - r * 0.48, y: cy - r * 0.05, width: r * 0.96, height: r * 0.72))
            localContext.fill(pad, with: .color(color))
            // 4 toe dots
            let toeOffsets = [
                CGPoint(x: -r * 0.52, y: -r * 0.28),
                CGPoint(x: -r * 0.18, y: -r * 0.52),
                CGPoint(x: r * 0.18, y: -r * 0.52),
                CGPoint(x: r * 0.52, y: -r * 0.28)
            ]
            let toeRadius = r * 0.18
            for off in toeOffsets {
                let toe = Path(ellipseIn: CGRect(x: cx + off.x - toeRadius, y: cy + off.y - toeRadius, width: toeRadius * 2, height: toeRadius * 2))
                localContext.fill(toe, with: .color(color))
            }

        case .cloud:
            var p = Path()
            p.move(to: CGPoint(x: cx - r * 0.65, y: cy + r * 0.35))
            p.addLine(to: CGPoint(x: cx + r * 0.65, y: cy + r * 0.35))
            p.addCurve(to: CGPoint(x: cx + r * 0.55, y: cy - r * 0.15),
                       control1: CGPoint(x: cx + r * 1.0, y: cy + r * 0.35),
                       control2: CGPoint(x: cx + r * 1.0, y: cy - r * 0.15))
            p.addCurve(to: CGPoint(x: cx - r * 0.35, y: cy - r * 0.20),
                       control1: CGPoint(x: cx + r * 0.45, y: cy - r * 0.65),
                       control2: CGPoint(x: cx - r * 0.25, y: cy - r * 0.65))
            p.addCurve(to: CGPoint(x: cx - r * 0.65, y: cy + r * 0.35),
                       control1: CGPoint(x: cx - r * 0.95, y: cy - r * 0.25),
                       control2: CGPoint(x: cx - r * 1.0, y: cy + r * 0.35))
            p.closeSubpath()
            localContext.stroke(p, with: .color(color), style: strokeStyle)

        case .crescentMoon:
            var p = Path()
            p.move(to: CGPoint(x: cx + r * 0.25, y: cy - r * 0.85))
            p.addCurve(to: CGPoint(x: cx + r * 0.25, y: cy + r * 0.85),
                       control1: CGPoint(x: cx - r * 0.85, y: cy - r * 0.75),
                       control2: CGPoint(x: cx - r * 0.85, y: cy + r * 0.75))
            p.addCurve(to: CGPoint(x: cx + r * 0.25, y: cy - r * 0.85),
                       control1: CGPoint(x: cx - r * 0.30, y: cy + r * 0.45),
                       control2: CGPoint(x: cx - r * 0.30, y: cy - r * 0.45))
            p.closeSubpath()
            localContext.stroke(p, with: .color(color), style: strokeStyle)

        case .butterfly:
            var p = Path()
            p.move(to: CGPoint(x: cx, y: cy))
            p.addCurve(to: CGPoint(x: cx, y: cy + r * 0.05),
                       control1: CGPoint(x: cx - r * 0.95, y: cy - r * 0.95),
                       control2: CGPoint(x: cx - r * 1.05, y: cy + r * 0.05))
            p.addCurve(to: CGPoint(x: cx, y: cy + r * 0.25),
                       control1: CGPoint(x: cx - r * 0.75, y: cy + r * 0.20),
                       control2: CGPoint(x: cx - r * 0.65, y: cy + r * 0.85))
            p.move(to: CGPoint(x: cx, y: cy))
            p.addCurve(to: CGPoint(x: cx, y: cy + r * 0.05),
                       control1: CGPoint(x: cx + r * 0.95, y: cy - r * 0.95),
                       control2: CGPoint(x: cx + r * 1.05, y: cy + r * 0.05))
            p.addCurve(to: CGPoint(x: cx, y: cy + r * 0.25),
                       control1: CGPoint(x: cx + r * 0.75, y: cy + r * 0.20),
                       control2: CGPoint(x: cx + r * 0.65, y: cy + r * 0.85))
            localContext.stroke(p, with: .color(color), style: strokeStyle)
            var bodyLine = Path()
            bodyLine.move(to: CGPoint(x: cx, y: cy - r * 0.45))
            bodyLine.addLine(to: CGPoint(x: cx, y: cy + r * 0.55))
            localContext.stroke(bodyLine, with: .color(color), style: strokeStyle)

        case .musicNote:
            let noteHead = Path(ellipseIn: CGRect(x: cx - r * 0.55, y: cy + r * 0.15, width: r * 0.62, height: r * 0.46))
            localContext.fill(noteHead, with: .color(color))
            var stem = Path()
            stem.move(to: CGPoint(x: cx + r * 0.04, y: cy + r * 0.35))
            stem.addLine(to: CGPoint(x: cx + r * 0.04, y: cy - r * 0.72))
            stem.addQuadCurve(to: CGPoint(x: cx + r * 0.48, y: cy - r * 0.05), control: CGPoint(x: cx + r * 0.65, y: cy - r * 0.52))
            localContext.stroke(stem, with: .color(color), style: strokeStyle)

        case .clover:
            let leafDist = r * 0.38
            let leafR = r * 0.32
            let dirs = [
                CGPoint(x: 0, y: -leafDist),
                CGPoint(x: leafDist, y: 0),
                CGPoint(x: 0, y: leafDist),
                CGPoint(x: -leafDist, y: 0)
            ]
            for d in dirs {
                let leaf = Path(ellipseIn: CGRect(x: cx + d.x - leafR, y: cy + d.y - leafR, width: leafR * 2, height: leafR * 2))
                localContext.stroke(leaf, with: .color(color), style: thinStroke)
            }
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: cy + r * 0.25))
            stem.addLine(to: CGPoint(x: cx + r * 0.28, y: cy + r * 0.92))
            localContext.stroke(stem, with: .color(color), style: strokeStyle)

        case .diamond:
            var p = Path()
            p.move(to: CGPoint(x: cx, y: cy - r * 0.90))
            p.addLine(to: CGPoint(x: cx + r * 0.65, y: cy))
            p.addLine(to: CGPoint(x: cx, y: cy + r * 0.90))
            p.addLine(to: CGPoint(x: cx - r * 0.65, y: cy))
            p.closeSubpath()
            localContext.stroke(p, with: .color(color), style: strokeStyle)
            var facet = Path()
            facet.move(to: CGPoint(x: cx - r * 0.65, y: cy))
            facet.addLine(to: CGPoint(x: cx + r * 0.65, y: cy))
            localContext.stroke(facet, with: .color(color), style: thinStroke)

        case .sparkles:
            let star1 = fourPointStarPath(cx: cx - r * 0.28, cy: cy - r * 0.22, outerR: r * 0.55, innerR: r * 0.16)
            localContext.fill(star1, with: .color(color))
            let star2 = fourPointStarPath(cx: cx + r * 0.38, cy: cy + r * 0.28, outerR: r * 0.42, innerR: r * 0.13)
            localContext.fill(star2, with: .color(color))
            let dot1 = Path(ellipseIn: CGRect(x: cx + r * 0.35 - strokeWidth, y: cy - r * 0.42 - strokeWidth, width: strokeWidth * 2, height: strokeWidth * 2))
            localContext.fill(dot1, with: .color(color))
            let dot2 = Path(ellipseIn: CGRect(x: cx - r * 0.42 - strokeWidth * 0.85, y: cy + r * 0.45 - strokeWidth * 0.85, width: strokeWidth * 1.7, height: strokeWidth * 1.7))
            localContext.fill(dot2, with: .color(color))

        case .coffeeCup:
            // Cute coffee mug with steam
            var mug = Path()
            // Body
            let mw = r * 0.9
            let mh = r * 0.85
            let mx = cx - mw / 2.0
            let my = cy - mh / 2.0 + r * 0.15
            mug.addRoundedRect(in: CGRect(x: mx, y: my, width: mw, height: mh), cornerSize: CGSize(width: r * 0.25, height: r * 0.25))
            localContext.stroke(mug, with: .color(color), style: strokeStyle)

            // Handle on the right
            var handle = Path()
            handle.move(to: CGPoint(x: mx + mw, y: my + mh * 0.2))
            handle.addQuadCurve(to: CGPoint(x: mx + mw, y: my + mh * 0.8), control: CGPoint(x: mx + mw + r * 0.45, y: my + mh * 0.5))
            localContext.stroke(handle, with: .color(color), style: strokeStyle)

            // Steam curves
            var steam1 = Path()
            steam1.move(to: CGPoint(x: cx - r * 0.2, y: my - r * 0.05))
            steam1.addQuadCurve(to: CGPoint(x: cx - r * 0.2, y: my - r * 0.45), control: CGPoint(x: cx - r * 0.35, y: my - r * 0.25))
            localContext.stroke(steam1, with: .color(color), style: thinStroke)

            var steam2 = Path()
            steam2.move(to: CGPoint(x: cx + r * 0.15, y: my - r * 0.05))
            steam2.addQuadCurve(to: CGPoint(x: cx + r * 0.15, y: my - r * 0.45), control: CGPoint(x: cx + r * 0.3, y: my - r * 0.25))
            localContext.stroke(steam2, with: .color(color), style: thinStroke)
        }
    }

    private static func heartPath(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        var p = Path()
        let topY = cy - r * 0.32
        let bottomY = cy + r * 0.82
        p.move(to: CGPoint(x: cx, y: bottomY))
        p.addCurve(to: CGPoint(x: cx, y: topY),
                   control1: CGPoint(x: cx - r * 1.15, y: cy + r * 0.18),
                   control2: CGPoint(x: cx - r * 0.92, y: cy - r * 0.88))
        p.addCurve(to: CGPoint(x: cx, y: bottomY),
                   control1: CGPoint(x: cx + r * 0.92, y: cy - r * 0.88),
                   control2: CGPoint(x: cx + r * 1.15, y: cy + r * 0.18))
        p.closeSubpath()
        return p
    }

    private static func fourPointStarPath(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy - outerR))
        p.addQuadCurve(to: CGPoint(x: cx + outerR, y: cy), control: CGPoint(x: cx + innerR * 0.35, y: cy - innerR * 0.35))
        p.addQuadCurve(to: CGPoint(x: cx, y: cy + outerR), control: CGPoint(x: cx + innerR * 0.35, y: cy + innerR * 0.35))
        p.addQuadCurve(to: CGPoint(x: cx - outerR, y: cy), control: CGPoint(x: cx - innerR * 0.35, y: cy + innerR * 0.35))
        p.addQuadCurve(to: CGPoint(x: cx, y: cy - outerR), control: CGPoint(x: cx - innerR * 0.35, y: cy - innerR * 0.35))
        p.closeSubpath()
        return p
    }

    private static func fivePointStarPath(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat) -> Path {
        var p = Path()
        let startAngle = -Double.pi / 2.0
        let step = Double.pi / 5.0
        for i in 0..<10 {
            let rad = (i % 2 == 0) ? outerR : innerR
            let a = startAngle + Double(i) * step
            let px = cx + CGFloat(cos(a)) * rad
            let py = cy + CGFloat(sin(a)) * rad
            if i == 0 {
                p.move(to: CGPoint(x: px, y: py))
            } else {
                p.addLine(to: CGPoint(x: px, y: py))
            }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Margin & Background Doodles Layer

public struct DiaryDoodlesLayer: View {
    public var selectedDoodles: Set<String>
    public var seed: Int = 42
    public var isDark: Bool = false
    public var isEmbossingEnabled: Bool = true
    public var isMarginOnly: Bool = true

    public init(
        selectedDoodles: Set<String>,
        seed: Int = 42,
        isDark: Bool = false,
        isEmbossingEnabled: Bool = true,
        isMarginOnly: Bool = true
    ) {
        self.selectedDoodles = selectedDoodles
        self.seed = seed
        self.isDark = isDark
        self.isEmbossingEnabled = isEmbossingEnabled
        self.isMarginOnly = isMarginOnly
    }

    public var body: some View {
        Canvas { context, size in
            let activeTypes = selectedDoodles.compactMap { DiaryDoodleType(rawValue: $0) }
            guard !activeTypes.isEmpty, size.width > 20, size.height > 20 else { return }

            if isMarginOnly {
                // Draw delicate margin doodles along left & right margins
                let count = max(3, Int(size.height / 140.0))
                for i in 0..<count {
                    let sideLeft = (i % 2 == 0)
                    let cx: CGFloat = sideLeft ? 24.0 : size.width - 24.0
                    let cy: CGFloat = CGFloat(i) * (size.height / CGFloat(count)) + 60.0
                    let type = activeTypes[(i + seed) % activeTypes.count]
                    let ink = DiaryDoodleInks.ink(for: i + seed)
                    let rot = Double(((i * 37 + seed) % 40) - 20)
                    let radius: CGFloat = 11.0

                    if isEmbossingEnabled {
                        // Subtle embossed shadow/bevel highlight
                        let bevelColor = isDark ? Color.white.opacity(0.06) : Color(hex: 0xFFFBF2).opacity(0.4)
                        DiaryDoodleRenderer.drawDoodle(
                            type: type,
                            cx: cx + 0.8,
                            cy: cy + 0.8,
                            r: radius,
                            rotationDeg: rot,
                            color: bevelColor,
                            strokeWidth: 1.3,
                            in: &context
                        )
                    }

                    DiaryDoodleRenderer.drawDoodle(
                        type: type,
                        cx: cx,
                        cy: cy,
                        r: radius,
                        rotationDeg: rot,
                        color: ink.opacity(isDark ? 0.32 : 0.38),
                        strokeWidth: 1.3,
                        in: &context
                    )
                }
            } else {
                // Full organic sheet grid matching Android
                let cols = 4
                let rows = 9
                let cellW = size.width / CGFloat(cols)
                let cellH = size.height / CGFloat(rows)

                for c in 0..<cols {
                    for r in 0..<rows {
                        let idx = c * rows + r
                        let hashVal = (idx * 7919 + seed * 1337)
                        if (hashVal % 100) > 85 { continue }

                        let jitterX = CGFloat((hashVal % 65) + 15) / 100.0 * cellW
                        let jitterY = CGFloat(((hashVal / 65) % 65) + 15) / 100.0 * cellH
                        let cx = CGFloat(c) * cellW + jitterX
                        let cy = CGFloat(r) * cellH + jitterY
                        let rot = Double((hashVal % 44) - 22)
                        let radius = CGFloat(8.5 + Double(hashVal % 5))
                        let type = activeTypes[abs(hashVal) % activeTypes.count]
                        let ink = DiaryDoodleInks.ink(for: hashVal)

                        if isEmbossingEnabled {
                            let bevelColor = isDark ? Color.white.opacity(0.05) : Color(hex: 0xFFFBF2).opacity(0.35)
                            DiaryDoodleRenderer.drawDoodle(
                                type: type,
                                cx: cx + 0.8,
                                cy: cy + 0.8,
                                r: radius,
                                rotationDeg: rot,
                                color: bevelColor,
                                strokeWidth: 1.25,
                                in: &context
                            )
                        }

                        DiaryDoodleRenderer.drawDoodle(
                            type: type,
                            cx: cx,
                            cy: cy,
                            r: radius,
                            rotationDeg: rot,
                            color: ink.opacity(isDark ? 0.22 : 0.28),
                            strokeWidth: 1.25,
                            in: &context
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Interactive Doodle Selector Grid

public struct DiaryDoodleSelectorModalView: View {
    @Binding public var selectedIds: Set<String>
    public var isDark: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme

    public init(selectedIds: Binding<Set<String>>, isDark: Bool) {
        self._selectedIds = selectedIds
        self.isDark = isDark
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Дудлы на полях")
                                .font(.headline.bold())
                                .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))
                            Spacer()
                            Text("👑 PRO")
                                .font(.caption.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(theme.currentAccent.primary.opacity(0.15))
                                .foregroundStyle(theme.currentAccent.primary)
                                .clipShape(Capsule())
                        }

                        Text("Выберите любимые рисунки и штампы, которые будут украшать поля и страницы вашего личного дневника.")
                            .font(.footnote)
                            .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF8F4EB))
                    )

                    // Quick presets
                    HStack(spacing: 8) {
                        Button("Все") {
                            selectedIds = Set(DiaryDoodleType.allCases.map { $0.rawValue })
                            MiodiHapticFeedback.lightClick()
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.currentAccent.primary)

                        Button("По умолчанию") {
                            selectedIds = DiaryDoodleType.defaultSelected
                            MiodiHapticFeedback.lightClick()
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.currentAccent.primary)

                        Button("Очистить") {
                            selectedIds.removeAll()
                            MiodiHapticFeedback.lightClick()
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }

                    // Grid of 17 doodles
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 75), spacing: 12)], spacing: 12) {
                        ForEach(DiaryDoodleType.allCases) { doodle in
                            let isSelected = selectedIds.contains(doodle.rawValue)
                            Button {
                                if isSelected {
                                    selectedIds.remove(doodle.rawValue)
                                } else {
                                    selectedIds.insert(doodle.rawValue)
                                }
                                MiodiHapticFeedback.selection()
                            } label: {
                                VStack(spacing: 6) {
                                    DiaryDoodleIconView(
                                        type: doodle,
                                        size: 32,
                                        color: isSelected ? theme.currentAccent.primary : (isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                                    )
                                    .padding(.top, 4)

                                    Text(doodle.displayName)
                                        .font(.system(size: 10, weight: .medium))
                                        .lineLimit(1)
                                        .foregroundStyle(isSelected ? theme.currentAccent.primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 72)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? theme.currentAccent.primary.opacity(isDark ? 0.22 : 0.12) : (isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF4EFE6)))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? theme.currentAccent.primary : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(16)
            }
            .background(isDark ? Color(hex: 0x141720) : Color.white)
            .navigationTitle("Настройка полей дневника")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .font(.body.bold())
                }
            }
        }
    }
}
