import Foundation
import SpeakerKit
import SwiftUI
import WhisperKit

@MainActor
final class TranscribeJob: ObservableObject {
    enum Stage: String {
        case idle = "대기"
        case loadingAudio = "오디오 로드"
        case preparingWhisper = "WhisperKit 모델 준비"
        case transcribing = "전사 (WhisperKit)"
        case preparingSpeaker = "SpeakerKit 모델 준비"
        case diarizing = "화자 분리 (SpeakerKit)"
        case reviewingTranscript = "전사본 검토"
        case generatingMinutes = "회의록 생성"
        case reviewingMinutes = "회의록 검토"
        case failed = "실패"
    }

    @Published var stage: Stage = .idle
    @Published var detail: String = ""
    @Published var liveText: String = ""
    @Published var progress: Double = 0.0
    @Published var lastError: String?
    @Published var lastSourceURL: URL?
    @Published var lastTranscriptURL: URL?
    @Published var lastMinutesURL: URL?

    /// 회의록 생성 단계 "모델 대화" 카드용. 요청(보낸 프롬프트 지시) + 응답(실시간 누적).
    @Published var modelPromptPreview: String = ""
    @Published var modelTranscriptChars: Int = 0
    @Published var modelResponseLive: String = ""

    /// Phase 1 산출. 사용자 편집 대상.
    @Published var draftTranscript: EditableTranscript?
    /// Phase 2 산출. 사용자 편집 대상.
    @Published var draftMinutes: String = ""
    /// 마지막으로 디스크에 저장된 회의록 본문. `draftMinutes`와 다르면 미저장 편집이 있다는 뜻.
    @Published private(set) var lastSavedMinutes: String = ""

    /// 회의록 검토 중 사용자가 편집했지만 아직 저장하지 않은 변경이 있는가.
    /// (생성·재생성 직후 autoSave로 `lastSavedMinutes`가 동기화되므로 그 시점엔 false.)
    var hasUnsavedMinuteEdits: Bool {
        stage == .reviewingMinutes && draftMinutes != lastSavedMinutes
    }

    private let transcriber = Transcriber()
    private let diarizer = Diarizer()

    private var currentTemplate: PromptTemplate?
    private var phase1StartedAt: Date?
    private var progressTimer: Timer?

    // MARK: - Phase 1

    func startPhase1(url: URL, template: PromptTemplate) {
        Task { await runPhase1(url: url, template: template) }
    }

    private func runPhase1(url: URL, template: PromptTemplate) async {
        resetPhase1State()
        currentTemplate = template
        lastSourceURL = url
        phase1StartedAt = Date()
        DebugLog.log("[job] phase1 start \(url.lastPathComponent), template=\(template.id)")

        do {
            stage = .loadingAudio
            detail = "16kHz mono PCM 변환"
            progress = 0.02
            let audioArray = try AudioLoader.loadFloatArray(from: url)
            let durationSeconds = Double(audioArray.count) / 16_000
            DebugLog.log("[job] audio loaded, duration=\(durationSeconds)s")

            // 전사·화자분리 합쳐서 ~ audioDuration의 30% 정도 (Apple Silicon turbo).
            // 너무 짧으면 막대가 빨리 차서 어색하므로 최소 8초.
            let estimatedSeconds = max(8.0, durationSeconds * 0.30)
            startEstimating(from: 0.05, to: 0.95, durationSeconds: estimatedSeconds)

            stage = .preparingWhisper
            detail = "WhisperKit 모델 로드"
            let transcription = try await transcriber.transcribe(
                audioArray: audioArray,
                progressCallback: { [weak self] msg in
                    Task { @MainActor in
                        self?.detail = msg
                        if msg.contains("진행 중") { self?.stage = .transcribing }
                    }
                },
                liveTextCallback: { [weak self] text in
                    Task { @MainActor in
                        self?.liveText = text
                    }
                }
            )

            stage = .preparingSpeaker
            detail = "SpeakerKit 모델 로드"
            let (_, grouped) = try await diarizer.diarizeAndAlign(
                audioArray: audioArray,
                transcription: transcription,
                progressCallback: { [weak self] msg in
                    Task { @MainActor in
                        self?.detail = msg
                        if msg.contains("진행 중") { self?.stage = .diarizing }
                    }
                }
            )

            stopEstimating()
            progress = 1.0

            let editable = EditableTranscript.from(
                sourceURL: url,
                durationSeconds: durationSeconds,
                speakerSegments: grouped
            )
            draftTranscript = editable
            stage = .reviewingTranscript
            detail = "사용자 검토 대기"
            DebugLog.log("[job] phase1 done, speakers=\(editable.activeSpeakerCount), blocks=\(editable.segments.count)")
        } catch {
            stopEstimating()
            handleError(error)
        }
    }

    // MARK: - Phase 2

    /// 전사본 검토 단계에서 사용자가 "회의록 만들기" 클릭 시 호출.
    /// 편집된 EditableTranscript를 .md로 저장한 뒤 claude -p 실행.
    func startPhase2() {
        guard let draft = draftTranscript, let template = currentTemplate else {
            handleError(NSError(domain: "TranscribeJob", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "전사본 또는 템플릿이 비어 있습니다."
            ]))
            return
        }
        Task { await runPhase2(draft: draft, template: template) }
    }

    private func runPhase2(draft: EditableTranscript, template: PromptTemplate) async {
        progress = 0.0
        detail = "전사본 저장"
        DebugLog.log("[job] phase2 start, template=\(template.id)")
        let transcriptMD = TranscriptExporter.render(transcript: draft)

        do {
            // 전사본 .md 저장 (사용자 편집·매핑 반영본)
            let transcriptURL = try TranscriptExporter.save(
                markdown: transcriptMD,
                sourceURL: draft.sourceURL
            )
            lastTranscriptURL = transcriptURL
            DebugLog.log("[job] transcript saved → \(transcriptURL.path)")

            // 선택된 기본 엔진으로 회의록 생성 — 시간 추정으로 progress 보간
            guard let tool = AIToolRegistry.defaultTool() else {
                throw NSError(domain: "TranscribeJob", code: -6, userInfo: [
                    NSLocalizedDescriptionKey: "사용 가능한 AI 도구가 없습니다. Resources/ai-tools.json을 확인하세요."
                ])
            }
            modelResponseLive = ""
            modelPromptPreview = template.body
            modelTranscriptChars = transcriptMD.count
            stage = .generatingMinutes
            detail = "\(tool.name) 호출 중 (수십 초)"
            progress = 0.05
            startEstimating(from: 0.05, to: 0.92, durationSeconds: 60)

            let minutesBody = try await AIToolRunner.generateMinutes(
                tool: tool,
                template: template,
                transcriptMarkdown: transcriptMD,
                onResponseChunk: { [weak self] text in
                    Task { @MainActor in self?.modelResponseLive = text }
                }
            )

            stopEstimating()
            progress = 1.0

            draftMinutes = minutesBody
            autoSaveMinutes()   // 생성 즉시 라이브러리에 반영 (검토 화면의 "자동 저장됨" 배지 의도)
            stage = .reviewingMinutes
            detail = "회의록 검토 대기"
            DebugLog.log("[job] phase2 done, minutes length=\(minutesBody.count)")
        } catch {
            stopEstimating()
            handleError(error)
        }
    }

    // MARK: - Regenerate

    /// 회의록 검토 단계에서 사용자가 "다시 생성" 시 호출.
    /// 템플릿을 바꾸거나 추가 지시를 넣어 phase 2만 재실행한다.
    func regenerateMinutes(templateID: String, hint: String) {
        Task { await runRegenerate(templateID: templateID, hint: hint) }
    }

    private func runRegenerate(templateID: String, hint: String) async {
        guard let draft = draftTranscript else {
            handleError(NSError(domain: "TranscribeJob", code: -4, userInfo: [
                NSLocalizedDescriptionKey: "전사본이 비어 있어 다시 생성할 수 없습니다."
            ]))
            return
        }
        let templates = PromptTemplateStore.loadAll()
        guard let template = templates.first(where: { $0.id == templateID }) ?? currentTemplate else {
            handleError(NSError(domain: "TranscribeJob", code: -5, userInfo: [
                NSLocalizedDescriptionKey: "템플릿(\(templateID))을 찾을 수 없습니다."
            ]))
            return
        }
        currentTemplate = template

        let transcriptMD = TranscriptExporter.render(transcript: draft)
        guard let tool = AIToolRegistry.defaultTool() else {
            handleError(NSError(domain: "TranscribeJob", code: -6, userInfo: [
                NSLocalizedDescriptionKey: "사용 가능한 AI 도구가 없습니다. Resources/ai-tools.json을 확인하세요."
            ]))
            return
        }
        modelResponseLive = ""
        modelPromptPreview = template.body
        modelTranscriptChars = transcriptMD.count
        stage = .generatingMinutes
        detail = "\(tool.name) 다시 호출 중"
        progress = 0.05
        startEstimating(from: 0.05, to: 0.92, durationSeconds: 60)

        do {
            let body = try await AIToolRunner.generateMinutes(
                tool: tool,
                template: template,
                transcriptMarkdown: transcriptMD,
                hint: hint,
                onResponseChunk: { [weak self] text in
                    Task { @MainActor in self?.modelResponseLive = text }
                }
            )
            stopEstimating()
            progress = 1.0
            draftMinutes = body
            autoSaveMinutes()   // 재생성본도 동일 파일을 덮어써 라이브러리를 최신으로 유지
            stage = .reviewingMinutes
            detail = "회의록 다시 생성 완료"
            DebugLog.log("[job] regenerate done, template=\(template.id), hint=\(hint.count)자")
        } catch {
            stopEstimating()
            handleError(error)
        }
    }

    // MARK: - Save / Reset

    /// 회의록 검토 단계에서 사용자가 "저장" 클릭 시 호출.
    /// 현재 draftMinutes(편집본)를 .md 로 저장한다.
    @discardableResult
    func saveMinutes() throws -> URL {
        guard let draft = draftTranscript, let template = currentTemplate else {
            throw NSError(domain: "TranscribeJob", code: -3, userInfo: [
                NSLocalizedDescriptionKey: "현재 작업 컨텍스트가 비어 있습니다."
            ])
        }
        let elapsed = phase1StartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let url = try MinutesExporter.save(
            body: draftMinutes,
            sourceURL: draft.sourceURL,
            templateTitle: template.title,
            templateID: template.id,
            elapsedSeconds: elapsed,
            existingURL: lastMinutesURL
        )
        lastMinutesURL = url
        lastSavedMinutes = draftMinutes   // 저장 시점의 본문을 기준선으로 — 이후 편집 감지용
        DebugLog.log("[job] minutes saved → \(url.path)")
        return url
    }

    /// 생성·재생성 완료 직후 호출하는 자동 저장. 실패해도 검토 흐름을 막지 않도록
    /// 에러를 로그로만 남긴다(사용자는 ⌘S로 재시도 가능).
    private func autoSaveMinutes() {
        do {
            _ = try saveMinutes()
        } catch {
            DebugLog.log("[job] auto-save failed: \(error)")
        }
    }

    func reset() {
        stopEstimating()
        stage = .idle
        detail = ""
        liveText = ""
        progress = 0.0
        lastError = nil
        lastSourceURL = nil
        lastTranscriptURL = nil
        lastMinutesURL = nil
        draftTranscript = nil
        draftMinutes = ""
        lastSavedMinutes = ""
        currentTemplate = nil
        phase1StartedAt = nil
    }

    // MARK: - Helpers

    private func resetPhase1State() {
        stopEstimating()
        progress = 0.0
        detail = ""
        lastError = nil
        lastTranscriptURL = nil
        lastMinutesURL = nil
        draftTranscript = nil
        draftMinutes = ""
        lastSavedMinutes = ""
    }

    private func handleError(_ error: Error) {
        let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        lastError = msg
        DebugLog.log("[job] FAILED: \(error)")
        stage = .failed
    }

    /// 시간 기반 progress 추정. ease-out 곡선으로 자연스럽게 끝까지 채운다.
    private func startEstimating(from start: Double, to end: Double, durationSeconds: TimeInterval) {
        stopEstimating()
        progress = start
        let startedAt = Date()
        let span = end - start
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            guard let self else { return }
            let elapsed = Date().timeIntervalSince(startedAt)
            let frac = min(1.0, elapsed / durationSeconds)
            let eased = 1.0 - pow(1.0 - frac, 2.0)
            Task { @MainActor in
                self.progress = max(self.progress, start + span * eased)
            }
        }
    }

    private func stopEstimating() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
