// Theme+Components.swift — 화면 전반의 반복 패턴을 한 곳으로 모은 공통 컴포넌트.
// 도입 후 점진적으로 인라인 패턴을 치환한다.

import SwiftUI

// MARK: - Surface card modifier (background + hairline border, no padding/shadow)

extension View {
    /// surface fill + 0.5pt 라인 보더의 표준 카드 표면.
    /// 패딩이나 그림자가 필요하면 `.card(palette:padding:)`을 사용.
    func surfaceCard(
        palette p: ThemePalette,
        radius: CGFloat = 10,
        fill: Color? = nil,
        stroke: Color? = nil
    ) -> some View {
        let bg = fill ?? p.surface
        let border = stroke ?? p.line
        return self
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(border, lineWidth: 0.5)
            )
    }
}

// MARK: - Section label (uppercase + tracking)

struct SectionLabel: View {
    let text: String
    var weight: Font.Weight = .heavy
    var tracking: CGFloat = 0.8

    @Environment(\.palette) private var p

    var body: some View {
        Text(text)
            .font(.ui(size: 11, weight: weight))
            .foregroundColor(p.ink50)
            .textCase(.uppercase)
            .tracking(tracking)
    }
}

// MARK: - Meta label / separator

struct MetaLabel: View {
    let text: String
    var color: Color?

    @Environment(\.palette) private var p

    var body: some View {
        Text(text)
            .font(.mono(size: 11))
            .foregroundColor(color ?? p.ink50)
    }
}

struct MetaSeparator: View {
    @Environment(\.palette) private var p
    var body: some View {
        Text("·").font(.mono(size: 11)).foregroundColor(p.ink20)
    }
}

// MARK: - Speaker avatar

struct SpeakerAvatar: View {
    let id: Int?
    var initial: String
    var size: CGFloat = 22
    var ringColor: Color?

    var body: some View {
        ZStack {
            Circle()
                .fill(SpeakerPalette.color(for: id))
                .frame(width: size, height: size)
            Text(initial)
                .font(.ui(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .overlay(
            Circle().stroke(ringColor ?? .clear, lineWidth: ringColor == nil ? 0 : 1.5)
        )
    }
}

// MARK: - Brand icon box (gradient bg + system image)

struct BrandIconBox: View {
    let systemName: String
    var size: CGFloat = 36
    var iconScale: CGFloat = 0.45
    var corner: CGFloat = 10

    @Environment(\.palette) private var p

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(p.brandGradient)
                .frame(width: size, height: size)
                .shadow(color: p.accent2.opacity(0.30), radius: 4, y: 2)
            Image(systemName: systemName)
                .font(.system(size: size * iconScale, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Date formatters (cached, locale ko_KR)

enum DateFormatters {
    private static let koLong: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일"
        return f
    }()

    private static let koShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f
    }()

    private static let koCompact: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d"
        return f
    }()

    /// "2026년 5월 8일"
    static func long(_ date: Date) -> String { koLong.string(from: date) }
    /// "5월 8일"
    static func short(_ date: Date) -> String { koShort.string(from: date) }
    /// "5/8" — sidebar 등 좁은 자리.
    static func compact(_ date: Date) -> String { koCompact.string(from: date) }
}
