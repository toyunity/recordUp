import AppKit
import SwiftUI

enum SettingsCategory: String, CaseIterable, Identifiable {
    case storage, connections, about
    var id: String { rawValue }
    var label: String {
        switch self {
        case .storage: return "저장 위치"
        case .connections: return "AI 도구"
        case .about: return "정보"
        }
    }
    var icon: String {
        switch self {
        case .storage: return "folder"
        case .connections: return "cpu"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @Environment(\.palette) private var p
    @AppStorage(AppTheme.storageKey) private var themeRaw: String = AppTheme.warm.rawValue
    @State private var category: SettingsCategory = .storage
    @State private var showReleaseNotes: Bool = false
    @State private var releaseNotes: [ReleaseNote] = []
    @StateObject private var connections = ConnectionsModel()
    @AppStorage("autoDeleteAudio") private var autoDeleteAudio: Bool = true
    @AppStorage("autoOpenMinutes") private var autoOpenMinutes: Bool = true
    @AppStorage("syncICloud") private var syncICloud: Bool = false

    private var theme: AppTheme {
        AppTheme(rawValue: themeRaw) ?? .warm
    }

    private var latestRelease: ReleaseNote? { releaseNotes.first }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(breadcrumb: "설정", breadcrumbDetail: "저장 위치 · AI 도구 · 정보")
            HStack(spacing: 0) {
                categorySidebar
                    .frame(width: 200)
                    .background(p.canvas.opacity(0.5))
                Divider().background(p.line)
                ScrollView {
                    panel
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)
                }
            }
        }
        .onAppear {
            releaseNotes = ReleaseNotesStore.loadAll()
        }
        .sheet(isPresented: $showReleaseNotes) {
            ReleaseNotesSheet(palette: p, notes: releaseNotes) {
                showReleaseNotes = false
            }
        }
    }

    // MARK: - Sidebar

    private var categorySidebar: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("설정")
                .font(.ui(size: 11, weight: .heavy))
                .foregroundColor(p.ink50)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 10)
            ForEach(SettingsCategory.allCases) { cat in
                categoryRow(cat)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func categoryRow(_ cat: SettingsCategory) -> some View {
        let active = category == cat
        return Button {
            category = cat
        } label: {
            HStack(spacing: 8) {
                Image(systemName: cat.icon)
                    .font(.system(size: 13))
                    .foregroundColor(active ? p.ink : p.ink70)
                    .frame(width: 18)
                Text(cat.label)
                    .font(.ui(size: 12.5, weight: active ? .semibold : .medium))
                    .foregroundColor(active ? p.ink : p.ink70)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(active ? p.surface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(active ? p.lineStrong : Color.clear, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }

    // MARK: - Panel

    @ViewBuilder
    private var panel: some View {
        switch category {
        case .storage: storagePanel
        case .connections: connectionsPanel
        case .about: aboutPanel
        }
    }

    // MARK: Storage

    private var storagePanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            panelHero(title: "저장 위치", description: "모든 결과물은 본인의 Mac에만 저장됩니다.")

            VStack(spacing: 6) {
                pathCard(
                    label: "모델 캐시",
                    path: AppPaths.modelCachePath,
                    size: estimatedSize(at: AppPaths.modelCachePath)
                )
            }

            VStack(spacing: 6) {
                toggleRow(
                    label: "처리 후 원본 오디오 삭제",
                    sub: "회의록 저장이 완료되면 .m4a 파일을 삭제합니다.",
                    isOn: $autoDeleteAudio,
                    disabledBadge: "준비 중"
                )
                toggleRow(
                    label: "회의록 자동 열기",
                    sub: "처리 완료 후 기본 마크다운 에디터로 엽니다.",
                    isOn: $autoOpenMinutes
                )
                toggleRow(
                    label: "iCloud Drive로 동기화",
                    sub: "회의록만 동기화됩니다 (베타).",
                    isOn: $syncICloud,
                    disabledBadge: "v2 예정"
                )
            }
        }
    }

    private func pathCard(label: String, path: String, size: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 14))
                .foregroundColor(p.ink50)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.ui(size: 12.5, weight: .semibold))
                    .foregroundColor(p.ink)
                Text(path)
                    .font(.mono(size: 11))
                    .foregroundColor(p.ink50)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text(size)
                .font(.mono(size: 11, weight: .medium))
                .foregroundColor(p.ink70)
            Button("폴더 열기") {
                let url = URL(fileURLWithPath: path)
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                NSWorkspace.shared.open(url)
            }
            .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(p.line, lineWidth: 0.5)
        )
    }

    private func toggleRow(
        label: String, sub: String, isOn: Binding<Bool>,
        disabledBadge: String? = nil
    ) -> some View {
        let disabled = disabledBadge != nil
        return Button {
            if !disabled { isOn.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.ui(size: 12.5, weight: .semibold))
                            .foregroundColor(disabled ? p.ink50 : p.ink)
                        if let badge = disabledBadge {
                            statusBadge(badge)
                        }
                    }
                    Text(sub)
                        .font(.ui(size: 11))
                        .foregroundColor(p.ink50)
                }
                Spacer()
                ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isOn.wrappedValue ? p.accent : p.ink20)
                        .frame(width: 36, height: 22)
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .padding(2)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                }
                .animation(.easeInOut(duration: 0.15), value: isOn.wrappedValue)
                .opacity(disabled ? 0.5 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(p.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(p.line, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    /// "준비 중" 같은 작은 inline 배지.
    private func statusBadge(_ text: String) -> some View {
        Text(text)
            .font(.mono(size: 9, weight: .semibold))
            .foregroundColor(p.ink70)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3).fill(p.surfaceMuted)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3).stroke(p.line, lineWidth: 0.5)
            )
    }

    /// 하위 디렉터리까지 재귀적으로 합산한다. 모델 캐시처럼 nested 구조에서도 정확.
    private func estimatedSize(at path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else { return "—" }
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey]
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: keys,
                                             options: [.skipsHiddenFiles]) else {
            return "—"
        }
        var total: Int64 = 0
        for case let item as URL in enumerator {
            guard let v = try? item.resourceValues(forKeys: Set(keys)),
                  v.isRegularFile == true else { continue }
            let size = v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0
            total += Int64(size)
        }
        return formatBytes(total)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }

    // MARK: Connections (AI 도구)

    private var connectionsPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            panelHero(title: "AI 도구 연결", description: "회의록 생성에 사용할 로컬 AI CLI를 관리합니다.")

            VStack(alignment: .leading, spacing: 8) {
                Text("기본 생성 엔진")
                    .font(.ui(size: 11, weight: .heavy))
                    .foregroundColor(p.ink50)
                    .textCase(.uppercase)
                    .tracking(0.8)
                HStack(spacing: 8) {
                    ForEach(connections.statuses) { status in
                        engineChip(status)
                    }
                    Spacer(minLength: 0)
                }
            }

            VStack(spacing: 8) {
                ForEach(connections.statuses) { status in
                    toolCard(status)
                }
            }
        }
        .onAppear { connections.refreshAll() }
    }

    private func engineChip(_ status: AIToolStatus) -> some View {
        let isDefault = connections.defaultEngineID == status.tool.id
        let selectable = status.detected
        return Button {
            if selectable { connections.setDefault(status.tool) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isDefault ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(isDefault ? p.accent : p.ink35)
                Text(status.tool.name)
                    .font(.ui(size: 12.5, weight: isDefault ? .semibold : .medium))
                    .foregroundColor(selectable ? p.ink : p.ink35)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDefault ? p.accent.opacity(0.08) : p.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDefault ? p.accent : p.line, lineWidth: isDefault ? 1 : 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
        .help(selectable ? "기본 생성 엔진으로 설정" : "설치되지 않아 기본 엔진으로 선택할 수 없습니다")
    }

    private func toolCard(_ status: AIToolStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: status.tool.icon)
                    .font(.system(size: 14))
                    .foregroundColor(p.ink70)
                    .frame(width: 20)
                Text(status.tool.name)
                    .font(.ui(size: 13, weight: .semibold))
                    .foregroundColor(p.ink)
                if let version = status.version {
                    Text(version)
                        .font(.mono(size: 11))
                        .foregroundColor(p.ink50)
                }
                Spacer()
                detectionBadge(status)
                authBadge(status)
            }
            Text(status.path ?? "경로를 찾을 수 없습니다")
                .font(.mono(size: 11))
                .foregroundColor(status.path == nil ? p.ink35 : p.ink50)
                .lineLimit(1)
                .truncationMode(.middle)
            HStack(spacing: 8) {
                Button("자동 탐지") { connections.rediscover(status.tool) }
                    .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
                Button("경로 지정…") { chooseBinary(for: status.tool) }
                    .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
                Button("테스트") { connections.probe(status.tool) }
                    .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(p.line, lineWidth: 0.5)
        )
    }

    private func detectionBadge(_ status: AIToolStatus) -> some View {
        status.detected ? dotBadge("연결됨", color: p.accent) : dotBadge("미설치", color: p.ink35)
    }

    @ViewBuilder
    private func authBadge(_ status: AIToolStatus) -> some View {
        if status.detected {
            switch status.auth {
            case .loggedIn:  dotBadge("로그인", color: .green)
            case .loggedOut: dotBadge("로그아웃", color: p.ink35)
            case .checking:  dotBadge("확인 중", color: p.ink35)
            case .unknown:   dotBadge("확인 불가", color: p.ink35)
            }
        }
    }

    /// 컬러 점 + 텍스트의 작은 상태 배지.
    private func dotBadge(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.mono(size: 10, weight: .medium))
                .foregroundColor(p.ink70)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4).fill(p.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4).stroke(p.line, lineWidth: 0.5)
        )
    }

    /// NSOpenPanel로 도구 실행파일을 직접 지정한다. 실행 가능 파일만 저장.
    private func chooseBinary(for tool: AITool) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "\(tool.name) 실행파일 선택"
        panel.message = "\(tool.name) CLI의 실행 파일을 선택하세요."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if FileManager.default.isExecutableFile(atPath: url.path) {
            connections.setPath(url.path, for: tool)
        } else {
            let alert = NSAlert()
            alert.messageText = "실행할 수 없는 파일"
            alert.informativeText = "선택한 파일은 실행 권한이 없습니다:\n\(url.path)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "닫기")
            alert.runModal()
        }
    }

    // MARK: About

    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 16) {
                BrandMark(palette: p, size: 80)
                VStack(alignment: .leading, spacing: 4) {
                    BrandWordmark(palette: p, baseSize: 22, inkColor: p.ink70)
                    Text(versionLine())
                        .font(.mono(size: 12))
                        .foregroundColor(p.ink50)
                }
            }
            Text("음성 메모를 끌어다 놓으면 한국어 전사·화자 분리는 이 Mac에서 처리하고, 회의록은 본인의 AI CLI 구독으로 생성합니다.\n오디오는 외부로 전송되지 않으며, 회의록 생성 시 전사본 텍스트만 선택한 AI 서비스로 전송됩니다.")
                .font(.ui(size: 13))
                .foregroundColor(p.ink70)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            appearanceSection

            VStack(spacing: 0) {
                aboutRow("릴리스 노트", releaseNotesValue, pending: false) {
                    showReleaseNotes = true
                }
                aboutRow("개발/지원", "ethan@aijinet.com", pending: false) {
                    if let url = URL(string: "mailto:ethan@aijinet.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                aboutRow("오픈소스", "WhisperKit · Whisper · SpeakerKit", pending: false) {
                    showOpenSourceAlert()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10).fill(p.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(p.line, lineWidth: 0.5)
            )
        }
    }

    private var releaseNotesValue: String {
        guard let latest = latestRelease else { return "—" }
        if let highlight = latest.highlight, !highlight.isEmpty {
            return "v\(latest.version) — \(highlight)"
        }
        return "v\(latest.version)"
    }

    private func showOpenSourceAlert() {
        let alert = NSAlert()
        alert.messageText = "오픈소스 라이선스"
        alert.informativeText = """
        recordup은 다음 오픈소스 라이브러리를 사용합니다:

        • WhisperKit / SpeakerKit — 음성 인식·화자 분리 (MIT)
        • Whisper large-v3-turbo 모델 (MIT) · 토크나이저 (Apache-2.0)
        • SpeakerKit 화자 분리 모델 (CC BY 4.0)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "닫기")
        alert.addButton(withTitle: "전체 고지 보기")
        if alert.runModal() == .alertSecondButtonReturn,
           let url = Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "md") {
            NSWorkspace.shared.open(url)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("외관")
                .font(.ui(size: 11, weight: .heavy))
                .foregroundColor(p.ink50)
                .textCase(.uppercase)
                .tracking(0.8)
            HStack(spacing: 12) {
                ForEach(AppTheme.allCases) { t in
                    themeMiniCard(t)
                }
            }
        }
    }

    private func aboutRow(_ key: String, _ value: String, pending: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(key)
                    .font(.ui(size: 12.5))
                    .foregroundColor(p.ink70)
                if pending {
                    statusBadge("준비 중")
                }
                Spacer()
                Text(value)
                    .font(.ui(size: 12, weight: .medium))
                    .foregroundColor(pending ? p.ink50 : p.ink)
                if !pending {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(p.ink35)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Rectangle().fill(p.line).frame(height: 0.5)
                    .opacity(key == "릴리스 노트" ? 0 : 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(pending)
    }

    private func themeMiniCard(_ t: AppTheme) -> some View {
        let pal = t.palette
        let active = theme == t
        return Button {
            themeRaw = t.rawValue
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(pal.canvas)
                        .frame(height: 50)
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(pal.brandGradient)
                            .frame(width: 10, height: 10)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(pal.surface)
                            .frame(width: 30, height: 10)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(pal.line))
                    }
                    .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(active ? p.accent : p.line, lineWidth: active ? 1.5 : 0.5)
                )
                Text(t.displayName)
                    .font(.ui(size: 11, weight: active ? .semibold : .medium))
                    .foregroundColor(active ? p.accent : p.ink70)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    private func appBuild() -> String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }

    private func versionLine() -> String {
        if let build = appBuild(), !build.isEmpty, build != appVersion() {
            return "v\(appVersion()) · build \(build)"
        }
        return "v\(appVersion())"
    }

    // MARK: Helpers

    private func panelHero(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.display(size: 22, weight: .semibold))
                .foregroundColor(p.ink)
            Text(description)
                .font(.ui(size: 13))
                .foregroundColor(p.ink70)
        }
    }
}

// MARK: - Release Notes Sheet

fileprivate struct ReleaseNotesSheet: View {
    let palette: ThemePalette
    let notes: [ReleaseNote]
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(palette.ink70)
                Text("릴리스 노트")
                    .font(.display(size: 18, weight: .semibold))
                    .foregroundColor(palette.ink)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(palette.ink70)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6).fill(palette.surfaceMuted)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().background(palette.line)

            ScrollView {
                if notes.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(notes) { note in
                            noteCard(note)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .frame(width: 520, height: 480)
        .background(palette.canvas)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 28))
                .foregroundColor(palette.ink50)
            Text("릴리스 노트가 아직 등록되지 않았습니다.")
                .font(.ui(size: 13))
                .foregroundColor(palette.ink70)
            Text("Resources/release-notes.json 에 항목을 추가하세요.")
                .font(.mono(size: 11))
                .foregroundColor(palette.ink50)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }

    private func noteCard(_ note: ReleaseNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("v\(note.version)")
                    .font(.mono(size: 13, weight: .semibold))
                    .foregroundColor(palette.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5).fill(palette.surfaceMuted)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5).stroke(palette.line, lineWidth: 0.5)
                    )
                if let build = note.build, !build.isEmpty {
                    Text("build \(build)")
                        .font(.mono(size: 10))
                        .foregroundColor(palette.ink50)
                }
                Spacer()
                Text(note.date)
                    .font(.mono(size: 11))
                    .foregroundColor(palette.ink50)
            }
            if let highlight = note.highlight, !highlight.isEmpty {
                Text(highlight)
                    .font(.ui(size: 13, weight: .semibold))
                    .foregroundColor(palette.ink)
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(note.items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.ui(size: 12))
                            .foregroundColor(palette.ink50)
                        Text(item)
                            .font(.ui(size: 12.5))
                            .foregroundColor(palette.ink70)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(palette.line, lineWidth: 0.5)
        )
    }
}
