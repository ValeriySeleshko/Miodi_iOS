//
//  SettingsView.swift
//  Plan4U_iOS
//
//  Settings screen: Accent Theme Palette (18 colors), Dark/Light mode, Haptics.
//

import SwiftUI

public struct SettingsView: View {
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var isShowingCycleTracker: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init() {}

    public var body: some View {
        ZStack {
            NotebookCanvasView(
                patternType: .lines,
                patternSize: 32,
                marginLineX: 50,
                isDarkTheme: isDark
            )

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Настройки блокнота")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isDark ? MiodiStaticColors.darkTopBarBg : Color.white.opacity(0.85))

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Themes & Accents
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Цветовая тема обложки и акцентов")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 12) {
                                ForEach(Array(AccentThemes.all.enumerated()), id: \.offset) { index, accent in
                                    let isSelected = (theme.activeAccentIndex == index)
                                    Button {
                                        MiodiHapticFeedback.lightClick()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            theme.activeAccentIndex = index
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            ZStack {
                                                Circle()
                                                    .fill(accent.primary)
                                                    .frame(width: 42, height: 42)
                                                    .shadow(color: accent.primary.opacity(0.35), radius: 4, x: 0, y: 2)

                                                if isSelected {
                                                    Circle()
                                                        .strokeBorder(Color.white, lineWidth: 2.5)
                                                        .frame(width: 42, height: 42)
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            Text(accent.name)
                                                .font(.system(size: 10))
                                                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                                .lineLimit(1)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                        )

                        // Section 2: Dark Mode Override
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Оформление")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Toggle("Темный блокнот", isOn: Binding(
                                get: { theme.isDarkThemeOverride ?? (colorScheme == .dark) },
                                set: { newValue in
                                    MiodiHapticFeedback.lightClick()
                                    theme.isDarkThemeOverride = newValue
                                }
                            ))
                            .tint(theme.currentAccent.primary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                        )

                        // Section 3: Cycle Feature
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Модули и здоровье")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Button {
                                isShowingCycleTracker = true
                                MiodiHapticFeedback.lightClick()
                            } label: {
                                HStack(spacing: 12) {
                                    Text("🍒")
                                        .font(.system(size: 22))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Женский календарь цикла")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                        Text("Фазы, прогноз, симптомы и экспорт")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                        )

                        // Section 4: App info
                        VStack(spacing: 4) {
                            Text("Miodi для iOS")
                                .font(.footnote.bold())
                                .foregroundStyle(theme.currentAccent.primary)
                            Text("Версия 1.0.0 • Swift 5.10 & SwiftData")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        Color.clear.frame(height: 120)
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $isShowingCycleTracker) {
            CycleTrackerView()
        }
    }
}
