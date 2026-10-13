import ArgmaxCore
import Foundation
import WhisperKit

enum TranscriberError: LocalizedError {
    case bundledModelMissing
    var errorDescription: String? {
        switch self {
        case .bundledModelMissing:
            return "WhisperKit 모델이 .app 번들에 없습니다. 네트워크가 제한되지 않은 환경에서 './Scripts/fetch-models.sh' 를 한 번 실행한 뒤 './Scripts/build.sh' 로 다시 빌드하세요."
        }
    }
}

actor Transcriber {
    private var whisperKit: WhisperKit?

    /// 동봉된 모델만 사용. 다운로드는 시도하지 않는다.
    func warmUp(progressCallback: @escaping @Sendable (String) -> Void) async throws {
        if whisperKit != nil { return }
        guard let modelFolder = AppPaths.bundledWhisperFolder else {
            throw TranscriberError.bundledModelMissing
        }
        progressCallback("WhisperKit 모델 로드 (\(AppPaths.whisperVariant))")
        DebugLog.log("[whisper] warmUp start, modelFolder=\(modelFolder)")
        let config = WhisperKitConfig(
            modelFolder: modelFolder,
            verbose: true,
            logLevel: .info,
            load: true,
            download: false
        )
        whisperKit = try await WhisperKit(config)
        DebugLog.log("[whisper] warmUp done")
    }

    func transcribe(
        audioArray: [Float],
        progressCallback: @escaping @Sendable (String) -> Void,
        liveTextCallback: (@Sendable (String) -> Void)? = nil
    ) async throws -> [TranscriptionResult] {
        try await warmUp(progressCallback: progressCallback)
        guard let whisperKit else {
            throw NSError(domain: "Transcriber", code: -1)
        }
        progressCallback("전사 진행 중")
        DebugLog.log("[whisper] transcribe start, samples=\(audioArray.count)")
        let options = DecodingOptions(
            task: .transcribe,
            language: "ko",
            wordTimestamps: true,
            chunkingStrategy: .vad
        )
        let result = try await whisperKit.transcribe(
            audioArray: audioArray,
            decodeOptions: options,
            callback: { progress in
                if let cb = liveTextCallback {
                    let text = progress.text
                    if !text.isEmpty { cb(text) }
                }
                return nil
            }
        )
        DebugLog.log("[whisper] transcribe done, results=\(result.count)")
        return result
    }
}
