# VibeDrop — mobile app (UI build)

Flutter UI for the VibeDrop digital-identity app, built from [`docs/`](docs/). This build is **UI-only**: there is no Supabase, auth provider, payment gateway, camera plugin or any network call. Every screen and action works against in-memory mock data (`lib/core/store.dart`), so the whole product flow can be explored and demoed before any backend is wired in.

## Run

```powershell
flutter pub get
flutter run                                   # any device
flutter run -d chrome                         # web preview
flutter run --dart-define=SKIP_ONBOARDING=true   # jump straight into the app
```

Demo helpers: OTP code is `123456`, promo code `VIBE20`, PIN-locked profile `@dilan_p` (PIN `1234`), riddle-locked `@anjali.f` (answer `cargills`), ghost profile `@ghost_one`. Use **Scan → Enter code** to open them. After sign-in you land on Home; tap **Add details & generate QR** there to create your QR.

## Theme

Dark-first with a violet → fuchsia brand gradient and warm orange highlights (inspired by the dark reference you attached), plus a full light theme. Toggle in **Profile → Settings → Dark mode**. All colours live in `lib/core/theme.dart`.

## What's implemented

| Area | Screens / behaviour |
| --- | --- |
| Onboarding | Splash, 3-slide intro, Google / Apple / phone + OTP / email sign-in, sign-up with password strength + verify screen, forgot password, 3-step wizard (live username check, avatar picker, bio, first links), celebration screen |
| Home | QR hero card, mode switcher, stats, Pro banner, quick actions, recent scans, notifications, burner-link banner |
| QR Studio | Custom QR renderer (5 dot styles, 3 eye styles, 8 palettes incl. neon, centre avatar/logo, 5 CTA frames, EN/தமிழ்/සිංහල text), Pro gating |
| Export | Lock-screen wallpaper (safe zone), Story card, hi-res image, transparent PNG, SVG/PDF (Pro), Wallet pass, simulated save |
| Privacy | Social / Work / Custom modes, Ghost mode, PIN or secret-question lock, 24 h burner link, blocked users, "test as a scanner" |
| Scanner | Simulated viewfinder, torch, gallery import, manual handle entry, auto-save to wallet |
| Public profile | App/Web view toggle, links open-sheet, vCard save, Wave sheet, report / block, locked + ghost states |
| Connections | Activity, Waves (accept / dismiss / pending / mutual), Scans, My Wallet, in-app chat with auto-replies |
| Profile | Edit profile (gallery, drag-to-reorder links, vCard fields), link editor, cover picker |
| Analytics | Totals free; Pro graphs, per-link clicks, cities, devices |
| Monetisation | Pro paywall, checkout (promo code), merch store, order flow + tracking |
| Settings | Theme, language, notification toggles, FAQ, log out, delete account |

## Backend

Nothing is integrated on purpose. The previous Supabase schema (`supabase/`) and Next.js fallback (`web-fallback/`) are untouched but unused by this build. When you're ready, replace the methods in `AppStore` with real calls — screens only talk to the store.

## Checks

```powershell
flutter analyze
flutter test
```

`test/screens_test.dart` renders every screen in light and dark mode and fails on any exception.
