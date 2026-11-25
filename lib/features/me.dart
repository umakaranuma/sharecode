import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'analytics.dart';
import 'edit_profile.dart';
import 'export.dart';
import 'home.dart';
import 'links.dart';
import 'merch.dart';
import 'privacy.dart';
import 'pro.dart';
import 'profile_view.dart';
import 'settings.dart';
import 'wallet.dart';

/// Profile tab: the user's own card + hub to every account feature.
class MePage extends StatelessWidget {
  const MePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final me = s.me;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 290,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 200,
                child: Scenic(seed: me.coverSeed),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 140,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, c.bg],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      _glass(Icons.palette_rounded, () => pickCover(context)),
                      const SizedBox(width: 10),
                      _glass(
                        Icons.settings_rounded,
                        () => pushPage(context, const SettingsPage()),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 146,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Avatar(
                    name: me.name,
                    seed: me.avatarSeed,
                    emoji: me.emoji,
                    size: 108,
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 222,
                child: Tap(
                  onTap: () => pushPage(context, const EditProfilePage()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: VC.brand,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: VC.violet.withValues(alpha: .4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Edit profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      me.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified_rounded,
                    color: VC.violet,
                    size: 22,
                  ),
                  if (s.pro) ...[const SizedBox(width: 8), const ProBadge()],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '@${me.username}',
                style: TextStyle(color: c.sub, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                me.bio,
                style: const TextStyle(fontSize: 15.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (me.city.isNotEmpty)
                    Pill(
                      '${me.city}, Sri Lanka',
                      icon: Icons.place_rounded,
                      color: c.sub,
                    ),
                  if (me.campus.isNotEmpty)
                    Pill(me.campus, icon: Icons.school_rounded, color: c.sub),
                  Pill(
                    '${modeName(s.mode)} mode',
                    icon: modeIcon(s.mode),
                    color: modeColor(s.mode),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _num('${s.me.links.length}', 'Links')),
                  Expanded(child: _num(fmt(s.totalScans), 'Scans')),
                  Expanded(
                    child: _num(
                      '${s.waves.where((w) => w.status == WaveStatus.mutual).length}',
                      'Mutuals',
                    ),
                  ),
                  Expanded(child: _num('${s.wallet.length}', 'Wallet')),
                ],
              ),
              SectionTitle(
                'My links',
                sub: 'Tap to edit • manage order in Edit profile',
                action: '+ Add',
                onAction: () => editLinkSheet(context),
              ),
              for (final l in s.me.links)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Box(
                    pad: 12,
                    onTap: () => editLinkSheet(context, link: l),
                    child: Row(
                      children: [
                        PlatformBadge(l.meta, size: 46),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.meta.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                l.display,
                                style: TextStyle(color: c.sub, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${l.clicks}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'clicks',
                              style: TextStyle(color: c.sub, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SectionTitle('Account'),
              Box(
                pad: 8,
                child: Column(
                  children: [
                    _tile(
                      context,
                      Icons.visibility_rounded,
                      'Preview public profile',
                      'See what scanners see',
                      VC.fuchsia,
                      () => pushPage(
                        context,
                        PublicProfilePage(
                          data: ViewData.fromMe(s),
                          preview: true,
                        ),
                      ),
                    ),
                    const Divider1(),
                    _tile(
                      context,
                      Icons.shield_moon_rounded,
                      'Privacy & modes',
                      'Ghost mode, locks, burner links',
                      VC.blue,
                      () => pushPage(context, const PrivacyPage()),
                    ),
                    const Divider1(),
                    _tile(
                      context,
                      Icons.bar_chart_rounded,
                      'Analytics',
                      'Scans, clicks & locations',
                      VC.violet,
                      () => pushPage(context, const AnalyticsPage()),
                    ),
                    const Divider1(),
                    _tile(
                      context,
                      Icons.badge_rounded,
                      'My wallet',
                      '${s.wallet.length} scanned cards',
                      VC.green,
                      () => pushPage(context, const WalletPage()),
                    ),
                    const Divider1(),
                    _tile(
                      context,
                      Icons.download_rounded,
                      'Export & download',
                      'Wallpaper, story card, PNG, SVG',
                      VC.pink,
                      () => pushPage(context, const ExportPage()),
                    ),
                    const Divider1(),
                    _tile(
                      context,
                      Icons.shopping_bag_rounded,
                      'Order physical QR',
                      s.orders.isEmpty
                          ? 'Stickers, keychains, tap cards'
                          : '${s.orders.length} order(s)',
                      VC.orange,
                      () => pushPage(context, const MerchPage()),
                    ),
                    const Divider1(),
                    _tile(
                      context,
                      Icons.workspace_premium_rounded,
                      s.pro ? 'Manage Pro' : 'Upgrade to Pro',
                      s.pro ? 'Active • ${s.proPlan}' : 'Unlock everything',
                      VC.gold,
                      () => pushPage(context, const ProPage()),
                    ),
                    const Divider1(),
                    _tile(
                      context,
                      Icons.settings_rounded,
                      'Settings',
                      'Theme, notifications, help',
                      c.sub,
                      () => pushPage(context, const SettingsPage()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    IconData i,
    String t,
    String sub,
    Color col,
    VoidCallback f,
  ) => RowTile(icon: i, title: t, sub: sub, color: col, onTap: f);

  Widget _glass(IconData i, VoidCallback f) => Tap(
    onTap: f,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        shape: BoxShape.circle,
      ),
      child: Icon(i, color: Colors.white, size: 21),
    ),
  );

  Widget _num(String n, String l) => Builder(
    builder: (context) => Column(
      children: [
        Text(
          n,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        Text(l, style: TextStyle(color: context.c.sub, fontSize: 12.5)),
      ],
    ),
  );
}

void pickCover(BuildContext context) {
  final s = context.store;
  sheet(
    context,
    (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cover banner',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 6; i++)
                Tap(
                  onTap: () {
                    s.me.coverSeed = i;
                    s.touch();
                    Navigator.pop(ctx);
                    toast(context, 'Cover updated');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: s.me.coverSeed == i
                            ? VC.violet
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Scenic(seed: i, radius: 15),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
