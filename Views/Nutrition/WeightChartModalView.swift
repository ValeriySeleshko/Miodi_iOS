//
//  WeightChartModalView.swift
//  Plan4U_iOS
//
//  Interactive Weight Tracker: SwiftUI Charts, Linear Trend Line, BMI / ИМТ Calculation,
//  Periods (1M, 3M, 1Y, All), Quick Weigh-in, and History with Deltas.
//

import SwiftUI
import SwiftData
import Charts

public struct WeightChartModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \WeightEntryItem.date, order: .reverse) private var weightEntries: [WeightEntryItem]

    private var prefs: NutritionPreferences { NutritionPreferences.shared }

    @State private var selectedPeriod: Int = 0 // 0: 1 мес, 1: 3 мес, 2: 1 год, 3: Все
    @State private var selectedDate: Date = Date()
    @State private var inputWeightStr: String = ""
    @State private var noteStr: String = ""
    @State private var showSavedToast: Bool = false
    @State private var selectedChartEntry: WeightEntryItem? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var latestWeight: Double {
        weightEntries.first?.weightKg ?? prefs.weightKg
    }

    private var targetWeight: Double {
        prefs.targetWeightKg
    }

    private var bmiValue: Double {
        NutritionPreferences.calculateBMI(weightKg: latestWeight, heightCm: prefs.heightCm)
    }

    private var bmiCategory: BMICategory {
        NutritionPreferences.getBMICategory(bmi: bmiValue)
    }

    private var healthyRange: (minKg: Double, maxKg: Double) {
        NutritionPreferences.healthyWeightRange(heightCm: prefs.heightCm)
    }

    // Filtered entries for selected period (ordered ascending for charts)
    private var chartEntries: [WeightEntryItem] {
        let sorted = weightEntries.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        let calendar = Calendar.current
        let now = Date()
        let cutoffDate: Date?

        switch selectedPeriod {
        case 0: cutoffDate = calendar.date(byAdding: .month, value: -1, to: now)
        case 1: cutoffDate = calendar.date(byAdding: .month, value: -3, to: now)
        case 2: cutoffDate = calendar.date(byAdding: .year, value: -1, to: now)
        default: cutoffDate = nil
        }

        guard let cutoff = cutoffDate else { return sorted }
        let cutoffStr = cutoff.yyyyMMddString
        let filtered = sorted.filter { $0.date >= cutoffStr }
        return filtered.isEmpty ? sorted : filtered
    }

    // Linear trend points (start and end)
    private var trendLine: (start: (date: Date, val: Double), end: (date: Date, val: Double))? {
        let entries = chartEntries
        guard entries.count >= 2 else { return nil }

        let points = entries.compactMap { entry -> (x: Double, y: Double, date: Date)? in
            guard let d = Date.from(yyyyMMdd: entry.date) else { return nil }
            return (d.timeIntervalSince1970, entry.weightKg, d)
        }
        guard points.count >= 2 else { return nil }

        let n = Double(points.count)
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        let sumXY = points.reduce(0.0) { $0 + ($1.x * $1.y) }
        let sumX2 = points.reduce(0.0) { $0 + ($1.x * $1.x) }

        let denominator = (n * sumX2 - sumX * sumX)
        guard denominator != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        let first = points.first!
        let last = points.last!
        let yStart = slope * first.x + intercept
        let yEnd = slope * last.x + intercept

        return (start: (first.date, yStart), end: (last.date, yEnd))
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Metric Cards (Current, Target, Remaining, BMI)
                    HStack(spacing: 8) {
                        MetricCard(
                            icon: "⚖️",
                            title: String(format: "%.1f кг", latestWeight),
                            subtitle: weightEntries.first != nil ? (Date.from(yyyyMMdd: weightEntries.first!.date)?.userFriendlyDateString() ?? "Текущий") : "Текущий вес",
                            accent: theme.currentAccent.primary,
                            isDark: isDark
                        )

                        MetricCard(
                            icon: "🎯",
                            title: String(format: "%.1f кг", targetWeight),
                            subtitle: "Цель",
                            accent: theme.currentAccent.primary,
                            isDark: isDark
                        )

                        let diff = latestWeight - targetWeight
                        let absDiff = abs(diff)
                        let isGoalReached = absDiff <= 0.2
                        MetricCard(
                            icon: isGoalReached ? "🎉" : (diff > 0 ? "📉" : "📈"),
                            title: isGoalReached ? "Достигнуто!" : String(format: "%@%.1f кг", diff > 0 ? "-" : "+", absDiff),
                            subtitle: isGoalReached ? "Поздравляем!" : "Осталось",
                            accent: isGoalReached ? Color(hex: 0x10B981) : theme.currentAccent.primary,
                            isDark: isDark
                        )
                    }

                    // BMI / ИМТ Card
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("ИМТ:")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f", bmiValue))
                                    .font(.system(size: 16, weight: .black))
                                Text(bmiCategory.title)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(bmiCategory.color.opacity(0.15))
                                    .foregroundStyle(bmiCategory.color)
                                    .clipShape(Capsule())
                            }
                            Text("Здоровый диапазон веса для роста \(Int(prefs.heightCm)) см: \(String(format: "%.1f – %.1f кг", healthyRange.minKg, healthyRange.maxKg))")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(bmiCategory.color.opacity(0.3), lineWidth: 1))

                    // 2. Quick Weigh-in Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Внести измерение веса", systemImage: "pencil.and.list.clipboard")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                            Spacer()
                            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }

                        // Stepper + Input
                        HStack(spacing: 12) {
                            Button {
                                adjustInputWeight(by: -0.1)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(theme.currentAccent.primary)
                            }

                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                TextField("60.0", text: $inputWeightStr)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 26, weight: .black))
                                    .frame(maxWidth: 120)
                                Text("кг")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(theme.currentAccent.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button {
                                adjustInputWeight(by: 0.1)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(theme.currentAccent.primary)
                            }
                        }

                        // Optional Note Input
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                            TextField("Заметка (натощак, после пробежки...)", text: $noteStr)
                                .font(.system(size: 13))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Save Button
                        Button {
                            saveWeight()
                        } label: {
                            Text("Записать вес")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(theme.currentAccent.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        if showSavedToast {
                            HStack {
                                Spacer()
                                Label("Вес успешно сохранён", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x10B981))
                                Spacer()
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(14)
                    .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1))

                    // 3. Interactive Chart (SwiftUI Charts)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Динамика веса")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()

                            // Period Filter
                            Picker("Период", selection: $selectedPeriod) {
                                Text("1 мес").tag(0)
                                Text("3 мес").tag(1)
                                Text("1 год").tag(2)
                                Text("Все").tag(3)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 190)
                        }

                        if chartEntries.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                Text("Нет записей веса за выбранный период")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                        } else {
                            // Selected entry details banner
                            if let selected = selectedChartEntry ?? chartEntries.last {
                                HStack {
                                    Text(Date.from(yyyyMMdd: selected.date)?.userFriendlyDateString() ?? selected.date)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Text(String(format: "%.1f кг", selected.weightKg))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(theme.currentAccent.primary)
                                        if let note = selected.note, !note.isEmpty {
                                            Text("(\(note))")
                                                .font(.system(size: 11))
                                                .italic()
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(theme.currentAccent.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            // SwiftUI Charts
                            let allWeights = chartEntries.map { $0.weightKg } + [targetWeight]
                            let minW = max(20.0, (allWeights.min() ?? 50.0) - 2.0)
                            let maxW = min(250.0, (allWeights.max() ?? 80.0) + 2.0)

                            Chart {
                                // Target Weight Reference Line
                                RuleMark(y: .value("Цель", targetWeight))
                                    .foregroundStyle(Color(hex: 0x10B981))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                    .annotation(position: .top, alignment: .trailing) {
                                        Text(String(format: "Цель: %.1f кг", targetWeight))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color(hex: 0x10B981))
                                            .padding(.horizontal, 4)
                                            .background(Color.white.opacity(0.8))
                                    }

                                // Area Gradient
                                ForEach(chartEntries) { entry in
                                    if let dateObj = Date.from(yyyyMMdd: entry.date) {
                                        AreaMark(
                                            x: .value("Дата", dateObj),
                                            y: .value("Вес", entry.weightKg)
                                        )
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [theme.currentAccent.primary.opacity(0.25), Color.clear],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    }
                                }

                                // Spline Line
                                ForEach(chartEntries) { entry in
                                    if let dateObj = Date.from(yyyyMMdd: entry.date) {
                                        LineMark(
                                            x: .value("Дата", dateObj),
                                            y: .value("Вес", entry.weightKg)
                                        )
                                        .foregroundStyle(theme.currentAccent.primary)
                                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                                        PointMark(
                                            x: .value("Дата", dateObj),
                                            y: .value("Вес", entry.weightKg)
                                        )
                                        .symbolSize(36)
                                        .foregroundStyle(theme.currentAccent.primary)
                                    }
                                }

                                // Linear Trend Line
                                if let trend = trendLine {
                                    LineMark(
                                        x: .value("Дата", trend.start.date),
                                        y: .value("Тренд", trend.start.val)
                                    )
                                    .foregroundStyle(Color(hex: 0x8B5CF6))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                                    LineMark(
                                        x: .value("Дата", trend.end.date),
                                        y: .value("Тренд", trend.end.val)
                                    )
                                    .foregroundStyle(Color(hex: 0x8B5CF6))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                }
                            }
                            .chartYScale(domain: minW...maxW)
                            .frame(height: 200)
                            .chartOverlay { proxy in
                                GeometryReader { geo in
                                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { val in
                                                    let origin = geo[proxy.plotAreaFrame].origin
                                                    let x = val.location.x - origin.x
                                                    if let date: Date = proxy.value(atX: x) {
                                                        findClosestEntry(to: date)
                                                    }
                                                }
                                        )
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1))

                    // 4. Weight History List with Deltas
                    if !weightEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("История измерений (\(weightEntries.count))")
                                .font(.system(size: 14, weight: .bold))

                            VStack(spacing: 8) {
                                ForEach(Array(weightEntries.enumerated()), id: \.element.id) { index, entry in
                                    let prev = weightEntries[safe: index + 1]
                                    let delta = prev != nil ? (entry.weightKg - prev!.weightKg) : nil

                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(Date.from(yyyyMMdd: entry.date)?.userFriendlyDateString() ?? entry.date)
                                                .font(.system(size: 13, weight: .semibold))
                                            if let note = entry.note, !note.isEmpty {
                                                Text(note)
                                                    .font(.system(size: 11))
                                                    .italic()
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        HStack(spacing: 8) {
                                            Text(String(format: "%.1f кг", entry.weightKg))
                                                .font(.system(size: 15, weight: .bold))

                                            if let d = delta {
                                                let isLoss = d < -0.05
                                                let isGain = d > 0.05
                                                let badgeColor: Color = isLoss ? Color(hex: 0x10B981) : (isGain ? Color(hex: 0xF59E0B) : .secondary)
                                                let sign = isGain ? "+" : ""

                                                Text(String(format: "%@%.1f", sign, d))
                                                    .font(.system(size: 10.5, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(badgeColor.opacity(0.15))
                                                    .foregroundStyle(badgeColor)
                                                    .clipShape(Capsule())
                                            }

                                            Button {
                                                deleteEntry(entry)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 13))
                                                    .foregroundStyle(.secondary.opacity(0.6))
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)

                                    if index < weightEntries.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Трекер веса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .onAppear {
                inputWeightStr = String(format: "%.1f", latestWeight)
            }
        }
    }

    private func adjustInputWeight(by step: Double) {
        let cur = Double(inputWeightStr.replacingOccurrences(of: ",", with: ".")) ?? latestWeight
        let updated = max(20.0, min(250.0, cur + step))
        inputWeightStr = String(format: "%.1f", updated)
    }

    private func saveWeight() {
        guard let w = Double(inputWeightStr.replacingOccurrences(of: ",", with: ".")), w in 20...250 else { return }
        let dateStr = selectedDate.yyyyMMddString

        // Replace or insert
        if let existing = weightEntries.first(where: { $0.date == dateStr }) {
            existing.weightKg = w
            existing.note = noteStr.trimmingCharacters(in: .whitespaces)
            existing.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        } else {
            let entry = WeightEntryItem(
                date: dateStr,
                weightKg: w,
                note: noteStr.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()

        // Sync with preferences current weight
        prefs.weightKg = w

        MiodiHapticFeedback.success()
        noteStr = ""
        withAnimation {
            showSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showSavedToast = false
            }
        }
    }

    private func deleteEntry(_ entry: WeightEntryItem) {
        MiodiHapticFeedback.warning()
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private func findClosestEntry(to date: Date) {
        let dateStr = date.yyyyMMddString
        let sorted = chartEntries
        guard !sorted.isEmpty else { return }
        var closest = sorted.first!
        var minDiff = Double.greatestFiniteMagnitude

        for item in sorted {
            if let d = Date.from(yyyyMMdd: item.date) {
                let diff = abs(d.timeIntervalSince(date))
                if diff < minDiff {
                    minDiff = diff
                    closest = item
                }
            }
        }
        selectedChartEntry = closest
    }
}

private struct MetricCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let isDark: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(icon).font(.system(size: 16))
            Text(title)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.2), lineWidth: 1))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
