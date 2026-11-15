//
//  HabitsTrayView.swift
//  Plan4U_iOS
//
//  Interactive slide-up bottom tray for habits under tasks screen.
//  Matching Android HabitsSubstrateTray.kt 1-to-1.
//  Allows check-ins, numeric stepper, status contexts (completed, failed, frozen),
//  habit freeze activation, and milestone celebrations (7, 21, 66, 100 days) directly from tasks!
//

import SwiftUI
import SwiftData

public struct HabitsTrayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \HabitItem.orderIndex) private var habits: [HabitItem]
    @Query private var entries: [HabitEntryItem]

    @Binding public var isExpanded: Bool

    // Modals
    @State private var editingHabit: HabitItem? = nil
    @State private var isShowingCreateHabit: Bool = false
    @State private var isShowingFreezeModal: Bool = false
    @State private var stepperHolder: TrayStepperHolder? = nil
    @State private var activeMilestone: HabitMilestone? = nil

    // Drag offset for rubber-band interaction
    @State private var dragOffsetY: CGFloat = 0.0

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init(isExpanded: Binding<Bool>) {
        self._isExpanded = isExpanded
    }

    private var todayStr: String {
        isoFormatter.string(from: Date())
    }

    // 7 Week Dates (Mon..Sun of current calendar week, matching Android)
    private var currentWeekDates: [(name: String, dateStr: String, isToday: Bool)] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...
        let daysFromMonday = (weekday + 5) % 7 // 0=Mon..6=Sun

        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        let dayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        var list: [(name: String, dateStr: String, isToday: Bool)] = []

        for i in 0..<7 {
            if let d = calendar.date(byAdding: .day, value: i, to: monday) {
                let ds = isoFormatter.string(from: d)
                list.append((name: dayNames[i], dateStr: ds, isToday: ds == todayStr))
            }
        }
        return list
    }

    private var completedTodayCount: Int {
        habits.count { habit in
            let entry = entries.first { $0.habitId == habit.id && $0.date == todayStr }
            return entry?.isCompleted == true
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedTrayView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                collapsedPillView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded)
        // Modals
        .sheet(item: $editingHabit) { habit in
            HabitDetailModalView(editingHabit: habit)
        }
        .sheet(isPresented: $isShowingCreateHabit) {
            HabitDetailModalView()
        }
        .sheet(isPresented: $isShowingFreezeModal) {
            HabitFreezeModalView()
        }
        .sheet(item: $stepperHolder) { holder in
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
                    stepperHolder = nil
                }
            )
        }
        .fullScreenCover(item: $activeMilestone) { milestone in
            HabitMilestoneAlertView(milestone: milestone) {
                activeMilestone = nil
            }
        }
    }

    // MARK: - Collapsed Floating Pill View
    private var collapsedPillView: some View {
        HStack(spacing: 10) {
            // Target Icon
            Text("🎯")
                .font(.system(size: 15))

            // Progress text
            Text("Привычки: \(completedTodayCount)/\(habits.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDark ? Color.white : Color(hex: 0x0F172A))

            // Mini day dots
            HStack(spacing: 3) {
                ForEach(habits.prefix(5)) { habit in
                    let isDone = entries.first { $0.habitId == habit.id && $0.date == todayStr }?.isCompleted == true
                    Circle()
                        .fill(isDone ? theme.currentAccent.primary : (isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1)))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            // Expand button pill
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isExpanded = true
                }
                MiodiHapticFeedback.lightClick()
            } label: {
                HStack(spacing: 4) {
                    Text("Раскрыть")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(theme.currentAccent.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.currentAccent.primary.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color(hex: 0x161C2C) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.08), radius: 10, x: 0, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDark ? Color(hex: 0x2A354E) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                isExpanded = true
            }
            MiodiHapticFeedback.lightClick()
        }
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    if value.translation.height < -20 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            isExpanded = true
                        }
                        MiodiHapticFeedback.selection()
                    }
                }
        )
    }

    // MARK: - Expanded Substrate Tray View
    private var expandedTrayView: some View {
        VStack(spacing: 8) {
            // Top Drag Handle (interactive collapse)
            HStack {
                Spacer()
                Capsule()
                    .fill(isDark ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1))
                    .frame(width: 38, height: 4.5)
                Spacer()
            }
            .padding(.top, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded = false
                }
                MiodiHapticFeedback.lightClick()
            }

            // Tray Header
            HStack(spacing: 8) {
                // Title & Today Counter Badge
                HStack(spacing: 6) {
                    Text("🎯")
                        .font(.system(size: 16))

                    Text("Привычки")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Text("\(completedTodayCount)/\(habits.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.currentAccent.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.currentAccent.primary.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()

                // Freeze / Vacation Mode button
                Button {
                    isShowingFreezeModal = true
                    MiodiHapticFeedback.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text("❄️")
                        Text("Отпуск")
                    }
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0284C7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .background(Color(hex: 0x0284C7).opacity(0.12))
                    .clipShape(Capsule())
                }

                // + Add Habit Button
                Button {
                    isShowingCreateHabit = true
                    MiodiHapticFeedback.lightClick()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Привычка")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(theme.currentAccent.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .background(theme.currentAccent.primary.opacity(0.15))
                    .clipShape(Capsule())
                }

                // Collapse Button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                    MiodiHapticFeedback.lightClick()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(isDark ? Color(hex: 0x334155) : Color(hex: 0xF1F5F9))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)

            // Week Day Names Bar (aligned with columns)
            weekDaysHeaderRow
                .padding(.horizontal, 14)
                .padding(.top, 4)

            // Habit Rows List
            ScrollView {
                VStack(spacing: 5) {
                    if habits.isEmpty {
                        emptyHabitsHint
                    } else {
                        ForEach(habits) { habit in
                            trayHabitRow(habit: habit)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 14)
            }
            .frame(maxHeight: 280)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isDark ? Color(hex: 0x141824) : Color(hex: 0xF8FAFC))
                .shadow(color: Color.black.opacity(isDark ? 0.45 : 0.12), radius: 16, x: 0, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isDark ? Color(hex: 0x2A354E) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 8)
        .offset(y: dragOffsetY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffsetY = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 60 || value.predictedEndTranslation.height > 120 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpanded = false
                            dragOffsetY = 0
                        }
                        MiodiHapticFeedback.lightClick()
                    } else {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            dragOffsetY = 0
                        }
                    }
                }
        )
    }

    // MARK: - Week Days Header Row
    private var weekDaysHeaderRow: some View {
        HStack(spacing: 0) {
            // Left spacer matching title column (1/3 width)
            Text("Привычка")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Right 7 day column headers (2/3 width)
            HStack(spacing: 4) {
                ForEach(currentWeekDates, id: \.dateStr) { day in
                    VStack(spacing: 2) {
                        Text(day.name)
                            .font(.system(size: 9.5, weight: day.isToday ? .heavy : .medium))
                            .foregroundStyle(day.isToday ? theme.currentAccent.primary : .secondary)

                        if day.isToday {
                            Circle()
                                .fill(theme.currentAccent.primary)
                                .frame(width: 4, height: 4)
                        } else {
                            Color.clear.frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Habit Row
    private func trayHabitRow(habit: HabitItem) -> some View {
        HStack(spacing: 0) {
            // Col 1: Habit title & reminder badge (left 1/3)
            HStack(spacing: 6) {
                // Accent Bar
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(theme.currentAccent.primary)
                    .frame(width: 3, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isDark ? Color.white : Color(hex: 0x0F172A))
                        .lineLimit(1)

                    if habit.scheduleType == "periodic" {
                        let completedCount = getPeriodicCompletedCount(habit: habit)
                        let targetCount = habit.scheduleTargetCount
                        let isGoalMet = completedCount >= targetCount
                        Text("🎯 \(completedCount)/\(targetCount) \(habit.schedulePeriod == "month" ? "в мес." : "в нед.")")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isGoalMet ? Color(hex: 0x10B981) : theme.currentAccent.primary)
                    } else if habit.reminderEnabled && !habit.reminderTime.isEmpty {
                        Text("⏰ \(habit.reminderTime)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(theme.currentAccent.primary)
                    } else if habit.type == "numeric" {
                        Text("🎯 \(HabitNumericStepperSheet.formatValue(habit.targetValue)) \(habit.targetUnit)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                editingHabit = habit
                MiodiHapticFeedback.lightClick()
            }

            // Col 2: 7 Day Checkboxes / progress cells (right 2/3)
            HStack(spacing: 4) {
                ForEach(currentWeekDates, id: \.dateStr) { day in
                    let entry = entries.first { $0.habitId == habit.id && $0.date == day.dateStr }
                    trayDayCell(habit: habit, day: day, entry: entry)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDark ? Color(hex: 0x1C2333) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.04), radius: 3, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isDark ? Color(hex: 0x2E3A52) : Color.black.opacity(0.06), lineWidth: 0.8)
        )
    }

    // MARK: - Tray Day Cell
    private func trayDayCell(habit: HabitItem, day: (name: String, dateStr: String, isToday: Bool), entry: HabitEntryItem?) -> some View {
        let isDone = entry?.isCompleted == true
        let isFrozen = entry?.status == "frozen"
        let isFailed = entry?.status == "failed"
        let isUnset = (entry == nil) || (entry?.status.isEmpty == true && !isDone)
        let isPastUnset = !day.isToday && day.dateStr < todayStr && isUnset

        // Check if rest day for weekdays schedule
        let isRestDay: Bool = {
            guard habit.scheduleType == "weekdays" else { return false }
            let cal = Calendar.current
            if let d = isoFormatter.date(from: day.dateStr) {
                let w = cal.component(.weekday, from: d)
                let stdDow = (w == 1) ? 7 : (w - 1)
                return !habit.daysOfWeekSet.contains(stdDow)
            }
            return false
        }()

        return Group {
            if habit.type == "numeric" && !isFrozen && !isFailed {
                let curVal = entry?.value ?? 0
                let target = max(0.1, habit.targetValue)
                let pct = CGFloat(min(max(curVal / target, 0), 1))
                let isNumDone = curVal >= target

                Button {
                    stepperHolder = TrayStepperHolder(habit: habit, dateStr: day.dateStr)
                    MiodiHapticFeedback.lightClick()
                } label: {
                    ZStack(alignment: .bottom) {
                        // Background cell
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isDark ? Color(hex: 0x222C3E) : Color(hex: 0xF1F5F9))

                        // Vertical Progress Fill
                        if pct > 0 {
                            GeometryReader { geo in
                                VStack {
                                    Spacer(minLength: 0)
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(theme.currentAccent.primary.opacity(isNumDone ? 1.0 : 0.8))
                                        .frame(height: geo.size.height * pct)
                                }
                            }
                        }

                        // Text or Checkmark
                        if isNumDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if pct > 0 {
                            Text("\(Int(pct * 100))%")
                                .font(.system(size: 7.5, weight: .bold))
                                .foregroundStyle(pct > 0.5 ? .white : (isDark ? .white : Color(hex: 0x0F172A)))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if isPastUnset {
                            Text("?")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: 27, height: 27)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                day.isToday
                                    ? theme.currentAccent.primary
                                    : (isPastUnset
                                        ? Color.gray.opacity(0.4)
                                        : (isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1))),
                                style: StrokeStyle(lineWidth: day.isToday ? 1.5 : 1, dash: isPastUnset ? [3, 2] : [])
                            )
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    contextMenuItems(habit: habit, dateStr: day.dateStr, isUnset: isUnset)
                }
            } else {
                // Boolean or Explicitly Frozen/Failed Habit
                let cellBg: Color = {
                    if isDone { return theme.currentAccent.primary }
                    if isFrozen { return isDark ? Color(hex: 0x0C2B3C) : Color(hex: 0xE0F2FE) }
                    if isFailed { return isDark ? Color(hex: 0x2C1920) : Color(hex: 0xFEE2E2) }
                    if isPastUnset { return isDark ? Color(hex: 0x161C26) : Color(hex: 0xF1F5F9) }
                    if day.isToday { return theme.currentAccent.primary.opacity(isDark ? 0.22 : 0.14) }
                    return isDark ? Color(hex: 0x222C3E) : Color(hex: 0xF1F5F9)
                }()

                let dayBorderColor: Color = {
                    if isDone { return theme.currentAccent.primary }
                    if isFrozen { return Color(hex: 0x38BDF8) }
                    if isFailed { return Color(hex: 0xEF4444) }
                    if day.isToday { return theme.currentAccent.primary }
                    return isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1)
                }()

                Button {
                    toggleHabitDay(habit: habit, dateStr: day.dateStr)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(cellBg)

                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else if isFrozen {
                            Text("❄️")
                                .font(.system(size: 10))
                        } else if isFailed {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: 0xEF4444))
                        } else if isPastUnset {
                            Text("?")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.secondary)
                        } else if isRestDay {
                            Circle()
                                .fill(isDark ? Color(hex: 0x64748B) : Color(hex: 0x94A3B8))
                                .frame(width: 3.5, height: 3.5)
                        }
                    }
                    .frame(width: 27, height: 27)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                dayBorderColor,
                                style: StrokeStyle(lineWidth: (isDone || day.isToday || isFrozen || isFailed) ? 1.4 : 1, dash: isPastUnset ? [3, 2] : [])
                            )
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    contextMenuItems(habit: habit, dateStr: day.dateStr, isUnset: isUnset)
                }
            }
        }
    }

    // MARK: - Context Menu for Day Cell
    @ViewBuilder
    private func contextMenuItems(habit: HabitItem, dateStr: String, isUnset: Bool) -> some View {
        Button {
            setDayStatus(habit: habit, dateStr: dateStr, status: "completed")
        } label: {
            Label("Выполнено", systemImage: "checkmark.circle.fill")
        }

        Button {
            setDayStatus(habit: habit, dateStr: dateStr, status: "failed")
        } label: {
            Label("Не выполнено", systemImage: "xmark.circle.fill")
        }

        Button {
            setDayStatus(habit: habit, dateStr: dateStr, status: "frozen")
        } label: {
            Label("Заморозить на этот день", systemImage: "snowflake")
        }

        if !isUnset {
            Divider()
            Button(role: .destructive) {
                setDayStatus(habit: habit, dateStr: dateStr, status: "clear")
            } label: {
                Label("Сбросить отметку", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: - Empty Habits Hint
    private var emptyHabitsHint: some View {
        Button {
            isShowingCreateHabit = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(theme.currentAccent.primary)
                Text("Нажмите, чтобы добавить первую привычку")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(theme.currentAccent.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
        }
    }

    // MARK: - Business Logic & Streak Milestone Check
    private func toggleHabitDay(habit: HabitItem, dateStr: String) {
        if let existing = entries.first(where: { $0.habitId == habit.id && $0.date == dateStr }) {
            if existing.isCompleted {
                // Uncheck / Clear
                modelContext.delete(existing)
                MiodiHapticFeedback.lightClick()
            } else {
                existing.isCompleted = true
                existing.status = "completed"
                existing.value = habit.targetValue > 0 ? habit.targetValue : 1.0
                existing.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
                MiodiHapticFeedback.taskComplete()
                checkMilestoneStreak(habit: habit)
            }
        } else {
            let entry = HabitEntryItem(
                id: "\(habit.id)_\(dateStr)",
                habitId: habit.id,
                date: dateStr,
                value: habit.targetValue > 0 ? habit.targetValue : 1.0,
                isCompleted: true,
                status: "completed"
            )
            modelContext.insert(entry)
            MiodiHapticFeedback.taskComplete()
            checkMilestoneStreak(habit: habit)
        }
        try? modelContext.save()
    }

    private func setDayStatus(habit: HabitItem, dateStr: String, status: String) {
        if status == "clear" {
            if let existing = entries.first(where: { $0.habitId == habit.id && $0.date == dateStr }) {
                modelContext.delete(existing)
            }
            MiodiHapticFeedback.lightClick()
        } else {
            let isComp = status == "completed"
            if let existing = entries.first(where: { $0.habitId == habit.id && $0.date == dateStr }) {
                existing.status = status
                existing.isCompleted = isComp
                existing.value = isComp ? habit.targetValue : 0
                existing.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
            } else {
                let entry = HabitEntryItem(
                    id: "\(habit.id)_\(dateStr)",
                    habitId: habit.id,
                    date: dateStr,
                    value: isComp ? habit.targetValue : 0,
                    isCompleted: isComp,
                    status: status
                )
                modelContext.insert(entry)
            }

            if status == "frozen" {
                MiodiHapticFeedback.iceFreeze()
            } else if isComp {
                MiodiHapticFeedback.taskComplete()
                checkMilestoneStreak(habit: habit)
            } else {
                MiodiHapticFeedback.lightClick()
            }
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
            let entry = HabitEntryItem(
                id: "\(habit.id)_\(dateStr)",
                habitId: habit.id,
                date: dateStr,
                value: value,
                isCompleted: isDone,
                status: status
            )
            modelContext.insert(entry)
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

    private func getPeriodicCompletedCount(habit: HabitItem) -> Int {
        if habit.schedulePeriod == "month" {
            let prefix = String(todayStr.prefix(7))
            return entries.count { $0.habitId == habit.id && $0.date.hasPrefix(prefix) && $0.isCompleted }
        } else {
            let weekDatesSet = Set(currentWeekDates.map { $0.dateStr })
            return entries.count { $0.habitId == habit.id && weekDatesSet.contains($0.date) && $0.isCompleted }
        }
    }
}

private struct TrayStepperHolder: Identifiable {
    let id = UUID()
    let habit: HabitItem
    let dateStr: String
}
