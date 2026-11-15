//
//  HabitsView.swift
//  Plan4U_iOS
//
//  Habits Tracker screen matching Android Habit components 1-to-1.
//  Weekly check-ins matrix, numeric/boolean progress, Taptic triggers,
//  drag-and-drop reordering, vacation/habit freeze modal,
//  and festive milestone celebrations (7, 21, 66, 100 days)!
//

import SwiftUI
import SwiftData

public struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \HabitItem.orderIndex) private var habits: [HabitItem]
    @Query private var entries: [HabitEntryItem]

    @State private var isShowingCreateHabit: Bool = false
    @State private var editingHabit: HabitItem? = nil
    @State private var isShowingCycleTracker: Bool = false
    @State private var isShowingFreezeModal: Bool = false
    @State private var isReordering: Bool = false
    @State private var stepperHabitDate: StepperHabitHolder? = nil
    @State private var activeMilestone: HabitMilestone? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init() {}

    private var todayStr: String {
        isoFormatter.string(from: Date())
    }

    public var body: some View {
        ZStack {
            // Authentic paper background
            NotebookCanvasView(
                patternType: .lines,
                patternSize: 32,
                marginLineX: 50,
                isDarkTheme: isDark
            )

            VStack(spacing: 0) {
                // Section Header
                HStack(spacing: 8) {
                    Text("Привычки")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)

                    Spacer()

                    // Reorder Toggle Button
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            isReordering.toggle()
                        }
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down")
                            if isReordering {
                                Text("Готово")
                            }
                        }
                        .font(.system(size: 12.5, weight: .bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isReordering ? theme.currentAccent.primary : (isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0)))
                        )
                        .foregroundStyle(isReordering ? .white : (isDark ? .white : Color(hex: 0x0F172A)))
                    }

                    // Vacation / Freeze Mode Button
                    Button {
                        MiodiHapticFeedback.lightClick()
                        isShowingFreezeModal = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("❄️")
                            Text("Отпуск")
                        }
                        .font(.system(size: 12.5, weight: .semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color(hex: 0x0284C7).opacity(0.16))
                        )
                        .foregroundStyle(Color(hex: 0x0284C7))
                    }

                    // Female Cycle Quick Access Button
                    Button {
                        MiodiHapticFeedback.lightClick()
                        isShowingCycleTracker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("🍒")
                            Text("Цикл")
                        }
                        .font(.system(size: 12.5, weight: .semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color(hex: 0xFB7185).opacity(0.18))
                        )
                        .foregroundStyle(Color(hex: 0xFB7185))
                    }

                    // + Add Habit Button
                    Button {
                        MiodiHapticFeedback.lightClick()
                        isShowingCreateHabit = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Привычка")
                        }
                        .font(.system(size: 12.5, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(theme.currentAccent.primary.opacity(0.15))
                        )
                        .foregroundStyle(theme.currentAccent.primary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isDark ? MiodiStaticColors.darkTopBarBg : Color.white.opacity(0.85))

                // Reorder Hint Banner (when reordering active)
                if isReordering {
                    HStack {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 12))
                        Text("Перетаскивайте привычки за маркеры справа для смены порядка")
                            .font(.system(size: 11.5, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(theme.currentAccent.primary.opacity(0.12))
                    .foregroundStyle(theme.currentAccent.primary)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Habits List with native onMove Drag-and-Drop
                if habits.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "flame")
                            .font(.system(size: 38))
                            .foregroundStyle(theme.currentAccent.primary.opacity(0.6))
                        Text("Нет привычек")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Нажмите «+ Привычка», чтобы настроить цели и расписание")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(habits) { habit in
                            HabitCardRowView(
                                habit: habit,
                                entries: entries.filter { $0.habitId == habit.id },
                                todayStr: todayStr,
                                isReordering: isReordering,
                                onMoveUp: { moveHabitOneStep(habit: habit, direction: -1) },
                                onMoveDown: { moveHabitOneStep(habit: habit, direction: 1) },
                                onTapCard: {
                                    if !isReordering {
                                        editingHabit = habit
                                    }
                                },
                                onToggleCheck: {
                                    if !isReordering {
                                        if habit.type == "numeric" {
                                            stepperHabitDate = StepperHabitHolder(habit: habit, dateStr: todayStr)
                                        } else {
                                            toggleTodayCompletion(habit: habit)
                                        }
                                    }
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 5, leading: 14, bottom: 5, trailing: 14))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onMove(perform: moveHabits)

                        // Bottom Spacing
                        Color.clear
                            .frame(height: 110)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, isReordering ? .constant(.active) : .constant(.inactive))
                }
            }
        }
        // Modal for Creating Habit
        .sheet(isPresented: $isShowingCreateHabit) {
            HabitDetailModalView()
        }
        // Modal for Editing Habit
        .sheet(item: $editingHabit) { habit in
            HabitDetailModalView(editingHabit: habit)
        }
        // Modal for Female Cycle Tracker
        .sheet(isPresented: $isShowingCycleTracker) {
            CycleTrackerView()
        }
        // Modal for Habit Vacation/Freeze Mode
        .sheet(isPresented: $isShowingFreezeModal) {
            HabitFreezeModalView()
        }
        // Stepper sheet for Numeric habit
        .sheet(item: $stepperHabitDate) { holder in
            let entry = entries.first { $0.habitId == holder.habit.id && $0.date == holder.dateStr }
            HabitNumericStepperSheet(
                habit: holder.habit,
                dateStr: holder.dateStr,
                initialValue: entry?.value ?? 0,
                status: entry?.status ?? "completed",
                onSave: { newVal, status in
                    updateNumericEntry(habit: holder.habit, dateStr: holder.dateStr, value: newVal, status: status)
                },
                onDismiss: {
                    stepperHabitDate = nil
                }
            )
        }
        // Milestone Celebration Confetti Overlay
        .fullScreenCover(item: $activeMilestone) { milestone in
            HabitMilestoneAlertView(milestone: milestone) {
                activeMilestone = nil
            }
        }
    }

    // MARK: - Drag-and-Drop Reordering Logic
    private func moveHabits(from source: IndexSet, to destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, habit) in reordered.enumerated() {
            habit.orderIndex = idx
        }
        try? modelContext.save()
        MiodiHapticFeedback.lightClick()
    }

    private func moveHabitOneStep(habit: HabitItem, direction: Int) {
        guard let currentIdx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let newIdx = currentIdx + direction
        guard newIdx >= 0 && newIdx < habits.count else { return }

        var reordered = habits
        let item = reordered.remove(at: currentIdx)
        reordered.insert(item, at: newIdx)

        for (idx, h) in reordered.enumerated() {
            h.orderIndex = idx
        }
        try? modelContext.save()
        MiodiHapticFeedback.selection()
    }

    // MARK: - Business Logic & Streak Milestone Check
    private func toggleTodayCompletion(habit: HabitItem) {
        if let existing = entries.first(where: { $0.habitId == habit.id && $0.date == todayStr }) {
            existing.isCompleted.toggle()
            existing.status = existing.isCompleted ? "completed" : "failed"
            existing.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
            if existing.isCompleted {
                MiodiHapticFeedback.taskComplete()
                checkMilestoneStreak(habit: habit)
            } else {
                MiodiHapticFeedback.lightClick()
            }
        } else {
            let newEntry = HabitEntryItem(
                id: "\(habit.id)_\(todayStr)",
                habitId: habit.id,
                date: todayStr,
                value: 1.0,
                isCompleted: true,
                status: "completed"
            )
            modelContext.insert(newEntry)
            MiodiHapticFeedback.taskComplete()
            checkMilestoneStreak(habit: habit)
        }
        try? modelContext.save()
    }

    private func updateNumericEntry(habit: HabitItem, dateStr: String, value: Float, status: String) {
        let isDone = status == "completed" && value >= (habit.targetValue > 0 ? habit.targetValue : 1.0)
        if let existing = entries.first(where: { $0.habitId == habit.id && $0.date == dateStr }) {
            existing.value = value
            existing.status = status
            existing.isCompleted = isDone
            existing.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
        } else {
            let newEntry = HabitEntryItem(
                id: "\(habit.id)_\(dateStr)",
                habitId: habit.id,
                date: dateStr,
                value: value,
                isCompleted: isDone,
                status: status
            )
            modelContext.insert(newEntry)
        }
        try? modelContext.save()
        if isDone {
            MiodiHapticFeedback.success()
            checkMilestoneStreak(habit: habit)
        } else {
            MiodiHapticFeedback.lightClick()
        }
    }

    private func checkMilestoneStreak(habit: HabitItem) {
        try? modelContext.save()
        let stats = HabitStatsCalculator.calculate(habit: habit, entries: entries)
        let cur = stats.currentStreak
        if [7, 21, 66, 100].contains(cur) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activeMilestone = HabitMilestone(days: cur, habitTitle: habit.title)
            }
        }
    }
}

private struct StepperHabitHolder: Identifiable {
    let id = UUID()
    let habit: HabitItem
    let dateStr: String
}

private struct HabitCardRowView: View {
    @Bindable var habit: HabitItem
    let entries: [HabitEntryItem]
    let todayStr: String
    var isReordering: Bool = false
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    let onTapCard: () -> Void
    let onToggleCheck: () -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var todayEntry: HabitEntryItem? {
        entries.first { $0.date == todayStr }
    }

    private var isCompletedToday: Bool {
        todayEntry?.isCompleted == true
    }

    private var isFrozenToday: Bool {
        todayEntry?.status == "frozen"
    }

    private var numericProgressText: String? {
        guard habit.type == "numeric" else { return nil }
        let current = todayEntry?.value ?? 0
        let target = habit.targetValue
        let unit = habit.targetUnit
        return "\(HabitNumericStepperSheet.formatValue(current)) / \(HabitNumericStepperSheet.formatValue(target)) \(unit)"
    }

    private var past7DaysStatus: [(isDone: Bool, isFrozen: Bool)] {
        let calendar = Calendar.current
        let today = Date()
        let entryMap = Dictionary(entries.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"

        var result: [(isDone: Bool, isFrozen: Bool)] = []
        for i in (0..<7).reversed() {
            if let d = calendar.date(byAdding: .day, value: -i, to: today) {
                let dStr = f.string(from: d)
                let entry = entryMap[dStr]
                result.append((isDone: entry?.isCompleted == true, isFrozen: entry?.status == "frozen"))
            } else {
                result.append((false, false))
            }
        }
        return result
    }

    var body: some View {
        HStack(spacing: 12) {
            // Reordering Single-Click Arrows (when reorder mode active)
            if isReordering {
                VStack(spacing: 2) {
                    Button {
                        onMoveUp?()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(4)
                    }

                    Button {
                        onMoveDown?()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(4)
                    }
                }
            }

            // Checkmark or Numeric Button
            Button(action: onToggleCheck) {
                ZStack {
                    let strokeColor: Color = {
                        if isCompletedToday { return theme.currentAccent.primary }
                        if isFrozenToday { return Color(hex: 0x38BDF8) }
                        return Color.gray.opacity(0.4)
                    }()

                    let fillColor: Color = {
                        if isCompletedToday { return theme.currentAccent.primary }
                        if isFrozenToday { return isDark ? Color(hex: 0x0C2B3C) : Color(hex: 0xE0F2FE) }
                        return Color.clear
                    }()

                    Circle()
                        .strokeBorder(strokeColor, lineWidth: 2)
                        .background(Circle().fill(fillColor))
                        .frame(width: 34, height: 34)

                    if isFrozenToday {
                        Text("❄️")
                            .font(.system(size: 13))
                    } else if habit.type == "numeric" {
                        if isCompletedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text(todayEntry?.value ?? 0 > 0 ? "\(Int(todayEntry!.value))" : "＋")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(todayEntry?.value ?? 0 > 0 ? theme.currentAccent.primary : .secondary)
                        }
                    } else {
                        if isCompletedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Content Info - Click opens Detail Modal
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let progress = numericProgressText {
                        Text(progress)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.currentAccent.primary)
                    } else {
                        Text(scheduleDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    if isFrozenToday {
                        Text("• ❄️ На заморозке")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x0284C7))
                    }

                    if habit.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapCard)

            // Past 7 Days Micro Circles (unless in reorder mode)
            if !isReordering {
                HStack(spacing: 4) {
                    ForEach(0..<past7DaysStatus.count, id: \.self) { idx in
                        let status = past7DaysStatus[idx]
                        if status.isFrozen {
                            Text("❄")
                                .font(.system(size: 7))
                                .foregroundStyle(Color(hex: 0x38BDF8))
                        } else {
                            Circle()
                                .fill(status.isDone ? theme.currentAccent.primary : (isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0)))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onTapCard)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.05), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isDark ? Color(hex: 0x2A3347) : Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var scheduleDescription: String {
        switch habit.scheduleType {
        case "weekdays":
            return "По дням недели"
        case "periodic":
            return "\(habit.scheduleTargetCount) раз \(habit.schedulePeriod == "week" ? "в нед." : "в мес.")"
        default:
            return "Каждый день"
        }
    }
}
