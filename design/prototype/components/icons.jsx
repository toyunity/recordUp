// icons.jsx — minimal icon set, sized via currentColor

const Icon = ({ name, size = 16, stroke = 1.6, color = 'currentColor', style = {} }) => {
  const props = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth: stroke,
    strokeLinecap: 'round', strokeLinejoin: 'round',
    style,
  };
  switch (name) {
    case 'mic':
      return <svg {...props}><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3M8 21h8"/></svg>;
    case 'wave':
      return <svg {...props}><path d="M2 12h2M6 8v8M10 5v14M14 8v8M18 11v2M22 12h-2"/></svg>;
    case 'doc':
      return <svg {...props}><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6M8 13h8M8 17h6"/></svg>;
    case 'play':
      return <svg {...props}><path d="M6 4l14 8-14 8z" fill={color}/></svg>;
    case 'pause':
      return <svg {...props}><rect x="6" y="4" width="4" height="16" rx="1" fill={color}/><rect x="14" y="4" width="4" height="16" rx="1" fill={color}/></svg>;
    case 'stop':
      return <svg {...props}><rect x="5" y="5" width="14" height="14" rx="2" fill={color}/></svg>;
    case 'check':
      return <svg {...props}><path d="M4 12l5 5 11-11"/></svg>;
    case 'x':
      return <svg {...props}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'lock':
      return <svg {...props}><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>;
    case 'plus':
      return <svg {...props}><path d="M12 5v14M5 12h14"/></svg>;
    case 'search':
      return <svg {...props}><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>;
    case 'sidebar':
      return <svg {...props}><rect x="3" y="4" width="18" height="16" rx="2"/><path d="M9 4v16"/></svg>;
    case 'gear':
      return <svg {...props}><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.3l2-1.5-2-3.5-2.4.8a7 7 0 0 0-2.2-1.3L14 3h-4l-.3 2.2a7 7 0 0 0-2.2 1.3l-2.4-.8-2 3.5 2 1.5A7 7 0 0 0 5 12c0 .4 0 .9.1 1.3l-2 1.5 2 3.5 2.4-.8c.7.5 1.4.9 2.2 1.3L10 21h4l.3-2.2a7 7 0 0 0 2.2-1.3l2.4.8 2-3.5-2-1.5c.1-.4.1-.9.1-1.3z"/></svg>;
    case 'folder':
      return <svg {...props}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>;
    case 'sparkle':
      return <svg {...props}><path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/></svg>;
    case 'arrowRight':
      return <svg {...props}><path d="M5 12h14M13 6l6 6-6 6"/></svg>;
    case 'arrowLeft':
      return <svg {...props}><path d="M19 12H5M11 6l-6 6 6 6"/></svg>;
    case 'export':
      return <svg {...props}><path d="M12 3v12M7 8l5-5 5 5M5 17v2a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-2"/></svg>;
    case 'copy':
      return <svg {...props}><rect x="8" y="8" width="13" height="13" rx="2"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/></svg>;
    case 'share':
      return <svg {...props}><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/></svg>;
    case 'pencil':
      return <svg {...props}><path d="M4 20l4-1 11-11-3-3L5 16z"/></svg>;
    case 'user':
      return <svg {...props}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>;
    case 'users':
      return <svg {...props}><circle cx="9" cy="8" r="4"/><path d="M2 21a7 7 0 0 1 14 0"/><path d="M17 11a3 3 0 1 0 0-6M22 21a6 6 0 0 0-5-6"/></svg>;
    case 'clock':
      return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    case 'calendar':
      return <svg {...props}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
    case 'flag':
      return <svg {...props}><path d="M5 3v18M5 4h12l-2 4 2 4H5"/></svg>;
    case 'star':
      return <svg {...props}><path d="M12 3l2.7 5.5 6.3.9-4.5 4.4 1 6.2L12 17l-5.5 3 1-6.2L3 9.4l6.3-.9z"/></svg>;
    case 'trash':
      return <svg {...props}><path d="M4 7h16M9 7V4h6v3M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/></svg>;
    case 'list':
      return <svg {...props}><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/></svg>;
    case 'sound':
      return <svg {...props}><path d="M3 10v4h4l5 4V6l-5 4H3z"/><path d="M16 8a5 5 0 0 1 0 8M19 5a9 9 0 0 1 0 14"/></svg>;
    case 'lightning':
      return <svg {...props}><path d="M13 2L4 14h7l-1 8 9-12h-7z"/></svg>;
    case 'tag':
      return <svg {...props}><path d="M3 3h9l9 9-9 9-9-9z"/><circle cx="8" cy="8" r="1.5" fill={color}/></svg>;
    case 'more':
      return <svg {...props}><circle cx="6" cy="12" r="1.5" fill={color}/><circle cx="12" cy="12" r="1.5" fill={color}/><circle cx="18" cy="12" r="1.5" fill={color}/></svg>;
    case 'refresh':
      return <svg {...props}><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M3 21v-5h5"/></svg>;
    case 'download':
      return <svg {...props}><path d="M12 3v13M7 12l5 5 5-5M5 21h14"/></svg>;
    case 'globe':
      return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>;
    case 'link':
      return <svg {...props}><path d="M10 14a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1"/><path d="M14 10a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/></svg>;
    case 'eye':
      return <svg {...props}><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>;
    case 'mdLogo':
      return <svg {...props}><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M6 15V9l3 3 3-3v6M16 9v6M14 13l2 2 2-2"/></svg>;
    default:
      return <svg {...props}><circle cx="12" cy="12" r="8"/></svg>;
  }
};

window.Icon = Icon;
