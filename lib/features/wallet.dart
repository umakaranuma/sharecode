import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'profile_view.dart';

/// "My Wallet": everyone the user has scanned, searchable.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final list = s.wallet
        .where(
          (x) =>
              x.name.toLowerCase().contains(q.toLowerCase()) ||
              x.handle.contains(q.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: Glow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                hintText: 'Search scanned connections',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${s.wallet.length} saved connections • never lose a contact',
              style: TextStyle(color: c.sub, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.badge_outlined, size: 64, color: c.sub),
                    const SizedBox(height: 12),
                    const Text(
                      'Nothing here yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Scan a QR to save someone automatically.',
                      style: TextStyle(color: c.sub),
                    ),
                  ],
                ),
              ),
            for (final x in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(x.handle),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: VC.red.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_rounded, color: VC.red),
                  ),
                  onDismissed: (_) {
                    s.removeFromWallet(x.handle);
                    toast(
                      context,
                      '${x.name} removed',
                      icon: Icons.delete_rounded,
                      color: VC.red,
                    );
                  },
                  child: Box(
                    pad: 14,
                    onTap: () => pushPage(
                      context,
                      PublicProfilePage(data: ViewData.fromContact(x)),
                    ),
                    child: Row(
                      children: [
                        Avatar(
                          name: x.name,
                          seed: x.seed,
                          emoji: x.emoji,
                          size: 54,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                x.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '@${x.handle} • ${x.when}',
                                style: TextStyle(color: c.sub, fontSize: 12.5),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final l in x.links.take(4))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: PlatformBadge(
                                        platformOf(l[0]),
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: c.sub),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
