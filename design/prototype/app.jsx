// app.jsx — root that wires screens, sidebar, toolbar, tweaks panel

const { useState, useEffect } = React;

function App() {
  const [t, setTweak] = useTweaks(window.TWEAK_DEFAULTS);
  const theme = useTheme(t.theme);

  const [screen, setScreen] = useState(t.screen || 'drop');
  const [selectedMeeting, setSelectedMeeting] = useState(t.selectedMeeting || 'current');
  const [pickerOpen, setPickerOpen] = useState(false);
  const [pickerFile, setPickerFile] = useState(null);
  const [isTargeted, setTargeted] = useState(false);

  // sync screen back to tweaks
  useEffect(() => {
    if (t.screen !== screen) setTweak('screen', screen);
  // eslint-disable-next-line
  }, [screen]);
  useEffect(() => {
    if (t.screen && t.screen !== screen) setScreen(t.screen);
  // eslint-disable-next-line
  }, [t.screen]);

  const startFromFile = () => {
    setPickerFile('새 음성 메모.m4a');
    setPickerOpen(true);
  };
  const onPick = (tplId) => {
    setPickerOpen(false);
    setScreen('progress');
  };

  // Toolbar per screen
  const toolbar = (() => {
    switch (screen) {
      case 'drop':
        return <Toolbar theme={theme} title="새 회의록" subtitle="음성 메모를 끌어오세요" right={
          <>
            <PillButton theme={theme} ghost size="sm" icon="folder">파일 열기…</PillButton>
            <PillButton theme={theme} ghost size="sm" icon="gear" onClick={() => setScreen('settings')} />
          </>
        } />;
      case 'progress':
        return <Toolbar theme={theme} breadcrumb="새 회의록" title="처리 중" subtitle="제품팀 스탠드업.m4a" right={
          <PillButton theme={theme} ghost size="sm" icon="x" onClick={() => setScreen('drop')}>취소</PillButton>
        } />;
      case 'transcript':
        return <Toolbar theme={theme} breadcrumb="새 회의록 → 1단계" title="전사본 검토" subtitle="화자와 문장을 다듬어주세요" right={
          <>
            <PillButton theme={theme} ghost size="sm" icon="x" onClick={() => setScreen('drop')}>취소</PillButton>
            <PillButton theme={theme} primary size="sm" icon="sparkle" onClick={() => setScreen('minutes')}>회의록 생성</PillButton>
          </>
        } />;
      case 'minutes':
        return <Toolbar theme={theme} breadcrumb="새 회의록 → 2단계" title="회의록 검토" subtitle="내용을 확인하고 내보내세요" right={
          <PillButton theme={theme} ghost size="sm" icon="arrowLeft" onClick={() => setScreen('transcript')}>전사본으로</PillButton>
        } />;
      case 'library':
        return <Toolbar theme={theme} title="라이브러리" subtitle="이전에 처리한 회의록" right={
          <PillButton theme={theme} primary size="sm" icon="plus" onClick={() => setScreen('drop')}>새 회의록</PillButton>
        } />;
      case 'templates':
        return <Toolbar theme={theme} title="템플릿" subtitle="회의록 양식 관리" right={null} />;
      case 'settings':
        return <Toolbar theme={theme} title="설정" subtitle="모델·저장·단축키" right={null} />;
      default:
        return null;
    }
  })();

  const content = (() => {
    switch (screen) {
      case 'drop':
        return <ScreenDrop theme={theme}
          onPickFile={startFromFile}
          onStart={(id) => { setSelectedMeeting(id); setScreen('minutes'); }}
          isTargeted={isTargeted} setTargeted={setTargeted} />;
      case 'progress':
        return <ScreenProgress theme={theme} fileName="2026-05-04 제품팀 스탠드업.m4a"
          onCancel={() => setScreen('drop')} />;
      case 'transcript':
        return <ScreenTranscript theme={theme}
          onConfirm={() => setScreen('minutes')}
          onCancel={() => setScreen('drop')} />;
      case 'minutes':
        return <ScreenMinutes theme={theme} onNew={() => setScreen('drop')} />;
      case 'library':
        return <ScreenLibrary theme={theme} onOpen={(id) => { setSelectedMeeting(id); setScreen('minutes'); }} />;
      case 'templates':
        return <ScreenTemplates theme={theme} />;
      case 'settings':
        return <ScreenSettings theme={theme} />;
      default:
        return null;
    }
  })();

  return (
    <>
      <WindowShell
        theme={theme}
        sidebar={<Sidebar theme={theme} themeName={t.theme}
          library={FAKE_LIBRARY}
          selectedId={(screen === 'minutes' || screen === 'transcript' || screen === 'progress') ? selectedMeeting : null}
          onSelect={(id) => { setSelectedMeeting(id); setScreen('minutes'); }}
          onNew={() => setScreen('drop')}
          onNav={(id) => setScreen(id)}
          currentNav={screen}
        />}
        toolbar={toolbar}
      >
        {content}
        {pickerOpen && (
          <TemplatePickerSheet theme={theme} fileName={pickerFile}
            onPick={onPick} onCancel={() => setPickerOpen(false)} />
        )}
      </WindowShell>

      <TweaksPanel>
        <TweakSection label="화면" />
        <TweakSelect label="현재 화면" value={t.screen}
          options={[
            { value: 'drop', label: '시작 (드롭존)' },
            { value: 'progress', label: '처리 중' },
            { value: 'transcript', label: '전사본 검토' },
            { value: 'minutes', label: '회의록' },
            { value: 'library', label: '라이브러리' },
            { value: 'templates', label: '템플릿' },
            { value: 'settings', label: '설정' },
          ]}
          onChange={(v) => { setTweak('screen', v); setScreen(v); }} />

        <TweakSection label="테마" />
        <TweakRadio label="모드" value={t.theme}
          options={[
            { value: 'warm', label: 'Warm' },
            { value: 'mono', label: 'Mono' },
            { value: 'dark', label: 'Dark' },
          ]}
          onChange={(v) => setTweak('theme', v)} />

        <TweakSection label="플로우" />
        <TweakButton label="전체 흐름 데모" onClick={async () => {
          const seq = ['drop', 'progress', 'transcript', 'minutes'];
          for (const s of seq) {
            setScreen(s); setTweak('screen', s);
            await new Promise(r => setTimeout(r, 1800));
          }
        }}>▶ 재생</TweakButton>
      </TweaksPanel>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
