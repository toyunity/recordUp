# recordup — Claude Code 가이드

> 전역 규칙(`~/.claude/CLAUDE.md`)이 자동 로드되며, 이 파일은 프로젝트 고유 규칙만 정의한다.

## 보안 규칙

- **금지**: `.env*`, `*.pem` 등 비밀 파일 읽기·출력·수정
- **금지**: `Resources/models/` 또는 `~/Library/Application Support/recordup/models/` 하위 모델 바이너리 직접 출력 (대용량)
- **금지**: 사용자 홈 디렉터리(`~/Documents/record-up/`, `~/Library/Application Support/recordup/`) 임의 변경

---

## 커밋 규칙

작업 완료 후 **절대로 자동으로 커밋하지 않는다.** 사용자가 명시적으로 요청한 경우에만 커밋한다.

### 릴리스 버전 관리 워크플로

사용자가 명시적으로 커밋을 요청하면 **커밋 직전에** 다음 두 가지를 한 번의 `AskUserQuestion`으로 묻는다.

1. **버전 번호 갱신 여부** — `project.yml`의 `MARKETING_VERSION`(SemVer) 또는 `CURRENT_PROJECT_VERSION`(빌드 번호)을 올릴지.
   - patch / minor / major / build-only / 변경 없음 중 선택
2. **릴리스 노트 추가 여부** — `Resources/release-notes.json`에 새 항목을 추가할지.
   - 추가하면: `version` · `build` · `date`(오늘) · `highlight` · `items[]` 입력받아 배열 맨 앞에 삽입
   - 같은 `version`이 이미 있으면 항목을 머지(추가)할지 새 엔트리로 둘지 사용자에게 한 번 더 확인

판단 기준:
- 버그 수정·소규모 개선 → patch + 릴리스 노트 1줄 추가 권장
- 신규 기능 → minor + 릴리스 노트 추가 필수
- 단순 리팩터/문서/주석 → 버전 변경 없음, 릴리스 노트 생략 권장
- WIP·실험 커밋 → 둘 다 생략

`MARKETING_VERSION` 변경 시 `Resources/release-notes.json`의 최신 엔트리도 일치해야 한다(앱이 두 값을 함께 보여줌).

---

## 프로젝트 개요

음성 메모(`.m4a`) → **WhisperKit 한국어 전사 → SpeakerKit 화자 분리 → Claude Code(`claude -p`)로 회의록 자동 생성**까지 처리하는 macOS 앱.

- **Bundle ID**: `com.toyunity.recordup`
- **언어/플랫폼**: Swift 5.9 / macOS 14+ (Apple Silicon)
- **UI**: SwiftUI
- **빌드**: XcodeGen (`project.yml`) → `xcodebuild` (Xcode IDE 미사용)
- **패키징**: `pkgbuild`/`productbuild` 설치 마법사(기본) · `create-dmg`(선택) — 셀프 사인 ad-hoc
- **외부 의존**: [argmaxinc/WhisperKit](https://github.com/argmaxinc/WhisperKit) v1.0.0 (`WhisperKit` + `SpeakerKit`)
- **회의록 생성**: 사용자의 Claude Max 구독 (`claude -p` CLI 호출)

---

## 빌드/실행 명령

```sh
# XcodeGen으로 .xcodeproj 재생성 후 Release 빌드
./Scripts/build.sh

# 빌드 + 실행
./Scripts/build.sh && open .build/Build/Products/Release/recordup.app

# 설치 마법사(.pkg) 패키징까지 원샷 (필요 시 모델 자동 fetch)
# '설치 유형' 단계에서 회의록 AI 도구(claude/codex) 선택 → postinstall이 UserDefaults defaultEngineID 기록
./Scripts/release.sh

# PKG만 (빌드 산출물 있어야 함)
./Scripts/package-pkg.sh

# 모델만 다운로드 (.app에 동봉할 모델을 미리 받음)
./Scripts/fetch-models.sh

# DMG만 (빌드 산출물 있어야 함)
./Scripts/package-dmg.sh
```

> `recordup.xcodeproj/`는 `xcodegen`이 매번 재생성한다. **직접 편집 금지** — 변경은 `project.yml`에만.

> WhisperKit/SpeakerKit은 **번들 모델만 사용**(`download: false`). 빌드 전에 `fetch-models.sh`로 모델을 미리 받아 `Resources/models/`에 두어야 한다.

---

## 처리 흐름 (TranscribeJob 2-Phase)

```
[Phase 1] AudioLoader → Transcriber(WhisperKit) → Diarizer(SpeakerKit) → EditableTranscript
            └── 사용자가 화자 매핑/세그먼트 편집 ──┐
[Phase 2] TranscriptExporter(.md) → AIToolRunner(기본 엔진, 기본값 `claude -p`) → MinutesExporter(.md)
            └── 사용자가 회의록 검토/재생성/저장 ──┘
```

`TranscribeJob.Stage` 머신: `idle → loadingAudio → preparingWhisper → transcribing → preparingSpeaker → diarizing → reviewingTranscript → generatingMinutes → reviewingMinutes`. 실패 시 `failed`.

---

## 아키텍처

| 레이어 | 디렉터리 | 책임 | 문서 |
|---|---|---|---|
| 진입 | `Sources/recordup/Root/` | 4-탭 사이드바, 메인 라우팅, ConfirmCancel 모달 | [docs/modules/root.md](docs/modules/root.md) |
| 오디오 | `Sources/recordup/Audio/` | 16kHz mono Float32 PCM 로드, AVAudioPlayer 재생 엔진 | [docs/modules/audio.md](docs/modules/audio.md) |
| STT | `Sources/recordup/STT/` | WhisperKit 한국어 전사 (actor) | [docs/modules/stt.md](docs/modules/stt.md) |
| 파이프라인 | `Sources/recordup/Pipeline/` | TranscribeJob 2-Phase + Diarizer + EditableTranscript | [docs/modules/pipeline.md](docs/modules/pipeline.md) |
| AI 도구 | `Sources/recordup/AITools/` | AI CLI 연결 관리(탐지·버전·로그인) + 생성 엔진 추상화(claude/codex) | [docs/modules/ai-tools.md](docs/modules/ai-tools.md) |
| 프롬프트 템플릿 | `Sources/recordup/Claude/` | 회의록 프롬프트 템플릿 로드·CRUD | [docs/modules/claude.md](docs/modules/claude.md) |
| 출력 | `Sources/recordup/Export/` | 전사본/회의록 .md + PDF/RTF/Share | [docs/modules/export.md](docs/modules/export.md) |
| 라이브러리 | `Sources/recordup/Library/` | 회의록 인덱스(MinutesIndex) + 핀(PinnedStore) + 릴리스 노트(ReleaseNotesStore) | [docs/modules/library.md](docs/modules/library.md) |
| 화면/시트 | `Sources/recordup/Sheets/` | 검토 화면, 라이브러리/설정/템플릿 화면, 모달 시트 | [docs/modules/sheets.md](docs/modules/sheets.md) |
| 디자인 | `Sources/recordup/Theme*.swift` | AppTheme(warm/dark) + ThemePalette + 공통 컴포넌트 | [docs/patterns/theme.md](docs/patterns/theme.md) |

루트 유틸 (매핑되지 않은 단일 파일):
- `App.swift` — `@main RecordUpApp`, WindowGroup
- `AppPaths.swift` — `~/Library/Application Support/recordup/` 경로 헬퍼, 번들 모델 폴더 lookup
- `DebugLog.swift` — 로깅

---

## 데이터 저장 위치

| 용도 | 경로 |
|---|---|
| 모델 캐시 (다운로드 받은 후) | `~/Library/Application Support/recordup/models/` |
| 번들 동봉 모델 | `<.app>/Contents/Resources/models/whisperkit-coreml/<variant>`, `.../speakerkit-coreml/` |
| 전사본 출력 | `~/Documents/record-up/transcripts/` |
| 회의록 출력 | `~/Documents/record-up/minutes/` |
| 사용자 정의 템플릿 | `~/Documents/record-up/Templates/` |
| AI 도구별 바이너리 경로 | UserDefaults `aiToolPath.<id>` (구 `claudeBinaryPath`에서 마이그레이션) |
| 기본 생성 엔진 | UserDefaults `defaultEngineID` (기본값 `claude`) |
| 핀 고정된 회의록 ID | UserDefaults `pinnedMinuteIDs` |
| 테마 | UserDefaults `AppTheme.storageKey` |

---

## 개발 패턴 가이드

- 회의록 프롬프트 템플릿: `Resources/prompts/{default,decision-action,customer-interview}.md` (frontmatter `title`/`description` + 본문)
- 사용자 템플릿이 같은 ID로 존재하면 번들 템플릿을 덮어쓴다 (`PromptTemplateStore`)
- 릴리스 노트: `Resources/release-notes.json` (배열, 최신 버전이 맨 앞). `ReleaseNotesStore.loadAll()`이 번들에서 읽어 설정 화면 시트에 표시
- 디자인 시스템: [docs/patterns/theme.md](docs/patterns/theme.md), 토큰 출처 `design/design-tokens.json`
- 디자인 스펙 이력: `docs/specs/`

---

## sync-docs 자동 갱신

`Sources/recordup/` 하위 `.swift` 변경이 commit되면 `~/.claude/hooks/sync-docs.sh`가 매핑된 `docs/modules/*.md` · `docs/patterns/*.md`를 자동 업데이트한다. 매핑은 `.claude/sync-docs-config.json` 참고. (훅은 `git commit` Bash 호출에서만 동작하며, `file_patterns: ["*.swift"]`에 매치되는 파일이 없으면 즉시 종료)
