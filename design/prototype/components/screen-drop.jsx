// screen-drop.jsx — start screen with drop zone

function ScreenDrop({ theme, onStart, onPickFile, isTargeted, setTargeted }) {
  const t = theme;
  const [hovering, setHovering] = React.useState(false);

  return (
    <div style={{
      flex: 1, height: '100%',
      display: 'flex', flexDirection: 'column',
      padding: '32px 48px',
      overflow: 'auto',
      gap: 28
    }}>
      {/* Hero */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{
          fontSize: 11, fontWeight: 700, color: t.ink50,
          letterSpacing: '0.08em', textTransform: 'uppercase'
        }}>
          새 회의록
        </div>
        <h1 style={{
          margin: 0,
          fontSize: 32, fontWeight: 600, letterSpacing: '-0.02em',
          color: t.ink, fontFamily: TOKENS.fontDisplay
        }}>
          음성 메모를 떨어뜨리세요.
        </h1>
        <p style={{
          margin: 0, color: t.ink70, maxWidth: 540, lineHeight: 1.5, width: "560px", fontSize: "12px"
        }}>
          한국어 전사·화자 분리·회의록 생성까지 모두 이 Mac에서 처리됩니다.
          파일은 외부로 전송되지 않아요.
        </p>
      </div>

      {/* Drop zone */}
      <div
        onDragEnter={() => setTargeted(true)}
        onDragLeave={() => setTargeted(false)}
        onDragOver={(e) => {e.preventDefault();setTargeted(true);}}
        onDrop={(e) => {e.preventDefault();setTargeted(false);onPickFile();}}
        onClick={onPickFile}
        onMouseEnter={() => setHovering(true)}
        onMouseLeave={() => setHovering(false)}
        style={{
          height: 280,
          borderRadius: 18,
          border: `1.5px dashed ${isTargeted ? t.accent : t.lineStrong}`,
          background: isTargeted ?
          t.gradientSoft :
          hovering ? t.surfaceMuted : t.surface,
          display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center',
          gap: 14, cursor: 'pointer',
          transition: 'all 0.18s ease',
          position: 'relative', overflow: 'hidden'
        }}>
        
        {/* decorative waves */}
        <svg width="100%" height="100%" viewBox="0 0 1000 280" preserveAspectRatio="none"
        style={{ position: 'absolute', inset: 0, opacity: isTargeted ? 0.6 : 0.28, transition: 'opacity 0.2s' }}>
          <defs>
            <style>{`
              @keyframes pebbleWave0 { 0%,100% { transform: translateX(0) } 50% { transform: translateX(-40px) } }
              @keyframes pebbleWave1 { 0%,100% { transform: translateX(0) } 50% { transform: translateX(50px) } }
              @keyframes pebbleWave2 { 0%,100% { transform: translateX(0) } 50% { transform: translateX(-30px) } }
              @keyframes pebbleWave3 { 0%,100% { transform: translateX(0) } 50% { transform: translateX(35px) } }
              .pw0 { animation: pebbleWave0 7.2s ease-in-out infinite }
              .pw1 { animation: pebbleWave1 9.4s ease-in-out infinite }
              .pw2 { animation: pebbleWave2 6.1s ease-in-out infinite }
              .pw3 { animation: pebbleWave3 11s ease-in-out infinite }
            `}</style>
          </defs>
          {[0, 1, 2, 3].map((i) =>
          <path key={i} className={`pw${i}`}
          d={`M-100 ${140 + Math.sin(i) * 30} Q 250 ${100 + i * 18} 500 ${140 + Math.cos(i) * 25} T 1100 ${140 + Math.sin(i + 1) * 30}`}
          stroke={t.accent} strokeWidth={1.2 - i * 0.15} fill="none" opacity={0.7 - i * 0.15}>
              <animate attributeName="d" dur={`${8 + i * 1.4}s`} repeatCount="indefinite"
                values={[
                  `M-100 ${140 + Math.sin(i) * 30} Q 250 ${100 + i * 18} 500 ${140 + Math.cos(i) * 25} T 1100 ${140 + Math.sin(i + 1) * 30}`,
                  `M-100 ${140 + Math.sin(i + 1.5) * 30} Q 250 ${160 - i * 14} 500 ${140 + Math.cos(i + 1.5) * 28} T 1100 ${140 + Math.sin(i + 2.5) * 30}`,
                  `M-100 ${140 + Math.sin(i + 3) * 30} Q 250 ${110 + i * 12} 500 ${140 + Math.cos(i + 3) * 22} T 1100 ${140 + Math.sin(i + 4) * 30}`,
                  `M-100 ${140 + Math.sin(i) * 30} Q 250 ${100 + i * 18} 500 ${140 + Math.cos(i) * 25} T 1100 ${140 + Math.sin(i + 1) * 30}`
                ].join(';')} />
            </path>
          )}
        </svg>

        <div style={{
          width: 64, height: 64, borderRadius: 16,
          background: t.gradient,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 6px 16px rgba(224,36,94,0.30), inset 0 1px 0 rgba(255,255,255,0.35)',
          position: 'relative',
          transform: isTargeted ? 'scale(1.06)' : 'scale(1)',
          transition: 'transform 0.18s ease'
        }}>
          <Icon name="mic" size={28} color="#fff" stroke={1.8} />
        </div>
        <div style={{ position: 'relative', textAlign: 'center' }}>
          <div style={{ fontSize: 16, fontWeight: 600, color: t.ink, letterSpacing: '-0.01em' }}>
            {isTargeted ? '여기에 놓으세요' : '음성 메모를 끌어다 놓으세요'}
          </div>
          <div style={{ fontSize: 12.5, color: t.ink50, marginTop: 4 }}>
            또는 <span style={{ color: t.accent, fontWeight: 600 }}>클릭해서 파일 선택</span>
          </div>
        </div>

        <div style={{
          position: 'absolute', bottom: 14, left: 14,
          fontFamily: TOKENS.fontMono, fontSize: 10, color: t.ink35,
          letterSpacing: '0.04em'
        }}>
          음성 메모 · .m4a · .mp3 · .wav · .aac
        </div>
        <div style={{
          position: 'absolute', bottom: 14, right: 14,
          display: 'flex', alignItems: 'center', gap: 6,
          fontSize: 10.5, color: t.ink50
        }}>
          <Icon name="lightning" size={11} />
          <span>WhisperKit · large-v3-turbo</span>
        </div>
      </div>

      {/* Quick actions */}
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12
      }}>
        <QuickCard theme={t} icon="folder" label="음성 메모 앱에서 불러오기" sub="iCloud Voice Memos" />
        <QuickCard theme={t} icon="globe" label="URL에서 가져오기" sub="Google Meet · Zoom 녹음" badge="v2" />
        <QuickCard theme={t} icon="sound" label="이 Mac에서 직접 녹음" sub="시스템 오디오 + 마이크" badge="v2" />
      </div>

      {/* Recent strip */}
      <div>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12
        }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: t.ink50,
            letterSpacing: '0.08em', textTransform: 'uppercase'
          }}>이어서 작업하기</div>
          <span style={{ fontSize: 11.5, color: t.accent, fontWeight: 500, cursor: 'pointer' }}>전체 보기 →</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {FAKE_LIBRARY.slice(0, 2).map((m) => <RecentCard key={m.id} m={m} theme={t} onOpen={onStart} />)}
        </div>
      </div>
    </div>);

}

function QuickCard({ theme, icon, label, sub, badge }) {
  const t = theme;
  return (
    <div style={{
      background: t.surface,
      border: `0.5px solid ${t.line}`,
      borderRadius: 12,
      padding: 14,
      display: 'flex', flexDirection: 'column', gap: 6,
      cursor: 'pointer',
      position: 'relative',
      opacity: badge ? 0.6 : 1
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: 8,
        background: t.surfaceMuted,
        border: `0.5px solid ${t.line}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: t.ink70
      }}>
        <Icon name={icon} size={15} />
      </div>
      <div style={{ fontSize: 12.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>{label}</div>
      <div style={{ fontSize: 11, color: t.ink50 }}>{sub}</div>
      {badge &&
      <div style={{
        position: 'absolute', top: 12, right: 12,
        fontSize: 9.5, fontWeight: 600, color: t.ink50,
        background: t.surfaceMuted, padding: '2px 6px', borderRadius: 4,
        border: `0.5px solid ${t.line}`, letterSpacing: '0.04em', textTransform: 'uppercase'
      }}>{badge}</div>
      }
    </div>);

}

function RecentCard({ m, theme, onOpen }) {
  const t = theme;
  return (
    <div onClick={() => onOpen(m.id)} style={{
      background: t.surface,
      border: `0.5px solid ${t.line}`,
      borderRadius: 12,
      padding: 14,
      display: 'flex', flexDirection: 'column', gap: 8,
      cursor: 'pointer'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 8 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em',
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{m.title}</div>
        <div style={{ fontFamily: TOKENS.fontMono, fontSize: 10.5, color: t.ink50, flexShrink: 0 }}>{m.duration}</div>
      </div>
      <div style={{ display: 'flex', gap: 12, fontSize: 11, color: t.ink50 }}>
        <span>{m.date.replace('2026년 ', '')}</span>
        <span style={{ color: t.ink20 }}>·</span>
        <span>화자 {m.speakers}명</span>
        {m.decisions > 0 &&
        <>
            <span style={{ color: t.ink20 }}>·</span>
            <span style={{ color: t.decision, fontWeight: 600 }}>결정 {m.decisions}</span>
          </>
        }
        {m.actions > 0 &&
        <>
            <span style={{ color: t.ink20 }}>·</span>
            <span style={{ color: t.action, fontWeight: 600 }}>액션 {m.actions}</span>
          </>
        }
      </div>
    </div>);

}

window.ScreenDrop = ScreenDrop;