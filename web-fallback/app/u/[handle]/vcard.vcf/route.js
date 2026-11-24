import { publicProfile, logClick } from '../../../../lib/data';
import { vcardEscape } from '../../../../lib/links';

export const dynamic = 'force-dynamic';

export async function GET(_request, { params }) {
  const { handle } = await params;
  const result = await publicProfile(handle);
  if (!result || result.profile.is_paused || result.profile.privacy_mode !== 'work' || !result.profile.allow_save_contact) {
    return new Response('Contact unavailable', { status: 404 });
  }
  const p = result.profile;
  const lines = ['BEGIN:VCARD', 'VERSION:3.0', `FN:${vcardEscape(p.display_name)}`];
  if (p.phone) lines.push(`TEL:${vcardEscape(p.phone)}`);
  if (p.contact_email) lines.push(`EMAIL:${vcardEscape(p.contact_email)}`);
  if (p.company) lines.push(`ORG:${vcardEscape(p.company)}`);
  if (p.designation) lines.push(`TITLE:${vcardEscape(p.designation)}`);
  lines.push('END:VCARD');
  await logClick(p.id, null, 'vcf_download');
  return new Response(`${lines.join('\r\n')}\r\n`, {
    headers: { 'Content-Type': 'text/vcard; charset=utf-8', 'Content-Disposition': `attachment; filename="${p.handle}.vcf"`, 'Cache-Control': 'no-store' },
  });
}
