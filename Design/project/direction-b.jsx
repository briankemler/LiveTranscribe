// Direction B — "Editorial flow"
// Flowing teleprompter-style transcript. Large serif emphasis on the latest line.
// Sound chips live in a thin side rail. Speakers as inline pills.

const bStyles = {
  page: {
    fontFamily: TOKENS.fontUI,
    background: TOKENS.bg,
    color: TOKENS.ink,
    height: '100%',
    display: 'flex', flexDirection: 'column',
  },
  topbar: {
    height: 52, padding: '0 16px',
    display: 'flex', alignItems: 'center', gap: 10,
    borderBottom: `1px solid ${TOKENS.hairline}`,
  },
  liveDot: {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    fontSize: 12, fontWeight: 600, color: TOKENS.peachDeep, letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  body: {
    flex: 1, overflowY: 'auto',
    display: 'flex', flexDirection: 'row',
  },
  rail: {
    width: 56, flexShrink: 0,
    borderRight: `1px solid ${TOKENS.hairline}`,
    padding: '20px 0',
    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
  },
  railLabel: {
    writingMode: 'vertical-rl', transform: 'rotate(180deg)',
    fontSize: 10, letterSpacing: 2, color: TOKENS.inkMute,
    textTransform: 'uppercase', fontWeight: 600, marginBottom: 8,
  },
  railChip: {
    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
    padding: '8px 4px', width: 44,
  },
  feed: {
    flex: 1, padding: '24px 24px 140px',
  },
  spkPill: {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '2px 10px 2px 4px', borderRadius: 999,
    fontSize: 12, fontWeight: 600, marginRight: 8,
    verticalAlign: 'middle',
  },
  spkDot: {
    width: 18, height: 18, borderRadius: 9, color: '#fff',
    display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700,
  },
  para: {
    marginBottom: 24,
    fontSize: 22, lineHeight: 1.45,
    color: TOKENS.inkSoft,
    textWrap: 'pretty',
  },
  paraLatest: {
    fontFamily: TOKENS.fontDisplay,
    fontSize: 30, lineHeight: 1.3,
    color: TOKENS.ink, fontWeight: 500,
    letterSpacing: -0.4,
  },
  bottomBar: {
    position: 'absolute', left: 0, right: 0, bottom: 0,
    padding: '12px 16px 16px',
    background: 'linear-gradient(to top, rgba(250,246,241,1) 60%, rgba(250,246,241,0))',
  },
  controls: {
    height: 56, borderRadius: 28,
    background: TOKENS.surface,
    border: `1px solid ${TOKENS.hairline}`,
    display: 'flex', alignItems: 'center', padding: '0 8px 0 16px',
    gap: 12, boxShadow: '0 4px 16px rgba(42,34,28,0.08)',
  },
};

// Vertical rail entry
const RailChip = ({ icon, label, time, tone = 'ambient', strong }) => {
  const colors = {
    ambient: { bg: TOKENS.ambientBg, fg: TOKENS.inkSoft },
    alert: { bg: TOKENS.alertBg, fg: TOKENS.alert },
    social: { bg: TOKENS.socialBg, fg: TOKENS.social },
  }[tone];
  return (
    <div style={bStyles.railChip}>
      <div style={{
        width: 36, height: 36, borderRadius: 18,
        background: colors.bg, color: colors.fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        border: strong ? `2px solid ${colors.fg}` : 'none',
      }}>
        <LTIcon name={icon} size={16} color={colors.fg} strokeWidth={2} />
      </div>
      <div style={{ fontSize: 9, color: TOKENS.inkMute, fontVariantNumeric: 'tabular-nums' }}>{time}</div>
      <div style={{ fontSize: 10, fontWeight: 600, color: colors.fg, textAlign: 'center', lineHeight: 1.1 }}>{label}</div>
    </div>
  );
};

const SpkPill = ({ name, color }) => (
  <span style={{ ...bStyles.spkPill, background: TOKENS.surface, color: TOKENS.ink, border: `1px solid ${TOKENS.hairline}` }}>
    <span style={{ ...bStyles.spkDot, background: color }}>{name[0]}</span>
    {name}
  </span>
);

// ── Onboarding ────────────────────────────────────────────────
const B_Onboarding = () => (
  <div style={bStyles.page}>
    <div style={{ flex: 1, padding: '60px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 3, color: TOKENS.peachDeep, textTransform: 'uppercase', marginBottom: 24 }}>
        Live Transcribe
      </div>

      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 52, fontWeight: 400, lineHeight: 0.98,
        letterSpacing: -1.8, color: TOKENS.ink, marginBottom: 28,
      }}>
        Read the<br/>
        <em style={{ fontStyle: 'italic', color: TOKENS.peachDeep }}>room.</em>
      </div>

      <div style={{ fontSize: 18, lineHeight: 1.5, color: TOKENS.inkSoft, marginBottom: 'auto', maxWidth: 320 }}>
        Speech, sounds, and the silences between them — captioned in real time, on your phone alone.
      </div>

      <div style={{
        margin: '32px 0',
        padding: '18px 20px',
        background: TOKENS.surface,
        borderRadius: 16,
        border: `1px solid ${TOKENS.hairline}`,
      }}>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: 8 }}>
          <LTIcon name="cpu" size={18} color={TOKENS.peachDeep} />
          <div style={{ fontSize: 14, fontWeight: 600, color: TOKENS.ink }}>On-device only</div>
        </div>
        <div style={{ fontSize: 13, color: TOKENS.inkSoft, lineHeight: 1.4 }}>
          The model lives in the app. Your audio never leaves your phone — not even to us.
        </div>
      </div>

      <button style={{
        height: 56, borderRadius: 28,
        background: TOKENS.peachDeep, color: '#fff',
        fontSize: 17, fontWeight: 600, border: 'none', cursor: 'pointer',
        fontFamily: 'inherit',
      }}>
        Allow microphone
      </button>
      <div style={{ textAlign: 'center', fontSize: 13, color: TOKENS.inkMute, marginTop: 16 }}>
        Step 2 of 3
      </div>
    </div>
  </div>
);

// ── Live 1:1 ──────────────────────────────────────────────────
const B_Live11 = () => (
  <div style={{ ...bStyles.page, position: 'relative' }}>
    <div style={bStyles.topbar}>
      <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', background: 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="back" size={20} />
      </button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Coffee with Maya</div>
      <div style={bStyles.liveDot}>
        <span style={{ width: 7, height: 7, borderRadius: 4, background: TOKENS.peachDeep }} />
        Live · 8:42
      </div>
    </div>

    <div style={bStyles.body}>
      <div style={bStyles.rail}>
        <div style={bStyles.railLabel}>Sounds</div>
        <RailChip icon="music" label="jazz" time="8:38" tone="ambient" />
        <RailChip icon="volume" label="laugh" time="8:40" tone="social" />
        <RailChip icon="wind" label="hiss" time="8:41" tone="ambient" />
      </div>

      <div style={bStyles.feed}>
        <div style={bStyles.para}>
          <SpkPill name="Maya" color={TOKENS.spkB} />
          So I switched to working from the café most mornings. Way better than the apartment.
        </div>
        <div style={bStyles.para}>
          <SpkPill name="You" color={TOKENS.spkA} />
          Is it not too loud?
        </div>
        <div style={bStyles.para}>
          <SpkPill name="Maya" color={TOKENS.spkB} />
          Honestly the background noise helps me focus. And the espresso is unreal.
        </div>
        <div style={{ ...bStyles.para, ...bStyles.paraLatest }}>
          <SpkPill name="Maya" color={TOKENS.spkB} />
          They actually know my order now, which is<span style={{ opacity: 0.4 }}>…</span>
        </div>
      </div>
    </div>

    <div style={bStyles.bottomBar}>
      <div style={bStyles.controls}>
        <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', background: TOKENS.peachSoft, color: TOKENS.peachDeep, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <LTIcon name="keyboard" size={18} color={TOKENS.peachDeep} />
        </button>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 3 }}>
          {Array.from({ length: 22 }).map((_, i) => (
            <div key={i} style={{ width: 3, height: 4 + Math.abs(Math.sin(i * 0.6)) * 18, borderRadius: 2, background: TOKENS.peach, opacity: 0.5 + (i % 3) * 0.2 }} />
          ))}
        </div>
        <button style={{ width: 44, height: 44, borderRadius: 22, border: 'none', background: TOKENS.peachDeep, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <LTIcon name="pause" size={18} color="#fff" strokeWidth={2.2} />
        </button>
      </div>
    </div>
  </div>
);

// ── Sound recognition (alert) ─────────────────────────────────
const B_SoundAlert = () => (
  <div style={{ ...bStyles.page, position: 'relative' }}>
    <div style={{ ...bStyles.topbar, background: TOKENS.alertBg, borderBottom: `1px solid ${TOKENS.alert}` }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: TOKENS.alert, fontWeight: 700, fontSize: 13 }}>
        <span style={{ width: 8, height: 8, borderRadius: 4, background: TOKENS.alert }} />
        URGENT SOUND DETECTED
      </div>
      <div style={{ flex: 1 }} />
      <div style={{ fontSize: 12, color: TOKENS.alert, fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>14:03</div>
    </div>

    {/* Hero alert */}
    <div style={{
      padding: '32px 24px 24px',
      borderBottom: `1px solid ${TOKENS.hairline}`,
      background: `linear-gradient(180deg, ${TOKENS.alertBg} 0%, ${TOKENS.bg} 100%)`,
    }}>
      <div style={{
        display: 'flex', gap: 16, alignItems: 'center', marginBottom: 16,
      }}>
        <div style={{
          width: 64, height: 64, borderRadius: 32,
          background: TOKENS.alert,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <LTIcon name="bell" size={32} color="#fff" strokeWidth={2.2} />
        </div>
        <div>
          <div style={{
            fontFamily: TOKENS.fontDisplay,
            fontSize: 36, fontWeight: 600, color: TOKENS.alert,
            letterSpacing: -0.6, lineHeight: 1,
          }}>
            Smoke alarm
          </div>
          <div style={{ fontSize: 13, color: TOKENS.inkSoft, marginTop: 4 }}>
            Continuous · loud · nearby
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={{
          flex: 1, height: 44, borderRadius: 22,
          background: 'transparent', color: TOKENS.ink,
          border: `1px solid ${TOKENS.hairline}`, fontSize: 14, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
        }}>Snooze 5 min</button>
        <button style={{
          flex: 1, height: 44, borderRadius: 22,
          background: TOKENS.alert, color: '#fff',
          border: 'none', fontSize: 14, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
        }}>I see it</button>
      </div>
    </div>

    <div style={bStyles.body}>
      <div style={bStyles.rail}>
        <div style={bStyles.railLabel}>Sounds</div>
        <RailChip icon="bell" label="alarm" time="14:03" tone="alert" strong />
        <RailChip icon="music" label="kettle" time="14:01" tone="ambient" />
      </div>

      <div style={bStyles.feed}>
        <div style={bStyles.para}>
          <SpkPill name="Sam" color={TOKENS.spkB} />
          I'll grab the kettle, you want tea?
        </div>
        <div style={{ ...bStyles.para, ...bStyles.paraLatest }}>
          <SpkPill name="Sam" color={TOKENS.spkB} />
          Wait — that's the kitchen, hold on<span style={{ opacity: 0.4 }}>…</span>
        </div>
      </div>
    </div>
  </div>
);

// ── Group ─────────────────────────────────────────────────────
const B_Group = () => (
  <div style={{ ...bStyles.page, position: 'relative' }}>
    <div style={bStyles.topbar}>
      <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', background: 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="back" size={20} />
      </button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Tuesday dinner · 4 voices</div>
      <div style={bStyles.liveDot}>
        <span style={{ width: 7, height: 7, borderRadius: 4, background: TOKENS.peachDeep }} />
        23:18
      </div>
    </div>

    <div style={bStyles.body}>
      <div style={bStyles.rail}>
        <div style={bStyles.railLabel}>Sounds</div>
        <RailChip icon="volume" label="cheer" time="23:10" tone="social" />
        <RailChip icon="music" label="dishes" time="23:14" tone="ambient" />
      </div>

      <div style={bStyles.feed}>
        <div style={bStyles.para}>
          <SpkPill name="Jordan" color={TOKENS.spkC} />
          Wait, you actually finished the marathon?
        </div>
        <div style={bStyles.para}>
          <SpkPill name="Maya" color={TOKENS.spkB} />
          Four hours twelve. Knees still hate me.
        </div>
        <div style={bStyles.para}>
          <SpkPill name="Priya" color={TOKENS.spkD} />
          Okay but the real question is what's for dessert.
        </div>
        <div style={bStyles.para}>
          <SpkPill name="You" color={TOKENS.spkA} />
          There's tiramisu in the fridge.
        </div>
        <div style={{ ...bStyles.para, ...bStyles.paraLatest }}>
          <SpkPill name="Jordan" color={TOKENS.spkC} />
          You're a hero, I'll grab plates<span style={{ opacity: 0.4 }}>…</span>
        </div>
      </div>
    </div>

    <div style={bStyles.bottomBar}>
      <div style={bStyles.controls}>
        <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', background: TOKENS.peachSoft, color: TOKENS.peachDeep, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <LTIcon name="people" size={18} color={TOKENS.peachDeep} />
        </button>
        <div style={{ flex: 1, fontSize: 13, color: TOKENS.inkSoft, fontWeight: 500 }}>4 voices · auto-detect</div>
        <button style={{ width: 44, height: 44, borderRadius: 22, border: 'none', background: TOKENS.peachDeep, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <LTIcon name="pause" size={18} color="#fff" strokeWidth={2.2} />
        </button>
      </div>
    </div>
  </div>
);

// ── Type-to-speak ─────────────────────────────────────────────
const B_TypeToSpeak = () => (
  <div style={{ ...bStyles.page, position: 'relative' }}>
    <div style={bStyles.topbar}>
      <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', background: 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="back" size={20} />
      </button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Coffee with Maya</div>
    </div>

    <div style={{ padding: '24px 24px 16px' }}>
      <div style={bStyles.para}>
        <SpkPill name="Maya" color={TOKENS.spkB} />
        What do you want to do this weekend?
      </div>
    </div>

    {/* Compose */}
    <div style={{
      margin: '0 16px',
      padding: 20, borderRadius: 20,
      background: TOKENS.surface,
      border: `2px solid ${TOKENS.peach}`,
      boxShadow: '0 8px 24px rgba(201,100,66,0.12)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <LTIcon name="volume" size={14} color={TOKENS.peachDeep} strokeWidth={2.4} />
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: TOKENS.peachDeep, textTransform: 'uppercase' }}>I'll say this aloud</div>
      </div>
      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 26, lineHeight: 1.3, color: TOKENS.ink, fontWeight: 500,
        letterSpacing: -0.3, minHeight: 80,
      }}>
        How about that bookshop in the Mission?<span style={{ display: 'inline-block', width: 2, height: 28, background: TOKENS.peachDeep, marginLeft: 2, verticalAlign: 'middle' }} />
      </div>
      <div style={{ display: 'flex', gap: 10, marginTop: 16, alignItems: 'center' }}>
        <div style={{ fontSize: 12, color: TOKENS.inkMute, flex: 1 }}>Voice · Warm female</div>
        <button style={{
          padding: '10px 20px', borderRadius: 22,
          background: TOKENS.peachDeep, color: '#fff', border: 'none',
          fontSize: 14, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <LTIcon name="send" size={14} color="#fff" strokeWidth={2.4} />
          Speak
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

window.B_Onboarding = B_Onboarding;
window.B_Live11 = B_Live11;
window.B_SoundAlert = B_SoundAlert;
window.B_Group = B_Group;
window.B_TypeToSpeak = B_TypeToSpeak;
