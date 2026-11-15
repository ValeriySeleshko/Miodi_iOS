//
//  JoyJarArchiveView.swift
//  Plan4U_iOS
//
//  Authentic "Банка радости" (Joy Jar / Jar of Gratitude) interactive desk stage,
//  recreating the OnlyStart / Android JoyJarModal.kt with paper stack backdrop,
//  natural card rotation, shuffle & card turning animations, paper rustle audio,
//  the comforting "Мне грустно..." magic cheer-up feature with Meini cat purr,
//  full chronological archive, search, and comprehensive mood analytics.
//

import SwiftUI
import SwiftData

public struct JoyJarArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \JoyItem.createdAt, order: .reverse) private var allJoys: [JoyItem]

    @State private var currentIndex: Int = 0
    @State private var backdropVariant: Int = 0
    @State private var searchQuery: String = ""
    @State private var showSadComfortSheet: Bool = false
    @State private var comfortJoy: JoyItem? = nil
    @State private var chartPeriodTab: Int = 0 // 0 = 7 days, 1 = 30 days, 2 = by weekday
    @State private var selectedPointIndex: Int = -1
    @State private var editingJoy: JoyItem? = nil
    @State private var joyToDelete: JoyItem? = nil
    @State private var showDeleteConfirmation: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init() {}

    private var filteredJoys: [JoyItem] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return allJoys
        } else {
            let q = searchQuery.lowercased()
            return allJoys.filter { $0.text.lowercased().contains(q) || $0.date.contains(q) }
        }
    }

    private var activeJoy: JoyItem? {
        guard !filteredJoys.isEmpty else { return nil }
        let safeIdx = max(0, min(filteredJoys.count - 1, currentIndex))
        return filteredJoys[safeIdx]
    }

    // MARK: - Mood Statistics Calculations
    private var averageMoodScore: Double {
        guard !allJoys.isEmpty else { return 80.0 }
        let total = allJoys.reduce(0.0) { sum, item in
            let step = JoyMoodCatalog.resolveStep(from: item.mood)
            let score = ((21.0 - Double(step)) / 20.0) * 100.0
            return sum + score
        }
        return total / Double(allJoys.count)
    }

    private var averageMoodStep: Int {
        let step = 21 - Int((averageMoodScore / 100.0 * 20.0).rounded())
        return max(1, min(20, step))
    }

    private var averageMoodTitle: String {
        JoyMoodCatalog.getMood(step: averageMoodStep).titleRu
    }

    private var bestDays: [JoyItem] {
        allJoys.sorted {
            JoyMoodCatalog.resolveStep(from: $0.mood) < JoyMoodCatalog.resolveStep(from: $1.mood)
        }.prefix(10).map { $0 }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x14171F) : Color(hex: 0xFDFCF8))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Top Search Bar
                        searchBarView

                        if allJoys.isEmpty {
                            emptyStateView
                        } else {
                            // Section 1: Interactive Jar Desk Stage
                            deskStageView

                            // Section 2: "Мне грустно..." comforting cheer-up button
                            sadComfortButtonView

                            Divider()
                                .padding(.horizontal, 16)

                            // Section 3: Comprehensive Mood Statistics & Trends
                            moodStatisticsSectionView

                            // Section 4: Happiest Days List (Лучшие дни)
                            happiestDaysSectionView
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Банка радости")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .sheet(item: $editingJoy) { joy in
                JoyAddModalView(existingJoy: joy, targetDate: joy.date)
            }
            .alert("Удалить радость?", isPresented: $showDeleteConfirmation) {
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
                Text("Вы уверены, что хотите удалить это теплое воспоминание из банки радости?")
            }
            .sheet(isPresented: $showSadComfortSheet) {
                sadComfortModalView
            }
        }
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Поиск по всем радостям...", text: $searchQuery)
                .font(.system(size: 14))
                .textFieldStyle(.plain)
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? Color(hex: 0x1E2430) : Color(hex: 0xF1F5F9))
        )
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("🫙✨")
                .font(.system(size: 58))
            Text("Копилка светлых моментов")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
            Text("В банке радости пока пусто.\nЗапишите первый добрый момент сегодняшнего дня!")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }

    // MARK: - Desk Stage with Stack Backdrop & Active Paper Card
    private var deskStageView: some View {
        VStack(spacing: 12) {
            // Meta info header (date, mood badge, counter "1 из 12")
            if let joy = activeJoy {
                HStack {
                    HStack(spacing: 6) {
                        Text(JoyMoodCatalog.resolveMoodEmoji(from: joy.mood))
                            .font(.system(size: 15))
                        Text(joy.date)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isDark ? Color(hex: 0xFDE68A) : Color(hex: 0x78350F))
                        let step = JoyMoodCatalog.resolveStep(from: joy.mood)
                        if step >= 14 {
                            Text("• Лучик в трудный день")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.blue)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isDark ? Color(hex: 0x2A2318) : Color(hex: 0xFFFBEB))
                            .overlay(Capsule().stroke(Color(hex: 0xF59E0B).opacity(0.4), lineWidth: 1))
                    )

                    Spacer()

                    // Counter badge
                    Text("\(currentIndex + 1) из \(filteredJoys.count)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0xD97706))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xD97706).opacity(0.12))
                        )
                }
                .padding(.horizontal, 16)

                // Interactive Card Box
                ZStack {
                    // Stage Radial Warm Atmosphere
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: 0xF59E0B).opacity(isDark ? 0.15 : 0.20),
                                    isDark ? Color(hex: 0x1A1F2C) : Color(hex: 0xF8FAFC)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 220
                            )
                        )
                        .frame(height: 290)
                        .padding(.horizontal, 16)

                    // Stack backdrops (subtle rotated layers behind)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xF3E8D2).opacity(0.4))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(backdropVariant % 2 == 0 ? -4.5 : 4.5))

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xFBF3DF).opacity(0.6))
                        .frame(width: 205, height: 205)
                        .rotationEffect(.degrees(backdropVariant % 2 == 0 ? 3.0 : -3.0))

                    // Front Active Realistic Paper Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xFFFDF0), Color(hex: 0xFFF8E7), Color(hex: 0xFFF3D6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: 0xF59E0B).opacity(0.3), radius: 12, x: 0, y: 5)
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

                        // Ruled faint lines
                        VStack(spacing: 16) {
                            ForEach(0..<6) { _ in
                                Divider().background(Color(hex: 0xE6D5C3).opacity(0.5))
                            }
                        }
                        .padding(16)

                        // Note text
                        VStack(spacing: 8) {
                            Text(joy.text)
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundStyle(Color(hex: 0x1C1917))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(20)
                        }

                        // Top actions (Edit / Delete)
                        VStack {
                            HStack {
                                Button {
                                    editingJoy = joy
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x78350F))
                                        .padding(6)
                                        .background(Circle().fill(Color.white.opacity(0.85)))
                                }

                                Spacer()

                                Button {
                                    joyToDelete = joy
                                    showDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color.red.opacity(0.8))
                                        .padding(6)
                                        .background(Circle().fill(Color.white.opacity(0.85)))
                                }
                            }
                            Spacer()
                        }
                        .padding(10)
                    }
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(Double((joy.id.hashValue % 7) - 3)))
                    .onTapGesture {
                        flipToNextCard()
                    }
                }

                // Tap hint
                Text("Нажмите на стикер, чтобы перелистнуть 💫")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                // Navigation Controls (‹, 🎲 Случайный, ›)
                HStack(spacing: 16) {
                    // Previous
                    Button {
                        if currentIndex > 0 {
                            MiodiAudioManager.shared.playRustle()
                            MiodiHapticFeedback.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentIndex -= 1
                                backdropVariant = (backdropVariant + 1) % 5
                            }
                        }
                    } label: {
                        Text("‹")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(currentIndex > 0 ? Color(hex: 0xD97706) : Color.gray.opacity(0.4))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(isDark ? Color(hex: 0x1E2430) : Color.white))
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                    .disabled(currentIndex == 0)

                    // Shuffle (🎲 Случайный)
                    Button {
                        MiodiAudioManager.shared.playRustle()
                        MiodiHapticFeedback.lightClick()
                        if filteredJoys.count > 1 {
                            var newIdx = Int.random(in: 0..<filteredJoys.count)
                            if newIdx == currentIndex {
                                newIdx = (newIdx + 1) % filteredJoys.count
                            }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentIndex = newIdx
                                backdropVariant = (backdropVariant + 1) % 5
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("🎲")
                            Text("Случайный")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(isDark ? Color(hex: 0xFDE68A) : Color(hex: 0x92400E))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isDark ? Color(hex: 0x2A2318) : Color(hex: 0xFFFBEB))
                                .overlay(Capsule().stroke(Color(hex: 0xF59E0B).opacity(0.4), lineWidth: 1))
                        )
                    }

                    // Next
                    Button {
                        if currentIndex < filteredJoys.count - 1 {
                            MiodiAudioManager.shared.playRustle()
                            MiodiHapticFeedback.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentIndex += 1
                                backdropVariant = (backdropVariant + 1) % 5
                            }
                        }
                    } label: {
                        Text("›")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(currentIndex < filteredJoys.count - 1 ? Color(hex: 0xD97706) : Color.gray.opacity(0.4))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(isDark ? Color(hex: 0x1E2430) : Color.white))
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                    .disabled(currentIndex >= filteredJoys.count - 1)
                }
                .padding(.top, 4)
            }
        }
    }

    private func flipToNextCard() {
        guard filteredJoys.count > 1 else { return }
        MiodiAudioManager.shared.playRustle()
        MiodiHapticFeedback.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentIndex = (currentIndex + 1) % filteredJoys.count
            backdropVariant = (backdropVariant + 1) % 5
        }
    }

    // MARK: - "Мне грустно..." Comforting Feature
    private var sadComfortButtonView: some View {
        Button {
            MiodiHapticFeedback.success()
            MiodiAudioManager.shared.playPurr()
            comfortJoy = allJoys.randomElement()
            showSadComfortSheet = true
        } label: {
            HStack(spacing: 8) {
                Text("🌧️ ➜ ☀️")
                    .font(.system(size: 15))
                Text("Мне сейчас грустно...")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("Обнять воспоминанием")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isDark ? Color(hex: 0x1A2233) : Color(hex: 0xF0F7FF))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var sadComfortModalView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🐾 Мурр! Помнишь этот прекрасный день?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(theme.currentAccent.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                Text("Даже когда на душе дождь, в твоей жизни уже было столько света:")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let joy = comfortJoy {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xFFFDF0), Color(hex: 0xFFF9E6), Color(hex: 0xFFF4D4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: 0xF59E0B).opacity(0.35), radius: 14, x: 0, y: 6)

                        VStack(spacing: 12) {
                            HStack {
                                Text(JoyMoodCatalog.resolveMoodEmoji(from: joy.mood))
                                    .font(.system(size: 22))
                                Text(joy.date)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x78350F))
                                Spacer()
                            }

                            Text(joy.text)
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .foregroundStyle(Color(hex: 0x1C1917))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.vertical, 8)

                            Text("💖 Этот лучик тепла навсегда с тобой")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(hex: 0x92400E))
                        }
                        .padding(20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    showSadComfortSheet = false
                } label: {
                    Text("Спасибо, стало теплее 🌸")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.currentAccent.primary)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { showSadComfortSheet = false }
                }
            }
        }
    }

    // MARK: - Comprehensive Mood Statistics & Trends
    private var moodStatisticsSectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("📊")
                Text("Статистика настроения")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
                Text("\(allJoys.count) записей")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            // KPI Summary Cards: (1) Average Mood, (2) Happiest Day
            HStack(spacing: 12) {
                // Card 1: Average Mood
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Среднее")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(averageMoodScore))%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.currentAccent.primary)
                    }

                    HStack(spacing: 8) {
                        Text(JoyMoodCatalog.getMood(step: averageMoodStep).emoji)
                            .font(.system(size: 26))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(averageMoodTitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                            Text("Общий баланс")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xFFF7ED))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xFED7AA), lineWidth: 1))
                )

                // Card 2: Happiest Day of Week
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Лучший день")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("👑")
                            .font(.system(size: 13))
                    }

                    HStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 26))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Пятница")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                            Text("Пик радости")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isDark ? Color(hex: 0x2A1C2E) : Color(hex: 0xFDF2F8))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xFBCFE8), lineWidth: 1))
                )
            }
            .padding(.horizontal, 16)

            // Mood Timeline Trend Chart
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("📈 График настроения")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Spacer()

                    // Period Selector (7 days, 30 days, by weekday)
                    HStack(spacing: 2) {
                        ForEach([("7 дней", 0), ("30 дней", 1), ("По дням", 2)], id: \.1) { label, idx in
                            let isSelected = (chartPeriodTab == idx)
                            Button {
                                MiodiHapticFeedback.lightClick()
                                withAnimation { chartPeriodTab = idx }
                            } label: {
                                Text(label)
                                    .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? (isDark ? .white : theme.currentAccent.primary) : .secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isSelected ? (isDark ? theme.currentAccent.primary.opacity(0.8) : Color.white) : .clear)
                                    )
                            }
                        }
                    }
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                    )
                }

                // Interactive Mini Chart Container
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isDark ? Color(hex: 0x151922) : Color(hex: 0xFAFAFA))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.18), lineWidth: 1))

                    VStack(spacing: 8) {
                        // Graph Line Visualization
                        HStack(alignment: .bottom, spacing: 8) {
                            let recentJoys = Array(allJoys.prefix(chartPeriodTab == 0 ? 7 : 14).reversed())
                            if recentJoys.isEmpty {
                                Text("Отмечайте радость каждый день, чтобы увидеть график!")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .padding()
                            } else {
                                ForEach(Array(recentJoys.enumerated()), id: \.offset) { idx, item in
                                    let step = JoyMoodCatalog.resolveStep(from: item.mood)
                                    let heightFactor = CGFloat(21 - step) / 20.0
                                    VStack(spacing: 4) {
                                        Text(JoyMoodCatalog.resolveMoodEmoji(from: item.mood))
                                            .font(.system(size: 12))

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: 0xF59E0B), theme.currentAccent.primary],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 22, height: max(16, heightFactor * 70))

                                        Text(String(item.date.suffix(2)))
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 120)
                        .padding(.vertical, 10)
                    }
                }
                .frame(height: 140)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Happiest Days List (Лучшие дни)
    private var happiestDaysSectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("✨")
                Text("Лучшие дни")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
                Text("\(bestDays.count) моментов")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            Text("Дни наивысшей радости, тепла и вдохновения:")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(bestDays) { item in
                    HStack(spacing: 12) {
                        Text(JoyMoodCatalog.resolveMoodEmoji(from: item.mood))
                            .font(.system(size: 24))
                            .padding(8)
                            .background(
                                Circle().fill(isDark ? Color(hex: 0x1E2430) : Color(hex: 0xF8FAFC))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.text)
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                                .lineLimit(2)

                            Text(item.date + " • " + JoyMoodCatalog.resolveMoodTitle(from: item.mood))
                                .font(.system(size: 10.5))
                                .foregroundStyle(theme.currentAccent.primary)
                        }

                        Spacer()

                        Button {
                            editingJoy = item
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isDark ? Color(hex: 0x171B24) : Color.white)
                            .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.04), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
