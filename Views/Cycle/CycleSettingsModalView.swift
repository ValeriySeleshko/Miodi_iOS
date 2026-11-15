//
//  CycleSettingsModalView.swift
//  Plan4U_iOS
//
//  Complete Cycle Settings Sheet matching Android CycleSettingsDialog & CycleNotificationsDialog 1-to-1
//  Lengths steppers, Indicator style picker, Irregular cycle mode, Luteal nutrition sync,
//  Notification triggers and Face ID / Passcode privacy lock.
//

import SwiftUI

public struct CycleSettingsModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var settings = CycleSettingsStore.shared
    @State private var security = CycleSecurityManager.shared

    @State private var cycleLength: Int = 28
    @State private var periodLength: Int = 5
    @State private var selectedIndicator: CycleIndicatorStyle = .cherry
    @State private var isIrregular: Bool = true
    @State private var lutealNutritionSync: Bool = false
    @State private var lutealBoostPercent: Int = 10

    // Notification settings
    @State private var remindersEnabled: Bool = true
    @State private var reminderDaysBefore: Int = 3
    @State private var delayRemindersEnabled: Bool = true
    @State private var endRemindersEnabled: Bool = true
    @State private var popupEnabled: Bool = true

    // Privacy & Security
    @State private var isPrivacyProtected: Bool = false
    @State private var showSecurityError: String? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public var onSave: (() -> Void)?

    public init(onSave: (() -> Void)? = nil) {
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x0F172A) : Color(hex: 0xFDF4F8))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Lengths Section (Cycle & Period)
                        cycleLengthsSection

                        // 2. Indicator Style Picker
                        indicatorStyleSection

                        // 3. Smart Prediction Modes
                        smartPredictionSection

                        // 4. Luteal Nutrition Sync
                        lutealSynergySection

                        // 5. Notifications & Reminders
                        notificationsSection

                        // 6. Privacy & Face ID Protection
                        privacySection

                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Настройки цикла")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        saveAllSettings()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFB7185))
                }
            }
            .onAppear {
                loadSettings()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 1. Cycle Lengths Section
    private var cycleLengthsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🗓")
                Text("Длительность цикла и менструации")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
            }

            Text("Укажите привычные значения для точного прогноза фаз и овуляции.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Cycle Length Stepper
            stepperRow(
                label: "Длительность цикла",
                value: $cycleLength,
                range: 20...45,
                unit: "дн.",
                benchmark: "Базовый ориентир: 28 дн."
            )

            Divider().opacity(0.5)

            // Period Length Stepper
            stepperRow(
                label: "Длительность менструации",
                value: $periodLength,
                range: 2...10,
                unit: "дн.",
                benchmark: "Базовый ориентир: 5 дн."
            )
        }
        .padding(14)
        .background(cardBackground)
    }

    private func stepperRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        unit: String,
        benchmark: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        if value.wrappedValue > range.lowerBound {
                            value.wrappedValue -= 1
                            MiodiHapticFeedback.lightClick()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(value.wrappedValue > range.lowerBound ? Color(hex: 0xFB7185) : .secondary.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xFCE7F0))
                            .clipShape(Circle())
                    }
                    .disabled(value.wrappedValue <= range.lowerBound)

                    Text("\(value.wrappedValue) \(unit)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFB7185))
                        .frame(minWidth: 54)
                        .multilineTextAlignment(.center)

                    Button {
                        if value.wrappedValue < range.upperBound {
                            value.wrappedValue += 1
                            MiodiHapticFeedback.lightClick()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(value.wrappedValue < range.upperBound ? Color(hex: 0xFB7185) : .secondary.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xFCE7F0))
                            .clipShape(Circle())
                    }
                    .disabled(value.wrappedValue >= range.upperBound)
                }
            }

            Text(benchmark)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 2. Indicator Style Section
    private var indicatorStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎨")
                Text("Стиль указателя фаз")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                Spacer()

                Text("5 стилей")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(CycleIndicatorStyle.allCases) { style in
                    let isSelected = (selectedIndicator == style)

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            selectedIndicator = style
                        }
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        VStack(spacing: 6) {
                            Text(style.emoji)
                                .font(.system(size: 26))

                            Text(style.titleRu)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color(hex: 0xFB7185) : .secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? Color(hex: 0xFB7185).opacity(0.18) : (isDark ? Color(hex: 0x1E293B) : Color.white))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? Color(hex: 0xFB7185) : (isDark ? Color(hex: 0x334155) : Color.black.opacity(0.08)), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 3. Smart Prediction Modes
    private var smartPredictionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔮")
                Text("Режим расчёта и адаптации")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
            }

            Toggle(isOn: $isIrregular) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Нерегулярный цикл (умный режим)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Text("Расчёт по медиане и окну вероятности с учётом вариабельности организма.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: 0xFB7185))
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 4. Luteal Nutrition Sync
    private var lutealSynergySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🌸")
                Text("Связка с питанием в лютеиновую фазу")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
            }

            Toggle(isOn: $lutealNutritionSync) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Поддержка в лютеиновой фазе")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Text("Бережное повышение дневной нормы калорий и сложных углеводов во второй половине цикла.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: 0xFB7185))

            if lutealNutritionSync {
                HStack {
                    Text("Увеличение калорий:")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: $lutealBoostPercent) {
                        Text("+5%").tag(5)
                        Text("+10%").tag(10)
                        Text("+15%").tag(15)
                        Text("+20%").tag(20)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 190)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 5. Notifications & Reminders
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🔔")
                Text("Уведомления и напоминания")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
            }

            // Remind beforehand toggle & days
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $remindersEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Напоминать о приближении")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                        Text("Деликатное оповещение за несколько дней до начала.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color(hex: 0xFB7185))

                if remindersEnabled {
                    HStack {
                        Text("Напоминать за:")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $reminderDaysBefore) {
                            Text("1 дн.").tag(1)
                            Text("2 дн.").tag(2)
                            Text("3 дн.").tag(3)
                            Text("5 дн.").tag(5)
                            Text("7 дн.").tag(7)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
            }

            Divider().opacity(0.5)

            // Overdue reminder
            Toggle(isOn: $delayRemindersEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Напоминание при задержке")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Text("Ежедневный заботливый чек-ин, если цикл задерживается.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: 0xFB7185))

            Divider().opacity(0.5)

            // Period end reminder
            Toggle(isOn: $endRemindersEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Проверка окончания менструации")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Text("Напомнить отметить окончание на 5–6 день.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: 0xFB7185))

            Divider().opacity(0.5)

            // Popup check-in
            Toggle(isOn: $popupEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Быстрое окно проверки статуса")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Text("Показывать подсказки в приложении при приближении цикла.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: 0xFB7185))
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 6. Privacy & Face ID Protection
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: security.biometricIcon)
                    .foregroundStyle(Color(hex: 0xFB7185))
                Text("Приватность и защита")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
            }

            Toggle(isOn: $isPrivacyProtected) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Защита \(security.biometricName)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                    Text("Запрашивать \(security.biometricName) при каждом входе в женский календарь.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: 0xFB7185))
            .onChange(of: isPrivacyProtected) { oldValue, newValue in
                guard oldValue != newValue else { return }
                security.authenticate(reason: newValue ? "Подтвердите включение защиты" : "Подтвердите отключение защиты") { success in
                    if success {
                        security.isProtectionEnabled = newValue
                        isPrivacyProtected = newValue
                    } else {
                        isPrivacyProtected = oldValue
                    }
                }
            }
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

    private func loadSettings() {
        cycleLength = settings.defaultCycleLength
        periodLength = settings.periodLength
        selectedIndicator = settings.indicatorStyle
        isIrregular = settings.isIrregular
        lutealNutritionSync = settings.lutealNutritionSync
        lutealBoostPercent = settings.lutealBoostPercent
        remindersEnabled = settings.remindersEnabled
        reminderDaysBefore = settings.reminderDaysBefore
        delayRemindersEnabled = settings.delayRemindersEnabled
        endRemindersEnabled = settings.endRemindersEnabled
        popupEnabled = settings.popupEnabled
        isPrivacyProtected = security.isProtectionEnabled
    }

    private func saveAllSettings() {
        settings.defaultCycleLength = cycleLength
        settings.periodLength = periodLength
        settings.indicatorStyle = selectedIndicator
        settings.isIrregular = isIrregular
        settings.lutealNutritionSync = lutealNutritionSync
        settings.lutealBoostPercent = lutealBoostPercent
        settings.remindersEnabled = remindersEnabled
        settings.reminderDaysBefore = reminderDaysBefore
        settings.delayRemindersEnabled = delayRemindersEnabled
        settings.endRemindersEnabled = endRemindersEnabled
        settings.popupEnabled = popupEnabled

        MiodiHapticFeedback.success()
        onSave?()
    }
}
