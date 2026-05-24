// Spotlight — Live transcribe screens (1:1, group, alert, type-to-speak)

const { useState: useS1, useEffect: useE1, useRef: useR1 } = React;

// ─── Live screen — Spotlight active speaker, dark, swipe-up history ──
const LiveScreen = ({ mode, onEnd, onRewind, onTypeToSpeak }) => {
  const [historyOpen, setHistoryOpen] = useS1(false);
  const [paused, setPaused] = useS1(false);
  const [tick, setTick] = useS1(0);

  // Read tweaks (with sensible defaults if absent)
  const tw = (typeof window !== 'undefined' && window.__SPOT_TWEAKS) || {};
  const sizeMap = { small: 0.78, regular: 1, large: 1.18, huge: 1.42 };
  const sz = sizeMap[tw.textSize] || 1;
  const density = tw.density || 'regular';
  const padPx = density === 'cozy' ? 18 : density === 'roomy' ? 36 : 28;
  const colorOn = tw.speakerColors !== false;
  const showAmb = tw.showAmbient !== false;
  // Diarization: auto = real names; smart = "Speaker 1/2/3" auto-detected; off = no speaker label
  const diar = tw.diarization || 'auto';
  const labelFor = (name) => {
    if (diar === 'off') return '';
    if (diar === 'smart') {
      const order = ['Maya','Jordan','Priya','You','Sam','Mom'];
      const idx = order.indexOf(name);
      return name === 'You' ? 'You' : `Speaker ${(idx >= 0 ? idx : 0) + 1}`;
    }
    return name;
  };
  const accentColor = (c) => colorOn ? c : T.inkSoft;

  // Demo conversation drives the active speaker
  const script = mode === 'group' ? [
    { name: 'Jordan', text: 'Wait, you actually finished the marathon?' },
    { name: 'Maya',   text: 'Four hours twelve. Knees still hate me.' },
    { name: 'Priya',  text: "Okay but the real question is what's for dessert." },
    { name: 'You',    text: "There's tiramisu in the fridge." },
    { name: 'Jordan', text: "You're a hero, I'll grab plates", emphasis: 'hero' },
  ] : [
    { name: 'Maya', text: "I had the most ridiculous run this morning." },
    { name: 'You',  text: "Oh no, what happened?" },
    { name: 'Maya', text: "A goose chased me around the lake. Like, committed." },
    { name: 'You',  text: "You okay?" },
    { name: 'Maya', text: "Honestly, the background noise helped me focus. And the espresso is unreal", emphasis: 'unreal' },
  ];

  useE1(() => {
    if (paused) return;
    const id = setInterval(() => setTick(t => Math.min(t + 1, script.length - 1)), 3500);
    return () => clearInterval(id);
  }, [paused, script.length]);

  const current = script[tick];
  const history = script.slice(0, tick);
  const spRaw = SPK[current.name] || { color: T.peach, initial: current.name[0] };
  const sp = { ...spRaw, color: accentColor(spRaw.color) };
  const dispName = labelFor(current.name) || '·';

  // Render current text with optional emphasis word colored peach
  const renderText = (s) => {
    if (!s.emphasis) return s.text;
    const idx = s.text.toLowerCase().indexOf(s.emphasis.toLowerCase());
    if (idx < 0) return s.text;
    return (
      <>
        {s.text.slice(0, idx)}
        <em style={{ color: T.peach, fontStyle: 'italic' }}>{s.text.slice(idx, idx + s.emphasis.length)}</em>
        {s.text.slice(idx + s.emphasis.length)}
      </>
    );
  };

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink, position: 'relative', overflow: 'hidden' }}>
      <TopBar
        left={<IconBtn name="back" onClick={onEnd} color={T.inkSoft} />}
        title={mode === 'group' ? 'Tuesday dinner' : 'Coffee with Maya'}
        subtitle={mode === 'group' ? '4 voices · 23:18' : 'Live · 8:42'}
        right={<PrivacyPill />}
      />

      {/* GROUP MODE — speaker roster strip */}
      {mode === 'group' && (() => {
        const roster = ['Jordan', 'Maya', 'Priya', 'You'];
        // Find each speaker's most recent line in the script
        const lastLineFor = (name) => {
          for (let i = tick; i >= 0; i--) {
            if (script[i].name === name) return { line: script[i], idx: i };
          }
          return null;
        };
        return (
          <div style={{ padding: '14px 16px 0', display: 'flex', gap: 8 }}>
            {roster.map((nm) => {
              const psp = SPK[nm] || { color: T.peach, initial: nm[0] };
              const isActive = nm === current.name;
              const last = lastLineFor(nm);
              return (
                <div key={nm} style={{
                  flex: 1, padding: '8px 10px', borderRadius: 12,
                  background: isActive ? psp.color : T.surfaceLo,
                  border: `1px solid ${isActive ? psp.color : T.line}`,
                  display: 'flex', flexDirection: 'column', gap: 4,
                  transition: 'all 0.2s',
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                    <div style={{
                      width: 18, height: 18, borderRadius: 9,
                      background: isActive ? T.bg : psp.color,
                      color: isActive ? psp.color : T.bg,
                      fontSize: 9, fontWeight: 700,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>{psp.initial}</div>
                    <div style={{
                      fontSize: 10, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
                      color: isActive ? T.bg : psp.color, lineHeight: 1,
                    }}>{nm}</div>
                    {isActive && (
                      <div style={{ marginLeft: 'auto', display: 'flex', gap: 1.5 }}>
                        {[6, 10, 5, 8].map((h, i) => (
                          <div key={i} style={{
                            width: 2, height: h, borderRadius: 1, background: T.bg,
                            animation: `spwave ${0.5 + (i % 2) * 0.2}s ease-in-out ${i * 0.06}s infinite alternate`,
                          }} />
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        );
      })()}

      {/* 1:1 — Speaker name plate */}
      {mode !== 'group' && (
        <div style={{ padding: '24px 28px 0', display: 'flex', alignItems: 'center', gap: 12 }}>
          <div key={current.name} className="sp-fade-in" style={{
            width: 44, height: 44, borderRadius: 22, background: sp.color, color: T.bg,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          }}>{sp.initial}</div>
          <div className="sp-fade-in" key={current.name + '-meta'}>
            <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: -0.3, color: T.ink }}>{dispName}</div>
            <div style={{ fontSize: 11, color: T.peach, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase', marginTop: 1 }}>speaking now</div>
          </div>
          <div style={{ flex: 1 }} />
          <Waveform color={sp.color} count={8} height={20} />
        </div>
      )}

      {/* GROUP — recent lines from each previous speaker (smaller, dimmed) */}
      {mode === 'group' && (
        <div style={{ padding: '12px 16px 0', display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 200, overflow: 'hidden' }}>
          {history.slice(-3).map((h, i, arr) => {
            const hsp = SPK[h.name] || { color: T.peach, initial: h.name[0] };
            const recency = (i + 1) / arr.length; // older = lower
            return (
              <div key={tick + '-' + i} style={{
                padding: '8px 12px', borderRadius: 12,
                background: T.surface, borderLeft: `3px solid ${hsp.color}`,
                opacity: 0.35 + recency * 0.45,
              }}>
                <div style={{ fontSize: 10, fontWeight: 700, color: hsp.color, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 2 }}>{h.name}</div>
                <div style={{ fontSize: 13, color: T.inkSoft, lineHeight: 1.35 }}>{h.text}</div>
              </div>
            );
          })}
        </div>
      )}

      {/* Massive transcript — current speaker spotlit */}
      <div style={{
        flex: 1,
        padding: mode === 'group' ? '14px 20px 14px' : '24px 28px',
        display: 'flex', flexDirection: 'column', justifyContent: mode === 'group' ? 'flex-end' : 'center',
        minHeight: 0,
      }}>
        <div key={tick} className="sp-fade-in" style={{
          ...(mode === 'group' ? {
            padding: '14px 16px',
            borderRadius: 16,
            background: T.surfaceHi,
            borderLeft: `4px solid ${sp.color}`,
            boxShadow: '0 8px 24px rgba(0,0,0,0.3)',
          } : {}),
        }}>
          {mode === 'group' && (
            <div style={{ fontSize: 11, fontWeight: 700, color: sp.color, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 6, display: 'flex', alignItems: 'center', gap: 6 }}>
              {current.name} <span style={{ color: T.peach }}>· now</span>
            </div>
          )}
          <div style={{
            fontFamily: T.fontDisplay,
            fontSize: mode === 'group' ? 26 : 40,
            fontWeight: 500,
            lineHeight: mode === 'group' ? 1.25 : 1.12,
            letterSpacing: mode === 'group' ? -0.4 : -1.2,
            color: T.ink,
          }}>
            {renderText(current)}<span className="sp-caret" style={{ display: 'inline-block', width: mode === 'group' ? 3 : 4, height: mode === 'group' ? 22 : 36, background: T.peach, marginLeft: 4, verticalAlign: 'middle' }} />
          </div>
        </div>
      </div>

      {/* Inline ambient sound */}
      {showAmb && <div style={{ padding: '0 28px 16px', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        {mode === 'group' ? (
          <>
            <SoundChip icon="volume" label="cheering" tone="social" />
            <SoundChip icon="music" label="dishes" tone="ambient" />
          </>
        ) : (
          <>
            <SoundChip icon="music" label="jazz · soft" tone="ambient" />
            <SoundChip icon="wind" label="espresso hiss" tone="ambient" />
          </>
        )}
      </div>}

      {/* Pull-up history handle */}
      <button onClick={() => setHistoryOpen(true)} style={{
        background: 'transparent', border: 'none', borderTop: `1px solid ${T.line}`,
        padding: '14px 28px', display: 'flex', alignItems: 'center', gap: 12,
        cursor: 'pointer', fontFamily: 'inherit',
      }}>
        <div style={{ width: 32, height: 4, borderRadius: 2, background: T.lineHi }} />
        <div style={{ fontSize: 12, color: T.inkSoft, fontWeight: 500 }}>
          Pull for history · {history.length + 1} line{history.length === 0 ? '' : 's'}
        </div>
        <div style={{ flex: 1 }} />
        <SpIcon name="chevron-up" size={16} color={T.inkSoft} />
      </button>

      {/* Bottom controls */}
      <div style={{ padding: '12px 16px 16px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <IconBtn name="rewind" onClick={onRewind} color={T.inkSoft} />
        <IconBtn name="keyboard" onClick={onTypeToSpeak} color={T.inkSoft} />
        <div style={{ flex: 1 }} />
        <button onClick={() => setPaused(!paused)} style={{
          width: 56, height: 56, borderRadius: 28, border: 'none',
          background: paused ? T.peach : T.surfaceHi, color: paused ? T.bg : T.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          boxShadow: paused ? `0 8px 24px ${T.peachGlow}` : '0 4px 14px rgba(0,0,0,0.3)',
        }}>
          <SpIcon name={paused ? 'play' : 'pause'} size={22} color={paused ? T.bg : T.ink} strokeWidth={2.4} />
        </button>
      </div>

      {/* History sheet */}
      {historyOpen && (
        <div onClick={() => setHistoryOpen(false)} style={{
          position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 10,
          backdropFilter: 'blur(4px)',
        }}>
          <div onClick={(e) => e.stopPropagation()} style={{
            position: 'absolute', left: 0, right: 0, bottom: 0,
            background: T.bgSoft, borderTopLeftRadius: 24, borderTopRightRadius: 24,
            maxHeight: '85%', display: 'flex', flexDirection: 'column',
            animation: 'spfadein 0.25s cubic-bezier(0.2,0.8,0.2,1)',
            border: `1px solid ${T.line}`, borderBottom: 'none',
          }}>
            <div style={{ padding: '12px 0 8px', display: 'flex', justifyContent: 'center' }}>
              <div style={{ width: 44, height: 4, borderRadius: 2, background: T.lineHi }} />
            </div>
            <div style={{ padding: '4px 24px 14px', display: 'flex', alignItems: 'center' }}>
              <div style={{ fontFamily: T.fontDisplay, fontSize: 22, fontWeight: 600, letterSpacing: -0.4 }}>History</div>
              <div style={{ flex: 1 }} />
              <button style={{ background: 'transparent', border: 'none', color: T.peach, fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit' }}>Star</button>
            </div>
            <div style={{ overflowY: 'auto', padding: '0 20px 24px', display: 'flex', flexDirection: 'column', gap: 12 }}>
              {history.length === 0 && (
                <div style={{ padding: '24px 0', color: T.inkMute, fontSize: 13, textAlign: 'center' }}>
                  Nothing yet. Conversation just started.
                </div>
              )}
              {history.map((h, i) => {
                const hsp = SPK[h.name] || { color: T.peach, initial: h.name[0] };
                return (
                  <div key={i} style={{
                    padding: '12px 14px', borderRadius: 14,
                    background: T.surface, borderLeft: `3px solid ${hsp.color}`,
                  }}>
                    <div style={{ fontSize: 11, fontWeight: 700, color: hsp.color, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 4 }}>{h.name}</div>
                    <div style={{ fontSize: 15, color: T.inkSoft, lineHeight: 1.4 }}>{h.text}</div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// ─── Sound alert overlay (smoke alarm) ─────────────────────────
const AlertScreen = ({ onDismiss, onSeeIt }) => (
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink, position: 'relative' }}>
    <div style={{
      position: 'absolute', inset: 0, background: 'radial-gradient(circle at 50% 30%, rgba(232,90,69,0.28), transparent 60%)',
      pointerEvents: 'none',
    }} />

    <TopBar
      left={<IconBtn name="back" onClick={onDismiss} color={T.inkSoft} />}
      title="At home"
      right={<PrivacyPill />}
    />

    <div style={{ flex: 1, padding: '20px 20px 16px', display: 'flex', flexDirection: 'column', position: 'relative', zIndex: 1 }}>
      <div className="sp-fade-in" style={{
        padding: 24, borderRadius: 24,
        background: T.alert, color: '#fff',
        position: 'relative', overflow: 'hidden',
        boxShadow: `0 24px 60px rgba(232,90,69,0.4)`,
      }}>
        <div style={{ position: 'absolute', inset: 0,
          background: 'repeating-linear-gradient(45deg, transparent 0 16px, rgba(255,255,255,0.05) 16px 32px)' }} />
        <div style={{ position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 18 }}>
            <div style={{
              width: 64, height: 64, borderRadius: 32, background: 'rgba(255,255,255,0.18)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }} className="sp-pulse">
              <SpIcon name="bell" size={32} color="#fff" strokeWidth={2.2} />
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 2, opacity: 0.85 }}>URGENT · 14:03</div>
              <div style={{
                fontFamily: T.fontDisplay, fontSize: 38, fontWeight: 600, letterSpacing: -1, lineHeight: 1, marginTop: 4,
              }}>Smoke alarm</div>
            </div>
          </div>
          <div style={{ fontSize: 14, opacity: 0.92, marginBottom: 18, lineHeight: 1.4 }}>
            Continuous · loud · nearby · <strong>96% match</strong>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <button onClick={onDismiss} style={{
              flex: 1, height: 44, borderRadius: 22, background: 'rgba(255,255,255,0.18)', color: '#fff',
              border: 'none', fontSize: 14, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
            }}>Dismiss</button>
            <button onClick={onSeeIt} style={{
              flex: 1, height: 44, borderRadius: 22, background: '#fff', color: T.alert,
              border: 'none', fontSize: 14, fontWeight: 700, fontFamily: 'inherit', cursor: 'pointer',
            }}>I see it</button>
          </div>
        </div>
      </div>

      <div style={{ marginTop: 24, fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: T.inkMute }}>WHAT'S AROUND</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 10 }}>
        <div style={{
          padding: '12px 14px', borderRadius: 14, background: T.surface, borderLeft: `3px solid ${T.spkB}`, opacity: 0.75,
        }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.spkB, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 4 }}>Sam · 14:01</div>
          <div style={{ fontSize: 15, color: T.inkSoft }}>I'll grab the kettle, you want tea?</div>
        </div>
        <div style={{
          padding: '14px 16px', borderRadius: 14, background: T.surfaceHi, borderLeft: `4px solid ${T.spkB}`,
        }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.spkB, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 4 }}>Sam · NOW</div>
          <div style={{ fontFamily: T.fontDisplay, fontSize: 22, fontWeight: 500, lineHeight: 1.3, color: T.ink, letterSpacing: -0.3 }}>
            Wait — that's the kitchen, hold on<span className="sp-caret">…</span>
          </div>
        </div>
      </div>
    </div>
  </div>
);

// ─── Type-to-speak ─────────────────────────────────────────────
const TypeToSpeakScreen = ({ onClose }) => {
  const [text, setText] = useS1("How about that bookshop in the Mission?");
  const [voice, setVoice] = useS1('warm');
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink, position: 'relative' }}>
      <TopBar
        left={<IconBtn name="close" onClick={onClose} color={T.inkSoft} />}
        title="Speak as you"
        right={<PrivacyPill />}
      />

      {/* Last incoming line for context */}
      <div style={{ padding: '0 16px 12px' }}>
        <div style={{ padding: '12px 14px', borderRadius: 14, background: T.surface, borderLeft: `3px solid ${T.spkB}`, opacity: 0.7 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.spkB, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 4 }}>Maya</div>
          <div style={{ fontSize: 15, color: T.inkSoft }}>What do you want to do this weekend?</div>
        </div>
      </div>

      {/* Compose card */}
      <div style={{ padding: '0 16px', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{
          padding: 20, borderRadius: 22, background: T.surfaceHi,
          border: `1.5px solid ${T.peach}`, boxShadow: `0 12px 32px ${T.peachGlow}`,
          display: 'flex', flexDirection: 'column', flex: 1,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <div style={{
              width: 26, height: 26, borderRadius: 13, background: T.peach,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <SpIcon name="volume" size={13} color={T.bg} strokeWidth={2.4} />
            </div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: T.peach, textTransform: 'uppercase' }}>I'll say this aloud</div>
          </div>
          <textarea
            value={text} onChange={(e) => setText(e.target.value)}
            style={{
              flex: 1, minHeight: 140, border: 'none', background: 'transparent',
              outline: 'none', resize: 'none', color: T.ink,
              fontFamily: T.fontDisplay, fontSize: 26, fontWeight: 500,
              lineHeight: 1.3, letterSpacing: -0.4,
            }}
          />
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 12 }}>
            {['Sounds good','Yes','No','Could you repeat that?','One sec'].map((q) => (
              <button key={q} onClick={() => setText(q)} style={{
                padding: '7px 12px', borderRadius: 999,
                background: T.surfaceLo, color: T.inkSoft,
                border: `1px solid ${T.line}`, fontSize: 12, fontWeight: 500, cursor: 'pointer', fontFamily: 'inherit',
              }}>{q}</button>
            ))}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 10, padding: '14px 0' }}>
          <button onClick={() => setVoice(voice === 'warm' ? 'clear' : 'warm')} style={{
            padding: '12px 16px', borderRadius: 22, background: T.surface, color: T.ink,
            border: `1px solid ${T.lineHi}`, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', gap: 8,
          }}>
            <SpIcon name="person" size={14} color={T.peach} />
            Voice · {voice === 'warm' ? 'Warm' : 'Clear'}
          </button>
          <div style={{ flex: 1 }} />
          <PrimaryBtn onClick={onClose}>
            <SpIcon name="send" size={16} color={T.bg} strokeWidth={2.4} />
            Speak now
          </PrimaryBtn>
        </div>
      </div>
    </div>
  );
};

// ─── Rewind ────────────────────────────────────────────────────
const RewindScreen = ({ onClose, onCatchUp }) => {
  const [pos, setPos] = useS1(0.58);
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: T.bg, color: T.ink }}>
      <TopBar
        left={<IconBtn name="close" onClick={onClose} color={T.inkSoft} />}
        title="Rewind"
        right={<button onClick={onCatchUp} style={{ background: 'transparent', border: 'none', color: T.peach, fontSize: 13, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit', padding: '0 8px' }}>Catch up →</button>}
      />

      <div style={{ padding: '8px 24px 0' }}>
        <div style={{ fontFamily: T.fontDisplay, fontSize: 30, fontWeight: 500, letterSpacing: -0.8, lineHeight: 1.15 }}>
          Scrub back to <em style={{ color: T.peach, fontStyle: 'italic' }}>catch up.</em>
        </div>
        <div style={{ fontSize: 13, color: T.inkSoft, marginTop: 6 }}>
          Live transcript keeps going underneath.
        </div>
      </div>

      {/* Replayed line */}
      <div style={{ padding: '20px 16px 8px', flex: 1 }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.5, color: T.peach, marginBottom: 8 }}>
          ⟲ {Math.round((1 - pos) * 8.7)}m {Math.round(((1 - pos) * 8.7 % 1) * 60)}s ago
        </div>
        <div style={{
          padding: 18, borderRadius: 18, background: T.surfaceHi,
          borderLeft: `5px solid ${T.spkB}`, boxShadow: '0 8px 24px rgba(0,0,0,0.3)',
        }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: T.spkB, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 8 }}>Maya</div>
          <div style={{ fontFamily: T.fontDisplay, fontSize: 24, fontWeight: 500, lineHeight: 1.3, letterSpacing: -0.4 }}>
            So I switched to working from the café most mornings.
          </div>
        </div>
      </div>

      {/* Timeline scrubber */}
      <div style={{ margin: '0 16px 12px', padding: 16, borderRadius: 18, background: T.surface, border: `1px solid ${T.line}` }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: T.inkMute, fontVariantNumeric: 'tabular-nums', fontWeight: 600, marginBottom: 8 }}>
          <span>0:00</span>
          <span>8:42 · NOW</span>
        </div>
        <div style={{ position: 'relative', height: 36 }}>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', gap: 1.5 }}>
            {Array.from({ length: 60 }).map((_, i) => {
              const colors = [T.spkB, T.spkA, T.spkB, T.spkB, T.spkA];
              const c = colors[Math.floor(i / 12) % colors.length];
              const h = 8 + Math.abs(Math.sin(i * 0.7)) * 22;
              return <div key={i} style={{ flex: 1, height: h, background: c, borderRadius: 1, opacity: i / 60 < pos ? 1 : 0.22 }} />;
            })}
          </div>
          <input type="range" min="0" max="100" value={pos * 100}
            onChange={(e) => setPos(Number(e.target.value) / 100)}
            style={{ position: 'absolute', inset: 0, width: '100%', opacity: 0, cursor: 'pointer' }} />
          <div style={{
            position: 'absolute', left: `calc(${pos * 100}% - 2px)`, top: -4, bottom: -4,
            width: 4, background: T.peach, borderRadius: 2,
            boxShadow: `0 0 0 4px ${T.peachGlow}`,
            pointerEvents: 'none',
          }} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 16, marginTop: 14 }}>
          <button onClick={() => setPos(Math.max(0, pos - 0.05))} style={{ width: 40, height: 40, borderRadius: 20, border: 'none', background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={T.ink} strokeWidth="1.8" strokeLinecap="round"><path d="M11 6l-7 6 7 6M21 6l-7 6 7 6"/></svg>
          </button>
          <button style={{ width: 52, height: 52, borderRadius: 26, border: 'none', background: T.peach, color: T.bg, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <SpIcon name="play" size={22} color={T.bg} strokeWidth={2.4} />
          </button>
          <button onClick={() => setPos(Math.min(1, pos + 0.05))} style={{ width: 40, height: 40, borderRadius: 20, border: 'none', background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={T.ink} strokeWidth="1.8" strokeLinecap="round"><path d="M13 6l7 6-7 6M3 6l7 6-7 6"/></svg>
          </button>
        </div>
      </div>

      {/* Live underneath */}
      <div style={{
        margin: '0 16px 12px', padding: '10px 14px', borderRadius: 12,
        background: T.surfaceLo, borderLeft: `3px solid ${T.peach}`,
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <Waveform color={T.peach} count={6} height={10} />
        <div style={{ flex: 1, fontSize: 12, color: T.inkSoft }}>
          <span style={{ fontWeight: 600, color: T.ink }}>Still listening</span> · 3 lines while you were rewinding
        </div>
      </div>
    </div>
  );
};

Object.assign(window, { LiveScreen, AlertScreen, TypeToSpeakScreen, RewindScreen });
