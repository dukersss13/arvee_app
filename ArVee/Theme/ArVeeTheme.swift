import SwiftUI

// MARK: - ArVee Color Palette

extension Color {

    // Warm paper background — matches web --paper: #f4efe4
    static let arveePaper = Color(light: .init(hex: 0xF4EFE4), dark: .init(hex: 0x1A1816))

    // Sandy tan — matches web --sand: #e9dbc1
    static let arveeSand = Color(light: .init(hex: 0xE9DBC1), dark: .init(hex: 0x2A2520))

    // Soft SAP blue tint for success/info surfaces
    static let arveeMint = Color(light: .init(hex: 0xE3F2FD), dark: .init(hex: 0x1B2E42))

    // Primary text — matches web --ink: #1f1d1a
    static let arveeInk = Color(light: .init(hex: 0x1F1D1A), dark: .init(hex: 0xF0EBE2))

    // Muted text — matches web --ink-muted: #5a554d
    static let arveeInkMuted = Color(light: .init(hex: 0x5A554D), dark: .init(hex: 0xA39B8E))

    // Primary SAP-inspired light blue
    static let arveeTeal = Color(light: .init(hex: 0x449DD4), dark: .init(hex: 0x68B1EE))

    // Deeper blue companion tone
    static let arveeTealDark = Color(light: .init(hex: 0x1F78B4), dark: .init(hex: 0x4299E1))

    // Coral accent — matches web --coral: #ea8f58
    static let arveeCoral = Color(light: .init(hex: 0xEA8F58), dark: .init(hex: 0xEA8F58))

    // Danger red — matches web --danger: #b23a2c
    static let arveeDanger = Color(light: .init(hex: 0xB23A2C), dark: .init(hex: 0xE05545))

    // Card surface — matches web --card: rgba(255,255,255,0.86)
    static let arveeCard = Color(light: .init(white: 1.0, alpha: 0.86), dark: .init(hex: 0x242120, alpha: 0.9))

    // Borders — matches web --line: rgba(34,30,26,0.15)
    static let arveeLine = Color(light: .init(hex: 0x221E1A, alpha: 0.15), dark: .init(hex: 0xF0EBE2, alpha: 0.12))

    // Table header background — matches web #f4ebda
    static let arveeTableHead = Color(light: .init(hex: 0xF4EBDA), dark: .init(hex: 0x2E2924))

    // Success accent aligned to the light-blue family
    static let arveeSuccess = Color(light: .init(hex: 0x64B5F6), dark: .init(hex: 0x5AA8E8))

    // Elevated card surface — slightly more opaque than arveeCard
    static let arveeCardElevated = Color(light: .init(white: 1.0, alpha: 0.94), dark: .init(hex: 0x2A2724, alpha: 0.95))

    // Glass layers for premium fintech card surfaces
    static let arveeGlassBase = Color(light: .init(white: 1.0, alpha: 0.70), dark: .init(hex: 0x221F1D, alpha: 0.82))
    static let arveeGlassHighlight = Color(light: .init(white: 1.0, alpha: 0.48), dark: .init(hex: 0xF0EBE2, alpha: 0.06))
    static let arveeGlassStroke = Color(light: .init(hex: 0xFFFFFF, alpha: 0.52), dark: .init(hex: 0xF0EBE2, alpha: 0.18))
    static let arveeGlowTeal = Color(light: .init(hex: 0x449DD4, alpha: 0.24), dark: .init(hex: 0x68B1EE, alpha: 0.22))
    static let arveeGlowCoral = Color(light: .init(hex: 0xEA8F58, alpha: 0.22), dark: .init(hex: 0xEA8F58, alpha: 0.20))

    // Soft blue background — subtle tint for sections
    static let arveeTealSoft = Color(light: .init(hex: 0x449DD4, alpha: 0.08), dark: .init(hex: 0x68B1EE, alpha: 0.11))

    // Step indicator colors
    static let arveeStepComplete = Color(light: .init(hex: 0x449DD4), dark: .init(hex: 0x68B1EE))
    static let arveeStepActive = Color(light: .init(hex: 0xEA8F58), dark: .init(hex: 0xEA8F58))
    static let arveeStepPending = Color(light: .init(hex: 0x5A554D, alpha: 0.3), dark: .init(hex: 0xA39B8E, alpha: 0.3))

    // MARK: - Chart Palette (matching web SVG colors)

    static let arveeChartPalette: [Color] = [
        Color(UIColor(hex: 0x4EA8DE)),   // light blue
        Color(UIColor(hex: 0xE59F3A)),   // golden
        Color(UIColor(hex: 0x6F8A3B)),   // olive
        Color(UIColor(hex: 0xCF6B4D)),   // terracotta
        Color(UIColor(hex: 0x4A7895)),   // steel blue
        Color(UIColor(hex: 0xB7779F)),   // mauve
        Color(UIColor(hex: 0x8F6B4F)),   // brown
    ]

    // MARK: - Gradients

    static var arveeTealGradient: LinearGradient {
        LinearGradient(
            colors: [.arveeTeal, .arveeTealDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var arveeInkGradient: LinearGradient {
        LinearGradient(
            colors: [Color.arveeInk, Color.arveeInk.opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Adaptive Color Initializer

extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// MARK: - UIColor hex initializer

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    convenience init(white: CGFloat, alpha: CGFloat) {
        self.init(red: white, green: white, blue: white, alpha: alpha)
    }
}

// MARK: - Font Helpers (system fallbacks matching web typography spirit)

extension Font {
    static func arveeBrand(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func arveeHeadline() -> Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }

    static func arveeBody() -> Font {
        .system(.body, design: .rounded)
    }

    static func arveeMono(_ style: TextStyle = .caption) -> Font {
        .system(style, design: .monospaced)
    }

    static func arveeEyebrow() -> Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }
}
