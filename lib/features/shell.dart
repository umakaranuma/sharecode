import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'connections.dart';
import 'home.dart';
import 'me.dart';
import 'scanner.dart';
import 'studio.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    const pages = [HomePage(), StudioPage(), ConnectionsPage(), MePage()];
    final waveBadge = s.waves
        .where((w) => w.status == WaveStatus.incoming)
        .length;
    Widget item(
      int i,
      IconData icon,
      IconData active,
      String label, {
      int badge = 0,
    }) {
      final on = s.tab == i;
      return Expanded(
        child: Tap(
          onTap: () => s.setTab(i),
          scale: .9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: on
                          ? VC.violet.withValues(alpha: .18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      on ? active : icon,
                      size: 24,
                      color: on ? c.accent : c.sub,
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: 6,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: VC.red,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: c.bg, width: 2),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w600,
                  color: on ? c.accent : c.sub,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: Glow(
        child: IndexedStack(index: s.tab, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.dark ? const Color(0xFF0A0F1E) : const Color(0xFFFFFFFF),
          border: Border(top: BorderSide(color: c.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .3 : .04),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                item(1, Icons.layers_outlined, Icons.layers_rounded, 'Studio'),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -16),
                    child: Tap(
                      onTap: () => pushPage(context, const ScannerPage()),
                      scale: .9,
                      child: Container(
                        height: 58,
                        width: 58,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          gradient: VC.brand,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.bg, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: VC.violet.withValues(alpha: .3),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                item(
                  2,
                  Icons.people_outline_rounded,
                  Icons.people_alt_rounded,
                  'Connections',
                  badge: waveBadge,
                ),
                item(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
