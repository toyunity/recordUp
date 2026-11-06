import SwiftUI

/// 드롭존 배경의 4겹 sine-wave 곡선. 시안 (screen-drop.jsx) 기준.
/// TimelineView로 시간에 따라 위상을 흐르게 한다.
struct AnimatedDropWave: View {
    let palette: ThemePalette
    var emphasized: Bool = false

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let mid = size.height / 2
                let lines = 4
                for i in 0..<lines {
                    var path = Path()
                    let amp: CGFloat = 22 + CGFloat(i) * 5
                    let phase = t * (0.6 + Double(i) * 0.18)
                    let stroke = max(0.4, 1.4 - CGFloat(i) * 0.25)
                    let baseY = mid + CGFloat(sin(Double(i) * 1.4)) * 8
                    let opacity = (0.7 - Double(i) * 0.15) * (emphasized ? 1.5 : 1.0)
                    let step: CGFloat = 8
                    var x: CGFloat = -20
                    while x <= size.width + 20 {
                        let theta = Double(x) * 0.012 + phase
                        let y = baseY + CGFloat(sin(theta + Double(i)) * Double(amp))
                        if x == -20 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        x += step
                    }
                    ctx.stroke(
                        path,
                        with: .color(palette.accent.opacity(min(1, opacity))),
                        lineWidth: stroke
                    )
                }
            }
        }
    }
}
