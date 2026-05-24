// Direction C v2 — additional screens
// Home, History, Sound settings, Rewind moment, Conversation summary

const c2s = {
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
};

// ─── Home / start screen ──────────────────────────────────────
const C_Home = () => (
  <div style={c2s.page}>
    <div style={{ ...c2s.topbar, padding: '0 16px' }}>
      <div style={{ flex: 1, fontSize: 13, fontWeight: 700, letterSpacing: 1.5, color: TOKENS.peachDeep, textTransform: 'uppercase' }}>Live Transcribe</div>
      <button style={c2s.iconBtn}><LTIcon name="settings" size={20} /></button>
    </div>

    <div style={{ padding: '8px 20px 16px' }}>
      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 40, fontWeight: 500, letterSpacing: -1.2, lineHeight: 1.05,
        color: TOKENS.ink,
      }}>
        Ready when<br/>
        <em style={{ color: TOKENS.peachDeep, fontStyle: 'italic' }}>you are.</em>
      </div>
    </div>

    {/* Big start button */}
    <div style={{ padding: '0 16px 16px' }}>
      <button style={{
        width: '100%', padding: '24px 22px',
        borderRadius: 24, border: 'none',
        background: TOKENS.ink, color: '#fff',
        cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
        display: 'flex', alignItems: 'center', gap: 16,
        boxShadow: '0 12px 32px rgba(42,34,28,0.22)',
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: 28,
          background: TOKENS.peach,
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <LTIcon name="mic" size={26} color={TOKENS.ink} strokeWidth={2.4} />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: -0.3 }}>Start listening</div>
          <div style={{ fontSize: 13, opacity: 0.7, marginTop: 2 }}>Auto-detect speakers · 96 sounds</div>
        </div>
        <LTIcon name="arrow" size={20} color="#fff" strokeWidth={2.2} />
      </button>
    </div>

    {/* Mode selector */}
    <div style={{ padding: '0 16px', display: 'flex', gap: 10, marginBottom: 20 }}>
      {[
        { i: 'person', t: '1:1', s: 'two voices' },
        { i: 'people', t: 'Group', s: '3+ voices' },
      ].map((m) => (
        <div key={m.t} style={{
          flex: 1, padding: '14px 14px',
          borderRadius: 16, background: TOKENS.surface,
          border: `1px solid ${TOKENS.hairline}`,
        }}>
          <LTIcon name={m.i} size={18} color={TOKENS.peachDeep} />
          <div style={{ fontSize: 14, fontWeight: 700, marginTop: 8 }}>{m.t}</div>
          <div style={{ fontSize: 11, color: TOKENS.inkSoft }}>{m.s}</div>
        </div>
      ))}
    </div>

    {/* Recent */}
    <div style={{ padding: '0 16px', flex: 1, overflowY: 'auto' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.inkMute, textTransform: 'uppercase', marginBottom: 10 }}>Recent</div>
      {[
        { t: 'Coffee with Maya', d: 'Today · 8m', sp: 2, snd: 4 },
        { t: 'Tuesday dinner', d: 'Yesterday · 47m', sp: 4, snd: 12 },
        { t: 'Standup', d: 'Mon · 22m', sp: 5, snd: 2 },
      ].map((r, i) => (
        <div key={i} style={{
          padding: '12px 14px', borderRadius: 12,
          background: TOKENS.surface, marginBottom: 8,
          border: `1px solid ${TOKENS.hairline}`,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600 }}>{r.t}</div>
            <div style={{ fontSize: 12, color: TOKENS.inkSoft, marginTop: 2 }}>{r.d} · {r.sp} voices · {r.snd} sounds</div>
          </div>
          <LTIcon name="arrow" size={16} color={TOKENS.inkMute} />
        </div>
      ))}
    </div>

    <div style={{
      padding: '12px 16px',
      display: 'flex', alignItems: 'center', gap: 8,
      borderTop: `1px solid ${TOKENS.hairline}`,
      fontSize: 11, color: TOKENS.inkSoft,
    }}>
      <LTIcon name="cpu" size={12} color={TOKENS.peachDeep} strokeWidth={2.4} />
      <span>On-device · nothing leaves your phone</span>
    </div>
  </div>
);

// ─── Rewind: "I missed that" ──────────────────────────────────
const C_Rewind = () => (
  <div style={{ ...c2s.page, position: 'relative' }}>
    <div style={c2s.topbar}>
      <button style={c2s.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Rewind</div>
      <button style={c2s.iconBtn}><LTIcon name="close" size={20} /></button>
    </div>

    <div style={{ padding: '12px 20px 0' }}>
      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 28, fontWeight: 500, letterSpacing: -0.5, lineHeight: 1.2,
      }}>
        Scrub back to <em style={{ color: TOKENS.peachDeep, fontStyle: 'italic' }}>catch up.</em>
      </div>
      <div style={{ fontSize: 13, color: TOKENS.inkSoft, marginTop: 6 }}>
        Live transcript keeps going underneath.
      </div>
    </div>

    {/* Timeline scrubber */}
    <div style={{ margin: '20px 16px 0', padding: '14px 14px', borderRadius: 14, background: TOKENS.surface, border: `1px solid ${TOKENS.hairline}` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: TOKENS.inkMute, fontVariantNumeric: 'tabular-nums', fontWeight: 600, marginBottom: 6 }}>
        <span>0:00</span>
        <span>8:42 · NOW</span>
      </div>
      <div style={{ position: 'relative', height: 32 }}>
        {/* speaker bars */}
        <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', gap: 1 }}>
          {Array.from({ length: 64 }).map((_, i) => {
            const colors = [TOKENS.spkB, TOKENS.spkA, TOKENS.spkB, TOKENS.spkB, TOKENS.spkA];
            const c = colors[Math.floor(i / 13) % colors.length];
            const h = 8 + Math.abs(Math.sin(i * 0.7)) * 18;
            return <div key={i} style={{ flex: 1, height: h, background: c, borderRadius: 1, opacity: i < 38 ? 1 : 0.25 }} />;
          })}
        </div>
        {/* playhead */}
        <div style={{
          position: 'absolute', left: '58%', top: -4, bottom: -4,
          width: 3, background: TOKENS.peachDeep, borderRadius: 2,
          boxShadow: '0 0 0 4px rgba(201,100,66,0.2)',
        }} />
      </div>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 16, marginTop: 14 }}>
        <button style={{ width: 40, height: 40, borderRadius: 20, border: 'none', background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={TOKENS.ink} strokeWidth="1.8" strokeLinecap="round"><path d="M11 6l-7 6 7 6M21 6l-7 6 7 6"/></svg>
        </button>
        <button style={{ width: 48, height: 48, borderRadius: 24, border: 'none', background: TOKENS.peachDeep, color: '#fff', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <LTIcon name="play" size={20} color="#fff" strokeWidth={2.4} />
        </button>
        <button style={{ width: 40, height: 40, borderRadius: 20, border: 'none', background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={TOKENS.ink} strokeWidth="1.8" strokeLinecap="round"><path d="M13 6l7 6-7 6M3 6l7 6-7 6"/></svg>
        </button>
      </div>
    </div>

    {/* Replayed line */}
    <div style={{ padding: '20px 16px', flex: 1 }}>
      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.5, color: TOKENS.peachDeep, textTransform: 'uppercase', marginBottom: 8 }}>
        ⟲ 4:58 ago
      </div>
      <div style={{
        padding: 18, borderRadius: 18,
        background: TOKENS.surface,
        borderLeft: `5px solid ${TOKENS.spkB}`,
        boxShadow: '0 8px 24px rgba(42,34,28,0.08)',
      }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: TOKENS.spkB, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 8 }}>Maya</div>
        <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 26, fontWeight: 500, lineHeight: 1.3, letterSpacing: -0.3 }}>
          So I switched to working from the café most mornings.
        </div>
      </div>
    </div>

    {/* Live underneath */}
    <div style={{
      margin: '0 16px 12px',
      padding: '10px 14px', borderRadius: 12,
      background: 'rgba(42,34,28,0.06)',
      borderLeft: `3px solid ${TOKENS.peach}`,
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{ display: 'flex', gap: 2 }}>
        {[6, 10, 14, 8, 12, 7].map((h, i) => (
          <div key={i} style={{ width: 2, height: h, borderRadius: 1, background: TOKENS.peach, opacity: 0.5 + (i % 2) * 0.4 }} />
        ))}
      </div>
      <div style={{ flex: 1, fontSize: 12, color: TOKENS.inkSoft }}>
        <span style={{ fontWeight: 600 }}>Still listening</span> · 3 lines while you were rewinding
      </div>
      <button style={{ fontSize: 11, fontWeight: 700, color: TOKENS.peachDeep, background: 'none', border: 'none', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: 0.5 }}>Catch up →</button>
    </div>
  </div>
);

// ─── Sound recognition settings ───────────────────────────────
const C_SoundSettings = () => (
  <div style={c2s.page}>
    <div style={c2s.topbar}>
      <button style={c2s.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Sound recognition</div>
    </div>

    <div style={{ padding: '12px 20px 0' }}>
      <div style={{
        fontFamily: TOKENS.fontDisplay, fontSize: 28, fontWeight: 500,
        letterSpacing: -0.5, lineHeight: 1.15,
      }}>
        What should we<br/>
        <em style={{ color: TOKENS.peachDeep, fontStyle: 'italic' }}>watch for?</em>
      </div>
      <div style={{ fontSize: 13, color: TOKENS.inkSoft, marginTop: 8 }}>
        96 sounds available. Tap to mute or set urgency.
      </div>
    </div>

    <div style={{ padding: '20px 16px', flex: 1, overflowY: 'auto' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.alert, textTransform: 'uppercase', marginBottom: 10 }}>
        Urgent · alert me loud
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 18 }}>
        {[
          { i: 'bell', t: 'Smoke alarm' },
          { i: 'bell', t: 'Carbon monoxide' },
          { i: 'baby', t: 'Baby crying' },
          { i: 'door', t: 'Doorbell' },
          { i: 'car', t: 'Car horn' },
        ].map((s) => (
          <div key={s.t} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '8px 12px', borderRadius: 999,
            background: TOKENS.alert, color: '#fff',
            fontSize: 12, fontWeight: 600,
          }}>
            <LTIcon name={s.i} size={13} color="#fff" strokeWidth={2.2} />
            {s.t}
            <LTIcon name="check" size={12} color="#fff" strokeWidth={2.6} />
          </div>
        ))}
      </div>

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.social, textTransform: 'uppercase', marginBottom: 10 }}>
        Social · show inline
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 18 }}>
        {[
          { i: 'volume', t: 'Laughter' },
          { i: 'volume', t: 'Applause' },
          { i: 'volume', t: 'Cheering' },
          { i: 'volume', t: 'Singing' },
        ].map((s) => (
          <div key={s.t} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '8px 12px', borderRadius: 999,
            background: TOKENS.socialBg, color: TOKENS.social,
            fontSize: 12, fontWeight: 600,
            border: `1px solid ${TOKENS.social}`,
          }}>
            <LTIcon name={s.i} size={13} color={TOKENS.social} strokeWidth={2.2} />
            {s.t}
          </div>
        ))}
      </div>

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.inkMute, textTransform: 'uppercase', marginBottom: 10 }}>
        Ambient · subtle
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 18 }}>
        {[
          { i: 'music', t: 'Music' },
          { i: 'water', t: 'Water running' },
          { i: 'wind', t: 'Wind' },
          { i: 'dog', t: 'Dog barking' },
          { i: 'car', t: 'Traffic' },
        ].map((s) => (
          <div key={s.t} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '8px 12px', borderRadius: 999,
            background: TOKENS.surface, color: TOKENS.inkSoft,
            fontSize: 12, fontWeight: 500,
            border: `1px solid ${TOKENS.hairline}`,
          }}>
            <LTIcon name={s.i} size={13} color={TOKENS.inkSoft} strokeWidth={2.2} />
            {s.t}
          </div>
        ))}
      </div>

      <button style={{
        width: '100%', padding: '12px', borderRadius: 12,
        background: 'transparent', color: TOKENS.peachDeep,
        border: `1.5px dashed ${TOKENS.peachDeep}`,
        fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
      }}>
        + Browse all 96 sounds
      </button>
    </div>
  </div>
);

// ─── Conversation summary ─────────────────────────────────────
const C_Summary = () => (
  <div style={c2s.page}>
    <div style={c2s.topbar}>
      <button style={c2s.iconBtn}><LTIcon name="close" size={20} /></button>
      <div style={{ flex: 1 }} />
      <button style={c2s.iconBtn}><LTIcon name="star" size={20} /></button>
    </div>

    <div style={{ padding: '8px 24px 16px' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: TOKENS.peachDeep, textTransform: 'uppercase' }}>That's a wrap</div>
      <div style={{
        fontFamily: TOKENS.fontDisplay, fontSize: 38, fontWeight: 500,
        letterSpacing: -1, lineHeight: 1.05, marginTop: 6,
      }}>
        Coffee with<br/>
        <em style={{ color: TOKENS.spkB, fontStyle: 'italic' }}>Maya.</em>
      </div>
      <div style={{ fontSize: 13, color: TOKENS.inkSoft, marginTop: 8 }}>
        Today · 9:33 to 10:24 AM · 51 minutes
      </div>
    </div>

    {/* Stats */}
    <div style={{ display: 'flex', gap: 8, padding: '0 16px', marginBottom: 16 }}>
      {[
        { n: '2', l: 'voices' },
        { n: '184', l: 'lines' },
        { n: '7', l: 'sounds' },
      ].map((s) => (
        <div key={s.l} style={{
          flex: 1, padding: '14px 12px', borderRadius: 14,
          background: TOKENS.surface, border: `1px solid ${TOKENS.hairline}`,
          textAlign: 'center',
        }}>
          <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 28, fontWeight: 600, color: TOKENS.ink, lineHeight: 1 }}>{s.n}</div>
          <div style={{ fontSize: 11, color: TOKENS.inkSoft, marginTop: 4, letterSpacing: 0.5, textTransform: 'uppercase', fontWeight: 600 }}>{s.l}</div>
        </div>
      ))}
    </div>

    {/* Highlight */}
    <div style={{ padding: '0 16px', flex: 1, overflowY: 'auto' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.inkMute, textTransform: 'uppercase', marginBottom: 10 }}>You starred 2</div>
      <div style={{
        padding: 16, borderRadius: 16,
        background: TOKENS.surface, borderLeft: `4px solid ${TOKENS.spkB}`,
        marginBottom: 8,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
          <LTIcon name="star" size={12} color={TOKENS.peachDeep} strokeWidth={2.4} />
          <span style={{ fontSize: 11, fontWeight: 700, color: TOKENS.spkB, letterSpacing: 0.3, textTransform: 'uppercase' }}>Maya · 9:48</span>
        </div>
        <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 18, lineHeight: 1.35, fontWeight: 500, letterSpacing: -0.2 }}>
          Honestly the background noise helps me focus. And the espresso is unreal.
        </div>
      </div>
      <div style={{
        padding: 16, borderRadius: 16,
        background: TOKENS.surface, borderLeft: `4px solid ${TOKENS.spkA}`,
        marginBottom: 16,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
          <LTIcon name="star" size={12} color={TOKENS.peachDeep} strokeWidth={2.4} />
          <span style={{ fontSize: 11, fontWeight: 700, color: TOKENS.spkA, letterSpacing: 0.3, textTransform: 'uppercase' }}>You · 10:11</span>
        </div>
        <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 18, lineHeight: 1.35, fontWeight: 500, letterSpacing: -0.2 }}>
          Let's do the bookshop in the Mission this Saturday.
        </div>
      </div>

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.inkMute, textTransform: 'uppercase', marginBottom: 10 }}>Sounds heard</div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 16 }}>
        {[
          { t: 'jazz · 28m', tone: 'ambient' },
          { t: 'laughter · 4×', tone: 'social' },
          { t: 'espresso hiss · 2×', tone: 'ambient' },
          { t: 'dishes', tone: 'ambient' },
        ].map((s) => {
          const colors = {
            ambient: { bg: TOKENS.ambientBg, fg: TOKENS.inkSoft },
            social: { bg: TOKENS.socialBg, fg: TOKENS.social },
          }[s.tone];
          return <div key={s.t} style={{ padding: '5px 10px', borderRadius: 999, background: colors.bg, color: colors.fg, fontSize: 11, fontWeight: 600 }}>{s.t}</div>;
        })}
      </div>
    </div>

    <div style={{ padding: '12px 16px 16px', display: 'flex', gap: 8, borderTop: `1px solid ${TOKENS.hairline}` }}>
      <button style={{
        flex: 1, height: 44, borderRadius: 22,
        background: 'transparent', color: TOKENS.ink,
        border: `1px solid ${TOKENS.hairline}`, fontFamily: 'inherit',
        fontSize: 13, fontWeight: 600, cursor: 'pointer',
      }}>Read full</button>
      <button style={{
        flex: 1, height: 44, borderRadius: 22,
        background: TOKENS.ink, color: '#fff', border: 'none', fontFamily: 'inherit',
        fontSize: 13, fontWeight: 600, cursor: 'pointer',
      }}>Save</button>
    </div>
  </div>
);

// ─── History list ─────────────────────────────────────────────
const C_History = () => (
  <div style={c2s.page}>
    <div style={c2s.topbar}>
      <button style={c2s.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Transcripts</div>
      <button style={c2s.iconBtn}><LTIcon name="settings" size={20} /></button>
    </div>

    <div style={{ padding: '8px 20px 4px' }}>
      <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 32, fontWeight: 500, letterSpacing: -0.8, lineHeight: 1 }}>
        47 conversations
      </div>
      <div style={{ fontSize: 12, color: TOKENS.inkSoft, marginTop: 6 }}>
        All on this phone · 318 MB · auto-delete after 30 days
      </div>
    </div>

    <div style={{ padding: '14px 16px 8px', display: 'flex', gap: 6, overflowX: 'auto' }}>
      {['All', '1:1', 'Group', 'Starred', 'With alerts'].map((c, i) => (
        <div key={c} style={{
          padding: '6px 12px', borderRadius: 999,
          background: i === 0 ? TOKENS.ink : TOKENS.surface,
          color: i === 0 ? '#fff' : TOKENS.inkSoft,
          fontSize: 12, fontWeight: 600,
          border: i === 0 ? 'none' : `1px solid ${TOKENS.hairline}`,
          flexShrink: 0,
        }}>{c}</div>
      ))}
    </div>

    <div style={{ flex: 1, overflowY: 'auto', padding: '8px 16px 16px' }}>
      {[
        { d: 'TODAY', items: [
          { t: 'Coffee with Maya', m: '9:33 AM · 51m', sp: ['M', 'Y'], spk: 2, snd: 7, urg: 0 },
        ]},
        { d: 'YESTERDAY', items: [
          { t: 'Tuesday dinner', m: '7:12 PM · 1h 23m', sp: ['M', 'J', 'P', 'Y'], spk: 4, snd: 12, urg: 0 },
          { t: 'Quick call · Mom', m: '4:08 PM · 14m', sp: ['M', 'Y'], spk: 2, snd: 1, urg: 0 },
        ]},
        { d: 'MON · APR 27', items: [
          { t: 'Standup', m: '9:00 AM · 22m', sp: ['A', 'B', 'C', 'D', 'Y'], spk: 5, snd: 2, urg: 0 },
          { t: 'At home', m: '2:14 PM · 38m', sp: ['S', 'Y'], spk: 2, snd: 4, urg: 1, urgT: 'smoke alarm' },
        ]},
      ].map((g) => (
        <div key={g.d} style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.5, color: TOKENS.inkMute, marginBottom: 8, padding: '0 4px' }}>{g.d}</div>
          {g.items.map((it, i) => (
            <div key={i} style={{
              padding: '14px 16px', borderRadius: 14,
              background: TOKENS.surface, marginBottom: 6,
              border: `1px solid ${TOKENS.hairline}`,
              ...(it.urg ? { borderColor: TOKENS.alertBg, borderLeftWidth: 4, borderLeftColor: TOKENS.alert } : {}),
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 15, fontWeight: 600 }}>{it.t}</div>
                  <div style={{ fontSize: 11, color: TOKENS.inkSoft, marginTop: 2 }}>{it.m}</div>
                </div>
                <div style={{ display: 'flex' }}>
                  {it.sp.slice(0, 4).map((s, j) => {
                    const colors = [TOKENS.spkB, TOKENS.spkC, TOKENS.spkD, TOKENS.spkA];
                    return <div key={j} style={{
                      width: 22, height: 22, borderRadius: 11,
                      background: s === 'Y' ? TOKENS.spkA : colors[j % 4],
                      color: '#fff', fontSize: 10, fontWeight: 700,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      marginLeft: j ? -6 : 0, border: `2px solid ${TOKENS.surface}`,
                    }}>{s}</div>;
                  })}
                </div>
              </div>
              {it.urg ? (
                <div style={{ marginTop: 8, padding: '5px 9px', borderRadius: 999, background: TOKENS.alertBg, color: TOKENS.alert, fontSize: 11, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 5 }}>
                  <LTIcon name="bell" size={11} color={TOKENS.alert} strokeWidth={2.4} /> {it.urgT} detected
                </div>
              ) : (
                <div style={{ marginTop: 8, fontSize: 11, color: TOKENS.inkMute }}>
                  {it.snd} ambient sound{it.snd === 1 ? '' : 's'}
                </div>
              )}
            </div>
          ))}
        </div>
      ))}
    </div>
  </div>
);

window.C_Home = C_Home;
window.C_Rewind = C_Rewind;
window.C_SoundSettings = C_SoundSettings;
window.C_Summary = C_Summary;
window.C_History = C_History;
