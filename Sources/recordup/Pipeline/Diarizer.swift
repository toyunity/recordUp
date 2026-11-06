import ArgmaxCore
import Foundation
import SpeakerKit
import WhisperKit

enum DiarizerError: LocalizedError {
    case bundledModelMissing
    var errorDescription: String? {
        switch self {
        case .bundledModelMissing:
            return "SpeakerKit 모델이 .app 번들에 없습니다. './Scripts/fetch-models.sh' 를 실행한 뒤 다시 빌드하세요."
        }
    }
}

actor Diarizer {
    private var speakerKit: SpeakerKit?

    func warmUp(progressCallback: @escaping @Sendable (String) -> Void) async throws {
        if speakerKit != nil { return }
        guard let modelFolder = AppPaths.bundledSpeakerFolder else {
            throw DiarizerError.bundledModelMissing
        }
        progressCallback("SpeakerKit 모델 로드")
        DebugLog.log("[speaker] warmUp start, modelFolder=\(modelFolder)")
        let config = PyannoteConfig(
            modelFolder: modelFolder,
            download: false,
            load: true
        )
        speakerKit = try await SpeakerKit(config)
        DebugLog.log("[speaker] warmUp done")
    }

    func diarizeAndAlign(
        audioArray: [Float],
        transcription: [TranscriptionResult],
        progressCallback: @escaping @Sendable (String) -> Void
    ) async throws -> (result: DiarizationResult, segments: [[SpeakerSegment]]) {
        try await warmUp(progressCallback: progressCallback)
        guard let speakerKit else {
            throw NSError(domain: "Diarizer", code: -1)
        }
        progressCallback("화자 분리 진행 중")
        DebugLog.log("[speaker] diarize start")
        let result = try await speakerKit.diarize(audioArray: audioArray)
        let segments = result.addSpeakerInfo(to: transcription)
        DebugLog.log("[speaker] diarize done, speakerCount=\(result.speakerCount)")
        return (result, segments)
    }
}
