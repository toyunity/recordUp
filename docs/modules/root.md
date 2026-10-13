# Root 모듈

`Sources/recordup/Root/` — 앱 셸 / 메인 화면.

## 파일

- `RootView.swift` — 4-탭 사이드바 + `TranscribeJob.Stage`별 메인 영역 라우팅. `ConfirmCancelSheet`로 작업 중 이동 시 컨펌. `palette` 환경값 주입. stage가 `.reviewingMinutes`로 전환되면(job이 회의록을 자동 저장한 직후) `MinutesIndex.reload()`로 라이브러리·최근 목록을 즉시 갱신.
- `Sidebar.swift` — 4개 항목(`SidebarItem`: `newRecord`/`library`/`templates`/`settings`) + 최근 회의록 6개.
- `TopBar.swift` — 상단 바.
- `DropScreen.swift` — 새 회의록 입력 화면. `.m4a` 드래그&드롭 + 파일 picker + 최근 회의록 + 마지막 에러 표시. "음성 메모 앱에서 불러오기" 카드는 `openFilePicker(startIn:message:)`로 Apple 음성 메모(Voice Memos) 녹음 폴더(`voiceMemosDirectory()`로 탐색, 없으면 기본 위치)에서 picker를 연다.
- `ProgressScreen.swift` — Phase 1·Phase 2 공통 진행률 화면 (제목/세부/progress bar/취소). 현재 단계를 `TranscribeJob.Stage` enum으로 직접 받아(rawValue 문자열 매칭 제거 — stage 라벨 변경 시 desync 방지) 파이프라인 카드의 현재 스텝을 판정하고, 회의록 생성 노드엔 기본 엔진명(`engineName`)을 표시. `.generatingMinutes` 단계에서는 라이브 텍스트 대신 **"모델 대화" 카드**(요청=템플릿 지시 + 첨부 전사본 글자수, 응답=실시간 누적 스트리밍)를, 그 외 단계에서는 라이브 스트림 카드를 표시.
- `AnimatedWaveform.swift` — 진행률 화면의 파형 애니메이션.
- `Brand.swift` — 브랜드 로고/타이포.

## 라우팅 규칙 (`RootView`)

```
job.stage == .idle | .failed
  → sidebarItem 별:
       .newRecord  → DropScreen
       .library    → LibraryView   (Sheets/)
       .templates  → TemplateManagerView (Sheets/)
       .settings   → SettingsView   (Sheets/)
job.stage == loadingAudio|preparingWhisper|transcribing|preparingSpeaker|diarizing
  → ProgressScreen ("전사·화자 분리 중")
job.stage == .reviewingTranscript  → TranscriptReviewView (Sheets/)
job.stage == .generatingMinutes    → ProgressScreen ("회의록 생성 중")
job.stage == .reviewingMinutes     → MinutesReviewView (Sheets/)
```

## 컨펌 가드

- `requestNavigation(_:)`: `job.stage`별로 이동 흐름을 분기.
  - `.idle`/`.failed`: 즉시 이동.
  - `.reviewingMinutes` + 미저장 편집 없음(`!job.hasUnsavedMinuteEdits`): 회의록이 자동 저장됐으므로 모달 없이 `job.reset()` 후 이동.
  - `.reviewingMinutes` + 미저장 편집 있음: "저장 없이 나가기 / 저장하고 나가기 / 계속 진행" 3지선다 컨펌. "저장하고 나가기"(`saveMinutesAndLeave`)는 `job.saveMinutes()` 성공 시에만 `MinutesIndex.reload()`+`reset`+이동(실패 시 편집 보존).
  - 그 외 진행 중 단계: "작업 취소" 컨펌(`cancelMessage`) → 승인 시 `job.reset()` 후 이동.
- `requestCancelOnly()`: 진행 중 화면의 "취소" 버튼 — 이동 없이 `reset`만.

## 메인 윈도우

- 최소 사이즈 1100×720, `windowResizability(.contentSize)`
- `@AppStorage` 기반 테마(`AppTheme`) → `preferredColorScheme` + palette 주입

## 의존

- 내부: `Pipeline/TranscribeJob` (워크플로우), `Library/MinutesIndex` (최근/목록), `Sheets/*`(라우팅 대상), `Theme*` (palette)
- 상위: `App.swift` (`@main`)
