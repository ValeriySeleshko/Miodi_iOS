//
//  PetProgressionService.swift
//  Plan4U_iOS
//
//  Complete 100% Port of Android PetProgressionDomainService & MeiniShopManager.
//  Encapsulates XP calculation, trust levels, hunger/happiness decay, feeding, petting, and task rewards.
//

import Foundation
import SwiftData

public struct PetProgressionResult: Sendable {
    public let isLevelUp: Bool
    public let newLevel: Int
    public let pawBonus: Int

    public init(isLevelUp: Bool, newLevel: Int, pawBonus: Int = 0) {
        self.isLevelUp = isLevelUp
        self.newLevel = newLevel
        self.pawBonus = pawBonus
    }
}

public enum PetProgressionService {

    // MARK: - Level XP Formulas (matches Android MeiniShopManager.kt)
    public static func calculateMaxXpForLevel(_ level: Int) -> Int {
        let safeLvl = max(1, level)
        switch safeLvl {
        case 1:
            return 120
        case 2...5:
            return 120 + (safeLvl - 1) * 65         // Lvl 2..5: 185..380 XP
        case 6...15:
            return 380 + (safeLvl - 5) * 95         // Lvl 6..15: 475..1330 XP
        case 16...30:
            return 1330 + (safeLvl - 15) * 140      // Lvl 16..30: 1470..3430 XP
        default:
            return 3430 + (safeLvl - 30) * 190      // Lvl 31..50+: 3620..7230 XP
        }
    }

    public static func getLevelUpPawReward(newLevel: Int) -> Int {
        if newLevel <= 10 {
            return 40
        } else if newLevel <= 25 {
            return 60
        } else {
            return 80
        }
    }

    // MARK: - Natural Time Decay (matches Android PetProgressionDomainService.kt)
    @discardableResult
    public static func applyTimeDecay(pet: PetItem, now: Date = Date()) -> Bool {
        let elapsed = max(0, now.timeIntervalSince(pet.lastSaved))
        let elapsedHours = elapsed / 3600.0
        guard elapsedHours >= 0.05 else { return false } // Ignore < 3 minutes

        // 7.5% hunger decay per hour, 3.0% happiness decay per hour
        let hungerLoss = Int(elapsedHours * 7.5)
        let happyLoss = Int(elapsedHours * 3.0)
        guard hungerLoss > 0 || happyLoss > 0 else { return false }

        pet.hungerPercent = min(100, max(10, pet.hungerPercent - hungerLoss))
        pet.happinessPercent = min(100, max(15, pet.happinessPercent - happyLoss))
        pet.lastSaved = now
        return true
    }

    // MARK: - Core Progression Update
    public static func applyProgression(
        pet: PetItem,
        xpGain: Int = 0,
        hungerDelta: Int = 0,
        happinessDelta: Int = 0,
        stoneDelta: Int = 0,
        treatDelta: Int = 0,
        forceFullHunger: Bool = false,
        now: Date = Date()
    ) -> PetProgressionResult {
        // First decay time before awarding new gains
        applyTimeDecay(pet: pet, now: now)

        let targetMaxXp = calculateMaxXpForLevel(pet.level)
        let newXp = pet.currentXp + max(0, xpGain)
        let isLevelUp = newXp >= targetMaxXp
        let nextLevel = isLevelUp ? pet.level + 1 : pet.level
        let nextMaxXp = calculateMaxXpForLevel(nextLevel)

        pet.hungerPercent = forceFullHunger ? 100 : min(100, max(0, pet.hungerPercent + hungerDelta))
        pet.happinessPercent = min(100, max(0, pet.happinessPercent + happinessDelta))
        pet.stoneCount = max(0, pet.stoneCount + stoneDelta)
        pet.treatCount = max(0, pet.treatCount + treatDelta)
        pet.currentXp = isLevelUp ? max(0, newXp - targetMaxXp) : newXp
        pet.maxXp = nextMaxXp
        pet.level = nextLevel
        pet.lastSaved = now

        let pawReward = isLevelUp ? getLevelUpPawReward(newLevel: nextLevel) : 0
        return PetProgressionResult(isLevelUp: isLevelUp, newLevel: nextLevel, pawBonus: pawReward)
    }

    // MARK: - Task Completion Reward (Maine Quests & Standard Tasks)
    public static func rewardTaskCompleted(
        pet: PetItem,
        priority: Int,
        isMaineQuest: Bool,
        now: Date = Date()
    ) -> PetProgressionResult {
        let isPriority = priority > 0
        let xpGain: Int
        let stoneGain: Int
        let treatGain: Int
        let happyGain: Int

        if isMaineQuest {
            xpGain = 50
            stoneGain = 1
            treatGain = 1
            happyGain = 10
        } else if isPriority {
            xpGain = 30
            stoneGain = 0
            treatGain = 1
            happyGain = 3
        } else {
            xpGain = 10
            stoneGain = 1
            treatGain = 0
            happyGain = 3
        }

        return applyProgression(
            pet: pet,
            xpGain: xpGain,
            hungerDelta: 0,
            happinessDelta: happyGain,
            stoneDelta: stoneGain,
            treatDelta: treatGain,
            now: now
        )
    }

    // MARK: - Petting & Interactions
    public static func petTheCat(pet: PetItem, now: Date = Date()) -> PetProgressionResult {
        pet.lastPetDate = now
        return applyProgression(
            pet: pet,
            xpGain: 5,
            hungerDelta: 0,
            happinessDelta: 4,
            now: now
        )
    }

    public static func feedStone(pet: PetItem, now: Date = Date()) -> PetProgressionResult? {
        guard pet.stoneCount > 0 else { return nil }
        return applyProgression(
            pet: pet,
            xpGain: 15,
            hungerDelta: 15,
            happinessDelta: 5,
            stoneDelta: -1,
            now: now
        )
    }

    public static func feedTreat(pet: PetItem, now: Date = Date()) -> PetProgressionResult? {
        guard pet.treatCount > 0 else { return nil }
        return applyProgression(
            pet: pet,
            xpGain: 25,
            hungerDelta: 25,
            happinessDelta: 20,
            treatDelta: -1,
            now: now
        )
    }

    public static func playWithLaser(pet: PetItem, now: Date = Date()) -> PetProgressionResult {
        return applyProgression(
            pet: pet,
            xpGain: 15,
            hungerDelta: -3,
            happinessDelta: 12,
            now: now
        )
    }

    public static func brushFur(pet: PetItem, now: Date = Date()) -> PetProgressionResult {
        return applyProgression(
            pet: pet,
            xpGain: 20,
            hungerDelta: 0,
            happinessDelta: 8,
            now: now
        )
    }
}
