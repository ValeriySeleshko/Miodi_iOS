//
//  CycleCheckInPopupView.swift
//  Plan4U_iOS
//
//  Smart Daily Check-In Popup Dialog matching Android CycleCheckInPopupDialog 1-to-1
//  Approaching cycle, Expected today, Delay reminders, and Period completion check.
//

import SwiftUI

public struct CycleCheckInPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public let prompt: CycleCheckInPrompt
    public let periodLength: Int

    public var onStartPeriodOnDate: (String) -> Void
    public var onEndPeriodOnDate: (String?, String) -> Void
    public var onStillOngoing: (String?) -> Void
    public var onDismissToday: () -> Void

    @State private var isShowingCustomDatePicker: Bool = false
    @State private var customPickedDate: Date = Date()
    @State private var isPickingStartDate: Bool = true

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init(
        prompt: CycleCheckInPrompt,
        periodLength: Int = 5,
        onStartPeriodOnDate: @escaping (String) -> Void,
        onEndPeriodOnDate: @escaping (String?, String) -> Void,
        onStillOngoing: @escaping (String?) -> Void,
        onDismissToday: @escaping () -> Void
    ) {
        self.prompt = prompt
        self.periodLength = periodLength
        self.onStartPeriodOnDate = onStartPeriodOnDate
        self.onEndPeriodOnDate = onEndPeriodOnDate
        self.onStillOngoing = onStillOngoing
        self.onDismissToday = onDismissToday
    }

    public var body: some View {
        ZStack {
            (isDark ? Color.black.opacity(0.65) : Color.black.opacity(0.40))
                .ignoresSafeArea()
                .onTapGesture {
                    onDismissToday()
                    dismiss()
                }

            VStack(spacing: 16) {
                // Header Icon & Title
                VStack(spacing: 6) {
                    Text(headerEmoji)
                        .font(.system(size: 36))

                    Text(headerTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                        .multilineTextAlignment(.center)

                    Text(bodyDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 8)
                }

                Divider().opacity(0.6)

                // Action Buttons based on prompt type
                VStack(spacing: 8) {
                    switch prompt.type {
                    case .approaching, .expectedToday, .overdueDaily:
                        primaryButton(title: "🩸 Да, начался сегодня", color: Color(hex: 0xFB7185)) {
                            onStartPeriodOnDate(CycleEngine.getTodayString())
                            dismiss()
                        }

                        secondaryButton(title: "📅 Начался раньше (выбрать дату)") {
                            isPickingStartDate = true
                            isShowingCustomDatePicker = true
                        }

                        neutralButton(title: "Пока нет (напомнить завтра)") {
                            onDismissToday()
                            dismiss()
                        }

                    case .forgotEnd:
                        primaryButton(
                            title: "✨ Да, по норме (\(prompt.defaultEndDate), \(periodLength) дн.)",
                            color: Color(hex: 0x34D399)
                        ) {
                            onEndPeriodOnDate(prompt.cycleId, prompt.defaultEndDate)
                            dismiss()
                        }

                        secondaryButton(title: "✨ Завершился сегодня (\(CycleEngine.getTodayString()))") {
                            onEndPeriodOnDate(prompt.cycleId, CycleEngine.getTodayString())
                            dismiss()
                        }

                        secondaryButton(title: "📅 Выбрать другую дату окончания") {
                            isPickingStartDate = false
                            isShowingCustomDatePicker = true
                        }

                        neutralButton(title: "🩸 Ещё идёт (спросить завтра)") {
                            onStillOngoing(prompt.cycleId)
                            dismiss()
                        }
                    }
                }

                if isShowingCustomDatePicker {
                    VStack(spacing: 10) {
                        Divider()
                        DatePicker(
                            isPickingStartDate ? "Дата начала:" : "Дата окончания:",
                            selection: $customPickedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)

                        Button {
                            let pickedStr = isoFormatter.string(from: customPickedDate)
                            if isPickingStartDate {
                                onStartPeriodOnDate(pickedStr)
                            } else {
                                onEndPeriodOnDate(prompt.cycleId, pickedStr)
                            }
                            dismiss()
                        } label: {
                            Text("Подтвердить дату")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(hex: 0xFB7185))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(hex: 0xFB7185).opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 16)
            )
            .padding(.horizontal, 24)
        }
    }

    private var headerEmoji: String {
        switch prompt.type {
        case .approaching: return "🌸"
        case .expectedToday: return "🩸"
        case .overdueDaily: return "⏳"
        case .forgotEnd: return "✨"
        }
    }

    private var headerTitle: String {
        switch prompt.type {
        case .approaching:
            return "Скоро новый цикл"
        case .expectedToday:
            return "Сегодня ожидается старт"
        case .overdueDaily:
            return "Задержка цикла: \(prompt.daysCount) дн."
        case .forgotEnd:
            return "Закончились ли месячные?"
        }
    }

    private var bodyDescription: String {
        switch prompt.type {
        case .approaching:
            return "По прогнозу новый цикл ожидается примерно \(prompt.expectedDate) (через \(prompt.daysCount) дн.). Если он уже начался, отметьте сегодня."
        case .expectedToday:
            return "По календарю сегодня расчётный день начала менструации (\(prompt.expectedDate))."
        case .overdueDaily:
            return "Расчётный день был \(prompt.expectedDate). Организм может реагировать на стресс или смену ритма. Всё в порядке?"
        case .forgotEnd:
            return "Менструация началась \(prompt.startDate) и длится уже \(prompt.daysCount) дн. Если она завершилась, сохраните дату."
        }
    }

    private func primaryButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E293B))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xF1F5F9))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func neutralButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
    }
}
