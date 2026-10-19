# Goal — Silero VAD 도입 (무음 구간 건너뛰기)

recordUp(macOS 앱)의 전사 단계에 Silero VAD를 넣는다.
무음 구간을 Whisper에 넣지 않아 환각 전사를 막고, 30초 분할 지점도 Silero 판정으로 고른다.
설계와 근거는 `docs/specs/silero-vad-design.html`에 있다. 이 파일은 실행 지시문이다.

## 0. 작업 환경

- 저장소: `https://github.com/toyunity/recordUp` (public). 로컬 경로는 `~/dev/recordUp`를 기준으로 한다.
  - 없으면 `git clone https://github.com/toyunity/recordUp ~/dev/recordUp`
  - 있으면 `git -C ~/dev/recordUp pull --ff-only`
- `~/dev/record-up`(하이픈, private)은 옛 저장소다. **절대 수정하지 않는다.**
- `main`에서 `feat/silero-vad` 브랜치를 만들어 작업한다.
- 빌드: `./Scripts/build.sh` (XcodeGen → xcodebuild). `recordup.xcodeproj/`는 직접 편집하지 않고 `project.yml`만 고친다.
- 모델은 `./Scripts/fetch-models.sh`로 받아 `Resources/models/`에 둔다. 앱은 번들 모델만 쓴다(`download: false`).

## 1. 지켜야 할 규칙 (CLAUDE.md 우선)

- **커밋·푸시 금지.** 사용자가 명시적으로 요청할 때만 한다. 요청하면 CLAUDE.md의 버전·릴리스 노트 질문을 먼저 한다.
- `.env*`, `*.pem` 같은 비밀 파일은 읽지 않는다. 모델 바이너리를 출력하지 않는다.
- `~/Documents/record-up/`, `~/Library/Application Support/recordup/`를 임의로 바꾸지 않는다.
- 네트워크가 Hugging Face를 막으면(403·프록시 거부) **우회하지 말고 멈춰서 보고**한다.
- 외부 라이브러리·모델의 라이선스, 버전, 입출력 형식은 공식 출처에서 확인하고 URL을 남긴다. 확인 못 한 것은 "미확인"으로 적는다.
- 측정하지 않은 수치를 결과로 쓰지 않는다.

## 2. 먼저 읽을 것

1. `docs/specs/silero-vad-design.html` 전문
2. `CLAUDE.md`, `project.yml`, `THIRD_PARTY_NOTICES.md`
3. `Sources/recordup/STT/Transcriber.swift`, `Sources/recordup/Pipeline/Diarizer.swift`, `Sources/recordup/AppPaths.swift`, `Sources/recordup/Sheets/SettingsView.swift`
4. `Scripts/fetch-models.sh`, `Scripts/package-pkg.sh`
5. 빌드 후 WhisperKit 소스(`.build/SourcePackages/checkouts/WhisperKit/Sources/WhisperKit/Core/Audio/`)
   - `VoiceActivityDetector.swift`, `EnergyVAD.swift`, `AudioChunker.swift`
   - `Core/WhisperKit.swift`에서 `voiceActivityDetector` 사용처, `Core/Configurations.swift`의 `clipTimestamps`

## 3. 단계

### M0 — 사전 검증 (앱 코드 변경 없음, 산출물은 scratch 폴더)

1. **모델 확보**
   - 1순위: Hugging Face `FluidInference/silero-vad-coreml`. 모델 카드에서 라이선스, Silero 버전(v5/v6), 파일 목록, 입출력 텐서 이름·형태를 확인한다.
   - 2순위: `snakers4/silero-vad`의 ONNX/PyTorch를 `coremltools`로 직접 변환한다(scratch의 Python venv).
2. **입출력 실측**: 작은 Swift 스크립트로 16kHz 오디오의 프레임별 음성 확률을 뽑는다.
   - 원본 Silero(Python `silero-vad` 패키지)가 돌면 같은 파일의 확률과 비교한다. 프레임별 차이 0.05 이하면 통과.
   - 1시간 오디오 처리 시간을 잰다. **목표 30초 이하.** 넘으면 원인(프레임당 호출 오버헤드 등)과 대안을 적는다.
3. **테스트 세트 만들기** (설계 문서 §6 참고)
   - T1 원본: 사용자에게 한국어 회의 샘플 경로를 묻는다. 없으면 `say -v Yuna`로 2인 대화를 합성한다.
   - T2 앞뒤 무음 30초, T3 중간 무음 10초×3 + 약한 소음, T4 −20dB 감쇠
4. **기준선 측정**: 현재 앱(EnergyVAD, `chunkingStrategy: .vad`)으로 T1~T4를 전사한다.
   - 기록: 환각 문장 수, 원본 대비 누락 문장 수, 전사 시간
   - 앱 UI 대신 같은 `DecodingOptions`를 쓰는 CLI 스크립트를 써도 된다.

**승인 지점 1** — 여기서 멈추고 아래를 보고한 뒤 사용자 답을 기다린다.
- 모델 출처·라이선스·버전, 입출력 형식, 처리 속도
- 통합 방식 추천: 자체 래퍼(설계 기본안) 또는 FluidAudio 패키지
- 기준선 측정표

### M1 — `SileroVAD` 구현

- 새 파일 `Sources/recordup/STT/SileroVAD.swift`: WhisperKit의 `VoiceActivityDetector`를 상속한다.
  - `frameLengthSamples = 512`(32ms). `voiceActivity(in:)`가 프레임별 `Bool`을 돌려준다.
  - 64샘플 컨텍스트와 LSTM 상태를 프레임 사이에 이어 준다. 호출마다 상태를 초기화한다.
  - 확률 → `Bool` 후처리: 임계값 0.5, 해제 임계값 0.35(히스테리시스), 최소 발화 250ms, 최소 무음 500ms, 앞뒤 여백 200ms. 값은 상수로 두고 M4 결과로 조정한다.
  - `selfCheck()`를 두고 App init의 DEBUG 블록에서 호출한다(기존 패턴과 같게). 후처리 로직만 검사하고 모델은 부르지 않는다.
- `Transcriber.warmUp`에서 `WhisperKitConfig(voiceActivityDetector:)`로 넘긴다.
- 모델 폴더가 없거나 로드에 실패하면 `EnergyVAD`로 떨어지고 `DebugLog`에 `[vad]`로 남긴다. 전사가 멈추면 안 된다.

### M2 — 무음 구간 건너뛰기

- `Transcriber.transcribe`에서 `calculateActiveChunks(in:)`로 음성 구간을 구해 `DecodingOptions.clipTimestamps`로 넘긴다.
- 확인할 것:
  - 결과 세그먼트의 시각이 **원본 오디오 기준 절대 시각**인지. 화자 분리(`addSpeakerInfo`) 정렬이 깨지지 않는지.
  - 음성 구간이 하나도 없을 때 빈 결과가 오류 없이 처리되고 사용자에게 "음성을 찾지 못했습니다"류 메시지가 나오는지.
  - VAD를 두 번(구간 계산 + 30초 분할) 돌리는 비용. 크면 결과를 캐시한다.

### M3 — 번들·설정·문서

- `Scripts/fetch-models.sh`에 VAD 모델 다운로드를 추가한다(`Resources/models/silero-vad-coreml/`).
- `AppPaths`에 `bundledVADFolder`를 추가한다. `project.yml`은 `Resources/models`를 이미 포함하는지 확인하고 필요할 때만 고친다.
- 설정 화면에 "무음 구간 건너뛰기" 토글을 추가한다. UserDefaults 키 `vadSkipSilence`, 기본값 켬. 끄면 M1의 분할 지점 개선만 남는다.
- 문서: `THIRD_PARTY_NOTICES.md`(Silero VAD MIT, 변환본 출처), `CLAUDE.md` 저장 위치 표, `docs/modules/stt.md`, `README.md` 특징 목록

### M4 — 검증

- T1~T4를 다시 측정해 M0 기준선과 나란히 표로 만든다.
- 통과 기준:
  - T2·T3 환각 문장 0건
  - T1·T4 누락 문장이 기준선보다 늘지 않음
  - T2·T3 전사 시간이 무음 비율만큼 줄어듦
  - `./Scripts/build.sh` 통과, `./Scripts/release.sh`로 만든 pkg 크기 증가 5MB 이하
- 기준을 못 넘으면 M1 후처리 값을 조정하고 다시 잰다. 두 번 조정해도 안 되면 멈추고 보고한다.

**승인 지점 2** — 측정표, 바뀐 파일 목록, 남은 위험을 보고하고 멈춘다. 커밋은 사용자 지시가 있을 때만 한다.

## 4. 최종 보고 형식

- 바뀐 파일 목록
- M0 기준선 vs M4 결과 표 (T1~T4 × 환각·누락·시간)
- 확정한 후처리 값과 근거
- 미확인 항목과 남은 위험
