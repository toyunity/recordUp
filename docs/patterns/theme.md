# Theme 패턴

`Sources/recordup/Theme.swift`, `Sources/recordup/Theme+Components.swift`.

## 출처

`design/design-tokens.json` + `design/Theme.swift`가 source of truth. `Sources/recordup/Theme.swift`는 빌드 타깃에 들어가는 변환본.

## 구성

- **`AppTheme`** (`enum`): `warm` / `dark`. `@AppStorage(AppTheme.storageKey)`로 사용자 선택을 영속. `App.swift`의 `WindowGroup`에 `preferredColorScheme(...)`으로 적용.
- **`ThemePalette`**: 컬러 토큰(`canvas`, `ink50`, …) 모음. `EnvironmentValues.palette`로 뷰 트리 전체에 주입.
- **`Font.ui(size:)`**: 시스템 폰트를 일관 사용하기 위한 ui-typography 헬퍼.
- **공통 컴포넌트**(`Theme+Components.swift`): 화면 전반의 반복 패턴을 모아둔 SwiftUI ViewModifier·View 확장. 인라인 스타일을 점진적으로 이쪽으로 치환한다.

## 사용 가이드

- 새 컴포넌트가 2회 이상 등장하면 `Theme+Components`에 추출 검토.
- 색상은 항상 `palette`(환경값) 또는 시스템 컬러를 거쳐 사용. 인라인 `Color(red:green:blue:)` 금지.
- 다크모드 자동 대응을 위해 `@Environment(\.colorScheme)` 또는 palette의 사전 분기 사용.
- `design/design-tokens.json`이 변경되면 `Theme.swift`도 함께 업데이트해야 한다 (수기 또는 design 워크플로우).
