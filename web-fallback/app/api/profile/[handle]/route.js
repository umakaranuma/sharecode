import { publicProfile, logScan } from '../../../../lib/data';

export const dynamic = 'force-dynamic';

export async function GET(request, { params }) {
  const { handle } = await params;
  const result = await publicProfile(handle);
  if (!result) return Response.json({ error: 'Not found' }, { status: 404 });
  const { profile: p, links } = result;
  await logScan(p.id, request.headers.get('user-agent') ?? '', 'app');
  return Response.json({
    id: p.id, handle: p.handle, name: p.display_name, bio: p.is_paused ? '' : p.bio,
    city: p.is_paused ? '' : p.city, campus: p.is_paused ? '' : p.campus,
    avatarUrl: p.avatar_url, coverUrl: p.cover_url, paused: p.is_paused,
    galleryUrls: !p.is_paused && p.privacy_mode !== 'work' ? p.gallery_urls : [],
    canSaveContact: !p.is_paused && p.privacy_mode === 'work' && p.allow_save_contact,
    links: links.map(link => ({ id: link.id, platform: link.platform, label: link.label, value: link.url_or_handle })),
  }, { headers: { 'Cache-Control': 'no-store' } });
}
