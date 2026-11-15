//
//  FinanceModels.swift
//  Plan4U_iOS
//
//  Domain models, currencies, categories, periods, wallets and Zero-Spend Day management.
//  1-to-1 matching Android features in com.miodi.app.features.finance.
//

import SwiftUI
import Foundation

// MARK: - 1. Finance Category
public struct FinanceCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let type: String // "expense" or "income"
    public let colorHex: String
    public let iconSymbol: String // SF Symbol
    public let emoji: String
    public let iconIndex: Int
    public let isCustom: Bool

    public init(
        id: String,
        name: String,
        type: String = "expense",
        colorHex: String = "#22c55e",
        iconSymbol: String = "cart.fill",
        emoji: String = "🛒",
        iconIndex: Int = 0,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.colorHex = colorHex
        self.iconSymbol = iconSymbol
        self.emoji = emoji
        self.iconIndex = iconIndex
        self.isCustom = isCustom
    }

    public var isIncome: Bool { type == "income" }
    public var isExpense: Bool { type == "expense" }

    public var color: Color {
        Color(hexString: colorHex)
    }

    // Default Android 1-to-1 categories
    public static let defaultExpenseCategories: [FinanceCategory] = [
        FinanceCategory(id: "cat_food", name: "Продукты", type: "expense", colorHex: "#22C55E", iconSymbol: "cart.fill", emoji: "🥦", iconIndex: 0),
        FinanceCategory(id: "cat_auto", name: "Авто", type: "expense", colorHex: "#38BDF8", iconSymbol: "car.fill", emoji: "🚗", iconIndex: 14),
        FinanceCategory(id: "cat_restaurants", name: "Кафе", type: "expense", colorHex: "#EAB308", iconSymbol: "fork.knife", emoji: "☕", iconIndex: 2),
        FinanceCategory(id: "cat_rent", name: "Жилье", type: "expense", colorHex: "#A16207", iconSymbol: "house.fill", emoji: "🏠", iconIndex: 7),
        FinanceCategory(id: "cat_hobby", name: "Хобби", type: "expense", colorHex: "#A855F7", iconSymbol: "gamecontroller.fill", emoji: "🎨", iconIndex: 36),
        FinanceCategory(id: "cat_gifts", name: "Подарки", type: "expense", colorHex: "#3B82F6", iconSymbol: "gift.fill", emoji: "🎁", iconIndex: 41),
        FinanceCategory(id: "cat_health", name: "Здоровье", type: "expense", colorHex: "#EC4899", iconSymbol: "heart.fill", emoji: "💊", iconIndex: 28),
        FinanceCategory(id: "cat_shopping", name: "Покупки", type: "expense", colorHex: "#F97316", iconSymbol: "bag.fill", emoji: "🛍️", iconIndex: 21)
    ]

    public static let defaultIncomeCategories: [FinanceCategory] = [
        FinanceCategory(id: "cat_salary", name: "Зарплата", type: "income", colorHex: "#10B981", iconSymbol: "banknote.fill", emoji: "💼", iconIndex: 44),
        FinanceCategory(id: "cat_freelance", name: "Подработка", type: "income", colorHex: "#06B6D4", iconSymbol: "laptopcomputer", emoji: "💻", iconIndex: 46),
        FinanceCategory(id: "cat_savings", name: "Копилка", type: "income", colorHex: "#F43F5E", iconSymbol: "archivebox.fill", emoji: "🐷", iconIndex: 45),
        FinanceCategory(id: "cat_gift_in", name: "Подарок", type: "income", colorHex: "#8B5CF6", iconSymbol: "gift.fill", emoji: "🎁", iconIndex: 41),
        FinanceCategory(id: "cat_initial_balance", name: "Начальный баланс", type: "income", colorHex: "#10B981", iconSymbol: "creditcard.fill", emoji: "💳", iconIndex: 45)
    ]

    public static var allDefaults: [FinanceCategory] {
        defaultExpenseCategories + defaultIncomeCategories
    }

    public static func resolveCategory(idOrName: String?) -> FinanceCategory {
        guard let idOrName = idOrName, !idOrName.isEmpty else {
            return defaultExpenseCategories[0]
        }
        if let found = allDefaults.first(where: { $0.id == idOrName || $0.name.caseInsensitiveCompare(idOrName) == .orderedSame }) {
            return found
        }
        // Aliases / localizations
        let lower = idOrName.lowercased()
        if lower.contains("food") || lower.contains("продукт") || lower.contains("еда") || lower.contains("їжа") {
            return defaultExpenseCategories[0]
        }
        if lower.contains("auto") || lower.contains("авто") || lower.contains("машина") {
            return defaultExpenseCategories[1]
        }
        if lower.contains("caf") || lower.contains("кафе") || lower.contains("ресторан") {
            return defaultExpenseCategories[2]
        }
        if lower.contains("rent") || lower.contains("жиль") || lower.contains("квартир") || lower.contains("аренд") {
            return defaultExpenseCategories[3]
        }
        if lower.contains("salary") || lower.contains("зарплат") || lower.contains("доход") {
            return defaultIncomeCategories[0]
        }
        return FinanceCategory(
            id: idOrName,
            name: idOrName,
            type: "expense",
            colorHex: "#94A3B8",
            iconSymbol: "tag.fill",
            emoji: "🏷️",
            iconIndex: 0
        )
    }
}

// MARK: - 2. Finance Currency
public struct FinanceCurrency: Identifiable, Hashable, Sendable {
    public var id: String { code }
    public let code: String
    public let symbol: String
    public let flag: String
    public let nameRu: String
    public let nameEn: String
    public let defaultRatePerUsd: Double

    public init(
        code: String,
        symbol: String,
        flag: String,
        nameRu: String,
        nameEn: String,
        defaultRatePerUsd: Double
    ) {
        self.code = code
        self.symbol = symbol
        self.flag = flag
        self.nameRu = nameRu
        self.nameEn = nameEn
        self.defaultRatePerUsd = defaultRatePerUsd
    }

    public static let supportedCurrencies: [FinanceCurrency] = [
        FinanceCurrency(code: "RUB", symbol: "₽", flag: "🇷🇺", nameRu: "Рубль", nameEn: "Russian Ruble", defaultRatePerUsd: 96.50),
        FinanceCurrency(code: "USD", symbol: "$", flag: "🇺🇸", nameRu: "Доллар США", nameEn: "US Dollar", defaultRatePerUsd: 1.0),
        FinanceCurrency(code: "EUR", symbol: "€", flag: "🇪🇺", nameRu: "Евро", nameEn: "Euro", defaultRatePerUsd: 0.92),
        FinanceCurrency(code: "KZT", symbol: "₸", flag: "🇰🇿", nameRu: "Казахстанский тенге", nameEn: "Kazakhstani Tenge", defaultRatePerUsd: 486.0),
        FinanceCurrency(code: "BYN", symbol: "Br", flag: "🇧🇾", nameRu: "Белорусский рубль", nameEn: "Belarusian Ruble", defaultRatePerUsd: 3.27),
        FinanceCurrency(code: "UAH", symbol: "₴", flag: "🇺🇦", nameRu: "Гривна", nameEn: "Hryvnia", defaultRatePerUsd: 41.35),
        FinanceCurrency(code: "PLN", symbol: "zł", flag: "🇵🇱", nameRu: "Злотый", nameEn: "Polish Zloty", defaultRatePerUsd: 4.01),
        FinanceCurrency(code: "GBP", symbol: "£", flag: "🇬🇧", nameRu: "Фунт стерлингов", nameEn: "British Pound", defaultRatePerUsd: 0.77),
        FinanceCurrency(code: "TRY", symbol: "₺", flag: "🇹🇷", nameRu: "Турецкая лира", nameEn: "Turkish Lira", defaultRatePerUsd: 34.25),
        FinanceCurrency(code: "GEL", symbol: "₾", flag: "🇬🇪", nameRu: "Грузинский лари", nameEn: "Georgian Lari", defaultRatePerUsd: 2.72)
    ]

    public static func resolve(symbolOrCode: String) -> FinanceCurrency {
        let clean = symbolOrCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { return supportedCurrencies[0] }
        if let found = supportedCurrencies.first(where: {
            $0.symbol == clean || $0.code.caseInsensitiveCompare(clean) == .orderedSame
        }) {
            return found
        }
        return FinanceCurrency(code: clean, symbol: clean, flag: "🌐", nameRu: clean, nameEn: clean, defaultRatePerUsd: 1.0)
    }

    public static func exchangeRate(from: String, to: String) -> Double {
        let fromCur = resolve(symbolOrCode: from)
        let toCur = resolve(symbolOrCode: to)
        if fromCur.code == toCur.code { return 1.0 }
        let fromUsd = fromCur.defaultRatePerUsd > 0 ? fromCur.defaultRatePerUsd : 1.0
        let toUsd = toCur.defaultRatePerUsd > 0 ? toCur.defaultRatePerUsd : 1.0
        return toUsd / fromUsd
    }
}

// MARK: - 3. Finance Wallet
public struct FinanceWallet: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    public let currency: String // empty = base currency
    public let orderIndex: Int
    public let isDefault: Bool
    public let isCustom: Bool

    public init(
        id: String,
        name: String,
        icon: String,
        currency: String = "",
        orderIndex: Int = 0,
        isDefault: Bool = false,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.currency = currency
        self.orderIndex = orderIndex
        self.isDefault = isDefault
        self.isCustom = isCustom
    }

    public static let defaultWallets: [FinanceWallet] = [
        FinanceWallet(id: "wallet_card", name: "Карта", icon: "💳", currency: "", orderIndex: 0, isDefault: true, isCustom: false),
        FinanceWallet(id: "wallet_cash", name: "Наличные", icon: "💵", currency: "", orderIndex: 1, isDefault: true, isCustom: false),
        FinanceWallet(id: "wallet_savings", name: "Копилка", icon: "🐷", currency: "", orderIndex: 2, isDefault: false, isCustom: false),
        FinanceWallet(id: "wallet_crypto", name: "Крипта", icon: "🪙", currency: "USDT", orderIndex: 3, isDefault: false, isCustom: false)
    ]
}

// MARK: - 4. Finance Period
public enum FinancePeriod: String, CaseIterable, Identifiable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"
    case year = "Год"
    case all = "Все"

    public var id: String { rawValue }

    public func dateRange(for date: Date = Date()) -> (start: Date?, end: Date?) {
        let calendar = Calendar.current
        switch self {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
            return (start, end)
        case .week:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
                return (nil, nil)
            }
            return (weekInterval.start, weekInterval.end)
        case .month:
            guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
                return (nil, nil)
            }
            return (monthInterval.start, monthInterval.end)
        case .year:
            guard let yearInterval = calendar.dateInterval(of: .year, for: date) else {
                return (nil, nil)
            }
            return (yearInterval.start, yearInterval.end)
        case .all:
            return (nil, nil)
        }
    }

    public func displaySubtitle(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        let calendar = Calendar.current

        switch self {
        case .day:
            if calendar.isDateInToday(date) {
                formatter.dateFormat = "d MMMM"
                return "Сегодня, \(formatter.string(from: date))"
            } else {
                formatter.dateFormat = "d MMMM yyyy"
                return formatter.string(from: date)
            }
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return "Эта неделя" }
            formatter.dateFormat = "d MMM"
            let startStr = formatter.string(from: interval.start)
            let endDay = calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.end
            let endStr = formatter.string(from: endDay)
            return "\(startStr) — \(endStr)"
        case .month:
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: date).capitalized
        case .year:
            formatter.dateFormat = "yyyy"
            return "\(formatter.string(from: date)) год"
        case .all:
            return "За всё время"
        }
    }

    public func shift(date: Date, forward: Bool) -> Date {
        let step = forward ? 1 : -1
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: step, to: date) ?? date
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: step, to: date) ?? date
        case .month:
            return calendar.date(byAdding: .month, value: step, to: date) ?? date
        case .year:
            return calendar.date(byAdding: .year, value: step, to: date) ?? date
        case .all:
            return date
        }
    }
}

// MARK: - 5. Category Breakdown Item (for Pie/Donut Chart)
public struct CategoryBreakdownItem: Identifiable, Hashable, Sendable {
    public var id: String { categoryId }
    public let categoryId: String
    public let name: String
    public let color: Color
    public let iconSymbol: String
    public let emoji: String
    public let amount: Double
    public let percent: Double // 0..100
    public let transactionCount: Int

    public init(
        categoryId: String,
        name: String,
        color: Color,
        iconSymbol: String,
        emoji: String,
        amount: Double,
        percent: Double,
        transactionCount: Int = 1
    ) {
        self.categoryId = categoryId
        self.name = name
        self.color = color
        self.iconSymbol = iconSymbol
        self.emoji = emoji
        self.amount = amount
        self.percent = percent
        self.transactionCount = transactionCount
    }
}

// MARK: - 6. Zero-Spend Day Manager (День без трат 🏆)
@Observable
public final class NoSpendManager {
    public static let shared = NoSpendManager()

    private let userDefaultsKey = "miodi_no_spend_dates"
    private let pawsCountKey = "miodi_paw_count"

    public private(set) var noSpendDates: Set<String> = []
    public private(set) var pawCount: Int = 0

    private init() {
        load()
    }

    public func load() {
        if let array = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            noSpendDates = Set(array)
        }
        pawCount = UserDefaults.standard.integer(forKey: pawsCountKey)
    }

    public func isNoSpend(date: String) -> Bool {
        noSpendDates.contains(date)
    }

    public func claimNoSpend(date: String) {
        noSpendDates.insert(date)
        pawCount += 2
        UserDefaults.standard.set(Array(noSpendDates), forKey: userDefaultsKey)
        UserDefaults.standard.set(pawCount, forKey: pawsCountKey)
        MiodiHapticFeedback.success()
    }

    public func removeNoSpend(date: String) {
        if noSpendDates.contains(date) {
            noSpendDates.remove(date)
            UserDefaults.standard.set(Array(noSpendDates), forKey: userDefaultsKey)
        }
    }

    public func noSpendCount(forMonthPrefix prefix: String) -> Int {
        noSpendDates.filter { $0.hasPrefix(prefix) }.count
    }
}
