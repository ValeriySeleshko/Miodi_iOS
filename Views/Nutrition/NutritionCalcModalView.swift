//
//  NutritionCalcModalView.swift
//  Plan4U_iOS
//
//  100% Match to Android NutritionCalcModal:
//  Mifflin-St Jeor scientific formula, BMR, TDEE, macro split options,
//  steppers, top-down meal percentage balancing.
//

import SwiftUI

public struct NutritionCalcModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private var prefs: NutritionPreferences { NutritionPreferences.shared }

    @State private var isFemale: Bool
    @State private var age: Int
    @State private var heightCm: Double
    @State private var weightKg: Double
    @State private var targetWeightKg: Double
    @State private var selectedActivityIndex: Int
    @State private var selectedGoal: Int // 0: Cut, 1: Maintain, 2: Gain
    @State private var selectedSplitIndex: Int

    @State private var manualCalories: Double? = nil
    @State private var manualProt: Double? = nil
    @State private var manualFat: Double? = nil
    @State private var manualCarb: Double? = nil

    @State private var mealPercentages: [Int]

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init() {
        let p = NutritionPreferences.shared
        _isFemale = State(initialValue: p.isFemale)
        _age = State(initialValue: p.age)
        _heightCm = State(initialValue: p.heightCm)
        _weightKg = State(initialValue: p.weightKg)
        _targetWeightKg = State(initialValue: p.targetWeightKg)
        _selectedActivityIndex = State(initialValue: p.activityLevelIndex)
        _selectedGoal = State(initialValue: p.goalIndex)
        _selectedSplitIndex = State(initialValue: p.splitIndex)
        _mealPercentages = State(initialValue: p.mealPercentages)
    }

    // Calculations
    private var bmr: Double {
        prefs.calculateBMR(weight: weightKg, height: heightCm, ageVal: age, female: isFemale)
    }

    private var tdee: Double {
        let factor = NutritionPreferences.activityLevels[safe: selectedActivityIndex]?.factor ?? 1.375
        return (bmr * factor).rounded()
    }

    private var calculatedCalories: Double {
        switch selectedGoal {
        case 0: return (tdee * 0.85).rounded()
        case 2: return (tdee * 1.10).rounded()
        default: return tdee
        }
    }

    private var effectiveCalories: Double {
        manualCalories ?? calculatedCalories
    }

    private var selectedSplit: MacroSplitConfig {
        NutritionPreferences.macroSplits[safe: selectedSplitIndex] ?? NutritionPreferences.macroSplits[0]
    }

    private var baseMacros: (protein: Double, fat: Double, carbs: Double) {
        prefs.calculateMacros(calories: effectiveCalories, split: selectedSplit)
    }

    private var effectiveProt: Double { manualProt ?? baseMacros.protein }
    private var effectiveFat: Double { manualFat ?? baseMacros.fat }
    private var effectiveCarb: Double { manualCarb ?? baseMacros.carbs }

    private var isCustomized: Bool {
        manualCalories != nil || manualProt != nil || manualFat != nil || manualCarb != nil
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Subtitle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Формула Миффлина-Сан Жеора")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                            Text("Расчет базового метаболизма и нормы калорий с учетом роста, веса, пола и физической активности.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    // Gender Switcher: [♀ Девушка] [♂ Мужчина]
                    HStack(spacing: 10) {
                        Button {
                            MiodiHapticFeedback.selection()
                            isFemale = true
                            resetManualOverrides()
                        } label: {
                            HStack {
                                Text("♀")
                                Text("Девушка")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(isFemale ? Color(hex: 0xEC4899) : (isDark ? Color(hex: 0x381E2E) : Color(hex: 0xFDF2F8)))
                            .foregroundStyle(isFemale ? Color.white : Color(hex: 0xDB2777))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xEC4899).opacity(isFemale ? 1 : 0.3), lineWidth: 1))
                        }

                        Button {
                            MiodiHapticFeedback.selection()
                            isFemale = false
                            resetManualOverrides()
                        } label: {
                            HStack {
                                Text("♂")
                                Text("Мужчина")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(!isFemale ? Color(hex: 0x0284C7) : (isDark ? Color(hex: 0x162A45) : Color(hex: 0xF0F9FF)))
                            .foregroundStyle(!isFemale ? Color.white : Color(hex: 0x0284C7))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0x0284C7).opacity(!isFemale ? 1 : 0.3), lineWidth: 1))
                        }
                    }

                    // 3 Steppers: Возраст, Рост, Вес
                    HStack(spacing: 8) {
                        StepperCard(
                            icon: "📅",
                            label: "Возраст",
                            unit: "лет",
                            value: age,
                            isDark: isDark,
                            onMinus: { if age > 10 { age -= 1; resetManualOverrides() } },
                            onPlus: { if age < 100 { age += 1; resetManualOverrides() } }
                        )

                        StepperCard(
                            icon: "📏",
                            label: "Рост",
                            unit: "см",
                            value: Int(heightCm),
                            isDark: isDark,
                            onMinus: { if heightCm > 100 { heightCm -= 1; resetManualOverrides() } },
                            onPlus: { if heightCm < 230 { heightCm += 1; resetManualOverrides() } }
                        )

                        StepperCard(
                            icon: "⚖️",
                            label: "Вес",
                            unit: "кг",
                            value: Int(weightKg),
                            isDark: isDark,
                            onMinus: { if weightKg > 30 { weightKg -= 1; resetManualOverrides() } },
                            onPlus: { if weightKg < 200 { weightKg += 1; resetManualOverrides() } }
                        )
                    }

                    // Physical Activity Dropdown
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ФИЗИЧЕСКАЯ АКТИВНОСТЬ")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        Menu {
                            ForEach(Array(NutritionPreferences.activityLevels.enumerated()), id: \.offset) { index, opt in
                                Button {
                                    MiodiHapticFeedback.selection()
                                    selectedActivityIndex = index
                                    resetManualOverrides()
                                } label: {
                                    HStack {
                                        Text("\(opt.icon(isFemale: isFemale)) \(opt.title)")
                                        if selectedActivityIndex == index {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                let cur = NutritionPreferences.activityLevels[safe: selectedActivityIndex] ?? NutritionPreferences.activityLevels[1]
                                Text("\(cur.icon(isFemale: isFemale)) \(cur.title)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1))
                        }
                    }

                    // Goal Selector: 3 Cards (Снижение, Поддержание, Набор)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ЦЕЛЬ")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            GoalOptionButton(
                                icon: "🎯",
                                title: "Снижение",
                                subtitle: "(-15%)",
                                isSelected: selectedGoal == 0,
                                accentColor: theme.currentAccent.primary,
                                isDark: isDark
                            ) {
                                selectedGoal = 0
                                selectedSplitIndex = 0
                                if targetWeightKg >= weightKg { targetWeightKg = max(30, weightKg - 3) }
                                resetManualOverrides()
                            }

                            GoalOptionButton(
                                icon: "⚖️",
                                title: "Баланс",
                                subtitle: "Поддержание",
                                isSelected: selectedGoal == 1,
                                accentColor: theme.currentAccent.primary,
                                isDark: isDark
                            ) {
                                selectedGoal = 1
                                selectedSplitIndex = 1
                                targetWeightKg = weightKg
                                resetManualOverrides()
                            }

                            GoalOptionButton(
                                icon: "📈",
                                title: "Набор",
                                subtitle: "(+10%)",
                                isSelected: selectedGoal == 2,
                                accentColor: theme.currentAccent.primary,
                                isDark: isDark
                            ) {
                                selectedGoal = 2
                                selectedSplitIndex = 2
                                if targetWeightKg <= weightKg { targetWeightKg = min(250, weightKg + 3) }
                                resetManualOverrides()
                            }
                        }
                    }

                    // Target Weight Card with Stepper and Delta
                    let deltaKg = abs(weightKg - targetWeightKg)
                    let isCut = targetWeightKg < weightKg
                    let isGain = targetWeightKg > weightKg
                    let weeksEst = isCut ? max(1, Int((deltaKg / 0.5).rounded())) : (isGain ? max(1, Int((deltaKg / 0.35).rounded())) : 0)

                    VStack(spacing: 6) {
                        HStack {
                            Label("Целевой вес:", systemImage: "target")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    if targetWeightKg > 30 {
                                        targetWeightKg -= 1
                                        updateGoalByTargetWeight()
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(theme.currentAccent.primary)
                                }

                                Text(String(format: "%.0f кг", targetWeightKg))
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(minWidth: 55)

                                Button {
                                    if targetWeightKg < 250 {
                                        targetWeightKg += 1
                                        updateGoalByTargetWeight()
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(theme.currentAccent.primary)
                                }
                            }
                        }

                        HStack {
                            Text(isCut ? "Снижение на \(String(format: "%.1f", deltaKg)) кг" : (isGain ? "Набор \(String(format: "%.1f", deltaKg)) кг" : "Поддержание текущего веса"))
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(theme.currentAccent.primary)
                            Spacer()
                            if weeksEst > 0 {
                                Text("~ \(weeksEst) нед. безопасного прогресса")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1))

                    // Macro Split Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ПРОПОРЦИИ БЖУ")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        Menu {
                            ForEach(Array(NutritionPreferences.macroSplits.enumerated()), id: \.offset) { index, split in
                                Button {
                                    MiodiHapticFeedback.selection()
                                    selectedSplitIndex = index
                                    resetManualOverrides()
                                } label: {
                                    HStack {
                                        Text("\(split.icon) \(split.title)")
                                        if selectedSplitIndex == index {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(selectedSplit.icon) \(selectedSplit.title)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1))
                        }
                    }

                    // Result Target Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("ИТОГОВАЯ ДНЕВНАЯ НОРМА")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.currentAccent.primary)
                            Spacer()
                            let diffCal = Int(effectiveCalories - tdee)
                            let sign = diffCal > 0 ? "+" : ""
                            Text(diffCal != 0 ? "\(sign)\(diffCal) ккал" : "Баланс")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.currentAccent.primary.opacity(0.12))
                                .foregroundStyle(theme.currentAccent.primary)
                                .clipShape(Capsule())
                        }

                        // Big Calories Display with Stepper
                        HStack {
                            HStack(alignment: .lastTextBaseline, spacing: 6) {
                                Text("🔥")
                                    .font(.system(size: 26))
                                Text(String(format: "%.0f", effectiveCalories))
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundStyle(Color(hex: 0xD95300))
                                Text("ккал / день")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                Button {
                                    MiodiHapticFeedback.lightClick()
                                    let cur = effectiveCalories
                                    manualCalories = max(500, cur - 50)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(theme.currentAccent.primary.opacity(0.8))
                                }

                                Button {
                                    MiodiHapticFeedback.lightClick()
                                    let cur = effectiveCalories
                                    manualCalories = min(8000, cur + 50)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(theme.currentAccent.primary.opacity(0.8))
                                }
                            }
                        }

                        // Tricolor Macro Bar
                        GeometryReader { geo in
                            let totalKcal = (effectiveProt * 4 + effectiveFat * 9 + effectiveCarb * 4)
                            let pWidth = totalKcal > 0 ? (effectiveProt * 4 / totalKcal) * geo.size.width : geo.size.width / 3
                            let fWidth = totalKcal > 0 ? (effectiveFat * 9 / totalKcal) * geo.size.width : geo.size.width / 3
                            let cWidth = max(0, geo.size.width - pWidth - fWidth)

                            HStack(spacing: 2) {
                                Rectangle().fill(MiodiStaticColors.macroProtein).frame(width: pWidth)
                                Rectangle().fill(MiodiStaticColors.macroFat).frame(width: fWidth)
                                Rectangle().fill(MiodiStaticColors.macroCarb).frame(width: cWidth)
                            }
                            .clipShape(Capsule())
                        }
                        .frame(height: 8)

                        // 3 Macro Steppers (Белки, Жиры, Углеводы)
                        HStack(spacing: 8) {
                            MacroTargetPill(
                                title: "Белки",
                                grams: effectiveProt,
                                color: MiodiStaticColors.macroProtein,
                                isDark: isDark,
                                onMinus: { manualProt = max(0, effectiveProt - 5) },
                                onPlus: { manualProt = min(600, effectiveProt + 5) }
                            )

                            MacroTargetPill(
                                title: "Жиры",
                                grams: effectiveFat,
                                color: MiodiStaticColors.macroFat,
                                isDark: isDark,
                                onMinus: { manualFat = max(0, effectiveFat - 5) },
                                onPlus: { manualFat = min(400, effectiveFat + 5) }
                            )

                            MacroTargetPill(
                                title: "Углеводы",
                                grams: effectiveCarb,
                                color: MiodiStaticColors.macroCarb,
                                isDark: isDark,
                                onMinus: { manualCarb = max(0, effectiveCarb - 5) },
                                onPlus: { manualCarb = min(1000, effectiveCarb + 5) }
                            )
                        }

                        HStack {
                            Text("Базовый обмен (BMR): \(Int(bmr)) ккал")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if isCustomized {
                                Button("Сбросить к формуле") {
                                    resetManualOverrides()
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.currentAccent.primary)
                            }
                        }
                    }
                    .padding(16)
                    .background(isDark ? Color(hex: 0x2A1C29) : Color(hex: 0xFDF2F8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.currentAccent.primary.opacity(0.35), lineWidth: 1))

                    // Meal Percentages Distribution Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("РАСПРЕДЕЛЕНИЕ ПО ПРИЁМАМ ПИЩИ")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                Text("Настройте доли калорийности для каждого приёма. Сумма всегда равна 100%.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(mealPercentages.reduce(0, +))% ✓")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.currentAccent.primary.opacity(0.15))
                                .foregroundStyle(theme.currentAccent.primary)
                                .clipShape(Capsule())
                        }

                        // Proportional segmented bar of meals
                        GeometryReader { geo in
                            let mealColors: [Color] = [Color(hex: 0xF59E0B), Color(hex: 0x10B981), Color(hex: 0x6366F1), Color(hex: 0xEC4899)]
                            HStack(spacing: 2) {
                                ForEach(0..<4, id: \.self) { idx in
                                    let pct = mealPercentages[safe: idx] ?? 25
                                    let w = (Double(pct) / 100.0) * geo.size.width
                                    Rectangle().fill(mealColors[idx]).frame(width: max(0, w))
                                }
                            }
                            .clipShape(Capsule())
                        }
                        .frame(height: 8)

                        // 4 Sliders (Breakfast, Lunch, Dinner, Snack)
                        let mealNames = ["Завтрак", "Обед", "Ужин", "Перекус"]
                        let mealIcons = ["🍳", "🍲", "🍗", "🍌"]
                        let mealColors: [Color] = [Color(hex: 0xF59E0B), Color(hex: 0x10B981), Color(hex: 0x6366F1), Color(hex: 0xEC4899)]

                        VStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { index in
                                let pct = mealPercentages[safe: index] ?? 25
                                let mealCal = Int((effectiveCalories * Double(pct) / 100.0).rounded())

                                HStack(spacing: 10) {
                                    HStack(spacing: 6) {
                                        Text(mealIcons[index])
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(mealNames[index])
                                                .font(.system(size: 12, weight: .bold))
                                            Text("\(mealCal) ккал")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(width: 85, alignment: .leading)

                                    Slider(
                                        value: Binding(
                                            get: { Double(pct) },
                                            set: { newVal in
                                                let updated = NutritionPreferences.rebalancePercentagesTopDown(
                                                    current: mealPercentages,
                                                    changedIndex: index,
                                                    newValue: Int(newVal.rounded())
                                                )
                                                mealPercentages = updated
                                            }
                                        ),
                                        in: 0...100
                                    )
                                    .tint(mealColors[index])

                                    Text("\(pct)%")
                                        .font(.system(size: 12, weight: .bold))
                                        .frame(width: 36, alignment: .trailing)
                                }
                            }
                        }

                        // Reset percentages button
                        HStack {
                            Spacer()
                            Button("Сбросить по умолчанию (25/35/25/15)") {
                                mealPercentages = [25, 35, 25, 15]
                            }
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(theme.currentAccent.primary)
                        }
                    }
                    .padding(14)
                    .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.currentAccent.primary.opacity(0.2), lineWidth: 1))

                    // Apply Button
                    Button {
                        MiodiHapticFeedback.success()
                        saveAndApply()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Применить дневную норму")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(theme.currentAccent.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: theme.currentAccent.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("Калькулятор калорий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func resetManualOverrides() {
        manualCalories = nil
        manualProt = nil
        manualFat = nil
        manualCarb = nil
    }

    private func updateGoalByTargetWeight() {
        if targetWeightKg < weightKg {
            selectedGoal = 0
            selectedSplitIndex = 0
        } else if targetWeightKg > weightKg {
            selectedGoal = 2
            selectedSplitIndex = 2
        } else {
            selectedGoal = 1
            selectedSplitIndex = 1
        }
        resetManualOverrides()
    }

    private func saveAndApply() {
        prefs.isFemale = isFemale
        prefs.age = age
        prefs.heightCm = heightCm
        prefs.weightKg = weightKg
        prefs.targetWeightKg = targetWeightKg
        prefs.activityLevelIndex = selectedActivityIndex
        prefs.goalIndex = selectedGoal
        prefs.splitIndex = selectedSplitIndex
        prefs.targetCalories = effectiveCalories
        prefs.targetProteins = effectiveProt
        prefs.targetFats = effectiveFat
        prefs.targetCarbs = effectiveCarb
        prefs.mealPercentages = mealPercentages
    }
}

private struct StepperCard: View {
    let icon: String
    let label: String
    let unit: String
    let value: Int
    let isDark: Bool
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 16))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("\(value) \(unit)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
            HStack(spacing: 12) {
                Button(action: onMinus) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 26, height: 26)
                        .background(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 26, height: 26)
                        .background(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            .foregroundStyle(.primary)
            .padding(.top, 2)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

private struct GoalOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accentColor: Color
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(icon).font(.system(size: 18))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? accentColor : (isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText))
                Text(subtitle)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? accentColor.opacity(0.12) : (isDark ? MiodiStaticColors.darkCardBg : Color.white))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1))
        }
    }
}

private struct MacroTargetPill: View {
    let title: String
    let grams: Double
    let color: Color
    let isDark: Bool
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(color)
            Text(String(format: "%.0f г", grams))
                .font(.system(size: 13, weight: .black))
            Text(String(format: "%.0f ккал", grams * (title == "Жиры" ? 9 : 4)))
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button(action: onMinus) {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(color.opacity(0.15))
                        .foregroundStyle(color)
                        .clipShape(Circle())
                }
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(color.opacity(0.15))
                        .foregroundStyle(color)
                        .clipShape(Circle())
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
