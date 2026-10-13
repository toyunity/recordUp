// Theme.swift — record-up design system
// Source of truth: design/design-tokens.json + design/Theme.swift
//
// 사용법
//   @Environment(\.palette) private var p
//   Text("…").foregroundColor(p.ink)
// 또는
//   Color.canvas (= warm 기본 정적 컬러; 환경 분리 없이 쓰는 곳에서)
//
// 테마 전환은 RootView 가 .environment(\.palette, …) 로 주입한다.

import SwiftUI

// MARK: - Theme enum & storage key

enum AppTheme: String, CaseIterable, Identifiable {
    case warm, mono, dark
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warm: return "따뜻한"
        case .mono: return "단색"
        case .dark: return "다크 스튜디오"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .warm: return .warm
        case .mono: return .mono
        case .dark: return .dark
        }
    }

    static let storageKey = "theme"
}

// MARK: - Palette — theme-aware color set

struct ThemePalette {
    var canvas: Color
    var surface: Color
    var surfaceMuted: Color
    var sidebar: Color
    var line: Color
    var lineStrong: Color
    var ink: Color
    var ink70: Color
    var ink50: Color
    var ink35: Color
    var ink20: Color
    var ink10: Color
    var accent: Color
    var accent2: Color
    var accentSoft: Color
    var accent2Soft: Color
    var success: Color
    var decision: Color
    var action: Color
    var brandGradient: LinearGradient
    var brandGradientSoft: LinearGradient
    var isDark: Bool

    static let warm = ThemePalette(
        canvas:        Color(hex: 0xf6f1ea),
        surface:       Color.white,
        surfaceMuted:  Color(hex: 0xfbf6ef),
        sidebar:       Color(hex: 0xf8f2e8, opacity: 0.72),
        line:          Color(hex: 0x1f1a17, opacity: 0.08),
        lineStrong:    Color(hex: 0x1f1a17, opacity: 0.14),
        ink:           Color(hex: 0x1f1a17),
        ink70:         Color(hex: 0x1f1a17, opacity: 0.7),
        ink50:         Color(hex: 0x1f1a17, opacity: 0.5),
        ink35:         Color(hex: 0x1f1a17, opacity: 0.35),
        ink20:         Color(hex: 0x1f1a17, opacity: 0.2),
        ink10:         Color(hex: 0x1f1a17, opacity: 0.1),
        accent:        Color(hex: 0xFF6A3D),
        accent2:       Color(hex: 0xE0245E),
        accentSoft:    Color(hex: 0xFF6A3D, opacity: 0.10),
        accent2Soft:   Color(hex: 0xE0245E, opacity: 0.10),
        success:       Color(hex: 0x1f8a5b),
        decision:      Color(hex: 0x7A5AE0),
        action:        Color(hex: 0x0E7C86),
        brandGradient: LinearGradient(
            colors: [Color(hex: 0xFF6A3D), Color(hex: 0xE0245E)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        brandGradientSoft: LinearGradient(
            colors: [Color(hex: 0xFF6A3D, opacity: 0.12), Color(hex: 0xE0245E, opacity: 0.12)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        isDark: false
    )

    static let mono = ThemePalette(
        canvas:        Color(hex: 0xfafaf8),
        surface:       Color.white,
        surfaceMuted:  Color(hex: 0xf3f3f0),
        sidebar:       Color(hex: 0xf5f5f2, opacity: 0.85),
        line:          Color.black.opacity(0.08),
        lineStrong:    Color.black.opacity(0.16),
        ink:           Color(hex: 0x0d0d0d),
        ink70:         Color(hex: 0x0d0d0d, opacity: 0.7),
        ink50:         Color(hex: 0x0d0d0d, opacity: 0.5),
        ink35:         Color(hex: 0x0d0d0d, opacity: 0.35),
        ink20:         Color(hex: 0x0d0d0d, opacity: 0.2),
        ink10:         Color(hex: 0x0d0d0d, opacity: 0.08),
        accent:        Color(hex: 0xFF6A3D),
        accent2:       Color(hex: 0xFF6A3D),
        accentSoft:    Color(hex: 0xFF6A3D, opacity: 0.10),
        accent2Soft:   Color(hex: 0xFF6A3D, opacity: 0.10),
        success:       Color(hex: 0x0d7a4a),
        decision:      Color(hex: 0x0d0d0d),
        action:        Color(hex: 0x0d0d0d),
        brandGradient: LinearGradient(
            colors: [Color(hex: 0xFF6A3D)], startPoint: .leading, endPoint: .trailing
        ),
        brandGradientSoft: LinearGradient(
            colors: [Color(hex: 0xFF6A3D, opacity: 0.10)],
            startPoint: .leading, endPoint: .trailing
        ),
        isDark: false
    )

    static let dark = ThemePalette(
        canvas:        Color(hex: 0x1a1614),
        surface:       Color(hex: 0x221d1a),
        surfaceMuted:  Color(hex: 0x1f1a17),
        sidebar:       Color(hex: 0x14100e, opacity: 0.82),
        line:          Color.white.opacity(0.07),
        lineStrong:    Color.white.opacity(0.14),
        ink:           Color(hex: 0xf4ece2),
        ink70:         Color(hex: 0xf4ece2, opacity: 0.7),
        ink50:         Color(hex: 0xf4ece2, opacity: 0.5),
        ink35:         Color(hex: 0xf4ece2, opacity: 0.35),
        ink20:         Color(hex: 0xf4ece2, opacity: 0.2),
        ink10:         Color(hex: 0xf4ece2, opacity: 0.1),
        accent:        Color(hex: 0xFF8B62),
        accent2:       Color(hex: 0xF04C7E),
        accentSoft:    Color(hex: 0xFF8B62, opacity: 0.16),
        accent2Soft:   Color(hex: 0xF04C7E, opacity: 0.16),
        success:       Color(hex: 0x3ec78a),
        decision:      Color(hex: 0xa78bfa),
        action:        Color(hex: 0x3ec7c7),
        brandGradient: LinearGradient(
            colors: [Color(hex: 0xFF8B62), Color(hex: 0xF04C7E)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        brandGradientSoft: LinearGradient(
            colors: [Color(hex: 0xFF8B62, opacity: 0.18), Color(hex: 0xF04C7E, opacity: 0.18)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        isDark: true
    )
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: ThemePalette = .warm
}

extension EnvironmentValues {
    var palette: ThemePalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

// MARK: - Static color shortcuts (warm 기본; 환경 주입과 분리해서 쓸 때만)

extension Color {
    static let canvas        = ThemePalette.warm.canvas
    static let surface       = ThemePalette.warm.surface
    static let surfaceMuted  = ThemePalette.warm.surfaceMuted
    static let sidebar       = ThemePalette.warm.sidebar
    static let line          = ThemePalette.warm.line
    static let lineStrong    = ThemePalette.warm.lineStrong
    static let ink           = ThemePalette.warm.ink
    static let ink70         = ThemePalette.warm.ink70
    static let ink50         = ThemePalette.warm.ink50
    static let ink35         = ThemePalette.warm.ink35
    static let ink20         = ThemePalette.warm.ink20
    static let ink10         = ThemePalette.warm.ink10
    static let accent        = ThemePalette.warm.accent
    static let accent2       = ThemePalette.warm.accent2
    static let accentSoft    = ThemePalette.warm.accentSoft
    static let accent2Soft   = ThemePalette.warm.accent2Soft
    static let success       = ThemePalette.warm.success
    static let decision      = ThemePalette.warm.decision
    static let action        = ThemePalette.warm.action
}

extension LinearGradient {
    static let brand     = ThemePalette.warm.brandGradient
    static let brandSoft = ThemePalette.warm.brandGradientSoft
}

// MARK: - Typography

extension Font {
    static func display(size: CGFloat, weight: Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func ui(size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Spacing & radius

enum Spacing {
    static let half: CGFloat   = 2
    static let s1: CGFloat     = 4
    static let s1_5: CGFloat   = 6
    static let s2: CGFloat     = 8
    static let s2_5: CGFloat   = 10
    static let s3: CGFloat     = 12
    static let s4: CGFloat     = 14
    static let s5: CGFloat     = 18
    static let s6: CGFloat     = 24
    static let s8: CGFloat     = 32
    static let s10: CGFloat    = 40
}

enum Radius {
    static let sm: CGFloat   = 6
    static let md: CGFloat   = 8
    static let lg: CGFloat   = 12
    static let xl: CGFloat   = 16
    static let full: CGFloat = 9999
}

// MARK: - Modifiers

extension View {
    /// 표준 카드 — palette 기반 흰 배경 + 가벼운 그림자 + 12pt 모서리.
    func card(palette p: ThemePalette, padding: CGFloat = Spacing.s5) -> some View {
        self
            .padding(padding)
            .background(p.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .shadow(color: .black.opacity(p.isDark ? 0.25 : 0.04), radius: 8, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(p.line, lineWidth: 0.5)
            )
    }

    /// 호버 시 부드러운 그라데이션 강조
    func brandRing(active: Bool, palette p: ThemePalette) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(p.brandGradient, lineWidth: active ? 1.5 : 0)
                .animation(.easeOut(duration: 0.15), value: active)
        )
    }
}

// MARK: - Hex color helper

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >>  8) & 0xff) / 255
        let b = Double( hex        & 0xff) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Button styles

struct BrandButtonStyle: ButtonStyle {
    var size: ButtonSize = .md
    var palette: ThemePalette = .warm

    enum ButtonSize {
        case sm, md, lg
        var height: CGFloat       { switch self { case .sm: 28; case .md: 32; case .lg: 40 } }
        var horizontal: CGFloat   { switch self { case .sm: 12; case .md: 16; case .lg: 20 } }
        var fontSize: CGFloat     { switch self { case .sm: 12; case .md: 13; case .lg: 14 } }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(size: size.fontSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, size.horizontal)
            .frame(height: size.height)
            .background(palette.brandGradient)
            .clipShape(Capsule())
            .shadow(color: palette.accent2.opacity(0.25), radius: 6, y: 2)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var palette: ThemePalette = .warm
    var size: BrandButtonStyle.ButtonSize = .md

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(size: size.fontSize, weight: .medium))
            .foregroundColor(palette.ink70)
            .padding(.horizontal, size.horizontal)
            .frame(height: size.height)
            .background(palette.ink10.opacity(configuration.isPressed ? 1 : 0))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(palette.line, lineWidth: 0.5))
    }
}

// MARK: - Speaker color helper

enum SpeakerPalette {
    static let colors: [Color] = [
        Color(hex: 0xFF6A3D),
        Color(hex: 0x7A5AE0),
        Color(hex: 0x0E7C86),
        Color(hex: 0xE0245E),
        Color(hex: 0x1f8a5b),
        Color(hex: 0xD89A1F),
        Color(hex: 0x4A8AE0),
        Color(hex: 0xC75B5B),
    ]

    static func color(for id: Int?) -> Color {
        guard let id else { return .gray }
        let idx = ((id % colors.count) + colors.count) % colors.count
        return colors[idx]
    }
}
