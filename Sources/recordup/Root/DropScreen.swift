import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DropScreen: View {
    let lastError: String?
    let isFailed: Bool
    let recents: [MinutesEntry]
    let onPickFile: (URL) -> Void
    let onShowAll: () -> Void
    let onPickRecent: (MinutesEntry) -> Void
    let onOpenTemplates: () -> Void

    @Environment(\.palette) private var p
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                breadcrumb: "새 회의록",
                breadcrumbDetail: "음성 메모를 끌어오세요",
                trailing: {
                    AnyView(
                        HStack(spacing: 8) {
                            Button { openFilePicker() } label: {
                                Label("파일 열기…", systemImage: "folder")
                            }
                            .buttonStyle(GhostButtonStyle(palette: p))
                            Button { onOpenTemplates() } label: {
                                Image(systemName: "gearshape")
                            }
                            .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
                        }
                    )
                }
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    sectionTitle
                    dropZone
                    importOptions
                    if !recents.isEmpty {
                        continueSection
                    }
                    if let err = lastError, isFailed {
                        errorBanner(err)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Title

    private var sectionTitle: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("음성 메모를 떨어뜨리세요.")
                .font(.display(size: 32, weight: .bold))
                .foregroundColor(p.ink)
            Text("한국어 전사·화자 분리는 이 Mac에서 처리돼 오디오가 외부로 전송되지 않아요. 회의록 생성 시에는 전사본 텍스트가 선택한 AI 서비스로 전송됩니다.")
                .font(.ui(size: 14))
                .foregroundColor(p.ink70)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Drop zone

    private var decorativeWaveform: some View {
        AnimatedDropWave(palette: p, emphasized: isTargeted)
            .opacity(isTargeted ? 0.6 : 0.28)
            .allowsHitTesting(false)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(p.surface)
                .shadow(color: .black.opacity(p.isDark ? 0.25 : 0.04), radius: 8, y: 2)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isTargeted ? AnyShapeStyle(p.brandGradient) : AnyShapeStyle(p.line),
                    style: StrokeStyle(lineWidth: isTargeted ? 1.5 : 0.5, dash: isTargeted ? [] : [5])
                )
            decorativeWaveform

            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(p.brandGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: p.accent2.opacity(0.35), radius: 14, y: 4)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(spacing: 6) {
                    Text(isTargeted ? "여기에 떨어뜨리세요" : "음성 메모를 끌어다 놓으세요")
                        .font(.display(size: 16, weight: .semibold))
                        .foregroundColor(p.ink)
                    Button("또는 클릭해서 파일 선택") { openFilePicker() }
                        .buttonStyle(.plain)
                        .font(.ui(size: 13, weight: .medium))
                        .foregroundColor(p.accent)
                }
            }

            HStack {
                Text("음성 메모  ·  .m4a  ·  .mp3  ·  .wav  ·  .aac")
                    .font(.mono(size: 11))
                    .foregroundColor(p.ink35)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("WhisperKit · large-v3-turbo")
                        .font(.mono(size: 11))
                }
                .foregroundColor(p.ink50)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 280)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            openFilePicker()
        }
        .onDrop(of: [.fileURL, .audio, .item, .data], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Import options

    private var importOptions: some View {
        HStack(spacing: 14) {
            importCard(
                icon: "folder.badge.plus",
                title: "음성 메모 앱에서 불러오기",
                subtitle: "iCloud Voice Memos",
                disabled: false,
                action: {
                    openFilePicker(
                        startIn: voiceMemosDirectory(),
                        message: "음성 메모 녹음(.m4a)을 선택하세요"
                    )
                }
            )
            importCard(
                icon: "globe",
                title: "URL에서 가져오기",
                subtitle: "Google Meet · Zoom 녹음",
                disabled: true,
                action: {}
            )
            importCard(
                icon: "speaker.wave.2",
                title: "이 Mac에서 직접 녹음",
                subtitle: "시스템 오디오 + 마이크",
                disabled: true,
                action: {}
            )
        }
    }

    private func importCard(
        icon: String,
        title: String,
        subtitle: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(p.surfaceMuted)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(p.ink70)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.ui(size: 13, weight: .semibold))
                            .foregroundColor(p.ink)
                        if disabled {
                            Text("v2")
                                .font(.mono(size: 9, weight: .semibold))
                                .foregroundColor(p.ink50)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(p.ink10)
                                )
                        }
                    }
                    Text(subtitle)
                        .font(.ui(size: 12))
                        .foregroundColor(p.ink50)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 92)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(p.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(p.line, lineWidth: 0.5)
            )
            .opacity(disabled ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - Continue

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("이어서 작업하기")
                    .font(.ui(size: 12, weight: .semibold))
                    .foregroundColor(p.ink70)
                Spacer()
                Button {
                    onShowAll()
                } label: {
                    HStack(spacing: 4) {
                        Text("전체 보기")
                        Image(systemName: "arrow.right")
                    }
                    .font(.ui(size: 12, weight: .medium))
                    .foregroundColor(p.accent)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 12) {
                ForEach(recents.prefix(2)) { entry in
                    continueCard(entry)
                }
                if recents.count == 1 {
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func continueCard(_ entry: MinutesEntry) -> some View {
        Button {
            onPickRecent(entry)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(entry.title)
                        .font(.ui(size: 13, weight: .semibold))
                        .foregroundColor(p.ink)
                        .lineLimit(1)
                    Spacer()
                    if let elapsed = entry.elapsedSeconds {
                        Text(TranscriptExporter.formatTime(elapsed))
                            .font(.mono(size: 11))
                            .foregroundColor(p.ink50)
                    }
                }
                HStack(spacing: 8) {
                    Text(DateFormatters.short(entry.createdAt))
                        .font(.ui(size: 11))
                        .foregroundColor(p.ink50)
                    if let speakers = entry.speakerCount {
                        Text("·").foregroundColor(p.ink35)
                        Text("화자 \(speakers)명")
                            .font(.ui(size: 11))
                            .foregroundColor(p.ink50)
                    }
                    Text("·").foregroundColor(p.ink35)
                    Text("결정 \(entry.decisionCount)")
                        .font(.ui(size: 11, weight: .semibold))
                        .foregroundColor(p.decision)
                    Text("액션 \(entry.actionCount)")
                        .font(.ui(size: 11, weight: .semibold))
                        .foregroundColor(p.action)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(p.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(p.line, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error

    private func errorBanner(_ msg: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(p.accent2)
            VStack(alignment: .leading, spacing: 4) {
                Text("처리 실패")
                    .font(.ui(size: 13, weight: .semibold))
                    .foregroundColor(p.ink)
                Text(msg)
                    .font(.ui(size: 12))
                    .foregroundColor(p.ink70)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(p.accent2Soft)
        )
    }

    // MARK: - File handling

    private func openFilePicker(startIn directory: URL? = nil, message: String? = nil) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, UTType("com.apple.m4a-audio") ?? .audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if let directory { panel.directoryURL = directory }
        if let message { panel.message = message }
        if panel.runModal() == .OK, let url = panel.url {
            onPickFile(url)
        }
    }

    /// Apple 음성 메모(Voice Memos) 녹음이 저장되는 폴더. 없으면 nil(기본 위치 사용).
    /// 폴더 자체는 TCC 보호 대상이지만, NSOpenPanel(powerbox)은 사용자가 직접 고르게 해준다.
    private func voiceMemosDirectory() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            "Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings",
            "Library/Application Support/com.apple.voicememos/Recordings",
        ]
        for rel in candidates {
            let url = home.appending(path: rel, directoryHint: .isDirectory)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        DebugLog.log("[drop] received providers=\(providers.count)")
        guard let provider = providers.first else { return false }

        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, err in
                DebugLog.log("[drop] loadObject(URL) → \(url?.path ?? "nil") err=\(err?.localizedDescription ?? "nil")")
                if let url {
                    DispatchQueue.main.async { onPickFile(url) }
                }
            }
            return true
        }

        let fileURLType = UTType.fileURL.identifier
        if provider.hasItemConformingToTypeIdentifier(fileURLType) {
            provider.loadItem(forTypeIdentifier: fileURLType, options: nil) { item, err in
                var resolved: URL?
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    resolved = url
                } else if let url = item as? URL {
                    resolved = url
                }
                DebugLog.log("[drop] loadItem(fileURL) → \(resolved?.path ?? "nil") err=\(err?.localizedDescription ?? "nil")")
                if let url = resolved {
                    DispatchQueue.main.async { onPickFile(url) }
                }
            }
            return true
        }

        if let firstAudio = provider.registeredTypeIdentifiers.first(where: { UTType($0)?.conforms(to: .audio) ?? false }) {
            provider.loadFileRepresentation(forTypeIdentifier: firstAudio) { url, err in
                DebugLog.log("[drop] loadFileRepresentation(\(firstAudio)) → \(url?.path ?? "nil") err=\(err?.localizedDescription ?? "nil")")
                if let url {
                    // 파일명이 회의 제목으로 쓰이므로 UUID는 폴더에만 붙인다.
                    let dir = FileManager.default.temporaryDirectory
                        .appending(path: "recordup-drop-\(UUID().uuidString)", directoryHint: .isDirectory)
                    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    let tmp = dir.appending(path: url.lastPathComponent)
                    try? FileManager.default.copyItem(at: url, to: tmp)
                    DispatchQueue.main.async { onPickFile(tmp) }
                }
            }
            return true
        }

        DebugLog.log("[drop] no usable representation")
        return false
    }
}
