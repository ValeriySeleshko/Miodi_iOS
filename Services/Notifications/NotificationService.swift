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

        let content = UNMutableNotificationContent()
        content.title = "Miodi"
        content.body = task.text
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "task_\(task.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    public func cancelTaskReminder(task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task_\(task.id)"])
    }
}
