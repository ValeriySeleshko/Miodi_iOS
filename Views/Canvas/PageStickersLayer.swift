//
//  PageStickersLayer.swift
//  Plan4U_iOS
//
//  Interactive sticker overlay for notebook sheets matching Android InteractiveStickerLayer.kt 1-to-1.
//  Supports free dragging, scaling, rotating, horizontal flipping, water ripples, and deletion.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

public struct PageStickersLayer: View {
    public var tabId: String
    public var dateStr: String = ""
    public var sheetWidth: CGFloat
    public var sheetHeight: CGFloat

    @Environment(\.modelContext) private var modelContext
    @Query private var allStickers: [PageStickerItem]

    @State private var activeStickerId: String? = nil
    @State private var dragOffsets: [String: CGSize] = [:]
    @State private var rippleState: StickerRipple? = nil

    public init(
        tabId: String,
        dateStr: String = "",
        sheetWidth: CGFloat = 360,
        sheetHeight: CGFloat = 600
    ) {
        self.tabId = tabId
        self.dateStr = dateStr
        self.sheetWidth = sheetWidth
        self.sheetHeight = sheetHeight
    }

    private var currentStickers: [PageStickerItem] {
        allStickers.filter { sticker in
            if sticker.tabId != tabId { return false }
            if !dateStr.isEmpty && !sticker.date.isEmpty {
                return sticker.date == dateStr
            }
            return true
        }
    }

    public var body: some View {
        ZStack {
            // Background tap to deselect active sticker
            if activeStickerId != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            activeStickerId = nil
                        }
                    }
            }

            // Water ripple effect on touch / lift
            if let ripple = rippleState {
                StickerWaterRippleView(ripple: ripple) {
                    rippleState = nil
                }
            }

            // Placed Stickers
            ForEach(currentStickers) { sticker in
                let isActive = (activeStickerId == sticker.id)
                let dragOffset = dragOffsets[sticker.id] ?? .zero

                stickerItemView(sticker: sticker, isActive: isActive, dragOffset: dragOffset)
                    .zIndex(isActive ? 30 : 2)
            }
        }
        .frame(width: sheetWidth, height: sheetHeight)
    }

    // MARK: - Individual Sticker Item View
    @ViewBuilder
    private func stickerItemView(
        sticker: PageStickerItem,
        isActive: Bool,
        dragOffset: CGSize
    ) -> some View {
        let baseSize: CGFloat = 88.0
        let visualScale = sticker.scale * (dragOffsets[sticker.id] != nil ? 1.06 : 1.0)
        let curX = CGFloat(sticker.xOffsetDp) + dragOffset.width
        let curY = CGFloat(sticker.yOffsetDp) + dragOffset.height

        ZStack {
            // Main Sticker Graphic
            Group {
                if sticker.assetPath.contains("/") || sticker.assetPath.hasSuffix(".webp") || sticker.assetPath.hasSuffix(".png") {
                    #if canImport(UIKit)
                    if let uiImg = UIImage(named: sticker.assetPath) ?? UIImage(contentsOfFile: sticker.assetPath) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                    } else if let resPath = Bundle.main.path(forResource: sticker.assetPath, ofType: nil),
                              let uiImg = UIImage(contentsOfFile: resPath) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(sticker.assetPath)
                            .resizable()
                            .scaledToFit()
                    }
                    #else
                    Image(sticker.assetPath)
                        .resizable()
                        .scaledToFit()
                    #endif
                } else {
                    // Emoji / Mood Sticker / Text
                    Text(sticker.assetPath)
                        .font(.system(size: 58))
                }
            }
            .frame(width: baseSize, height: baseSize)
            .scaleEffect(x: sticker.isFlipped ? -1.0 : 1.0, y: 1.0)
            .rotationEffect(.degrees(sticker.rotation))
            .opacity(sticker.alpha)

            // Optional note text banner below sticker
            if let text = sticker.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x334155))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.85))
                            .shadow(radius: 1)
                    )
                    .offset(y: baseSize / 2 + 10)
            }

            // Transformation Controls Overlay (Shown when selected)
            if isActive {
                // Bounding frame
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color(hex: 0xEC4899).opacity(0.6),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
                    .frame(width: baseSize + 16, height: baseSize + 16)

                // Top-Left: Scale Handle
                scaleHandleView(sticker: sticker)
                    .offset(x: -(baseSize / 2 + 10), y: -(baseSize / 2 + 10))

                // Top-Right: Rotate Handle
                rotateHandleView(sticker: sticker)
                    .offset(x: (baseSize / 2 + 10), y: -(baseSize / 2 + 10))

                // Bottom-Left: Flip Horizontal Handle
                flipHandleView(sticker: sticker)
                    .offset(x: -(baseSize / 2 + 10), y: (baseSize / 2 + 10))

                // Bottom-Right: Delete Handle
                deleteHandleView(sticker: sticker)
                    .offset(x: (baseSize / 2 + 10), y: (baseSize / 2 + 10))
            }
        }
        .scaleEffect(visualScale)
        .position(x: curX, y: curY)
        .onTapGesture {
            MiodiHapticFeedback.lightClick()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                activeStickerId = (activeStickerId == sticker.id ? nil : sticker.id)
            }
            // Trigger water ripple
            rippleState = StickerRipple(x: curX, y: curY)
        }
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if dragOffsets[sticker.id] == nil {
                        MiodiHapticFeedback.lightClick()
                        activeStickerId = sticker.id
                        rippleState = StickerRipple(x: curX, y: curY)
                    }
                    dragOffsets[sticker.id] = value.translation
                }
                .onEnded { value in
                    let newX = Double(CGFloat(sticker.xOffsetDp) + value.translation.width)
                        .clamped(to: 30...(Double(sheetWidth) - 30))
                    let newY = Double(CGFloat(sticker.yOffsetDp) + value.translation.height)
                        .clamped(to: 40...(Double(sheetHeight) - 40))

                    sticker.xOffsetDp = newX
                    sticker.yOffsetDp = newY
                    try? modelContext.save()

                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        dragOffsets[sticker.id] = nil
                    }
                    MiodiHapticFeedback.lightClick()
                }
        )
    }

    // MARK: - Handles (Scale, Rotate, Flip, Delete)
    @ViewBuilder
    private func scaleHandleView(sticker: PageStickerItem) -> some View {
        Button {
            MiodiHapticFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                if sticker.scale < 0.95 {
                    sticker.scale = 1.0
                } else if sticker.scale < 1.2 {
                    sticker.scale = 1.25
                } else if sticker.scale < 1.45 {
                    sticker.scale = 1.5
                } else if sticker.scale < 1.75 {
                    sticker.scale = 1.8
                } else {
                    sticker.scale = 0.8
                }
            }
            try? modelContext.save()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .overlay(Circle().stroke(Color(hex: 0xEC4899), lineWidth: 1.5))
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: 0xEC4899))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func rotateHandleView(sticker: PageStickerItem) -> some View {
        Button {
            MiodiHapticFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                sticker.rotation = (sticker.rotation + 15.0).truncatingRemainder(dividingBy: 360.0)
            }
            try? modelContext.save()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .overlay(Circle().stroke(Color(hex: 0x0D9488), lineWidth: 1.5))
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0D9488))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func flipHandleView(sticker: PageStickerItem) -> some View {
        Button {
            MiodiHapticFeedback.lightClick()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                sticker.isFlipped.toggle()
            }
            try? modelContext.save()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .overlay(Circle().stroke(Color(hex: 0x3B82F6), lineWidth: 1.5))
                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: 0x3B82F6))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func deleteHandleView(sticker: PageStickerItem) -> some View {
        Button {
            MiodiHapticFeedback.warning()
            withAnimation(.easeOut(duration: 0.2)) {
                if activeStickerId == sticker.id {
                    activeStickerId = nil
                }
                modelContext.delete(sticker)
                try? modelContext.save()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .overlay(Circle().stroke(Color(hex: 0xEF4444), lineWidth: 1.5))
                Image(systemName: "trash.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: 0xEF4444))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sticker Water Ripple
public struct StickerRipple: Equatable {
    public let id = UUID()
    public let x: CGFloat
    public let y: CGFloat
}

public struct StickerWaterRippleView: View {
    public var ripple: StickerRipple
    public var onFinished: () -> Void = {}

    @State private var radius: CGFloat = 16.0
    @State private var opacity: Double = 0.55

    public var body: some View {
        Circle()
            .strokeBorder(Color(hex: 0xEC4899).opacity(opacity), lineWidth: 2)
            .frame(width: radius * 2, height: radius * 2)
            .position(x: ripple.x, y: ripple.y)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) {
                    radius = 54.0
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) {
                    onFinished()
                }
            }
            .allowsHitTesting(false)
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
