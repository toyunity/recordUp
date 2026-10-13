# Audio 모듈

`Sources/recordup/Audio/` — 오디오 입출력.

## 파일

- `AudioLoader.swift` — `WhisperKit.AudioProcessor.loadAudioAsFloatArray`로 임의 오디오를 **16kHz mono Float32 PCM `[Float]`** 으로 정규화. WhisperKit·SpeakerKit이 같은 배열을 공유해 변환을 두 번 하지 않는다 (`channelMode: .sumChannels(nil)`).
- `AudioPlayerEngine.swift` — `@MainActor` `ObservableObject`. `AVAudioPlayer` 래퍼로 `playhead`/`isPlaying`/`duration`을 published. 50ms 타이머로 재생 위치 폴링. 같은 URL 재load는 스킵, 절대/상대 seek 지원, `playFrom(_:)`으로 특정 시점 재생.

## 책임

- 입력 오디오 파일을 STT 모듈이 소비할 수 있는 PCM 배열로 정규화
- 검토 화면(전사본/회의록)에서 원본 음성 재생·탐색 제공

## 의존

- 외부: WhisperKit (`AudioProcessor`), AVFoundation, Combine
- 상위: `Pipeline/TranscribeJob`(전사 입력), `Sheets/TranscriptReviewView` 등 검토 화면 (재생)
