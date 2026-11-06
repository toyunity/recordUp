# Claude 모듈

`Sources/recordup/Claude/` — 회의록 **프롬프트 템플릿** 관리.

> 회의록 생성 호출과 바이너리 탐색은 [AITools 모듈](ai-tools.md)로 일반화되어 이동했다.
> (구 `ClaudeBinaryLocator.swift`·`ClaudeRunner.swift` → `AIToolLocator.swift`·`AIToolRunner.swift`)

## 파일

- `PromptTemplateStore.swift` — `Resources/prompts/*.md`(번들) + `~/Documents/record-up/Templates/*.md`(사용자) 통합 로드. 같은 ID는 사용자 템플릿이 번들을 덮어쓴다. ID는 `[A-Za-z0-9_-]`만 허용. frontmatter `---\ntitle: ...\ndescription: ...\n---` 파싱. 사용자 템플릿 CRUD(`write(draft:)`·`delete(template:)`)와 `nextNewID()`.

## 책임

- 회의록 프롬프트 템플릿 선택·관리 (도구와 독립적; 어느 AI 엔진이든 동일 템플릿 사용)
- 번들 기본 템플릿: default / decision-action / customer-interview / brainstorming / one-on-one / requirements / retrospective / weekly-sync
- 사용자 템플릿 CRUD, `nextNewID()`로 충돌 없는 새 ID

## 의존

- 상위: `Pipeline/TranscribeJob`(생성·재생성 시 템플릿 본문 사용), `Sheets/TemplatePicker`·`TemplateManagerView`(선택/관리 UI), `Sheets/MinutesReviewView`(재생성 hint)
- 회의록 생성 실행은 `AITools/AIToolRunner` 가 담당

## 보안

- 프롬프트 템플릿은 `Resources/prompts/`에 정적 번들; 사용자 추가본은 `~/Documents/record-up/Templates/`
- 사용자 템플릿 ID는 화이트리스트(`[A-Za-z0-9_-]`)로만 허용 — 경로 탈출 방지
