// screen-settings.jsx — settings

function ScreenSettings({ theme }) {
  const t = theme;
  const [tab, setTab] = React.useState('models');
  const tabs = [
    { id: 'models', label: '모델', icon: 'sparkle' },
    { id: 'storage', label: '저장 위치', icon: 'folder' },
    { id: 'shortcuts', label: '단축키', icon: 'lightning' },
    { id: 'about', label: '정보', icon: 'star' },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', minHeight: 0 }}>
      {/* tabs */}
      <div style={{
        width: 200, flexShrink: 0, padding: '24px 12px',
        borderRight: `0.5px solid ${t.line}`,
      }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: t.ink50, letterSpacing: '0.08em', textTransform: 'uppercase', padding: '0 8px 10px' }}>설정</div>
        {tabs.map((tb) => (
          <button key={tb.id} onClick={() => setTab(tb.id)} style={{
            width: '100%', textAlign: 'left', border: 'none',
            background: tab === tb.id ? t.surface : 'transparent',
            color: tab === tb.id ? t.ink : t.ink70,
            padding: '7px 10px', borderRadius: 7, marginBottom: 1,
            display: 'flex', alignItems: 'center', gap: 8,
            cursor: 'pointer', fontFamily: 'inherit',
            fontSize: 12.5, fontWeight: tab === tb.id ? 600 : 500,
            boxShadow: tab === tb.id ? `0 0 0 0.5px ${t.lineStrong}` : 'none',
          }}>
            <Icon name={tb.icon} size={13} />
            {tb.label}
          </button>
        ))}
      </div>

      {/* content */}
      <div style={{ flex: 1, overflow: 'auto', padding: '24px 32px' }}>
        {tab === 'models' && <SettingsModels theme={t} />}
        {tab === 'storage' && <SettingsStorage theme={t} />}
        {tab === 'shortcuts' && <SettingsShortcuts theme={t} />}
        {tab === 'about' && <SettingsAbout theme={t} />}
      </div>
    </div>
  );
}

function SettingsModels({ theme }) {
  const t = theme;
  const [whisper, setWhisper] = React.useState('large-v3-turbo');
  const [diar, setDiar] = React.useState('pyannote-v4');
  return (
    <div style={{ maxWidth: 640, display: 'flex', flexDirection: 'column', gap: 28 }}>
      <SettingsHero theme={t} title="모델" sub="모든 처리는 이 Mac에서 이루어집니다." />

      <SettingsGroup theme={t} title="음성 인식 (STT)" sub="WhisperKit · CoreML">
        {[
          { id: 'large-v3-turbo', name: 'large-v3-turbo', size: '1.5 GB', sub: '권장 · 빠르고 정확', state: 'downloaded' },
          { id: 'large-v3', name: 'large-v3', size: '3.1 GB', sub: '최고 품질 · 느림', state: 'downloadable' },
          { id: 'medium', name: 'medium', size: '770 MB', sub: '빠름 · 짧은 회의', state: 'downloaded' },
        ].map((m) => (
          <ModelRow key={m.id} theme={t} model={m} active={whisper === m.id} onSelect={() => setWhisper(m.id)} />
        ))}
      </SettingsGroup>

      <SettingsGroup theme={t} title="화자 분리" sub="SpeakerKit · pyannote">
        {[
          { id: 'pyannote-v4', name: 'pyannote v4', size: '420 MB', sub: '권장', state: 'downloaded' },
          { id: 'pyannote-v3', name: 'pyannote v3', size: '380 MB', sub: '구버전', state: 'downloadable' },
        ].map((m) => (
          <ModelRow key={m.id} theme={t} model={m} active={diar === m.id} onSelect={() => setDiar(m.id)} />
        ))}
      </SettingsGroup>

      <SettingsGroup theme={t} title="회의록 생성" sub="Claude Code CLI">
        <div style={{
          padding: 14, borderRadius: 10,
          background: t.surface, border: `0.5px solid ${t.line}`,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 9,
            background: 'linear-gradient(135deg, #C97757 0%, #6E4A33 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff',
          }}>
            <Icon name="sparkle" size={16} color="#fff" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>Claude Max</div>
            <div style={{ fontSize: 11.5, color: t.ink50, fontFamily: TOKENS.fontMono }}>본인의 구독 사용 · 추가 비용 없음</div>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            fontSize: 11, color: t.success, fontWeight: 600,
            padding: '3px 8px', borderRadius: 4,
            background: 'rgba(31,138,91,0.10)',
          }}>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: t.success }} />
            로그인됨
          </div>
        </div>
        <div style={{
          padding: '10px 14px', borderRadius: 10,
          background: t.surfaceMuted, border: `0.5px solid ${t.line}`,
          fontFamily: TOKENS.fontMono, fontSize: 11, color: t.ink70,
          marginTop: 8, display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <Icon name="folder" size={11} color={t.ink50} />
          <span style={{ flex: 1 }}>/usr/local/bin/claude</span>
          <span style={{ color: t.success }}>v1.4.2</span>
        </div>
      </SettingsGroup>
    </div>
  );
}

function ModelRow({ theme, model, active, onSelect }) {
  const t = theme;
  return (
    <div onClick={onSelect} style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 14px', borderRadius: 10,
      background: active ? t.gradientSoft : t.surface,
      border: `0.5px solid ${active ? 'transparent' : t.line}`,
      cursor: 'pointer',
    }}>
      <div style={{
        width: 16, height: 16, borderRadius: '50%',
        background: active ? t.accent : 'transparent',
        border: `1.5px solid ${active ? t.accent : t.lineStrong}`,
        flexShrink: 0, position: 'relative',
      }}>
        {active && <div style={{ position: 'absolute', inset: 4, borderRadius: '50%', background: '#fff' }} />}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>{model.name}</div>
        <div style={{ fontSize: 11.5, color: t.ink50 }}>{model.sub}</div>
      </div>
      <div style={{ fontFamily: TOKENS.fontMono, fontSize: 11, color: t.ink50 }}>{model.size}</div>
      {model.state === 'downloaded' ? (
        <Icon name="check" size={12} color={t.success} stroke={2.4} />
      ) : (
        <button style={{
          padding: '3px 9px', borderRadius: 6,
          border: `0.5px solid ${t.lineStrong}`, background: t.canvas,
          fontFamily: 'inherit', fontSize: 11, color: t.ink70, cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', gap: 4,
        }}>
          <Icon name="download" size={10} />
          <span>다운로드</span>
        </button>
      )}
    </div>
  );
}

function SettingsStorage({ theme }) {
  const t = theme;
  const items = [
    { label: '모델 캐시', path: '~/Documents/huggingface/', size: '2.1 GB' },
    { label: '전사본', path: '~/Documents/record-up/transcripts/', size: '38.4 MB' },
    { label: '회의록', path: '~/Documents/record-up/minutes/', size: '4.2 MB' },
    { label: '원본 오디오', path: '~/Documents/record-up/audio/', size: '0 — 자동 삭제 켜짐' },
  ];
  return (
    <div style={{ maxWidth: 640, display: 'flex', flexDirection: 'column', gap: 24 }}>
      <SettingsHero theme={t} title="저장 위치" sub="모든 결과물은 본인의 Mac에만 저장됩니다." />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {items.map((it, i) => (
          <div key={i} style={{
            padding: '12px 14px', borderRadius: 10,
            background: t.surface, border: `0.5px solid ${t.line}`,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <Icon name="folder" size={15} color={t.ink50} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>{it.label}</div>
              <div style={{ fontSize: 11, color: t.ink50, fontFamily: TOKENS.fontMono,
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{it.path}</div>
            </div>
            <div style={{ fontFamily: TOKENS.fontMono, fontSize: 11.5, color: t.ink70 }}>{it.size}</div>
            <PillButton theme={t} ghost size="sm">변경…</PillButton>
          </div>
        ))}
      </div>

      <ToggleRow theme={t} label="처리 후 원본 오디오 삭제" sub="회의록 저장이 완료되면 .m4a 파일을 삭제합니다." defaultOn />
      <ToggleRow theme={t} label="회의록 자동 열기" sub="처리 완료 후 기본 마크다운 에디터로 엽니다." defaultOn />
      <ToggleRow theme={t} label="iCloud Drive로 동기화" sub="회의록만 동기화됩니다 (베타)." />
    </div>
  );
}

function ToggleRow({ theme, label, sub, defaultOn }) {
  const t = theme;
  const [on, setOn] = React.useState(!!defaultOn);
  return (
    <div onClick={() => setOn(!on)} style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 14px', borderRadius: 10,
      background: t.surface, border: `0.5px solid ${t.line}`,
      cursor: 'pointer',
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 12.5, fontWeight: 600, color: t.ink, letterSpacing: '-0.005em' }}>{label}</div>
        <div style={{ fontSize: 11, color: t.ink50, marginTop: 2 }}>{sub}</div>
      </div>
      <div style={{
        width: 36, height: 22, borderRadius: 11,
        background: on ? t.accent : t.ink20,
        position: 'relative', transition: 'background 0.15s',
      }}>
        <div style={{
          position: 'absolute', top: 2, left: on ? 16 : 2,
          width: 18, height: 18, borderRadius: '50%', background: '#fff',
          boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
          transition: 'left 0.15s',
        }} />
      </div>
    </div>
  );
}

function SettingsShortcuts({ theme }) {
  const t = theme;
  const groups = [
    {
      title: '일반',
      items: [
        ['새 회의록', '⌘N'],
        ['파일 열기…', '⌘O'],
        ['검색', '⌘F'],
        ['설정', '⌘,'],
      ],
    },
    {
      title: '전사본 검토',
      items: [
        ['재생/일시정지', 'Space'],
        ['10초 뒤로', '←'],
        ['10초 앞으로', '→'],
        ['이 구간 화자 변경', '⌘E'],
      ],
    },
    {
      title: '회의록',
      items: [
        ['저장', '⌘S'],
        ['클립보드 복사', '⌘C'],
        ['내보내기…', '⌘⇧E'],
        ['다시 생성', '⌘R'],
      ],
    },
  ];
  return (
    <div style={{ maxWidth: 560, display: 'flex', flexDirection: 'column', gap: 24 }}>
      <SettingsHero theme={t} title="단축키" sub="자주 쓰는 동작들" />
      {groups.map((g) => (
        <div key={g.title}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: t.ink50,
            letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 8,
          }}>{g.title}</div>
          <div style={{
            background: t.surface, border: `0.5px solid ${t.line}`, borderRadius: 10,
            overflow: 'hidden',
          }}>
            {g.items.map(([k, v], i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 14px',
                borderTop: i === 0 ? 'none' : `0.5px solid ${t.line}`,
              }}>
                <span style={{ flex: 1, fontSize: 13, color: t.ink }}>{k}</span>
                <Kbd t={t}>{v}</Kbd>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function Kbd({ children, t }) {
  return (
    <span style={{
      fontFamily: TOKENS.fontMono, fontSize: 11, fontWeight: 500,
      color: t.ink70,
      padding: '2px 8px', borderRadius: 5,
      background: t.canvas,
      border: `0.5px solid ${t.lineStrong}`,
      boxShadow: `inset 0 -1px 0 ${t.line}`,
    }}>{children}</span>
  );
}

function SettingsAbout({ theme }) {
  const t = theme;
  return (
    <div style={{ maxWidth: 480, display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <img src="assets/brand-icon.png" alt="record-up" width="80" height="80"
          style={{
            width: 80, height: 80, borderRadius: 18, display: 'block',
            boxShadow: '0 8px 24px rgba(224,36,94,0.30)'
          }} />
        <div>
          <div style={{
            display: 'flex', alignItems: 'baseline',
            fontFamily: TOKENS.fontDisplay, lineHeight: 1.25,
            paddingBottom: 4,
          }}>
            <span style={{ fontSize: 22, fontWeight: 500, color: t.ink70, letterSpacing: '-0.02em' }}>record</span>
            <span style={{
              display: 'inline-block', width: 5, height: 5, borderRadius: '50%',
              background: 'linear-gradient(135deg, #FF6A3D 0%, #E0245E 100%)',
              margin: '0 5px 3px', alignSelf: 'center',
            }} />
            <span style={{
              fontSize: 26, fontWeight: 800, letterSpacing: '-0.04em', fontStyle: 'italic',
              background: 'linear-gradient(135deg, #FF6A3D 0%, #E0245E 100%)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
              display: 'inline-block', paddingRight: 6, paddingBottom: 3,
            }}>UP</span>
          </div>
          <div style={{ fontSize: 12.5, color: t.ink50, fontFamily: TOKENS.fontMono }}>v0.3.0 · build 2026.05.07</div>
        </div>
      </div>
      <p style={{
        margin: 0, fontSize: 13.5, lineHeight: 1.6, color: t.ink70,
      }}>
        음성 메모를 끌어다 놓으면 한국어 전사·화자 분리·회의록 생성을 모두 이 Mac에서 처리합니다.
        오디오는 외부로 전송되지 않으며, 회의록 생성에는 본인의 Claude Max 구독을 사용합니다.
      </p>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 1, background: t.line, borderRadius: 10, overflow: 'hidden' }}>
        {[
          ['릴리스 노트', '0.3.0 — 화자 분리 정확도 개선'],
          ['지원', 'support@record-up.app'],
          ['오픈소스', 'WhisperKit · pyannote · ImageRenderer'],
        ].map(([k, v], i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '12px 14px', background: t.surface,
            cursor: 'pointer',
          }}>
            <span style={{ flex: 1, fontSize: 12.5, color: t.ink70 }}>{k}</span>
            <span style={{ fontSize: 12, color: t.ink, fontWeight: 500 }}>{v}</span>
            <Icon name="arrowRight" size={12} color={t.ink35} />
          </div>
        ))}
      </div>
    </div>
  );
}

function SettingsHero({ theme, title, sub }) {
  const t = theme;
  return (
    <div>
      <h2 style={{ margin: '0 0 4px', fontSize: 22, fontWeight: 600, letterSpacing: '-0.015em', color: t.ink, fontFamily: TOKENS.fontDisplay }}>{title}</h2>
      <div style={{ fontSize: 13, color: t.ink70 }}>{sub}</div>
    </div>
  );
}

function SettingsGroup({ theme, title, sub, children }) {
  const t = theme;
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 10 }}>
        <div style={{
          fontSize: 11, fontWeight: 700, color: t.ink50,
          letterSpacing: '0.08em', textTransform: 'uppercase',
        }}>{title}</div>
        {sub && <div style={{ fontSize: 11, color: t.ink35, fontFamily: TOKENS.fontMono }}>{sub}</div>}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>{children}</div>
    </div>
  );
}

window.ScreenSettings = ScreenSettings;
