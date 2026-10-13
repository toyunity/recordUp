import SwiftUI

/// 사이드바·정보 패널에서 공유하는 record·UP 브랜드 워드마크.
/// 시안 (sidebar.jsx, screen-settings.jsx About) 기준.
struct BrandWordmark: View {
    let palette: ThemePalette
    var baseSize: CGFloat = 14
    var inkColor: Color? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("record")
                .font(.system(size: baseSize, weight: .medium, design: .default))
                .foregroundColor(inkColor ?? palette.ink70)
                .tracking(-0.1)
            // 그라데이션 점
            Circle()
                .fill(palette.brandGradient)
                .frame(width: max(2, baseSize * 0.22), height: max(2, baseSize * 0.22))
                .alignmentGuide(.firstTextBaseline) { dim in dim.height * 0.6 }
                .padding(.horizontal, 3)
            Text("UP")
                .font(.system(size: baseSize * 1.15, weight: .heavy, design: .default))
                .italic()
                .foregroundStyle(palette.brandGradient)
                .tracking(-0.5)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}

/// 앱 아이콘과 동일한 이미지(BrandIcon)를 사이드바·About 등에서 재사용.
struct BrandMark: View {
    let palette: ThemePalette
    var size: CGFloat = 36

    var body: some View {
        Image("BrandIcon")
            .resizable()
            .interpolation(.high)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: size, height: size)
            .shadow(color: palette.accent2.opacity(0.22), radius: size * 0.06, x: 0, y: 0)
    }
}
