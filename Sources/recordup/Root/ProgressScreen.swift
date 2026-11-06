import SwiftUI

/// 처리 중 화면. 시안 (screen-progress.jsx) 기준으로 waveform + 파이프라인 + 라이브 스트림.
struct ProgressScreen: View {
    var title: String
    var subtitle: String?
    /// 현재 파이프라인 단계. rawValue 문자열 매칭은 stage 라벨이 바뀌면 desync되므로 enum으로 직접 받는다.
    var stage: TranscribeJob.Stage
    /// 회의록 생성 노드에 표시할 엔진명(claude/codex). 기본 엔진 표시명.
    var engineName: String
    var detail: String
    var liveText: String = ""
    /// 회의록 생성 단계 "모델 대화" 카드: 보낸 요청(템플릿 지시) · 첨부 전사본 글자수 · 실시간 누적 응답.
    var promptPreview: String = ""
    var transcriptChars: Int = 0
    var responseLive: String = ""
    var progress: Double
    var fileName: String?
    var onCancel: () -> Void

    @Environment(\.palette) private var p

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    waveformCard
                    pipelineCards
                    if stage == .generatingMinutes {
                        modelConversationCard
                    } else {
                        liveStreamCard
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("새 회의록")
                    .font(.ui(size: 11))
                    .foregroundColor(p.ink50)
                Text(title)
                    .font(.display(size: 14.5, weight: .semibold))
                    .foregroundColor(p.ink)
            }
            Spacer()
            Button("취소", action: onCancel)
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
        }
        .padding(.horizontal, 24)
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(currentPipelineStep.label)
                .font(.display(size: 26, weight: .semibold))
                .foregroundColor(p.ink)
            if let f = fileName {
                Text(f)
                    .font(.mono(size: 12))
                    .foregroundColor(p.ink50)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Waveform card

    private var waveformCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(p.brandGradient)
                        .frame(width: 36, height: 36)
                        .shadow(color: p.accent2.opacity(0.30), radius: 4, y: 2)
                    Image(systemName: currentPipelineStep.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(progress * 100))")
                        .font(.mono(size: 26, weight: .semibold))
                        .foregroundColor(p.ink)
                    Text("%")
                        .font(.mono(size: 14))
                        .foregroundColor(p.ink50)
                }
            }

            AnimatedProgressWave(palette: p, progress: progress)
                .frame(height: 90)

            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(p.ink10).frame(height: 4)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p.brandGradient)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.easeOut(duration: 0.5), value: progress)
                    }
                    .frame(height: 4)
                }
                HStack {
                    Text(detail.isEmpty ? "약 1분 남음" : detail)
                        .font(.mono(size: 11))
                        .foregroundColor(p.ink50)
                    Spacer()
                    Text("RTF 0.42×")
                        .font(.mono(size: 11))
                        .foregroundColor(p.ink50)
                }
            }
        }
        .padding(EdgeInsets(top: 24, leading: 28, bottom: 20, trailing: 28))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18).stroke(p.line, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(p.isDark ? 0.25 : 0.04), radius: 8, y: 2)
    }

    // MARK: - Pipeline

    private struct PipelineStep {
        let label: String
        let sub: String
        let icon: String
    }

    private var pipeline: [PipelineStep] {
        [
            PipelineStep(label: "오디오 디코딩", sub: "AVFoundation", icon: "speaker.wave.2"),
            PipelineStep(label: "Whisper 모델 준비", sub: "large-v3-turbo", icon: "sparkle"),
            PipelineStep(label: "한국어 전사", sub: "WhisperKit", icon: "waveform"),
            PipelineStep(label: "화자 분리", sub: "SpeakerKit", icon: "person.2"),
            PipelineStep(label: "회의록 생성", sub: engineName, icon: "doc.text"),
        ]
    }

    private var currentStepIndex: Int {
        switch stage {
        case .loadingAudio: return 0
        case .preparingWhisper: return 1
        case .transcribing: return 2
        case .preparingSpeaker: return 2
        case .diarizing: return 3
        case .generatingMinutes: return 4
        case .idle, .reviewingTranscript, .reviewingMinutes, .failed:
            // ProgressScreen은 활성 처리 stage에서만 표시되지만, 안전하게 progress로 추정.
            let idx = Int(progress * 5)
            return min(4, max(0, idx))
        }
    }

    private var currentPipelineStep: PipelineStep {
        pipeline[currentStepIndex]
    }

    private var pipelineCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("파이프라인")
                .font(.ui(size: 11, weight: .heavy))
                .foregroundColor(p.ink50)
                .textCase(.uppercase)
                .tracking(0.8)
            HStack(spacing: 8) {
                ForEach(Array(pipeline.enumerated()), id: \.offset) { idx, step in
                    pipelineCard(step: step, index: idx)
                    if idx < pipeline.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(p.ink20)
                    }
                }
            }
        }
    }

    private func pipelineCard(step: PipelineStep, index: Int) -> some View {
        let status: PipelineStatus = index < currentStepIndex ? .done :
                                       (index == currentStepIndex ? .active : .pending)
        return VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(status.bgColor(palette: p))
                    .frame(width: 22, height: 22)
                switch status {
                case .done:
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                case .active:
                    PulsingDot(color: .white, size: 7)
                case .pending:
                    Circle().fill(p.ink35).frame(width: 6, height: 6)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(step.label)
                    .font(.ui(size: 12, weight: .semibold))
                    .foregroundColor(p.ink)
                Text(step.sub)
                    .font(.ui(size: 10.5))
                    .foregroundColor(p.ink50)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(status == .active ? AnyShapeStyle(p.brandGradientSoft) : AnyShapeStyle(p.surface))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(status == .active ? Color.clear : p.line, lineWidth: 0.5)
        )
        .opacity(status == .pending ? 0.55 : 1)
    }

    private enum PipelineStatus {
        case done, active, pending

        func bgColor(palette p: ThemePalette) -> Color {
            switch self {
            case .done: return p.success
            case .active: return p.accent
            case .pending: return p.ink10
            }
        }
    }

    // MARK: - Live stream card

    private var liveStreamCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("실시간 전사")
                    .font(.ui(size: 11, weight: .heavy))
                    .foregroundColor(p.ink50)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if !liveText.isEmpty {
                    HStack(spacing: 5) {
                        PulsingDot(color: p.accent, size: 6)
                        Text("스트리밍 중")
                            .font(.ui(size: 10.5, weight: .semibold))
                            .foregroundColor(p.accent)
                    }
                }
            }
            ScrollView {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(displayedLiveText)
                        .font(.ui(size: 13.5))
                        .foregroundColor(liveText.isEmpty ? p.ink50 : p.ink)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .italic(liveText.isEmpty)
                    if !liveText.isEmpty {
                        BlinkingCaret(color: p.accent)
                            .frame(width: 2, height: 16)
                    }
                }
                .padding(.bottom, 2)
            }
            .frame(minHeight: 60, maxHeight: 200)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(p.line, lineWidth: 0.5)
        )
    }

    // MARK: - Model conversation card (회의록 생성 단계)

    private var modelConversationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("모델 대화")
                    .font(.ui(size: 11, weight: .heavy))
                    .foregroundColor(p.ink50)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if !responseLive.isEmpty {
                    HStack(spacing: 5) {
                        PulsingDot(color: p.accent, size: 6)
                        Text("스트리밍 중")
                            .font(.ui(size: 10.5, weight: .semibold))
                            .foregroundColor(p.accent)
                    }
                }
            }

            // 보낸 요청
            chatBubble(role: "요청", roleColor: p.ink50) {
                VStack(alignment: .leading, spacing: 8) {
                    if !promptPreview.isEmpty {
                        ScrollView {
                            Text(promptPreview)
                                .font(.ui(size: 12))
                                .foregroundColor(p.ink70)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 84)
                    }
                    if transcriptChars > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 10))
                            Text("전사본 \(transcriptChars.formatted())자 첨부")
                                .font(.mono(size: 10.5))
                        }
                        .foregroundColor(p.ink50)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(p.surface))
                    }
                }
            }

            // 모델 응답 (실시간)
            chatBubble(role: engineName, roleColor: p.accent) {
                if responseLive.isEmpty {
                    HStack(spacing: 8) {
                        PulsingDot(color: p.accent, size: 6)
                        Text("응답 작성 중…")
                            .font(.ui(size: 13))
                            .foregroundColor(p.ink50)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(responseLive)
                                .font(.ui(size: 13.5))
                                .foregroundColor(p.ink)
                                .lineSpacing(5)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            BlinkingCaret(color: p.accent)
                                .frame(width: 2, height: 16)
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(p.line, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func chatBubble<Content: View>(
        role: String,
        roleColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(role)
                .font(.ui(size: 10.5, weight: .heavy))
                .foregroundColor(roleColor)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(p.surfaceMuted)
                )
        }
    }

    private var displayedLiveText: String {
        if liveText.isEmpty {
            switch stage {
            case .loadingAudio, .preparingWhisper:
                return "모델을 준비하고 있어요. 곧 전사가 시작됩니다…"
            case .preparingSpeaker, .diarizing:
                return "전사가 끝나고 화자를 분리하는 중입니다."
            case .generatingMinutes:
                return "\(engineName)(이)가 회의록을 작성하고 있습니다."
            default:
                return "처리를 시작하고 있어요…"
            }
        }
        return liveText
    }
}

/// 80-bar 애니메이션 waveform — playhead 근처는 wobble.
struct AnimatedProgressWave: View {
    let palette: ThemePalette
    let progress: Double

    private static let bars: [CGFloat] = (0..<80).map { i in
        let seed = sin(Double(i) * 1.7) * 0.5 + cos(Double(i) * 0.4) * 0.5
        return CGFloat(0.25 + abs(seed) * 0.7 + sin(Double(i) * 0.3) * 0.15)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { context in
            let tick = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(Self.bars.indices, id: \.self) { i in
                        let frac = Double(i) / Double(Self.bars.count)
                        let isPast = frac < progress
                        let isHead = abs(frac - progress) < 0.02
                        let wobble: CGFloat = isHead ? 1 + CGFloat(sin(tick * 5 + Double(i)) * 0.3) : 1
                        let h = max(2, 90 * Self.bars[i] * wobble)
                        Capsule()
                            .fill(isPast ? AnyShapeStyle(palette.brandGradient) : AnyShapeStyle(palette.ink10))
                            .frame(maxWidth: .infinity)
                            .frame(height: h)
                            .opacity(isHead ? 1 : (isPast ? 1 : 0.6))
                    }
                }
                .frame(width: geo.size.width, height: 90, alignment: .center)
            }
        }
    }
}

struct PulsingDot: View {
    let color: Color
    var size: CGFloat = 7

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let scale = 0.7 + 0.3 * abs(sin(t * 3))
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .opacity(scale)
        }
    }
}

struct BlinkingCaret: View {
    let color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let visible = (Int(t * 2) % 2) == 0
            Rectangle()
                .fill(color)
                .opacity(visible ? 1 : 0)
        }
    }
}
