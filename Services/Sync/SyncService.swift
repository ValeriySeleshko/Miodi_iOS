//
//  SyncService.swift
//  Plan4U_iOS
//
//  Cross-platform sync & backup service matching BackupManager.kt
//  Allows zero-conflict data exchange between Android (S24 Ultra) and iOS (iPhone).
//

import Foundation
import SwiftData

public struct MiodiBackupPayload: Codable {
    public let version: Int
    public let timestamp: Int64
    public let tasks: [TaskDTO]
    public let habits: [HabitDTO]
    public let finance: [FinanceDTO]
    public let diary: [DiaryDTO]

    public struct TaskDTO: Codable {
        public let id: String
        public let text: String
        public let isCompleted: Bool
        public let date: String
        public let orderIndex: Int
    }

    public struct HabitDTO: Codable {
        public let id: String
        public let title: String
        public let type: String
        public let orderIndex: Int
    }

    public struct FinanceDTO: Codable {
        public let id: String
        public let type: String
        public let amount: Double
        public let category: String
        public let date: String
    }

    public struct DiaryDTO: Codable {
        public let id: String
        public let date: String
        public let time: String
        public let content: String
        public var formattingJson: String? = nil
    }
}

public final class SyncService {
    public static let shared = SyncService()

    private init() {}

    /// Export complete database state to portable JSON string
    public func exportBackupJson(
        tasks: [TaskItem],
        habits: [HabitItem],
        finance: [FinanceItem],
        diary: [DiaryItem]
    ) throws -> String {
        let payload = MiodiBackupPayload(
            version: 1,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            tasks: tasks.map { .init(id: $0.id, text: $0.text, isCompleted: $0.isCompleted, date: $0.date, orderIndex: $0.orderIndex) },
            habits: habits.map { .init(id: $0.id, title: $0.title, type: $0.type, orderIndex: $0.orderIndex) },
            finance: finance.map { .init(id: $0.id, type: $0.type, amount: $0.amount, category: $0.category, date: $0.date) },
            diary: diary.map { .init(id: $0.id, date: $0.date, time: $0.time, content: $0.content, formattingJson: $0.formattingJson) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(payload)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
