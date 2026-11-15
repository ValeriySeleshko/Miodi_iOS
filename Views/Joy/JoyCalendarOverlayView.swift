//
//  JoyCalendarOverlayView.swift
//  Plan4U_iOS
//
//  Joy indicator overlay for week days bar and month calendar.
//  Matching Android JoyCalendarOverlay.kt.
//

import SwiftUI

public struct JoyCalendarDayBadgeView: View {
    public let joysCount: Int
    public let dominantMoodEmoji: String?

    public init(joysCount: Int, dominantMoodEmoji: String? = nil) {
        self.joysCount = joysCount
        self.dominantMoodEmoji = dominantMoodEmoji
    }

    public var body: some View {
        if joysCount > 0 {
            HStack(spacing: 2) {
                Text(dominantMoodEmoji ?? "☀️")
                    .font(.system(size: 9))
                if joysCount > 1 {
                    Text("\(joysCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(hex: 0xD97706))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(
                Capsule()
                    .fill(Color(hex: 0xFEF3C7))
                    .overlay(Capsule().stroke(Color(hex: 0xF59E0B).opacity(0.5), lineWidth: 0.5))
            )
            .shadow(color: Color(hex: 0xF59E0B).opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}
