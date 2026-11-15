//
//  HabitNumericStepperSheet.swift
//  Plan4U_iOS
//
//  Bottom sheet stepper modal for numeric habits matching Android HabitStepperModal.kt
//

import SwiftUI
import SwiftData

public struct HabitNumericStepperSheet: View {
    public let habit: HabitItem
    public let dateStr: String
    public let initialValue: Float
    public let onSave: (Float, String) -> Void
    public let onDismiss: () -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentValue: Float
    @State private var textInput: String
    @State private var selectedStatus: String = "completed" // "completed", "failed", "frozen"

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(
        habit: HabitItem,
        dateStr: String,
        initialValue: Float,
        status: String = "completed",
        onSave: @escaping (Float, String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.habit = habit
        self.dateStr = dateStr
        self.initialValue = initialValue
        self.onSave = onSave
        self.onDismiss = onDismiss
        _currentValue = State(initialValue: initialValue)
        _textInput = State(initialValue: formatValue(initialValue))
        _selectedStatus = State(initialValue: status)
    }

    private static func formatValue(_ val: Float) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(val))
        } else {
            return String(format: "%.2f", val).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        }
    }

    private var target: Float {
        habit.targetValue > 0 ? habit.targetValue : 1.0
    }

    private var step: Float {
        habit.targetStep > 0 ? habit.targetStep : 1.0
    }

    private var progressRatio: CGFloat {
        min(1.0, max(0.0, CGFloat(currentValue / target)))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header & Target Info
                VStack(spacing: 6) {
                    Text(habit.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)

                    Text("Цель: \(Self.formatValue(target)) \(habit.targetUnit) • Дата: \(dateStr)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 14)

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                            .frame(height: 10)

                        Capsule()
                            .fill(theme.currentAccent.primary)
                            .frame(width: geo.size.width * progressRatio, height: 10)
                    }
                }
                .frame(height: 10)
                .padding(.horizontal, 24)

                // Large Value Display & Stepper Controls
                HStack(spacing: 20) {
                    Button {
                        adjust(by: -step)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x1E293B))
                            .frame(width: 50, height: 50)
                            .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                            .clipShape(Circle())
                    }

                    VStack(spacing: 2) {
                        TextField("0", text: $textInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.currentAccent.primary)
                            .frame(width: 120)
                            .onChange(of: textInput) { _, newValue in
                                if let val = Float(newValue.replacingOccurrences(of: ",", with: ".")) {
                                    currentValue = max(0, val)
                                }
                            }

                        Text(habit.targetUnit)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        adjust(by: step)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x1E293B))
                            .frame(width: 50, height: 50)
                            .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                            .clipShape(Circle())
                    }
                }
                .padding(.vertical, 8)

                // Quick Presets
                HStack(spacing: 10) {
                    quickButton(label: "+1") { adjust(by: 1.0) }
                    quickButton(label: "+\(Self.formatValue(step))") { adjust(by: step) }
                    quickButton(label: "100% (\(Self.formatValue(target)))") {
                        currentValue = target
                        textInput = Self.formatValue(target)
                        selectedStatus = "completed"
                        MiodiHapticFeedback.taskComplete()
                    }
                    quickButton(label: "Сброс") {
                        currentValue = 0
                        textInput = "0"
                        selectedStatus = "failed"
                        MiodiHapticFeedback.lightClick()
                    }
                }

                // Status Selector: Normal / Frozen / Failed
                HStack(spacing: 8) {
                    statusTab(status: "completed", title: "Выполнено", icon: "checkmark")
                    statusTab(status: "frozen", title: "❄ Заморозка", icon: "snowflake")
                    statusTab(status: "failed", title: "✕ Пропуск", icon: "xmark")
                }
                .padding(.horizontal, 16)

                Spacer()

                // Save Action Button
                Button {
                    MiodiHapticFeedback.success()
                    onSave(currentValue, selectedStatus)
                    onDismiss()
                } label: {
                    Text("Сохранить результат")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.currentAccent.primary)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("Прогресс привычки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { onDismiss() }
                }
            }
        }
        .presentationDetents([.fraction(0.55), .fraction(0.85)])
    }

    private func adjust(by delta: Float) {
        currentValue = max(0, currentValue + delta)
        textInput = Self.formatValue(currentValue)
        selectedStatus = currentValue >= target ? "completed" : "completed"
        MiodiHapticFeedback.lightClick()
    }

    private func quickButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isDark ? Color.white.opacity(0.9) : Color(hex: 0x334155))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                .clipShape(Capsule())
        }
    }

    private func statusTab(status: String, title: String, icon: String) -> some View {
        let isSel = selectedStatus == status
        return Button {
            selectedStatus = status
            MiodiHapticFeedback.selection()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: isSel ? .bold : .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSel ? theme.currentAccent.primary.opacity(0.18) : (isDark ? Color(hex: 0x263044) : Color(hex: 0xF1F5F9)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSel ? theme.currentAccent.primary : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundStyle(isSel ? theme.currentAccent.primary : .secondary)
        }
    }
}
