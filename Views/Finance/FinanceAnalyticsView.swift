//
//  FinanceAnalyticsView.swift
//  Plan4U_iOS
//
//  Detailed Month & Period Financial Analytics:
//  Donut distribution chart, Top Categories ranking, Average daily spend,
//  Income vs Expense breakdown, and Zero-Spend Days counter.
//

import SwiftUI
import SwiftData
import Charts

public struct FinanceAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public let transactions: [FinanceItem]
    public let currencySymbol: String
    @Binding public var selectedPeriod: FinancePeriod
    @Binding public var currentDate: Date
    public let onAddExpense: () -> Void
    public let onClaimZeroSpend: () -> Void

    @State private var focusedCategoryId: String? = nil

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

    // Filtered transactions for the selected period
    private var periodTransactions: [FinanceItem] {
        let (startDate, endDate) = selectedPeriod.dateRange(for: currentDate)
        guard let start = startDate, let end = endDate else {
            return transactions
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)
        return transactions.filter { $0.date >= startStr && $0.date <= endStr }
    }

    private var expenses: [FinanceItem] {
        periodTransactions.filter { $0.type == "expense" }
    }

    private var incomes: [FinanceItem] {
        periodTransactions.filter { $0.type == "income" }
    }

    private var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }

    private var netBalance: Double {
        totalIncome - totalExpense
    }

    // Days elapsed in current period for daily average
    private var daysInPeriod: Int {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            return 1
        case .week:
            return 7
        case .month:
            let range = calendar.range(of: .day, in: .month, for: currentDate)
            let totalDaysInMonth = range?.count ?? 30
            if calendar.isDate(currentDate, equalTo: Date(), toGranularity: .month) {
                let day = calendar.component(.day, from: Date())
                return max(day, 1)
            }
            return totalDaysInMonth
        case .year:
            return 365
        case .all:
            return max(Set(expenses.map { $0.date }).count, 1)
        }
    }

    private var averageDailySpend: Double {
        let days = max(daysInPeriod, 1)
        return totalExpense / Double(days)
    }

    // Category Breakdown Items
    private var categoryBreakdown: [CategoryBreakdownItem] {
        if totalExpense <= 0 { return [] }
        var grouped: [String: (amount: Double, count: Int)] = [:]
        for item in expenses {
            let catKey = item.category.isEmpty ? "Продукты" : item.category
            let current = grouped[catKey] ?? (0.0, 0)
            grouped[catKey] = (current.amount + item.amount, current.count + 1)
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

    // Zero-spend days count for current month / period
    private var noSpendCountInPeriod: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthPrefix = formatter.string(from: currentDate)
        return NoSpendManager.shared.noSpendCount(forMonthPrefix: monthPrefix)
    }

    public init(
        transactions: [FinanceItem],
        currencySymbol: String = "₽",
        selectedPeriod: Binding<FinancePeriod>,
        currentDate: Binding<Date>,
        onAddExpense: @escaping () -> Void,
        onClaimZeroSpend: @escaping () -> Void
    ) {
        self.transactions = transactions
        self.currencySymbol = currencySymbol
        self._selectedPeriod = selectedPeriod
        self._currentDate = currentDate
        self.onAddExpense = onAddExpense
        self.onClaimZeroSpend = onClaimZeroSpend
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period Navigation Header
                periodNavigator

                // Top KPI Metrics (4 cards grid)
                metricsGrid

                // Donut Chart Card
                donutSectionCard

                // Income vs Expense Comparison Bar
                incomeExpenseComparisonCard

                // Zero-Spend Days Achievement Card
                zeroSpendAchievementCard

                // Top Categories List
                topCategoriesSection

                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    // MARK: - 1. Period Navigator
    private var periodNavigator: some View {
        HStack {
            Button {
                MiodiHapticFeedback.selection()
                currentDate = selectedPeriod.shift(date: currentDate, forward: false)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(textSecondary)
                    .frame(width: 32, height: 32)
                    .background(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedPeriod.displaySubtitle(for: currentDate))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(textPrimary)

                Text(selectedPeriod.rawValue.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(theme.currentAccent.primary)
            }

            Spacer()

            Button {
                MiodiHapticFeedback.selection()
                currentDate = selectedPeriod.shift(date: currentDate, forward: true)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(textSecondary)
                    .frame(width: 32, height: 32)
                    .background(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - 2. KPI Metrics 2x2 Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            // Card 1: Total Expense
            metricTile(
                title: "Расходы",
                value: "-\(formatMoney(totalExpense)) \(currencySymbol)",
                icon: "arrow.down.right",
                iconColor: Color(hex: 0xEF4444),
                subtext: "\(expenses.count) операций"
            )

            // Card 2: Average Daily Spend
            metricTile(
                title: "Средний чек / день",
                value: "\(formatMoney(averageDailySpend)) \(currencySymbol)",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Color(hex: 0x3B82F6),
                subtext: "за \(daysInPeriod) дн."
            )

            // Card 3: Net Balance
            metricTile(
                title: "Баланс за период",
                value: "\(netBalance >= 0 ? "+" : "")\(formatMoney(netBalance)) \(currencySymbol)",
                icon: "scalemass.fill",
                iconColor: netBalance >= 0 ? Color(hex: 0x10B981) : Color(hex: 0xEF4444),
                subtext: netBalance >= 0 ? "Профицит ✨" : "Дефицит"
            )

            // Card 4: Zero-Spend Days
            metricTile(
                title: "Дней без трат",
                value: "\(noSpendCountInPeriod) 🏆",
                icon: "trophy.fill",
                iconColor: Color(hex: 0xF59E0B),
                subtext: "+ \(noSpendCountInPeriod * 2) 🐾 получено"
            )
        }
    }

    private func metricTile(
        title: String,
        value: String,
        icon: String,
        iconColor: Color,
        subtext: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(textSecondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtext)
                .font(.system(size: 10.5))
                .foregroundStyle(textSecondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.03), radius: 5, x: 0, y: 2)
    }

    // MARK: - 3. Donut Section Card
    private var donutSectionCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Распределение трат")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(textPrimary)
                Spacer()
                if focusedCategoryId != nil {
                    Button("Сброс") {
                        MiodiHapticFeedback.lightClick()
                        focusedCategoryId = nil
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.currentAccent.primary)
                }
            }

            FinanceDonutChartView(
                items: categoryBreakdown,
                totalExpense: totalExpense,
                focusedCategoryId: focusedCategoryId,
                currencySymbol: currencySymbol,
                isDarkTheme: isDark
            ) { newFocus in
                focusedCategoryId = newFocus
            }
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - 4. Income vs Expense Comparison
    private var incomeExpenseComparisonCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Доходы и Расходы")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(textPrimary)
                Spacer()
            }

            // Ratio Bar
            let totalFlow = totalIncome + totalExpense
            let incRatio = totalFlow > 0 ? (totalIncome / totalFlow) : 0.5

            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: 0x10B981))
                        .frame(width: max(geo.size.width * CGFloat(incRatio) - 1.5, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: 0xEF4444))
                        .frame(width: max(geo.size.width * CGFloat(1.0 - incRatio) - 1.5, 4))
                }
            }
            .frame(height: 8)

            HStack {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: 0x10B981)).frame(width: 8, height: 8)
                    Text("Доход: +\(formatMoney(totalIncome)) \(currencySymbol)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x10B981))
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: 0xEF4444)).frame(width: 8, height: 8)
                    Text("Расход: -\(formatMoney(totalExpense)) \(currencySymbol)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xEF4444))
                }
            }
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - 5. Zero-Spend Day Achievement Card
    private var zeroSpendAchievementCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xF59E0B).opacity(0.18))
                    .frame(width: 46, height: 46)
                Text("🏆")
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Дни осознанной экономии")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(textPrimary)
                Text("В этом месяце: \(noSpendCountInPeriod) \(declinedDays(noSpendCountInPeriod)) без трат")
                    .font(.system(size: 12))
                    .foregroundStyle(textSecondary)
            }

            Spacer()

            Button {
                MiodiHapticFeedback.success()
                onClaimZeroSpend()
            } label: {
                Text("Зафиксировать")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Color(hex: 0xB45309))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0xFEF3C7))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(isDark ? Color(hex: 0x241C10) : Color(hex: 0xFFFBEB))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xF59E0B).opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - 6. Top Categories List
    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Топ категорий трат")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(textPrimary)
                Spacer()
                Text("\(categoryBreakdown.count) категорий")
                    .font(.system(size: 12))
                    .foregroundStyle(textSecondary)
            }

            if categoryBreakdown.isEmpty {
                VStack(spacing: 8) {
                    Text("За выбранный период нет расходов")
                        .font(.system(size: 13))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(categoryBreakdown) { item in
                        let isSelected = (item.categoryId == focusedCategoryId)
                        Button {
                            MiodiHapticFeedback.lightClick()
                            if focusedCategoryId == item.categoryId {
                                focusedCategoryId = nil
                            } else {
                                focusedCategoryId = item.categoryId
                            }
                        } label: {
                            VStack(spacing: 6) {
                                HStack(spacing: 10) {
                                    Text(item.emoji)
                                        .font(.system(size: 17))
                                        .frame(width: 34, height: 34)
                                        .background(item.color.opacity(0.18))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(textPrimary)
                                        Text("\(item.transactionCount) операций · \(Int(item.percent))%")
                                            .font(.system(size: 11))
                                            .foregroundStyle(textSecondary)
                                    }

                                    Spacer()

                                    Text("-\(formatMoney(item.amount)) \(currencySymbol)")
                                        .font(.system(size: 14.5, weight: .bold))
                                        .foregroundStyle(textPrimary)
                                }

                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(isDark ? Color(hex: 0x242A38) : Color(hex: 0xF1F5F9))
                                            .frame(height: 5)
                                        Capsule()
                                            .fill(item.color)
                                            .frame(width: geo.size.width * CGFloat(item.percent / 100.0), height: 5)
                                    }
                                }
                                .frame(height: 5)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? item.color.opacity(isDark ? 0.25 : 0.1) : cardBg)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isSelected ? item.color : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.04), radius: 8, x: 0, y: 3)
    }

    private func formatMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func declinedDays(_ count: Int) -> String {
        let rem10 = count % 10
        let rem100 = count % 100
        if rem100 >= 11 && rem100 <= 19 { return "дней" }
        if rem10 == 1 { return "день" }
        if rem10 >= 2 && rem10 <= 4 { return "дня" }
        return "дней"
    }
}
