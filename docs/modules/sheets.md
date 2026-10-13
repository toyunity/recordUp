# Sheets 모듈

`Sources/recordup/Sheets/` — 검토 화면 + 사이드바 라우팅 대상 화면 + 진짜 모달 시트.

> 디렉터리 이름은 "Sheets"지만 실제 내용은 **주요 화면**도 함께 위치한다. `Root/RootView`가 `TranscribeJob.Stage` 또는 `SidebarItem`에 따라 이 디렉터리의 View들을 메인 영역에 그린다.

## 파일

### 검토 화면 (메인 영역)
- `TranscriptReviewView.swift` — Phase 1 산출 `EditableTranscript` 편집 + 화자 매핑 + 재생(연계: `Audio/AudioPlayerEngine`) + "회의록 만들기" 트리거.
- `MinutesReviewView.swift` — 회의록 마크다운 편집 + 저장 + 외부 앱으로 열기 + 공유/PDF/RTF (`Export/ExportFormats`). `Source` enum(`newRecord`/`library`)으로 컨텍스트 구분:
  - `newRecord`: Phase 2 산출에서 진입. 브레드크럼 "새 회의록 → 2단계", "다시 생성" 버튼 노출, 재생성 hint 입력 (`onRegenerate`).
  - `library`: 라이브러리에서 항목 클릭 시 진입. 브레드크럼 "라이브러리", "다시 생성" 숨김, `onBack`으로 라이브러리 복귀 버튼 노출.
  - 메타 헤더는 외부에서 주입한 `createdAt`·`participantCount`(둘 다 옵션)를 그대로 표시(자체 추정 로직 없음).

### 사이드바 라우팅 화면 (메인 영역)
- `LibraryView.swift` — 회의록 목록(`MinutesIndex`) + 핀(`PinnedStore`) + 상세 미리보기. 행 클릭은 인앱 검수(`selected = entry`); 외부 앱 열기는 행 more-menu의 "외부 앱으로 열기"로 이동.
- `TemplateManagerView.swift` — 회의록 프롬프트 템플릿 관리 (조회/편집/삭제/신규).
- `SettingsView.swift` — 앱 설정. 카테고리는 `storage` / `connections` / `about` 3개:
  - **storage**: 모델 캐시 경로 카드(폴더 열기) + 토글 3종(`autoDeleteAudio`/`autoOpenMinutes`/`syncICloud`). "준비 중"·"v2 예정" inline 배지로 비활성 항목 표시. `estimatedSize`는 `FileManager.enumerator`로 재귀 합산.
  - **connections** ("AI 도구"): 회의록 생성에 쓸 로컬 AI CLI 연결 관리. `ConnectionsModel`(`@StateObject`)이 도구별 상태를 detached 프로브로 채움. "기본 생성 엔진" 라디오 칩(연결된 도구만 선택 가능, `defaultEngineID` 저장) + 도구 카드(아이콘·버전·경로 + 연결/인증 상태 배지 + "자동 탐지"·"경로 지정…"·"테스트" 버튼). "경로 지정…"은 `NSOpenPanel`로 고른 파일을 `isExecutableFile` 검증 후 저장.
  - **about**: 앱 버전(`CFBundleShortVersionString` + `CFBundleVersion` 합성), 외관(테마), 릴리스 노트(`ReleaseNotesStore.loadAll()`의 최신 highlight 표시 → 클릭 시 `ReleaseNotesSheet`), 개발/지원 메일, 오픈소스 알림.
  - 같은 파일에 fileprivate `ReleaseNotesSheet` 정의(520×480, ScrollView로 노트 카드 나열, 빈 상태 안내 포함).
- `TemplateUsageStat.swift` — 템플릿 사용 통계 표시.

### 진짜 모달 시트
- `TemplatePicker.swift` — 새 회의록 시작 시 표시되는 템플릿 선택 시트 (`TemplatePickerSheet`).
- `NewTemplateSheet.swift` — 새 템플릿 생성 시트.
- `ConfirmCancelSheet.swift` — 작업 취소 컨펌 모달 (`Root/RootView`가 ZStack으로 표시). `title` 커스터마이즈 가능, 선택적 `saveLabel`/`onSave`를 주면 "저장하고 나가기"(브랜드 강조) 3번째 버튼을 노출(이때 카드 폭 480, 기본 420).

## 의존

- 내부: `Pipeline/EditableTranscript`·`TranscribeJob` (검토), `Library/*`(목록/핀), `Claude/PromptTemplateStore`(템플릿), `AITools/ConnectionsModel`(설정 AI 도구 패널), `Audio/AudioPlayerEngine`(재생), `Export/*`(저장·내보내기)
- 상위: `Root/RootView`가 stage·sidebar에 따라 표시
