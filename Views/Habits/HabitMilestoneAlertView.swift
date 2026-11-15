//
//  HabitMilestoneAlertView.swift
//  Plan4U_iOS
//
//  Festive celebration modal for habit streak milestones:
//  7 Days (First Spark), 21 Days (Neural Pathway), 66 Days (Automaticity), 100 Days (Century Mastery).
//  Includes particle confetti burst, celebratory haptics, victory audio, and inspirational science-backed quotes.
//

import SwiftUI

public struct HabitMilestone: Identifiable, Sendable {
    public let id = UUID()
    public let days: Int
    public let habitTitle: String
    public let tierName: String
    public let badgeEmoji: String
    public let headline: String
    public let explanation: String
    public let quote: String
    public let quoteAuthor: String
    public let badgeGradient: [Color]

    public init(days: Int, habitTitle: String) {
        self.days = days
        self.habitTitle = habitTitle

        switch days {
        case 7:
            self.tierName = "Рубеж 1 • Бронза"
            self.badgeEmoji = "🔥"
            self.headline = "Первый рубеж пройден!"
            self.explanation = "Вы сформировали устойчивый импульс. Первая неделя — самая сложная, но ваша решимость оказалась сильнее лени!"
            self.quote = "Маленькие ежедневные шаги приводят к колоссальным переменам. Начало пути уже преодолено!"
            self.quoteAuthor = "Конфуций"
            self.badgeGradient = [Color(hex: 0xF59E0B), Color(hex: 0xD97706)]
        case 21:
            self.tierName = "Рубеж 2 • Серебро"
            self.badgeEmoji = "🧠"
            self.headline = "Рождение новой привычки!"
            self.explanation = "21 день стойкости! В вашем мозге закрепились новые нейронные пути. Действие перестало требовать сверхусилий и стало привычным ритмом."
            self.quote = "Мы — то, что мы делаем изо дня в день. Совершенство — не действие, а привычка."
            self.quoteAuthor = "Аристотель"
            self.badgeGradient = [Color(hex: 0x8B5CF6), Color(hex: 0x6366F1)]
        case 66:
            self.tierName = "Рубеж 3 • Золото"
            self.headline = "Полный автопилот!"
            self.badgeEmoji = "⚡"
            self.explanation = "Исследования University College London доказали: ровно 66 дней требуется человеку для достижения абсолютного автоматизма. Привычка стала частью вашей личности!"
            self.quote = "Успех — это сумма небольших побед, повторяющихся день за днем без перерывов."
            self.quoteAuthor = "Роберт Кольер"
            self.badgeGradient = [Color(hex: 0xEC4899), Color(hex: 0xF43F5E)]
        case 100:
            self.tierName = "Легенда • Платина"
            self.badgeEmoji = "👑"
            self.headline = "Клуб сотни! Легендарный век"
            self.explanation = "100 дней непрерывного триумфа! Менее 1% людей в мире обладают такой несгибаемой волей и дисциплиной. Вы — пример для подражания!"
            self.quote = "Невозможно победить того, кто никогда не сдается и продолжает действовать."
            self.quoteAuthor = "Бэйб Рут"
            self.badgeGradient = [Color(hex: 0xEAB308), Color(hex: 0xF59E0B), Color(hex: 0xEF4444)]
        default:
            self.tierName = "\(days) Дней Побед"
            self.badgeEmoji = "🌟"
            self.headline = "Потрясающая серия!"
            self.explanation = "Вы продолжаете уверенно двигаться вперед и удерживать непрерывную серию!"
            self.quote = "Постоянство побеждает любой талант."
            self.quoteAuthor = "Народная мудрость"
            self.badgeGradient = [Color(hex: 0x10B981), Color(hex: 0x059669)]
        }
    }
}

public struct HabitMilestoneAlertView: View {
    public let milestone: HabitMilestone
    public var onDismiss: () -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var appearScale: CGFloat = 0.5
    @State private var appearOpacity: Double = 0.0
    @State private var glowRotation: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(milestone: HabitMilestone, onDismiss: @escaping () -> Void) {
        self.milestone = milestone
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Dark Frosted Backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Confetti Particle Explosion
            CelebrationConfettiView()
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // Main Alert Card
            VStack(spacing: 0) {
                // Glow Halo Behind Badge
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: milestone.badgeGradient + [milestone.badgeGradient.first ?? .yellow],
                                center: .center
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 28)
                        .opacity(0.6)
                        .rotationEffect(.degrees(glowRotation))

                    // Badge Container
                    VStack(spacing: 2) {
                        Text(milestone.badgeEmoji)
                            .font(.system(size: 34))

                        Text("\(milestone.days)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("ДНЕЙ")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .tracking(1.5)
                    }
                    .frame(width: 96, height: 96)
                    .background(
                        LinearGradient(
                            colors: milestone.badgeGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 3)
                    )
                    .shadow(color: milestone.badgeGradient.first?.opacity(0.5) ?? .clear, radius: 14, y: 6)
                    .scaleEffect(pulseScale)
                }
                .padding(.top, -48)
                .padding(.bottom, 12)

                // Tier Pill
                let pillColor = milestone.badgeGradient.first ?? theme.currentAccent.primary
                Text(milestone.tierName.uppercased())
                    .font(.system(size: 10.5, weight: .extrabold))
                    .tracking(1.2)
                    .foregroundStyle(pillColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(pillColor.opacity(0.14))
                    )
                    .padding(.bottom, 6)

                // Headline
                Text(milestone.headline)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(isDark ? Color.white : Color(hex: 0x0F172A))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

                // Habit title label
                HStack(spacing: 4) {
                    Text("Привычка:")
                        .foregroundStyle(.secondary)
                    Text("«\(milestone.habitTitle)»")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.currentAccent.primary)
                }
                .font(.system(size: 13))
                .padding(.bottom, 14)

                // Explanation
                Text(milestone.explanation)
                    .font(.system(size: 13.5))
                    .lineSpacing(2)
                    .foregroundStyle(isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)

                // Quote Card
                VStack(spacing: 6) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("“")
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundStyle(theme.currentAccent.primary.opacity(0.6))
                            .offset(y: -4)

                        Text(milestone.quote)
                            .font(.system(size: 12.5, weight: .medium, design: .serif))
                            .italic()
                            .foregroundStyle(isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155))
                            .lineSpacing(1.5)
                    }

                    HStack {
                        Spacer()
                        Text("— \(milestone.quoteAuthor)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isDark ? Color(hex: 0x1E293B) : Color(hex: 0xF1F5F9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 22)

                // Action Button: "Продолжить побеждать! 🚀"
                Button {
                    MiodiHapticFeedback.lightClick()
                    onDismiss()
                } label: {
                    HStack(spacing: 8) {
                        Text("Продолжить путь!")
                            .font(.system(size: 15, weight: .bold))
                        Text("🚀")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [theme.currentAccent.primary, theme.currentAccent.primary.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: theme.currentAccent.primary.opacity(0.35), radius: 8, y: 3)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(isDark ? Color(hex: 0x141A28) : Color.white)
                    .shadow(color: Color.black.opacity(0.35), radius: 24, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(isDark ? Color(hex: 0x2A354E) : Color.black.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
        }
        .onAppear {
            // Audio fanfare + Taptic celebration
            MiodiHapticFeedback.celebrationFanfare()
            MiodiAudioManager.shared.playTriumphFanfare()

            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }

            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }

            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
            }
        }
    }
}

// MARK: - Celebration Confetti Particles Canvas
private struct CelebrationConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var startTime = Date.now

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                for p in particles {
                    let progress = min(1.0, elapsed / p.duration)
                    if progress >= 1.0 { continue }

                    let currentY = p.startY + (size.height + 100) * progress * p.speedMultiplier
                    let currentX = p.startX + sin(progress * p.swayFrequency * .pi * 2) * p.swayAmplitude
                    let currentRotation = p.initialRotation + progress * p.rotationSpeed * 360
                    let alpha = progress > 0.8 ? (1.0 - progress) / 0.2 : 1.0

                    context.opacity = alpha
                    var shapeContext = context
                    shapeContext.translateBy(x: currentX, y: currentY)
                    shapeContext.rotate(by: .degrees(currentRotation))

                    let rect = CGRect(x: -p.size.width / 2, y: -p.size.height / 2, width: p.size.width, height: p.size.height)
                    if p.isCircle {
                        shapeContext.fill(Circle().path(in: rect), with: .color(p.color))
                    } else {
                        shapeContext.fill(RoundedRectangle(cornerRadius: 2).path(in: rect), with: .color(p.color))
                    }
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        let colors: [Color] = [
            Color(hex: 0xF43F5E), Color(hex: 0xFB7185), Color(hex: 0xF59E0B),
            Color(hex: 0x10B981), Color(hex: 0x38BDF8), Color(hex: 0x8B5CF6),
            Color(hex: 0xEAB308), Color(hex: 0xEC4899)
        ]
        var list: [ConfettiParticle] = []
        for _ in 0..<85 {
            let p = ConfettiParticle(
                startX: CGFloat.random(in: 20...380),
                startY: CGFloat.random(in: -120 ... -10),
                duration: Double.random(in: 2.2 ... 4.5),
                speedMultiplier: CGFloat.random(in: 0.7 ... 1.3),
                swayAmplitude: CGFloat.random(in: 15 ... 55),
                swayFrequency: CGFloat.random(in: 1.0 ... 3.0),
                initialRotation: Double.random(in: 0 ... 360),
                rotationSpeed: Double.random(in: 0.8 ... 2.5),
                size: CGSize(width: CGFloat.random(in: 6 ... 12), height: CGFloat.random(in: 6 ... 14)),
                isCircle: Bool.random(),
                color: colors.randomElement() ?? .pink
            )
            list.append(p)
        }
        particles = list
        startTime = Date.now
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let duration: Double
    let speedMultiplier: CGFloat
    let swayAmplitude: CGFloat
    let swayFrequency: CGFloat
    let initialRotation: Double
    let rotationSpeed: Double
    let size: CGSize
    let isCircle: Bool
    let color: Color
}
