//
//  NotebookCoverOpeningOverlayView.swift
//  Plan4U_iOS
//
//  Cinematic 3D Notebook Cover Opening Animation matching Android NotebookCoverOpeningOverlay.kt 1-to-1.
//  Features authentic leather/paper cover, golden/debossed Miodi logo embossing, dynamic inner shadow,
//  specular lighting sweep, tap-to-skip, and haptic feedback.
//

import SwiftUI

public struct NotebookCoverOpeningOverlayView: View {
    public var isDarkTheme: Bool = false
    public var onFinished: () -> Void = {}

    @State private var progress: CGFloat = 0.0
    @State private var hasStarted: Bool = false
    @State private var isSkipped: Bool = false

    public init(
        isDarkTheme: Bool = false,
        onFinished: @escaping () -> Void = {}
    ) {
        self.isDarkTheme = isDarkTheme
        self.onFinished = onFinished
    }

    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // 1. Dynamic shadow cast on the notebook page beneath as the cover opens
                if progress > 0.005 && progress < 0.999 {
                    let shadowAlpha = (1.0 - progress) * 0.45
                    LinearGradient(
                        colors: [
                            Color.black.opacity(shadowAlpha),
                            Color.black.opacity(shadowAlpha * 0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: UnitPoint(x: 220.0 / max(width, 1), y: 0.5)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                }

                // 2. 3D Rotating Cover Leaf (hinged on left spine edge)
                coverPageView(width: width, height: height)
                    .rotation3DEffect(
                        .degrees(-115.0 * Double(progress)),
                        axis: (x: 0.0, y: 1.0, z: 0.0),
                        anchor: .leading,
                        anchorZ: 0.0,
                        perspective: 0.35
                    )
                    .opacity(progress < 0.88 ? 1.0 : Double((1.0 - progress) / 0.12).clamped(to: 0...1))
                    .shadow(
                        color: Color.black.opacity(progress > 0.01 ? 0.35 * (1.0 - progress) : 0.0),
                        radius: 20 * (1.0 - progress),
                        x: 10 * (1.0 - progress),
                        y: 4
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                skipAnimation()
            }
        }
        .ignoresSafeArea()
        .zIndex(999)
        .onAppear {
            startCoverAnimation()
        }
    }

    // MARK: - Cover Page Content & Textures
    @ViewBuilder
    private func coverPageView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Base cover texture & gradient (warm rich notebook leather / dark titanium)
            if isDarkTheme {
                LinearGradient(
                    colors: [
                        Color(hex: 0x181A22),
                        Color(hex: 0x12141C),
                        Color(hex: 0x0E1017)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: 0xFDFBF7),
                        Color(hex: 0xF7F2E9),
                        Color(hex: 0xECE4D4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Left Spine binding stitched line and shadow
            HStack(spacing: 0) {
                // Spine edge border
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(isDarkTheme ? 0.45 : 0.18),
                                Color.black.opacity(isDarkTheme ? 0.2 : 0.05),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 24)

                Spacer()
            }

            // Spine stitching dashed line
            HStack(spacing: 0) {
                Rectangle()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
                    .foregroundStyle(
                        isDarkTheme
                            ? Color(hex: 0xD4AF37).opacity(0.35)
                            : Color(hex: 0x8A725D).opacity(0.35)
                    )
                    .frame(width: 1)
                    .padding(.leading, 18)

                Spacer()
            }

            // Outer golden/debossed double-frame perimeter border
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            (isDarkTheme ? Color(hex: 0xD4AF37) : Color(hex: 0xB38F60)).opacity(0.45),
                            (isDarkTheme ? Color(hex: 0xF5E6A3) : Color(hex: 0xD9BE9B)).opacity(0.2),
                            (isDarkTheme ? Color(hex: 0xD4AF37) : Color(hex: 0xB38F60)).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(.leading, 28)
                .padding(.trailing, 16)
                .padding(.vertical, 20)

            // Dynamic lighting specular sheen sweep while turning
            if progress > 0.005 {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08 * progress),
                        Color.white.opacity(0.12 * (1.0 - progress)),
                        Color.black.opacity(0.15 * progress)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .allowsHitTesting(false)
            }

            // Embossed Miodi Medallion & Title in the Center
            VStack(spacing: 14) {
                // Circular App Icon with subtle debossed frame
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    isDarkTheme ? Color(hex: 0x222633) : Color(hex: 0xFFFFFF),
                                    isDarkTheme ? Color(hex: 0x161822) : Color(hex: 0xF3EFE7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 104, height: 104)
                        .shadow(
                            color: Color.black.opacity(isDarkTheme ? 0.6 : 0.15),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: 0xD4AF37).opacity(0.8),
                                            Color(hex: 0xF5E6A3).opacity(0.3),
                                            Color(hex: 0xD4AF37).opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.0
                                )
                        )

                    // App mascot icon / cat logo
                    Text("🐱")
                        .font(.system(size: 48))
                }

                // Debossed / Gold foil "Miodi"
                Text("Miodi")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .tracking(2.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: isDarkTheme
                                ? [Color(hex: 0xF5E6A3), Color(hex: 0xD4AF37), Color(hex: 0xAA8232)]
                                : [Color(hex: 0x5D4037), Color(hex: 0x3E2723), Color(hex: 0x271916)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: isDarkTheme ? Color.black.opacity(0.8) : Color.white.opacity(0.9),
                        radius: 1,
                        x: 0,
                        y: 1
                    )

                // Subtitle
                Text("УМНЫЙ БЛОКНОТ • LIFE PLANNER")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(3.0)
                    .foregroundStyle(
                        isDarkTheme
                            ? Color(hex: 0xD4AF37).opacity(0.7)
                            : Color(hex: 0x8D6E63)
                    )

                // Small decorative laurel / ribbon flourish
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(isDarkTheme ? Color(hex: 0xD4AF37).opacity(0.4) : Color(hex: 0xBCAAA4))
                        .frame(width: 32, height: 1)
                    Text("✦")
                        .font(.system(size: 9))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0xD4AF37) : Color(hex: 0x8D6E63))
                    Rectangle()
                        .fill(isDarkTheme ? Color(hex: 0xD4AF37).opacity(0.4) : Color(hex: 0xBCAAA4))
                        .frame(width: 32, height: 1)
                }
            }
            .padding(.leading, 12)
        }
        .frame(width: width, height: height)
        .clipped()
    }

    // MARK: - Animation Logic
    private func startCoverAnimation() {
        guard !hasStarted else { return }
        hasStarted = true

        // 300ms pause so the user's eye registers the pristine notebook cover
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            guard !isSkipped else { return }
            MiodiHapticFeedback.lightClick()

            withAnimation(.easeInOut(duration: 1.45)) {
                progress = 1.0
            }

            // Finish after 1.45s animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.48) {
                if !isSkipped {
                    onFinished()
                }
            }
        }
    }

    private func skipAnimation() {
        guard !isSkipped else { return }
        isSkipped = true
        MiodiHapticFeedback.selection()
        withAnimation(.easeOut(duration: 0.15)) {
            progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            onFinished()
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
