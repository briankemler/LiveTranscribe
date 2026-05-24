// Direction C v2 — Speaker Stage, deeper exploration
// Builds on direction-c.jsx; adds variations + new screens.

const c2 = {
  page: {
    fontFamily: TOKENS.fontUI,
    background: TOKENS.bgSoft,
    color: TOKENS.ink,
    height: '100%',
    display: 'flex', flexDirection: 'column',
  },
  pageDark: {
    fontFamily: TOKENS.fontUI,
    background: TOKENS.ink,
    color: '#fff',
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
  privacy: {
    display: 'inline-flex', alignItems: 'center', gap: 5,
    padding: '4px 9px', borderRadius: 999,
    background: TOKENS.peachSoft, color: TOKENS.peachDeep,
    fontSize: 10, fontWeight: 700, letterSpacing: 0.5,
  },
};

// ─── Active speaker variation 1 — "Hero" ──────────────────────
// Active speaker fills 65% of the screen, large display serif,
// history collapsed above as small dimmed cards.
const C_Live_Hero = () => (
  <div style={{ ...c2.page, position: 'relative' }}>
    <div style={c2.topbar}>
      <button style={c2.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Coffee with Maya</div>
      <div style={c2.privacy}>
        <LTIcon name="cpu" size={9} color={TOKENS.peachDeep} strokeWidth={2.4} />
        ON-DEVICE
      </div>
    </div>

    {/* History — small cards, dimmed */}
    <div style={{ padding: '4px 12px 0', display: 'flex', flexDirection: 'column', gap: 6 }}>
      {[
        { n: 'Maya', c: TOKENS.spkB, t: 'So I switched to working from the café most mornings.' },
        { n: 'You', c: TOKENS.spkA, t: 'Is it not too loud?' },
      ].map((s, i) => (
        <div key={i} style={{
          padding: '8px 12px', borderRadius: 10,
          background: 'rgba(255,255,255,0.5)',
          borderLeft: `3px solid ${s.c}`, opacity: 0.55,
          fontSize: 14, color: TOKENS.inkSoft, lineHeight: 1.35,
        }}>
          <span style={{ fontWeight: 700, color: s.c, fontSize: 11, letterSpacing: 0.3, textTransform: 'uppercase', marginRight: 8 }}>{s.n}</span>
          {s.t}
        </div>
      ))}
    </div>

    {/* HERO active speaker */}
    <div style={{
      flex: 1, margin: '12px 12px 100px',
      padding: '24px 22px',
      borderRadius: 24,
      background: TOKENS.surface,
      borderLeft: `6px solid ${TOKENS.spkB}`,
      boxShadow: '0 8px 32px rgba(42,34,28,0.08)',
      display: 'flex', flexDirection: 'column',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
        <div style={{
          width: 36, height: 36, borderRadius: 18, background: TOKENS.spkB,
          color: '#fff', fontSize: 14, fontWeight: 700,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>M</div>
        <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: 0.5, color: TOKENS.spkB, textTransform: 'uppercase' }}>Maya</div>
        <div style={{ display: 'flex', gap: 2.5, marginLeft: 'auto' }}>
          {[10, 18, 8, 16, 12, 14, 7].map((h, i) => (
            <div key={i} style={{ width: 3, height: h, borderRadius: 2, background: TOKENS.spkB, opacity: 0.4 + (i % 2) * 0.5 }} />
          ))}
        </div>
      </div>

      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 38, fontWeight: 500, lineHeight: 1.18,
        letterSpacing: -0.8, color: TOKENS.ink, flex: 1,
      }}>
        Honestly the background noise helps me focus. And the espresso<span style={{ color: TOKENS.peachDeep }}> is unreal</span><span style={{ display: 'inline-block', width: 3, height: 32, background: TOKENS.peachDeep, marginLeft: 4, verticalAlign: 'middle', opacity: 0.6 }} />
      </div>

      {/* Sound chip floating in bottom-right */}
      <div style={{
        position: 'absolute', bottom: 16, right: 16,
        display: 'inline-flex', alignItems: 'center', gap: 5,
        padding: '6px 11px', borderRadius: 999,
        background: TOKENS.ambientBg, color: TOKENS.inkSoft,
        fontSize: 11, fontWeight: 600,
      }}>
        <LTIcon name="music" size={11} color={TOKENS.inkSoft} strokeWidth={2.2} /> jazz · soft
      </div>
    </div>

    <div style={{
      position: 'absolute', bottom: 12, left: 12, right: 12,
      height: 60, borderRadius: 30,
      background: TOKENS.ink, color: '#fff',
      display: 'flex', alignItems: 'center', padding: '0 8px 0 16px', gap: 12,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
        {Array.from({ length: 14 }).map((_, i) => (
          <div key={i} style={{ width: 3, height: 4 + Math.abs(Math.sin(i * 0.5)) * 16, borderRadius: 2, background: TOKENS.peach, opacity: 0.5 + (i % 3) * 0.2 }} />
        ))}
      </div>
      <div style={{ flex: 1, fontSize: 13, fontVariantNumeric: 'tabular-nums', opacity: 0.7 }}>00:08:42</div>
      <button style={{ width: 44, height: 44, borderRadius: 22, border: 'none', background: TOKENS.peach, color: TOKENS.ink, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="pause" size={18} color={TOKENS.ink} strokeWidth={2.4} />
      </button>
    </div>
  </div>
);

// ─── Active speaker variation 2 — "Spotlight" ─────────────────
// Fullscreen active speaker, dark dramatic background, swipe up handle for history
const C_Live_Spotlight = () => (
  <div style={{ ...c2.pageDark, position: 'relative' }}>
    <div style={{ ...c2.topbar, color: '#fff' }}>
      <button style={c2.iconBtn}><LTIcon name="back" size={20} color="#fff" /></button>
      <div style={{ flex: 1, fontSize: 13, fontWeight: 600, color: 'rgba(255,255,255,0.7)' }}>Coffee with Maya · 8:42</div>
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 5,
        padding: '4px 9px', borderRadius: 999,
        background: 'rgba(232,152,120,0.2)', color: TOKENS.peach,
        fontSize: 10, fontWeight: 700, letterSpacing: 0.5,
      }}>
        <LTIcon name="cpu" size={9} color={TOKENS.peach} strokeWidth={2.4} />
        ON-DEVICE
      </div>
    </div>

    {/* Speaker name plate */}
    <div style={{
      padding: '32px 28px 0', display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 22, background: TOKENS.spkB,
        color: '#fff', fontSize: 18, fontWeight: 700,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>M</div>
      <div>
        <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: -0.3 }}>Maya</div>
        <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)' }}>speaking now</div>
      </div>
      <div style={{ flex: 1 }} />
      <div style={{ display: 'flex', gap: 3 }}>
        {[10, 18, 8, 16, 12, 14, 7, 12].map((h, i) => (
          <div key={i} style={{ width: 3, height: h, borderRadius: 2, background: TOKENS.peach, opacity: 0.5 + (i % 2) * 0.5 }} />
        ))}
      </div>
    </div>

    {/* Massive transcript */}
    <div style={{
      flex: 1, padding: '32px 28px',
      display: 'flex', flexDirection: 'column', justifyContent: 'center',
    }}>
      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 44, fontWeight: 500, lineHeight: 1.1,
        letterSpacing: -1.2, color: '#fff',
      }}>
        Honestly the background <span style={{ color: 'rgba(255,255,255,0.45)' }}>noise helps me focus.</span> <span style={{ color: TOKENS.peach, fontStyle: 'italic' }}>And the espresso is unreal</span><span style={{ display: 'inline-block', width: 4, height: 38, background: TOKENS.peach, marginLeft: 4, verticalAlign: 'middle' }} />
      </div>
    </div>

    {/* Inline sound chip */}
    <div style={{ padding: '0 28px 16px' }}>
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 6,
        padding: '6px 12px', borderRadius: 999,
        background: 'rgba(255,255,255,0.08)',
        border: '1px solid rgba(255,255,255,0.12)',
        color: 'rgba(255,255,255,0.7)',
        fontSize: 12, fontWeight: 500,
      }}>
        <LTIcon name="music" size={12} color="rgba(255,255,255,0.7)" /> jazz playing softly · since 8:38
      </div>
    </div>

    {/* Drag handle for history */}
    <div style={{
      borderTop: '1px solid rgba(255,255,255,0.08)',
      padding: '12px 28px',
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{ width: 32, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.3)' }} />
      <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)' }}>Pull for history · 12 lines</div>
    </div>

    {/* Floating control */}
    <div style={{
      position: 'absolute', bottom: 16, right: 16,
      width: 56, height: 56, borderRadius: 28,
      background: TOKENS.peach, color: TOKENS.ink,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      border: 'none', cursor: 'pointer',
      boxShadow: '0 8px 24px rgba(232,152,120,0.4)',
    }}>
      <LTIcon name="pause" size={20} color={TOKENS.ink} strokeWidth={2.4} />
    </div>
  </div>
);

// ─── Active speaker variation 3 — "Stack" ─────────────────────
// Active pins to top with tall card; history scrolls below normally.
const C_Live_Stack = () => (
  <div style={{ ...c2.page, position: 'relative' }}>
    <div style={c2.topbar}>
      <button style={c2.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Coffee with Maya · 8:42</div>
      <div style={c2.privacy}>
        <LTIcon name="cpu" size={9} color={TOKENS.peachDeep} strokeWidth={2.4} />
        ON-DEVICE
      </div>
    </div>

    {/* Pinned active card */}
    <div style={{
      margin: '4px 12px 12px',
      padding: '18px 18px 16px',
      borderRadius: 22,
      background: TOKENS.surface,
      borderLeft: `5px solid ${TOKENS.spkB}`,
      boxShadow: '0 6px 20px rgba(42,34,28,0.08)',
      position: 'relative',
    }}>
      <div style={{
        position: 'absolute', top: -8, left: 14,
        background: TOKENS.spkB, color: '#fff',
        fontSize: 10, fontWeight: 700, letterSpacing: 0.8,
        padding: '3px 8px', borderRadius: 6, textTransform: 'uppercase',
      }}>NOW · MAYA</div>
      <div style={{
        fontFamily: TOKENS.fontDisplay,
        fontSize: 28, fontWeight: 500, lineHeight: 1.25,
        letterSpacing: -0.5, color: TOKENS.ink, marginTop: 8,
      }}>
        Honestly the background noise helps me focus. And the espresso is unreal<span style={{ color: TOKENS.peachDeep, opacity: 0.7 }}>…</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, paddingTop: 12, borderTop: `1px dashed ${TOKENS.hairline}` }}>
        <div style={{ display: 'flex', gap: 2.5 }}>
          {[8, 14, 6, 12, 10, 13, 9].map((h, i) => (
            <div key={i} style={{ width: 2.5, height: h, borderRadius: 1.5, background: TOKENS.spkB, opacity: 0.5 + (i % 2) * 0.4 }} />
          ))}
        </div>
        <div style={{ fontSize: 11, color: TOKENS.inkMute, marginLeft: 'auto' }}>jazz · soft</div>
        <LTIcon name="music" size={12} color={TOKENS.inkMute} strokeWidth={2.2} />
      </div>
    </div>

    {/* History */}
    <div style={{ padding: '0 12px 100px', flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: TOKENS.inkMute, textTransform: 'uppercase', padding: '4px 4px 8px' }}>
        Earlier ↑
      </div>
      {[
        { n: 'You', c: TOKENS.spkA, t: 'Is it not too loud?' },
        { n: 'Maya', c: TOKENS.spkB, t: 'So I switched to working from the café most mornings. Way better than the apartment.' },
      ].map((s, i) => (
        <div key={i} style={{
          padding: '12px 14px', borderRadius: 14,
          background: TOKENS.surface, border: `1px solid ${TOKENS.hairline}`,
          borderLeft: `3px solid ${s.c}`,
        }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: s.c, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 4 }}>{s.n}</div>
          <div style={{ fontSize: 16, lineHeight: 1.4, color: TOKENS.inkSoft }}>{s.t}</div>
        </div>
      ))}
    </div>

    <div style={{
      position: 'absolute', bottom: 12, left: 12, right: 12,
      height: 60, borderRadius: 30,
      background: TOKENS.ink, color: '#fff',
      display: 'flex', alignItems: 'center', padding: '0 8px 0 16px', gap: 12,
    }}>
      <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', background: 'rgba(255,255,255,0.12)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="keyboard" size={16} color="#fff" />
      </button>
      <div style={{ flex: 1, fontSize: 13, opacity: 0.7 }}>Listening…</div>
      <button style={{ width: 44, height: 44, borderRadius: 22, border: 'none', background: TOKENS.peach, color: TOKENS.ink, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <LTIcon name="pause" size={18} color={TOKENS.ink} strokeWidth={2.4} />
      </button>
    </div>
  </div>
);

// ─── Sound treatment 1 — "Ambient watercolor" ─────────────────
// Sound info bleeds into the background as a colored tint behind text
const C_Sound_Ambient = () => (
  <div style={{ ...c2.page, position: 'relative', background: `linear-gradient(180deg, ${TOKENS.bgSoft} 0%, ${TOKENS.socialBg} 100%)` }}>
    <div style={c2.topbar}>
      <button style={c2.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Tuesday dinner</div>
      <div style={c2.privacy}>
        <LTIcon name="cpu" size={9} color={TOKENS.peachDeep} strokeWidth={2.4} />
        ON-DEVICE
      </div>
    </div>

    {/* Atmosphere strip */}
    <div style={{
      margin: '0 12px 8px',
      padding: '14px 16px',
      borderRadius: 16,
      background: 'rgba(255,255,255,0.65)',
      backdropFilter: 'blur(8px)',
      border: `1px solid rgba(255,255,255,0.6)`,
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: 15,
        background: TOKENS.socialBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <LTIcon name="ear" size={14} color={TOKENS.social} strokeWidth={2.2} />
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.6, color: TOKENS.social, textTransform: 'uppercase' }}>The room</div>
        <div style={{ fontSize: 13, color: TOKENS.ink, marginTop: 1 }}>cheering · dishes clinking · warm chatter</div>
      </div>
      <div style={{ display: 'flex', gap: 2 }}>
        {[6, 10, 14, 8, 12, 7].map((h, i) => (
          <div key={i} style={{ width: 2, height: h, borderRadius: 1, background: TOKENS.social, opacity: 0.4 + (i % 2) * 0.4 }} />
        ))}
      </div>
    </div>

    {/* Stage */}
    <div style={{ flex: 1, padding: '4px 12px 16px', display: 'flex', flexDirection: 'column', gap: 8, overflowY: 'auto' }}>
      {[
        { n: 'Jordan', c: TOKENS.spkC, t: 'Wait, you actually finished the marathon?' },
        { n: 'Maya', c: TOKENS.spkB, t: 'Four hours twelve. Knees still hate me.' },
      ].map((s, i) => (
        <div key={i} style={{
          padding: '12px 14px', borderRadius: 14,
          background: 'rgba(255,255,255,0.7)',
          borderLeft: `3px solid ${s.c}`, opacity: 0.6,
          fontSize: 15, color: TOKENS.inkSoft,
        }}>
          <span style={{ fontWeight: 700, color: s.c, fontSize: 11, textTransform: 'uppercase', letterSpacing: 0.3, marginRight: 8 }}>{s.n}</span>
          {s.t}
        </div>
      ))}
      <div style={{
        padding: '18px 18px',
        borderRadius: 18,
        background: TOKENS.surface,
        borderLeft: `4px solid ${TOKENS.spkD}`,
        boxShadow: '0 6px 20px rgba(42,34,28,0.06)',
      }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: TOKENS.spkD, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 6 }}>Priya</div>
        <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 26, fontWeight: 500, lineHeight: 1.25, letterSpacing: -0.3, color: TOKENS.ink }}>
          Okay but the real question is what's for dessert.
        </div>
      </div>
    </div>
  </div>
);

// ─── Sound treatment 2 — "Inline sound moment" ────────────────
// Sound becomes a full-width content card in the conversation flow
const C_Sound_Inline = () => (
  <div style={{ ...c2.page, position: 'relative' }}>
    <div style={c2.topbar}>
      <button style={c2.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>At home</div>
      <div style={c2.privacy}>
        <LTIcon name="cpu" size={9} color={TOKENS.peachDeep} strokeWidth={2.4} />
        ON-DEVICE
      </div>
    </div>

    <div style={{ flex: 1, padding: '8px 12px', display: 'flex', flexDirection: 'column', gap: 10, overflowY: 'auto' }}>
      <div style={{
        padding: '12px 14px', borderRadius: 14,
        background: TOKENS.surface, borderLeft: `3px solid ${TOKENS.spkB}`, opacity: 0.6,
      }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: TOKENS.spkB, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 4 }}>Sam</div>
        <div style={{ fontSize: 15, color: TOKENS.inkSoft }}>I'll grab the kettle, you want tea?</div>
      </div>

      {/* Inline sound moment — quiet ambient */}
      <div style={{
        margin: '4px 0',
        padding: '10px 14px', borderRadius: 999,
        background: TOKENS.ambientBg,
        display: 'flex', alignItems: 'center', gap: 10,
        alignSelf: 'flex-start', maxWidth: '90%',
      }}>
        <LTIcon name="water" size={14} color={TOKENS.inkSoft} />
        <div style={{ fontSize: 13, color: TOKENS.inkSoft, fontWeight: 500 }}>kettle starting to boil</div>
        <div style={{ fontSize: 11, color: TOKENS.inkMute, fontVariantNumeric: 'tabular-nums' }}>14:01</div>
      </div>

      {/* Inline sound moment — URGENT, takes the whole row */}
      <div style={{
        padding: '18px 18px', borderRadius: 18,
        background: TOKENS.alert, color: '#fff',
        position: 'relative', overflow: 'hidden',
        boxShadow: '0 6px 24px rgba(204,69,48,0.3)',
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          background: `repeating-linear-gradient(45deg, transparent 0 14px, rgba(255,255,255,0.06) 14px 28px)`,
        }} />
        <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{
            width: 48, height: 48, borderRadius: 24,
            background: 'rgba(255,255,255,0.18)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <LTIcon name="bell" size={26} color="#fff" strokeWidth={2.2} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.5, opacity: 0.8 }}>URGENT · 14:03</div>
            <div style={{
              fontFamily: TOKENS.fontDisplay,
              fontSize: 28, fontWeight: 600, letterSpacing: -0.5, lineHeight: 1, marginTop: 2,
            }}>Smoke alarm</div>
            <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>Continuous · loud · nearby</div>
          </div>
        </div>
        <div style={{ position: 'relative', display: 'flex', gap: 8, marginTop: 14 }}>
          <button style={{ flex: 1, height: 36, borderRadius: 18, background: 'rgba(255,255,255,0.18)', color: '#fff', border: 'none', fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Snooze</button>
          <button style={{ flex: 1, height: 36, borderRadius: 18, background: '#fff', color: TOKENS.alert, border: 'none', fontSize: 13, fontWeight: 700, fontFamily: 'inherit', cursor: 'pointer' }}>I see it</button>
        </div>
      </div>

      <div style={{
        padding: '14px 16px', borderRadius: 16,
        background: TOKENS.surface, borderLeft: `4px solid ${TOKENS.spkB}`,
        boxShadow: '0 4px 14px rgba(42,34,28,0.05)',
      }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: TOKENS.spkB, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 4 }}>Sam</div>
        <div style={{ fontFamily: TOKENS.fontDisplay, fontSize: 22, fontWeight: 500, lineHeight: 1.3, color: TOKENS.ink }}>
          Wait — that's the kitchen, hold on<span style={{ opacity: 0.5 }}>…</span>
        </div>
      </div>
    </div>
  </div>
);

// ─── Sound treatment 3 — "Margin annotation" ─────────────────
// Sounds as small handwritten-feeling marginalia in the gutter
const C_Sound_Margin = () => (
  <div style={{ ...c2.page, position: 'relative' }}>
    <div style={c2.topbar}>
      <button style={c2.iconBtn}><LTIcon name="back" size={20} /></button>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>Tuesday dinner</div>
      <div style={c2.privacy}>
        <LTIcon name="cpu" size={9} color={TOKENS.peachDeep} strokeWidth={2.4} />
        ON-DEVICE
      </div>
    </div>

    <div style={{ flex: 1, overflowY: 'auto', display: 'flex' }}>
      {/* Gutter */}
      <div style={{
        width: 70, flexShrink: 0,
        borderRight: `1px dashed ${TOKENS.hairline}`,
        padding: '12px 4px 12px 8px',
        position: 'relative',
      }}>
        <div style={{ position: 'absolute', top: 14, left: 8, right: 8, fontSize: 10, color: TOKENS.inkMute, fontVariantNumeric: 'tabular-nums', fontWeight: 600, letterSpacing: 0.5 }}>23:10</div>
        <div style={{ position: 'absolute', top: 38, left: 6, right: 6, display: 'flex', alignItems: 'flex-start', gap: 4, color: TOKENS.social }}>
          <LTIcon name="volume" size={11} color={TOKENS.social} strokeWidth={2.2} />
          <div style={{ fontSize: 11, fontStyle: 'italic', fontWeight: 500, lineHeight: 1.2 }}>cheering</div>
        </div>

        <div style={{ position: 'absolute', top: 200, left: 8, right: 8, fontSize: 10, color: TOKENS.inkMute, fontVariantNumeric: 'tabular-nums', fontWeight: 600, letterSpacing: 0.5 }}>23:14</div>
        <div style={{ position: 'absolute', top: 224, left: 6, right: 6, display: 'flex', alignItems: 'flex-start', gap: 4, color: TOKENS.inkSoft }}>
          <LTIcon name="music" size={11} color={TOKENS.inkSoft} strokeWidth={2.2} />
          <div style={{ fontSize: 11, fontStyle: 'italic', fontWeight: 500, lineHeight: 1.2 }}>dishes clink</div>
        </div>

        <div style={{ position: 'absolute', top: 360, left: 8, right: 8, fontSize: 10, color: TOKENS.inkMute, fontVariantNumeric: 'tabular-nums', fontWeight: 600, letterSpacing: 0.5 }}>23:18</div>
        <div style={{ position: 'absolute', top: 384, left: 6, right: 6, display: 'flex', alignItems: 'flex-start', gap: 4, color: TOKENS.peachDeep }}>
          <LTIcon name="volume" size={11} color={TOKENS.peachDeep} strokeWidth={2.2} />
          <div style={{ fontSize: 11, fontStyle: 'italic', fontWeight: 500, lineHeight: 1.2 }}>laughter</div>
        </div>
      </div>

      {/* Stage */}
      <div style={{ flex: 1, padding: '12px 14px 80px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {[
          { n: 'Jordan', c: TOKENS.spkC, t: 'Wait, you actually finished the marathon?' },
          { n: 'Maya', c: TOKENS.spkB, t: 'Four hours twelve. Knees still hate me.', faded: true },
          { n: 'Priya', c: TOKENS.spkD, t: "Okay but the real question is what's for dessert.", faded: true },
          { n: 'You', c: TOKENS.spkA, t: "There's tiramisu in the fridge.", faded: true },
          { n: 'Jordan', c: TOKENS.spkC, t: "You're a hero, I'll grab plates", active: true },
        ].map((s, i) => (
          <div key={i} style={{
            opacity: s.faded ? 0.55 : 1,
          }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: s.c, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 4 }}>{s.n}</div>
            <div style={{
              fontFamily: s.active ? TOKENS.fontDisplay : TOKENS.fontUI,
              fontSize: s.active ? 24 : 17,
              fontWeight: s.active ? 500 : 400,
              lineHeight: 1.35, color: s.active ? TOKENS.ink : TOKENS.inkSoft,
              letterSpacing: s.active ? -0.3 : 0,
            }}>
              {s.t}{s.active && <span style={{ opacity: 0.4 }}>…</span>}
            </div>
          </div>
        ))}
      </div>
    </div>
  </div>
);

window.C_Live_Hero = C_Live_Hero;
window.C_Live_Spotlight = C_Live_Spotlight;
window.C_Live_Stack = C_Live_Stack;
window.C_Sound_Ambient = C_Sound_Ambient;
window.C_Sound_Inline = C_Sound_Inline;
window.C_Sound_Margin = C_Sound_Margin;
