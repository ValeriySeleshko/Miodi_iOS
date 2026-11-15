//
//  QuickAccessSlotPickerModalView.swift
//  Plan4U_iOS
//
//  Pixel-perfect and feature-complete port of Android QuickAccessSlotPickerModal.kt (303 lines).
//  Centered popup modal for customizing button slots on long press.
//  Displays an aesthetic grid of circular module buttons without text,
//  letting the user instantly tap a circle to replace the active slot.
//

import SwiftUI

// MARK: - QuickAccessItem Enum (1-to-1 with QuickAccessItem.kt)
public enum QuickAccessItem: String, CaseIterable, Identifiable, Sendable {
    case calendar = "calendar"
    case tasks = "tasks"
    case achievements = "achievements"
    case paw = "paw"
    case stickers = "stickers"
    case finance = "finance"
    case nutrition = "nutrition"
    case cycle = "cycle"
    case joy = "joy"
    case moments = "moments"

    public var id: String { rawValue }

    public var isSelectableInSlots: Bool {
        self != .calendar
    }

    public var title: String {
        switch self {
        case .calendar: return "Календарь"
        case .tasks: return "Дела"
        case .achievements: return "Достижения"
        case .paw: return "Лапка Гармонии"
        case .stickers: return "Стикеры"
        case .finance: return "Финансы"
        case .nutrition: return "Питание"
        case .cycle: return "Женский календарь"
        case .joy: return "Банка радости"
        case .moments: return "Моменты"
        }
    }

    public var iconSystemName: String {
        switch self {
        case .calendar: return "calendar"
        case .tasks: return "checklist"
        case .achievements: return "trophy.fill"
        case .paw: return "pawprint.fill"
        case .stickers: return "sparkles"
        case .finance: return "rublesign.circle.fill"
        case .nutrition: return "fork.knife"
        case .cycle: return "drop.fill"
        case .joy: return "sun.max.fill"
        case .moments: return "camera.fill"
        }
    }

    public var emoji: String {
        switch self {
        case .calendar: return "🗓️"
        case .tasks: return "📋"
        case .achievements: return "🏆"
        case .paw: return "🐾"
        case .stickers: return "⭐"
        case .finance: return "💰"
        case .nutrition: return "🥑"
        case .cycle: return "🍒"
        case .joy: return "☀️"
        case .moments: return "📷"
        }
    }

    public var accentColor: Color {
        switch self {
        case .calendar: return Color(hex: 0xD83A88)
        case .tasks: return Color(hex: 0x3B82F6)
        case .achievements: return Color(hex: 0xF59E0B)
        case .paw: return Color(hex: 0xEC4899)
        case .stickers: return Color(hex: 0x8B5CF6)
        case .finance: return Color(hex: 0x10B981)
        case .nutrition: return Color(hex: 0x14B8A6)
        case .cycle: return Color(hex: 0xFB7185)
        case .joy: return Color(hex: 0xF59E0B)
        case .moments: return Color(hex: 0x6366F1)
        }
    }
}

// MARK: - QuickAccessSlots Model (1-to-1 with QuickAccessSlots)
public struct QuickAccessSlots: Equatable, Sendable {
    public var topSlot1: QuickAccessItem?
    public var topSlot2: QuickAccessItem?
    public var topSlot3: QuickAccessItem?
    public var bottomSlot1: QuickAccessItem?
    public var bottomSlot2: QuickAccessItem?

    public init(
        topSlot1: QuickAccessItem? = .paw,
        topSlot2: QuickAccessItem? = .tasks,
        topSlot3: QuickAccessItem? = .achievements,
        bottomSlot1: QuickAccessItem? = .stickers,
        bottomSlot2: QuickAccessItem? = .finance
    ) {
        self.topSlot1 = topSlot1
        self.topSlot2 = topSlot2
        self.topSlot3 = topSlot3
        self.bottomSlot1 = bottomSlot1
        self.bottomSlot2 = bottomSlot2
    }

    public func getSlotItem(slotIndex: Int) -> QuickAccessItem? {
        switch slotIndex {
        case 0: return topSlot1
        case 1: return topSlot2
        case 2: return topSlot3
        case 3: return bottomSlot1
        case 4: return bottomSlot2
        default: return topSlot1
        }
    }

    public func withSlotUpdated(slotIndex: Int, newItem: QuickAccessItem) -> QuickAccessSlots {
        var copy = self
        switch slotIndex {
        case 0: copy.topSlot1 = newItem
        case 1: copy.topSlot2 = newItem
        case 2: copy.topSlot3 = newItem
        case 3: copy.bottomSlot1 = newItem
        case 4: copy.bottomSlot2 = newItem
        default: break
        }
        return copy
    }
}

// MARK: - QuickAccessSlotPickerModalView
public struct QuickAccessSlotPickerModalView: View {
    public let slotIndex: Int
    public let currentSlots: QuickAccessSlots
    public let onDismiss: () -> Void
    public let onSelect: (QuickAccessItem) -> Void
    public let onResetToDefaults: () -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0.0

    public init(
        slotIndex: Int,
        currentSlots: QuickAccessSlots = QuickAccessSlots(),
        onDismiss: @escaping () -> Void = {},
        onSelect: @escaping (QuickAccessItem) -> Void = { _ in },
        onResetToDefaults: @escaping () -> Void = {}
    ) {
        self.slotIndex = slotIndex
        self.currentSlots = currentSlots
        self.onDismiss = onDismiss
        self.onSelect = onSelect
        self.onResetToDefaults = onResetToDefaults
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var currentItemInThisSlot: QuickAccessItem? {
        currentSlots.getSlotItem(slotIndex: slotIndex)
    }

    private var availableItems: [QuickAccessItem] {
        QuickAccessItem.allCases.filter { $0.isSelectableInSlots }
    }

    // Split available circle buttons into rows of 3
    private var itemRows: [[QuickAccessItem]] {
        var rows: [[QuickAccessItem]] = []
        var currentRow: [QuickAccessItem] = []
        for item in availableItems {
            currentRow.append(item)
            if currentRow.count == 3 {
                rows.append(currentRow)
                currentRow = []
            }
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }

    private var expressiveBorderGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                theme.currentAccent.primary,
                theme.currentAccent.marginLine,
                theme.currentAccent.primary,
                isDark ? theme.currentAccent.primaryDark : theme.currentAccent.primary.opacity(0.9)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cardBackgroundGradient: LinearGradient {
        if isDark {
            return LinearGradient(
                colors: [Color(hex: 0x1E2536), Color(hex: 0x141924)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.white, Color(hex: 0xF7F9FC)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    public var body: some View {
        ZStack {
            // Fullscreen backdrop with tap-to-dismiss
            Color.black.opacity(0.45 * opacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Centered Card with Grid of Circle Buttons (No Text)
            VStack(spacing: 18) {
                // Title hint
                VStack(spacing: 3) {
                    Text("Выберите модуль для слота")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

                    Text("Нажмите, чтобы заменить активную кнопку")
                        .font(.system(size: 11))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B))
                }
                .padding(.bottom, 2)

                // Grid of 3x3 circular module buttons
                VStack(spacing: 15) {
                    ForEach(0..<itemRows.count, id: \.self) { rowIndex in
                        HStack(spacing: 15) {
                            ForEach(itemRows[rowIndex]) { item in
                                let isSelected = (item == currentItemInThisSlot)
                                circleButton(item: item, isSelected: isSelected)
                            }
                        }
                    }
                }

                // Reset to defaults button
                Button {
                    MiodiHapticFeedback.lightClick()
                    onResetToDefaults()
                    dismissWithAnimation()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .semibold))

                        Text("Сбросить по умолчанию")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(cardBackgroundGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(expressiveBorderGradient, lineWidth: 2.4)
            )
            .shadow(
                color: theme.currentAccent.primary.opacity(isDark ? 0.50 : 0.35),
                radius: 26,
                x: 0,
                y: 8
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    // MARK: - Circle Module Button
    private func circleButton(item: QuickAccessItem, isSelected: Bool) -> some View {
        Button {
            MiodiHapticFeedback.lightClick()
            onSelect(item)
            dismissWithAnimation()
        } label: {
            ZStack {
                // Selected Aura Ring
                if isSelected {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    theme.currentAccent.primary,
                                    theme.currentAccent.marginLine,
                                    theme.currentAccent.primary,
                                    theme.currentAccent.marginLine,
                                    theme.currentAccent.primary
                                ]),
                                center: .center
                            ),
                            lineWidth: 2.6
                        )
                        .frame(width: 58, height: 58)
                        .background(
                            Circle()
                                .fill(theme.currentAccent.primary.opacity(isDark ? 0.28 : 0.16))
                        )
                        .shadow(
                            color: theme.currentAccent.primary.opacity(isDark ? 0.70 : 0.50),
                            radius: 8,
                            x: 0,
                            y: 0
                        )
                }

                // Inner Main Circle Button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                isDark ? Color(hex: 0x1E2433) : Color.white,
                                isDark ? Color(hex: 0x141824) : Color(hex: 0xF8FAFC)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isSelected ? 48 : 52, height: isSelected ? 48 : 52)
                    .shadow(
                        color: Color.black.opacity(isDark ? 0.4 : 0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected
                                    ? theme.currentAccent.primary
                                    : (isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE2E8F0)),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                // Module Icon / Emoji
                VStack(spacing: 0) {
                    Text(item.emoji)
                        .font(.system(size: isSelected ? 20 : 22))
                }
            }
            .frame(width: 58, height: 58)
        }
        .buttonStyle(.plain)
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.16)) {
            scale = 0.85
            opacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            onDismiss()
        }
    }
}
