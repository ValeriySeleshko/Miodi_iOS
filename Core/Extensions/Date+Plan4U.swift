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

    public func fullWeekdayNameCapitalized(languageCode: String = "ru") -> String {
        let weekday = Calendar.current.component(.weekday, from: self) // 1 = Sun, 2 = Mon ... 7 = Sat
        let index = (weekday + 5) % 7 // 0 = Mon ... 6 = Sun
        let names: [String]
        switch languageCode.lowercased() {
        case "uk":
            names = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця", "Субота", "Неділя"]
        case "en":
            names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        case "lt":
            names = ["Pirmadienis", "Antradienis", "Trečiadienis", "Ketvirtadienis", "Penktadienis", "Šeštadienis", "Sekmadienis"]
        case "de":
            names = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
        case "fr":
            names = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        case "es":
            names = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        case "pl":
            names = ["Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota", "Niedziela"]
        case "pt":
            names = ["Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"]
        case "it":
            names = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
        case "tr":
            names = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]
        case "id", "in":
            names = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
        default:
            names = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
        }
        return names[min(max(0, index), 6)]
    }

    public static func formatMomentDateWithWeekday(_ rawDate: String, languageCode: String = "ru") -> String {
        let cleanDate = rawDate.components(separatedBy: "#").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !cleanDate.isEmpty, let parsedDate = Date.from(yyyyMMdd: cleanDate) else {
            return cleanDate
        }
        let digitalDate = formatDigitalDate(cleanDate, languageCode: languageCode)
        return "\(digitalDate) \(parsedDate.fullWeekdayNameCapitalized(languageCode: languageCode))"
    }

    public static func formatDigitalDate(_ isoDate: String, languageCode: String = "ru") -> String {
        let clean = isoDate.components(separatedBy: "#").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !clean.isEmpty else { return "" }
        let parts = clean.components(separatedBy: "-")
        guard parts.count == 3 else { return clean }
        let y = parts[0]
        let m = parts[1]
        let d = parts[2]
        if languageCode.lowercased() == "en" {
            return "\(m)/\(d)/\(y)"
        } else {
            return "\(d).\(m).\(y)"
        }
    }
}
