//
//  ArchiveDayStampsView.swift
//  Plan4U_iOS
//
//  Vintage Notebook Wax/Ink Seal Stamps for Archive Day Overview.
//  100% pixel, color, mathematical, and haptic match with Android ArchiveDayStamps.kt.
//

import SwiftUI

// MARK: - Color Palettes (Identical to Android ArchiveDayStamps.kt)
public let CategoryColorPalette: [Color] = [
    Color(hex: 0xE11D48),
    Color(hex: 0x2563EB),
    Color(hex: 0x10B981),
    Color(hex: 0xF59E0B),
    Color(hex: 0x8B5CF6),
    Color(hex: 0x06B6D4),
    Color(hex: 0xEC4899),
    Color(hex: 0x84CC16)
]

public let NutritionCategoryPalette: [Color] = [
    Color(hex: 0xF59E0B), // Amber (Завтрак)
    Color(hex: 0x10B981), // Emerald (Обед)
    Color(hex: 0x6366F1), // Indigo (Ужин)
    Color(hex: 0xEC4899), // Pink (Перекус)
    Color(hex: 0x06B6D4), // Cyan
    Color(hex: 0x8B5CF6), // Purple
    Color(hex: 0xF97316), // Orange
    Color(hex: 0x14B8A6)  // Teal
]

public let DefaultMealColors: [String: Color] = [
    "Завтрак": Color(hex: 0xF59E0B),
    "meal_breakfast": Color(hex: 0xF59E0B),
    "Breakfast": Color(hex: 0xF59E0B),
    "Сніданок": Color(hex: 0xF59E0B),
    "Pusryčiai": Color(hex: 0xF59E0B),
    "Frühstück": Color(hex: 0xF59E0B),
    "Petit-déjeuner": Color(hex: 0xF59E0B),
    "Desayuno": Color(hex: 0xF59E0B),
    "Śniadanie": Color(hex: 0xF59E0B),
    "Café da manhã": Color(hex: 0xF59E0B),
    "Colazione": Color(hex: 0xF59E0B),
    "Kahvaltı": Color(hex: 0xF59E0B),
    "Sarapan": Color(hex: 0xF59E0B),
    "Обед": Color(hex: 0x10B981),
    "meal_lunch": Color(hex: 0x10B981),
    "Lunch": Color(hex: 0x10B981),
    "Обід": Color(hex: 0x10B981),
    "Pietūs": Color(hex: 0x10B981),
    "Mittagessen": Color(hex: 0x10B981),
    "Déjeuner": Color(hex: 0x10B981),
    "Almuerzo": Color(hex: 0x10B981),
    "Obiad": Color(hex: 0x10B981),
    "Almoço": Color(hex: 0x10B981),
    "Pranzo": Color(hex: 0x10B981),
    "Öğle yemeği": Color(hex: 0x10B981),
    "Makan Siang": Color(hex: 0x10B981),
    "Ужин": Color(hex: 0x6366F1),
    "meal_dinner": Color(hex: 0x6366F1),
    "Dinner": Color(hex: 0x6366F1),
    "Вечеря": Color(hex: 0x6366F1),
    "Vakarienė": Color(hex: 0x6366F1),
    "Abendessen": Color(hex: 0x6366F1),
    "Dîner": Color(hex: 0x6366F1),
    "Cena": Color(hex: 0x6366F1),
    "Kolacja": Color(hex: 0x6366F1),
    "Jantar": Color(hex: 0x6366F1),
    "Akşam yemeği": Color(hex: 0x6366F1),
    "Makan Malam": Color(hex: 0x6366F1),
    "Перекус": Color(hex: 0xEC4899),
    "meal_snack": Color(hex: 0xEC4899),
    "Snack": Color(hex: 0xEC4899),
    "Užkandis": Color(hex: 0xEC4899),
    "Collation": Color(hex: 0xEC4899),
    "Merienda": Color(hex: 0xEC4899),
    "Przekąska": Color(hex: 0xEC4899),
    "Lanche": Color(hex: 0xEC4899),
    "Spuntino": Color(hex: 0xEC4899),
    "Atıştırmalık": Color(hex: 0xEC4899),
    "Camilan": Color(hex: 0xEC4899)
]

private let MealOrderMap: [String: Int] = [
    "Завтрак": 0, "meal_breakfast": 0, "Сніданок": 0, "Breakfast": 0, "Pusryčiai": 0, "Frühstück": 0, "Petit-déjeuner": 0, "Desayuno": 0, "Śniadanie": 0, "Café da manhã": 0, "Colazione": 0, "Kahvaltı": 0, "Sarapan": 0,
    "Обед": 1, "meal_lunch": 1, "Обід": 1, "Lunch": 1, "Pietūs": 1, "Mittagessen": 1, "Déjeuner": 1, "Almuerzo": 1, "Obiad": 1, "Almoço": 1, "Pranzo": 1, "Öğle yemeği": 1, "Makan Siang": 1,
    "Ужин": 2, "meal_dinner": 2, "Вечеря": 2, "Dinner": 2, "Vakarienė": 2, "Abendessen": 2, "Dîner": 2, "Cena": 2, "Kolacja": 2, "Jantar": 2, "Akşam yemeği": 2, "Makan Malam": 2,
    "Перекус": 3, "meal_snack": 3, "Snack": 3, "Užkandis": 3, "Collation": 3, "Merienda": 3, "Przekąska": 3, "Lanche": 3, "Spuntino": 3, "Atıştırmalık": 3, "Camilan": 3
]

// MARK: - Mathematical Pseudo-Random for Ink Speckles (1:1 Java/Kotlin Random)
private struct KotlinRandom {
    private var seed: UInt64

    init(seed: Int32) {
        self.seed = (UInt64(bitPattern: Int64(seed)) ^ 0x5DEECE66D) & ((1 << 48) - 1)
    }

    private mutating func next(bits: Int) -> Int32 {
        seed = (seed &* 0x5DEECE66D &+ 0xB) & ((1 << 48) - 1)
        return Int32(seed >> (48 - bits))
    }

    mutating func nextFloat() -> CGFloat {
        let val = next(bits: 24)
        return CGFloat(Float(val) / Float(1 << 24))
    }
}

/// Java String.hashCode() replica for 100% cross-platform deterministic seed matching
public func javaStringHashCode(_ string: String) -> Int32 {
    var h: Int32 = 0
    for byte in string.utf8 {
        h = 31 &* h &+ Int32(byte)
    }
    return h
}

// MARK: - Entry ViewModels for Interoperability
public struct ArchiveFinanceEntry: Identifiable, Sendable {
    public let id: String
    public let type: String // "expense", "income", "transfer"
    public let amount: Double
    public let category: String
    public let date: String // "yyyy-MM-dd"
    public let note: String?
    public let currency: String
    public let originalAmount: Double
    public let toCurrency: String?
    public let toAmount: Double?

    public init(
        id: String = UUID().uuidString,
        type: String = "expense",
        amount: Double = 0.0,
        category: String = "",
        date: String = "",
        note: String? = nil,
        currency: String = "RUB",
        originalAmount: Double = 0.0,
        toCurrency: String? = nil,
        toAmount: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
        self.currency = currency
        self.originalAmount = originalAmount > 0.0 ? originalAmount : amount
        self.toCurrency = toCurrency
        self.toAmount = toAmount
    }

    public init(item: FinanceItem) {
        self.id = item.id
        self.type = item.type
        self.amount = item.amount
        self.category = item.category
        self.date = item.date
        self.note = item.note
        self.currency = item.currency
        self.originalAmount = item.effectiveOriginalAmount
        self.toCurrency = item.toCurrency
        self.toAmount = item.toAmount
    }
}

public struct ArchiveMealEntry: Identifiable, Sendable {
    public let id: String
    public let date: String
    public let mealType: String
    public let foodName: String
    public let calories: Double
    public let proteins: Double
    public let fats: Double
    public let carbs: Double
    public let weightGrams: Double

    public init(
        id: String = UUID().uuidString,
        date: String = "",
        mealType: String = "breakfast",
        foodName: String = "",
        calories: Double = 0.0,
        proteins: Double = 0.0,
        fats: Double = 0.0,
        carbs: Double = 0.0,
        weightGrams: Double = 0.0
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.foodName = foodName
        self.calories = calories
        self.proteins = proteins
        self.fats = fats
        self.carbs = carbs
        self.weightGrams = weightGrams
    }

    public init(item: MealItem) {
        self.id = item.id
        self.date = item.date
        self.mealType = item.mealType
        self.foodName = item.title
        self.calories = item.calories
        self.proteins = item.proteins
        self.fats = item.fats
        self.carbs = item.carbs
        self.weightGrams = item.weightGrams
    }
}

// MARK: - 1. ArchiveFinanceStamp
/// Vintage Notebook Wax/Ink Seal Stamp for Finance Day Overview in Archive.
public struct ArchiveFinanceStamp: View {
    public let date: String
    public let entries: [ArchiveFinanceEntry]
    public let currency: String
    public let isNoSpendActive: Bool
    public let isDarkTheme: Bool
    public let onClick: (() -> Void)?

    public init(
        date: String,
        entries: [ArchiveFinanceEntry],
        currency: String = "₽",
        isNoSpendActive: Bool = false,
        isDarkTheme: Bool = false,
        onClick: (() -> Void)? = nil
    ) {
        self.date = date
        self.entries = entries
        self.currency = currency
        self.isNoSpendActive = isNoSpendActive
        self.isDarkTheme = isDarkTheme
        self.onClick = onClick
    }

    public init(
        date: String,
        financeItems: [FinanceItem],
        currency: String = "₽",
        isNoSpendActive: Bool? = nil,
        isDarkTheme: Bool = false,
        onClick: (() -> Void)? = nil
    ) {
        let noSpend = isNoSpendActive ?? NoSpendManager.shared.isNoSpend(date: date)
        self.init(
            date: date,
            entries: financeItems.map { ArchiveFinanceEntry(item: $0) },
            currency: currency,
            isNoSpendActive: noSpend,
            isDarkTheme: isDarkTheme,
            onClick: onClick
        )
    }

    private var dayEntries: [ArchiveFinanceEntry] {
        entries.filter { $0.date == date }
    }

    private var expenses: [ArchiveFinanceEntry] {
        dayEntries.filter { $0.type == "expense" }
    }

    private var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var isZeroSpendCup: Bool {
        expenses.isEmpty && isNoSpendActive
    }

    private var categorySlices: [(sweep: CGFloat, color: Color)] {
        if totalExpense <= 0 { return [] }
        var grouped: [String: Double] = [:]
        for exp in expenses {
            grouped[exp.category, default: 0] += exp.amount
        }
        return grouped.enumerated().map { idx, element in
            let sweep = CGFloat((element.value / totalExpense) * 360.0)
            let color = CategoryColorPalette[idx % CategoryColorPalette.count]
            return (sweep, color)
        }
    }

    private var formattedExpense: String {
        if totalExpense <= 0 {
            return "0\(currency)"
        } else if totalExpense >= 10000 {
            return "\(Int(totalExpense / 1000))k\(currency)"
        } else if totalExpense == floor(totalExpense) {
            return "\(Int(totalExpense))\(currency)"
        } else {
            return String(format: "%.1f%@", totalExpense, currency)
        }
    }

    private var daySeed: Int32 {
        javaStringHashCode(date)
    }

    private var stampRotation: Double {
        -4.0 + Double(abs(daySeed % 60)) / 12.0
    }

    private var stampBg: Color {
        if isZeroSpendCup {
            return isDarkTheme ? Color(hex: 0x281E0D) : Color(hex: 0xFFFBEB)
        } else {
            return isDarkTheme ? Color(hex: 0x221721) : Color(hex: 0xFFF6F8)
        }
    }

    private var stampBorderColor: Color {
        if isZeroSpendCup {
            return isDarkTheme ? Color(hex: 0xFBBF24) : Color(hex: 0xD97706)
        } else {
            return isDarkTheme ? Color(hex: 0xFB7185).opacity(0.88) : Color(hex: 0xBE123C).opacity(0.92)
        }
    }

    public var body: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            onClick?()
        } label: {
            ZStack {
                // Vector Canvas for Stamp Ring, Slices, Dashed Accent and Ink Speckles
                Canvas { context, size in
                    let strokeWidth: CGFloat = 4.5
                    let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
                    let radius = (min(size.width, size.height) - strokeWidth) / 2.0

                    if isZeroSpendCup {
                        let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                        context.stroke(Path(ellipseIn: circleRect), with: .color(stampBorderColor.opacity(0.85)), lineWidth: strokeWidth)
                    } else if categorySlices.isEmpty {
                        let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                        context.stroke(Path(ellipseIn: circleRect), with: .color(stampBorderColor.opacity(0.25)), lineWidth: strokeWidth)
                    } else {
                        var currentAngle: Double = -90.0
                        let gap: Double = categorySlices.count > 1 ? 3.0 : 0.0
                        for (sweep, color) in categorySlices {
                            let arcSweep = max(Double(sweep) - gap, 1.5)
                            var path = Path()
                            path.addArc(
                                center: center,
                                radius: radius,
                                startAngle: Angle(degrees: currentAngle + (gap / 2.0)),
                                endAngle: Angle(degrees: currentAngle + (gap / 2.0) + arcSweep),
                                clockwise: false
                            )
                            let isRound = categorySlices.count > 1 && arcSweep > 8.0
                            context.stroke(
                                path,
                                with: .color(color),
                                style: StrokeStyle(lineWidth: strokeWidth, lineCap: isRound ? .round : .butt)
                            )
                            currentAngle += Double(sweep)
                        }
                    }

                    // Inner vintage seal dashed ring
                    let dashedRadius = radius - 7.0
                    if dashedRadius > 0 {
                        let dashedRect = CGRect(x: center.x - dashedRadius, y: center.y - dashedRadius, width: dashedRadius * 2, height: dashedRadius * 2)
                        context.stroke(
                            Path(ellipseIn: dashedRect),
                            with: .color(stampBorderColor.opacity(0.32)),
                            style: StrokeStyle(lineWidth: 1.0, dash: [5, 4], dashPhase: CGFloat(abs(daySeed % 12)))
                        )
                    }

                    // Realistic ink grunge & paper grain speckles mask (50 deterministic speckles)
                    var rnd = KotlinRandom(seed: daySeed)
                    let maxR = min(size.width, size.height) / 2.0
                    for i in 0..<50 {
                        let angle = rnd.nextFloat() * 2.0 * .pi
                        let dist = rnd.nextFloat() * (maxR - 2.0)
                        let x = center.x + cos(angle) * dist
                        let y = center.y + sin(angle) * dist
                        let dotRadius = 0.6 + rnd.nextFloat() * 1.5
                        let isInkSkip = (i % 3 == 0)
                        let speckColor = isInkSkip ?
                            stampBg.opacity(0.40 + Double(rnd.nextFloat()) * 0.35) :
                            stampBorderColor.opacity(0.08 + Double(rnd.nextFloat()) * 0.18)

                        let rect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(speckColor))
                    }
                }
                .frame(width: 58, height: 58)

                // Inner content
                if isZeroSpendCup {
                    VStack(spacing: 1) {
                        Text("🏆")
                            .font(.system(size: 17))
                        Text("БЕЗ ТРАТ")
                            .font(.system(size: 8.5, weight: .heavy))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0xFDE68A) : Color(hex: 0xB45309))
                            .lineLimit(1)
                    }
                } else {
                    VStack(spacing: 1) {
                        Text("💰")
                            .font(.system(size: 13.5))
                        Text(formattedExpense)
                            .font(.system(size: formattedExpense.count > 5 ? 10.5 : 12.5, weight: .bold))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x0F172A))
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 68, height: 68)
            .background(stampBg)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(stampBorderColor, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            .rotationEffect(.degrees(stampRotation))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 2. ArchiveNutritionStamp
/// Vintage Notebook Wax/Ink Seal Stamp for Nutrition Day Overview in Archive.
public struct ArchiveNutritionStamp: View {
    public let date: String
    public let meals: [ArchiveMealEntry]
    public let targetCalories: Double
    public let isDarkTheme: Bool
    public let onClick: (() -> Void)?

    public init(
        date: String,
        meals: [ArchiveMealEntry],
        targetCalories: Double = 2000.0,
        isDarkTheme: Bool = false,
        onClick: (() -> Void)? = nil
    ) {
        self.date = date
        self.meals = meals
        self.targetCalories = targetCalories
        self.isDarkTheme = isDarkTheme
        self.onClick = onClick
    }

    public init(
        date: String,
        mealItems: [MealItem],
        targetCalories: Double = 2000.0,
        isDarkTheme: Bool = false,
        onClick: (() -> Void)? = nil
    ) {
        self.init(
            date: date,
            meals: mealItems.map { ArchiveMealEntry(item: $0) },
            targetCalories: targetCalories,
            isDarkTheme: isDarkTheme,
            onClick: onClick
        )
    }

    private var dayMeals: [ArchiveMealEntry] {
        meals.filter { $0.date == date }
    }

    private var totalCalories: Double {
        dayMeals.reduce(0) { $0 + $1.calories }
    }

    private var progress: Double {
        let target = targetCalories > 0 ? targetCalories : 2000.0
        return min(max(totalCalories / target, 0.0), 1.0)
    }

    private var mealSlices: [(sweep: CGFloat, color: Color)] {
        if totalCalories <= 0 { return [] }
        var grouped: [String: Double] = [:]
        for meal in dayMeals {
            let key = meal.mealType.trimmingCharacters(in: .whitespacesAndNewlines)
            let catKey = key.isEmpty ? "Завтрак" : key
            grouped[catKey, default: 0] += meal.calories
        }

        let sorted = grouped.sorted { (a, b) -> Bool in
            let orderA = MealOrderMap[a.key] ?? 10
            let orderB = MealOrderMap[b.key] ?? 10
            return orderA < orderB
        }

        return sorted.enumerated().map { idx, entry in
            let sweep = CGFloat((entry.value / totalCalories) * 360.0)
            let color = DefaultMealColors[entry.key] ?? NutritionCategoryPalette[idx % NutritionCategoryPalette.count]
            return (sweep, color)
        }
    }

    private var daySeed: Int32 {
        javaStringHashCode(date) &* 37
    }

    private var stampRotation: Double {
        1.5 + Double(abs(daySeed % 60)) / 12.0
    }

    private var stampBg: Color {
        isDarkTheme ? Color(hex: 0x14241E) : Color(hex: 0xF4FDF8)
    }

    private var stampBorderColor: Color {
        isDarkTheme ? Color(hex: 0x34D399).opacity(0.88) : Color(hex: 0x047857).opacity(0.92)
    }

    public var body: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            onClick?()
        } label: {
            ZStack {
                // Vector Canvas for Dual Concentric Scales (Calories + Meal Slices)
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)

                    // --- 1. OUTER SCALE: CALORIES ---
                    let outerStroke: CGFloat = 3.5
                    let outerRadius = (min(size.width, size.height) - outerStroke) / 2.0

                    // Track
                    let outerTrackRect = CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)
                    context.stroke(Path(ellipseIn: outerTrackRect), with: .color(stampBorderColor.opacity(0.20)), lineWidth: outerStroke)

                    // Progress Arc
                    if progress > 0.005 {
                        let sweepAngle = min(max(progress * 360.0, 3.0), 360.0)
                        if sweepAngle >= 359.5 {
                            context.stroke(Path(ellipseIn: outerTrackRect), with: .color(stampBorderColor), lineWidth: outerStroke)
                        } else {
                            var arcPath = Path()
                            arcPath.addArc(
                                center: center,
                                radius: outerRadius,
                                startAngle: Angle(degrees: -90.0),
                                endAngle: Angle(degrees: -90.0 + sweepAngle),
                                clockwise: false
                            )
                            context.stroke(
                                arcPath,
                                with: .color(stampBorderColor),
                                style: StrokeStyle(lineWidth: outerStroke, lineCap: progress >= 0.98 ? .butt : .round)
                            )
                        }
                    }

                    // --- 2. INNER SCALE: MEAL SECTORS ---
                    let ringGap: CGFloat = 2.0
                    let innerStroke: CGFloat = 3.5
                    let innerRadius = outerRadius - outerStroke / 2.0 - ringGap - innerStroke / 2.0

                    if mealSlices.isEmpty {
                        let innerTrackRect = CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2)
                        context.stroke(Path(ellipseIn: innerTrackRect), with: .color(stampBorderColor.opacity(0.14)), lineWidth: innerStroke)
                    } else {
                        var currentAngle: Double = -90.0
                        let gap: Double = mealSlices.count > 1 ? 3.0 : 0.0
                        for (sweep, color) in mealSlices {
                            let arcSweep = max(Double(sweep) - gap, 1.5)
                            var path = Path()
                            path.addArc(
                                center: center,
                                radius: innerRadius,
                                startAngle: Angle(degrees: currentAngle + (gap / 2.0)),
                                endAngle: Angle(degrees: currentAngle + (gap / 2.0) + arcSweep),
                                clockwise: false
                            )
                            let isRound = mealSlices.count > 1 && arcSweep > 8.0
                            context.stroke(
                                path,
                                with: .color(color),
                                style: StrokeStyle(lineWidth: innerStroke, lineCap: isRound ? .round : .butt)
                            )
                            currentAngle += Double(sweep)
                        }
                    }

                    // --- 3. VINTAGE INK TEXTURE & DASHED SEAL ACCENT ---
                    let dashedRadius = innerRadius - innerStroke / 2.0 - 1.5
                    if dashedRadius > 0 {
                        let dashedRect = CGRect(x: center.x - dashedRadius, y: center.y - dashedRadius, width: dashedRadius * 2, height: dashedRadius * 2)
                        context.stroke(
                            Path(ellipseIn: dashedRect),
                            with: .color(stampBorderColor.opacity(0.25)),
                            style: StrokeStyle(lineWidth: 0.8, dash: [4, 3.5], dashPhase: CGFloat(abs(daySeed % 12)))
                        )
                    }

                    // Realistic ink speckles (35 deterministic speckles)
                    var rnd = KotlinRandom(seed: daySeed)
                    let maxR = max(dashedRadius - 1.0, 0.0)
                    for i in 0..<35 {
                        let angle = rnd.nextFloat() * 2.0 * .pi
                        let dist = rnd.nextFloat() * maxR
                        let x = center.x + cos(angle) * dist
                        let y = center.y + sin(angle) * dist
                        let dotRadius = 0.5 + rnd.nextFloat() * 1.2
                        let isInkSkip = (i % 3 == 0)
                        let speckColor = isInkSkip ?
                            stampBg.opacity(0.40 + Double(rnd.nextFloat()) * 0.30) :
                            stampBorderColor.opacity(0.06 + Double(rnd.nextFloat()) * 0.15)

                        let rect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(speckColor))
                    }
                }
                .frame(width: 58, height: 58)

                // Center Icon + Calories (Without redundant text)
                VStack(spacing: 1) {
                    Text("🥗")
                        .font(.system(size: 13.5))
                    Text("\(Int(totalCalories.rounded()))")
                        .font(.system(size: totalCalories >= 1000 ? 11.0 : 12.5, weight: .bold))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x0F172A))
                        .lineLimit(1)
                }
            }
            .frame(width: 68, height: 68)
            .background(stampBg)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(stampBorderColor, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            .rotationEffect(.degrees(stampRotation))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 3. ArchiveFinanceDayModalView
/// Read-only Informational Modal for Past Day Finances.
public struct ArchiveFinanceDayModalView: View {
    public let date: String
    public let entries: [ArchiveFinanceEntry]
    public let currency: String
    public let isDarkTheme: Bool
    public var isNoSpendActive: Bool
    public let onDismiss: () -> Void
    public let onClaimNoSpend: (() -> Void)?
    public let onAddExpense: (() -> Void)?

    public init(
        date: String,
        entries: [ArchiveFinanceEntry],
        currency: String = "₽",
        isDarkTheme: Bool = false,
        isNoSpendActive: Bool? = nil,
        onDismiss: @escaping () -> Void,
        onClaimNoSpend: (() -> Void)? = nil,
        onAddExpense: (() -> Void)? = nil
    ) {
        self.date = date
        self.entries = entries
        self.currency = currency
        self.isDarkTheme = isDarkTheme
        self.isNoSpendActive = isNoSpendActive ?? NoSpendManager.shared.isNoSpend(date: date)
        self.onDismiss = onDismiss
        self.onClaimNoSpend = onClaimNoSpend ?? {
            NoSpendManager.shared.claimNoSpend(date: date)
        }
        self.onAddExpense = onAddExpense
    }

    private var dayEntries: [ArchiveFinanceEntry] {
        entries.filter { $0.date == date }
    }

    private var totalExpense: Double {
        dayEntries.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Double {
        dayEntries.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }

    private var balance: Double {
        totalIncome - totalExpense
    }

    private var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let d = inputFormatter.date(from: date) else { return date }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMMM yyyy"
        outputFormatter.locale = Locale(identifier: "ru_RU")
        return outputFormatter.string(from: d)
    }

    private var cardBg: Color {
        isDarkTheme ? Color(hex: 0x161A24) : Color.white
    }

    private var textPrimary: Color {
        isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x0F172A)
    }

    private var textSecondary: Color {
        isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row
            HStack {
                Text("💰 Финансы за \(formattedDate)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(textPrimary)
                    .lineLimit(1)

                Spacer()

                Button {
                    MiodiHapticFeedback.lightClick()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(textSecondary)
                        .frame(width: 32, height: 32)
                        .background(isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xF1F5F9))
                        .clipShape(Circle())
                }
            }

            // 3 Summary Badges (Expenses, Income, Balance)
            HStack(spacing: 8) {
                // Expenses
                VStack(spacing: 2) {
                    Text("Расходы")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0xE11D48))
                    Text("-\(formatNumber(totalExpense)) \(currency)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color(hex: 0xE11D48))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .background(isDarkTheme ? Color(hex: 0x3B151E) : Color(hex: 0xFFF1F2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Income
                VStack(spacing: 2) {
                    Text("Доходы")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0x10B981))
                    Text("+\(formatNumber(totalIncome)) \(currency)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color(hex: 0x10B981))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .background(isDarkTheme ? Color(hex: 0x132F23) : Color(hex: 0xECFDF5))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Balance
                VStack(spacing: 2) {
                    Text("Баланс")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0x3B82F6))
                    let balColor = balance >= 0 ? Color(hex: 0x10B981) : Color(hex: 0xE11D48)
                    let balSign = balance > 0 ? "+" : ""
                    Text("\(balSign)\(formatNumber(balance)) \(currency)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(balColor)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .background(isDarkTheme ? Color(hex: 0x1E283D) : Color(hex: 0xEFF6FF))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // No-spend banner / button when totalExpense <= 0
            if totalExpense <= 0 {
                if isNoSpendActive {
                    HStack(spacing: 12) {
                        Text("🏆")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("День без трат зафиксирован!")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0xFDE68A) : Color(hex: 0x92400E))
                            Text("Отличная дисциплина и контроль бюджета.")
                                .font(.system(size: 12))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0xFDE68A).opacity(0.85) : Color(hex: 0xB45309))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(isDarkTheme ? Color(hex: 0x2E2210) : Color(hex: 0xFEF3C7))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isDarkTheme ? Color(hex: 0xF59E0B).opacity(0.5) : Color(hex: 0xFCD34D), lineWidth: 1)
                    )
                } else {
                    Button {
                        MiodiHapticFeedback.success()
                        onClaimNoSpend?()
                    } label: {
                        HStack(spacing: 8) {
                            Text("🏆")
                                .font(.system(size: 18))
                            Text("Зафиксировать день без трат (+2 🐾)")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0xFBBF24) : Color(hex: 0xB45309))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(isDarkTheme ? Color(hex: 0x281E10) : Color(hex: 0xFFFBEB))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isDarkTheme ? Color(hex: 0xF59E0B).opacity(0.45) : Color(hex: 0xFCD34D), lineWidth: 1)
                        )
                    }
                }
            }

            // List of Entries
            if dayEntries.isEmpty {
                if totalExpense > 0 || !isNoSpendActive {
                    Text("Нет записей финансов за этот день")
                        .font(.system(size: 13.5))
                        .foregroundStyle(textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                }
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(dayEntries) { entry in
                            let isTransfer = entry.type == "transfer"
                            let isExpense = entry.type == "expense"
                            let amtColor = isTransfer ? Color(hex: 0x6366F1) : (isExpense ? Color(hex: 0xE11D48) : Color(hex: 0x10B981))
                            let amtPrefix = isExpense ? "-" : "+"

                            HStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill((isTransfer ? Color(hex: 0x6366F1) : Color(hex: 0xD83A88)).opacity(0.2))
                                            .frame(width: 28, height: 28)
                                        Text(isTransfer ? "⇄" : "💳")
                                            .font(.system(size: 13))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(isTransfer ? "Перевод" : entry.category)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(textPrimary)
                                            .lineLimit(1)
                                        if let note = entry.note, !note.isEmpty {
                                            Text(note)
                                                .font(.system(size: 11))
                                                .foregroundStyle(textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(amtPrefix)\(formatNumber(entry.originalAmount)) \(entry.currency)")
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundStyle(amtColor)
                                    if entry.currency != currency {
                                        Text("≈ \(formatNumber(entry.amount)) \(currency)")
                                            .font(.system(size: 10.5))
                                            .foregroundStyle(textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isDarkTheme ? Color(hex: 0x19202E) : Color(hex: 0xF8FAFC))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .frame(maxHeight: 240)
            }

            // Optional Add Expense Button
            if let onAddExpense {
                Button {
                    MiodiHapticFeedback.lightClick()
                    onAddExpense()
                } label: {
                    Text("Добавить расход за этот день")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 16)
    }

    private func formatNumber(_ num: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}

// MARK: - 4. ArchiveNutritionDayModalView
/// Read-only Informational Modal for Past Day Nutrition.
public struct ArchiveNutritionDayModalView: View {
    public let date: String
    public let meals: [ArchiveMealEntry]
    public let targetCalories: Double
    public let isDarkTheme: Bool
    public let onDismiss: () -> Void

    public init(
        date: String,
        meals: [ArchiveMealEntry],
        targetCalories: Double = 2000.0,
        isDarkTheme: Bool = false,
        onDismiss: @escaping () -> Void
    ) {
        self.date = date
        self.meals = meals
        self.targetCalories = targetCalories
        self.isDarkTheme = isDarkTheme
        self.onDismiss = onDismiss
    }

    private var dayMeals: [ArchiveMealEntry] {
        meals.filter { $0.date == date }
    }

    private var totalCalories: Double {
        dayMeals.reduce(0) { $0 + $1.calories }
    }

    private var totalProteins: Double {
        dayMeals.reduce(0) { $0 + $1.proteins }
    }

    private var totalFats: Double {
        dayMeals.reduce(0) { $0 + $1.fats }
    }

    private var totalCarbs: Double {
        dayMeals.reduce(0) { $0 + $1.carbs }
    }

    private var progress: Double {
        let target = targetCalories > 0 ? targetCalories : 2000.0
        return min(max(totalCalories / target, 0.0), 1.0)
    }

    private var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let d = inputFormatter.date(from: date) else { return date }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMMM yyyy"
        outputFormatter.locale = Locale(identifier: "ru_RU")
        return outputFormatter.string(from: d)
    }

    private var cardBg: Color {
        isDarkTheme ? Color(hex: 0x161A24) : Color.white
    }

    private var textPrimary: Color {
        isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x0F172A)
    }

    private var textSecondary: Color {
        isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row
            HStack {
                Text("🥗 Питание за \(formattedDate)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(textPrimary)
                    .lineLimit(1)

                Spacer()

                Button {
                    MiodiHapticFeedback.lightClick()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(textSecondary)
                        .frame(width: 32, height: 32)
                        .background(isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xF1F5F9))
                        .clipShape(Circle())
                }
            }

            // Calories Progress Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Калории за день")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isDarkTheme ? Color(hex: 0x34D399) : Color(hex: 0x059669))
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(Int(totalCalories.rounded()))")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0x6EE7B7) : Color(hex: 0x065F46))
                            Text(" / \(Int(targetCalories.rounded())) ккал")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isDarkTheme ? Color(hex: 0x34D399).opacity(0.8) : Color(hex: 0x059669).opacity(0.85))
                                .padding(.bottom, 1)
                        }
                    }

                    Spacer()

                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0x34D399) : Color(hex: 0x059669))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0x10B981).opacity(isDarkTheme ? 0.22 : 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: 0x10B981).opacity(0.25))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color(hex: 0x10B981))
                            .frame(width: max(geo.size.width * CGFloat(progress), 0), height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(12)
            .background(isDarkTheme ? Color(hex: 0x132F23) : Color(hex: 0xECFDF5))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Macros Row (Белки / Жиры / Углеводы)
            HStack(spacing: 8) {
                // Proteins
                VStack(spacing: 2) {
                    Text("Белки")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0x3B82F6))
                    Text("\(Int(totalProteins.rounded())) г")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0x3B82F6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(isDarkTheme ? Color(hex: 0x1E283D) : Color(hex: 0xEFF6FF))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Fats
                VStack(spacing: 2) {
                    Text("Жиры")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0xD97706))
                    Text("\(Int(totalFats.rounded())) г")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xD97706))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(isDarkTheme ? Color(hex: 0x362817) : Color(hex: 0xFEF3C7))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Carbs
                VStack(spacing: 2) {
                    Text("Углеводы")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0xDB2777))
                    Text("\(Int(totalCarbs.rounded())) г")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xDB2777))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(isDarkTheme ? Color(hex: 0x351C2C) : Color(hex: 0xFCE7F3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // List of Meals
            if dayMeals.isEmpty {
                Text("Нет записей питания за этот день")
                    .font(.system(size: 13.5))
                    .foregroundStyle(textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(dayMeals) { meal in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(meal.foodName) • \(Int(meal.weightGrams.rounded())) г")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(textPrimary)
                                        .lineLimit(1)
                                    Text("Б: \(Int(meal.proteins.rounded()))г • Ж: \(Int(meal.fats.rounded()))г • У: \(Int(meal.carbs.rounded()))г")
                                        .font(.system(size: 11))
                                        .foregroundStyle(textSecondary)
                                }

                                Spacer()

                                Text("\(Int(meal.calories.rounded())) ккал")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x059669))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isDarkTheme ? Color(hex: 0x19202E) : Color(hex: 0xF8FAFC))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 16)
    }
}

// MARK: - Archive Joy Stamp (Vintage Solar Wax/Ink Seal Stamp for Archived Day)
public struct ArchiveJoyStamp: View {
    public let date: String
    public let joys: [JoyItem]
    public let isDarkTheme: Bool
    public let onClick: (() -> Void)?

    public init(
        date: String,
        joys: [JoyItem],
        isDarkTheme: Bool = false,
        onClick: (() -> Void)? = nil
    ) {
        self.date = date
        self.joys = joys
        self.isDarkTheme = isDarkTheme
        self.onClick = onClick
    }

    private var naturalAngle: Double {
        let hash = date.hashValue
        let rnd = KotlinRandom(seed: Int64(abs(hash) + 109))
        return rnd.nextDouble(from: -4.0, until: 4.0)
    }

    private var dominantMoodEmoji: String {
        guard let first = joys.first else { return "☀️" }
        return JoyMoodCatalog.resolveMoodEmoji(from: first.mood)
    }

    public var body: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            onClick?()
        } label: {
            ZStack {
                // Outer Seal Ring
                Circle()
                    .stroke(
                        Color(hex: 0xD97706).opacity(isDarkTheme ? 0.75 : 0.65),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 2])
                    )
                    .frame(width: 86, height: 86)

                Circle()
                    .stroke(
                        Color(hex: 0xF59E0B).opacity(isDarkTheme ? 0.6 : 0.5),
                        lineWidth: 1.0
                    )
                    .frame(width: 80, height: 80)

                // Seal Backdrop
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFEF3C7).opacity(isDarkTheme ? 0.25 : 0.45),
                                Color(hex: 0xF59E0B).opacity(isDarkTheme ? 0.08 : 0.15)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 40
                        )
                    )
                    .frame(width: 78, height: 78)

                VStack(spacing: 2) {
                    Text("• РАДОСТЬ •")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xD97706))

                    Text(dominantMoodEmoji)
                        .font(.system(size: 20))
                        .shadow(color: Color(hex: 0xF59E0B).opacity(0.4), radius: 3, x: 0, y: 1)

                    Text("\(joys.count) \(joys.count == 1 ? "момент" : (joys.count < 5 ? "радости" : "радостей"))")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(isDarkTheme ? Color(hex: 0xFCD34D) : Color(hex: 0x92400E))

                    Text(date)
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xB45309).opacity(0.8))
                }
            }
            .frame(width: 90, height: 90)
            .rotationEffect(.degrees(naturalAngle))
        }
        .buttonStyle(.plain)
    }
}

