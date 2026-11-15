//
//  PageStickerItem.swift
//  Plan4U_iOS
//
//  SwiftData Model matching Android PageStickerEntity.kt 1-to-1.
//  Represents a decorative or mood sticker pinned to a notebook sheet or diary page.
//

import Foundation
import SwiftData

@Model
public final class PageStickerItem: Identifiable {
    @Attribute(.unique) public var id: String
    public var tabId: String
    public var date: String // "yyyy-MM-dd" for daily sheets in "todo", "" for permanent tabs
    public var assetPath: String
    public var xOffsetDp: Double
    public var yOffsetDp: Double
    public var rotation: Double
    public var scale: Double
    public var isFlipped: Bool
    public var alpha: Double
    public var text: String?
    public var mood: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        tabId: String = "todo",
        date: String = "",
        assetPath: String = "🐱",
        xOffsetDp: Double = 50.0,
        yOffsetDp: Double = 120.0,
        rotation: Double = 0.0,
        scale: Double = 1.0,
        isFlipped: Bool = false,
        alpha: Double = 0.92,
        text: String? = nil,
        mood: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tabId = tabId
        self.date = date
        self.assetPath = assetPath
        self.xOffsetDp = xOffsetDp
        self.yOffsetDp = yOffsetDp
        self.rotation = rotation
        self.scale = scale
        self.isFlipped = isFlipped
        self.alpha = alpha
        self.text = text
        self.mood = mood
        self.createdAt = createdAt
    }
}
