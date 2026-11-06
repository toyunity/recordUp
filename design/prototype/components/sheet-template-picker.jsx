// sheet-template-picker.jsx — modal sheet shown after a file is dropped

function TemplatePickerSheet({ theme, fileName, onPick, onCancel }) {
  const t = theme;
  const [active, setActive] = React.useState('decision-action');
  const tpls = [
    { id: 'default', name: '기본 회의록', sub: '범용 회의 표준 포맷', icon: 'doc',
      sample: '• 요약\n• 논의\n• 결정 사항\n• 다음 단계' },
    { id: 'decision-action', name: '결정·액션 추출', sub: '결정사항·액션 강조', icon: 'flag',
      sample: '• 한눈에 보기\n• 결정 사항\n• 액션 아이템\n• 논의 요약', featured: true },
    { id: 'customer-interview', name: '고객 인터뷰', sub: '인사이트·인용·후속', icon: 'users',
      sample: '• 핵심 인사이트\n• 인용구\n• 관찰\n• 후속 질문' },
  ];

  return (
    <>
      <div onClick={onCancel} style={{
        position: 'absolute', inset: 0, background: 'rgba(20,12,10,0.30)',
        backdropFilter: 'blur(4px)', zIndex: 100,
      }} />
      <div style={{
        position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
        zIndex: 101, width: 580,
        background: t.surface, borderRadius: 16,
        border: `0.5px solid ${t.lineStrong}`,
        boxShadow: '0 24px 60px rgba(0,0,0,0.30)', padding: 22,
        fontFamily: TOKENS.fontUI,
      }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 18 }}>
          <div style={{
            width: 38, height: 38, borderRadius: 10,
            background: t.gradient,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(224,36,94,0.30)',
          }}>
            <Icon name="wave" size={18} color="#fff" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 600, color: t.ink, letterSpacing: '-0.01em' }}>회의록 양식 선택</div>
            <div style={{ fontSize: 12, color: t.ink50, marginTop: 2, fontFamily: TOKENS.fontMono }}>{fileName}</div>
          </div>
          <button onClick={onCancel} style={{
            width: 24, height: 24, borderRadius: 6,
            background: 'transparent', border: 'none', color: t.ink50,
            cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="x" size={14} />
          </button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 16 }}>
          {tpls.map((p) => {
            const sel = active === p.id;
            return (
              <button key={p.id} onClick={() => setActive(p.id)} style={{
                textAlign: 'left',
                padding: '14px 16px', borderRadius: 12,
                border: `1px solid ${sel ? t.accent : t.line}`,
                background: sel ? t.gradientSoft : t.canvas,
                cursor: 'pointer', fontFamily: 'inherit',
                display: 'flex', alignItems: 'center', gap: 14,
              }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 9,
                  background: sel ? t.gradient : t.surface,
                  border: sel ? 'transparent' : `0.5px solid ${t.line}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: sel ? '#fff' : t.ink70, flexShrink: 0,
                  boxShadow: sel ? '0 2px 6px rgba(224,36,94,0.30)' : 'none',
                }}>
                  <Icon name={p.icon} size={16} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                    <span style={{ fontSize: 13.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>{p.name}</span>
                    {p.featured && (
                      <span style={{
                        fontSize: 9.5, fontWeight: 700, color: t.accent,
                        background: t.accentSoft, padding: '1px 6px',
                        borderRadius: 3, letterSpacing: '0.04em', textTransform: 'uppercase',
                      }}>추천</span>
                    )}
                  </div>
                  <div style={{ fontSize: 11.5, color: t.ink50 }}>{p.sub}</div>
                </div>
                <pre style={{
                  margin: 0, fontFamily: TOKENS.fontMono, fontSize: 10.5,
                  color: t.ink50, lineHeight: 1.5, whiteSpace: 'pre',
                  paddingLeft: 14, borderLeft: `0.5px solid ${t.line}`,
                  flexShrink: 0,
                }}>{p.sample}</pre>
              </button>
            );
          })}
        </div>

        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '10px 12px', borderRadius: 9,
          background: t.surfaceMuted, border: `0.5px solid ${t.line}`,
          marginBottom: 16,
        }}>
          <Icon name="lightning" size={12} color={t.accent} />
          <span style={{ fontSize: 11.5, color: t.ink70, flex: 1 }}>
            예상 처리 시간 <b style={{ color: t.ink }}>약 1분 30초</b> · 32:18 오디오 기준
          </span>
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: 12, color: t.ink70, cursor: 'pointer' }}>
            <input type="checkbox" defaultChecked style={{ accentColor: t.accent }} />
            전사본 검토 단계 거치기
          </label>
          <div style={{ display: 'flex', gap: 8 }}>
            <PillButton theme={t} ghost onClick={onCancel}>취소</PillButton>
            <PillButton theme={t} primary onClick={() => onPick(active)} icon="arrowRight">시작</PillButton>
          </div>
        </div>
      </div>
    </>
  );
}

window.TemplatePickerSheet = TemplatePickerSheet;
