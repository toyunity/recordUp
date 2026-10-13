# AITools 모듈

`Sources/recordup/AITools/` — 로컬 AI CLI 도구(claude / codex)의 **연결 관리**와 회의록 **생성 엔진 추상화**. 기존 `Claude/ClaudeBinaryLocator`·`ClaudeRunner`를 도구 id로 일반화한 것이다.

## 파일

- `AITool.swift` — 도구의 **선언적 스펙**(Codable). `id`·`name`·`icon`(SF Symbol)·`candidatePaths`·`versionArgs`·`invocation`(`args` + `promptVia` + `outputLastMessageFlag` 옵션)·`auth`(옵션). `promptVia`는 `stdin`(claude) 또는 `argTail`(프롬프트를 마지막 인자로 추가; codex). `outputLastMessageFlag`가 있으면 최종 답을 stdout이 아니라 `<flag> <임시파일>`로 받는 도구(codex `exec` 등)임을 뜻한다. `resolvedInvocation(prompt:outputFile:)` 순수 함수가 최종 인자 배열과 stdin 텍스트를 계산(`outputFile`가 주어지면 프롬프트 앞에 `outputLastMessageFlag`+파일경로를 끼운다).
- `AIToolRegistry.swift` — 번들 `Resources/ai-tools.json` 로드 → `loadAll()`·`tool(id:)`·`defaultTool()`. 기본 생성 엔진 id는 UserDefaults `defaultEngineID`(미설정 시 `claude`). `defaultTool()`은 저장 id가 없거나 사라지면 claude → 첫 도구로 폴백.
- `AIToolLocator.swift` — 도구별 바이너리 경로 탐색·캐시(UserDefaults `aiToolPath.<id>`), `version(of:)`, `authState(of:)`. 탐색 순서: 캐시 → `candidatePaths`(`~` 확장) → `/bin/zsh -lc 'command -v <id>'`. `rediscover(_:)`는 캐시 무시 재탐지. `migrateLegacyClaudePathIfNeeded()`가 구 `claudeBinaryPath` → `aiToolPath.claude` 1회 이전(앱 시작 시 `App.swift`에서 호출).
- `AIToolRunner.swift` — 스펙 기반 회의록 생성. `promptVia`에 따라 프롬프트를 stdin 또는 argTail로 전달. `outputLastMessageFlag`가 있으면 결과를 stdout이 아니라 `<flag> <임시파일>`로 받아 그 파일을 읽는다(codex `exec`는 stdout에 에이전트 이벤트가 섞임). `currentDirectoryURL`을 임시 폴더로 고정(codex git 체크·claude의 cwd CLAUDE.md 로드 회피). 기본 timeout 600초. 비-제로 종료 시 `AIToolRunnerError.nonZeroExit(toolName, code, stderr)`(stderr가 비면 stdout을 detail로 사용 — codex는 에러도 stdout에 씀), 미탐지 시 `binaryNotFound(toolName)`, 빈 응답 시 `noOutput(toolName)`. 선택적 `onResponseChunk` 콜백을 주면 **stdout이 곧 결과인 도구**(`outputLastMessageFlag` 미지정 → tempfile 미사용, `outputFileURL == nil`)에서만 stdout을 증분으로 읽어 매번 **누적 디코드 텍스트**를 전달한다(UTF-8 멀티바이트 경계에서 끝 바이트를 잘라가며 디코드해 한글 깨짐 방지). tempfile 도구(codex)와 stderr는 스트리밍하지 않는다. 콜백은 detached Task(백그라운드)에서 호출되므로 호출부가 MainActor로 hop해야 한다.
- `ConnectionsModel.swift` — `@MainActor ObservableObject`. 도구별 `AIToolStatus`(detected·path·version·`AuthState`)를 detached Task 프로브로 채워 설정 뷰에 게시. `refreshAll()`·`probe(_:)`·`rediscover(_:)`·`setPath(_:for:)`·`setDefault(_:)`.

## 인증 상태 (AuthState)

`loggedIn` / `loggedOut` / `unknown` / `checking`. `auth.type`:
- `credentialFile` — `paths` 중 하나라도 존재하면 로그인 추정 (claude `~/.claude/.credentials.json`, codex `~/.codex/auth.json`)
- `command` — 명령 실행 후 `successPattern` 매칭
- 스펙 없음 → `unknown` ("확인 불가")

**검증 상태(2026-06-02):**
- claude: `-p --output-format text --input-format text`, stdin. 검증됨.
- codex: `exec --skip-git-repo-check --ephemeral -s read-only -o <tempfile>`, argTail. **실호출 검증됨**(앱 실행). stdout이 지저분해 `-o` 파일로 최종 답 수신.

## 책임

- 도구별 연결 진단(경로·버전·로그인)과 사용자 경로 오버라이드(설정 "AI 도구" 패널)
- 전역 기본 생성 엔진 선택(`defaultEngineID`) → 모든 회의록 생성에 적용
- 회의록 생성 호출 (`AIToolRunner.generateMinutes(tool:…)`)

## 의존

- 외부: 각 AI CLI (시스템에 설치되어 있어야 함). 인증은 각 CLI가 자체 처리
- 상위: `Pipeline/TranscribeJob`(Phase 2·재생성에서 `defaultTool()`로 호출), `Sheets/SettingsView`(`connections` 패널)
- 데이터: 번들 `Resources/ai-tools.json`

## 보안

- AI CLI 호출 시 사용자 머신의 인증을 그대로 사용. 앱은 토큰을 읽거나 저장하지 않는다.
- 인증 상태는 자격증명 파일 **존재 여부만** 확인(내용 미열람).
- "경로 지정…"은 `isExecutableFile` 검증을 통과한 실행파일만 저장.
