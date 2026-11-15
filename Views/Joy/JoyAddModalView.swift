//
//  JoyAddModalView.swift
//  Plan4U_iOS
//
//  Quick entry modal for Joy of the Day with authentic emoji mood selector,
//  20-step vertical mood slider, 25 paper sticker picker, handwritten note text,
//  inspiration prompt questions, and adaptive placeholders.
//  100% parity with Android JoyModal.kt.
//

import SwiftUI
import SwiftData

public struct JoyAddModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public var existingJoy: JoyItem?
    public var targetDate: String
    public var onSaved: ((JoyItem) -> Void)?

    @State private var noteText: String = ""
    @State private var currentMoodStep: Int = 3 // default ☀️ Joyful
    @State private var selectedStickerAsset: String = "stickers/paper/paper_17.webp"
    @State private var isStickerPickerPresented: Bool = false
    @State private var showConceptHelp: Bool = false
    @State private var currentPromptText: String? = nil
    @State private var lastPromptIndex: Int = -1
    @State private var showAdvancedMoodSlider: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let maxCharacters: Int = 75

    public init(
        existingJoy: JoyItem? = nil,
        targetDate: String = Date().yyyyMMddString,
        onSaved: ((JoyItem) -> Void)? = nil
    ) {
        self.existingJoy = existingJoy
        self.targetDate = targetDate
        self.onSaved = onSaved
    }

    private var currentMood: JoyMood {
        JoyMoodCatalog.getMood(step: currentMoodStep)
    }

    private var adaptivePlaceholder: String {
        if currentMoodStep >= 14 {
            return "День был непростым. Было ли хоть что-то маленькое, что согрело или помогло справиться?"
        } else if currentMoodStep >= 8 {
            return "За какую приятную мелочь хочется сказать спасибо сегодня?"
        } else {
            return "Какое яркое или радостное событие согрело сегодня душу?"
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x14171F) : Color.white)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header info
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("За что я благодарен сегодня?")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

                                Text(existingJoy != nil ? "Редактирование радости" : "Запишите светлый момент дня")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Concept help button
                            Button {
                                MiodiHapticFeedback.lightClick()
                                showConceptHelp = true
                            } label: {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: 0xD97706))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(isDark ? Color(hex: 0x2A2318) : Color(hex: 0xFEF3C7))
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // 1. Quick Emoji Mood Row (☀️, ☕️, 😊, 🫂, 🌿, ✨, 💖, 🌸)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Настроение момента:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showAdvancedMoodSlider.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(currentMood.titleRu)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(theme.currentAccent.primary)
                                        Image(systemName: showAdvancedMoodSlider ? "chevron.up" : "slider.vertical.3")
                                            .font(.system(size: 11))
                                            .foregroundStyle(theme.currentAccent.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(theme.currentAccent.primary.opacity(0.12)))
                                }
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(JoyMoodCatalog.quickPresets) { preset in
                                        let isSelected = (currentMoodStep == preset.step)
                                        Button {
                                            MiodiHapticFeedback.moodStepTick()
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                                currentMoodStep = preset.step
                                            }
                                        } label: {
                                            VStack(spacing: 3) {
                                                Text(preset.emoji)
                                                    .font(.system(size: 22))
                                                    .scaleEffect(isSelected ? 1.15 : 1.0)
                                                Text(preset.title)
                                                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                                    .foregroundStyle(isSelected ? (isDark ? .white : Color(hex: 0x0F172A)) : .secondary)
                                            }
                                            .frame(width: 58, height: 60)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(
                                                        isSelected
                                                            ? preset.color.opacity(isDark ? 0.35 : 0.20)
                                                            : (isDark ? Color(hex: 0x1E2430) : Color(hex: 0xF8FAFC))
                                                    )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(
                                                        isSelected ? preset.color : (isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE2E8F0)),
                                                        lineWidth: isSelected ? 2 : 1
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.horizontal, 16)

                        // 2. Expandable 20-Step Mood Scrubber
                        if showAdvancedMoodSlider {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Шкала настроения (шаг \(currentMoodStep) из 20)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(currentMood.emoji + " " + currentMood.titleRu)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                                }

                                Slider(
                                    value: Binding(
                                        get: { Double(currentMoodStep) },
                                        set: { newVal in
                                            let step = Int(newVal.rounded())
                                            if step != currentMoodStep {
                                                currentMoodStep = step
                                                MiodiHapticFeedback.moodStepTick()
                                            }
                                        }
                                    ),
                                    in: 1...20,
                                    step: 1
                                )
                                .tint(
                                    currentMoodStep <= 5 ? Color(hex: 0xF59E0B) :
                                    currentMoodStep <= 10 ? Color(hex: 0xEC4899) :
                                    currentMoodStep <= 15 ? Color(hex: 0x38BDF8) : Color(hex: 0x64748B)
                                )

                                HStack {
                                    Text("✨ Восторг")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color(hex: 0xF59E0B))
                                    Spacer()
                                    Text("😐 В норме")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("💔 Грусть")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color(hex: 0x64748B))
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDark ? Color(hex: 0x1A1F2B) : Color(hex: 0xF1F5F9))
                            )
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // 3. Central Paper Sticker Note (with warm sunlight glow)
                        ZStack(alignment: .topLeading) {
                            // Realistic paper backdrop with authentic shadows
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: 0xFFFDF0),
                                                Color(hex: 0xFFF9E6),
                                                Color(hex: 0xFFF4D4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color(hex: 0xF59E0B).opacity(isDark ? 0.25 : 0.35), radius: 14, x: 0, y: 6)
                                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.08), radius: 6, x: 0, y: 2)

                                // Notebook faint ruled lines for authentic handwritten feel
                                VStack(spacing: 20) {
                                    ForEach(0..<6) { _ in
                                        Divider()
                                            .background(Color(hex: 0xEADBC8).opacity(0.6))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 24)

                                // Text input area
                                ZStack {
                                    if noteText.isEmpty {
                                        Text(adaptivePlaceholder)
                                            .font(.system(size: 16, design: .serif))
                                            .foregroundStyle(Color(hex: 0x78716C).opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    }

                                    TextEditor(text: $noteText)
                                        .scrollContentBackground(.hidden)
                                        .font(.system(size: 18, weight: .medium, design: .serif))
                                        .foregroundStyle(Color(hex: 0x1C1917))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 24)
                                        .onChange(of: noteText) { _, newVal in
                                            if newVal.count > maxCharacters {
                                                noteText = String(newVal.prefix(maxCharacters))
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)

                            // Sticker texture change button
                            Button {
                                MiodiHapticFeedback.lightClick()
                                isStickerPickerPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("🎨")
                                        .font(.system(size: 12))
                                    Text("Стикер")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x78350F))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.92)))
                                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                            }
                            .padding(10)

                            // Current mood icon badge on top right
                            HStack {
                                Spacer()
                                Text(currentMood.emoji)
                                    .font(.system(size: 20))
                                    .padding(6)
                                    .background(Circle().fill(Color.white.opacity(0.9)))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .padding(10)
                        }
                        .padding(.horizontal, 16)

                        // 4. Sub-bar: "💡 Не знаю, что написать" button + Counter
                        HStack {
                            Button {
                                MiodiHapticFeedback.lightClick()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    let (idx, text) = JoyPromptsData.randomPrompt(excludeIndex: lastPromptIndex)
                                    lastPromptIndex = idx
                                    currentPromptText = text
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("💡")
                                    Text("Не знаю, что написать")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(Color(hex: 0xD97706))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: 0xD97706).opacity(0.12))
                                )
                            }

                            Spacer()

                            Text("\(noteText.count)/\(maxCharacters)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(noteText.count >= maxCharacters ? Color.red : .secondary)
                        }
                        .padding(.horizontal, 16)

                        // 5. Inspiration Prompt Helper Card
                        if let prompt = currentPromptText {
                            VStack(spacing: 6) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("✨")
                                        .font(.system(size: 14))

                                    Text(prompt)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(isDark ? Color(hex: 0xFCD34D) : Color(hex: 0x92400E))
                                        .lineSpacing(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    // Reroll dice button
                                    Button {
                                        MiodiHapticFeedback.selection()
                                        let (idx, text) = JoyPromptsData.randomPrompt(excludeIndex: lastPromptIndex)
                                        lastPromptIndex = idx
                                        currentPromptText = text
                                    } label: {
                                        Text("🎲")
                                            .font(.system(size: 14))
                                            .padding(4)
                                    }

                                    // Close prompt
                                    Button {
                                        withAnimation {
                                            currentPromptText = nil
                                        }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.secondary)
                                            .padding(4)
                                    }
                                }

                                Button {
                                    noteText = String(prompt.prefix(maxCharacters))
                                    MiodiHapticFeedback.lightClick()
                                    withAnimation { currentPromptText = nil }
                                } label: {
                                    Text("Использовать этот вопрос как заметку")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(hex: 0xD97706))
                                }
                                .padding(.top, 4)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDark ? Color(hex: 0x2A2318) : Color(hex: 0xFFFBEB))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: 0xF59E0B).opacity(0.6), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        Spacer(minLength: 20)

                        // 6. Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Закрыть")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isDark ? Color(hex: 0x1E2430) : Color(hex: 0xF1F5F9))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }

                            Button {
                                saveJoy()
                            } label: {
                                HStack(spacing: 6) {
                                    Text(existingJoy != nil ? "Обновить радость ✨" : "Сохранить радость ✨")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            canSave
                                                ? theme.currentAccent.primary
                                                : theme.currentAccent.primary.opacity(0.4)
                                        )
                                        .shadow(
                                            color: canSave ? theme.currentAccent.primary.opacity(0.35) : .clear,
                                            radius: 8, x: 0, y: 3
                                        )
                                )
                            }
                            .disabled(!canSave)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle(existingJoy != nil ? "Редактировать радость" : "Радость дня")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .sheet(isPresented: $isStickerPickerPresented) {
                stickerPickerView
            }
            .sheet(isPresented: $showConceptHelp) {
                conceptHelpView
            }
            .onAppear {
                if let joy = existingJoy {
                    noteText = joy.text
                    currentMoodStep = JoyMoodCatalog.resolveStep(from: joy.mood)
                    if !joy.sticker.isEmpty {
                        selectedStickerAsset = joy.sticker
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveJoy() {
        guard canSave else { return }
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let moodId = "mood_\(String(format: "%02d", currentMoodStep))"

        if let existing = existingJoy {
            existing.text = trimmed
            existing.mood = moodId
            existing.sticker = selectedStickerAsset
            existing.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            try? modelContext.save()
            MiodiHapticFeedback.success()
            MiodiAudioManager.shared.playDing()
            onSaved?(existing)
        } else {
            let newJoy = JoyItem(
                date: targetDate,
                text: trimmed,
                orderIndex: 0,
                mood: moodId,
                sticker: selectedStickerAsset
            )
            modelContext.insert(newJoy)
            try? modelContext.save()
            MiodiHapticFeedback.success()
            MiodiAudioManager.shared.playDing()
            onSaved?(newJoy)
        }
        dismiss()
    }

    // MARK: - Sticker Picker Sheet (25 Paper Styles)
    private var stickerPickerView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Выберите бумажный стикер для вашей радости:")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 12)], spacing: 12) {
                        ForEach(JoyPaperStickers.allStickers, id: \.self) { asset in
                            let isSelected = (selectedStickerAsset == asset)
                            Button {
                                MiodiHapticFeedback.selection()
                                selectedStickerAsset = asset
                                isStickerPickerPresented = false
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: 0xFFFDF0), Color(hex: 0xFFF4D4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    isSelected ? theme.currentAccent.primary : Color.gray.opacity(0.2),
                                                    lineWidth: isSelected ? 2.5 : 1
                                                )
                                        )

                                    Text("📝")
                                        .font(.system(size: 20))

                                    if isSelected {
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(theme.currentAccent.primary)
                                            }
                                            Spacer()
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Бумажные стикеры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { isStickerPickerPresented = false }
                }
            }
        }
    }

    // MARK: - Concept Help Dialog
    private var conceptHelpView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("🍯 Банка радости и Настроение")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("📊")
                            Text("Слайдер — честное настроение дня")
                                .font(.system(size: 14, weight: .bold))
                        }
                        Text("Не нужно притворяться счастливым, если день выдался тяжёлым. Слайдером вы честно фиксируете эмоцию: от восторга до грусти. Это наполняет график вашего состояния.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isDark ? Color(hex: 0x1E2430) : Color(hex: 0xF8FAFC))
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("🫙")
                            Text("Стикер — лучик света в банку")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: 0xD97706))
                        }
                        Text("Стикер тренирует мозг находить хотя бы одну крошечную опору или благодарность (чашка чая, звонок друга, закат) — даже в трудные дни. Банка хранит эти крупицы тепла, чтобы поддержать вас, когда грустно.")
                            .font(.system(size: 12))
                            .foregroundStyle(isDark ? Color(hex: 0xFDE68A) : Color(hex: 0x78350F))
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isDark ? Color(hex: 0x2A2318) : Color(hex: 0xFFFBEB))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: 0xF59E0B).opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 16)

                Spacer()

                Button {
                    showConceptHelp = false
                } label: {
                    Text("Понятно")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.currentAccent.primary)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { showConceptHelp = false }
                }
            }
        }
    }
}
