//
//  TopWidgetsBarView.swift
//  Plan4U_iOS
//
//  1:1 Port of Android TopWidgetsBar.kt.
//  Displays the signature glossy rose gradient bar with circle quick access slots:
//  - Slot 0: Date circle (dayNumber, dayOfWeek)
//  - Slot 1: Tasks progress circle (completed / total with circular ring)
//  - Slot 2: Streak flame circle (streak count)
//  - Slot 3: Achievements / Stickers sparkle
//  - Right Slot: Settings gear / Hub icon
//

import SwiftUI

public struct TopWidgetsBarView: View {
    public var dayNumber: String = "25"
    public var dayOfWeek: String = "пт"
    public var completedTasks: Int = 0
    public var totalTasks: Int = 0
    public var streakCount: Int = 0

    public var onDateClick: () -> Void = {}
    public var onTasksClick: () -> Void = {}
    public var onStreakClick: () -> Void = {}
    public var onStickersClick: () -> Void = {}
    public var onSettingsClick: () -> Void = {}

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public init(
        dayNumber: String = "25",
        dayOfWeek: String = "пт",
        completedTasks: Int = 0,
        totalTasks: Int = 0,
        streakCount: Int = 0,
        onDateClick: @escaping () -> Void = {},
        onTasksClick: @escaping () -> Void = {},
        onStreakClick: @escaping () -> Void = {},
        onStickersClick: @escaping () -> Void = {},
        onSettingsClick: @escaping () -> Void = {}
    ) {
        self.dayNumber = dayNumber
        self.dayOfWeek = dayOfWeek
        self.completedTasks = completedTasks
        self.totalTasks = totalTasks
        self.streakCount = streakCount
        self.onDateClick = onDateClick
        self.onTasksClick = onTasksClick
        self.onStreakClick = onStreakClick
        self.onStickersClick = onStickersClick
        self.onSettingsClick = onSettingsClick
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 1. Date Circle Widget
                Button {
                    MiodiHapticFeedback.lightClick()
                    onDateClick()
                } label: {
                    VStack(spacing: -1) {
                        Text(dayNumber)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E2229))
                        Text(dayOfWeek.lowercased())
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                    }
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.08), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isDark ? 0.1 : 0.6), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                // 2. Tasks Progress Widget
                Button {
                    MiodiHapticFeedback.lightClick()
                    onTasksClick()
                } label: {
                    ZStack {
                        let ratio: CGFloat = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0
                        Circle()
                            .stroke(isDark ? Color(hex: 0x2A3346) : Color(hex: 0xE2E8F0), lineWidth: 2.2)

                        if ratio > 0 {
                            Circle()
                                .trim(from: 0, to: min(max(ratio, 0), 1))
                                .stroke(Color(hex: 0x3B82F6), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }

                        VStack(spacing: -2) {
                            Text("\(completedTasks)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E2229))
                            Text("/ \(totalTasks)")
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.08), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                // 3. Streak Flame Widget (Centerpiece)
                Button {
                    MiodiHapticFeedback.lightClick()
                    onStreakClick()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: 0xF59E0B), Color(hex: 0xEF4444)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.4
                            )

                        VStack(spacing: -1) {
                            Text("🔥")
                                .font(.system(size: 14))
                            Text("\(streakCount)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color(hex: 0xF59E0B))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                            .shadow(color: Color(hex: 0xF59E0B).opacity(0.3), radius: 6, x: 0, y: 3)
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                // 4. Stickers / Magic Sparkle Widget
                Button {
                    MiodiHapticFeedback.lightClick()
                    onStickersClick()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.08), radius: 4, x: 0, y: 2)

                        Image(systemName: "sparkles")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(theme.currentAccent.primary)
                    }
                    .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                // 5. Settings Gear Widget
                Button {
                    MiodiHapticFeedback.lightClick()
                    onSettingsClick()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.08), radius: 4, x: 0, y: 2)

                        Image(systemName: "gearshape")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569))
                    }
                    .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: isDark
                        ? [Color(hex: 0x1E2433), Color(hex: 0x14171F)]
                        : [Color(hex: 0xFFF1F5), Color(hex: 0xFCE7F3), Color(hex: 0xFFF5F8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Bottom Gloss Divider
            Rectangle()
                .fill(Color.white.opacity(isDark ? 0.12 : 0.8))
                .frame(height: 1.5)
        }
    }
}
