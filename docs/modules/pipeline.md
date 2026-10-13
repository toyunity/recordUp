# Pipeline 모듈

`Sources/recordup/Pipeline/` — 전사+화자 분리 → 사용자 검토 → 회의록 생성의 2-Phase 작업 단위.

## 파일

- `TranscribeJob.swift` — `@MainActor ObservableObject`. 작업의 **상태 머신**과 progress 추정을 보유. Phase 1/2 + 회의록 재생성을 같은 객체에서 처리.
- `Diarizer.swift` — SpeakerKit 래퍼 (`actor`). `download: false`, 번들 모델만 사용 (`AppPaths.bundledSpeakerFolder`). `diarizeAndAlign()`이 transcription 결과에 화자 정보를 입혀 `[[SpeakerSegment]]` 반환 (outer = 같은 화자 연속 블록).
- `EditableTranscript.swift` — `@MainActor ObservableObject`. 화자 단위 블록(`EditableSegment`) 컬렉션. 사용자가 화자 이름·블록 텍스트·블록 추가/삭제·화자 추가/삭제(최소 1명 보존, 사용 중 화자 삭제 시 첫 남은 화자로 재매핑)·블록의 화자 변경 가능.

## 상태 머신 (`TranscribeJob.Stage`)

```
idle
  → loadingAudio        (AudioLoader)
  → preparingWhisper    (Transcriber.warmUp)
  → transcribing
  → preparingSpeaker    (Diarizer.warmUp)
  → diarizing
  → reviewingTranscript (사용자가 EditableTranscript 편집)
  → generatingMinutes   (AIToolRunner.generateMinutes — 기본 엔진, Phase 2 시작)
  → reviewingMinutes    (사용자가 회의록 검토/재생성/저장)

failed (어느 단계에서든 에러 시)
```

## Progress 추정

`startEstimating(from:to:durationSeconds:)` — 시간 기반 ease-out 곡선으로 progress를 자연스럽게 채운다. 실제 작업 종료 시 `progress = 1.0` 강제. 전사 추정치: `max(8s, audioDuration * 0.30)` (Apple Silicon turbo 기준).

## 책임

- Phase 1: Audio → STT → Diarize → `EditableTranscript` 생성
- Phase 2: 편집된 transcript를 `.md`로 저장 → 기본 생성 엔진(`AIToolRegistry.defaultTool()`) 호출 → 회의록 본문 생성. 사용 가능한 AI 도구가 없으면 에러로 중단. progress detail에는 도구 표시명(`tool.name`)을 노출. 생성·재생성(`regenerateMinutes`) 모두 시작 시 `@Published modelPromptPreview`(보낸 템플릿 지시)·`modelTranscriptChars`(첨부 전사본 글자수)·`modelResponseLive`를 리셋·설정하고, `AIToolRunner`의 `onResponseChunk` 콜백에서 `Task { @MainActor }`로 `modelResponseLive`를 실시간 누적해 `Root/ProgressScreen`의 "모델 대화" 카드를 채운다
- 회의록 재생성(`regenerateMinutes`): 다른 템플릿 또는 `hint` 추가 지시로 Phase 2만 재실행
- 회의록 저장(`saveMinutes`): `MinutesExporter`에 `elapsedSeconds`(Phase1 시작부터 경과) + `existingURL`(`lastMinutesURL`)을 넘겨 같은 작업의 재저장은 동일 파일을 덮어쓴다
- 회의록 자동 저장(`autoSaveMinutes`): 생성·재생성 완료 직후 `saveMinutes`를 호출해 라이브러리에 즉시 반영(검토 화면 "자동 저장됨" 배지). 실패해도 검토 흐름을 막지 않고 로그만 남긴다(사용자는 ⌘S로 재시도)
- 미저장 편집 감지(`hasUnsavedMinuteEdits`): `reviewingMinutes` 단계에서 `draftMinutes`가 마지막 저장본(`lastSavedMinutes`)과 다르면 `true`. `saveMinutes`가 저장 시점의 본문을 `lastSavedMinutes` 기준선으로 동기화하므로 생성·재생성(→ 자동 저장) 직후엔 `false`. `Root/RootView`의 검토 이탈 컨펌 분기에 사용

## 의존

- 외부: WhisperKit (`SpeakerKit` product)
- 내부: `Audio/AudioLoader`, `STT/Transcriber`, `AITools/AIToolRegistry`·`AITools/AIToolRunner`, `Claude/PromptTemplateStore`, `Export/TranscriptExporter`, `Export/MinutesExporter`
- 상위: `Root/RootView`(stage별 화면 라우팅)
