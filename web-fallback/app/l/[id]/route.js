import { linkById, profileById, logClick } from '../../../lib/data';
import { linkUrl } from '../../../lib/links';

export const dynamic = 'force-dynamic';

export async function GET(_request, { params }) {
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/i.test(id)) return new Response('Not found', { status: 404 });
  const link = await linkById(id);
  if (!link || !link.is_active) return new Response('Not found', { status: 404 });
  const profile = await profileById(link.profile_id);
  if (!profile || profile.is_paused || (profile.privacy_mode !== 'custom' && link.visibility_mode !== 'both' && link.visibility_mode !== profile.privacy_mode)) {
    return new Response('Not found', { status: 404 });
  }
  const target = linkUrl(link.platform, link.url_or_handle);
  if (!target) return new Response('Invalid link', { status: 400 });
  await logClick(profile.id, link.id);
  return Response.redirect(target, 302);
}
