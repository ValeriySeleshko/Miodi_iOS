//
//  DiaryPinModalView.swift
//  Plan4U_iOS
//
//  PIN Code & Biometric Lock for Diary privacy matching Android DiaryPinModal.kt.
//

import SwiftUI
import LocalAuthentication

public enum DiaryPinMode {
    case enterToUnlock
    case enterToDisable
    case createNewPin
}

public struct DiaryPinModalView: View {
    public var mode: DiaryPinMode = .enterToUnlock
    public var onSuccess: () -> Void
    public var onDismiss: () -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("diary_pin_code") private var savedPinCode: String = ""
    @AppStorage("diary_pin_enabled") private var isPinEnabled: Bool = false

    @State private var currentPinInput: String = ""
    @State private var firstPinStepInput: String = ""
    @State private var isConfirmingStep: Bool = false
    @State private var errorMessage: String? = nil
    @State private var shakeOffset: CGFloat = 0.0

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(
        mode: DiaryPinMode = .enterToUnlock,
        onSuccess: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.mode = mode
        self.onSuccess = onSuccess
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            (isDark ? Color(hex: 0x121620) : Color(hex: 0xF7F4EE))
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header Bar with Close button
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // Lock icon badge
                ZStack {
                    Circle()
                        .fill(theme.currentAccent.primary.opacity(isDark ? 0.2 : 0.12))
                        .frame(width: 74, height: 74)

                    Image(systemName: mode == .enterToUnlock ? "lock.fill" : (mode == .createNewPin ? "key.fill" : "lock.open.fill"))
                        .font(.system(size: 30))
                        .foregroundStyle(theme.currentAccent.primary)
                }

                // Title & Subtitle
                VStack(spacing: 6) {
                    Text(titleText)
                        .font(.title3.bold())
                        .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))

                    Text(subtitleText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // 4 PIN Dots Indicator
                HStack(spacing: 18) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index < currentPinInput.count ? theme.currentAccent.primary : (isDark ? Color(hex: 0x2E3547) : Color(hex: 0xDDD6C8)))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(index < currentPinInput.count ? theme.currentAccent.primary : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(index < currentPinInput.count ? 1.15 : 1.0)
                            .animation(.spring(response: 0.25), value: currentPinInput.count)
                    }
                }
                .offset(x: shakeOffset)
                .padding(.vertical, 8)

                if let err = errorMessage {
                    Text(err)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: 0xEF4444))
                        .transition(.opacity)
                }

                Spacer()

                // Number Keypad (1-9, FaceID, 0, Backspace)
                keypadGrid
                    .padding(.horizontal, 36)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            if mode == .enterToUnlock && !savedPinCode.isEmpty {
                tryBiometricUnlock()
            }
        }
    }

    // MARK: - Keypad Grid

    private var keypadGrid: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { row in
                HStack(spacing: 24) {
                    ForEach(1...3, id: \.self) { col in
                        let digit = "\(row * 3 + col)"
                        keypadButton(label: digit) {
                            appendDigit(digit)
                        }
                    }
                }
            }

            HStack(spacing: 24) {
                // Biometrics (Face ID) or Empty
                if mode == .enterToUnlock {
                    Button {
                        tryBiometricUnlock()
                    } label: {
                        Image(systemName: "faceid")
                            .font(.system(size: 24))
                            .foregroundStyle(theme.currentAccent.primary)
                            .frame(width: 72, height: 72)
                            .background(
                                Circle()
                                    .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                            )
                    }
                } else {
                    Spacer().frame(width: 72, height: 72)
                }

                // Zero
                keypadButton(label: "0") {
                    appendDigit("0")
                }

                // Backspace
                Button {
                    deleteDigit()
                } label: {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20))
                        .foregroundStyle(isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155))
                        .frame(width: 72, height: 72)
                        .background(
                            Circle()
                                .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                        )
                }
            }
        }
    }

    private func keypadButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E2433))
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 4, x: 0, y: 2)
                )
        }
    }

    // MARK: - Logic

    private var titleText: String {
        switch mode {
        case .enterToUnlock:
            return "Вход в дневник"
        case .enterToDisable:
            return "Отключение пароля"
        case .createNewPin:
            return isConfirmingStep ? "Подтвердите PIN-код" : "Придумайте PIN-код"
        }
    }

    private var subtitleText: String {
        switch mode {
        case .enterToUnlock:
            return "Введите 4 цифры для доступа к записям"
        case .enterToDisable:
            return "Введите текущий пароль для снятия защиты"
        case .createNewPin:
            return isConfirmingStep ? "Введите 4 цифры ещё раз" : "4 цифры для защиты личных записей"
        }
    }

    private func appendDigit(_ digit: String) {
        guard currentPinInput.count < 4 else { return }
        currentPinInput.append(digit)
        MiodiHapticFeedback.lightClick()
        errorMessage = nil

        if currentPinInput.count == 4 {
            handlePinCompletion()
        }
    }

    private func deleteDigit() {
        guard !currentPinInput.isEmpty else { return }
        currentPinInput.removeLast()
        MiodiHapticFeedback.lightClick()
        errorMessage = nil
    }

    private func handlePinCompletion() {
        switch mode {
        case .enterToUnlock:
            if currentPinInput == savedPinCode || savedPinCode.isEmpty {
                MiodiHapticFeedback.success()
                onSuccess()
                dismiss()
            } else {
                triggerError(message: "Неверный PIN-код")
            }

        case .enterToDisable:
            if currentPinInput == savedPinCode {
                savedPinCode = ""
                isPinEnabled = false
                MiodiHapticFeedback.success()
                onSuccess()
                dismiss()
            } else {
                triggerError(message: "Неверный текущий PIN-код")
            }

        case .createNewPin:
            if !isConfirmingStep {
                firstPinStepInput = currentPinInput
                currentPinInput = ""
                isConfirmingStep = true
                MiodiHapticFeedback.selection()
            } else {
                if currentPinInput == firstPinStepInput {
                    savedPinCode = currentPinInput
                    isPinEnabled = true
                    MiodiHapticFeedback.success()
                    onSuccess()
                    dismiss()
                } else {
                    triggerError(message: "PIN-коды не совпадают")
                    isConfirmingStep = false
                    firstPinStepInput = ""
                }
            }
        }
    }

    private func triggerError(message: String) {
        errorMessage = message
        MiodiHapticFeedback.warning()
        withAnimation(.default) {
            shakeOffset = -15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = 15 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.default) { shakeOffset = -8 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.default) { shakeOffset = 0 }
                    currentPinInput = ""
                }
            }
        }
    }

    private func tryBiometricUnlock() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Разблокировка дневника Miodi") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        MiodiHapticFeedback.success()
                        onSuccess()
                        dismiss()
                    }
                }
            }
        }
    }
}
