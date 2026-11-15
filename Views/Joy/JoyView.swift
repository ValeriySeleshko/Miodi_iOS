//
//  JoyView.swift
//  Plan4U_iOS
//
//  Joy of the Day (Радость дня) Main Dashboard.
//  100% faithful to Android concept:
//  - "3 радости в день" (Daily 3-Joy Goal Meter with glowing stars & sun rays)
//  - List of today's joy cards with warm solar glow & paper textures
//  - Fast "+ Добавить радость" quick entry button
//  - Festive Pyrotechnic Salute celebration overlay when reaching the 3-joy goal
//  - "🫙 Банка радостей" archive and mood statistics link
//  - Inspiration reflection prompt card
//

import SwiftUI
import SwiftData

public struct JoyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \JoyItem.createdAt, order: .forward) private var allJoys: [JoyItem]

    @State private var selectedDateStr: String = Date().yyyyMMddString
    @State private var isAddModalPresented: Bool = false
    @State private var isJarArchivePresented: Bool = false
    @State private var editingJoy: JoyItem? = nil
    @State private var joyToDelete: JoyItem? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var showSaluteOverlay: Bool = false
    @State private var hasTriggeredSaluteToday: Bool = false
    @State private var inspirationPrompt: (index: Int, text: String) = JoyPromptsData.randomPrompt()

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var todayDateStr: String {
        Date().yyyyMMddString
    }

    private var joysForSelectedDate: [JoyItem] {
        allJoys.filter { $0.date == selectedDateStr }
    }

    // Target is 3 joys per day (min 1, target 3, max 5)
    private let targetJoysCount: Int = 3

    public init() {}

    public var body: some View {
        ZStack {
            // Notebook ruled background
            NotebookCanvasView(
                patternType: .lines,
                patternSize: 32,
                marginLineX: 50,
                isDarkTheme: isDark
            )

            VStack(spacing: 0) {
                // Header Bar: Title + Date selector + Jar Button
                headerBarView

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Goal Card: "3 радости в день" with solar glow & animated stars
                        dailyGoalMeterCardView

                        // 2. Today's Joy Cards List (with warm solar glow)
                        joyCardsListView

                        // 3. Quick Action: Add Joy Button (if < 5)
                        if joysForSelectedDate.count < 5 {
                            addJoyButtonView
                        }

                        // 4. Daily Inspiration Reflection Prompt
                        inspirationPromptCardView

                        // 5. Joy Jar Quick Teaser Card
                        joyJarTeaserCardView

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }

            // Pyrotechnic Salute Overlay when 3 joys goal is accomplished!
            if showSaluteOverlay {
                JoySaluteOverlayView {
                    withAnimation {
                        showSaluteOverlay = false
                    }
                }
                .transition(.opacity)
                .zIndex(9999)
            }
        }
        .sheet(isPresented: $isAddModalPresented) {
            JoyAddModalView(targetDate: selectedDateStr) { newJoy in
                checkForCelebration()
            }
        }
        .sheet(item: $editingJoy) { joy in
            JoyAddModalView(existingJoy: joy, targetDate: joy.date)
        }
        .sheet(isPresented: $isJarArchivePresented) {
            JoyJarArchiveView()
        }
        .alert("Удалить радость?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) { joyToDelete = nil }
            Button("Удалить", role: .destructive) {
                if let item = joyToDelete {
                    modelContext.delete(item)
                    try? modelContext.save()
                    joyToDelete = nil
                    MiodiHapticFeedback.warning()
                }
            }
        } message: {
            Text("Вы уверены, что хотите удалить эту радость из сегодняшнего дня?")
        }
        .onAppear {
            if joysForSelectedDate.count >= targetJoysCount {
                hasTriggeredSaluteToday = true
            }
        }
    }

    // MARK: - Header Bar
    private var headerBarView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("☀️")
                        .font(.system(size: 20))
                    Text("Радость дня")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                }

                // Date label with quick today toggle
                HStack(spacing: 4) {
                    Text(formatDisplayDate(selectedDateStr))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(selectedDateStr == todayDateStr ? theme.currentAccent.primary : .secondary)

                    if selectedDateStr != todayDateStr {
                        Button {
                            MiodiHapticFeedback.selection()
                            selectedDateStr = todayDateStr
                        } label: {
                            Text("• Сегодня")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.currentAccent.primary)
                        }
                    }
                }
            }

            Spacer()

            // Bank of Joy ("🫙 Банка радостей")
            Button {
                MiodiHapticFeedback.lightClick()
                MiodiAudioManager.shared.playRustle()
                isJarArchivePresented = true
            } label: {
                HStack(spacing: 5) {
                    Text("🫙")
                        .font(.system(size: 16))
                    Text("Копилка")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color(hex: 0xD97706))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isDark ? Color(hex: 0x2A2318) : Color(hex: 0xFEF3C7))
                        .overlay(Capsule().stroke(Color(hex: 0xF59E0B).opacity(0.4), lineWidth: 1))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isDark ? MiodiStaticColors.darkTopBarBg : Color.white.opacity(0.85))
    }

    // MARK: - Daily Goal Meter: "3 радости в день"
    private var dailyGoalMeterCardView: some View {
        let count = joysForSelectedDate.count
        let isGoalComplete = count >= targetJoysCount

        return ZStack {
            // Warm Solar Glow Atmosphere
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isDark ? [
                            Color(hex: 0x2E2415),
                            Color(hex: 0x1E1A14)
                        ] : [
                            Color(hex: 0xFFFBEB),
                            Color(hex: 0xFEF3C7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color(hex: 0xF59E0B).opacity(isGoalComplete ? 0.35 : 0.18),
                    radius: isGoalComplete ? 12 : 6,
                    x: 0,
                    y: 3
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isGoalComplete
                                ? Color(hex: 0xF59E0B)
                                : Color(hex: 0xF59E0B).opacity(0.35),
                            lineWidth: isGoalComplete ? 2 : 1
                        )
                )

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(isGoalComplete ? "🎉 Все 3 радости собраны!" : "Цель дня: 3 радости")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isDark ? Color(hex: 0xFCD34D) : Color(hex: 0x92400E))

                            if isGoalComplete {
                                Text("✨")
                                    .font(.system(size: 15))
                            }
                        }

                        Text(motivationSubtitle(for: count))
                            .font(.system(size: 12))
                            .foregroundStyle(isDark ? Color(hex: 0xFDE68A).opacity(0.8) : Color(hex: 0xB45309))
                    }

                    Spacer()

                    // Count Badge
                    Text("\(min(count, 3))/3")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isGoalComplete ? Color(hex: 0xF59E0B) : Color(hex: 0xD97706))
                        )
                }

                // 3 Interactive Star & Sun Ray Badges
                HStack(spacing: 14) {
                    ForEach(1...3, id: \.self) { starIndex in
                        let isFilled = (count >= starIndex)
                        HStack(spacing: 6) {
                            Text(isFilled ? "⭐" : "☆")
                                .font(.system(size: isFilled ? 22 : 18))
                                .scaleEffect(isFilled ? 1.15 : 1.0)
                            Text("Радость \(starIndex)")
                                .font(.system(size: 11, weight: isFilled ? .bold : .medium))
                                .foregroundStyle(
                                    isFilled
                                        ? (isDark ? Color(hex: 0xFCD34D) : Color(hex: 0x92400E))
                                        : Color.gray.opacity(0.6)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    isFilled
                                        ? Color(hex: 0xF59E0B).opacity(isDark ? 0.3 : 0.18)
                                        : (isDark ? Color(hex: 0x1E2430) : Color.white.opacity(0.7))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isFilled ? Color(hex: 0xF59E0B) : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(14)
        }
    }

    private func motivationSubtitle(for count: Int) -> String {
        switch count {
        case 0: return "Запишите первую радость сегодняшнего дня ☀️"
        case 1: return "Чудесно! Ещё две радости для полной гармонии 💫"
        case 2: return "Почти у цели! Осталась последняя радость 🌸"
        default: return "Браво! Ваш день озарён светом и благодарностью ✨"
        }
    }

    // MARK: - Today's Joy Cards List
    private var joyCardsListView: some View {
        VStack(spacing: 12) {
            if joysForSelectedDate.isEmpty {
                // Empty invitation
                VStack(spacing: 12) {
                    Text("☀️")
                        .font(.system(size: 42))
                    Text("Сегодня ещё нет записей радости")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                    Text("Вкусный кофе, улыбка прохожего, закат или маленькая победа — найдите свой теплый лучик!")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDark ? Color(hex: 0x1A1F2C) : Color.white)
                        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.05), radius: 6, x: 0, y: 2)
                )
            } else {
                ForEach(Array(joysForSelectedDate.enumerated()), id: \.element.id) { index, joy in
                    joyCardView(joy: joy, index: index)
                }
            }
        }
    }

    private func joyCardView(joy: JoyItem, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            // Realistic paper note background with warm solar glow
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xFFFDF2),
                            Color(hex: 0xFFFAF0),
                            Color(hex: 0xFFF5E4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color(hex: 0xF59E0B).opacity(isDark ? 0.22 : 0.28),
                    radius: 8,
                    x: 0,
                    y: 3
                )
                .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.06), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xFDE68A), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                // Card Header: Mood emoji, Title, Order badge (#1, #2...)
                HStack(spacing: 8) {
                    Text(JoyMoodCatalog.resolveMoodEmoji(from: joy.mood))
                        .font(.system(size: 22))
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.85)))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(JoyMoodCatalog.resolveMoodTitle(from: joy.mood))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: 0x78350F))
                        Text("Радость №\(index + 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(hex: 0xD97706))
                    }

                    Spacer()

                    // Card Action Menu (Edit / Delete)
                    Menu {
                        Button {
                            editingJoy = joy
                        } label: {
                            Label("Редактировать", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            joyToDelete = joy
                            showDeleteAlert = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x78350F))
                            .padding(8)
                    }
                }

                // Handwritten note body
                Text(joy.text)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color(hex: 0x1C1917))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .padding(14)
        }
        .rotationEffect(.degrees(Double((joy.id.hashValue % 5) - 2) * 0.4))
    }

    // MARK: - Add Joy Button
    private var addJoyButtonView: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            isAddModalPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Записать радость (\(joysForSelectedDate.count + 1)/3)")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.currentAccent.primary)
                    .shadow(color: theme.currentAccent.primary.opacity(0.35), radius: 8, x: 0, y: 3)
            )
        }
        .padding(.top, 4)
    }

    // MARK: - Inspiration Reflection Prompt Card
    private var inspirationPromptCardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("💡 Вдохновение дня")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: 0xD97706))

                Spacer()

                Button {
                    MiodiHapticFeedback.selection()
                    inspirationPrompt = JoyPromptsData.randomPrompt(excludeIndex: inspirationPrompt.index)
                } label: {
                    Text("🎲 Другой вопрос")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xD97706))
                }
            }

            Text(inspirationPrompt.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isDark ? Color(hex: 0xFCD34D) : Color(hex: 0x92400E))
                .lineSpacing(2)

            Button {
                MiodiHapticFeedback.lightClick()
                isAddModalPresented = true
            } label: {
                Text("Ответить на этот вопрос ✍️")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: 0xD97706))
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDark ? Color(hex: 0x2A2318) : Color(hex: 0xFFFBEB))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: 0xF59E0B).opacity(0.4), lineWidth: 1)
                )
        )
    }

    // MARK: - Joy Jar Teaser Card
    private var joyJarTeaserCardView: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            MiodiAudioManager.shared.playRustle()
            isJarArchivePresented = true
        } label: {
            HStack(spacing: 12) {
                Text("🫙")
                    .font(.system(size: 30))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Банка радости (Копилка)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                    Text("Всего сохранено: \(allJoys.count) добрых моментов. Нажмите, чтобы полистать стопку и посмотреть график настроения.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDark ? Color(hex: 0x1A1F2C) : Color.white)
                    .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.05), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Celebration Check
    private func checkForCelebration() {
        if joysForSelectedDate.count >= targetJoysCount && !hasTriggeredSaluteToday {
            hasTriggeredSaluteToday = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showSaluteOverlay = true
            }
        }
    }

    private func formatDisplayDate(_ dateStr: String) -> String {
        if dateStr == todayDateStr {
            return "Сегодня"
        }
        guard let d = Date.from(yyyyMMdd: dateStr) else { return dateStr }
        return d.userFriendlyDateString()
    }
}
