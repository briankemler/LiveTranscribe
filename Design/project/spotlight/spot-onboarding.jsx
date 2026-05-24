// Spotlight — Onboarding (3 steps) + Home

const { useState } = React;

// ─── Onboarding ──────────────────────────────────────────────
const OnboardingScreen = ({ onDone }) => {
  const [step, setStep] = useState(0);
  const steps = [
    {
      kicker: 'LIVE TRANSCRIBE',
      title: <>Every voice.<br/><em style={{ color: T.peach, fontStyle: 'italic' }}>Every sound.</em></>,
      body: 'Captions in real time, on this phone, for free, forever.',
      cta: 'Continue',
      visual: 'hero',
    },
    {
      kicker: 'PRIVACY',
      title: <>It all stays<br/><em style={{ color: T.peach, fontStyle: 'italic' }}>here.</em></>,
      body: 'The model lives in the app. Your conversations never leave your phone — not even to us.',
      cta: 'Allow microphone',
      visual: 'privacy',
    },
    {
      kicker: 'HOW IT WORKS',
      title: <>Hold up.<br/><em style={{ color: T.peach, fontStyle: 'italic' }}>Read along.</em></>,
      body: 'Set the phone between you and a speaker. Tap start. Captions appear in seconds.',
      cta: "I'm ready",
      visual: 'preview',
    },
  ];
  const s = steps[step];

  const next = () => step < 2 ? setStep(step + 1) : onDone();

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
      <div style={{ padding: '0 28px', display: 'flex', flexDirection: 'column', flex: 1 }}>
        <div style={{ marginTop: 32, fontSize: 11, fontWeight: 700, letterSpacing: 2, color: T.peach }}>{s.kicker}</div>
        <div key={step} className="sp-fade-in" style={{
          fontFamily: T.fontDisplay, fontSize: 56, fontWeight: 500, lineHeight: 0.98,
          letterSpacing: -2, color: T.ink, marginTop: 18,
        }}>{s.title}</div>
        <div className="sp-fade-in" style={{ fontSize: 17, lineHeight: 1.5, color: T.inkSoft, marginTop: 20, maxWidth: 320 }}>
          {s.body}
        </div>

        {/* Visual */}
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '28px 0' }}>
          {s.visual === 'hero' && (
            <div style={{ position: 'relative', width: '100%', display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div style={{ padding: 16, borderRadius: 16, background: T.surface, borderLeft: `3px solid ${T.spkB}`, opacity: 0.55 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: T.spkB, letterSpacing: 0.5, textTransform: 'uppercase' }}>Maya</div>
                <div style={{ fontSize: 14, color: T.inkSoft, marginTop: 4 }}>I had the most ridiculous run this morning.</div>
              </div>
              <div style={{ padding: 16, borderRadius: 16, background: T.surfaceHi, borderLeft: `3px solid ${T.spkB}`, boxShadow: '0 8px 24px rgba(0,0,0,0.3)' }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: T.spkB, letterSpacing: 0.5, textTransform: 'uppercase' }}>Maya · NOW</div>
                <div style={{ fontFamily: T.fontDisplay, fontSize: 22, fontWeight: 500, lineHeight: 1.25, color: T.ink, marginTop: 6, letterSpacing: -0.3 }}>
                  A goose chased me through the park.
                </div>
              </div>
              <div style={{ display: 'inline-flex', alignSelf: 'flex-start', alignItems: 'center', gap: 6, padding: '5px 10px', borderRadius: 999, background: T.peachSoft, color: T.peach, fontSize: 11, fontWeight: 600 }}>
                <SpIcon name="volume" size={11} color={T.peach} /> laughter
              </div>
            </div>
          )}
          {s.visual === 'privacy' && (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
              <div style={{
                width: 120, height: 120, borderRadius: 60,
                background: T.surface, border: `1px solid ${T.lineHi}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
              }}>
                <SpIcon name="lock" size={48} color={T.peach} strokeWidth={1.6} />
                <div style={{ position: 'absolute', inset: -10, borderRadius: 70, border: `1px solid ${T.peachSoft}` }} />
                <div style={{ position: 'absolute', inset: -22, borderRadius: 80, border: `1px solid ${T.peachSoft}`, opacity: 0.5 }} />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-start' }}>
                {[
                  ['Audio processed on-device', 'cpu'],
                  ['Works offline, no account', 'wind'],
                  ['You choose what to save', 'star'],
                ].map(([t, ic]) => (
                  <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13, color: T.inkSoft }}>
                    <SpIcon name={ic} size={14} color={T.peach} />
                    {t}
                  </div>
                ))}
              </div>
            </div>
          )}
          {s.visual === 'preview' && (
            <div style={{ width: '100%', padding: '20px 0', position: 'relative' }}>
              <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 14 }}>
                <div style={{
                  width: 64, height: 64, borderRadius: 32,
                  background: T.peach, color: T.bg,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: `0 0 0 8px ${T.peachSoft}, 0 0 0 16px rgba(232,152,120,0.08)`,
                }} className="sp-pulse">
                  <SpIcon name="mic" size={28} color={T.bg} strokeWidth={2.2} />
                </div>
              </div>
              <div style={{ textAlign: 'center', fontSize: 12, color: T.inkMute, fontWeight: 500 }}>tap and start talking</div>
            </div>
          )}
        </div>

        {/* dots */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 16 }}>
          {[0, 1, 2].map(i => (
            <div key={i} style={{
              width: i === step ? 24 : 6, height: 6, borderRadius: 3,
              background: i === step ? T.peach : T.lineHi, transition: 'all 0.3s',
            }} />
          ))}
        </div>

        <PrimaryBtn full onClick={next}>{s.cta}</PrimaryBtn>
        <button onClick={onDone} style={{
          marginTop: 10, marginBottom: 16, height: 36, background: 'transparent', border: 'none',
          color: T.inkMute, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer',
        }}>{step < 2 ? 'Skip' : ''}</button>
      </div>
    </div>
  );
};

// ─── Home ────────────────────────────────────────────────────
const HomeScreen = ({ onStart, onHistory, onSettings, recents }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink, overflow: 'hidden' }}>
    <TopBar
      left={<div style={{ paddingLeft: 8, fontSize: 12, fontWeight: 700, letterSpacing: 2, color: T.peach }}>LIVE TRANSCRIBE</div>}
      right={<IconBtn name="settings" onClick={onSettings} color={T.inkSoft} />}
    />

    <div style={{ padding: '4px 24px 16px' }}>
      <div style={{
        fontFamily: T.fontDisplay, fontSize: 44, fontWeight: 500,
        letterSpacing: -1.6, lineHeight: 1, color: T.ink,
      }}>
        Ready when<br/>
        <em style={{ color: T.peach, fontStyle: 'italic' }}>you are.</em>
      </div>
    </div>

    {/* Big start button */}
    <div style={{ padding: '0 16px 14px' }}>
      <button onClick={() => onStart('11')} style={{
        width: '100%', padding: '22px 22px',
        borderRadius: 24, border: 'none',
        background: T.surfaceHi, color: T.ink,
        cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
        display: 'flex', alignItems: 'center', gap: 16,
        boxShadow: '0 8px 28px rgba(0,0,0,0.4)',
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: 28,
          background: T.peach, color: T.bg,
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <SpIcon name="mic" size={26} color={T.bg} strokeWidth={2.4} />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 19, fontWeight: 700, letterSpacing: -0.2 }}>Start listening</div>
          <div style={{ fontSize: 12, color: T.inkSoft, marginTop: 3 }}>Auto-detect speakers · 96 sounds</div>
        </div>
        <SpIcon name="arrow" size={20} color={T.ink} strokeWidth={2.2} />
      </button>
    </div>

    {/* Mode selector */}
    <div style={{ padding: '0 16px', display: 'flex', gap: 10, marginBottom: 18 }}>
      {[
        { k: '11', i: 'person', t: '1:1', s: 'two voices' },
        { k: 'group', i: 'people', t: 'Group', s: '3+ voices' },
      ].map((m) => (
        <button key={m.k} onClick={() => onStart(m.k)} style={{
          flex: 1, padding: '14px 14px', textAlign: 'left',
          borderRadius: 18, background: T.surface,
          border: `1px solid ${T.line}`, color: T.ink,
          cursor: 'pointer', fontFamily: 'inherit',
        }}>
          <SpIcon name={m.i} size={18} color={T.peach} />
          <div style={{ fontSize: 14, fontWeight: 700, marginTop: 8 }}>{m.t}</div>
          <div style={{ fontSize: 11, color: T.inkMute, marginTop: 1 }}>{m.s}</div>
        </button>
      ))}
    </div>

    {/* Recent */}
    <div style={{ padding: '0 16px', flex: 1, overflowY: 'auto' }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 10,
      }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.inkMute }}>RECENT</div>
        <button onClick={onHistory} style={{ background: 'transparent', border: 'none', color: T.peach, fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit' }}>See all →</button>
      </div>
      {recents.map((r, i) => (
        <button key={i} onClick={() => r.onOpen && r.onOpen()} style={{
          width: '100%', padding: '12px 14px', borderRadius: 12,
          background: T.surface, marginBottom: 8, color: T.ink,
          border: `1px solid ${T.line}`, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 600 }}>{r.title}</div>
            <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>{r.meta}</div>
          </div>
          {r.urgent && (
            <div style={{ padding: '2px 7px', borderRadius: 999, background: T.alertSoft, color: T.alert, fontSize: 10, fontWeight: 700, letterSpacing: 0.5 }}>ALERT</div>
          )}
          <SpIcon name="arrow" size={16} color={T.inkMute} />
        </button>
      ))}
    </div>

    <div style={{
      padding: '12px 20px', flexShrink: 0,
      display: 'flex', alignItems: 'center', gap: 8,
      borderTop: `1px solid ${T.line}`,
      fontSize: 11, color: T.inkMute,
    }}>
      <SpIcon name="cpu" size={12} color={T.peach} strokeWidth={2.4} />
      <span>On-device · nothing leaves your phone</span>
    </div>
  </div>
);

Object.assign(window, { OnboardingScreen, HomeScreen });
