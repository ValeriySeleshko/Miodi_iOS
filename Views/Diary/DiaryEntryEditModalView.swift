//
//  DiaryEntryEditModalView.swift
//  Plan4U_iOS
//
//  Full-featured rich-text Diary entry editor matching Android DiaryEditModal.kt (1055 lines).
//

import SwiftUI

public struct DiaryEntryEditModalView: View {
    public var entry: DiaryItem?
    public var initialDate: String = ""
    public var initialTime: String = ""
    public var onDismiss: () -> Void
    public var onSave: (DiaryItem) -> Void
    public var onDelete: ((String) -> Void)? = nil

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // Editable text and spans
    @State private var text: String = ""
    @State private var spans: [DiaryStyleSpan] = []
    @State private var activeStyle = DiaryCharStyle()
    @State private var selectedFontFamily: DiaryFontFamily = .ptSerif
    @State private var fontSize: CGFloat = 16.0

    // Date & Time states
    @State private var entryDate: Date = Date()
    @State private var entryTimeString: String = ""
    @State private var isShowingDateTimePicker: Bool = false

    // UI & Toolbar states
    @State private var isPreviewMode: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showFontOptions: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(
        entry: DiaryItem? = nil,
        initialDate: String = "",
        initialTime: String = "",
        onDismiss: @escaping () -> Void,
        onSave: @escaping (DiaryItem) -> Void,
        onDelete: ((String) -> Void)? = nil
    ) {
        self.entry = entry
        self.initialDate = initialDate
        self.initialTime = initialTime
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var wordCount: Int {
        DiaryRichTextEngine.wordCount(of: text)
    }

    private var charCount: Int {
        DiaryRichTextEngine.charCount(of: text)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                (isDark ? Color(hex: 0x141720) : Color(hex: 0xFDFBF7))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Date/Time badge & Close button
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 10)

                    // Mode Switcher: Редактор / Предпросмотр
                    HStack(spacing: 12) {
                        Picker("Режим", selection: $isPreviewMode) {
                            Text("Редактор").tag(false)
                            Text("Предпросмотр").tag(true)
                        }
                        .pickerStyle(.segmented)

                        Button {
                            showFontOptions.toggle()
                            MiodiHapticFeedback.lightClick()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "textformat")
                                Text(selectedFontFamily.displayName.components(separatedBy: " ").first ?? "Шрифт")
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(theme.currentAccent.primary.opacity(0.12)))
                            .foregroundStyle(theme.currentAccent.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    // Font options drawer if expanded
                    if showFontOptions {
                        fontOptionsCard
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Main Editor Card
                    ScrollView {
                        VStack(spacing: 12) {
                            if isPreviewMode {
                                previewCard
                            } else {
                                editorCard
                            }

                            // Sub-bar: Word and character counter
                            HStack {
                                Spacer()
                                Text("\(wordCount) слов, \(charCount) символов")
                                    .font(.caption)
                                    .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                            }
                            .padding(.horizontal, 4)

                            Color.clear.frame(height: 80)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Bottom Action Bar (Delete + Cancel + Save)
                    bottomActionBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(isDark ? Color(hex: 0x181C26) : Color.white)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(isDark ? Color(hex: 0x2A3142) : Color(hex: 0xE8E3DA)),
                            alignment: .top
                        )
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupInitialData()
            }
            .sheet(isPresented: $isShowingDateTimePicker) {
                dateTimePickerSheet
            }
            .confirmationDialog(
                "Удалить запись дневника?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    if let id = entry?.id {
                        onDelete?(id)
                        MiodiHapticFeedback.warning()
                        dismiss()
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Это действие нельзя будет отменить.")
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry == nil ? "Новая мысль" : "Запись дневника")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))

                // Date & Time clickable chip
                Button {
                    isShowingDateTimePicker = true
                    MiodiHapticFeedback.lightClick()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .semibold))
                        Text(formatHeaderDateTime())
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.currentAccent.primary.opacity(isDark ? 0.22 : 0.12))
                    )
                    .foregroundStyle(theme.currentAccent.primary)
                }
            }

            Spacer()

            Button {
                onDismiss()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isDark ? Color(hex: 0x64748B) : Color(hex: 0x94A3B8))
            }
        }
    }

    // MARK: - Editor Card

    private var editorCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Что у вас на уме сегодня? Запишите свои мысли, переживания, идеи или благодарности...")
                        .font(customFont(size: fontSize))
                        .foregroundStyle(isDark ? Color(hex: 0x64748B) : Color(hex: 0x94A3B8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(customFont(size: fontSize))
                    .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 220)
            }

            // Expandable color picker palette
            if showColorPicker {
                colorSwatchesBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Rich Text Formatting Toolbar
            formattingToolbar
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDark ? Color(hex: 0x1B202D) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE5DDD0), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(entryDate.userFriendlyDateString())
                }
                .font(.caption.bold())
                .foregroundStyle(theme.currentAccent.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(entryTimeString)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Текст записи пуст")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Text(DiaryRichTextEngine.buildAttributedString(
                    text: text,
                    spans: spans,
                    isDark: isDark,
                    fontSize: fontSize,
                    fontFamily: selectedFontFamily
                ))
                .lineSpacing(6)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDark ? Color(hex: 0x1B202D) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE5DDD0), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Font Options Card

    private var fontOptionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Шрифт:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Размер: \(Int(fontSize)) pt")
                    .font(.caption.bold())
                    .foregroundStyle(theme.currentAccent.primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DiaryFontFamily.allCases) { fontChoice in
                        Button {
                            selectedFontFamily = fontChoice
                            MiodiHapticFeedback.selection()
                        } label: {
                            Text(fontChoice.displayName)
                                .font(.system(size: 13, weight: selectedFontFamily == fontChoice ? .bold : .regular, design: fontChoice.design))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedFontFamily == fontChoice ? theme.currentAccent.primary : (isDark ? Color(hex: 0x283042) : Color(hex: 0xEDE7DC)))
                                )
                                .foregroundStyle(selectedFontFamily == fontChoice ? Color.white : (isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155)))
                        }
                    }
                }
            }

            // Font size slider
            Slider(value: $fontSize, in: 13...24, step: 1)
                .tint(theme.currentAccent.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF4EFE6))
        )
    }

    // MARK: - Color Swatches Bar

    private var colorSwatchesBar: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE5DDD0))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DiaryRichTextEngine.colorPalette) { option in
                        let swatchColor = isDark ? option.darkColor : option.lightColor
                        let isSelected = (activeStyle.colorHex == option.hex)

                        Button {
                            activeStyle.colorHex = (activeStyle.colorHex == option.hex) ? nil : option.hex
                            applyStyleToAllOrSelection()
                            MiodiHapticFeedback.lightClick()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(swatchColor)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? theme.currentAccent.primary : Color.white.opacity(0.5), lineWidth: isSelected ? 2.5 : 1)
                                    )

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(isDark ? Color(hex: 0x161B26) : Color(hex: 0xFAF6EF))
        }
    }

    // MARK: - Formatting Toolbar

    private var formattingToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE5DDD0))

            HStack(spacing: 6) {
                // Bold Button
                toolbarButton(
                    icon: "bold",
                    isActive: activeStyle.bold
                ) {
                    activeStyle.bold.toggle()
                    spans = DiaryRichTextEngine.toggleBold(
                        textLength: text.count,
                        spans: spans,
                        start: 0,
                        end: text.count
                    )
                    MiodiHapticFeedback.lightClick()
                }

                // Underline Button
                toolbarButton(
                    icon: "underline",
                    isActive: activeStyle.underline
                ) {
                    activeStyle.underline.toggle()
                    spans = DiaryRichTextEngine.toggleUnderline(
                        textLength: text.count,
                        spans: spans,
                        start: 0,
                        end: text.count
                    )
                    MiodiHapticFeedback.lightClick()
                }

                // Strikethrough Button
                toolbarButton(
                    icon: "strikethrough",
                    isActive: activeStyle.strikethrough
                ) {
                    activeStyle.strikethrough.toggle()
                    spans = DiaryRichTextEngine.toggleStrikethrough(
                        textLength: text.count,
                        spans: spans,
                        start: 0,
                        end: text.count
                    )
                    MiodiHapticFeedback.lightClick()
                }

                // Color Picker Toggle Button
                Button {
                    showColorPicker.toggle()
                    MiodiHapticFeedback.lightClick()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 13))
                        Circle()
                            .fill(activeStyle.colorHex != nil ? Color(hexString: activeStyle.colorHex!) : theme.currentAccent.primary)
                            .frame(width: 8, height: 8)
                    }
                    .frame(height: 32)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showColorPicker ? theme.currentAccent.primary.opacity(0.18) : Color.clear)
                    )
                    .foregroundStyle(showColorPicker ? theme.currentAccent.primary : (isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155)))
                }

                // Quote block styling button
                toolbarButton(
                    icon: "quote.opening",
                    isActive: false
                ) {
                    insertQuote()
                    MiodiHapticFeedback.lightClick()
                }

                Spacer()

                // Clear Formatting Button
                Button {
                    activeStyle = DiaryCharStyle()
                    spans.removeAll()
                    showColorPicker = false
                    MiodiHapticFeedback.lightClick()
                } label: {
                    Image(systemName: "eraser.fill")
                        .font(.system(size: 13))
                        .padding(7)
                        .background(Circle().fill(Color.gray.opacity(0.15)))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isDark ? Color(hex: 0x161B26) : Color(hex: 0xF7F2EA))
        }
    }

    private func toolbarButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: isActive ? .bold : .regular))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? theme.currentAccent.primary.opacity(isDark ? 0.28 : 0.16) : Color.clear)
                )
                .foregroundStyle(isActive ? theme.currentAccent.primary : (isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155)))
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            // Delete button (if editing existing entry)
            if entry != nil {
                Button {
                    showDeleteConfirmation = true
                    MiodiHapticFeedback.lightClick()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xEF4444))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(hex: 0xEF4444).opacity(isDark ? 0.2 : 0.1))
                        )
                }
            }

            // Cancel button
            Button {
                onDismiss()
                dismiss()
            } label: {
                Text("Отмена")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDark ? Color(hex: 0x222938) : Color(hex: 0xEDE8DF))
                    )
            }

            // Save button
            Button {
                saveEntry()
            } label: {
                Text("Сохранить")
                    .font(.body.bold())
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.4) : theme.currentAccent.primary)
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Date & Time Picker Sheet

    private var dateTimePickerSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Дата записи")) {
                    DatePicker(
                        "Выберите дату",
                        selection: $entryDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }

                Section(header: Text("Время записи")) {
                    HStack {
                        Text("Время")
                        Spacer()
                        TextField("ЧЧ:мм", text: $entryTimeString)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                    }

                    HStack(spacing: 8) {
                        Button("Сейчас") {
                            let f = DateFormatter()
                            f.dateFormat = "HH:mm"
                            entryTimeString = f.string(from: Date())
                            MiodiHapticFeedback.selection()
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.currentAccent.primary)

                        Button("Утро (09:00)") {
                            entryTimeString = "09:00"
                            MiodiHapticFeedback.selection()
                        }
                        .buttonStyle(.bordered)

                        Button("Вечер (21:00)") {
                            entryTimeString = "21:00"
                            MiodiHapticFeedback.selection()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Дата и время записи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Применить") {
                        isShowingDateTimePicker = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers & Actions

    private func setupInitialData() {
        if let existing = entry {
            self.text = existing.content
            self.entryTimeString = existing.time.isEmpty ? Date().timeStringHHmm : existing.time
            if let dateObj = Date.from(yyyyMMdd: existing.date) {
                self.entryDate = dateObj
            }
            self.spans = DiaryRichTextEngine.parseSpans(from: existing.formattingJson, maxTextLen: existing.content.count)
        } else {
            self.entryTimeString = initialTime.isEmpty ? Date().timeStringHHmm : initialTime
            if !initialDate.isEmpty, let d = Date.from(yyyyMMdd: initialDate) {
                self.entryDate = d
            } else {
                self.entryDate = Date()
            }
        }
    }

    private func formatHeaderDateTime() -> String {
        let datePart = entryDate.userFriendlyDateString()
        return entryTimeString.isEmpty ? datePart : "\(datePart), \(entryTimeString)"
    }

    private func customFont(size: CGFloat) -> Font {
        switch selectedFontFamily {
        case .ptSerif:
            return .system(size: size, weight: .regular, design: .serif)
        case .caveat:
            return .system(size: size + 1, weight: .regular, design: .serif).italic()
        case .comfortaa:
            return .system(size: size, weight: .regular, design: .rounded)
        case .roboto:
            return .system(size: size, weight: .regular, design: .default)
        }
    }

    private func applyStyleToAllOrSelection() {
        guard !text.isEmpty else { return }
        spans = DiaryRichTextEngine.applyColor(
            textLength: text.count,
            spans: spans,
            start: 0,
            end: text.count,
            colorHex: activeStyle.colorHex
        )
    }

    private func insertQuote() {
        if text.isEmpty {
            text = "«Ваша цитата или важная мысль»"
        } else {
            text.append("\n\n«Ваша цитата»")
        }
    }

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let dateStr = entryDate.yyyyMMddString
        let serializedSpans = DiaryRichTextEngine.serializeSpans(spans)
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)

        let target = entry ?? DiaryItem(
            date: dateStr,
            time: entryTimeString,
            content: trimmed,
            formattingJson: serializedSpans
        )

        target.date = dateStr
        target.time = entryTimeString
        target.content = trimmed
        target.formattingJson = serializedSpans
        target.updatedAt = nowMs

        onSave(target)
        MiodiHapticFeedback.success()
        dismiss()
    }
}
