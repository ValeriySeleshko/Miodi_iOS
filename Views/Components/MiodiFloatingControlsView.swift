//
//  MiodiFloatingControlsView.swift
//  Plan4U_iOS
//
//  1:1 Port of Android Floating Action Controls (BottomControlsBar.kt).
//  Displays:
//  - Floating Cat Speech Bubble
//  - Floating Circle '+' Button (56dp, signature PrimaryMagenta)
//  - Floating Stickers ✨ Button (56dp)
//  - Floating 3D Pop-Out Illustrated Cat Mascot Button (56dp, orange border) with Level Badge
//

import SwiftUI

public struct MiodiFloatingControlsView: View {
    public var catMessage: String?
    public var pet: PetItem?
    public var onAddClick: () -> Void
    public var onStickersClick: () -> Void
    public var onPetClick: () -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public init(
        catMessage: String? = nil,
        pet: PetItem? = nil,
        onAddClick: @escaping () -> Void,
        onStickersClick: @escaping () -> Void,
        onPetClick: @escaping () -> Void
    ) {
        self.catMessage = catMessage
        self.pet = pet
        self.onAddClick = onAddClick
        self.onStickersClick = onStickersClick
        self.onPetClick = onPetClick
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // 1. Floating Speech Bubble
            if let msg = catMessage, !msg.isEmpty {
                Button {
                    MiodiHapticFeedback.lightClick()
                    onPetClick()
                } label: {
                    HStack(spacing: 6) {
                        Text("🐾")
                            .font(.system(size: 12))
                        Text(msg)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E293B))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xFFFBEB))
                            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.1), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isDark ? Color(hex: 0x384256) : Color(hex: 0xF59E0B).opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .transition(.scale.combined(with: .opacity))
            }

            // 2. Action Controls Row: Equal Spacing (space-evenly) matching Android
            HStack {
                // Left: Floating Primary Pink Plus Button (+)
                Button {
                    MiodiHapticFeedback.notebookOpen()
                    onAddClick()
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.currentAccent.primary)
                            .frame(width: 58, height: 58)
                            .shadow(color: theme.currentAccent.primary.opacity(0.4), radius: 8, x: 0, y: 4)

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Center: Stickers Sparkle Button (✨)
                Button {
                    MiodiHapticFeedback.lightClick()
                    onStickersClick()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                            .frame(width: 54, height: 54)
                            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.12), radius: 6, x: 0, y: 3)
                            .overlay(
                                Circle().stroke(Color(hex: 0xE2E8F0).opacity(isDark ? 0.2 : 0.8), lineWidth: 1.5)
                            )

                        Text("✨")
                            .font(.system(size: 24))
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Right: 3D Pop-Out Illustrated Cat Mascot Button with Level Badge
                Button {
                    MiodiHapticFeedback.purr()
                    onPetClick()
                } label: {
                    ZStack {
                        // Background Circular Substrate
                        Circle()
                            .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xFFF7ED))
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.15), radius: 6, x: 0, y: 3)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: 0xF97316), lineWidth: 2)
                            )

                        // 3D Illustrated Mascot (66dp, offset y: -8)
                        MaineCoonIllustratedCatView(
                            colorScheme: pet?.color ?? "ginger",
                            poseId: 21
                        )
                        .frame(width: 68, height: 68)
                        .offset(y: -7)

                        // Pet Level Badge (e.g. "18")
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(pet?.level ?? 1)")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4.5)
                                    .frame(minWidth: 17, height: 17)
                                    .background(Color(hex: 0xF97316))
                                    .clipShape(Capsule())
                                    .shadow(radius: 2)
                                    .offset(x: 4, y: 3)
                            }
                        }
                        .frame(width: 56, height: 56)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }
}
