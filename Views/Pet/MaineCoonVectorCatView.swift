//
//  MaineCoonVectorCatView.swift
//  Plan4U_iOS
//
//  Pixel-for-pixel and vector-accurate SwiftUI port of Android MaineCoonCatView.kt.
//  Features:
//  - 9 authentic coat palettes (Ginger, White, Tiger, Silver, Midnight, Cream, Mocha, Siamese, Calico)
//  - Lynx ear tufts, bushy plume tail, fluffy bib/mane, forehead tabby "M", expressive eyes
//  - Fluid living animations: natural breathing, tail sway, spontaneous ear twitches, eye blinking loop,
//    purr micro-vibrations, eating head-bob, and floating Zzz sleeping bubbles.
//

import SwiftUI

// MARK: - Coat Palettes
public struct MaineCoonPalette: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let furMain: Color
    public let furGrad: Color
    public let furLight: Color
    public let furDark: Color
    public let bib: Color
    public let earInner: Color
    public let earTuft: Color
    public let eyes: Color
    public let eyeHighlight: Color
    public let nose: Color
    public let markings: Color
    public let swatchColors: [Color]

    public init(
        id: String,
        name: String,
        emoji: String,
        furMain: Color,
        furGrad: Color,
        furLight: Color,
        furDark: Color,
        bib: Color,
        earInner: Color,
        earTuft: Color,
        eyes: Color,
        eyeHighlight: Color = .white,
        nose: Color,
        markings: Color,
        swatchColors: [Color]
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.furMain = furMain
        self.furGrad = furGrad
        self.furLight = furLight
        self.furDark = furDark
        self.bib = bib
        self.earInner = earInner
        self.earTuft = earTuft
        self.eyes = eyes
        self.eyeHighlight = eyeHighlight
        self.nose = nose
        self.markings = markings
        self.swatchColors = swatchColors
    }
}

public enum MaineCoonPalettes {
    public static let ginger = MaineCoonPalette(
        id: "ginger",
        name: "Рыжий табби",
        emoji: "🦁",
        furMain: Color(hex: 0xF97316),
        furGrad: Color(hex: 0xC2410C),
        furLight: Color(hex: 0xFED7AA),
        furDark: Color(hex: 0x9A3412),
        bib: Color(hex: 0xFFFBEB),
        earInner: Color(hex: 0xFBCFE8),
        earTuft: Color(hex: 0x7C2D12),
        eyes: Color(hex: 0x10B981),
        nose: Color(hex: 0xFB7185),
        markings: Color(hex: 0x9A3412),
        swatchColors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)]
    )

    public static let white = MaineCoonPalette(
        id: "white",
        name: "Белоснежный",
        emoji: "❄️",
        furMain: Color(hex: 0xFFFFFF),
        furGrad: Color(hex: 0xE2E8F0),
        furLight: Color(hex: 0xFFFFFF),
        furDark: Color(hex: 0x94A3B8),
        bib: Color(hex: 0xF8FAFC),
        earInner: Color(hex: 0xFED7E2),
        earTuft: Color(hex: 0xCBD5E1),
        eyes: Color(hex: 0x0284C7),
        nose: Color(hex: 0xFB7185),
        markings: Color(hex: 0xCBD5E1),
        swatchColors: [Color(hex: 0xFFFFFF), Color(hex: 0xE2E8F0)]
    )

    public static let tiger = MaineCoonPalette(
        id: "tiger",
        name: "Тигровый",
        emoji: "🐯",
        furMain: Color(hex: 0xB45309),
        furGrad: Color(hex: 0x78350F),
        furLight: Color(hex: 0xFEF3C7),
        furDark: Color(hex: 0x451A03),
        bib: Color(hex: 0xFEFCE8),
        earInner: Color(hex: 0xFED7AA),
        earTuft: Color(hex: 0x291102),
        eyes: Color(hex: 0x16A34A),
        nose: Color(hex: 0xE11D48),
        markings: Color(hex: 0x291102),
        swatchColors: [Color(hex: 0xB45309), Color(hex: 0x451A03)]
    )

    public static let silver = MaineCoonPalette(
        id: "silver",
        name: "Серебристый",
        emoji: "🐺",
        furMain: Color(hex: 0x94A3B8),
        furGrad: Color(hex: 0x475569),
        furLight: Color(hex: 0xE2E8F0),
        furDark: Color(hex: 0x334155),
        bib: Color(hex: 0xFFFFFF),
        earInner: Color(hex: 0xFCE7F3),
        earTuft: Color(hex: 0x1E293B),
        eyes: Color(hex: 0x0284C7),
        nose: Color(hex: 0xF43F5E),
        markings: Color(hex: 0x334155),
        swatchColors: [Color(hex: 0x94A3B8), Color(hex: 0x64748B)]
    )

    public static let midnight = MaineCoonPalette(
        id: "midnight",
        name: "Угольный",
        emoji: "🌙",
        furMain: Color(hex: 0x1E293B),
        furGrad: Color(hex: 0x0F172A),
        furLight: Color(hex: 0x475569),
        furDark: Color(hex: 0x020617),
        bib: Color(hex: 0x334155),
        earInner: Color(hex: 0x64748B),
        earTuft: Color(hex: 0x020617),
        eyes: Color(hex: 0xEAB308),
        nose: Color(hex: 0x475569),
        markings: Color(hex: 0x020617),
        swatchColors: [Color(hex: 0x334155), Color(hex: 0x0F172A)]
    )

    public static let cream = MaineCoonPalette(
        id: "cream",
        name: "Кремовый",
        emoji: "🍑",
        furMain: Color(hex: 0xFED7AA),
        furGrad: Color(hex: 0xFB923C),
        furLight: Color(hex: 0xFFF7ED),
        furDark: Color(hex: 0xEA580C),
        bib: Color(hex: 0xFFFFFF),
        earInner: Color(hex: 0xFED7E2),
        earTuft: Color(hex: 0xC2410C),
        eyes: Color(hex: 0x14B8A6),
        nose: Color(hex: 0xF43F5E),
        markings: Color(hex: 0xEA580C),
        swatchColors: [Color(hex: 0xFFFFEDD5), Color(hex: 0xFDBA74)]
    )

    public static let mocha = MaineCoonPalette(
        id: "mocha",
        name: "Мокко",
        emoji: "🍫",
        furMain: Color(hex: 0x78350F),
        furGrad: Color(hex: 0x451A03),
        furLight: Color(hex: 0xFEF3C7),
        furDark: Color(hex: 0x291102),
        bib: Color(hex: 0xFEF9C3),
        earInner: Color(hex: 0xFED7AA),
        earTuft: Color(hex: 0x1C0A00),
        eyes: Color(hex: 0xF59E0B),
        nose: Color(hex: 0xBE123C),
        markings: Color(hex: 0x291102),
        swatchColors: [Color(hex: 0x78350F), Color(hex: 0x451A03)]
    )

    public static let siamese = MaineCoonPalette(
        id: "siamese",
        name: "Сиамский",
        emoji: "🐾",
        furMain: Color(hex: 0xFEF3C7),
        furGrad: Color(hex: 0xD97706),
        furLight: Color(hex: 0xFFFFFF),
        furDark: Color(hex: 0x451A03),
        bib: Color(hex: 0xFFFFFF),
        earInner: Color(hex: 0xFED7AA),
        earTuft: Color(hex: 0x291102),
        eyes: Color(hex: 0x0284C7),
        nose: Color(hex: 0x881337),
        markings: Color(hex: 0x451A03),
        swatchColors: [Color(hex: 0xFFFBEB), Color(hex: 0x78350F)]
    )

    public static let calico = MaineCoonPalette(
        id: "calico",
        name: "Калико",
        emoji: "🎨",
        furMain: Color(hex: 0xEA580C),
        furGrad: Color(hex: 0x1E293B),
        furLight: Color(hex: 0xFFFFFF),
        furDark: Color(hex: 0x0F172A),
        bib: Color(hex: 0xFFFFFF),
        earInner: Color(hex: 0xFBCFE8),
        earTuft: Color(hex: 0x0F172A),
        eyes: Color(hex: 0x10B981),
        nose: Color(hex: 0xFB7185),
        markings: Color(hex: 0x0F172A),
        swatchColors: [Color(hex: 0xF97316), Color(hex: 0xFFFFFF), Color(hex: 0x1E293B)]
    )

    public static let all: [MaineCoonPalette] = [
        ginger, white, tiger, silver, midnight, cream, mocha, siamese, calico
    ]

    public static func palette(for id: String) -> MaineCoonPalette {
        all.first { $0.id == id } ?? ginger
    }
}

// MARK: - Maine Coon Vector Cat Composable View
public struct MaineCoonVectorCatView: View {
    public var colorScheme: String
    public var isSleeping: Bool
    public var isPurring: Bool
    public var isEating: Bool

    @State private var breathPhase: Bool = false
    @State private var tailPhase: Bool = false
    @State private var purrPhase: Bool = false
    @State private var eatBobPhase: Bool = false
    @State private var eyeBlinkScale: CGFloat = 1.0
    @State private var leftEarTwitch: CGFloat = 0.0
    @State private var rightEarTwitch: CGFloat = 0.0
    @State private var zzzProgress1: CGFloat = 0.0
    @State private var zzzProgress2: CGFloat = 0.0

    public init(
        colorScheme: String = "ginger",
        isSleeping: Bool = false,
        isPurring: Bool = false,
        isEating: Bool = false
    ) {
        self.colorScheme = colorScheme
        self.isSleeping = isSleeping
        self.isPurring = isPurring
        self.isEating = isEating
    }

    private var palette: MaineCoonPalette {
        MaineCoonPalettes.palette(for: colorScheme)
    }

    public var body: some View {
        GeometryReader { proxy in
            let dim = min(proxy.size.width, proxy.size.height)
            let scaleFactor = dim / 200.0
            let offsetX = (proxy.size.width - 200.0 * scaleFactor) / 2.0
            let offsetY = (proxy.size.height - 200.0 * scaleFactor) / 2.0

            ZStack {
                // Main Vector Canvas
                Canvas { context, _ in
                    context.translateBy(x: offsetX, y: offsetY)
                    context.scaleBy(x: scaleFactor, y: scaleFactor)

                    // 1. Floor Drop Shadow
                    let shadowRect = CGRect(x: 42, y: 174, width: 116, height: 20)
                    context.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.12)))

                    // 2. Plume Tail with rotation
                    let tailRotAngle = Angle.degrees(Double(tailPhase ? 10.0 : -8.0))
                    var tailContext = context
                    let tailPivot = CGPoint(x: 56, y: 160)
                    tailContext.translateBy(x: tailPivot.x, y: tailPivot.y)
                    tailContext.rotate(by: tailRotAngle)
                    tailContext.translateBy(x: -tailPivot.x, y: -tailPivot.y)
                    drawTail(context: tailContext, palette: palette)

                    // 3. Body with Breathing / Purring Scale
                    let bodyScaleX: CGFloat = isPurring ? (purrPhase ? 1.025 : 1.01) : (breathPhase ? 1.02 : 1.0)
                    let bodyScaleY: CGFloat = isPurring ? (purrPhase ? 1.025 : 1.01) : (breathPhase ? (isSleeping ? 0.96 : 0.985) : 1.0)
                    let bodyPivot = CGPoint(x: 100, y: 180)

                    var bodyContext = context
                    bodyContext.translateBy(x: bodyPivot.x, y: bodyPivot.y)
                    bodyContext.scaleBy(x: bodyScaleX, y: bodyScaleY)
                    bodyContext.translateBy(x: -bodyPivot.x, y: -bodyPivot.y)
                    drawBody(context: bodyContext, palette: palette)

                    // 4. Head with ear twitches, eating bobbing & blinking
                    let headBobY: CGFloat = isEating ? (eatBobPhase ? 4.0 : 0.0) : 0.0
                    let headBobRot: Double = isEating ? (eatBobPhase ? 2.5 : 0.0) : 0.0
                    let headPivot = CGPoint(x: 100, y: 100)

                    var headContext = context
                    headContext.translateBy(x: 0, y: headBobY)
                    headContext.translateBy(x: headPivot.x, y: headPivot.y)
                    headContext.rotate(by: Angle.degrees(headBobRot))
                    headContext.translateBy(x: -headPivot.x, y: -headPivot.y)

                    drawHead(
                        context: headContext,
                        palette: palette,
                        isSleeping: isSleeping,
                        leftEarTwitch: leftEarTwitch,
                        rightEarTwitch: rightEarTwitch,
                        eyeBlinkScale: isSleeping ? 0.08 : eyeBlinkScale
                    )
                }

                // Sleeping Zzz Bubbles Overlay
                if isSleeping {
                    ZStack {
                        Text("Z")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: 0x6366F1).opacity(Double(1.0 - zzzProgress1)))
                            .offset(x: -26.0 + 14.0 * zzzProgress1, y: -24.0 - 32.0 * zzzProgress1)

                        Text("z")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x818CF8).opacity(Double(1.0 - zzzProgress2)))
                            .offset(x: -16.0 + 18.0 * zzzProgress2, y: -18.0 - 36.0 * zzzProgress2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            startLivingAnimations()
        }
        .onChange(of: isSleeping) { _, _ in
            startLivingAnimations()
        }
    }

    // MARK: - Animation Timers & Loops
    private func startLivingAnimations() {
        // Natural Breathing
        withAnimation(.easeInOut(duration: isSleeping ? 1.8 : 1.75).repeatForever(autoreverses: true)) {
            breathPhase.toggle()
        }

        // Tail Wag
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            tailPhase.toggle()
        }

        // Purr vibration
        withAnimation(.linear(duration: 0.09).repeatForever(autoreverses: true)) {
            purrPhase.toggle()
        }

        // Eating bob
        withAnimation(.easeInOut(duration: 0.14).repeatForever(autoreverses: true)) {
            eatBobPhase.toggle()
        }

        // Sleeping Zzz loop
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
            zzzProgress1 = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                zzzProgress2 = 1.0
            }
        }

        // Eye Blinking Loop
        Task { @MainActor in
            while !Task.isCancelled {
                let delaySeconds = Double.random(in: 3.2...5.2)
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                guard !isSleeping else { continue }
                withAnimation(.easeOut(duration: 0.08)) {
                    eyeBlinkScale = 0.08
                }
                try? await Task.sleep(nanoseconds: 80_000_000)
                withAnimation(.easeIn(duration: 0.11)) {
                    eyeBlinkScale = 1.0
                }
            }
        }

        // Ear Tufts Spontaneous Twitches
        Task { @MainActor in
            while !Task.isCancelled {
                let delaySeconds = Double.random(in: 3.5...6.5)
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                guard !isSleeping else { continue }
                withAnimation(.easeInOut(duration: 0.07)) { leftEarTwitch = -8.0 }
                try? await Task.sleep(nanoseconds: 70_000_000)
                withAnimation(.easeInOut(duration: 0.07)) { leftEarTwitch = 4.0 }
                try? await Task.sleep(nanoseconds: 70_000_000)
                withAnimation(.easeInOut(duration: 0.07)) { leftEarTwitch = 0.0 }

                let rightDelay = Double.random(in: 0.3...0.7)
                try? await Task.sleep(nanoseconds: UInt64(rightDelay * 1_000_000_000))
                withAnimation(.easeInOut(duration: 0.07)) { rightEarTwitch = 8.0 }
                try? await Task.sleep(nanoseconds: 70_000_000)
                withAnimation(.easeInOut(duration: 0.07)) { rightEarTwitch = -4.0 }
                try? await Task.sleep(nanoseconds: 70_000_000)
                withAnimation(.easeInOut(duration: 0.07)) { rightEarTwitch = 0.0 }
            }
        }
    }

    // MARK: - Drawing Functions (1-in-1 matching Compose DrawScope)

    private func drawTail(context: GraphicsContext, palette: MaineCoonPalette) {
        var tailPath = Path()
        tailPath.move(to: CGPoint(x: 56, y: 160))
        tailPath.addCurve(to: CGPoint(x: 12, y: 92), control1: CGPoint(x: 30, y: 152), control2: CGPoint(x: 6, y: 128))
        tailPath.addCurve(to: CGPoint(x: 48, y: 76), control1: CGPoint(x: 16, y: 68), control2: CGPoint(x: 38, y: 60))
        tailPath.addCurve(to: CGPoint(x: 52, y: 136), control1: CGPoint(x: 56, y: 88), control2: CGPoint(x: 44, y: 116))
        tailPath.addCurve(to: CGPoint(x: 70, y: 162), control1: CGPoint(x: 56, y: 146), control2: CGPoint(x: 64, y: 154))
        tailPath.closeSubpath()

        let tailGrad = Gradient(colors: [palette.furMain, palette.furGrad])
        context.fill(tailPath, with: .linearGradient(tailGrad, startPoint: CGPoint(x: 35, y: 60), endPoint: CGPoint(x: 50, y: 162)))
        context.stroke(tailPath, with: .color(palette.furDark), style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))

        // Fluffy Tufts
        var tuft1 = Path()
        tuft1.move(to: CGPoint(x: 12, y: 92))
        tuft1.addCurve(to: CGPoint(x: 30, y: 148), control1: CGPoint(x: 2, y: 108), control2: CGPoint(x: 10, y: 134))
        context.stroke(tuft1, with: .color(palette.markings.opacity(0.65)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

        var tuft2 = Path()
        tuft2.move(to: CGPoint(x: 22, y: 80))
        tuft2.addCurve(to: CGPoint(x: 42, y: 130), control1: CGPoint(x: 26, y: 94), control2: CGPoint(x: 28, y: 116))
        context.stroke(tuft2, with: .color(palette.markings.opacity(0.65)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

        var tuft3 = Path()
        tuft3.move(to: CGPoint(x: 48, y: 76))
        tuft3.addCurve(to: CGPoint(x: 46, y: 118), control1: CGPoint(x: 42, y: 88), control2: CGPoint(x: 36, y: 104))
        context.stroke(tuft3, with: .color(palette.furLight.opacity(0.75)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
    }

    private func drawBody(context: GraphicsContext, palette: MaineCoonPalette) {
        let furGrad = Gradient(colors: [palette.furMain, palette.furGrad])

        // Back Paws & Hips (Left & Right)
        let leftHip = Path(ellipseIn: CGRect(x: 42, y: 150, width: 44, height: 28))
        context.fill(leftHip, with: .linearGradient(furGrad, startPoint: CGPoint(x: 64, y: 140), endPoint: CGPoint(x: 64, y: 178)))
        context.stroke(leftHip, with: .color(palette.furDark), lineWidth: 1.6)

        let rightHip = Path(ellipseIn: CGRect(x: 114, y: 150, width: 44, height: 28))
        context.fill(rightHip, with: .linearGradient(furGrad, startPoint: CGPoint(x: 136, y: 140), endPoint: CGPoint(x: 136, y: 178)))
        context.stroke(rightHip, with: .color(palette.furDark), lineWidth: 1.6)

        // Main Torso
        var torsoPath = Path()
        torsoPath.move(to: CGPoint(x: 68, y: 120))
        torsoPath.addCurve(to: CGPoint(x: 100, y: 176), control1: CGPoint(x: 64, y: 145), control2: CGPoint(x: 68, y: 174))
        torsoPath.addCurve(to: CGPoint(x: 132, y: 120), control1: CGPoint(x: 132, y: 174), control2: CGPoint(x: 136, y: 145))
        torsoPath.addCurve(to: CGPoint(x: 68, y: 120), control1: CGPoint(x: 128, y: 105), control2: CGPoint(x: 72, y: 105))
        torsoPath.closeSubpath()

        context.fill(torsoPath, with: .linearGradient(furGrad, startPoint: CGPoint(x: 100, y: 100), endPoint: CGPoint(x: 100, y: 178)))
        context.stroke(torsoPath, with: .color(palette.furDark), lineWidth: 1.8)

        // Luxurious Fluffy Maine Coon Mane / Bib
        let bibGrad = Gradient(colors: [.white, palette.bib])
        var bibPath = Path()
        bibPath.move(to: CGPoint(x: 72, y: 114))
        bibPath.addCurve(to: CGPoint(x: 80, y: 156), control1: CGPoint(x: 62, y: 128), control2: CGPoint(x: 66, y: 146))
        bibPath.addCurve(to: CGPoint(x: 100, y: 172), control1: CGPoint(x: 88, y: 162), control2: CGPoint(x: 94, y: 168))
        bibPath.addCurve(to: CGPoint(x: 120, y: 156), control1: CGPoint(x: 106, y: 168), control2: CGPoint(x: 112, y: 162))
        bibPath.addCurve(to: CGPoint(x: 128, y: 114), control1: CGPoint(x: 134, y: 146), control2: CGPoint(x: 138, y: 128))
        bibPath.addCurve(to: CGPoint(x: 100, y: 132), control1: CGPoint(x: 120, y: 126), control2: CGPoint(x: 108, y: 132))
        bibPath.addCurve(to: CGPoint(x: 72, y: 114), control1: CGPoint(x: 92, y: 132), control2: CGPoint(x: 80, y: 126))
        bibPath.closeSubpath()

        context.fill(bibPath, with: .linearGradient(bibGrad, startPoint: CGPoint(x: 100, y: 114), endPoint: CGPoint(x: 100, y: 172)))
        context.stroke(bibPath, with: .color(palette.furDark), lineWidth: 1.2)

        // Fluffy fur layers on bib
        var bibTufts = Path()
        bibTufts.move(to: CGPoint(x: 84, y: 126))
        bibTufts.addCurve(to: CGPoint(x: 100, y: 158), control1: CGPoint(x: 76, y: 138), control2: CGPoint(x: 86, y: 148))
        bibTufts.addCurve(to: CGPoint(x: 116, y: 126), control1: CGPoint(x: 114, y: 148), control2: CGPoint(x: 124, y: 138))
        context.stroke(bibTufts, with: .color(palette.furLight), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

        // Front Paws
        let leftFrontPaw = Path(ellipseIn: CGRect(x: 76, y: 171, width: 20, height: 14))
        context.fill(leftFrontPaw, with: .color(palette.bib))
        context.stroke(leftFrontPaw, with: .color(palette.furDark), lineWidth: 1.4)

        let rightFrontPaw = Path(ellipseIn: CGRect(x: 104, y: 171, width: 20, height: 14))
        context.fill(rightFrontPaw, with: .color(palette.bib))
        context.stroke(rightFrontPaw, with: .color(palette.furDark), lineWidth: 1.4)

        // Toe Separator Lines
        var clawLines = Path()
        clawLines.move(to: CGPoint(x: 83, y: 176))
        clawLines.addLine(to: CGPoint(x: 83, y: 182))
        clawLines.move(to: CGPoint(x: 89, y: 176))
        clawLines.addLine(to: CGPoint(x: 89, y: 182))
        clawLines.move(to: CGPoint(x: 111, y: 176))
        clawLines.addLine(to: CGPoint(x: 111, y: 182))
        clawLines.move(to: CGPoint(x: 117, y: 176))
        clawLines.addLine(to: CGPoint(x: 117, y: 182))
        context.stroke(clawLines, with: .color(palette.furDark), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }

    private func drawHead(
        context: GraphicsContext,
        palette: MaineCoonPalette,
        isSleeping: Bool,
        leftEarTwitch: CGFloat,
        rightEarTwitch: CGFloat,
        eyeBlinkScale: CGFloat
    ) {
        let furGrad = Gradient(colors: [palette.furMain, palette.furGrad])

        // 1. Left Lynx Ear with Tuft (with twitch rotation)
        var leftEarContext = context
        let leftEarPivot = CGPoint(x: 66, y: 84)
        leftEarContext.translateBy(x: leftEarPivot.x, y: leftEarPivot.y)
        leftEarContext.rotate(by: Angle.degrees(Double(leftEarTwitch)))
        leftEarContext.translateBy(x: -leftEarPivot.x, y: -leftEarPivot.y)

        var leftEar = Path()
        leftEar.move(to: CGPoint(x: 56, y: 84))
        leftEar.addLine(to: CGPoint(x: 66, y: 32))
        leftEar.addLine(to: CGPoint(x: 94, y: 68))
        leftEar.closeSubpath()
        leftEarContext.fill(leftEar, with: .linearGradient(furGrad, startPoint: CGPoint(x: 75, y: 32), endPoint: CGPoint(x: 75, y: 84)))
        leftEarContext.stroke(leftEar, with: .color(palette.furDark), lineWidth: 1.8)

        var leftEarInner = Path()
        leftEarInner.move(to: CGPoint(x: 62, y: 80))
        leftEarInner.addLine(to: CGPoint(x: 70, y: 42))
        leftEarInner.addLine(to: CGPoint(x: 90, y: 68))
        leftEarInner.closeSubpath()
        leftEarContext.fill(leftEarInner, with: .color(palette.earInner))

        // Pointed Lynx Ear Tuft
        var leftTuft = Path()
        leftTuft.move(to: CGPoint(x: 66, y: 32))
        leftTuft.addCurve(to: CGPoint(x: 56, y: 8), control1: CGPoint(x: 64, y: 20), control2: CGPoint(x: 60, y: 14))
        leftTuft.addCurve(to: CGPoint(x: 69, y: 34), control1: CGPoint(x: 62, y: 16), control2: CGPoint(x: 68, y: 22))
        leftTuft.closeSubpath()
        leftEarContext.fill(leftTuft, with: .color(palette.earTuft))
        leftEarContext.stroke(leftTuft, with: .color(palette.earTuft), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

        // 2. Right Lynx Ear with Tuft (with twitch rotation)
        var rightEarContext = context
        let rightEarPivot = CGPoint(x: 134, y: 84)
        rightEarContext.translateBy(x: rightEarPivot.x, y: rightEarPivot.y)
        rightEarContext.rotate(by: Angle.degrees(Double(rightEarTwitch)))
        rightEarContext.translateBy(x: -rightEarPivot.x, y: -rightEarPivot.y)

        var rightEar = Path()
        rightEar.move(to: CGPoint(x: 144, y: 84))
        rightEar.addLine(to: CGPoint(x: 134, y: 32))
        rightEar.addLine(to: CGPoint(x: 106, y: 68))
        rightEar.closeSubpath()
        rightEarContext.fill(rightEar, with: .linearGradient(furGrad, startPoint: CGPoint(x: 125, y: 32), endPoint: CGPoint(x: 125, y: 84)))
        rightEarContext.stroke(rightEar, with: .color(palette.furDark), lineWidth: 1.8)

        var rightEarInner = Path()
        rightEarInner.move(to: CGPoint(x: 138, y: 80))
        rightEarInner.addLine(to: CGPoint(x: 130, y: 42))
        rightEarInner.addLine(to: CGPoint(x: 110, y: 68))
        rightEarInner.closeSubpath()
        rightEarContext.fill(rightEarInner, with: .color(palette.earInner))

        // Pointed Lynx Ear Tuft
        var rightTuft = Path()
        rightTuft.move(to: CGPoint(x: 134, y: 32))
        rightTuft.addCurve(to: CGPoint(x: 144, y: 8), control1: CGPoint(x: 136, y: 20), control2: CGPoint(x: 140, y: 14))
        rightTuft.addCurve(to: CGPoint(x: 131, y: 34), control1: CGPoint(x: 138, y: 16), control2: CGPoint(x: 132, y: 22))
        rightTuft.closeSubpath()
        rightEarContext.fill(rightTuft, with: .color(palette.earTuft))
        rightEarContext.stroke(rightTuft, with: .color(palette.earTuft), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

        // 3. Head Silhouette with Fluffy Cheeks
        var headPath = Path()
        headPath.move(to: CGPoint(x: 64, y: 78))
        headPath.addCurve(to: CGPoint(x: 68, y: 126), control1: CGPoint(x: 52, y: 92), control2: CGPoint(x: 50, y: 114))
        headPath.addCurve(to: CGPoint(x: 132, y: 126), control1: CGPoint(x: 82, y: 134), control2: CGPoint(x: 118, y: 134))
        headPath.addCurve(to: CGPoint(x: 136, y: 78), control1: CGPoint(x: 150, y: 114), control2: CGPoint(x: 148, y: 92))
        headPath.addCurve(to: CGPoint(x: 64, y: 78), control1: CGPoint(x: 126, y: 66), control2: CGPoint(x: 74, y: 66))
        headPath.closeSubpath()

        context.fill(headPath, with: .linearGradient(furGrad, startPoint: CGPoint(x: 100, y: 32), endPoint: CGPoint(x: 100, y: 134)))
        context.stroke(headPath, with: .color(palette.furDark), lineWidth: 1.8)

        // Fluffy Cheek Wisps
        var leftCheek = Path()
        leftCheek.move(to: CGPoint(x: 50, y: 106))
        leftCheek.addLine(to: CGPoint(x: 42, y: 112))
        leftCheek.addLine(to: CGPoint(x: 52, y: 116))
        leftCheek.addLine(to: CGPoint(x: 44, y: 122))
        leftCheek.addLine(to: CGPoint(x: 58, y: 124))
        context.stroke(leftCheek, with: .color(palette.furDark), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

        var rightCheek = Path()
        rightCheek.move(to: CGPoint(x: 150, y: 106))
        rightCheek.addLine(to: CGPoint(x: 158, y: 112))
        rightCheek.addLine(to: CGPoint(x: 148, y: 116))
        rightCheek.addLine(to: CGPoint(x: 156, y: 122))
        rightCheek.addLine(to: CGPoint(x: 142, y: 124))
        context.stroke(rightCheek, with: .color(palette.furDark), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

        // 4. Forehead Tabby "M" Signature
        var tabbyM1 = Path()
        tabbyM1.move(to: CGPoint(x: 88, y: 68))
        tabbyM1.addLine(to: CGPoint(x: 94, y: 80))
        tabbyM1.addLine(to: CGPoint(x: 100, y: 72))
        tabbyM1.addLine(to: CGPoint(x: 106, y: 80))
        tabbyM1.addLine(to: CGPoint(x: 112, y: 68))
        context.stroke(tabbyM1, with: .color(palette.markings.opacity(0.75)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))

        var tabbyM2 = Path()
        tabbyM2.move(to: CGPoint(x: 92, y: 62))
        tabbyM2.addLine(to: CGPoint(x: 100, y: 66))
        tabbyM2.addLine(to: CGPoint(x: 108, y: 62))
        context.stroke(tabbyM2, with: .color(palette.markings.opacity(0.75)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

        // 5. Expressive Eyes (Awake vs Sleeping)
        if isSleeping {
            // Sleeping closed arcs
            var leftSleep = Path()
            leftSleep.move(to: CGPoint(x: 72, y: 100))
            leftSleep.addQuadCurve(to: CGPoint(x: 92, y: 100), control: CGPoint(x: 82, y: 110))
            context.stroke(leftSleep, with: .color(palette.furDark), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))

            var rightSleep = Path()
            rightSleep.move(to: CGPoint(x: 108, y: 100))
            rightSleep.addQuadCurve(to: CGPoint(x: 128, y: 100), control: CGPoint(x: 118, y: 110))
            context.stroke(rightSleep, with: .color(palette.furDark), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
        } else {
            // Awake eyes with blink scaling
            let eyeGrad = Gradient(colors: [palette.eyes, Color(hex: 0x064E3B)])

            // Left Eye
            let leftPivot = CGPoint(x: 82, y: 98)
            var leftEyeContext = context
            leftEyeContext.translateBy(x: leftPivot.x, y: leftPivot.y)
            leftEyeContext.scaleBy(x: 1.0, y: eyeBlinkScale)
            leftEyeContext.translateBy(x: -leftPivot.x, y: -leftPivot.y)

            let leftEyeRect = CGRect(x: 82 - 10.5, y: 98 - 12.5, width: 21, height: 25)
            leftEyeContext.fill(Path(ellipseIn: leftEyeRect), with: .linearGradient(eyeGrad, startPoint: CGPoint(x: 82, y: 85.5), endPoint: CGPoint(x: 82, y: 110.5)))
            leftEyeContext.stroke(Path(ellipseIn: leftEyeRect), with: .color(palette.furDark), lineWidth: 1.6)

            let leftPupilRect = CGRect(x: 83 - 4.5, y: 98 - 8.5, width: 9, height: 17)
            leftEyeContext.fill(Path(ellipseIn: leftPupilRect), with: .color(Color(hex: 0x0F172A)))

            // Highlights
            leftEyeContext.fill(Path(ellipseIn: CGRect(x: 79 - 3.2, y: 93 - 3.2, width: 6.4, height: 6.4)), with: .color(palette.eyeHighlight))
            leftEyeContext.fill(Path(ellipseIn: CGRect(x: 85 - 1.5, y: 103 - 1.5, width: 3.0, height: 3.0)), with: .color(palette.eyeHighlight))

            // Right Eye
            let rightPivot = CGPoint(x: 118, y: 98)
            var rightEyeContext = context
            rightEyeContext.translateBy(x: rightPivot.x, y: rightPivot.y)
            rightEyeContext.scaleBy(x: 1.0, y: eyeBlinkScale)
            rightEyeContext.translateBy(x: -rightPivot.x, y: -rightPivot.y)

            let rightEyeRect = CGRect(x: 118 - 10.5, y: 98 - 12.5, width: 21, height: 25)
            rightEyeContext.fill(Path(ellipseIn: rightEyeRect), with: .linearGradient(eyeGrad, startPoint: CGPoint(x: 118, y: 85.5), endPoint: CGPoint(x: 118, y: 110.5)))
            rightEyeContext.stroke(Path(ellipseIn: rightEyeRect), with: .color(palette.furDark), lineWidth: 1.6)

            let rightPupilRect = CGRect(x: 117 - 4.5, y: 98 - 8.5, width: 9, height: 17)
            rightEyeContext.fill(Path(ellipseIn: rightPupilRect), with: .color(Color(hex: 0x0F172A)))

            // Highlights
            rightEyeContext.fill(Path(ellipseIn: CGRect(x: 115 - 3.2, y: 93 - 3.2, width: 6.4, height: 6.4)), with: .color(palette.eyeHighlight))
            rightEyeContext.fill(Path(ellipseIn: CGRect(x: 121 - 1.5, y: 103 - 1.5, width: 3.0, height: 3.0)), with: .color(palette.eyeHighlight))
        }

        // 6. Cute Muzzle (Cream base)
        let muzzleRect = CGRect(x: 100 - 16, y: 116 - 10, width: 32, height: 20)
        context.fill(Path(ellipseIn: muzzleRect), with: .color(palette.bib.opacity(0.95)))

        // 7. Pink Nose
        var nosePath = Path()
        nosePath.move(to: CGPoint(x: 96, y: 110))
        nosePath.addLine(to: CGPoint(x: 104, y: 110))
        nosePath.addLine(to: CGPoint(x: 100, y: 115))
        nosePath.closeSubpath()
        context.fill(nosePath, with: .color(palette.nose))
        context.stroke(nosePath, with: .color(palette.furDark), lineWidth: 0.8)

        // 8. Sweet Mouth Line
        var mouthPath = Path()
        mouthPath.move(to: CGPoint(x: 94, y: 118))
        mouthPath.addQuadCurve(to: CGPoint(x: 100, y: 115), control: CGPoint(x: 100, y: 122))
        mouthPath.addQuadCurve(to: CGPoint(x: 106, y: 118), control: CGPoint(x: 100, y: 122))
        context.stroke(mouthPath, with: .color(palette.furDark), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

        // 9. Long Whiskers (White)
        let whiskerColor = Color.white.opacity(0.85)
        var whiskers = Path()
        // Left
        whiskers.move(to: CGPoint(x: 92, y: 114))
        whiskers.addLine(to: CGPoint(x: 48, y: 108))
        whiskers.move(to: CGPoint(x: 91, y: 117))
        whiskers.addLine(to: CGPoint(x: 44, y: 118))
        whiskers.move(to: CGPoint(x: 92, y: 120))
        whiskers.addLine(to: CGPoint(x: 52, y: 128))
        // Right
        whiskers.move(to: CGPoint(x: 108, y: 114))
        whiskers.addLine(to: CGPoint(x: 152, y: 108))
        whiskers.move(to: CGPoint(x: 109, y: 117))
        whiskers.addLine(to: CGPoint(x: 156, y: 118))
        whiskers.move(to: CGPoint(x: 108, y: 120))
        whiskers.addLine(to: CGPoint(x: 148, y: 128))
        context.stroke(whiskers, with: .color(whiskerColor), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

        // 10. Eyebrow Whiskers
        var brows = Path()
        brows.move(to: CGPoint(x: 78, y: 86))
        brows.addQuadCurve(to: CGPoint(x: 68, y: 76), control: CGPoint(x: 72, y: 80))
        brows.move(to: CGPoint(x: 122, y: 86))
        brows.addQuadCurve(to: CGPoint(x: 132, y: 76), control: CGPoint(x: 128, y: 80))
        context.stroke(brows, with: .color(Color.white.opacity(0.8)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }
}
