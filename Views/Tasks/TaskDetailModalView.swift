//
//  TaskDetailModalView.swift
//  Plan4U_iOS
//
//  Pixel-perfect and feature-complete port of Android TaskEditModal.kt (846 lines).
//  Features:
//  - Pure SwiftUI Modal Sheet presentation
//  - Task text input with sentence auto-capitalization & 150-char counter
//  - Section / Category dropdown & selector
//  - Date picker with quick chips (Сегодня, Завтра, Послезавтра, Через неделю)
//  - Priority switcher (Обычный / Важный)
//  - 5-color dark palette picker for important tasks:
//      * Чёрный (#0F172A)
//      * Бордовый (#881337)
//      * Фиолетовый (#7E22CE)
//      * Тёмно-синий (#1E3A8A)
//      * Тёмно-зелёный (#065F46)
//  - Reminder time picker with quick presets (+5m, +15m, +1h, 09:00, 14:00, 19:00, 21:00)
//  - Additional notes editor
//  - Photos attachment gallery using native PhotosUI PhotosPicker
//  - Auto-save debouncing & save/cancel actions with Taptic Engine haptics
//

import SwiftUI
import PhotosUI

public struct TaskDetailModalView: View {
    // Optional TaskItem binding if editing existing task
    public var task: TaskItem?
    public var sections: [SectionItem]

    // Initial values
    public var initialText: String
    public var initialSectionId: String
    public var initialDate: String
    public var initialPriority: Int
    public var initialPriorityColor: String
    public var initialTime: String?
    public var initialReminderOffset: Int = 0
    public var initialNotes: String
    public var initialPhotoUri: String?

    // Callbacks
    public var onDismiss: () -> Void
    public var onSave: (
        _ text: String,
        _ sectionId: String,
        _ date: String,
        _ priority: Int,
        _ priorityColor: String,
        _ reminderTime: String?,
        _ reminderOffset: Int,
        _ notes: String,
        _ photoUri: String?
    ) -> Void
    public var onAutoSave: ((
        _ text: String,
        _ sectionId: String,
        _ date: String,
        _ priority: Int,
        _ priorityColor: String,
        _ reminderTime: String?,
        _ reminderOffset: Int,
        _ notes: String,
        _ photoUri: String?
    ) -> Void)?

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // Form Editable States
    @State private var taskText: String
    @State private var selectedSectionId: String
    @State private var selectedDate: Date
    @State private var isShowingCalendarPicker: Bool = false
    @State private var selectedPriority: Int
    @State private var selectedPriorityColor: String
    @State private var reminderTime: String?
    @State private var reminderOffset: Int
    @State private var isShowingCustomOffsetSheet: Bool = false
    @State private var customOffsetValueText: String = "30"
    @State private var customOffsetUnitIndex: Int = 0
    @State private var isShowingTimePicker: Bool = false
    @State private var pickerTime: Date = Date()
    @State private var notesText: String
    @State private var attachedPhotos: [String]

    public init(
        task: TaskItem? = nil,
        sections: [SectionItem] = [],
        initialText: String = "",
        initialSectionId: String = "todo",
        initialDate: String = "",
        initialPriority: Int = 0,
        initialPriorityColor: String = "black",
        initialTime: String? = nil,
        initialReminderOffset: Int = 0,
        initialNotes: String = "",
        initialPhotoUri: String? = nil,
        onDismiss: @escaping () -> Void = {},
        onAutoSave: ((String, String, String, Int, String, String?, Int, String, String?) -> Void)? = nil,
        onSave: @escaping (String, String, String, Int, String, String?, Int, String, String?) -> Void
    ) {
        self.task = task
        self.sections = sections.isEmpty ? TaskDetailModalView.defaultSections : sections
        let effectiveText = task?.text ?? initialText
        let effectiveSecId = task?.sectionId.isEmpty == false ? task!.sectionId : (initialSectionId.isEmpty ? "todo" : initialSectionId)
        let effectiveDateStr = task?.date.isEmpty == false ? task!.date : (initialDate.isEmpty ? Date().yyyyMMddString : initialDate)
        let effectivePrio = task?.priority ?? initialPriority
        let effectiveColor = task?.priorityColor.isEmpty == false ? task!.priorityColor : initialPriorityColor
        let effectiveTime = task?.reminderTime ?? initialTime
        let effectiveOffset = task?.reminderOffset ?? initialReminderOffset
        let effectiveNotes = task?.notes ?? initialNotes
        let effectivePhotos = task?.photoUri ?? initialPhotoUri

        self.initialText = effectiveText
        self.initialSectionId = effectiveSecId
        self.initialDate = effectiveDateStr
        self.initialPriority = effectivePrio
        self.initialPriorityColor = effectiveColor
        self.initialTime = effectiveTime
        self.initialReminderOffset = effectiveOffset
        self.initialNotes = effectiveNotes
        self.initialPhotoUri = effectivePhotos

        self.onDismiss = onDismiss
        self.onAutoSave = onAutoSave
        self.onSave = onSave

        _taskText = State(initialValue: effectiveText)
        _selectedSectionId = State(initialValue: effectiveSecId)
        _selectedDate = State(initialValue: Date.from(yyyyMMdd: effectiveDateStr) ?? Date())
        _selectedPriority = State(initialValue: effectivePrio)
        _selectedPriorityColor = State(initialValue: effectiveColor)
        _reminderTime = State(initialValue: effectiveTime)
        _reminderOffset = State(initialValue: effectiveOffset)
        _notesText = State(initialValue: effectiveNotes)
        _attachedPhotos = State(initialValue: TaskPhotoStorage.parsePhotoUris(effectivePhotos))
    }

    public static let defaultSections: [SectionItem] = [
        SectionItem(id: "todo", title: "Дела", icon: "📁", orderIndex: 0),
        SectionItem(id: "work", title: "Работа", icon: "💼", orderIndex: 1),
        SectionItem(id: "home", title: "Дом", icon: "🏠", orderIndex: 2),
        SectionItem(id: "ideas", title: "Идеи", icon: "💡", orderIndex: 3)
    ]

    private var isDarkTheme: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var currentSection: SectionItem {
        sections.first { $0.id == selectedSectionId } ?? sections.first ?? TaskDetailModalView.defaultSections[0]
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Header Bar with Drag Handle & Close Button
                    headerBar

                    // Card 1: Task Text Input
                    taskTextCard

                    // Card 2: Section Dropdown / Selector
                    sectionSelectorCard

                    // Card 3: Date Selector with Quick Chips
                    dateSelectorCard

                    // Card 4: Priority Selector (Обычный / Важный + 5 Colors)
                    prioritySelectorCard

                    // Card 5: Reminder Time (Shown when Important)
                    if selectedPriority == 1 {
                        reminderTimeCard
                    }

                    // Card 6: Additional Notes & Photo Attachments
                    notesAndPhotosCard

                    // Bottom Action Buttons: Отмена / Сохранить
                    bottomActionButtons
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(isDarkTheme ? Color(hex: 0x14171F) : Color(hex: 0xFAFAFA))
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Text(initialText.isEmpty ? "Новая задача" : "Редактирование задачи")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2229))

            Spacer()

            Button {
                MiodiHapticFeedback.lightClick()
                onDismiss()
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(isDarkTheme ? Color(hex: 0x262C3D) : Color(hex: 0xF3F4F6))
                        .frame(width: 30, height: 30)

                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x6B7280))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 14)
    }

    // MARK: - Card 1: Task Text Input
    private var taskTextCard: some View {
        fieldCard(title: "Текст задачи") {
            VStack(alignment: .trailing, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    if taskText.isEmpty {
                        Text("Что нужно сделать?")
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0x64748B) : Color(hex: 0x9CA3AF))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }

                    TextEditor(text: Binding(
                        get: { taskText },
                        set: { newText in
                            if newText.count <= 150 {
                                taskText = capitalizeFirst(newText)
                                triggerAutoSave()
                            }
                        }
                    ))
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2229))
                    .frame(minHeight: 70, maxHeight: 110)
                    .padding(8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    taskText.count >= 140 ? theme.currentAccent.primary : (isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xE5E7EB)),
                                    lineWidth: 1
                                )
                        )
                )

                // Character counter
                Text("\(taskText.count)/150")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(taskText.count >= 140 ? theme.currentAccent.primary : (isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x6B7280)))
            }
        }
    }

    // MARK: - Card 2: Section Dropdown / Menu
    private var sectionSelectorCard: some View {
        fieldCard(title: "Раздел / Папка") {
            Menu {
                ForEach(sections) { sec in
                    Button {
                        MiodiHapticFeedback.selection()
                        selectedSectionId = sec.id
                        triggerAutoSave()
                    } label: {
                        HStack {
                            Text("\(sec.icon) \(sec.title)")
                            if sec.id == selectedSectionId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("\(currentSection.icon) \(currentSection.title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2229))

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0x9CA3AF))
                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xE5E7EB), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Card 3: Date Selector with Quick Chips
    private var dateSelectorCard: some View {
        fieldCard(title: "Дата выполнения") {
            VStack(alignment: .leading, spacing: 8) {
                // Active Date display row
                Button {
                    MiodiHapticFeedback.lightClick()
                    isShowingCalendarPicker.toggle()
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundStyle(theme.currentAccent.primary)

                        Text(selectedDate.userFriendlyDateString())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2229))

                        Spacer()

                        Image(systemName: isShowingCalendarPicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x9CA3AF))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xE5E7EB), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Inline Graphical Calendar when expanded
                if isShowingCalendarPicker {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { selectedDate },
                            set: { newDate in
                                selectedDate = newDate
                                triggerAutoSave()
                            }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                    )
                }

                // Quick Date Preset Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        quickDateChip(title: "Сегодня", date: Date())
                        quickDateChip(title: "Завтра", date: Date().adding(days: 1))
                        quickDateChip(title: "Послезавтра", date: Date().adding(days: 2))
                        quickDateChip(title: "Через неделю", date: Date().adding(days: 7))
                    }
                }
            }
        }
    }

    private func quickDateChip(title: String, date: Date) -> some View {
        let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
        return Button {
            MiodiHapticFeedback.selection()
            selectedDate = date
            triggerAutoSave()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : (isDarkTheme ? Color(hex: 0xCBD5E1) : Color(hex: 0x4B5563)))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? theme.currentAccent.primary : (isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF3F4F6)))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card 4: Priority Selector (Обычный / Важный + 5 Dark Colors)
    private var prioritySelectorCard: some View {
        fieldCard(title: "Приоритет задачи") {
            VStack(spacing: 10) {
                // Priority Mode Chips
                HStack(spacing: 10) {
                    // Normal
                    priorityChip(
                        label: "Обычный",
                        isSelected: selectedPriority == 0
                    ) {
                        selectedPriority = 0
                        reminderTime = nil
                        triggerAutoSave()
                    }

                    // Important
                    priorityChip(
                        label: "Важный",
                        isSelected: selectedPriority == 1
                    ) {
                        selectedPriority = 1
                        triggerAutoSave()
                    }
                }

                // 5 Dark Colors Palette for Important Tasks
                if selectedPriority == 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Цвет важной задачи")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569))

                        HStack(spacing: 12) {
                            ForEach(TaskPriorityColors.all) { colorItem in
                                let isSelected = selectedPriorityColor.lowercased() == colorItem.id.lowercased()
                                Button {
                                    MiodiHapticFeedback.selection()
                                    selectedPriorityColor = colorItem.id
                                    triggerAutoSave()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? (isDarkTheme ? Color.white.opacity(0.2) : Color.black.opacity(0.12)) : Color.clear)
                                            .frame(width: 44, height: 44)

                                        Circle()
                                            .fill(colorItem.circleColor)
                                            .frame(width: isSelected ? 34 : 30, height: isSelected ? 34 : 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        isSelected ? theme.currentAccent.primary : (isDarkTheme ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1)),
                                                        lineWidth: isSelected ? 2.5 : 1.5
                                                    )
                                            )

                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .black))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDarkTheme ? Color(hex: 0x141824) : Color(hex: 0xF1F5F9))
                    )
                }
            }
        }
    }

    private func priorityChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            MiodiHapticFeedback.selection()
            action()
        } label: {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x111827))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isSelected
                                ? (isDarkTheme ? Color(hex: 0x10B981).opacity(0.2) : Color(hex: 0x10B981).opacity(0.12))
                                : (isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isSelected ? Color(hex: 0x10B981) : (isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xE5E7EB)),
                                    lineWidth: isSelected ? 1.8 : 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Event Timing & Offset Calculation
    private var eventTimestamp: Date? {
        guard let timeStr = reminderTime, !timeStr.isEmpty else { return nil }
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return Calendar.current.date(from: comps)
    }

    private var isEventInPast: Bool {
        guard let eventDate = eventTimestamp else { return false }
        return eventDate <= Date()
    }

    private var minutesUntilEvent: Int? {
        guard let eventDate = eventTimestamp, !isEventInPast else { return nil }
        let diff = eventDate.timeIntervalSince(Date())
        return max(0, Int(diff / 60))
    }

    // MARK: - Card 5: Reminder Time Picker (Only on Important)
    private var reminderTimeCard: some View {
        fieldCard(title: "⏰ Время события / напоминание") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // Display & picker trigger
                    Button {
                        MiodiHapticFeedback.lightClick()
                        isShowingTimePicker.toggle()
                    } label: {
                        HStack {
                            Text(reminderTime ?? "Установить время")
                                .font(.system(size: 14, weight: reminderTime != nil ? .semibold : .regular))
                                .foregroundStyle(reminderTime != nil ? (isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2229)) : Color(hex: 0x9CA3AF))

                            Spacer()

                            Image(systemName: "clock")
                                .font(.system(size: 16))
                                .foregroundStyle(theme.currentAccent.primary)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isEventInPast ? Color(hex: 0xEF4444) : (isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xE5E7EB)), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // Reset button
                    if reminderTime != nil {
                        Button {
                            MiodiHapticFeedback.lightClick()
                            reminderTime = nil
                            reminderOffset = 0
                            triggerAutoSave()
                        } label: {
                            Text("Сброс")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: 0xEF4444))
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: 0xEF4444).opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Inline Wheel TimePicker when opened
                if isShowingTimePicker {
                    DatePicker(
                        "",
                        selection: $pickerTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .clipped()
                    .onChange(of: pickerTime) { _, newTime in
                        reminderTime = newTime.timeStringHHmm
                        triggerAutoSave()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                    )
                }

                // Quick Time Preset Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        quickTimeChip(label: "+5 мин", deltaMins: 5)
                        quickTimeChip(label: "+15 мин", deltaMins: 15)
                        quickTimeChip(label: "+1 ч", deltaMins: 60)
                        quickExactTimeChip(time: "09:00")
                        quickExactTimeChip(time: "14:00")
                        quickExactTimeChip(time: "19:00")
                        quickExactTimeChip(time: "21:00")
                    }
                }

                if let timeStr = reminderTime {
                    if isEventInPast {
                        HStack(spacing: 6) {
                            Text("⚠️ Время события (\(timeStr)) уже прошло. Напоминание установить нельзя.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(Color(hex: 0xE11D48))
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xE11D48).opacity(0.1))
                        )
                    } else {
                        // Offset selection section
                        Text("Напомнить до события:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x6B7280))

                        let standardOffsets: [(Int, String)] = [
                            (0, "Вовремя"),
                            (5, "За 5 мин"),
                            (15, "За 15 мин"),
                            (30, "За 30 мин"),
                            (60, "За 1 ч"),
                            (120, "За 2 ч"),
                            (1440, "За 1 дн")
                        ]

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(standardOffsets, id: \.0) { offsetMins, label in
                                    let isAllowed = offsetMins == 0 || (minutesUntilEvent != nil && offsetMins < minutesUntilEvent!)
                                    let isSelected = reminderOffset == offsetMins

                                    Button {
                                        MiodiHapticFeedback.selection()
                                        reminderOffset = offsetMins
                                        triggerAutoSave()
                                    } label: {
                                        Text(label)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                            .foregroundStyle(
                                                !isAllowed ? Color(hex: 0x9CA3AF).opacity(0.5) :
                                                (isSelected ? Color.white : (isDarkTheme ? Color(hex: 0xCBD5E1) : Color(hex: 0x4B5563)))
                                            )
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(
                                                        !isAllowed ? (isDarkTheme ? Color(hex: 0x1E2433).opacity(0.35) : Color(hex: 0xF3F4F6).opacity(0.5)) :
                                                        (isSelected ? theme.currentAccent.primary : (isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF3F4F6)))
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!isAllowed)
                                }

                                // Custom offset chip
                                let isCustom = reminderOffset > 0 && standardOffsets.allSatisfy { $0.0 != reminderOffset }
                                let customLabel: String = {
                                    if isCustom {
                                        if reminderOffset % 1440 == 0 { return "За \(reminderOffset / 1440) дн ✓" }
                                        if reminderOffset % 60 == 0 { return "За \(reminderOffset / 60) ч ✓" }
                                        return "За \(reminderOffset) мин ✓"
                                    }
                                    return "+ Своё"
                                }()

                                Button {
                                    MiodiHapticFeedback.selection()
                                    isShowingCustomOffsetSheet = true
                                } label: {
                                    Text(customLabel)
                                        .font(.system(size: 12, weight: isCustom ? .bold : .medium))
                                        .foregroundStyle(isCustom ? Color.white : (isDarkTheme ? Color(hex: 0xCBD5E1) : Color(hex: 0x4B5563)))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isCustom ? theme.currentAccent.primary : (isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF3F4F6)))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Trigger info text
                        if reminderOffset == 0 {
                            Text("🔔 Напоминание придет в \(timeStr) (в момент события)")
                                .font(.system(size: 11.5))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0x38BDF8) : Color(hex: 0x0284C7))
                        } else if let eventDate = eventTimestamp {
                            let triggerDate = eventDate.addingTimeInterval(-Double(reminderOffset * 60))
                            let isSameDay = Calendar.current.isDate(triggerDate, inSameDayAs: Date())
                            let timePart = triggerDate.timeStringHHmm
                            let whenStr = isSameDay ? "сегодня в \(timePart)" : triggerDate.formatted(date: .abbreviated, time: .shortened)
                            let offsetStr = reminderOffset % 1440 == 0 ? "\(reminderOffset / 1440) дн." : (reminderOffset % 60 == 0 ? "\(reminderOffset / 60) ч." : "\(reminderOffset) мин.")

                            Text("🔔 Напоминание придет: \(whenStr) (за \(offsetStr) до события)")
                                .font(.system(size: 11.5))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0x38BDF8) : Color(hex: 0x0284C7))
                        }
                    }
                } else {
                    Text("Уведомление поступит в назначенное время")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0xE11D48))
                }
            }
        }
        .sheet(isPresented: $isShowingCustomOffsetSheet) {
            customOffsetSheetView
        }
    }

    private var customOffsetSheetView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Свое время напоминания")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2229))
                    .padding(.top, 16)

                HStack(spacing: 12) {
                    TextField("30", text: $customOffsetValueText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF3F4F6))
                        )
                        .frame(width: 90)

                    Picker("Единица", selection: $customOffsetUnitIndex) {
                        Text("минут").tag(0)
                        Text("часов").tag(1)
                        Text("дней").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)

                let mult = (customOffsetUnitIndex == 0 ? 1 : (customOffsetUnitIndex == 1 ? 60 : 1440))
                let val = (Int(customOffsetValueText) ?? 0) * mult
                let isTooLong = minutesUntilEvent != nil && val >= minutesUntilEvent!
                let isValid = val > 0 && !isTooLong

                if isTooLong {
                    Text("До события осталось меньше времени (\(minutesUntilEvent ?? 0) мин)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0xEF4444))
                        .padding(.horizontal, 20)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Отмена") {
                        isShowingCustomOffsetSheet = false
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button("Применить") {
                        reminderOffset = val
                        isShowingCustomOffsetSheet = false
                        triggerAutoSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .presentationDetents([.height(260)])
        }
    }

    private func quickTimeChip(label: String, deltaMins: Int) -> some View {
        Button {
            MiodiHapticFeedback.selection()
            let target = Date().adding(minutes: deltaMins)
            reminderTime = target.timeStringHHmm
            triggerAutoSave()
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isDarkTheme ? Color(hex: 0xCBD5E1) : Color(hex: 0x4B5563))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF3F4F6))
                )
        }
        .buttonStyle(.plain)
    }

    private func quickExactTimeChip(time: String) -> some View {
        let isSelected = reminderTime == time
        return Button {
            MiodiHapticFeedback.selection()
            reminderTime = time
            triggerAutoSave()
        } label: {
            Text(time)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : (isDarkTheme ? Color(hex: 0xCBD5E1) : Color(hex: 0x4B5563)))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? theme.currentAccent.primary : (isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF3F4F6)))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card 6: Additional Notes & Photos Attachment
    private var notesAndPhotosCard: some View {
        fieldCard(title: "Заметки и фото") {
            VStack(alignment: .leading, spacing: 10) {
                // Notes editor
                ZStack(alignment: .topLeading) {
                    if notesText.isEmpty {
                        Text("Дополнительная информация, подзадачи, контакты...")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0x64748B) : Color(hex: 0x9CA3AF))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }

                    TextEditor(text: Binding(
                        get: { notesText },
                        set: { newNotes in
                            notesText = capitalizeFirst(newNotes)
                            triggerAutoSave()
                        }
                    ))
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2229))
                    .frame(minHeight: 65, maxHeight: 95)
                    .padding(8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xE5E7EB), lineWidth: 1)
                        )
                )

                // Photos Attachment Gallery (1-to-1 match with Android TaskEditModal)
                TaskPhotoGalleryView(
                    photos: $attachedPhotos,
                    mode: .editableThumbnails,
                    maxPhotos: 10,
                    isDarkTheme: isDarkTheme,
                    accentColor: theme.currentAccent.primary,
                    onPhotosChanged: { _ in
                        triggerAutoSave()
                    }
                )
            }
        }
    }

    // MARK: - Bottom Action Buttons: Отмена / Сохранить
    private var bottomActionButtons: some View {
        HStack(spacing: 12) {
            // Cancel
            Button {
                MiodiHapticFeedback.lightClick()
                onDismiss()
                dismiss()
            } label: {
                Text("Отмена")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x374151))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isDarkTheme ? Color(hex: 0x384256) : Color(hex: 0xD1D5DB), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            // Save
            Button {
                handleSave()
            } label: {
                Text("Сохранить")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : theme.currentAccent.primary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Save and AutoSave Logic
    private func handleSave() {
        let clean = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        MiodiHapticFeedback.success()
        let photoUriString = TaskPhotoStorage.joinPhotoUris(attachedPhotos)
        let dateString = selectedDate.yyyyMMddString

        onSave(
            clean,
            selectedSectionId,
            dateString,
            selectedPriority,
            selectedPriorityColor,
            selectedPriority == 1 ? reminderTime : nil,
            selectedPriority == 1 && reminderTime != nil ? reminderOffset : 0,
            notesText,
            photoUriString
        )
        dismiss()
    }

    private func triggerAutoSave() {
        let clean = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let photoUriString = TaskPhotoStorage.joinPhotoUris(attachedPhotos)
        let dateString = selectedDate.yyyyMMddString

        onAutoSave?(
            clean,
            selectedSectionId,
            dateString,
            selectedPriority,
            selectedPriorityColor,
            selectedPriority == 1 ? reminderTime : nil,
            selectedPriority == 1 && reminderTime != nil ? reminderOffset : 0,
            notesText,
            photoUriString
        )
    }

    private func capitalizeFirst(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased() + s.dropFirst()
    }

    // MARK: - Reusable Field Card
    private func fieldCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x1F2937))

            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF9FAFB))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isDarkTheme ? Color(hex: 0x2E3547) : Color(hex: 0xE5E7EB), lineWidth: 1)
                )
        )
    }
}
