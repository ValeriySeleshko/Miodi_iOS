//
//  NoSpendDayModalView.swift
//  Plan4U_iOS
//
//  Zero-Spend Day confirmation dialog & Trophy Claim.
//  100% pixel, color and text match with Android NoSpendDayDialog.kt.
//

import SwiftUI

public struct NoSpendDayModalView: View {
    public let dateStr: String
    public let isDarkTheme: Bool
    public let onConfirmNoSpend: () -> Void
    public let onAddExpense: () -> Void
    public let onDismiss: () -> Void

    public init(
        dateStr: String,
        isDarkTheme: Bool = false,
        onConfirmNoSpend: @escaping () -> Void,
        onAddExpense: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.dateStr = dateStr
        self.isDarkTheme = isDarkTheme
        self.onConfirmNoSpend = onConfirmNoSpend
        self.onAddExpense = onAddExpense
        self.onDismiss = onDismiss
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = formatter.date(from: dateStr) {
            let out = DateFormatter()
            out.locale = Locale(identifier: "ru_RU")
            out.dateFormat = "d MMMM"
            return out.string(from: d)
        }
        return dateStr
    }

    private var cardBg: Color {
        isDarkTheme ? Color(hex: 0x161A24) : Color(hex: 0xFFFDF8)
    }

    private var textPrimary: Color {
        isDarkTheme ? Color(hex: 0xF1F5F9) : Color(hex: 0x0F172A)
    }

    private var textSecondary: Color {
        isDarkTheme ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B)
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 0) {
                // Top Close button
                HStack {
                    Spacer()
                    Button {
                        MiodiHapticFeedback.lightClick()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(textSecondary)
                            .frame(width: 32, height: 32)
                            .background(isDarkTheme ? Color(hex: 0x334155).opacity(0.6) : Color(hex: 0xF1F5F9))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                VStack(spacing: 16) {
                    // Glowing Trophy Icon Badge
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: 0xFEF3C7),
                                        Color(hex: 0xFDE68A),
                                        Color(hex: 0xF59E0B).opacity(0.25)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 36
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: 0xF59E0B).opacity(0.7), lineWidth: 1.5)
                            )

                        Text("🏆")
                            .font(.system(size: 36))
                    }

                    // Title
                    Text("День без трат?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("За день (\(formattedDate)) не записано ни одного расхода. Удалось сберечь бюджет или забыли внести запись?")
                        .font(.system(size: 13.5))
                        .lineSpacing(4)
                        .foregroundStyle(textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Spacer().frame(height: 8)

                    // 1. Primary Button: "День без растрат! 🏆 (+2 🐾)"
                    Button {
                        MiodiHapticFeedback.success()
                        onConfirmNoSpend()
                    } label: {
                        HStack(spacing: 6) {
                            Text("День без растрат! 🏆 (+2 🐾)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0xF59E0B), Color(hex: 0xD97706)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color(hex: 0xF59E0B).opacity(0.35), radius: 6, x: 0, y: 3)
                    }

                    // 2. Secondary Button: "Внести расход за вчера ✍️"
                    Button {
                        MiodiHapticFeedback.lightClick()
                        onAddExpense()
                    } label: {
                        Text("Внести расход ✍️")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isDarkTheme ? Color(hex: 0x1E2433) : Color(hex: 0xF8FAFC))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(isDarkTheme ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0), lineWidth: 1)
                            )
                    }

                    // 3. Tertiary: "Сделаю записи позже"
                    Button {
                        MiodiHapticFeedback.lightClick()
                        onDismiss()
                    } label: {
                        Text("Сделаю записи позже")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(textSecondary)
                            .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: 360)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        isDarkTheme ? Color(hex: 0xF59E0B).opacity(0.45) : Color(hex: 0xF59E0B).opacity(0.35),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
    }
}
