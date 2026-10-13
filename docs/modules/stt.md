# STT 모듈

`Sources/recordup/STT/` — 음성 → 한국어 텍스트 변환.

## 파일

- `Transcriber.swift` — WhisperKit 래퍼. Swift `actor`로 단일 인스턴스 보호. 한국어 고정(`language: "ko"`), `wordTimestamps: true`, VAD 청킹(`chunkingStrategy: .vad`).

## 모델 정책

- **다운로드하지 않는다** (`download: false`). `.app`에 동봉된 모델만 사용.
- 모델 폴더: `AppPaths.bundledWhisperFolder` → `<.app>/Contents/Resources/models/whisperkit-coreml/<variant>/`
- 현재 variant: `openai_whisper-large-v3-v20240930_turbo_632MB` (`AppPaths.whisperVariant`)
- 번들에 모델이 없으면 `TranscriberError.bundledModelMissing` (사용자에게 `./Scripts/fetch-models.sh` 후 재빌드 안내)

## 책임

- WhisperKit warmUp(모델 로드, 1회)
- 16kHz mono PCM `[Float]` → `[TranscriptionResult]` 변환
- 진행률 메시지(`progressCallback`) + 라이브 텍스트(`liveTextCallback`) 콜백 제공

## 의존

- 외부: [argmaxinc/WhisperKit](https://github.com/argmaxinc/WhisperKit) — `WhisperKit` product, `ArgmaxCore`
- 내부: `Audio/AudioLoader` (입력), `AppPaths` (모델 폴더)
- 상위: `Pipeline/TranscribeJob`이 `Transcriber` + `Diarizer`를 합쳐 Phase 1 수행
