import SwiftUI
import CoreText

// Design tokens ported from ui_kits/ios-app/Shared.jsx
enum KUTheme {
    // Refined palette — black & white foundation, red + KU green (#006765) as accents.
    // Goal: official, clean, editorial.
    enum Palette {
        // KU Green — primary brand / "Found" / primary CTA
        static let primary900 = Color(hex: 0x004544)
        static let primary700 = Color(hex: 0x006765)   // ★ official KU teal
        static let primary500 = Color(hex: 0x008F8C)
        static let primary200 = Color(hex: 0xB8D4D3)
        static let primary50  = Color(hex: 0xEEF5F5)

        // Red — "Lost" / destructive / accent stripe
        static let accent500  = Color(hex: 0xC62828)   // refined red
        static let accent700  = Color(hex: 0x8E1F1F)
        static let accent200  = Color(hex: 0xE8B5B5)
        static let accent50   = Color(hex: 0xFCEEEE)

        // Black & white scale (higher contrast, editorial)
        static let neutral900 = Color(hex: 0x0A0A0A)   // near-black
        static let neutral700 = Color(hex: 0x2C2C2E)
        static let neutral600 = Color(hex: 0x6B6B70)
        static let neutral400 = Color(hex: 0xA8A8AD)
        static let neutral300 = Color(hex: 0xD4D4D8)
        static let neutral200 = Color(hex: 0xE5E5E7)
        static let neutral100 = Color(hex: 0xF7F7F8)   // off-white app bg
        static let white      = Color.white

        // Semantic — only red & green per spec
        static let success    = Color(hex: 0x006765)
        static let successBg  = Color(hex: 0xEEF5F5)
        static let warning    = Color(hex: 0xC62828)
        static let warningBg  = Color(hex: 0xFCEEEE)
        static let lostText   = Color(hex: 0xC62828)
        static let danger     = Color(hex: 0xC62828)
        static let dangerBg   = Color(hex: 0xFCEEEE)
        static let info       = Color(hex: 0x0A0A0A)   // collapse "info" to neutral black
        static let infoBg     = Color(hex: 0xF0F0F2)
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let btn: CGFloat = 10
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // Subtle, editorial — prefer thin hairlines over heavy drop shadows.
    enum Shadow {
        static let sm = (color: Color.black.opacity(0.04), radius: 2.0, x: 0.0, y: 1.0)
        static let md = (color: Color.black.opacity(0.06), radius: 6.0, x: 0.0, y: 2.0)
    }

    // Hairline border modifier
    static let hairline = Color(hex: 0xE5E5E7)
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
