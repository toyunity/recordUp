// screen-templates.jsx — template manager

function ScreenTemplates({ theme }) {
  const t = theme;
  const [active, setActive] = React.useState('decision-action');
  const [showNew, setShowNew] = React.useState(false);
  const tpls = [
    {
      id: 'default', name: '기본 회의록', icon: 'doc',
      sub: '범용 회의에 적합한 표준 포맷',
      sections: ['요약', '논의', '결정 사항', '다음 단계'],
      uses: 47,
      lastUsed: '5월 2일',
    },
    {
      id: 'decision-action', name: '결정·액션 추출', icon: 'flag',
      sub: '결정사항과 담당자별 액션 아이템 강조',
      sections: ['한눈에 보기', '결정 사항', '액션 아이템', '논의 요약'],
      uses: 32,
      lastUsed: '오늘',
      featured: true,
    },
    {
      id: 'customer-interview', name: '고객 인터뷰', icon: 'users',
      sub: '리서치·UX 인터뷰용. 인사이트·인용·후속 질문',
      sections: ['핵심 인사이트', '인용구', '관찰', '후속 질문'],
      uses: 18,
      lastUsed: '4월 28일',
    },
    {
      id: 'one-on-one', name: '1:1 미팅', icon: 'user',
      sub: '주간 1:1, 멘토링용',
      sections: ['지난 주 회고', '이번 주 목표', '블로커', '피드백'],
      uses: 12,
      lastUsed: '4월 27일',
      custom: true,
    },
  ];

  const current = tpls.find(p => p.id === active);

  const samplePrompt = `다음은 한국어로 진행된 회의의 전사본입니다. 이를 바탕으로 회의록을 작성해주세요.

# 형식
- 한국어 마크다운으로 출력
- 결정사항은 명확히 번호 매기기
- 액션 아이템은 [ ] 체크박스 + 담당자 + 기한 형식
- 인용은 그대로 옮기지 말고 의미 단위로 요약

# 섹션
1. 한눈에 보기 (3줄 이내 핵심 요약)
2. 결정 사항 (각 결정의 근거 한 문장 포함)
3. 액션 아이템 (담당자 · 내용 · 기한)
4. 논의 요약 (주제별 묶음)

# 입력
{{transcript}}`;

  return (
    <div style={{ height: '100%', display: 'flex', minHeight: 0 }}>
      {/* List */}
      <div style={{
        width: 320, flexShrink: 0,
        borderRight: `0.5px solid ${t.line}`,
        display: 'flex', flexDirection: 'column', minHeight: 0,
      }}>
        <div style={{ padding: '20px 18px 12px' }}>
          <PillButton theme={t} primary icon="plus" size="sm" style={{ width: '100%', justifyContent: 'center' }} onClick={() => setShowNew(true)}>새 템플릿</PillButton>
        </div>
        <div style={{ flex: 1, overflow: 'auto', padding: '4px 10px 10px' }}>
          {tpls.map((p) => {
            const sel = p.id === active;
            return (
              <button key={p.id} onClick={() => setActive(p.id)} style={{
                width: '100%', textAlign: 'left',
                border: 'none',
                background: sel ? t.surface : 'transparent',
                padding: '12px 12px',
                borderRadius: 10, marginBottom: 2,
                cursor: 'pointer', fontFamily: 'inherit',
                boxShadow: sel ? `0 0 0 0.5px ${t.lineStrong}, 0 1px 2px rgba(0,0,0,0.04)` : 'none',
                display: 'flex', flexDirection: 'column', gap: 4,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{
                    width: 26, height: 26, borderRadius: 7,
                    background: sel ? t.gradient : t.surfaceMuted,
                    border: sel ? 'transparent' : `0.5px solid ${t.line}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    color: sel ? '#fff' : t.ink70,
                  }}>
                    <Icon name={p.icon} size={14} />
                  </div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em', flex: 1 }}>{p.name}</div>
                  {p.featured && (
                    <span style={{
                      fontSize: 9.5, fontWeight: 600, color: t.accent,
                      background: t.accentSoft, padding: '1px 5px',
                      borderRadius: 3, letterSpacing: '0.04em', textTransform: 'uppercase',
                    }}>기본</span>
                  )}
                  {p.custom && (
                    <Icon name="pencil" size={11} color={t.ink50} />
                  )}
                </div>
                <div style={{ fontSize: 11.5, color: t.ink50, lineHeight: 1.4 }}>{p.sub}</div>
                <div style={{ fontSize: 10.5, color: t.ink35, fontFamily: TOKENS.fontMono, marginTop: 2 }}>
                  사용 {p.uses}회 · 마지막 {p.lastUsed}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Detail */}
      <div style={{ flex: 1, overflow: 'auto', padding: '24px 32px', minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 16, marginBottom: 24 }}>
          <div style={{
            width: 48, height: 48, borderRadius: 12,
            background: t.gradient,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 10px rgba(224,36,94,0.30)',
          }}>
            <Icon name={current.icon} size={22} color="#fff" />
          </div>
          <div style={{ flex: 1 }}>
            <h2 style={{ margin: '0 0 4px', fontSize: 24, fontWeight: 600, letterSpacing: '-0.015em', color: t.ink, fontFamily: TOKENS.fontDisplay }}>{current.name}</h2>
            <div style={{ fontSize: 13, color: t.ink70 }}>{current.sub}</div>
          </div>
          <PillButton theme={t} ghost size="sm" icon="copy">복제</PillButton>
          <PillButton theme={t} ghost size="sm" icon="check">기본 템플릿 설정</PillButton>
          <PillButton theme={t} size="sm" icon="pencil">편집</PillButton>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <Section theme={t} title="섹션 구성">
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 6 }}>
                {current.sections.map((s, i) => (
                  <div key={i} style={{
                    padding: '6px 8px 6px 10px', borderRadius: 7,
                    background: t.surface, border: `0.5px solid ${t.line}`,
                    display: 'flex', alignItems: 'center', gap: 8,
                  }}>
                    <span style={{
                      width: 16, height: 16, borderRadius: '50%',
                      background: t.surfaceMuted, fontSize: 10, fontWeight: 600,
                      fontFamily: TOKENS.fontMono, color: t.ink70,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      flexShrink: 0,
                    }}>{i + 1}</span>
                    <span style={{ fontSize: 12, color: t.ink, letterSpacing: '-0.005em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>{s}</span>
                    <button title="삭제" style={{
                      width: 20, height: 20, borderRadius: 5,
                      border: 'none', background: 'transparent',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      color: t.ink35, cursor: 'pointer', flexShrink: 0,
                    }}
                      onMouseEnter={(e) => { e.currentTarget.style.background = t.surfaceMuted; e.currentTarget.style.color = t.ink70; }}
                      onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = t.ink35; }}>
                      <Icon name="x" size={11} />
                    </button>
                  </div>
                ))}
                <button style={{
                  padding: '6px 10px', borderRadius: 7,
                  background: 'transparent', border: `1px dashed ${t.line}`,
                  display: 'flex', alignItems: 'center', gap: 6, color: t.ink50,
                  cursor: 'pointer', fontFamily: 'inherit', fontSize: 12,
                }}>
                  <Icon name="plus" size={11} />
                  <span>섹션 추가</span>
                </button>
              </div>
            </Section>

            <Section theme={t} title="프롬프트" hint="섹션 변경 시 자동 갱신됩니다" hintIcon="lock">
              <pre style={{
                margin: 0, padding: 16, borderRadius: 9,
                background: t.surface, border: `0.5px solid ${t.line}`,
                fontFamily: TOKENS.fontMono, fontSize: 11.5, lineHeight: 1.6,
                color: t.ink70, whiteSpace: 'pre-wrap', overflow: 'auto',
                minHeight: 320,
              }}>{samplePrompt}</pre>
            </Section>
          </div>
      </div>
      {showNew && <NewTemplateSheet theme={t} onClose={() => setShowNew(false)} tpls={tpls} />}
    </div>
  );
}

function NewTemplateSheet({ theme, onClose, tpls }) {
  const t = theme;
  const [name, setName] = React.useState('');
  const [desc, setDesc] = React.useState('');
  const [iconName, setIconName] = React.useState('doc');
  const [start, setStart] = React.useState('blank'); // blank | duplicate | preset
  const [presetId, setPresetId] = React.useState(tpls[0]?.id);
  const iconChoices = ['doc', 'flag', 'users', 'user', 'sparkle', 'lightning'];
  const valid = name.trim().length > 0;

  return (
    <div onClick={onClose} style={{
      position: 'absolute', inset: 0, zIndex: 50,
      background: 'rgba(15,10,8,0.32)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 24,
    }}>
      <div onClick={(e) => e.stopPropagation()} style={{
        width: 540, maxHeight: '90%',
        background: t.canvas, borderRadius: 14,
        border: `0.5px solid ${t.lineStrong}`,
        boxShadow: '0 24px 60px rgba(15,10,8,0.28)',
        display: 'flex', flexDirection: 'column', overflow: 'hidden',
      }}>
        {/* Header */}
        <div style={{
          padding: '18px 22px 14px',
          borderBottom: `0.5px solid ${t.line}`,
          display: 'flex', alignItems: 'flex-start', gap: 10,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 17, fontWeight: 600, color: t.ink, letterSpacing: '-0.012em', fontFamily: TOKENS.fontDisplay }}>새 템플릿</div>
            <div style={{ fontSize: 12, color: t.ink50, marginTop: 2 }}>회의록 양식의 이름과 시작 방식을 정해주세요</div>
          </div>
          <button onClick={onClose} style={{
            width: 26, height: 26, borderRadius: 7,
            border: 'none', background: 'transparent', cursor: 'pointer',
            color: t.ink50, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><Icon name="x" size={14} /></button>
        </div>

        {/* Body */}
        <div style={{ padding: '18px 22px', overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 18 }}>
          {/* Name + Icon */}
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: t.ink70, marginBottom: 8, letterSpacing: '-0.005em' }}>이름</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'stretch' }}>
              <div style={{ position: 'relative' }}>
                <button style={{
                  width: 38, height: 38, borderRadius: 8,
                  background: t.surfaceMuted, border: `0.5px solid ${t.line}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  cursor: 'pointer', color: t.accent,
                }}><Icon name={iconName} size={16} /></button>
              </div>
              <input autoFocus value={name} onChange={(e) => setName(e.target.value)}
                placeholder="예: 스프린트 리뷰"
                style={{
                  flex: 1, height: 38, padding: '0 12px', borderRadius: 8,
                  background: t.canvas, border: `0.5px solid ${t.line}`,
                  fontFamily: 'inherit', fontSize: 13, color: t.ink, outline: 'none',
                  letterSpacing: '-0.005em',
                }} />
            </div>
            {/* Icon picker */}
            <div style={{ display: 'flex', gap: 4, marginTop: 8, flexWrap: 'wrap' }}>
              {iconChoices.map((ic) => (
                <button key={ic} onClick={() => setIconName(ic)} style={{
                  width: 28, height: 28, borderRadius: 6,
                  border: `0.5px solid ${iconName === ic ? t.accent : t.line}`,
                  background: iconName === ic ? `${t.accent}14` : t.surface,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: iconName === ic ? t.accent : t.ink50, cursor: 'pointer',
                }}><Icon name={ic} size={12} /></button>
              ))}
            </div>
          </div>

          {/* Description */}
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: t.ink70, marginBottom: 8, letterSpacing: '-0.005em' }}>설명 <span style={{ color: t.ink35, fontWeight: 400 }}>(선택)</span></div>
            <input value={desc} onChange={(e) => setDesc(e.target.value)}
              placeholder="이 템플릿을 언제 쓰는지 한 줄로"
              style={{
                width: '100%', height: 36, padding: '0 12px', borderRadius: 8,
                background: t.canvas, border: `0.5px solid ${t.line}`,
                fontFamily: 'inherit', fontSize: 12.5, color: t.ink, outline: 'none',
                boxSizing: 'border-box',
              }} />
          </div>

          {/* Start from */}
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: t.ink70, marginBottom: 8, letterSpacing: '-0.005em' }}>시작 방식</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {[
                { id: 'blank', label: '빈 템플릿', sub: '섹션을 직접 추가합니다', icon: 'plus' },
                { id: 'duplicate', label: '기존 템플릿 복제', sub: '선택한 템플릿의 섹션·프롬프트를 복사', icon: 'copy' },
                { id: 'preset', label: '프리셋에서 시작', sub: '회고·리서치·1:1 등 추천 구성', icon: 'sparkle' },
              ].map((opt) => {
                const sel = start === opt.id;
                return (
                  <button key={opt.id} onClick={() => setStart(opt.id)} style={{
                    display: 'flex', alignItems: 'center', gap: 10,
                    padding: '10px 12px', borderRadius: 9,
                    background: sel ? t.surface : 'transparent',
                    border: `0.5px solid ${sel ? t.accent : t.line}`,
                    boxShadow: sel ? `0 0 0 1px ${t.accent}33` : 'none',
                    cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                  }}>
                    <div style={{
                      width: 28, height: 28, borderRadius: 7,
                      background: sel ? `${t.accent}1A` : t.surfaceMuted,
                      color: sel ? t.accent : t.ink50,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      flexShrink: 0,
                    }}><Icon name={opt.icon} size={13} /></div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 12.5, color: t.ink, fontWeight: 500, letterSpacing: '-0.005em' }}>{opt.label}</div>
                      <div style={{ fontSize: 11, color: t.ink50, marginTop: 1 }}>{opt.sub}</div>
                    </div>
                    <div style={{
                      width: 14, height: 14, borderRadius: '50%',
                      border: `1px solid ${sel ? t.accent : t.line}`,
                      background: sel ? t.accent : 'transparent',
                      flexShrink: 0,
                    }} />
                  </button>
                );
              })}
            </div>

            {/* Conditional sub-picker */}
            {start === 'duplicate' && (
              <div style={{ marginTop: 8, padding: '10px 12px', borderRadius: 9, background: t.surfaceMuted, border: `0.5px solid ${t.line}` }}>
                <div style={{ fontSize: 11, color: t.ink50, marginBottom: 6 }}>복제할 템플릿</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                  {tpls.map((p) => (
                    <button key={p.id} onClick={() => setPresetId(p.id)} style={{
                      padding: '5px 10px', borderRadius: 999,
                      border: `0.5px solid ${presetId === p.id ? t.accent : t.line}`,
                      background: presetId === p.id ? `${t.accent}14` : t.canvas,
                      color: presetId === p.id ? t.accent : t.ink70,
                      fontSize: 11.5, cursor: 'pointer', fontFamily: 'inherit',
                    }}>{p.name}</button>
                  ))}
                </div>
              </div>
            )}
            {start === 'preset' && (
              <div style={{ marginTop: 8, padding: '10px 12px', borderRadius: 9, background: t.surfaceMuted, border: `0.5px solid ${t.line}` }}>
                <div style={{ fontSize: 11, color: t.ink50, marginBottom: 6 }}>프리셋</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                  {['스프린트 회고', '디자인 리뷰', '리서치 인터뷰', '주간 1:1', '브레인스토밍'].map((n) => (
                    <button key={n} style={{
                      padding: '5px 10px', borderRadius: 999,
                      border: `0.5px solid ${t.line}`, background: t.canvas,
                      color: t.ink70, fontSize: 11.5, cursor: 'pointer', fontFamily: 'inherit',
                    }}>{n}</button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div style={{
          padding: '12px 22px',
          borderTop: `0.5px solid ${t.line}`,
          display: 'flex', alignItems: 'center', gap: 8,
          background: t.surface,
        }}>
          <div style={{ fontSize: 11, color: t.ink50, flex: 1, fontFamily: TOKENS.fontMono }}>
            {start === 'blank' ? '빈 상태로 만들기' :
             start === 'duplicate' ? `${tpls.find((p) => p.id === presetId)?.name} 복제` :
             '프리셋에서 시작'}
          </div>
          <PillButton theme={t} ghost size="sm" onClick={onClose}>취소</PillButton>
          <PillButton theme={t} primary size="sm" icon="check" onClick={onClose} disabled={!valid}>만들기</PillButton>
        </div>
      </div>
    </div>
  );
}

function Section({ theme, title, children, hint, hintIcon }) {
  const t = theme;
  return (
    <div>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        marginBottom: 10,
      }}>
        <div style={{
          fontSize: 11, fontWeight: 700, color: t.ink50,
          letterSpacing: '0.08em', textTransform: 'uppercase',
        }}>{title}</div>
        {hint && (
          <div style={{
            fontSize: 10.5, color: t.ink50,
            display: 'inline-flex', alignItems: 'center', gap: 4,
            padding: '2px 7px', borderRadius: 999,
            background: t.surfaceMuted, border: `0.5px solid ${t.line}`,
          }}>
            {hintIcon && <Icon name={hintIcon} size={10} />}
            <span>{hint}</span>
          </div>
        )}
      </div>
      {children}
    </div>
  );
}

function SideBox({ theme, label, value, sub }) {
  const t = theme;
  return (
    <div style={{
      padding: 12, borderRadius: 10,
      background: t.surface, border: `0.5px solid ${t.line}`,
    }}>
      <div style={{ fontSize: 10.5, color: t.ink50, marginBottom: 2 }}>{label}</div>
      <div style={{ fontSize: 16, fontWeight: 600, color: t.ink, letterSpacing: '-0.01em', fontFamily: TOKENS.fontDisplay }}>{value}</div>
      <div style={{ fontSize: 10.5, color: t.ink50, marginTop: 1 }}>{sub}</div>
    </div>
  );
}

window.ScreenTemplates = ScreenTemplates;
