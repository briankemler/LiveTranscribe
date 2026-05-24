// Design tokens shared across all directions

const TOKENS = {
  // Warm neutrals
  bg: '#faf6f1',          // warm off-white
  bgSoft: '#f3ede4',
  surface: '#ffffff',
  surfaceAlt: '#fbf5ec',
  ink: '#2a221c',         // deep warm charcoal
  inkSoft: '#5a4f44',
  inkMute: '#8c8074',
  hairline: '#e8dfd2',

  // Dark mode
  bgDark: '#1a1612',
  bgDarkSoft: '#241e18',
  surfaceDark: '#2a231d',
  inkDark: '#f5ede0',
  inkDarkSoft: '#bdb1a0',
  hairlineDark: '#3a3128',

  // Accents (warm peach/terracotta family)
  peach: '#e89878',
  peachDeep: '#c96442',
  peachSoft: '#fde4d4',
  terra: '#a8553a',

  // Speaker palette (warm-leaning, distinguishable)
  spkA: '#c96442',  // terracotta
  spkB: '#5a8a7a',  // sage teal
  spkC: '#b88a3a',  // amber
  spkD: '#8a6cb0',  // muted violet

  // Sound chip semantic
  alert: '#cc4530',        // alarm/urgent
  alertBg: '#ffe4dc',
  ambient: '#8c8074',      // background noise
  ambientBg: '#f0e9dd',
  social: '#5a8a7a',       // speech-adjacent (laughter, applause)
  socialBg: '#dfeae3',

  // Typography
  fontUI: '"Inter", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
  fontDisplay: '"Fraunces", "Iowan Old Style", Georgia, serif',
  fontMono: '"JetBrains Mono", "Roboto Mono", ui-monospace, monospace',
};

window.TOKENS = TOKENS;

// Inject Google Fonts once
if (typeof document !== 'undefined' && !document.getElementById('lt-fonts')) {
  const l = document.createElement('link');
  l.id = 'lt-fonts';
  l.rel = 'stylesheet';
  l.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fraunces:opsz,wght@9..144,400;9..144,500;9..144,600;9..144,700&family=JetBrains+Mono:wght@400;500&display=swap';
  document.head.appendChild(l);
}

// Shared icon set — flat single-stroke, matches warm/friendly tone
const Icon = ({ name, size = 20, color = 'currentColor', strokeWidth = 1.8 }) => {
  const props = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  switch (name) {
    case 'mic':
      return <svg {...props}><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>;
    case 'micOff':
      return <svg {...props}><path d="M3 3l18 18M9 9v2a3 3 0 0 0 5.12 2.12M15 9.34V6a3 3 0 0 0-5.94-.6M5 11a7 7 0 0 0 .69 3M19 11a7 7 0 0 1-1.16 3.86M12 18v3"/></svg>;
    case 'pause':
      return <svg {...props}><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>;
    case 'play':
      return <svg {...props}><path d="M6 4l14 8-14 8z"/></svg>;
    case 'stop':
      return <svg {...props}><rect x="6" y="6" width="12" height="12" rx="2"/></svg>;
    case 'people':
      return <svg {...props}><circle cx="9" cy="8" r="3"/><path d="M3 20a6 6 0 0 1 12 0M17 11a3 3 0 1 0 0-6M21 20a5 5 0 0 0-3-4.6"/></svg>;
    case 'person':
      return <svg {...props}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>;
    case 'settings':
      return <svg {...props}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>;
    case 'lock':
      return <svg {...props}><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>;
    case 'wifi-off':
      return <svg {...props}><path d="M3 3l18 18M8.5 16.5a5 5 0 0 1 7 0M5 12.5a10 10 0 0 1 4-2.6M2 8.8a14 14 0 0 1 3-2.2M22 8.8a14 14 0 0 0-9-3.6M19 12.5a10 10 0 0 0-3-2.4M12 20h.01"/></svg>;
    case 'cpu':
      return <svg {...props}><rect x="5" y="5" width="14" height="14" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/></svg>;
    case 'sparkle':
      return <svg {...props}><path d="M12 3l1.5 5L18 9.5 13.5 11 12 16l-1.5-5L6 9.5 10.5 8z"/></svg>;
    case 'volume':
      return <svg {...props}><path d="M11 5L6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14"/></svg>;
    case 'send':
      return <svg {...props}><path d="M5 12l14-7-7 14-2-6-5-1z"/></svg>;
    case 'plus':
      return <svg {...props}><path d="M12 5v14M5 12h14"/></svg>;
    case 'check':
      return <svg {...props}><path d="M5 12l5 5 9-11"/></svg>;
    case 'star':
      return <svg {...props}><path d="M12 3l2.6 6.2 6.4.6-4.9 4.4 1.5 6.3L12 17.3l-5.6 3.2 1.5-6.3-4.9-4.4 6.4-.6z"/></svg>;
    case 'arrow':
      return <svg {...props}><path d="M5 12h14M13 5l7 7-7 7"/></svg>;
    case 'back':
      return <svg {...props}><path d="M19 12H5M11 5l-7 7 7 7"/></svg>;
    case 'close':
      return <svg {...props}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'menu':
      return <svg {...props}><path d="M4 6h16M4 12h16M4 18h16"/></svg>;
    case 'baby':
      return <svg {...props}><circle cx="12" cy="9" r="5"/><path d="M9 9h.01M15 9h.01M9.5 12s1 1.5 2.5 1.5 2.5-1.5 2.5-1.5M12 14v7M8 18l4-2 4 2"/></svg>;
    case 'bell':
      return <svg {...props}><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21a2 2 0 0 0 4 0"/></svg>;
    case 'car':
      return <svg {...props}><path d="M3 13l2-6h14l2 6M3 13v5h2v-2h14v2h2v-5M5 13h14"/><circle cx="7.5" cy="15.5" r="1.5"/><circle cx="16.5" cy="15.5" r="1.5"/></svg>;
    case 'dog':
      return <svg {...props}><path d="M10 5l-2 3v3l-3 2v4l3 2h10v-4l-2-1v-3l2-2-3-4-2 1zM12 14h.01"/></svg>;
    case 'door':
      return <svg {...props}><path d="M5 21V4a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v17M3 21h18M14 12h.01"/></svg>;
    case 'water':
      return <svg {...props}><path d="M12 3s7 7 7 12a7 7 0 0 1-14 0c0-5 7-12 7-12z"/></svg>;
    case 'music':
      return <svg {...props}><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>;
    case 'wind':
      return <svg {...props}><path d="M3 8h12a3 3 0 1 0-3-3M3 12h17a3 3 0 1 1-3 3M3 16h9a3 3 0 1 1-3 3"/></svg>;
    case 'keyboard':
      return <svg {...props}><rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M6 14h12"/></svg>;
    case 'ear':
      return <svg {...props}><path d="M6 8a6 6 0 0 1 12 0c0 4-3 4-3 7a3 3 0 0 1-6 0M9 9a3 3 0 0 1 6 0"/></svg>;
    case 'shield':
      return <svg {...props}><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></svg>;
    default:
      return <svg {...props}><circle cx="12" cy="12" r="9"/></svg>;
  }
};

window.LTIcon = Icon;
