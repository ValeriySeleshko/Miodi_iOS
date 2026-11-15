//
//  FolderTabEditModalView.swift
//  Plan4U_iOS
//
//  Exact 100% replica of Android EditTabModal.kt (matching baseline 03_edit_tab_modal.png).
//  Features tab name input, 21-color palette grid (3x7), 8 sheet pattern cards with live canvas previews,
//  pattern size slider with "✨ Авто" 26px reset, diary typography controls, delete confirmation, and haptics.
//

import SwiftUI

public struct FolderTabEditModalView: View {
    public var tab: TabItem?
    public var isCreateMode: Bool = false
    public var onDismiss: () -> Void = {}
    public var onDelete: (() -> Void)? = nil
    public var onSave: (
        _ title: String,
        _ colorId: String,
        _ patternType: String,
        _ patternSizePx: Int
    ) -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String = ""
    @State private var selectedColorId: String = "white"
    @State private var selectedPattern: NotebookPattern = .lines
    @State private var patternSize: Double = 32.0
    @State private var isConfirmDeleteOpen: Bool = false

    // Diary-specific additions
    @State private var selectedDiaryFont: String = "Caveat"
    @State private var diaryEmbossing: Bool = true

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var isSystemTab: Bool {
        guard let tab = tab else { return false }
        return ["todo", "buy", "watch", "diary"].contains(tab.id)
    }

    public init(
        tab: TabItem? = nil,
        isCreateMode: Bool = false,
        onDismiss: @escaping () -> Void = {},
        onDelete: (() -> Void)? = nil,
        onSave: @escaping (
            _ title: String,
            _ colorId: String,
            _ patternType: String,
            _ patternSizePx: Int
        ) -> Void
    ) {
        self.tab = tab
        self.isCreateMode = isCreateMode
        self.onDismiss = onDismiss
        self.onDelete = onDelete
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Row
                    headerRowView

                    // 1. Tab Name Input
                    tabNameSectionView

                    // 2. Tab & Sheet Color (21 colors in 3 rows of 7)
                    colorPaletteSectionView

                    // 3. Notebook Sheet Pattern (8 patterns)
                    patternSelectionSectionView

                    // 4. Pattern Size Slider (hidden if "blank")
                    if selectedPattern != .blank {
                        patternSizeSliderView
                    }

                    // 5. Diary Options (if diary tab)
                    if tab?.id == "diary" {
                        diarySpecificOptionsView
                    }

                    // 6. Delete Tab Button (if not system tab and in edit mode)
                    if !isSystemTab && !isCreateMode && onDelete != nil {
                        deleteTabButtonView
                    }

                    // 7. Action Buttons (Отмена / Сохранить)
                    actionButtonsRowView
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
            .sheet(isPresented: $isConfirmDeleteOpen) {
                ConfirmDeleteModalView(
                    title: "Удалить закладку?",
                    message: "Вы уверены? Закладка «\(title)» и все задачи в ней будут удалены навсегда.",
                    onCancel: {
                        isConfirmDeleteOpen = false
                    },
                    onConfirm: {
                        isConfirmDeleteOpen = false
                        onDelete?()
                        onDismiss()
                    }
                )
            }
        }
        .onAppear {
            initializeValues()
        }
    }

    private func initializeValues() {
        if let tab = tab {
            self.title = tab.title
            self.selectedColorId = tab.colorHex ?? "white"
            self.selectedPattern = NotebookPattern(string: tab.patternType)
            self.patternSize = Double(tab.patternSizePx)
        } else {
            self.title = ""
            self.selectedColorId = "white"
            self.selectedPattern = .lines
            self.patternSize = 32.0
        }
    }

    // MARK: - Header Row
    private var headerRowView: some View {
        HStack {
            Text(isCreateMode ? "Новая закладка" : "Редактировать закладку")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

            Spacer()

            Button {
                MiodiHapticFeedback.lightClick()
                onDismiss()
            } label: {
                Circle()
                    .fill(isDark ? Color(hex: 0x334155) : Color(hex: 0xF1F5F9))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("✕")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Tab Name Section
    private var tabNameSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Название закладки")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

            HStack {
                TextField("Например: Учёба, Проекты...", text: $title)
                    .font(.system(size: 14))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
                    .onChange(of: title) { _, newVal in
                        if newVal.count > 20 {
                            title = String(newVal.prefix(20))
                        }
                    }

                if !title.isEmpty {
                    Button {
                        title = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0x94A3B8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Color Palette Section (21 colors in 3 rows of 7)
    private var colorPaletteSectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Цвет закладки и листа")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

            VStack(spacing: 10) {
                ForEach(0..<3) { rowIndex in
                    let startIndex = rowIndex * 7
                    let endIndex = min(startIndex + 7, TAB_PALETTE.count)
                    let rowSlice = TAB_PALETTE[startIndex..<endIndex]

                    HStack(spacing: 0) {
                        ForEach(Array(rowSlice)) { colorDef in
                            let isSelected = (selectedColorId == colorDef.id)

                            Button {
                                MiodiHapticFeedback.selection()
                                selectedColorId = colorDef.id
                            } label: {
                                ZStack {
                                    Circle()
                                        .strokeBorder(
                                            isSelected ? theme.currentAccent.primary : Color(hex: 0xEC4899).opacity(isDark ? 0.35 : 0.22),
                                            lineWidth: isSelected ? 2.5 : 1.0
                                        )
                                        .frame(width: 36, height: 36)

                                    Circle()
                                        .fill(colorDef.swatchColor)
                                        .frame(width: isSelected ? 28 : 34, height: isSelected ? 28 : 34)

                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(
                                                (colorDef.id == "white" || colorDef.id == "cream")
                                                    ? Color(hex: 0x0F172A)
                                                    : Color.white
                                            )
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            if colorDef.id != rowSlice.last?.id {
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pattern Selection (8 Cards)
    private var patternSelectionSectionView: some View {
        let patternList: [(pattern: NotebookPattern, name: String)] = [
            (.lines, "Линейка"),
            (.grid, "Клетка"),
            (.dots, "Точки"),
            (.blank, "Чистый лист"),
            (.music, "Нотный стан"),
            (.englishGrid, "Сейес"),
            (.millimeter, "Миллиметровка"),
            (.slantLines, "Косая")
        ]

        let selectedColorDef = getTabColorDef(idOrHex: selectedColorId)
        let sheetColor = isDark ? selectedColorDef.darkSheetBg : selectedColorDef.sheetBg

        return VStack(alignment: .leading, spacing: 10) {
            Text("Разлиновка листа")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(patternList, id: \.pattern.rawValue) { item in
                    let isSelected = (selectedPattern == item.pattern)

                    Button {
                        MiodiHapticFeedback.selection()
                        selectedPattern = item.pattern
                    } label: {
                        VStack(spacing: 6) {
                            // Thumbnail Preview Box
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(sheetColor)

                                // Mini Canvas preview
                                NotebookCanvasView(
                                    patternType: item.pattern,
                                    patternSize: 16.0,
                                    marginLineX: 0,
                                    scrollY: 0,
                                    agingDays: 0,
                                    isDarkTheme: isDark,
                                    backgroundColor: sheetColor,
                                    drawBackground: false
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                if isSelected {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.currentAccent.primary, lineWidth: 2.5)

                                    VStack {
                                        HStack {
                                            Spacer()
                                            Circle()
                                                .fill(theme.currentAccent.primary)
                                                .frame(width: 16, height: 16)
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundStyle(.white)
                                                )
                                                .padding(3)
                                        }
                                        Spacer()
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0), lineWidth: 1)
                                }
                            }
                            .frame(height: 52)

                            Text(item.name)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(
                                    isSelected
                                        ? theme.currentAccent.primary
                                        : (isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x475569))
                                )
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Pattern Size Slider (18px - 48px)
    private var patternSizeSliderView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Шаг разлиновки")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

                Spacer()

                // ✨ Авто button (resets to 26px)
                Button {
                    MiodiHapticFeedback.lightClick()
                    patternSize = 26.0
                } label: {
                    HStack(spacing: 4) {
                        Text("✨ Авто")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                Int(patternSize) == 26
                                    ? theme.currentAccent.primary
                                    : (isDark ? Color(hex: 0x261D2B) : Color(hex: 0xFDF2F8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(theme.currentAccent.primary.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(Int(patternSize) == 26 ? Color.white : theme.currentAccent.primary)
                }
                .buttonStyle(.plain)

                // Current px badge
                Text("\(Int(patternSize)) px")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.currentAccent.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDark ? Color(hex: 0x3B1F34) : Color(hex: 0xFDF2F8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(theme.currentAccent.primary.opacity(0.4), lineWidth: 1)
                            )
                    )
            }

            Slider(value: $patternSize, in: 18...48, step: 1)
                .tint(theme.currentAccent.primary)
        }
    }

    // MARK: - Diary Specific Options
    private var diarySpecificOptionsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Оформление личного дневника")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

            // Diary Font Picker
            HStack(spacing: 8) {
                ForEach(["Caveat", "Cormorant", "Inter", "Georgia"], id: \.self) { fontName in
                    let isSel = (selectedDiaryFont == fontName)
                    Button {
                        MiodiHapticFeedback.selection()
                        selectedDiaryFont = fontName
                    } label: {
                        Text(fontName)
                            .font(.system(size: 12, weight: isSel ? .bold : .medium, design: fontName == "Caveat" ? .serif : .default))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        isSel
                                            ? theme.currentAccent.primary.opacity(0.2)
                                            : (isDark ? Color(hex: 0x1E293B) : Color(hex: 0xF8FAFC))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSel ? theme.currentAccent.primary : Color.clear, lineWidth: 1.5)
                                    )
                            )
                            .foregroundStyle(isSel ? theme.currentAccent.primary : (isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x475569)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Paper embossing toggle
            Toggle(isOn: $diaryEmbossing) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Тиснение бумаги")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
                    Text("Аутентичный тактильный микрорельеф бумажного волокна")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0x94A3B8))
                }
            }
            .tint(theme.currentAccent.primary)
        }
        .padding(.top, 6)
    }

    // MARK: - Delete Tab Button
    private var deleteTabButtonView: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            isConfirmDeleteOpen = true
        } label: {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .bold))
                Text("Удалить закладку")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(Color(hex: 0xEF4444))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDark ? Color(hex: 0x2E1920) : Color(hex: 0xFEF2F2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xEF4444).opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons
    private var actionButtonsRowView: some View {
        HStack(spacing: 12) {
            // Cancel
            Button {
                MiodiHapticFeedback.lightClick()
                onDismiss()
            } label: {
                Text("Отмена")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xEC4899).opacity(isDark ? 0.35 : 0.22), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            // Save
            Button {
                saveTab()
            } label: {
                Text("Сохранить")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.currentAccent.primary)
                            .shadow(color: theme.currentAccent.primary.opacity(0.35), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
    }

    private func saveTab() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = trimmed.isEmpty ? (tab?.title ?? "Без названия") : trimmed

        MiodiHapticFeedback.success()
        onSave(
            resolvedTitle,
            selectedColorId,
            selectedPattern.rawValue,
            Int(patternSize)
        )
        onDismiss()
    }
}
