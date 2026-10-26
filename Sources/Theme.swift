import AppKit
import SwiftUI

extension RGB {
    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }
    var nsColor: NSColor { NSColor(srgbRed: red, green: green, blue: blue, alpha: 1) }
}

/// The size of the popover, kept as it was in every earlier version.
enum ShelfStyle {
    static let width: CGFloat = 400
    static let height: CGFloat = 600
    static let paused = Color(red: 1.0, green: 0.62, blue: 0.04)
}

/// The skin's colours for the light or dark look the shelf is drawing in, ready to use.
struct ShelfPalette {
    let accent: Color
    let onAccent: Color
    let window: Color
    let surface: Color
    let isDark: Bool

    init(skin: ShelfSkin, dark: Bool) {
        let palette = skin.palette(dark: dark)
        accent = palette.accent.color
        onAccent = palette.onAccent.color
        window = palette.window.color
        surface = palette.surface.color
        isDark = dark
    }

    /// The hairline around a resting row.
    var cardBorder: Color {
        isDark ? Color.white.opacity(0.09) : Color.black.opacity(0.08)
    }
}

/// The shelf's own background: the skin's window colour, with a lit top edge in the dark look, as
/// on the Echo App Studio website.
struct ShelfBackground: View {
    let palette: ShelfPalette

    var body: some View {
        palette.window
            .overlay(alignment: .top) {
                if palette.isDark {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.24), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .allowsHitTesting(false)
                }
            }
    }
}

/// A resting row: the skin's surface colour with a hairline edge. A row under the pointer is filled
/// with the accent instead.
struct ShelfRowBackground: View {
    let palette: ShelfPalette
    let highlighted: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        shape
            .fill(highlighted ? palette.accent : palette.surface)
            .overlay {
                if !highlighted {
                    shape.strokeBorder(palette.cardBorder, lineWidth: 0.75)
                }
            }
            .shadow(color: highlighted ? palette.accent.opacity(0.25) : Color.clear, radius: 7, y: 3)
    }
}
