//
//  NutritionWeightView.swift
//  Plan4U_iOS
//
//  Complete 100% Android-matching Nutrition & Weight Master Hub:
//  - Dual Mode Switcher: Nutrition (Meals & Macros) vs Weight (Dynamics, BMI, Chart)
//  - Day-by-Day Navigation with logical date & "Today" reset
//  - Macro Progress Bars (Proteins, Fats, Carbs) & Daily Calorie Rings
//  - Category Cards (Breakfast, Lunch, Dinner, Snack) with Quota Percentages
//  - Interactive Food Picker & Mifflin-St Jeor Calculator Modals
//

import SwiftUI
import SwiftData

public struct NutritionWeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \MealItem.timestamp, order: .reverse) private var allMeals: [MealItem]
    @Query(sort: \WeightEntryItem.date, order: .reverse) private var weightEntries: [WeightEntryItem]

    private var prefs: NutritionPreferences { NutritionPreferences.shared }

    // Top Mode: 0: Питание, 1: График веса
    @State private var selectedMode: Int = 0

    // Active Date
    @State private var currentDate: Date = Date()

    // Modals
    @State private var isAddFoodOpen: Bool = false
    @State private var selectedCategoryForAdd: String = "meal_breakfast"
    @State private var isCalcOpen: Bool = false
    @State private var isWeightModalOpen: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var currentDateStr: String {
        currentDate.yyyyMMddString
    }

    // Filter meals for active date
    private var todayMeals: [MealItem] {
        allMeals.filter { $0.date == currentDateStr }
    }

    private var totalCalories: Double { todayMeals.reduce(0) { $0 + $1.calories } }
    private var totalProteins: Double { todayMeals.reduce(0) { $0 + $1.proteins } }
    private var totalFats: Double { todayMeals.reduce(0) { $0 + $1.fats } }
    private var totalCarbs: Double { todayMeals.reduce(0) { $0 + $1.carbs } }

    private var targetCal: Double { prefs.targetCalories }
    private var targetProt: Double { prefs.targetProteins }
    private var targetFat: Double { prefs.targetFats }
    private var targetCarb: Double { prefs.targetCarbs }

    private var latestWeight: Double {
        weightEntries.first?.weightKg ?? prefs.weightKg
    }

    public init() {}

    public var body: some View {
        ZStack {
            NotebookCanvasView(
                patternType: .lines,
                patternSize: 32,
                marginLineX: 50,
                isDarkTheme: isDark
            )

            VStack(spacing: 0) {
                // Top App Bar: Mode Switcher & Quick Actions
                VStack(spacing: 10) {
                    HStack {
                        // Dual Mode Segmented Picker
                        HStack(spacing: 4) {
                            ModeSegmentButton(
                                title: "🥑 Питание",
                                isSelected: selectedMode == 0,
                                accent: theme.currentAccent.primary
                            ) {
                                MiodiHapticFeedback.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedMode = 0
                                }
                            }

                            ModeSegmentButton(
                                title: "⚖️ Вес и график",
                                isSelected: selectedMode == 1,
                                accent: theme.currentAccent.primary
                            ) {
                                MiodiHapticFeedback.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedMode = 1
                                }
                            }
                        }
                        .padding(3)
                        .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .clipShape(Capsule())

                        Spacer()

                        // Calculator & Target Button
                        Button {
                            MiodiHapticFeedback.lightClick()
                            isCalcOpen = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("🪄")
                                Text("Норма")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(theme.currentAccent.primary.opacity(0.15)))
                            .foregroundStyle(theme.currentAccent.primary)
                        }
                    }

                    // Date Navigator Bar (Only in Nutrition Mode)
                    if selectedMode == 0 {
                        HStack {
                            Button {
                                MiodiHapticFeedback.lightClick()
                                currentDate = currentDate.adding(days: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(8)
                                    .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                                    .clipShape(Circle())
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text(currentDate.userFriendlyDateString())
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                Text(String(format: "%.0f / %.0f ккал", totalCalories, targetCal))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                MiodiHapticFeedback.lightClick()
                                currentDate = currentDate.adding(days: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(8)
                                    .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                                    .clipShape(Circle())
                            }

                            if !Calendar.current.isDateInToday(currentDate) {
                                Button("Сегодня") {
                                    MiodiHapticFeedback.lightClick()
                                    currentDate = Date()
                                }
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.currentAccent.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isDark ? MiodiStaticColors.darkTopBarBg : Color.white.opacity(0.92))

                Divider()

                // Content Area
                if selectedMode == 0 {
                    // ================= NUTRITION & MEALS VIEW =================
                    ScrollView {
                        VStack(spacing: 14) {
                            // 1. Calories & Macro Progress Card
                            VStack(spacing: 12) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                                            Text(String(format: "%.0f", totalCalories))
                                                .font(.system(size: 28, weight: .black))
                                                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                            Text(String(format: "/ %.0f ккал", targetCal))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.secondary)
                                        }

                                        let remaining = targetCal - totalCalories
                                        if remaining >= 0 {
                                            Text("Осталось \(Int(remaining)) ккал")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(Color(hex: 0x10B981))
                                        } else {
                                            Text("Перебор на \(Int(abs(remaining))) ккал")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(Color(hex: 0xEF4444))
                                        }
                                    }

                                    Spacer()

                                    // Circular Calorie Gauge
                                    ZStack {
                                        Circle()
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                                        let ratio = targetCal > 0 ? min(1.0, totalCalories / targetCal) : 0
                                        Circle()
                                            .trim(from: 0, to: CGFloat(ratio))
                                            .stroke(
                                                totalCalories > targetCal ? Color(hex: 0xEF4444) : theme.currentAccent.primary,
                                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))
                                        Text("\(Int(ratio * 100))%")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .frame(width: 48, height: 48)
                                }

                                // Macro Progress Bars (Белки, Жиры, Углеводы)
                                HStack(spacing: 10) {
                                    MacroProgressBar(
                                        title: "Белки",
                                        consumed: totalProteins,
                                        target: targetProt,
                                        color: MiodiStaticColors.macroProtein
                                    )

                                    MacroProgressBar(
                                        title: "Жиры",
                                        consumed: totalFats,
                                        target: targetFat,
                                        color: MiodiStaticColors.macroFat
                                    )

                                    MacroProgressBar(
                                        title: "Углеводы",
                                        consumed: totalCarbs,
                                        target: targetCarb,
                                        color: MiodiStaticColors.macroCarb
                                    )
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.05), radius: 8, x: 0, y: 3)
                            )

                            // Empty State quick-add banner when no meals logged yet for the day
                            if todayMeals.isEmpty {
                                Button {
                                    MiodiHapticFeedback.light()
                                    selectedCategoryForAdd = currentMealTypeByTime()
                                    isAddFoodOpen = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(theme.currentAccent.primary)
                                        Text("Пока нет записей о еде за этот день")
                                            .font(.system(size: 13, weight: .medium))
                                            .italic()
                                            .foregroundStyle(isDark ? MiodiStaticColors.darkTextSecondary : Color.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 72)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(isDark ? Color(hex: 0x141824) : Color(hex: 0xFAFAFA))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(theme.currentAccent.primary.opacity(isDark ? 0.35 : 0.22), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            // 2. Meal Categories: Breakfast, Lunch, Dinner, Snack
                            let categories: [(id: String, name: String, icon: String, color: Color, defaultPct: Int)] = [
                                ("meal_breakfast", "Завтрак", "🍳", Color(hex: 0xF59E0B), prefs.mealPercentages[safe: 0] ?? 25),
                                ("meal_lunch", "Обед", "🍲", Color(hex: 0x10B981), prefs.mealPercentages[safe: 1] ?? 35),
                                ("meal_dinner", "Ужин", "🍗", Color(hex: 0x6366F1), prefs.mealPercentages[safe: 2] ?? 25),
                                ("meal_snack", "Перекус", "🍌", Color(hex: 0xEC4899), prefs.mealPercentages[safe: 3] ?? 15)
                            ]

                            VStack(spacing: 12) {
                                ForEach(categories, id: \.id) { cat in
                                    let catMeals = todayMeals.filter { isMealInType($0, catType: cat.id) }
                                    let catCal = catMeals.reduce(0.0) { $0 + $1.calories }
                                    let quotaCal = (targetCal * Double(cat.defaultPct) / 100.0).rounded()

                                    MealCategorySectionCard(
                                        categoryId: cat.id,
                                        name: cat.name,
                                        icon: cat.icon,
                                        color: cat.color,
                                        quotaPercent: cat.defaultPct,
                                        quotaCalories: quotaCal,
                                        consumedCalories: catCal,
                                        meals: catMeals,
                                        isDark: isDark,
                                        accent: theme.currentAccent.primary,
                                        onAdd: {
                                            selectedCategoryForAdd = cat.id
                                            isAddFoodOpen = true
                                        },
                                        onDeleteMeal: { meal in
                                            deleteMeal(meal)
                                        }
                                    )
                                }
                            }

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                    }
                } else {
                    // ================= WEIGHT DYNAMICS & CHART VIEW =================
                    WeightChartModalView()
                }
            }
        }
        .sheet(isPresented: $isAddFoodOpen) {
            FoodPickerModalView(
                targetDate: currentDateStr,
                initialMealType: selectedCategoryForAdd
            )
        }
        .sheet(isPresented: $isCalcOpen) {
            NutritionCalcModalView()
        }
    }

    private func deleteMeal(_ meal: MealItem) {
        MiodiHapticFeedback.warning()
        modelContext.delete(meal)
        try? modelContext.save()
    }

    private func isMealInType(_ meal: MealItem, catType: String) -> Bool {
        let m = meal.mealType.lowercased()
        switch catType {
        case "meal_breakfast":
            return m.contains("breakfast") || m.contains("завтрак") || m.contains("сніданок")
        case "meal_lunch":
            return m.contains("lunch") || m.contains("обед") || m.contains("обід")
        case "meal_dinner":
            return m.contains("dinner") || m.contains("ужин") || m.contains("вечеря")
        case "meal_snack":
            return m.contains("snack") || m.contains("перекус")
        default:
            return m == catType
        }
    }

    private func currentMealTypeByTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<12:
            return "meal_breakfast"
        case 12..<17:
            return "meal_lunch"
        case 17..<22:
            return "meal_dinner"
        default:
            return "meal_snack"
        }
    }
}

private struct ModeSegmentButton: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? accent : Color.clear)
                .foregroundStyle(isSelected ? Color.white : .secondary)
                .clipShape(Capsule())
        }
    }
}

private struct MacroProgressBar: View {
    let title: String
    let consumed: Double
    let target: Double
    let color: Color

    private var ratio: Double {
        target > 0 ? min(1.0, consumed / target) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                Spacer()
                Text(String(format: "%.0fг", consumed))
                    .font(.system(size: 11, weight: .black))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(ratio), height: 6)
                }
            }
            .frame(height: 6)

            Text(String(format: "из %.0fг", target))
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct MealCategorySectionCard: View {
    let categoryId: String
    let name: String
    let icon: String
    let color: Color
    let quotaPercent: Int
    let quotaCalories: Double
    let consumedCalories: Double
    let meals: [MealItem]
    let isDark: Bool
    let accent: Color
    let onAdd: () -> Void
    let onDeleteMeal: (MealItem) -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Category Header
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                        Text("\(quotaPercent)%")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(color.opacity(0.15))
                            .foregroundStyle(color)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Text(String(format: "%.0f / %.0f ккал", consumedCalories, quotaCalories))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    MiodiHapticFeedback.lightClick()
                    onAdd()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Добавить")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
                }
            }

            // Category Mini Progress Bar
            GeometryReader { geo in
                let ratio = quotaCalories > 0 ? min(1.0, consumedCalories / quotaCalories) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(ratio), height: 4)
                }
            }
            .frame(height: 4)

            // Meals List in this category
            if !meals.isEmpty {
                VStack(spacing: 6) {
                    ForEach(meals) { meal in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.title)
                                    .font(.system(size: 13.5, weight: .medium))
                                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                Text(String(format: "%.0fг • Б: %.1fг  Ж: %.1fг  У: %.1fг", meal.weightGrams, meal.proteins, meal.fats, meal.carbs))
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(String(format: "%.0f ккал", meal.calories))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(color)

                            Button {
                                onDeleteMeal(meal)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                    .padding(.leading, 6)
                            }
                        }
                        .padding(.vertical, 3)

                        if meal.id != meals.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? MiodiStaticColors.darkCardBg : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.04), radius: 4, x: 0, y: 2)
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
