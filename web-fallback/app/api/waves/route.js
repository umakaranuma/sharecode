import { admin, publicProfile } from '../../../lib/data';

async function requester(request) {
  const bearer = request.headers.get('authorization')?.replace(/^Bearer /i, '');
  if (!bearer) return null;
  const { data, error } = await admin().auth.getUser(bearer);
  return error ? null : data.user;
}

export async function GET(request) {
  const user = await requester(request);
  if (!user) return Response.json({ error: 'Sign in required' }, { status: 401 });
  const db = admin();
  const { data: waves, error } = await db.from('connections_waves').select('id,sender_id,note,status,created_at').eq('receiver_profile_id', user.id).order('created_at', { ascending: false }).limit(50);
  if (error) return Response.json({ error: 'Could not load waves' }, { status: 500 });
  const ids = [...new Set((waves ?? []).map(wave => wave.sender_id))];
  const { data: senders } = ids.length ? await db.from('profiles').select('id,display_name,handle,avatar_url').in('id', ids) : { data: [] };
  const names = new Map((senders ?? []).map(sender => [sender.id, sender]));
  return Response.json((waves ?? []).map(wave => ({ ...wave, sender: names.get(wave.sender_id) ?? null })), { headers: { 'Cache-Control': 'no-store' } });
}

export async function POST(request) {
  const user = await requester(request);
  if (!user) return Response.json({ error: 'Sign in required' }, { status: 401 });
  const db = admin();
  const body = await request.json().catch(() => null);
  const handle = String(body?.handle ?? '');
  const note = String(body?.note ?? '').trim().slice(0, 150);
  const result = await publicProfile(handle);
  if (!result || result.profile.is_paused) return Response.json({ error: 'Profile unavailable' }, { status: 404 });
  if (result.profile.id === user.id) return Response.json({ error: 'Cannot wave at yourself' }, { status: 400 });
  const { error } = await db.from('connections_waves').insert({ sender_id: user.id, receiver_profile_id: result.profile.id, note, status: 'pending' });
  if (error?.code === '23505') return Response.json({ error: 'Wave already sent' }, { status: 409 });
  if (error) return Response.json({ error: 'Could not send wave' }, { status: 500 });
  return Response.json({ ok: true });
}
