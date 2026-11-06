// screen-minutes.jsx — minutes review with split markdown / preview, exports

function ScreenMinutes({ theme, onNew }) {
  const t = theme;
  const [mode, setMode] = React.useState('split'); // split | edit | preview
  const [text, setText] = React.useState(FAKE_MINUTES);
  const [showExport, setShowExport] = React.useState(false);
  const [showRegen, setShowRegen] = React.useState(false);
  const [saved, setSaved] = React.useState(true);

  const stats = React.useMemo(() => {
    const decisions = (text.match(/\n## 결정 사항/i) ? text.split('## 결정 사항')[1].split('##')[0] : '').match(/^\d+\./gm)?.length || 0;
    const actions = (text.match(/^- \[ \]/gm) || []).length;
    const words = text.length;
    return { decisions, actions, words };
  }, [text]);

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      {/* Toolbar — match transcript screen */}
      <div style={{
        flexShrink: 0,
        display: 'flex', alignItems: 'center', gap: 14,
        padding: '14px 24px',
        borderBottom: `0.5px solid ${t.line}`
      }}>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{
            display: 'flex', alignItems: 'baseline', gap: 12,
            minWidth: 0,
          }}>
            <div style={{
              fontSize: 16, fontWeight: 600, color: t.ink, letterSpacing: '-0.012em',
              fontFamily: TOKENS.fontDisplay,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
              flexShrink: 1, minWidth: 0,
            }}>
              제품팀 주간 스탠드업 — 5월 첫째 주
            </div>
            <div style={{
              fontSize: 11, color: t.ink50,
              display: 'flex', alignItems: 'baseline', gap: 8,
              fontFamily: TOKENS.fontMono,
              whiteSpace: 'nowrap', flexShrink: 0,
            }}>
              <span>2026년 5월 4일 생성</span>
              <span style={{ color: t.ink20 }}>·</span>
              <span>참석자 4명</span>
              <span style={{ color: t.ink20 }}>·</span>
              <span>{text.split('\n').length}줄</span>
            </div>
          </div>
        </div>

        {/* Mode segmented control */}
        <div style={{
          display: 'flex', padding: 2, borderRadius: 8,
          background: t.surfaceMuted, border: `0.5px solid ${t.line}`
        }}>
          {[
          { id: 'edit', label: '편집', icon: 'pencil' },
          { id: 'split', label: '나란히', icon: 'sidebar' },
          { id: 'preview', label: '미리보기', icon: 'eye' }].
          map((m) =>
          <button key={m.id} onClick={() => setMode(m.id)} style={{
            padding: '4px 10px', borderRadius: 6,
            border: 'none', cursor: 'pointer',
            background: mode === m.id ? t.surface : 'transparent',
            color: mode === m.id ? t.ink : t.ink50,
            fontFamily: 'inherit', fontSize: 11.5, fontWeight: 500,
            boxShadow: mode === m.id ? `0 0 0 0.5px ${t.lineStrong}, 0 1px 2px rgba(0,0,0,0.04)` : 'none',
            display: 'inline-flex', alignItems: 'center', gap: 5
          }}>
              <Icon name={m.icon} size={11} />
              {m.label}
            </button>
          )}
        </div>

        <PillButton theme={t} ghost size="sm" icon="refresh" onClick={() => setShowRegen(true)}>다시 생성</PillButton>
        <div style={{ position: 'relative' }}>
          <PillButton theme={t} primary size="sm" icon="export" onClick={() => setShowExport((v) => !v)}>내보내기</PillButton>
          {showExport && <ExportMenu theme={t} onClose={() => setShowExport(false)} />}
        </div>
      </div>

      {/* Template info strip */}
      <div style={{
        flexShrink: 0, padding: '8px 24px',
        display: 'flex', gap: 12, alignItems: 'center',
        borderBottom: `0.5px solid ${t.line}`, background: t.surfaceMuted,
        fontSize: 11.5, color: t.ink50
      }}>
        <Icon name="sparkle" size={12} color={t.accent} />
        <span>Claude Code · <b style={{ color: t.ink70, fontWeight: 600 }}>결정·액션 추출</b> 템플릿으로 생성됨</span>
        <span style={{ color: t.ink20 }}>·</span>
        <span style={{ fontFamily: TOKENS.fontMono }}>32:18 회의</span>
      </div>

      {/* Body — split */}
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {(mode === 'edit' || mode === 'split') &&
        <div style={{
          flex: 1, minWidth: 0,
          borderRight: mode === 'split' ? `0.5px solid ${t.line}` : 'none',
          display: 'flex', flexDirection: 'column', minHeight: 0
        }}>
            <div style={{
            flexShrink: 0, padding: '8px 18px',
            fontFamily: TOKENS.fontMono, fontSize: 10.5, color: t.ink50,
            letterSpacing: '0.04em', textTransform: 'uppercase',
            display: 'flex', alignItems: 'center', gap: 8
          }}>
              <Icon name="mdLogo" size={12} />
              <span>마크다운</span>
              <span style={{ color: t.ink20, marginLeft: 'auto' }}>{text.split('\n').length}줄</span>
            </div>
            <textarea
            value={text}
            onChange={(e) => {setText(e.target.value);setSaved(false);setTimeout(() => setSaved(true), 600);}}
            spellCheck={false}
            style={{
              flex: 1, minHeight: 0, width: '100%',
              resize: 'none', border: 'none', outline: 'none',
              background: t.canvas, color: t.ink70,
              padding: '12px 18px',
              fontFamily: TOKENS.fontMono, fontSize: 12.5, lineHeight: 1.7,
              boxSizing: 'border-box'
            }} />
          
          </div>
        }
        {(mode === 'preview' || mode === 'split') &&
        <div style={{ flex: 1, minWidth: 0, overflow: 'auto', padding: '20px 28px 40px', background: t.canvas }}>
            <MinutesPreview theme={t} text={text} />
          </div>
        }
      </div>

      {/* Footer */}
      <div style={{
        flexShrink: 0, padding: '10px 24px',
        borderTop: `0.5px solid ${t.line}`,
        display: 'flex', alignItems: 'center', gap: 12,
        background: t.surface,
        fontSize: 11.5, color: t.ink50
      }}>
        <Icon name="folder" size={12} />
        <span style={{ fontFamily: TOKENS.fontMono }}>~/Documents/record-up/minutes/2026-05-04 제품팀 스탠드업.md</span>
        <div style={{ flex: 1 }} />
        <PillButton theme={t} ghost size="sm" icon="copy">복사</PillButton>
        <PillButton theme={t} ghost size="sm" icon="folder">Finder에서 보기</PillButton>
        <PillButton theme={t} size="sm" onClick={onNew} icon="plus">새 회의록</PillButton>
      </div>

      {showRegen && <RegenSheet theme={t} onClose={() => setShowRegen(false)} />}
    </div>);

}

function Divider({ t }) {
  return <div style={{ width: 1, height: 18, background: t.line }} />;
}

function SmallStat({ theme, icon, color, label, value }) {
  const t = theme;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <div style={{
        width: 22, height: 22, borderRadius: 6,
        background: color === t.ink70 ? t.surface : `${color}1A`,
        display: 'flex', alignItems: 'center', justifyContent: 'center'
      }}>
        <Icon name={icon} size={12} color={color} stroke={2} />
      </div>
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        <div style={{ fontSize: 10.5, color: t.ink50, lineHeight: 1.2 }}>{label}</div>
        <div style={{ fontSize: 13, fontWeight: 600, color: t.ink, lineHeight: 1.2, letterSpacing: '-0.005em' }}>{value}</div>
      </div>
    </div>);

}

// Markdown preview — bespoke renderer optimized for meeting-notes shape
function MinutesPreview({ theme, text }) {
  const t = theme;
  const lines = text.split('\n');
  const rendered = [];
  let i = 0;
  let section = null;

  while (i < lines.length) {
    const line = lines[i];

    if (line.startsWith('# ')) {
      rendered.push(<h1 key={i} style={{
        fontSize: 26, fontWeight: 600, letterSpacing: '-0.02em',
        color: t.ink, fontFamily: TOKENS.fontDisplay, margin: '0 0 14px'
      }}>{line.slice(2)}</h1>);
    } else if (line.startsWith('## ')) {
      const heading = line.slice(3);
      section = heading;
      const isDecision = heading.includes('결정');
      const isAction = heading.includes('액션');
      const accent = isDecision ? t.decision : isAction ? t.action : null;
      rendered.push(
        <div key={i} style={{
          display: 'flex', alignItems: 'center', gap: 10,
          margin: '24px 0 10px'
        }}>
          {accent && <div style={{
            width: 4, height: 18, borderRadius: 2, background: accent
          }} />}
          <h2 style={{
            margin: 0, fontSize: 17, fontWeight: 600, letterSpacing: '-0.01em',
            color: t.ink, fontFamily: TOKENS.fontDisplay
          }}>{heading}</h2>
        </div>
      );
    } else if (line.startsWith('### ')) {
      rendered.push(
        <h3 key={i} style={{
          fontSize: 13.5, fontWeight: 600, letterSpacing: '-0.005em',
          color: t.ink70, margin: '16px 0 6px', fontFamily: TOKENS.fontDisplay
        }}>{line.slice(4)}</h3>
      );
    } else if (line.startsWith('---')) {
      rendered.push(<div key={i} style={{
        height: 1, background: t.line, margin: '14px 0 6px'
      }} />);
    } else if (line.startsWith('- [ ]') || line.startsWith('- [x]')) {
      const checked = line.startsWith('- [x]');
      const content = line.slice(5).trim();
      rendered.push(<ActionItem key={i} theme={t} content={content} checked={checked} />);
    } else if (/^\d+\.\s/.test(line)) {
      const content = line.replace(/^\d+\.\s/, '');
      const num = parseInt(line);
      rendered.push(<DecisionItem key={i} theme={t} content={content} num={num} accent={section?.includes('결정')} />);
    } else if (line.startsWith('- ')) {
      rendered.push(
        <div key={i} style={{
          display: 'flex', gap: 8, fontSize: 13.5, lineHeight: 1.65, color: t.ink70,
          marginLeft: 4, marginBottom: 2
        }}>
          <span style={{ color: t.ink35, marginTop: 0 }}>•</span>
          <span>{renderInline(line.slice(2), t)}</span>
        </div>
      );
    } else if (line.startsWith('**') && line.endsWith('**') === false && line.includes('**')) {
      // metadata line like "**일시** ..."
      rendered.push(<MetaLine key={i} theme={t} line={line} />);
    } else if (line.trim() === '') {
      rendered.push(<div key={i} style={{ height: 8 }} />);
    } else {
      rendered.push(
        <p key={i} style={{
          margin: '0 0 8px', fontSize: 13.5, lineHeight: 1.65, color: t.ink70,
          letterSpacing: '-0.005em', fontFamily: TOKENS.fontDisplay
        }}>{renderInline(line, t)}</p>
      );
    }
    i++;
  }

  return <div style={{ maxWidth: 720, margin: '0 auto' }}>{rendered}</div>;
}

function renderInline(text, t) {
  // bold **text**
  const parts = [];
  let last = 0;
  const re = /\*\*([^*]+)\*\*/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) parts.push(text.slice(last, m.index));
    parts.push(<b key={m.index} style={{ color: t.ink, fontWeight: 600 }}>{m[1]}</b>);
    last = m.index + m[0].length;
  }
  if (last < text.length) parts.push(text.slice(last));
  return parts;
}

function ActionItem({ theme, content, checked }) {
  const t = theme;
  const [c, setC] = React.useState(checked);
  // parse: **name** — body (~date)
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 10,
      padding: '8px 10px', marginBottom: 4,
      borderRadius: 8,
      background: c ? 'transparent' : t.surface,
      border: c ? '0.5px solid transparent' : `0.5px solid ${t.line}`,
      transition: 'background 0.15s'
    }}>
      <button onClick={() => setC(!c)} style={{
        marginTop: 2,
        width: 16, height: 16, borderRadius: 4,
        background: c ? t.action : 'transparent',
        border: `1.4px solid ${c ? t.action : t.lineStrong}`,
        cursor: 'pointer', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center'
      }}>
        {c && <Icon name="check" size={10} color="#fff" stroke={2.6} />}
      </button>
      <div style={{
        fontSize: 13.5, lineHeight: 1.55, color: c ? t.ink50 : t.ink,
        textDecoration: c ? 'line-through' : 'none',
        letterSpacing: '-0.005em', flex: 1, fontFamily: TOKENS.fontDisplay
      }}>{renderInline(content, t)}</div>
    </div>);

}

function DecisionItem({ theme, content, num, accent }) {
  const t = theme;
  if (!accent) return (
    <div style={{ display: 'flex', gap: 10, marginBottom: 6, fontSize: 13.5, lineHeight: 1.6, color: t.ink70 }}>
      <span style={{ color: t.ink35, fontFamily: TOKENS.fontMono, fontVariantNumeric: 'tabular-nums' }}>{num}.</span>
      <span>{renderInline(content, t)}</span>
    </div>);

  return (
    <div style={{
      display: 'flex', gap: 12, padding: '12px 14px',
      marginBottom: 6, borderRadius: 10,
      background: t.surface,
      border: `0.5px solid ${t.line}`,
      borderLeft: `3px solid ${t.decision}`
    }}>
      <div style={{
        width: 22, height: 22, borderRadius: '50%',
        background: t.decision, color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 11, fontWeight: 700, flexShrink: 0,
        fontFamily: TOKENS.fontMono
      }}>{num}</div>
      <div style={{
        fontSize: 13.5, lineHeight: 1.55, color: t.ink,
        letterSpacing: '-0.005em', flex: 1, fontFamily: TOKENS.fontDisplay
      }}>{renderInline(content, t)}</div>
    </div>);

}

function MetaLine({ theme, line }) {
  const t = theme;
  // **label** rest
  const m = line.match(/^\*\*([^*]+)\*\*\s*(.*)$/);
  if (!m) return null;
  return (
    <div style={{ display: 'flex', gap: 12, fontSize: 12, marginBottom: 4 }}>
      <span style={{ color: t.ink50, minWidth: 60, fontWeight: 500 }}>{m[1]}</span>
      <span style={{ color: t.ink70 }}>{m[2]}</span>
    </div>);

}

function ExportMenu({ theme, onClose }) {
  const t = theme;
  const items = [
  { icon: 'mdLogo', label: 'Markdown 파일', sub: '.md', shortcut: '⌘S' },
  { icon: 'doc', label: 'PDF 문서', sub: '.pdf' },
  { icon: 'doc', label: 'Word 문서', sub: '.docx' },
  null,
  { icon: 'copy', label: '클립보드에 복사', shortcut: '⌘C' },
  { icon: 'share', label: '공유…', shortcut: '⌘⇧S' },
  null,
  { icon: 'link', label: 'Notion에 보내기', sub: 'beta' },
  { icon: 'link', label: 'Slack DM으로 공유', sub: 'beta' }];

  return (
    <>
      <div onClick={onClose} style={{
        position: 'fixed', inset: 0, zIndex: 50
      }} />
      <div style={{
        position: 'absolute', top: 36, right: 0, zIndex: 51,
        background: t.surface,
        border: `0.5px solid ${t.lineStrong}`,
        borderRadius: 12, padding: 6, minWidth: 240,
        boxShadow: '0 12px 30px rgba(0,0,0,0.18), 0 1px 0 rgba(255,255,255,0.5) inset'
      }}>
        {items.map((it, i) => it === null ?
        <div key={i} style={{ height: 1, background: t.line, margin: '4px 6px' }} /> :

        <button key={i} onClick={onClose} style={{
          width: '100%', display: 'flex', alignItems: 'center', gap: 10,
          padding: '7px 10px', borderRadius: 7,
          border: 'none', background: 'transparent',
          cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
          color: t.ink, fontSize: 12.5
        }}
        onMouseEnter={(e) => e.currentTarget.style.background = t.surfaceMuted}
        onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}>
          
            <Icon name={it.icon} size={14} color={t.ink70} />
            <span style={{ flex: 1 }}>{it.label}</span>
            {it.sub && <span style={{ fontSize: 10, color: t.ink50, fontFamily: TOKENS.fontMono }}>{it.sub}</span>}
            {it.shortcut && <span style={{ fontSize: 10, color: t.ink35, fontFamily: TOKENS.fontMono, marginLeft: 6 }}>{it.shortcut}</span>}
          </button>
        )}
      </div>
    </>);

}

function RegenSheet({ theme, onClose }) {
  const t = theme;
  const [tpl, setTpl] = React.useState('decision-action');
  const [hint, setHint] = React.useState('');
  const tpls = [
  { id: 'default', name: '기본 회의록', sub: '요약·논의·다음 단계' },
  { id: 'decision-action', name: '결정·액션 추출', sub: '결정사항과 액션 아이템 강조' },
  { id: 'customer-interview', name: '고객 인터뷰', sub: '인사이트·인용·질문' }];

  return (
    <>
      <div onClick={onClose} style={{
        position: 'fixed', inset: 0, background: 'rgba(20,12,10,0.30)',
        backdropFilter: 'blur(4px)', zIndex: 100,
        display: 'flex', alignItems: 'center', justifyContent: 'center'
      }} />
      <div style={{
        position: 'fixed', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
        zIndex: 101, width: 480,
        background: t.surface, borderRadius: 14,
        border: `0.5px solid ${t.lineStrong}`,
        boxShadow: '0 20px 60px rgba(0,0,0,0.30)', padding: 20
      }}>
        <div style={{ fontSize: 16, fontWeight: 600, color: t.ink, letterSpacing: '-0.01em', marginBottom: 4 }}>
          회의록 다시 생성
        </div>
        <div style={{ fontSize: 12.5, color: t.ink50, marginBottom: 16 }}>
          템플릿을 바꾸거나 추가 지시를 더해서 다시 만들 수 있어요. 전사본은 그대로 사용됩니다.
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 14 }}>
          {tpls.map((p) => {
            const active = tpl === p.id;
            return (
              <button key={p.id} onClick={() => setTpl(p.id)} style={{
                textAlign: 'left',
                padding: '10px 12px', borderRadius: 9,
                border: `1px solid ${active ? t.accent : t.line}`,
                background: active ? t.accentSoft : t.canvas,
                cursor: 'pointer', fontFamily: 'inherit',
                display: 'flex', alignItems: 'center', gap: 10
              }}>
                <div style={{
                  width: 14, height: 14, borderRadius: '50%',
                  background: active ? t.accent : 'transparent',
                  border: `1.4px solid ${active ? t.accent : t.lineStrong}`,
                  flexShrink: 0, position: 'relative'
                }}>
                  {active && <div style={{ position: 'absolute', inset: 4, borderRadius: '50%', background: '#fff' }} />}
                </div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>{p.name}</div>
                  <div style={{ fontSize: 11.5, color: t.ink50 }}>{p.sub}</div>
                </div>
              </button>);

          })}
        </div>
        <div style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: t.ink70, marginBottom: 6 }}>추가 지시 (선택)</div>
          <textarea
            value={hint} onChange={(e) => setHint(e.target.value)}
            placeholder="예: 액션 아이템에 담당자 이메일도 함께 적어주세요."
            style={{
              width: '100%', height: 64, resize: 'none',
              padding: '8px 10px', boxSizing: 'border-box',
              border: `0.5px solid ${t.lineStrong}`, borderRadius: 8,
              fontFamily: 'inherit', fontSize: 12, color: t.ink,
              background: t.canvas, outline: 'none'
            }} />
          
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
          <PillButton theme={t} ghost onClick={onClose}>취소</PillButton>
          <PillButton theme={t} primary icon="sparkle" onClick={onClose}>다시 생성</PillButton>
        </div>
      </div>
    </>);

}

window.ScreenMinutes = ScreenMinutes;