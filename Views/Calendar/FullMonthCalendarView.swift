//
//  FullMonthCalendarView.swift
//  Plan4U_iOS
//
//  Pixel-perfect and feature-complete port of Android CalendarModal.kt (963 lines).
//  Full month calendar grid with multi-dot event indicators:
//  - Tasks dot (blue / white)
//  - Nutrition avocado icon (🥑)
//  - Finance coin (💰) / No-Spend trophy (🏆)
//  - Joy jar sun (☀️)
//  - Habit all-done badge (green circle with checkmark)
//  - Moments camera badge
//  - Diary book badge
//  - Cycle / period highlight and cherry badge (🍒)
//  - Full interactive swipe gesture between months with Taptic feedback
//  - Diary mode with future date protection
//  - Rich summary card with active module tags
//  - Jump to today and Open Day action buttons
//

import SwiftUI
import SwiftData

public struct FullMonthCalendarView: View {
    // Dates
    public var selectedDate: String
    public var todayDate: String

    // Module Active Date Sets
    public var activeDates: Set<String>
    public var nutritionDates: Set<String>
    public var financeDates: Set<String>
    public var noSpendDates: Set<String>
    public var joyDates: Set<String>
    public var momentDates: Set<String>
    public var diaryDates: Set<String>
    public var cycleDates: Set<String>

    // Module Flags
    public var isCycleEnabled: Bool
    public var isNutritionEnabled: Bool
    public var isFinanceEnabled: Bool
    public var isJoyEnabled: Bool
    public var isMomentsEnabled: Bool
    public var isDiaryEnabled: Bool
    public var isDiaryMode: Bool

    // Data lists for detailed day summary
    public var tasks: [TaskItem]
    public var habits: [HabitItem]
    public var diaryEntries: [DiaryItem]

    // Actions
    public var onDismiss: () -> Void
    public var onOpenDiaryForDate: ((String) -> Void)?
    public var onOpenCycle: (() -> Void)?
    public var onSelectDate: (String) -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // Local Calendar State
    @State private var displayedMonthDate: Date
    @State private var selectedDayNum: Int
    @State private var dragOffset: CGFloat = 0

    public init(
        selectedDate: String = "",
        todayDate: String = "",
        activeDates: Set<String> = [],
        nutritionDates: Set<String> = [],
        financeDates: Set<String> = [],
        noSpendDates: Set<String> = [],
        joyDates: Set<String> = [],
        momentDates: Set<String> = [],
        diaryDates: Set<String> = [],
        cycleDates: Set<String> = [],
        isCycleEnabled: Bool = true,
        isNutritionEnabled: Bool = true,
        isFinanceEnabled: Bool = true,
        isJoyEnabled: Bool = true,
        isMomentsEnabled: Bool = true,
        isDiaryEnabled: Bool = true,
        isDiaryMode: Bool = false,
        tasks: [TaskItem] = [],
        habits: [HabitItem] = [],
        diaryEntries: [DiaryItem] = [],
        onDismiss: @escaping () -> Void = {},
        onOpenDiaryForDate: ((String) -> Void)? = nil,
        onOpenCycle: (() -> Void)? = nil,
        onSelectDate: @escaping (String) -> Void = { _ in }
    ) {
        let effToday = todayDate.isEmpty ? Date().yyyyMMddString : todayDate
        let effSel = selectedDate.isEmpty ? effToday : selectedDate
        self.selectedDate = effSel
        self.todayDate = effToday
        self.activeDates = activeDates
        self.nutritionDates = nutritionDates
        self.financeDates = financeDates
        self.noSpendDates = noSpendDates
        self.joyDates = joyDates
        self.momentDates = momentDates
        self.diaryDates = diaryDates
        self.cycleDates = cycleDates
        self.isCycleEnabled = isCycleEnabled
        self.isNutritionEnabled = isNutritionEnabled
        self.isFinanceEnabled = isFinanceEnabled
        self.isJoyEnabled = isJoyEnabled
        self.isMomentsEnabled = isMomentsEnabled
        self.isDiaryEnabled = isDiaryEnabled
        self.isDiaryMode = isDiaryMode
        self.tasks = tasks
        self.habits = habits
        self.diaryEntries = diaryEntries
        self.onDismiss = onDismiss
        self.onOpenDiaryForDate = onOpenDiaryForDate
        self.onOpenCycle = onOpenCycle
        self.onSelectDate = onSelectDate

        let initialDate = Date.from(yyyyMMdd: effSel) ?? Date()
        let cal = Calendar.current
        let day = cal.component(.day, from: initialDate)
        let comps = cal.dateComponents([.year, .month], from: initialDate)
        let firstOfMonth = cal.date(from: comps) ?? initialDate

        _displayedMonthDate = State(initialValue: firstOfMonth)
        _selectedDayNum = State(initialValue: day)
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday start (1 = Sunday, 2 = Monday)
        cal.locale = Locale(identifier: "ru_RU")
        return cal
    }

    private var effectiveTodayStr: String {
        todayDate.isEmpty ? Date().yyyyMMddString : todayDate
    }

    private var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        let str = formatter.string(from: displayedMonthDate)
        return str.prefix(1).uppercased() + str.dropFirst()
    }

    private var daysOfWeekHeaders: [String] {
        ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    }

    private var canGoNextMonth: Bool {
        if !isDiaryMode { return true }
        let now = Date()
        let cal = calendar
        let displayedComps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        let nowComps = cal.dateComponents([.year, .month], from: now)
        if let dYear = displayedComps.year, let nYear = nowComps.year,
           let dMonth = displayedComps.month, let nMonth = nowComps.month {
            return dYear < nYear || (dYear == nYear && dMonth < nMonth)
        }
        return true
    }

    // Fixed 6-row (42 cells) month days calculation
    private struct MonthCellData: Identifiable {
        let id: Int // 0..41
        let dayNumber: Int // 1..daysInMonth or 0 if outside
        let dateString: String
        let isToday: Bool
        let isFuture: Bool
        let isArchive: Bool
        let isClickable: Bool
    }

    private var monthCells: [MonthCellData] {
        let cal = calendar
        guard let range = cal.range(of: .day, in: .month, for: displayedMonthDate) else { return [] }
        let daysInMonth = range.count

        // Find weekday of the 1st day of the month (Monday = 0, Sunday = 6)
        let firstDayWeekday = cal.component(.weekday, from: displayedMonthDate)
        let startDayOffset = (firstDayWeekday + 5) % 7

        let yearMonthComps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        let year = yearMonthComps.year ?? 2026
        let month = yearMonthComps.month ?? 11

        var cells: [MonthCellData] = []
        for cellIdx in 0..<42 {
            let dayNum = cellIdx - startDayOffset + 1
            if dayNum >= 1 && dayNum <= daysInMonth {
                let dateStr = String(format: "%04d-%02d-%02d", year, month, dayNum)
                let isToday = (dateStr == effectiveTodayStr)
                let isFuture = (dateStr > effectiveTodayStr)
                let isArchive = (dateStr < effectiveTodayStr)
                let hasDiary = diaryDates.contains(dateStr)
                let isClickable = isDiaryMode ? (isToday || hasDiary) : true

                cells.append(MonthCellData(
                    id: cellIdx,
                    dayNumber: dayNum,
                    dateString: dateStr,
                    isToday: isToday,
                    isFuture: isFuture,
                    isArchive: isArchive,
                    isClickable: isClickable
                ))
            } else {
                cells.append(MonthCellData(
                    id: cellIdx,
                    dayNumber: 0,
                    dateString: "",
                    isToday: false,
                    isFuture: false,
                    isArchive: false,
                    isClickable: false
                ))
            }
        }
        return cells
    }

    private var selectedDateFormattedString: String {
        let cal = calendar
        guard let range = cal.range(of: .day, in: .month, for: displayedMonthDate) else { return "" }
        let clampedDay = min(max(selectedDayNum, 1), range.count)
        let comps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        let year = comps.year ?? 2026
        let month = comps.month ?? 11
        return String(format: "%04d-%02d-%02d", year, month, clampedDay)
    }

    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            // Drag Handle for bottom sheet styling
            Capsule()
                .fill(isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Header Row: Title & Close
                    headerRow

                    // Month Navigator Box with ◄ and ►
                    monthNavigatorBox

                    // Day of Week Header Row: Пн Вт Ср Чт Пт Сб Вс
                    dayOfWeekHeadersRow

                    // 6-Row Days Grid with Swipe Gestures
                    daysGrid
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width * 0.4
                                }
                                .onEnded { value in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                        if value.translation.width < -45 {
                                            goToNextMonth()
                                        } else if value.translation.width > 45 {
                                            goToPreviousMonth()
                                        }
                                    }
                                }
                        )

                    // Summary Card for Selected Date
                    summaryCard

                    // Action Buttons: [📍 Сегодня] [✓ Открыть этот день]
                    actionButtonsRow
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.45 : 0.15), radius: 20, x: 0, y: -4)
    }

    // MARK: - Header Row
    private var headerRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text(isDiaryMode ? "📖" : "🗓️")
                    .font(.system(size: 18))

                Text(isDiaryMode ? "Календарь записей" : "Календарь ежедневника")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
            }

            Spacer()

            Button {
                MiodiHapticFeedback.lightClick()
                onDismiss()
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(isDark ? Color(hex: 0x334155) : Color(hex: 0xF1F5F9))
                        .frame(width: 32, height: 32)

                    Text("✕")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B))
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Month Navigator Box
    private var monthNavigatorBox: some View {
        HStack {
            // Previous Month Button
            Button {
                goToPreviousMonth()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)

                    Text("◄")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Month & Year Title
            Text(currentMonthTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

            Spacer()

            // Next Month Button
            Button {
                if canGoNextMonth {
                    goToNextMonth()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)

                    Text("►")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            canGoNextMonth
                                ? (isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
                                : (isDark ? MiodiStaticColors.darkTextSecondary.opacity(0.25) : Color(hex: 0x64748B).opacity(0.25))
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(!canGoNextMonth)
        }
        .frame(height: 46)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF8FAFC))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.22), lineWidth: 1)
        )
    }

    // MARK: - Day of Week Header Row
    private var dayOfWeekHeadersRow: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeekHeaders, id: \.self) { dayName in
                Text(dayName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 2)
    }

    // MARK: - Days Grid (6 rows x 7 columns)
    private var daysGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(monthCells) { cell in
                if cell.dayNumber > 0 {
                    dayCellView(cell: cell)
                } else {
                    Color.clear
                        .frame(height: 38)
                }
            }
        }
    }

    // MARK: - Single Day Cell View
    private func dayCellView(cell: MonthCellData) -> some View {
        let isSelected = (cell.dayNumber == selectedDayNum)
        let dateStr = cell.dateString

        // Indicator flags
        let hasTaskActivity = !isDiaryMode && activeDates.contains(dateStr)
        let hasNutrition = !isDiaryMode && isNutritionEnabled && nutritionDates.contains(dateStr)
        let hasNoSpend = !isDiaryMode && isFinanceEnabled && noSpendDates.contains(dateStr)
        let hasFinance = !isDiaryMode && isFinanceEnabled && financeDates.contains(dateStr) && !hasNoSpend
        let hasJoy = !isDiaryMode && isJoyEnabled && joyDates.contains(dateStr)
        let hasMoment = !isDiaryMode && isMomentsEnabled && momentDates.contains(dateStr)
        let hasDiary = diaryDates.contains(dateStr)
        let isPeriodDay = !isDiaryMode && isCycleEnabled && cycleDates.contains(dateStr)

        // Habits on this day
        let hasHabitsDone: Bool = {
            if isDiaryMode { return false }
            let cal = calendar
            guard let cellDate = Date.from(yyyyMMdd: dateStr) else { return false }
            let dow = cal.component(.weekday, cellDate)
            let standardDow = (dow == 1) ? 7 : (dow - 1)
            let scheduledHabits = habits.filter { h in
                switch h.scheduleType {
                case "weekdays": return h.daysOfWeekSet.contains(standardDow)
                default: return true
                }
            }
            return !scheduledHabits.isEmpty
        }()

        // Styling
        let borderColor: Color = {
            if isSelected { return theme.currentAccent.primary }
            if isDiaryMode {
                if cell.isFuture { return theme.currentAccent.primary.opacity(0.15) }
                if hasDiary { return theme.currentAccent.primary.opacity(0.55) }
                if cell.isToday { return theme.currentAccent.primary.opacity(0.65) }
                return theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.22)
            }
            if isPeriodDay {
                return isDark ? Color(hex: 0xFB7185).opacity(0.40) : Color(hex: 0xFB7185).opacity(0.45)
            }
            return theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.22)
        }()

        let bgColor: Color = {
            if isSelected { return theme.currentAccent.primary }
            if isDiaryMode {
                if cell.isFuture { return isDark ? Color(hex: 0x1E2433).opacity(0.35) : Color(hex: 0xF1F5F9).opacity(0.45) }
                if hasDiary { return isDark ? Color(hex: 0x2C2238) : Color(hex: 0xFDF2F8) }
                if cell.isToday { return isDark ? Color(hex: 0x1E2433) : Color.white }
                return isDark ? Color(hex: 0x1E2433).opacity(0.25) : Color(hex: 0xF1F5F9).opacity(0.35)
            }
            if isPeriodDay {
                return isDark ? Color(hex: 0x881337).opacity(0.35) : Color(hex: 0xFFFFE4E6).opacity(0.65)
            }
            return isDark ? Color(hex: 0x1E2433) : Color.white
        }()

        let textColor: Color = {
            if isSelected { return .white }
            if isDiaryMode {
                if cell.isFuture { return (isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B)).opacity(0.20) }
                if hasDiary { return isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A) }
                if cell.isToday { return theme.currentAccent.primary }
                return (isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B)).opacity(0.30)
            }
            if isPeriodDay {
                return isDark ? Color(hex: 0xFECDD3) : Color(hex: 0xBE123C)
            }
            return isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A)
        }()

        return Button {
            guard cell.isClickable else { return }
            MiodiHapticFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedDayNum = cell.dayNumber
            }
        } label: {
            ZStack {
                // Background & Border
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )

                // 1. Day Number in the Center
                Text("\(cell.dayNumber)")
                    .font(.system(size: 12.5, weight: isSelected || (isDiaryMode && (hasDiary || cell.isToday)) ? .bold : .medium))
                    .foregroundStyle(textColor)

                if isDiaryMode {
                    // In Diary mode: show mini book icon at bottom center if entry exists
                    if hasDiary {
                        CalendarDiaryBookView(isSelected: isSelected, isDark: isDark)
                            .frame(width: 9, height: 7.5)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 2.5)
                    }
                } else {
                    // Multi-dot indicators in Notebook mode:

                    // 2. Task Activity Dot - Bottom Center
                    if hasTaskActivity {
                        Circle()
                            .fill(isSelected ? Color.white : Color(hex: 0x0284C7))
                            .frame(width: 3.5, height: 3.5)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 2)
                    }

                    // 3. Nutrition Icon (🥑) - Bottom Right
                    if hasNutrition {
                        Text("🥑")
                            .font(.system(size: 7.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(.trailing, 1.5)
                            .padding(.bottom, 1)
                    }

                    // 4. Finance / No-Spend Icon (🏆 or 💰) - Bottom Left
                    if hasNoSpend {
                        Text("🏆")
                            .font(.system(size: 7.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .padding(.leading, 1.5)
                            .padding(.bottom, 1)
                    } else if hasFinance {
                        Text("💰")
                            .font(.system(size: 7.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .padding(.leading, 1.5)
                            .padding(.bottom, 1)
                    }

                    // 5. Joy Sun (☀️) - Top Right
                    if hasJoy {
                        Text("☀️")
                            .font(.system(size: 7.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.top, 1)
                            .padding(.trailing, 1.5)
                    }

                    // 6. Habit Badge (Green Circle with checkmark) - Top Left
                    if hasHabitsDone {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0x10B981))
                                .frame(width: 8.5, height: 8.5)

                            Image(systemName: "checkmark")
                                .font(.system(size: 5, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.top, 2)
                        .padding(.leading, 2)
                    }

                    // 7. Moments Camera Icon - Top Center
                    if hasMoment {
                        CalendarCameraView(isSelected: isSelected, isDark: isDark)
                            .frame(width: 10, height: 8)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, 1.5)
                    }

                    // 8. Diary Tiny Book Icon - Center Left
                    if hasDiary {
                        CalendarDiaryBookView(isSelected: isSelected, isDark: isDark)
                            .frame(width: 7.5, height: 7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 1.5)
                    }
                }
            }
            .frame(height: 38)
        }
        .buttonStyle(.plain)
        .disabled(!cell.isClickable)
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        let selDateStr = selectedDateFormattedString
        let isSelectedToday = (selDateStr == effectiveTodayStr)
        let isArchiveDay = (selDateStr < effectiveTodayStr)
        let isFutureDay = (selDateStr > effectiveTodayStr)

        // Day Tasks Count
        let dayTasks = tasks.filter { task in
            if isArchiveDay {
                return task.isCompleted && task.date == selDateStr
            } else if isSelectedToday {
                return task.date == effectiveTodayStr || task.date.isEmpty
            } else {
                return task.date == selDateStr
            }
        }
        let completedTasksCount = dayTasks.filter { $0.isCompleted }.count

        // Diary entries
        let dayDiaryEntries = diaryEntries.filter { $0.date == selDateStr && !$0.content.isEmpty }
            .sorted { $0.timestamp < $1.timestamp }

        // Module badges presence
        let dayHasNutrition = isNutritionEnabled && nutritionDates.contains(selDateStr)
        let dayHasNoSpend = isFinanceEnabled && noSpendDates.contains(selDateStr)
        let dayHasFinance = isFinanceEnabled && financeDates.contains(selDateStr) && !dayHasNoSpend
        let dayHasJoy = isJoyEnabled && joyDates.contains(selDateStr)
        let dayHasMoment = isMomentsEnabled && momentDates.contains(selDateStr)
        let dayHasDiary = isDiaryEnabled && diaryDates.contains(selDateStr)
        let dayIsCycle = isCycleEnabled && cycleDates.contains(selDateStr)

        let summaryText: String = {
            if isDiaryMode {
                if let first = dayDiaryEntries.first {
                    let countStr = "Записей: \(dayDiaryEntries.count)"
                    let snippet = first.content.components(separatedBy: .newlines).first ?? ""
                    let trimmedSnippet = snippet.count > 36 ? snippet.prefix(36) + "…" : snippet
                    if !first.time.isEmpty && !trimmedSnippet.isEmpty {
                        return "\(countStr) • \(first.time): \"\(trimmedSnippet)\""
                    } else if !trimmedSnippet.isEmpty {
                        return "\(countStr) • \"\(trimmedSnippet)\""
                    }
                    return countStr
                } else {
                    return isSelectedToday ? "Нет записей за сегодня" : "Нет записей за этот день"
                }
            } else {
                if isArchiveDay {
                    return "Выполнено задач: \(dayTasks.count) • Привычки: \(habits.count)"
                } else if isFutureDay {
                    return "Запланировано задач: \(dayTasks.count) • Привычки: \(habits.count)"
                } else {
                    return "Запланировано: \(dayTasks.count) • Выполнено: \(completedTasksCount) • Привычки: \(habits.count)"
                }
            }
        }()

        return VStack(alignment: .leading, spacing: 8) {
            // Title Row: "25 Ноябрь 2026" + "Сегодня" badge
            HStack {
                Text("\(selectedDayNum) \(currentMonthTitle)")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

                Spacer()

                if isSelectedToday {
                    Text("Сегодня")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.currentAccent.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.currentAccent.primary.opacity(0.15))
                        )
                }
            }

            // Summary Text
            Text(summaryText)
                .font(.system(size: 12))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B))

            // Module Badges Flow Row
            if dayHasNoSpend || dayHasFinance || dayHasNutrition || dayHasJoy || dayHasMoment || dayHasDiary || dayIsCycle {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if dayHasNoSpend {
                            moduleTagView(text: "🏆 День без трат")
                        } else if dayHasFinance {
                            moduleTagView(text: "💰 Финансы")
                        }
                        if dayHasNutrition {
                            moduleTagView(text: "🥑 Питание")
                        }
                        if dayHasJoy {
                            moduleTagView(text: "☀️ Радость")
                        }
                        if dayHasMoment {
                            moduleTagView(text: "📷 Моменты")
                        }
                        if dayHasDiary {
                            moduleTagView(text: "📖 Дневник") {
                                onOpenDiaryForDate?(selDateStr)
                            }
                        }
                        if dayIsCycle {
                            moduleTagView(text: "🍒 Цикл", isCycle: true) {
                                onOpenCycle?()
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF8FAFC))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.22), lineWidth: 1)
        )
    }

    private func moduleTagView(text: String, isCycle: Bool = false, onTap: (() -> Void)? = nil) -> some View {
        Button {
            onTap?()
        } label: {
            Text(text)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(
                    isCycle
                        ? (isDark ? Color(hex: 0xFECDD3) : Color(hex: 0xBE123C))
                        : (isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569))
                )
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isCycle
                                ? (isDark ? Color(hex: 0x4C0519).opacity(0.55) : Color(hex: 0xFFFFE4E6))
                                : (isDark ? Color(hex: 0x273244) : Color(hex: 0xE2E8F0).opacity(0.70))
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    // MARK: - Action Buttons Row
    private var actionButtonsRow: some View {
        let isTodayCurrent = (selectedDateFormattedString == effectiveTodayStr)
        let isActionEnabled = isDiaryMode ? (isTodayCurrent || diaryDates.contains(selectedDateFormattedString)) : true
        let actionTitle: String = {
            if isDiaryMode {
                if diaryDates.contains(selectedDateFormattedString) {
                    return "📖 Открыть страницу"
                } else if isTodayCurrent {
                    return "✍️ Написать за этот день"
                }
                return "📖 Открыть страницу"
            }
            return "✓ Открыть этот день"
        }()

        return HStack(spacing: 12) {
            // [📍 Сегодня]
            Button {
                MiodiHapticFeedback.lightClick()
                jumpToToday()
            } label: {
                Text("📍 Сегодня")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.22), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            // [✓ Открыть этот день]
            Button {
                MiodiHapticFeedback.success()
                let targetDate = selectedDateFormattedString
                if isDiaryMode {
                    onOpenDiaryForDate?(targetDate) ?? onSelectDate(targetDate)
                } else {
                    onSelectDate(targetDate)
                }
                onDismiss()
                dismiss()
            } label: {
                Text(actionTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isActionEnabled ? theme.currentAccent.primary : (isDark ? Color(hex: 0x334155).opacity(0.4) : Color(hex: 0xE2E8F0)))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isActionEnabled)
        }
    }

    // MARK: - Navigation Helpers
    private func goToPreviousMonth() {
        MiodiHapticFeedback.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonthDate) {
                displayedMonthDate = prevMonth
            }
        }
    }

    private func goToNextMonth() {
        guard canGoNextMonth else { return }
        MiodiHapticFeedback.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonthDate) {
                displayedMonthDate = nextMonth
            }
        }
    }

    private func jumpToToday() {
        let now = Date()
        let cal = calendar
        let day = cal.component(.day, from: now)
        let comps = cal.dateComponents([.year, .month], from: now)
        if let firstOfMonth = cal.date(from: comps) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                displayedMonthDate = firstOfMonth
                selectedDayNum = day
            }
        }
    }
}

// MARK: - Vector Shapes mirroring Android Custom Draw

/// Mini Diary Book vector matching Android `CalendarDiaryBookIcon`
private struct CalendarDiaryBookView: View {
    let isSelected: Bool
    let isDark: Bool

    private var bookColor: Color {
        if isSelected { return .white }
        return isDark ? Color(hex: 0xFBBF24) : Color(hex: 0xB45309)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let midX = w * 0.5

            Path { path in
                // Left page
                path.move(to: CGPoint(x: midX, y: h * 0.18))
                path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.16), control: CGPoint(x: w * 0.25, y: h * 0.05))
                path.addLine(to: CGPoint(x: 0, y: h * 0.86))
                path.addQuadCurve(to: CGPoint(x: midX, y: h * 0.90), control: CGPoint(x: w * 0.25, y: h * 0.76))
                // Right page
                path.addQuadCurve(to: CGPoint(x: w, y: h * 0.86), control: CGPoint(x: w * 0.75, y: h * 0.76))
                path.addLine(to: CGPoint(x: w, y: h * 0.16))
                path.addQuadCurve(to: CGPoint(x: midX, y: h * 0.18), control: CGPoint(x: w * 0.75, y: h * 0.05))
                path.closeSubpath()
            }
            .fill(bookColor.opacity(0.25))

            Path { path in
                // Spine line
                path.move(to: CGPoint(x: midX, y: h * 0.18))
                path.addLine(to: CGPoint(x: midX, y: h * 0.90))
            }
            .stroke(bookColor, lineWidth: 1.0)
        }
    }
}

/// Mini Camera vector matching Android `CalendarMomentCameraIcon`
private struct CalendarCameraView: View {
    let isSelected: Bool
    let isDark: Bool

    private var cameraColor: Color {
        if isSelected { return .white }
        return isDark ? Color(hex: 0xA78BFA) : Color(hex: 0x7C3AED)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(cameraColor.opacity(0.20))

            RoundedRectangle(cornerRadius: 2)
                .stroke(cameraColor, lineWidth: 0.9)

            Circle()
                .stroke(cameraColor, lineWidth: 0.9)
                .frame(width: 4, height: 4)
        }
    }
}
