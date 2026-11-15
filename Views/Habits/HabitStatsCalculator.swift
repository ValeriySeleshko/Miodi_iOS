//
//  HabitStatsCalculator.swift
//  Plan4U_iOS
//
//  Complete statistics, streak, and heatmap calculation matching Android HabitStatsCalculator.kt
//

import Foundation
import SwiftUI

public struct HabitBarItem: Identifiable, Sendable {
    public let id = UUID()
    public let label: String
    public let valueText: String
    public let heightFraction: CGFloat
    public let status: String // "completed", "frozen", "failed"
    public let isCurrent: Bool

    public init(
        label: String,
        valueText: String,
        heightFraction: CGFloat,
        status: String = "completed",
        isCurrent: Bool = false
    ) {
        self.label = label
        self.valueText = valueText
        self.heightFraction = heightFraction
        self.status = status
        self.isCurrent = isCurrent
    }
}

public struct HabitHeatmapCell: Identifiable, Sendable {
    public let id = UUID()
    public let dateStr: String
    public let dayOfMonth: Int
    public let level: Int // 0: None, 1: Low, 2: Mid, 3: Full, 4: Frozen, 5: Failed
    public let isFuture: Bool
    public let isCurrent: Bool
    public let tooltip: String

    public init(
        dateStr: String,
        dayOfMonth: Int,
        level: Int,
        isFuture: Bool = false,
        isCurrent: Bool = false,
        tooltip: String = ""
    ) {
        self.dateStr = dateStr
        self.dayOfMonth = dayOfMonth
        self.level = level
        self.isFuture = isFuture
        self.isCurrent = isCurrent
        self.tooltip = tooltip
    }
}

public struct HabitFrequencyMonthCell: Identifiable, Sendable {
    public let id = UUID()
    public let monthName: String
    public let rate: CGFloat
    public let tooltip: String
}

public struct HabitFrequencyRow: Identifiable, Sendable {
    public let id = UUID()
    public let dowShort: String
    public let months: [HabitFrequencyMonthCell]
}

public struct HabitFrequencyData: Sendable {
    public let rows: [HabitFrequencyRow]
}

public struct HabitStats: Sendable {
    public let currentStreak: Int
    public let bestStreak: Int
    public let currentStreakText: String
    public let bestStreakText: String
    public let currentStreakRange: String
    public let bestStreakRange: String
    public let rate30Days: Int
    public let dynamicLabel: String
    public let dynamicValue: String
    public let dynamicSub: String
    public let targetBadge: String
    public let weeklyBars: [HabitBarItem]
    public let heatmapWeeks: [[HabitHeatmapCell]]
    public let bestDayInsight: String
    public let frequencyData: HabitFrequencyData
}

public enum HabitStatsCalculator {
    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()

    public static func calculate(
        habit: HabitItem,
        entries: [HabitEntryItem],
        period: String = "weeks"
    ) -> HabitStats {
        let calendar = Calendar.current
        let today = Date()

        // Map entries by date for fast lookup
        let entryMap = Dictionary(entries.filter { $0.habitId == habit.id }.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })

        // 1. Calculate 30-day success rate and average
        var scheduled30Count = 0
        var success30Count = 0
        var total30Sum: Float = 0.0

        let weekdaySuccessCounts = [Int](repeating: 0, count: 8) // 1=Mon..7=Sun
        var mutableWeekdaySuccess = weekdaySuccessCounts
        var mutableWeekdayScheduled = weekdaySuccessCounts

        for i in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateStr = isoFormatter.string(from: date)
            let weekday = calendar.component(.weekday, from: date)
            let standardDow = weekday == 1 ? 7 : (weekday - 1) // 1=Mon..7=Sun

            let isScheduled: Bool
            switch habit.scheduleType {
            case "weekdays":
                isScheduled = habit.daysOfWeekSet.contains(standardDow)
            default:
                isScheduled = true
            }

            if isScheduled {
                let entry = entryMap[dateStr]
                let isFrozen = entry?.status == "frozen"
                if isFrozen { continue }

                scheduled30Count += 1
                mutableWeekdayScheduled[standardDow] += 1

                let isCompleted = entry?.isCompleted ?? false
                if isCompleted {
                    success30Count += 1
                    mutableWeekdaySuccess[standardDow] += 1
                }

                if habit.type == "numeric", let entry = entry {
                    total30Sum += entry.value
                }
            }
        }

        let rate30: Int
        if habit.scheduleType == "periodic" {
            let periodicTarget: Int
            if habit.schedulePeriod == "month" {
                periodicTarget = max(1, habit.scheduleTargetCount)
            } else {
                periodicTarget = max(1, Int(round((30.0 / 7.0) * Double(habit.scheduleTargetCount))))
            }
            rate30 = min(100, max(0, Int(round((Double(success30Count) / Double(periodicTarget)) * 100.0))))
        } else if scheduled30Count > 0 {
            rate30 = min(100, max(0, Int(round((Double(success30Count) / Double(scheduled30Count)) * 100.0))))
        } else {
            rate30 = 0
        }

        // 2. Streaks calculation
        var curStreak = 0
        var bestStreak = 0
        var curStreakEnd = ""
        var curStreakStart = ""
        var bestStreakEnd = ""
        var bestStreakStart = ""

        var tempStreak = 0
        var tempStreakStart = ""
        var tempStreakEnd = ""
        var countingCurrent = true

        // Check past 180 days for streaks
        for i in 0..<180 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateStr = isoFormatter.string(from: date)
            let weekday = calendar.component(.weekday, from: date)
            let standardDow = weekday == 1 ? 7 : (weekday - 1)

            let isScheduled: Bool
            switch habit.scheduleType {
            case "weekdays":
                isScheduled = habit.daysOfWeekSet.contains(standardDow)
            default:
                isScheduled = true
            }

            if !isScheduled { continue }

            let entry = entryMap[dateStr]
            let isDone = entry?.isCompleted ?? false
            let isFrozen = entry?.status == "frozen"

            if isFrozen {
                // Frozen preserves streak
                continue
            }

            if isDone {
                tempStreak += 1
                if tempStreakEnd.isEmpty { tempStreakEnd = dateStr }
                tempStreakStart = dateStr

                if countingCurrent {
                    curStreak = tempStreak
                    curStreakEnd = tempStreakEnd
                    curStreakStart = tempStreakStart
                }
                if tempStreak > bestStreak {
                    bestStreak = tempStreak
                    bestStreakStart = tempStreakStart
                    bestStreakEnd = tempStreakEnd
                }
            } else {
                // If today is not done yet, allow streak to continue from yesterday
                if i == 0 {
                    continue
                }
                countingCurrent = false
                tempStreak = 0
                tempStreakStart = ""
                tempStreakEnd = ""
            }
        }

        // Streak unit text
        let streakUnit = "дн."
        let currentStreakText = "\(curStreak) \(streakUnit)"
        let bestStreakText = "\(bestStreak) \(streakUnit)"

        let currentStreakRange = formatRange(start: curStreakStart, end: curStreakEnd)
        let bestStreakRange = formatRange(start: bestStreakStart, end: bestStreakEnd)

        // Dynamic Card Metrics
        let dynamicLabel: String
        let dynamicValue: String
        let dynamicSub: String

        if habit.type == "numeric" {
            dynamicLabel = "Среднее / день"
            let avg = scheduled30Count > 0 ? (total30Sum / Float(scheduled30Count)) : 0.0
            dynamicValue = String(format: "%.1f %@", avg, habit.targetUnit.isEmpty ? "" : habit.targetUnit)
            dynamicSub = "за 30 дней"
        } else {
            dynamicLabel = "Всего сделано"
            dynamicValue = "\(success30Count)"
            dynamicSub = "за последние 30 дней"
        }

        let targetBadge: String
        if habit.type == "numeric" {
            targetBadge = "Цель: \(formatFloat(habit.targetValue)) \(habit.targetUnit)"
        } else {
            targetBadge = habit.scheduleType == "daily" ? "Каждый день" : "По графику"
        }

        // 3. 12-column Bars
        let bars = generateBars(
            habit: habit,
            entryMap: entryMap,
            period: period,
            today: today,
            calendar: calendar
        )

        // 4. 4-week Heatmap Grid (4 rows x 7 columns)
        let heatmapWeeks = generateHeatmap(
            habit: habit,
            entryMap: entryMap,
            today: today,
            calendar: calendar
        )

        // 5. Best Day Insight
        let dayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        var bestDowIdx = 0
        var bestDowRate = -1.0
        for dow in 1...7 {
            let sched = mutableWeekdayScheduled[dow]
            if sched > 0 {
                let r = Double(mutableWeekdaySuccess[dow]) / Double(sched)
                if r > bestDowRate {
                    bestDowRate = r
                    bestDowIdx = dow
                }
            }
        }

        let bestDayInsight: String
        if bestDowRate > 0 {
            let pct = Int(round(bestDowRate * 100))
            let dName = dayNames[bestDowIdx - 1]
            bestDayInsight = "💡 Самый продуктивный день: \(dName) (\(pct)%)"
        } else {
            bestDayInsight = "💡 Отмечайте привычку регулярно для точной аналитики"
        }

        // 6. Day Frequency Rows
        let frequencyData = generateFrequencyData(
            entryMap: entryMap,
            today: today,
            calendar: calendar
        )

        return HabitStats(
            currentStreak: curStreak,
            bestStreak: bestStreak,
            currentStreakText: currentStreakText,
            bestStreakText: bestStreakText,
            currentStreakRange: currentStreakRange,
            bestStreakRange: bestStreakRange,
            rate30Days: rate30,
            dynamicLabel: dynamicLabel,
            dynamicValue: dynamicValue,
            dynamicSub: dynamicSub,
            targetBadge: targetBadge,
            weeklyBars: bars,
            heatmapWeeks: heatmapWeeks,
            bestDayInsight: bestDayInsight,
            frequencyData: frequencyData
        )
    }

    private static func formatRange(start: String, end: String) -> String {
        guard !start.isEmpty, !end.isEmpty else { return "" }
        if start == end { return start }
        return "\(start) — \(end)"
    }

    private static func formatFloat(_ val: Float) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(val))
        } else {
            return String(format: "%.1f", val)
        }
    }

    private static func generateBars(
        habit: HabitItem,
        entryMap: [String: HabitEntryItem],
        period: String,
        today: Date,
        calendar: Calendar
    ) -> [HabitBarItem] {
        var items: [HabitBarItem] = []

        if period == "days" {
            // Last 12 days
            let dayNames = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
            for i in (0..<12).reversed() {
                guard let d = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
                let dStr = isoFormatter.string(from: d)
                let dow = calendar.component(.weekday, from: d)
                let label = dayNames[dow - 1]
                let entry = entryMap[dStr]
                let isDone = entry?.isCompleted ?? false
                let status = entry?.status ?? "completed"
                let val = entry?.value ?? 0

                let heightFraction: CGFloat
                let valueText: String

                if habit.type == "numeric" {
                    let target = habit.targetValue > 0 ? habit.targetValue : 1
                    heightFraction = CGFloat(min(1.0, max(0.05, Double(val / target))))
                    valueText = val > 0 ? formatFloat(val) : ""
                } else {
                    heightFraction = isDone ? 1.0 : (status == "frozen" ? 0.6 : 0.05)
                    valueText = isDone ? "✓" : (status == "frozen" ? "❄" : (status == "failed" ? "✕" : ""))
                }

                items.append(HabitBarItem(
                    label: label,
                    valueText: valueText,
                    heightFraction: heightFraction,
                    status: status,
                    isCurrent: i == 0
                ))
            }
        } else if period == "months" {
            // Last 12 months
            let monthNames = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
            for i in (0..<12).reversed() {
                guard let d = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
                let m = calendar.component(.month, from: d)
                let label = monthNames[m - 1]

                // Count completed in this month
                var completedCount = 0
                for (dateStr, entry) in entryMap {
                    if dateStr.hasPrefix(String(format: "%04d-%02d", calendar.component(.year, from: d), m)) && entry.isCompleted {
                        completedCount += 1
                    }
                }
                let fraction = min(1.0, max(0.05, CGFloat(completedCount) / 25.0))

                items.append(HabitBarItem(
                    label: label,
                    valueText: completedCount > 0 ? "\(completedCount)" : "",
                    heightFraction: fraction,
                    status: "completed",
                    isCurrent: i == 0
                ))
            }
        } else {
            // Default: 12 weeks
            for i in (0..<12).reversed() {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: today) else { continue }
                let wNum = calendar.component(.weekOfYear, from: weekStart)
                let label = "н.\(wNum)"

                var doneInWeek = 0
                for dOff in 0..<7 {
                    if let d = calendar.date(byAdding: .day, value: dOff, to: weekStart) {
                        let dStr = isoFormatter.string(from: d)
                        if entryMap[dStr]?.isCompleted == true {
                            doneInWeek += 1
                        }
                    }
                }
                let fraction = min(1.0, max(0.05, CGFloat(doneInWeek) / 7.0))

                items.append(HabitBarItem(
                    label: label,
                    valueText: doneInWeek > 0 ? "\(doneInWeek)" : "",
                    heightFraction: fraction,
                    status: "completed",
                    isCurrent: i == 0
                ))
            }
        }

        return items
    }

    private static func generateHeatmap(
        habit: HabitItem,
        entryMap: [String: HabitEntryItem],
        today: Date,
        calendar: Calendar
    ) -> [[HabitHeatmapCell]] {
        // Build 4 weeks (28 days) ending on end of current week or today
        // Standard Monday start
        var weeks: [[HabitHeatmapCell]] = []

        // Find current week's Monday
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = weekday == 1 ? 6 : (weekday - 2)
        guard let currentMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else {
            return []
        }

        // Start 3 weeks before current Monday (total 4 weeks)
        guard let startMonday = calendar.date(byAdding: .weekOfYear, value: -3, to: currentMonday) else {
            return []
        }

        let todayStr = isoFormatter.string(from: today)

        for w in 0..<4 {
            var weekCells: [HabitHeatmapCell] = []
            for d in 0..<7 {
                let offset = (w * 7) + d
                guard let cellDate = calendar.date(byAdding: .day, value: offset, to: startMonday) else { continue }
                let dateStr = isoFormatter.string(from: cellDate)
                let dayOfMonth = calendar.component(.day, from: cellDate)
                let isFuture = cellDate > today && dateStr != todayStr
                let isCurrent = (dateStr == todayStr)

                let entry = entryMap[dateStr]
                let level: Int
                if let entry = entry {
                    if entry.status == "frozen" {
                        level = 4
                    } else if entry.status == "failed" {
                        level = 5
                    } else if entry.isCompleted {
                        level = 3
                    } else if entry.value > 0 {
                        level = habit.targetValue > 0 && entry.value >= (habit.targetValue * 0.5) ? 2 : 1
                    } else {
                        level = 0
                    }
                } else {
                    level = 0
                }

                weekCells.append(HabitHeatmapCell(
                    dateStr: dateStr,
                    dayOfMonth: dayOfMonth,
                    level: level,
                    isFuture: isFuture,
                    isCurrent: isCurrent,
                    tooltip: "\(dateStr): \(level > 0 ? "Выполнено" : "Нет записей")"
                ))
            }
            weeks.append(weekCells)
        }

        return weeks
    }

    private static func generateFrequencyData(
        entryMap: [String: HabitEntryItem],
        today: Date,
        calendar: Calendar
    ) -> HabitFrequencyData {
        let dayLabels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        let monthNames = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн"]

        var rows: [HabitFrequencyRow] = []

        for dowIdx in 1...7 {
            var monthCells: [HabitFrequencyMonthCell] = []
            for mIdx in (0..<5).reversed() {
                guard let d = calendar.date(byAdding: .month, value: -mIdx, to: today) else { continue }
                let m = calendar.component(.month, from: d)
                let mName = monthNames[(m - 1) % monthNames.count]

                // Mock frequency density based on entries for dow in that month
                var total = 0
                var hits = 0
                for (dateStr, entry) in entryMap {
                    if let entryDate = isoFormatter.date(from: dateStr) {
                        let w = calendar.component(.weekday, from: entryDate)
                        let stdDow = w == 1 ? 7 : (w - 1)
                        if stdDow == dowIdx && calendar.component(.month, from: entryDate) == m {
                            total += 1
                            if entry.isCompleted { hits += 1 }
                        }
                    }
                }
                let rate: CGFloat = total > 0 ? CGFloat(hits) / CGFloat(total) : 0.0
                monthCells.append(HabitFrequencyMonthCell(
                    monthName: mName,
                    rate: rate,
                    tooltip: "\(dayLabels[dowIdx - 1]) \(mName): \(Int(rate * 100))%"
                ))
            }
            rows.append(HabitFrequencyRow(dowShort: dayLabels[dowIdx - 1], months: monthCells))
        }

        return HabitFrequencyData(rows: rows)
    }
}
