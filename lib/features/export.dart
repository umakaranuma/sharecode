import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/qr_view.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'merch.dart';
import 'pro.dart';

/// Simulated save: shows progress then a success state.
Future<void> fakeSave(
  BuildContext context,
  String what, {
  String where = 'Camera Roll',
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Box(
        pad: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                color: VC.violet,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rendering $what…',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await Future.delayed(const Duration(milliseconds: 1100));
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  HapticFeedback.mediumImpact();
  toast(context, '$what saved to $where', icon: Icons.download_done_rounded);
}

class ExportPage extends StatefulWidget {
  const ExportPage({super.key, this.focus = 0});
  final int focus;
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  late final ctrl = PageController(
    viewportFraction: .62,
    initialPage: widget.focus,
  );
  late int page = widget.focus;
  int bg = 2;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final titles = [
      'QR Lock Screen Wallpaper',
      'Instagram Story Card',
      'High-Res Image',
    ];
    final subs = [
      'A stylish wallpaper with your QR in the safe zone, below the clock.',
      'Ready-to-post 1080 × 1920 card for Stories & Highlights.',
      '2048 × 2048 crisp image for WhatsApp or gallery.',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Download')),
      body: Glow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 50),
          children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                controller: ctrl,
                itemCount: 3,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (_, i) => AnimatedBuilder(
                  animation: ctrl,
                  builder: (_, child) {
                    final d =
                        ((ctrl.hasClients && ctrl.position.haveDimensions
                                    ? ctrl.page!
                                    : widget.focus.toDouble()) -
                                i)
                            .abs()
                            .clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 1 - d * .12,
                      child: Opacity(opacity: 1 - d * .45, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: [
                      WallpaperPreview(bg: bg),
                      StoryPreview(),
                      const _ImagePreview(),
                    ][i],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: i == page ? VC.brand : null,
                      color: i == page ? null : c.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[page],
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subs[page],
                          style: TextStyle(
                            color: c.sub,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GradBtn(
                    'Generate',
                    icon: Icons.auto_awesome_rounded,
                    height: 46,
                    expand: false,
                    onTap: () => fakeSave(
                      context,
                      ['Wallpaper', 'Story card', 'Image'][page],
                    ),
                  ),
                ],
              ),
            ),
            if (page == 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_android_rounded,
                      size: 16,
                      color: VC.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Detected screen 1080 × 2400 • safe zone applied',
                      style: TextStyle(
                        color: c.sub,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => Tap(
                    onTap: () => setState(() => bg = i),
                    child: Container(
                      width: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: bg == i ? VC.violet : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Scenic(seed: i, radius: 11, palms: false),
                    ),
                  ),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: SectionTitle('Export options'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Box(
                pad: 6,
                child: Column(
                  children: [
                    _opt(
                      context,
                      FontAwesomeIcons.instagram,
                      const Color(0xFFE1306C),
                      'Instagram Story (9:16)',
                      'Share your QR on IG stories',
                      () => fakeSave(context, 'Story card'),
                    ),
                    const Divider1(),
                    _opt(
                      context,
                      Icons.image_rounded,
                      VC.blue,
                      'PNG (High Quality)',
                      '2048 × 2048 • best for general use',
                      () => fakeSave(context, 'PNG'),
                    ),
                    const Divider1(),
                    _opt(
                      context,
                      Icons.grid_on_rounded,
                      VC.green,
                      'Transparent PNG',
                      'No background (logo / print)',
                      () => _transparent(context),
                    ),
                    const Divider1(),
                    _opt(
                      context,
                      Icons.description_rounded,
                      VC.gold,
                      'SVG / PDF',
                      'Vector quality (for print & merch)',
                      () {
                        if (!s.pro) {
                          pushPage(
                            context,
                            const ProPage(
                              reason: 'Print-ready SVG / PDF vectors',
                            ),
                          );
                          return;
                        }
                        fakeSave(context, 'SVG + PDF', where: 'Files');
                      },
                      pro: true,
                    ),
                    const Divider1(),
                    _opt(
                      context,
                      Icons.account_balance_wallet_rounded,
                      VC.orange,
                      'Add to Wallet',
                      'Save your VibeDrop card to Apple / Google Wallet',
                      () => _wallet(context),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Tap(
                onTap: () => pushPage(context, const MerchPage()),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: VC.sunset,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Print My QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              'Stickers, keychains & NFC tap cards',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white),
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

  Widget _opt(
    BuildContext context,
    Object i,
    Color col,
    String t,
    String sub,
    VoidCallback f, {
    bool pro = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: RowTile(
      icon: i,
      color: col,
      title: t,
      sub: sub,
      onTap: f,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pro && !context.store.pro) const ProBadge(),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );

  void _transparent(BuildContext context) {
    sheet(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transparent PNG',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _Checker(ctx.c.dark)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: MyQr(size: 190, transparent: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradBtn(
              'Save PNG',
              icon: Icons.download_rounded,
              onTap: () {
                Navigator.pop(ctx);
                fakeSave(context, 'Transparent PNG');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _wallet(BuildContext context) {
    final s = context.store;
    sheet(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wallet pass',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: VC.brand,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: VC.violet.withValues(alpha: .2),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const VLogo(size: 26),
                      const Spacer(),
                      Text(
                        '@${s.me.username}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: MyQr(
                      size: 150,
                      cfg: QrConfig(frame: false, showAvatar: true),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.me.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _walletBtn(
                    ctx,
                    Icons.apple,
                    'Apple Wallet',
                    Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _walletBtn(
                    ctx,
                    Icons.account_balance_wallet_rounded,
                    'Google Wallet',
                    const Color(0xFF1A73E8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletBtn(BuildContext ctx, IconData i, String t, Color col) => Tap(
    onTap: () {
      Navigator.pop(ctx);
      toast(context, 'Pass added to $t', icon: Icons.check_circle_rounded);
    },
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: col,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            t,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Checker extends CustomPainter {
  _Checker(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size s) {
    final a = Paint()
      ..color = dark ? const Color(0xFF26233F) : const Color(0xFFE6E1F5);
    final b = Paint()..color = dark ? const Color(0xFF1B1930) : Colors.white;
    const t = 14.0;
    for (var y = 0; y * t < s.height; y++) {
      for (var x = 0; x * t < s.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * t, y * t, t, t),
          (x + y).isEven ? a : b,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Checker o) => o.dark != dark;
}

/// Phone mock with wallpaper + QR in the lower-middle safe zone.
class WallpaperPreview extends StatelessWidget {
  const WallpaperPreview({super.key, this.bg = 2});
  final int bg;
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    return LayoutBuilder(
      builder: (_, b) {
        final w = b.maxWidth;
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFF3A3658), width: 4),
            boxShadow: [
              BoxShadow(
                color: VC.violet.withValues(alpha: .35),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Scenic(seed: bg),
                Align(
                  alignment: const Alignment(0, -.78),
                  child: Container(
                    width: w * .3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mon, 24 Nov',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .9),
                          fontWeight: FontWeight.w600,
                          fontSize: w * .06,
                        ),
                      ),
                      Text(
                        '9:41',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: w * .3,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: const Alignment(0, .62),
                  child: MyQr(
                    size: w * .52,
                    cfg: s.qr.copy()
                      ..frame = true
                      ..frameStyle = 0,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, .96),
                  child: Container(
                    width: w * .36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StoryPreview extends StatelessWidget {
  const StoryPreview({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    return LayoutBuilder(
      builder: (_, b) {
        final w = b.maxWidth;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B0764), Color(0xFF6F66E8), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: VC.pink.withValues(alpha: .3),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Avatar(
                name: s.me.name,
                seed: s.me.avatarSeed,
                emoji: s.me.emoji,
                size: w * .26,
                ring: true,
              ),
              SizedBox(height: w * .04),
              Text(
                s.me.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: w * .075,
                ),
              ),
              Text(
                '@${s.me.username}',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: w * .05,
                ),
              ),
              SizedBox(height: w * .06),
              MyQr(size: w * .6, cfg: s.qr.copy()..frame = false),
              SizedBox(height: w * .06),
              Text(
                'SCAN TO CONNECT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontSize: w * .042,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview();
  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (_, b) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: VC.violet.withValues(alpha: .3),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(child: MyQr(size: b.maxWidth * .78)),
        ),
      ),
    ),
  );
}
