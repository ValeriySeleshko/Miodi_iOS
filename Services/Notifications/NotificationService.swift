//
//  NotificationService.swift
//  Plan4U_iOS
//
//  Local Push Notifications for Tasks & Habits via UNUserNotificationCenter.
//

import Foundation
import UserNotifications

public final class NotificationService {
    public static let shared = NotificationService()

    private init() {}

    public func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    public func scheduleTaskReminder(task: TaskItem) {
        guard let timeStr = task.reminderTime, !timeStr.isEmpty else { return }

        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return }

        let calendar = Calendar.current
        var baseDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if !task.date.isEmpty, let d = formatter.date(from: task.date) {
            baseDate = d
        }

        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0

        guard var scheduledDate = calendar.date(from: comps) else { return }

        if task.reminderOffset > 0 {
            scheduledDate = scheduledDate.addingTimeInterval(-Double(task.reminderOffset * 60))
        }

        guard scheduledDate > Date() else { return } // Already in past

        let content = UNMutableNotificationContent()
        content.title = "Miodi"
        if task.reminderOffset > 0 {
            content.body = "\(task.text) (в \(timeStr))"
        } else {
            content.body = task.text
        }
        content.sound = .default

        let triggerComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        let request = UNNotificationRequest(identifier: "task_\(task.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    public func cancelTaskReminder(task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task_\(task.id)"])
    }
}
