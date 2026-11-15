//
//  NutritionPreferences.swift
//  Plan4U_iOS
//
//  State manager for Nutrition Targets, Mifflin-St Jeor Formula, BMI, and Macro Splits.
//

import SwiftUI
import Observation

public struct MacroSplitConfig: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let icon: String
    public let proteinPercent: Double
    public let fatPercent: Double
    public let carbsPercent: Double

    public init(id: String, title: String, icon: String, proteinPercent: Double, fatPercent: Double, carbsPercent: Double) {
        self.id = id
        self.title = title
        self.icon = icon
        self.proteinPercent = proteinPercent
        self.fatPercent = fatPercent
        self.carbsPercent = carbsPercent
    }
}

public struct ActivityLevelConfig: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let femaleIcon: String
    public let maleIcon: String
    public let factor: Double

    public init(id: String, title: String, femaleIcon: String, maleIcon: String, factor: Double) {
        self.id = id
        self.title = title
        self.femaleIcon = femaleIcon
        self.maleIcon = maleIcon
        self.factor = factor
    }

    public func icon(isFemale: Bool) -> String {
        isFemale ? femaleIcon : maleIcon
    }
}

public enum BMICategory {
    case severeUnderweight
    case underweight
    case normal
    case overweight
    case obesityClass1
    case obesityClass2
    case obesityClass3

    public var title: String {
        switch self {
        case .severeUnderweight: return "Выраженный дефицит массы"
        case .underweight: return "Дефицит массы"
        case .normal: return "Нормальный вес"
        case .overweight: return "Избыточный вес"
        case .obesityClass1: return "Ожирение I степени"
        case .obesityClass2: return "Ожирение II степени"
        case .obesityClass3: return "Ожирение III степени"
        }
    }

    public var color: Color {
        switch self {
        case .severeUnderweight: return Color(hex: 0x3B82F6)
        case .underweight: return Color(hex: 0x0284C7)
        case .normal: return Color(hex: 0x10B981)
        case .overweight: return Color(hex: 0xF59E0B)
        case .obesityClass1: return Color(hex: 0xF97316)
        case .obesityClass2: return Color(hex: 0xEF4444)
        case .obesityClass3: return Color(hex: 0xDC2626)
        }
    }
}

@Observable
public final class NutritionPreferences {
    public static let shared = NutritionPreferences()

    public static let macroSplits: [MacroSplitConfig] = [
        MacroSplitConfig(id: "cut", title: "Снижение веса (35/25/40)", icon: "🎯", proteinPercent: 0.35, fatPercent: 0.25, carbsPercent: 0.40),
        MacroSplitConfig(id: "balanced", title: "Баланс (30/30/40)", icon: "⚖️", proteinPercent: 0.30, fatPercent: 0.30, carbsPercent: 0.40),
        MacroSplitConfig(id: "gain", title: "Набор массы (25/20/55)", icon: "📈", proteinPercent: 0.25, fatPercent: 0.20, carbsPercent: 0.55),
        MacroSplitConfig(id: "classic", title: "Классический фитнес (30/20/50)", icon: "🏋️", proteinPercent: 0.30, fatPercent: 0.20, carbsPercent: 0.50),
        MacroSplitConfig(id: "low_carb", title: "Низкоуглеводное (30/45/25)", icon: "🥑", proteinPercent: 0.30, fatPercent: 0.45, carbsPercent: 0.25),
        MacroSplitConfig(id: "keto", title: "Кето (20/75/5)", icon: "🧀", proteinPercent: 0.20, fatPercent: 0.75, carbsPercent: 0.05)
    ]

    public static let activityLevels: [ActivityLevelConfig] = [
        ActivityLevelConfig(id: "sedentary", title: "Сидячий образ жизни", femaleIcon: "🛋️", maleIcon: "🛋️", factor: 1.2),
        ActivityLevelConfig(id: "light", title: "Легкая активность (1-3 дня в нед.)", femaleIcon: "🏃‍♀️", maleIcon: "🏃‍♂️", factor: 1.375),
        ActivityLevelConfig(id: "moderate", title: "Умеренная активность (3-5 дней)", femaleIcon: "🚴‍♀️", maleIcon: "🚴‍♂️", factor: 1.55),
        ActivityLevelConfig(id: "heavy", title: "Высокая активность (6-7 дней)", femaleIcon: "🏋️‍♀️", maleIcon: "🏋️‍♂️", factor: 1.725),
        ActivityLevelConfig(id: "extreme", title: "Экстремальная активность", femaleIcon: "⚡", maleIcon: "⚡", factor: 1.9)
    ]

    // Stored Properties
    public var weightKg: Double {
        didSet { UserDefaults.standard.set(weightKg, forKey: "nutrition_weightKg") }
    }
    public var targetWeightKg: Double {
        didSet { UserDefaults.standard.set(targetWeightKg, forKey: "nutrition_targetWeightKg") }
    }
    public var heightCm: Double {
        didSet { UserDefaults.standard.set(heightCm, forKey: "nutrition_heightCm") }
    }
    public var age: Int {
        didSet { UserDefaults.standard.set(age, forKey: "nutrition_age") }
    }
    public var isFemale: Bool {
        didSet { UserDefaults.standard.set(isFemale, forKey: "nutrition_isFemale") }
    }
    public var activityLevelIndex: Int {
        didSet { UserDefaults.standard.set(activityLevelIndex, forKey: "nutrition_activityLevelIndex") }
    }
    public var goalIndex: Int {
        didSet { UserDefaults.standard.set(goalIndex, forKey: "nutrition_goalIndex") }
    }
    public var splitIndex: Int {
        didSet { UserDefaults.standard.set(splitIndex, forKey: "nutrition_splitIndex") }
    }
    public var targetCalories: Double {
        didSet { UserDefaults.standard.set(targetCalories, forKey: "nutrition_targetCalories") }
    }
    public var targetProteins: Double {
        didSet { UserDefaults.standard.set(targetProteins, forKey: "nutrition_targetProteins") }
    }
    public var targetFats: Double {
        didSet { UserDefaults.standard.set(targetFats, forKey: "nutrition_targetFats") }
    }
    public var targetCarbs: Double {
        didSet { UserDefaults.standard.set(targetCarbs, forKey: "nutrition_targetCarbs") }
    }
    public var mealPercentages: [Int] {
        didSet {
            UserDefaults.standard.set(mealPercentages, forKey: "nutrition_mealPercentages")
        }
    }

    private init() {
        let def = UserDefaults.standard
        self.weightKg = def.double(forKey: "nutrition_weightKg") != 0 ? def.double(forKey: "nutrition_weightKg") : 60.0
        self.targetWeightKg = def.double(forKey: "nutrition_targetWeightKg") != 0 ? def.double(forKey: "nutrition_targetWeightKg") : 60.0
        self.heightCm = def.double(forKey: "nutrition_heightCm") != 0 ? def.double(forKey: "nutrition_heightCm") : 170.0
        self.age = def.integer(forKey: "nutrition_age") != 0 ? def.integer(forKey: "nutrition_age") : 25
        self.isFemale = def.object(forKey: "nutrition_isFemale") != nil ? def.bool(forKey: "nutrition_isFemale") : true
        self.activityLevelIndex = def.integer(forKey: "nutrition_activityLevelIndex")
        self.goalIndex = def.integer(forKey: "nutrition_goalIndex")
        self.splitIndex = def.integer(forKey: "nutrition_splitIndex")
        self.targetCalories = def.double(forKey: "nutrition_targetCalories") != 0 ? def.double(forKey: "nutrition_targetCalories") : 2000.0
        self.targetProteins = def.double(forKey: "nutrition_targetProteins") != 0 ? def.double(forKey: "nutrition_targetProteins") : 80.0
        self.targetFats = def.double(forKey: "nutrition_targetFats") != 0 ? def.double(forKey: "nutrition_targetFats") : 70.0
        self.targetCarbs = def.double(forKey: "nutrition_targetCarbs") != 0 ? def.double(forKey: "nutrition_targetCarbs") : 250.0

        if let savedPercentages = def.array(forKey: "nutrition_mealPercentages") as? [Int], savedPercentages.count == 4, savedPercentages.reduce(0, +) == 100 {
            self.mealPercentages = savedPercentages
        } else {
            self.mealPercentages = [25, 35, 25, 15] // Breakfast, Lunch, Dinner, Snack
        }
    }

    // MARK: - Mifflin-St Jeor Scientific Calculations
    public func calculateBMR(weight: Double, height: Double, ageVal: Int, female: Bool) -> Double {
        if female {
            return (10.0 * weight + 6.25 * height - 5.0 * Double(ageVal) - 161.0).rounded()
        } else {
            return (10.0 * weight + 6.25 * height - 5.0 * Double(ageVal) + 5.0).rounded()
        }
    }

    public func calculateTDEE(weight: Double, height: Double, ageVal: Int, female: Bool, actIndex: Int) -> Double {
        let bmr = calculateBMR(weight: weight, height: height, ageVal: ageVal, female: female)
        let factor = Self.activityLevels[safe: actIndex]?.factor ?? 1.375
        return (bmr * factor).rounded()
    }

    public func calculateTargetCalories(weight: Double, height: Double, ageVal: Int, female: Bool, actIndex: Int, goal: Int) -> Double {
        let tdee = calculateTDEE(weight: weight, height: height, ageVal: ageVal, female: female, actIndex: actIndex)
        switch goal {
        case 0: // Снижение (-15%)
            return (tdee * 0.85).rounded()
        case 2: // Набор (+10%)
            return (tdee * 1.10).rounded()
        default: // Поддержание
            return tdee
        }
    }

    public func calculateMacros(calories: Double, split: MacroSplitConfig) -> (protein: Double, fat: Double, carbs: Double) {
        let protGrams = ((calories * split.proteinPercent) / 4.0).rounded()
        let fatGrams = ((calories * split.fatPercent) / 9.0).rounded()
        let carbGrams = ((calories * split.carbsPercent) / 4.0).rounded()
        return (protGrams, fatGrams, carbGrams)
    }

    // MARK: - Top-Down Meal Percentages Rebalance
    public static func rebalancePercentagesTopDown(current: [Int], changedIndex: Int, newValue: Int) -> [Int] {
        let n = current.count
        guard n > 1, changedIndex >= 0, changedIndex < n else { return current }

        var safeCurrent = current
        if safeCurrent.reduce(0, +) != 100 {
            safeCurrent = [25, 35, 25, 15]
        }

        var result = safeCurrent
        let sumAbove = (0..<changedIndex).reduce(0) { $0 + safeCurrent[$1] }

        if changedIndex < n - 1 {
            let maxAllowed = max(0, min(100, 100 - sumAbove))
            let targetVal = max(0, min(maxAllowed, newValue))
            result[changedIndex] = targetVal

            let remainingBudget = 100 - sumAbove - targetVal
            let belowIndices = Array((changedIndex + 1)..<n)
            let currentBelowSum = belowIndices.reduce(0) { $0 + safeCurrent[$1] }

            if remainingBudget == 0 {
                for idx in belowIndices {
                    result[idx] = 0
                }
            } else if currentBelowSum == 0 {
                let base = remainingBudget / belowIndices.count
                var rem = remainingBudget % belowIndices.count
                for idx in belowIndices {
                    let add = (rem > 0) ? 1 : 0
                    if rem > 0 { rem -= 1 }
                    result[idx] = base + add
                }
            } else {
                var allocated = 0
                var rawValues: [(Int, Double)] = []
                for idx in belowIndices {
                    let prop = Double(safeCurrent[idx]) / Double(currentBelowSum)
                    let raw = prop * Double(remainingBudget)
                    rawValues.append((idx, raw))
                }

                for (idx, raw) in rawValues {
                    let rounded = max(0, Int(raw.rounded(.down)))
                    result[idx] = rounded
                    allocated += rounded
                }

                var diff = remainingBudget - allocated
                if diff > 0 {
                    let sortedByRemainder = rawValues.sorted { ($0.1 - $0.1.rounded(.down)) > ($1.1 - $1.1.rounded(.down)) }
                    var ptr = 0
                    while diff > 0 && ptr < sortedByRemainder.count {
                        let idx = sortedByRemainder[ptr % sortedByRemainder.count].0
                        result[idx] += 1
                        diff -= 1
                        ptr += 1
                    }
                }
            }
        } else {
            // Last item changed: adjust item directly above it
            let targetVal = max(0, min(100, newValue))
            result[changedIndex] = targetVal
            let sumExceptLast = (0..<(n - 1)).reduce(0) { $0 + safeCurrent[$1] }
            var diff = (sumExceptLast + targetVal) - 100

            var ptr = n - 2
            while diff > 0 && ptr >= 0 {
                let available = result[ptr]
                let take = min(available, diff)
                result[ptr] -= take
                diff -= take
                ptr -= 1
            }
            if diff < 0 {
                result[n - 2] += (-diff)
            }
        }

        return result
    }

    // MARK: - BMI / ИМТ Helper
    public static func calculateBMI(weightKg: Double, heightCm: Double) -> Double {
        guard heightCm > 50 else { return 21.0 }
        let hMeters = heightCm / 100.0
        return (weightKg / (hMeters * hMeters) * 10.0).rounded() / 10.0
    }

    public static func getBMICategory(bmi: Double) -> BMICategory {
        switch bmi {
        case ..<16.0: return .severeUnderweight
        case 16.0..<18.5: return .underweight
        case 18.5..<25.0: return .normal
        case 25.0..<30.0: return .overweight
        case 30.0..<35.0: return .obesityClass1
        case 35.0..<40.0: return .obesityClass2
        default: return .obesityClass3
        }
    }

    public static func healthyWeightRange(heightCm: Double) -> (minKg: Double, maxKg: Double) {
        guard heightCm > 50 else { return (50.0, 70.0) }
        let hMeters = heightCm / 100.0
        let minW = (18.5 * hMeters * hMeters * 10.0).rounded() / 10.0
        let maxW = (24.9 * hMeters * hMeters * 10.0).rounded() / 10.0
        return (minW, maxW)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
