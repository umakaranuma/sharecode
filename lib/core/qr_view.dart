import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:qr/qr.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

final _cache = <String, QrImage>{};
QrImage _image(String data) => _cache.putIfAbsent(data, () {
  final code = QrCode.fromData(
    data: data,
    errorCorrectLevel: QrErrorCorrectLevel.H,
  );
  return QrImage(code);
});

class _QrPainter extends CustomPainter {
  _QrPainter(
    this.data,
    this.dots,
    this.eyes,
    this.pal,
    this.hole, {
    this.transparent = false,
  });
  final String data;
  final QrDots dots;
  final QrEyes eyes;
  final QrPalette pal;
  final bool hole, transparent;

  @override
  void paint(Canvas canvas, Size size) {
    final img = _image(data);
    final n = img.moduleCount;
    const quiet = 1.0;
    final cell = size.width / (n + quiet * 2);
    final off = cell * quiet;
    if (!transparent) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(cell * 2.4),
        ),
        Paint()..color = pal.bg,
      );
    }
    final shader = LinearGradient(
      colors: [pal.a, pal.b],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Offset.zero & size);

    bool dark(int r, int c) =>
        r >= 0 && c >= 0 && r < n && c < n && img.isDark(r, c);
    bool finder(int r, int c) =>
        (r < 7 && c < 7) || (r < 7 && c >= n - 7) || (r >= n - 7 && c < 7);
    final holeSide = hole ? (n * .25).ceil() : 0;
    final h0 = ((n - holeSide) / 2).floor();
    bool inHole(int r, int c) =>
        hole &&
        r >= h0 - 1 &&
        r < h0 + holeSide + 1 &&
        c >= h0 - 1 &&
        c < h0 + holeSide + 1;

    final path = Path();
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (!dark(r, c) || finder(r, c) || inHole(r, c)) continue;
        final x = off + c * cell, y = off + r * cell;
        final rect = Rect.fromLTWH(x, y, cell, cell);
        switch (dots) {
          case QrDots.classic:
            path.addRect(rect.inflate(.25));
          case QrDots.dots:
            path.addOval(
              Rect.fromCenter(
                center: rect.center,
                width: cell * .86,
                height: cell * .86,
              ),
            );
          case QrDots.rounded:
            final u = dark(r - 1, c),
                d = dark(r + 1, c),
                l = dark(r, c - 1),
                rt = dark(r, c + 1);
            final rad = Radius.circular(cell * .5);
            path.addRRect(
              RRect.fromRectAndCorners(
                rect.inflate(.2),
                topLeft: !u && !l ? rad : Radius.zero,
                topRight: !u && !rt ? rad : Radius.zero,
                bottomLeft: !d && !l ? rad : Radius.zero,
                bottomRight: !d && !rt ? rad : Radius.zero,
              ),
            );
          case QrDots.soft:
            path.addOval(
              Rect.fromCenter(
                center: rect.center,
                width: cell * .92,
                height: cell * .92,
              ),
            );
            if (dark(r, c + 1) && !finder(r, c + 1) && !inHole(r, c + 1)) {
              path.addRect(
                Rect.fromLTWH(x + cell * .5, y + cell * .08, cell, cell * .84),
              );
            }
            if (dark(r + 1, c) && !finder(r + 1, c) && !inHole(r + 1, c)) {
              path.addRect(
                Rect.fromLTWH(x + cell * .08, y + cell * .5, cell * .84, cell),
              );
            }
          case QrDots.diamond:
            final m = rect.center;
            final k = cell * .56;
            path
              ..moveTo(m.dx, m.dy - k)
              ..lineTo(m.dx + k, m.dy)
              ..lineTo(m.dx, m.dy + k)
              ..lineTo(m.dx - k, m.dy)
              ..close();
        }
      }
    }
    // Finder eyes.
    void eye(int r0, int c0) {
      final x = off + c0 * cell, y = off + r0 * cell;
      final outer = Rect.fromLTWH(x, y, cell * 7, cell * 7);
      final mid = Rect.fromLTWH(x + cell, y + cell, cell * 5, cell * 5);
      final inner = Rect.fromLTWH(
        x + cell * 2,
        y + cell * 2,
        cell * 3,
        cell * 3,
      );
      Path ring;
      switch (eyes) {
        case QrEyes.square:
          ring = Path()..addRect(outer);
          ring = Path.combine(
            PathOperation.difference,
            ring,
            Path()..addRect(mid),
          );
          path.addPath(ring, Offset.zero);
          path.addRect(inner);
        case QrEyes.rounded:
          ring = Path()
            ..addRRect(
              RRect.fromRectAndRadius(outer, Radius.circular(cell * 2.2)),
            );
          ring = Path.combine(
            PathOperation.difference,
            ring,
            Path()..addRRect(
              RRect.fromRectAndRadius(mid, Radius.circular(cell * 1.4)),
            ),
          );
          path.addPath(ring, Offset.zero);
          path.addRRect(
            RRect.fromRectAndRadius(inner, Radius.circular(cell * 1.1)),
          );
        case QrEyes.circle:
          ring = Path()..addOval(outer);
          ring = Path.combine(
            PathOperation.difference,
            ring,
            Path()..addOval(mid),
          );
          path.addPath(ring, Offset.zero);
          path.addOval(inner);
      }
    }

    eye(0, 0);
    eye(0, n - 7);
    eye(n - 7, 0);

    if (pal.neon) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = shader
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _QrPainter o) =>
      o.data != data ||
      o.dots != dots ||
      o.eyes != eyes ||
      o.pal != pal ||
      o.hole != hole ||
      o.transparent != transparent;
}

/// The QR itself (modules + optional center avatar).
class VibeQr extends StatelessWidget {
  const VibeQr({
    super.key,
    required this.data,
    required this.cfg,
    required this.me,
    this.size = 220,
    this.transparent = false,
  });
  final String data;
  final QrConfig cfg;
  final Profile me;
  final double size;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final pal = qrPalettes[cfg.paletteIndex];
    final showCenter = cfg.showAvatar;
    final logo = size * .23;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _QrPainter(
                data,
                cfg.dots,
                cfg.eyes,
                pal,
                showCenter,
                transparent: transparent,
              ),
            ),
          ),
          if (showCenter)
            Container(
              width: logo,
              height: logo,
              padding: EdgeInsets.all(logo * .08),
              decoration: BoxDecoration(color: pal.bg, shape: BoxShape.circle),
              child: switch (cfg.centerIcon) {
                'instagram' => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFEC4899),
                        Color(0xFF8B5CF6),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.instagram,
                    color: Colors.white,
                    size: logo * .5,
                  ),
                ),
                'monogram' => Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [pal.a, pal.b]),
                  ),
                  child: Text(
                    me.name.isEmpty ? 'V' : me.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: logo * .5,
                    ),
                  ),
                ),
                _ => Avatar(
                  name: me.name,
                  seed: me.avatarSeed,
                  size: logo,
                  emoji: me.emoji,
                ),
              },
            ),
        ],
      ),
    );
  }
}

const frameNames = ['Pill', 'Banner', 'Bubble', 'Ticket', 'Neon'];
const frameTexts = [
  'Scan to connect',
  'Scan for Insta',
  'Save My Number',
  'Tap to Connect',
  'ஸ்கேன் செய்க',
  'ස්කෑන් කරන්න',
];

/// QR with the user's chosen call-to-action frame around it.
class QrCard extends StatelessWidget {
  const QrCard({
    super.key,
    required this.cfg,
    required this.me,
    this.size = 220,
    this.transparent = false,
    this.link,
  });
  final QrConfig cfg;
  final Profile me;
  final double size;
  final bool transparent;
  final String? link;

  @override
  Widget build(BuildContext context) {
    final pal = qrPalettes[cfg.paletteIndex];
    final data = 'https://${link ?? me.url}';
    final qr = VibeQr(
      data: data,
      cfg: cfg,
      me: me,
      size: size,
      transparent: transparent,
    );
    if (!cfg.frame || transparent) return qr;
    final handle = '@${me.username}';
    final label = cfg.frameText;
    final grad = LinearGradient(colors: [pal.a, pal.b]);
    final txtCol = Colors.white;
    switch (cfg.frameStyle) {
      case 1: // banner under
        return Container(
          padding: EdgeInsets.all(size * .05),
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(size * .12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(size * .08),
                child: qr,
              ),
              SizedBox(height: size * .04),
              Text(
                label,
                style: TextStyle(
                  color: txtCol,
                  fontWeight: FontWeight.w700,
                  fontSize: size * .075,
                  letterSpacing: .4,
                ),
              ),
              SizedBox(height: size * .015),
            ],
          ),
        );
      case 2: // bubble on top
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * .08,
                vertical: size * .035,
              ),
              decoration: BoxDecoration(
                gradient: grad,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: txtCol,
                  fontWeight: FontWeight.w700,
                  fontSize: size * .06,
                ),
              ),
            ),
            CustomPaint(
              size: Size(size * .08, size * .04),
              painter: _Tri(pal.b),
            ),
            Container(
              padding: EdgeInsets.all(size * .03),
              decoration: BoxDecoration(
                border: Border.all(color: pal.a, width: 3),
                borderRadius: BorderRadius.circular(size * .1),
              ),
              child: qr,
            ),
          ],
        );
      case 3: // ticket
        return Container(
          padding: EdgeInsets.fromLTRB(
            size * .05,
            size * .05,
            size * .05,
            size * .03,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * .1),
            border: Border.all(color: pal.a, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              qr,
              SizedBox(height: size * .03),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: size * .07, color: pal.a),
                  Text(
                    ' $label',
                    style: TextStyle(
                      color: pal.a,
                      fontWeight: FontWeight.w700,
                      fontSize: size * .062,
                    ),
                  ),
                ],
              ),
              Text(
                handle,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: size * .05,
                ),
              ),
            ],
          ),
        );
      case 4: // neon glow
        return Container(
          padding: EdgeInsets.all(size * .04),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0820),
            borderRadius: BorderRadius.circular(size * .12),
            border: Border.all(color: pal.b, width: 2),
            boxShadow: [
              BoxShadow(color: pal.b.withValues(alpha: .6), blurRadius: 24),
              BoxShadow(color: pal.a.withValues(alpha: .4), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              qr,
              SizedBox(height: size * .03),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: pal.b,
                  fontWeight: FontWeight.w700,
                  fontSize: size * .055,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        );
      default: // pill (reference design)
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: EdgeInsets.all(size * .04),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(size * .13),
                boxShadow: [
                  BoxShadow(
                    color: pal.a.withValues(alpha: .25),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: size * .06),
                child: qr,
              ),
            ),
            Positioned(
              bottom: -size * .045,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * .07,
                  vertical: size * .03,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: size * .075,
                      height: size * .075,
                      decoration: BoxDecoration(
                        gradient: grad,
                        borderRadius: BorderRadius.circular(size * .02),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        size: size * .055,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: size * .025),
                    Text(
                      handle,
                      style: TextStyle(
                        color: const Color(0xFF14112E),
                        fontWeight: FontWeight.w700,
                        fontSize: size * .062,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _Tri extends CustomPainter {
  _Tri(this.c);
  final Color c;
  @override
  void paint(Canvas canvas, Size s) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width / 2, s.height)
      ..close(),
    Paint()..color = c,
  );
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Convenience: renders the current user's QR card from the store.
class MyQr extends StatelessWidget {
  const MyQr({super.key, this.size = 220, this.cfg, this.transparent = false});
  final double size;
  final QrConfig? cfg;
  final bool transparent;
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    return QrCard(
      cfg: cfg ?? s.qr,
      me: s.me,
      size: size,
      transparent: transparent,
    );
  }
}
