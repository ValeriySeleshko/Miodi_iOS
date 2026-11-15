//
//  FinanceView.swift
//  Plan4U_iOS
//
//  Master Finance Screen matching Android FinanceScreen.kt 100%.
//  Period Tabs (День, Неделя, Месяц, Год, Все) with Date Navigation,
//  Interactive SectorMark/Donut Chart with category filtering,
//  Multi-Currency Wallet Pockets Strip (Card, Cash, Savings, Crypto),
//  Zero-Spend Day ("День без трат" 🏆) with Archive Trophy & Paw prints (+2 🐾),
//  Transactions list with full Swipe Actions: Delete, Edit, Duplicate,
//  and Bottom Action FABs: (+) Income, (⇄) Transfer, (–) Expense.
//

import SwiftUI
import SwiftData

public struct FinanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \FinanceItem.timestamp, order: .reverse) private var allTransactions: [FinanceItem]

    // Navigation and Period State
    @State private var selectedPeriod: FinancePeriod = .month
    @State private var currentDate: Date = Date()
    @State private var selectedTab: Int = 0 // 0 = Обзор (Donut), 1 = История, 2 = Аналитика
    @State private var focusedCategoryId: String? = nil
    @State private var selectedWalletId: String? = nil // nil = All wallets
    @State private var baseCurrency: String = "₽"

    // Modals
    @State private var isAddingEntry: Bool = false
    @State private var entryModalIsIncome: Bool = false
    @State private var editingTransaction: FinanceItem? = nil
    @State private var isTransferModalOpen: Bool = false
    @State private var isNoSpendModalOpen: Bool = false

    private var noSpendManager: NoSpendManager {
        NoSpendManager.shared
    }

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

    // Filter transactions by period and wallet
    private var filteredTransactions: [FinanceItem] {
        let (startDate, endDate) = selectedPeriod.dateRange(for: currentDate)
        var list = allTransactions

        if let start = startDate, let end = endDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)
            list = list.filter { $0.date >= startStr && $0.date <= endStr }
        }

        if let wId = selectedWalletId {
            list = list.filter { $0.walletId == wId }
        }

        if let focusedCat = focusedCategoryId {
            list = list.filter { $0.category == focusedCat }
        }

        return list
    }

    private var expenses: [FinanceItem] {
        filteredTransactions.filter { $0.type == "expense" }
    }

    private var incomes: [FinanceItem] {
        filteredTransactions.filter { $0.type == "income" }
    }

    private var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.effectiveOriginalAmount }
    }

    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.effectiveOriginalAmount }
    }

    private var currentBalance: Double {
        totalIncome - totalExpense
    }

    // Category breakdown for Donut Chart
    private var categoryBreakdown: [CategoryBreakdownItem] {
        if totalExpense <= 0 { return [] }
        var grouped: [String: (amount: Double, count: Int)] = [:]
        for exp in expenses {
            let catKey = exp.category.isEmpty ? "Продукты" : exp.category
            let current = grouped[catKey] ?? (0.0, 0)
            grouped[catKey] = (current.amount + exp.effectiveOriginalAmount, current.count + 1)
        }

        return grouped.map { catName, val in
            let cat = FinanceCategory.resolveCategory(idOrName: catName)
            let pct = (val.amount / totalExpense) * 100.0
            return CategoryBreakdownItem(
                categoryId: cat.id,
                name: cat.name,
                color: cat.color,
                iconSymbol: cat.iconSymbol,
                emoji: cat.emoji,
                amount: val.amount,
                percent: pct,
                transactionCount: val.count
            )
        }.sorted { $0.amount > $1.amount }
    }

    private var currentDateStr: String {
        currentDate.yyyyMMddString
    }

    private var isCurrentDayZeroSpend: Bool {
        noSpendManager.isNoSpend(date: currentDateStr)
    }

    public init() {}

    public var body: some View {
        ZStack {
            // Paper Notebook Background
            NotebookCanvasView(
                patternType: .lines,
                patternSize: 32,
                marginLineX: 50,
                isDarkTheme: isDark
            )

            VStack(spacing: 0) {
                // Header: Title, Zero-Spend Trophy Button, and Period Switcher
                topHeaderSection

                // Period Tabs (День, Неделя, Месяц, Год, Все)
                periodTabsRow

                // Segmented View Mode Picker (🍩 Обзор | 📋 История | 📊 Аналитика)
                modeSwitcherBar

                // Content View according to selectedTab
                Group {
                    switch selectedTab {
                    case 0:
                        overviewTabContent
                    case 1:
                        historyTabContent
                    case 2:
                        FinanceAnalyticsView(
                            transactions: allTransactions,
                            currencySymbol: baseCurrency,
                            selectedPeriod: $selectedPeriod,
                            currentDate: $currentDate,
                            onAddExpense: {
                                entryModalIsIncome = false
                                editingTransaction = nil
                                isAddingEntry = true
                            },
                            onClaimZeroSpend: {
                                isNoSpendModalOpen = true
                            }
                        )
                    default:
                        overviewTabContent
                    }
                }
            }

            // Bottom Floating Action Buttons
            if selectedTab != 2 {
                bottomFabsRow
            }
        }
        .sheet(isPresented: $isAddingEntry) {
            FinanceEntryModalView(
                transactionToEdit: editingTransaction,
                initialType: entryModalIsIncome ? "income" : "expense",
                initialDate: currentDateStr,
                baseCurrencySymbol: baseCurrency
            ) { amount, category, date, note, currency, rate, walletId in
                if let editing = editingTransaction {
                    editing.amount = amount
                    editing.originalAmount = amount
                    editing.category = category
                    editing.date = date
                    editing.note = note.isEmpty ? nil : note
                    editing.currency = currency
                    editing.exchangeRate = rate
                    editing.walletId = walletId
                } else {
                    let newItem = FinanceItem(
                        type: entryModalIsIncome ? "income" : "expense",
                        amount: amount,
                        category: category,
                        date: date,
                        note: note.isEmpty ? nil : note,
                        currency: currency,
                        originalAmount: amount,
                        exchangeRate: rate,
                        walletId: walletId
                    )
                    modelContext.insert(newItem)
                }
                try? modelContext.save()
                editingTransaction = nil
            }
            .presentationDetents([.fraction(0.88), .large])
        }
        .sheet(isPresented: $isTransferModalOpen) {
            FinanceTransferModalView(
                baseCurrencySymbol: baseCurrency
            ) { fromAmt, fromWallet, toWallet, toAmt, fromCurr, toCurr, date, note in
                let transferItem = FinanceItem(
                    type: "transfer",
                    amount: fromAmt,
                    category: "Перевод",
                    date: date,
                    note: note,
                    currency: fromCurr,
                    originalAmount: fromAmt,
                    exchangeRate: 1.0,
                    toCurrency: toCurr,
                    toAmount: toAmt,
                    walletId: fromWallet,
                    toWalletId: toWallet
                )
                modelContext.insert(transferItem)
                try? modelContext.save()
            }
            .presentationDetents([.fraction(0.65)])
        }
        .overlay {
            if isNoSpendModalOpen {
                NoSpendDayModalView(
                    dateStr: currentDateStr,
                    isDarkTheme: isDark,
                    onConfirmNoSpend: {
                        noSpendManager.claimNoSpend(date: currentDateStr)
                        isNoSpendModalOpen = false
                    },
                    onAddExpense: {
                        isNoSpendModalOpen = false
                        entryModalIsIncome = false
                        editingTransaction = nil
                        isAddingEntry = true
                    },
                    onDismiss: {
                        isNoSpendModalOpen = false
                    }
                )
            }
        }
    }

    // MARK: - 1. Top Header Section
    private var topHeaderSection: some View {
        HStack {
            Text("Финансы")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(textPrimary)

            Spacer()

            // Paw Counter Badge (+🐾)
            HStack(spacing: 4) {
                Text("🐾")
                    .font(.system(size: 13))
                Text("\(noSpendManager.pawCount)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF59E0B))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: 0xFEF3C7).opacity(isDark ? 0.2 : 0.8))
            .clipShape(Capsule())

            // Quick Zero-Spend Button
            Button {
                MiodiHapticFeedback.lightClick()
                isNoSpendModalOpen = true
            } label: {
                HStack(spacing: 4) {
                    Text("🏆")
                        .font(.system(size: 14))
                    if isCurrentDayZeroSpend {
                        Text("0 трат!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0xF59E0B))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isDark ? Color(hex: 0x2A2010) : Color(hex: 0xFFFBEB))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: 0xF59E0B).opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - 2. Period Tabs Row
    private var periodTabsRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(FinancePeriod.allCases) { period in
                    let isSelected = selectedPeriod == period
                    Button {
                        MiodiHapticFeedback.selection()
                        selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isSelected ? theme.currentAccent.primary : (isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Date Navigation Bar (< Subtitle >)
            HStack {
                Button {
                    MiodiHapticFeedback.selection()
                    currentDate = selectedPeriod.shift(date: currentDate, forward: false)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(textSecondary)
                        .frame(width: 28, height: 28)
                        .background(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                        .clipShape(Circle())
                }

                Spacer()

                Text(selectedPeriod.displaySubtitle(for: currentDate))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(textPrimary)

                Spacer()

                Button {
                    MiodiHapticFeedback.selection()
                    currentDate = selectedPeriod.shift(date: currentDate, forward: true)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(textSecondary)
                        .frame(width: 28, height: 28)
                        .background(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 6)
    }

    // MARK: - 3. Mode Switcher Bar
    private var modeSwitcherBar: some View {
        HStack(spacing: 6) {
            modeButton(index: 0, title: "🍩 Обзор")
            modeButton(index: 1, title: "📋 История")
            modeButton(index: 2, title: "📊 Аналитика")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func modeButton(index: Int, title: String) -> some View {
        let isSelected = selectedTab == index
        return Button {
            MiodiHapticFeedback.selection()
            selectedTab = index
        } label: {
            Text(title)
                .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? theme.currentAccent.primary : textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? theme.currentAccent.primary.opacity(0.14) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Overview Tab Content (Donut, Balance, Wallets, Zero-spend)
    private var overviewTabContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Interactive Donut Chart
                FinanceDonutChartView(
                    items: categoryBreakdown,
                    totalExpense: totalExpense,
                    focusedCategoryId: focusedCategoryId,
                    currencySymbol: baseCurrency,
                    isDarkTheme: isDark
                ) { newFocus in
                    focusedCategoryId = newFocus
                }
                .padding(.top, 4)

                // Zero-Spend Day Claim Banner (if 0 expenses)
                if totalExpense <= 0 {
                    zeroSpendBanner
                }

                // Balance & Summary Card with Wallet Strip
                balanceSummaryCard

                // Recent Transactions Preview
                recentTransactionsSection

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Zero-Spend Banner
    private var zeroSpendBanner: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            isNoSpendModalOpen = true
        } label: {
            HStack(spacing: 12) {
                Text("🏆")
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 2) {
                    Text(isCurrentDayZeroSpend ? "День без трат зафиксирован! 🏆" : "Зафиксировать день без трат (+2 🐾)")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(isDark ? Color(hex: 0xFDE68A) : Color(hex: 0x92400E))
                    Text(isCurrentDayZeroSpend ? "Бюджет сохранен в целости ✨" : "Нажмите, чтобы получить трофей за осознанную экономию")
                        .font(.system(size: 11.5))
                        .foregroundStyle(isDark ? Color(hex: 0xFDE68A).opacity(0.8) : Color(hex: 0xB45309))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF59E0B))
            }
            .padding(14)
            .background(isDark ? Color(hex: 0x2A1F10) : Color(hex: 0xFEF3C7))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: 0xF59E0B).opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Balance Summary Card
    private var balanceSummaryCard: some View {
        VStack(spacing: 12) {
            // Main Balance Row
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Текущий баланс")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(textSecondary)
                    Text("\(currentBalance >= 0 ? "" : "-")\(formatMoney(abs(currentBalance))) \(baseCurrency)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(currentBalance >= 0 ? Color(hex: 0x10B981) : Color(hex: 0xEF4444))
                }
                Spacer()
            }

            // Wallet Pockets Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All Wallets Pill
                    walletPill(id: nil, name: "Все счета", icon: "🌐", balance: currentBalance)

                    ForEach(FinanceWallet.defaultWallets) { w in
                        let wBal = calculateWalletBalance(w.id)
                        walletPill(id: w.id, name: w.name, icon: w.icon, balance: wBal)
                    }
                }
            }

            Divider()

            // Incomes vs Expenses
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: 0x10B981))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Доходы")
                            .font(.system(size: 10.5))
                            .foregroundStyle(textSecondary)
                        Text("+\(formatMoney(totalIncome)) \(baseCurrency)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: 0x10B981))
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: 0xEF4444))
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Расходы")
                            .font(.system(size: 10.5))
                            .foregroundStyle(textSecondary)
                        Text("-\(formatMoney(totalExpense)) \(baseCurrency)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: 0xEF4444))
                    }
                }
            }
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.04), radius: 8, x: 0, y: 3)
    }

    private func walletPill(id: String?, name: String, icon: String, balance: Double) -> some View {
        let isSelected = selectedWalletId == id
        return Button {
            MiodiHapticFeedback.lightClick()
            selectedWalletId = id
        } label: {
            HStack(spacing: 5) {
                Text(icon)
                    .font(.system(size: 13))
                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? theme.currentAccent.primary : textSecondary)
                    Text("\(formatMoney(balance)) \(baseCurrency)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(textPrimary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? theme.currentAccent.primary.opacity(0.14) : (isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF8FAFC)))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? theme.currentAccent.primary : (isDark ? Color(hex: 0x2A3245) : Color(hex: 0xE2E8F0)), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func calculateWalletBalance(_ walletId: String) -> Double {
        let inc = allTransactions.filter { $0.walletId == walletId && $0.type == "income" }.reduce(0) { $0 + $1.effectiveOriginalAmount }
        let exp = allTransactions.filter { $0.walletId == walletId && $0.type == "expense" }.reduce(0) { $0 + $1.effectiveOriginalAmount }
        return inc - exp
    }

    // MARK: - Recent Transactions Preview Section
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Последние операции")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(textPrimary)
                Spacer()
                Button("Все") {
                    MiodiHapticFeedback.lightClick()
                    selectedTab = 1
                }
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(theme.currentAccent.primary)
            }

            if filteredTransactions.isEmpty {
                VStack(spacing: 8) {
                    Text("Нет операций за этот период")
                        .font(.system(size: 13))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredTransactions.prefix(5)) { item in
                        transactionRow(item)
                    }
                }
            }
        }
    }

    // MARK: - 5. History Tab Content (Full List with Swipes)
    private var historyTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 38))
                            .foregroundStyle(theme.currentAccent.primary.opacity(0.6))
                        Text("Нет операций")
                            .font(.headline)
                            .foregroundStyle(textSecondary)
                    }
                    .padding(.top, 80)
                } else {
                    // Grouped by date
                    let grouped = Dictionary(grouping: filteredTransactions) { $0.date }
                    let sortedDates = grouped.keys.sorted(by: >)

                    ForEach(sortedDates, id: \.self) { dateStr in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(formatGroupHeader(dateStr))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(textSecondary)
                                .padding(.horizontal, 4)
                                .padding(.top, 6)

                            ForEach(grouped[dateStr] ?? []) { item in
                                transactionRow(item)
                            }
                        }
                    }
                }
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Transaction Row with Full Swipes (Delete, Edit, Duplicate)
    private func transactionRow(_ item: FinanceItem) -> some View {
        let cat = FinanceCategory.resolveCategory(idOrName: item.category)
        let isIncome = item.type == "income"
        let isTransfer = item.type == "transfer"

        return HStack(spacing: 12) {
            // Category Icon Badge
            Text(cat.emoji)
                .font(.system(size: 17))
                .frame(width: 38, height: 38)
                .background(cat.color.opacity(0.18))
                .clipShape(Circle())

            // Category & Note
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(cat.name)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(textPrimary)

                    if isTransfer {
                        Text("⇄ Обмен")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: 0x6366F1))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: 0x6366F1).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11.5))
                        .foregroundStyle(textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 1) {
                let prefix = isIncome ? "+" : (isTransfer ? "⇄" : "-")
                let amountColor: Color = isIncome ? Color(hex: 0x10B981) : (isTransfer ? Color(hex: 0x6366F1) : textPrimary)

                Text("\(prefix)\(formatMoney(item.effectiveOriginalAmount)) \(item.currency.isEmpty ? baseCurrency : item.currency)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(amountColor)

                // If foreign currency, show base amount
                if !item.currency.isEmpty && item.currency != baseCurrency {
                    Text("≈ \(formatMoney(item.amount)) \(baseCurrency)")
                        .font(.system(size: 10))
                        .foregroundStyle(textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.03), radius: 4, x: 0, y: 1)
        // Trailing Swipes: Delete (Red) & Edit (Magenta)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteTransaction(item)
            } label: {
                Label("Удалить", systemImage: "trash.fill")
            }

            Button {
                editTransaction(item)
            } label: {
                Label("Изменить", systemImage: "pencil")
            }
            .tint(theme.currentAccent.primary)
        }
        // Leading Swipe: Duplicate (Blue)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                duplicateTransaction(item)
            } label: {
                Label("Копия", systemImage: "doc.on.doc.fill")
            }
            .tint(Color(hex: 0x3B82F6))
        }
        .contextMenu {
            Button {
                editTransaction(item)
            } label: {
                Label("Изменить", systemImage: "pencil")
            }

            Button {
                duplicateTransaction(item)
            } label: {
                Label("Дублировать", systemImage: "doc.on.doc")
            }

            Button(role: .destructive) {
                deleteTransaction(item)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    // MARK: - 6. Bottom Floating Action Buttons
    private var bottomFabsRow: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                // (+) Add Income FAB
                Button {
                    MiodiHapticFeedback.lightClick()
                    entryModalIsIncome = true
                    editingTransaction = nil
                    isAddingEntry = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0x10B981))
                            .frame(width: 52, height: 52)
                            .shadow(color: Color(hex: 0x10B981).opacity(0.35), radius: 6, x: 0, y: 3)

                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }

                // (⇄) Transfer / Currency Exchange FAB
                Button {
                    MiodiHapticFeedback.lightClick()
                    isTransferModalOpen = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0x6366F1))
                            .frame(width: 44, height: 44)
                            .shadow(color: Color(hex: 0x6366F1).opacity(0.35), radius: 5, x: 0, y: 2)

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }

                // (–) Add Expense FAB
                Button {
                    MiodiHapticFeedback.lightClick()
                    entryModalIsIncome = false
                    editingTransaction = nil
                    isAddingEntry = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xEF4444))
                            .frame(width: 52, height: 52)
                            .shadow(color: Color(hex: 0xEF4444).opacity(0.35), radius: 6, x: 0, y: 3)

                        Image(systemName: "minus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .padding(.bottom, 96)
        }
    }

    // MARK: - Transaction Actions
    private func deleteTransaction(_ item: FinanceItem) {
        MiodiHapticFeedback.warning()
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    private func editTransaction(_ item: FinanceItem) {
        MiodiHapticFeedback.lightClick()
        editingTransaction = item
        entryModalIsIncome = item.type == "income"
        isAddingEntry = true
    }

    private func duplicateTransaction(_ item: FinanceItem) {
        MiodiHapticFeedback.success()
        let copy = FinanceItem(
            type: item.type,
            amount: item.amount,
            category: item.category,
            date: Date().yyyyMMddString,
            note: item.note,
            currency: item.currency,
            originalAmount: item.originalAmount,
            exchangeRate: item.exchangeRate,
            toCurrency: item.toCurrency,
            toAmount: item.toAmount,
            walletId: item.walletId,
            toWalletId: item.toWalletId
        )
        modelContext.insert(copy)
        try? modelContext.save()
    }

    private func formatMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func formatGroupHeader(_ dateStr: String) -> String {
        let today = Date().yyyyMMddString
        if dateStr == today {
            return "Сегодня"
        }
        let yesterday = Date().adding(days: -1).yyyyMMddString
        if dateStr == yesterday {
            return "Вчера"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = formatter.date(from: dateStr) {
            let out = DateFormatter()
            out.locale = Locale(identifier: "ru_RU")
            out.dateFormat = "d MMMM, EEE"
            return out.string(from: d)
        }
        return dateStr
    }
}
