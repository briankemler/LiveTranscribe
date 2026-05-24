// Spotlight app — design tokens (dark-first, V3 lineage)

const T = {
  // Backgrounds (dark-first)
  bg: '#1a1612',
  bgSoft: '#241e18',
  surface: '#2a231d',
  surfaceHi: '#332b23',
  surfaceLo: 'rgba(255,255,255,0.04)',

  // Text
  ink: '#f5ede0',
  inkSoft: 'rgba(245,237,224,0.72)',
  inkMute: 'rgba(245,237,224,0.45)',
  inkDim: 'rgba(245,237,224,0.28)',

  // Hairlines
  line: 'rgba(245,237,224,0.08)',
  lineHi: 'rgba(245,237,224,0.16)',

  // Accents (warm peach/terracotta)
  peach: '#e89878',
  peachDeep: '#c96442',
  peachSoft: 'rgba(232,152,120,0.18)',
  peachGlow: 'rgba(232,152,120,0.35)',

  // Speaker palette (warm, distinguishable on dark)
  spkA: '#e89878',  // you (peach)
  spkB: '#7ab8a4',  // sage
  spkC: '#e8b85a',  // amber
  spkD: '#b89cd8',  // soft violet
  spkE: '#e87878',  // rose

  // Sound semantics
  alert: '#e85a45',
  alertSoft: 'rgba(232,90,69,0.22)',
  ambient: 'rgba(245,237,224,0.45)',
  ambientSoft: 'rgba(245,237,224,0.06)',
  social: '#7ab8a4',
  socialSoft: 'rgba(122,184,164,0.18)',

  // Type
  fontUI: '"Inter", -apple-system, system-ui, sans-serif',
  fontDisplay: '"Fraunces", "Iowan Old Style", Georgia, serif',
  fontMono: '"JetBrains Mono", ui-monospace, monospace',
};

if (typeof document !== 'undefined' && !document.getElementById('sp-fonts')) {
  const l = document.createElement('link');
  l.id = 'sp-fonts';
  l.rel = 'stylesheet';
  l.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fraunces:opsz,wght@9..144,400;9..144,500;9..144,600;9..144,700&display=swap';
  document.head.appendChild(l);
}

// Small helper: speaker chip
const SPK = {
  You:    { color: T.spkA, initial: 'Y' },
  Maya:   { color: T.spkB, initial: 'M' },
  Jordan: { color: T.spkC, initial: 'J' },
  Priya:  { color: T.spkD, initial: 'P' },
  Sam:    { color: T.spkB, initial: 'S' },
  Mom:    { color: T.spkD, initial: 'M' },
};

// Inline icon set (reusing direction-c style)
const SpIcon = ({ name, size = 20, color = 'currentColor', strokeWidth = 1.8 }) => {
  const p = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'mic': return <svg {...p}><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>;
    case 'pause': return <svg {...p}><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>;
    case 'play': return <svg {...p}><path d="M6 4l14 8-14 8z"/></svg>;
    case 'stop': return <svg {...p}><rect x="6" y="6" width="12" height="12" rx="2"/></svg>;
    case 'people': return <svg {...p}><circle cx="9" cy="8" r="3"/><path d="M3 20a6 6 0 0 1 12 0M17 11a3 3 0 1 0 0-6M21 20a5 5 0 0 0-3-4.6"/></svg>;
    case 'person': return <svg {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>;
    case 'cpu': return <svg {...p}><rect x="5" y="5" width="14" height="14" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/></svg>;
    case 'volume': return <svg {...p}><path d="M11 5L6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14"/></svg>;
    case 'send': return <svg {...p}><path d="M5 12l14-7-7 14-2-6-5-1z"/></svg>;
    case 'star': return <svg {...p}><path d="M12 3l2.6 6.2 6.4.6-4.9 4.4 1.5 6.3L12 17.3l-5.6 3.2 1.5-6.3-4.9-4.4 6.4-.6z"/></svg>;
    case 'back': return <svg {...p}><path d="M19 12H5M11 5l-7 7 7 7"/></svg>;
    case 'close': return <svg {...p}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'settings': return <svg {...p}><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.5-2-3.5-2.4.8a7 7 0 0 0-2-1.2L14 3h-4l-.5 2.4a7 7 0 0 0-2 1.2L5 5.8l-2 3.5 2 1.5a7 7 0 0 0 0 2.4L3 14.7l2 3.5 2.4-.8a7 7 0 0 0 2 1.2L10 21h4l.5-2.4a7 7 0 0 0 2-1.2l2.4.8 2-3.5-2-1.5A7 7 0 0 0 19 12z"/></svg>;
    case 'history': return <svg {...p}><path d="M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7v5l3 2"/></svg>;
    case 'rewind': return <svg {...p}><path d="M11 19L3 12l8-7zM21 19l-8-7 8-7z"/></svg>;
    case 'keyboard': return <svg {...p}><rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M6 14h12"/></svg>;
    case 'bell': return <svg {...p}><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21a2 2 0 0 0 4 0"/></svg>;
    case 'music': return <svg {...p}><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>;
    case 'water': return <svg {...p}><path d="M12 3s7 7 7 12a7 7 0 0 1-14 0c0-5 7-12 7-12z"/></svg>;
    case 'wind': return <svg {...p}><path d="M3 8h12a3 3 0 1 0-3-3M3 12h17a3 3 0 1 1-3 3M3 16h9a3 3 0 1 1-3 3"/></svg>;
    case 'door': return <svg {...p}><path d="M5 21V4a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v17M3 21h18M14 12h.01"/></svg>;
    case 'baby': return <svg {...p}><circle cx="12" cy="9" r="5"/><path d="M9 9h.01M15 9h.01M9.5 12s1 1.5 2.5 1.5 2.5-1.5 2.5-1.5M12 14v7M8 18l4-2 4 2"/></svg>;
    case 'phone': return <svg {...p}><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 13 13 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 13 13 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>;
    case 'arrow': return <svg {...p}><path d="M5 12h14M13 5l7 7-7 7"/></svg>;
    case 'plus': return <svg {...p}><path d="M12 5v14M5 12h14"/></svg>;
    case 'check': return <svg {...p}><path d="M5 12l5 5 9-11"/></svg>;
    case 'chevron-up': return <svg {...p}><path d="M6 15l6-6 6 6"/></svg>;
    case 'chevron-down': return <svg {...p}><path d="M6 9l6 6 6-6"/></svg>;
    case 'export': return <svg {...p}><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5-5 5 5M12 5v12"/></svg>;
    case 'trash': return <svg {...p}><path d="M3 6h18M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6M10 11v6M14 11v6M9 6V3h6v3"/></svg>;
    case 'ear': return <svg {...p}><path d="M6 8a6 6 0 0 1 12 0c0 4-3 4-3 7a3 3 0 0 1-6 0M9 9a3 3 0 0 1 6 0"/></svg>;
    case 'lock': return <svg {...p}><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>;
    default: return <svg {...p}><circle cx="12" cy="12" r="9"/></svg>;
  }
};

Object.assign(window, { T, SPK, SpIcon });
