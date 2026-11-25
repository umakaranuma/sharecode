import 'package:flutter/material.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'merch.dart';
import 'privacy.dart';
import 'pro.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    Widget group(String t, List<Widget> kids) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t),
        Box(
          pad: 12,
          child: Column(
            children: [
              for (var i = 0; i < kids.length; i++) ...[
                if (i > 0) const Divider1(),
                kids[i],
              ],
            ],
          ),
        ),
      ],
    );
    Widget sw(
      IconData i,
      String t,
      String sub,
      bool v,
      ValueChanged<bool> f, {
      Color? col,
    }) => RowTile(
      icon: i,
      title: t,
      sub: sub,
      color: col,
      trailing: Switch(value: v, onChanged: f),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Glow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
          children: [
            Box(
              onTap: () => pushPage(context, const ProPage()),
              gradient: s.pro ? VC.proGrad : VC.brand,
              child: Row(
                children: [
                  Avatar(
                    name: s.me.name,
                    seed: s.me.avatarSeed,
                    emoji: s.me.emoji,
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.me.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          s.authEmail.isEmpty ? 'Signed in' : s.authEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.pro
                              ? 'Pro • ${s.proPlan}'
                              : 'Free plan • Tap to upgrade',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
            group('Appearance', [
              sw(
                s.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                'Dark mode',
                s.dark ? 'Easy on the eyes' : 'Bright & airy',
                s.dark,
                (_) => s.toggleTheme(),
                col: VC.violet,
              ),
              RowTile(
                icon: Icons.translate_rounded,
                title: 'Language',
                sub: s.language,
                color: VC.blue,
                onTap: () => _lang(context),
              ),
            ]),
            group('Notifications', [
              sw(
                Icons.qr_code_scanner_rounded,
                'Scan alerts',
                '“Someone in Jaffna just scanned your QR”',
                s.nScans,
                (v) {
                  s.nScans = v;
                  s.touch();
                },
                col: VC.violet,
              ),
              sw(
                Icons.waving_hand_rounded,
                'Waves',
                'New and mutual waves',
                s.nWaves,
                (v) {
                  s.nWaves = v;
                  s.touch();
                },
                col: VC.orange,
              ),
              sw(
                Icons.emoji_events_rounded,
                'Milestones',
                '“Your QR hit 100 scans!”',
                s.nMilestones,
                (v) {
                  s.nMilestones = v;
                  s.touch();
                },
                col: VC.gold,
              ),
              sw(
                Icons.campaign_rounded,
                'Offers & news',
                'Product updates and promos',
                s.nMarketing,
                (v) {
                  s.nMarketing = v;
                  s.touch();
                },
                col: VC.pink,
              ),
            ]),
            group('Account & safety', [
              RowTile(
                icon: Icons.shield_moon_rounded,
                title: 'Privacy & modes',
                color: VC.blue,
                onTap: () => pushPage(context, const PrivacyPage()),
              ),
              RowTile(
                icon: Icons.local_shipping_rounded,
                title: 'My orders',
                sub: '${s.orders.length} order(s)',
                color: VC.orange,
                onTap: () => pushPage(context, const OrdersPage()),
              ),
              RowTile(
                icon: Icons.download_for_offline_rounded,
                title: 'Download my data',
                color: VC.green,
                onTap: () => toast(
                  context,
                  'We\'ll email you a copy within 24 hours',
                  icon: Icons.mail_rounded,
                ),
              ),
            ]),
            group('Help', [
              RowTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & FAQ',
                color: c.accent,
                onTap: () => _faq(context),
              ),
              RowTile(
                icon: Icons.support_agent_rounded,
                title: 'Contact support',
                sub: 'support@vibedrop.lk',
                color: VC.green,
                onTap: () => copyText(
                  context,
                  'support@vibedrop.lk',
                  'Support email copied',
                ),
              ),
              RowTile(
                icon: Icons.description_outlined,
                title: 'Terms & Privacy Policy',
                color: c.sub,
                onTap: () => toast(
                  context,
                  'Opens vibedrop.lk/legal',
                  icon: Icons.open_in_new_rounded,
                  color: VC.gold,
                ),
              ),
            ]),
            const SizedBox(height: 18),
            SoftBtn(
              'Log out',
              icon: Icons.logout_rounded,
              color: VC.red,
              onTap: () async {
                final store = context.store;
                final nav = Navigator.of(context);
                if (await confirm(
                  context,
                  'Log out?',
                  'You can sign back in any time.',
                  ok: 'Log out',
                  danger: true,
                )) {
                  nav.popUntil((r) => r.isFirst);
                  store.signOut();
                }
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () async {
                  final store = context.store;
                  final nav = Navigator.of(context);
                  if (await confirm(
                    context,
                    'Delete account?',
                    'This permanently removes your profile, links and QR. This can\'t be undone.',
                    ok: 'Delete',
                    danger: true,
                  )) {
                    nav.popUntil((r) => r.isFirst);
                    store.signOut();
                  }
                },
                child: const Text(
                  'Delete account',
                  style: TextStyle(color: VC.red, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Center(
              child: Text(
                'VibeDrop v0.2.0 • UI preview build',
                style: TextStyle(color: c.sub, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _lang(BuildContext context) {
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
              'Language',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: s.language,
              onChanged: (v) {
                s.language = v!;
                s.touch();
                Navigator.pop(ctx);
              },
              child: Column(
                children: [
                  for (final l in [
                    'English',
                    'தமிழ் (Tamil)',
                    'සිංහල (Sinhala)',
                  ])
                    RadioListTile<String>(
                      value: l,
                      activeColor: VC.violet,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _faq(BuildContext context) {
    const faqs = [
      (
        'Do scanners need the app?',
        'No. If they don\'t have it, your profile opens in a fast web page with a 1-tap contact download.',
      ),
      (
        'Do I need to reprint my QR if I change links?',
        'Never. The QR points to your permanent link, so edits go live instantly.',
      ),
      (
        'What is Ghost mode?',
        'It pauses your profile. Scanners see “This profile is currently private”.',
      ),
      (
        'How do waves work?',
        'Wave at someone you scanned. If they wave back, you both unlock in-app chat.',
      ),
    ];
    sheet(
      context,
      (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & FAQ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final f in faqs)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  f.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      f.$2,
                      style: TextStyle(color: ctx.c.sub, height: 1.45),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
