//
//  FinanceDonutChartView.swift
//  Plan4U_iOS
//
//  Interactive Donut / Pie Chart for Finance Expenses.
//  Matching Android FinanceDonutChart.kt with center hole, category badges, tap focus,
//  and empty dial state with radial tick marks.
//

import SwiftUI
import Charts

public struct FinanceDonutChartView: View {
    public let items: [CategoryBreakdownItem]
    public let totalExpense: Double
    public let focusedCategoryId: String?
    public let currencySymbol: String
    public let isDarkTheme: Bool
    public let onCategoryClick: (String?) -> Void

    @State private var selectedAngle: Double? = nil

    public init(
        items: [CategoryBreakdownItem],
        totalExpense: Double,
        focusedCategoryId: String? = nil,
        currencySymbol: String = "₽",
        isDarkTheme: Bool = false,
        onCategoryClick: @escaping (String?) -> Void
    ) {
        self.items = items
        self.totalExpense = totalExpense
        self.focusedCategoryId = focusedCategoryId
        self.currencySymbol = currencySymbol
        self.isDarkTheme = isDarkTheme
        self.onCategoryClick = onCategoryClick
    }

    private var textPrimary: Color {
        isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x0F172A)
    }

    private var textSecondary: Color {
        isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B)
    }

    private var activeFocusedItem: CategoryBreakdownItem? {
        items.first { $0.categoryId == focusedCategoryId }
    }

    public var body: some View {
        ZStack {
            if items.isEmpty || totalExpense <= 0 {
                // Empty State: 40 radial ticks matching Android EmptyFinanceDial
                emptyDialView
            } else {
                // Interactive Donut Chart using SwiftUI Charts SectorMark
                ZStack {
                    Chart(items) { item in
                        let isSelected = (item.categoryId == focusedCategoryId)
                        SectorMark(
                            angle: .value("Сумма", item.amount),
                            innerRadius: .ratio(0.68),
                            outerRadius: isSelected ? .ratio(1.0) : .ratio(0.93),
                            angularInset: items.count > 1 ? 2.0 : 0.0
                        )
                        .cornerRadius(4)
                        .foregroundStyle(item.color)
                        .opacity(focusedCategoryId == nil || isSelected ? 1.0 : 0.45)
                    }
                    .chartLegend(.hidden)
                    .chartBackground { _ in
                        // Center Hole Information
                        centerHoleContent
                    }
                    .chartAngleSelection(value: $selectedAngle)
                    .onChange(of: selectedAngle) { _, newAngle in
                        if let newAngle, let matched = findItem(for: newAngle) {
                            MiodiHapticFeedback.selection()
                            onCategoryClick(matched.categoryId)
                        }
                    }

                    // Surrounding Category Icons & Badges
                    GeometryReader { geo in
                        let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
                        let radius = min(geo.size.width, geo.size.height) / 2.0 * 0.81

                        // Render top items badges if reasonable count
                        ForEach(items.prefix(6)) { item in
                            let isSelected = item.categoryId == focusedCategoryId
                            let midAngle = calculateMidAngle(for: item)
                            let x = center.x + radius * CGFloat(cos(midAngle))
                            let y = center.y + radius * CGFloat(sin(midAngle))

                            Button {
                                MiodiHapticFeedback.lightClick()
                                if focusedCategoryId == item.categoryId {
                                    onCategoryClick(nil)
                                } else {
                                    onCategoryClick(item.categoryId)
                                }
                            } label: {
                                Text(item.emoji)
                                    .font(.system(size: isSelected ? 18 : 14))
                                    .frame(width: isSelected ? 34 : 26, height: isSelected ? 34 : 26)
                                    .background(isDarkTheme ? Color(hex: 0x1E2433) : Color.white)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(item.color, lineWidth: isSelected ? 2.5 : 1.2)
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                                    .scaleEffect(isSelected ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                            }
                            .position(x: x, y: y)
                        }
                    }
                }
            }
        }
        .frame(width: 270, height: 270)
    }

    // MARK: - Center Hole
    private var centerHoleContent: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            onCategoryClick(nil)
        } label: {
            VStack(spacing: 2) {
                if let focused = activeFocusedItem {
                    Text(focused.emoji + " " + focused.name.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(focused.color)
                        .lineLimit(1)
                        .padding(.horizontal, 10)

                    Text(formatMoney(focused.amount))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .lineLimit(1)

                    Text("\(Int(focused.percent))% · \(currencySymbol)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(textSecondary)
                } else {
                    Text("РАСХОД")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(textSecondary)
                        .lineLimit(1)

                    Text(formatMoney(totalExpense))
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .lineLimit(1)

                    Text(currencySymbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textSecondary)
                }
            }
            .frame(width: 150, height: 150)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty Dial View (Matching Android EmptyFinanceDial)
    private var emptyDialView: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
                let radius = min(size.width, size.height) / 2.0 - 12
                let tickCount = 40

                for i in 0..<tickCount {
                    let angle = (Double(i) / Double(tickCount)) * 2.0 * .pi - (.pi / 2.0)
                    let isMajor = (i % 5 == 0)
                    let tickLen: CGFloat = isMajor ? 12 : 7
                    let inner = radius - tickLen

                    let x1 = center.x + CGFloat(cos(angle)) * inner
                    let y1 = center.y + CGFloat(sin(angle)) * inner
                    let x2 = center.x + CGFloat(cos(angle)) * radius
                    let y2 = center.y + CGFloat(sin(angle)) * radius

                    var path = Path()
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))

                    let color = isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1)
                    context.stroke(path, with: .color(color.opacity(isMajor ? 0.8 : 0.45)), lineWidth: isMajor ? 2.0 : 1.2)
                }
            }

            VStack(spacing: 3) {
                Text("РАСХОД")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(textSecondary)
                Text("0")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(textPrimary.opacity(0.4))
                Text(currencySymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(textSecondary)
            }
        }
    }

    private func calculateMidAngle(for target: CategoryBreakdownItem) -> Double {
        var start: Double = -Double.pi / 2.0
        for item in items {
            let sweep = (item.amount / totalExpense) * 2.0 * .pi
            if item.categoryId == target.categoryId {
                return start + (sweep / 2.0)
            }
            start += sweep
        }
        return -Double.pi / 2.0
    }

    private func findItem(for angle: Double) -> CategoryBreakdownItem? {
        var accumulated: Double = 0.0
        for item in items {
            accumulated += item.amount
            if angle <= accumulated {
                return item
            }
        }
        return items.last
    }

    private func formatMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}
