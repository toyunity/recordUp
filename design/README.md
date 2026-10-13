# record-up — 디자인 핸드오프

이 폴더는 **record-up macOS 앱**(SwiftUI)의 디자인 시안과 구현 가이드를 담고 있습니다.
HTML/JSX는 인터랙티브 시안일 뿐이며, **실제 적용 대상은 `Sources/recordup/` SwiftUI 코드**입니다.

---

## 한 번에 시작하기

`record-up/` 저장소 루트에서:

```sh
# 1. 이 폴더(handoff)를 record-up/design/ 으로 풀기
unzip ~/Downloads/record-up-handoff.zip -d design/

# 2. Claude Code 실행
cd record-up
claude
```

첫 프롬프트 (복사·붙여넣기):

```
design/CLAUDE.md 를 읽고 record-up 디자인 시스템 적용을 시작해줘.
먼저 design/Theme.swift 를 Sources/recordup/Theme.swift 로 가져오고,
화면별로 한 번에 하나씩 디자인을 적용한다 (transcript → minutes → templates 순).
스크린샷은 design/screenshots/ 에 있다.
```

---

## 폴더 구성

```
design/
├── README.md                        # 이 파일
├── CLAUDE.md                        # Claude Code용 컨텍스트 (필수 읽기)
├── Theme.swift                      # SwiftUI Color/Font extension (바로 복붙 가능)
├── design-tokens.json               # 디자인 토큰 (RGB, 폰트, 간격)
│
├── screenshots/                     # 화면별 디자인 시안 PNG
│   ├── 01-drop.png                  # ContentView (드롭존)
│   ├── 02-library.png               # 라이브러리 (v2 — 신규)
│   ├── 03-templates.png             # TemplateManagerView
│   ├── 04-settings.png              # SettingsView (v2 — 신규)
│   ├── 05-minutes.png               # MinutesReviewView
│   └── 06-transcript.png            # TranscriptReviewView
│
└── prototype/                       # 인터랙티브 HTML 시안 (브라우저에서 열기)
    ├── record-up.html
    ├── app.jsx
    ├── tweaks-panel.jsx
    ├── macos-window.jsx
    └── components/                  # 화면별 React 컴포넌트
        ├── tokens.jsx
        ├── window-shell.jsx
        ├── sidebar.jsx
        ├── icons.jsx
        ├── data.jsx
        ├── screen-drop.jsx
        ├── screen-progress.jsx
        ├── screen-transcript.jsx
        ├── screen-minutes.jsx
        ├── screen-library.jsx
        ├── screen-templates.jsx
        ├── screen-settings.jsx
        └── sheet-template-picker.jsx
```

---

## 인터랙티브 시안 보기

```sh
cd design/prototype
python3 -m http.server 8000
# 브라우저: http://localhost:8000/record-up.html
```

우상단 **Tweaks** 토글로 화면 전환·테마 변경 가능 (warm / mono / dark).

---

## 디자인 매핑 — 시안 → SwiftUI 파일

| 시안 (스크린샷)            | SwiftUI 대상                                          |
|-------------------------|-----------------------------------------------------|
| `01-drop.png`            | `Sources/recordup/ContentView.swift`                |
| `02-library.png` *(신규)*| 신규 `Sources/recordup/Sheets/LibraryView.swift`     |
| `03-templates.png`       | `Sources/recordup/Sheets/TemplateManagerView.swift` |
| `04-settings.png` *(신규)*| 신규 `Sources/recordup/Sheets/SettingsView.swift`    |
| `05-minutes.png`         | `Sources/recordup/Sheets/MinutesReviewView.swift`   |
| `06-transcript.png`      | `Sources/recordup/Sheets/TranscriptReviewView.swift`|

---

## 작업 순서 (권장)

1. **Theme 적용**: `design/Theme.swift` → `Sources/recordup/Theme.swift` 복사 후 빌드 확인
2. **TranscriptReviewView**: 화자별 색상 칩, 인라인 편집, 파형 푸터
3. **MinutesReviewView**: 마크다운/미리보기 분할, 결정·액션 강조
4. **TemplateManagerView**: 섹션 구성 ↔ 프롬프트 동기화
5. **ContentView (드롭존)**: 사이드바 + 큰 타이틀 + recents 카드
6. **신규**: LibraryView, SettingsView 추가 (현재 코드베이스에 없음)

각 단계는 별도 PR로 분리 권장.
