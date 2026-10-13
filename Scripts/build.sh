#!/usr/bin/env bash
# record-up — Xcode IDE 없이 SwiftUI 앱을 빌드한다.
# 1) project.yml → recordup.xcodeproj 재생성
# 2) xcodebuild Release 빌드
# 3) ad-hoc 셀프 사인
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# --- 사전 점검 ---
require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "❌ '$1' 명령이 없습니다. 'brew install $2' 로 설치하세요." >&2
        exit 1
    fi
}
require xcodegen xcodegen
require xcodebuild "Xcode (App Store에서 정식 설치 후 sudo xcode-select -s /Applications/Xcode.app)"

# Command Line Tools만 있으면 SwiftUI 빌드가 실패하므로 명시적으로 확인.
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
if [[ -z "$SDK_PATH" || "$SDK_PATH" == */CommandLineTools/* ]]; then
    echo "❌ macOS SDK가 Xcode가 아닌 Command Line Tools를 가리킵니다." >&2
    echo "   App Store에서 Xcode를 설치한 뒤:" >&2
    echo "   sudo xcode-select -s /Applications/Xcode.app" >&2
    exit 1
fi

echo "▶︎ XcodeGen으로 .xcodeproj 재생성"
xcodegen generate --quiet

echo "▶︎ xcodebuild Release"
xcodebuild \
    -project recordup.xcodeproj \
    -scheme recordup \
    -configuration Release \
    -derivedDataPath .build \
    -quiet \
    clean build

APP_PATH=".build/Build/Products/Release/recordup.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "❌ 빌드 산출물이 없습니다: $APP_PATH" >&2
    exit 1
fi

echo "▶︎ 셀프 사인 (ad-hoc)"
codesign --deep --force --sign - "$APP_PATH"

echo
echo "✅ 빌드 완료: $APP_PATH"
echo "   실행: open $APP_PATH"
