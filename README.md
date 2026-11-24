# VibeDrop mobile app

Flutter app based on the product requirements and UI reference in [`docs/`](docs/). The app includes a dashboard, public profile preview, profile and link editor, privacy modes, QR Studio, PNG/story/wallpaper exports, camera/gallery scanner, scan history, and connections view. [`web-fallback/`](web-fallback/) serves public profiles when the app is not installed.

## Run locally

```powershell
flutter pub get
flutter run
```

Without cloud settings, the app starts with an editable **sample profile** stored on the device. The QR uses the default placeholder host `https://yourapp.lk`; set a real `PROFILE_HOST` before sharing or printing it. Local sample mode does not publish a public profile.

## Connect Supabase

1. Create a Supabase project and apply [`supabase/migrations/202611240001_vibedrop.sql`](supabase/migrations/202611240001_vibedrop.sql).
2. Configure Email, Google, and Apple authentication providers as needed. Google and Apple OAuth need their native redirect configuration in Supabase and the platform projects.
3. Deploy `web-fallback/` on your public domain. Copy its `.env.example` to `.env.local` and provide the project URL and **server-only service role key** in the deployment environment. Never include this key in Flutter or client bundles.
4. Run the app with the project URL, **publishable/anon client key**, and your deployed public profile host:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY --dart-define=PROFILE_HOST=https://YOUR_DOMAIN
```

Never pass a Supabase service role key or payment secret to Flutter. The mobile client writes only the signed-in owner's profile, links, QR style, and avatar under Row Level Security. Scan/click events, subscriptions, orders, generated media, and public profile reads require trusted server endpoints. The migration intentionally does not allow direct client writes to those tables.

## Public profile host and app links

```powershell
cd web-fallback
npm install
npm run dev
```

The web server provides `/u/{handle}`, `/u/{handle}/vcard.vcf`, `/api/profile/{handle}`, `/api/waves`, tracked link redirects, and the two `.well-known` association files. It requires `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` server environment variables. For association files, also set `ANDROID_APP_ID`, `ANDROID_SHA256_FINGERPRINT`, `IOS_TEAM_ID`, and `IOS_BUNDLE_ID`. Use your production signing certificate fingerprint, not the debug certificate.

Before a release, replace `com.example.sharecode` in Android and iOS with app identifiers you control. Set `VIBEDROP_HOST=your.domain` in `android/gradle.properties` for Android's verified link intent filter. Replace `applinks:yourapp.lk` in `ios/Runner/Runner.entitlements` with the same domain, enable Associated Domains for the iOS App ID, and set `PROFILE_HOST` to `https://your.domain` in the Flutter build. Deploy the web server and verify the association files before testing links on real devices.

## Current integration boundaries

This repository includes source for the web fallback and native link handling; it does **not** deploy them or configure your domain, signing fingerprints, OAuth provider credentials, or payment gateway. Wallet passes, push notifications, server media generation, Pro entitlement verification, SVG/PDF, detailed analytics, mutual chat, and merch checkout still need backend services. Do not print or distribute QR codes until the public profile host is deployed and tested on real devices.

## Checks

```powershell
flutter analyze
flutter test
```
