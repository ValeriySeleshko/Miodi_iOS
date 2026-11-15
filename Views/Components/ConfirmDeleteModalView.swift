//
//  ConfirmDeleteModalView.swift
//  Plan4U_iOS
//
//  Exact 100% replica of Android ConfirmDeleteModal.kt (matching baseline 38_confirm_modal.png).
//  Soft circular icon container, rose accent border, elastic spring physics, and haptic feedback.
//

import SwiftUI

public struct ConfirmDeleteModalView: View {
    public var title: String = "Удалить закладку?"
    public var message: String = "Вы уверены? Все задачи и записи внутри этой закладки будут удалены безвозвратно."
    public var confirmButtonTitle: String = "Удалить"
    public var cancelButtonTitle: String = "Отмена"
    public var onCancel: () -> Void = {}
    public var onConfirm: () -> Void = {}

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(
        title: String = "Удалить закладку?",
        message: String = "Вы уверены? Все задачи и записи внутри этой закладки будут удалены безвозвратно.",
        confirmButtonTitle: String = "Удалить",
        cancelButtonTitle: String = "Отмена",
        onCancel: @escaping () -> Void = {},
        onConfirm: @escaping () -> Void = {}
    ) {
        self.title = title
        self.message = message
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag handle with accent dot
            Capsule()
                .fill(isDark ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Soft circular icon container (38_confirm_modal.png)
            ZStack {
                Circle()
                    .fill(isDark ? Color(hex: 0x2E1925) : Color(hex: 0xFFF1F2))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: 0xFECDD3), lineWidth: 2)
                    )

                Text("🗑️")
                    .font(.system(size: 32))
            }
            .padding(.bottom, 18)

            // Title
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            // Message
            Text(message)
                .font(.system(size: 13.5))
                .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)

            // Action Buttons: [Отмена] [Удалить]
            HStack(spacing: 12) {
                // Cancel Button
                Button {
                    MiodiHapticFeedback.lightClick()
                    onCancel()
                } label: {
                    Text(cancelButtonTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x475569))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                // Delete Destructive Button
                Button {
                    MiodiHapticFeedback.warning()
                    onConfirm()
                } label: {
                    Text(confirmButtonTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: 0xEF4444))
                                .shadow(color: Color(hex: 0xEF4444).opacity(0.35), radius: 6, x: 0, y: 3)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
        .presentationDetents([.height(310)])
        .presentationDragIndicator(.hidden)
    }
}
