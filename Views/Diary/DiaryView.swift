//
//  DiaryView.swift
//  Plan4U_iOS
//
//  Personal Diary & Joy of the Day screen matching Android Diary features 100%.
//  Features:
//  - Live search across diary entry texts and timestamps
//  - Calendar date filtering & quick filter pills (Все, Сегодня, Вчера, Эта неделя, Этот месяц)
//  - Chronological grouping by days with localized Russian headers
//  - Rich text formatting & quote display
//  - Handwritten margin doodles layer (hearts, coffee cup, stars, cat paws)
//  - Swipe actions (Leading: Postcard Export; Trailing: Edit, Delete)
//  - Context menus on cards
//  - Postcard export & social media sharing modal
//  - Fullscreen rich editor modal with time picker and live preview
//  - PIN code & Biometric lock protection
//  - Joy of the Day ("Радость дня") integration
//

import SwiftUI
import SwiftData

public struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    // SwiftData Queries
    @Query(sort: \DiaryItem.timestamp, order: .reverse) private var allEntries: [DiaryItem]
    @Query(sort: \JoyItem.createdAt, order: .reverse) private var allJoys: [JoyItem]

    // Preferences & Privacy Lock
    @AppStorage("diary_selected_doodles") private var storedDoodlesRaw: String = "heart_outline,star_4pt,cat_paw,ribbon_bow,coffee_cup"
    @AppStorage("diary_font_id") private var storedFontId: String = "pt_serif"
    @AppStorage("diary_pin_code") private var savedPinCode: String = ""
    @AppStorage("diary_pin_enabled") private var isPinEnabled: Bool = false

    @State private var isDiaryUnlocked: Bool = false
    @State private var isShowingPinModal: Bool = false

    // Search & Filter States
    @State private var searchText: String = ""
    @State private var isSearchVisible: Bool = false
    @State private var activeFilter: DiaryDateFilter = .all
    @State private var customCalendarDate: Date = Date()
    @State private var isShowingCalendarSheet: Bool = false

    // Modals & Sheets
    @State private var editingEntry: DiaryItem? = nil
    @State private var isCreatingNewEntry: Bool = false
    @State private var exportingEntry: DiaryItem? = nil
    @State private var isShowingDoodleSettings: Bool = false
    @State private var deletingEntryId: String? = nil
    @State private var isShowingDeleteAlert: Bool = false

    // Joy of the Day states
    @State private var newJoyText: String = ""
    @State private var isAddingJoy: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var selectedDoodlesSet: Set<String> {
        get {
            Set(storedDoodlesRaw.components(separatedBy: ",").filter { !$0.isEmpty })
        }
    }

    public enum DiaryDateFilter: String, CaseIterable, Identifiable {
        case all = "Все записи"
        case today = "Сегодня"
        case yesterday = "Вчера"
        case thisWeek = "Эта неделя"
        case thisMonth = "Этот месяц"
        case custom = "Календарь"

        public var id: String { rawValue }
    }

    public init() {}

    // MARK: - Filtered & Grouped Entries

    private var filteredEntries: [DiaryItem] {
        let calendar = Calendar.current
        let today = Date()

        return allEntries.filter { entry in
            // Search filter
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let query = searchText.lowercased()
                let matchesContent = entry.content.lowercased().contains(query)
                let matchesDate = entry.date.contains(query)
                let matchesTime = entry.time.contains(query)
                if !matchesContent && !matchesDate && !matchesTime {
                    return false
                }
            }

            // Date filter
            guard let entryDate = Date.from(yyyyMMdd: entry.date) else { return true }

            switch activeFilter {
            case .all:
                return true
            case .today:
                return calendar.isDateInToday(entryDate)
            case .yesterday:
                return calendar.isDateInYesterday(entryDate)
            case .thisWeek:
                return calendar.isDate(entryDate, equalTo: today, toGranularity: .weekOfYear)
            case .thisMonth:
                return calendar.isDate(entryDate, equalTo: today, toGranularity: .month)
            case .custom:
                return calendar.isDate(entryDate, inSameDayAs: customCalendarDate)
            }
        }
    }

    private var groupedEntries: [(dateString: String, entries: [DiaryItem])] {
        let dict = Dictionary(grouping: filteredEntries, by: { $0.date })
        return dict.keys.sorted(by: >).map { key in
            (dateString: key, entries: dict[key] ?? [])
        }
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Authentic Ruled Notebook Canvas
            NotebookCanvasView(
                patternType: .lines,
                patternSize: 32,
                marginLineX: 48,
                isDarkTheme: isDark
            )

            // Background & Margin Doodles Layer
            DiaryDoodlesLayer(
                selectedDoodles: selectedDoodlesSet,
                seed: 42,
                isDark: isDark,
                isEmbossingEnabled: true,
                isMarginOnly: true
            )

            if isPinEnabled && !isDiaryUnlocked {
                // Locked Screen Shield
                lockedPrivacyView
            } else {
                // Main Diary Content Stream
                VStack(spacing: 0) {
                    headerView

                    if isSearchVisible {
                        searchBarView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    filterPillsRow

                    // Entries Scroll Stream
                    entriesScrollView
                }
            }
        }
        .onAppear {
            if !isPinEnabled {
                isDiaryUnlocked = true
            }
        }
        // MARK: - Sheets & Alerts
        .sheet(item: $editingEntry) { item in
            DiaryEntryEditModalView(
                entry: item,
                onDismiss: { editingEntry = nil },
                onSave: { updated in
                    try? modelContext.save()
                    editingEntry = nil
                },
                onDelete: { idToDelete in
                    deleteEntryById(idToDelete)
                    editingEntry = nil
                }
            )
        }
        .sheet(isPresented: $isCreatingNewEntry) {
            DiaryEntryEditModalView(
                initialDate: activeFilter == .today ? Date().yyyyMMddString : "",
                onDismiss: { isCreatingNewEntry = false },
                onSave: { newEntry in
                    modelContext.insert(newEntry)
                    try? modelContext.save()
                    isCreatingNewEntry = false
                }
            )
        }
        .sheet(item: $exportingEntry) { item in
            DiaryCardExportView(entry: item) {
                exportingEntry = nil
            }
        }
        .sheet(isPresented: $isShowingDoodleSettings) {
            DiaryDoodleSelectorModalView(
                selectedIds: Binding(
                    get: { selectedDoodlesSet },
                    set: { newSet in
                        storedDoodlesRaw = newSet.joined(separator: ",")
                    }
                ),
                isDark: isDark
            )
        }
        .sheet(isPresented: $isShowingPinModal) {
            DiaryPinModalView(
                mode: .enterToUnlock,
                onSuccess: {
                    isDiaryUnlocked = true
                    isShowingPinModal = false
                },
                onDismiss: {
                    isShowingPinModal = false
                }
            )
        }
        .sheet(isPresented: $isShowingCalendarSheet) {
            calendarPickerSheet
        }
        .confirmationDialog(
            "Удалить запись дневника?",
            isPresented: $isShowingDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                if let id = deletingEntryId {
                    deleteEntryById(id)
                    deletingEntryId = nil
                }
            }
            Button("Отмена", role: .cancel) {
                deletingEntryId = nil
            }
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }

    // MARK: - Top Header

    private var headerView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Дневник")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))

                    if isPinEnabled {
                        Image(systemName: isDiaryUnlocked ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.currentAccent.primary)
                    }
                }

                Text("\(allEntries.count) записей")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Search Toggle Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isSearchVisible.toggle()
                    if !isSearchVisible { searchText = "" }
                }
                MiodiHapticFeedback.lightClick()
            } label: {
                Image(systemName: isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundStyle(isSearchVisible ? theme.currentAccent.primary : (isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155)))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(isDark ? Color(hex: 0x1E2433) : Color.white.opacity(0.85))
                    )
            }

            // Doodles / Margins Settings
            Button {
                isShowingDoodleSettings = true
                MiodiHapticFeedback.lightClick()
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 17))
                    .foregroundStyle(theme.currentAccent.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(isDark ? Color(hex: 0x1E2433) : Color.white.opacity(0.85))
                    )
            }

            // New Entry Primary Action Button
            Button {
                MiodiHapticFeedback.lightClick()
                isCreatingNewEntry = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Запись")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(theme.currentAccent.primary)
                )
                .foregroundStyle(Color.white)
                .shadow(color: theme.currentAccent.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isDark ? Color(hex: 0x14171F).opacity(0.95) : Color.white.opacity(0.9))
    }

    // MARK: - Search Bar

    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Поиск по мыслям, датам, времени...", text: $searchText)
                .font(.system(size: 14))
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    MiodiHapticFeedback.lightClick()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF2EFE9))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Filter Pills Row

    private var filterPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiaryDateFilter.allCases) { filter in
                    let isSelected = (activeFilter == filter)
                    Button {
                        if filter == .custom {
                            isShowingCalendarSheet = true
                        } else {
                            activeFilter = filter
                        }
                        MiodiHapticFeedback.selection()
                    } label: {
                        HStack(spacing: 4) {
                            if filter == .custom {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                            }
                            Text(filter == .custom && activeFilter == .custom ? customCalendarDate.userFriendlyDateString() : filter.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? theme.currentAccent.primary : (isDark ? Color(hex: 0x1E2433) : Color.white.opacity(0.85)))
                        )
                        .foregroundStyle(isSelected ? Color.white : (isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569)))
                        .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.04), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Entries Scroll Stream

    private var entriesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Joy of the Day Banner Card
                joyOfTheDayBanner

                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    ForEach(groupedEntries, id: \.dateString) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            // Day Header
                            daySectionHeader(dateString: group.dateString, count: group.entries.count)

                            // Entries of this day
                            ForEach(group.entries) { entry in
                                entryCard(entry: entry)
                            }
                        }
                    }
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
        }
    }

    // MARK: - Day Section Header

    private func daySectionHeader(dateString: String, count: Int) -> some View {
        HStack(spacing: 8) {
            // Day Badge
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text(formatGroupHeader(dateString: dateString))
                    .font(.system(size: 13, weight: .bold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(theme.currentAccent.primary.opacity(isDark ? 0.22 : 0.12))
            )
            .foregroundStyle(theme.currentAccent.primary)

            Text("\(count) \(pluralizeThoughts(count))")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // Decorative separator line
            Rectangle()
                .fill(isDark ? Color(hex: 0x2A3142) : Color(hex: 0xE2D8C8))
                .frame(height: 1)
                .frame(maxWidth: 80)
        }
        .padding(.top, 6)
    }

    // MARK: - Entry Card

    private func entryCard(entry: DiaryItem) -> some View {
        Button {
            editingEntry = entry
            MiodiHapticFeedback.lightClick()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Top metadata row: Time + Postcard Export Button + Menu
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(entry.time.isEmpty ? "--:--" : entry.time)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(theme.currentAccent.primary)

                    Spacer()

                    // Quick Postcard Button
                    Button {
                        exportingEntry = entry
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 10))
                            Text("Открытка")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: 0x10B981).opacity(isDark ? 0.22 : 0.12)))
                        .foregroundStyle(Color(hex: 0x10B981))
                    }
                    .buttonStyle(.plain)

                    // Context Menu
                    Menu {
                        Button {
                            editingEntry = entry
                        } label: {
                            Label("Редактировать", systemImage: "pencil")
                        }

                        Button {
                            exportingEntry = entry
                        } label: {
                            Label("Создать открытку", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            UIPasteboard.general.string = entry.content
                            MiodiHapticFeedback.success()
                        } label: {
                            Label("Скопировать текст", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive) {
                            deletingEntryId = entry.id
                            isShowingDeleteAlert = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(6)
                    }
                }

                // Entry Content with Rich Formatting & Font
                Text(DiaryRichTextEngine.buildAttributedString(
                    text: entry.content,
                    spans: DiaryRichTextEngine.parseSpans(from: entry.formattingJson, maxTextLen: entry.content.count),
                    isDark: isDark,
                    fontSize: 15,
                    fontFamily: DiaryFontFamily(rawValue: storedFontId) ?? .ptSerif
                ))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isDark ? Color(hex: 0x181C26) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(isDark ? Color(hex: 0x2A3142) : Color(hex: 0xEBE5DC), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.05), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        // Swipe gestures
        .swipeActions(edge: .leading) {
            Button {
                exportingEntry = entry
            } label: {
                Label("Открытка", systemImage: "envelope.badge")
            }
            .tint(Color(hex: 0x10B981))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deletingEntryId = entry.id
                isShowingDeleteAlert = true
            } label: {
                Label("Удалить", systemImage: "trash")
            }

            Button {
                editingEntry = entry
            } label: {
                Label("Изменить", systemImage: "pencil")
            }
            .tint(theme.currentAccent.primary)
        }
    }

    // MARK: - Joy of the Day Banner

    private var joyOfTheDayBanner: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            isAddingJoy = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(Color(hex: 0xF59E0B))
                        Text("Радость дня")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))
                        Text("• 3 радости в день")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xD97706))
                    }

                    Spacer()

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.currentAccent.primary)
                }

                if let latestJoy = allJoys.first {
                    HStack(spacing: 6) {
                        Text(JoyMoodCatalog.resolveMoodEmoji(from: latestJoy.mood))
                            .font(.system(size: 14))
                        Text(latestJoy.text)
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155))
                            .lineLimit(2)
                    }
                } else {
                    Text("За что вы сегодня благодарны? Отметьте маленькую радость!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xFFFBF2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: 0xF59E0B).opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isAddingJoy) {
            JoyAddModalView()
        }
    }

    // MARK: - Locked Privacy View

    private var lockedPrivacyView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.currentAccent.primary.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(theme.currentAccent.primary)
            }

            VStack(spacing: 8) {
                Text("Личный дневник защищён")
                    .font(.title3.bold())
                    .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))

                Text("Для просмотра записей требуется ввести пароль или использовать Face ID.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                isShowingPinModal = true
                MiodiHapticFeedback.lightClick()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                    Text("Разблокировать")
                }
                .font(.body.bold())
                .foregroundStyle(Color.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Capsule().fill(theme.currentAccent.primary))
            }

            Spacer()
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: searchText.isEmpty ? "book.closed" : "magnifyingglass")
                .font(.system(size: 42))
                .foregroundStyle(theme.currentAccent.primary.opacity(0.6))
                .padding(.top, 60)

            Text(searchText.isEmpty ? "Дневник чист" : "Ничего не найдено")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(searchText.isEmpty ? "Запишите свои сокровенные мысли, события или идеи" : "Попробуйте изменить поисковый запрос или фильтр по дате")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if !searchText.isEmpty || activeFilter != .all {
                Button("Сбросить фильтры") {
                    searchText = ""
                    activeFilter = .all
                    MiodiHapticFeedback.lightClick()
                }
                .buttonStyle(.bordered)
                .tint(theme.currentAccent.primary)
            } else {
                Button {
                    isCreatingNewEntry = true
                    MiodiHapticFeedback.lightClick()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                        Text("Написать первую мысль")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.currentAccent.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(theme.currentAccent.primary.opacity(0.12)))
                }
            }
        }
    }

    // MARK: - Calendar Picker Sheet

    private var calendarPickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Дата для фильтра",
                    selection: $customCalendarDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Переход к дате")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { isShowingCalendarSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Выбрать") {
                        activeFilter = .custom
                        isShowingCalendarSheet = false
                        MiodiHapticFeedback.selection()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatGroupHeader(dateString: String) -> String {
        guard let d = Date.from(yyyyMMdd: dateString) else { return dateString }
        return d.userFriendlyDateString()
    }

    private func pluralizeThoughts(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 {
            return "запись"
        } else if mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20) {
            return "записи"
        } else {
            return "записей"
        }
    }

    private func deleteEntryById(_ id: String) {
        if let toDelete = allEntries.first(where: { $0.id == id }) {
            modelContext.delete(toDelete)
            try? modelContext.save()
            MiodiHapticFeedback.warning()
        }
    }

    private func saveJoy() {
        let trimmed = newJoyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let joy = JoyItem(
            date: Date().yyyyMMddString,
            text: trimmed,
            orderIndex: allJoys.count
        )
        modelContext.insert(joy)
        try? modelContext.save()
        newJoyText = ""
        isAddingJoy = false
        MiodiHapticFeedback.success()
    }
}
