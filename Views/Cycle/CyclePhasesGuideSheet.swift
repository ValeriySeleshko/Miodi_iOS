//
//  CyclePhasesGuideSheet.swift
//  Plan4U_iOS
//
//  Educational Phases Guide matching Android CyclePhasesGuideDialog 1-to-1
//  Menstrual, Follicular, Ovulation and Luteal biological rhythm descriptions.
//

import SwiftUI

public struct CyclePhasesGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? Color(hex: 0x0F172A) : Color(hex: 0xFDF4F8))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        phaseCard(
                            phase: .menstrual,
                            emoji: "🩸",
                            badge: "Фаза отдыха и восстановления",
                            days: "Дни 1–5",
                            color: CyclePhase.menstrual.color,
                            description: "Менструация. Тело обновляется — время тишины, покоя, тепла и заботы о себе. Снизьте нагрузку, пейте тёплый чай и избегайте стресса.",
                            tips: ["Спокойные дела, рефлексия, чтение", "Йога, растяжка, прогулки", "Тепло, сон и железосодержащие продукты"]
                        )

                        phaseCard(
                            phase: .follicular,
                            emoji: "🌱",
                            badge: "Фаза подъёма и вдохновения",
                            days: "Дни 6–13",
                            color: CyclePhase.follicular.color,
                            description: "Фолликулярная фаза. Растёт эстроген — прилив свежих сил, вдохновения и энергии. Организм готов к новым вызовам и покорению целей.",
                            tips: ["Старт новых проектов, мозговые штурмы", "Интенсивные тренировки, бег, фитнес", "Обучение, знакомства и активное общение"]
                        )

                        phaseCard(
                            phase: .ovulation,
                            emoji: "✨",
                            badge: "Пик продуктивности и обаяния",
                            days: "Дни 14–16",
                            color: CyclePhase.ovulation.color,
                            description: "Овуляция. Пик энергии, уверенности, яркого обаяния и выносливости. Вы на максимуме своих физических и ментальных ресурсов.",
                            tips: ["Публичные выступления, презентации", "Рекордные спортивные результаты", "Переговоры и важные встречи"]
                        )

                        phaseCard(
                            phase: .luteal,
                            emoji: "🌙",
                            badge: "Фаза уюта и завершения дел",
                            days: "Дни 17–28+",
                            color: CyclePhase.luteal.color,
                            description: "Лютеиновая фаза. Замедление ритма — уют, завершение дел, заземление и бережность к эмоциям. Тело требует больше тепла и питательных веществ.",
                            tips: ["Наведение порядка, закрытие хвостов", "Мягкие тренировки, пилатес, растяжка", "Сложные углеводы, магний, уютный отдых"]
                        )

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Фазы цикла и состояния")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Понятно ✨") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFB7185))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func phaseCard(
        phase: CyclePhase,
        emoji: String,
        badge: String,
        days: String,
        color: Color,
        description: String,
        tips: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Text(emoji).font(.system(size: 20))
                    Text(phase.displayNameRu)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                }

                Spacer()

                Text(days)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(badge)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)

            Text(description)
                .font(.system(size: 13))
                .foregroundStyle(isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569))
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(color)
                        Text(tip)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color(hex: 0x1E293B) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.35), lineWidth: 1.2)
                )
                .shadow(color: color.opacity(0.10), radius: 6, y: 2)
        )
    }
}
