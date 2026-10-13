#!/usr/bin/env bash
# 네트워크 제한으로 막히면 이 스크립트를 다른 네트워크에서 한 번만 실행한다.
# 받은 모델은 .app 번들에 동봉되므로 그 후로는 오프라인 동작.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$PROJECT_ROOT/Resources/models"

# 새 Hugging Face CLI는 'hf' (예전 'huggingface-cli'는 deprecated).
if ! command -v hf >/dev/null 2>&1; then
    echo "▶︎ hf 설치 (없으면)"
    brew install hf
fi

WHISPER_VARIANT="${WHISPER_VARIANT:-openai_whisper-large-v3-v20240930_turbo_632MB}"

echo "▶︎ WhisperKit 모델 다운로드: $WHISPER_VARIANT"
hf download argmaxinc/whisperkit-coreml \
    --include "$WHISPER_VARIANT/*" \
    --local-dir "$DEST/whisperkit-coreml"

# 토크나이저는 whisperkit-coreml 저장소에 없다. 모델 폴더에 두지 않으면 WhisperKit이
# 첫 전사 때 Hugging Face에서 받으려다(~/Documents/huggingface) 오프라인·네트워크 제한 환경에서 실패한다.
echo "▶︎ Whisper 토크나이저 다운로드"
hf download openai/whisper-large-v3 tokenizer.json tokenizer_config.json \
    --local-dir "$DEST/whisperkit-coreml/$WHISPER_VARIANT"

echo "▶︎ SpeakerKit 모델 다운로드"
hf download argmaxinc/speakerkit-coreml \
    --local-dir "$DEST/speakerkit-coreml"

echo
echo "✅ 모델 동봉 준비 완료"
du -sh "$DEST/whisperkit-coreml" "$DEST/speakerkit-coreml" 2>/dev/null || true
echo
echo "다음: ./Scripts/build.sh 로 빌드하면 .app 번들에 모델이 함께 들어갑니다."
