import Foundation

/// 앱이 사용하는 표준 경로. Documents는 TCC 권한 prompt가 잘 안 떠서 셀프 사인 macOS 앱은
/// Application Support 하위에 모델·캐시를 두는 게 안전하다.
enum AppPaths {
    static let bundleId = "com.toyunity.recordup"

    /// `~/Library/Application Support/recordup/`
    static var appSupport: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appending(path: "recordup", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// WhisperKit · SpeakerKit 모델 캐시.
    static var modelCache: URL {
        let dir = appSupport.appending(path: "models", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var modelCachePath: String { modelCache.path }

    /// `.app/Contents/Resources/models/` — 빌드 시 동봉된 모델 위치. 없을 수 있음(개발 초기).
    static var bundledModels: URL? {
        Bundle.main.url(forResource: "models", withExtension: nil)
    }

    /// 동봉된 WhisperKit 모델 폴더(특정 변형 디렉토리).
    /// fetch-models.sh가 받는 기본 변형과 일치해야 한다.
    static let whisperVariant = "openai_whisper-large-v3-v20240930_turbo_632MB"

    static var bundledWhisperFolder: String? {
        guard let root = bundledModels else { return nil }
        let url = root.appending(path: "whisperkit-coreml/\(whisperVariant)", directoryHint: .isDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url.path : nil
    }

    static var bundledSpeakerFolder: String? {
        guard let root = bundledModels else { return nil }
        let url = root.appending(path: "speakerkit-coreml", directoryHint: .isDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url.path : nil
    }
}
