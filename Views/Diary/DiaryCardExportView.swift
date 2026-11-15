//
//  DiaryCardExportView.swift
//  Plan4U_iOS
//
//  Aesthetic postcard & stationery export generator for diary entries.
//

import SwiftUI
import UIKit

public struct DiaryCardExportView: View {
    public let entry: DiaryItem
    public var onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var cardPaperTheme: CardPaperStyle = .cream
    @State private var showDoodles: Bool = true
    @State private var showStamp: Bool = true
    @State private var renderedCardImage: UIImage? = nil
    @State private var isSharingPresented: Bool = false
    @State private var isSavedToPhotosAlert: Bool = false

    public enum CardPaperStyle: String, CaseIterable, Identifiable {
        case cream = "Кремовая"
        case blush = "Розовая"
        case kraft = "Крафт"
        case night = "Ночь"

        public var id: String { rawValue }

        public var bgColor: Color {
            switch self {
            case .cream: return Color(hex: 0xFDFBF5)
            case .blush: return Color(hex: 0xFDF2F4)
            case .kraft: return Color(hex: 0xF4EBE1)
            case .night: return Color(hex: 0x1A1F2C)
            }
        }

        public var textColor: Color {
            switch self {
            case .night: return Color(hex: 0xF1F5F9)
            default: return Color(hex: 0x2A2118)
            }
        }

        public var lineColor: Color {
            switch self {
            case .night: return Color.white.opacity(0.08)
            default: return Color(hex: 0x7A634E).opacity(0.15)
            }
        }

        public var isDark: Bool {
            self == .night
        }
    }

    public init(entry: DiaryItem, onClose: @escaping () -> Void = {}) {
        self.entry = entry
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Aesthetic Postcard Preview
                    postcardPreview
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    // Customization Toolbar
                    customizationSection
                        .padding(.horizontal, 20)

                    // Action Buttons: Share & Save
                    actionButtonsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .background(colorScheme == .dark ? Color(hex: 0x0F131A) : Color(hex: 0xF2EFE9))
            .navigationTitle("Открытка из дневника")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        onClose()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isSharingPresented) {
                if let image = renderedCardImage {
                    ActivityView(activityItems: [image, "Запись из личного дневника Miodi"])
                }
            }
            .alert("Открытка сохранена в Фото!", isPresented: $isSavedToPhotosAlert) {
                Button("ОК", role: .cancel) {}
            }
        }
    }

    // MARK: - Postcard Render View

    @ViewBuilder
    private var postcardPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Content Container
            ZStack {
                // Background paper with ruling lines
                cardPaperTheme.bgColor

                // Ruled lines pattern
                Canvas { context, size in
                    let step: CGFloat = 28.0
                    var y: CGFloat = 80.0
                    while y < size.height - 40.0 {
                        var line = Path()
                        line.move(to: CGPoint(x: 24, y: y))
                        line.addLine(to: CGPoint(x: size.width - 24, y: y))
                        context.stroke(line, with: .color(cardPaperTheme.lineColor), lineWidth: 1)
                        y += step
                    }
                }

                // Doodles layer on corners if enabled
                if showDoodles {
                    Canvas { context, size in
                        let ink = cardPaperTheme.isDark ? Color(hex: 0xC084FC).opacity(0.4) : Color(hex: 0xDC687A).opacity(0.45)
                        // Top left doodle: heart
                        DiaryDoodleRenderer.drawDoodle(
                            type: .heartFilled,
                            cx: 32,
                            cy: 32,
                            r: 12,
                            rotationDeg: -12,
                            color: ink,
                            strokeWidth: 1.3,
                            in: &context
                        )
                        // Top right sparkles
                        DiaryDoodleRenderer.drawDoodle(
                            type: .sparkles,
                            cx: size.width - 80,
                            cy: 36,
                            r: 13,
                            rotationDeg: 15,
                            color: ink,
                            strokeWidth: 1.3,
                            in: &context
                        )
                        // Bottom right cat paw
                        DiaryDoodleRenderer.drawDoodle(
                            type: .catPaw,
                            cx: size.width - 34,
                            cy: size.height - 34,
                            r: 13,
                            rotationDeg: 10,
                            color: ink,
                            strokeWidth: 1.3,
                            in: &context
                        )
                        // Bottom left coffee cup
                        DiaryDoodleRenderer.drawDoodle(
                            type: .coffeeCup,
                            cx: 34,
                            cy: size.height - 34,
                            r: 12,
                            rotationDeg: -8,
                            color: ink,
                            strokeWidth: 1.3,
                            in: &context
                        )
                    }
                }

                // Foreground Content
                VStack(alignment: .leading, spacing: 14) {
                    // Header: Date + Postage Stamp
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(friendlyDateString())
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundStyle(cardPaperTheme.textColor)

                            if !entry.time.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10))
                                    Text(entry.time)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundStyle(cardPaperTheme.textColor.opacity(0.65))
                            }
                        }

                        Spacer()

                        // Postage Stamp
                        if showStamp {
                            postageStampBadge
                        }
                    }

                    // Diary Text Body
                    Text(DiaryRichTextEngine.buildAttributedString(
                        text: entry.content,
                        spans: DiaryRichTextEngine.parseSpans(from: entry.formattingJson, maxTextLen: entry.content.count),
                        isDark: cardPaperTheme.isDark,
                        fontSize: 15,
                        fontFamily: .caveat,
                        defaultColor: cardPaperTheme.textColor
                    ))
                    .lineSpacing(7)
                    .padding(.vertical, 8)

                    Spacer(minLength: 20)

                    // Footer Watermark
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("Miodi • Личный дневник")
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                        Spacer()
                    }
                    .foregroundStyle(cardPaperTheme.textColor.opacity(0.45))
                }
                .padding(26)
            }
            .frame(minHeight: 380)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(cardPaperTheme.isDark ? Color.white.opacity(0.12) : Color(hex: 0xE2D5C3), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(cardPaperTheme.isDark ? 0.4 : 0.12), radius: 12, x: 0, y: 5)
        }
    }

    // MARK: - Postage Stamp Badge

    private var postageStampBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "heart.fill")
                .font(.system(size: 12))
                .foregroundStyle(theme.currentAccent.primary)
            Text("MIODI")
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(theme.currentAccent.primary)
            Text("POST")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .foregroundStyle(theme.currentAccent.primary.opacity(0.6))
        )
    }

    // MARK: - Customization Section

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Оформление открытки")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            // Paper Style Picker
            HStack(spacing: 8) {
                ForEach(CardPaperStyle.allCases) { style in
                    Button {
                        cardPaperTheme = style
                        MiodiHapticFeedback.selection()
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(style.bgColor)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            Text(style.rawValue)
                                .font(.system(size: 12, weight: cardPaperTheme == style ? .bold : .regular))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(cardPaperTheme == style ? theme.currentAccent.primary.opacity(0.15) : Color.gray.opacity(0.1))
                        )
                        .foregroundStyle(cardPaperTheme == style ? theme.currentAccent.primary : .primary)
                    }
                }
            }

            // Toggles
            HStack(spacing: 16) {
                Toggle("Дудлы", isOn: $showDoodles)
                    .font(.footnote)
                    .tint(theme.currentAccent.primary)

                Toggle("Марка", isOn: $showStamp)
                    .font(.footnote)
                    .tint(theme.currentAccent.primary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(hex: 0x1A1F2C) : Color.white)
        )
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            // Share button
            Button {
                renderAndShare()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Поделиться открыткой")
                }
                .font(.body.bold())
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.currentAccent.primary)
                )
            }

            HStack(spacing: 10) {
                // Save to Camera Roll
                Button {
                    renderAndSaveToPhotos()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                        Text("Сохранить в Фото")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(hex: 0x222938) : Color.white)
                    )
                }

                // Copy Text
                Button {
                    UIPasteboard.general.string = entry.content
                    MiodiHapticFeedback.success()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Копировать")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(hex: 0x222938) : Color.white)
                    )
                }
            }
        }
    }

    // MARK: - Rendering & Helpers

    @MainActor
    private func renderCardImage() -> UIImage? {
        let card = postcardPreview
            .frame(width: 360)
            .padding(16)
            .background(Color.clear)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private func renderAndShare() {
        MiodiHapticFeedback.lightClick()
        if let image = renderCardImage() {
            self.renderedCardImage = image
            self.isSharingPresented = true
        }
    }

    private func renderAndSaveToPhotos() {
        MiodiHapticFeedback.lightClick()
        if let image = renderCardImage() {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            MiodiHapticFeedback.success()
            isSavedToPhotosAlert = true
        }
    }

    private func friendlyDateString() -> String {
        if let d = Date.from(yyyyMMdd: entry.date) {
            return d.userFriendlyDateString()
        }
        return entry.date
    }
}

// MARK: - UIActivityViewController Bridge

public struct ActivityView: UIViewControllerRepresentable {
    public var activityItems: [Any]
    public var applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
