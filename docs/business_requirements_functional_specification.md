# Business Requirements Document (BRD) & Functional Specification
**Project Name:** VibeDrop / LinkQR (Working Title)  
**Target Market:** Sri Lanka (Jaffna, Colombo, Island-wide) & Global Expansion  
**Platform:** Mobile Application (iOS & Android via Flutter) + Dynamic Web Fallback (`yourapp.lk`)

---

## 1. Executive Summary & Core Architecture

### 1.1 Product Vision
A mobile-first dynamic digital identity and social-connection platform that allows users to consolidate their social media profiles, contact details, and photos into a single customizable profile, generate stylized QR codes in multiple formats, and control who sees what in real time—without forcing the person scanning the QR code to download the app first.

### 1.2 The Golden Rule: Dynamic Routing + "App-Optional" Scanning
* **Dynamic QR Encoding:** The QR code **never** hardcodes raw social links directly. Instead, it encodes a short, permanent dynamic URL: `https://yourapp.lk/u/{username}` (or `https://yourapp.lk/c/{card_slug}`).
* **Why This Matters:**
  1. Users can update their Instagram handle, phone number, photos, or active privacy mode anytime without re-downloading or reprinting their QR code.
  2. **Universal Links (iOS) & App Links (Android):**
     * **If the scanner HAS the app installed:** The phone OS intercepts the URL and opens the profile natively inside the mobile app (enabling 1-tap "Wave Back", "Save Contact", and mutual connection features).
     * **If the scanner DOES NOT have the app installed:** It opens an ultra-fast, zero-login mobile web page in Chrome/Safari displaying the profile, social buttons, and a 1-tap `.vcf` contact download button, alongside a banner prompting them to download the app.

---

## 2. User Roles

1. **Standard User (Free Tier):** Registers, builds 1 primary profile card, generates standard QR codes, downloads basic formats, and views total scan counts.
2. **Pro User (Paid Subscription):** Unlocks multiple profile modes (e.g., *Social Mode* vs. *Business Mode*), custom QR styling, lock-screen wallpaper generator, question/password locks, and detailed scan analytics.
3. **Scanner / Guest (Unauthenticated or App User):** Anyone scanning the QR code via native phone camera, Google Lens, or inside the app.
4. **System Admin (Web Dashboard):** Manages users, reported profiles, promo codes, physical merch orders, and subscription tiers.

---

## 3. Complete Functional Requirements

### Module 1: Authentication & Onboarding
1. **Registration & Login Methods:**
   * **Continue with Google** (1-tap OAuth — primary for Android users in Sri Lanka).
   * **Continue with Apple** (Required for iOS App Store compliance).
   * **Mobile Number + OTP** (SMS OTP via Dialog/Mobitel gateway or WhatsApp OTP for instant local onboarding).
   * **Email & Password** (Standard signup with email verification link & password reset flow).
2. **Username Claim & Onboarding Wizard:**
   * Step 1: Claim unique handle (`@username`, alphanumeric + underscores, real-time availability check).
   * Step 2: Upload profile picture (with built-in crop/compress) and enter Display Name + 1-line Bio (supports English, Tamil, and Sinhala Unicode).
   * Step 3: Add top 2 social links (e.g., Instagram, WhatsApp) so the user reaches an active QR code within 45 seconds of signup.

---

### Module 2: Profile & Digital Card Builder
Users can build and edit their digital card content inside the app:

1. **Media & Bio Section:**
   * Profile Avatar (circular/rounded square) + Cover Banner image or animated gradient background.
   * Display Name, Tagline/Bio (max 150 chars), City/Campus badge (optional, e.g., *"Jaffna"*, *"Colombo"*, *"UoJ"*).
   * Photo Gallery Carousel (up to 3 photos on Free, up to 9 photos on Pro).
2. **Social Media & Platform Links (Drag-and-Drop Reordering):**
   * **Social:** Instagram, Snapchat, TikTok, Facebook, X (Twitter), Threads, YouTube.
   * **Messaging:** WhatsApp (auto-formats `+94` numbers into `wa.me` direct chat links with optional pre-filled greeting like *"Hey! Scanned your QR"*), Telegram, Viber.
   * **Music & Lifestyle:** Spotify (Profile or favorite anthem track preview), LinkedIn, Behance/Portfolio, Custom Website URL.
   * *Smart Input Helper:* Users only type their username (e.g., `kavishan_99`) rather than pasting full URLs; the app validates and builds the deep link (`instagram://user?username=...` with web fallback).
3. **Contact Card (vCard / `.vcf`) Fields:**
   * Primary Mobile Number, Secondary Number, Email Address, Company/University, Designation.
   * Includes a toggle: **"Allow 1-Tap Save to Contacts"** (generates a downloadable `.vcf` file when scanned).

---

### Module 3: Multi-Mode & Privacy Controls (Critical for Sri Lanka)
Users control exactly what is exposed when someone scans their QR code:

1. **Profile Modes (Switchable in 1 Tap without changing the QR):**
   * **Chill / Social Mode:** Displays only Instagram, Snapchat, TikTok, Spotify, and photos. Hides phone numbers, email, and LinkedIn.
   * **Work / Campus Mode:** Displays phone number, WhatsApp, email, LinkedIn, and portfolio.
   * **Custom Mode (Pro):** User creates custom visibility rules per link.
2. **Privacy & Safety Shield:**
   * **Master Pause Switch ("Ghost Mode"):** Temporarily disables the QR link; scanners see a *"This profile is currently private"* message.
   * **Secret Question / PIN Lock (Pro):** User sets a playful riddle or 4-digit PIN (e.g., *"What café did we meet at?"*). Scanners see the user's photo/bio and must answer correctly to unlock the Instagram/WhatsApp links.
   * **Auto-Expiring Temporary Link (Pro):** Generates a 24-hour burner QR link for parties/events that self-destructs automatically.
   * **Report & Block System:** Scanners can report abusive/impersonation profiles; owners can block specific app users from sending waves.

---

### Module 4: QR Code Customization & Export Studio
This is the core creation engine inside the mobile app:

1. **QR Visual Customizer:**
   * **Dot & Eye Styles:** Classic square, rounded dots, liquid/smooth, diamond.
   * **Color Palettes:** Solid colors, dual-tone gradients, dark/neon presets, and brand-matched themes.
   * **Center Logo / Avatar:** Embed the user's profile picture, Instagram icon, or custom monogram in the center (automatically sets QR Error Correction Level to `H` / 30% so it remains 100% scannable).
   * **Call-to-Action (CTA) Frames:** Border frames with customizable text in English, Tamil, or Sinhala (e.g., *"Scan for Insta"*, *"Tap to Connect"*, *"Save My Number"*).
2. **Multi-Format Download & Share Options:**
   * **Option 1: Lock-Screen Wallpaper Generator (Hero Feature):** Detects the user's exact phone screen resolution and places the stylized QR in the lower-middle safe zone (below the lock-screen clock/notifications) over a custom aesthetic background or user photo. One tap saves directly to Camera Roll.
   * **Option 2: Instagram Story / Highlight Card (1080 × 1920 PNG):** Ready-to-post vertical card with user's photo, handle, and QR framed for Instagram Highlights.
   * **Option 3: Standard High-Res Image (PNG / JPG):** 2048 × 2048 px crisp image for sharing on WhatsApp or gallery.
   * **Option 4: Transparent Background PNG:** For overlaying onto videos, posters, or custom designs.
   * **Option 5: Print-Ready Vector (SVG / PDF — Pro):** Infinite-resolution file for printing on bike stickers, phone cases, T-shirts, café table tents, or wedding cards.
   * **Option 6: Apple Wallet / Google Wallet Pass:** Adds the QR card directly into the phone's native wallet for double-click power-button access.

---

### Module 5: Scanning Flow & In-App Social Loop
What happens step-by-step when **User B** scans **User A's** QR code:

```text
[User B Points Camera at User A's QR]
                 │
                 ▼
   Reads URL: https://yourapp.lk/u/kavishan
                 │
        ┌────────┴────────┐
        ▼                 ▼
[App IS Installed]  [App NOT Installed]
        │                 │
        ▼                 ▼
Opens natively in    Opens fast Mobile Web
User B's App         Profile in Browser
        │                 │
        ├────────┬────────┘
                 ▼
   Checks Privacy Mode & Locks
   (Active / Paused / PIN Locked)
                 │
                 ▼
   Displays Profile, Photos & Links
   • Tap Instagram ──► Opens IG App directly
   • Tap WhatsApp  ──► Opens WA Chat directly
   • Tap Save Contact ► Downloads .vcf file
   • Tap "Send Wave" ─► Sends mutual interest ping
```

1. **Built-In App Scanner:** Includes a fast camera QR scanner tab inside the app (with flashlight toggle and "Scan from Gallery Image" support for screenshots).
2. **Scan History ("My Wallet"):** When an app user scans someone else's QR, that card is automatically saved in their *"Scanned Connections"* list so they never lose a contact.
3. **"Send a Wave" (Mutual Icebreaker):**
   * When User B views User A's profile (via app or web), they can tap **"Wave 👋"** and optionally leave a 1-line note (*"Saw you at Cargills Square!"*).
   * User A gets a push notification. If User A waves back, both users get a *"Mutual Wave"* badge and unlock direct in-app chat or private handles.

---

### Module 6: Analytics & Notifications
1. **Scan & Click Dashboard:**
   * **Free:** Total lifetime QR scans and total link clicks.
   * **Pro:** Daily/weekly scan graphs, link-by-link breakdown (e.g., *42 scans → 31 clicked Instagram, 8 clicked WhatsApp, 3 saved contact*), approximate city-level scan location (e.g., *Jaffna*, *Colombo*), and device type (iOS vs. Android).
2. **Push Notifications (Firebase Cloud Messaging):**
   * *"Someone in Jaffna just scanned your QR code!"*
   * *"You received a new Wave 👋"*
   * *"Your QR card hit 100 scans!"*

---

### Module 7: Monetization & Physical Merch Store
1. **Subscription Engine (Free vs. Pro):**
   * Integrated with **PayHere / LankaQR** (for Sri Lankan cards, Genie, FriMi, eZ Cash, LankaQR) and **RevenueCat** (for Apple App Store & Google Play global in-app purchases).
2. **In-App Physical Drop Store ("Order Physical QR"):**
   * Users tap **"Print My QR"** inside the export screen to order:
     * Waterproof Phone-Back Epoxy QR/NFC Sticker
     * Custom Acrylic Keychain
     * Matte Black Metal / PVC Tap Card
   * Auto-populates their dynamic QR link into the print order queue and collects delivery address + COD/Card payment.

---

## 4. Technical Stack & Database Blueprint

### 4.1 Recommended Tech Stack
* **Mobile App:** Flutter (single codebase for iOS & Android, fast native QR rendering via `pretty_qr_code`, local image compositing for lock-screen wallpapers).
* **Web Fallback & Deep-Link Host:** Next.js (deployed on Vercel/Cloudflare for sub-100ms edge rendering of `/u/{username}` pages + `.well-known/apple-app-site-association` and `.well-known/assetlinks.json`).
* **Backend & Database:** Supabase (PostgreSQL + Auth + Storage buckets for avatars/galleries + Edge Functions for `.vcf` generation and analytics logging).
* **Payments:** PayHere API (LKR & USD) + RevenueCat (IAP).

### 4.2 Core Database Tables (PostgreSQL)
* `users`: `id`, `email`, `phone`, `auth_provider`, `tier` (`free` | `pro`), `pro_expires_at`, `created_at`
* `profiles`: `id`, `user_id`, `username` (unique slug), `display_name`, `bio`, `avatar_url`, `cover_url`, `active_mode` (`social` | `work` | `paused`), `lock_question`, `lock_answer_hash`, `qr_style_json`
* `profile_links`: `id`, `profile_id`, `platform` (`instagram`, `whatsapp`, `tiktok`, etc.), `handle_or_url`, `visible_in_modes` (array), `sort_order`, `click_count`
* `scan_events`: `id`, `profile_id`, `scanner_user_id` (nullable), `city`, `country`, `device_os`, `referrer` (`app` | `web`), `scanned_at`
* `connections_waves`: `id`, `sender_id` (nullable), `receiver_profile_id`, `note`, `status` (`pending` | `accepted`), `created_at`
* `merch_orders`: `id`, `user_id`, `profile_id`, `product_type`, `shipping_address`, `phone`, `amount_lkr`, `payment_status`, `fulfillment_status`

---

## 5. Development Roadmap (4-Week MVP Plan)

* **Week 1 — Backend & Web Fallback:** Set up Supabase schema, Auth, Storage, and build the ultra-fast Next.js public profile page (`/u/[username]`) with `.vcf` contact download and Universal/App Link configuration.
* **Week 2 — Core Mobile App & Profile Builder:** Build Flutter onboarding, username claim, profile editor, social link manager, and Privacy Mode toggles (*Social* vs. *Work* vs. *Paused*).
* **Week 3 — QR Customizer & Export Studio:** Build custom QR styling (colors, shapes, center avatar, CTA frames) and the **Lock-Screen Wallpaper / Story Card / PNG / SVG** export engine.
* **Week 4 — Scanner, Analytics & Payments:** Add built-in QR scanner, scan history wallet, "Send Wave" notifications, scan analytics dashboard, and PayHere/RevenueCat Pro upgrade flow.