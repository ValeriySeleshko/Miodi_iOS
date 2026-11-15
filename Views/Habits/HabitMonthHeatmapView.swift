//
//  HabitMonthHeatmapView.swift
//  Plan4U_iOS
//
//  Interactive Month Calendar with completion heatmap, frozen/failed days, and haptic feedback.
//

import SwiftUI
import SwiftData

public struct HabitMonthHeatmapView: View {
    @Bindable public var habit: HabitItem
    public var entries: [HabitEntryItem]
    public var onToggleDay: (String) -> Void
    public var onOpenStepper: ((String) -> Void)?
    public var onSetStatus: ((String, String) -> Void)?

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedMonthDate: Date = Date()
    @State private var hoveredDateStr: String? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let calendar = Calendar.current
    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()

    public init(
        habit: HabitItem,
        entries: [HabitEntryItem],
        onToggleDay: @escaping (String) -> Void,
        onOpenStepper: ((String) -> Void)? = nil,
        onSetStatus: ((String, String) -> Void)? = nil
    ) {
        self.habit = habit
        self.entries = entries
        self.onToggleDay = onToggleDay
        self.onOpenStepper = onOpenStepper
        self.onSetStatus = onSetStatus
    }

    private var entryMap: [String: HabitEntryItem] {
        Dictionary(entries.filter { $0.habitId == habit.id }.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header with Month Selector
            HStack {
                Text(monthTitleFormatter.string(from: selectedMonthDate).capitalized)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x334155))
                            .frame(width: 28, height: 28)
                            .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                            .clipShape(Circle())
                    }

                    Button {
                        withAnimation { selectedMonthDate = Date() }
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        Text("Сегодня")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.currentAccent.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.currentAccent.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x334155))
                            .frame(width: 28, height: 28)
                            .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                            .clipShape(Circle())
                    }
                }
            }

            // Weekday Headers (Пн..Вс)
            let weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                        .frame(maxWidth: .infinity)
                }
            }

            // Month Grid
            let gridDays = calculateGridDays(for: selectedMonthDate)
            let todayStr = isoFormatter.string(from: Date())

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(gridDays) { day in
                    HeatmapCellView(
                        day: day,
                        isToday: day.dateStr == todayStr,
                        entry: entryMap[day.dateStr],
                        habitType: habit.type,
                        targetValue: habit.targetValue,
                        isDark: isDark,
                        accentColor: theme.currentAccent.primary
                    )
                    .onTapGesture {
                        guard !day.isFuture else { return }
                        MiodiHapticFeedback.taskComplete()
                        if habit.type == "numeric" {
                            onOpenStepper?(day.dateStr)
                        } else {
                            onToggleDay(day.dateStr)
                        }
                    }
                    .contextMenu {
                        if !day.isFuture {
                            Button {
                                onToggleDay(day.dateStr)
                            } label: {
                                Label("Выполнено", systemImage: "checkmark.circle.fill")
                            }

                            Button {
                                onSetStatus?(day.dateStr, "frozen")
                            } label: {
                                Label("Заморозить (отпуск/болезнь)", systemImage: "snowflake")
                            }

                            Button {
                                onSetStatus?(day.dateStr, "failed")
                            } label: {
                                Label("Не сделано", systemImage: "xmark.circle")
                            }

                            if habit.type == "numeric" {
                                Button {
                                    onOpenStepper?(day.dateStr)
                                } label: {
                                    Label("Ввести значение...", systemImage: "slider.horizontal.3")
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.currentAccent.primary)
                        .frame(width: 10, height: 10)
                    Text("Выполнено")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: 0x38BDF8))
                        .frame(width: 10, height: 10)
                    Text("❄ Заморожено")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: 0xEF4444).opacity(0.8))
                        .frame(width: 10, height: 10)
                    Text("✕ Пропуск")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color(hex: 0x1E293B) : Color(hex: 0xF8FAFC))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.2), lineWidth: 1)
                )
        )
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonthDate) {
            selectedMonthDate = newDate
            MiodiHapticFeedback.lightClick()
        }
    }

    private func calculateGridDays(for monthDate: Date) -> [CalendarGridDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [CalendarGridDay] = []
        var currentDate = monthFirstWeek.start
        let today = Date()

        while days.count < 35 || (days.count < 42 && currentDate <= monthInterval.end) {
            let dateStr = isoFormatter.string(from: currentDate)
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: monthDate, toGranularity: .month)
            let dayNum = calendar.component(.day, from: currentDate)
            let isFuture = currentDate > today && !calendar.isDate(currentDate, inSameDayAs: today)

            days.append(CalendarGridDay(
                date: currentDate,
                dateStr: dateStr,
                dayNumber: dayNum,
                isCurrentMonth: isCurrentMonth,
                isFuture: isFuture
            ))

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return days
    }
}

private struct CalendarGridDay: Identifiable {
    let id = UUID()
    let date: Date
    let dateStr: String
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isFuture: Bool
}

private struct HeatmapCellView: View {
    let day: CalendarGridDay
    let isToday: Bool
    let entry: HabitEntryItem?
    let habitType: String
    let targetValue: Float
    let isDark: Bool
    let accentColor: Color

    private var status: String? {
        entry?.status
    }

    private var cellColor: Color {
        if let entry = entry {
            if entry.status == "frozen" {
                return Color(hex: 0x38BDF8)
            } else if entry.status == "failed" {
                return Color(hex: 0xEF4444).opacity(0.8)
            } else if entry.isCompleted {
                return accentColor
            } else if entry.value > 0 {
                let frac = targetValue > 0 ? (entry.value / targetValue) : 0.5
                return accentColor.opacity(Double(min(1.0, max(0.25, frac))))
            }
        }
        return isDark ? Color(hex: 0x263044) : Color(hex: 0xE2E8F0)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cellColor)
                .frame(height: 32)
                .opacity(day.isCurrentMonth ? (day.isFuture ? 0.4 : 1.0) : 0.25)

            if isToday {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(accentColor, lineWidth: 2)
                    .frame(height: 32)
            }

            // Label or status symbol
            if let entry = entry, entry.status == "frozen" {
                Text("❄")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
            } else if let entry = entry, entry.status == "failed" {
                Text("✕")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(day.dayNumber)")
                    .font(.system(size: 11, weight: isToday ? .bold : .medium))
                    .foregroundStyle(
                        entry?.isCompleted == true
                            ? .white
                            : (day.isCurrentMonth
                                ? (isDark ? Color.white.opacity(0.85) : Color(hex: 0x1E293B))
                                : Color.gray.opacity(0.4))
                    )
            }
        }
    }
}
