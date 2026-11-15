//
//  FinanceTransferModalView.swift
//  Plan4U_iOS
//
//  Transfer / Currency Exchange modal between wallets.
//  Matching Android FinanceExchangeModal.kt.
//

import SwiftUI
import SwiftData

public struct FinanceTransferModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public var baseCurrencySymbol: String = "₽"
    public let onSaveTransfer: (Double, String, String, Double, String, String, String, String?) -> Void // fromAmount, fromWalletId, toWalletId, toAmount, fromCurr, toCurr, date, note

    @State private var fromWalletId: String = "wallet_card"
    @State private var toWalletId: String = "wallet_cash"
    @State private var fromAmountText: String = ""
    @State private var toAmountText: String = ""
    @State private var fromCurrency: String = "₽"
    @State private var toCurrency: String = "₽"
    @State private var exchangeRateText: String = "1.0"
    @State private var dateStr: String = Date().yyyyMMddString
    @State private var noteText: String = ""

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var cardBg: Color {
        isDark ? Color(hex: 0x161A24) : Color.white
    }

    private var textPrimary: Color {
        isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x0F172A)
    }

    private var textSecondary: Color {
        isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B)
    }

    public init(
        baseCurrencySymbol: String = "₽",
        onSaveTransfer: @escaping (Double, String, String, Double, String, String, String, String?) -> Void
    ) {
        self.baseCurrencySymbol = baseCurrencySymbol
        self.onSaveTransfer = onSaveTransfer
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Откуда перевести") {
                    Picker("Счет списания", selection: $fromWalletId) {
                        ForEach(FinanceWallet.defaultWallets) { w in
                            Text("\(w.icon) \(w.name)").tag(w.id)
                        }
                    }

                    TextField("Сумма списания", text: $fromAmountText)
                        .keyboardType(.decimalPad)
                        .onChange(of: fromAmountText) { _, newFrom in
                            updateToAmount(from: newFrom)
                        }
                }

                Section("Куда зачислить") {
                    Picker("Счет зачисления", selection: $toWalletId) {
                        ForEach(FinanceWallet.defaultWallets) { w in
                            Text("\(w.icon) \(w.name)").tag(w.id)
                        }
                    }

                    TextField("Сумма зачисления", text: $toAmountText)
                        .keyboardType(.decimalPad)
                }

                Section("Курс и Заметка") {
                    HStack {
                        Text("Курс обмена")
                        Spacer()
                        TextField("1.0", text: $exchangeRateText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }

                    TextField("Заметка (необязательно)", text: $noteText)
                }
            }
            .navigationTitle("Перевод / Обмен")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Перевести") {
                        saveTransfer()
                    }
                    .disabled(Double(fromAmountText) == nil || fromWalletId == toWalletId)
                }
            }
        }
    }

    private func updateToAmount(from: String) {
        guard let f = Double(from), let rate = Double(exchangeRateText), rate > 0 else { return }
        let to = f * rate
        toAmountText = (to.truncatingRemainder(dividingBy: 1) == 0) ? "\(Int(to))" : String(format: "%.2f", to)
    }

    private func saveTransfer() {
        guard let fromAmt = Double(fromAmountText), fromAmt > 0 else { return }
        let toAmt = Double(toAmountText) ?? fromAmt
        MiodiHapticFeedback.success()
        onSaveTransfer(
            fromAmt,
            fromWalletId,
            toWalletId,
            toAmt,
            fromCurrency,
            toCurrency,
            dateStr,
            noteText.isEmpty ? nil : noteText
        )
        dismiss()
    }
}
