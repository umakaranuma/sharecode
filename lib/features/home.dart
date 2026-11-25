import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/qr_view.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'analytics.dart';
import 'export.dart';
import 'merch.dart';
import 'notifications.dart';
import 'privacy.dart';
import 'pro.dart';
import 'profile_view.dart';
import 'share.dart';
import 'wallet.dart';
import 'wizard.dart';

String fmt(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]},',
);

String modeName(ProfileMode m) => switch (m) {
  ProfileMode.social => 'Chill / Social',
  ProfileMode.work => 'Work / Campus',
  ProfileMode.custom => 'Custom',
};

IconData modeIcon(ProfileMode m) => switch (m) {
  ProfileMode.social => Icons.celebration_rounded,
  ProfileMode.work => Icons.work_rounded,
  ProfileMode.custom => Icons.tune_rounded,
};

Color modeColor(ProfileMode m) => switch (m) {
  ProfileMode.social => VC.pink,
  ProfileMode.work => VC.blue,
  ProfileMode.custom => VC.gold,
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? tick;
  @override
  void initState() {
    super.initState();
    tick = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final me = s.me;
    final first = me.name.split(' ').first;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Row(
            children: [
              const VLogo(size: 32),
              const Spacer(),
              IconCircle(
                Icons.notifications_none_rounded,
                dot: s.unreadCount > 0,
                onTap: () => pushPage(context, const NotificationsPage()),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Reveal(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey $first! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.ghost
                            ? 'Ghost mode is on — you\'re hidden.'
                            : 'Your digital identity is ready.',
                        style: TextStyle(color: c.sub, fontSize: 14.5),
                      ),
                    ],
                  ),
                ),
                Tap(
                  onTap: () => s.setTab(3),
                  child: Avatar(
                    name: me.name,
                    seed: me.avatarSeed,
                    emoji: me.emoji,
                    size: 54,
                    ring: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!s.qrReady)
            Reveal(i: 1, child: const _SetupCard())
          else ...[
            // hero QR card
            Reveal(
              i: 1,
              child: Tap(
                onTap: () => pushPage(context, const FullQrPage()),
                scale: .985,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B1D14), Color(0xFF15100D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: VibeQr(
                              data: 'https://${me.url}',
                              cfg: s.qr,
                              me: me,
                              size: 128,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  me.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${me.username}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Tap(
                                  onTap: () => copyText(
                                    context,
                                    'https://${me.url}',
                                    'Profile link copied',
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          me.url,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: .8,
                                            ),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 12,
                                        color: Colors.white.withValues(
                                          alpha: .8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Reveal(
              i: 2,
              child: Row(
                children: [
                  Expanded(
                    child: GradBtn(
                      'Share QR',
                      icon: Icons.ios_share_rounded,
                      height: 52,
                      onTap: () => shareQrSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftBtn(
                      'Customize',
                      icon: Icons.brush_rounded,
                      height: 52,
                      onTap: () => s.setTab(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (s.tempLinkUntil != null) ...[
            const SizedBox(height: 14),
            _TempBanner(),
          ],
          const SizedBox(height: 22),
          Text(
            'Active mode',
            style: TextStyle(
              color: c.sub,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Reveal(
            i: 3,
            child: Box(
              pad: 14,
              onTap: () => _modeSheet(context),
              child: Row(
                children: [
                  RoundIconBg(
                    s.ghost ? Icons.visibility_off_rounded : modeIcon(s.mode),
                    s.ghost ? c.sub : modeColor(s.mode),
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.ghost ? 'Ghost Mode' : modeName(s.mode),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          s.ghost
                              ? 'Profile paused for scanners'
                              : '${s.visibleLinks.length} links visible to scanners',
                          style: TextStyle(color: c.sub, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.swap_horiz_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            i: 4,
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    Icons.qr_code_2_rounded,
                    fmt(s.totalScans),
                    'Total Scans',
                    '+12%',
                    onTap: () => pushPage(context, const AnalyticsPage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    Icons.link_rounded,
                    fmt(s.totalClicks),
                    'Link Clicks',
                    '+18%',
                    onTap: () => pushPage(context, const AnalyticsPage()),
                  ),
                ),
              ],
            ),
          ),
          if (!s.pro) ...[
            const SizedBox(height: 14),
            Reveal(
              i: 5,
              child: Tap(
                onTap: () => pushPage(context, const ProPage()),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        VC.orange.withValues(alpha: .22),
                        VC.violet.withValues(alpha: .22),
                      ],
                    ),
                    border: Border.all(color: VC.orange.withValues(alpha: .2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: VC.proGrad,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upgrade to Pro',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Custom modes, analytics, PIN lock & more.',
                              style: TextStyle(color: c.sub, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SectionTitle('Quick actions'),
          SizedBox(
            height: 116,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _Quick(
                  Icons.wallpaper_rounded,
                  'Lock-screen\nwallpaper',
                  VC.violet,
                  () => pushPage(context, const ExportPage(focus: 0)),
                ),
                _Quick(
                  Icons.auto_stories_rounded,
                  'Story\ncard',
                  VC.pink,
                  () => pushPage(context, const ExportPage(focus: 1)),
                ),
                _Quick(
                  Icons.shield_moon_rounded,
                  'Privacy\n& modes',
                  VC.blue,
                  () => pushPage(context, const PrivacyPage()),
                ),
                _Quick(
                  Icons.shopping_bag_rounded,
                  'Print my\nQR',
                  VC.orange,
                  () => pushPage(context, const MerchPage()),
                ),
                _Quick(
                  Icons.badge_rounded,
                  'My\nwallet',
                  VC.green,
                  () => pushPage(context, const WalletPage()),
                ),
                _Quick(
                  Icons.visibility_rounded,
                  'Preview\nprofile',
                  VC.fuchsia,
                  () => pushPage(
                    context,
                    PublicProfilePage(data: ViewData.fromMe(s), preview: true),
                  ),
                ),
              ],
            ),
          ),
          SectionTitle(
            'Recent scans',
            sub: 'People who scanned you',
            action: 'See all',
            onAction: () => s.setTab(2),
          ),
          Box(
            pad: 6,
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const Divider1(),
                  _ScanRow(s.scans[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _modeSheet(BuildContext context) {
    sheet(context, (ctx) => const ModePickerSheet());
  }
}

class ModePickerSheet extends StatelessWidget {
  const ModePickerSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Switch mode',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            'Changes instantly. Your QR stays the same.',
            style: TextStyle(color: c.sub),
          ),
          const SizedBox(height: 14),
          for (final m in ProfileMode.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Box(
                pad: 14,
                color: s.mode == m && !s.ghost
                    ? VC.violet.withValues(alpha: .14)
                    : null,
                onTap: () {
                  s.setGhost(false);
                  s.setMode(m);
                  Navigator.pop(context);
                  toast(
                    context,
                    '${modeName(m)} mode active',
                    icon: modeIcon(m),
                    color: modeColor(m),
                  );
                },
                child: Row(
                  children: [
                    RoundIconBg(modeIcon(m), modeColor(m)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            modeName(m),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (s.mode == m && !s.ghost)
                      const Icon(Icons.check_circle_rounded, color: VC.violet),
                  ],
                ),
              ),
            ),
          Box(
            pad: 14,
            color: s.ghost ? VC.violet.withValues(alpha: .14) : null,
            onTap: () {
              s.setGhost(!s.ghost);
              Navigator.pop(context);
              toast(
                context,
                s.ghost ? 'Ghost mode on — profile paused' : 'Ghost mode off',
                icon: Icons.visibility_off_rounded,
              );
            },
            child: Row(
              children: [
                RoundIconBg(Icons.visibility_off_rounded, c.sub),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Ghost Mode (pause)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                if (s.ghost)
                  const Icon(Icons.check_circle_rounded, color: VC.violet),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TempBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final left = s.tempLinkUntil!.difference(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VC.orange.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VC.orange.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: VC.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Burner link active • ${left.inHours}h ${left.inMinutes % 60}m left',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: s.endTempLink,
            child: const Text(
              'End',
              style: TextStyle(color: VC.orange, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
    this.icon,
    this.value,
    this.label,
    this.delta, {
    required this.onTap,
  });
  final IconData icon;
  final String value, label, delta;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Box(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoundIconBg(icon, c.accent, size: 38, radius: 12),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: c.sub, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 14, color: VC.green),
              Text(
                delta,
                style: const TextStyle(
                  color: VC.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Tap(
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundIconBg(icon, color, size: 38, radius: 12),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String agoText(Duration d) {
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

class _ScanRow extends StatelessWidget {
  const _ScanRow(this.e);
  final ScanEvent e;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Avatar(name: e.who, seed: e.seed, size: 44, online: e.fresh),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.who,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Scanned your QR • ${agoText(e.when)}',
                  style: TextStyle(color: c.sub, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Pill(e.city, icon: Icons.place_rounded, color: c.sub),
        ],
      ),
    );
  }
}

/// Shown to new users until they set up their profile and generate a QR.
class _SetupCard extends StatelessWidget {
  const _SetupCard();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.store;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: VC.brand,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: VC.violet.withValues(alpha: .2),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 76,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Create your QR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your username, details and social links — your QR is generated instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Tap(
            onTap: () => pushPage(context, const WizardPage()),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: c.dark ? VC.violet : VC.violet,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add details & generate QR',
                    style: TextStyle(
                      color: VC.violet,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (s.me.username.isNotEmpty) const SizedBox(height: 0),
        ],
      ),
    );
  }
}
