-- VibeDrop mobile schema. Public reads and event writes belong in server endpoints.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  handle text not null unique check (handle ~ '^[a-z0-9_]{3,24}$'),
  display_name text not null,
  bio text not null default '' check (char_length(bio) <= 150),
  city text not null default '',
  campus text not null default '',
  phone text not null default '',
  contact_email text not null default '',
  company text not null default '',
  designation text not null default '',
  avatar_url text,
  cover_url text,
  gallery_urls text[] not null default '{}',
  privacy_mode text not null default 'social' check (privacy_mode in ('social','work','custom')),
  is_paused boolean not null default false,
  allow_save_contact boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.social_links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  label text not null default '',
  url_or_handle text not null,
  visibility_mode text not null default 'both' check (visibility_mode in ('social','work','both')),
  sort_order integer not null default 0,
  is_active boolean not null default true
);

create table if not exists public.qr_configs (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  fg_color text not null default '#6B20E8',
  dot_style text not null default 'rounded',
  updated_at timestamptz not null default now()
);

create table if not exists public.qr_scans (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  source text not null check (source in ('app','web_fallback')),
  device_os text,
  city text,
  country text,
  scanned_at timestamptz not null default now()
);

create table if not exists public.link_clicks (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  social_link_id uuid references public.social_links(id) on delete set null,
  action_type text not null check (action_type in ('link_click','vcf_download')),
  clicked_at timestamptz not null default now()
);

create table if not exists public.connections_waves (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_profile_id uuid not null references public.profiles(id) on delete cascade,
  note text not null default '' check (char_length(note) <= 150),
  status text not null default 'pending' check (status in ('pending','accepted','blocked')),
  created_at timestamptz not null default now(),
  unique(sender_id, receiver_profile_id)
);

create table if not exists public.subscriptions (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  provider text not null,
  provider_ref text not null,
  status text not null check (status in ('active','expired','cancelled')),
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  product_type text not null,
  shipping_address text not null,
  phone text not null,
  amount_lkr numeric(12,2) not null check (amount_lkr >= 0),
  payment_status text not null default 'pending',
  fulfillment_status text not null default 'pending',
  created_at timestamptz not null default now()
);

create index if not exists social_links_profile_order on public.social_links(profile_id, sort_order);
create index if not exists qr_scans_profile_time on public.qr_scans(profile_id, scanned_at desc);
create index if not exists link_clicks_profile_time on public.link_clicks(profile_id, clicked_at desc);
create index if not exists connections_waves_receiver on public.connections_waves(receiver_profile_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.social_links enable row level security;
alter table public.qr_configs enable row level security;
alter table public.qr_scans enable row level security;
alter table public.link_clicks enable row level security;
alter table public.connections_waves enable row level security;
alter table public.subscriptions enable row level security;
alter table public.orders enable row level security;

create policy "profile owner reads" on public.profiles for select to authenticated using (id = auth.uid());
create policy "profile owner inserts" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "profile owner updates" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "profile owner deletes" on public.profiles for delete to authenticated using (id = auth.uid());

create policy "link owner reads" on public.social_links for select to authenticated using (profile_id = auth.uid());
create policy "link owner inserts" on public.social_links for insert to authenticated with check (profile_id = auth.uid());
create policy "link owner updates" on public.social_links for update to authenticated using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy "link owner deletes" on public.social_links for delete to authenticated using (profile_id = auth.uid());

create policy "qr owner reads" on public.qr_configs for select to authenticated using (profile_id = auth.uid());
create policy "qr owner inserts" on public.qr_configs for insert to authenticated with check (profile_id = auth.uid());
create policy "qr owner updates" on public.qr_configs for update to authenticated using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "scan owner reads" on public.qr_scans for select to authenticated using (profile_id = auth.uid());
create policy "click owner reads" on public.link_clicks for select to authenticated using (profile_id = auth.uid());
create policy "sender or receiver reads wave" on public.connections_waves for select to authenticated using (sender_id = auth.uid() or receiver_profile_id = auth.uid());
create policy "sender creates wave" on public.connections_waves for insert to authenticated with check (sender_id = auth.uid() and sender_id <> receiver_profile_id);
create policy "subscription owner reads" on public.subscriptions for select to authenticated using (profile_id = auth.uid());
create policy "order owner reads" on public.orders for select to authenticated using (profile_id = auth.uid());

-- The server role alone creates scan/click events, subscriptions, and orders.

insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true)
on conflict (id) do nothing;
create policy "avatar owner uploads" on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatar owner updates" on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

insert into storage.buckets (id, name, public) values ('covers', 'covers', true)
on conflict (id) do nothing;
create policy "cover owner uploads" on storage.objects for insert to authenticated
with check (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "cover owner updates" on storage.objects for update to authenticated
using (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text);

insert into storage.buckets (id, name, public) values ('gallery', 'gallery', true)
on conflict (id) do nothing;
create policy "gallery owner uploads" on storage.objects for insert to authenticated
with check (bucket_id = 'gallery' and (storage.foldername(name))[1] = auth.uid()::text);
