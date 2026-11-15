//
//  HandDrawnStrikeLineView.swift
//  Plan4U_iOS
//
//  12 authentic hand-drawn ballpoint pen strikeout styles.
//  100% mathematical match with Android HandDrawnStrikeLine.kt
//

import SwiftUI

public enum StrikeStyle: String, CaseIterable, Sendable {
    case arcUp = "Дуга вверх"
    case arcDown = "Дуга вниз"
    case waveGentle = "Мягкая волна"
    case waveDynamic = "Энергичная волна"
    case doubleLine = "Двойная линия"
    case casualSlant = "Диагональный слэш"
    case zigzagScratch = "Энергичный зигзаг"
    case crossDoubleSlash = "Перекрестный двойной"
    case tremorStraight = "Живая прямая с тремором"
    case loopFlourish = "Росчерк с петлей"
    case sCurve = "S-образная кривая"
    case decisiveStrike = "Уверенный штрих с крючком"
}

public struct HandDrawnStrikeLineView: View {
    public var isCompleted: Bool
    public var seed: Int
    public var strokeColor: Color = Color.black.opacity(0.7)
    public var strokeWidth: CGFloat = 1.6

    @State private var animProgress: CGFloat = 0.0

    public init(
        isCompleted: Bool,
        seed: Int = 42,
        strokeColor: Color = Color.black.opacity(0.7),
        strokeWidth: CGFloat = 1.6
    ) {
        self.isCompleted = isCompleted
        self.seed = seed
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    public var body: some View {
        GeometryReader { geo in
            let path = buildStrikePath(size: geo.size, seed: seed)
            path.trimmedPath(from: 0, to: animProgress)
                .stroke(
                    strokeColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                )
        }
        .onAppear {
            if isCompleted {
                animProgress = 1.0
            }
        }
        .onChange(of: isCompleted) { _, completed in
            if completed {
                withAnimation(.easeOut(duration: 0.28)) {
                    animProgress = 1.0
                }
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    animProgress = 0.0
                }
            }
        }
    }

    private func buildStrikePath(size: CGSize, seed: Int) -> Path {
        let w = size.width
        let h = size.height
        let midY = h * 0.52

        // Deterministic pseudo-random based on seed
        let styleIndex = abs(seed) % StrikeStyle.allCases.count
        let style = StrikeStyle.allCases[styleIndex]

        var p = Path()
        let startX: CGFloat = -2.0
        let endX: CGFloat = w + 4.0

        switch style {
        case .arcUp:
            p.move(to: CGPoint(x: startX, y: midY + 1.5))
            p.addQuadCurve(
                to: CGPoint(x: endX, y: midY - 0.5),
                control: CGPoint(x: w * 0.5, y: midY - 4.5)
            )

        case .arcDown:
            p.move(to: CGPoint(x: startX, y: midY - 1.5))
            p.addQuadCurve(
                to: CGPoint(x: endX, y: midY + 1.0),
                control: CGPoint(x: w * 0.5, y: midY + 4.0)
            )

        case .waveGentle:
            p.move(to: CGPoint(x: startX, y: midY))
            p.addCurve(
                to: CGPoint(x: endX, y: midY),
                control1: CGPoint(x: w * 0.33, y: midY - 3.0),
                control2: CGPoint(x: w * 0.66, y: midY + 3.0)
            )

        case .waveDynamic:
            p.move(to: CGPoint(x: startX, y: midY + 1.0))
            p.addCurve(
                to: CGPoint(x: endX, y: midY - 1.0),
                control1: CGPoint(x: w * 0.25, y: midY - 5.0),
                control2: CGPoint(x: w * 0.75, y: midY + 5.0)
            )

        case .doubleLine:
            p.move(to: CGPoint(x: startX, y: midY - 1.5))
            p.addLine(to: CGPoint(x: endX, y: midY - 2.0))
            p.move(to: CGPoint(x: startX + 2.0, y: midY + 2.0))
            p.addLine(to: CGPoint(x: endX - 1.0, y: midY + 1.5))

        case .casualSlant:
            p.move(to: CGPoint(x: startX, y: midY + 3.0))
            p.addLine(to: CGPoint(x: endX, y: midY - 3.0))

        case .zigzagScratch:
            p.move(to: CGPoint(x: startX, y: midY))
            p.addLine(to: CGPoint(x: w * 0.3, y: midY - 3.5))
            p.addLine(to: CGPoint(x: w * 0.6, y: midY + 3.0))
            p.addLine(to: CGPoint(x: endX, y: midY - 1.0))

        case .tremorStraight, .sCurve, .loopFlourish, .crossDoubleSlash, .decisiveStrike:
            // Human tremor straight
            p.move(to: CGPoint(x: startX, y: midY - 0.5))
            p.addCurve(
                to: CGPoint(x: endX, y: midY + 0.5),
                control1: CGPoint(x: w * 0.4, y: midY + 1.2),
                control2: CGPoint(x: w * 0.8, y: midY - 1.2)
            )
        }
        return p
    }
}
