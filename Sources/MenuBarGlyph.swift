import AppKit

/// EchoLena's menu-bar picture: the app icon's clipboard, solid, with its lines left open. While
/// recording is paused the lines become two pause bars. It is a template image, so macOS draws it
/// white or black to match the menu bar.
enum MenuBarGlyph {
    private static let side: CGFloat = 18

    /// A rounded rectangle given in the 18-point grid with the y axis pointing down, as a path in
    /// the image's own (upward) coordinates.
    private static func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, radius: CGFloat) -> NSBezierPath {
        NSBezierPath(
            roundedRect: NSRect(x: x, y: side - y - height, width: width, height: height),
            xRadius: radius,
            yRadius: radius
        )
    }

    @MainActor
    static func image(paused: Bool, description: String) -> NSImage {
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in
            NSColor.black.setFill()

            // The clip on top, with a slot in it.
            let clip = box(5.9, 1, 6.2, 3.6, radius: 1.6)
            clip.append(box(6.9, 1.8, 4.2, 1.1, radius: 0.55))
            clip.windingRule = .evenOdd
            clip.fill()

            // The board, with its three lines (or two pause bars) left open.
            let board = box(3, 3, 12, 14, radius: 2.6)
            if paused {
                board.append(box(6.2, 7.4, 1.9, 6.2, radius: 0.9))
                board.append(box(9.9, 7.4, 1.9, 6.2, radius: 0.9))
            } else {
                board.append(box(5.6, 8, 6.8, 1.5, radius: 0.75))
                board.append(box(5.6, 11, 6.8, 1.5, radius: 0.75))
                board.append(box(5.6, 14, 4.4, 1.5, radius: 0.75))
            }
            board.windingRule = .evenOdd
            board.fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = description
        return image
    }
}
