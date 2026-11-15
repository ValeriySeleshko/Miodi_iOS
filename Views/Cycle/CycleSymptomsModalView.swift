//
//  CycleSymptomsModalView.swift
//  Plan4U_iOS
//
//  Complete Symptoms & Mood Tracking Sheet matching Android CycleMoodDialog & CycleModal.kt
//  Flow intensity, Physical symptoms checklist, Mood chips, and Custom Notes.
//

import SwiftUI
import SwiftData

public struct CycleSymptomsModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public var selectedDateStr: String
    public var onSave: (() -> Void)?

    @State private var flow: FlowIntensity = .none
    @State private var selectedMoods: Set<String> = []
    @State private var selectedSymptoms: Set<String> = []
    @State private var customNote: String = ""
    @State private var targetDate: Date = Date()

    @Query(sort: \CycleItem.startDate, order: .reverse) private var cycleHistory: [CycleItem]

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init(selectedDateStr: String = CycleEngine.getTodayString(), onSave: (() -> Void)? = nil) {
        self.selectedDateStr = selectedDateStr
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x0F172A) : Color(hex: 0xFDF4F8))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Date Bar
                        dateHeaderSection

                        // 1. Flow Intensity
                        flowIntensitySection

                        // 2. Mood Chips
                        moodSection

                        // 3. Physical Symptoms Checklist
                        physicalSymptomsSection

                        // 4. Custom Note
                        notesSection

                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Самочувствие и симптомы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveRecord()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFB7185))
                }
            }
            .onAppear {
                loadExistingRecord()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Date Header
    private var dateHeaderSection: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(Color(hex: 0xFB7185))
            Text("Дата записи:")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            DatePicker("", selection: $targetDate, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .onChange(of: targetDate) { _, newDate in
                    let newDateStr = isoFormatter.string(from: newDate)
                    loadRecordForDate(newDateStr)
                }
        }
        .padding(12)
        .background(cardBackground)
    }

    // MARK: - 1. Flow Intensity
    private var flowIntensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🩸")
                Text("Интенсивность выделений")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(FlowIntensity.allCases) { item in
                    let isSelected = (flow == item)

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            flow = item
                        }
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : item.color)

                            Text(item.titleRu)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? .white : (isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569)))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? item.color : (isDark ? Color(hex: 0x1E293B) : Color.white))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? item.color : (isDark ? Color(hex: 0x334155) : Color.black.opacity(0.08)), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 2. Mood Chips
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🌸")
                Text("Настроение и эмоции")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
                if !selectedMoods.isEmpty {
                    Text("\(selectedMoods.count) выбр.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xFB7185))
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(CycleMoodItem.allMoods) { mood in
                    let isSelected = selectedMoods.contains(mood.title)
                    let chipColor = Color(hex: mood.colorHex)

                    Button {
                        toggleMood(mood.title)
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        HStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 14))
                            Text(mood.title)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? .white : (isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E293B)))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? chipColor : (isDark ? Color(hex: 0x1E293B) : Color.white))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? chipColor : (isDark ? Color(hex: 0x334155) : Color.black.opacity(0.08)), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 3. Physical Symptoms Checklist
    private var physicalSymptomsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("💆‍♀️")
                Text("Физические симптомы")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
                if !selectedSymptoms.isEmpty {
                    Text("\(selectedSymptoms.count) выбр.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xFB7185))
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                ForEach(CycleSymptomItem.allSymptoms) { sym in
                    let isSelected = selectedSymptoms.contains(sym.title)

                    Button {
                        toggleSymptom(sym.title)
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        HStack(spacing: 8) {
                            Text(sym.emoji)
                                .font(.system(size: 15))

                            Text(sym.title)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color(hex: 0xFB7185) : (isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E293B)))
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 15))
                                .foregroundStyle(isSelected ? Color(hex: 0xFB7185) : Color.secondary.opacity(0.4))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? Color(hex: 0xFB7185).opacity(0.12) : (isDark ? Color(hex: 0x1E293B) : Color.white))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? Color(hex: 0xFB7185) : (isDark ? Color(hex: 0x334155) : Color.black.opacity(0.08)), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 4. Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📝")
                Text("Личные заметки")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
            }

            TextField("Самочувствие, триггеры, мысли...", text: $customNote, axis: .vertical)
                .font(.system(size: 14))
                .lineLimit(3...6)
                .padding(12)
                .background(isDark ? Color(hex: 0x141B2D) : Color(hex: 0xF8FAFC))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isDark ? Color(hex: 0x334155) : Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isDark ? Color(hex: 0x2A3347) : Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 6, y: 2)
    }

    // MARK: - Logic
    private func toggleMood(_ mood: String) {
        if selectedMoods.contains(mood) {
            selectedMoods.remove(mood)
        } else {
            selectedMoods.insert(mood)
        }
    }

    private func toggleSymptom(_ sym: String) {
        if selectedSymptoms.contains(sym) {
            selectedSymptoms.remove(sym)
        } else {
            selectedSymptoms.insert(sym)
        }
    }

    private func loadExistingRecord() {
        if let d = isoFormatter.date(from: selectedDateStr) {
            targetDate = d
        }
        loadRecordForDate(selectedDateStr)
    }

    private func loadRecordForDate(_ dateStr: String) {
        if let existing = CycleSettingsStore.shared.getSymptomRecord(for: dateStr) {
            flow = existing.flow
            selectedMoods = Set(existing.moods)
            selectedSymptoms = Set(existing.symptoms)
            customNote = existing.note
        } else {
            flow = .none
            selectedMoods = []
            selectedSymptoms = []
            customNote = ""
        }
    }

    private func saveRecord() {
        let dateStr = isoFormatter.string(from: targetDate)
        let record = DailySymptomRecord(
            date: dateStr,
            flow: flow,
            moods: Array(selectedMoods),
            symptoms: Array(selectedSymptoms),
            note: customNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        CycleSettingsStore.shared.saveSymptomRecord(record)

        // Also update matching CycleItem note for compatibility with Android database & export
        let activeCycle = cycleHistory.first { cycle in
            let end = cycle.endDate ?? CycleEngine.addDays(to: cycle.startDate, n: 10)
            return dateStr >= cycle.startDate && dateStr <= end
        } ?? cycleHistory.first

        if let cycle = activeCycle {
            let noteTag = "[\(dateStr)] \(record.summaryDescription)"
            let currentNotes = cycle.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if currentNotes.isEmpty {
                cycle.note = noteTag
            } else if currentNotes.contains("[\(dateStr)]") {
                cycle.note = currentNotes.components(separatedBy: "\n").map { line in
                    line.hasPrefix("[\(dateStr)]") ? noteTag : line
                }.joined(separator: "\n")
            } else {
                cycle.note = "\(currentNotes)\n\(noteTag)"
            }
            try? modelContext.save()
        }

        MiodiHapticFeedback.success()
        onSave?()
    }
}
