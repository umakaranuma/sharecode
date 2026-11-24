# Flutter & Backend Implementation Guide

**Project:** Dynamic Social-Identity, Profile/Cover Media & Smart QR Application  
**Mobile Framework:** Flutter (iOS & Android)  
**Backend & Database:** Supabase (PostgreSQL, Auth, Storage, Edge Functions) + Web Fallback & Deep Links  

---

## 1. High-Level System Architecture

To make scanning seamless and keep your backend clean and secure, the system is divided into three connected parts:

1. **Flutter Mobile App (`iOS & Android`):** Handles authentication, profile and social link editing, privacy mode switching, avatar/cover image generation requests, QR styling, multi-format exports (lock-screen wallpaper, story card, PNG/SVG), deep-link handling, and analytics viewing.
2. **Supabase Backend (`PostgreSQL + Auth + Storage + Edge Functions`):** Stores user accounts, profiles, social links, QR configurations, scan/click logs, media generation records, and orders. Uses Row Level Security (RLS) for direct user data access and Edge Functions/API endpoints for sensitive operations.
3. **Web Fallback & Deep-Link Layer (`https://yourapp.lk/u/<handle>`):** Resolves dynamic QR slugs. If the scanner has the app installed, Android App Links or iOS Universal Links open the profile inside the app. If not, a fast web profile page opens in the browser with one-tap social links and `.vcf` contact download.

---

## 2. What You Need to Build in Flutter

### 2.1 Project Structure & State Management
* Organize the codebase by feature (`features/auth`, `features/profile`, `features/media_studio`, `features/qr_studio`, `features/export`, `features/scanner_view`, `core/routing`, `core/network`).
* Use **BLoC/Cubit** or **Riverpod** for predictable state management and **`go_router`** for navigation and deep links.
* **Security rule:** Never store secret API keys (image generation keys, payment gateway secrets, or Supabase service-role keys) inside Flutter code or assets.

### 2.2 Core Screens & Features

#### A. Authentication & Onboarding
* Sign in with **Google**, **Apple**, **Email/Password**, or **Phone/Email OTP** using `supabase_flutter`.
* Onboarding flow:
  1. Claim a unique `@handle` (used in `https://yourapp.lk/u/<handle>`).
  2. Enter display name, bio, and default privacy mode.
  3. Add initial social links or contact info so the user gets a working QR code right away.

#### B. Profile & Social Links Editor
* Add, edit, toggle active/inactive, and reorder social links (Instagram, WhatsApp, TikTok, Snapchat, LinkedIn, X, YouTube, custom URLs) and contact fields (phone number, email, `.vcf` details).
* Auto-format handles/numbers into clean links (for example, turning a mobile number into a WhatsApp chat link or vCard field) while keeping raw handles editable.
* **Privacy Mode Switcher:** Let users switch between modes in one tap without changing their QR code:
  * *Social Mode:* Shows social links/media and hides sensitive contact details like personal phone numbers.
  * *Work / Campus Mode:* Highlights professional/academic links and contact details.
  * *Locked / Paused Mode:* Hides public profile details until unlocked or re-enabled.

#### C. Profile Image, Cover Image & QR Studio
* **Avatar & Cover Image Generation:** Allow users to upload existing photos or generate custom profile avatars and cover images in exact aspect ratios (such as `1:1` for avatars and `16:9`, `4:3`, or `3:2` for cover banners) by calling your backend media generation endpoint.
* **Dynamic QR Generator:** Generate a QR code pointing to `https://yourapp.lk/u/<handle>` with customizable colors, module/corner styles, and optional center avatar/logo—while preserving strong contrast and error correction so cameras scan reliably.

#### D. Multi-Format Export Hub
* Render export templates at high resolution (using off-screen rendering/canvas export helpers and saving via gallery/file packages):
  * **Lock-Screen Wallpaper:** Sized for phone screens (`9:16` / `9:19.5` style layouts) with the QR placed cleanly below the clock area.
  * **Story / Social Card:** Vertical/square shareable cards (`9:16` or `4:5` / `1:1`) combining cover/avatar, handle, and QR.
  * **Standard Image & Vector Exports:** High-resolution `PNG` and print-ready `SVG` / card layouts (`1:1`, `3:2`) for stickers, cards, or merchandise.

#### E. Deep-Link Handling & Scanned Profile View
* Configure **Android App Links** (`AndroidManifest.xml` with `autoVerify="true"`) and **iOS Universal Links** (Associated Domains in Xcode), and listen for incoming links using `app_links` + `go_router`.
* Build the **Scanned Profile Screen** to display the target user's public profile filtered by their active privacy mode, support one-tap **Save to Contacts** (`.vcf`), and send click events to your backend.

#### F. Analytics & Subscription / Order Flow
* Display scan counts and link-click counts to the profile owner.
* Connect subscription upgrades and physical QR/NFC orders to your payment flow, verifying payment completion on the backend before unlocking Pro features or confirming orders.

---

## 3. Best Backend Choice & How to Manage Endpoints

### 3.1 Why Supabase Is the Best Fit
* **Relational Data for Profiles & Analytics:** PostgreSQL models users, profiles, social links, QR settings, scan events, and click events cleanly with foreign keys and indexes.
* **Built-In Auth & Storage:** Handles user sign-in and media storage buckets (`avatars`, `covers`, `exports`) in one place.
* **Row Level Security (RLS) + Server Endpoints:** Lets authenticated users manage their own records safely while keeping sensitive logic (scan logging, media generation, payment webhooks, and `.vcf` generation) on the server.

### 3.2 Direct Supabase Access vs. Backend Endpoints

#### Direct Supabase Client (with RLS Enabled)
Use `supabase_flutter` directly when `auth.uid() = user_id` for:
* Signing in, signing out, and refreshing sessions.
* Reading and updating the logged-in user's own `profiles`, `social_links`, and `qr_configs`.
* Uploading user-selected images to allowed Storage paths.

#### Backend / Edge Function Endpoints to Create
1. **`GET /r/:slug` (Scan Resolver & Redirect / Web Fallback)**
   * Looks up `slug` (`handle`) in `profiles`.
   * Checks if the profile is active or locked.
   * Inserts a row into `qr_scans` (timestamp, `web_fallback` or `app`, platform, coarse location/referrer if applicable).
   * Routes to the app via App Links / Universal Links when installed, or renders the `/u/:slug` web profile page when opened in a browser.
2. **`POST /events/click` (Link Click & vCard Action Tracker)**
   * Records when a visitor clicks a social link or downloads a `.vcf` contact card into `link_clicks`.
3. **`POST /media/generate` (Profile & Cover Image Generator)**
   * Authenticates the user, checks generation credits/rate limits, calls the image generation API using server-side credentials, enforces the requested aspect ratio, saves the output image to Storage, records it in `media_generations`, and returns the image URL.
4. **`GET /u/:slug/vcard.vcf` (Dynamic Contact Card Generator)**
   * Builds a valid vCard file containing only contact fields allowed by the profile's current `privacy_mode`.
5. **`POST /payments/webhook` (Payment Verification & Fulfillment)**
   * Verifies gateway signatures/payloads on the server and updates `profiles.is_pro` or creates/updates rows in `orders`.

---

## 4. Recommended PostgreSQL Schema (Supabase)

```sql
-- 1. Profiles
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  handle text unique not null,
  display_name text not null,
  bio text default '',
  avatar_url text,
  cover_url text,
  privacy_mode text not null default 'social' check (privacy_mode in ('social', 'work', 'locked')),
  is_pro boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Social & Contact Links
create table public.social_links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  label text not null,
  url_or_handle text not null,
  visibility_mode text not null default 'both' check (visibility_mode in ('social', 'work', 'both')),
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 3. QR Style Configuration
create table public.qr_configs (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  fg_color text not null default '#000000',
  bg_color text not null default '#FFFFFF',
  dot_style text not null default 'square',
  center_type text not null default 'none' check (center_type in ('none', 'avatar', 'logo')),
  updated_at timestamptz not null default now()
);

-- 4. QR Scan Events
create table public.qr_scans (
  id bigserial primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  source text not null check (source in ('app', 'web_fallback')),
  platform text not null default 'unknown',
  city text,
  country text,
  scanned_at timestamptz not null default now()
);

-- 5. Link Click & vCard Events
create table public.link_clicks (
  id bigserial primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  social_link_id uuid references public.social_links(id) on delete set null,
  action_type text not null check (action_type in ('link_click', 'vcf_download')),
  clicked_at timestamptz not null default now()
);

-- 6. Generated Media History
create table public.media_generations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  media_type text not null check (media_type in ('avatar', 'cover')),
  aspect_ratio text not null,
  prompt text not null,
  image_url text not null,
  created_at timestamptz not null default now()
);

-- 7. Subscriptions & Physical Orders
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  order_type text not null check (order_type in ('subscription', 'physical_qr')),
  status text not null default 'pending' check (status in ('pending', 'paid', 'failed', 'fulfilled')),
  provider_ref text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Indexes for fast lookups & analytics
create index idx_social_links_profile_order on public.social_links(profile_id, sort_order);
create index idx_qr_scans_profile_time on public.qr_scans(profile_id, scanned_at desc);
create index idx_link_clicks_profile_time on public.link_clicks(profile_id, clicked_at desc);
```

### Baseline Row Level Security (RLS) Guidance
* Enable RLS on all tables.
* Allow authenticated users to `SELECT`, `INSERT`, `UPDATE`, and `DELETE` only rows where `id = auth.uid()` (for `profiles`) or `profile_id = auth.uid()` (for `social_links`, `qr_configs`, `media_generations`, and `orders`).
* Keep `qr_scans` and `link_clicks` writable only through your backend/Edge Function (using the service role) and readable (`SELECT`) by the owning `profile_id = auth.uid()`.

---

## 5. Practical 4-Week Build Plan

1. **Week 1 — Foundation & Profile Editor:** Create the Supabase project, run the SQL schema with RLS, implement Flutter auth + `@handle` onboarding, and build the Profile & Social Links editor with Privacy Mode toggles.
2. **Week 2 — Dynamic QR, Exports & Web Fallback:** Build QR generation in Flutter, implement Lock-Screen Wallpaper / Story Card / PNG & SVG exports, and publish the `/u/:slug` web fallback page plus `.well-known` App Links / Universal Links files.
3. **Week 3 — Deep Links, Scan Logging & Click Analytics:** Wire `app_links` + `go_router` on Android and iOS, implement `/r/:slug` scan logging and `/events/click` tracking, and test cold-start deep links on real devices.
4. **Week 4 — Media Generation, Payments & Release Prep:** Add `POST /media/generate` for avatar and cover generation in exact aspect ratios, hook up payment verification webhooks, and run end-to-end testing before launch.