//
//  BottomControlsBarView.swift
//  Plan4U_iOS
//
//  Floating ultraThinMaterial bottom controls bar mirroring BottomControlsBar.kt
//

import SwiftUI

public enum MiodiSection: String, CaseIterable, Identifiable, Sendable {
    case tasks = "tasks"
    case habits = "habits"
    case joy = "joy"
    case diary = "diary"
    case finance = "finance"
    case nutrition = "nutrition"
    case settings = "settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .tasks: return "checklist"
        case .habits: return "flame.fill"
        case .joy: return "sun.max.fill"
        case .diary: return "book.closed.fill"
        case .finance: return "rublesign.circle.fill"
        case .nutrition: return "fork.knife"
        case .settings: return "gearshape.fill"
        }
    }

    public var title: String {
        switch self {
        case .tasks: return "Задачи"
        case .habits: return "Привычки"
        case .joy: return "Радость"
        case .diary: return "Дневник"
        case .finance: return "Финансы"
        case .nutrition: return "Питание"
        case .settings: return "Опции"
        }
    }
}

public struct BottomControlsBarView: View {
    @Binding public var currentSection: MiodiSection

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public init(currentSection: Binding<MiodiSection>) {
        self._currentSection = currentSection
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(MiodiSection.allCases) { section in
                let isSelected = (section == currentSection)
                Button {
                    MiodiHapticFeedback.lightClick()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        currentSection = section
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: section.iconName)
                            .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(
                                isSelected
                                    ? theme.currentAccent.primary
                                    : (isDark ? Color(hex: 0x8892B0) : Color(hex: 0x737780))
                            )
                            .scaleEffect(isSelected ? 1.08 : 1.0)

                        Text(section.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(
                                isSelected
                                    ? theme.currentAccent.primary
                                    : (isDark ? Color(hex: 0x8892B0) : Color(hex: 0x737780))
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isDark ? Color(hex: 0x14171F).opacity(0.92) : Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.12), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    isDark ? Color(hex: 0x2E3547) : theme.currentAccent.primary.opacity(0.18),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
