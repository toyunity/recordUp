# Export 모듈

`Sources/recordup/Export/` — 전사본·회의록 저장 + 다른 포맷 내보내기.

## 파일

- `TranscriptExporter.swift` — `EditableTranscript` → 사람·LLM 모두 읽기 좋은 Markdown. frontmatter(`source`, `duration`, `speakers`, `generated_at`, `speaker_mapping`) + `# 전사본 — <원본명>` + 블록(`**화자A** (mm:ss–mm:ss)`). `~/Documents/record-up/transcripts/<yyyyMMdd-HHmm>-<원본명>.md`로 저장. `outputDirectory(subdir:)`/`filename(for:)`/`formatTime(_:)` 유틸을 다른 모듈도 재사용.
- `MinutesExporter.swift` — `claude -p` 결과 본문 + 메타 frontmatter(`source`, `template`, `template_id`, `generated_at`, `elapsed_seconds`)를 붙여 `~/Documents/record-up/minutes/<yyyyMMdd-HHmm>-<원본명>.md`로 저장. `existingURL`을 넘기면 새 타임스탬프 파일을 만들지 않고 그 URL을 덮어쓴다 — 같은 작업의 자동 저장→편집 ⌘S→재생성이 분 경계마다 중복 파일을 만드는 것을 막는다(`filename(for:)`이 분 단위 stamp 사용). `openInDefaultEditor(_:)`로 시스템 기본 앱에서 열기.
- `ExportFormats.swift` — 회의록 마크다운을 **서식화된** `NSAttributedString`(`attributedDocument(from:)`)으로 변환 → **PDF**(US Letter 612×792, 54pt 마진, CoreText 자동 페이지 분할) / **RTF**(Word 호환) / **시스템 공유 시트**. frontmatter와 HTML 주석(`<!-- ... -->`)을 제거하고 `Sheets/MinutesReviewView.parseBlocks`를 미러링해 헤더 크기·굵기·메타라인·불릿·결정(번호)·액션(체크박스)을 스타일링한다 — **파서가 두 벌이므로 한쪽을 바꾸면 다른 쪽도 같이 고쳐야 한다**. 인라인 서식은 `**bold**`만 지원(이탤릭·링크·인라인 코드는 기호째 출력); 결정 섹션 밖 번호 목록은 불릿으로, 표 등 미지원 구문은 일반 문단으로 떨어진다. PDF/RTF는 raw CGContext에 appearance 컨텍스트 없이 그려져 동적색(labelColor 등)이 다크 모드에서 흰색으로 풀리므로 **고정 ink 색**으로 그린다. `runSavePanel(suggestedName:allowedExtension:directoryURL:save:)` NSSavePanel 통합 헬퍼 — `directoryURL`로 기본 폴더를 명시하면(없으면 생성) 음성 메모 불러오기가 열어둔 TCC 보호 폴더가 기본값으로 떠 쓰기 권한이 거부(NSCocoaError 513 / EPERM)되는 것을 막는다.

## 출력 위치

| 산출물 | 경로 |
|---|---|
| 전사본 | `~/Documents/record-up/transcripts/<stamp>-<원본명>.md` |
| 회의록 | `~/Documents/record-up/minutes/<stamp>-<원본명>.md` |
| PDF/RTF | 사용자가 NSSavePanel로 직접 선택 (기본 폴더 `~/Documents/record-up/minutes/`) |

stamp 포맷: `yyyyMMdd-HHmm` (`en_US_POSIX`).

## 의존

- 외부: AppKit(`NSSavePanel`, `NSSharingServicePicker`), CoreText, Foundation
- 내부: `Pipeline/EditableTranscript` 입력
- 상위: `Pipeline/TranscribeJob` (자동 저장), `Sheets/MinutesReviewView` (사용자 export 액션)
