//
//  NotebookCanvasView.swift
//  Plan4U_iOS
//
//  Authentic ruled/gridded/dotted/musical notebook paper rendered via SwiftUI Canvas / Metal.
//  100% pixel-and-physics match with Android NotebookCanvas.kt (560 lines).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// All 7 paper ruling patterns + blank paper, matching Android NotebookCanvas.kt
public enum NotebookPattern: String, CaseIterable, Sendable {
    case lines
    case grid
    case dots
    case music
    case englishGrid = "english_grid"
    case slantLines = "slant_lines"
    case millimeter
    case blank

    public init(string: String) {
        let lower = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch lower {
        case "lines": self = .lines
        case "grid": self = .grid
        case "dots": self = .dots
        case "music": self = .music
        case "english_grid", "englishgrid", "seyes": self = .englishGrid
        case "slant_lines", "slantlines", "slant": self = .slantLines
        case "millimeter", "milli": self = .millimeter
        case "blank": self = .blank
        default: self = .lines
        }
    }
}

public struct NotebookCanvasView: View {
    public var patternType: NotebookPattern = .lines
    public var patternSize: CGFloat = 32.0
    public var marginLineX: CGFloat = 50.0
    public var scrollY: CGFloat = 0.0
    public var agingDays: Double = 0.0
    public var isDarkTheme: Bool = false
    public var backgroundColor: Color? = nil
    public var lineColor: Color? = nil
    public var marginLineColor: Color? = nil
    public var drawBackground: Bool = true

    @Environment(MiodiThemeManager.self) private var theme

    public init(
        patternType: NotebookPattern = .lines,
        patternSize: CGFloat = 32.0,
        marginLineX: CGFloat = 50.0,
        scrollY: CGFloat = 0.0,
        agingDays: Double = 0.0,
        isDarkTheme: Bool = false,
        backgroundColor: Color? = nil,
        lineColor: Color? = nil,
        marginLineColor: Color? = nil,
        drawBackground: Bool = true
    ) {
        self.patternType = patternType
        self.patternSize = patternSize
        self.marginLineX = marginLineX
        self.scrollY = scrollY
        self.agingDays = agingDays
        self.isDarkTheme = isDarkTheme
        self.backgroundColor = backgroundColor
        self.lineColor = lineColor
        self.marginLineColor = marginLineColor
        self.drawBackground = drawBackground
    }

    /// String pattern initializer for seamless parity with Android string tokens
    public init(
        patternTypeString: String,
        patternSize: CGFloat = 32.0,
        marginLineX: CGFloat = 50.0,
        scrollY: CGFloat = 0.0,
        agingDays: Double = 0.0,
        isDarkTheme: Bool = false,
        backgroundColor: Color? = nil,
        lineColor: Color? = nil,
        marginLineColor: Color? = nil,
        drawBackground: Bool = true
    ) {
        self.init(
            patternType: NotebookPattern(string: patternTypeString),
            patternSize: patternSize,
            marginLineX: marginLineX,
            scrollY: scrollY,
            agingDays: agingDays,
            isDarkTheme: isDarkTheme,
            backgroundColor: backgroundColor,
            lineColor: lineColor,
            marginLineColor: marginLineColor,
            drawBackground: drawBackground
        )
    }

    public var body: some View {
        Canvas { context, size in
            // Smooth continuous aging calculation:
            // f(days) = days / (days + 85.0), smoothly bounded in 0.0...1.0
            // Day 0: 0.00
            // Day 1: 0.012 (imperceptible warmth, less than 1.5%)
            // Day 2: 0.023
            // Day 7: 0.076
            // Day 30: 0.26
            // Day 90: 0.51
            // Day 180: 0.68
            // Day 365: 0.81
            let days = CGFloat(agingDays)
            let agingFactor: CGFloat = days > 0 ? min(max(days / (days + 85.0), 0.0), 1.0) : 0.0

            let baseBg = backgroundColor ?? (isDarkTheme ? Color(hex: 0x141720) : Color(hex: 0xFFFFFF))
            let maxAgedBg = !isDarkTheme ? Color(hex: 0xE2D1AC) : Color(hex: 0x281E15)
            let effectiveBg = agingFactor > 0 ? lerpColor(baseBg, maxAgedBg, fraction: agingFactor) : baseBg

            // 1. Draw paper background
            if drawBackground {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(effectiveBg))
            }

            // Fresh & aged line color interpolation
            let defaultFreshLine: Color
            if let customLine = lineColor {
                defaultFreshLine = customLine
            } else {
                let comps = rgbaComponents(of: baseBg)
                if isDarkTheme {
                    defaultFreshLine = Color(
                        .sRGB,
                        red: min(max(comps.r + 0.18, 0.0), 1.0),
                        green: min(max(comps.g + 0.18, 0.0), 1.0),
                        blue: min(max(comps.b + 0.18, 0.0), 1.0),
                        opacity: 1.0
                    )
                } else {
                    defaultFreshLine = Color(
                        .sRGB,
                        red: min(max(comps.r * 0.75, 0.0), 1.0),
                        green: min(max(comps.g * 0.75, 0.0), 1.0),
                        blue: min(max(comps.b * 0.75, 0.0), 1.0),
                        opacity: 1.0
                    )
                }
            }

            let maxAgedLine = !isDarkTheme ? Color(hex: 0x8F7654).opacity(0.45) : Color(hex: 0x856E4F).opacity(0.55)
            let lineCol = agingFactor > 0 ? lerpColor(defaultFreshLine, maxAgedLine, fraction: agingFactor) : defaultFreshLine

            let defaultFreshMargin = marginLineColor ?? (isDarkTheme ? Color(hex: 0x4A3449) : Color(hex: 0xF4A5C0))
            let maxAgedMargin = !isDarkTheme ? Color(hex: 0x884353).opacity(0.80) : Color(hex: 0x9E6377).opacity(0.85)
            let marginCol = agingFactor > 0 ? lerpColor(defaultFreshMargin, maxAgedMargin, fraction: agingFactor) : defaultFreshMargin

            let step = max(patternSize, 2.0)
            let marginPx = max(marginLineX, 0.0)

            // 2. Draw rulings for all 7 authentic patterns + blank
            switch patternType {
            case .lines:
                drawRuledLines(context: context, size: size, step: step, lineCol: lineCol)

            case .grid:
                // Horizontal lines shifting with scrollY
                drawRuledLines(context: context, size: size, step: step, lineCol: lineCol)
                // Vertical grid lines starting from marginLineX
                var currentX = marginPx + step
                while currentX < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: currentX, y: 0))
                    path.addLine(to: CGPoint(x: currentX, y: size.height))
                    context.stroke(path, with: .color(lineCol), lineWidth: 1.0)
                    currentX += step
                }

            case .dots:
                // Dot matrix shifting with scrollY
                let dotRadius = min(max(step * 0.045, 1.1), 2.2)
                let phaseY = ((-scrollY).truncatingRemainder(dividingBy: step)).let { $0 > 0 ? $0 - step : $0 }
                var currentY = phaseY + step
                while currentY < size.height + dotRadius + step {
                    if currentY >= -dotRadius && currentY <= size.height + dotRadius {
                        var currentX = marginPx + step
                        while currentX < size.width {
                            let rect = CGRect(
                                x: currentX - dotRadius,
                                y: currentY - dotRadius,
                                width: dotRadius * 2,
                                height: dotRadius * 2
                            )
                            context.fill(Path(ellipseIn: rect), with: .color(lineCol))
                            currentX += step
                        }
                    }
                    currentY += step
                }

            case .music:
                // Authentic 5-line musical staves (нотный стан) shifting with scrollY
                let lineGap = step * 0.12
                let staffHeight = 4.0 * lineGap
                let interStaffGap = step * 0.75
                let period = staffHeight + interStaffGap
                let baseStaffTop = step * 0.75

                let phaseStaff = (((baseStaffTop - scrollY).truncatingRemainder(dividingBy: period)) + period).truncatingRemainder(dividingBy: period)
                var staffTop = phaseStaff - period
                while staffTop < size.height + period {
                    if staffTop + staffHeight >= 0 {
                        // 5 horizontal staff lines
                        for i in 0...4 {
                            let y = staffTop + CGFloat(i) * lineGap
                            if y >= -1.0 && y <= size.height + 1.0 {
                                var path = Path()
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                                context.stroke(path, with: .color(lineCol), lineWidth: 1.0)
                            }
                        }
                        // Musical vertical barline connecting the 5 lines at margin
                        let barTop = max(staffTop, 0)
                        let barBottom = min(staffTop + staffHeight, size.height)
                        if barBottom > barTop {
                            var barPath = Path()
                            barPath.move(to: CGPoint(x: marginPx, y: barTop))
                            barPath.addLine(to: CGPoint(x: marginPx, y: barBottom))
                            context.stroke(barPath, with: .color(lineCol), lineWidth: 1.5)
                        }
                    }
                    staffTop += period
                }

            case .englishGrid:
                // French/English Seyès ruling (Grands Carreaux) shifting with scrollY
                let seyesMajorCol = lineCol
                let seyesMinorCol = lineCol.opacity(0.55)
                let seyesVertCol = lineCol.opacity(0.70)

                let subStep = max(step / 4.0, 1.0)
                let phaseY = ((-scrollY).truncatingRemainder(dividingBy: step)).let { $0 > 0 ? $0 - step : $0 }
                var currentY = phaseY - step
                while currentY < size.height + subStep {
                    if currentY >= 0 && currentY <= size.height {
                        let absY = currentY + scrollY
                        let index = Int((absY / subStep).rounded())
                        let isMajor = (index % 4 == 0)
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: currentY))
                        path.addLine(to: CGPoint(x: size.width, y: currentY))
                        context.stroke(
                            path,
                            with: .color(isMajor ? seyesMajorCol : seyesMinorCol),
                            lineWidth: isMajor ? 1.2 : 0.7
                        )
                    }
                    currentY += subStep
                }
                // Vertical grid lines
                var currentX = marginPx + step
                while currentX < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: currentX, y: 0))
                    path.addLine(to: CGPoint(x: currentX, y: size.height))
                    context.stroke(path, with: .color(seyesVertCol), lineWidth: 0.85)
                    currentX += step
                }

            case .millimeter:
                // Engineering millimeter graph paper shifting with scrollY
                let milliMajorCol = lineCol
                let milliMinorCol = lineCol.opacity(0.50)

                let unit = max(step / 5.0, 1.0)
                let phaseY = ((-scrollY).truncatingRemainder(dividingBy: step)).let { $0 > 0 ? $0 - step : $0 }
                var currentY = phaseY - step
                while currentY < size.height + unit {
                    if currentY >= 0 && currentY <= size.height {
                        let absY = currentY + scrollY
                        let indexY = Int((absY / unit).rounded())
                        let isMajor = (indexY % 5 == 0)
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: currentY))
                        path.addLine(to: CGPoint(x: size.width, y: currentY))
                        context.stroke(
                            path,
                            with: .color(isMajor ? milliMajorCol : milliMinorCol),
                            lineWidth: isMajor ? 1.2 : 0.6
                        )
                    }
                    currentY += unit
                }
                var currentX = marginPx + unit
                var indexX = 1
                while currentX < size.width {
                    let isMajor = (indexX % 5 == 0)
                    var path = Path()
                    path.move(to: CGPoint(x: currentX, y: 0))
                    path.addLine(to: CGPoint(x: currentX, y: size.height))
                    context.stroke(
                        path,
                        with: .color(isMajor ? milliMajorCol : milliMinorCol),
                        lineWidth: isMajor ? 1.2 : 0.6
                    )
                    currentX += unit
                    indexX += 1
                }

            case .slantLines:
                // Russian/European calligraphy copybook (косая линейка) shifting with scrollY
                let baseLineCol = lineCol
                let waistLineCol = lineCol.opacity(0.65)
                let slantLineCol = lineCol.opacity(0.60)

                let bandHeight = max(step * 0.35, 1.0)
                let slantSpacing = max(step * 0.70, 1.0)

                let phaseY = ((-scrollY).truncatingRemainder(dividingBy: step)).let { $0 > 0 ? $0 - step : $0 }
                var currentY = phaseY - step
                while currentY < size.height + step {
                    // Baseline (lower boundary of writing strip)
                    if currentY >= 0 && currentY <= size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: currentY))
                        path.addLine(to: CGPoint(x: size.width, y: currentY))
                        context.stroke(path, with: .color(baseLineCol), lineWidth: 1.1)
                    }
                    // Waistline (upper boundary of writing strip)
                    let waistY = currentY - bandHeight
                    if waistY >= 0 && waistY <= size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: waistY))
                        path.addLine(to: CGPoint(x: size.width, y: waistY))
                        context.stroke(path, with: .color(waistLineCol), lineWidth: 0.75)
                    }
                    currentY += step
                }

                // 65-degree cursive slant guide lines shifting with scrollY
                let cot65: CGFloat = 0.466307658 // cot(65 deg) = 1.0 / tan(65 * .pi / 180)
                let dx = size.height * cot65
                let slantPhaseX = (((-scrollY * cot65).truncatingRemainder(dividingBy: slantSpacing)) + slantSpacing).truncatingRemainder(dividingBy: slantSpacing)

                var topX = -dx + slantPhaseX - slantSpacing
                while topX <= size.width + dx + slantSpacing {
                    var path = Path()
                    path.move(to: CGPoint(x: topX, y: 0))
                    path.addLine(to: CGPoint(x: topX - dx, y: size.height))
                    context.stroke(path, with: .color(slantLineCol), lineWidth: 0.65)
                    topX += slantSpacing
                }

            case .blank:
                // No pattern lines, only margin line
                break
            }

            // 3. Draw vertical margin line (width: 1.2 pt)
            var marginPath = Path()
            marginPath.move(to: CGPoint(x: marginPx, y: 0))
            marginPath.addLine(to: CGPoint(x: marginPx, y: size.height))
            context.stroke(marginPath, with: .color(marginCol), lineWidth: 1.2)

            // 4. Draw authentic antique edge patina & vignette scaling smoothly with age
            if agingFactor > 0.001 {
                drawVignetteAndPatina(
                    context: context,
                    size: size,
                    agingFactor: agingFactor,
                    isDarkTheme: isDarkTheme
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Sub-drawers
    private func drawRuledLines(context: GraphicsContext, size: CGSize, step: CGFloat, lineCol: Color) {
        let phaseY = ((-scrollY).truncatingRemainder(dividingBy: step)).let { $0 > 0 ? $0 - step : $0 }
        var currentY = phaseY + step
        while currentY < size.height + step {
            if currentY >= 0 && currentY <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: currentY))
                path.addLine(to: CGPoint(x: size.width, y: currentY))
                context.stroke(path, with: .color(lineCol), lineWidth: 1.0)
            }
            currentY += step
        }
    }

    private func drawVignetteAndPatina(
        context: GraphicsContext,
        size: CGSize,
        agingFactor: CGFloat,
        isDarkTheme: Bool
    ) {
        let vignetteAlpha = min(max(agingFactor * 0.18, 0.0), 0.20)
        let vignetteColor = isDarkTheme ? Color.black : Color(hex: 0x6B4E2B)

        // Top gradient (70 pt)
        let topRect = CGRect(x: 0, y: 0, width: size.width, height: 70)
        context.fill(
            Path(topRect),
            with: .linearGradient(
                Gradient(colors: [vignetteColor.opacity(vignetteAlpha * 1.2), .clear]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: 70)
            )
        )

        // Bottom gradient (80 pt)
        let botY = max(size.height - 80, 0)
        let botRect = CGRect(x: 0, y: botY, width: size.width, height: size.height - botY)
        context.fill(
            Path(botRect),
            with: .linearGradient(
                Gradient(colors: [.clear, vignetteColor.opacity(vignetteAlpha * 1.5)]),
                startPoint: CGPoint(x: 0, y: botY),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Left margin edge gradient (40 pt)
        let leftRect = CGRect(x: 0, y: 0, width: 40, height: size.height)
        context.fill(
            Path(leftRect),
            with: .linearGradient(
                Gradient(colors: [vignetteColor.opacity(vignetteAlpha), .clear]),
                startPoint: .zero,
                endPoint: CGPoint(x: 40, y: 0)
            )
        )

        // Right border edge gradient (40 pt)
        let rightX = max(size.width - 40, 0)
        let rightRect = CGRect(x: rightX, y: 0, width: size.width - rightX, height: size.height)
        context.fill(
            Path(rightRect),
            with: .linearGradient(
                Gradient(colors: [.clear, vignetteColor.opacity(vignetteAlpha * 1.1)]),
                startPoint: CGPoint(x: rightX, y: 0),
                endPoint: CGPoint(x: size.width, y: 0)
            )
        )

        // For very old paper (>180 days, agingFactor > 0.65), smoothly fade in antique patina specks
        if agingFactor > 0.65 {
            let speckProgress = min(max((agingFactor - 0.65) / 0.35, 0.0), 1.0)
            let speckAlpha = speckProgress * speckProgress * 0.16
            let speckColor = !isDarkTheme ? Color(hex: 0x8B6C43).opacity(speckAlpha) : Color(hex: 0x997A48).opacity(speckAlpha * 1.1)

            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.88 - 2.5, y: 120 - 2.5, width: 5.0, height: 5.0)), with: .color(speckColor))
            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.92 - 1.8, y: 135 - 1.8, width: 3.6, height: 3.6)), with: .color(speckColor))
            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.12 - 2.0, y: max(size.height - 180, 0) - 2.0, width: 4.0, height: 4.0)), with: .color(speckColor))
            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.85 - 3.0, y: max(size.height - 240, 0) - 3.0, width: 6.0, height: 6.0)), with: .color(speckColor))
        }
    }
}

// MARK: - Mathematical Helpers & Modifiers
public func lerpColor(_ c1: Color, _ c2: Color, fraction: CGFloat) -> Color {
    let f = min(max(fraction, 0.0), 1.0)
    let comp1 = rgbaComponents(of: c1)
    let comp2 = rgbaComponents(of: c2)
    return Color(
        .sRGB,
        red: Double(comp1.r + (comp2.r - comp1.r) * f),
        green: Double(comp1.g + (comp2.g - comp1.g) * f),
        blue: Double(comp1.b + (comp2.b - comp1.b) * f),
        opacity: Double(comp1.a + (comp2.a - comp1.a) * f)
    )
}

public func rgbaComponents(of color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    #if canImport(UIKit)
    let ui = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
        return (r, g, b, a)
    }
    if let cg = ui.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
       let comps = cg.components, comps.count >= 3 {
        return (comps[0], comps[1], comps[2], cg.alpha)
    }
    #endif
    return (0, 0, 0, 1)
}

public extension View {
    func notebookPaper(
        patternType: NotebookPattern = .lines,
        patternSize: CGFloat = 32.0,
        marginLineX: CGFloat = 50.0,
        scrollY: CGFloat = 0.0,
        agingDays: Double = 0.0,
        isDarkTheme: Bool = false,
        backgroundColor: Color? = nil,
        lineColor: Color? = nil,
        marginLineColor: Color? = nil,
        drawBackground: Bool = true
    ) -> some View {
        self.background(
            NotebookCanvasView(
                patternType: patternType,
                patternSize: patternSize,
                marginLineX: marginLineX,
                scrollY: scrollY,
                agingDays: agingDays,
                isDarkTheme: isDarkTheme,
                backgroundColor: backgroundColor,
                lineColor: lineColor,
                marginLineColor: marginLineColor,
                drawBackground: drawBackground
            )
        )
    }
}

private extension CGFloat {
    func `let`<R>(_ transform: (CGFloat) -> R) -> R {
        transform(self)
    }
}
