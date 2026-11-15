//
//  WeekDaysBarView.swift
//  Plan4U_iOS
//
//  Pixel-perfect replica of Miodi Android WeekDaysBar.kt
//  7 circular day progress rings with haptic feedback.
//  When drawer is expanded, smoothly slides in "+ Привычка" button on the left.
//

import SwiftUI

public struct DayItemModel: Identifiable, Sendable {
    public let id = UUID()
    public let dayName: String
    public let dateStr: String
    public let isToday: Bool
    public var progress: Double // 0.0 ... 1.0 (habits completed)

    public init(dayName: String, dateStr: String, isToday: Bool = false, progress: Double = 0.0) {
        self.dayName = dayName
        self.dateStr = dateStr
        self.isToday = isToday
        self.progress = progress
    }
}

public struct WeekDaysBarView: View {
    public var days: [DayItemModel]
    public var isDrawerExpanded: Bool = false
    public var onSelectDay: (DayItemModel) -> Void = { _ in }
    public var onAddHabitClick: (() -> Void)? = nil
    public var onToggleDrawer: (() -> Void)? = nil

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public init(
        days: [DayItemModel] = [],
        isDrawerExpanded: Bool = false,
        onSelectDay: @escaping (DayItemModel) -> Void = { _ in },
        onAddHabitClick: (() -> Void)? = nil,
        onToggleDrawer: (() -> Void)? = nil
    ) {
        self.days = days
        self.isDrawerExpanded = isDrawerExpanded
        self.onSelectDay = onSelectDay
        self.onAddHabitClick = onAddHabitClick
        self.onToggleDrawer = onToggleDrawer
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Left Slot: "+ Привычка" button (expands when drawer is open)
            if isDrawerExpanded {
                Button {
                    MiodiHapticFeedback.lightClick()
                    onAddHabitClick?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Привычка")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(theme.currentAccent.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(theme.currentAccent.primary.opacity(isDark ? 0.22 : 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(theme.currentAccent.primary, lineWidth: 1.2)
                    )
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .frame(maxWidth: 110)
            }

            // Right Track: 7 Week circles (smoothly shifts)
            HStack(spacing: 0) {
                ForEach(days) { day in
                    DayCircleView(day: day, isDark: isDark) {
                        MiodiHapticFeedback.selection()
                        onSelectDay(day)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isDrawerExpanded)
        .frame(height: 48)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onToggleDrawer?()
        }
    }
}

private struct DayCircleView: View {
    let day: DayItemModel
    let isDark: Bool
    let onTap: () -> Void

    @Environment(MiodiThemeManager.self) private var theme

    private var isWeekend: Bool {
        let name = day.dayName.lowercased()
        return name == "сб" || name == "вс" || name == "sat" || name == "sun"
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background Track Circle
                Circle()
                    .stroke(
                        day.isToday
                            ? theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.25)
                            : (isDark ? Color(hex: 0x2E384D) : Color(hex: 0xE2E8F0)),
                        lineWidth: 2.2
                    )
                    .background(
                        Circle().fill(
                            day.isToday
                                ? (isDark ? theme.currentAccent.darkSectionBg : theme.currentAccent.sectionBg)
                                : (isDark ? Color(hex: 0x1E2433) : Color.white)
                        )
                    )

                // Progress Arc (habit completions)
                if day.progress > 0.04 {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(day.progress, 0), 1)))
                        .stroke(
                            theme.currentAccent.primary,
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                // Day Label
                Text(day.dayName)
                    .font(.system(size: 12, weight: day.isToday ? .bold : .medium))
                    .foregroundStyle(
                        day.isToday
                            ? (isDark ? .white : theme.currentAccent.sectionText)
                            : (isWeekend ? (isDark ? Color(hex: 0x64748B) : Color(hex: 0x838A98)) : (isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x3B404D)))
                    )

                // Verified Badge (Green Checkmark when all habits completed)
                if day.allHabitsDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: 0x10B981))
                        .background(Circle().fill(Color.white).padding(1))
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
    }
}
