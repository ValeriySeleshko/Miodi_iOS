//
//  TaskRowView.swift
//  Plan4U_iOS
//
//  Pixel-perfect and physics-accurate port of Android TaskRowItem.kt (1054 lines).
//  Features:
//  - Ruled notebook line alignment (26-32pt height)
//  - Left margin (50pt) checkbox & lock bullet area
//  - Precise swipe physics:
//      * completeThresholdPx = 85pt (drag right -> completion)
//      * swipeOpenThresholdPx = 36pt (drag left -> action buttons open)
//      * previewThresholdPx = 20pt (drag left -> actions fade-in preview)
//  - 5 Action buttons on swipe left:
//      1. Перенос на завтра (Amber #F59E0B)
//      2. Редактирование (Purple #8B5CF6)
//      3. Выбор даты (Blue #3B82F6)
//      4. Блокировка/Архив (Slate #64748B)
//      5. Удаление (Red #EF4444)
//  - Full priority support:
//      * 5 priority colors: black, burgundy, purple, navy, darkgreen
//      * Colored priority markers & tinted text
//      * Custom strikeout colors matching priority
//  - Metadata badges:
//      * Maine Quest secret cat paw 🐾
//      * Photo attachment badge 📷
//      * Reminder time ⏰ HH:mm
//      * Notes preview line with notebook ruling
//  - Haptic feedback integration (Taptic Engine)
//

import SwiftUI

public struct TaskRowView: View {
    @Bindable public var task: TaskItem

    // Callbacks
    public var onToggle: () -> Void
    public var onEdit: () -> Void
    public var onMoveToTomorrow: () -> Void
    public var onSelectDate: (() -> Void)?
    public var onToggleLock: (() -> Void)?
    public var onDelete: () -> Void
    public var onOpenPhotos: (([String]) -> Void)?
    public var onClick: (() -> Void)?
    public var onLongClick: (() -> Void)?
    public var onRestoreFromArchive: (() -> Void)?

    // Configuration flags
    public var isArchive: Bool = false
    public var canSwipeToRestore: Bool = false
    public var canMoveToTomorrow: Bool = true
    public var isEmptyPlaceholder: Bool = false
    public var marginWidth: CGFloat = 50.0
    public var rowHeight: CGFloat = 30.0

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    // Gesture & Interactive State
    @State private var dragOffset: CGFloat = 0.0
    @State private var isActionOpen: Bool = false
    @State private var hasHapticTriggeredForComplete: Bool = false
    @State private var hasHapticTriggeredForOpen: Bool = false
    @State private var isShowingDatePickerSheet: Bool = false
    @State private var pickerSelectedDate: Date = Date()
    @State private var isLockedState: Bool = false

    // Thresholds matching Android TaskRowItem.kt exactly
    private let completeThreshold: CGFloat = 85.0
    private let swipeOpenThreshold: CGFloat = 36.0
    private let previewThreshold: CGFloat = 20.0

    public init(
        task: TaskItem,
        isArchive: Bool = false,
        canSwipeToRestore: Bool = false,
        canMoveToTomorrow: Bool = true,
        isEmptyPlaceholder: Bool = false,
        marginWidth: CGFloat = 50.0,
        rowHeight: CGFloat = 30.0,
        onToggle: @escaping () -> Void = {},
        onEdit: @escaping () -> Void = {},
        onMoveToTomorrow: @escaping () -> Void = {},
        onSelectDate: (() -> Void)? = nil,
        onToggleLock: (() -> Void)? = nil,
        onDelete: @escaping () -> Void = {},
        onOpenPhotos: (([String]) -> Void)? = nil,
        onClick: (() -> Void)? = nil,
        onLongClick: (() -> Void)? = nil,
        onRestoreFromArchive: (() -> Void)? = nil
    ) {
        self.task = task
        self.isArchive = isArchive
        self.canSwipeToRestore = canSwipeToRestore
        self.canMoveToTomorrow = canMoveToTomorrow
        self.isEmptyPlaceholder = isEmptyPlaceholder
        self.marginWidth = marginWidth
        self.rowHeight = rowHeight
        self.onToggle = onToggle
        self.onEdit = onEdit
        self.onMoveToTomorrow = onMoveToTomorrow
        self.onSelectDate = onSelectDate
        self.onToggleLock = onToggleLock
        self.onDelete = onDelete
        self.onOpenPhotos = onOpenPhotos
        self.onClick = onClick
        self.onLongClick = onLongClick
        self.onRestoreFromArchive = onRestoreFromArchive
    }

    private var isDarkTheme: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var actionsWidth: CGFloat {
        if isArchive || task.isMaineQuest {
            return 105.0
        } else if !canMoveToTomorrow {
            return 134.0
        } else {
            return 168.0
        }
    }

    private var isImportant: Bool {
        task.priority == 1
    }

    private var taskTextColor: Color {
        if task.isCompleted {
            return isDarkTheme ? Color(hex: 0x64748B) : Color(hex: 0x8C827A)
        }
        if isImportant {
            return TaskPriorityColors.getTextColor(task.priorityColor, isDarkTheme: isDarkTheme)
        }
        return isDarkTheme ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText
    }

    private var strikeColor: Color {
        if isImportant {
            return TaskPriorityColors.getStrikeColor(task.priorityColor, isDarkTheme: isDarkTheme)
        }
        return isDarkTheme ? Color(hex: 0x94A3B8) : Color.black.opacity(0.75)
    }

    private var attachedPhotos: [String] {
        TaskPhotoStorage.parsePhotoUris(task.photoUri)
    }

    private var cleanText: String {
        if task.isMaineQuest {
            return task.text.replacingOccurrences(of: #"\s*🐾\s*$"#, with: "", options: .regularExpression)
        }
        return task.text
    }

    public var body: some View {
        if isEmptyPlaceholder {
            placeholderRow
        } else {
            mainTaskRow
        }
    }

    // MARK: - Empty Placeholder Row (Pencil on margin)
    private var placeholderRow: some View {
        HStack(spacing: 0) {
            Button {
                MiodiHapticFeedback.lightClick()
                onClick?()
            } label: {
                Text("✏️")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x9E8C94).opacity(0.6))
                    .frame(width: marginWidth, height: rowHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("Записать задачу...")
                .font(.system(size: 15, design: .serif))
                .italic()
                .foregroundStyle(isDarkTheme ? Color(hex: 0x64748B) : Color(hex: 0x9E8C94))
                .padding(.leading, 13)
                .padding(.trailing, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    MiodiHapticFeedback.lightClick()
                    onClick?()
                }
        }
        .frame(height: rowHeight)
    }

    // MARK: - Main Task Row
    private var mainTaskRow: some View {
        ZStack(alignment: .leading) {
            // 1. Right Swipe Background (Green Completion / Restoration)
            if (!isArchive || canSwipeToRestore) && dragOffset > 0 {
                greenCompletionBackground
            }

            // 2. Action Buttons (Revealed on swipe left)
            let showActions = !isArchive && (isActionOpen || (dragOffset < -previewThreshold))
            if showActions {
                HStack {
                    Spacer()
                    actionButtonsContainer
                        .padding(.trailing, 6)
                }
            }

            // 3. Foreground Content (Checkbox + Text + Indicators + Notes)
            HStack(alignment: .top, spacing: 0) {
                // Left Margin: Bullet / Checkbox
                marginCheckboxArea
                    .frame(width: marginWidth, height: rowHeight)

                // Task Details: Title + Badges + Notes
                VStack(alignment: .leading, spacing: 2) {
                    // Row 1: Text + Meta Badges + Strike line
                    HStack(alignment: .center, spacing: 6) {
                        // Priority Dot Marker (if Important)
                        if isImportant {
                            Circle()
                                .fill(TaskPriorityColors.fromId(task.priorityColor).circleColor)
                                .frame(width: 6, height: 6)
                                .overlay(
                                    Circle().stroke(isDarkTheme ? Color.white.opacity(0.4) : Color.black.opacity(0.2), lineWidth: 0.5)
                                )
                        }

                        // Text with authentic hand-drawn strike line
                        ZStack(alignment: .leading) {
                            Text(cleanText)
                                .font(.system(size: 15, weight: isImportant ? .semibold : .regular, design: .serif))
                                .foregroundStyle(taskTextColor)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            if task.isCompleted {
                                HandDrawnStrikeLineView(
                                    isCompleted: task.isCompleted,
                                    seed: task.id.hashValue,
                                    strokeColor: strikeColor,
                                    strokeWidth: 1.6
                                )
                                .padding(.leading, -2)
                                .padding(.trailing, -2)
                            }
                        }

                        // Badges / Indicators
                        metaIndicatorsView

                        Spacer(minLength: 4)
                    }
                    .frame(minHeight: rowHeight)

                    // Row 2: Additional Notes (underlined notebook style)
                    if let notes = task.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(notes)
                            .font(.system(size: 12, weight: .regular, design: .serif))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                            .lineLimit(2)
                            .padding(.top, 1)
                            .padding(.bottom, 3)
                    }
                }
                .padding(.leading, 13)
                .padding(.trailing, isActionOpen ? actionsWidth + 10 : 14)
            }
            .contentShape(Rectangle())
            .offset(x: dragOffset)
            .gesture(horizontalSwipeGesture)
            .onTapGesture {
                handleRowClick()
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                handleRowLongClick()
            }
        }
        .frame(minHeight: rowHeight)
        .sheet(isPresented: $isShowingDatePickerSheet) {
            datePickerSheet
        }
    }

    // MARK: - Green Completion Background
    private var greenCompletionBackground: some View {
        let progress = min(max(dragOffset / completeThreshold, 0.2), 1.0)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color(hex: 0x10B981)
                    .opacity(progress * 0.95)

                HStack(spacing: 6) {
                    Image(systemName: canSwipeToRestore ? "arrow.counterclockwise" : "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text(canSwipeToRestore ? "Восстановить" : (task.isCompleted ? "Отменить" : "Выполнено"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Margin Checkbox / Lock Area
    private var marginCheckboxArea: some View {
        Button {
            handleMarginTap()
        } label: {
            ZStack {
                if isArchive || isLockedState {
                    // Lock icon bullet for archived / locked tasks
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isDarkTheme ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1), lineWidth: 1)
                        )
                        .frame(width: 18, height: 18)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                } else {
                    // Checkbox bullet
                    let isChecked = task.isCompleted
                    let borderColor = isChecked
                        ? theme.currentAccent.primary
                        : (isDarkTheme ? Color(hex: 0x6B7280) : Color(hex: 0x4A4E57))

                    RoundedRectangle(cornerRadius: 3.5)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(isChecked ? theme.currentAccent.primary : Color.clear)
                        )
                        .frame(width: 17, height: 17)

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons Container (5 Action Buttons on Swipe Left)
    private var actionButtonsContainer: some View {
        HStack(spacing: 4) {
            if task.isMaineQuest {
                // Maine Quest 🐾 3 action buttons
                // Button 1: Edit / Info
                actionButton(
                    icon: "pawprint.fill",
                    bgColor: Color(hex: 0xF59E0B)
                ) {
                    closeActions()
                    onEdit()
                }

                // Button 2: Move to tomorrow
                actionButton(
                    icon: "arrow.turn.up.right",
                    bgColor: Color(hex: 0x3B82F6)
                ) {
                    closeActions()
                    onMoveToTomorrow()
                }

                // Button 3: Delete
                actionButton(
                    icon: "trash.fill",
                    bgColor: Color(hex: 0xEF4444)
                ) {
                    closeActions()
                    onDelete()
                }
            } else {
                // 1. Move to tomorrow (Amber)
                if canMoveToTomorrow {
                    actionButton(
                        icon: "arrow.turn.up.right",
                        bgColor: Color(hex: 0xF59E0B)
                    ) {
                        closeActions()
                        onMoveToTomorrow()
                    }
                }

                // 2. Edit (Purple)
                actionButton(
                    icon: "pencil",
                    bgColor: Color(hex: 0x8B5CF6)
                ) {
                    closeActions()
                    onEdit()
                }

                // 3. Pick Date (Blue)
                actionButton(
                    icon: "calendar",
                    bgColor: Color(hex: 0x3B82F6)
                ) {
                    closeActions()
                    if let onSelectDate = onSelectDate {
                        onSelectDate()
                    } else {
                        isShowingDatePickerSheet = true
                    }
                }

                // 4. Lock / Archive (Slate)
                actionButton(
                    icon: isLockedState ? "lock.open.fill" : "lock.fill",
                    bgColor: Color(hex: 0x64748B)
                ) {
                    closeActions()
                    isLockedState.toggle()
                    onToggleLock?()
                }

                // 5. Delete (Red)
                actionButton(
                    icon: "trash.fill",
                    bgColor: Color(hex: 0xEF4444)
                ) {
                    closeActions()
                    onDelete()
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1), lineWidth: 1)
                )
        )
    }

    private func actionButton(icon: String, bgColor: Color, action: @escaping () -> Void) -> some View {
        Button {
            MiodiHapticFeedback.lightClick()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(bgColor)
                    .frame(width: 28, height: 26)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meta Indicators View (Paw, Photos, Alarm)
    @ViewBuilder
    private var metaIndicatorsView: some View {
        HStack(spacing: 4) {
            // 1. Maine Quest Paw
            if task.isMaineQuest {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(task.isCompleted ? (isDarkTheme ? Color(hex: 0x64748B) : Color(hex: 0x9E8C94)) : theme.currentAccent.primary)
            }

            // 2. Photo attachment badge
            if !attachedPhotos.isEmpty {
                Button {
                    MiodiHapticFeedback.lightClick()
                    onOpenPhotos?(attachedPhotos)
                } label: {
                    HStack(spacing: 2) {
                        Text("📷")
                            .font(.system(size: 11))
                        if attachedPhotos.count > 1 {
                            Text("\(attachedPhotos.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isDarkTheme ? Color(hex: 0x262C3D) : Color(hex: 0xEDE8E4))
                    )
                }
                .buttonStyle(.plain)
            }

            // 3. Reminder time badge
            if let reminder = task.reminderTime, !reminder.isEmpty {
                HStack(spacing: 2) {
                    Text("⏰")
                        .font(.system(size: 10))
                    Text(reminder)
                        .font(.system(size: 10.5, weight: .medium, design: .serif))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                }
            }
        }
    }

    // MARK: - Gesture Handling (Strict adherence to 85pt, 36pt, 20pt)
    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                let translation = value.translation.width
                if isArchive && !canSwipeToRestore {
                    return
                }

                // Limit drag bounds
                let minOffset = -actionsWidth - 10.0
                let maxOffset = completeThreshold + 30.0
                let clamped = min(max(translation, minOffset), maxOffset)
                dragOffset = clamped

                // Haptic ticks at thresholds
                if (!isArchive || canSwipeToRestore) {
                    if clamped >= completeThreshold && !hasHapticTriggeredForComplete {
                        hasHapticTriggeredForComplete = true
                        MiodiHapticFeedback.selection()
                    } else if clamped < completeThreshold && hasHapticTriggeredForComplete {
                        hasHapticTriggeredForComplete = false
                    }
                }

                if !isArchive {
                    if clamped <= -swipeOpenThreshold && !hasHapticTriggeredForOpen {
                        hasHapticTriggeredForOpen = true
                        MiodiHapticFeedback.selection()
                    } else if clamped > -swipeOpenThreshold && hasHapticTriggeredForOpen {
                        hasHapticTriggeredForOpen = false
                    }
                }
            }
            .onEnded { value in
                let current = dragOffset
                hasHapticTriggeredForComplete = false
                hasHapticTriggeredForOpen = false

                if canSwipeToRestore && current > completeThreshold {
                    MiodiHapticFeedback.success()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        dragOffset = 0
                        isActionOpen = false
                    }
                    onRestoreFromArchive?()
                } else if !isArchive && current > completeThreshold {
                    MiodiHapticFeedback.taskComplete()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        dragOffset = 0
                        isActionOpen = false
                    }
                    toggleTaskCompleted()
                } else if !isArchive && current < -swipeOpenThreshold {
                    MiodiHapticFeedback.lightClick()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        dragOffset = -actionsWidth - 6
                        isActionOpen = true
                    }
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        dragOffset = 0
                        isActionOpen = false
                    }
                }
            }
    }

    private func handleMarginTap() {
        if isActionOpen {
            closeActions()
            return
        }
        if isArchive {
            if canSwipeToRestore {
                MiodiHapticFeedback.lightClick()
                onRestoreFromArchive?()
            }
            return
        }
        toggleTaskCompleted()
    }

    private func toggleTaskCompleted() {
        task.isCompleted.toggle()
        if task.isCompleted {
            task.completedAt = Int64(Date().timeIntervalSince1970 * 1000)
            MiodiHapticFeedback.taskComplete()
        } else {
            MiodiHapticFeedback.lightClick()
        }
        onToggle()
    }

    private func closeActions() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            dragOffset = 0
            isActionOpen = false
        }
    }

    private func handleRowClick() {
        if isActionOpen {
            closeActions()
        } else {
            MiodiHapticFeedback.lightClick()
            onClick?()
        }
    }

    private func handleRowLongClick() {
        if !isArchive && !isActionOpen {
            MiodiHapticFeedback.selection()
            onLongClick?()
        }
    }

    // MARK: - Native Date Picker Sheet for Action Button "Выбор даты"
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Дата выполнения задачи",
                    selection: $pickerSelectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Выбор даты задачи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        isShowingDatePickerSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Выбрать") {
                        task.date = pickerSelectedDate.yyyyMMddString
                        isShowingDatePickerSheet = false
                        MiodiHapticFeedback.success()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(theme.currentAccent.primary)
                }
            }
            .onAppear {
                if let parsed = Date.from(yyyyMMdd: task.date) {
                    pickerSelectedDate = parsed
                } else {
                    pickerSelectedDate = Date()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
