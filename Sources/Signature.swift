import Foundation

/// A colour as plain numbers, so the skins can be listed and tested without any UI framework.
struct RGB: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    /// `RGB(hex: 0xE6E7EA)`.
    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    /// WCAG relative luminance.
    var relativeLuminance: Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    /// WCAG contrast ratio between two colours (1 to 21).
    static func contrast(_ first: RGB, _ second: RGB) -> Double {
        let a = first.relativeLuminance
        let b = second.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}

/// The colours the shelf draws itself. Text and secondary text are the system's own, so they always
/// read well on the light or dark background.
struct SkinPalette: Equatable, Sendable {
    /// The chosen All/Pinned part, the row under the pointer, the dot and Clear recent.
    let accent: RGB
    /// Text and symbols on an accent surface.
    let onAccent: RGB
    /// Behind the whole shelf.
    let window: RGB
    /// The resting rows.
    let surface: RGB
}

/// The colour waves the shelf can wear. Signature is Echo App Studio's black, charcoal and silver,
/// and the default; the other five are Verbyn's skins, with the same colours. Every skin has a dark
/// and a light version that follow the Mac's setting (or the Appearance choice).
enum ShelfSkin: String, CaseIterable, Sendable {
    case signature
    case sky
    case green
    case turquoise
    case bordeaux
    case wisteria

    /// The skin a fresh install wears.
    static let fallback = ShelfSkin.signature
    /// The skin the app's own icon is drawn in, so it needs no custom icon in Finder.
    static let builtInIcon = ShelfSkin.signature

    /// A stored name if it is a known skin, otherwise Signature.
    static func from(stored: String?) -> ShelfSkin {
        guard let stored, let skin = ShelfSkin(rawValue: stored) else { return fallback }
        return skin
    }

    var title: String {
        switch self {
        case .signature: return "Signature"
        case .sky: return "Sky"
        case .green: return "Green"
        case .turquoise: return "Turquoise"
        case .bordeaux: return "Bordeaux"
        case .wisteria: return "Wisteria"
        }
    }

    var tagline: String {
        switch self {
        case .signature: return "Black and silver"
        case .sky: return "Classic blue"
        case .green: return "Fresh green"
        case .turquoise: return "Deep teal"
        case .bordeaux: return "Wine red"
        case .wisteria: return "Soft violet"
        }
    }

    func palette(dark: Bool) -> SkinPalette {
        func make(_ accent: UInt32, _ onAccent: UInt32, _ window: UInt32, _ surface: UInt32) -> SkinPalette {
            SkinPalette(accent: RGB(hex: accent), onAccent: RGB(hex: onAccent), window: RGB(hex: window), surface: RGB(hex: surface))
        }
        switch (self, dark) {
        case (.signature, false): return make(0x1C1D20, 0xFFFFFF, 0xF3F3F4, 0xFFFFFF)
        case (.signature, true): return make(0xE6E7EA, 0x0B0C0D, 0x0B0C0D, 0x151618)
        case (.sky, false): return make(0x2D64AE, 0xFFFFFF, 0xEEF3FA, 0xFBFCFE)
        case (.sky, true): return make(0x86B5F4, 0x06142B, 0x08101D, 0x0F1A2C)
        case (.green, false): return make(0x167A47, 0xFFFFFF, 0xEEF3EF, 0xFBFDFB)
        case (.green, true): return make(0x7CE2A3, 0x04140A, 0x141A17, 0x1B231F)
        case (.turquoise, false): return make(0x1D7470, 0xFFFFFF, 0xEDF5F4, 0xFAFDFC)
        case (.turquoise, true): return make(0x5FD0C8, 0x04201F, 0x081416, 0x0F2023)
        case (.bordeaux, false): return make(0xA33B4F, 0xFFFFFF, 0xF7F0F1, 0xFDFAFA)
        case (.bordeaux, true): return make(0xE8909F, 0x2A0A10, 0x160B0E, 0x211216)
        case (.wisteria, false): return make(0x6352A8, 0xFFFFFF, 0xF3F1F9, 0xFCFBFE)
        case (.wisteria, true): return make(0xB9A6F2, 0x130C2E, 0x110F1D, 0x1A1729)
        }
    }
}

/// Whether the shelf follows the Mac's light or dark look, or stays in one.
enum ShelfAppearance: String, CaseIterable, Sendable {
    case auto
    case light
    case dark

    static func from(stored: String?) -> ShelfAppearance {
        guard let stored, let value = ShelfAppearance(rawValue: stored) else { return .auto }
        return value
    }

    var title: String {
        switch self {
        case .auto: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// The look settings: skin, light or dark, whether each item shows the app it came from, and
/// whether the app's icon in Finder follows the skin. Nothing is written until the user changes one.
struct ShelfPreferences: Equatable, Sendable {
    static let skinKey = "EchoLenaSkinV1"
    static let appearanceKey = "EchoLenaAppearanceV1"
    static let sourceIconsKey = "EchoLenaShowSourceIconsV1"
    static let appIconKey = "EchoLenaAppIconFollowsSkinV1"

    var skin = ShelfSkin.fallback
    var appearance = ShelfAppearance.auto
    /// On unless the user turned it off.
    var showSourceIcons = true
    /// On unless the user turned it off.
    var appIconFollowsSkin = true

    static func load(from defaults: UserDefaults = .standard) -> ShelfPreferences {
        ShelfPreferences(
            skin: ShelfSkin.from(stored: defaults.string(forKey: skinKey)),
            appearance: ShelfAppearance.from(stored: defaults.string(forKey: appearanceKey)),
            showSourceIcons: defaults.object(forKey: sourceIconsKey) as? Bool ?? true,
            appIconFollowsSkin: defaults.object(forKey: appIconKey) as? Bool ?? true
        )
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(skin.rawValue, forKey: Self.skinKey)
        defaults.set(appearance.rawValue, forKey: Self.appearanceKey)
        defaults.set(showSourceIcons, forKey: Self.sourceIconsKey)
        defaults.set(appIconFollowsSkin, forKey: Self.appIconKey)
    }

    /// The skin whose icon the app should show in Finder, or nil for the app's own icon.
    var customIconSkin: ShelfSkin? {
        appIconFollowsSkin && skin != ShelfSkin.builtInIcon ? skin : nil
    }
}
