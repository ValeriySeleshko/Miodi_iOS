//
//  TabColors.swift
//  Plan4U_iOS
//
//  Exact 100% replica of Android TabColors.kt (21-color palette for tabs and sheet backgrounds).
//

import SwiftUI

public struct TabColorDef: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let swatchColor: Color
    public let sheetBg: Color
    public let inactiveBg: Color
    public let darkInactiveBg: Color
    public let darkSheetBg: Color

    public init(
        id: String,
        name: String,
        swatchColor: Color,
        sheetBg: Color,
        inactiveBg: Color,
        darkInactiveBg: Color,
        darkSheetBg: Color
    ) {
        self.id = id
        self.name = name
        self.swatchColor = swatchColor
        self.sheetBg = sheetBg
        self.inactiveBg = inactiveBg
        self.darkInactiveBg = darkInactiveBg
        self.darkSheetBg = darkSheetBg
    }
}

public let TAB_PALETTE: [TabColorDef] = [
    // Row 1: Нейтральные, Серые и Лавандовые
    TabColorDef(
        id: "white",
        name: "Белый",
        swatchColor: Color(hex: 0xFFFFFF),
        sheetBg: Color(hex: 0xFFFFFF),
        inactiveBg: Color(hex: 0xE8E4DB),
        darkInactiveBg: Color(hex: 0x1C202D),
        darkSheetBg: Color(hex: 0x131620)
    ),
    TabColorDef(
        id: "cream",
        name: "Кремовый",
        swatchColor: Color(hex: 0xF6F0E2),
        sheetBg: Color(hex: 0xFCF8EE),
        inactiveBg: Color(hex: 0xECE4D2),
        darkInactiveBg: Color(hex: 0x221F1A),
        darkSheetBg: Color(hex: 0x171512)
    ),
    TabColorDef(
        id: "gray_light",
        name: "Светло-серый",
        swatchColor: Color(hex: 0xE2E8F0),
        sheetBg: Color(hex: 0xF1F5F9),
        inactiveBg: Color(hex: 0xDBE1E8),
        darkInactiveBg: Color(hex: 0x1E2430),
        darkSheetBg: Color(hex: 0x141822)
    ),
    TabColorDef(
        id: "gray_slate",
        name: "Пепельный серый",
        swatchColor: Color(hex: 0x94A3B8),
        sheetBg: Color(hex: 0xE2E8F0),
        inactiveBg: Color(hex: 0xCBD5E1),
        darkInactiveBg: Color(hex: 0x212635),
        darkSheetBg: Color(hex: 0x151924)
    ),
    TabColorDef(
        id: "lavender_light",
        name: "Нежная лаванда",
        swatchColor: Color(hex: 0xEDE9FE),
        sheetBg: Color(hex: 0xF6F3FF),
        inactiveBg: Color(hex: 0xE2DCFA),
        darkInactiveBg: Color(hex: 0x221D36),
        darkSheetBg: Color(hex: 0x171426)
    ),
    TabColorDef(
        id: "lavender",
        name: "Лавандовый",
        swatchColor: Color(hex: 0xC4B5FD),
        sheetBg: Color(hex: 0xEEE8FC),
        inactiveBg: Color(hex: 0xD4CBFA),
        darkInactiveBg: Color(hex: 0x251E3E),
        darkSheetBg: Color(hex: 0x19142B)
    ),
    TabColorDef(
        id: "violet_pastel",
        name: "Сиреневый",
        swatchColor: Color(hex: 0xA78BFA),
        sheetBg: Color(hex: 0xE8DDFB),
        inactiveBg: Color(hex: 0xC3B5F7),
        darkInactiveBg: Color(hex: 0x271C42),
        darkSheetBg: Color(hex: 0x1A132C)
    ),

    // Row 2: Тёплые пастельные (Розовые, Пудровые, Персиковые, Лимонные)
    TabColorDef(
        id: "pink_powder",
        name: "Пудровый розовый",
        swatchColor: Color(hex: 0xFCE7F3),
        sheetBg: Color(hex: 0xFDF2F8),
        inactiveBg: Color(hex: 0xF8DBE8),
        darkInactiveBg: Color(hex: 0x2A1A26),
        darkSheetBg: Color(hex: 0x1C121B)
    ),
    TabColorDef(
        id: "pink",
        name: "Розовый",
        swatchColor: Color(hex: 0xF472B6),
        sheetBg: Color(hex: 0xFBE4EF),
        inactiveBg: Color(hex: 0xF6BFDA),
        darkInactiveBg: Color(hex: 0xFF2E1929),
        darkSheetBg: Color(hex: 0x1F111D)
    ),
    TabColorDef(
        id: "rose",
        name: "Роза",
        swatchColor: Color(hex: 0xEC4899),
        sheetBg: Color(hex: 0xFADBE9),
        inactiveBg: Color(hex: 0xF4A5CA),
        darkInactiveBg: Color(hex: 0x32182B),
        darkSheetBg: Color(hex: 0x21101E)
    ),
    TabColorDef(
        id: "peach_light",
        name: "Нежный персик",
        swatchColor: Color(hex: 0xFFEDD5),
        sheetBg: Color(hex: 0xFFF3E8),
        inactiveBg: Color(hex: 0xFAE3CB),
        darkInactiveBg: Color(hex: 0x2B1F18),
        darkSheetBg: Color(hex: 0x1C1410)
    ),
    TabColorDef(
        id: "orange",
        name: "Персиковый",
        swatchColor: Color(hex: 0xFB923C),
        sheetBg: Color(hex: 0xFEE8CF),
        inactiveBg: Color(hex: 0xF8CC9E),
        darkInactiveBg: Color(hex: 0x2F1F17),
        darkSheetBg: Color(hex: 0x1F130E)
    ),
    TabColorDef(
        id: "apricot",
        name: "Абрикосовый",
        swatchColor: Color(hex: 0xF97316),
        sheetBg: Color(hex: 0xFEDEBF),
        inactiveBg: Color(hex: 0xF7B677),
        darkInactiveBg: Color(hex: 0x301D14),
        darkSheetBg: Color(hex: 0x20120C)
    ),
    TabColorDef(
        id: "yellow",
        name: "Лимонный",
        swatchColor: Color(hex: 0xEAB308),
        sheetBg: Color(hex: 0xFEF5BE),
        inactiveBg: Color(hex: 0xFAEA7E),
        darkInactiveBg: Color(hex: 0x2B2312),
        darkSheetBg: Color(hex: 0x1B160B)
    ),

    // Row 3: Природные и Свежие (Мятные, Фисташка, Небесные, Морская волна)
    TabColorDef(
        id: "mint_light",
        name: "Светлая мята",
        swatchColor: Color(hex: 0xBBF7D0),
        sheetBg: Color(hex: 0xEBFAF0),
        inactiveBg: Color(hex: 0xCCF7D9),
        darkInactiveBg: Color(hex: 0x172720),
        darkSheetBg: Color(hex: 0x101B16)
    ),
    TabColorDef(
        id: "green",
        name: "Мятный",
        swatchColor: Color(hex: 0x4ADE80),
        sheetBg: Color(hex: 0xDEF7E7),
        inactiveBg: Color(hex: 0xA8F0BE),
        darkInactiveBg: Color(hex: 0x162B20),
        darkSheetBg: Color(hex: 0x0F1D16)
    ),
    TabColorDef(
        id: "sage",
        name: "Шалфей",
        swatchColor: Color(hex: 0x22C55E),
        sheetBg: Color(hex: 0xD3F4E2),
        inactiveBg: Color(hex: 0x8EE6B2),
        darkInactiveBg: Color(hex: 0x182B22),
        darkSheetBg: Color(hex: 0x101E17)
    ),
    TabColorDef(
        id: "sky_light",
        name: "Небесный ультралайт",
        swatchColor: Color(hex: 0xBAE6FD),
        sheetBg: Color(hex: 0xEDF7FC),
        inactiveBg: Color(hex: 0xD1EBFC),
        darkInactiveBg: Color(hex: 0x162232),
        darkSheetBg: Color(hex: 0x101723)
    ),
    TabColorDef(
        id: "blue",
        name: "Голубой",
        swatchColor: Color(hex: 0x38BDF8),
        sheetBg: Color(hex: 0xDDF0FB),
        inactiveBg: Color(hex: 0xB1DEFA),
        darkInactiveBg: Color(hex: 0x152438),
        darkSheetBg: Color(hex: 0x0E1826)
    ),
    TabColorDef(
        id: "azure",
        name: "Лазурный",
        swatchColor: Color(hex: 0x60A5FA),
        sheetBg: Color(hex: 0xDBEAFE),
        inactiveBg: Color(hex: 0x96CCFA),
        darkInactiveBg: Color(hex: 0x16203A),
        darkSheetBg: Color(hex: 0x0F1628)
    ),
    TabColorDef(
        id: "teal_ice",
        name: "Морская пена",
        swatchColor: Color(hex: 0x2DD4BF),
        sheetBg: Color(hex: 0xD5F7F9),
        inactiveBg: Color(hex: 0x9DEDE5),
        darkInactiveBg: Color(hex: 0x15272A),
        darkSheetBg: Color(hex: 0x0E1A1C)
    )
]

public func getTabColorDef(idOrHex: String?) -> TabColorDef {
    guard let idOrHex = idOrHex, !idOrHex.isEmpty else {
        return TAB_PALETTE[0]
    }
    let lower = idOrHex.lowercased()
    return TAB_PALETTE.first { $0.id == lower } ?? TAB_PALETTE[0]
}
