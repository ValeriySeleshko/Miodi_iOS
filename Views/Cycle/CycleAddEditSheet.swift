//
//  CycleAddEditSheet.swift
//  Plan4U_iOS
//
//  Complete Cycle Add / Edit Sheet matching Android CycleAddModal.kt 1-to-1
//  Start & end date pickers, explicit period ended toggle, outlier flag,
//  ovulation date tracker, notes, and safety validations.
//

import SwiftUI
import SwiftData

public struct CycleAddEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public var editingItem: CycleItem?
    public var onDismiss: () -> Void

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hasEndDate: Bool = true
    @State private var isOutlier: Bool = false
    @State private var hasOvulationDate: Bool = false
    @State private var ovulationDate: Date = Date()
    @State private var note: String = ""
    @State private var validationWarning: String? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init(editingItem: CycleItem? = nil, onDismiss: @escaping () -> Void) {
        self.editingItem = editingItem
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Dates
                Section(header: Text("Даты менструации")) {
                    DatePicker("Дата начала", selection: $startDate, in: ...Date(), displayedComponents: .date)

                    Toggle("Менструация завершилась", isOn: $hasEndDate)
                        .tint(Color(hex: 0xFB7185))

                    if hasEndDate {
                        DatePicker("Дата окончания", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                    }
                }

                // Section 2: Ovulation Date Tracking
                Section(header: Text("Овуляция")) {
                    Toggle("Отметить дату овуляции", isOn: $hasOvulationDate)
                        .tint(Color(hex: 0xF59E0B))

                    if hasOvulationDate {
                        DatePicker("Дата овуляции", selection: $ovulationDate, in: startDate...Date(), displayedComponents: .date)
                    }
                }

                // Section 3: Cycle Anomalies & Outliers
                Section(header: Text("Особенности цикла")) {
                    Toggle("Сбой / Стресс (выброс)", isOn: $isOutlier)
                        .tint(Color(hex: 0xF59E0B))

                    Text("Исключить эту запись из расчёта будущих прогнозов и средней длительности.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Section 4: Notes
                Section(header: Text("Заметки о самочувствии")) {
                    TextField("Симптомы, препараты, настроение...", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                // Validation Warning if any
                if let warning = validationWarning {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color(hex: 0xF59E0B))
                            Text(warning)
                                .font(.footnote)
                                .foregroundStyle(Color(hex: 0xF59E0B))
                        }
                    }
                }

                // Delete Button if editing
                if let item = editingItem {
                    Section {
                        Button(role: .destructive) {
                            modelContext.delete(item)
                            try? modelContext.save()
                            MiodiHapticFeedback.warning()
                            onDismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Удалить запись", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(editingItem != nil ? "Редактировать запись" : "Новый цикл")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { onDismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if validateAndSave() {
                            onDismiss()
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFB7185))
                }
            }
            .onAppear {
                setupInitialData()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func setupInitialData() {
        if let item = editingItem {
            if let d = isoFormatter.date(from: item.startDate) {
                startDate = d
            }
            if let end = item.endDate, let d = isoFormatter.date(from: end) {
                endDate = d
                hasEndDate = true
            } else {
                hasEndDate = false
            }
            if let ov = item.ovulationDate, let d = isoFormatter.date(from: ov) {
                ovulationDate = d
                hasOvulationDate = true
            } else {
                hasOvulationDate = false
            }
            isOutlier = item.isOutlier
            note = item.note ?? ""
        } else {
            let defaultPeriod = CycleSettingsStore.shared.periodLength
            startDate = Date()
            if let targetEnd = Calendar.current.date(byAdding: .day, value: defaultPeriod - 1, to: Date()), targetEnd <= Date() {
                endDate = targetEnd
                hasEndDate = true
            } else {
                endDate = Date()
                hasEndDate = false
            }
        }
    }

    private func validateAndSave() -> Bool {
        let sStr = isoFormatter.string(from: startDate)
        let eStr = hasEndDate ? isoFormatter.string(from: endDate) : nil
        let ovStr = hasOvulationDate ? isoFormatter.string(from: ovulationDate) : nil

        if let e = eStr, e < sStr {
            validationWarning = "Дата окончания не может быть раньше даты начала."
            MiodiHapticFeedback.warning()
            return false
        }

        if let e = eStr {
            let days = CycleEngine.diffInDays(start: sStr, end: e) + 1
            if days > 14 && !isOutlier {
                validationWarning = "Длительность менструации более 14 дней. Рекомендуем отметить запись как «Сбой/Стресс»."
            }
        }

        if let item = editingItem {
            item.startDate = sStr
            item.endDate = eStr
            item.isOutlier = isOutlier
            item.ovulationDate = ovStr
            item.note = note.isEmpty ? nil : note
        } else {
            let newItem = CycleItem(
                startDate: sStr,
                endDate: eStr,
                cycleLengthDays: CycleSettingsStore.shared.defaultCycleLength,
                periodLengthDays: CycleSettingsStore.shared.periodLength,
                isOutlier: isOutlier,
                ovulationDate: ovStr,
                note: note.isEmpty ? nil : note
            )
            modelContext.insert(newItem)
        }

        try? modelContext.save()
        MiodiHapticFeedback.success()
        return true
    }
}
