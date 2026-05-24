// Spotlight — History, Settings, Summary screens

const { useState: uS2 } = React;

// ─── History list ─────────────────────────────────────────────
const HistoryScreen = ({ onBack, onOpen }) => {
  const [filter, setFilter] = uS2('All');
  const groups = [
    { d: 'TODAY', items: [
      { t: 'Coffee with Maya', m: '9:33 AM · 51m', sp: ['M','Y'], snd: 7, urg: false },
    ]},
    { d: 'YESTERDAY', items: [
      { t: 'Tuesday dinner', m: '7:12 PM · 1h 23m', sp: ['M','J','P','Y'], snd: 12, urg: false },
      { t: 'Quick call · Mom', m: '4:08 PM · 14m', sp: ['M','Y'], snd: 1, urg: false },
    ]},
    { d: 'MON · APR 27', items: [
      { t: 'Standup', m: '9:00 AM · 22m', sp: ['A','B','C','D','Y'], snd: 2, urg: false },
      { t: 'At home', m: '2:14 PM · 38m', sp: ['S','Y'], snd: 4, urg: true, urgT: 'smoke alarm' },
    ]},
  ];

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
      <TopBar
        left={<IconBtn name="back" onClick={onBack} color={T.inkSoft} />}
        title="Transcripts"
        right={<IconBtn name="settings" color={T.inkSoft} />}
      />

      <div style={{ padding: '4px 24px 4px' }}>
        <div style={{ fontFamily: T.fontDisplay, fontSize: 32, fontWeight: 500, letterSpacing: -1, lineHeight: 1 }}>
          47 conversations
        </div>
        <div style={{ fontSize: 12, color: T.inkMute, marginTop: 6 }}>
          All on this phone · 318 MB · auto-delete after 30 days
        </div>
      </div>

      <div className="sp-no-scrollbar" style={{ padding: '14px 16px 8px', display: 'flex', gap: 6, overflowX: 'auto' }}>
        {['All', '1:1', 'Group', 'Starred', 'With alerts'].map((c) => (
          <button key={c} onClick={() => setFilter(c)} style={{
            padding: '7px 14px', borderRadius: 999,
            background: filter === c ? T.peach : T.surface,
            color: filter === c ? T.bg : T.inkSoft,
            fontSize: 12, fontWeight: 600, fontFamily: 'inherit',
            border: filter === c ? 'none' : `1px solid ${T.line}`,
            flexShrink: 0, cursor: 'pointer',
          }}>{c}</button>
        ))}
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 16px 16px' }}>
        {groups.map((g) => (
          <div key={g.d} style={{ marginBottom: 18 }}>
            <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.5, color: T.inkMute, marginBottom: 8, padding: '0 4px' }}>{g.d}</div>
            {g.items.map((it, i) => (
              <button key={i} onClick={onOpen} style={{
                width: '100%', padding: '14px 16px', borderRadius: 14, marginBottom: 6,
                background: T.surface, color: T.ink, fontFamily: 'inherit', textAlign: 'left',
                border: `1px solid ${it.urg ? T.alertSoft : T.line}`,
                borderLeft: it.urg ? `4px solid ${T.alert}` : `1px solid ${T.line}`,
                cursor: 'pointer',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, fontWeight: 600 }}>{it.t}</div>
                    <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>{it.m}</div>
                  </div>
                  <div style={{ display: 'flex' }}>
                    {it.sp.slice(0, 4).map((s, j) => {
                      const colors = [T.spkB, T.spkC, T.spkD, T.spkA];
                      return <div key={j} style={{
                        width: 22, height: 22, borderRadius: 11,
                        background: s === 'Y' ? T.spkA : colors[j % 4],
                        color: T.bg, fontSize: 10, fontWeight: 700,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        marginLeft: j ? -6 : 0, border: `2px solid ${T.surface}`,
                      }}>{s}</div>;
                    })}
                  </div>
                </div>
                {it.urg ? (
                  <div style={{ marginTop: 8, padding: '4px 9px', borderRadius: 999, background: T.alertSoft, color: T.alert, fontSize: 11, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 5 }}>
                    <SpIcon name="bell" size={11} color={T.alert} strokeWidth={2.4} /> {it.urgT} detected
                  </div>
                ) : (
                  <div style={{ marginTop: 6, fontSize: 11, color: T.inkMute }}>
                    {it.snd} ambient sound{it.snd === 1 ? '' : 's'}
                  </div>
                )}
              </button>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── Settings ─────────────────────────────────────────────────
const SettingsScreen = ({ onBack, onSounds }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
    <TopBar
      left={<IconBtn name="back" onClick={onBack} color={T.inkSoft} />}
      title="Settings"
    />
    <div style={{ flex: 1, overflowY: 'auto', padding: '8px 16px 24px' }}>
      <div style={{ padding: '0 8px 16px' }}>
        <div style={{ fontFamily: T.fontDisplay, fontSize: 28, fontWeight: 500, letterSpacing: -0.6 }}>Make it yours.</div>
      </div>

      {[
        { title: 'Captions', items: [
          { label: 'Text size', value: 'Large', icon: 'arrow' },
          { label: 'Show speaker colors', toggle: true, on: true },
          { label: 'Emphasize sentence end', toggle: true, on: true },
        ]},
        { title: 'Sound recognition', items: [
          { label: 'What we listen for', value: '24 sounds', icon: 'arrow', onClick: onSounds },
          { label: 'Vibrate on alerts', toggle: true, on: true },
          { label: 'Flash screen on alerts', toggle: true, on: false },
        ]},
        { title: 'Privacy', items: [
          { label: 'Auto-delete transcripts', value: '30 days', icon: 'arrow' },
          { label: 'Save audio with transcript', toggle: true, on: false, sub: 'Off — only text is kept' },
          { label: 'Export all transcripts', icon: 'export' },
          { label: 'Erase all data', destructive: true, icon: 'trash' },
        ]},
      ].map((sec) => (
        <div key={sec.title} style={{ marginBottom: 22 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.peach, padding: '0 8px 8px' }}>{sec.title.toUpperCase()}</div>
          <div style={{ background: T.surface, borderRadius: 16, border: `1px solid ${T.line}`, overflow: 'hidden' }}>
            {sec.items.map((it, i) => (
              <button key={i} onClick={it.onClick} style={{
                width: '100%', padding: '14px 16px',
                background: 'transparent', border: 'none', color: it.destructive ? T.alert : T.ink,
                fontFamily: 'inherit', cursor: 'pointer',
                display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
                borderTop: i ? `1px solid ${T.line}` : 'none',
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 500 }}>{it.label}</div>
                  {it.sub && <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>{it.sub}</div>}
                </div>
                {it.toggle ? (
                  <div style={{
                    width: 36, height: 20, borderRadius: 10,
                    background: it.on ? T.peach : T.surfaceLo, position: 'relative',
                    transition: 'background 0.15s',
                  }}>
                    <div style={{
                      position: 'absolute', top: 2, left: it.on ? 18 : 2,
                      width: 16, height: 16, borderRadius: 8, background: '#fff',
                      transition: 'left 0.15s',
                    }} />
                  </div>
                ) : it.value ? (
                  <span style={{ fontSize: 13, color: T.inkSoft }}>{it.value}</span>
                ) : null}
                {it.icon && <SpIcon name={it.icon} size={14} color={it.destructive ? T.alert : T.inkMute} />}
              </button>
            ))}
          </div>
        </div>
      ))}
    </div>
  </div>
);

// ─── Sounds settings (sub-page) ───────────────────────────────
const SoundSettingsScreen = ({ onBack }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
    <TopBar
      left={<IconBtn name="back" onClick={onBack} color={T.inkSoft} />}
      title="Sound recognition"
    />
    <div style={{ padding: '4px 24px 0' }}>
      <div style={{ fontFamily: T.fontDisplay, fontSize: 28, fontWeight: 500, letterSpacing: -0.6, lineHeight: 1.15 }}>
        What should we<br/><em style={{ color: T.peach, fontStyle: 'italic' }}>watch for?</em>
      </div>
      <div style={{ fontSize: 13, color: T.inkSoft, marginTop: 8 }}>
        96 sounds available. Tap to mute or set urgency.
      </div>
    </div>

    <div style={{ flex: 1, overflowY: 'auto', padding: '20px 16px' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.alert, marginBottom: 10 }}>URGENT · ALERT ME LOUD</div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
        {[['bell','Smoke alarm'],['bell','Carbon monoxide'],['baby','Baby crying'],['door','Doorbell'],['phone','Phone ringing']].map(([i, t]) => (
          <div key={t} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '8px 12px', borderRadius: 999,
            background: T.alert, color: '#fff',
            fontSize: 12, fontWeight: 600,
          }}>
            <SpIcon name={i} size={13} color="#fff" strokeWidth={2.2} />
            {t}
            <SpIcon name="check" size={12} color="#fff" strokeWidth={2.6} />
          </div>
        ))}
      </div>

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.social, marginBottom: 10 }}>SOCIAL · SHOW INLINE</div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
        {[['volume','Laughter'],['volume','Applause'],['volume','Cheering'],['volume','Singing']].map(([i, t]) => (
          <div key={t} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '8px 12px', borderRadius: 999,
            background: T.socialSoft, color: T.social, border: `1px solid ${T.social}`,
            fontSize: 12, fontWeight: 600,
          }}>
            <SpIcon name={i} size={13} color={T.social} strokeWidth={2.2} />
            {t}
          </div>
        ))}
      </div>

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.inkMute, marginBottom: 10 }}>AMBIENT · SUBTLE</div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
        {[['music','Music'],['water','Water'],['wind','Wind'],['music','Dishes']].map(([i, t]) => (
          <div key={t} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '8px 12px', borderRadius: 999,
            background: T.surface, color: T.inkSoft, border: `1px solid ${T.line}`,
            fontSize: 12, fontWeight: 500,
          }}>
            <SpIcon name={i} size={13} color={T.inkSoft} strokeWidth={2.2} />
            {t}
          </div>
        ))}
      </div>

      <button style={{
        width: '100%', padding: 14, borderRadius: 14,
        background: 'transparent', color: T.peach,
        border: `1.5px dashed ${T.peach}`,
        fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
      }}>+ Browse all 96 sounds</button>
    </div>
  </div>
);

// ─── Summary ──────────────────────────────────────────────────
const SummaryScreen = ({ onClose }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
    <TopBar
      left={<IconBtn name="close" onClick={onClose} color={T.inkSoft} />}
      right={<IconBtn name="star" color={T.peach} />}
    />
    <div style={{ padding: '0 24px 16px' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 2, color: T.peach }}>THAT'S A WRAP</div>
      <div style={{ fontFamily: T.fontDisplay, fontSize: 40, fontWeight: 500, letterSpacing: -1.4, lineHeight: 1.02, marginTop: 6 }}>
        Coffee with<br/><em style={{ color: T.spkB, fontStyle: 'italic' }}>Maya.</em>
      </div>
      <div style={{ fontSize: 13, color: T.inkSoft, marginTop: 8 }}>Today · 9:33–10:24 AM · 51m</div>
    </div>

    <div style={{ display: 'flex', gap: 8, padding: '0 16px', marginBottom: 16 }}>
      {[['2','voices'],['184','lines'],['7','sounds']].map(([n,l]) => (
        <div key={l} style={{ flex: 1, padding: '14px 12px', borderRadius: 14, background: T.surface, border: `1px solid ${T.line}`, textAlign: 'center' }}>
          <div style={{ fontFamily: T.fontDisplay, fontSize: 28, fontWeight: 600, lineHeight: 1 }}>{n}</div>
          <div style={{ fontSize: 10, color: T.inkMute, marginTop: 4, letterSpacing: 0.5, textTransform: 'uppercase', fontWeight: 700 }}>{l}</div>
        </div>
      ))}
    </div>

    <div style={{ padding: '0 16px', flex: 1, overflowY: 'auto' }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.inkMute, marginBottom: 10 }}>YOU STARRED 2</div>
      {[
        { n: 'Maya', c: T.spkB, t: 'Honestly the background noise helps me focus. And the espresso is unreal.', tm: '9:48' },
        { n: 'You',  c: T.spkA, t: "Let's do the bookshop in the Mission this Saturday.", tm: '10:11' },
      ].map((s, i) => (
        <div key={i} style={{
          padding: 16, borderRadius: 16, marginBottom: 8,
          background: T.surface, borderLeft: `4px solid ${s.c}`,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
            <SpIcon name="star" size={11} color={T.peach} strokeWidth={2.4} />
            <span style={{ fontSize: 11, fontWeight: 700, color: s.c, letterSpacing: 0.4, textTransform: 'uppercase' }}>{s.n} · {s.tm}</span>
          </div>
          <div style={{ fontFamily: T.fontDisplay, fontSize: 18, lineHeight: 1.35, fontWeight: 500, letterSpacing: -0.2 }}>{s.t}</div>
        </div>
      ))}

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.inkMute, marginTop: 16, marginBottom: 10 }}>SOUNDS HEARD</div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 16 }}>
        <SoundChip icon="music" label="jazz · 28m" tone="ambient" />
        <SoundChip icon="volume" label="laughter · 4×" tone="social" />
        <SoundChip icon="wind" label="espresso hiss · 2×" tone="ambient" />
      </div>
    </div>

    <div style={{ padding: '12px 16px 16px', display: 'flex', gap: 10, borderTop: `1px solid ${T.line}` }}>
      <GhostBtn full><SpIcon name="export" size={14} color={T.ink} />Export</GhostBtn>
      <PrimaryBtn full onClick={onClose}><SpIcon name="check" size={16} color={T.bg} strokeWidth={2.4} />Save</PrimaryBtn>
    </div>
  </div>
);

Object.assign(window, { HistoryScreen, SettingsScreen, SoundSettingsScreen, SummaryScreen });
