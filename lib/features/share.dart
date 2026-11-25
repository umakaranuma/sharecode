import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/models.dart';
import '../core/qr_view.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'export.dart';

void shareQrSheet(BuildContext context) {
  final s = context.store;
  sheet(context, (ctx) {
    final c = ctx.c;
    Widget target(Object i, String label, Color col, VoidCallback f) =>
        Expanded(
          child: Tap(
            onTap: f,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: anyIcon(i, color: col, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
    void done(String msg) {
      Navigator.pop(ctx);
      toast(context, msg, icon: Icons.ios_share_rounded);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Share your QR',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          const MyQr(size: 190),
          const SizedBox(height: 28),
          Box(
            pad: 14,
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: VC.violet),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'https://${s.me.url}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      copyText(ctx, 'https://${s.me.url}', 'Link copied'),
                  child: Text(
                    'Copy',
                    style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              target(
                FontAwesomeIcons.whatsapp,
                'WhatsApp',
                const Color(0xFF25D366),
                () => done('Opening WhatsApp share…'),
              ),
              target(
                FontAwesomeIcons.instagram,
                'IG Story',
                const Color(0xFFE1306C),
                () {
                  Navigator.pop(ctx);
                  pushPage(context, const ExportPage(focus: 1));
                },
              ),
              target(
                Icons.sms_rounded,
                'Messages',
                const Color(0xFF3B82F6),
                () => done('Opening Messages…'),
              ),
              target(
                Icons.more_horiz_rounded,
                'More',
                c.sub,
                () => done('System share sheet opens on device'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SoftBtn(
                  'Full screen',
                  icon: Icons.fullscreen_rounded,
                  height: 50,
                  onTap: () {
                    Navigator.pop(ctx);
                    pushPage(context, const FullQrPage());
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SoftBtn(
                  'Export',
                  icon: Icons.download_rounded,
                  height: 50,
                  onTap: () {
                    Navigator.pop(ctx);
                    pushPage(context, const ExportPage());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}

/// Bright, full-screen QR for easy scanning in person.
class FullQrPage extends StatelessWidget {
  const FullQrPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final pal = qrPalettes[s.qr.paletteIndex];
    final w = context.screen.width;
    return Scaffold(
      backgroundColor: pal.neon ? pal.bg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: pal.neon ? Colors.white : Colors.black87,
                  size: 28,
                ),
              ),
            ),
            const Spacer(),
            Hero(
              tag: 'qr',
              child: MyQr(size: (w - 90).clamp(200, 380)),
            ),
            const SizedBox(height: 34),
            Text(
              s.me.name,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: pal.neon ? Colors.white : const Color(0xFF14112E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Point a camera at this code',
              style: TextStyle(
                color: pal.neon ? Colors.white70 : Colors.black54,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GradBtn(
                      'Share',
                      icon: Icons.ios_share_rounded,
                      height: 52,
                      onTap: () => shareQrSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftBtn(
                      'Copy link',
                      icon: Icons.copy_rounded,
                      height: 52,
                      color: VC.violet,
                      onTap: () => copyText(context, 'https://${s.me.url}'),
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
}
