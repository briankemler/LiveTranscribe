// Direction C — "Speaker stage"
// Speaker-forward: latest speaker takes the stage with their name as a banner.
// Sound recognition as floating chip over a sound-wave timeline at top.
// Bold, confident, expressive type.

const cStyles = {
  page: {
    fontFamily: TOKENS.fontUI,
    background: TOKENS.bgSoft,
    color: TOKENS.ink,
    height: '100%',
    display: 'flex', flexDirection: 'column',
  },
  topbar: {
    height: 48, padding: '0 12px',
    display: 'flex', alignItems: 'center', gap: 8,
  },
  iconBtn: {
    width: 40, height: 40, borderRadius: 20, border: 'none',
    background: 'transparent', cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  },
  // Sound timeline at top
  soundTimeline: {
    margin: '0 12px 8px',
    padding: '10px 14px',
    borderRadius: 14,
    background: TOKENS.surface,
    border: `1px solid ${TOKENS.hairline}`,
    display: 'flex', alignItems: 'center', gap: 10,
  },
  // Stage area
  stage: {
    flex: 1, overflowY: 'auto',
    padding: '8px 12px 120px',
    display: 'flex', flexDirection: 'column', gap: 10,
  },
  speakerCard: {
    padding: '14px 16px',
    borderRadius: 18,
    background: TOKENS.surface,
    border: `1px solid ${TOKENS.hairline}`,
    position: 'relative',
  },
  speakerCardActive: {
    borderColor: 'transparent',
    boxShadow: '0 4px 16px rgba(42,34,28,0.06)',
  },
  speakerHeader: {
    display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8,
  },
  speakerName: {
    fontSize: 13, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase',
  },
  speakerText: {
    fontSize: 24, lineHeight: 1.35, color: TOKENS.ink,
    fontWeight: 400, letterSpacing: -0.2,
  },
  speakerTextActive: {
    fontFamily: TOKENS.fontDisplay,
    fontSize: 32, fontWeight: 500, letterSpacing: -0.5, lineHeight: 1.25,
  },
  controlBar: {
    position: 'absolute', bottom: 12, left: 12, right: 12,
    height: 64, borderRadius: 32,
    background: TOKENS.ink, color: '#fff',
    display: 'flex', alignItems: 'center', padding: '0 8px 0 16px', gap: 12,
  },
};

const C_StageCard = ({ name, color, text, active, partial, sound }) => (
  <div style={{
    ...cStyles.speakerCard,
    ...(active ? cStyles.speakerCardActive : {}),
    background: active ? TOKENS.surface : TOKENS.surface,
    opacity: active ? 1 : 0.55,
    borderLeft: `4px solid ${color}`,
  }}>
    <div style={cStyles.speakerHeader}>
      <div style={{
        width: 28, height: 28, borderRadius: 14,
        background: color, color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 12, fontWeight: 700,
      }}>{name[0]}</div>
      <div style={{ ...cStyles.speakerName, color }}>{name}</div>
      {active && (
        <div style={{ display: 'flex', gap: 2, marginLeft: 'auto' }}>
          {[8, 14, 6, 12, 10].map((h, i) => (
            <div key={i} style={{
              width: 2.5, height: h, borderRadius: 1.5, background: color,
              opacity: 0.5 + (i % 2) * 0.4,
            }} />
          ))}
        </div>
      )}
    </div>
    <div style={{ ...cStyles.speakerText, ...(active ? cStyles.speakerTextActive : {}) }}>
      {text}{partial && <span style={{ opacity: 0.4 }}>…</span>}
    </div>
    {sound && (
      <div style={{
        marginTop: 10, paddingTop: 10, borderTop: `1px dashed ${TOKENS.hairline}`,
        display: 'flex', alignItems: 'center', gap: 8,
        fontSize: 13, color: TOKENS.inkSoft, fontStyle: 'italic',
      }}>
        <LTIcon name={sound.icon} size={14} />
        {sound.label}
      </div>
    )}
  </div>
);

// ── Onboarding ────────────────────────────────────────────────
const C_Onboarding = () => (
  <div style={{
    ...cStyles.page, background: TOKENS.ink, color: '#fff',
    display: 'flex', flexDirection: 'column',
  }}>
    <div style={{ flex: 1, padding: '60px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 64, fontWeight: 500, lineHeight: 0.95,
        letterSpacing: -2.4, marginBottom: 24, color: '#fff',
      }}>
        Every<br/>voice.<br/>
        <span style={{ color: TOKENS.peach, fontStyle: 'italic' }}>Every sound.</span>
      </div>
      <div style={{ fontSize: 18, lineHeight: 1.5, color: 'rgba(245,237,224,0.7)', marginBottom: 'auto', maxWidth: 320 }}>
        Captions in real time, on this phone, for free, forever.
      </div>

      {/* mini speaker preview */}
      <div style={{
        margin: '32px 0 24px',
        padding: 16, borderRadius: 16,
        background: 'rgba(255,255,255,0.06)',
        border: `1px solid rgba(255,255,255,0.1)`,
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 22, height: 22, borderRadius: 11, background: TOKENS.spkB, color: '#fff', fontSize: 10, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>M</div>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, color: TOKENS.spkB, textTransform: 'uppercase' }}>Maya</div>
        </div>
        <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 20, lineHeight: 1.3, color: '#fff' }}>
          The model lives <em style={{ color: TOKENS.peach, fontStyle: 'italic' }}>here</em>, on this phone.
        </div>
        <div style={{ display: 'inline-flex', alignSelf: 'flex-start', alignItems: 'center', gap: 6, padding: '4px 10px', borderRadius: 999, background: 'rgba(232,152,120,0.15)', color: TOKENS.peach, fontSize: 12, fontWeight: 500 }}>
          <LTIcon name="music" size={11} color={TOKENS.peach} /> coffee shop chatter
        </div>
      </div>

      <button style={{
        height: 56, borderRadius: 28,
        background: TOKENS.peach, color: TOKENS.ink,
        fontSize: 17, fontWeight: 700, border: 'none', cursor: 'pointer',
        fontFamily: 'inherit',
      }}>
        Start listening
      </button>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 16 }}>
        <div style={{ width: 6, height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.2)' }} />
        <div style={{ width: 6, height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.2)' }} />
        <div style={{ width: 24, height: 6, borderRadius: 3, background: TOKENS.peach }} />
      </div>
    </div>
  </div>
);

// ── Sound timeline component ──────────────────────────────────
const SoundTimeline = ({ items, urgent }) => (
  <div style={{
    ...cStyles.soundTimeline,
    ...(urgent ? { background: TOKENS.alertBg, border: `1.5px solid ${TOKENS.alert}` } : {}),
  }}>
    <LTIcon name="ear" size={16} color={urgent ? TOKENS.alert : TOKENS.inkMute} />
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, color: urgent ? TOKENS.alert : TOKENS.inkMute, textTransform: 'uppercase' }}>
      {urgent ? 'Alert' : 'Sounds'}
    </div>
    <div style={{ display: 'flex', gap: 6, flex: 1, overflowX: 'auto', alignItems: 'center' }}>
      {items.map((s, i) => {
        const colors = {
          ambient: { bg: TOKENS.ambientBg, fg: TOKENS.inkSoft },
          alert: { bg: TOKENS.alert, fg: '#fff' },
          social: { bg: TOKENS.socialBg, fg: TOKENS.social },
        }[s.tone];
        return (
          <div key={i} style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '5px 10px', borderRadius: 999,
            background: colors.bg, color: colors.fg,
            fontSize: 12, fontWeight: 600, flexShrink: 0,
            ...(s.strong ? { boxShadow: `0 0 0 2px ${TOKENS.alert}` } : {}),
          }}>
            <LTIcon name={s.icon} size={12} color={colors.fg} strokeWidth={2.2} />
            {s.label}
          </div>
        );
      })}
    </div>
  </div>
);

// ── Live 1:1 ──────────────────────────────────────────────────
const C_Live11 = () => (
  <div style={{ ...cStyles.page, position: 'relative' }}>
    <div style={cStyles.topbar}>
      <button style={cStyles.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 15, fontWeight: 600 }}>Coffee with Maya</div>
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 6,
        padding: '4px 10px', borderRadius: 999,
        background: TOKENS.peachSoft, color: TOKENS.peachDeep,
        fontSize: 11, fontWeight: 700, letterSpacing: 0.5,
      }}>
        <LTIcon name="cpu" size={10} color={TOKENS.peachDeep} strokeWidth={2.4} />
        ON-DEVICE
      </div>
    </div>

    <SoundTimeline items={[
      { icon: 'music', label: 'jazz · soft', tone: 'ambient' },
      { icon: 'volume', label: 'laughter', tone: 'social' },
      { icon: 'wind', label: 'espresso hiss', tone: 'ambient' },
    ]} />

    <div style={cStyles.stage}>
      <C_StageCard name="Maya" color={TOKENS.spkB}
        text="So I switched to working from the café most mornings." />
      <C_StageCard name="You" color={TOKENS.spkA}
        text="Is it not too loud?" />
      <C_StageCard name="Maya" color={TOKENS.spkB} active partial
        text="Honestly the background noise helps me focus. And the espresso is unreal" />
    </div>

    <div style={cStyles.controlBar}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
        {Array.from({ length: 14 }).map((_, i) => (
          <div key={i} style={{ width: 3, height: 4 + Math.abs(Math.sin(i * 0.5)) * 18, borderRadius: 2, background: TOKENS.peach, opacity: 0.5 + (i % 3) * 0.2 }} />
        ))}
      </div>
      <div style={{ flex: 1, fontSize: 13, fontVariantNumeric: 'tabular-nums', opacity: 0.7 }}>00:08:42</div>
      <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', background: 'rgba(255,255,255,0.12)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="keyboard" size={16} color="#fff" />
      </button>
      <button style={{ width: 48, height: 48, borderRadius: 24, border: 'none', background: TOKENS.peach, color: TOKENS.ink, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="pause" size={20} color={TOKENS.ink} strokeWidth={2.4} />
      </button>
    </div>
  </div>
);

// ── Sound alert ───────────────────────────────────────────────
const C_SoundAlert = () => (
  <div style={{ ...cStyles.page, position: 'relative' }}>
    <div style={cStyles.topbar}>
      <button style={cStyles.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 15, fontWeight: 600 }}>At home</div>
    </div>

    <SoundTimeline urgent items={[
      { icon: 'bell', label: 'Smoke alarm', tone: 'alert', strong: true },
      { icon: 'music', label: 'kettle', tone: 'ambient' },
    ]} />

    {/* Hero alert card */}
    <div style={{
      margin: '4px 12px 8px',
      padding: 20, borderRadius: 20,
      background: TOKENS.alert,
      color: '#fff',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', top: -20, right: -20,
        width: 120, height: 120, borderRadius: 60,
        background: 'rgba(255,255,255,0.08)',
      }} />
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14, position: 'relative' }}>
        <div style={{
          width: 52, height: 52, borderRadius: 26,
          background: 'rgba(255,255,255,0.15)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <LTIcon name="bell" size={28} color="#fff" strokeWidth={2.2} />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, opacity: 0.7, marginBottom: 4 }}>SOUND DETECTED</div>
          <div style={{
            fontFamily: TOKENS.fontDisplay,
            fontSize: 32, fontWeight: 600, letterSpacing: -0.6, lineHeight: 1, marginBottom: 6,
          }}>Smoke alarm</div>
          <div style={{ fontSize: 13, opacity: 0.85 }}>Continuous · loud · nearby · 96%</div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
        <button style={{
          flex: 1, height: 40, borderRadius: 20,
          background: 'rgba(255,255,255,0.15)', color: '#fff',
          border: 'none', fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
        }}>Dismiss</button>
        <button style={{
          flex: 1, height: 40, borderRadius: 20,
          background: '#fff', color: TOKENS.alert,
          border: 'none', fontSize: 13, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
        }}>I see it</button>
      </div>
    </div>

    <div style={cStyles.stage}>
      <C_StageCard name="Sam" color={TOKENS.spkB}
        text="I'll grab the kettle, you want tea?" />
      <C_StageCard name="Sam" color={TOKENS.spkB} active partial
        text="Wait — that's the kitchen, hold on" />
    </div>
  </div>
);

// ── Group ─────────────────────────────────────────────────────
const C_Group = () => (
  <div style={{ ...cStyles.page, position: 'relative' }}>
    <div style={cStyles.topbar}>
      <button style={cStyles.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 15, fontWeight: 600 }}>Tuesday dinner</div>
        <div style={{ fontSize: 11, color: TOKENS.inkSoft }}>4 voices · 23:18</div>
      </div>
      <button style={cStyles.iconBtn}><LTIcon name="people" size={20} /></button>
    </div>

    <SoundTimeline items={[
      { icon: 'volume', label: 'cheering', tone: 'social' },
      { icon: 'music', label: 'dishes', tone: 'ambient' },
    ]} />

    <div style={cStyles.stage}>
      <C_StageCard name="Jordan" color={TOKENS.spkC}
        text="Wait, you actually finished the marathon?" />
      <C_StageCard name="Maya" color={TOKENS.spkB}
        text="Four hours twelve. Knees still hate me." />
      <C_StageCard name="Priya" color={TOKENS.spkD}
        text="Okay but the real question is what's for dessert." />
      <C_StageCard name="Jordan" color={TOKENS.spkC} active partial
        text="You're a hero, I'll grab plates"
        sound={{ icon: 'music', label: 'dishes clinking nearby' }} />
    </div>
  </div>
);

// ── Type-to-speak ─────────────────────────────────────────────
const C_TypeToSpeak = () => (
  <div style={{ ...cStyles.page, position: 'relative' }}>
    <div style={cStyles.topbar}>
      <button style={cStyles.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 15, fontWeight: 600 }}>Coffee with Maya</div>
    </div>

    <div style={{ padding: '0 12px' }}>
      <C_StageCard name="Maya" color={TOKENS.spkB}
        text="What do you want to do this weekend?" />
    </div>

    {/* Compose card */}
    <div style={{
      margin: '12px 12px 0',
      padding: 18, borderRadius: 20,
      background: TOKENS.ink, color: '#fff',
      position: 'relative',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <div style={{
          width: 24, height: 24, borderRadius: 12,
          background: TOKENS.peach,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <LTIcon name="volume" size={12} color={TOKENS.ink} strokeWidth={2.4} />
        </div>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.peach, textTransform: 'uppercase' }}>Speaking as you</div>
      </div>
      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 28, lineHeight: 1.25, fontWeight: 500, letterSpacing: -0.4, color: '#fff',
        minHeight: 80,
      }}>
        How about that bookshop in the Mission?<span style={{ display: 'inline-block', width: 2, height: 28, background: TOKENS.peach, marginLeft: 2, verticalAlign: 'middle' }} />
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
        <button style={{
          padding: '10px 14px', borderRadius: 20,
          background: 'rgba(255,255,255,0.1)', color: '#fff',
          border: 'none', fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
        }}>Edit voice</button>
        <div style={{ flex: 1 }} />
        <button style={{
          padding: '10px 20px', borderRadius: 20,
          background: TOKENS.peach, color: TOKENS.ink,
          border: 'none', fontSize: 14, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <LTIcon name="send" size={14} color={TOKENS.ink} strokeWidth={2.4} />
          Speak now
        </button>
      </div>
    </div>

    <div style={{ flex: 1 }} />
    <div style={{
      height: 200, background: TOKENS.bgSoft,
      borderTop: `1px solid ${TOKENS.hairline}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: TOKENS.inkMute, fontSize: 12,
    }}>
      <div style={{ opacity: 0.5 }}>⌨︎ keyboard</div>
    </div>
  </div>
);

window.C_Onboarding = C_Onboarding;
window.C_Live11 = C_Live11;
window.C_SoundAlert = C_SoundAlert;
window.C_Group = C_Group;
window.C_TypeToSpeak = C_TypeToSpeak;
