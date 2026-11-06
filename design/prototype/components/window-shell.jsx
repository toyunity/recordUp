// window-shell.jsx — macOS window chrome with traffic lights, titlebar, content area

const TrafficLights = ({ onClose }) => {
  const dot = (bg, key) =>
  <div key={key} style={{
    width: 12, height: 12, borderRadius: '50%', background: bg,
    border: '0.5px solid rgba(0,0,0,0.18)'
  }} />;

  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      {dot('#ff5f57', 'r')}
      {dot('#febc2e', 'y')}
      {dot('#28c840', 'g')}
    </div>);

};

function WindowShell({ theme, sidebar, toolbar, children, statusbar }) {
  const t = theme;
  return (
    <div style={{
      width: 1280,
      height: 820,
      borderRadius: 14,
      overflow: 'hidden',
      background: t.canvas,
      color: t.ink,
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.25), 0 30px 80px rgba(0,0,0,0.35), 0 8px 24px rgba(0,0,0,0.18)',
      display: 'flex',
      flexDirection: 'column',
      fontFamily: TOKENS.fontUI,
      position: 'relative'
    }}>
      {/* titlebar */}
      <div style={{
        height: 40,
        flexShrink: 0,
        display: 'flex',
        alignItems: 'center',
        padding: '0 14px',
        background: t.canvas,
        borderBottom: `0.5px solid ${t.line}`,
        position: 'relative',
        zIndex: 2
      }}>
        <TrafficLights />
        <div style={{ flex: 1, display: 'flex', justifyContent: 'center' }}>
          <div style={{
            fontSize: 12.5, fontWeight: 600, color: t.ink70,
            letterSpacing: '-0.005em'
          }}>
          <div style={{
              fontSize: 13, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em',
              display: 'flex', alignItems: 'baseline', gap: 0
            }}>
            <span style={{ color: t.ink50, fontWeight: 500 }}>record</span>
            <span style={{
                display: 'inline-block', width: 2.5, height: 2.5, borderRadius: '50%',
                background: 'linear-gradient(135deg, #FF6A3D 0%, #E0245E 100%)',
                margin: '0 2px 1px', alignSelf: 'center'
              }} />
            <span style={{
                fontWeight: 800, fontStyle: 'italic', letterSpacing: '-0.03em',
                background: 'linear-gradient(135deg, #FF6A3D 0%, #E0245E 100%)',
                WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
                display: 'inline-block', paddingRight: 3, paddingBottom: 2, lineHeight: 1.3
              }}>UP</span>
          </div>
          </div>
        </div>
        {/* keep right side balanced */}
        <div style={{ width: 52 }} />
      </div>

      {/* main row: sidebar + content */}
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {sidebar}
        <div style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          minWidth: 0,
          background: t.canvas,
          borderLeft: `0.5px solid ${t.line}`
        }}>
          {toolbar}
          <div style={{ flex: 1, minHeight: 0, overflow: 'hidden', position: 'relative' }}>
            {children}
          </div>
          {statusbar}
        </div>
      </div>
    </div>);

}

// Subtle pill button used everywhere
function PillButton({ children, onClick, primary, ghost, danger, theme, size = 'md', icon, style = {}, title }) {
  const t = theme;
  const heights = { sm: 26, md: 30, lg: 36 };
  const fontSizes = { sm: 11.5, md: 12.5, lg: 13 };
  const padX = { sm: 10, md: 12, lg: 16 };
  const h = heights[size];

  let bg, fg, border;
  if (primary) {
    bg = 'linear-gradient(135deg, #F43F6E 0%, #E0245E 60%, #C81D5A 100%)';
    fg = '#fff';
    border = 'transparent';
  } else if (danger) {
    bg = 'transparent';
    fg = t.accent2;
    border = t.lineStrong;
  } else if (ghost) {
    bg = 'transparent';
    fg = t.ink70;
    border = 'transparent';
  } else {
    bg = t.surface;
    fg = t.ink;
    border = t.lineStrong;
  }
  return (
    <button onClick={onClick} title={title} style={{
      height: h, padding: `0 ${padX[size]}px`,
      borderRadius: primary ? 8 : h / 2,
      background: bg, color: fg,
      border: `0.5px solid ${border}`,
      fontFamily: 'inherit', fontSize: fontSizes[size], fontWeight: primary ? 600 : 500,
      letterSpacing: '-0.005em',
      display: 'inline-flex', alignItems: 'center', gap: 6,
      cursor: 'pointer',
      whiteSpace: 'nowrap',
      transition: 'transform 0.08s ease, opacity 0.15s ease',
      boxShadow: primary ? '0 2px 6px rgba(224,36,94,0.40), inset 0 1px 0 rgba(255,255,255,0.28)' : 'none',
      ...style
    }}
    onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.98)'}
    onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}>
      
      {icon && <Icon name={icon} size={size === 'sm' ? 12 : 14} />}
      {children}
    </button>);

}

// Toolbar shell: title (left) + actions (right)
function Toolbar({ theme, title, subtitle, breadcrumb, right }) {
  const t = theme;
  return (
    <div style={{
      height: 52, flexShrink: 0,
      display: 'flex', alignItems: 'center',
      padding: '0 16px',
      borderBottom: `0.5px solid ${t.line}`,
      background: t.canvas,
      gap: 10
    }}>
      <div style={{ minWidth: 0, flex: 1, overflow: 'hidden' }}>
        {breadcrumb &&
        <div style={{ fontSize: 11, color: t.ink50, marginBottom: 2, letterSpacing: '-0.005em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{breadcrumb}</div>
        }
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, minWidth: 0 }}>
          <div style={{ fontSize: 14.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.01em', whiteSpace: 'nowrap', flexShrink: 0 }}>{title}</div>
          {subtitle && <div style={{ fontSize: 12, color: t.ink50, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', minWidth: 0 }}>{subtitle}</div>}
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexShrink: 0 }}>{right}</div>
    </div>);

}

window.WindowShell = WindowShell;
window.PillButton = PillButton;
window.Toolbar = Toolbar;