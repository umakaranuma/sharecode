import { headers } from 'next/headers';
import { notFound } from 'next/navigation';
import { logScan, publicProfile } from '../../../lib/data';

export const dynamic = 'force-dynamic';

export default async function ProfilePage({ params }) {
  const { handle } = await params;
  const result = await publicProfile(handle);
  if (!result) notFound();
  const { profile, links } = result;
  const headerList = await headers();
  await logScan(profile.id, headerList.get('user-agent') ?? '');

  return <main className="shell">
    <div className="brand">✦ VibeDrop</div>
    <article className="card profile">
      <div className="cover" style={profile.cover_url ? { backgroundImage: `url(${profile.cover_url})` } : undefined} />
      <div className="details">
        <div className="avatar">{profile.avatar_url ? <img src={profile.avatar_url} alt="" /> : profile.display_name.charAt(0).toUpperCase()}</div>
        <h1>{profile.display_name}</h1>
        <p className="handle">@{profile.handle}</p>
        {profile.is_paused ? <div className="private">This profile is currently private.</div> : <>
          {profile.bio && <p className="bio">{profile.bio}</p>}
          {(profile.city || profile.campus) && <p className="location">{[profile.city, profile.campus].filter(Boolean).join(' · ')}</p>}
          {profile.privacy_mode !== 'work' && profile.gallery_urls?.length > 0 && <div className="gallery">{profile.gallery_urls.map(url => <img key={url} src={url} alt="Profile gallery" />)}</div>}
          <div className="links">{links.map(link => <a key={link.id} className="link" href={`/l/${link.id}`}><span>{link.label || link.platform}</span><span aria-hidden="true">↗</span></a>)}</div>
          {profile.privacy_mode === 'work' && profile.allow_save_contact && <a className="save" href={`/u/${profile.handle}/vcard.vcf`}>Save Contact</a>}
        </>}
      </div>
    </article>
    <p className="foot">Create your own digital identity with VibeDrop.</p>
  </main>;
}
