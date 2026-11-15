//
//  PetItem.swift
//  Plan4U_iOS
//
//  SwiftData Model matching Android PetEntity.kt 1-to-1 with mood, trust levels and progression.
//

import Foundation
import SwiftData

public enum PetMood: String, Codable, Sendable {
    case happy      // High happiness & hunger (>70%)
    case hungry     // Low hunger (<=30%)
    case sleeping   // Asleep (e.g. night time or toggled)
    case purring    // Recently pet or fed
    case playful    // High happiness (>80%), wants to play
    case content    // Normal calm state

    public var emoji: String {
        switch self {
        case .happy: return "😸"
        case .hungry: return "🐟"
        case .sleeping: return "💤"
        case .purring: return "💖"
        case .playful: return "🐾"
        case .content: return "🐱"
        }
    }

    public var title: String {
        switch self {
        case .happy: return "Радостный"
        case .hungry: return "Голодный"
        case .sleeping: return "Спит"
        case .purring: return "Мурлычет"
        case .playful: return "Игривый"
        case .content: return "Довольный"
        }
    }
}

@Model
public final class PetItem {
    @Attribute(.unique) public var id: String
    public var name: String
    public var color: String // ginger, white, tiger, silver, midnight, cream, mocha, siamese, calico
    public var level: Int
    public var currentXp: Int
    public var maxXp: Int
    public var hungerPercent: Int
    public var happinessPercent: Int
    public var stoneCount: Int      // Dry food pebbles
    public var treatCount: Int      // Wet food treats (cans / jars)
    public var lastSaved: Date
    public var isSleeping: Bool
    public var lastPetDate: Date?

    public init(
        id: String = "main_pet",
        name: String = "Мейни",
        color: String = "ginger",
        level: Int = 1,
        currentXp: Int = 20,
        maxXp: Int = 120,
        hungerPercent: Int = 80,
        happinessPercent: Int = 85,
        stoneCount: Int = 3,
        treatCount: Int = 1,
        lastSaved: Date = Date(),
        isSleeping: Bool = false,
        lastPetDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.level = level
        self.currentXp = currentXp
        self.maxXp = maxXp
        self.hungerPercent = hungerPercent
        self.happinessPercent = happinessPercent
        self.stoneCount = stoneCount
        self.treatCount = treatCount
        self.lastSaved = lastSaved
        self.isSleeping = isSleeping
        self.lastPetDate = lastPetDate
    }

    public var mood: PetMood {
        if isSleeping {
            return .sleeping
        }
        if hungerPercent <= 30 {
            return .hungry
        }
        if happinessPercent >= 85 && hungerPercent >= 70 {
            return .playful
        }
        if happinessPercent >= 70 {
            return .happy
        }
        return .content
    }

    public var trustTitle: String {
        switch level {
        case 1: return "Любопытный хвостик"
        case 2: return "Мягкие лапки"
        case 3: return "Мурчащий пушистик"
        case 4: return "Игривый непоседа"
        case 5: return "Верный дружочек"
        case 6...8: return "Хранитель блокнота"
        case 9...12: return "Повелитель уюта"
        case 13...18: return "Царственный Мейн-кун"
        case 19...25: return "Мудрый компаньон"
        case 26...35: return "Магистр уюта и задач"
        default: return "Легендарный хранитель снов"
        }
    }
}
