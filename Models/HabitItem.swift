//
//  HabitItem.swift
//  Plan4U_iOS
//
//  SwiftData Model matching Android HabitEntity.kt 1-to-1
//

import Foundation
import SwiftData

@Model
public final class HabitItem {
    @Attribute(.unique) public var id: String
    public var title: String
    public var type: String // "boolean" or "numeric"
    public var targetValue: Float
    public var targetUnit: String
    public var targetStep: Float
    public var scheduleType: String // "daily", "weekdays", "periodic"
    public var scheduleDaysOfWeek: String // "1,2,3,4,5" (1=Mon..7=Sun)
    public var scheduleTargetCount: Int
    public var schedulePeriod: String // "week", "month"
    public var reminderEnabled: Bool
    public var reminderTime: String
    public var createdAt: Int64
    public var orderIndex: Int

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        type: String = "boolean",
        targetValue: Float = 1.0,
        targetUnit: String = "",
        targetStep: Float = 1.0,
        scheduleType: String = "daily",
        scheduleDaysOfWeek: String = "1,2,3,4,5,6,7",
        scheduleTargetCount: Int = 3,
        schedulePeriod: String = "week",
        reminderEnabled: Bool = false,
        reminderTime: String = "09:00",
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        orderIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.targetStep = targetStep
        self.scheduleType = scheduleType
        self.scheduleDaysOfWeek = scheduleDaysOfWeek
        self.scheduleTargetCount = scheduleTargetCount
        self.schedulePeriod = schedulePeriod
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.createdAt = createdAt
        self.orderIndex = orderIndex
    }

    // MARK: - Helper Methods matching Android HabitEntity

    public var daysOfWeekSet: Set<Int> {
        let items = scheduleDaysOfWeek.split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        return Set(items.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : items)
    }

    public func setDaysOfWeek(_ set: Set<Int>) {
        self.scheduleDaysOfWeek = set.sorted().map { String($0) }.joined(separator: ",")
    }

    public var reminderTimes: [String] {
        if reminderTime.trimmingCharacters(in: .whitespaces).isEmpty { return [] }
        return reminderTime.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .sorted()
    }

    public func setReminderTimes(_ times: [String]) {
        self.reminderTime = times.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.sorted().joined(separator: ", ")
    }
}

@Model
public final class HabitEntryItem {
    @Attribute(.unique) public var id: String // "\(habitId)_\(date)"
    public var habitId: String
    public var date: String // "yyyy-MM-dd"
    public var value: Float
    public var isCompleted: Bool
    public var status: String // "completed", "failed", "frozen"
    public var updatedAt: Int64

    public init(
        id: String = UUID().uuidString,
        habitId: String = "",
        date: String = "",
        value: Float = 1.0,
        isCompleted: Bool = true,
        status: String = "completed",
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.habitId = habitId
        self.date = date
        self.value = value
        self.isCompleted = isCompleted
        self.status = status
        self.updatedAt = updatedAt
    }
}
