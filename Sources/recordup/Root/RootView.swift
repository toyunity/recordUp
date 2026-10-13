import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum SidebarItem: String, CaseIterable, Identifiable {
    case newRecord, library, templates, settings
    var id: String { rawValue }

    var label: String {
        switch self {
        case .newRecord: return "새 회의록"
        case .library:   return "라이브러리"
        case .templates: return "템플릿"
        case .settings:  return "설정"
        }
    }

    var icon: String {
        switch self {
        case .newRecord: return "plus"
        case .library:   return "folder"
        case .templates: return "doc.text"
        case .settings:  return "gearshape"
        }
    }
}

struct RootView: View {
    @StateObject private var job = TranscribeJob()
    @StateObject private var minutesIndex = MinutesIndex.shared
    @State private var sidebarItem: SidebarItem = .newRecord
    @State private var pendingURL: URL?
    @State private var templates: [PromptTemplate] = []
    @State private var selectedMinute: MinutesEntry?
    @State private var libraryMinutesText: String = ""
    @State private var confirmCancel: ConfirmRequest?

    private struct ConfirmRequest: Identifiable {
        let id = UUID()
        var title: String = "진행 중인 작업을 취소할까요?"
        let message: String
        let confirmLabel: String
        let action: () -> Void
        var saveLabel: String? = nil
        var saveAction: (() -> Void)? = nil
    }

    /// 진행 중(전사 검토·생성 등) 단계에서 "작업 취소" 확인에 쓰는 메시지.
    private var cancelMessage: String {
        switch job.stage {
        case .reviewingTranscript:
            return "전사본 검토 중입니다. 검토를 중단하면 결과가 사라집니다."
        case .generatingMinutes:
            return "회의록 생성이 진행 중입니다. 취소하면 진행 상황이 사라집니다."
        default:
            return "전사·화자 분리가 진행 중입니다. 취소하면 진행 상황이 사라집니다."
        }
    }

    /// 메뉴 이동 시 단계별로 적절한 확인 흐름을 탄다.
    /// - reviewingMinutes: 회의록은 자동 저장되므로 미저장 편집이 없으면 모달 없이 이동.
    ///   미저장 편집이 있으면 "저장하고 나가기 / 저장 없이 나가기 / 계속 진행" 3지선다.
    /// - 그 외 진행 중 단계: "작업 취소" 확인.
    private func requestNavigation(_ action: @escaping () -> Void) {
        switch job.stage {
        case .idle, .failed:
            action()
        case .reviewingMinutes where !job.hasUnsavedMinuteEdits:
            job.reset()   // 저장된 결과는 라이브러리에 남는다
            action()
        case .reviewingMinutes:
            confirmCancel = ConfirmRequest(
                title: "저장하지 않은 변경 사항",
                message: "편집한 회의록이 아직 저장되지 않았습니다. 어떻게 할까요?",
                confirmLabel: "저장 없이 나가기",
                action: { job.reset(); action() },
                saveLabel: "저장하고 나가기",
                saveAction: { saveMinutesAndLeave(action) }
            )
        default:
            confirmCancel = ConfirmRequest(
                message: cancelMessage,
                confirmLabel: "작업 취소",
                action: { job.reset(); action() }
            )
        }
    }

    /// "저장하고 나가기" — 저장에 성공할 때만 세션을 정리하고 이동한다(실패 시 편집 보존).
    private func saveMinutesAndLeave(_ action: @escaping () -> Void) {
        do {
            _ = try job.saveMinutes()
            minutesIndex.reload()
            job.reset()
            action()
        } catch {
            DebugLog.log("[ui] save-and-leave failed: \(error)")
        }
    }

    /// 처리 중에서만 의미 있는 "취소" 버튼용 — 이동 없이 reset만.
    private func requestCancelOnly() {
        confirmCancel = ConfirmRequest(
            message: cancelMessage,
            confirmLabel: "작업 취소",
            action: { job.reset() }
        )
    }

    @AppStorage(AppTheme.storageKey) private var themeRaw: String = AppTheme.warm.rawValue
    @AppStorage("autoOpenMinutes") private var autoOpenMinutes: Bool = true

    private var theme: AppTheme {
        AppTheme(rawValue: themeRaw) ?? .warm
    }
    private var palette: ThemePalette { theme.palette }

    var body: some View {
        ZStack {
            palette.canvas.ignoresSafeArea()
            HStack(spacing: 0) {
                Sidebar(
                    selected: Binding(
                        get: { sidebarItem },
                        set: { newValue in
                            // 라이브러리/최근에서 띄운 검수 화면에선 같은 항목(예: "라이브러리") 재클릭으로
                            // 테이블 복귀가 가능해야 하므로 selectedMinute이 있을 때는 가드를 통과시킨다.
                            // 검수 화면이 아닐 때는 작업 중 confirm-cancel 모달이 잘못 뜨지 않도록 no-op.
                            if newValue == sidebarItem && selectedMinute == nil { return }
                            requestNavigation {
                                selectedMinute = nil
                                sidebarItem = newValue
                            }
                        }
                    ),
                    recents: minutesIndex.recents,
                    onPickRecent: { entry in
                        requestNavigation {
                            sidebarItem = .library
                            selectedMinute = entry
                        }
                    }
                )
                .frame(width: 256)

                mainArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if let req = confirmCancel {
                ConfirmCancelSheet(
                    title: req.title,
                    message: req.message,
                    confirmLabel: req.confirmLabel,
                    onConfirm: {
                        let act = req.action
                        confirmCancel = nil
                        act()
                    },
                    onCancel: { confirmCancel = nil },
                    saveLabel: req.saveLabel,
                    onSave: req.saveAction.map { save in
                        { confirmCancel = nil; save() }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeOut(duration: 0.15), value: confirmCancel?.id)
        .environment(\.palette, palette)
        .frame(minWidth: 1100, minHeight: 720)
        .onAppear {
            templates = PromptTemplateStore.loadAll()
            minutesIndex.reload()
        }
        .onChange(of: selectedMinute) { _, newValue in
            if let entry = newValue {
                libraryMinutesText = (try? String(contentsOf: entry.url, encoding: .utf8)) ?? ""
            } else {
                libraryMinutesText = ""
            }
        }
        .onChange(of: job.stage) { _, newStage in
            // 생성·재생성 완료 시 job이 회의록을 자동 저장한 뒤 reviewingMinutes로 전환한다.
            // 이 시점에 인덱스를 다시 읽어 라이브러리·최근 목록에 즉시 반영한다.
            if newStage == .reviewingMinutes {
                minutesIndex.reload()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSidebarNewRecord)) { _ in
            // 이미 confirm-cancel 모달이 떠 있으면 단축키 중복 입력으로 모달이 덮어씌워지는 것을 방지.
            guard confirmCancel == nil else { return }
            requestNavigation { selectedMinute = nil; sidebarItem = .newRecord }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSidebarLibrary)) { _ in
            guard confirmCancel == nil else { return }
            requestNavigation { selectedMinute = nil; sidebarItem = .library }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSidebarSettings)) { _ in
            guard confirmCancel == nil else { return }
            requestNavigation { selectedMinute = nil; sidebarItem = .settings }
        }
        .sheet(item: Binding(
            get: { pendingURL.map { PendingURL(url: $0) } },
            set: { pendingURL = $0?.url }
        )) { wrapped in
            TemplatePickerSheet(
                sourceURL: wrapped.url,
                templates: templates,
                onPick: { tpl in
                    let url = wrapped.url
                    pendingURL = nil
                    job.startPhase1(url: url, template: tpl)
                },
                onCancel: { pendingURL = nil }
            )
            .environment(\.palette, palette)
        }
    }

    // MARK: - Routing

    @ViewBuilder
    private var mainArea: some View {
        switch job.stage {
        case .idle, .failed:
            if let entry = selectedMinute {
                MinutesReviewView(
                    source: .library,
                    minutesText: $libraryMinutesText,
                    savedURL: entry.url,
                    createdAt: entry.createdAt,
                    participantCount: entry.speakerCount,
                    onSave: { saveLibraryMinutes(entry: entry) },
                    onOpenExternal: { NSWorkspace.shared.open(entry.url) },
                    onNew: {
                        selectedMinute = nil
                        sidebarItem = .newRecord
                    },
                    onBack: {
                        selectedMinute = nil
                        sidebarItem = .library
                    },
                    onRegenerate: { _, _ in /* 라이브러리 컨텍스트에선 노출 안 함 */ }
                )
            } else {
                sidebarRouted
            }
        case .loadingAudio, .preparingWhisper, .transcribing, .preparingSpeaker, .diarizing:
            ProgressScreen(
                title: "전사·화자 분리 중",
                subtitle: job.lastSourceURL?.lastPathComponent,
                stage: job.stage,
                engineName: AIToolRegistry.defaultTool()?.name ?? "AI 도구",
                detail: job.detail,
                liveText: job.liveText,
                progress: job.progress,
                fileName: job.lastSourceURL?.lastPathComponent,
                onCancel: { requestCancelOnly() }
            )
        case .reviewingTranscript:
            if let draft = job.draftTranscript {
                TranscriptReviewView(
                    transcript: draft,
                    onConfirm: { job.startPhase2() },
                    onCancel: { requestCancelOnly() }
                )
            } else {
                placeholder("전사본을 불러오는 중…")
            }
        case .generatingMinutes:
            ProgressScreen(
                title: "회의록 생성 중",
                subtitle: "\(AIToolRegistry.defaultTool()?.name ?? "AI") (으)로 생성합니다",
                stage: job.stage,
                engineName: AIToolRegistry.defaultTool()?.name ?? "AI 도구",
                detail: job.detail,
                liveText: job.liveText,
                promptPreview: job.modelPromptPreview,
                transcriptChars: job.modelTranscriptChars,
                responseLive: job.modelResponseLive,
                progress: job.progress,
                fileName: job.lastSourceURL?.lastPathComponent,
                onCancel: { requestCancelOnly() }
            )
        case .reviewingMinutes:
            MinutesReviewView(
                source: .newRecord,
                minutesText: $job.draftMinutes,
                savedURL: job.lastMinutesURL,
                createdAt: nil,
                participantCount: nil,
                onSave: saveMinutes,
                onOpenExternal: openMinutesExternal,
                onNew: {
                    requestNavigation {
                        minutesIndex.reload()
                    }
                },
                onBack: nil,
                onRegenerate: { templateID, hint in
                    job.regenerateMinutes(templateID: templateID, hint: hint)
                }
            )
        }
    }

    @ViewBuilder
    private var sidebarRouted: some View {
        switch sidebarItem {
        case .newRecord:
            DropScreen(
                lastError: job.lastError,
                isFailed: job.stage == .failed,
                recents: minutesIndex.recents,
                onPickFile: { url in pendingURL = url },
                onShowAll: { sidebarItem = .library },
                onPickRecent: { entry in
                    selectedMinute = entry
                    sidebarItem = .library
                },
                onOpenTemplates: { sidebarItem = .templates }
            )
        case .library:
            LibraryView(
                index: minutesIndex,
                selected: $selectedMinute,
                onNewRecord: { sidebarItem = .newRecord }
            )
        case .templates:
            TemplateManagerView(onClose: {
                templates = PromptTemplateStore.loadAll()
                sidebarItem = .newRecord
            })
        case .settings:
            SettingsView()
        }
    }

    // MARK: - Helpers

    private struct PendingURL: Identifiable {
        let url: URL
        var id: String { url.path }
    }

    private func saveMinutes() {
        do {
            let url = try job.saveMinutes()
            minutesIndex.reload()
            if autoOpenMinutes {
                NSWorkspace.shared.open(url)
            }
        } catch {
            DebugLog.log("[ui] saveMinutes failed: \(error)")
        }
    }

    private func openMinutesExternal() {
        guard let url = job.lastMinutesURL else { return }
        NSWorkspace.shared.open(url)
    }

    /// 라이브러리 컨텍스트에서 회의록을 저장한다. 저장 후 인덱스를 재구성하고
    /// `selectedMinute`을 새 항목으로 교체해 사이드바·테이블·헤더 메타가
    /// 함께 갱신되도록 한다.
    private func saveLibraryMinutes(entry: MinutesEntry) {
        do {
            try libraryMinutesText.write(to: entry.url, atomically: true, encoding: .utf8)
            minutesIndex.reload()
            if let updated = minutesIndex.entries.first(where: { $0.id == entry.id }) {
                selectedMinute = updated
            }
            if autoOpenMinutes {
                NSWorkspace.shared.open(entry.url)
            }
        } catch {
            DebugLog.log("[ui] saveLibraryMinutes failed: \(error)")
        }
    }

    private func placeholder(_ msg: String) -> some View {
        VStack(spacing: 8) {
            ProgressView().scaleEffect(0.8)
            Text(msg)
                .font(.ui(size: 12))
                .foregroundColor(palette.ink50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RootView()
        .frame(width: 1240, height: 800)
}
