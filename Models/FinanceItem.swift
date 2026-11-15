//
//  FinanceItem.swift
//  Plan4U_iOS
//
//  SwiftData Model matching Android FinanceEntity.kt 1-to-1
//

import Foundation
import SwiftData

@Model
public final class FinanceItem {
    @Attribute(.unique) public var id: String
    public var type: String // "income", "expense", "transfer"
    public var amount: Double
    public var category: String
    public var date: String // "yyyy-MM-dd"
    public var note: String?
    public var timestamp: Int64
    public var currency: String
    public var originalAmount: Double
    public var exchangeRate: Double
    public var toCurrency: String?
    public var toAmount: Double?
    public var walletId: String
    public var toWalletId: String?

    public init(
        id: String = UUID().uuidString,
        type: String = "expense",
        amount: Double = 0.0,
        category: String = "",
        date: String = "",
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        currency: String = "RUB",
        originalAmount: Double = 0.0,
        exchangeRate: Double = 1.0,
        toCurrency: String? = nil,
        toAmount: Double? = nil,
        walletId: String = "wallet_card",
        toWalletId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
        self.timestamp = timestamp
        self.currency = currency
        self.originalAmount = originalAmount > 0.0 ? originalAmount : amount
        self.exchangeRate = exchangeRate > 0.0 ? exchangeRate : 1.0
        self.toCurrency = toCurrency
        self.toAmount = toAmount
        self.walletId = walletId
        self.toWalletId = toWalletId
    }

    public var effectiveOriginalAmount: Double {
        originalAmount > 0.0 ? originalAmount : amount
    }

    public var isIncome: Bool {
        type == "income"
    }

    public var isExpense: Bool {
        type == "expense"
    }

    public var isTransfer: Bool {
        type == "transfer"
    }
}
