//
//  HabitDetailModalView.swift
//  Plan4U_iOS
//
//  Full-featured Habit Detail & Settings Modal matching Android HabitModal.kt 1-to-1
//  Tabs: [📊 Статистика] [⚙️ Настройки]
//

import SwiftUI
import SwiftData

public struct HabitDetailModalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public var editingHabit: HabitItem?
    public var onSave: ((HabitItem) -> Void)?
    public var onDelete: ((HabitItem) -> Void)?

    @Query private var allEntries: [HabitEntryItem]

    // Form state
    @State private var activeTab: Int = 0 // 0: Stats (if edit), 1: Settings
    @State private var title: String = ""
    @State private var habitType: String = "boolean" // "boolean", "numeric"
    @State private var targetValueStr: String = "2"
    @State private var targetStepStr: String = "1"
    @State private var targetUnit: String = "стакан"
    @State private var customUnit: String = ""
    @State private var scheduleType: String = "daily" // "daily", "weekdays", "periodic"
    @State private var selectedDaysOfWeek: Set<Int> = [1, 2, 3, 4, 5]
    @State private var periodicTargetCount: Int = 3
    @State private var periodicPeriod: String = "week" // "week", "month"
    @State private var reminderEnabled: Bool = false
    @State private var reminderTimes: [String] = ["09:00"]
    @State private var newReminderDate: Date = Date()
    @State private var isShowingTimePicker: Bool = false

    // Stats state
    @State private var chartPeriod: String = "weeks" // "days", "weeks", "months"
    @State private var selectedActivityTab: Int = 0 // 0: 4 Weeks, 1: Frequency, 2: Full Month
    @State private var showDeleteConfirmation: Bool = false
    @State private var isShowingFreezeModal: Bool = false
    @State private var activeStepperDateStr: String? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var isEditMode: Bool {
        editingHabit != nil
    }

    private let unitPresets = ["стакан", "л", "мин", "км", "стр", "раз", "шаг", "чашка", "кг"]

    public init(
        editingHabit: HabitItem? = nil,
        onSave: ((HabitItem) -> Void)? = nil,
        onDelete: ((HabitItem) -> Void)? = nil
    ) {
        self.editingHabit = editingHabit
        self.onSave = onSave
        self.onDelete = onDelete
        _activeTab = State(initialValue: editingHabit != nil ? 0 : 1)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x0F172A) : Color(hex: 0xF8FAFC))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Segmented Bar: [📊 Статистика] [⚙️ Настройки]
                    if isEditMode {
                        HStack(spacing: 0) {
                            tabHeaderButton(index: 0, title: "📊 Статистика")
                            tabHeaderButton(index: 1, title: "⚙️ Настройки")
                        }
                        .padding(3)
                        .background(isDark ? Color(hex: 0x1E293B) : Color(hex: 0xE2E8F0))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                    }

                    ScrollView {
                        VStack(spacing: 16) {
                            if isEditMode && activeTab == 0 {
                                statsSectionView
                            } else {
                                settingsSectionView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle(isEditMode ? (title.isEmpty ? "Привычка" : title) : "Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveHabit()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadInitialState()
            }
            .confirmationDialog("Удалить привычку?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Удалить привычку", role: .destructive) {
                    deleteCurrentHabit()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все данные прогресса и статистика этой привычки будут безвозвратно удалены.")
            }
            .sheet(isPresented: $isShowingTimePicker) {
                timePickerSheet
            }
            .sheet(isPresented: $isShowingFreezeModal) {
                HabitFreezeModalView(preselectedHabitId: editingHabit?.id)
            }
            .sheet(item: Binding(
                get: { activeStepperDateStr.map { StepperDateHolder(dateStr: $0) } },
                set: { activeStepperDateStr = $0?.dateStr }
            )) { holder in
                if let habit = editingHabit {
                    let entry = allEntries.first { $0.habitId == habit.id && $0.date == holder.dateStr }
                    HabitNumericStepperSheet(
                        habit: habit,
                        dateStr: holder.dateStr,
                        initialValue: entry?.value ?? 0,
                        status: entry?.status ?? "completed",
                        onSave: { newVal, status in
                            updateHabitEntry(habitId: habit.id, dateStr: holder.dateStr, value: newVal, status: status)
                        },
                        onDismiss: {
                            activeStepperDateStr = nil
                        }
                    )
                }
            }
        }
    }

    private func tabHeaderButton(index: Int, title: String) -> some View {
        let isSel = activeTab == index
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                activeTab = index
            }
            MiodiHapticFeedback.lightClick()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: isSel ? .bold : .medium))
                .foregroundStyle(isSel ? (isDark ? .white : Color(hex: 0x0F172A)) : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSel
                        ? (isDark ? Color(hex: 0x334155) : Color.white)
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(color: isSel ? Color.black.opacity(0.08) : Color.clear, radius: 2, y: 1)
        }
    }

    // MARK: - STATS SECTION VIEW
    private var statsSectionView: some View {
        guard let habit = editingHabit else { return AnyView(EmptyView()) }
        let stats = HabitStatsCalculator.calculate(habit: habit, entries: allEntries, period: chartPeriod)

        return AnyView(
            VStack(spacing: 16) {
                // 4 Metric cards
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    metricCard(
                        icon: "🔥",
                        value: stats.currentStreakText,
                        label: "Текущая серия",
                        sub: stats.currentStreakRange
                    )
                    metricCard(
                        icon: "🏆",
                        value: stats.bestStreakText,
                        label: "Лучшая серия",
                        sub: stats.bestStreakRange
                    )
                    metricCard(
                        icon: "📈",
                        value: "\(stats.rate30Days)%",
                        label: "Успешность (30 дн.)",
                        sub: "за 30 дней"
                    )
                    metricCard(
                        icon: "🎯",
                        value: stats.dynamicValue,
                        label: stats.dynamicLabel,
                        sub: stats.dynamicSub
                    )
                }

                // 12-column Bar Chart
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Text("📊")
                            Menu {
                                Button("По дням") { chartPeriod = "days" }
                                Button("По неделям") { chartPeriod = "weeks" }
                                Button("По месяцам") { chartPeriod = "months" }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(periodName(chartPeriod))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }

                        Spacer()

                        Text(stats.targetBadge)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    // 12 Columns
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(stats.weeklyBars) { bar in
                            VStack(spacing: 4) {
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                                        .frame(height: 84)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(barColor(for: bar))
                                        .frame(height: max(6, 84 * bar.heightFraction))

                                    if !bar.valueText.isEmpty {
                                        Text(bar.valueText)
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(bar.heightFraction > 0.35 ? Color.white : (isDark ? Color.white : Color(hex: 0x0F172A)))
                                            .padding(.bottom, 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                Text(bar.label)
                                    .font(.system(size: 9, weight: bar.isCurrent ? .bold : .regular))
                                    .foregroundStyle(bar.isCurrent ? theme.currentAccent.primary : .secondary)
                            }
                        }
                    }
                    .frame(height: 110)
                }
                .padding(14)
                .background(cardBackground)

                // Activity Tabs: [4 Недели] [Частота] [Месяц подробно]
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        activityTabButton(index: 0, title: "📅 4 недели")
                        activityTabButton(index: 1, title: "🫧 Частота")
                        activityTabButton(index: 2, title: "📆 Месяц")
                    }
                    .padding(2)
                    .background(isDark ? Color(hex: 0x263044) : Color(hex: 0xE2E8F0))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    if selectedActivityTab == 0 {
                        // 4-week Heatmap Grid
                        VStack(spacing: 6) {
                            let dows = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
                            HStack {
                                ForEach(dows, id: \.self) { d in
                                    Text(d)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            ForEach(0..<stats.heatmapWeeks.count, id: \.self) { wIdx in
                                HStack(spacing: 4) {
                                    ForEach(stats.heatmapWeeks[wIdx]) { cell in
                                        cellHeatmapView(cell: cell, habit: habit)
                                    }
                                }
                            }

                            Text(stats.bestDayInsight)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(theme.currentAccent.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                        .padding(12)
                        .background(cardBackground)
                    } else if selectedActivityTab == 1 {
                        // Frequency bubble matrix
                        VStack(spacing: 8) {
                            ForEach(stats.frequencyData.rows) { row in
                                HStack(spacing: 10) {
                                    Text(row.dowShort)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24, alignment: .leading)

                                    HStack(spacing: 12) {
                                        ForEach(row.months) { m in
                                            ZStack {
                                                if m.rate > 0 {
                                                    Circle()
                                                        .fill(theme.currentAccent.primary.opacity(Double(0.35 + (m.rate * 0.65))))
                                                        .frame(width: 8 + (m.rate * 16), height: 8 + (m.rate * 16))
                                                } else {
                                                    Circle()
                                                        .fill(isDark ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1))
                                                        .frame(width: 4, height: 4)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(cardBackground)
                    } else {
                        // Full Month Heatmap
                        HabitMonthHeatmapView(
                            habit: habit,
                            entries: allEntries,
                            onToggleDay: { dateStr in
                                toggleHabitDay(habitId: habit.id, dateStr: dateStr)
                            },
                            onOpenStepper: { dateStr in
                                activeStepperDateStr = dateStr
                            },
                            onSetStatus: { dateStr, status in
                                updateHabitEntry(habitId: habit.id, dateStr: dateStr, value: habit.targetValue, status: status)
                            }
                        )
                    }
                }
            }
        )
    }

    private func cellHeatmapView(cell: HabitHeatmapCell, habit: HabitItem) -> some View {
        let color: Color = {
            switch cell.level {
            case 4: return Color(hex: 0x38BDF8)
            case 5: return Color(hex: 0xEF4444).opacity(0.8)
            case 3: return theme.currentAccent.primary
            case 2: return theme.currentAccent.primary.opacity(0.6)
            case 1: return theme.currentAccent.primary.opacity(0.25)
            default: return isDark ? Color(hex: 0x263044) : Color(hex: 0xE2E8F0)
            }
        }()

        return ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(color)
                .frame(height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(cell.isCurrent ? theme.currentAccent.primary : Color.clear, lineWidth: 1.5)
                )

            if cell.level == 4 {
                Text("❄").font(.system(size: 9)).foregroundStyle(.white)
            } else if cell.level == 5 {
                Text("✕").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            guard !cell.isFuture else { return }
            MiodiHapticFeedback.taskComplete()
            if habit.type == "numeric" {
                activeStepperDateStr = cell.dateStr
            } else {
                toggleHabitDay(habitId: habit.id, dateStr: cell.dateStr)
            }
        }
    }

    private func activityTabButton(index: Int, title: String) -> some View {
        let isSel = selectedActivityTab == index
        return Button {
            selectedActivityTab = index
            MiodiHapticFeedback.lightClick()
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSel ? .bold : .medium))
                .foregroundStyle(isSel ? theme.currentAccent.primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSel ? (isDark ? Color(hex: 0x334155) : Color.white) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func metricCard(icon: String, value: String, label: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(icon).font(.system(size: 16))
                Spacer()
            }
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            if !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.04), radius: 4, y: 1)
    }

    private func periodName(_ p: String) -> String {
        switch p {
        case "days": return "Дни"
        case "months": return "Месяцы"
        default: return "Недели"
        }
    }

    private func barColor(for bar: HabitBarItem) -> Color {
        switch bar.status {
        case "frozen": return Color(hex: 0x38BDF8)
        case "failed": return Color(hex: 0xEF4444).opacity(0.8)
        default: return bar.isCurrent ? theme.currentAccent.primary : theme.currentAccent.primary.opacity(0.65)
        }
    }

    // MARK: - SETTINGS SECTION VIEW
    private var settingsSectionView: some View {
        VStack(spacing: 16) {
            // 1. Title Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Название привычки")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("Например: Читать 20 минут или 💧 Выпить воды", text: $title)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(isDark ? Color(hex: 0x1E293B) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.currentAccent.primary.opacity(0.3), lineWidth: 1)
                    )
            }

            // 2. Type Selector: [✓ Да / Нет] vs [123 Измеримая]
            VStack(alignment: .leading, spacing: 8) {
                Text("Тип привычки")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    typeOptionButton(
                        typeKey: "boolean",
                        symbol: "✓",
                        title: "Да / Нет",
                        subtitle: "Простая отметка"
                    )
                    typeOptionButton(
                        typeKey: "numeric",
                        symbol: "123",
                        title: "Измеримая",
                        subtitle: "Шаг, цель, единицы"
                    )
                }

                // Numeric parameters if selected
                if habitType == "numeric" {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Цель в день")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                TextField("2", text: $targetValueStr)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(isDark ? Color(hex: 0x0F172A) : Color(hex: 0xF1F5F9))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Шаг (+ / −)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                TextField("1", text: $targetStepStr)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(isDark ? Color(hex: 0x0F172A) : Color(hex: 0xF1F5F9))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        // Common unit chips
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Единица измерения")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(unitPresets, id: \.self) { unit in
                                        let isSel = (targetUnit == unit)
                                        Button {
                                            targetUnit = unit
                                            MiodiHapticFeedback.lightClick()
                                        } label: {
                                            Text(unit)
                                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(isSel ? theme.currentAccent.primary : (isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0)))
                                                .foregroundStyle(isSel ? .white : (isDark ? .white : Color(hex: 0x1E293B)))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }

                            TextField("Своя единица (например: глав, сетов)", text: $customUnit)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(8)
                                .background(isDark ? Color(hex: 0x0F172A) : Color(hex: 0xF1F5F9))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onChange(of: customUnit) { _, newVal in
                                    if !newVal.trimmingCharacters(in: .whitespaces).isEmpty {
                                        targetUnit = newVal.trimmingCharacters(in: .whitespaces)
                                    }
                                }
                        }
                    }
                    .padding(12)
                    .background(cardBackground)
                }
            }

            // 3. Regularity / Schedule
            VStack(alignment: .leading, spacing: 8) {
                Text("Регулярность")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 0) {
                    scheduleOptionTab(type: "daily", title: "Каждый день")
                    scheduleOptionTab(type: "weekdays", title: "По дням")
                    scheduleOptionTab(type: "periodic", title: "Периодическая")
                }
                .padding(2)
                .background(isDark ? Color(hex: 0x1E293B) : Color(hex: 0xE2E8F0))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if scheduleType == "weekdays" {
                    // 7 Weekday Circles (Mon..Sun)
                    let dows = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { dow in
                            let isSel = selectedDaysOfWeek.contains(dow)
                            Button {
                                if isSel {
                                    if selectedDaysOfWeek.count > 1 {
                                        selectedDaysOfWeek.remove(dow)
                                    }
                                } else {
                                    selectedDaysOfWeek.insert(dow)
                                }
                                MiodiHapticFeedback.selection()
                            } label: {
                                Text(dows[dow - 1])
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(isSel ? theme.currentAccent.primary : (isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0)))
                                    .foregroundStyle(isSel ? .white : (isDark ? .white : Color(hex: 0x1E293B)))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.top, 4)
                } else if scheduleType == "periodic" {
                    // Periodic counter
                    HStack {
                        Text("Выполнять:")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        Spacer()

                        HStack(spacing: 8) {
                            Button {
                                periodicTargetCount = max(1, periodicTargetCount - 1)
                                MiodiHapticFeedback.lightClick()
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 28, height: 28)
                                    .background(isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0))
                                    .clipShape(Circle())
                            }

                            Text("\(periodicTargetCount) раз")
                                .font(.system(size: 14, weight: .bold))

                            Button {
                                let maxAllowed = periodicPeriod == "week" ? 7 : 31
                                periodicTargetCount = min(maxAllowed, periodicTargetCount + 1)
                                MiodiHapticFeedback.lightClick()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 28, height: 28)
                                    .background(isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0))
                                    .clipShape(Circle())
                            }

                            Button {
                                periodicPeriod = (periodicPeriod == "week") ? "month" : "week"
                                MiodiHapticFeedback.lightClick()
                            } label: {
                                Text(periodicPeriod == "week" ? "в неделю" : "в месяц")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(theme.currentAccent.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(theme.currentAccent.primary.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(12)
                    .background(cardBackground)
                }
            }

            // 4. Reminders
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Text("⏰")
                        Text("Напоминания")
                            .font(.system(size: 13, weight: .semibold))
                    }

                    Spacer()

                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                        .tint(theme.currentAccent.primary)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled && reminderTimes.isEmpty {
                                reminderTimes = ["09:00"]
                            }
                            MiodiHapticFeedback.lightClick()
                        }
                }

                if reminderEnabled {
                    // Time Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(reminderTimes, id: \.self) { time in
                                HStack(spacing: 4) {
                                    Text(time)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(theme.currentAccent.primary)

                                    Button {
                                        reminderTimes.removeAll { $0 == time }
                                        if reminderTimes.isEmpty { reminderEnabled = false }
                                        MiodiHapticFeedback.lightClick()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(theme.currentAccent.primary.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(theme.currentAccent.primary.opacity(0.12))
                                .clipShape(Capsule())
                            }

                            Button {
                                isShowingTimePicker = true
                                MiodiHapticFeedback.lightClick()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Время")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.currentAccent.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .strokeBorder(theme.currentAccent.primary, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(cardBackground)

            // 5. Freeze & Delete Actions if Editing
            if isEditMode {
                Button {
                    isShowingFreezeModal = true
                    MiodiHapticFeedback.lightClick()
                } label: {
                    HStack(spacing: 6) {
                        Text("❄️")
                        Text("Заморозить на время отпуска...")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0284C7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0x0284C7).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 6)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                    MiodiHapticFeedback.warning()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Удалить привычку")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xEF4444))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0xEF4444).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
        }
    }

    private func typeOptionButton(typeKey: String, symbol: String, title: String, subtitle: String) -> some View {
        let isSel = habitType == typeKey
        return Button {
            habitType = typeKey
            MiodiHapticFeedback.selection()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(symbol)
                        .font(.system(size: 15, weight: .heavy))
                    Spacer()
                    if isSel {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.currentAccent.primary)
                    }
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSel ? theme.currentAccent.primary.opacity(0.12) : (isDark ? Color(hex: 0x1E293B) : Color.white))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSel ? theme.currentAccent.primary : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
        }
    }

    private func scheduleOptionTab(type: String, title: String) -> some View {
        let isSel = scheduleType == type
        return Button {
            scheduleType = type
            MiodiHapticFeedback.selection()
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSel ? .bold : .medium))
                .foregroundStyle(isSel ? theme.currentAccent.primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSel ? (isDark ? Color(hex: 0x334155) : Color.white) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var timePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Выберите время", selection: $newReminderDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Новое время")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { isShowingTimePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        let f = DateFormatter()
                        f.dateFormat = "HH:mm"
                        let timeStr = f.string(from: newReminderDate)
                        if !reminderTimes.contains(timeStr) {
                            reminderTimes.append(timeStr)
                            reminderTimes.sort()
                        }
                        isShowingTimePicker = false
                        MiodiHapticFeedback.lightClick()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.4)])
    }

    // MARK: - Business Logic & Persistence
    private func loadInitialState() {
        guard let habit = editingHabit else { return }
        title = habit.title
        habitType = habit.type
        targetValueStr = HabitNumericStepperSheet.formatValue(habit.targetValue)
        targetStepStr = HabitNumericStepperSheet.formatValue(habit.targetStep)
        targetUnit = habit.targetUnit.isEmpty ? "стакан" : habit.targetUnit
        scheduleType = habit.scheduleType
        selectedDaysOfWeek = habit.daysOfWeekSet
        periodicTargetCount = habit.scheduleTargetCount
        periodicPeriod = habit.schedulePeriod
        reminderEnabled = habit.reminderEnabled
        reminderTimes = habit.reminderTimes.isEmpty ? ["09:00"] : habit.reminderTimes
    }

    private func saveHabit() {
        let tVal = Float(targetValueStr.replacingOccurrences(of: ",", with: ".")) ?? 1.0
        let tStep = Float(targetStepStr.replacingOccurrences(of: ",", with: ".")) ?? 1.0

        if let habit = editingHabit {
            habit.title = title.trimmingCharacters(in: .whitespaces)
            habit.type = habitType
            habit.targetValue = max(0.1, tVal)
            habit.targetStep = max(0.1, tStep)
            habit.targetUnit = targetUnit.trimmingCharacters(in: .whitespaces)
            habit.scheduleType = scheduleType
            habit.setDaysOfWeek(selectedDaysOfWeek)
            habit.scheduleTargetCount = periodicTargetCount
            habit.schedulePeriod = periodicPeriod
            habit.reminderEnabled = reminderEnabled
            habit.setReminderTimes(reminderTimes)

            try? modelContext.save()
            onSave?(habit)
        } else {
            let newHabit = HabitItem(
                title: title.trimmingCharacters(in: .whitespaces),
                type: habitType,
                targetValue: max(0.1, tVal),
                targetUnit: targetUnit.trimmingCharacters(in: .whitespaces),
                targetStep: max(0.1, tStep),
                scheduleType: scheduleType,
                scheduleDaysOfWeek: selectedDaysOfWeek.sorted().map { String($0) }.joined(separator: ","),
                scheduleTargetCount: periodicTargetCount,
                schedulePeriod: periodicPeriod,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTimes.joined(separator: ", ")
            )
            modelContext.insert(newHabit)
            try? modelContext.save()
            onSave?(newHabit)
        }
        MiodiHapticFeedback.success()
    }

    private func deleteCurrentHabit() {
        guard let habit = editingHabit else { return }
        // Delete all related entries
        let relatedEntries = allEntries.filter { $0.habitId == habit.id }
        for e in relatedEntries {
            modelContext.delete(e)
        }
        modelContext.delete(habit)
        try? modelContext.save()
        onDelete?(habit)
        MiodiHapticFeedback.warning()
        dismiss()
    }

    private func toggleHabitDay(habitId: String, dateStr: String) {
        if let existing = allEntries.first(where: { $0.habitId == habitId && $0.date == dateStr }) {
            existing.isCompleted.toggle()
            existing.status = existing.isCompleted ? "completed" : "failed"
            existing.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
        } else {
            let newEntry = HabitEntryItem(
                id: "\(habitId)_\(dateStr)",
                habitId: habitId,
                date: dateStr,
                value: 1.0,
                isCompleted: true,
                status: "completed"
            )
            modelContext.insert(newEntry)
        }
        try? modelContext.save()
    }

    private func updateHabitEntry(habitId: String, dateStr: String, value: Float, status: String) {
        let isDone = status == "completed" && value > 0
        if let existing = allEntries.first(where: { $0.habitId == habitId && $0.date == dateStr }) {
            existing.value = value
            existing.status = status
            existing.isCompleted = isDone
            existing.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
        } else {
            let newEntry = HabitEntryItem(
                id: "\(habitId)_\(dateStr)",
                habitId: habitId,
                date: dateStr,
                value: value,
                isCompleted: isDone,
                status: status
            )
            modelContext.insert(newEntry)
        }
        try? modelContext.save()
    }
}

private struct StepperDateHolder: Identifiable {
    let id = UUID()
    let dateStr: String
}
