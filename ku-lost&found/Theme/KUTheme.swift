import SwiftUI
import CoreText

// Design tokens ported from ui_kits/ios-app/Shared.jsx
enum KUTheme {
    enum Palette {
        static let primary900 = Color(hex: 0x004544)
        static let primary700 = Color(hex: 0x006765)
        static let primary500 = Color(hex: 0x008F8C)
        static let primary200 = Color(hex: 0x80C4C3)
        static let primary50  = Color(hex: 0xE0F4F4)

        static let accent500  = Color(hex: 0xB2BB1E)
        static let accent700  = Color(hex: 0x96A019)
        static let accent200  = Color(hex: 0xD8DF8F)
        static let accent50   = Color(hex: 0xF5F7D6)

        static let neutral900 = Color(hex: 0x1C1C1E)
        static let neutral700 = Color(hex: 0x3A3A3C)
        static let neutral600 = Color(hex: 0x636366)
        static let neutral400 = Color(hex: 0xAEAEB2)
        static let neutral300 = Color(hex: 0xC7C7CC)
        static let neutral200 = Color(hex: 0xD1D1D6)
        static let neutral100 = Color(hex: 0xF2F2F7)
        static let white      = Color.white

        static let success    = Color(hex: 0x006765)
        static let successBg  = Color(hex: 0xE0F4F4)
        static let warning    = Color(hex: 0x96A019)
        static let warningBg  = Color(hex: 0xF5F7D6)
        static let lostText   = Color(hex: 0xE65100)
        static let danger     = Color(hex: 0xD32F2F)
        static let dangerBg   = Color(hex: 0xFFEBEE)
        static let info       = Color(hex: 0x1565C0)
        static let infoBg     = Color(hex: 0xE3F2FD)
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let btn: CGFloat = 10
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 999
    }

    enum Shadow {
        static let sm = (color: Color.black.opacity(0.08), radius: 4.0, x: 0.0, y: 1.0)
        static let md = (color: Color.black.opacity(0.10), radius: 8.0, x: 0.0, y: 2.0)
    }
}

// MARK: - Color hex helper
extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Sarabun font
extension Font {
    enum Sarabun {
        static func light(_ size: CGFloat)    -> Font { .custom("Sarabun-Light",    size: size) }
        static func regular(_ size: CGFloat)  -> Font { .custom("Sarabun-Regular",  size: size) }
        static func medium(_ size: CGFloat)   -> Font { .custom("Sarabun-Medium",   size: size) }
        static func semibold(_ size: CGFloat) -> Font { .custom("Sarabun-SemiBold", size: size) }
        static func bold(_ size: CGFloat)     -> Font { .custom("Sarabun-Bold",     size: size) }
    }
}

// MARK: - Runtime font registration
enum KUFonts {
    static func register() {
        let names = [
            "Sarabun-Light", "Sarabun-Regular", "Sarabun-Medium",
            "Sarabun-SemiBold", "Sarabun-Bold",
        ]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Shadow helper
extension View {
    func kuShadow(_ s: (color: Color, radius: Double, x: Double, y: Double) = KUTheme.Shadow.sm) -> some View {
        shadow(color: s.color, radius: CGFloat(s.radius), x: CGFloat(s.x), y: CGFloat(s.y))
    }
}
