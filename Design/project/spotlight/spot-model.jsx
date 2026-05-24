// Spotlight — Model download flow (3 moments)
// Pre-download (set expectations) → Downloading (progress + teach while waiting) → Ready

const ModelHeroIcon = ({ size = 80 }) => (
  <svg width={size} height={size} viewBox="0 0 80 80" fill="none">
    <defs>
      <radialGradient id="mdg" cx="50%" cy="40%" r="60%">
        <stop offset="0%" stopColor={T.peach} stopOpacity="0.35" />
        <stop offset="100%" stopColor={T.peach} stopOpacity="0" />
      </radialGradient>
    </defs>
    <circle cx="40" cy="40" r="38" fill="url(#mdg)" />
    {/* Phone outline */}
    <rect x="24" y="14" width="32" height="52" rx="5" stroke={T.peach} strokeWidth="2" />
    {/* Cube inside (model) */}
    <g transform="translate(40 42)">
      <path d="M-10 -4 L0 -10 L10 -4 L10 8 L0 14 L-10 8 Z" fill={T.peach} fillOpacity="0.18" stroke={T.peach} strokeWidth="1.6" strokeLinejoin="round" />
      <path d="M-10 -4 L0 2 L10 -4 M0 2 V14" stroke={T.peach} strokeWidth="1.6" strokeLinejoin="round" />
    </g>
  </svg>
);

// ─── Step 1: Pre-download — set expectations ──────────────────
const ModelPrepScreen = ({ onStart, onSkip }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
    <div style={{ padding: '0 28px', display: 'flex', flexDirection: 'column', flex: 1 }}>
      <div style={{ marginTop: 32, fontSize: 11, fontWeight: 700, letterSpacing: 2, color: T.peach }}>ONE-TIME SETUP</div>
      <div style={{
        fontFamily: T.fontDisplay, fontSize: 50, fontWeight: 500,
        lineHeight: 0.98, letterSpacing: -1.8, color: T.ink, marginTop: 18,
      }}>
        Let's bring<br/>the model<br/>
        <em style={{ color: T.peach, fontStyle: 'italic' }}>onto your phone.</em>
      </div>
      <div style={{ fontSize: 16, lineHeight: 1.5, color: T.inkSoft, marginTop: 18, maxWidth: 320 }}>
        This is what makes everything work without a cloud. You only do this once.
      </div>

      {/* Download specs card */}
      <div style={{
        marginTop: 28, padding: 18, borderRadius: 18,
        background: T.surface, border: `1px solid ${T.line}`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, paddingBottom: 14, borderBottom: `1px solid ${T.line}`, marginBottom: 14 }}>
          <ModelHeroIcon size={56} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Spotlight transcription model</div>
            <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>v3.2 · English + Spanish</div>
          </div>
        </div>

        {[
          { ic: 'export', l: '1.5 GB', s: 'About 90 seconds on Wi-Fi' },
          { ic: 'wind', l: 'Wi-Fi only', s: 'We won\'t use your cellular data' },
          { ic: 'lock', l: 'Stays on this phone', s: 'Never sent back to a server' },
        ].map((r) => (
          <div key={r.l} style={{ display: 'flex', alignItems: 'flex-start', gap: 12, paddingBottom: 12 }}>
            <div style={{
              width: 32, height: 32, borderRadius: 10, background: T.peachSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <SpIcon name={r.ic} size={14} color={T.peach} strokeWidth={2.2} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: T.ink }}>{r.l}</div>
              <div style={{ fontSize: 12, color: T.inkMute, marginTop: 1 }}>{r.s}</div>
            </div>
          </div>
        ))}
      </div>

      <div style={{ flex: 1 }} />

      <PrimaryBtn full onClick={onStart}>
        <SpIcon name="export" size={16} color={T.bg} strokeWidth={2.4} />
        Download over Wi-Fi
      </PrimaryBtn>
      <button onClick={onSkip} style={{
        marginTop: 10, marginBottom: 16, height: 36, background: 'transparent', border: 'none',
        color: T.inkSoft, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer', fontWeight: 500,
      }}>Use a smaller model (320 MB) instead</button>
    </div>
  </div>
);

// ─── Step 2: Downloading — make the wait useful ───────────────
const ModelDownloadingScreen = ({ pct = 42, mb = 630 }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
    <div style={{ padding: '0 28px', display: 'flex', flexDirection: 'column', flex: 1 }}>
      <div style={{ marginTop: 32, fontSize: 11, fontWeight: 700, letterSpacing: 2, color: T.peach }}>DOWNLOADING · ~52s LEFT</div>

      <div style={{
        fontFamily: T.fontDisplay, fontSize: 44, fontWeight: 500,
        lineHeight: 1, letterSpacing: -1.6, color: T.ink, marginTop: 16,
      }}>
        Almost yours.<br/>
        <em style={{ color: T.peach, fontStyle: 'italic' }}>{pct}% done.</em>
      </div>

      {/* Progress bar with peach gradient */}
      <div style={{ marginTop: 24, marginBottom: 8 }}>
        <div style={{
          height: 8, borderRadius: 4, background: T.surface, overflow: 'hidden', position: 'relative',
        }}>
          <div style={{
            position: 'absolute', left: 0, top: 0, bottom: 0,
            width: `${pct}%`, borderRadius: 4,
            background: `linear-gradient(90deg, ${T.peachDeep}, ${T.peach})`,
            boxShadow: `0 0 12px ${T.peachGlow}`,
            transition: 'width 0.4s',
          }} />
          {/* Animated shimmer */}
          <div style={{
            position: 'absolute', left: `${pct - 10}%`, top: 0, bottom: 0, width: '20%',
            background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.25), transparent)',
            animation: 'spshim 1.4s ease-in-out infinite',
          }} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: T.inkMute, marginTop: 8, fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>
          <span>{mb} MB of 1.5 GB</span>
          <span>Wi-Fi · 18 MB/s</span>
        </div>
      </div>

      {/* While-you-wait teach card */}
      <div style={{ marginTop: 22, padding: 18, borderRadius: 18, background: T.surface, border: `1px solid ${T.line}` }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.5, color: T.peach, marginBottom: 10 }}>WHILE YOU WAIT · 2 OF 4</div>
        <div style={{ fontFamily: T.fontDisplay, fontSize: 22, fontWeight: 500, lineHeight: 1.25, letterSpacing: -0.3, color: T.ink }}>
          Sound recognition catches <em style={{ color: T.peach, fontStyle: 'italic' }}>96 different sounds</em>, from doorbells to smoke alarms.
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 14 }}>
          <SoundChip icon="bell" label="Smoke alarm" tone="alert" />
          <SoundChip icon="baby" label="Baby crying" tone="alert" />
          <SoundChip icon="door" label="Doorbell" tone="ambient" />
          <SoundChip icon="phone" label="Phone" tone="ambient" />
          <SoundChip icon="volume" label="Laughter" tone="social" />
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 16 }}>
          {[0,1,2,3].map(i => (
            <div key={i} style={{
              width: i === 1 ? 20 : 6, height: 6, borderRadius: 3,
              background: i === 1 ? T.peach : T.lineHi,
            }} />
          ))}
        </div>
      </div>

      <div style={{ flex: 1 }} />

      <div style={{
        padding: '12px 14px', borderRadius: 12,
        background: T.surfaceLo, border: `1px solid ${T.line}`,
        display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12,
      }}>
        <SpIcon name="cpu" size={14} color={T.peach} strokeWidth={2.2} />
        <div style={{ fontSize: 12, color: T.inkSoft, lineHeight: 1.4 }}>
          You can lock the screen — we'll keep downloading in the background.
        </div>
      </div>

      <button style={{
        marginBottom: 16, height: 36, background: 'transparent', border: 'none',
        color: T.inkMute, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer', fontWeight: 500,
      }}>Pause download</button>
    </div>
  </div>
);

// ─── Step 3: Ready ────────────────────────────────────────────
const ModelReadyScreen = ({ onContinue }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink, position: 'relative', overflow: 'hidden' }}>
    {/* Soft peach radial bg */}
    <div style={{
      position: 'absolute', inset: 0,
      background: `radial-gradient(circle at 50% 30%, ${T.peachSoft}, transparent 65%)`,
      pointerEvents: 'none',
    }} />

    <div style={{ padding: '0 28px', display: 'flex', flexDirection: 'column', flex: 1, position: 'relative' }}>
      <div style={{ marginTop: 56, display: 'flex', justifyContent: 'center' }}>
        <div style={{ position: 'relative' }}>
          <div style={{
            width: 96, height: 96, borderRadius: 48,
            background: T.peach, color: T.bg,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 12px 40px ${T.peachGlow}, 0 0 0 10px ${T.peachSoft}`,
          }}>
            <SpIcon name="check" size={48} color={T.bg} strokeWidth={3} />
          </div>
        </div>
      </div>

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 2, color: T.peach, textAlign: 'center', marginTop: 28 }}>READY</div>
      <div style={{
        fontFamily: T.fontDisplay, fontSize: 48, fontWeight: 500,
        lineHeight: 1, letterSpacing: -1.6, color: T.ink, textAlign: 'center', marginTop: 12,
      }}>
        It's all<br/>
        <em style={{ color: T.peach, fontStyle: 'italic' }}>here now.</em>
      </div>
      <div style={{ fontSize: 15, lineHeight: 1.5, color: T.inkSoft, marginTop: 14, textAlign: 'center', maxWidth: 280, alignSelf: 'center' }}>
        Spotlight is fully on your phone. No connection needed from here on.
      </div>

      {/* Quick stats */}
      <div style={{ display: 'flex', gap: 8, marginTop: 28 }}>
        {[['1.5','GB on disk'],['96','sounds'],['0','to the cloud']].map(([n,l]) => (
          <div key={l} style={{ flex: 1, padding: '14px 10px', borderRadius: 14, background: T.surface, border: `1px solid ${T.line}`, textAlign: 'center' }}>
            <div style={{ fontFamily: T.fontDisplay, fontSize: 24, fontWeight: 600, color: T.ink, lineHeight: 1 }}>{n}</div>
            <div style={{ fontSize: 10, color: T.inkMute, marginTop: 5, letterSpacing: 0.5, textTransform: 'uppercase', fontWeight: 700 }}>{l}</div>
          </div>
        ))}
      </div>

      <div style={{ flex: 1 }} />

      <PrimaryBtn full onClick={onContinue}>
        <SpIcon name="mic" size={16} color={T.bg} strokeWidth={2.4} />
        Try it out
      </PrimaryBtn>
      <div style={{ height: 36, marginTop: 10, marginBottom: 16 }} />
    </div>
  </div>
);

// Add shimmer keyframe (one-time)
if (typeof document !== 'undefined' && !document.getElementById('spot-shim-css')) {
  const s = document.createElement('style');
  s.id = 'spot-shim-css';
  s.textContent = `@keyframes spshim { 0%,100%{transform:translateX(-100%)} 50%{transform:translateX(400%)} }`;
  document.head.appendChild(s);
}

Object.assign(window, { ModelPrepScreen, ModelDownloadingScreen, ModelReadyScreen });
