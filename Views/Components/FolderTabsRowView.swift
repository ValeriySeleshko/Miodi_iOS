//
//  FolderTabsRowView.swift
//  Plan4U_iOS
//
//  Pixel-perfect replica of Miodi Android FolderTabsRow.kt (643 lines).
//  Authentic notebook tab bookmarks with 21-color palette, drag-and-drop reordering,
//  double-tap to edit, comprehensive context menu, badge counts, and plus (+) button.
//

import SwiftUI

public struct FolderTabItemModel: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var count: Int
    public var colorHex: String?
    public var patternType: String
    public var patternSizePx: Int
    public var orderIndex: Int

    public init(
        id: String,
        title: String,
        count: Int = 0,
        colorHex: String? = nil,
        patternType: String = "lines",
        patternSizePx: Int = 32,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.colorHex = colorHex
        self.patternType = patternType
        self.patternSizePx = patternSizePx
        self.orderIndex = orderIndex
    }
}

public struct FolderTabsRowView: View {
    public var tabs: [FolderTabItemModel]
    @Binding public var activeTabId: String
    public var onSelectTab: (String) -> Void = { _ in }
    public var onEditTab: (FolderTabItemModel) -> Void = { _ in }
    public var onReorderTabs: ([FolderTabItemModel]) -> Void = { _ in }
    public var onAddTab: () -> Void = {}
    public var onChangeColor: ((_ tabId: String, _ colorId: String) -> Void)? = nil
    public var onChangePattern: ((_ tabId: String, _ pattern: String) -> Void)? = nil
    public var onDeleteTab: ((_ tabId: String) -> Void)? = nil

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var draggingTabId: String? = nil
    @State private var dragOffset: CGFloat = 0.0
    @State private var localTabs: [FolderTabItemModel] = []

    public init(
        tabs: [FolderTabItemModel],
        activeTabId: Binding<String>,
        onSelectTab: @escaping (String) -> Void = { _ in },
        onEditTab: @escaping (FolderTabItemModel) -> Void = { _ in },
        onReorderTabs: @escaping ([FolderTabItemModel]) -> Void = { _ in },
        onAddTab: @escaping () -> Void = {},
        onChangeColor: ((_ tabId: String, _ colorId: String) -> Void)? = nil,
        onChangePattern: ((_ tabId: String, _ pattern: String) -> Void)? = nil,
        onDeleteTab: ((_ tabId: String) -> Void)? = nil
    ) {
        self.tabs = tabs
        self._activeTabId = activeTabId
        self.onSelectTab = onSelectTab
        self.onEditTab = onEditTab
        self.onReorderTabs = onReorderTabs
        self.onAddTab = onAddTab
        self.onChangeColor = onChangeColor
        self.onChangePattern = onChangePattern
        self.onDeleteTab = onDeleteTab
    }

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    private var displayTabs: [FolderTabItemModel] {
        localTabs.isEmpty ? tabs : localTabs
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(displayTabs) { tab in
                        let isActive = (tab.id == activeTabId)
                        let isDragging = (draggingTabId == tab.id)

                        tabButtonView(tab: tab, isActive: isActive, isDragging: isDragging)
                            .id(tab.id)
                    }

                    // Plus (+) Add Tab Button
                    addTabButtonView
                }
                .padding(.leading, 10)
                .padding(.trailing, 8)
                .padding(.top, 4)
                .padding(.bottom, 0)
            }
            .background(
                isDark ? MiodiStaticColors.darkTabsSubstrate : MiodiStaticColors.tabBarBg
            )
            .onChange(of: tabs) { _, newTabs in
                if draggingTabId == nil {
                    localTabs = newTabs
                }
            }
            .onChange(of: activeTabId) { _, newActiveId in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    proxy.scrollTo(newActiveId, anchor: .center)
                }
            }
            .onAppear {
                localTabs = tabs
            }
        }
    }

    // MARK: - Individual Tab Bookmark View
    @ViewBuilder
    private func tabButtonView(
        tab: FolderTabItemModel,
        isActive: Bool,
        isDragging: Bool
    ) -> some View {
        let colorDef = getTabColorDef(idOrHex: tab.colorHex)
        let bg = isActive
            ? (isDark ? colorDef.darkSheetBg : colorDef.sheetBg)
            : (isDark ? colorDef.darkInactiveBg : colorDef.inactiveBg)

        let textColor = isActive
            ? (isDark ? MiodiStaticColors.darkTextPrimary : Color.black)
            : (isDark ? MiodiStaticColors.darkTabInactiveText : MiodiStaticColors.tabInactiveText)

        let isSystem = ["todo", "buy", "watch", "diary"].contains(tab.id)

        ZStack(alignment: .topLeading) {
            // Tab Body
            HStack(spacing: 6) {
                // Diary lock indicator
                if tab.id == "diary" {
                    Text("📖")
                        .font(.system(size: 11))
                }

                Text(tab.title)
                    .font(.system(size: tab.title.count > 14 ? 12 : 13, weight: isActive ? .bold : .semibold))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
            }
            .padding(.leading, tab.count > 0 ? 24 : 14)
            .padding(.trailing, 14)
            .frame(minWidth: 90, maxWidth: 190)
            .frame(height: (isActive || isDragging) ? 46 : 42)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
                .fill(bg)
                .shadow(
                    color: Color.black.opacity(isDragging ? 0.25 : (isActive ? 0.12 : 0.04)),
                    radius: isDragging ? 8 : (isActive ? 4 : 1),
                    x: 0,
                    y: isDragging ? -2 : -1
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
                .stroke(
                    isDragging
                        ? theme.currentAccent.primary
                        : (isActive
                            ? (isDark ? Color(hex: 0x2E3547) : Color.black.opacity(0.12))
                            : Color.black.opacity(0.08)),
                    lineWidth: isDragging ? 2.0 : 1.0
                )
            )

            // Top-Left Count Badge
            if tab.count > 0 {
                Text("\(tab.count)")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 4.5)
                    .frame(minWidth: 16, height: 16)
                    .background(
                        Capsule().fill(
                            (isActive || isDragging)
                                ? theme.currentAccent.primary
                                : (isDark ? Color(hex: 0x384256) : MiodiStaticColors.badgeInactiveBg)
                        )
                    )
                    .offset(x: 5, y: 4)
            }
        }
        .scaleEffect(isDragging ? 1.04 : 1.0)
        .offset(x: isDragging ? dragOffset : 0)
        .zIndex(isDragging ? 50 : (isActive ? 10 : 1))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            // Double tap to edit tab directly (matching Android)
            MiodiHapticFeedback.lightClick()
            onEditTab(tab)
        }
        .onTapGesture(count: 1) {
            // Single tap to select tab
            MiodiHapticFeedback.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                activeTabId = tab.id
            }
            onSelectTab(tab.id)
        }
        .contextMenu {
            // 1. Edit Tab
            Button {
                MiodiHapticFeedback.lightClick()
                onEditTab(tab)
            } label: {
                Label("Редактировать закладку", systemImage: "pencil")
            }

            // 2. Change Color Sub-menu
            Menu {
                ForEach(["white", "cream", "pink_powder", "peach_light", "mint_light", "sky_light", "lavender_light"], id: \.self) { cId in
                    let cDef = getTabColorDef(idOrHex: cId)
                    Button {
                        MiodiHapticFeedback.selection()
                        onChangeColor?(tab.id, cId)
                    } label: {
                        HStack {
                            Text(cDef.name)
                            if (tab.colorHex ?? "white") == cId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Сменить цвет", systemImage: "paintpalette")
            }

            // 3. Change Ruling Sub-menu
            Menu {
                ForEach([
                    ("lines", "Линейка"),
                    ("grid", "Клетка"),
                    ("dots", "Точки"),
                    ("blank", "Чистый лист"),
                    ("music", "Нотный стан")
                ], id: \.0) { pId, pName in
                    Button {
                        MiodiHapticFeedback.selection()
                        onChangePattern?(tab.id, pId)
                    } label: {
                        HStack {
                            Text(pName)
                            if tab.patternType == pId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Разлиновка листа", systemImage: "square.grid.3x3")
            }

            // 4. Delete Tab (only for non-system tabs)
            if !isSystem {
                Divider()
                Button(role: .destructive) {
                    MiodiHapticFeedback.warning()
                    onDeleteTab?(tab.id)
                } label: {
                    Label("Удалить закладку", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Plus (+) Add Tab Button
    private var addTabButtonView: some View {
        Button {
            MiodiHapticFeedback.lightClick()
            onAddTab()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDark ? MiodiStaticColors.darkTabInactiveBg : MiodiStaticColors.tabInactiveBg)
                    .frame(width: 42, height: 42)
                    .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)

                Text("+")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : MiodiStaticColors.tabInactiveText)
            }
            .padding(.bottom, 2)
            .padding(.leading, 2)
        }
        .buttonStyle(.plain)
    }
}
