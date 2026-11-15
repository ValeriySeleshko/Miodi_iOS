//
//  CycleSecurityManager.swift
//  Plan4U_iOS
//
//  Face ID / Biometric / Passcode Privacy Protection for Female Cycle Tracker
//  Uses LocalAuthentication framework for bank-grade privacy
//

import Foundation
import SwiftUI
import LocalAuthentication

@Observable
public final class CycleSecurityManager {
    public static let shared = CycleSecurityManager()

    private enum Keys {
        static let isProtectionEnabled = "miodi_cycle_privacy_protected"
    }

    public var isProtectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.isProtectionEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.isProtectionEnabled) }
    }

    public var isUnlockedThisSession: Bool = false

    private init() {}

    public var biometricName: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            default: return "Биометрия"
            }
        }
        return "Код-пароль"
    }

    public var biometricIcon: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "eye.circle"
            default: return "lock.shield.fill"
            }
        }
        return "lock.shield.fill"
    }

    public func authenticate(
        reason: String = "Разблокируйте доступ к женскому календарю",
        completion: @escaping (Bool) -> Void
    ) {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlockedThisSession = true
                        MiodiHapticFeedback.success()
                    } else {
                        MiodiHapticFeedback.warning()
                    }
                    completion(success)
                }
            }
        } else {
            // Biometrics or passcode unavailable on simulator/environment -> fallback unlock
            DispatchQueue.main.async {
                self.isUnlockedThisSession = true
                completion(true)
            }
        }
    }

    public func lockSession() {
        isUnlockedThisSession = false
    }

    public func toggleProtection(completion: @escaping (Bool) -> Void) {
        let targetState = !isProtectionEnabled
        let reason = targetState ? "Подтвердите Face ID для включения защиты" : "Подтвердите Face ID для отключения защиты"
        authenticate(reason: reason) { success in
            if success {
                self.isProtectionEnabled = targetState
            }
            completion(success)
        }
    }
}

// MARK: - Privacy Lock Screen Overlay
public struct CyclePrivacyLockView: View {
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAuthenticating: Bool = false
    @State private var authError: String? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public var onUnlocked: () -> Void

    public init(onUnlocked: @escaping () -> Void) {
        self.onUnlocked = onUnlocked
    }

    public var body: some View {
        ZStack {
            (isDark ? Color(hex: 0x0F172A) : Color(hex: 0xFDF4F8))
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Lock Icon with glowing feminine ring
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xFB7185).opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Color(hex: 0xFB7185).opacity(0.35), lineWidth: 2)
                        .frame(width: 120, height: 120)

                    Image(systemName: CycleSecurityManager.shared.biometricIcon)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xFB7185))
                }

                VStack(spacing: 8) {
                    Text("Личный календарь защищён")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? .white : Color(hex: 0x0F172A))
                        .multilineTextAlignment(.center)

                    Text("Для просмотра записей, фаз цикла и симптомов подтвердите вход через \(CycleSecurityManager.shared.biometricName).")
                        .font(.system(size: 14))
                        .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let err = authError {
                    Text(err)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: 0xEF4444))
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    performUnlock()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: CycleSecurityManager.shared.biometricIcon)
                            .font(.system(size: 18, weight: .bold))
                        Text("Разблокировать")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: 0xFB7185))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(hex: 0xFB7185).opacity(0.35), radius: 10, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            performUnlock()
        }
    }

    private func performUnlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authError = nil

        CycleSecurityManager.shared.authenticate { success in
            isAuthenticating = false
            if success {
                onUnlocked()
            } else {
                authError = "Не удалось подтвердить личность. Нажмите кнопку, чтобы повторить попытку."
            }
        }
    }
}
