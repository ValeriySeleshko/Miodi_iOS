//
//  FoodPickerModalView.swift
//  Plan4U_iOS
//
//  Food Database, Instant Search, Live Grams Recalculation, Custom Food & Favorites.
//

import SwiftUI
import SwiftData

public struct FoodPickerModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \CustomFoodItem.timestamp, order: .reverse) private var customFoods: [CustomFoodItem]

    public let targetDate: String
    public let initialMealType: String

    @State private var searchQuery: String = ""
    @State private var filterTab: Int = 0 // 0: Все, 1: Избранное, 2: Мои продукты

    // Selected food for portion calculation
    @State private var selectedFood: UnifiedFoodItem? = nil
    @State private var portionGrams: Double = 100.0
    @State private var selectedMealType: String

    // Custom food creation modal
    @State private var isCreatingCustom: Bool = false
    @State private var customName: String = ""
    @State private var customCalStr: String = ""
    @State private var customProtStr: String = ""
    @State private var customFatStr: String = ""
    @State private var customCarbStr: String = ""

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(targetDate: String, initialMealType: String = "meal_breakfast") {
        self.targetDate = targetDate
        self.initialMealType = initialMealType
        _selectedMealType = State(initialValue: initialMealType)
    }

    // Unified Food representation
    private var allUnifiedItems: [UnifiedFoodItem] {
        let staples = StapleFoodDictionary.allItems.map { item in
            let isFav = customFoods.first(where: { $0.barcode == item.id })?.isFavorite ?? false
            return UnifiedFoodItem(
                id: item.id,
                name: item.name,
                nameEn: item.nameEn,
                caloriesPer100g: item.calories,
                proteinsPer100g: item.proteins,
                fatsPer100g: item.fats,
                carbsPer100g: item.carbs,
                category: item.category,
                isCustom: false,
                isFavorite: isFav
            )
        }

        let customs = customFoods.map { item in
            UnifiedFoodItem(
                id: item.id,
                name: item.name,
                nameEn: item.brand ?? "",
                caloriesPer100g: item.caloriesPer100g,
                proteinsPer100g: item.proteinsPer100g,
                fatsPer100g: item.fatsPer100g,
                carbsPer100g: item.carbsPer100g,
                category: "Мои продукты",
                isCustom: true,
                isFavorite: item.isFavorite
            )
        }

        return customs + staples
    }

    private var filteredItems: [UnifiedFoodItem] {
        var list = allUnifiedItems
        if filterTab == 1 {
            list = list.filter { $0.isFavorite }
        } else if filterTab == 2 {
            list = list.filter { $0.isCustom }
        }

        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return list
        }

        let tokens = q.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return list.filter { item in
            let text = "\(item.name) \(item.nameEn) \(item.category)".lowercased()
            return tokens.allSatisfy { text.contains($0) }
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar & Filter Tabs
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Поиск по базе продуктов...", text: $searchQuery)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Filter Segmented Chips
                    HStack(spacing: 8) {
                        FilterChip(title: "Все (\(allUnifiedItems.count))", isSelected: filterTab == 0, accent: theme.currentAccent.primary) {
                            MiodiHapticFeedback.selection()
                            filterTab = 0
                        }
                        FilterChip(title: "⭐ Избранное", isSelected: filterTab == 1, accent: theme.currentAccent.primary) {
                            MiodiHapticFeedback.selection()
                            filterTab = 1
                        }
                        FilterChip(title: "📝 Мои продукты", isSelected: filterTab == 2, accent: theme.currentAccent.primary) {
                            MiodiHapticFeedback.selection()
                            filterTab = 2
                        }
                        Spacer()
                        Button {
                            MiodiHapticFeedback.lightClick()
                            isCreatingCustom = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(theme.currentAccent.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isDark ? MiodiStaticColors.darkTopBarBg : Color.white)

                Divider()

                // Products List
                if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary.opacity(0.6))
                        Text("Ничего не найдено")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Button("Создать свой продукт") {
                            customName = searchQuery
                            isCreatingCustom = true
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.currentAccent.primary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            Button {
                                MiodiHapticFeedback.lightClick()
                                selectedFood = item
                                portionGrams = 100.0
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(item.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                                            if item.isCustom {
                                                Text("Свой")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(theme.currentAccent.primary.opacity(0.15))
                                                    .foregroundStyle(theme.currentAccent.primary)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                            }
                                        }

                                        Text(String(format: "на 100г: %.0f ккал  •  Б: %.1fг  Ж: %.1fг  У: %.1fг", item.caloriesPer100g, item.proteinsPer100g, item.fatsPer100g, item.carbsPer100g))
                                            .font(.system(size: 11.5))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    // Favorite Toggle Button
                                    Button {
                                        toggleFavorite(item)
                                    } label: {
                                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                                            .font(.system(size: 16))
                                            .foregroundStyle(item.isFavorite ? Color(hex: 0xF59E0B) : Color.secondary.opacity(0.4))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if item.isCustom {
                                    Button(role: .destructive) {
                                        deleteCustom(item)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("База продуктов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            // Portion & Macro Calculator Sheet
            .sheet(item: $selectedFood) { food in
                PortionCalcSheet(
                    food: food,
                    portionGrams: $portionGrams,
                    selectedMealType: $selectedMealType,
                    isDark: isDark,
                    theme: theme,
                    onAdd: { grams, cal, p, f, c, mealType in
                        logMeal(foodName: food.name, grams: grams, calories: cal, proteins: p, fats: f, carbs: c, mealType: mealType)
                        selectedFood = nil
                        dismiss()
                    }
                )
                .presentationDetents([.fraction(0.55)])
            }
            // Create Custom Food Modal
            .sheet(isPresented: $isCreatingCustom) {
                NavigationStack {
                    Form {
                        Section("Название") {
                            TextField("Название продукта", text: $customName)
                        }
                        Section("Пищевая ценность на 100 грамм") {
                            TextField("Калории (ккал)", text: $customCalStr).keyboardType(.decimalPad)
                            TextField("Белки (г)", text: $customProtStr).keyboardType(.decimalPad)
                            TextField("Жиры (г)", text: $customFatStr).keyboardType(.decimalPad)
                            TextField("Углеводы (г)", text: $customCarbStr).keyboardType(.decimalPad)
                        }
                    }
                    .navigationTitle("Новый продукт")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") { isCreatingCustom = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Сохранить") {
                                saveCustomFood()
                                isCreatingCustom = false
                            }
                            .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .presentationDetents([.fraction(0.5)])
            }
        }
    }

    private func toggleFavorite(_ item: UnifiedFoodItem) {
        MiodiHapticFeedback.lightClick()
        if let existing = customFoods.first(where: { $0.id == item.id || $0.barcode == item.id }) {
            existing.isFavorite.toggle()
        } else {
            let newFav = CustomFoodItem(
                name: item.name,
                caloriesPer100g: item.caloriesPer100g,
                proteinsPer100g: item.proteinsPer100g,
                fatsPer100g: item.fatsPer100g,
                carbsPer100g: item.carbsPer100g,
                brand: item.nameEn,
                barcode: item.id,
                isFavorite: true
            )
            modelContext.insert(newFav)
        }
        try? modelContext.save()
    }

    private func deleteCustom(_ item: UnifiedFoodItem) {
        if let existing = customFoods.first(where: { $0.id == item.id }) {
            modelContext.delete(existing)
            try? modelContext.save()
            MiodiHapticFeedback.warning()
        }
    }

    private func saveCustomFood() {
        let name = customName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let cal = Double(customCalStr.replacingOccurrences(of: ",", with: ".")) ?? 0
        let p = Double(customProtStr.replacingOccurrences(of: ",", with: ".")) ?? 0
        let f = Double(customFatStr.replacingOccurrences(of: ",", with: ".")) ?? 0
        let c = Double(customCarbStr.replacingOccurrences(of: ",", with: ".")) ?? 0

        let item = CustomFoodItem(
            name: name,
            caloriesPer100g: cal,
            proteinsPer100g: p,
            fatsPer100g: f,
            carbsPer100g: c,
            brand: "Мой продукт",
            isFavorite: false
        )
        modelContext.insert(item)
        try? modelContext.save()
        MiodiHapticFeedback.success()

        customName = ""
        customCalStr = ""
        customProtStr = ""
        customFatStr = ""
        customCarbStr = ""
    }

    private func logMeal(foodName: String, grams: Double, calories: Double, proteins: Double, fats: Double, carbs: Double, mealType: String) {
        let meal = MealItem(
            date: targetDate,
            mealType: mealType,
            title: foodName,
            calories: calories,
            proteins: proteins,
            fats: fats,
            carbs: carbs,
            weightGrams: grams
        )
        modelContext.insert(meal)
        try? modelContext.save()
        MiodiHapticFeedback.success()
    }
}

public struct UnifiedFoodItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let nameEn: String
    public let caloriesPer100g: Double
    public let proteinsPer100g: Double
    public let fatsPer100g: Double
    public let carbsPer100g: Double
    public let category: String
    public let isCustom: Bool
    public var isFavorite: Bool
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? accent.opacity(0.15) : Color.primary.opacity(0.06))
                .foregroundStyle(isSelected ? accent : .secondary)
                .clipShape(Capsule())
        }
    }
}

private struct PortionCalcSheet: View {
    let food: UnifiedFoodItem
    @Binding var portionGrams: Double
    @Binding var selectedMealType: String
    let isDark: Bool
    let theme: MiodiThemeManager
    let onAdd: (Double, Double, Double, Double, Double, String) -> Void

    private var ratio: Double { portionGrams / 100.0 }
    private var totalCalories: Double { food.caloriesPer100g * ratio }
    private var totalProt: Double { food.proteinsPer100g * ratio }
    private var totalFat: Double { food.fatsPer100g * ratio }
    private var totalCarb: Double { food.carbsPer100g * ratio }

    var body: some View {
        VStack(spacing: 16) {
            // Food Header
            VStack(spacing: 2) {
                Text(food.name)
                    .font(.system(size: 17, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(String(format: "на 100г: %.0f ккал • Б: %.1f • Ж: %.1f • У: %.1f", food.caloriesPer100g, food.proteinsPer100g, food.fatsPer100g, food.carbsPer100g))
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)

            // Grams Stepper & Text
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button {
                        if portionGrams > 10 { portionGrams -= 10 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.currentAccent.primary)
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(Int(portionGrams))")
                            .font(.system(size: 28, weight: .black))
                        Text("грамм")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 100)

                    Button {
                        if portionGrams < 2000 { portionGrams += 10 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.currentAccent.primary)
                    }
                }

                // Quick Gram Buttons
                HStack(spacing: 8) {
                    QuickGramBtn(label: "-50г") { if portionGrams > 50 { portionGrams -= 50 } }
                    QuickGramBtn(label: "100г") { portionGrams = 100 }
                    QuickGramBtn(label: "150г") { portionGrams = 150 }
                    QuickGramBtn(label: "200г") { portionGrams = 200 }
                    QuickGramBtn(label: "+50г") { portionGrams += 50 }
                    QuickGramBtn(label: "+100г") { portionGrams += 100 }
                }
            }

            // Live Recalculated Macros
            HStack(spacing: 10) {
                LiveMacroCard(title: "Калории", val: totalCalories, unit: "ккал", color: Color(hex: 0xD95300))
                LiveMacroCard(title: "Белки", val: totalProt, unit: "г", color: MiodiStaticColors.macroProtein)
                LiveMacroCard(title: "Жиры", val: totalFat, unit: "г", color: MiodiStaticColors.macroFat)
                LiveMacroCard(title: "Углеводы", val: totalCarb, unit: "г", color: MiodiStaticColors.macroCarb)
            }

            // Meal Category Picker: Breakfast, Lunch, Dinner, Snack
            Picker("Приём пищи", selection: $selectedMealType) {
                Text("🍳 Завтрак").tag("meal_breakfast")
                Text("🍲 Обед").tag("meal_lunch")
                Text("🍗 Ужин").tag("meal_dinner")
                Text("🍌 Перекус").tag("meal_snack")
            }
            .pickerStyle(.segmented)

            // Add button
            Button {
                onAdd(portionGrams, totalCalories, totalProt, totalFat, totalCarb, selectedMealType)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Добавить в приём пищи")
                }
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(theme.currentAccent.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
    }
}

private struct QuickGramBtn: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

private struct LiveMacroCard: View {
    let title: String
    let val: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(String(format: "%.0f", val))
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
