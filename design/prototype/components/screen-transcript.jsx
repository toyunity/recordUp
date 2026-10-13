// screen-transcript.jsx — transcript review with audio + speaker editing

// 검색어 하이라이트 — 현재 활성 매치는 더 진하게
function highlightMatch(text, query, isCurrent) {
  if (!query || !query.trim()) return text;
  const q = query.toLowerCase();
  const lower = text.toLowerCase();
  const parts = [];
  let i = 0,key = 0;
  while (i < text.length) {
    const idx = lower.indexOf(q, i);
    if (idx === -1) {parts.push(text.slice(i));break;}
    if (idx > i) parts.push(text.slice(i, idx));
    parts.push(
      React.createElement('mark', {
        key: key++,
        style: {
          background: isCurrent ? '#FFD23F' : 'rgba(255,210,63,0.4)',
          color: 'inherit', padding: '0 1px', borderRadius: 2
        }
      }, text.slice(idx, idx + q.length))
    );
    i = idx + q.length;
  }
  return parts;
}

function ScreenTranscript({ theme, onConfirm, onCancel }) {
  const t = theme;
  const [playing, setPlaying] = React.useState(false);
  const [playhead, setPlayhead] = React.useState(34); // seconds
  const [activeIdx, setActiveIdx] = React.useState(3); // segment 4
  const [speakerEditFor, setSpeakerEditFor] = React.useState(null); // segment id
  // 화자를 state로 관리 — 추가/삭제/이름·색상 수정 가능
  const [speakers, setSpeakers] = React.useState(SPEAKER_PALETTE.map((s) => ({ ...s })));
  // 전사 구간을 state로 관리 — 텍스트 편집/추가/삭제 가능
  const [segments, setSegments] = React.useState(() => FAKE_TRANSCRIPT.map((s) => ({ ...s })));
  const [editingId, setEditingId] = React.useState(null);
  const [hovering, setHovering] = React.useState(null);
  const [managingSpeakers, setManagingSpeakers] = React.useState(false);
  const [searchOpen, setSearchOpen] = React.useState(false);
  const [searchQuery, setSearchQuery] = React.useState('');
  const [searchIdx, setSearchIdx] = React.useState(0);
  // 검색 매칭: 쿼리가 포함된 segment 인덱스 배열
  const matches = React.useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return [];
    return segments.map((s, i) => ({ i, hit: s.text && s.text.toLowerCase().includes(q) })).
    filter((x) => x.hit).map((x) => x.i);
  }, [segments, searchQuery]);
  React.useEffect(() => {setSearchIdx(0);}, [searchQuery]);
  const TOTAL = 1938; // 32:18 in seconds

  // 화자 인덱스는 segments 안에 들어 있음
  const segSpeakers = segments.map((s) => s.speaker);

  // Auto-advance the playhead when "playing"
  React.useEffect(() => {
    if (!playing) return;
    const id = setInterval(() => setPlayhead((x) => Math.min(TOTAL, x + 1)), 600);
    return () => clearInterval(id);
  }, [playing]);

  // Whichever segment matches the playhead is "active"
  React.useEffect(() => {
    const idx = segments.findIndex((s, i) => {
      const next = segments[i + 1];
      return s.tSec <= playhead && (!next || next.tSec > playhead);
    });
    if (idx >= 0) setActiveIdx(idx);
  }, [playhead, segments]);

  const fmtTime = (s) => {
    const m = Math.floor(s / 60),r = Math.floor(s % 60);
    return `${String(m).padStart(2, '0')}:${String(r).padStart(2, '0')}`;
  };

  // 화자 헬퍼
  const updateSpeaker = (i, patch) => {
    setSpeakers((arr) => arr.map((s, j) => j === i ? { ...s, ...patch } : s));
  };
  const addSpeaker = () => {
    if (speakers.length >= 8) return;
    const usedColors = new Set(speakers.map((s) => s.color));
    const color = SPEAKER_COLORS.find((c) => !usedColors.has(c)) || SPEAKER_COLORS[speakers.length % SPEAKER_COLORS.length];
    const n = speakers.length + 1;
    setSpeakers([...speakers, { name: `화자 ${n}`, short: String(n), color }]);
  };
  const removeSpeaker = (i) => {
    if (speakers.length <= 1) return;
    // 삭제된 화자에 할당된 구간은 0번 화자로 이동
    setSegments((arr) => arr.map((s) => ({ ...s, speaker: s.speaker === i ? 0 : s.speaker > i ? s.speaker - 1 : s.speaker })));
    setSpeakers((arr) => arr.filter((_, j) => j !== i));
  };
  const reassignSegment = (segIdx, newSpeakerIdx) => {
    setSegments((arr) => arr.map((s, i) => i === segIdx ? { ...s, speaker: newSpeakerIdx } : s));
  };

  // 구간 헬퍼
  const updateSegmentText = (segIdx, text) => {
    setSegments((arr) => arr.map((s, i) => i === segIdx ? { ...s, text } : s));
  };
  const removeSegment = (segIdx) => {
    if (segments.length <= 1) return;
    setSegments((arr) => arr.filter((_, i) => i !== segIdx));
    if (editingId === segments[segIdx]?.id) setEditingId(null);
  };
  const insertSegmentAfter = (segIdx) => {
    const cur = segments[segIdx];
    const nxt = segments[segIdx + 1];
    const newTSec = nxt ? Math.floor((cur.tSec + nxt.tSec) / 2) : cur.tSec + 5;
    const m = Math.floor(newTSec / 60),r = Math.floor(newTSec % 60);
    const newT = `${String(m).padStart(2, '0')}:${String(r).padStart(2, '0')}`;
    const newSeg = {
      id: Date.now(),
      t: newT, tSec: newTSec,
      speaker: cur.speaker,
      text: ''
    };
    setSegments((arr) => [...arr.slice(0, segIdx + 1), newSeg, ...arr.slice(segIdx + 1)]);
    setEditingId(newSeg.id);
  };
  const insertSegmentAtEnd = () => {
    const last = segments[segments.length - 1];
    const newTSec = last ? last.tSec + 8 : 0;
    const m = Math.floor(newTSec / 60),r = Math.floor(newTSec % 60);
    const newT = `${String(m).padStart(2, '0')}:${String(r).padStart(2, '0')}`;
    const newSeg = {
      id: Date.now(),
      t: newT, tSec: newTSec,
      speaker: last ? last.speaker : 0,
      text: ''
    };
    setSegments((arr) => [...arr, newSeg]);
    setEditingId(newSeg.id);
  };

  // 발화 비율 계산
  const speakerRatios = React.useMemo(() => {
    const counts = speakers.map(() => 0);
    segments.forEach((s) => {if (counts[s.speaker] !== undefined) counts[s.speaker] += 1;});
    const total = counts.reduce((a, b) => a + b, 0) || 1;
    return counts.map((c) => c / total);
  }, [segments, speakers]);

  // waveform mini
  const waveBars = React.useMemo(() => Array.from({ length: 240 }, (_, i) => {
    const seed = Math.sin(i * 0.41) + Math.cos(i * 0.17) + Math.sin(i * 1.3) * 0.5;
    return 0.18 + Math.abs(seed) * 0.5;
  }), []);

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      {/* Toolbar row */}
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
              <span>32:18</span>
              <span style={{ color: t.ink20 }}>·</span>
              <span>{speakers.length}명</span>
              <span style={{ color: t.ink20 }}>·</span>
              <span>{segments.length}개 구간</span>
              <span style={{ color: t.ink20 }}>·</span>
              <span>신뢰도 96.4%</span>
            </div>
          </div>
        </div>

        <PillButton theme={t} ghost size="sm" icon="search" onClick={() => setSearchOpen((v) => !v)}>찾기</PillButton>
        <PillButton theme={t} ghost size="sm" icon="users" onClick={() => setManagingSpeakers(true)}>
          화자 {speakers.length}명 관리
        </PillButton>
      </div>

      {/* Search bar — toggled by 찾기 */}
      {searchOpen &&
      <div style={{
        flexShrink: 0,
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '10px 24px',
        borderBottom: `0.5px solid ${t.line}`,
        background: t.surfaceMuted
      }}>
          <Icon name="search" size={13} color={t.ink50} />
          <input autoFocus value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Escape') {setSearchOpen(false);setSearchQuery('');}
          if (e.key === 'Enter' && matches.length > 0) {
            const next = e.shiftKey ? (searchIdx - 1 + matches.length) % matches.length : (searchIdx + 1) % matches.length;
            setSearchIdx(next);
            setActiveIdx(matches[next]);
            setPlayhead(segments[matches[next]].tSec);
          }
        }}
        placeholder="전사본에서 찾기…"
        style={{
          flex: 1, border: 'none', outline: 'none',
          background: 'transparent', fontSize: 13, color: t.ink,
          fontFamily: 'inherit', letterSpacing: '-0.005em'
        }} />
          {searchQuery &&
        <span style={{
          fontSize: 11, color: matches.length ? t.ink70 : t.ink35,
          fontFamily: TOKENS.fontMono
        }}>
              {matches.length ? `${searchIdx + 1} / ${matches.length}` : '결과 없음'}
            </span>
        }
          <button onClick={() => {
          if (!matches.length) return;
          const prev = (searchIdx - 1 + matches.length) % matches.length;
          setSearchIdx(prev);setActiveIdx(matches[prev]);setPlayhead(segments[matches[prev]].tSec);
        }}
        disabled={!matches.length}
        style={{
          width: 26, height: 24, borderRadius: 5,
          border: `0.5px solid ${t.line}`, background: t.surface,
          cursor: matches.length ? 'pointer' : 'not-allowed',
          color: t.ink70,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>↑</button>
          <button onClick={() => {
          if (!matches.length) return;
          const next = (searchIdx + 1) % matches.length;
          setSearchIdx(next);setActiveIdx(matches[next]);setPlayhead(segments[matches[next]].tSec);
        }}
        disabled={!matches.length}
        style={{
          width: 26, height: 24, borderRadius: 5,
          border: `0.5px solid ${t.line}`, background: t.surface,
          cursor: matches.length ? 'pointer' : 'not-allowed',
          color: t.ink70,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>↓</button>
          <button onClick={() => {setSearchOpen(false);setSearchQuery('');}}
        style={{
          border: 'none', background: 'transparent', cursor: 'pointer',
          color: t.ink50, fontSize: 16, padding: '0 4px'
        }}>×</button>
        </div>
      }

      {/* Body — two columns: transcript + side panel */}
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {/* Transcript scroll area */}
        <div style={{
          flex: 1, minWidth: 0, padding: '20px 24px 140px',
          overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 4
        }}>
          {segments.map((seg, i) => {
            const segSpeakerIdx = seg.speaker;
            const sp = speakers[segSpeakerIdx] || speakers[0];
            const active = i === activeIdx;
            const isEditing = editingId === seg.id;
            const speakerPickerOpen = speakerEditFor === seg.id;
            return (
              <div key={seg.id}
              onMouseEnter={() => setHovering(seg.id)}
              onMouseLeave={() => setHovering(null)}
              style={{
                display: 'grid',
                gridTemplateColumns: '60px 36px 1fr 88px',
                gap: 12,
                padding: '10px 12px',
                borderRadius: 10,
                background: isEditing ? t.surfaceMuted : active ? t.gradientSoft : 'transparent',
                border: isEditing ? `1px solid ${t.accent}` : '1px solid transparent',
                position: 'relative',
                transition: 'background 0.15s ease'
              }}>
                
                {/* timestamp — click to seek */}
                <button onClick={() => setPlayhead(seg.tSec)}
                title="이 시점으로 이동"
                style={{
                  fontFamily: TOKENS.fontMono, fontSize: 11,
                  color: active ? t.accent : t.ink50,
                  paddingTop: 2, fontWeight: active ? 600 : 400,
                  textAlign: 'right', userSelect: 'none',
                  border: 'none', background: 'transparent',
                  cursor: 'pointer'
                }}>
                  {seg.t}
                </button>

                {/* speaker avatar */}
                <div style={{ position: 'relative' }}>
                  <button
                    onClick={(e) => {e.stopPropagation();setSpeakerEditFor(speakerPickerOpen ? null : seg.id);}}
                    title="화자 변경"
                    style={{
                      width: 28, height: 28, borderRadius: '50%',
                      background: sp.color, border: 'none',
                      color: '#fff', fontWeight: 700, fontSize: 12,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      cursor: 'pointer', fontFamily: 'inherit',
                      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.25)'
                    }}>
                    {sp.short}
                  </button>
                  {speakerPickerOpen &&
                  <div style={{
                    position: 'absolute', top: 32, left: -4, zIndex: 10,
                    background: t.surface,
                    border: `0.5px solid ${t.lineStrong}`,
                    borderRadius: 10, padding: 6,
                    boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
                    display: 'flex', flexDirection: 'column', gap: 2,
                    minWidth: 140
                  }}>
                      <div style={{ fontSize: 10, color: t.ink50, padding: '4px 8px 2px', letterSpacing: '0.04em', textTransform: 'uppercase', fontWeight: 600 }}>이 구간 화자 변경</div>
                      {speakers.map((s2, j) =>
                    <button key={j} onClick={(e) => {e.stopPropagation();reassignSegment(i, j);setSpeakerEditFor(null);}}
                    style={{
                      border: 'none', background: 'transparent',
                      padding: '5px 8px', borderRadius: 6,
                      display: 'flex', alignItems: 'center', gap: 8,
                      cursor: 'pointer', fontFamily: 'inherit', fontSize: 12, color: t.ink
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.background = t.surfaceMuted}
                    onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}>
                      
                          <div style={{
                        width: 18, height: 18, borderRadius: '50%', background: s2.color,
                        color: '#fff', fontSize: 10, fontWeight: 700,
                        display: 'flex', alignItems: 'center', justifyContent: 'center'
                      }}>{s2.short}</div>
                          <span>{s2.name}</span>
                          {segSpeakerIdx === j && <Icon name="check" size={11} color={t.accent} stroke={2.4} style={{ marginLeft: 'auto' }} />}
                        </button>
                    )}
                    </div>
                  }
                </div>

                {/* text + speaker name — click anywhere = edit */}
                <div style={{ minWidth: 0 }} onClick={() => setEditingId(seg.id)}>
                  <div style={{
                    fontSize: 11, fontWeight: 600, color: sp.color,
                    marginBottom: 3, letterSpacing: '-0.005em',
                    display: 'flex', alignItems: 'center', gap: 6
                  }}>
                    <span>{sp.name}</span>
                    {isEditing &&
                    <span style={{
                      fontSize: 9.5, fontWeight: 700, color: t.accent,
                      padding: '1px 5px', borderRadius: 3,
                      background: t.accentSoft,
                      letterSpacing: '0.04em', textTransform: 'uppercase'
                    }}>편집 중</span>
                    }
                  </div>
                  {isEditing ?
                  <textarea
                    value={seg.text}
                    autoFocus
                    onChange={(e) => updateSegmentText(i, e.target.value)}
                    onBlur={() => setEditingId(null)}
                    onKeyDown={(e) => {
                      if (e.key === 'Escape') {e.currentTarget.blur();}
                      if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {e.currentTarget.blur();}
                    }}
                    onClick={(e) => e.stopPropagation()}
                    rows={Math.max(2, seg.text.split('\n').length)}
                    placeholder="이 구간의 발화 내용을 입력하세요…"
                    style={{
                      width: '100%', minHeight: 24,
                      fontSize: 14, lineHeight: 1.65, color: t.ink,
                      letterSpacing: '-0.005em',
                      outline: 'none', border: 'none',
                      background: 'transparent', resize: 'vertical',
                      fontFamily: TOKENS.fontDisplay,
                      padding: 0
                    }} /> :


                  <div style={{
                    fontSize: 14, lineHeight: 1.65,
                    color: seg.text ? t.ink : t.ink35,
                    letterSpacing: '-0.005em',
                    fontFamily: TOKENS.fontDisplay,
                    cursor: 'text',
                    fontStyle: seg.text ? 'normal' : 'italic'
                  }}>{seg.text ? highlightMatch(seg.text, searchQuery, matches[searchIdx] === i) : '클릭하여 텍스트 입력…'}</div>
                  }
                </div>

                {/* Always-visible action rail */}
                <div style={{
                  display: 'flex', gap: 4, alignItems: 'flex-start',
                  paddingTop: 2, justifyContent: 'flex-end',
                  opacity: hovering === seg.id || isEditing ? 1 : 0.45,
                  transition: 'opacity 0.15s ease'
                }} onClick={(e) => e.stopPropagation()}>
                  <SegBtn theme={t} title={isEditing ? '편집 완료' : '편집'}
                  icon={isEditing ? 'check' : 'pencil'}
                  accent={isEditing}
                  onClick={() => setEditingId(isEditing ? null : seg.id)} />
                  {seg.text && seg.text.trim() &&
                  <SegBtn theme={t} title="여기서 재생" icon="play"
                  onClick={() => {setPlayhead(seg.tSec);setPlaying(true);}} />
                  }
                  <SegBtn theme={t} title="아래에 구간 추가" icon="plus"
                  onClick={() => insertSegmentAfter(i)} />
                  <SegBtn theme={t} title="구간 삭제" icon="trash" danger
                  disabled={segments.length <= 1}
                  onClick={() => removeSegment(i)} />
                </div>
              </div>);

          })}

          {/* Add segment at end */}
          <button onClick={insertSegmentAtEnd}
          style={{
            marginTop: 8, padding: '12px',
            border: `1px dashed ${t.lineStrong}`,
            background: 'transparent',
            borderRadius: 10,
            color: t.ink50,
            fontFamily: 'inherit', fontSize: 12.5, fontWeight: 500,
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            transition: 'all 0.15s ease'
          }}
          onMouseEnter={(e) => {e.currentTarget.style.borderColor = t.accent;e.currentTarget.style.color = t.accent;}}
          onMouseLeave={(e) => {e.currentTarget.style.borderColor = t.lineStrong;e.currentTarget.style.color = t.ink50;}}>
            
            <Icon name="plus" size={13} stroke={2.2} />
            <span>새 구간 추가</span>
          </button>

          {/* end-of-transcript marker */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '20px 12px 0',
            fontSize: 11, color: t.ink35, fontFamily: TOKENS.fontMono
          }}>
            <div style={{ flex: 1, height: 1, background: t.line }} />
            <span>{segments.length}개 구간</span>
            <div style={{ flex: 1, height: 1, background: t.line }} />
          </div>
        </div>

        {/* Side panel */}
        <div style={{
          width: 280, flexShrink: 0,
          borderLeft: `0.5px solid ${t.line}`,
          padding: 18, display: 'flex', flexDirection: 'column', gap: 16,
          overflow: 'auto'
        }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: t.ink50, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 8 }}>원본</div>
            <div style={{ fontSize: 11.5, color: t.ink70, fontFamily: TOKENS.fontMono, lineHeight: 1.5, wordBreak: 'break-all' }}>
              2026-05-04 제품팀 스탠드업.m4a
            </div>
          </div>

          <Stat theme={t} label="신뢰도" value="96.4%" sub="Whisper turbo" highlight />

          {/* 화자 관리 패널 */}
          <div style={{ marginTop: 4 }}>
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              marginBottom: 10
            }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: t.ink50, letterSpacing: '0.08em', textTransform: 'uppercase' }}>화자 관리</div>
              <button onClick={addSpeaker} disabled={speakers.length >= 8}
              style={{
                display: 'inline-flex', alignItems: 'center', gap: 3,
                border: 'none', background: 'transparent',
                color: speakers.length >= 8 ? t.ink35 : t.accent,
                fontSize: 11, fontWeight: 600, fontFamily: 'inherit',
                cursor: speakers.length >= 8 ? 'not-allowed' : 'pointer',
                padding: 0
              }}>
                <Icon name="plus" size={11} stroke={2.2} />
                <span>추가</span>
              </button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {speakers.map((s, i) =>
              <SpeakerRow key={i} theme={t} speaker={s} ratio={speakerRatios[i]}
              onChange={(patch) => updateSpeaker(i, patch)}
              onRemove={speakers.length > 1 ? () => removeSpeaker(i) : null} />

              )}
            </div>
            {/* 누적 비율 막대 */}
            <div style={{
              marginTop: 10, height: 6, borderRadius: 3, overflow: 'hidden',
              display: 'flex', background: t.ink10
            }}>
              {speakers.map((s, i) =>
              <div key={i} style={{ width: `${speakerRatios[i] * 100}%`, background: s.color }} />
              )}
            </div>
          </div>

          <div style={{
            marginTop: 4, padding: 12, borderRadius: 10,
            background: t.surfaceMuted, border: `0.5px solid ${t.line}`
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
              <Icon name="sparkle" size={12} color={t.accent} />
              <span style={{ fontSize: 11, fontWeight: 700, color: t.ink70, letterSpacing: '0.04em', textTransform: 'uppercase' }}>다음 단계</span>
            </div>
            <div style={{ fontSize: 12, color: t.ink70, lineHeight: 1.5 }}>
              검토를 마치면 <b style={{ color: t.ink }}>결정·액션 추출</b> 템플릿으로 회의록을 생성합니다.
            </div>
            <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: t.ink50 }}>
              <Icon name="doc" size={12} />
              <span>decision-action.md</span>
              <button style={{
                marginLeft: 'auto', border: 'none', background: 'transparent', color: t.accent,
                fontSize: 11, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit'
              }}>변경</button>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom audio dock */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: t.surface,
        borderTop: `0.5px solid ${t.line}`,
        padding: '12px 24px 14px',
        display: 'flex', alignItems: 'center', gap: 16,
        boxShadow: '0 -2px 14px rgba(0,0,0,0.04)'
      }}>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <button onClick={() => setPlayhead(Math.max(0, playhead - 10))} style={iconBtn(t)}>
            <Icon name="arrowLeft" size={14} />
          </button>
          <button onClick={() => setPlaying((p) => !p)} style={{
            width: 36, height: 36, borderRadius: '50%',
            background: t.gradient, border: 'none', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', boxShadow: '0 2px 6px rgba(224,36,94,0.30)'
          }}>
            <Icon name={playing ? 'pause' : 'play'} size={14} color="#fff" />
          </button>
          <button onClick={() => setPlayhead(Math.min(TOTAL, playhead + 10))} style={iconBtn(t)}>
            <Icon name="arrowRight" size={14} />
          </button>
        </div>

        <div style={{ fontFamily: TOKENS.fontMono, fontSize: 12, color: t.ink, fontVariantNumeric: 'tabular-nums' }}>
          {fmtTime(playhead)} <span style={{ color: t.ink35 }}>/ 32:18</span>
        </div>

        {/* mini wave with playhead */}
        <div style={{ flex: 1, position: 'relative', height: 32, display: 'flex', alignItems: 'center', gap: 1.5 }}
        onClick={(e) => {
          const rect = e.currentTarget.getBoundingClientRect();
          const ratio = (e.clientX - rect.left) / rect.width;
          setPlayhead(Math.round(TOTAL * ratio));
        }}>
          
          {waveBars.map((h, i) => {
            const idx = i / waveBars.length;
            const past = idx < playhead / TOTAL;
            return (
              <div key={i} style={{
                flex: 1,
                height: `${h * 28}px`,
                background: past ? t.accent : t.ink20,
                borderRadius: 1,
                opacity: past ? 0.85 : 0.6
              }} />);

          })}
          {/* playhead line */}
          <div style={{
            position: 'absolute',
            left: `${playhead / TOTAL * 100}%`,
            top: 0, bottom: 0, width: 2,
            background: t.accent2,
            transform: 'translateX(-1px)',
            borderRadius: 1,
            boxShadow: `0 0 6px ${t.accent2}`
          }} />
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 11, color: t.ink50, fontFamily: TOKENS.fontMono }}>1.0×</span>
          <Icon name="sound" size={14} color={t.ink50} />
        </div>

        <div style={{ width: 1, height: 24, background: t.line }} />

        <PillButton theme={t} ghost onClick={onCancel}>다시 시작</PillButton>
        <PillButton theme={t} primary onClick={onConfirm} icon="sparkle">회의록 생성하기</PillButton>
      </div>
    </div>);

}

function iconBtn(t) {
  return {
    width: 30, height: 30, borderRadius: 8,
    background: 'transparent', border: `0.5px solid ${t.line}`,
    color: t.ink70, cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontFamily: 'inherit'
  };
}

function SegBtn({ theme, title, icon, onClick, danger, accent, disabled }) {
  const t = theme;
  const [hover, setHover] = React.useState(false);
  let bg = 'transparent',fg = t.ink70,border = t.line;
  if (accent) {bg = t.accent;fg = '#fff';border = t.accent;} else
  if (hover && !disabled) {
    if (danger) {bg = t.accent2Soft;fg = t.accent2;border = t.accent2;} else
    {bg = t.surfaceMuted;fg = t.ink;border = t.lineStrong;}
  }
  return (
    <button onClick={onClick} title={title} disabled={disabled}
    onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
    style={{
      width: 26, height: 26, borderRadius: 6,
      background: bg, color: fg,
      border: `0.5px solid ${border}`,
      cursor: disabled ? 'not-allowed' : 'pointer',
      opacity: disabled ? 0.35 : 1,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'inherit',
      transition: 'all 0.12s ease'
    }}>
      <Icon name={icon} size={12} stroke={1.8} />
    </button>);

}

function SpeakerChip({ theme, color, name, short, onChange, onColorChange, onRemove }) {
  const t = theme;
  const [editing, setEditing] = React.useState(false);
  const [val, setVal] = React.useState(name);
  const [pickerOpen, setPickerOpen] = React.useState(false);
  React.useEffect(() => setVal(name), [name]);
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '3px 6px 3px 4px', borderRadius: 12,
      background: t.surface, border: `0.5px solid ${t.line}`,
      cursor: editing ? 'text' : 'default',
      position: 'relative'
    }}>
      <button onClick={() => setPickerOpen((v) => !v)}
      title="색상 변경"
      style={{
        width: 18, height: 18, borderRadius: '50%', background: color,
        color: '#fff', fontSize: 10, fontWeight: 700,
        border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'inherit'
      }}>{short}</button>
      {pickerOpen &&
      <div style={{
        position: 'absolute', top: 26, left: 0, zIndex: 20,
        background: t.surface, border: `0.5px solid ${t.lineStrong}`,
        borderRadius: 10, padding: 8,
        boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6
      }}
      onMouseLeave={() => setPickerOpen(false)}>
          {SPEAKER_COLORS.map((c) =>
        <button key={c} onClick={() => {onColorChange && onColorChange(c);setPickerOpen(false);}}
        style={{
          width: 18, height: 18, borderRadius: '50%', background: c,
          border: c === color ? `2px solid ${t.ink}` : `1px solid ${t.line}`,
          cursor: 'pointer'
        }} />
        )}
        </div>
      }
      {editing ?
      <input value={val} autoFocus
      onChange={(e) => setVal(e.target.value)}
      onBlur={() => {onChange(val || name);setEditing(false);}}
      onKeyDown={(e) => {if (e.key === 'Enter') {onChange(val || name);setEditing(false);}}}
      style={{
        border: 'none', outline: 'none', background: 'transparent',
        fontSize: 11.5, color: t.ink, fontFamily: 'inherit', width: 60
      }} /> :


      <span onDoubleClick={() => setEditing(true)} onClick={() => setEditing(true)}
      style={{ fontSize: 11.5, color: t.ink, fontWeight: 500, cursor: 'text' }}>{name}</span>
      }
      {onRemove &&
      <button onClick={onRemove} title="화자 삭제"
      style={{
        width: 14, height: 14, borderRadius: '50%',
        border: 'none', background: 'transparent', color: t.ink50,
        cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: 0, marginLeft: 1
      }}
      onMouseEnter={(e) => e.currentTarget.style.color = t.accent2}
      onMouseLeave={(e) => e.currentTarget.style.color = t.ink50}>
        
          <Icon name="x" size={10} stroke={2.2} />
        </button>
      }
    </div>);

}

function SpeakerRow({ theme, speaker, ratio, onChange, onRemove }) {
  const t = theme;
  const [editing, setEditing] = React.useState(false);
  const [pickerOpen, setPickerOpen] = React.useState(false);
  const [val, setVal] = React.useState(speaker.name);
  React.useEffect(() => setVal(speaker.name), [speaker.name]);
  const commit = () => {
    const nm = val.trim() || speaker.name;
    onChange({ name: nm, short: nm.charAt(0) || speaker.short });
    setEditing(false);
  };
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      padding: '6px 8px', borderRadius: 8,
      background: t.surface, border: `0.5px solid ${t.line}`,
      position: 'relative'
    }}>
      <button onClick={() => setPickerOpen((v) => !v)} title="색상 변경"
      style={{
        width: 22, height: 22, borderRadius: '50%', background: speaker.color,
        color: '#fff', fontSize: 10, fontWeight: 700,
        border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'inherit', flexShrink: 0,
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.25)'
      }}>{speaker.short}</button>
      {pickerOpen &&
      <div style={{
        position: 'absolute', top: 32, left: 0, zIndex: 20,
        background: t.surface, border: `0.5px solid ${t.lineStrong}`,
        borderRadius: 10, padding: 8,
        boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6
      }}
      onMouseLeave={() => setPickerOpen(false)}>
          {SPEAKER_COLORS.map((c) =>
        <button key={c} onClick={() => {onChange({ color: c });setPickerOpen(false);}}
        style={{
          width: 18, height: 18, borderRadius: '50%', background: c,
          border: c === speaker.color ? `2px solid ${t.ink}` : `1px solid ${t.line}`,
          cursor: 'pointer'
        }} />
        )}
        </div>
      }
      <div style={{ flex: 1, minWidth: 0 }}>
        {editing ?
        <input value={val} autoFocus
        onChange={(e) => setVal(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {if (e.key === 'Enter') commit();if (e.key === 'Escape') {setVal(speaker.name);setEditing(false);}}}
        style={{
          border: 'none', outline: 'none', background: 'transparent',
          fontSize: 12.5, color: t.ink, fontFamily: 'inherit', width: '100%',
          fontWeight: 500
        }} /> :


        <div onClick={() => setEditing(true)}
        style={{ fontSize: 12.5, color: t.ink, fontWeight: 500, cursor: 'text', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {speaker.name}
          </div>
        }
        <div style={{ fontSize: 10.5, color: t.ink50, fontFamily: TOKENS.fontMono, fontVariantNumeric: 'tabular-nums', marginTop: 1 }}>
          {Math.round(ratio * 100)}% 발화
        </div>
      </div>
      {onRemove &&
      <button onClick={onRemove} title="화자 삭제"
      style={{
        width: 22, height: 22, borderRadius: 6,
        border: 'none', background: 'transparent', color: t.ink50,
        cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: 0, flexShrink: 0
      }}
      onMouseEnter={(e) => {e.currentTarget.style.color = t.accent2;e.currentTarget.style.background = t.accent2Soft;}}
      onMouseLeave={(e) => {e.currentTarget.style.color = t.ink50;e.currentTarget.style.background = 'transparent';}}>
        
          <Icon name="trash" size={12} />
        </button>
      }
    </div>);

}

function Stat({ theme, label, value, sub, highlight }) {
  const t = theme;
  return (
    <div>
      <div style={{ fontSize: 10.5, color: t.ink50, marginBottom: 2, letterSpacing: '0.02em' }}>{label}</div>
      <div style={{
        fontSize: 18, fontWeight: 600, color: highlight ? t.accent : t.ink,
        letterSpacing: '-0.01em', fontFamily: TOKENS.fontDisplay
      }}>{value}</div>
      <div style={{ fontSize: 11, color: t.ink50, marginTop: 1 }}>{sub}</div>
    </div>);

}

function SpeakerBar({ theme, segments }) {
  const t = theme;
  return (
    <div>
      <div style={{
        height: 8, borderRadius: 4, overflow: 'hidden',
        display: 'flex', background: t.ink10
      }}>
        {segments.map((s, i) =>
        <div key={i} style={{ width: `${s.ratio * 100}%`, background: s.color }} />
        )}
      </div>
      <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 4 }}>
        {segments.map((s, i) =>
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11.5 }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: s.color }} />
            <span style={{ color: t.ink70, flex: 1 }}>{s.name}</span>
            <span style={{ color: t.ink50, fontFamily: TOKENS.fontMono, fontVariantNumeric: 'tabular-nums' }}>{Math.round(s.ratio * 100)}%</span>
          </div>
        )}
      </div>
    </div>);

}

window.ScreenTranscript = ScreenTranscript;