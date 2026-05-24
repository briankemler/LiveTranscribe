// Direction A — "Cozy chat"
// Chat-bubble metaphor. Each speaker gets a colored bubble.
// Sound chips inline, contextual. Warm peach accents.

const aStyles = {
  page: {
    fontFamily: TOKENS.fontUI,
    background: TOKENS.bg,
    color: TOKENS.ink,
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
    fontSize: 16,
  },
  appbar: {
    height: 64,
    padding: '0 16px',
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    borderBottom: `1px solid ${TOKENS.hairline}`,
  },
  appTitle: {
    fontFamily: TOKENS.fontDisplay,
    fontSize: 22,
    fontWeight: 600,
    letterSpacing: -0.3,
    flex: 1,
  },
  iconBtn: {
    width: 40, height: 40, borderRadius: 20,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    background: 'transparent', border: 'none', color: TOKENS.ink, cursor: 'pointer',
  },
  privacyPill: {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '4px 10px', borderRadius: 999,
    background: TOKENS.peachSoft, color: TOKENS.terra,
    fontSize: 12, fontWeight: 600,
  },
  scroll: {
    flex: 1, overflowY: 'auto', padding: '20px 16px 100px',
    display: 'flex', flexDirection: 'column', gap: 14,
  },
  bubbleWrap: { display: 'flex', gap: 10, alignItems: 'flex-end' },
  bubbleWrapMine: { flexDirection: 'row-reverse' },
  avatar: {
    width: 32, height: 32, borderRadius: 16,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    color: '#fff', fontWeight: 600, fontSize: 13,
    flexShrink: 0,
  },
  bubbleCol: { display: 'flex', flexDirection: 'column', gap: 4, maxWidth: '78%' },
  speakerLabel: { fontSize: 12, fontWeight: 600, color: TOKENS.inkSoft, padding: '0 4px' },
  bubble: {
    padding: '12px 16px',
    borderRadius: 22,
    fontSize: 22,
    lineHeight: 1.35,
    fontWeight: 400,
    letterSpacing: -0.1,
  },
  soundChipRow: {
    display: 'flex', justifyContent: 'center', gap: 8, padding: '6px 0', flexWrap: 'wrap',
  },
  chipAmbient: {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '6px 12px', borderRadius: 999,
    background: TOKENS.ambientBg, color: TOKENS.inkSoft,
    fontSize: 13, fontWeight: 500,
  },
  chipAlert: {
    display: 'inline-flex', alignItems: 'center', gap: 8,
    padding: '10px 16px', borderRadius: 999,
    background: TOKENS.alertBg, color: TOKENS.alert,
    fontSize: 15, fontWeight: 600,
    border: `1.5px solid ${TOKENS.alert}`,
  },
  chipSocial: {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '6px 12px', borderRadius: 999,
    background: TOKENS.socialBg, color: TOKENS.social,
    fontSize: 13, fontWeight: 500,
  },
  liveBar: {
    position: 'absolute', bottom: 24, left: 16, right: 16,
    height: 64, borderRadius: 32,
    background: TOKENS.ink, color: TOKENS.bg,
    display: 'flex', alignItems: 'center', padding: '0 8px 0 20px',
    boxShadow: '0 8px 24px rgba(42,34,28,0.2)',
    gap: 12,
  },
  waveDot: {
    width: 4, borderRadius: 2, background: TOKENS.peach,
  },
  micBtn: {
    width: 48, height: 48, borderRadius: 24,
    background: TOKENS.peach,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    border: 'none', cursor: 'pointer',
    flexShrink: 0,
  },
};

// Animated waveform bars
const Waveform = ({ color = TOKENS.peach, count = 14, height = 18 }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 3, height }}>
    {Array.from({ length: count }).map((_, i) => {
      const h = 4 + Math.abs(Math.sin(i * 0.7)) * (height - 4);
      return <div key={i} style={{ width: 3, height: h, borderRadius: 1.5, background: color, opacity: 0.4 + (i % 3) * 0.2 }} />;
    })}
  </div>
);

const SpeakerBubble = ({ speaker, text, color, mine, partial }) => (
  <div style={{ ...aStyles.bubbleWrap, ...(mine ? aStyles.bubbleWrapMine : {}) }}>
    <div style={{ ...aStyles.avatar, background: color }}>{speaker[0]}</div>
    <div style={aStyles.bubbleCol}>
      <div style={{ ...aStyles.speakerLabel, textAlign: mine ? 'right' : 'left' }}>{speaker}</div>
      <div style={{
        ...aStyles.bubble,
        background: mine ? TOKENS.peach : TOKENS.surface,
        color: mine ? '#fff' : TOKENS.ink,
        border: mine ? 'none' : `1px solid ${TOKENS.hairline}`,
        borderBottomRightRadius: mine ? 6 : 22,
        borderBottomLeftRadius: mine ? 22 : 6,
      }}>
        {text}{partial && <span style={{ opacity: 0.5 }}>…</span>}
      </div>
    </div>
  </div>
);

// ── Onboarding ────────────────────────────────────────────────
const A_Onboarding = () => (
  <div style={aStyles.page}>
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '40px 28px 28px' }}>
      <div>
        <div style={{
          width: 56, height: 56, borderRadius: 16,
          background: TOKENS.peach,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          marginBottom: 28,
        }}>
          <LTIcon name="ear" size={30} color="#fff" />
        </div>
        <div style={{
          fontFamily: TOKENS.fontDisplay,
          fontSize: 40, fontWeight: 500, lineHeight: 1.05,
          letterSpacing: -1, marginBottom: 16, color: TOKENS.ink,
        }}>
          Hear every<br/>conversation,<br/><em style={{ fontStyle: 'italic', color: TOKENS.peachDeep }}>your way.</em>
        </div>
        <div style={{ fontSize: 17, lineHeight: 1.5, color: TOKENS.inkSoft, marginBottom: 32 }}>
          Live captions for one-on-ones and group chats. Plus the ambient sounds around you.
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {[
            { icon: 'cpu', t: 'Runs on your phone', s: 'No cloud. No accounts. No tracking.' },
            { icon: 'wifi-off', t: 'Works without Wi-Fi', s: 'Caption a coffee chat in a tunnel.' },
            { icon: 'shield', t: 'Yours alone', s: 'Transcripts never leave this device.' },
          ].map((f) => (
            <div key={f.icon} style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: TOKENS.peachSoft, color: TOKENS.peachDeep,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <LTIcon name={f.icon} size={18} color={TOKENS.peachDeep} />
              </div>
              <div>
                <div style={{ fontSize: 16, fontWeight: 600, color: TOKENS.ink, marginBottom: 2 }}>{f.t}</div>
                <div style={{ fontSize: 14, color: TOKENS.inkSoft, lineHeight: 1.4 }}>{f.s}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div>
        <button style={{
          width: '100%', height: 56, borderRadius: 28,
          background: TOKENS.ink, color: TOKENS.bg,
          fontSize: 17, fontWeight: 600, border: 'none', cursor: 'pointer',
          fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          Get started
          <LTIcon name="arrow" size={18} color={TOKENS.bg} />
        </button>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 16 }}>
          <div style={{ width: 24, height: 6, borderRadius: 3, background: TOKENS.peach }} />
          <div style={{ width: 6, height: 6, borderRadius: 3, background: TOKENS.hairline }} />
          <div style={{ width: 6, height: 6, borderRadius: 3, background: TOKENS.hairline }} />
        </div>
      </div>
    </div>
  </div>
);

// ── Live 1:1 ──────────────────────────────────────────────────
const A_Live11 = () => (
  <div style={{ ...aStyles.page, position: 'relative' }}>
    <div style={aStyles.appbar}>
      <button style={aStyles.iconBtn}><LTIcon name="back" size={22} /></button>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 16, fontWeight: 600 }}>Coffee with Maya</div>
        <div style={{ fontSize: 12, color: TOKENS.inkSoft, display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: '#5a8a7a' }} />
          Listening · 2 voices
        </div>
      </div>
      <div style={aStyles.privacyPill}>
        <LTIcon name="lock" size={11} color={TOKENS.terra} strokeWidth={2.4} />
        On-device
      </div>
    </div>

    <div style={aStyles.scroll}>
      <div style={{ textAlign: 'center', fontSize: 12, color: TOKENS.inkMute, padding: '4px 0' }}>
        Today · 9:41 AM
      </div>

      <SpeakerBubble speaker="Maya" color={TOKENS.spkB}
        text="So I switched to working from the café most mornings. Way better than the apartment." />

      <SpeakerBubble speaker="You" color={TOKENS.spkA} mine
        text="Is it not too loud?" />

      <div style={aStyles.soundChipRow}>
        <div style={aStyles.chipAmbient}>
          <LTIcon name="music" size={13} /> jazz playing softly
        </div>
      </div>

      <SpeakerBubble speaker="Maya" color={TOKENS.spkB}
        text="Honestly the background noise helps me focus. And the espresso is unreal." />

      <div style={aStyles.soundChipRow}>
        <div style={aStyles.chipSocial}>
          <LTIcon name="volume" size={13} /> laughter
        </div>
      </div>

      <SpeakerBubble speaker="Maya" color={TOKENS.spkB} partial
        text="They actually know my order now, which is" />
    </div>

    <div style={aStyles.liveBar}>
      <Waveform color={TOKENS.peach} count={20} height={22} />
      <div style={{ flex: 1 }} />
      <div style={{ fontSize: 13, opacity: 0.7 }}>00:08:42</div>
      <button style={aStyles.micBtn}>
        <LTIcon name="pause" size={20} color={TOKENS.ink} strokeWidth={2.2} />
      </button>
    </div>
  </div>
);

// ── Sound recognition moment (alarm/urgent) ───────────────────
const A_SoundAlert = () => (
  <div style={{ ...aStyles.page, position: 'relative' }}>
    <div style={aStyles.appbar}>
      <button style={aStyles.iconBtn}><LTIcon name="back" size={22} /></button>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 16, fontWeight: 600 }}>At home</div>
        <div style={{ fontSize: 12, color: TOKENS.inkSoft }}>Listening · 1 voice</div>
      </div>
      <div style={aStyles.privacyPill}>
        <LTIcon name="lock" size={11} color={TOKENS.terra} strokeWidth={2.4} />
        On-device
      </div>
    </div>

    <div style={aStyles.scroll}>
      <SpeakerBubble speaker="Sam" color={TOKENS.spkB}
        text="I'll grab the kettle, you want tea?" />

      <SpeakerBubble speaker="You" color={TOKENS.spkA} mine
        text="Please — green if there's any" />

      {/* Alert: sound recognition takes over */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, padding: '20px 0' }}>
        <div style={{
          width: 88, height: 88, borderRadius: 44,
          background: TOKENS.alertBg,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: `3px solid ${TOKENS.alert}`,
          position: 'relative',
        }}>
          <div style={{
            position: 'absolute', inset: -8, borderRadius: 50,
            border: `2px solid ${TOKENS.alert}`, opacity: 0.3,
          }} />
          <LTIcon name="bell" size={40} color={TOKENS.alert} strokeWidth={2.2} />
        </div>
        <div style={{
          fontFamily: TOKENS.fontDisplay,
          fontSize: 28, fontWeight: 600, color: TOKENS.alert,
          letterSpacing: -0.3,
        }}>
          Smoke alarm
        </div>
        <div style={{ fontSize: 14, color: TOKENS.inkSoft, textAlign: 'center', maxWidth: 240 }}>
          Detected nearby · 96% confident
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
          <button style={{
            padding: '10px 18px', borderRadius: 22,
            background: TOKENS.surface, color: TOKENS.ink,
            border: `1px solid ${TOKENS.hairline}`,
            fontSize: 14, fontWeight: 500, cursor: 'pointer', fontFamily: 'inherit',
          }}>Dismiss</button>
          <button style={{
            padding: '10px 18px', borderRadius: 22,
            background: TOKENS.alert, color: '#fff',
            border: 'none', fontSize: 14, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
          }}>I see it</button>
        </div>
      </div>

      <SpeakerBubble speaker="Sam" color={TOKENS.spkB} partial
        text="Wait — that's the kitchen, hold on" />
    </div>

    <div style={aStyles.liveBar}>
      <Waveform color={TOKENS.alert} count={20} height={22} />
      <div style={{ flex: 1 }} />
      <div style={{ fontSize: 13, opacity: 0.7 }}>00:14:03</div>
      <button style={aStyles.micBtn}>
        <LTIcon name="pause" size={20} color={TOKENS.ink} strokeWidth={2.2} />
      </button>
    </div>
  </div>
);

// ── Group conversation ────────────────────────────────────────
const A_Group = () => (
  <div style={{ ...aStyles.page, position: 'relative' }}>
    <div style={aStyles.appbar}>
      <button style={aStyles.iconBtn}><LTIcon name="back" size={22} /></button>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 16, fontWeight: 600 }}>Tuesday dinner</div>
        <div style={{ fontSize: 12, color: TOKENS.inkSoft, display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: '#5a8a7a' }} />
          Listening · 4 voices
        </div>
      </div>
      <button style={aStyles.iconBtn}><LTIcon name="people" size={22} /></button>
    </div>

    {/* speaker legend */}
    <div style={{
      display: 'flex', gap: 6, padding: '10px 16px',
      borderBottom: `1px solid ${TOKENS.hairline}`,
      overflowX: 'auto',
    }}>
      {[
        { n: 'You', c: TOKENS.spkA },
        { n: 'Maya', c: TOKENS.spkB },
        { n: 'Jordan', c: TOKENS.spkC },
        { n: 'Priya', c: TOKENS.spkD },
      ].map((s) => (
        <div key={s.n} style={{
          display: 'flex', alignItems: 'center', gap: 6,
          padding: '4px 10px 4px 4px', borderRadius: 999,
          background: TOKENS.surface, border: `1px solid ${TOKENS.hairline}`,
          flexShrink: 0,
        }}>
          <div style={{ width: 20, height: 20, borderRadius: 10, background: s.c, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700 }}>{s.n[0]}</div>
          <div style={{ fontSize: 12, fontWeight: 500 }}>{s.n}</div>
        </div>
      ))}
    </div>

    <div style={aStyles.scroll}>
      <SpeakerBubble speaker="Jordan" color={TOKENS.spkC}
        text="Wait, you actually finished the marathon?" />
      <SpeakerBubble speaker="Maya" color={TOKENS.spkB}
        text="Four hours twelve. Knees still hate me." />
      <div style={aStyles.soundChipRow}>
        <div style={aStyles.chipSocial}>
          <LTIcon name="volume" size={13} /> applause
        </div>
      </div>
      <SpeakerBubble speaker="Priya" color={TOKENS.spkD}
        text="Okay but the real question is what's for dessert" />
      <SpeakerBubble speaker="You" color={TOKENS.spkA} mine
        text="There's tiramisu in the fridge" />
      <div style={aStyles.soundChipRow}>
        <div style={aStyles.chipAmbient}>
          <LTIcon name="music" size={13} /> dishes clinking
        </div>
      </div>
      <SpeakerBubble speaker="Jordan" color={TOKENS.spkC} partial
        text="You're a hero, I'll grab plates" />
    </div>

    <div style={aStyles.liveBar}>
      <Waveform color={TOKENS.peach} count={20} height={22} />
      <div style={{ flex: 1 }} />
      <div style={{ fontSize: 13, opacity: 0.7 }}>00:23:18</div>
      <button style={aStyles.micBtn}>
        <LTIcon name="pause" size={20} color={TOKENS.ink} strokeWidth={2.2} />
      </button>
    </div>
  </div>
);

// ── Type-to-speak ─────────────────────────────────────────────
const A_TypeToSpeak = () => (
  <div style={{ ...aStyles.page, position: 'relative', background: TOKENS.bg }}>
    <div style={aStyles.appbar}>
      <button style={aStyles.iconBtn}><LTIcon name="back" size={22} /></button>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 16, fontWeight: 600 }}>Coffee with Maya</div>
        <div style={{ fontSize: 12, color: TOKENS.inkSoft }}>Type — I'll read it aloud</div>
      </div>
    </div>

    <div style={{ ...aStyles.scroll, paddingBottom: 280 }}>
      <SpeakerBubble speaker="Maya" color={TOKENS.spkB}
        text="What do you want to do this weekend?" />
    </div>

    {/* Floating compose card */}
    <div style={{
      position: 'absolute', bottom: 220, left: 16, right: 16,
      background: TOKENS.surface, borderRadius: 20, padding: 16,
      boxShadow: '0 8px 32px rgba(42,34,28,0.12)',
      border: `1px solid ${TOKENS.hairline}`,
    }}>
      <div style={{ fontSize: 12, fontWeight: 600, color: TOKENS.peachDeep, marginBottom: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
        <LTIcon name="volume" size={12} color={TOKENS.peachDeep} strokeWidth={2.2} />
        SPEAK FOR ME
      </div>
      <div style={{ fontSize: 22, lineHeight: 1.3, color: TOKENS.ink, minHeight: 60 }}>
        How about that bookshop in the Mission?<span style={{ display: 'inline-block', width: 2, height: 26, background: TOKENS.peach, marginLeft: 2, verticalAlign: 'middle', animation: 'caret 1s steps(2) infinite' }} />
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 14, justifyContent: 'flex-end' }}>
        <button style={{
          padding: '8px 14px', borderRadius: 18,
          background: 'transparent', color: TOKENS.inkSoft,
          border: `1px solid ${TOKENS.hairline}`,
          fontSize: 13, fontWeight: 500, cursor: 'pointer', fontFamily: 'inherit',
        }}>Cancel</button>
        <button style={{
          padding: '8px 16px', borderRadius: 18,
          background: TOKENS.peach, color: '#fff',
          border: 'none', fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <LTIcon name="send" size={13} color="#fff" strokeWidth={2.4} />
          Speak
        </button>
      </div>
    </div>

    {/* mini keyboard hint */}
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      height: 200, background: TOKENS.bgSoft,
      borderTop: `1px solid ${TOKENS.hairline}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: TOKENS.inkMute, fontSize: 12,
    }}>
      <div style={{ opacity: 0.5 }}>⌨︎ keyboard</div>
    </div>
  </div>
);

window.A_Onboarding = A_Onboarding;
window.A_Live11 = A_Live11;
window.A_SoundAlert = A_SoundAlert;
window.A_Group = A_Group;
window.A_TypeToSpeak = A_TypeToSpeak;
