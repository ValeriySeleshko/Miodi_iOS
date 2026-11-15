//
//  JoyStampView.swift
//  Plan4U_iOS
//
//  Joy Stamp / Paper Note Sticker Component matching Android JoySticker.kt & JoyStamp.kt.
//  Renders authentic paper note sticker with handwritten auto-sized text,
//  mood emoji, and long-press context actions.
//

import SwiftUI

public struct JoyStampView: View {
    public let joy: JoyItem
    public var size: CGFloat = 145
    public var onLongPress: (() -> Void)?
    public var onTap: (() -> Void)?

    @Environment(MiodiThemeManager.self) private var theme

    public init(
        joy: JoyItem,
        size: CGFloat = 145,
        onLongPress: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.joy = joy
        self.size = size
        self.onLongPress = onLongPress
        self.onTap = onTap
    }

    private var naturalRotation: Double {
        Double((joy.id.hashValue % 9) - 4) * 0.8
    }

    public var body: some View {
        ZStack {
            // Realistic paper note background
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xFFFDF0),
                            Color(hex: 0xFFF8E6),
                            Color(hex: 0xFFF2D6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: 0xF59E0B).opacity(0.3), radius: 8, x: 0, y: 3)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Faint notebook lines
            VStack(spacing: size * 0.12) {
                ForEach(0..<4) { _ in
                    Divider().background(Color(hex: 0xE6D5C3).opacity(0.4))
                }
            }
            .padding(size * 0.12)

            // Content
            VStack(spacing: 4) {
                Text(JoyMoodCatalog.resolveMoodEmoji(from: joy.mood))
                    .font(.system(size: size * 0.18))

                Text(joy.text)
                    .font(.system(size: max(11, size * 0.10), weight: .medium, design: .serif))
                    .foregroundStyle(Color(hex: 0x1C1917))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, size * 0.12)
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(naturalRotation))
        .onTapGesture {
            onTap?()
        }
        .onLongPressGesture {
            MiodiHapticFeedback.taskComplete()
            onLongPress?()
        }
    }
}
