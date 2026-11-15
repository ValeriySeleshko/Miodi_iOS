//
//  SectionItem.swift
//  Plan4U_iOS
//
//  SwiftData Model matching Android SectionEntity.kt 1-to-1
//

import Foundation
import SwiftData

@Model
public final class SectionItem {
    @Attribute(.unique) public var id: String
    public var title: String
    public var icon: String
    public var tabId: String
    public var orderIndex: Int

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        icon: String = "",
        tabId: String = "",
        orderIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.tabId = tabId
        self.orderIndex = orderIndex
    }
}
