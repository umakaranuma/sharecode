export function linkUrl(platform, value) {
  const clean = String(value ?? '').trim();
  if (!clean) return null;
  if (/^https?:\/\//i.test(clean)) return safeUrl(clean);
  const handle = clean.replace(/^@/, '');
  const paths = {
    instagram: `https://instagram.com/${encodeURIComponent(handle)}`,
    tiktok: `https://www.tiktok.com/@${encodeURIComponent(handle)}`,
    snapchat: `https://www.snapchat.com/add/${encodeURIComponent(handle)}`,
    linkedin: `https://www.linkedin.com/in/${encodeURIComponent(handle)}`,
    spotify: `https://open.spotify.com/user/${encodeURIComponent(handle)}`,
    youtube: `https://www.youtube.com/@${encodeURIComponent(handle)}`,
    telegram: `https://t.me/${encodeURIComponent(handle)}`,
    facebook: `https://facebook.com/${encodeURIComponent(handle)}`,
    x: `https://x.com/${encodeURIComponent(handle)}`,
    threads: `https://www.threads.net/@${encodeURIComponent(handle)}`,
    behance: `https://www.behance.net/${encodeURIComponent(handle)}`,
  };
  if (platform === 'whatsapp') {
    const digits = clean.replace(/[^0-9]/g, '');
    return `https://wa.me/${digits.startsWith('0') ? `94${digits.slice(1)}` : digits}`;
  }
  if (platform === 'email') return `mailto:${encodeURIComponent(clean)}`;
  if (platform === 'phone') return `tel:${clean.replace(/[^+0-9]/g, '')}`;
  return paths[platform] ?? safeUrl(`https://${clean}`);
}

function safeUrl(value) {
  try {
    const url = new URL(value);
    return ['https:', 'http:'].includes(url.protocol) ? url.toString() : null;
  } catch { return null; }
}

export function vcardEscape(value) {
  return String(value ?? '').replace(/\\/g, '\\\\').replace(/\r?\n/g, '\\n').replace(/,/g, '\\,').replace(/;/g, '\\;');
}
