#!/usr/bin/env bash
# record-up — 원샷 릴리즈 스크립트.
#   1) Resources/models 가 비어 있으면 fetch-models.sh 자동 실행
#   2) build.sh
#   3) package-pkg.sh (설치 마법사 .pkg — '설치 유형' 단계에서 AI 도구 선택 + SHA256)
# 결과: dist/record-up-<버전>.pkg 와 .sha256 (DMG가 필요하면 ./Scripts/package-dmg.sh)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

MODELS_ROOT="Resources/models"
WHISPER_DIR="$MODELS_ROOT/whisperkit-coreml"
SPEAKER_DIR="$MODELS_ROOT/speakerkit-coreml"

is_dir_empty() {
    local d="$1"
    [[ ! -d "$d" ]] && return 0
    [[ -z "$(ls -A "$d" 2>/dev/null)" ]] && return 0
    return 1
}

if is_dir_empty "$WHISPER_DIR" || is_dir_empty "$SPEAKER_DIR"; then
    echo "▶︎ Resources/models 가 비어있어 fetch-models.sh 자동 실행 (수GB 다운로드)"
    ./Scripts/fetch-models.sh
else
    echo "▶︎ 모델 동봉 확인 OK ($MODELS_ROOT)"
fi

./Scripts/build.sh
./Scripts/package-pkg.sh

echo
echo "🎁 릴리즈 산출물 (dist/):"
ls -lh dist/ 2>/dev/null || true
