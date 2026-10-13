// screen-progress.jsx — animated waveform + step pipeline

function ScreenProgress({ theme, fileName, onCancel }) {
  const t = theme;
  const [step, setStep] = React.useState(2); // 0..4
  const [progress, setProgress] = React.useState(0.42);
  const [tick, setTick] = React.useState(0);

  React.useEffect(() => {
    const id = setInterval(() => setTick((x) => x + 1), 80);
    return () => clearInterval(id);
  }, []);

  const steps = [
    { id: 0, label: '오디오 디코딩', sub: 'AVFoundation', icon: 'sound' },
    { id: 1, label: 'Whisper 모델 준비', sub: 'large-v3-turbo', icon: 'sparkle' },
    { id: 2, label: '한국어 전사', sub: '진행 중', icon: 'wave' },
    { id: 3, label: '화자 분리', sub: 'SpeakerKit', icon: 'users' },
    { id: 4, label: '회의록 생성', sub: 'Claude Code', icon: 'doc' },
  ];

  // generate 80 waveform bars
  const bars = React.useMemo(() =>
    Array.from({ length: 80 }, (_, i) => {
      const seed = Math.sin(i * 1.7) * 0.5 + Math.cos(i * 0.4) * 0.5;
      return 0.25 + Math.abs(seed) * 0.7 + Math.sin(i * 0.3) * 0.15;
    }), []);

  return (
    <div style={{
      flex: 1, height: '100%', overflow: 'auto',
      padding: '32px 48px',
      display: 'flex', flexDirection: 'column', gap: 28,
    }}>
      {/* Header */}
      <div>
        <div style={{
          fontSize: 11, fontWeight: 700, color: t.ink50,
          letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 6,
        }}>처리 중</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, flexWrap: 'nowrap' }}>
          <h2 style={{
            margin: 0, fontSize: 26, fontWeight: 600, letterSpacing: '-0.02em',
            color: t.ink, fontFamily: TOKENS.fontDisplay, whiteSpace: 'nowrap',
          }}>{steps[step].label}</h2>
          <span style={{ fontFamily: TOKENS.fontMono, fontSize: 12, color: t.ink50 }}>{fileName}</span>
        </div>
      </div>

      {/* Big waveform card */}
      <div style={{
        background: t.surface,
        border: `0.5px solid ${t.line}`,
        borderRadius: 18,
        padding: '24px 28px 20px',
        display: 'flex', flexDirection: 'column', gap: 16,
        position: 'relative', overflow: 'hidden',
      }}>
        {/* gradient sweep */}
        <div style={{
          position: 'absolute', top: 0, bottom: 0,
          left: `calc(${progress * 100}% - 80px)`, width: 160,
          background: `linear-gradient(90deg, transparent, ${t.accent}22, transparent)`,
          pointerEvents: 'none',
          transition: 'left 0.6s ease',
        }} />

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: t.gradient,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 2px 6px rgba(224,36,94,0.30)',
            }}>
              <Icon name={steps[step].icon} size={18} color="#fff" />
            </div>
            <div>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>
                {steps[step].label}
              </div>
              <div style={{ fontSize: 11.5, color: t.ink50 }}>{steps[step].sub}</div>
            </div>
          </div>
          <div style={{
            fontFamily: TOKENS.fontMono, fontSize: 26, fontWeight: 600,
            color: t.ink, letterSpacing: '-0.02em',
          }}>
            {Math.round(progress * 100)}<span style={{ fontSize: 14, color: t.ink50 }}>%</span>
          </div>
        </div>

        {/* waveform */}
        <div style={{
          height: 90,
          display: 'flex', alignItems: 'center', gap: 2,
          position: 'relative',
        }}>
          {bars.map((h, i) => {
            const idx = i / bars.length;
            const isPast = idx < progress;
            const isHead = Math.abs(idx - progress) < 0.02;
            const wobble = isHead ? 1 + Math.sin(tick * 0.4 + i) * 0.25 : 1;
            return (
              <div key={i} style={{
                flex: 1,
                height: `${h * 90 * wobble}px`,
                borderRadius: 2,
                background: isPast ? t.gradient : t.ink10,
                opacity: isHead ? 1 : (isPast ? 1 : 0.7),
                transition: isHead ? 'height 0.08s' : 'none',
              }} />
            );
          })}
        </div>

        {/* progress bar + time */}
        <div>
          <div style={{
            height: 4, borderRadius: 2,
            background: t.ink10, position: 'relative', overflow: 'hidden',
          }}>
            <div style={{
              position: 'absolute', inset: 0, width: `${progress * 100}%`,
              background: t.gradient, borderRadius: 2,
              transition: 'width 0.6s ease',
            }} />
          </div>
          <div style={{
            display: 'flex', justifyContent: 'space-between', marginTop: 8,
            fontFamily: TOKENS.fontMono, fontSize: 11, color: t.ink50,
          }}>
            <span>약 1분 남음 · 32:18 중 13:35 처리됨</span>
            <span>RTF 0.42×</span>
          </div>
        </div>
      </div>

      {/* Step pipeline */}
      <div>
        <div style={{
          fontSize: 11, fontWeight: 700, color: t.ink50,
          letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12,
        }}>파이프라인</div>
        <div style={{ display: 'flex', gap: 10 }}>
          {steps.map((s, i) => {
            const status = i < step ? 'done' : i === step ? 'active' : 'pending';
            return (
              <React.Fragment key={s.id}>
                <div style={{
                  flex: 1,
                  padding: '12px 14px',
                  borderRadius: 10,
                  background: status === 'active' ? t.gradientSoft : t.surface,
                  border: `0.5px solid ${status === 'active' ? 'transparent' : t.line}`,
                  display: 'flex', flexDirection: 'column', gap: 8,
                  position: 'relative',
                  opacity: status === 'pending' ? 0.55 : 1,
                }}>
                  <div style={{
                    width: 22, height: 22, borderRadius: '50%',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: status === 'done' ? t.success : status === 'active' ? t.gradient : t.ink10,
                    color: '#fff',
                  }}>
                    {status === 'done' && <Icon name="check" size={12} stroke={2.4} color="#fff" />}
                    {status === 'active' && <div style={{
                      width: 7, height: 7, borderRadius: '50%', background: '#fff',
                      animation: 'rupulse 1.2s ease-in-out infinite',
                    }} />}
                    {status === 'pending' && <div style={{ width: 6, height: 6, borderRadius: '50%', background: t.ink35 }} />}
                  </div>
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>{s.label}</div>
                    <div style={{ fontSize: 10.5, color: t.ink50, marginTop: 1 }}>{s.sub}</div>
                  </div>
                </div>
                {i < steps.length - 1 && (
                  <div style={{ display: 'flex', alignItems: 'center', color: t.ink20 }}>
                    <Icon name="arrowRight" size={12} />
                  </div>
                )}
              </React.Fragment>
            );
          })}
        </div>
      </div>

      {/* Live transcript stream */}
      <div style={{
        background: t.surface,
        border: `0.5px solid ${t.line}`,
        borderRadius: 14,
        padding: 18,
        flex: 1, minHeight: 140,
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: 10,
        }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: t.ink50, letterSpacing: '0.08em', textTransform: 'uppercase' }}>실시간 전사</div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            fontSize: 10.5, color: t.ink50,
          }}>
            <div style={{
              width: 6, height: 6, borderRadius: '50%', background: t.accent,
              animation: 'rupulse 1.2s ease-in-out infinite',
            }} />
            <span>스트리밍 중</span>
          </div>
        </div>
        <div style={{
          fontSize: 13.5, lineHeight: 1.7, color: t.ink, fontFamily: TOKENS.fontDisplay,
          letterSpacing: '-0.005em',
        }}>
          <span style={{ color: t.ink50 }}>… 그러면 5월 14일로 이틀 미루는 게 안전하겠네요. 다들 동의하시면 일정 14일로 확정하고 가시죠.</span>
          <span style={{ color: t.ink70 }}> 동의합니다. 마케팅 측 발표 자료도 그날 기준으로 다시 잡을게요. </span>
          <span style={{ color: t.ink }}>좋아요, 그러면 다음, 가격 정책. 정하늘님 진행해주세요</span>
          <span style={{
            display: 'inline-block', width: 2, height: 16, background: t.accent,
            verticalAlign: 'text-bottom', marginLeft: 2,
            animation: 'rublink 1s steps(2) infinite',
          }} />
        </div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
        <PillButton theme={t} ghost onClick={onCancel}>취소</PillButton>
      </div>

      <style>{`
        @keyframes rupulse { 0%,100% { transform: scale(1); opacity: 1; } 50% { transform: scale(0.6); opacity: 0.6; } }
        @keyframes rublink { 50% { opacity: 0; } }
      `}</style>
    </div>
  );
}

window.ScreenProgress = ScreenProgress;
