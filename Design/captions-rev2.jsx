// Live Transcribe — Captions, rev 2
// Combines:
//  A1 — live waveform + clock status pill (always visible)
//  B2 — tiny right-margin tag for ambient sounds
//  D1 — silence indicator
//  Transient bottom bar: settings + save (star) + pause
// Tap anywhere to reveal the bar. It auto-hides after 3s.

const { useState, useEffect, useRef } = React;

const T = {
  bg: '#1a1612', surface: '#2a231d', surfaceHi: '#332b23',
  ink: '#f5ede0', inkSoft: 'rgba(245,237,224,0.72)',
  inkMute: 'rgba(245,237,224,0.45)', inkDim: 'rgba(245,237,224,0.22)',
  line: 'rgba(245,237,224,0.08)', lineHi: 'rgba(245,237,224,0.16)',
  peach: '#e89878', peachDeep: '#c96442', peachSoft: 'rgba(232,152,120,0.18)',
  spkB: '#7ab8a4',
  fontUI: '"Inter", -apple-system, system-ui, sans-serif',
  fontDisplay: '"Fraunces", "Iowan Old Style", Georgia, serif',
};

if (typeof document !== 'undefined' && !document.getElementById('cap2-fonts')) {
  const l = document.createElement('link'); l.id = 'cap2-fonts'; l.rel = 'stylesheet';
  l.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fraunces:ital,wght@0,400;0,500;0,600;1,500&display=swap';
  document.head.appendChild(l);
}
if (typeof document !== 'undefined' && !document.getElementById('cap2-css')) {
  const s = document.createElement('style'); s.id = 'cap2-css';
  s.textContent = `
    @keyframes cw { from { transform: scaleY(0.5) } to { transform: scaleY(1.4) } }
    @keyframes breath { 0%,100% { opacity: 0.4 } 50% { opacity: 1 } }
  `;
  document.head.appendChild(s);
}

const I = ({ n, s = 18, c = 'currentColor', w = 1.8 }) => {
  const p = { width: s, height: s, viewBox: '0 0 24 24', fill: 'none', stroke: c, strokeWidth: w, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (n) {
    case 'pause': return <svg {...p}><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>;
    case 'star':  return <svg {...p}><path d="M12 3l2.6 6.2 6.4.6-4.9 4.4 1.5 6.3L12 17.3l-5.6 3.2 1.5-6.3-4.9-4.4 6.4-.6z"/></svg>;
    case 'cog':   return <svg {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>;
    case 'music': return <svg {...p}><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>;
    case 'close': return <svg {...p}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    default: return null;
  }
};

const Wave = ({ color = T.peach, n = 4 }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 2.5 }}>
    {Array.from({ length: n }).map((_, i) => (
      <div key={i} style={{
        width: 2.5, height: 4 + (i % 3) * 4, borderRadius: 1.5, background: color,
        animation: `cw ${0.6 + (i % 3) * 0.15}s ease-in-out ${i * 0.07}s infinite alternate`,
      }} />
    ))}
  </div>
);

const StatusPill = ({ children }) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 8,
    padding: '6px 12px', borderRadius: 999, background: T.surface,
    fontSize: 11, fontWeight: 600, color: T.ink, letterSpacing: 0.3,
  }}>{children}</div>
);

const SoundMarginTag = ({ icon = 'music', label = 'jazz' }) => (
  <div style={{
    position: 'absolute', top: 22, right: 24,
    fontSize: 9, color: T.inkMute, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
    display: 'flex', alignItems: 'center', gap: 5,
  }}>
    <I n={icon} s={11} c={T.inkMute} w={2} /> {label}
  </div>
);

// ─── Captions screen — full interactive demo ──────────────────
const CaptionsScreen = ({ silent = false, settingsOpen: settingsOpenInitial = false, hidden = false }) => {
  const [visible, setVisible] = useState(!hidden);
  const [settingsOpen, setSettingsOpen] = useState(settingsOpenInitial);
  const timer = useRef(null);

  const reveal = () => {
    if (settingsOpen) return;
    setVisible(true);
    clearTimeout(timer.current);
    timer.current = setTimeout(() => setVisible(false), 3000);
  };
  useEffect(() => () => clearTimeout(timer.current), []);

  return (
    <div onClick={reveal} style={{
      flex: 1, display: 'flex', flexDirection: 'column',
      background: T.bg, padding: '18px 24px 20px', cursor: 'pointer',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* Always-visible status pill (A1) */}
      <StatusPill>
        <Wave />
        <span style={{ fontVariantNumeric: 'tabular-nums' }}>Listening · 0:08:42</span>
      </StatusPill>

      {/* Right-margin sound tag (B2) — only when not silent */}
      {!silent && <SoundMarginTag icon="music" label="jazz" />}

      {silent ? (
        // ─── D1: silence indicator ─────────────────────────────
        <>
          <div style={{
            fontFamily: T.fontDisplay, fontSize: 18, lineHeight: 1.3,
            color: T.inkDim, marginTop: 24,
          }}>
            And the espresso is unreal.
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '12px 18px', borderRadius: 999,
              background: T.surface, color: T.inkMute,
              fontSize: 12, fontStyle: 'italic',
            }}>
              <span style={{
                width: 6, height: 6, borderRadius: 3, background: T.inkMute,
                animation: 'breath 2s ease-in-out infinite',
              }} />
              14 seconds of silence
            </div>
          </div>
        </>
      ) : (
        // ─── Normal captions ───────────────────────────────────
        <>
          <div style={{
            fontFamily: T.fontDisplay, fontSize: 20, lineHeight: 1.3,
            color: T.inkDim, marginTop: 28, marginBottom: 16,
          }}>
            A goose chased me around the lake.
          </div>
          <div style={{
            fontFamily: T.fontDisplay, fontSize: 32, fontWeight: 500,
            lineHeight: 1.2, letterSpacing: -0.8, color: T.ink,
          }}>
            And the espresso is unreal<span style={{
              display: 'inline-block', width: 3, height: 26, background: T.peach,
              marginLeft: 3, verticalAlign: 'middle',
            }} />
          </div>
          <div style={{ flex: 1 }} />
        </>
      )}

      {/* Tap hint when hidden */}
      <div style={{
        position: 'absolute', bottom: 26, left: 0, right: 0, textAlign: 'center',
        fontSize: 9, color: T.inkDim, fontWeight: 600, letterSpacing: 1.5,
        opacity: visible || settingsOpen ? 0 : 1,
        transition: 'opacity 0.3s', pointerEvents: 'none',
      }}>
        TAP FOR CONTROLS
      </div>

      {/* Transient control bar */}
      <div onClick={(e) => e.stopPropagation()} style={{
        position: 'absolute', left: 16, right: 16, bottom: 16,
        padding: '10px 12px', borderRadius: 28,
        background: 'rgba(42,35,29,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        border: `1px solid ${T.lineHi}`,
        boxShadow: '0 12px 32px rgba(0,0,0,0.4)',
        display: 'flex', alignItems: 'center', gap: 6,
        transform: visible ? 'translateY(0)' : 'translateY(90px)',
        opacity: visible ? 1 : 0,
        transition: 'transform 0.25s cubic-bezier(0.2,0.8,0.2,1), opacity 0.2s',
      }}>
        <button onClick={() => setSettingsOpen(true)} style={{
          width: 40, height: 40, borderRadius: 20, border: 'none',
          background: 'transparent', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <I n="cog" s={18} c={T.inkSoft} />
        </button>
        <button style={{
          width: 40, height: 40, borderRadius: 20, border: 'none',
          background: 'transparent', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <I n="star" s={18} c={T.inkSoft} />
        </button>
        <div style={{ flex: 1 }} />
        <button style={{
          width: 44, height: 44, borderRadius: 22, border: 'none',
          background: T.peach, color: T.bg, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <I n="pause" s={18} c={T.bg} w={2.4} />
        </button>
      </div>

      {/* Settings bottom sheet */}
      {settingsOpen && (
        <div onClick={() => setSettingsOpen(false)} style={{
          position: 'absolute', inset: 0, zIndex: 5,
          background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)',
        }}>
          <div onClick={(e) => e.stopPropagation()} style={{
            position: 'absolute', left: 0, right: 0, bottom: 0,
            background: T.surface, borderTopLeftRadius: 22, borderTopRightRadius: 22,
            padding: '12px 0 22px',
            border: `1px solid ${T.line}`, borderBottom: 'none',
          }}>
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 8 }}>
              <div style={{ width: 38, height: 4, borderRadius: 2, background: T.lineHi }} />
            </div>
            <div style={{ padding: '4px 22px 12px', display: 'flex', alignItems: 'center' }}>
              <div style={{ fontFamily: T.fontDisplay, fontSize: 19, fontWeight: 600, letterSpacing: -0.4 }}>
                Adjust
              </div>
              <div style={{ flex: 1 }} />
              <button onClick={() => setSettingsOpen(false)} style={{
                width: 28, height: 28, borderRadius: 14, border: 'none',
                background: 'transparent', cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <I n="close" s={16} c={T.inkSoft} />
              </button>
            </div>

            {/* Text size */}
            <div style={{ padding: '12px 22px' }}>
              <div style={{ fontSize: 11, color: T.inkMute, fontWeight: 600, letterSpacing: 0.5, marginBottom: 8 }}>
                TEXT SIZE
              </div>
              <div style={{ display: 'flex', gap: 6, background: T.bg, borderRadius: 999, padding: 3 }}>
                {[
                  { l: 'A', s: 11, v: 'small' },
                  { l: 'A', s: 13, v: 'regular' },
                  { l: 'A', s: 16, v: 'large', sel: true },
                  { l: 'A', s: 20, v: 'huge' },
                ].map((opt) => (
                  <button key={opt.v} style={{
                    flex: 1, padding: '8px 0', borderRadius: 999, border: 'none',
                    background: opt.sel ? T.peach : 'transparent',
                    color: opt.sel ? T.bg : T.inkSoft, cursor: 'pointer', fontFamily: 'inherit',
                    fontSize: opt.s, fontWeight: 600,
                  }}>{opt.l}</button>
                ))}
              </div>
            </div>

            {/* Show ambient sounds */}
            <div style={{
              padding: '12px 22px', display: 'flex', alignItems: 'center',
              borderTop: `1px solid ${T.line}`,
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 500 }}>Show ambient sounds</div>
                <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>
                  Tags like "jazz" in the corner
                </div>
              </div>
              <div style={{
                width: 36, height: 20, borderRadius: 10, background: T.peach,
                position: 'relative',
              }}>
                <div style={{
                  position: 'absolute', top: 2, left: 18, width: 16, height: 16,
                  borderRadius: 8, background: '#fff',
                }} />
              </div>
            </div>

            {/* Alert vibration */}
            <div style={{
              padding: '12px 22px', display: 'flex', alignItems: 'center',
              borderTop: `1px solid ${T.line}`,
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 500 }}>Vibrate on alerts</div>
                <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>
                  Smoke alarm, doorbell, baby crying
                </div>
              </div>
              <div style={{
                width: 36, height: 20, borderRadius: 10, background: T.peach,
                position: 'relative',
              }}>
                <div style={{
                  position: 'absolute', top: 2, left: 18, width: 16, height: 16,
                  borderRadius: 8, background: '#fff',
                }} />
              </div>
            </div>

            {/* More settings link */}
            <div style={{
              padding: '14px 22px 4px', borderTop: `1px solid ${T.line}`,
              display: 'flex', alignItems: 'center',
            }}>
              <div style={{ flex: 1, fontSize: 13, color: T.inkSoft }}>
                Sound recognition, diarization, more…
              </div>
              <button style={{
                background: 'transparent', border: 'none', color: T.peach,
                fontSize: 12, fontWeight: 700, fontFamily: 'inherit',
                textTransform: 'uppercase', letterSpacing: 0.5, cursor: 'pointer',
              }}>All settings →</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const Phone = ({ children }) => (
  <div style={{
    width: 380, height: 820, borderRadius: 36, overflow: 'hidden',
    background: T.bg, border: '8px solid #29231d',
    boxShadow: '0 30px 80px rgba(0,0,0,0.4)',
    display: 'flex', flexDirection: 'column', fontFamily: T.fontUI, color: T.ink,
  }}>
    <div style={{ height: 28, padding: '0 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 11, fontWeight: 600 }}>
      <span>9:41</span>
      <span style={{ width: 14, height: 8, border: `1px solid ${T.ink}`, borderRadius: 1.5 }} />
    </div>
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>{children}</div>
    <div style={{ height: 18, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ width: 90, height: 3, borderRadius: 2, background: T.ink, opacity: 0.45 }} />
    </div>
  </div>
);

const App = () => (
  <DesignCanvas>
    <DCSection id="hdr" title="Captions · rev 2" subtitle="A1 status pill + B2 right-margin sound tag + D1 silence indicator. Transient bar holds settings, save (star) and pause.">
      <DCPostIt top={20} left={40} rotate={-2} width={320}>
        First artboard is interactive — tap the phone to bring the bar up. Tap the cog to open quick settings as a bottom sheet. Other artboards show the controls-revealed and silence states statically.
      </DCPostIt>
    </DCSection>

    <DCSection id="states" title="States">
      <DCArtboard id="live" label="Live · controls hidden (tap to reveal)" width={380} height={820}>
        <Phone><CaptionsScreen /></Phone>
      </DCArtboard>
      <DCArtboard id="revealed" label="Live · controls revealed" width={380} height={820}>
        <Phone><CaptionsScreen hidden={false} /></Phone>
      </DCArtboard>
      <DCArtboard id="settings" label="Quick settings sheet" width={380} height={820}>
        <Phone><CaptionsScreen settingsOpen={true} /></Phone>
      </DCArtboard>
      <DCArtboard id="silent" label="Silence state (D1)" width={380} height={820}>
        <Phone><CaptionsScreen silent={true} hidden={true} /></Phone>
      </DCArtboard>
    </DCSection>

    <DCPostIt top={20} right={40} rotate={2} width={300}>
      Bar holds 3 controls: cog (settings sheet), star (save this moment), pause (end). Quick settings keeps the in-conversation knobs — text size, ambient sounds toggle, vibration — with a link out to full settings for the rest.
    </DCPostIt>
  </DesignCanvas>
);

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
