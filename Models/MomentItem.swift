//
//  MomentItem.swift
//  Plan4U_iOS
//
//  Polaroid Moment item matching Android MomentEntity.kt
//

import Foundation
import SwiftData

@Model
public final class MomentItem {
    @Attribute(.unique) public var id: String
    public var date: String // "yyyy-MM-dd"
    public var photoPath: String
    public var caption: String?
    public var tapeStyle: String // "craft", "pink", "mint", "grid"
    public var rotationDeg: Double
    public var xOffsetDp: Double
    public var yOffsetDp: Double
    public var timestamp: Int64

    public init(
        id: String = UUID().uuidString,
        date: String = "",
        photoPath: String = "",
        caption: String? = nil,
        tapeStyle: String = "craft",
        rotationDeg: Double = -2.5,
        xOffsetDp: Double = 0.0,
        yOffsetDp: Double = 0.0,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.date = date
        self.photoPath = photoPath
        self.caption = caption
        self.tapeStyle = tapeStyle
        self.rotationDeg = rotationDeg
        self.xOffsetDp = xOffsetDp
        self.yOffsetDp = yOffsetDp
        self.timestamp = timestamp
    }
}
