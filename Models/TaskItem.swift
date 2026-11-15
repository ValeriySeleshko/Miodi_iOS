//
//  TaskItem.swift
//  Plan4U_iOS
//
//  SwiftData Model matching Android TaskEntity.kt 1-to-1
//

import Foundation
import SwiftData

@Model
public final class TaskItem {
    @Attribute(.unique) public var id: String
    public var sectionId: String
    public var tabId: String
    public var text: String
    public var isCompleted: Bool
    public var date: String // Format: YYYY-MM-DD
    public var priority: Int // 0 = ordinary, 1 = important
    public var priorityColor: String // black, burgundy, purple, navy, darkgreen
    public var completedAt: Int64
    public var reminderTime: String?
    public var notes: String?
    public var photoUri: String?
    public var orderIndex: Int
    public var isMaineQuest: Bool
    public var questId: String?
    public var rewardClaimed: Bool

    public init(
        id: String = UUID().uuidString,
        sectionId: String = "",
        tabId: String = "",
        text: String = "",
        isCompleted: Bool = false,
        date: String = "",
        priority: Int = 0,
        priorityColor: String = "black",
        completedAt: Int64 = 0,
        reminderTime: String? = nil,
        notes: String? = nil,
        photoUri: String? = nil,
        orderIndex: Int = 0,
        isMaineQuest: Bool = false,
        questId: String? = nil,
        rewardClaimed: Bool = false
    ) {
        self.id = id
        self.sectionId = sectionId
        self.tabId = tabId
        self.text = text
        self.isCompleted = isCompleted
        self.date = date
        self.priority = priority
        self.priorityColor = priorityColor
        self.completedAt = completedAt
        self.reminderTime = reminderTime
        self.notes = notes
        self.photoUri = photoUri
        self.orderIndex = orderIndex
        self.isMaineQuest = isMaineQuest
        self.questId = questId
        self.rewardClaimed = rewardClaimed
    }
}
