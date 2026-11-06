#!/usr/bin/env bash
# 빌드된 .app 을 설치 마법사(.pkg)로 패키징한다.
#   - "설치 유형(사용자화)" 단계에서 회의록 생성 AI 도구(claude/codex) 중 하나를 고른다.
#   - 고른 도구는 postinstall 에서 콘솔 사용자의 UserDefaults `defaultEngineID` 로 기록된다.
#   - STT 모델은 .app 번들에 동봉된 그대로 설치된다(선택 없음).
# 결과: dist/record-up-<버전>.pkg 와 .sha256
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

APP_PATH=".build/Build/Products/Release/recordup.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "▶︎ 빌드 산출물이 없어 ./Scripts/build.sh 자동 실행"
    ./Scripts/build.sh
fi

BUNDLE_ID="com.toyunity.recordup"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Contents/Info.plist")"
DIST_DIR="dist"
PKG_NAME="record-up-${VERSION}.pkg"
PKG_PATH="$DIST_DIR/$PKG_NAME"
# 선택지로 노출할 엔진 — Resources/ai-tools.json 의 id 와 일치해야 한다.
ENGINES=(claude codex)
ENGINE_TITLES=(Claude Codex)

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 1) 앱 컴포넌트 pkg — 재배치(relocation) 비활성화.
#    기본값(true)이면 디스크 어딘가에 같은 번들 ID 앱(예: .build 산출물)이 있을 때 거기로 덮어써 버린다.
mkdir -p "$WORK/root/Applications"
ditto "$APP_PATH" "$WORK/root/Applications/recordup.app"
pkgbuild --analyze --root "$WORK/root" "$WORK/component.plist" >/dev/null
plutil -replace 0.BundleIsRelocatable -bool NO "$WORK/component.plist"
pkgbuild --quiet \
    --root "$WORK/root" \
    --component-plist "$WORK/component.plist" \
    --identifier "$BUNDLE_ID.app" \
    --version "$VERSION" \
    --install-location / \
    "$WORK/app.pkg"

# 2) 엔진별 payload 없는 pkg — postinstall 이 기본 엔진을 기록한다.
for engine in "${ENGINES[@]}"; do
    mkdir -p "$WORK/scripts-$engine"
    cat > "$WORK/scripts-$engine/postinstall" <<EOF
#!/bin/sh
# installer 는 root 로 돌므로 로그인한 콘솔 사용자 도메인에 써야 앱이 읽는다.
CONSOLE_USER=\$(stat -f%Su /dev/console)
[ -z "\$CONSOLE_USER" ] || [ "\$CONSOLE_USER" = "root" ] && exit 0
sudo -u "\$CONSOLE_USER" defaults write $BUNDLE_ID defaultEngineID $engine
exit 0
EOF
    chmod +x "$WORK/scripts-$engine/postinstall"
    pkgbuild --quiet --nopayload \
        --scripts "$WORK/scripts-$engine" \
        --identifier "$BUNDLE_ID.engine.$engine" \
        --version "$VERSION" \
        "$WORK/engine-$engine.pkg"
done

# 3) Distribution — 엔진 선택지는 서로 배타(라디오처럼 동작). customize="always" 로 선택 단계를 항상 노출.
{
cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>record-up ${VERSION}</title>
    <options customize="always" require-scripts="false" hostArchitectures="arm64"/>
    <domains enable_localSystem="true"/>
    <os-version min="14.0"/>
    <choices-outline>
        <line choice="app"/>
        <line choice="engine">
EOF
for engine in "${ENGINES[@]}"; do echo "            <line choice=\"engine-$engine\"/>"; done
cat <<EOF
        </line>
    </choices-outline>
    <choice id="app" title="record-up 앱" description="앱과 한국어 STT 모델(WhisperKit large-v3-turbo · SpeakerKit)을 설치합니다." enabled="false" selected="true">
        <pkg-ref id="$BUNDLE_ID.app"/>
    </choice>
    <choice id="engine" title="회의록 생성 AI 도구" description="하나만 선택하세요. 나중에 앱 설정에서 바꿀 수 있습니다."/>
EOF
for i in "${!ENGINES[@]}"; do
    engine="${ENGINES[$i]}"
    others=""
    for other in "${ENGINES[@]}"; do
        [[ "$other" == "$engine" ]] && continue
        others+="${others:+ &amp;&amp; }!choices['engine-$other'].selected"
    done
    start="false"; [[ $i -eq 0 ]] && start="true"
    cat <<EOF
    <choice id="engine-$engine" title="${ENGINE_TITLES[$i]}" description="${ENGINE_TITLES[$i]} CLI로 회의록을 생성합니다. CLI가 설치·로그인돼 있어야 합니다." start_selected="$start" selected="my.choice.selected &amp;&amp; $others">
        <pkg-ref id="$BUNDLE_ID.engine.$engine"/>
    </choice>
EOF
done
cat <<EOF
    <pkg-ref id="$BUNDLE_ID.app" version="$VERSION">app.pkg</pkg-ref>
EOF
for engine in "${ENGINES[@]}"; do
    echo "    <pkg-ref id=\"$BUNDLE_ID.engine.$engine\" version=\"$VERSION\">engine-$engine.pkg</pkg-ref>"
done
echo "</installer-gui-script>"
} > "$WORK/distribution.xml"

mkdir -p "$DIST_DIR"
rm -f "$PKG_PATH" "$PKG_PATH.sha256"
echo "▶︎ PKG 생성: $PKG_PATH"
productbuild --quiet \
    --distribution "$WORK/distribution.xml" \
    --package-path "$WORK" \
    "$PKG_PATH"

( cd "$DIST_DIR" && shasum -a 256 "$PKG_NAME" ) > "$PKG_PATH.sha256"

echo
echo "✅ 패키지: $PKG_PATH"
echo "   설치: 우클릭 → 열기 (서명되지 않은 pkg) → '설치 유형'에서 AI 도구 선택"
