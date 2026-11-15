//
//  Date+Plan4U.swift
//  Plan4U_iOS
//
//  Date parsing and formatting utilities matching Android DateUtils.
//

import Foundation

extension Date {
    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM, EEE"
        f.locale = Locale(identifier: "ru_RU")
        f.timeZone = TimeZone.current
        return f
    }()

    public var yyyyMMddString: String {
        Date.isoDateFormatter.string(from: self)
    }

    public static func from(yyyyMMdd: String) -> Date? {
        Date.isoDateFormatter.date(from: yyyyMMdd)
    }

    public func userFriendlyDateString() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Сегодня, \(Date.displayDateFormatter.string(from: self))"
        } else if calendar.isDateInTomorrow(self) {
            return "Завтра, \(Date.displayDateFormatter.string(from: self))"
        } else if calendar.isDateInYesterday(self) {
            return "Вчера, \(Date.displayDateFormatter.string(from: self))"
        }
        return Date.displayDateFormatter.string(from: self)
    }

    public func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    public func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    public var timeStringHHmm: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale.current
        return f.string(from: self)
    }
}
