# Claude Code Context — record-up Design Application

## 프로젝트 컨텍스트

- **앱**: record-up — 음성 메모 → 한국어 전사 → 회의록 자동 생성 macOS 앱
- **스택**: SwiftUI (macOS 14+, Apple Silicon), XcodeGen + xcodebuild CLI 빌드
- **소스 위치**: `Sources/recordup/`
- **현재 단계**: 기능 구현 완료, **디자인 적용 중**

## 디자인 원칙

1. **Apple Notes 정도의 일상감** — 따뜻하고 부드러운 톤. 차갑지 않게.
2. **온디바이스 신뢰감** — "파일이 외부로 전송되지 않아요" 메시지를 강조.
3. **한국어 우선** — 모든 UI 텍스트 한국어. 폰트는 SF Pro 기본.
4. **컬러풀한 액센트** — 오렌지(#FF6A3D) → 레드핑크(#E0245E) 그라데이션이 시그니처.
5. **세 가지 테마** — warm (기본), mono (단색), dark. 사용자가 설정에서 전환.

## 디자인 시스템

전체 토큰은 `design-tokens.json` 와 `Theme.swift` 참고.

### 핵심 색상 (warm 테마, 기본)
- `canvas`: `#f6f1ea` — 윈도우 배경
- `surface`: `#ffffff` — 카드
- `ink`: `#1f1a17` — 본문 텍스트
- `accent`: `#FF6A3D` — 오렌지 (primary)
- `accent2`: `#E0245E` — 레드핑크 (gradient end)
- `gradient`: `linear-gradient(135deg, #FF6A3D, #E0245E)` — primary 버튼·로고

### 의미 색상
- `success`: `#1f8a5b` — 모델 다운로드 완료
- `decision`: `#7A5AE0` — 결정 사항 강조 (보라)
- `action`: `#0E7C86` — 액션 아이템 강조 (청록)

### 타이포그래피
- **UI**: SF Pro Text (시스템 기본)
- **Display**: SF Pro Display — 큰 제목 (≥17pt)
- **Mono**: SF Mono — 시간/숫자/메타데이터

### 모서리
- 카드: 12px
- 작은 칩/버튼: 8px
- Pill 버튼: full (height/2)

## 화면별 적용 가이드

### 1. ContentView (드롭존) — `01-drop.png`

**기존**: 단순 드롭존
**신규 디자인**:
- 좌측 사이드바 (240px): 그라데이션 로고 워드마크 "record·UP", 4개 nav, 최근 회의록 6개 리스트
- 메인: 큰 디스플레이 타이틀 "음성 메모를 떨어뜨리세요." + 부제 + 큰 드롭존 (마이크 아이콘, 호버 시 파형 애니메이션)
- 드롭존 아래: 3개 import 옵션 카드 (음성 메모 앱, URL, Mac 직접 녹음 — 후자 둘은 v2 잠금)
- 하단: "이어서 작업하기" 최근 2개 카드

### 2. LibraryView (라이브러리) — `02-library.png` *(신규)*

전체 회의록 테이블. 컬럼: 제목, 날짜, 길이, 화자(아바타 그룹), 결정/액션 카운트.
상단에 검색 입력(⌘F) + 필터 칩 (전체 / 결정·액션 / 기본 / 고객 인터뷰 / 1:1).

### 3. TemplateManagerView — `03-templates.png`

좌측: 템플릿 리스트 + "새 템플릿" 그라데이션 버튼.
우측 상세:
- 헤더: 아이콘 + 이름 + 부제 + "복제" / "기본 설정" / "편집" 액션
- **섹션 구성** (단일 진실 소스): 카드 그리드, 행 호버 시 ✕ 삭제, 끝에 "+ 섹션 추가"
- **프롬프트** 영역: "🔒 섹션 변경 시 자동 갱신됩니다" 칩 + 마크다운 미리보기 textarea (읽기 전용 느낌)

### 4. SettingsView — `04-settings.png` *(신규)*

분할 뷰 — 좌측 카테고리 (모델·저장 위치·단축키·정보), 우측 패널.
**모델 패널**: STT(WhisperKit) 라디오 — large-v3-turbo (권장, 다운로드됨), large-v3 (3.1GB, 다운로드 버튼), medium / Diarization(SpeakerKit) 라디오 / Claude Code CLI 상태 카드.

### 5. MinutesReviewView — `05-minutes.png`

상단 툴바: breadcrumb "새 회의록 → 2단계", 큰 제목 **"회의록 검토"** + 메타(결정 N · 액션 N · 참석자 · 자동 저장됨), 우측 "전사본으로" 버튼.
좌측: 마크다운 편집기 (모노스페이스 텍스트). 우측: 렌더링된 미리보기 — 결정 사항은 보라 액센트 카드, 액션 아이템은 청록 체크박스.
하단: 파일 경로(`~/Documents/record-up/minutes/...md`) + 복사 / Finder에서 보기 / 새 회의록 / **내보내기** (그라데이션 primary).

### 6. TranscriptReviewView — `06-transcript.png`

상단 툴바: breadcrumb "새 회의록 → 1단계", 큰 제목 "전사본 검토" + 부제, 우측 "취소" / "회의록 생성" (그라데이션).
헤더: 회의명 + 메타(길이 · 화자 N · N개 구간 · 신뢰도 N%) + "찾기" / "화자 N명 관리".
본문: 화자 칩(이니셜 + 색) + 타임스탬프(모노) + 텍스트. 행 클릭 시 즉시 편집 모드 (textarea 인라인). 각 행 우측 액션: 편집/재생/아래에 추가/삭제 (45% opacity, 호버 시 100%).
우측 패널: 원본 파일 / 신뢰도 / 화자 관리 (이름 인라인 편집 + 발화율 바) / "다음 단계" 카드.
하단 푸터: 재생 컨트롤 + 파형 + 1.0× 속도 + 다시 시작 + "회의록 생성하기".

## SwiftUI 적용 팁

- **Color extension**: `Theme.swift` 의 `Color.canvas`, `Color.ink`, `Color.accent` 등을 그대로 사용
- **Gradient**: `LinearGradient.brand` 사용 (Theme.swift 정의됨)
- **Font**: `Font.display(size:)`, `Font.ui(size:)`, `Font.mono(size:)` 헬퍼 사용
- **테마 전환**: `@Environment(\.colorScheme)` + `@AppStorage("theme")` 조합 권장
- **카드 그림자**: `shadow(color: .black.opacity(0.04), radius: 8, y: 2)` 정도로 가볍게
- **호버 효과**: `onHover { hovering in ... }` + `withAnimation(.easeOut(duration: 0.15))`

## 비범위 (이번 디자인 적용에서 제외)

- iCloud Voice Memos 자동 감지 UI (v2)
- 앱 내 직접 녹음 UI (v2 — 카드만 보이고 잠금)
- URL 임포트 (Google Meet/Zoom — v2)
- 다국어 UI

## 작업 후 검증

각 화면 적용 후:
1. `./Scripts/build.sh` 빌드 통과
2. 시안 스크린샷과 실제 빌드 비교
3. 세 테마(warm / mono / dark) 모두에서 깨지지 않는지 확인

---

## 참고 — 인터랙티브 HTML 시안 보기

```sh
cd design/prototype
python3 -m http.server 8000
```

http://localhost:8000/record-up.html — 우상단 Tweaks로 화면 전환·테마 토글.
SwiftUI에서 의도가 모호할 때 이 시안을 단일 진실 소스로 참고.
