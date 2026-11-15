//
//  JoySaluteOverlayView.swift
//  Plan4U_iOS
//
//  Spectacular City Day Pyrotechnic Salute & Celebration Confetti Overlay.
//  100% faithful replication of CityDaySaluteOverlay.kt:
//  - 10 choreographed multi-volley bursts across the screen over ~5.5s
//  - Radiant epicenter detonation flashes with glowing white core
//  - 4 particle types: STARS (twinkling 4-point diamonds), SPARKS (hot dots),
//    RIBBONS (fluttering 3D tumbling streamers), RECT (confetti)
//  - 6 festive color palettes: Ruby Magenta, Cyan Emerald, Gold Imperial, Sunset Flame,
//    Violet Electric, Grand Festival
//  - Golden Willow cascading golden rain
//  - High-performance SwiftUI Canvas with 60/120fps TimelineView
//  - Taptic Engine fanfare arpeggio and sound
//

import SwiftUI

private enum SaluteParticleType {
    case star
    case spark
    case ribbon
    case rect
}

private final class SaluteParticle {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    let gravity: CGFloat
    let drag: CGFloat
    let size: CGFloat
    let color: Color
    var rotation: Double
    let rotationSpeed: Double
    var flip: Double
    let flipSpeed: Double
    var sway: Double
    let swaySpeed: Double
    let swayAmount: CGFloat
    let type: SaluteParticleType
    var opacity: Double
    let decay: Double
    let twinkleOffset: Double

    init(
        x: CGFloat,
        y: CGFloat,
        vx: CGFloat,
        vy: CGFloat,
        gravity: CGFloat,
        drag: CGFloat,
        size: CGFloat,
        color: Color,
        rotation: Double,
        rotationSpeed: Double,
        flip: Double,
        flipSpeed: Double,
        sway: Double,
        swaySpeed: Double,
        swayAmount: CGFloat,
        type: SaluteParticleType,
        opacity: Double = 1.0,
        decay: Double,
        twinkleOffset: Double
    ) {
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.gravity = gravity
        self.drag = drag
        self.size = size
        self.color = color
        self.rotation = rotation
        self.rotationSpeed = rotationSpeed
        self.flip = flip
        self.flipSpeed = flipSpeed
        self.sway = sway
        self.swaySpeed = swaySpeed
        self.swayAmount = swayAmount
        self.type = type
        self.opacity = opacity
        self.decay = decay
        self.twinkleOffset = twinkleOffset
    }
}

private final class EpicenterFlash {
    let x: CGFloat
    let y: CGFloat
    var radius: CGFloat
    let maxRadius: CGFloat
    var alpha: Double
    let color: Color

    init(x: CGFloat, y: CGFloat, radius: CGFloat = 14, maxRadius: CGFloat, alpha: Double = 0.95, color: Color) {
        self.x = x
        self.y = y
        self.radius = radius
        self.maxRadius = maxRadius
        self.alpha = alpha
        self.color = color
    }
}

private struct VolleyDef {
    let delayMs: Double
    let xFraction: CGFloat
    let yFraction: CGFloat
    let count: Int
    let palette: [Color]
    let speed: CGFloat
    let spread: CGFloat
    let goldenWillow: Bool

    init(
        delayMs: Double,
        xFraction: CGFloat,
        yFraction: CGFloat,
        count: Int,
        palette: [Color],
        speed: CGFloat,
        spread: CGFloat = 1.0,
        goldenWillow: Bool = false
    ) {
        self.delayMs = delayMs
        self.xFraction = xFraction
        self.yFraction = yFraction
        self.count = count
        self.palette = palette
        self.speed = speed
        self.spread = spread
        self.goldenWillow = goldenWillow
    }
}

public struct JoySaluteOverlayView: View {
    public var onFinished: (() -> Void)?

    @State private var particles: [SaluteParticle] = []
    @State private var flashes: [EpicenterFlash] = []
    @State private var firedVolleys: Set<Int> = []
    @State private var startTime: Date = Date()
    @State private var isRunning: Bool = true

    // 6 Authentic Color Palettes from Android
    private let rubyMagentaPalette: [Color] = [
        Color(hex: 0xFFFF007F), Color(hex: 0xFFFF4D80), Color(hex: 0xFFF72585),
        Color(hex: 0xFFB5179E), Color(hex: 0xFFFFB703), Color.white
    ]

    private let cyanEmeraldPalette: [Color] = [
        Color(hex: 0xFF00F5D4), Color(hex: 0xFF06D6A0), Color(hex: 0xFF00BBF9),
        Color(hex: 0xFF48CAE4), Color(hex: 0xFF90E0EF), Color.white
    ]

    private let goldImperialPalette: [Color] = [
        Color(hex: 0xFFFFD700), Color(hex: 0xFFFFC300), Color(hex: 0xFFFFAA00),
        Color(hex: 0xFFFFE600), Color(hex: 0xFFFFF3B0), Color.white, Color(hex: 0xFFFFB703)
    ]

    private let sunsetFlamePalette: [Color] = [
        Color(hex: 0xFFFF3366), Color(hex: 0xFFFF6B6B), Color(hex: 0xFFFF9E00),
        Color(hex: 0xFFFFD000), Color(hex: 0xFFFF5400), Color.white
    ]

    private let violetElectricPalette: [Color] = [
        Color(hex: 0xFF7209B7), Color(hex: 0xFF8338EC), Color(hex: 0xFF3A0CA3),
        Color(hex: 0xFF4CC9F0), Color(hex: 0xFFF72585), Color(hex: 0xFFE0AAFF)
    ]

    private let grandFestivalPalette: [Color] = [
        Color(hex: 0xFFFF0055), Color(hex: 0xFF00F5D4), Color(hex: 0xFFFFD700),
        Color(hex: 0xFF8338EC), Color(hex: 0xFF06D6A0), Color(hex: 0xFFFF9E00),
        Color(hex: 0xFF4CC9F0), Color.white, Color(hex: 0xFFFF3366)
    ]

    private var volleySchedule: [VolleyDef] {
        [
            // 1. Ruby Magenta opening on mid-left
            VolleyDef(delayMs: 0, xFraction: 0.28, yFraction: 0.38, count: 36, palette: rubyMagentaPalette, speed: 10.0),
            // 2. High shot on right (Cyan Emerald)
            VolleyDef(delayMs: 380, xFraction: 0.74, yFraction: 0.24, count: 40, palette: cyanEmeraldPalette, speed: 11.0),
            // 3. Imperial Gold center peony
            VolleyDef(delayMs: 820, xFraction: 0.50, yFraction: 0.42, count: 32, palette: goldImperialPalette, speed: 9.0),
            // 4. Electric Violet high left
            VolleyDef(delayMs: 1320, xFraction: 0.18, yFraction: 0.28, count: 38, palette: violetElectricPalette, speed: 10.5),
            // 5. Sunset Flame high right
            VolleyDef(delayMs: 1850, xFraction: 0.82, yFraction: 0.20, count: 40, palette: sunsetFlamePalette, speed: 11.5),
            // 6. Synchronous flanks duo (Emerald + Magenta)
            VolleyDef(delayMs: 2450, xFraction: 0.26, yFraction: 0.32, count: 32, palette: cyanEmeraldPalette, speed: 10.0),
            VolleyDef(delayMs: 2450, xFraction: 0.74, yFraction: 0.32, count: 32, palette: rubyMagentaPalette, speed: 10.0),
            // 7. "Golden Willow" zenith cascade
            VolleyDef(delayMs: 3100, xFraction: 0.50, yFraction: 0.16, count: 50, palette: goldImperialPalette, speed: 12.0, goldenWillow: true),
            // 8. Quick pre-climax doublet
            VolleyDef(delayMs: 3700, xFraction: 0.36, yFraction: 0.26, count: 35, palette: sunsetFlamePalette, speed: 10.5),
            VolleyDef(delayMs: 3700, xFraction: 0.64, yFraction: 0.26, count: 35, palette: violetElectricPalette, speed: 10.5),
            // 9. GRAND FINALE! Massive triple sky burst
            VolleyDef(delayMs: 4250, xFraction: 0.50, yFraction: 0.22, count: 70, palette: grandFestivalPalette, speed: 14.0, spread: 1.3),
            VolleyDef(delayMs: 4250, xFraction: 0.20, yFraction: 0.34, count: 36, palette: goldImperialPalette, speed: 10.5),
            VolleyDef(delayMs: 4250, xFraction: 0.80, yFraction: 0.34, count: 36, palette: cyanEmeraldPalette, speed: 10.5)
        ]
    }

    public init(onFinished: (() -> Void)? = nil) {
        self.onFinished = onFinished
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            TimelineView(.animation) { timeline in
                Canvas { context, canvasSize in
                    let now = timeline.date
                    let elapsedMs = now.timeIntervalSince(startTime) * 1000.0

                    // 1. Process choreographed burst launches
                    for (index, volley) in volleySchedule.enumerated() {
                        if !firedVolleys.contains(index) && elapsedMs >= volley.delayMs {
                            firedVolleys.insert(index)
                            spawnBurst(
                                cx: size.width * volley.xFraction,
                                cy: size.height * volley.yFraction,
                                count: volley.count,
                                palette: volley.palette,
                                speed: volley.speed,
                                spread: volley.spread,
                                isGoldenWillow: volley.goldenWillow
                            )
                        }
                    }

                    // 2. Render and update Epicenter Detonation Flashes
                    for flash in flashes {
                        if flash.alpha > 0.01 && flash.radius > 1 {
                            let a = max(0, min(1, flash.alpha))
                            let outerRect = CGRect(
                                x: flash.x - flash.radius,
                                y: flash.y - flash.radius,
                                width: flash.radius * 2,
                                height: flash.radius * 2
                            )
                            context.fill(Path(ellipseIn: outerRect), with: .color(flash.color.opacity(a * 0.45)))

                            let innerR = flash.radius * 0.4
                            let innerRect = CGRect(
                                x: flash.x - innerR,
                                y: flash.y - innerR,
                                width: innerR * 2,
                                height: innerR * 2
                            )
                            context.fill(Path(ellipseIn: innerRect), with: .color(Color.white.opacity(a * 0.85)))
                        }
                        flash.radius += (flash.maxRadius - flash.radius) * 0.28
                        flash.alpha -= 0.085
                    }
                    flashes.removeAll { $0.alpha <= 0 }

                    // 3. Render and update Particles
                    var aliveCount = 0
                    for p in particles {
                        if p.opacity <= 0 || p.y > size.height + 150 { continue }
                        aliveCount += 1

                        let alpha = max(0, min(1, p.opacity))
                        let pColor = p.color.opacity(alpha)

                        switch p.type {
                        case .spark:
                            let rect = CGRect(x: p.x - p.size, y: p.y - p.size, width: p.size * 2, height: p.size * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(pColor))

                        case .star:
                            let twinkle = 1.0 + 0.22 * sin(elapsedMs * 0.012 + p.twinkleOffset)
                            let r = p.size * CGFloat(twinkle)
                            var starContext = context
                            starContext.translateBy(x: p.x, y: p.y)
                            starContext.rotate(by: Angle(radians: p.rotation))

                            // Outer glow
                            let glowRect = CGRect(x: -r * 1.3, y: -r * 1.3, width: r * 2.6, height: r * 2.6)
                            starContext.fill(Path(ellipseIn: glowRect), with: .color(pColor.opacity(alpha * 0.35)))

                            // 4-pointed cross bars
                            let w = r * 1.1
                            let h = r * 0.28
                            starContext.fill(Path(CGRect(x: -w, y: -h, width: w * 2, height: h * 2)), with: .color(pColor))
                            starContext.fill(Path(CGRect(x: -h, y: -w, width: h * 2, height: w * 2)), with: .color(pColor))

                            // Hot center
                            let centerRect = CGRect(x: -h, y: -h, width: h * 2, height: h * 2)
                            starContext.fill(Path(ellipseIn: centerRect), with: .color(Color.white.opacity(alpha * 0.9)))

                        case .ribbon:
                            var ribbonContext = context
                            ribbonContext.translateBy(x: p.x, y: p.y)
                            ribbonContext.rotate(by: Angle(radians: p.rotation))
                            let scaleX = max(0.06, abs(sin(p.flip)))
                            let rw = p.size * 1.25 * CGFloat(scaleX)
                            let rh = p.size * 0.45
                            ribbonContext.fill(Path(CGRect(x: -rw / 2, y: -rh / 2, width: rw, height: rh)), with: .color(pColor))

                        case .rect:
                            var rectContext = context
                            rectContext.translateBy(x: p.x, y: p.y)
                            rectContext.rotate(by: Angle(radians: p.rotation))
                            let scaleY = max(0.06, abs(cos(p.flip)))
                            let rw = p.size
                            let rh = p.size * 0.7 * CGFloat(scaleY)
                            rectContext.fill(Path(CGRect(x: -rw / 2, y: -rh / 2, width: rw, height: rh)), with: .color(pColor))
                        }

                        // Physics step
                        p.x += p.vx + CGFloat(sin(p.sway)) * p.swayAmount
                        p.y += p.vy
                        p.vy += p.gravity
                        p.vx *= p.drag
                        p.vy *= p.drag
                        p.sway += p.swaySpeed
                        p.rotation += p.rotationSpeed
                        p.flip += p.flipSpeed
                        p.opacity = max(0, p.opacity - p.decay)
                    }

                    particles.removeAll { $0.opacity <= 0 || $0.y > size.height + 150 }

                    if aliveCount == 0 && elapsedMs >= 5500 && flashes.isEmpty && isRunning {
                        DispatchQueue.main.async {
                            isRunning = false
                            onFinished?()
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .contentShape(Rectangle())
        .onTapGesture {
            // Instant dismiss on user tap
            isRunning = false
            onFinished?()
        }
        .onAppear {
            startTime = Date()
            MiodiHapticFeedback.triumphSalute()
            MiodiAudioManager.shared.playDing()
        }
    }

    private func spawnBurst(
        cx: CGFloat,
        cy: CGFloat,
        count: Int,
        palette: [Color],
        speed: CGFloat,
        spread: CGFloat,
        isGoldenWillow: Bool
    ) {
        // Detonation Flash
        flashes.append(
            EpicenterFlash(
                x: cx,
                y: cy,
                radius: 14 * 2.0,
                maxRadius: 80 * spread * 2.0,
                alpha: 0.95,
                color: palette.first ?? Color.white
            )
        )

        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let baseSpeed = CGFloat(Double.random(in: 0.15...1.0)) * speed * spread * 2.0
            let typeRoll = Double.random(in: 0...1.0)
            var pType: SaluteParticleType = .rect
            if typeRoll < 0.28 { pType = .star }
            else if typeRoll < 0.54 { pType = .spark }
            else if typeRoll < 0.76 { pType = .ribbon }

            if isGoldenWillow && Double.random(in: 0...1.0) < 0.65 {
                pType = .spark
            }

            let gravity: CGFloat = isGoldenWillow ? 0.26 : (pType == .spark ? 0.44 : 0.32)
            let drag: CGFloat = isGoldenWillow ? 0.980 : (pType == .spark ? 0.974 : 0.967)

            let rawSize: CGFloat
            switch pType {
            case .ribbon: rawSize = CGFloat.random(in: 10...22)
            case .spark:  rawSize = CGFloat.random(in: 3.5...8.0)
            default:      rawSize = CGFloat.random(in: 6.5...15.0)
            }

            let decay = isGoldenWillow ? Double.random(in: 0.0025...0.0057) : Double.random(in: 0.0035...0.0080)

            particles.append(
                SaluteParticle(
                    x: cx,
                    y: cy,
                    vx: CGFloat(cos(angle)) * baseSpeed,
                    vy: CGFloat(sin(angle)) * baseSpeed * 0.86,
                    gravity: gravity,
                    drag: drag,
                    size: rawSize,
                    color: palette.randomElement() ?? Color.white,
                    rotation: Double.random(in: 0...(2 * .pi)),
                    rotationSpeed: Double.random(in: -0.18...0.18),
                    flip: Double.random(in: 0...(2 * .pi)),
                    flipSpeed: Double.random(in: 0.08...0.24),
                    sway: Double.random(in: 0...(2 * .pi)),
                    swaySpeed: Double.random(in: 0.03...0.09),
                    swayAmount: CGFloat.random(in: 0.4...1.2),
                    type: pType,
                    opacity: 1.0,
                    decay: decay,
                    twinkleOffset: Double.random(in: 0...10.0)
                )
            )
        }
    }
}
