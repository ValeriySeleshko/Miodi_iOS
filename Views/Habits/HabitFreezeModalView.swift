//
//  HabitFreezeModalView.swift
//  Plan4U_iOS
//
//  Vacation / Sick / Travel Habit Freeze Modal.
//  Preserves habits streaks across break periods by marking dates with ❄ (frozen).
//

import SwiftUI
import SwiftData

public struct HabitFreezeModalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \HabitItem.orderIndex) private var allHabits: [HabitItem]
    @Query private var allEntries: [HabitEntryItem]

    public var preselectedHabitId: String?
    public var onFreezeApplied: (() -> Void)?

    // State
    @State private var freezeAllHabits: Bool = true
    @State private var selectedHabitIds: Set<String> = []
    @State private var selectedReason: FreezeReason = .vacation
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()
    @State private var isCustomDateRange: Bool = false
    @State private var quickRangeDays: Int = 7

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()

    public enum FreezeReason: String, CaseIterable, Identifiable {
        case vacation = "Отпуск 🏖️"
        case sick = "Болезнь 🤒"
        case travel = "Поездка ✈️"
        case rest = "Перезагрузка 🧘"

        public var id: String { rawValue }
    }

    public init(preselectedHabitId: String? = nil, onFreezeApplied: (() -> Void)? = nil) {
        self.preselectedHabitId = preselectedHabitId
        self.onFreezeApplied = onFreezeApplied
    }

    // Active frozen entries for inspection
    private var activeFrozenEntries: [HabitEntryItem] {
        let todayStr = isoFormatter.string(from: Date())
        return allEntries.filter { $0.status == "frozen" && $0.date >= todayStr }
            .sorted(by: { $0.date < $1.date })
    }

    private var targetHabits: [HabitItem] {
        if freezeAllHabits {
            return allHabits
        } else {
            return allHabits.filter { selectedHabitIds.contains($0.id) }
        }
    }

    private var dateRangeDates: [String] {
        var result: [String] = []
        let cal = Calendar.current
        var cur = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)

        while cur <= end {
            result.append(isoFormatter.string(from: cur))
            guard let next = cal.date(byAdding: .day, value: 1, to: cur) else { break }
            cur = next
        }
        return result
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x0B1220) : Color(hex: 0xF0F9FF))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Frosty Header Card
                        headerCard

                        // Scope & Habits Selection Card
                        scopeSectionCard

                        // Reason Preset Card
                        reasonSectionCard

                        // Date Range Card
                        dateRangeCard

                        // Summary Pill
                        summaryCard

                        // Apply Button
                        applyFreezeButton

                        // Active Freezes (if any exist)
                        if !activeFrozenEntries.isEmpty {
                            activeFreezesCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Заморозка привычек")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .onAppear {
                if let preselected = preselectedHabitId {
                    freezeAllHabits = false
                    selectedHabitIds = [preselected]
                } else {
                    freezeAllHabits = true
                    selectedHabitIds = Set(allHabits.map { $0.id })
                }
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x38BDF8).opacity(0.18))
                    .frame(width: 68, height: 68)

                Text("❄️")
                    .font(.system(size: 34))
            }

            Text("Режим сохранения серии")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

            Text("Заморозка защищает ваши цепочки побед во время отпуска или недомогания. Дни отметятся снежинкой ❄ и не сломают статистику!")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x475569))
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDark ? Color(hex: 0x111C30) : Color.white)
                .shadow(color: Color(hex: 0x38BDF8).opacity(0.12), radius: 10, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0x38BDF8).opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Scope Section Card
    private var scopeSectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("КАКИЕ ПРИВЫЧКИ ЗАМОРОЗИТЬ")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: 0x0284C7))
                .tracking(0.5)

            // "Все привычки" toggle
            Toggle(isOn: $freezeAllHabits.animation(.spring(response: 0.25))) {
                HStack(spacing: 10) {
                    Text("🌟")
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Все активные привычки")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                        Text("\(allHabits.count) привычек в списке")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(Color(hex: 0x0284C7))

            // If not all, individual checkboxes
            if !freezeAllHabits {
                Divider()

                VStack(spacing: 8) {
                    ForEach(allHabits) { habit in
                        let isSelected = selectedHabitIds.contains(habit.id)
                        Button {
                            if isSelected {
                                selectedHabitIds.remove(habit.id)
                            } else {
                                selectedHabitIds.insert(habit.id)
                            }
                            MiodiHapticFeedback.selection()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(isSelected ? Color(hex: 0x0284C7) : .secondary)

                                Text(habit.title)
                                    .font(.system(size: 13.5, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                                Spacer()

                                if habit.type == "numeric" {
                                    Text("🎯 \(HabitNumericStepperSheet.formatValue(habit.targetValue)) \(habit.targetUnit)")
                                        .font(.system(size: 10.5))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Reason Preset Card
    private var reasonSectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ПРИЧИНА ЗАМОРОЗКИ")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: 0x0284C7))
                .tracking(0.5)

            HStack(spacing: 6) {
                ForEach(FreezeReason.allCases) { reason in
                    let isSel = selectedReason == reason
                    Button {
                        selectedReason = reason
                        MiodiHapticFeedback.selection()
                    } label: {
                        Text(reason.rawValue)
                            .font(.system(size: 11, weight: isSel ? .bold : .medium))
                            .foregroundStyle(isSel ? .white : (isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x334155)))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSel
                                    ? Color(hex: 0x0284C7)
                                    : (isDark ? Color(hex: 0x1E293B) : Color(hex: 0xE0F2FE))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Date Range Card
    private var dateRangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ПЕРИОД ЗАМОРОЗКИ")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: 0x0284C7))
                .tracking(0.5)

            // Quick preset pills
            HStack(spacing: 6) {
                quickRangePill(label: "Сегодня", days: 1)
                quickRangePill(label: "3 дня", days: 3)
                quickRangePill(label: "Неделя", days: 7)
                quickRangePill(label: "14 дней", days: 14)
            }

            Divider()

            // Custom Range Pickers
            VStack(spacing: 8) {
                HStack {
                    Text("С даты:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x475569))

                    Spacer()

                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: startDate) { _, newStart in
                            if endDate < newStart {
                                endDate = newStart
                            }
                        }
                }

                HStack {
                    Text("По дату:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x475569))

                    Spacer()

                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func quickRangePill(label: String, days: Int) -> some View {
        let isSel = quickRangeDays == days
        return Button {
            quickRangeDays = days
            startDate = Date()
            endDate = Calendar.current.date(byAdding: .day, value: days - 1, to: Date()) ?? Date()
            MiodiHapticFeedback.selection()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: isSel ? .bold : .medium))
                .foregroundStyle(isSel ? .white : Color(hex: 0x0284C7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSel ? Color(hex: 0x0284C7) : Color(hex: 0x38BDF8).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: 0x0284C7))

            VStack(alignment: .leading, spacing: 2) {
                Text("Заморозка \(targetHabits.count) привычек на \(dateRangeDates.count) дн.")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                Text("С \(displayDateFormatter.string(from: startDate)) по \(displayDateFormatter.string(from: endDate)) • Серия в безопасности")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0x0284C7).opacity(0.12))
        )
    }

    // MARK: - Apply Button
    private var applyFreezeButton: some View {
        Button {
            applyFreeze()
        } label: {
            HStack(spacing: 8) {
                Text("❄️")
                Text("Активировать заморозку")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x0284C7), Color(hex: 0x0369A1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color(hex: 0x0284C7).opacity(0.35), radius: 8, y: 3)
        }
        .disabled(targetHabits.isEmpty || dateRangeDates.isEmpty)
        .opacity(targetHabits.isEmpty || dateRangeDates.isEmpty ? 0.5 : 1.0)
    }

    // MARK: - Active Freezes Card
    private var activeFreezesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ТЕКУЩИЕ ЗАМОРОЖЕННЫЕ ДНИ")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: 0x0284C7))
                .tracking(0.5)

            ForEach(activeFrozenEntries.prefix(6)) { entry in
                let habit = allHabits.first { $0.id == entry.habitId }
                HStack {
                    Text("❄️")
                    Text(entry.date)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    Text("—")
                        .foregroundStyle(.secondary)
                    Text(habit?.title ?? "Привычка")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Spacer()

                    Button("Разморозить") {
                        unfreezeEntry(entry)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xEF4444))
                }
                .padding(.vertical, 3)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Persistence Actions
    private func applyFreeze() {
        let dates = dateRangeDates
        let habits = targetHabits

        for habit in habits {
            for dateStr in dates {
                if let existing = allEntries.first(where: { $0.habitId == habit.id && $0.date == dateStr }) {
                    existing.status = "frozen"
                    existing.isCompleted = false
                    existing.value = 0
                    existing.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
                } else {
                    let entry = HabitEntryItem(
                        id: "\(habit.id)_\(dateStr)",
                        habitId: habit.id,
                        date: dateStr,
                        value: 0,
                        isCompleted: false,
                        status: "frozen"
                    )
                    modelContext.insert(entry)
                }
            }
        }

        try? modelContext.save()
        MiodiHapticFeedback.iceFreeze()
        onFreezeApplied?()
        dismiss()
    }

    private func unfreezeEntry(_ entry: HabitEntryItem) {
        modelContext.delete(entry)
        try? modelContext.save()
        MiodiHapticFeedback.lightClick()
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isDark ? Color(hex: 0x111C30) : Color.white)
            .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 6, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isDark ? Color(hex: 0x1E2E4A) : Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}
