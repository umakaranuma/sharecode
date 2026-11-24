import { admin } from '../../../../../lib/data';

export async function POST(request, { params }) {
  const bearer = request.headers.get('authorization')?.replace(/^Bearer /i, '');
  if (!bearer) return Response.json({ error: 'Sign in required' }, { status: 401 });
  const db = admin();
  const { data: auth, error: authError } = await db.auth.getUser(bearer);
  if (authError || !auth.user) return Response.json({ error: 'Invalid session' }, { status: 401 });
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/i.test(id)) return Response.json({ error: 'Not found' }, { status: 404 });
  const { data, error } = await db.from('connections_waves').update({ status: 'accepted' }).eq('id', id).eq('receiver_profile_id', auth.user.id).eq('status', 'pending').select('id').maybeSingle();
  if (error || !data) return Response.json({ error: 'Wave unavailable' }, { status: 404 });
  return Response.json({ ok: true });
}
