import { createClient } from '@supabase/supabase-js';

export function admin() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('Server Supabase settings are missing');
  return createClient(url, key, { auth: { persistSession: false } });
}

export async function publicProfile(handle) {
  if (!/^[a-z0-9_]{3,24}$/.test(handle)) return null;
  const db = admin();
  const { data: profile, error } = await db.from('profiles').select('id,handle,display_name,bio,city,campus,phone,contact_email,company,designation,avatar_url,cover_url,gallery_urls,privacy_mode,is_paused,allow_save_contact').eq('handle', handle).maybeSingle();
  if (error) throw error;
  if (!profile) return null;
  if (profile.is_paused) return { profile, links: [] };
  const { data: links, error: linkError } = await db.from('social_links').select('id,platform,label,url_or_handle,visibility_mode,sort_order').eq('profile_id', profile.id).eq('is_active', true).order('sort_order');
  if (linkError) throw linkError;
  return { profile, links: (links ?? []).filter(link => profile.privacy_mode === 'custom' || link.visibility_mode === 'both' || link.visibility_mode === profile.privacy_mode) };
}

export async function logScan(profileId, userAgent, source = 'web_fallback') {
  const device = /android/i.test(userAgent) ? 'Android' : /iphone|ipad/i.test(userAgent) ? 'iOS' : 'Other';
  await admin().from('qr_scans').insert({ profile_id: profileId, source, device_os: device });
}

export async function linkById(id) {
  const { data, error } = await admin().from('social_links').select('id,profile_id,platform,url_or_handle,visibility_mode,is_active').eq('id', id).maybeSingle();
  if (error) throw error;
  return data;
}

export async function profileById(id) {
  const { data, error } = await admin().from('profiles').select('id,privacy_mode,is_paused').eq('id', id).maybeSingle();
  if (error) throw error;
  return data;
}

export async function logClick(profileId, linkId, actionType = 'link_click') {
  await admin().from('link_clicks').insert({ profile_id: profileId, social_link_id: linkId, action_type: actionType });
}
