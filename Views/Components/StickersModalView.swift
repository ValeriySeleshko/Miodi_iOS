//
//  StickersModalView.swift
//  Plan4U_iOS
//
//  Sticker Catalog Bottom Sheet matching Android StickersModal.kt.
//  Allows browsing stickers by category and tapping to place them directly onto the notebook page.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

public struct StickersModalView: View {
    public var tabId: String
    public var dateStr: String = ""
    public var onDismiss: () -> Void = {}
    public var onStickerSelected: (PageStickerItem) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: StickerCategory = .cats
    @State private var customNoteText: String = ""

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public enum StickerCategory: String, CaseIterable, Identifiable {
        case cats = "Котики"
        case sweets = "Сладости"
        case flowers = "Цветы"
        case mood = "Настроение"
        case notes = "Заметки"
        case icons = "Символы"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .cats: return "🐱"
            case .sweets: return "🍩"
            case .flowers: return "🌸"
            case .mood: return "✨"
            case .notes: return "📌"
            case .icons: return "🎨"
            }
        }

        public var items: [String] {
            switch self {
            case .cats:
                return ["🐱", "😸", "😻", "🐾", "🐈", "🐈‍⬛", "🧶", "🐟", "🍼", "💤", "😽", "😺"]
            case .sweets:
                return ["☕️", "🍵", "🍩", "🍰", "🧁", "🍪", "🥐", "🍓", "🍫", "🧃", "🥞", "🍯"]
            case .flowers:
                return ["🌸", "🌺", "🌼", "🌻", "🌿", "🍀", "🍁", "🍄", "🪴", "🌷", "🌹", "🌱"]
            case .mood:
                return ["✨", "💖", "⭐", "🔥", "🎉", "💡", "🥑", "🎈", "🧸", "📖", "👑", "🚀"]
            case .notes:
                return ["📌", "🏷️", "✏️", "📝", "📎", "💌", "📍", "🎯", "⏰", "📅", "💡", "🔖"]
            case .icons:
                return ["☀️", "🌙", "☁️", "🌈", "💧", "⚡", "🍀", "🥨", "🎨", "🎵", "🔮", "💎"]
            }
        }
    }

    public init(
        tabId: String,
        dateStr: String = "",
        onDismiss: @escaping () -> Void = {},
        onStickerSelected: @escaping (PageStickerItem) -> Void = { _ in }
    ) {
        self.tabId = tabId
        self.dateStr = dateStr
        self.onDismiss = onDismiss
        self.onStickerSelected = onStickerSelected
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(isDark ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                // Header
                HStack {
                    Text("Стикеры блокнота")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isDark ? MiodiStaticColors.darkTextPrimary : Color(hex: 0x0F172A))

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Circle()
                            .fill(isDark ? Color(hex: 0x334155) : Color(hex: 0xF1F5F9))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("✕")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Category Chips Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(StickerCategory.allCases) { cat in
                            let isSel = (selectedCategory == cat)
                            Button {
                                MiodiHapticFeedback.selection()
                                selectedCategory = cat
                            } label: {
                                HStack(spacing: 5) {
                                    Text(cat.icon)
                                        .font(.system(size: 14))
                                    Text(cat.rawValue)
                                        .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(
                                            isSel
                                                ? theme.currentAccent.primary
                                                : (isDark ? Color(hex: 0x1E293B) : Color(hex: 0xF1F5F9))
                                        )
                                )
                                .foregroundStyle(
                                    isSel
                                        ? Color.white
                                        : (isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x475569))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

                // Optional Quick Note text for sticker
                HStack(spacing: 8) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: 0x94A3B8))

                    TextField("Подпись к стикеру (необязательно)", text: $customNoteText)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDark ? Color(hex: 0x1E293B) : Color(hex: 0xF8FAFC))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Stickers Grid (4 columns)
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                        ForEach(selectedCategory.items, id: \.self) { item in
                            Button {
                                addStickerToPage(asset: item)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isDark ? Color(hex: 0x1E293B) : Color(hex: 0xF8FAFC))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isDark ? Color(hex: 0x334155) : Color(hex: 0xE2E8F0), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)

                                    if item.contains("/") || item.hasSuffix(".webp") || item.hasSuffix(".png") {
                                        #if canImport(UIKit)
                                        if let uiImg = UIImage(named: item) ?? UIImage(contentsOfFile: item) {
                                            Image(uiImage: uiImg)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 48, height: 48)
                                        } else {
                                            Text(item)
                                                .font(.system(size: 38))
                                        }
                                        #else
                                        Text(item)
                                            .font(.system(size: 38))
                                        #endif
                                    } else {
                                        Text(item)
                                            .font(.system(size: 38))
                                    }
                                }
                                .frame(height: 72)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(isDark ? MiodiStaticColors.darkCardBg : Color.white)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func addStickerToPage(asset: String) {
        MiodiHapticFeedback.success()
        let note = customNoteText.trimmingCharacters(in: .whitespacesAndNewlines)

        let newSticker = PageStickerItem(
            tabId: tabId,
            date: dateStr,
            assetPath: asset,
            xOffsetDp: Double.random(in: 80...240),
            yOffsetDp: Double.random(in: 120...320),
            rotation: Double.random(in: -10...10),
            scale: 1.0,
            isFlipped: false,
            alpha: 0.95,
            text: note.isEmpty ? nil : note
        )

        modelContext.insert(newSticker)
        try? modelContext.save()

        onStickerSelected(newSticker)
        onDismiss()
    }
}
