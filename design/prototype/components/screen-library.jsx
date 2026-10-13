// screen-library.jsx — full library / history view

function ScreenLibrary({ theme, onOpen }) {
  const t = theme;
  const [filter, setFilter] = React.useState('all');
  const filters = [
    { id: 'all', label: '전체', count: FAKE_LIBRARY.length },
    { id: 'decision-action', label: '결정·액션', count: FAKE_LIBRARY.filter(m => m.template === 'decision-action').length },
    { id: 'default', label: '기본', count: FAKE_LIBRARY.filter(m => m.template === 'default').length },
    { id: 'customer-interview', label: '고객 인터뷰', count: FAKE_LIBRARY.filter(m => m.template === 'customer-interview').length },
    { id: 'pinned', label: '고정됨', count: FAKE_LIBRARY.filter(m => m.pinned).length },
  ];
  const filtered = FAKE_LIBRARY.filter(m => {
    if (filter === 'all') return true;
    if (filter === 'pinned') return m.pinned;
    return m.template === filter;
  });

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      {/* Header */}
      <div style={{
        flexShrink: 0,
        padding: '24px 32px 16px',
        borderBottom: `0.5px solid ${t.line}`,
      }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: t.ink50, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 4 }}>라이브러리</div>
            <h1 style={{
              margin: 0, fontSize: 28, fontWeight: 600, letterSpacing: '-0.02em',
              color: t.ink, fontFamily: TOKENS.fontDisplay,
            }}>이전 회의록 <span style={{ color: t.ink35, fontWeight: 500 }}>{FAKE_LIBRARY.length}</span></h1>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 12px', borderRadius: 8,
            background: t.surface, border: `0.5px solid ${t.line}`,
            fontSize: 12, color: t.ink50,
          }}>
            <Icon name="search" size={13} color={t.ink50} />
            <input placeholder="회의록 검색…" style={{
              border: 'none', outline: 'none', background: 'transparent',
              fontFamily: 'inherit', fontSize: 12, color: t.ink, width: 200,
            }} />
            <span style={{ fontFamily: TOKENS.fontMono, fontSize: 10, color: t.ink35 }}>⌘F</span>
          </div>
        </div>

        {/* Filter chips */}
        <div style={{ display: 'flex', gap: 6 }}>
          {filters.map((f) => {
            const active = filter === f.id;
            return (
              <button key={f.id} onClick={() => setFilter(f.id)} style={{
                padding: '5px 11px', borderRadius: 999,
                border: `0.5px solid ${active ? 'transparent' : t.line}`,
                background: active ? t.gradient : t.surface,
                color: active ? '#fff' : t.ink70,
                cursor: 'pointer', fontFamily: 'inherit',
                fontSize: 11.5, fontWeight: 500,
                display: 'inline-flex', alignItems: 'center', gap: 6,
                boxShadow: active ? '0 1px 3px rgba(224,36,94,0.25)' : 'none',
              }}>
                {f.label}
                <span style={{
                  fontSize: 10, fontFamily: TOKENS.fontMono,
                  opacity: active ? 0.85 : 0.55,
                }}>{f.count}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Body — table */}
      <div style={{ flex: 1, overflow: 'auto', padding: '8px 24px 24px' }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: '40px minmax(280px,2fr) 1fr 100px 90px 100px 60px',
          padding: '12px 12px',
          fontSize: 10.5, fontWeight: 600, color: t.ink50,
          letterSpacing: '0.04em', textTransform: 'uppercase',
          borderBottom: `0.5px solid ${t.line}`,
        }}>
          <span></span>
          <span>제목</span>
          <span>날짜</span>
          <span>길이</span>
          <span>화자</span>
          <span>결정/액션</span>
          <span></span>
        </div>
        {filtered.map((m, i) => (
          <LibraryRow key={m.id} m={m} theme={t} onOpen={() => onOpen(m.id)} alt={i % 2 === 1} />
        ))}
      </div>
    </div>
  );
}

function LibraryRow({ m, theme, onOpen, alt }) {
  const t = theme;
  const [hover, setHover] = React.useState(false);
  const tplLabel = {
    'default': '기본',
    'decision-action': '결정·액션',
    'customer-interview': '고객 인터뷰',
  }[m.template];
  const tplColor = {
    'default': t.ink50,
    'decision-action': t.decision,
    'customer-interview': t.action,
  }[m.template];
  return (
    <div onClick={onOpen}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
      style={{
        display: 'grid',
        gridTemplateColumns: '40px minmax(280px,2fr) 1fr 100px 90px 100px 60px',
        padding: '14px 12px',
        alignItems: 'center', gap: 0,
        background: hover ? t.surface : (alt ? t.surfaceMuted : 'transparent'),
        borderRadius: 8,
        cursor: 'pointer',
        marginBottom: 1,
      }}>
      <div>
        {m.pinned ? (
          <Icon name="star" size={12} color={t.accent} />
        ) : (
          <div style={{ width: 8, height: 8, borderRadius: 2, background: tplColor, opacity: 0.4 }} />
        )}
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em', marginBottom: 2,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.title}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: t.ink50, fontFamily: TOKENS.fontMono }}>
          <span style={{
            color: tplColor, fontWeight: 600, padding: '1px 6px',
            background: `${tplColor}14`, borderRadius: 4, fontFamily: TOKENS.fontUI,
            fontSize: 10, letterSpacing: '0.02em',
          }}>{tplLabel}</span>
          <span>{m.file}</span>
        </div>
      </div>
      <div style={{ fontSize: 12, color: t.ink70 }}>{m.date}</div>
      <div style={{ fontFamily: TOKENS.fontMono, fontSize: 12, color: t.ink70, fontVariantNumeric: 'tabular-nums' }}>{m.duration}</div>
      <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
        {Array.from({ length: Math.min(m.speakers, 4) }, (_, i) => (
          <div key={i} style={{
            width: 18, height: 18, borderRadius: '50%',
            background: SPEAKER_PALETTE[i % 4].color,
            color: '#fff', fontSize: 9, fontWeight: 700,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: '1.5px solid ' + (alt ? t.surfaceMuted : (hover ? t.surface : t.canvas)),
            marginLeft: i === 0 ? 0 : -6,
          }}>{SPEAKER_PALETTE[i % 4].short}</div>
        ))}
        {m.speakers > 4 && (
          <span style={{ fontSize: 10.5, color: t.ink50, marginLeft: 4 }}>+{m.speakers - 4}</span>
        )}
      </div>
      <div style={{ display: 'flex', gap: 6, fontSize: 11.5 }}>
        {m.decisions > 0 && <span style={{ color: t.decision, fontWeight: 600 }}>{m.decisions}</span>}
        {m.decisions > 0 && m.actions > 0 && <span style={{ color: t.ink20 }}>·</span>}
        {m.actions > 0 && <span style={{ color: t.action, fontWeight: 600 }}>{m.actions}</span>}
      </div>
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <button style={{
          width: 24, height: 24, borderRadius: 6,
          background: 'transparent', border: 'none', color: t.ink50,
          cursor: 'pointer', opacity: hover ? 1 : 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="more" size={14} />
        </button>
      </div>
    </div>
  );
}

window.ScreenLibrary = ScreenLibrary;
