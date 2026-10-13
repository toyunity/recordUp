#!/usr/bin/env bash
# 빌드된 .app 을 DMG로 패키징한다.
#   - 빌드 산출물이 없으면 build.sh 자동 호출 (단독 실행 가능)
#   - DMG 안에 INSTALL.txt 동봉 (Gatekeeper 우회 안내 포함)
#   - 같은 폴더에 .sha256 무결성 파일 생성
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

APP_PATH=".build/Build/Products/Release/recordup.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "▶︎ 빌드 산출물이 없어 ./Scripts/build.sh 자동 실행"
    ./Scripts/build.sh
fi

if ! command -v create-dmg >/dev/null 2>&1; then
    echo "❌ create-dmg가 없습니다. 'brew install create-dmg'." >&2
    exit 1
fi

VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Contents/Info.plist")"
DIST_DIR="dist"
DMG_NAME="record-up-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
INSTALL_GUIDE="Scripts/dmg-assets/INSTALL.txt"

if [[ ! -f "$INSTALL_GUIDE" ]]; then
    echo "❌ 설치 안내 파일이 없습니다: $INSTALL_GUIDE" >&2
    exit 1
fi

mkdir -p "$DIST_DIR"
# 이전 실행 잔재 정리: 최종 dmg + sha256 + create-dmg 의 read-write 중간 파일(rw.*.dmg)
rm -f "$DMG_PATH" "$DMG_PATH.sha256" "$DIST_DIR"/rw.*.dmg

# --skip-jenkins:
#   create-dmg 마지막 단계의 osascript(Finder로 아이콘 좌표 정렬)는 macOS 자동화 권한이
#   터미널에 부여돼 있지 않거나 Finder 응답이 느릴 때 -1712 (timeout)로 자주 실패한다.
#   설치 흐름에서 핵심은 동봉된 INSTALL.txt 와 Applications 드롭 링크이므로 비주얼 정렬은
#   포기하고 DMG 생성을 안정화한다. 예쁜 정렬을 원하면 RECORDUP_PRETTY_DMG=1 로 호출.
SKIP_FLAG="--skip-jenkins"
if [[ "${RECORDUP_PRETTY_DMG:-0}" == "1" ]]; then
    SKIP_FLAG=""
fi

echo "▶︎ DMG 생성: $DMG_PATH"
create-dmg \
    --volname "record-up ${VERSION}" \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "recordup.app" 150 200 \
    --app-drop-link 450 200 \
    --add-file "INSTALL.txt" "$INSTALL_GUIDE" 300 60 \
    --hdiutil-quiet \
    --no-internet-enable \
    $SKIP_FLAG \
    "$DMG_PATH" \
    "$APP_PATH"

echo "▶︎ SHA256 체크섬 생성"
( cd "$DIST_DIR" && shasum -a 256 "$DMG_NAME" ) > "$DMG_PATH.sha256"

echo
echo "✅ 패키지: $DMG_PATH"
echo "   체크섬: $DMG_PATH.sha256"
echo "   설치: open $DMG_PATH  → INSTALL.txt 안내대로 Applications 폴더로 드래그"
