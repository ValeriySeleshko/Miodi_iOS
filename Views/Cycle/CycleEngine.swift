//
//  CycleEngine.swift
//  Plan4U_iOS
//
//  Female Cycle Calculation Engine matching Android CycleEngine.kt 1-to-1
//  Prediction calculations, Orbit metrics, Phase advice, and Smart Check-In prompts.
//

import Foundation
import SwiftUI

public enum CyclePhase: String, CaseIterable, Sendable {
    case menstrual = "menstrual"
    case follicular = "follicular"
    case ovulation = "ovulation"
    case luteal = "luteal"
    case overdueWindow = "overdue_window"

    public var displayNameRu: String {
        switch self {
        case .menstrual: return "Менструальная фаза"
        case .follicular: return "Фолликулярная фаза"
        case .ovulation: return "Овуляция"
        case .luteal: return "Лютеиновая фаза"
        case .overdueWindow: return "Окно ожидания"
        }
    }

    public var color: Color {
        switch self {
        case .menstrual: return Color(hex: 0xFB7185) // Rose / coral
        case .follicular: return Color(hex: 0x34D399) // Mint / emerald
        case .ovulation: return Color(hex: 0xFBBF24) // Gold / amber
        case .luteal: return Color(hex: 0xA78BFA) // Lavender / purple
        case .overdueWindow: return Color(hex: 0xF472B6) // Magenta
        }
    }
}

public struct CycleOrbitSegment: Identifiable, Sendable {
    public let id = UUID()
    public let phase: CyclePhase
    public let startDay: Int
    public let endDay: Int
    public let days: Int
    public let color: Color
}

public struct CycleOrbitData: Sendable {
    public let hasData: Bool
    public let totalDays: Int
    public let currentDay: Int?
    public let pointerAngleDeg: Double
    public let segments: [CycleOrbitSegment]

    public init(
        hasData: Bool = false,
        totalDays: Int = 28,
        currentDay: Int? = nil,
        pointerAngleDeg: Double = 0.0,
        segments: [CycleOrbitSegment] = []
    ) {
        self.hasData = hasData
        self.totalDays = totalDays
        self.currentDay = currentDay
        self.pointerAngleDeg = pointerAngleDeg
        self.segments = segments
    }
}

public struct CyclePrediction: Sendable {
    public let lastCycleStart: String
    public let windowStart: String
    public let windowEnd: String
    public let predictedCenter: String
    public let predictedEnd: String
    public let fertileStart: String
    public let fertileEnd: String
    public let estOvulationCenter: String
    public let medianLength: Int
    public let minLen: Int
    public let maxLen: Int
    public let historyCount: Int
    public let defaultCycleLength: Int
    public let isIrregular: Bool
    public let isOvulationOverride: Bool
}

public struct CycleDailyAdvice: Sendable {
    public let title: String
    public let badge: String
    public let energy: String
    public let energyFraction: Double
    public let taskTip: String
}

public struct CycleStatus: Sendable {
    public let hasData: Bool
    public let dayInCycle: Int
    public let curDateStr: String
    public let phase: CyclePhase
    public let isPeriodDay: Bool
    public let isPeriodActiveNow: Bool
    public let inWindow: Bool
    public let isOverdue: Bool
    public let overdueDays: Int
    public let daysUntilWindow: Int
    public let daysUntilExpected: Int
    public let advice: CycleDailyAdvice
    public let prediction: CyclePrediction?
    public let orbitData: CycleOrbitData
    public let checkInPrompt: CycleCheckInPrompt?

    public init(
        hasData: Bool,
        dayInCycle: Int,
        curDateStr: String,
        phase: CyclePhase,
        isPeriodDay: Bool,
        isPeriodActiveNow: Bool,
        inWindow: Bool,
        isOverdue: Bool,
        overdueDays: Int,
        daysUntilWindow: Int,
        daysUntilExpected: Int,
        advice: CycleDailyAdvice,
        prediction: CyclePrediction?,
        orbitData: CycleOrbitData,
        checkInPrompt: CycleCheckInPrompt? = nil
    ) {
        self.hasData = hasData
        self.dayInCycle = dayInCycle
        self.curDateStr = curDateStr
        self.phase = phase
        self.isPeriodDay = isPeriodDay
        self.isPeriodActiveNow = isPeriodActiveNow
        self.inWindow = inWindow
        self.isOverdue = isOverdue
        self.overdueDays = overdueDays
        self.daysUntilWindow = daysUntilWindow
        self.daysUntilExpected = daysUntilExpected
        self.advice = advice
        self.prediction = prediction
        self.orbitData = orbitData
        self.checkInPrompt = checkInPrompt
    }
}

public enum CycleEngine {
    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public static func getTodayString() -> String {
        isoFormatter.string(from: Date())
    }

    public static func addDays(to dateStr: String, n: Int) -> String {
        guard let d = isoFormatter.date(from: dateStr) else { return dateStr }
        guard let target = Calendar.current.date(byAdding: .day, value: n, to: d) else { return dateStr }
        return isoFormatter.string(from: target)
    }

    public static func diffInDays(start: String, end: String) -> Int {
        guard let d1 = isoFormatter.date(from: start),
              let d2 = isoFormatter.date(from: end) else { return 0 }
        return Calendar.current.dateComponents([.day], from: d1, to: d2).day ?? 0
    }

    public static func formatShortRange(startStr: String, endStr: String?) -> String {
        guard let d1 = isoFormatter.date(from: startStr) else { return startStr }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM"
        let s1 = f.string(from: d1)

        guard let endStr = endStr, let d2 = isoFormatter.date(from: endStr) else {
            return s1
        }
        let s2 = f.string(from: d2)
        return "\(s1) — \(s2)"
    }

    // MARK: - Prediction & Analysis
    public static func getPrediction(
        history: [CycleItem],
        defaultCycleLength: Int = 28,
        periodLength: Int = 5,
        lutealLength: Int = 14,
        isIrregularUser: Bool = false
    ) -> CyclePrediction? {
        guard let latest = history.max(by: { $0.startDate < $1.startDate }) else { return nil }
        let sorted = history.sorted(by: { $0.startDate < $1.startDate })

        var validLengths: [Int] = []
        for i in 0..<(sorted.count - 1) {
            let cur = sorted[i]
            let next = sorted[i + 1]
            let len = diffInDays(start: cur.startDate, end: next.startDate)
            if len >= 15 && len <= 90 {
                if !cur.isOutlier {
                    validLengths.append(len)
                }
            }
        }

        let medianLength: Int
        let minLen: Int
        let maxLen: Int

        if validLengths.isEmpty {
            medianLength = defaultCycleLength
            minLen = max(defaultCycleLength - 3, 20)
            maxLen = min(defaultCycleLength + 6, 45)
        } else if validLengths.count == 1 {
            medianLength = Int(round(Double(validLengths[0] + defaultCycleLength) / 2.0))
            minLen = min(validLengths[0], defaultCycleLength - 2)
            maxLen = max(validLengths[0], defaultCycleLength + 3)
        } else {
            let sortedL = validLengths.sorted()
            let mid = sortedL.count / 2
            medianLength = (sortedL.count % 2 != 0) ? sortedL[mid] : Int(round(Double(sortedL[mid - 1] + sortedL[mid]) / 2.0))
            minLen = sortedL.first ?? 28
            maxLen = sortedL.last ?? 28
        }

        let isHighVariability = validLengths.count >= 2 && (maxLen - minLen >= 7)
        let isIrregular = isIrregularUser || isHighVariability

        let windowStart: String
        let windowEnd: String
        let predictedCenter: String
        var isOvulationOverride = false

        if let ovDate = latest.ovulationDate, !ovDate.isEmpty, ovDate >= latest.startDate {
            isOvulationOverride = true
            predictedCenter = addDays(to: ovDate, n: lutealLength)
            windowStart = addDays(to: predictedCenter, n: -1)
            windowEnd = addDays(to: predictedCenter, n: 1)
        } else if isIrregular {
            if validLengths.count >= 2 {
                windowStart = addDays(to: latest.startDate, n: minLen)
                windowEnd = addDays(to: latest.startDate, n: maxLen)
                predictedCenter = addDays(to: latest.startDate, n: medianLength)
            } else {
                windowStart = addDays(to: latest.startDate, n: defaultCycleLength - 3)
                windowEnd = addDays(to: latest.startDate, n: defaultCycleLength + 6)
                predictedCenter = addDays(to: latest.startDate, n: defaultCycleLength)
            }
        } else {
            let targetLen = (validLengths.count >= 3 && abs(medianLength - defaultCycleLength) <= 2) ? medianLength : defaultCycleLength
            predictedCenter = addDays(to: latest.startDate, n: targetLen)
            windowStart = addDays(to: predictedCenter, n: -1)
            windowEnd = addDays(to: predictedCenter, n: 1)
        }

        let effectiveCycleLen = (!isIrregular && validLengths.count < 3) ? defaultCycleLength : ((validLengths.count >= 2) ? medianLength : defaultCycleLength)
        let estOvulationCenter = isOvulationOverride ? latest.ovulationDate! : addDays(to: latest.startDate, n: max(effectiveCycleLen - lutealLength, periodLength + 2))

        return CyclePrediction(
            lastCycleStart: latest.startDate,
            windowStart: windowStart,
            windowEnd: windowEnd,
            predictedCenter: predictedCenter,
            predictedEnd: addDays(to: predictedCenter, n: periodLength - 1),
            fertileStart: addDays(to: estOvulationCenter, n: -3),
            fertileEnd: addDays(to: estOvulationCenter, n: 1),
            estOvulationCenter: estOvulationCenter,
            medianLength: medianLength,
            minLen: minLen,
            maxLen: maxLen,
            historyCount: validLengths.count,
            defaultCycleLength: defaultCycleLength,
            isIrregular: isIrregular,
            isOvulationOverride: isOvulationOverride
        )
    }

    // MARK: - Daily Advice
    public static func getAdvice(phase: CyclePhase, day: Int) -> CycleDailyAdvice {
        switch phase {
        case .menstrual:
            return CycleDailyAdvice(
                title: "Период перезагрузки",
                badge: "Восстановление",
                energy: "Низкий",
                energyFraction: 0.35,
                taskTip: "Снизьте темп. Благоприятное время для рефлексии, планирования и спокойной рутины. Избегайте стрессовых пиков."
            )
        case .follicular:
            return CycleDailyAdvice(
                title: "Подъём сил и креатив",
                badge: "Энергия растёт",
                energy: "Высокий",
                energyFraction: 0.85,
                taskTip: "Идеально для запуска новых проектов, мозговых штурмов, силовых тренировок и важных переговоров."
            )
        case .ovulation:
            return CycleDailyAdvice(
                title: "Пик продуктивности",
                badge: "Максимум сил",
                energy: "Максимальный",
                energyFraction: 1.0,
                taskTip: "Время максимальной харизмы и выносливости. Презентации, публичные выступления, рекордные задачи."
            )
        case .luteal:
            return CycleDailyAdvice(
                title: "Фокус на завершении",
                badge: "Внимание к деталям",
                energy: "Умеренный",
                energyFraction: 0.55,
                taskTip: "Отличное время для наведения порядка, завершения начатых задач, анализа отчётов и бережного ухода за собой."
            )
        case .overdueWindow:
            return CycleDailyAdvice(
                title: "Ожидание нового цикла",
                badge: "Осознанность",
                energy: "Переменный",
                energyFraction: 0.45,
                taskTip: "Организм готовится к новому циклу. Пейте больше воды, отдавайте приоритет сну и мягким прогулкам."
            )
        }
    }

    // MARK: - Smart Check-In Prompt
    public static func getCheckInPrompt(
        history: [CycleItem],
        refDateStr: String = getTodayString(),
        periodLength: Int = 5,
        defaultCycleLength: Int = 28,
        remindersEnabled: Bool = true,
        reminderDaysBefore: Int = 3,
        delayRemindersEnabled: Bool = true,
        endRemindersEnabled: Bool = true
    ) -> CycleCheckInPrompt? {
        guard !history.isEmpty, let latest = history.max(by: { $0.startDate < $1.startDate }) else { return nil }

        // 1. Check if user forgot to mark the end of the current period
        if latest.endDate == nil && endRemindersEnabled {
            let daysSinceStart = diffInDays(start: latest.startDate, end: refDateStr)
            if daysSinceStart >= periodLength && daysSinceStart <= 20 {
                let defaultEnd = addDays(to: latest.startDate, n: periodLength - 1)
                return CycleCheckInPrompt(
                    type: .forgotEnd,
                    cycleId: latest.id,
                    startDate: latest.startDate,
                    defaultEndDate: (defaultEnd <= refDateStr) ? defaultEnd : refDateStr,
                    daysCount: daysSinceStart + 1
                )
            }
        }

        // 2. Prediction-based prompts
        guard let prediction = getPrediction(history: history, defaultCycleLength: defaultCycleLength, periodLength: periodLength) else { return nil }
        let diffToCenter = diffInDays(start: refDateStr, end: prediction.predictedCenter)

        if diffToCenter < 0 {
            let delayDays = -diffToCenter
            if delayDays >= 1 && delayDays <= 60 && delayRemindersEnabled {
                return CycleCheckInPrompt(
                    type: .overdueDaily,
                    cycleId: latest.id,
                    startDate: latest.startDate,
                    expectedDate: prediction.predictedCenter,
                    daysCount: delayDays
                )
            }
        } else if diffToCenter == 0 && latest.startDate != refDateStr && remindersEnabled {
            return CycleCheckInPrompt(
                type: .expectedToday,
                cycleId: latest.id,
                startDate: latest.startDate,
                expectedDate: prediction.predictedCenter,
                daysCount: 0
            )
        } else if diffToCenter >= 1 && diffToCenter <= reminderDaysBefore && remindersEnabled {
            return CycleCheckInPrompt(
                type: .approaching,
                cycleId: latest.id,
                startDate: latest.startDate,
                expectedDate: prediction.predictedCenter,
                daysCount: diffToCenter
            )
        }

        return nil
    }

    // MARK: - Status for Date
    public static func getStatusForDate(
        history: [CycleItem],
        refDateStr: String = getTodayString(),
        defaultCycleLength: Int = 28,
        periodLength: Int = 5,
        lutealLength: Int = 14
    ) -> CycleStatus {
        guard let latest = history.max(by: { $0.startDate < $1.startDate }) else {
            let emptyAdvice = CycleDailyAdvice(
                title: "Нет данных цикла",
                badge: "Старт",
                energy: "Н/Д",
                energyFraction: 0.5,
                taskTip: "Отметьте первый день цикла, чтобы включить умный прогноз фаз и рекомендаций."
            )
            return CycleStatus(
                hasData: false,
                dayInCycle: 1,
                curDateStr: refDateStr,
                phase: .follicular,
                isPeriodDay: false,
                isPeriodActiveNow: false,
                inWindow: false,
                isOverdue: false,
                overdueDays: 0,
                daysUntilWindow: 0,
                daysUntilExpected: 0,
                advice: emptyAdvice,
                prediction: nil,
                orbitData: CycleOrbitData(hasData: false, totalDays: defaultCycleLength),
                checkInPrompt: nil
            )
        }

        let dayInCycle = max(1, diffInDays(start: latest.startDate, end: refDateStr) + 1)
        let prediction = getPrediction(
            history: history,
            defaultCycleLength: defaultCycleLength,
            periodLength: periodLength,
            lutealLength: lutealLength
        )

        let effectiveEnd = latest.endDate ?? addDays(to: latest.startDate, n: periodLength - 1)
        let isPeriodDay = (refDateStr >= latest.startDate && refDateStr <= effectiveEnd)
        let isPeriodActiveNow = (latest.endDate == nil) && (dayInCycle <= 14)

        let phase: CyclePhase
        if isPeriodDay {
            phase = .menstrual
        } else if let pred = prediction, refDateStr >= pred.fertileStart && refDateStr <= pred.fertileEnd {
            phase = .ovulation
        } else if let pred = prediction, refDateStr > pred.fertileEnd {
            phase = .luteal
        } else {
            phase = .follicular
        }

        let inWindow = prediction.map { refDateStr >= $0.windowStart && refDateStr <= $0.windowEnd } ?? false
        let isOverdue = prediction.map { refDateStr > $0.windowEnd } ?? false
        let overdueDays = (prediction.map { refDateStr > $0.predictedCenter } ?? false) ? diffInDays(start: prediction!.predictedCenter, end: refDateStr) : 0
        let daysUntilWindow = (prediction.map { refDateStr < $0.windowStart } ?? false) ? diffInDays(start: refDateStr, end: prediction!.windowStart) : 0
        let daysUntilExpected = prediction.map { max(0, diffInDays(start: refDateStr, end: $0.predictedCenter)) } ?? 0

        let advice = getAdvice(phase: phase, day: dayInCycle)

        // Orbit calculation
        let totalDays = max(20, prediction?.medianLength ?? defaultCycleLength)
        let pointerAngleDeg = min(360.0, max(0.0, (Double(dayInCycle) - 0.5) * (360.0 / Double(totalDays))))

        let pLen = min(periodLength, Int(Double(totalDays) * 0.3))
        let ovCenter = max(pLen + 2, totalDays - lutealLength)
        let ovStart = max(pLen + 1, ovCenter - 1)
        let ovEnd = min(totalDays - 2, ovCenter + 1)

        let segments = [
            CycleOrbitSegment(phase: .menstrual, startDay: 1, endDay: pLen, days: max(1, pLen), color: CyclePhase.menstrual.color),
            CycleOrbitSegment(phase: .follicular, startDay: pLen + 1, endDay: ovStart - 1, days: max(1, ovStart - pLen - 1), color: CyclePhase.follicular.color),
            CycleOrbitSegment(phase: .ovulation, startDay: ovStart, endDay: ovEnd, days: max(1, ovEnd - ovStart + 1), color: CyclePhase.ovulation.color),
            CycleOrbitSegment(phase: .luteal, startDay: ovEnd + 1, endDay: totalDays, days: max(1, totalDays - ovEnd), color: CyclePhase.luteal.color)
        ]

        let orbitData = CycleOrbitData(
            hasData: true,
            totalDays: totalDays,
            currentDay: dayInCycle,
            pointerAngleDeg: pointerAngleDeg,
            segments: segments
        )

        let prompt = getCheckInPrompt(
            history: history,
            refDateStr: refDateStr,
            periodLength: periodLength,
            defaultCycleLength: defaultCycleLength,
            remindersEnabled: CycleSettingsStore.shared.remindersEnabled,
            reminderDaysBefore: CycleSettingsStore.shared.reminderDaysBefore,
            delayRemindersEnabled: CycleSettingsStore.shared.delayRemindersEnabled,
            endRemindersEnabled: CycleSettingsStore.shared.endRemindersEnabled
        )

        return CycleStatus(
            hasData: true,
            dayInCycle: dayInCycle,
            curDateStr: refDateStr,
            phase: phase,
            isPeriodDay: isPeriodDay,
            isPeriodActiveNow: isPeriodActiveNow,
            inWindow: inWindow,
            isOverdue: isOverdue,
            overdueDays: overdueDays,
            daysUntilWindow: daysUntilWindow,
            daysUntilExpected: daysUntilExpected,
            advice: advice,
            prediction: prediction,
            orbitData: orbitData,
            checkInPrompt: prompt
        )
    }
}
