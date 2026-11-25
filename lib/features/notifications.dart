import 'package:flutter/material.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: s.unreadCount == 0 ? null : s.markAllRead,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: s.unreadCount == 0 ? c.sub : c.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Glow(
        child: s.notifs.isEmpty
            ? Center(
                child: Text(
                  'You\'re all caught up 🎉',
                  style: TextStyle(color: c.sub),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                itemCount: s.notifs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final n = s.notifs[i];
                  return Dismissible(
                    key: ObjectKey(n),
                    background: Container(
                      decoration: BoxDecoration(
                        color: VC.red.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete_rounded, color: VC.red),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      s.notifs.remove(n);
                      s.touch();
                    },
                    child: Box(
                      pad: 14,
                      color: n.unread
                          ? VC.violet.withValues(alpha: c.dark ? .12 : .06)
                          : null,
                      onTap: () {
                        n.unread = false;
                        s.touch();
                        if (n.kind == 'wave') {
                          Navigator.pop(context);
                          s.setTab(2);
                        }
                      },
                      child: Row(
                        children: [
                          RoundIconBg(n.icon, n.color),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  n.body,
                                  style: TextStyle(
                                    color: c.sub,
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Text(
                                n.ago,
                                style: TextStyle(color: c.sub, fontSize: 12),
                              ),
                              if (n.unread)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: VC.violet,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
