//
//  CycleModels.swift
//  Plan4U_iOS
//
//  Complete Female Cycle Models, Indicators, Symptoms, Settings & Prompts
//  1-to-1 matching Android CycleModels.kt & CycleSettings
//

import Foundation
import SwiftUI

// MARK: - Cycle Indicator Style (Cherry, Strawberry, Sakura, Peach, Butterfly)
public enum CycleIndicatorStyle: String, CaseIterable, Identifiable, Sendable {
    case cherry = "cherry"
    case strawberry = "strawberry"
    case sakura = "sakura"
    case peach = "peach"
    case butterfly = "butterfly"

    public var id: String { rawValue }

    public var emoji: String {
        switch self {
        case .cherry: return "🍒"
        case .strawberry: return "🍓"
        case .sakura: return "🌸"
        case .peach: return "🍑"
        case .butterfly: return "🦋"
        }
    }

    public var titleRu: String {
        switch self {
        case .cherry: return "Вишенки"
        case .strawberry: return "Клубничка"
        case .sakura: return "Сакура"
        case .peach: return "Персик"
        case .butterfly: return "Бабочка"
        }
    }

    public var isProOnly: Bool {
        switch self {
        case .cherry: return false
        default: return true
        }
    }

    public static func from(id: String?) -> CycleIndicatorStyle {
        guard let id = id else { return .cherry }
        return CycleIndicatorStyle(rawValue: id) ?? .cherry
    }
}

// MARK: - Flow Intensity
public enum FlowIntensity: String, CaseIterable, Identifiable, Sendable, Codable {
    case none = "none"
    case spotting = "spotting"
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"

    public var id: String { rawValue }

    public var titleRu: String {
        switch self {
        case .none: return "Нет выделений"
        case .spotting: return "Мажущие"
        case .light: return "Лёгкие"
        case .medium: return "Средние"
        case .heavy: return "Обильные"
        }
    }

    public var icon: String {
        switch self {
        case .none: return "circle"
        case .spotting: return "drop"
        case .light: return "drop.fill"
        case .medium: return "drop.degreesign.fill"
        case .heavy: return "drop.triangle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .none: return Color.secondary
        case .spotting: return Color(hex: 0xF472B6)
        case .light: return Color(hex: 0xFB7185)
        case .medium: return Color(hex: 0xE11D48)
        case .heavy: return Color(hex: 0x9F1239)
        }
    }
}

// MARK: - Mood Type
public struct CycleMoodItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let emoji: String
    public let title: String
    public let colorHex: UInt32

    public init(id: String, emoji: String, title: String, colorHex: UInt32 = 0xFB7185) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.colorHex = colorHex
    }

    public static let allMoods: [CycleMoodItem] = [
        CycleMoodItem(id: "calm", emoji: "🌸", title: "Спокойное", colorHex: 0x34D399),
        CycleMoodItem(id: "great", emoji: "✨", title: "Отличное", colorHex: 0xFBBF24),
        CycleMoodItem(id: "tenderness", emoji: "🥰", title: "Нежность", colorHex: 0xF472B6),
        CycleMoodItem(id: "energy", emoji: "⚡", title: "Энергичное", colorHex: 0xF59E0B),
        CycleMoodItem(id: "sensitive", emoji: "🥺", title: "Чувствительное", colorHex: 0xA78BFA),
        CycleMoodItem(id: "fatigue", emoji: "😴", title: "Усталость", colorHex: 0x64748B),
        CycleMoodItem(id: "sadness", emoji: "🌧️", title: "Грустное", colorHex: 0x60A5FA),
        CycleMoodItem(id: "irritable", emoji: "🔥", title: "Раздражительное", colorHex: 0xEF4444),
        CycleMoodItem(id: "anxious", emoji: "😰", title: "Тревожное", colorHex: 0x9333EA)
    ]
}

// MARK: - Physical Symptoms
public struct CycleSymptomItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let emoji: String
    public let title: String

    public init(id: String, emoji: String, title: String) {
        self.id = id
        self.emoji = emoji
        self.title = title
    }

    public static let allSymptoms: [CycleSymptomItem] = [
        CycleSymptomItem(id: "cramps", emoji: "💆‍♀️", title: "Тянет низ живота"),
        CycleSymptomItem(id: "spasms", emoji: "⚡", title: "Спазмы"),
        CycleSymptomItem(id: "lower_back", emoji: "🦴", title: "Боль в пояснице"),
        CycleSymptomItem(id: "migraine", emoji: "🤕", title: "Мигрень / Головная боль"),
        CycleSymptomItem(id: "bloating", emoji: "🎈", title: "Вздутие живота"),
        CycleSymptomItem(id: "breast", emoji: "👙", title: "Чувствительность груди"),
        CycleSymptomItem(id: "edema", emoji: "💧", title: "Отёчность"),
        CycleSymptomItem(id: "insomnia", emoji: "🌙", title: "Бессонница"),
        CycleSymptomItem(id: "nausea", emoji: "🤢", title: "Тошнота"),
        CycleSymptomItem(id: "acne", emoji: "✨", title: "Высыпания / Акне")
    ]
}

// MARK: - Daily Symptom Record
public struct DailySymptomRecord: Identifiable, Codable, Sendable {
    public var id: String
    public var date: String // "yyyy-MM-dd"
    public var flow: FlowIntensity
    public var moods: [String]
    public var symptoms: [String]
    public var note: String
    public var timestamp: Int64

    public init(
        id: String = UUID().uuidString,
        date: String,
        flow: FlowIntensity = .none,
        moods: [String] = [],
        symptoms: [String] = [],
        note: String = "",
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.date = date
        self.flow = flow
        self.moods = moods
        self.symptoms = symptoms
        self.note = note
        self.timestamp = timestamp
    }

    public var summaryDescription: String {
        var parts: [String] = []
        if flow != .none {
            parts.append("Выделения: \(flow.titleRu)")
        }
        if !moods.isEmpty {
            parts.append("Настроение: " + moods.joined(separator: ", "))
        }
        if !symptoms.isEmpty {
            parts.append("Симптомы: " + symptoms.joined(separator: ", "))
        }
        if !note.isEmpty {
            parts.append("Заметка: \(note)")
        }
        return parts.joined(separator: " • ")
    }
}

// MARK: - Check-In Prompts
public enum CyclePromptType: String, Sendable {
    case approaching = "approaching"
    case expectedToday = "expected_today"
    case overdueDaily = "overdue_daily"
    case forgotEnd = "forgot_end"
}

public struct CycleCheckInPrompt: Sendable {
    public let type: CyclePromptType
    public let cycleId: String?
    public let startDate: String
    public let expectedDate: String
    public let defaultEndDate: String
    public let daysCount: Int

    public init(
        type: CyclePromptType,
        cycleId: String? = nil,
        startDate: String = "",
        expectedDate: String = "",
        defaultEndDate: String = "",
        daysCount: Int = 0
    ) {
        self.type = type
        self.cycleId = cycleId
        self.startDate = startDate
        self.expectedDate = expectedDate
        self.defaultEndDate = defaultEndDate
        self.daysCount = daysCount
    }
}

// MARK: - Cycle Settings Store (UserDefaults persistence)
@Observable
public final class CycleSettingsStore {
    public static let shared = CycleSettingsStore()

    private enum Keys {
        static let enabled = "miodi_cycle_enabled"
        static let isIrregular = "miodi_cycle_is_irregular"
        static let periodLength = "miodi_cycle_period_length"
        static let defaultCycleLength = "miodi_cycle_default_length"
        static let lutealLength = "miodi_cycle_luteal_length"
        static let lutealNutritionSync = "miodi_cycle_luteal_nutrition_sync"
        static let lutealBoostPercent = "miodi_cycle_luteal_boost_percent"
        static let remindersEnabled = "miodi_cycle_reminders_enabled"
        static let reminderDaysBefore = "miodi_cycle_reminder_days_before"
        static let delayRemindersEnabled = "miodi_cycle_delay_reminders_enabled"
        static let endRemindersEnabled = "miodi_cycle_end_reminders_enabled"
        static let popupEnabled = "miodi_cycle_popup_enabled"
        static let indicatorStyle = "miodi_cycle_indicator_style"
        static let popupDismissedDate = "miodi_cycle_popup_dismissed_date"
        static let symptomsHistory = "miodi_cycle_symptoms_history_v1"
    }

    public var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: Keys.enabled) }
    }
    public var isIrregular: Bool {
        didSet { UserDefaults.standard.set(isIrregular, forKey: Keys.isIrregular) }
    }
    public var periodLength: Int {
        didSet { UserDefaults.standard.set(periodLength, forKey: Keys.periodLength) }
    }
    public var defaultCycleLength: Int {
        didSet { UserDefaults.standard.set(defaultCycleLength, forKey: Keys.defaultCycleLength) }
    }
    public var lutealLength: Int {
        didSet { UserDefaults.standard.set(lutealLength, forKey: Keys.lutealLength) }
    }
    public var lutealNutritionSync: Bool {
        didSet { UserDefaults.standard.set(lutealNutritionSync, forKey: Keys.lutealNutritionSync) }
    }
    public var lutealBoostPercent: Int {
        didSet { UserDefaults.standard.set(lutealBoostPercent, forKey: Keys.lutealBoostPercent) }
    }
    public var remindersEnabled: Bool {
        didSet { UserDefaults.standard.set(remindersEnabled, forKey: Keys.remindersEnabled) }
    }
    public var reminderDaysBefore: Int {
        didSet { UserDefaults.standard.set(reminderDaysBefore, forKey: Keys.reminderDaysBefore) }
    }
    public var delayRemindersEnabled: Bool {
        didSet { UserDefaults.standard.set(delayRemindersEnabled, forKey: Keys.delayRemindersEnabled) }
    }
    public var endRemindersEnabled: Bool {
        didSet { UserDefaults.standard.set(endRemindersEnabled, forKey: Keys.endRemindersEnabled) }
    }
    public var popupEnabled: Bool {
        didSet { UserDefaults.standard.set(popupEnabled, forKey: Keys.popupEnabled) }
    }
    public var indicatorStyle: CycleIndicatorStyle {
        didSet { UserDefaults.standard.set(indicatorStyle.rawValue, forKey: Keys.indicatorStyle) }
    }
    public var popupDismissedDate: String {
        didSet { UserDefaults.standard.set(popupDismissedDate, forKey: Keys.popupDismissedDate) }
    }

    // In-memory cache of daily symptom records
    public var symptomsByDate: [String: DailySymptomRecord] = [:]

    private init() {
        let defaults = UserDefaults.standard
        self.enabled = defaults.object(forKey: Keys.enabled) != nil ? defaults.bool(forKey: Keys.enabled) : true
        self.isIrregular = defaults.object(forKey: Keys.isIrregular) != nil ? defaults.bool(forKey: Keys.isIrregular) : true
        self.periodLength = defaults.object(forKey: Keys.periodLength) != nil ? defaults.integer(forKey: Keys.periodLength) : 5
        self.defaultCycleLength = defaults.object(forKey: Keys.defaultCycleLength) != nil ? defaults.integer(forKey: Keys.defaultCycleLength) : 28
        self.lutealLength = defaults.object(forKey: Keys.lutealLength) != nil ? defaults.integer(forKey: Keys.lutealLength) : 14
        self.lutealNutritionSync = defaults.bool(forKey: Keys.lutealNutritionSync)
        self.lutealBoostPercent = defaults.object(forKey: Keys.lutealBoostPercent) != nil ? defaults.integer(forKey: Keys.lutealBoostPercent) : 10
        self.remindersEnabled = defaults.object(forKey: Keys.remindersEnabled) != nil ? defaults.bool(forKey: Keys.remindersEnabled) : true
        self.reminderDaysBefore = defaults.object(forKey: Keys.reminderDaysBefore) != nil ? defaults.integer(forKey: Keys.reminderDaysBefore) : 3
        self.delayRemindersEnabled = defaults.object(forKey: Keys.delayRemindersEnabled) != nil ? defaults.bool(forKey: Keys.delayRemindersEnabled) : true
        self.endRemindersEnabled = defaults.object(forKey: Keys.endRemindersEnabled) != nil ? defaults.bool(forKey: Keys.endRemindersEnabled) : true
        self.popupEnabled = defaults.object(forKey: Keys.popupEnabled) != nil ? defaults.bool(forKey: Keys.popupEnabled) : true
        self.indicatorStyle = CycleIndicatorStyle.from(id: defaults.string(forKey: Keys.indicatorStyle))
        self.popupDismissedDate = defaults.string(forKey: Keys.popupDismissedDate) ?? ""

        loadSymptoms()
    }

    // MARK: - Symptoms Persistence
    private func loadSymptoms() {
        guard let data = UserDefaults.standard.data(forKey: Keys.symptomsHistory) else { return }
        do {
            let records = try JSONDecoder().decode([DailySymptomRecord].self, from: data)
            var map: [String: DailySymptomRecord] = [:]
            for r in records {
                map[r.date] = r
            }
            self.symptomsByDate = map
        } catch {
            print("Failed to decode cycle symptoms: \(error)")
        }
    }

    public func saveSymptomRecord(_ record: DailySymptomRecord) {
        symptomsByDate[record.date] = record
        persistSymptoms()
    }

    public func getSymptomRecord(for date: String) -> DailySymptomRecord? {
        return symptomsByDate[date]
    }

    public func getAllSymptomsSorted() -> [DailySymptomRecord] {
        return symptomsByDate.values.sorted(by: { $0.date > $1.date })
    }

    private func persistSymptoms() {
        let list = Array(symptomsByDate.values)
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: Keys.symptomsHistory)
        }
    }
}
