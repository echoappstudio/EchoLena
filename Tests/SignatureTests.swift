import Foundation

private func hex(_ colour: RGB) -> String {
    String(format: "%02X%02X%02X", Int((colour.red * 255).rounded()), Int((colour.green * 255).rounded()), Int((colour.blue * 255).rounded()))
}

func testSkinPalettesAreReadable() {
    expect(abs(RGB(hex: 0xE6E7EA).red - 230.0 / 255) < 0.0001, "hex colours convert to numbers")
    expect(abs(RGB.contrast(RGB(hex: 0x000000), RGB(hex: 0xFFFFFF)) - 21) < 0.001, "black on white is 21:1")
    expect(abs(RGB.contrast(RGB(hex: 0xFFFFFF), RGB(hex: 0xFFFFFF)) - 1) < 0.001, "white on white is 1:1")

    for skin in ShelfSkin.allCases {
        for dark in [true, false] {
            let palette = skin.palette(dark: dark)
            let label = "\(skin.title), \(dark ? "dark" : "light")"
            // Signature is held to a higher bar than the colour skins.
            let needed = skin == .signature ? 7.0 : 4.5
            expect(RGB.contrast(palette.accent, palette.onAccent) >= needed, "text on accent is readable: \(label)")
            expect(RGB.contrast(palette.accent, palette.window) >= needed, "accent on the window is readable: \(label)")
            expect(RGB.contrast(palette.accent, palette.surface) >= needed, "accent on a row is readable: \(label)")
        }
        expect(skin.palette(dark: true) != skin.palette(dark: false), "\(skin.title) has a dark and a light version")
    }

    // Signature is Echo App Studio's black, charcoal and silver, as in Verbyn and EchoVela.
    expect(hex(ShelfSkin.signature.palette(dark: true).accent) == "E6E7EA", "Signature dark accent is silver")
    expect(hex(ShelfSkin.signature.palette(dark: true).window) == "0B0C0D", "Signature dark window is black")
    expect(hex(ShelfSkin.signature.palette(dark: true).surface) == "151618", "Signature dark rows are charcoal")
    expect(hex(ShelfSkin.signature.palette(dark: false).window) == "F3F3F4", "Signature light window is soft grey")
}

func testSkinsAndLookSettings() {
    let names = ShelfSkin.allCases.map { $0.rawValue }
    expect(names == ["signature", "sky", "green", "turquoise", "bordeaux", "wisteria"], "there are Verbyn's six skins, Signature first")
    expect(Set(ShelfSkin.allCases.map { $0.title }).count == 6, "every skin has its own title")
    expect(Set(ShelfSkin.allCases.map { $0.tagline }).count == 6, "every skin has its own tagline")
    let accents = ShelfSkin.allCases.map { $0.palette(dark: true).accent }
    expect(accents.indices.allSatisfy { index in !accents[(index + 1)...].contains(accents[index]) }, "every skin has its own accent colour")
    expect(ShelfSkin.fallback == .signature && ShelfSkin.builtInIcon == .signature, "Signature is the default skin and the built-in icon")
    expect(ShelfSkin.from(stored: nil) == .signature, "no stored skin means Signature")
    expect(ShelfSkin.from(stored: "bordeaux") == .bordeaux, "a stored skin is used")
    expect(ShelfSkin.from(stored: "lagoon") == .signature, "an unknown stored skin falls back to Signature")
    expect(ShelfAppearance.from(stored: nil) == .auto, "no stored appearance means Automatic")
    expect(ShelfAppearance.from(stored: "dark") == .dark, "a stored appearance is used")
    expect(ShelfAppearance.from(stored: "sepia") == .auto, "an unknown appearance falls back to Automatic")

    let suite = "com.echoapps.echolena.tests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else {
        expect(false, "a throwaway preference domain should be available")
        return
    }
    defer { defaults.removePersistentDomain(forName: suite) }

    let fresh = ShelfPreferences.load(from: defaults)
    expect(fresh.skin == .signature && fresh.appearance == .auto, "a fresh install starts with Signature and Automatic")
    expect(fresh.showSourceIcons, "source app icons are on by default")
    expect(fresh.appIconFollowsSkin, "the app icon follows the skin by default")
    expect(defaults.dictionaryRepresentation().keys.allSatisfy { !$0.hasPrefix("EchoLena") }, "loading the settings writes nothing")

    var chosen = fresh
    chosen.skin = .wisteria
    chosen.appearance = .light
    chosen.showSourceIcons = false
    chosen.appIconFollowsSkin = false
    chosen.save(to: defaults)
    expect(ShelfPreferences.load(from: defaults) == chosen, "the chosen look is remembered")
}

func testFinderIconSkin() {
    var preferences = ShelfPreferences()
    expect(preferences.customIconSkin == nil, "Signature, the default, uses the app's own icon, so no custom icon")
    preferences.skin = .sky
    expect(preferences.customIconSkin == .sky, "Sky shows its own icon in Finder")
    preferences.skin = .green
    preferences.appIconFollowsSkin = false
    expect(preferences.customIconSkin == nil, "with the switch off the app's own icon stays")
}
