import AppKit
import SwiftUI

/// 전사본 검토 — 채팅형 화자 블록 + 우측 화자 관리 + 하단 재생.
struct TranscriptReviewView: View {
    @ObservedObject var transcript: EditableTranscript
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.palette) private var p
    @StateObject private var audio = AudioPlayerEngine()
    @State private var editingID: UUID?
    @State private var hoverID: UUID?
    @State private var pickerForID: UUID?
    @State private var colorPickerForSpeaker: Int?
    @State private var searchOpen: Bool = false
    @State private var searchQuery: String = ""
    @State private var searchIdx: Int = 0
    @State private var activeID: UUID?

    private var playhead: Double { audio.playhead }
    private var isPlaying: Bool { audio.isPlaying }

    private func speakerColor(_ id: Int?) -> Color {
        SpeakerPalette.color(for: id)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                topToolbar
                if searchOpen { searchBar }
                metaHeader
                HStack(spacing: 0) {
                    segmentList
                    Divider().background(p.line)
                    rightPanel
                        .frame(width: 280)
                        .background(p.canvas.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.bottom, 80)
            audioDock
        }
        .onAppear {
            if activeID == nil { activeID = transcript.segments.first?.id }
            audio.load(url: transcript.sourceURL)
        }
        .onChange(of: audio.playhead) { _, newValue in
            updateActiveSegment(for: newValue)
        }
    }

    private func updateActiveSegment(for time: Double) {
        guard !transcript.segments.isEmpty else { return }
        let match = transcript.segments.last(where: { $0.startTime <= time + 0.001 })
            ?? transcript.segments.first
        if let m = match, activeID != m.id {
            activeID = m.id
        }
    }

    // MARK: - Top toolbar

    private var topToolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("새 회의록 → 1단계")
                    .font(.ui(size: 11))
                    .foregroundColor(p.ink50)
                HStack(spacing: 8) {
                    Text("전사본 검토")
                        .font(.display(size: 14.5, weight: .semibold))
                        .foregroundColor(p.ink)
                    Text("화자와 문장을 다듬어주세요")
                        .font(.ui(size: 12))
                        .foregroundColor(p.ink50)
                }
            }
            Spacer()
            Button("취소", action: onCancel)
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            Button {
                onConfirm()
            } label: {
                Label("회의록 생성", systemImage: "sparkle")
            }
            .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
            .disabled(transcript.segments.isEmpty)
        }
        .padding(.horizontal, 24)
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    // MARK: - Search bar

    private var matches: [UUID] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return transcript.segments.filter { $0.text.lowercased().contains(q) }.map { $0.id }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(p.ink50)
            TextField("전사본에서 찾기…", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.ui(size: 13))
                .foregroundColor(p.ink)
                .onChange(of: searchQuery) { _, _ in searchIdx = 0 }
                .onSubmit {
                    if !matches.isEmpty {
                        searchIdx = (searchIdx + 1) % matches.count
                        activeID = matches[searchIdx]
                    }
                }
            if !searchQuery.isEmpty {
                Text(matches.isEmpty ? "결과 없음" : "\(searchIdx + 1) / \(matches.count)")
                    .font(.mono(size: 11))
                    .foregroundColor(matches.isEmpty ? p.ink35 : p.ink70)
            }
            Button {
                if !matches.isEmpty {
                    searchIdx = (searchIdx - 1 + matches.count) % matches.count
                    activeID = matches[searchIdx]
                }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 11))
                    .foregroundColor(p.ink70)
                    .frame(width: 26, height: 24)
                    .background(RoundedRectangle(cornerRadius: 5).fill(p.surface))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(p.line, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(matches.isEmpty)
            Button {
                if !matches.isEmpty {
                    searchIdx = (searchIdx + 1) % matches.count
                    activeID = matches[searchIdx]
                }
            } label: {
                Image(systemName: "arrow.down")
                    .font(.system(size: 11))
                    .foregroundColor(p.ink70)
                    .frame(width: 26, height: 24)
                    .background(RoundedRectangle(cornerRadius: 5).fill(p.surface))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(p.line, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(matches.isEmpty)
            Button {
                searchOpen = false
                searchQuery = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(p.ink50)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(p.surfaceMuted)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    // MARK: - Meta header

    private var metaHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(transcript.sourceURL.deletingPathExtension().lastPathComponent)
                .font(.display(size: 16, weight: .semibold))
                .foregroundColor(p.ink)
                .lineLimit(1)
            HStack(spacing: 6) {
                metaText(TranscriptExporter.formatTime(transcript.durationSeconds))
                metaSep()
                metaText("\(transcript.registeredSpeakerCount)명")
                metaSep()
                metaText("\(transcript.segments.count)개 구간")
                metaSep()
                metaText("신뢰도 96.4%")
            }
            .padding(.leading, 12)
            Spacer()
            Button {
                searchOpen.toggle()
                if !searchOpen { searchQuery = "" }
            } label: {
                Label("찾기", systemImage: "magnifyingglass")
            }
            .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            Button {
                transcript.addSpeaker()
            } label: {
                Label("화자 관리", systemImage: "person.2")
            }
            .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    private func metaText(_ s: String) -> some View {
        Text(s)
            .font(.mono(size: 11))
            .foregroundColor(p.ink50)
    }
    private func metaSep() -> some View {
        Text("·").font(.mono(size: 11)).foregroundColor(p.ink20)
    }

    // MARK: - Segment list

    private var segmentList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(transcript.segments) { seg in
                        segmentRow(seg)
                            .id(seg.id)
                            .onHover { h in hoverID = h ? seg.id : (hoverID == seg.id ? nil : hoverID) }
                    }
                    addSegmentButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .onChange(of: activeID) { _, newVal in
                if let id = newVal {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func segmentRow(_ seg: EditableSegment) -> some View {
        let speakerColor = speakerColor(seg.speakerId)
        let isEditing = editingID == seg.id
        let isActive = activeID == seg.id
        let isHover = hoverID == seg.id
        let initial = String(transcript.displayName(for: seg.speakerId).prefix(1))
        return HStack(alignment: .top, spacing: 12) {
            // Timestamp button
            Button {
                audio.seek(to: seg.startTime)
                activeID = seg.id
            } label: {
                Text(TranscriptExporter.formatTime(seg.startTime))
                    .font(.mono(size: 11, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? p.accent : p.ink50)
                    .frame(width: 60, alignment: .trailing)
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)

            // Speaker avatar
            ZStack {
                Circle().fill(speakerColor).frame(width: 28, height: 28)
                Text(initial)
                    .font(.ui(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                ZStack {
                    if let pid = pickerForID, pid == seg.id {
                        speakerPickerPopup(for: seg)
                            .offset(y: 36)
                    }
                },
                alignment: .top
            )
            .onTapGesture {
                pickerForID = pickerForID == seg.id ? nil : seg.id
            }

            // Text + speaker name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(transcript.displayName(for: seg.speakerId))
                        .font(.ui(size: 11, weight: .semibold))
                        .foregroundColor(speakerColor)
                    if isEditing {
                        Text("편집 중")
                            .font(.ui(size: 9.5, weight: .heavy))
                            .foregroundColor(p.accent)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3).fill(p.accentSoft)
                            )
                    }
                    Spacer()
                }
                if isEditing {
                    TextEditor(text: textBinding(for: seg.id))
                        .font(.ui(size: 13))
                        .foregroundColor(p.ink)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, -5)
                        .frame(minHeight: 50)
                } else {
                    highlightedText(seg.text, isActiveMatch: matches[safe: searchIdx] == seg.id)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .contentShape(Rectangle())
                        .onTapGesture { editingID = seg.id }
                }
            }

            // Action buttons
            HStack(spacing: 4) {
                actionBtn(systemName: isEditing ? "checkmark" : "pencil", accent: isEditing) {
                    editingID = isEditing ? nil : seg.id
                }
                actionBtn(systemName: "play.fill") {
                    activeID = seg.id
                    audio.playFrom(seg.startTime)
                }
                actionBtn(systemName: "plus") {
                    if let idx = transcript.segments.firstIndex(where: { $0.id == seg.id }) {
                        transcript.insertSegment(after: idx)
                    }
                }
                actionBtn(systemName: "trash", danger: true) {
                    if let idx = transcript.segments.firstIndex(where: { $0.id == seg.id }) {
                        transcript.removeSegment(at: idx)
                    }
                }
            }
            .opacity(isHover || isEditing ? 1 : 0.45)
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground(isEditing: isEditing, isActive: isActive))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isEditing ? p.accent : Color.clear, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func rowBackground(isEditing: Bool, isActive: Bool) -> some View {
        if isEditing {
            RoundedRectangle(cornerRadius: 10).fill(p.surfaceMuted)
        } else if isActive {
            RoundedRectangle(cornerRadius: 10).fill(p.brandGradientSoft)
        } else {
            Color.clear
        }
    }

    private func highlightedText(_ text: String, isActiveMatch: Bool) -> some View {
        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            return AnyView(
                Text("클릭하여 텍스트 입력…")
                    .font(.ui(size: 13))
                    .foregroundColor(p.ink35)
                    .italic()
            )
        }
        guard !q.isEmpty, text.lowercased().contains(q.lowercased()) else {
            return AnyView(
                Text(text)
                    .font(.ui(size: 13))
                    .foregroundColor(p.ink)
                    .lineSpacing(4)
            )
        }
        // AttributedString으로 매치 하이라이트
        var attr = AttributedString(text)
        let lower = text.lowercased()
        let needle = q.lowercased()
        var searchRange = lower.startIndex..<lower.endIndex
        while let r = lower.range(of: needle, range: searchRange) {
            let attrLow = AttributedString.Index(r.lowerBound, within: attr) ?? attr.startIndex
            let attrHigh = AttributedString.Index(r.upperBound, within: attr) ?? attr.endIndex
            attr[attrLow..<attrHigh].backgroundColor = isActiveMatch
                ? Color.yellow.opacity(0.65)
                : Color.yellow.opacity(0.35)
            searchRange = r.upperBound..<lower.endIndex
        }
        return AnyView(
            Text(attr)
                .font(.ui(size: 13))
                .foregroundColor(p.ink)
                .lineSpacing(4)
        )
    }

    private func actionBtn(systemName: String, accent: Bool = false, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent ? .white : (danger ? p.accent2 : p.ink70))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accent ? p.accent : p.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(accent ? Color.clear : p.line, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Speaker picker popup

    private func speakerPickerPopup(for seg: EditableSegment) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("이 구간 화자 변경")
                .font(.ui(size: 9.5, weight: .heavy))
                .foregroundColor(p.ink50)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 2)
            ForEach(transcript.registeredSpeakerIds, id: \.self) { id in
                Button {
                    if let idx = transcript.segments.firstIndex(where: { $0.id == seg.id }) {
                        transcript.setSpeaker(id, forSegmentAt: idx)
                    }
                    pickerForID = nil
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(speakerColor(id))
                                .frame(width: 18, height: 18)
                            Text(String(transcript.displayName(for: id).prefix(1)))
                                .font(.ui(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text(transcript.displayName(for: id))
                            .font(.ui(size: 12))
                            .foregroundColor(p.ink)
                        Spacer()
                        if seg.speakerId == id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(p.accent)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .frame(width: 160)
        .background(p.surface)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9).stroke(p.lineStrong, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(p.isDark ? 0.4 : 0.12), radius: 8, y: 4)
        .zIndex(20)
    }

    // MARK: - Add segment + end divider

    private var addSegmentButton: some View {
        Button {
            transcript.insertSegment(after: transcript.segments.count - 1)
            if let last = transcript.segments.last { editingID = last.id }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("새 구간 추가")
                    .font(.ui(size: 12.5, weight: .medium))
            }
            .foregroundColor(p.ink50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(p.lineStrong, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Right panel

    private var rightPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                speakerManageCard
                nextStepCard
            }
            .padding(18)
        }
    }

    private var speakerManageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("화자 관리")
                    .font(.ui(size: 11, weight: .heavy))
                    .foregroundColor(p.ink50)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Button {
                    transcript.addSpeaker()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("추가")
                            .font(.ui(size: 11, weight: .semibold))
                    }
                    .foregroundColor(p.accent)
                }
                .buttonStyle(.plain)
            }
            VStack(spacing: 6) {
                ForEach(transcript.registeredSpeakerIds, id: \.self) { id in
                    speakerRow(id: id)
                }
            }
            speakerShareBar
        }
    }

    private func speakerRow(id: Int) -> some View {
        let color = speakerColor(id)
        let canDelete = transcript.registeredSpeakerIds.count > 1
        let share = speakerShare(id: id)
        return HStack(spacing: 8) {
            ZStack {
                Circle().fill(color).frame(width: 22, height: 22)
                Text(String(transcript.displayName(for: id).prefix(1)))
                    .font(.ui(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .onTapGesture {
                colorPickerForSpeaker = colorPickerForSpeaker == id ? nil : id
            }
            .overlay(
                ZStack {
                    if colorPickerForSpeaker == id {
                        colorPickerPopup(currentColor: color, onPick: { _ in
                            colorPickerForSpeaker = nil
                        })
                        .offset(y: 30)
                    }
                },
                alignment: .top
            )

            VStack(alignment: .leading, spacing: 1) {
                TextField("이름", text: nameBinding(for: id))
                    .textFieldStyle(.plain)
                    .font(.ui(size: 12.5, weight: .medium))
                    .foregroundColor(p.ink)
                Text("\(Int(share * 100))% 발화")
                    .font(.mono(size: 10))
                    .foregroundColor(p.ink50)
            }
            Spacer()
            if canDelete {
                Button {
                    transcript.removeSpeaker(id: id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(p.ink50)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(p.line, lineWidth: 0.5)
        )
    }

    private func colorPickerPopup(currentColor: Color, onPick: @escaping (Color) -> Void) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(20), spacing: 6), count: 4),
            spacing: 6
        ) {
            ForEach(SpeakerPalette.colors.indices, id: \.self) { i in
                Button {
                    onPick(SpeakerPalette.colors[i])
                } label: {
                    Circle()
                        .fill(SpeakerPalette.colors[i])
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle().stroke(p.ink, lineWidth: 0)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(p.surface)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9).stroke(p.lineStrong, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(p.isDark ? 0.4 : 0.12), radius: 8, y: 4)
        .zIndex(20)
    }

    private var speakerShareBar: some View {
        let segments = transcript.segments
        let shares: [(Int, Double, Color)] = transcript.registeredSpeakerIds.map { id in
            let dur = segments.filter { $0.speakerId == id }
                .reduce(0.0) { $0 + max(0, $1.endTime - $1.startTime) }
            return (id, dur, speakerColor(id))
        }
        let total = max(0.001, shares.reduce(0) { $0 + $1.1 })
        return GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(shares, id: \.0) { tuple in
                    Rectangle()
                        .fill(tuple.2)
                        .frame(width: max(2, CGFloat(tuple.1 / total) * geo.size.width))
                }
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
    }

    private func speakerShare(id: Int) -> Double {
        let total = transcript.segments.reduce(0.0) { $0 + max(0, $1.endTime - $1.startTime) }
        guard total > 0 else { return 0 }
        let mine = transcript.segments
            .filter { $0.speakerId == id }
            .reduce(0.0) { $0 + max(0, $1.endTime - $1.startTime) }
        return mine / total
    }

    private var nextStepCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11))
                    .foregroundColor(p.accent)
                Text("다음 단계")
                    .font(.ui(size: 11, weight: .heavy))
                    .foregroundColor(p.ink70)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            Text("검토를 마치면 결정·액션 추출 템플릿으로 회의록을 생성합니다.")
                .font(.ui(size: 12))
                .foregroundColor(p.ink70)
                .lineSpacing(3)
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundColor(p.ink50)
                Text("decision-action.md")
                    .font(.mono(size: 11))
                    .foregroundColor(p.ink70)
                Spacer()
                Text("변경")
                    .font(.ui(size: 11, weight: .semibold))
                    .foregroundColor(p.accent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(p.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(p.line, lineWidth: 0.5)
        )
    }

    // MARK: - Audio dock

    private var audioDock: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                dockIconBtn("arrow.left") {
                    audio.seek(by: -10)
                }
                Button {
                    audio.toggle()
                } label: {
                    ZStack {
                        Circle().fill(p.brandGradient).frame(width: 36, height: 36)
                            .shadow(color: p.accent2.opacity(0.30), radius: 4, y: 2)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                dockIconBtn("arrow.right") {
                    audio.seek(by: 10)
                }
            }

            Text("\(TranscriptExporter.formatTime(playhead)) / \(TranscriptExporter.formatTime(transcript.durationSeconds))")
                .font(.mono(size: 12))
                .foregroundColor(p.ink)

            DockWaveform(
                palette: p,
                total: transcript.durationSeconds,
                playhead: Binding(
                    get: { audio.playhead },
                    set: { audio.seek(to: $0) }
                )
            )
                .frame(maxWidth: .infinity)
                .frame(height: 32)

            HStack(spacing: 6) {
                Text("1.0×")
                    .font(.mono(size: 11))
                    .foregroundColor(p.ink50)
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 12))
                    .foregroundColor(p.ink50)
            }
            Rectangle().fill(p.line).frame(width: 1, height: 22)
            Button("다시 시작") {
                audio.restart()
            }
            .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            Button {
                onConfirm()
            } label: {
                Label("회의록 생성하기", systemImage: "sparkle")
            }
            .buttonStyle(BrandButtonStyle(size: .md, palette: p))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(height: 80)
        .background(p.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private func dockIconBtn(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 12))
                .foregroundColor(p.ink70)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(p.line, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bindings

    private func nameBinding(for id: Int) -> Binding<String> {
        Binding(
            get: { transcript.speakerNames[id] ?? "" },
            set: { transcript.speakerNames[id] = $0 }
        )
    }

    private func textBinding(for segmentID: UUID) -> Binding<String> {
        Binding(
            get: {
                transcript.segments.first(where: { $0.id == segmentID })?.text ?? ""
            },
            set: { newValue in
                guard let idx = transcript.segments.firstIndex(where: { $0.id == segmentID }) else { return }
                transcript.segments[idx].text = newValue
            }
        )
    }
}

/// 클릭으로 seek 가능한 dock 파형. 캐시된 막대 + 진행 표시.
struct DockWaveform: View {
    let palette: ThemePalette
    let total: Double
    @Binding var playhead: Double

    private static let bars: [CGFloat] = (0..<240).map { i in
        let seed = sin(Double(i) * 0.41) + cos(Double(i) * 0.17) + sin(Double(i) * 1.3) * 0.5
        return CGFloat(0.18 + abs(seed) * 0.5)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack(spacing: 1.5) {
                    ForEach(Self.bars.indices, id: \.self) { i in
                        let frac = Double(i) / Double(Self.bars.count)
                        let isPast = frac < (total > 0 ? playhead / total : 0)
                        Capsule()
                            .fill(isPast ? palette.accent : palette.ink20)
                            .frame(maxWidth: .infinity, maxHeight: 28 * Self.bars[i])
                    }
                }
                .frame(height: 28)
                if total > 0 {
                    Rectangle()
                        .fill(palette.accent2)
                        .frame(width: 2, height: 28)
                        .offset(x: CGFloat(playhead / total) * geo.size.width - 1)
                        .shadow(color: palette.accent2.opacity(0.7), radius: 4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let ratio = max(0, min(1, location.x / max(1, geo.size.width)))
                playhead = total * Double(ratio)
            }
        }
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
