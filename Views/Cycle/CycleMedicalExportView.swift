//
//  CycleMedicalExportView.swift
//  Plan4U_iOS
//
//  Clinical / Gynecologist Cycle Export Report Generator
//  Interactive Preview, PDF Generation via UIGraphicsPDFRenderer & Structured Messenger Export
//

import SwiftUI
import SwiftData
import PDFKit

public enum ExportPeriodRange: String, CaseIterable, Identifiable, Sendable {
    case threeMonths = "3 месяца"
    case sixMonths = "6 месяцев"
    case oneYear = "1 год"
    case allTime = "Всё время"

    public var id: String { rawValue }

    public var daysLimit: Int? {
        switch self {
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .allTime: return nil
        }
    }
}

public struct CycleMedicalExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \CycleItem.startDate, order: .reverse) private var allCycles: [CycleItem]

    @State private var selectedRange: ExportPeriodRange = .sixMonths
    @State private var generatedPdfUrl: URL? = nil
    @State private var isGeneratingPdf: Bool = false
    @State private var showCopiedToast: Bool = false

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init() {}

    private var filteredCycles: [CycleItem] {
        let todayStr = CycleEngine.getTodayString()
        guard let limit = selectedRange.daysLimit else { return allCycles }
        return allCycles.filter { item in
            CycleEngine.diffInDays(start: item.startDate, end: todayStr) <= limit
        }
    }

    private var reportSummary: ClinicalCycleSummary {
        ClinicalCycleSummary.calculate(from: filteredCycles)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x0F172A) : Color(hex: 0xF8FAFC))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // Period Selector
                        periodSelectorSection

                        // Clinical Summary Cards
                        clinicalSummaryCardsSection

                        // Export Action Buttons (PDF & Structured Text)
                        exportActionsSection

                        // Cycle History Table Preview
                        historyTablePreviewSection

                        // Symptoms Log Preview
                        symptomsLogPreviewSection

                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Отчёт для врача-гинеколога")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                if let pdfUrl = generatedPdfUrl {
                    ToolbarItem(placement: .confirmationAction) {
                        ShareLink(item: pdfUrl) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Поделиться PDF")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: 0xFB7185))
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: 0x34D399))
                        Text("Текст отчёта скопирован в буфер")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0x1E293B))
                    .clipShape(Capsule())
                    .shadow(radius: 8)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                generatePdfInBackground()
            }
            .onChange(of: selectedRange) { _, _ in
                generatePdfInBackground()
            }
        }
    }

    // MARK: - Period Selector
    private var periodSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Период выборки:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Picker("Период", selection: $selectedRange) {
                ForEach(ExportPeriodRange.allCases) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(cardBackground)
    }

    // MARK: - Clinical Summary Cards
    private var clinicalSummaryCardsSection: some View {
        let s = reportSummary

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🩺")
                Text("Клинические показатели")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
                Text("\(filteredCycles.count) циклов")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xFB7185))
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                summaryMetric(
                    label: "Средний цикл",
                    value: s.averageCycleLength > 0 ? "\(s.averageCycleLength) дн." : "—",
                    sub: "Разброс: \(s.minCycleLength)–\(s.maxCycleLength) дн."
                )

                summaryMetric(
                    label: "Менструация",
                    value: s.averagePeriodLength > 0 ? "\(s.averagePeriodLength) дн." : "—",
                    sub: "Норма: 3–7 дней"
                )

                summaryMetric(
                    label: "Регулярность",
                    value: s.variabilityText,
                    sub: s.isIrregular ? "Вариабельный" : "Стабильный ритм",
                    isWarning: s.isIrregular
                )

                summaryMetric(
                    label: "Сбои / Выбросы",
                    value: "\(s.outlierCount)",
                    sub: s.outlierCount > 0 ? "Исключены из прогноза" : "Сбоев не зафиксировано"
                )
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func summaryMetric(label: String, value: String, sub: String, isWarning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isWarning ? Color(hex: 0xF59E0B) : (isDark ? .white : Color(hex: 0x0F172A)))

            Text(sub)
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.8))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(isDark ? Color(hex: 0x141B2D) : Color(hex: 0xF1F5F9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Export Actions
    private var exportActionsSection: some View {
        HStack(spacing: 12) {
            // Share PDF Button
            if let pdfUrl = generatedPdfUrl {
                ShareLink(item: pdfUrl) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                        Text("Экспорт PDF")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: 0xFB7185))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                Button {} label: {
                    HStack(spacing: 6) {
                        ProgressView().tint(.white)
                        Text("Подготовка PDF...")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: 0xFB7185).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(true)
            }

            // Copy structured text
            Button {
                copyStructuredReport()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Копировать")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - History Table Preview
    private var historyTablePreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("📋")
                Text("Таблица менструальных циклов")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
            }

            if filteredCycles.isEmpty {
                Text("Нет данных за выбранный период.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(filteredCycles.enumerated()), id: \.element.id) { idx, cycle in
                        let nextCycle = filteredCycles.indices.contains(idx - 1) ? filteredCycles[idx - 1] : nil
                        let cycleLen = nextCycle.map { CycleEngine.diffInDays(start: cycle.startDate, end: $0.startDate) }
                        let periodLen = cycle.endDate.map { CycleEngine.diffInDays(start: cycle.startDate, end: $0) + 1 }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(CycleEngine.formatShortRange(startStr: cycle.startDate, endStr: cycle.endDate))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))

                                if let n = cycle.note, !n.isEmpty {
                                    Text(n)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                if let cLen = cycleLen {
                                    Text("Цикл: \(cLen) дн.")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: 0xFB7185))
                                } else {
                                    Text("Текущий")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color(hex: 0x34D399))
                                }

                                if let pLen = periodLen {
                                    Text("Менстр: \(pLen) дн.")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(isDark ? Color(hex: 0x141B2D) : Color(hex: 0xF8FAFC))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Symptoms Log Preview
    private var symptomsLogPreviewSection: some View {
        let symptoms = CycleSettingsStore.shared.getAllSymptomsSorted()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🌸")
                Text("Журнал зафиксированных симптомов")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                Spacer()
                Text("\(symptoms.count) отм.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if symptoms.isEmpty {
                Text("Симптомы пока не вносились.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(symptoms.prefix(10)) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Text(item.date)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: 0xFB7185))
                                .frame(width: 80, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                if item.flow != .none {
                                    Text("Выделения: \(item.flow.titleRu)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(item.flow.color)
                                }

                                if !item.symptoms.isEmpty {
                                    Text("Симптомы: " + item.symptoms.joined(separator: ", "))
                                        .font(.system(size: 11))
                                        .foregroundStyle(isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569))
                                }

                                if !item.moods.isEmpty {
                                    Text("Настроение: " + item.moods.joined(separator: ", "))
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                if !item.note.isEmpty {
                                    Text(item.note)
                                        .font(.system(size: 11, weight: .light))
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(8)
                        .background(isDark ? Color(hex: 0x141B2D) : Color(hex: 0xF8FAFC))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isDark ? Color(hex: 0x2A3347) : Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 6, y: 2)
    }

    // MARK: - PDF Generation Logic
    private func generatePdfInBackground() {
        isGeneratingPdf = true
        let cycles = filteredCycles
        let summary = reportSummary
        let symptoms = CycleSettingsStore.shared.getAllSymptomsSorted()

        DispatchQueue.global(qos: .userInitiated).async {
            let url = MedicalPdfRenderer.renderReport(
                cycles: cycles,
                summary: summary,
                symptoms: symptoms,
                periodTitle: selectedRange.rawValue
            )
            DispatchQueue.main.async {
                self.generatedPdfUrl = url
                self.isGeneratingPdf = false
            }
        }
    }

    // MARK: - Structured Text Report
    private func copyStructuredReport() {
        let s = reportSummary
        let today = CycleEngine.getTodayString()

        var text = """
        🏥 МЕДИЦИНСКАЯ ВЫПИСКА О МЕНСТРУАЛЬНОМ ЦИКЛЕ (Miodi)
        Дата формирования: \(today)
        Период отчёта: \(selectedRange.rawValue)
        Всего записей циклов: \(filteredCycles.count)

        📊 ОСНОВНЫЕ ПОКАЗАТЕЛИ:
        • Средняя длительность цикла: \(s.averageCycleLength > 0 ? "\(s.averageCycleLength) дн." : "—")
        • Разброс длины цикла: \(s.minCycleLength)–\(s.maxCycleLength) дн. (размах \(s.variabilityDays) дн.)
        • Регулярность: \(s.variabilityText)
        • Средняя длительность менструации: \(s.averagePeriodLength > 0 ? "\(s.averagePeriodLength) дн." : "—")
        • Зафиксировано сбоев (выбросов): \(s.outlierCount)

        🗓 ИСТОРИЯ ЦИКЛОВ:
        """

        for (idx, cycle) in filteredCycles.enumerated() {
            let nextCycle = filteredCycles.indices.contains(idx - 1) ? filteredCycles[idx - 1] : nil
            let cycleLen = nextCycle.map { "\(CycleEngine.diffInDays(start: cycle.startDate, end: $0.startDate)) дн." } ?? "текущий"
            let periodLen = cycle.endDate.map { "\(CycleEngine.diffInDays(start: cycle.startDate, end: $0) + 1) дн." } ?? "идёт сейчас"
            let noteStr = cycle.note.map { " (\($0))" } ?? ""
            text += "\n\(idx + 1). \(cycle.startDate) — \(cycle.endDate ?? "...") | Менстр: \(periodLen) | Цикл: \(cycleLen)\(noteStr)"
        }

        let symptoms = CycleSettingsStore.shared.getAllSymptomsSorted()
        if !symptoms.isEmpty {
            text += "\n\n🌸 ЗАФИКСИРОВАННЫЕ СИМПТОМЫ:"
            for sym in symptoms.prefix(15) {
                text += "\n• [\(sym.date)] \(sym.summaryDescription)"
            }
        }

        text += "\n\n(Сформировано автоматически в приложении Miodi)"

        UIPasteboard.general.string = text
        MiodiHapticFeedback.success()
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
}

// MARK: - Clinical Summary Model
public struct ClinicalCycleSummary: Sendable {
    public let totalCycles: Int
    public let averageCycleLength: Int
    public let minCycleLength: Int
    public let maxCycleLength: Int
    public let variabilityDays: Int
    public let variabilityText: String
    public let isIrregular: Bool
    public let averagePeriodLength: Int
    public let outlierCount: Int

    public static func calculate(from cycles: [CycleItem]) -> ClinicalCycleSummary {
        guard !cycles.isEmpty else {
            return ClinicalCycleSummary(
                totalCycles: 0,
                averageCycleLength: 28,
                minCycleLength: 28,
                maxCycleLength: 28,
                variabilityDays: 0,
                variabilityText: "Нет данных",
                isIrregular: false,
                averagePeriodLength: 5,
                outlierCount: 0
            )
        }

        var cycleLengths: [Int] = []
        var periodLengths: [Int] = []
        var outliers = 0

        for i in 0..<(cycles.count - 1) {
            let cur = cycles[i]
            let next = cycles[i + 1]
            let len = abs(CycleEngine.diffInDays(start: cur.startDate, end: next.startDate))
            if (15...90).contains(len) {
                if cur.isOutlier {
                    outliers += 1
                } else {
                    cycleLengths.append(len)
                }
            }
        }

        for c in cycles {
            if let end = c.endDate {
                let pLen = CycleEngine.diffInDays(start: c.startDate, end: end) + 1
                if (1...14).contains(pLen) {
                    periodLengths.append(pLen)
                }
            }
        }

        let avgCycle = cycleLengths.isEmpty ? 28 : Int(round(Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)))
        let minCycle = cycleLengths.min() ?? 28
        let maxCycle = cycleLengths.max() ?? 28
        let variability = maxCycle - minCycle
        let isIrreg = cycleLengths.count >= 2 && variability >= 7
        let varText = isIrreg ? "Вариабельный (±\(variability) дн.)" : "Регулярный (±\(variability) дн.)"
        let avgPeriod = periodLengths.isEmpty ? 5 : Int(round(Double(periodLengths.reduce(0, +)) / Double(periodLengths.count)))

        return ClinicalCycleSummary(
            totalCycles: cycles.count,
            averageCycleLength: avgCycle,
            minCycleLength: minCycle,
            maxCycleLength: maxCycle,
            variabilityDays: variability,
            variabilityText: varText,
            isIrregular: isIrreg,
            averagePeriodLength: avgPeriod,
            outlierCount: outliers
        )
    }
}

// MARK: - Clinical PDF Document Renderer
public enum MedicalPdfRenderer {
    public static func renderReport(
        cycles: [CycleItem],
        summary: ClinicalCycleSummary,
        symptoms: [DailySymptomRecord],
        periodTitle: String
    ) -> URL {
        let pageWidth: CGFloat = 595.2 // A4 Standard
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Miodi_Cycle_Report.pdf")

        try? renderer.writePDF(to: tempUrl) { context in
            context.beginPage()

            let margin: CGFloat = 40
            var currentY: CGFloat = margin

            // 1. Header Banner
            let headerFont = UIFont.systemFont(ofSize: 18, weight: .bold)
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor(red: 0.98, green: 0.44, blue: 0.52, alpha: 1.0) // Magenta / coral
            ]
            let headerText = "MIODI HEALTH • МЕДИЦИНСКИЙ ОТЧЁТ О ЦИКЛЕ"
            headerText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttrs)
            currentY += 26

            // Subtitle & Date
            let subFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: subFont,
                .foregroundColor: UIColor.darkGray
            ]
            let todayStr = CycleEngine.getTodayString()
            let subText = "Период: \(periodTitle)  |  Дата экспорта: \(todayStr)  |  Сформировано для врача-гинеколога"
            subText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: subAttrs)
            currentY += 20

            // Horizontal Divider
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: currentY))
            path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
            UIColor.lightGray.withAlphaComponent(0.6).setStroke()
            path.lineWidth = 1
            path.stroke()
            currentY += 16

            // 2. Summary Box
            let boxRect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: 75)
            let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
            UIColor(red: 0.98, green: 0.95, blue: 0.97, alpha: 1.0).setFill()
            boxPath.fill()
            UIColor(red: 0.98, green: 0.44, blue: 0.52, alpha: 0.3).setStroke()
            boxPath.lineWidth = 1
            boxPath.stroke()

            let summaryAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.black
            ]

            let col1 = "• Средняя длина цикла: \(summary.averageCycleLength) дн.\n• Разброс: \(summary.minCycleLength)–\(summary.maxCycleLength) дн.\n• Регулярность: \(summary.variabilityText)"
            let col2 = "• Средняя менструация: \(summary.averagePeriodLength) дн.\n• Всего циклов: \(summary.totalCycles)\n• Зафиксировано сбоев: \(summary.outlierCount)"

            col1.draw(in: CGRect(x: margin + 14, y: currentY + 12, width: 230, height: 55), withAttributes: summaryAttrs)
            col2.draw(in: CGRect(x: margin + 260, y: currentY + 12, width: 230, height: 55), withAttributes: summaryAttrs)
            currentY += 92

            // 3. Section Title: Таблица циклов
            let tableHeaderFont = UIFont.systemFont(ofSize: 13, weight: .bold)
            let tableHeaderAttrs: [NSAttributedString.Key: Any] = [
                .font: tableHeaderFont,
                .foregroundColor: UIColor.black
            ]
            "ИСТОРИЯ МЕНСТРУАЛЬНЫХ ЦИКЛОВ:".draw(at: CGPoint(x: margin, y: currentY), withAttributes: tableHeaderAttrs)
            currentY += 18

            // Table Columns Header
            let thAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor.gray
            ]
            "Даты начала / окончания".draw(at: CGPoint(x: margin, y: currentY), withAttributes: thAttrs)
            "Длит. менстр.".draw(at: CGPoint(x: margin + 180, y: currentY), withAttributes: thAttrs)
            "Длина цикла".draw(at: CGPoint(x: margin + 280, y: currentY), withAttributes: thAttrs)
            "Примечания / Симптомы".draw(at: CGPoint(x: margin + 380, y: currentY), withAttributes: thAttrs)
            currentY += 14

            let rowFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: rowFont,
                .foregroundColor: UIColor.black
            ]

            for (idx, cycle) in cycles.prefix(12).enumerated() {
                let nextCycle = cycles.indices.contains(idx - 1) ? cycles[idx - 1] : nil
                let cycleLen = nextCycle.map { "\(CycleEngine.diffInDays(start: cycle.startDate, end: $0.startDate)) дн." } ?? "—"
                let periodLen = cycle.endDate.map { "\(CycleEngine.diffInDays(start: cycle.startDate, end: $0) + 1) дн." } ?? "Идёт"
                let dateRange = "\(cycle.startDate) — \(cycle.endDate ?? "...")"
                let notes = cycle.note ?? (cycle.isOutlier ? "Выброс" : "—")

                dateRange.draw(at: CGPoint(x: margin, y: currentY), withAttributes: rowAttrs)
                periodLen.draw(at: CGPoint(x: margin + 180, y: currentY), withAttributes: rowAttrs)
                cycleLen.draw(at: CGPoint(x: margin + 280, y: currentY), withAttributes: rowAttrs)
                notes.draw(in: CGRect(x: margin + 380, y: currentY, width: 135, height: 14), withAttributes: rowAttrs)

                currentY += 16
            }

            currentY += 14

            // 4. Section Title: Зафиксированные симптомы
            "ЖУРНАЛ СИМПТОМОВ И САМОЧУВСТВИЯ:".draw(at: CGPoint(x: margin, y: currentY), withAttributes: tableHeaderAttrs)
            currentY += 18

            for sym in symptoms.prefix(8) {
                let line = "• [\(sym.date)] \(sym.summaryDescription)"
                line.draw(in: CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: 16), withAttributes: rowAttrs)
                currentY += 18
            }

            // Footer Disclaimer
            let footerY = pageHeight - margin - 20
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .light),
                .foregroundColor: UIColor.gray
            ]
            let disclaimer = "Примечание: Данный отчёт сформирован на основании записей пользователя в приложении Miodi и предназначен исключительно для информирования лечащего врача. Не является клиническим диагнозом."
            disclaimer.draw(in: CGRect(x: margin, y: footerY, width: pageWidth - 2 * margin, height: 26), withAttributes: footerAttrs)
        }

        return tempUrl
    }
}
