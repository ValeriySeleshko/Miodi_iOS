//
//  DayTimelineView.swift
//  Plan4U_iOS
//
//  Hourly Day Timeline & Time-Blocking Grid (06:00 - 24:00).
//  Pixel-perfect Miodi Notebook layout featuring:
//  - 18 hourly slots from 06:00 to 24:00
//  - Tasks mapped directly to their reminder time slots
//  - Real-time current time indicator line (when viewing today)
//  - Interactive task completion checkbox with strikethrough & haptic feedback
//  - One-tap quick task scheduling for any empty time slot
//  - Day navigation (◄ Prev, Today, Next ►) with smooth swipe gestures
//  - Month calendar modal trigger button
//

import SwiftUI
import SwiftData

public struct DayTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    // SwiftData Tasks
    @Query(sort: \TaskItem.orderIndex) private var allTasks: [TaskItem]

    // Selected Date
    @State private var currentDate: Date = Date()
    @State private var isShowingMonthCalendar: Bool = false
    @State private var quickAddHour: Int? = nil
    @State private var quickAddText: String = ""
    @State private var editingTask: TaskItem? = nil
    @State private var swipeOffset: CGFloat = 0

    // Callback when selecting a date or opening month calendar
    public var onOpenMonthCalendar: (() -> Void)? = nil

    public init(initialDate: Date = Date(), onOpenMonthCalendar: (() -> Void)? = nil) {
        _currentDate = State(initialValue: initialDate)
        self.onOpenMonthCalendar = onOpenMonthCalendar
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var currentDateStr: String {
        currentDate.yyyyMMddString
    }

    private var isViewingToday: Bool {
        Calendar.current.isDateInToday(currentDate)
    }

    private var dayTasks: [TaskItem] {
        allTasks.filter { task in
            task.date == currentDateStr || (isViewingToday && task.date.isEmpty)
        }
    }

    // Hours from 06:00 to 24:00 (18 hours)
    private let timelineHours: [Int] = Array(6...24)

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar: Day navigator & Calendar trigger
            headerBar

            // Hourly Timeline Scroll Area
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(timelineHours, id: \.self) { hour in
                            hourTimelineRow(hour: hour)
                                .id(hour)
                        }

                        // Bottom padding for navigation bars
                        Color.clear.frame(height: 120)
                    }
                    .padding(.top, 8)
                }
                .onAppear {
                    // Scroll to current hour if today, else scroll to 08:00 or 09:00
                    let targetHour = isViewingToday ? Calendar.current.component(.hour, from: Date()) : 8
                    let clamped = min(max(targetHour, 6), 24)
                    withAnimation {
                        proxy.scrollTo(clamped, anchor: .top)
                    }
                }
            }
        }
        .background(isDark ? MiodiStaticColors.darkPaperBg : MiodiStaticColors.paperLightBg)
        .offset(x: swipeOffset)
        .gesture(
            DragGesture()
                .onChanged { val in
                    swipeOffset = val.translation.width * 0.35
                }
                .onEnded { val in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        swipeOffset = 0
                        if val.translation.width < -40 {
                            goToNextDay()
                        } else if val.translation.width > 40 {
                            goToPreviousDay()
                        }
                    }
                }
        )
        .sheet(isPresented: $isShowingMonthCalendar) {
            FullMonthCalendarView(
                selectedDate: currentDateStr,
                todayDate: Date().yyyyMMddString,
                activeDates: Set(allTasks.map { $0.date }.filter { !$0.isEmpty }),
                tasks: allTasks,
                onDismiss: { isShowingMonthCalendar = false },
                onSelectDate: { newDateStr in
                    if let d = Date.from(yyyyMMdd: newDateStr) {
                        currentDate = d
                    }
                    isShowingMonthCalendar = false
                }
            )
        }
        .sheet(item: $editingTask) { taskToEdit in
            TaskDetailModalView(
                task: taskToEdit,
                onDismiss: { editingTask = nil },
                onSave: { text, sectionId, date, priority, priorityColor, reminderTime, reminderOffset, notes, photoUri in
                    taskToEdit.text = text
                    taskToEdit.sectionId = sectionId
                    taskToEdit.date = date
                    taskToEdit.priority = priority
                    taskToEdit.priorityColor = priorityColor
                    taskToEdit.reminderTime = reminderTime
                    taskToEdit.reminderOffset = reminderOffset
                    taskToEdit.notes = notes
                    taskToEdit.photoUri = photoUri
                    try? modelContext.save()
                    NotificationService.shared.cancelTaskReminder(task: taskToEdit)
                    if !taskToEdit.isCompleted && taskToEdit.reminderTime != nil {
                        NotificationService.shared.scheduleTaskReminder(task: taskToEdit)
                    }
                    editingTask = nil
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { quickAddHour != nil },
            set: { if !$0 { quickAddHour = nil } }
        )) {
            if let h = quickAddHour {
                quickAddTaskSheet(hour: h)
            }
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // Prev Day Button
                Button {
                    goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.currentAccent.primary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                        )
                }
                .buttonStyle(.plain)

                // Date Title & Subtitle
                VStack(spacing: 2) {
                    Text(formattedDateTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

                    Text(formattedDaySubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B))
                }
                .frame(maxWidth: .infinity)

                // Next Day Button
                Button {
                    goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.currentAccent.primary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                        )
                }
                .buttonStyle(.plain)

                // Month Calendar Modal Trigger
                Button {
                    MiodiHapticFeedback.lightClick()
                    if let customOpen = onOpenMonthCalendar {
                        customOpen()
                    } else {
                        isShowingMonthCalendar = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("🗓️")
                            .font(.system(size: 14))
                        Text("Месяц")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.currentAccent.primary)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.currentAccent.primary.opacity(isDark ? 0.22 : 0.12))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Day Progress Stats Bar
            HStack {
                let scheduled = dayTasks.count
                let completed = dayTasks.filter { $0.isCompleted }.count

                HStack(spacing: 6) {
                    Text("⏰ Задач на день: \(scheduled)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x475569))

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("Выполнено: \(completed)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x10B981))
                }

                Spacer()

                if !isViewingToday {
                    Button {
                        jumpToToday()
                    } label: {
                        Text("📍 Сегодня")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.currentAccent.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(theme.currentAccent.primary.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            Divider()
                .foregroundStyle(isDark ? MiodiStaticColors.darkRuledLine : MiodiStaticColors.ruledLineColor)
        }
        .background(isDark ? MiodiStaticColors.darkTopBarBg : Color.white)
    }

    // MARK: - Single Hour Timeline Row (06:00 - 24:00)
    private func hourTimelineRow(hour: Int) -> some View {
        let hourTasks = tasksForHour(hour)
        let hourString = String(format: "%02d:00", hour)
        let isNowHour = isViewingToday && (Calendar.current.component(.hour, from: Date()) == hour)
        let currentMinute = Calendar.current.component(.minute, from: Date())

        return HStack(alignment: .top, spacing: 0) {
            // Left Column: Hour Label
            VStack(alignment: .trailing, spacing: 2) {
                Text(hourString)
                    .font(.system(size: 12, weight: isNowHour ? .bold : .medium, design: .monospaced))
                    .foregroundStyle(
                        isNowHour
                            ? theme.currentAccent.primary
                            : (isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B))
                    )
            }
            .frame(width: 52, alignment: .trailing)
            .padding(.trailing, 8)
            .padding(.top, 2)

            // Timeline Spine (Node dot & vertical line)
            ZStack(alignment: .top) {
                // Vertical spine line
                Rectangle()
                    .fill(isDark ? MiodiStaticColors.darkRuledLine : MiodiStaticColors.ruledLineColor)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)

                // Hour node dot
                Circle()
                    .fill(
                        isNowHour
                            ? theme.currentAccent.primary
                            : (isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1))
                    )
                    .frame(width: isNowHour ? 8 : 6, height: isNowHour ? 8 : 6)
                    .padding(.top, 5)

                // Real-time Current Minute Indicator Line
                if isNowHour {
                    GeometryReader { geo in
                        let fraction = CGFloat(currentMinute) / 60.0
                        let yOffset = fraction * geo.size.height

                        HStack(spacing: 2) {
                            Circle()
                                .fill(theme.currentAccent.primary)
                                .frame(width: 7, height: 7)

                            Rectangle()
                                .fill(theme.currentAccent.primary)
                                .frame(height: 1.8)
                        }
                        .offset(y: yOffset)
                    }
                }
            }
            .frame(width: 14)

            // Right Column: Task Cards or Tap-to-Add Slot
            VStack(alignment: .leading, spacing: 6) {
                if hourTasks.isEmpty {
                    // Empty slot: tap to quick-add
                    Button {
                        MiodiHapticFeedback.lightClick()
                        quickAddHour = hour
                    } label: {
                        HStack(spacing: 6) {
                            Text("+")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(theme.currentAccent.primary.opacity(0.6))

                            Text("Запланировать на \(hourString)")
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(isDark ? Color(hex: 0x475569) : Color(hex: 0x94A3B8))

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isDark ? Color(hex: 0x141824).opacity(0.4) : Color(hex: 0xF8FAFC))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(
                                            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                                        )
                                        .foregroundStyle(isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE2E8F0))
                                )
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // One or more scheduled tasks in this hour
                    ForEach(hourTasks) { task in
                        taskTimelineCard(task: task)
                    }

                    // Plus button to add another task in this hour
                    Button {
                        MiodiHapticFeedback.lightClick()
                        quickAddHour = hour
                    } label: {
                        HStack(spacing: 4) {
                            Text("+")
                                .font(.system(size: 11, weight: .bold))
                            Text("ещё задачу")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(theme.currentAccent.primary)
                        .padding(.leading, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.bottom, 10)
        }
        .frame(minHeight: 54)
    }

    // MARK: - Task Timeline Card
    private func taskTimelineCard(task: TaskItem) -> some View {
        let isImportant = (task.priority == 1)
        let priorityColor = TaskPriorityColors.color(for: task.priorityColor)

        return HStack(spacing: 10) {
            // Task Priority Left Accent Indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(isImportant ? priorityColor : theme.currentAccent.primary)
                .frame(width: 3.5)

            // Checkbox
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    task.isCompleted.toggle()
                    if task.isCompleted {
                        task.completedAt = Int64(Date().timeIntervalSince1970 * 1000)
                        NotificationService.shared.cancelTaskReminder(task: task)
                        MiodiHapticFeedback.taskComplete()
                    } else {
                        task.completedAt = 0
                        if task.reminderTime != nil {
                            NotificationService.shared.scheduleTaskReminder(task: task)
                        }
                        MiodiHapticFeedback.lightClick()
                    }
                    try? modelContext.save()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            task.isCompleted ? Color(hex: 0x10B981) : (isDark ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1)),
                            lineWidth: 1.8
                        )
                        .frame(width: 20, height: 20)

                    if task.isCompleted {
                        Circle()
                            .fill(Color(hex: 0x10B981))
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Task Text & Time badge
            VStack(alignment: .leading, spacing: 3) {
                Text(task.text)
                    .font(.system(size: 14, weight: isImportant ? .semibold : .regular))
                    .foregroundStyle(
                        task.isCompleted
                            ? (isDark ? Color(hex: 0x64748B) : Color(hex: 0x94A3B8))
                            : (isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
                    )
                    .strikethrough(task.isCompleted, color: isDark ? Color(hex: 0x64748B) : Color(hex: 0x94A3B8))

                HStack(spacing: 6) {
                    if let rem = task.reminderTime, !rem.isEmpty {
                        HStack(spacing: 3) {
                            Text("⏰")
                                .font(.system(size: 10))
                            Text(rem)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(theme.currentAccent.primary)
                    }

                    if isImportant {
                        Text("Важно")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(priorityColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(priorityColor.opacity(0.15))
                            )
                    }
                }
            }

            Spacer()

            // Chevron to open full task edit modal
            Image(systemName: "pencil")
                .font(.system(size: 12))
                .foregroundStyle(isDark ? Color(hex: 0x64748B) : Color(hex: 0x94A3B8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.06), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isImportant
                        ? priorityColor.opacity(0.4)
                        : (isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE2E8F0)),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            MiodiHapticFeedback.lightClick()
            editingTask = task
        }
    }

    // MARK: - Quick Add Task Sheet
    private func quickAddTaskSheet(hour: Int) -> some View {
        let timeStr = String(format: "%02d:00", hour)

        return VStack(spacing: 16) {
            HStack {
                Text("Новая задача на \(timeStr)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

                Spacer()

                Button("Отмена") {
                    quickAddHour = nil
                    quickAddText = ""
                }
                .foregroundStyle(.secondary)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)

            TextField("Что нужно сделать?", text: $quickAddText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)

            HStack {
                Spacer()

                Button {
                    let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }

                    let newTask = TaskItem(
                        text: trimmed,
                        date: currentDateStr,
                        reminderTime: timeStr,
                        orderIndex: allTasks.count
                    )
                    modelContext.insert(newTask)
                    try? modelContext.save()
                    MiodiHapticFeedback.success()

                    quickAddHour = nil
                    quickAddText = ""
                } label: {
                    Text("Запланировать")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.currentAccent.primary)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.fraction(0.3)])
        .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
    }

    // MARK: - Helpers
    private func tasksForHour(_ hour: Int) -> [TaskItem] {
        let prefix = String(format: "%02d:", hour)
        return dayTasks.filter { task in
            if let rem = task.reminderTime, !rem.isEmpty {
                return rem.hasPrefix(prefix)
            }
            return false
        }
    }

    private var formattedDateTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: currentDate)
    }

    private var formattedDaySubtitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EEEE"
        let dayOfWeek = f.string(from: currentDate).capitalized
        if isViewingToday {
            return "Сегодня, \(dayOfWeek)"
        }
        return dayOfWeek
    }

    private func goToPreviousDay() {
        MiodiHapticFeedback.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentDate = currentDate.adding(days: -1)
        }
    }

    private func goToNextDay() {
        MiodiHapticFeedback.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentDate = currentDate.adding(days: 1)
        }
    }

    private func jumpToToday() {
        MiodiHapticFeedback.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentDate = Date()
        }
    }
}
