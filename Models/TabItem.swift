//
//  TabItem.swift
//  Plan4U_iOS
//
//  SwiftData Model matching Android TabEntity.kt 1-to-1
//

import Foundation
import SwiftData

@Model
public final class TabItem {
    @Attribute(.unique) public var id: String
    public var title: String
    public var colorHex: String?
    public var patternType: String // lines, grid, dots, blank
    public var patternSizePx: Int
    public var orderIndex: Int

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        colorHex: String? = nil,
        patternType: String = "lines",
        patternSizePx: Int = 32,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.patternType = patternType
        self.patternSizePx = patternSizePx
        self.orderIndex = orderIndex
    }
}
