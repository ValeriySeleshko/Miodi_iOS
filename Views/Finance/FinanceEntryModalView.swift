//
//  FinanceEntryModalView.swift
//  Plan4U_iOS
//
//  Advanced Finance Entry Modal matching Android FinanceEntryModal.kt 1-to-1.
//  Category grid (3 cols), Amount field with integrated Calculator & quick chips (+10..+1000),
//  Interactive multi-currency selector (RUB, USD, EUR, KZT, BYN, UAH) with live rate conversion,
//  Wallet selector (Card, Cash, Savings, Crypto), Date picker and Note.
//

import SwiftUI
import SwiftData

public struct FinanceEntryModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public var transactionToEdit: FinanceItem?
    public var initialType: String = "expense"
    public var initialDate: String?
    public var baseCurrencySymbol: String = "₽"
    public let onSave: (Double, String, String, String, String, Double, String) -> Void // amount, category, date, note, currency, rate, walletId

    @State private var entryType: String = "expense" // "expense" or "income"
    @State private var selectedCategoryId: String = "cat_food"
    @State private var amountText: String = ""
    @State private var noteText: String = ""
    @State private var dateStr: String = ""
    @State private var selectedCurrency: String = "₽"
    @State private var customExchangeRateText: String = "1.0"
    @State private var isEditingRate: Bool = false
    @State private var selectedWalletId: String = "wallet_card"
    @State private var showCurrencyPicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showCalculatorPad: Bool = false

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

    private var inputBg: Color {
        isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF8FAFC)
    }

    private var actionColor: Color {
        entryType == "income" ? Color(hex: 0x10B981) : theme.currentAccent.primary
    }

    private var availableCategories: [FinanceCategory] {
        if entryType == "income" {
            return FinanceCategory.defaultIncomeCategories
        } else {
            return FinanceCategory.defaultExpenseCategories
        }
    }

    private var exchangeRate: Double {
        if selectedCurrency == baseCurrencySymbol { return 1.0 }
        if let custom = Double(customExchangeRateText), custom > 0 {
            return custom
        }
        return FinanceCurrency.exchangeRate(from: selectedCurrency, to: baseCurrencySymbol)
    }

    private var evaluatedAmount: Double {
        evaluateExpression(amountText)
    }

    private var convertedBaseAmount: Double {
        if selectedCurrency == baseCurrencySymbol {
            return evaluatedAmount
        }
        return round(evaluatedAmount * exchangeRate * 100.0) / 100.0
    }

    public init(
        transactionToEdit: FinanceItem? = nil,
        initialType: String = "expense",
        initialDate: String? = nil,
        baseCurrencySymbol: String = "₽",
        onSave: @escaping (Double, String, String, String, String, Double, String) -> Void
    ) {
        self.transactionToEdit = transactionToEdit
        self.initialType = initialType
        self.initialDate = initialDate
        self.baseCurrencySymbol = baseCurrencySymbol
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Segmented Type Selector (Расход / Доход)
                    Picker("Тип операции", selection: $entryType) {
                        Text("Расход").tag("expense")
                        Text("Доход").tag("income")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 2)
                    .onChange(of: entryType) { _, newType in
                        MiodiHapticFeedback.selection()
                        if newType == "income" {
                            selectedCategoryId = "cat_salary"
                        } else {
                            selectedCategoryId = "cat_food"
                        }
                    }

                    // Category Selection Grid (3 columns)
                    categoryGridSection

                    // Amount Input Field with Currency Capsule & Calculator Button
                    amountInputCard

                    // Quick Amounts Row (+10..+1000)
                    quickAmountsRow

                    // Optional Inline Calculator Pad
                    if showCalculatorPad {
                        calculatorPadView
                    }

                    // Wallet Selector Strip
                    walletSelectorStrip

                    // Live Foreign Currency Conversion Banner
                    if selectedCurrency != baseCurrencySymbol {
                        currencyConversionBanner
                    }

                    // Date & Note Row
                    dateAndNoteRow

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
            .background(isDark ? Color(hex: 0x0B0D14) : Color(hex: 0xF8FAFC))
            .navigationTitle(transactionToEdit == nil ? (entryType == "income" ? "Новый доход" : "Новый расход") : "Редактировать запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                    } label: {
                        Text("✓ Сохранить")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(actionColor)
                    }
                    .disabled(evaluatedAmount <= 0)
                }
            }
            .sheet(isPresented: $showCurrencyPicker) {
                currencyPickerSheet
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .onAppear {
                setupInitialState()
            }
        }
    }

    // MARK: - Initial State Setup
    private func setupInitialState() {
        if let tx = transactionToEdit {
            entryType = tx.type
            amountText = (tx.effectiveOriginalAmount.truncatingRemainder(dividingBy: 1) == 0) ?
                "\(Int(tx.effectiveOriginalAmount))" : String(format: "%.2f", tx.effectiveOriginalAmount)
            selectedCategoryId = tx.category
            noteText = tx.note ?? ""
            dateStr = tx.date
            selectedCurrency = tx.currency.isEmpty ? baseCurrencySymbol : tx.currency
            customExchangeRateText = String(format: "%.3f", tx.exchangeRate)
            selectedWalletId = tx.walletId.isEmpty ? "wallet_card" : tx.walletId
        } else {
            entryType = initialType
            selectedCategoryId = (initialType == "income") ? "cat_salary" : "cat_food"
            dateStr = initialDate ?? Date().yyyyMMddString
            selectedCurrency = baseCurrencySymbol
            customExchangeRateText = "1.0"
            selectedWalletId = "wallet_card"
        }
    }

    // MARK: - Category Grid Section
    private var categoryGridSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ВЫБЕРИТЕ КАТЕГОРИЮ:")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(textSecondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(availableCategories) { cat in
                    let isSelected = cat.id == selectedCategoryId
                    Button {
                        MiodiHapticFeedback.lightClick()
                        selectedCategoryId = cat.id
                    } label: {
                        VStack(spacing: 4) {
                            Text(cat.emoji)
                                .font(.system(size: 22))

                            Text(cat.name)
                                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? cat.color.opacity(isDark ? 0.28 : 0.12) : cardBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? cat.color : (isDark ? Color(hex: 0x2A3245) : Color(hex: 0xE2E8F0)), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Amount Input Card
    private var amountInputCard: some View {
        HStack(spacing: 8) {
            // Calculator toggle button
            Button {
                MiodiHapticFeedback.lightClick()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showCalculatorPad.toggle()
                }
            } label: {
                Image(systemName: showCalculatorPad ? "keyboard" : "plus.forwardslash.minus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(showCalculatorPad ? actionColor : textSecondary)
                    .frame(width: 44, height: 44)
                    .background(inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Centered Amount TextField
            TextField("0", text: $amountText)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.numbersAndPunctuation)

            // Currency Selector Capsule
            Button {
                MiodiHapticFeedback.lightClick()
                showCurrencyPicker = true
            } label: {
                let info = FinanceCurrency.resolve(symbolOrCode: selectedCurrency)
                HStack(spacing: 4) {
                    Text(info.flag)
                        .font(.system(size: 14))
                    Text(selectedCurrency)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(selectedCurrency != baseCurrencySymbol ? actionColor : textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(selectedCurrency != baseCurrencySymbol ? actionColor.opacity(0.15) : inputBg)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selectedCurrency != baseCurrencySymbol ? actionColor : Color.clear, lineWidth: 1)
                )
            }
        }
        .padding(10)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(actionColor.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Quick Amounts Row (+10..+1000)
    private var quickAmountsRow: some View {
        let quickDeltas = [10, 50, 100, 200, 500, 1000]
        return HStack(spacing: 6) {
            ForEach(quickDeltas, id: \.self) { delta in
                Button {
                    MiodiHapticFeedback.lightClick()
                    let current = evaluatedAmount
                    let sum = current + Double(delta)
                    amountText = (sum.truncatingRemainder(dividingBy: 1) == 0) ? "\(Int(sum))" : String(format: "%.2f", sum)
                } label: {
                    Text("+\(delta)")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Inline Calculator Pad
    private var calculatorPadView: some View {
        let buttons: [[String]] = [
            ["7", "8", "9", "/"],
            ["4", "5", "6", "*"],
            ["1", "2", "3", "-"],
            ["C", "0", "=", "+"]
        ]

        return VStack(spacing: 6) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { btn in
                        Button {
                            handleCalculatorKey(btn)
                        } label: {
                            Text(btn)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(btn == "=" || btn == "+" || btn == "-" || btn == "*" || btn == "/" ? actionColor : textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isDark ? Color(hex: 0x2E3547) : Color(hex: 0xE2E8F0), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(inputBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func handleCalculatorKey(_ key: String) {
        MiodiHapticFeedback.lightClick()
        switch key {
        case "C":
            amountText = ""
        case "=":
            let result = evaluateExpression(amountText)
            amountText = (result.truncatingRemainder(dividingBy: 1) == 0) ? "\(Int(result))" : String(format: "%.2f", result)
        case "+", "-", "*", "/":
            amountText.append(key)
        default:
            amountText.append(key)
        }
    }

    // MARK: - Wallet Selector Strip
    private var walletSelectorStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("СЧЕТ / КОШЕЛЕК:")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(textSecondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FinanceWallet.defaultWallets) { wallet in
                        let isSelected = wallet.id == selectedWalletId
                        Button {
                            MiodiHapticFeedback.lightClick()
                            selectedWalletId = wallet.id
                        } label: {
                            HStack(spacing: 6) {
                                Text(wallet.icon)
                                    .font(.system(size: 14))
                                Text(wallet.name)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? actionColor : textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? actionColor.opacity(0.14) : cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? actionColor : (isDark ? Color(hex: 0x2A3245) : Color(hex: 0xE2E8F0)), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Currency Conversion Banner
    private var currencyConversionBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Text("В базовой валюте:")
                    .font(.system(size: 12))
                    .foregroundStyle(textSecondary)
                Spacer()
                Text("≈ \(formatMoney(convertedBaseAmount)) \(baseCurrencySymbol)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(textPrimary)
            }

            HStack {
                Text("Курс: 1 \(selectedCurrency) =")
                    .font(.system(size: 12))
                    .foregroundStyle(textSecondary)

                TextField("Курс", text: $customExchangeRateText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(actionColor)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

                Text(baseCurrencySymbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(textPrimary)
                Spacer()
            }
        }
        .padding(12)
        .background(isDark ? Color(hex: 0x172030) : Color(hex: 0xF1F5F9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(actionColor.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Date & Note Row
    private var dateAndNoteRow: some View {
        HStack(spacing: 10) {
            // Date Button
            Button {
                MiodiHapticFeedback.lightClick()
                showDatePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(textSecondary)
                    Text(dateStr)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textPrimary)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isDark ? Color(hex: 0x2A3245) : Color(hex: 0xE2E8F0), lineWidth: 1)
                )
            }

            // Note TextField
            TextField("Заметка...", text: $noteText)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isDark ? Color(hex: 0x2A3245) : Color(hex: 0xE2E8F0), lineWidth: 1)
                )
        }
    }

    // MARK: - Currency Picker Sheet
    private var currencyPickerSheet: some View {
        NavigationStack {
            List(FinanceCurrency.supportedCurrencies) { curr in
                Button {
                    MiodiHapticFeedback.selection()
                    selectedCurrency = curr.symbol
                    customExchangeRateText = String(format: "%.3f", FinanceCurrency.exchangeRate(from: curr.symbol, to: baseCurrencySymbol))
                    showCurrencyPicker = false
                } label: {
                    HStack(spacing: 12) {
                        Text(curr.flag)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(curr.nameRu) (\(curr.code))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(textPrimary)
                            Text("1 \(curr.symbol) ≈ \(String(format: "%.2f", FinanceCurrency.exchangeRate(from: curr.symbol, to: baseCurrencySymbol))) \(baseCurrencySymbol)")
                                .font(.system(size: 11))
                                .foregroundStyle(textSecondary)
                        }
                        Spacer()
                        if selectedCurrency == curr.symbol {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(actionColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Выбор валюты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { showCurrencyPicker = false }
                }
            }
        }
        .presentationDetents([.fraction(0.55), .large])
    }

    // MARK: - Date Picker Sheet
    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Дата операции",
                    selection: Binding(
                        get: { Date.from(yyyyMMdd: dateStr) ?? Date() },
                        set: { dateStr = $0.yyyyMMddString }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .navigationTitle("Дата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { showDatePicker = false }
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
    }

    // MARK: - Evaluation & Actions
    private func saveEntry() {
        let amount = evaluatedAmount
        guard amount > 0 else { return }
        MiodiHapticFeedback.success()
        onSave(
            amount,
            selectedCategoryId,
            dateStr,
            noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            selectedCurrency,
            exchangeRate,
            selectedWalletId
        )
        dismiss()
    }

    private func evaluateExpression(_ expr: String) -> Double {
        let clean = expr.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")
        if let direct = Double(clean) { return direct }
        guard !clean.isEmpty else { return 0.0 }
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/()")
        guard clean.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return 0.0 }
        do {
            let exp = NSExpression(format: clean)
            if let val = exp.expressionValue(with: nil, context: nil) as? NSNumber {
                return val.doubleValue
            }
        } catch {
            return 0.0
        }
        return 0.0
    }

    private func formatMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}
