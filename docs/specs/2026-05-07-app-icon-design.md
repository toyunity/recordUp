# record-up AppIcon 디자인 스펙

- 작성일: 2026-05-07
- 대상: `Resources/Assets.xcassets/AppIcon.appiconset`
- 생성 스크립트: `Scripts/generate-app-icon.swift`

## 컨셉
"녹음에서 회의록으로의 변환." 좌측 마이크에서 발산된 음파가 우측으로 갈수록 문서 텍스트 라인으로 변형되는 흐름으로 앱의 핵심 가치(음성 → 구조화된 회의록)를 한 장면에 담는다.

## 시각 스타일
- macOS Tahoe/Sonoma 아이콘 컨벤션
- 1024×1024 캔버스, Apple squircle(라운드 비율 ≈ 22.37%)로 배경 마스킹
- 상단 1% 미세 하이라이트, 안쪽 옅은 inner shadow로 깊이감
- 콘텐츠 안전 영역: 캔버스의 중앙 ~80%

## 컬러 팔레트
- 배경 그라데이션 (좌상 → 우하 대각선)
  - 시작 `#FF6A3D` (선명한 오렌지)
  - 끝   `#E0245E` (딥 레드핑크)
- 심볼: `#FFFFFF` (불투명도 100%)
- 음파/리플: 화이트, 끝쪽으로 알파 70% → 40% 감쇠
- 문서 라인: 화이트, 라인 두께 점진 감소

## 구성 요소 (1024 캔버스 좌표)
- 마이크 (좌측 1/3)
  - 캡슐형 그릴 약 200×360, 중앙 (300, 470)
  - 하단 짧은 스탠드 + 받침 라인
- 음파 → 문서 변환 영역 (가운데)
  - 마이크 우측에서 동심원형 리플 3겹이 우측으로 갈수록 직선화되며 문서 라인으로 전이
- 문서 라인 (우측 1/3)
  - 5~6줄, 둥근 끝 직사각형
  - 위에서 아래로 갈수록 약간 짧아져 텍스트 단락 느낌

## 산출물
```
Resources/Assets.xcassets/AppIcon.appiconset/
├── Contents.json
├── icon_16x16.png        (16)
├── icon_16x16@2x.png     (32)
├── icon_32x32.png        (32)
├── icon_32x32@2x.png     (64)
├── icon_128x128.png      (128)
├── icon_128x128@2x.png   (256)
├── icon_256x256.png      (256)
├── icon_256x256@2x.png   (512)
├── icon_512x512.png      (512)
└── icon_512x512@2x.png   (1024)
```

## 생성 방법
- `Scripts/generate-app-icon.swift`를 SwiftUI `ImageRenderer`로 작성
- 1024×1024 단일 디자인을 그린 뒤 필요한 모든 사이즈로 다운스케일
- `swift Scripts/generate-app-icon.swift` 실행 한 번으로 모든 PNG와 Contents.json 자동 생성
- 추가 의존성 없음 (macOS 14 + Swift 5.9)

## 검증
- 1024 원본에서 디자인 의도(마이크 → 음파 → 문서) 확인
- 16×16에서도 마이크 실루엣이 식별 가능한지 점검 (가장 중요한 품질 지표)
- 빌드 후 Dock/Finder 실제 렌더 확인
