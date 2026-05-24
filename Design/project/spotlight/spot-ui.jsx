// Spotlight — shared UI primitives

// Status bar (Android-ish, dark theme)
const StatusBar = () => (
  <div style={{
    height: 28, padding: '0 14px', flexShrink: 0,
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    fontSize: 11, fontWeight: 600, color: T.ink,
  }}>
    <span style={{ fontVariantNumeric: 'tabular-nums' }}>9:41</span>
    <span style={{ display: 'flex', gap: 5, alignItems: 'center', opacity: 0.85 }}>
      <span style={{ fontSize: 10 }}>●●●●○</span>
      <span style={{ width: 14, height: 8, borderRadius: 1.5, border: `1px solid ${T.ink}`, position: 'relative' }}>
        <span style={{ position: 'absolute', inset: 1, background: T.ink, borderRadius: 0.5, width: '70%' }} />
      </span>
    </span>
  </div>
);

const NavBar = () => (
  <div style={{ height: 18, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
    <div style={{ width: 90, height: 3, borderRadius: 2, background: T.ink, opacity: 0.45 }} />
  </div>
);

// Top bar
const TopBar = ({ left, title, subtitle, right, transparent }) => (
  <div style={{
    height: 52, padding: '0 12px', flexShrink: 0,
    display: 'flex', alignItems: 'center', gap: 8,
    background: transparent ? 'transparent' : 'transparent',
  }}>
    {left}
    <div style={{ flex: 1, minWidth: 0 }}>
      {title && <div style={{ fontSize: 14, fontWeight: 600, color: T.ink, lineHeight: 1.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>}
      {subtitle && <div style={{ fontSize: 11, color: T.inkMute, lineHeight: 1.2, marginTop: 1 }}>{subtitle}</div>}
    </div>
    {right}
  </div>
);

const IconBtn = ({ name, onClick, color = T.ink, size = 20 }) => (
  <button onClick={onClick} style={{
    width: 40, height: 40, borderRadius: 20, border: 'none', background: 'transparent',
    cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
    color,
  }}>
    <SpIcon name={name} size={size} color={color} />
  </button>
);

const PrivacyPill = () => (
  <span style={{
    display: 'inline-flex', alignItems: 'center', gap: 5,
    padding: '4px 9px', borderRadius: 999,
    background: T.peachSoft, color: T.peach,
    fontSize: 10, fontWeight: 700, letterSpacing: 0.6,
  }}>
    <SpIcon name="cpu" size={9} color={T.peach} strokeWidth={2.4} />
    ON-DEVICE
  </span>
);

// Speaker name + avatar + waveform
const SpeakerHeader = ({ name, speaking, accent }) => {
  const sp = SPK[name] || { color: accent || T.peach, initial: name[0] };
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{
        width: 32, height: 32, borderRadius: 16, background: sp.color, color: T.bg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 13, fontWeight: 700, letterSpacing: -0.3,
      }}>{sp.initial}</div>
      <div>
        <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: -0.2, color: T.ink }}>{name}</div>
        {speaking && <div style={{ fontSize: 10, color: T.peach, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase', marginTop: 1 }}>speaking</div>}
      </div>
      {speaking && (
        <div style={{ marginLeft: 'auto', display: 'flex', gap: 3 }}>
          {[10, 18, 8, 16, 12, 14, 7].map((h, i) => (
            <div key={i} className={`spwave-${i}`} style={{
              width: 3, height: h, borderRadius: 2, background: sp.color, opacity: 0.5 + (i % 2) * 0.5,
              animation: `spwave ${0.6 + (i % 3) * 0.2}s ease-in-out ${i * 0.07}s infinite alternate`,
            }} />
          ))}
        </div>
      )}
    </div>
  );
};

// Sound chip — three semantic tones
const SoundChip = ({ icon, label, time, tone = 'ambient', strong }) => {
  const colors = {
    ambient: { bg: T.ambientSoft, fg: T.inkSoft, border: 'transparent' },
    social:  { bg: T.socialSoft,  fg: T.social,  border: 'transparent' },
    alert:   { bg: T.alertSoft,   fg: T.alert,   border: T.alert },
  }[tone];
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '6px 11px', borderRadius: 999,
      background: colors.bg, color: colors.fg,
      fontSize: 12, fontWeight: 600,
      border: `1px solid ${colors.border}`,
      ...(strong ? { boxShadow: `0 0 0 2px ${T.alertSoft}` } : {}),
    }}>
      <SpIcon name={icon} size={12} color={colors.fg} strokeWidth={2.2} />
      <span>{label}</span>
      {time && <span style={{ opacity: 0.55, fontVariantNumeric: 'tabular-nums', fontWeight: 500 }}>{time}</span>}
    </div>
  );
};

// Big primary button
const PrimaryBtn = ({ children, onClick, fill = T.peach, color = T.bg, full }) => (
  <button onClick={onClick} style={{
    height: 56, padding: full ? '0' : '0 28px', borderRadius: 28,
    background: fill, color, border: 'none', cursor: 'pointer',
    fontSize: 17, fontWeight: 700, fontFamily: 'inherit',
    width: full ? '100%' : 'auto',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10,
  }}>{children}</button>
);

const GhostBtn = ({ children, onClick, full }) => (
  <button onClick={onClick} style={{
    height: 48, padding: full ? '0' : '0 22px', borderRadius: 24,
    background: T.surfaceLo, color: T.ink,
    border: `1px solid ${T.lineHi}`, cursor: 'pointer',
    fontSize: 14, fontWeight: 600, fontFamily: 'inherit',
    width: full ? '100%' : 'auto',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
  }}>{children}</button>
);

// Animated waveform (controls bar)
const Waveform = ({ color = T.peach, count = 14, height = 18 }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
    {Array.from({ length: count }).map((_, i) => (
      <div key={i} style={{
        width: 3, borderRadius: 2, background: color,
        height: 4 + Math.abs(Math.sin(i * 0.5)) * height,
        opacity: 0.4 + (i % 3) * 0.25,
        animation: `spwave ${0.7 + (i % 3) * 0.2}s ease-in-out ${i * 0.05}s infinite alternate`,
      }} />
    ))}
  </div>
);

// CSS keyframes — register once
if (typeof document !== 'undefined' && !document.getElementById('spot-css')) {
  const s = document.createElement('style');
  s.id = 'spot-css';
  s.textContent = `
    @keyframes spwave { from { transform: scaleY(0.5); } to { transform: scaleY(1.2); } }
    @keyframes spfadein { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }
    @keyframes spcaret { 50% { opacity: 0.2; } }
    @keyframes sppulse { 0%,100% { box-shadow: 0 0 0 0 rgba(232,90,69,0.6); } 50% { box-shadow: 0 0 0 16px rgba(232,90,69,0); } }
    .sp-fade-in { animation: spfadein 0.4s cubic-bezier(0.2,0.8,0.2,1); }
    .sp-caret { animation: spcaret 1s steps(2) infinite; }
    .sp-pulse { animation: sppulse 1.5s ease-out infinite; }
    .sp-no-scrollbar::-webkit-scrollbar { display: none; }
    .sp-no-scrollbar { scrollbar-width: none; }
  `;
  document.head.appendChild(s);
}

Object.assign(window, {
  StatusBar, NavBar, TopBar, IconBtn, PrivacyPill,
  SpeakerHeader, SoundChip, PrimaryBtn, GhostBtn, Waveform,
});
