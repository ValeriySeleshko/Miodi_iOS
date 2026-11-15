//
//  TaskPriorityColors.swift
//  Plan4U_iOS
//
//  1-to-1 match with Android TaskPriorityColors.kt
//  5 dark colors for important tasks:
//  1. Чёрный (black)
//  2. Бордовый (burgundy)
//  3. Фиолетовый (purple)
//  4. Тёмно-синий (navy)
//  5. Тёмно-зелёный (darkgreen)
//

import SwiftUI

public struct TaskPriorityColorItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let circleColor: Color
    public let lightTextColor: Color
    public let darkTextColor: Color
    public let lightStrikeColor: Color
    public let darkStrikeColor: Color

    public init(
        id: String,
        name: String,
        circleColor: Color,
        lightTextColor: Color,
        darkTextColor: Color,
        lightStrikeColor: Color,
        darkStrikeColor: Color
    ) {
        self.id = id
        self.name = name
        self.circleColor = circleColor
        self.lightTextColor = lightTextColor
        self.darkTextColor = darkTextColor
        self.lightStrikeColor = lightStrikeColor
        self.darkStrikeColor = darkStrikeColor
    }
}

public enum TaskPriorityColors {
    public static let black = TaskPriorityColorItem(
        id: "black",
        name: "Чёрный",
        circleColor: Color(hex: 0x0F172A),
        lightTextColor: Color(hex: 0x0F172A),
        darkTextColor: Color(hex: 0xF8FAFC),
        lightStrikeColor: Color(hex: 0x1E293B),
        darkStrikeColor: Color(hex: 0x94A3B8)
    )

    public static let burgundy = TaskPriorityColorItem(
        id: "burgundy",
        name: "Бордовый",
        circleColor: Color(hex: 0x881337),
        lightTextColor: Color(hex: 0x881337),
        darkTextColor: Color(hex: 0xFB7185),
        lightStrikeColor: Color(hex: 0x881337),
        darkStrikeColor: Color(hex: 0xF87171)
    )

    public static let purple = TaskPriorityColorItem(
        id: "purple",
        name: "Фиолетовый",
        circleColor: Color(hex: 0x7E22CE),
        lightTextColor: Color(hex: 0x7E22CE),
        darkTextColor: Color(hex: 0xC084FC),
        lightStrikeColor: Color(hex: 0x7E22CE),
        darkStrikeColor: Color(hex: 0xC084FC)
    )

    public static let navy = TaskPriorityColorItem(
        id: "navy",
        name: "Тёмно-синий",
        circleColor: Color(hex: 0x1E3A8A),
        lightTextColor: Color(hex: 0x1E3A8A),
        darkTextColor: Color(hex: 0x60A5FA),
        lightStrikeColor: Color(hex: 0x1E3A8A),
        darkStrikeColor: Color(hex: 0x60A5FA)
    )

    public static let darkgreen = TaskPriorityColorItem(
        id: "darkgreen",
        name: "Тёмно-зелёный",
        circleColor: Color(hex: 0x065F46),
        lightTextColor: Color(hex: 0x065F46),
        darkTextColor: Color(hex: 0x34D399),
        lightStrikeColor: Color(hex: 0x065F46),
        darkStrikeColor: Color(hex: 0x4ADE80)
    )

    public static let all: [TaskPriorityColorItem] = [black, burgundy, purple, navy, darkgreen]

    public static func fromId(_ id: String?) -> TaskPriorityColorItem {
        guard let id = id?.lowercased() else { return black }
        return all.first { $0.id == id } ?? black
    }

    public static func getTextColor(_ id: String?, isDarkTheme: Bool) -> Color {
        let item = fromId(id)
        return isDarkTheme ? item.darkTextColor : item.lightTextColor
    }

    public static func getStrikeColor(_ id: String?, isDarkTheme: Bool) -> Color {
        let item = fromId(id)
        return isDarkTheme ? item.darkStrikeColor : item.lightStrikeColor
    }
}
