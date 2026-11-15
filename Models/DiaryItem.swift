//
//  DiaryItem.swift
//  Plan4U_iOS
//
//  SwiftData Models matching Android DiaryEntryEntity.kt and JoyEntity.kt
//

import Foundation
import SwiftData

@Model
public final class DiaryItem {
    @Attribute(.unique) public var id: String
    public var date: String // "yyyy-MM-dd"
    public var time: String // "HH:mm"
    public var timestamp: Int64
    public var content: String
    public var updatedAt: Int64
    public var formattingJson: String?

    public init(
        id: String = UUID().uuidString,
        date: String = "",
        time: String = "",
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        content: String = "",
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        formattingJson: String? = nil
    ) {
        self.id = id
        self.date = date
        self.time = time
        self.timestamp = timestamp
        self.content = content
        self.updatedAt = updatedAt
        self.formattingJson = formattingJson
    }
}

@Model
public final class JoyItem {
    @Attribute(.unique) public var id: String
    public var date: String // "yyyy-MM-dd"
    public var text: String
    public var orderIndex: Int
    public var createdAt: Int64
    public var mood: String
    public var sticker: String
    public var timestamp: Int64

    public init(
        id: String = UUID().uuidString,
        date: String = "",
        text: String = "",
        orderIndex: Int = 0,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        mood: String = "joy_mood_01",
        sticker: String = "paper_01",
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.mood = mood
        self.sticker = sticker
        self.timestamp = timestamp
    }
}
