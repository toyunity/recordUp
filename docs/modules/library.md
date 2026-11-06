# Library 모듈

`Sources/recordup/Library/` — 회의록 인덱스 + 핀(고정) 상태.

> 앱 내 직접 녹음은 비범위(README §8). 본 모듈은 외부 음성 메모를 처리한 결과물(회의록)만 인덱싱한다.

## 파일

- `MinutesIndex.swift` — `@MainActor ObservableObject`. `~/Documents/record-up/minutes/*.md`를 스캔해 `MinutesEntry`로 변환. 각 항목에서 frontmatter(`title`/`generated_at`/`elapsed_seconds`/`template`/`template_id`/`source`) + 본문 H1 + 결정/액션 카운트 추출. `createdAt` 내림차순 정렬, `recents`는 상위 6개. `MinutesIndex.shared` 싱글톤.
- `PinnedStore.swift` — `@MainActor ObservableObject`. 회의록 핀 상태(파일 경로 = id)를 `UserDefaults.pinnedMinuteIDs`(string array)에 저장. `toggle(_:)`/`isPinned(_:)`/`setPinned(_:pinned:)`. `PinnedStore.shared` 싱글톤.

## 카운팅 로직 (`MinutesIndex`)

- **결정 사항**: 본문에 "결정 사항" 텍스트가 있으면 "결정" 토큰, 없으면 "decision" 토큰 등장 횟수 (캡 99)
- **액션 아이템**: `- [ ]` / `- [x]` / `- [X]` 체크박스 라인 카운트

## 의존

- 내부: `Export/TranscriptExporter.outputDirectory(subdir:)`로 minutes 디렉터리 경로 획득
- 상위: `Sheets/LibraryView`(목록 화면), `Root/Sidebar`(최근 회의록 표시), `Sheets/MinutesReviewView`(저장 후 reload)
