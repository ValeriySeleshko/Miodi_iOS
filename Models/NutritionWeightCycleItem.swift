//
//  NutritionWeightCycleItem.swift
//  Plan4U_iOS
//
//  SwiftData Models for Weight, Nutrition (Meals & Macros), Custom Foods, and Cycles.
//

import Foundation
import SwiftData

@Model
public final class WeightEntryItem {
    @Attribute(.unique) public var id: String
    public var date: String // "yyyy-MM-dd"
    public var weightKg: Double
    public var note: String?
    public var timestamp: Int64

    public init(
        id: String = UUID().uuidString,
        date: String = "",
        weightKg: Double = 0.0,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.note = note
        self.timestamp = timestamp
    }
}

@Model
public final class MealItem {
    @Attribute(.unique) public var id: String
    public var date: String // "yyyy-MM-dd"
    public var mealType: String // "meal_breakfast", "meal_lunch", "meal_dinner", "meal_snack"
    public var title: String
    public var calories: Double
    public var proteins: Double
    public var fats: Double
    public var carbs: Double
    public var weightGrams: Double
    public var timestamp: Int64

    public init(
        id: String = UUID().uuidString,
        date: String = "",
        mealType: String = "meal_breakfast",
        title: String = "",
        calories: Double = 0.0,
        proteins: Double = 0.0,
        fats: Double = 0.0,
        carbs: Double = 0.0,
        weightGrams: Double = 0.0,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.title = title
        self.calories = calories
        self.proteins = proteins
        self.fats = fats
        self.carbs = carbs
        self.weightGrams = weightGrams
        self.timestamp = timestamp
    }
}

@Model
public final class CustomFoodItem {
    @Attribute(.unique) public var id: String
    public var name: String
    public var caloriesPer100g: Double
    public var proteinsPer100g: Double
    public var fatsPer100g: Double
    public var carbsPer100g: Double
    public var brand: String?
    public var barcode: String?
    public var isFavorite: Bool
    public var timestamp: Int64

    public init(
        id: String = UUID().uuidString,
        name: String = "",
        caloriesPer100g: Double = 0.0,
        proteinsPer100g: Double = 0.0,
        fatsPer100g: Double = 0.0,
        carbsPer100g: Double = 0.0,
        brand: String? = nil,
        barcode: String? = nil,
        isFavorite: Bool = false,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.caloriesPer100g = caloriesPer100g
        self.proteinsPer100g = proteinsPer100g
        self.fatsPer100g = fatsPer100g
        self.carbsPer100g = carbsPer100g
        self.brand = brand
        self.barcode = barcode
        self.isFavorite = isFavorite
        self.timestamp = timestamp
    }
}

@Model
public final class CycleItem {
    @Attribute(.unique) public var id: String
    public var startDate: String // "yyyy-MM-dd"
    public var endDate: String? // "yyyy-MM-dd"
    public var cycleLengthDays: Int
    public var periodLengthDays: Int
    public var isOutlier: Bool
    public var ovulationDate: String? // "yyyy-MM-dd"
    public var note: String?
    public var timestamp: Int64

    public init(
        id: String = UUID().uuidString,
        startDate: String = "",
        endDate: String? = nil,
        cycleLengthDays: Int = 28,
        periodLengthDays: Int = 5,
        isOutlier: Bool = false,
        ovulationDate: String? = nil,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.cycleLengthDays = cycleLengthDays
        self.periodLengthDays = periodLengthDays
        self.isOutlier = isOutlier
        self.ovulationDate = ovulationDate
        self.note = note
        self.timestamp = timestamp
    }
}
