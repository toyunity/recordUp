// sidebar.jsx — left rail with library + nav

function Sidebar({ theme, library, selectedId, onSelect, onNew, onNav, currentNav, themeName }) {
  const t = theme;
  const navItems = [
  { id: 'drop', label: '새 회의록', icon: 'plus' },
  { id: 'library', label: '라이브러리', icon: 'folder' },
  { id: 'templates', label: '템플릿', icon: 'doc' },
  { id: 'settings', label: '설정', icon: 'gear' }];


  return (
    <div style={{
      width: 256, flexShrink: 0,
      background: themeName === 'dark' ? 'rgba(20,16,14,0.92)' : 'rgba(248,242,232,0.78)',
      backdropFilter: 'blur(40px) saturate(180%)',
      WebkitBackdropFilter: 'blur(40px) saturate(180%)',
      display: 'flex', flexDirection: 'column',
      fontFamily: TOKENS.fontUI,
      minHeight: 0
    }}>
      {/* Brand */}
      <div style={{
        padding: '12px 14px 10px',
        display: 'flex', alignItems: 'center', gap: 9
      }}>
        <BrandMark />
        <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <div style={{
            display: 'flex', alignItems: 'baseline', gap: 0,
            fontFamily: TOKENS.fontDisplay,
            lineHeight: 1.15,
            paddingBottom: 2
          }}>
            <span style={{
              fontSize: 14, fontWeight: 500,
              color: t.ink70, letterSpacing: '-0.02em'
            }}>record</span>
            <span style={{
              display: 'inline-block',
              width: 3, height: 3, borderRadius: '50%',
              background: 'linear-gradient(135deg, #FF6A3D 0%, #E0245E 100%)',
              margin: '0 3px 2px',
              alignSelf: 'center'
            }} />
            <span style={{
              fontSize: 16, fontWeight: 800, letterSpacing: '-0.04em',
              fontStyle: 'italic',
              background: 'linear-gradient(135deg, #FF6A3D 0%, #E0245E 100%)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
              display: 'inline-block',
              lineHeight: 1.3,
              paddingBottom: 4,
              paddingRight: 4,
              overflow: 'visible'
            }}>UP</span>
          </div>
          <div style={{
            fontSize: 9.5, color: t.ink50,
            letterSpacing: '0.16em', textTransform: 'uppercase',
            fontWeight: 600, marginTop: -3
          }}>온디바이스 회의록</div>
        </div>
      </div>

      {/* Top nav */}
      <div style={{ padding: '4px 8px 8px', display: 'flex', flexDirection: 'column', gap: 1 }}>
        {navItems.map((n) => {
          const active = currentNav === n.id || n.id === 'drop' && (currentNav === 'progress' || currentNav === 'transcript' || currentNav === 'minutes');
          return (
            <button key={n.id} onClick={() => onNav(n.id)} style={{
              border: 'none',
              background: active ? t.accentSoft : 'transparent',
              color: active ? t.accent : t.ink70,
              padding: '6px 10px',
              borderRadius: 7,
              display: 'flex', alignItems: 'center', gap: 9,
              fontSize: 12.5, fontWeight: active ? 600 : 500,
              fontFamily: 'inherit',
              cursor: 'pointer',
              textAlign: 'left',
              letterSpacing: '-0.005em'
            }}>
              <Icon name={n.icon} size={14} stroke={1.7} />
              <span>{n.label}</span>
            </button>);

        })}
      </div>

      {/* Library */}
      <div style={{ padding: '10px 14px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 10, fontWeight: 700, color: t.ink50, letterSpacing: '0.08em', textTransform: 'uppercase' }}>최근 회의록</div>
        <span style={{ fontSize: 10.5, color: t.ink35, fontFamily: TOKENS.fontMono }}>{library.length}</span>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', padding: '0 8px 10px', minHeight: 0 }}>
        {library.map((m) => {
          const active = m.id === selectedId;
          return (
            <button key={m.id} onClick={() => onSelect(m.id)} style={{
              width: '100%', textAlign: 'left',
              border: 'none',
              background: active ? t.surface : 'transparent',
              padding: '8px 10px',
              borderRadius: 8, marginBottom: 1,
              cursor: 'pointer',
              fontFamily: 'inherit',
              boxShadow: active ? `0 0 0 0.5px ${t.lineStrong}, 0 1px 2px rgba(0,0,0,0.04)` : 'none',
              display: 'flex', flexDirection: 'column', gap: 3
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                {m.pinned && <div style={{ width: 4, height: 4, borderRadius: '50%', background: t.accent }} />}
                <div style={{
                  fontSize: 12, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em',
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  flex: 1
                }}>{m.title}</div>
              </div>
              <div style={{
                fontSize: 10.5, color: t.ink50, display: 'flex', gap: 8, alignItems: 'center',
                fontFamily: TOKENS.fontMono
              }}>
                <span>{m.date.replace('2026년 ', '').replace('월 ', '/').replace('일', '')}</span>
                <span style={{ color: t.ink20 }}>·</span>
                <span>{m.duration}</span>
                <span style={{ color: t.ink20 }}>·</span>
                <span>{m.speakers}명</span>
              </div>
            </button>);

        })}
      </div>

      {/* Footer status */}
      <div style={{
        padding: '10px 14px',
        borderTop: `0.5px solid ${t.line}`,
        display: 'flex', alignItems: 'center', gap: 8,
        fontSize: 10.5, color: t.ink50
      }}>
        <div style={{
          width: 7, height: 7, borderRadius: '50%', background: t.success,
          boxShadow: `0 0 0 3px ${t.success}22`
        }} />
        <span>Claude Max · 온디바이스</span>
      </div>
    </div>);

}

function BrandMark() {
  return (
    <img src="assets/brand-icon.png" alt="record-up" width="36" height="36"
      style={{
        width: 36, height: 36, borderRadius: 9, display: 'block',
        flexShrink: 0,
        boxShadow: '0 1px 3px rgba(224,36,94,0.30)'
      }} />);

}

window.Sidebar = Sidebar;
window.BrandMark = BrandMark;