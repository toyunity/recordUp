// tokens.jsx — design system

const TOKENS = {
  // type
  fontUI: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif',
  fontDisplay: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", sans-serif',
  fontMono: 'ui-monospace, "SF Mono", "JetBrains Mono", Menlo, monospace',

  // warm theme (default)
  warm: {
    canvas: '#f6f1ea',         // off-white window bg
    surface: '#ffffff',        // cards
    surfaceMuted: '#fbf6ef',   // subtle alt
    sidebar: 'rgba(248,242,232,0.72)',
    line: 'rgba(31,26,23,0.08)',
    lineStrong: 'rgba(31,26,23,0.14)',
    ink: '#1f1a17',
    ink70: 'rgba(31,26,23,0.7)',
    ink50: 'rgba(31,26,23,0.5)',
    ink35: 'rgba(31,26,23,0.35)',
    ink20: 'rgba(31,26,23,0.2)',
    ink10: 'rgba(31,26,23,0.1)',
    accent: '#FF6A3D',
    accent2: '#E0245E',
    accentSoft: 'rgba(255,106,61,0.10)',
    accent2Soft: 'rgba(224,36,94,0.10)',
    gradient: 'linear-gradient(135deg, #FF6A3D 0%, #E0245E 100%)',
    gradientSoft: 'linear-gradient(135deg, rgba(255,106,61,0.12) 0%, rgba(224,36,94,0.12) 100%)',
    success: '#1f8a5b',
    decision: '#7A5AE0',
    action: '#0E7C86',
  },

  // mono ink theme
  mono: {
    canvas: '#fafaf8',
    surface: '#ffffff',
    surfaceMuted: '#f3f3f0',
    sidebar: 'rgba(245,245,242,0.85)',
    line: 'rgba(0,0,0,0.08)',
    lineStrong: 'rgba(0,0,0,0.16)',
    ink: '#0d0d0d',
    ink70: 'rgba(13,13,13,0.7)',
    ink50: 'rgba(13,13,13,0.5)',
    ink35: 'rgba(13,13,13,0.35)',
    ink20: 'rgba(13,13,13,0.2)',
    ink10: 'rgba(13,13,13,0.08)',
    accent: '#FF6A3D',
    accent2: '#FF6A3D',
    accentSoft: 'rgba(255,106,61,0.10)',
    accent2Soft: 'rgba(255,106,61,0.10)',
    gradient: '#FF6A3D',
    gradientSoft: 'rgba(255,106,61,0.10)',
    success: '#0d7a4a',
    decision: '#0d0d0d',
    action: '#0d0d0d',
  },

  // dark studio theme
  dark: {
    canvas: '#1a1614',
    surface: '#221d1a',
    surfaceMuted: '#1f1a17',
    sidebar: 'rgba(20,16,14,0.82)',
    line: 'rgba(255,255,255,0.07)',
    lineStrong: 'rgba(255,255,255,0.14)',
    ink: '#f4ece2',
    ink70: 'rgba(244,236,226,0.7)',
    ink50: 'rgba(244,236,226,0.5)',
    ink35: 'rgba(244,236,226,0.35)',
    ink20: 'rgba(244,236,226,0.2)',
    ink10: 'rgba(244,236,226,0.1)',
    accent: '#FF8B62',
    accent2: '#F04C7E',
    accentSoft: 'rgba(255,139,98,0.16)',
    accent2Soft: 'rgba(240,76,126,0.16)',
    gradient: 'linear-gradient(135deg, #FF8B62 0%, #F04C7E 100%)',
    gradientSoft: 'linear-gradient(135deg, rgba(255,139,98,0.20) 0%, rgba(240,76,126,0.20) 100%)',
    success: '#3ec78a',
    decision: '#a78bfa',
    action: '#3ec7c7',
  },
};

function useTheme(themeName) {
  return TOKENS[themeName] || TOKENS.warm;
}

window.TOKENS = TOKENS;
window.useTheme = useTheme;
