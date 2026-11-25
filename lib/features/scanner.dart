import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'profile_view.dart';

/// Simulated camera scanner (no camera plugin): a live-looking viewfinder with
/// a tappable QR "in the scene", torch, gallery import and manual code entry.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with TickerProviderStateMixin {
  late final AnimationController line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  late final AnimationController drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);
  bool torch = false, found = false, front = false;
  Contact? target;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    target ??= context.store.nextScan();
  }

  @override
  void dispose() {
    line.dispose();
    drift.dispose();
    super.dispose();
  }

  Future<void> detect(Contact c) async {
    if (found) return;
    HapticFeedback.heavyImpact();
    setState(() {
      found = true;
      target = c;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            PublicProfilePage(data: ViewData.fromContact(c), fromScan: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final size = context.screen;
    final box = size.width * .72;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // fake camera feed
          AnimatedBuilder(
            animation: drift,
            builder: (_, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    -.4 + drift.value * .8,
                    -.3 + drift.value * .3,
                  ),
                  radius: 1.3,
                  colors: torch
                      ? [
                          const Color(0xFF8A7F68),
                          const Color(0xFF2A2630),
                          const Color(0xFF0C0B10),
                        ]
                      : [
                          const Color(0xFF3A3548),
                          const Color(0xFF16141F),
                          const Color(0xFF07060B),
                        ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _Grain())),
          // the scene QR
          AnimatedBuilder(
            animation: drift,
            builder: (_, child) => Align(
              alignment: Alignment(
                sin(drift.value * pi) * .1,
                -.08 + drift.value * .06,
              ),
              child: Transform.rotate(
                angle: (drift.value - .5) * .08,
                child: child,
              ),
            ),
            child: Tap(
              onTap: () => detect(target!),
              child: Container(
                width: box * .72,
                height: box * .72,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .5),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: CustomPaint(painter: _MiniQr(target?.seed ?? 0)),
              ),
            ),
          ),
          // viewfinder
          IgnorePointer(
            child: Align(
              alignment: const Alignment(0, -.08),
              child: SizedBox(
                width: box,
                height: box,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(box, box),
                      painter: _Brackets(found ? VC.green : Colors.white),
                    ),
                    if (!found)
                      AnimatedBuilder(
                        animation: line,
                        builder: (_, _) => Positioned(
                          top: 14 + line.value * (box - 28),
                          left: 14,
                          right: 14,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  VC.fuchsia,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: VC.fuchsia.withValues(alpha: .8),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (found)
                      const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: VC.green,
                          size: 84,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _btn(Icons.close_rounded, () => Navigator.pop(context)),
                      const Spacer(),
                      const Text(
                        'Scan a QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _btn(Icons.help_outline_rounded, () => _help(context)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: EdgeInsets.only(bottom: size.height * .02),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    found
                        ? 'Code detected!'
                        : 'Tap the QR in view to scan (demo)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 6, 28, 26),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _action(
                        torch
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        torch ? 'Torch on' : 'Torch',
                        torch,
                        () => setState(() => torch = !torch),
                      ),
                      _action(
                        Icons.photo_library_rounded,
                        'Gallery',
                        false,
                        () => _gallery(context),
                      ),
                      _action(
                        Icons.keyboard_rounded,
                        'Enter code',
                        false,
                        () => _manual(context),
                      ),
                      _action(
                        Icons.cameraswitch_rounded,
                        front ? 'Front' : 'Back',
                        front,
                        () => setState(() => front = !front),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${s.wallet.length} cards in your wallet',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData i, VoidCallback f) => Tap(
    onTap: f,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        shape: BoxShape.circle,
      ),
      child: Icon(i, color: Colors.white),
    ),
  );

  Widget _action(IconData i, String t, bool on, VoidCallback f) => Tap(
    onTap: f,
    child: Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.white.withValues(alpha: .16),
            shape: BoxShape.circle,
          ),
          child: Icon(i, color: on ? Colors.black : Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          t,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  void _help(BuildContext context) {
    sheet(
      context,
      (ctx) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How scanning works',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 14),
            RowTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Point at any VibeDrop QR',
              sub: 'The profile opens instantly in the app.',
            ),
            RowTile(
              icon: Icons.bookmark_rounded,
              title: 'Auto-saved to My Wallet',
              sub: 'Every scan is kept in Scanned Connections.',
              color: VC.green,
            ),
            RowTile(
              icon: Icons.waving_hand_rounded,
              title: 'Send a Wave',
              sub: 'Mutual waves unlock in-app chat.',
              color: VC.orange,
            ),
          ],
        ),
      ),
    );
  }

  void _gallery(BuildContext context) {
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
              'Scan from image',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a screenshot or photo containing a QR.',
              style: TextStyle(color: ctx.c.sub),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 6; i++)
                  Tap(
                    onTap: () {
                      Navigator.pop(ctx);
                      final c = s.directory[i % s.directory.length];
                      detect(c);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Scenic(seed: i + 3),
                          Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(5),
                              color: Colors.white,
                              child: CustomPaint(painter: _MiniQr(i)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _manual(BuildContext context) {
    final s = context.store;
    final ctrl = TextEditingController();
    sheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          String? err;
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter a handle',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Try: nisha_r, thivyan, dilan_p, anjali.f, mathu, ghost_one',
                  style: TextStyle(color: ctx.c.sub, height: 1.4),
                ),
                const FormLabel('Username'),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  autocorrect: false,
                  decoration: InputDecoration(
                    prefixText: '@',
                    errorText: err,
                    hintText: 'username',
                  ),
                ),
                const SizedBox(height: 18),
                GradBtn(
                  'Open profile',
                  onTap: () {
                    final h = ctrl.text
                        .trim()
                        .replaceFirst('@', '')
                        .toLowerCase();
                    final c = s.contactByHandle(h);
                    if (c == null) {
                      toast(
                        ctx,
                        'No profile found for @$h',
                        icon: Icons.search_off_rounded,
                        color: VC.red,
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    detect(c);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Brackets extends CustomPainter {
  _Brackets(this.c);
  final Color c;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const l = 38.0, r = 26.0;
    for (final (sx, sy) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
      final x = sx * s.width, y = sy * s.height;
      final dx = sx == 0 ? 1 : -1, dy = sy == 0 ? 1 : -1;
      final path = Path()
        ..moveTo(x, y + dy * l)
        ..lineTo(x, y + dy * r)
        ..quadraticBezierTo(x, y, x + dx * r, y)
        ..lineTo(x + dx * l, y);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _Brackets o) => o.c != c;
}

class _Grain extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = Random(3);
    final p = Paint()..color = Colors.white.withValues(alpha: .035);
    for (var i = 0; i < 280; i++) {
      canvas.drawCircle(
        Offset(r.nextDouble() * s.width, r.nextDouble() * s.height),
        r.nextDouble() * 1.6,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _MiniQr extends CustomPainter {
  _MiniQr(this.seed);
  final int seed;
  @override
  void paint(Canvas canvas, Size s) {
    const n = 21;
    final cell = s.width / n;
    final r = Random(seed * 13 + 5);
    final p = Paint()..color = const Color(0xFF14112E);
    bool finder(int a, int b) =>
        (a < 8 && b < 8) || (a < 8 && b >= n - 8) || (a >= n - 8 && b < 8);
    for (var a = 0; a < n; a++) {
      for (var b = 0; b < n; b++) {
        if (!finder(a, b) && r.nextDouble() > .52) {
          canvas.drawRect(
            Rect.fromLTWH(b * cell, a * cell, cell + .3, cell + .3),
            p,
          );
        }
      }
    }
    for (final (a, b) in [(0, 0), (0, n - 7), (n - 7, 0)]) {
      final o = Offset(b * cell, a * cell);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx, o.dy, cell * 7, cell * 7),
          Radius.circular(cell * 1.5),
        ),
        p,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx + cell, o.dy + cell, cell * 5, cell * 5),
          Radius.circular(cell),
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx + cell * 2, o.dy + cell * 2, cell * 3, cell * 3),
          Radius.circular(cell * .8),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniQr o) => o.seed != seed;
}
