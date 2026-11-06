// Theme.swift — record-up design system
// Generated from design-tokens.json
// Place at: Sources/recordup/Theme.swift

import SwiftUI

// MARK: - Theme

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
}

// MARK: - Color palette

extension Color {
    // Warm theme (default)
    static let canvas        = Color(hex: 0xf6f1ea)
    static let surface       = Color.white
    static let surfaceMuted  = Color(hex: 0xfbf6ef)
    static let sidebar       = Color(hex: 0xf8f2e8).opacity(0.72)
    static let line          = Color(hex: 0x1f1a17).opacity(0.08)
    static let lineStrong    = Color(hex: 0x1f1a17).opacity(0.14)
    static let ink           = Color(hex: 0x1f1a17)
    static let ink70         = Color(hex: 0x1f1a17).opacity(0.7)
    static let ink50         = Color(hex: 0x1f1a17).opacity(0.5)
    static let ink35         = Color(hex: 0x1f1a17).opacity(0.35)
    static let ink20         = Color(hex: 0x1f1a17).opacity(0.2)
    static let ink10         = Color(hex: 0x1f1a17).opacity(0.1)

    // Brand
    static let accent        = Color(hex: 0xFF6A3D)   // 오렌지
    static let accent2       = Color(hex: 0xE0245E)   // 레드핑크
    static let accentSoft    = Color(hex: 0xFF6A3D).opacity(0.10)
    static let accent2Soft   = Color(hex: 0xE0245E).opacity(0.10)

    // Semantic
    static let success       = Color(hex: 0x1f8a5b)
    static let decision      = Color(hex: 0x7A5AE0)   // 결정 사항 (보라)
    static let action        = Color(hex: 0x0E7C86)   // 액션 아이템 (청록)
}

// MARK: - Brand gradients

extension LinearGradient {
    /// 오렌지 → 레드핑크 시그니처 그라데이션. Primary 버튼·로고에 사용.
    static let brand = LinearGradient(
        colors: [Color(hex: 0xFF6A3D), Color(hex: 0xE0245E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 같은 그라데이션의 12% 톤. 선택된 카드 배경 등.
    static let brandSoft = LinearGradient(
        colors: [
            Color(hex: 0xFF6A3D).opacity(0.12),
            Color(hex: 0xE0245E).opacity(0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

extension Font {
    /// SF Pro Display — 큰 제목 (≥17pt 권장)
    static func display(size: CGFloat, weight: Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// SF Pro Text — 본문/UI
    static func ui(size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// SF Mono — 시간·숫자·메타데이터
    static func mono(size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Spacing scale (token names match design-tokens.json)

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

// MARK: - Card style modifier

extension View {
    /// 표준 카드 — 흰 배경 + 가벼운 그림자 + 12pt 모서리
    func card(padding: CGFloat = Spacing.s5) -> some View {
        self
            .padding(padding)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Color.line, lineWidth: 0.5)
            )
    }

    /// 호버 시 부드러운 강조 — onHover 콜백과 함께 사용
    func brandRing(active: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(LinearGradient.brand, lineWidth: active ? 1.5 : 0)
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

// MARK: - Primary button style

struct BrandButtonStyle: ButtonStyle {
    var size: ButtonSize = .md
    enum ButtonSize { case sm, md, lg
        var height: CGFloat { switch self { case .sm: 28; case .md: 32; case .lg: 40 } }
        var horizontal: CGFloat { switch self { case .sm: 12; case .md: 16; case .lg: 20 } }
        var fontSize: CGFloat { switch self { case .sm: 12; case .md: 13; case .lg: 14 } }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(size: size.fontSize, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, size.horizontal)
            .frame(height: size.height)
            .background(LinearGradient.brand)
            .clipShape(Capsule())
            .shadow(color: Color(hex: 0xE0245E).opacity(0.25), radius: 6, y: 2)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(size: 13, weight: .medium))
            .foregroundColor(.ink70)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Color.ink10.opacity(configuration.isPressed ? 1 : 0))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.line, lineWidth: 0.5))
    }
}

// MARK: - Usage examples
//
// Text("회의록 검토")
//     .font(.display(size: 19, weight: .bold))
//     .foregroundColor(.ink)
//
// Button("회의록 생성") { ... }
//     .buttonStyle(BrandButtonStyle(size: .sm))
//
// VStack { ... }
//     .card()
