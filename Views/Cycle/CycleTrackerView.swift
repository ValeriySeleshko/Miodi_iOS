//
//  CycleTrackerView.swift
//  Plan4U_iOS
//
//  Complete Female Cycle Tracker matching Android CycleModal.kt & CycleEngine.kt 1-to-1
//  Interactive Orbit Phase Ring, Daily Symptoms Checklist, Medical Gynecologist Export,
//  Face ID / Passcode Privacy Mode, Smart Check-In Popups and Settings.
//

import SwiftUI
import SwiftData

public struct CycleTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \CycleItem.startDate, order: .reverse) private var cycleHistory: [CycleItem]

    @State private var settings = CycleSettingsStore.shared
    @State private var security = CycleSecurityManager.shared

    // Submenus & Popups state
    @State private var isShowingAddModal: Bool = false
    @State private var isShowingSymptomsModal: Bool = false
    @State private var isShowingSettingsModal: Bool = false
    @State private var isShowingMedicalExport: Bool = false
    @State private var isShowingGuide: Bool = false
    @State private var isShowingCheckInPopup: Bool = false

    @State private var editingCycle: CycleItem? = nil
    @State private var selectedDateStr: String = CycleEngine.getTodayString()
    @State private var showToastMessage: String? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var currentStatus: CycleStatus {
        CycleEngine.getStatusForDate(
            history: cycleHistory,
            refDateStr: selectedDateStr,
            defaultCycleLength: settings.defaultCycleLength,
            periodLength: settings.periodLength,
            lutealLength: settings.lutealLength
        )
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x0F172A) : Color(hex: 0xFDF4F8))
                    .ignoresSafeArea()

                if security.isProtectionEnabled && !security.isUnlockedThisSession {
                    CyclePrivacyLockView {
                        security.isUnlockedThisSession = true
                    }
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Женский календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Guide Info Button
                    Button {
                        isShowingGuide = true
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: 0xFB7185))
                    }

                    // Medical Report Button
                    Button {
                        isShowingMedicalExport = true
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        Image(systemName: "doc.text")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: 0xFB7185))
                    }

                    // Settings Button
                    Button {
                        isShowingSettingsModal = true
                        MiodiHapticFeedback.lightClick()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: 0xFB7185))
                    }
                }
            }
            .sheet(isPresented: $isShowingAddModal) {
                CycleAddEditSheet(editingItem: editingCycle) {
                    isShowingAddModal = false
                }
            }
            .sheet(isPresented: $isShowingSymptomsModal) {
                CycleSymptomsModalView(selectedDateStr: selectedDateStr) {
                    isShowingSymptomsModal = false
                    showToast("Симптомы сохранены ✨")
                }
            }
            .sheet(isPresented: $isShowingSettingsModal) {
                CycleSettingsModalView {
                    isShowingSettingsModal = false
                    showToast("Настройки обновлены ✨")
                }
            }
            .sheet(isPresented: $isShowingMedicalExport) {
                CycleMedicalExportView()
            }
            .sheet(isPresented: $isShowingGuide) {
                CyclePhasesGuideSheet()
            }
            .overlay {
                if isShowingCheckInPopup, let prompt = currentStatus.checkInPrompt {
                    CycleCheckInPopupView(
                        prompt: prompt,
                        periodLength: settings.periodLength,
                        onStartPeriodOnDate: { dateStr in
                            startNewPeriod(startDate: dateStr)
                            isShowingCheckInPopup = false
                        },
                        onEndPeriodOnDate: { cycleId, endDateStr in
                            confirmPeriodEnded(cycleId: cycleId, endDateStr: endDateStr)
                            isShowingCheckInPopup = false
                        },
                        onStillOngoing: { _ in
                            isShowingCheckInPopup = false
                        },
                        onDismissToday: {
                            settings.popupDismissedDate = CycleEngine.getTodayString()
                            isShowingCheckInPopup = false
                        }
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if let msg = showToastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color(hex: 0xFB7185))
                        Text(msg)
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
                checkAutoPopup()
            }
        }
    }

    // MARK: - Main Content View
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 1. Interactive Orbit Wheel
                orbitWheelSection

                // 2. Smart Check-In Banner (if prompt active)
                if let prompt = currentStatus.checkInPrompt, settings.popupDismissedDate != CycleEngine.getTodayString() {
                    smartCheckInBanner(prompt: prompt)
                }

                // 3. Fast Action Cards (Start/End Period, Symptoms, Ovulation, Medical Report)
                fastActionCardsSection

                // 4. Key Metrics Cards
                metricsSection

                // 5. Daily Phase Advice Card
                phaseAdviceSection

                // 6. Cycle History List
                historySection

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    // MARK: - 1. Orbit Wheel Section
    private var orbitWheelSection: some View {
        let status = currentStatus
        let orbit = status.orbitData
        let indicator = settings.indicatorStyle.emoji

        return VStack(spacing: 10) {
            // Header with day and phase pill
            HStack {
                Text(status.hasData ? "День \(status.dayInCycle)" : "День --")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0xFB7185))

                Spacer()

                HStack(spacing: 4) {
                    Text(indicator)
                    Text(status.hasData ? status.advice.badge : "Календарь готов")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color(hex: 0xFB7185))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: 0xFB7185).opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(hex: 0xFB7185).opacity(0.25), lineWidth: 1)
                )
            }

            ZStack {
                // Background Track
                Circle()
                    .stroke(isDark ? Color(hex: 0x2A1B28) : Color(hex: 0xFCE7F0), lineWidth: 18)
                    .frame(width: 236, height: 236)

                // Colored Orbit Segments
                if orbit.hasData {
                    ForEach(orbit.segments) { segment in
                        let startFraction = Double(segment.startDay - 1) / Double(orbit.totalDays)
                        let endFraction = Double(segment.endDay) / Double(orbit.totalDays)

                        Circle()
                            .trim(from: CGFloat(startFraction), to: CGFloat(endFraction))
                            .stroke(segment.color, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 236, height: 236)
                    }

                    // Indicator Needle / Pointer dot with emoji
                    let angle = (orbit.pointerAngleDeg - 90.0) * .pi / 180.0
                    let radius: Double = 118.0
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius

                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.black.opacity(0.25), radius: 4)
                        .overlay(
                            Text(indicator)
                                .font(.system(size: 15))
                        )
                        .offset(x: x, y: y)
                }

                // Center Display Info
                VStack(spacing: 4) {
                    if status.hasData {
                        Text(status.phase.displayNameRu)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(status.phase.color)
                            .multilineTextAlignment(.center)

                        if status.isPeriodActiveNow {
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: 0xFB7185)).frame(width: 6, height: 6)
                                Text("Менструация идёт")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: 0xFB7185))
                            }
                        } else if status.daysUntilExpected > 0 {
                            Text("След. цикл через \(status.daysUntilExpected) дн.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } else if status.isOverdue {
                            Text("Задержка \(status.overdueDays) дн.")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: 0xF472B6))
                        }

                        Text("из \(orbit.totalDays) дн.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.8))
                    } else {
                        Text("🍒")
                            .font(.system(size: 34))
                        Text("Нет записей")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                        Text("Отметьте начало цикла")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 250, height: 250)
            .padding(.vertical, 4)

            // Orbit Legend with Info tap
            Button {
                isShowingGuide = true
            } label: {
                HStack(spacing: 10) {
                    legendItem(title: "Отдых", color: CyclePhase.menstrual.color)
                    legendItem(title: "Подъём", color: CyclePhase.follicular.color)
                    legendItem(title: "Пик", color: CyclePhase.ovulation.color)
                    legendItem(title: "Уют", color: CyclePhase.luteal.color)
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0xFB7185))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardBackground)
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 2. Smart Check-In Banner
    private func smartCheckInBanner(prompt: CycleCheckInPrompt) -> some View {
        HStack(spacing: 12) {
            Text(prompt.type == .forgotEnd ? "✨" : (prompt.type == .overdueDaily ? "⏳" : "🌸"))
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.type == .forgotEnd ? "Закончились ли месячные?" : (prompt.type == .overdueDaily ? "Задержка цикла (\(prompt.daysCount) дн.)" : "Скоро новый цикл"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFB7185))

                Text("Нажмите для быстрого ответа")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isShowingCheckInPopup = true
                MiodiHapticFeedback.lightClick()
            } label: {
                Text("Ответить")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0xFB7185))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0xFB7185).opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: 0xFB7185).opacity(0.35), lineWidth: 1)
                )
        )
    }

    // MARK: - 3. Fast Action Cards
    private var fastActionCardsSection: some View {
        let isPeriodActive = currentStatus.isPeriodActiveNow
        let latestWithOvulation = cycleHistory.first { $0.ovulationDate != nil }

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            // Card 1: Toggle Period (Start or End)
            Button {
                togglePeriodToday()
            } label: {
                actionCardContent(
                    emoji: isPeriodActive ? "✨" : "🩸",
                    title: isPeriodActive ? "Конец\nмесячных" : "Начало\nмесячных",
                    subtitle: isPeriodActive ? "Завершить" : "Отметить старт",
                    accentColor: isPeriodActive ? Color(hex: 0x34D399) : Color(hex: 0xFB7185)
                )
            }
            .buttonStyle(.plain)

            // Card 2: Symptoms & Mood
            Button {
                isShowingSymptomsModal = true
                MiodiHapticFeedback.lightClick()
            } label: {
                actionCardContent(
                    emoji: "🌸",
                    title: "Настроение\nи симптомы",
                    subtitle: "Чеклист дня",
                    accentColor: Color(hex: 0xF472B6)
                )
            }
            .buttonStyle(.plain)

            // Card 3: Ovulation
            Button {
                toggleOvulationToday()
            } label: {
                let hasOvulation = latestWithOvulation?.ovulationDate == CycleEngine.getTodayString()
                actionCardContent(
                    emoji: "🌿",
                    title: hasOvulation ? "Овуляция\nотмечена" : "Овуляция\nзамечена",
                    subtitle: hasOvulation ? "Сбросить" : "Зафиксировать",
                    accentColor: Color(hex: 0xF59E0B)
                )
            }
            .buttonStyle(.plain)

            // Card 4: Doctor / Medical Report
            Button {
                isShowingMedicalExport = true
                MiodiHapticFeedback.lightClick()
            } label: {
                actionCardContent(
                    emoji: "🩺",
                    title: "Отчёт для\nгинеколога",
                    subtitle: "Экспорт в PDF",
                    accentColor: Color(hex: 0xA78BFA)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func actionCardContent(emoji: String, title: String, subtitle: String, accentColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 22))

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 94)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accentColor.opacity(0.35), lineWidth: 1)
                )
        )
    }

    // MARK: - 4. Key Metrics Cards
    private var metricsSection: some View {
        let pred = currentStatus.prediction

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            metricCard(
                icon: "🗓",
                value: "\(pred?.medianLength ?? settings.defaultCycleLength) дн.",
                label: "Длина цикла",
                sub: pred?.isIrregular == true ? "Нерегулярный" : "Стабильный"
            )

            metricCard(
                icon: "🩸",
                value: "\(settings.periodLength) дн.",
                label: "Длина менструации",
                sub: "Средняя длительность"
            )

            metricCard(
                icon: "🔮",
                value: pred != nil ? CycleEngine.formatShortRange(startStr: pred!.windowStart, endStr: pred!.windowEnd) : "—",
                label: "След. менструация",
                sub: "Окно прогноза"
            )

            metricCard(
                icon: "✨",
                value: pred != nil ? CycleEngine.formatShortRange(startStr: pred!.fertileStart, endStr: pred!.fertileEnd) : "—",
                label: "Окно фертильности",
                sub: "Овуляция: \(pred?.estOvulationCenter ?? "—")"
            )
        }
    }

    private func metricCard(icon: String, value: String, label: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(icon).font(.system(size: 16))
                Spacer()
            }
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(sub)
                .font(.system(size: 9))
                .foregroundStyle(.secondary.opacity(0.8))
                .lineLimit(1)
        }
        .padding(12)
        .background(cardBackground)
    }

    // MARK: - 5. Daily Phase Advice Card
    private var phaseAdviceSection: some View {
        let advice = currentStatus.advice

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Text("💡")
                    Text(advice.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)
                }

                Spacer()

                Text(advice.badge)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(currentStatus.phase.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(currentStatus.phase.color.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Energy meter
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Уровень энергии:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(advice.energy)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(currentStatus.phase.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(isDark ? Color(hex: 0x2A3347) : Color(hex: 0xE2E8F0))
                            .frame(height: 6)

                        Capsule()
                            .fill(currentStatus.phase.color)
                            .frame(width: geo.size.width * CGFloat(advice.energyFraction), height: 6)
                    }
                }
                .frame(height: 6)
            }

            Text(advice.taskTip)
                .font(.system(size: 13))
                .foregroundStyle(isDark ? Color.white.opacity(0.85) : Color(hex: 0x334155))
                .lineSpacing(3)
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - 6. History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("История циклов")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)

                Spacer()

                Button {
                    editingCycle = nil
                    isShowingAddModal = true
                    MiodiHapticFeedback.lightClick()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Добавить")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFB7185))
                }
            }

            if cycleHistory.isEmpty {
                VStack(spacing: 8) {
                    Text("Записей пока нет")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Нажмите «Начало месячных» или добавьте прошлые циклы вручную.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(cycleHistory.enumerated()), id: \.element.id) { idx, item in
                        let nextCycle = cycleHistory.indices.contains(idx - 1) ? cycleHistory[idx - 1] : nil
                        let cycleLen = nextCycle.map { CycleEngine.diffInDays(start: item.startDate, end: $0.startDate) }
                        historyRow(item: item, cycleLenDays: cycleLen)
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func historyRow(item: CycleItem, cycleLenDays: Int?) -> some View {
        let duration = item.endDate.map { CycleEngine.diffInDays(start: item.startDate, end: $0) + 1 }

        return HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: 0xFB7185).opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: 0xFB7185))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(CycleEngine.formatShortRange(startStr: item.startDate, endStr: item.endDate))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : MiodiStaticColors.darkText)

                HStack(spacing: 6) {
                    if let d = duration {
                        Text("\(d) дн. менструация")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Идёт сейчас")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0x34D399))
                    }

                    if let cLen = cycleLenDays {
                        Text("• Цикл: \(cLen) дн.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xFB7185))
                    }

                    if item.isOutlier {
                        Text("• Выброс")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xF59E0B))
                    }
                }

                if let n = item.note, !n.isEmpty {
                    Text(n)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Menu {
                Button {
                    editingCycle = item
                    isShowingAddModal = true
                } label: {
                    Label("Редактировать", systemImage: "pencil")
                }

                Button {
                    item.isOutlier.toggle()
                    try? modelContext.save()
                    MiodiHapticFeedback.lightClick()
                } label: {
                    Label(item.isOutlier ? "Убрать отметку выброса" : "Отметить как сбой/выброс", systemImage: "flag")
                }

                Button(role: .destructive) {
                    modelContext.delete(item)
                    try? modelContext.save()
                    MiodiHapticFeedback.warning()
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(10)
        .background(isDark ? Color(hex: 0x141B2D) : Color(hex: 0xF1F5F9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

    // MARK: - Actions
    private func togglePeriodToday() {
        let today = CycleEngine.getTodayString()
        if currentStatus.isPeriodActiveNow {
            // End active period
            endCurrentPeriod()
            showToast("Менструация завершена ✨")
        } else {
            // Start new period
            startNewPeriod(startDate: today)
            showToast("Новый цикл начат 🩸")
        }
    }

    private func startNewPeriod(startDate: String) {
        let newCycle = CycleItem(
            startDate: startDate,
            endDate: nil,
            cycleLengthDays: settings.defaultCycleLength,
            periodLengthDays: settings.periodLength
        )
        modelContext.insert(newCycle)
        try? modelContext.save()
        MiodiHapticFeedback.success()
    }

    private func endCurrentPeriod() {
        guard let latest = cycleHistory.first(where: { $0.endDate == nil }) else { return }
        latest.endDate = CycleEngine.getTodayString()
        try? modelContext.save()
        MiodiHapticFeedback.success()
    }

    private func confirmPeriodEnded(cycleId: String?, endDateStr: String) {
        let target = (cycleId != nil ? cycleHistory.first(where: { $0.id == cycleId }) : nil) ?? cycleHistory.first
        guard let item = target else { return }
        item.endDate = endDateStr
        try? modelContext.save()
        MiodiHapticFeedback.success()
        showToast("Дата окончания сохранена ✨")
    }

    private func toggleOvulationToday() {
        let today = CycleEngine.getTodayString()
        guard let latest = cycleHistory.first else {
            showToast("Сначала добавьте цикл")
            return
        }

        if latest.ovulationDate == today {
            latest.ovulationDate = nil
            showToast("Отметка овуляции сброшена")
        } else {
            latest.ovulationDate = today
            showToast("Овуляция зафиксирована 🌿")
        }
        try? modelContext.save()
        MiodiHapticFeedback.success()
    }

    private func checkAutoPopup() {
        if settings.popupEnabled && settings.popupDismissedDate != CycleEngine.getTodayString() && currentStatus.checkInPrompt != nil {
            isShowingCheckInPopup = true
        }
    }

    private func showToast(_ msg: String) {
        withAnimation {
            showToastMessage = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showToastMessage = nil
            }
        }
    }
}
