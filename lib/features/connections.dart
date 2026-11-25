import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'analytics.dart';
import 'chat.dart';
import 'home.dart';
import 'notifications.dart';
import 'pro.dart';
import 'profile_view.dart';
import 'wallet.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});
  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final incoming = s.waves
        .where((w) => w.status == WaveStatus.incoming)
        .length;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Connections',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
              ),
              IconCircle(
                Icons.notifications_none_rounded,
                dot: s.unreadCount > 0,
                onTap: () => pushPage(context, const NotificationsPage()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Segment(
            items: [
              'Activity',
              incoming > 0 ? 'Waves ($incoming)' : 'Waves',
              'Scans',
            ],
            index: tab,
            onChanged: (i) => setState(() => tab = i),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(tab),
              child: [
                _activity(context),
                _waves(context),
                _scans(context),
              ][tab],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activity(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final mutual = s.waves.where((w) => w.status == WaveStatus.mutual).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Recent scans',
          sub: 'People who scanned you',
          action: 'See all',
          onAction: () => setState(() => tab = 2),
        ),
        Box(
          pad: 6,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const Divider1(),
                _ScanTile(s.scans[i]),
              ],
            ],
          ),
        ),
        SectionTitle(
          'Mutual waves',
          action: 'See all',
          onAction: () => setState(() => tab = 1),
        ),
        if (mutual.isEmpty)
          Box(
            child: Text(
              'No mutual waves yet. Send a wave from someone\'s profile!',
              style: TextStyle(color: c.sub),
            ),
          )
        else
          Box(
            pad: 6,
            child: Column(
              children: [
                for (var i = 0; i < mutual.length; i++) ...[
                  if (i > 0) const Divider1(),
                  _WaveTile(mutual[i]),
                ],
              ],
            ),
          ),
        const SectionTitle('Scanner access'),
        Box(
          onTap: () => s.pro
              ? pushPage(context, const AnalyticsPage())
              : pushPage(context, const ProPage()),
          child: Row(
            children: [
              RoundIconBg(Icons.bar_chart_rounded, c.accent, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        const Text(
                          'Who viewed your profile?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (!s.pro) const ProBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'See total scans, locations, devices and more.',
                      style: TextStyle(color: c.sub, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _waves(BuildContext context) {
    final s = context.store;
    final c = context.c;
    List<Wave> by(WaveStatus st) =>
        s.waves.where((w) => w.status == st).toList();
    final inc = by(WaveStatus.incoming),
        mut = by(WaveStatus.mutual),
        sent = by(WaveStatus.sent);
    Widget group(String t, List<Wave> l, String empty) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t),
        l.isEmpty
            ? Box(
                child: Text(empty, style: TextStyle(color: c.sub)),
              )
            : Box(
                pad: 6,
                child: Column(
                  children: [
                    for (var i = 0; i < l.length; i++) ...[
                      if (i > 0) const Divider1(),
                      _WaveTile(l[i]),
                    ],
                  ],
                ),
              ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group('Waiting for you', inc, 'No new waves'),
        group('Mutual waves 💜', mut, 'Wave back to start chatting'),
        group('Sent by you', sent, 'You haven\'t waved at anyone yet'),
      ],
    );
  }

  Widget _scans(BuildContext context) {
    final s = context.store;
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Box(
          onTap: () => pushPage(context, const WalletPage()),
          gradient: LinearGradient(
            colors: [
              VC.violet.withValues(alpha: .9),
              VC.fuchsia.withValues(alpha: .85),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${s.wallet.length} cards you\'ve scanned',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
        SectionTitle(
          'Scanned your QR',
          sub: '${fmt(s.totalScans)} lifetime scans',
        ),
        Box(
          pad: 6,
          child: Column(
            children: [
              for (var i = 0; i < s.scans.length; i++) ...[
                if (i > 0) const Divider1(),
                _ScanTile(s.scans[i]),
              ],
            ],
          ),
        ),
        if (!s.pro)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SoftBtn(
              'Unlock full scan history',
              icon: Icons.workspace_premium_rounded,
              color: VC.orange,
              onTap: () => pushPage(context, const ProPage()),
            ),
          ),
        SizedBox(
          height: 4,
          child: Text('', style: TextStyle(color: c.sub)),
        ),
      ],
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile(this.e);
  final ScanEvent e;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.store;
    final guest = e.who.startsWith('Guest');
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Avatar(name: e.who, seed: e.seed, size: 46, online: e.fresh),
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded, color: c.sub),
            color: c.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (v) {
              if (v == 'wave') {
                final contact = s.directory[e.seed % s.directory.length];
                pushPage(
                  context,
                  PublicProfilePage(data: ViewData.fromContact(contact)),
                );
              } else if (v == 'block') {
                s.block(e.who);
                toast(
                  context,
                  'Blocked ${e.who}',
                  icon: Icons.block_rounded,
                  color: VC.red,
                );
              }
            },
            itemBuilder: (_) => [
              if (!guest)
                const PopupMenuItem(value: 'wave', child: Text('View profile')),
              PopupMenuItem(
                value: 'block',
                child: Text(
                  'Block',
                  style: TextStyle(color: c.sub == Colors.red ? null : VC.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveTile extends StatelessWidget {
  const _WaveTile(this.w);
  final Wave w;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.store;
    Widget trailing;
    switch (w.status) {
      case WaveStatus.incoming:
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tap(
              onTap: () => s.dismissWave(w.id),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.card2,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 20, color: c.sub),
              ),
            ),
            const SizedBox(width: 8),
            Tap(
              onTap: () {
                s.acceptWave(w.id);
                toast(
                  context,
                  'Mutual wave with ${w.name}! 💜',
                  icon: Icons.favorite_rounded,
                  color: VC.pink,
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [VC.orange, VC.pink]),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👋', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ],
        );
      case WaveStatus.mutual:
        trailing = Tap(
          onTap: () => pushPage(
            context,
            ChatPage(handle: w.handle, name: w.name, seed: w.seed),
          ),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: VC.violet.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: VC.violet,
              size: 20,
            ),
          ),
        );
      case WaveStatus.sent:
        trailing = const Pill(
          'Pending',
          icon: Icons.schedule_rounded,
          color: VC.gold,
        );
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Avatar(
            name: w.name,
            seed: w.seed,
            size: 46,
            online: w.status == WaveStatus.mutual,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  w.status == WaveStatus.mutual
                      ? 'You both waved! • ${w.ago}'
                      : '“${w.note}” • ${w.ago}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.sub, fontSize: 12.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
