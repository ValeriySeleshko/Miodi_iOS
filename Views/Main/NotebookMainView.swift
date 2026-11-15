//
//  NotebookMainView.swift
//  Plan4U_iOS
//
//  Master container: Task List, Habits, Finance, Diary, Nutrition, Settings.
//  100% feature-complete pixel-and-tactile twin of Miodi on Samsung Galaxy S24 Ultra.
//

import SwiftUI
import SwiftData

public struct NotebookMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \TaskItem.orderIndex) private var tasks: [TaskItem]
    @Query(sort: \TabItem.orderIndex) private var tabs: [TabItem]
    @Query private var allHabits: [HabitItem]
    @Query private var allDiary: [DiaryItem]
    @Query private var pets: [PetItem]
    @Query private var allCycles: [CycleItem]

    @State private var currentSection: MiodiSection = .tasks
    @State private var activeTabId: String = "todo"
    @State private var quickText: String = ""
    @State private var isAddingTask: Bool = false
    @State private var isPetModalOpen: Bool = false
    @State private var editingTask: TaskItem? = nil
    @State private var selectedDateStr: String = ""
    @State private var scrollOffsetY: CGFloat = 0.0
    @State private var activeLightboxPhotos: [String]? = nil
    @State private var activeLightboxIndex: Int = 0
    @State private var isShowingMonthCalendar: Bool = false
    @State private var isShowingCycleTracker: Bool = false
    @State private var isTimelineMode: Bool = false
    @State private var activeCustomizingSlotIndex: Int? = nil
    @State private var quickAccessSlots: QuickAccessSlots = QuickAccessSlots()
    @State private var isHabitsTrayExpanded: Bool = false
    @State private var isShowingCreateHabit: Bool = false

    // Notebook Enhancement States
    @State private var showCoverOverlay: Bool = true
    @State private var isAddingTab: Bool = false
    @State private var editingTabItem: TabItem? = nil
    @State private var tabToDelete: TabItem? = nil
    @State private var isStickersModalOpen: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var effectiveSelectedDate: String {
        selectedDateStr.isEmpty ? Date().yyyyMMddString : selectedDateStr
    }

    private var currentWeekDays: [DayItemModel] {
        let today = Date()
        let todayYmd = today.yyyyMMddString

        // Find Monday of the current week
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let monday = cal.date(from: comps) else {
            return []
        }

        let dayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        return (0..<7).compactMap { dayOffset in
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: monday) else { return nil }
            let ymd = date.yyyyMMddString
            let isToday = (ymd == todayYmd)
            let dayName = dayNames[dayOffset]

            return DayItemModel(
                dayName: dayName,
                dateStr: ymd,
                isToday: isToday,
                progress: 0.0
            )
        }
    }

    private var displayedTasks: [TaskItem] {
        let activeTab = activeTabId
        let selDate = effectiveSelectedDate

        let filtered: [TaskItem]
        if activeTab != "todo" {
            filtered = tasks.filter { $0.tabId == activeTab }
        } else {
            filtered = tasks.filter { task in
                (task.tabId == "todo" || task.tabId.isEmpty) && (task.date == selDate || task.date.isEmpty)
            }
        }

        return filtered.sorted { t1, t2 in
            if t1.isCompleted != t2.isCompleted {
                return !t1.isCompleted
            }
            return t1.orderIndex < t2.orderIndex
        }
    }

    private var folderTabs: [FolderTabItemModel] {
        if tabs.isEmpty {
            return [
                FolderTabItemModel(id: "todo", title: "Дела", count: tasks.filter { !$0.isCompleted }.count, colorHex: "white", patternType: "lines", patternSizePx: 32, orderIndex: 0),
                FolderTabItemModel(id: "work", title: "Работа", count: 0, colorHex: "peach_light", patternType: "lines", patternSizePx: 32, orderIndex: 1),
                FolderTabItemModel(id: "home", title: "Дом", count: 0, colorHex: "mint_light", patternType: "grid", patternSizePx: 32, orderIndex: 2),
                FolderTabItemModel(id: "ideas", title: "Идеи", count: 0, colorHex: "lavender_light", patternType: "dots", patternSizePx: 32, orderIndex: 3)
            ]
        }
        return tabs.map { tab in
            let count = (tab.id == "todo") ? tasks.filter { !$0.isCompleted }.count : 0
            return FolderTabItemModel(
                id: tab.id,
                title: tab.title,
                count: count,
                colorHex: tab.colorHex,
                patternType: tab.patternType,
                patternSizePx: tab.patternSizePx,
                orderIndex: tab.orderIndex
            )
        }
    }

    private var currentActiveTab: TabItem? {
        tabs.first { $0.id == activeTabId }
    }

    private var activePattern: NotebookPattern {
        guard let current = currentActiveTab else { return .lines }
        return NotebookPattern(string: current.patternType)
    }

    private var activePatternSize: CGFloat {
        guard let current = currentActiveTab else { return 32.0 }
        return CGFloat(current.patternSizePx)
    }

    private var activeSheetColor: Color? {
        guard let current = currentActiveTab else { return nil }
        let cDef = getTabColorDef(idOrHex: current.colorHex)
        return isDark ? cDef.darkSheetBg : cDef.sheetBg
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Section Content
            Group {
                switch currentSection {
                case .tasks:
                    tasksSectionView
                case .habits:
                    HabitsView()
                case .joy:
                    JoyView()
                case .finance:
                    FinanceView()
                case .diary:
                    DiaryView()
                case .nutrition:
                    NutritionWeightView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Maine Coon Cat Companion replaced by 1:1 Floating Controls Bar in Tasks section
            if showCoverOverlay {
                NotebookCoverOpeningOverlayView(isDarkTheme: isDark) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showCoverOverlay = false
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            ensurePetExists()
            ensureTabsExist()
        }
        .sheet(isPresented: $isPetModalOpen) {
            if let pet = activePet {
                PetStatusModalView(pet: pet)
            }
        }
        .sheet(isPresented: $isAddingTask) {
            TaskDetailModalView(
                initialDate: selectedDateStr.isEmpty ? Date().yyyyMMddString : selectedDateStr,
                onDismiss: {
                    isAddingTask = false
                },
                onSave: { text, sectionId, date, priority, priorityColor, reminderTime, notes, photoUri in
                    let newTask = TaskItem(
                        sectionId: sectionId,
                        text: text,
                        date: date,
                        priority: priority,
                        priorityColor: priorityColor,
                        reminderTime: reminderTime,
                        notes: notes,
                        photoUri: photoUri,
                        orderIndex: tasks.count
                    )
                    modelContext.insert(newTask)
                    try? modelContext.save()
                    isAddingTask = false
                }
            )
        }
        .sheet(item: $editingTask) { taskToEdit in
            TaskDetailModalView(
                task: taskToEdit,
                onDismiss: {
                    editingTask = nil
                },
                onSave: { text, sectionId, date, priority, priorityColor, reminderTime, notes, photoUri in
                    taskToEdit.text = text
                    taskToEdit.sectionId = sectionId
                    taskToEdit.date = date
                    taskToEdit.priority = priority
                    taskToEdit.priorityColor = priorityColor
                    taskToEdit.reminderTime = reminderTime
                    taskToEdit.notes = notes
                    taskToEdit.photoUri = photoUri
                    try? modelContext.save()
                    editingTask = nil
                }
            )
        }
        .fullScreenCover(isPresented: Binding(
            get: { activeLightboxPhotos != nil },
            set: { if !$0 { activeLightboxPhotos = nil } }
        )) {
            if let photos = activeLightboxPhotos {
                ImageLightboxModalView(
                    imageList: photos,
                    initialIndex: activeLightboxIndex,
                    onDismissRequest: {
                        activeLightboxPhotos = nil
                    }
                )
                .background(ClearBackgroundView())
            }
        }
        .sheet(isPresented: $isShowingMonthCalendar) {
            FullMonthCalendarView(
                selectedDate: selectedDateStr.isEmpty ? Date().yyyyMMddString : selectedDateStr,
                todayDate: Date().yyyyMMddString,
                activeDates: Set(tasks.map { $0.date }.filter { !$0.isEmpty }),
                diaryDates: Set(allDiary.map { $0.date }.filter { !$0.isEmpty }),
                cycleDates: Set(allCycles.map { $0.startDate }.filter { !$0.isEmpty }),
                tasks: tasks,
                habits: allHabits,
                diaryEntries: allDiary,
                onDismiss: { isShowingMonthCalendar = false },
                onOpenCycle: {
                    isShowingMonthCalendar = false
                    isShowingCycleTracker = true
                },
                onSelectDate: { newDate in
                    selectedDateStr = newDate
                    isShowingMonthCalendar = false
                }
            )
        }
        .sheet(isPresented: $isShowingCycleTracker) {
            CycleTrackerView()
        }
        .sheet(isPresented: $isShowingCreateHabit) {
            HabitDetailModalView()
        }
        .overlay {
            if let slotIdx = activeCustomizingSlotIndex {
                QuickAccessSlotPickerModalView(
                    slotIndex: slotIdx,
                    currentSlots: quickAccessSlots,
                    onDismiss: { activeCustomizingSlotIndex = nil },
                    onSelect: { selectedItem in
                        quickAccessSlots = quickAccessSlots.withSlotUpdated(slotIndex: slotIdx, newItem: selectedItem)
                        activeCustomizingSlotIndex = nil
                    },
                    onResetToDefaults: {
                        quickAccessSlots = QuickAccessSlots()
                        activeCustomizingSlotIndex = nil
                    }
                )
            }
        }
        .sheet(isPresented: $isStickersModalOpen) {
            StickersModalView(
                tabId: activeTabId,
                dateStr: selectedDateStr,
                onDismiss: {
                    isStickersModalOpen = false
                }
            )
        }
        .sheet(isPresented: $isAddingTab) {
            FolderTabEditModalView(
                isCreateMode: true,
                onDismiss: {
                    isAddingTab = false
                },
                onSave: { newTitle, newColorId, newPattern, newSizePx in
                    let newTab = TabItem(
                        id: UUID().uuidString.lowercased(),
                        title: newTitle,
                        colorHex: newColorId,
                        patternType: newPattern,
                        patternSizePx: newSizePx,
                        orderIndex: tabs.count
                    )
                    modelContext.insert(newTab)
                    try? modelContext.save()
                    activeTabId = newTab.id
                    isAddingTab = false
                }
            )
        }
        .sheet(item: $editingTabItem) { tabToEdit in
            FolderTabEditModalView(
                tab: tabToEdit,
                isCreateMode: false,
                onDismiss: {
                    editingTabItem = nil
                },
                onDelete: {
                    deleteTab(tabToEdit)
                },
                onSave: { newTitle, newColorId, newPattern, newSizePx in
                    tabToEdit.title = newTitle
                    tabToEdit.colorHex = newColorId
                    tabToEdit.patternType = newPattern
                    tabToEdit.patternSizePx = newSizePx
                    try? modelContext.save()
                    editingTabItem = nil
                }
            )
        }
        .sheet(item: $tabToDelete) { targetTab in
            ConfirmDeleteModalView(
                title: "Удалить закладку?",
                message: "Вы уверены? Закладка «\(targetTab.title)» будет удалена навсегда.",
                onCancel: {
                    tabToDelete = nil
                },
                onConfirm: {
                    deleteTab(targetTab)
                    tabToDelete = nil
                }
            )
        }
    }

    // MARK: - Tasks Section View
    private var tasksSectionView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Paper Background with active tab's pattern, size, and tint
                NotebookCanvasView(
                    patternType: activePattern,
                    patternSize: activePatternSize,
                    marginLineX: 50.0,
                    scrollY: scrollOffsetY,
                    agingDays: 0.0,
                    isDarkTheme: isDark,
                    backgroundColor: activeSheetColor
                )

                // Interactive Stickers Layer on sheet
                PageStickersLayer(
                    tabId: activeTabId,
                    dateStr: selectedDateStr,
                    sheetWidth: geometry.size.width,
                    sheetHeight: geometry.size.height
                )

                VStack(spacing: 0) {
                    // Top Widgets Bar: Date, Tasks count ring, Streak flame, Stickers sparkle, Settings
                    let calendar = Calendar.current
                    let now = Date.from(yyyyMMdd: effectiveSelectedDate) ?? Date()
                    let dayNum = "\(calendar.component(.day, from: now))"
                    let dayWk = DateFormatter().shortWeekdaySymbols?[calendar.component(.weekday, from: now) - 1] ?? "пт"
                    let completedCount = tasks.filter { $0.isCompleted }.count
                    let totalCount = tasks.count

                    TopWidgetsBarView(
                        dayNumber: dayNum,
                        dayOfWeek: dayWk,
                        completedTasks: completedCount,
                        totalTasks: totalCount,
                        streakCount: activePet?.streakDays ?? 0,
                        onDateClick: { isShowingMonthCalendar = true },
                        onTasksClick: { isShowingMonthCalendar = true },
                        onStreakClick: { isAchievementsOpen = true },
                        onStickersClick: { isStickersModalOpen = true },
                        onSettingsClick: { currentSection = .settings }
                    )

                    // Week Days Bar
                    WeekDaysBarView(
                        days: currentWeekDays,
                        isDrawerExpanded: isHabitsTrayExpanded,
                        onSelectDay: { selectedDay in
                            selectedDateStr = selectedDay.dateStr
                        },
                        onAddHabitClick: {
                            isShowingCreateHabit = true
                        },
                        onToggleDrawer: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                isHabitsTrayExpanded.toggle()
                            }
                        }
                    )
                    .background(isDark ? MiodiStaticColors.darkTopBarBg : Color(hex: 0xF7F7F8))
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(isDark ? MiodiStaticColors.darkTopBarBorder : MiodiStaticColors.ruledLineColor),
                        alignment: .bottom
                    )

                    // Folder Tabs Row with complete context menu & reordering
                    FolderTabsRowView(
                        tabs: folderTabs,
                        activeTabId: $activeTabId,
                        onSelectTab: { tabId in
                            activeTabId = tabId
                        },
                        onEditTab: { tabModel in
                            editingTabItem = tabs.first { $0.id == tabModel.id }
                        },
                        onReorderTabs: { reordered in
                            for (idx, item) in reordered.enumerated() {
                                if let found = tabs.first(where: { $0.id == item.id }) {
                                    found.orderIndex = idx
                                }
                            }
                            try? modelContext.save()
                        },
                        onAddTab: {
                            isAddingTab = true
                        },
                        onChangeColor: { tabId, newColor in
                            if let found = tabs.first(where: { $0.id == tabId }) {
                                found.colorHex = newColor
                                try? modelContext.save()
                            }
                        },
                        onChangePattern: { tabId, newPattern in
                            if let found = tabs.first(where: { $0.id == tabId }) {
                                found.patternType = newPattern
                                try? modelContext.save()
                            }
                        },
                        onDeleteTab: { tabId in
                            if let found = tabs.first(where: { $0.id == tabId }) {
                                tabToDelete = found
                            }
                        }
                    )

                    // Mode Switcher: Список / Таймлайн 06-24
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Button {
                                MiodiHapticFeedback.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    isTimelineMode = false
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Text("📋")
                                        .font(.system(size: 11))
                                    Text("Список")
                                        .font(.system(size: 11, weight: !isTimelineMode ? .bold : .medium))
                                }
                                .foregroundStyle(!isTimelineMode ? .white : (isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B)))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(!isTimelineMode ? theme.currentAccent.primary : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button {
                                MiodiHapticFeedback.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    isTimelineMode = true
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Text("⏱️")
                                        .font(.system(size: 11))
                                    Text("06-24")
                                        .font(.system(size: 11, weight: isTimelineMode ? .bold : .medium))
                                }
                                .foregroundStyle(isTimelineMode ? .white : (isDark ? MiodiStaticColors.darkTextSecondary : Color(hex: 0x64748B)))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isTimelineMode ? theme.currentAccent.primary : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 2)

                if isTimelineMode {
                    DayTimelineView(
                        initialDate: Date.from(yyyyMMdd: effectiveSelectedDate) ?? Date(),
                        onOpenMonthCalendar: { isShowingMonthCalendar = true }
                    )
                } else {
                    // Task List over paper ruling
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(displayedTasks) { task in
                                TaskRowView(
                                    task: task,
                                    onToggle: {
                                        handleTaskToggle(task)
                                    },
                                    onEdit: {
                                        editingTask = task
                                    },
                                    onMoveToTomorrow: { moveTaskTomorrow(task) },
                                    onDelete: { deleteTask(task) },
                                    onOpenPhotos: { photos in
                                        activeLightboxPhotos = photos
                                        activeLightboxIndex = 0
                                    }
                                )
                            }

                            // Pencil placeholder row for quick task input
                            HStack(spacing: 0) {
                                Button {
                                    isAddingTask = true
                                    MiodiHapticFeedback.lightClick()
                                } label: {
                                    Text("✏️")
                                        .font(.system(size: 11))
                                        .frame(width: 50, height: 32)
                                }
                                .buttonStyle(.plain)

                                TextField("Записать задачу...", text: $quickText)
                                    .font(.system(size: 15, design: .serif))
                                    .foregroundStyle(isDark ? Color(hex: 0x64748B) : Color(hex: 0x9E8C94))
                                    .padding(.leading, 13)
                                    .padding(.trailing, 14)
                                    .frame(height: 32)
                                    .onSubmit {
                                        commitQuickTask()
                                    }
                            }
                            .frame(height: 32)

                            // Bottom spacing for floating bar
                            Color.clear.frame(height: 110)
                        }
                        .padding(.top, 4)
                    }
                    .scrollIndicators(.hidden)
                }
            }

            // Interactive Bottom Habits Substrate Tray (when expanded)
            if isHabitsTrayExpanded {
                HabitsTrayView(isExpanded: $isHabitsTrayExpanded)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Floating Controls Bar: Speech Bubble, + Button, ✨ Stickers, 3D Mascot Avatar
            MiodiFloatingControlsView(
                catMessage: activePet?.currentQuote ?? "Привет, друг! Мяу! Готов планировать великие свершения? ✨",
                pet: activePet,
                onAddClick: { isAddingTask = true },
                onStickersClick: { isStickersModalOpen = true },
                onPetClick: { isPetModalOpen = true }
            )
        }
    }
}

    private func commitQuickTask() {
        let trimmed = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        createTask(text: trimmed)
        quickText = ""
    }

    private func createTask(text: String) {
        let newTask = TaskItem(
            sectionId: "",
            tabId: activeTabId,
            text: text,
            date: effectiveSelectedDate,
            orderIndex: tasks.count
        )
        modelContext.insert(newTask)
        try? modelContext.save()
        MiodiHapticFeedback.success()
    }

    private func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func moveTaskTomorrow(_ task: TaskItem) {
        let current = Date.from(yyyyMMdd: task.date) ?? Date()
        task.date = current.adding(days: 1).yyyyMMddString
        try? modelContext.save()
        MiodiHapticFeedback.lightClick()
    }

    // MARK: - Pet Helper Methods
    private var activePet: PetItem? {
        pets.first
    }

    private func ensurePetExists() {
        if pets.isEmpty {
            let defaultPet = PetItem()
            modelContext.insert(defaultPet)
            try? modelContext.save()
        }
    }

    private func handleTaskToggle(_ task: TaskItem) {
        if task.isCompleted {
            if let pet = activePet {
                _ = PetProgressionService.rewardTaskCompleted(
                    pet: pet,
                    priority: task.priority,
                    isMaineQuest: task.isMaineQuest
                )
                try? modelContext.save()
            }
        }
    }

    // MARK: - Tab Management
    private func deleteTab(_ tab: TabItem) {
        if ["todo", "buy", "watch", "diary"].contains(tab.id) { return }
        if activeTabId == tab.id {
            activeTabId = "todo"
        }
        modelContext.delete(tab)
        try? modelContext.save()
        MiodiHapticFeedback.warning()
    }

    private func ensureTabsExist() {
        if tabs.isEmpty {
            let defaults: [(id: String, title: String, color: String, pattern: String, size: Int)] = [
                ("todo", "Дела", "white", "lines", 32),
                ("work", "Работа", "peach_light", "lines", 32),
                ("home", "Дом", "mint_light", "grid", 32),
                ("ideas", "Идеи", "lavender_light", "dots", 32)
            ]
            for (idx, item) in defaults.enumerated() {
                let newTab = TabItem(
                    id: item.id,
                    title: item.title,
                    colorHex: item.color,
                    patternType: item.pattern,
                    patternSizePx: item.size,
                    orderIndex: idx
                )
                modelContext.insert(newTab)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Quick Add Modal Sheet
private struct QuickAddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @State private var taskText: String = ""
    var onSave: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Новая задача")
                .font(.headline)
                .padding(.top, 14)

            TextField("Что нужно сделать?", text: $taskText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)

            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Добавить") {
                    let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onSave(trimmed)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.currentAccent.primary)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
