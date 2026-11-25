import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';

// ───────────────────────── toast ─────────────────────────
void toast(
  BuildContext context,
  String msg, {
  IconData icon = Icons.check_circle_rounded,
  Color? color,
}) {
  final c = context.c;
  final m = ScaffoldMessenger.of(context);
  m.clearSnackBars();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.dark
          ? const Color(0xFF2A2650)
          : const Color(0xFF1E1B4B),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(milliseconds: 2200),
      content: Row(
        children: [
          Icon(icon, color: color ?? const Color(0xFF86EFAC), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void copyText(BuildContext context, String text, [String? msg]) {
  Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.lightImpact();
  toast(context, msg ?? 'Copied to clipboard', icon: Icons.copy_rounded);
}

Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

Future<T?> sheet<T>(
  BuildContext context,
  Widget Function(BuildContext) b, {
  bool full = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: BoxConstraints(
    maxHeight: context.screen.height * (full ? .95 : .88),
  ),
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
    child: b(ctx),
  ),
);

Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String ok = 'Confirm',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      content: Text(body, style: TextStyle(color: ctx.c.sub, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: TextStyle(color: ctx.c.sub)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger ? VC.red : VC.violet,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ───────────────────────── tap / animation ─────────────────────────
class Tap extends StatefulWidget {
  const Tap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = .96,
    this.onLong,
  });
  final Widget child;
  final VoidCallback? onTap, onLong;
  final double scale;
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => down = true),
    onTapCancel: () => setState(() => down = false),
    onTapUp: (_) => setState(() => down = false),
    onTap: widget.onTap == null
        ? null
        : () {
            HapticFeedback.selectionClick();
            widget.onTap!();
          },
    onLongPress: widget.onLong,
    child: AnimatedScale(
      scale: down ? widget.scale : 1,
      duration: const Duration(milliseconds: 110),
      child: widget.child,
    ),
  );
}

/// Staggered fade + slide-up entrance.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.i = 0, this.dy = 18});
  final Widget child;
  final int i;
  final double dy;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 420 + i * 70),
    curve: Curves.easeOutCubic,
    builder: (_, v, ch) => Opacity(
      opacity: v.clamp(0, 1),
      child: Transform.translate(offset: Offset(0, (1 - v) * dy), child: ch),
    ),
    child: child,
  );
}

// ───────────────────────── surfaces ─────────────────────────
class Box extends StatelessWidget {
  const Box({
    super.key,
    required this.child,
    this.pad = 16,
    this.onTap,
    this.radius = 22,
    this.color,
    this.border = true,
    this.gradient,
    this.margin,
  });
  final Widget child;
  final double pad, radius;
  final VoidCallback? onTap;
  final Color? color;
  final bool border;
  final Gradient? gradient;
  final EdgeInsets? margin;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final w = Container(
      margin: margin,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border && gradient == null ? Border.all(color: c.border) : null,
        boxShadow: c.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
    return onTap == null ? w : Tap(onTap: onTap, scale: .98, child: w);
  }
}

class GradBtn extends StatelessWidget {
  const GradBtn(
    this.label, {
    super.key,
    this.onTap,
    this.icon,
    this.gradient = VC.brand,
    this.height = 54,
    this.loading = false,
    this.expand = true,
    this.textColor = Colors.white,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient gradient;
  final double height;
  final bool loading, expand;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Tap(
      onTap: loading ? null : onTap,
      child: Opacity(
        opacity: disabled ? .45 : 1,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(height / 2.6),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: VC.violet.withValues(alpha: .2),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: textColor,
                  ),
                )
              else ...[
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SoftBtn extends StatelessWidget {
  const SoftBtn(
    this.label, {
    super.key,
    this.onTap,
    this.icon,
    this.height = 54,
    this.expand = true,
    this.color,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool expand;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = color ?? c.accent;
    return Tap(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: c.dark ? .16 : .1),
          borderRadius: BorderRadius.circular(height / 2.6),
          border: Border.all(color: fg.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 19),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.icon,
    this.color,
    this.filled = false,
  });
  final String text;
  final IconData? icon;
  final Color? color;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final col = color ?? context.c.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? col : col.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.white : col),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : col,
            ),
          ),
        ],
      ),
    );
  }
}

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      gradient: VC.proGrad,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
        SizedBox(width: 3),
        Text(
          'PRO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.text, {
    super.key,
    this.action,
    this.onAction,
    this.sub,
  });
  final String text;
  final String? action, sub;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sub != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    sub!,
                    style: TextStyle(fontSize: 13, color: context.c.sub),
                  ),
                ),
            ],
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: TextStyle(
                color: context.c.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
      ],
    ),
  );
}

class IconCircle extends StatelessWidget {
  const IconCircle(
    this.icon, {
    super.key,
    this.onTap,
    this.dot = false,
    this.size = 44,
    this.color,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool dot;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: c.card,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, size: size * .5, color: color ?? c.text),
          ),
          if (dot)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: VC.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders either a Material [IconData] or a Font Awesome brand icon.
Widget anyIcon(Object i, {Color? color, double? size}) => i is FaIconData
    ? FaIcon(i, color: color, size: size)
    : Icon(i as IconData, color: color, size: size);

class RoundIconBg extends StatelessWidget {
  const RoundIconBg(
    this.icon,
    this.color, {
    super.key,
    this.size = 46,
    this.radius = 15,
  });
  final Object icon;
  final Color color;
  final double size, radius;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: anyIcon(icon, color: color, size: size * .5),
  );
}

class PlatformBadge extends StatelessWidget {
  const PlatformBadge(this.p, {super.key, this.size = 44});
  final Platform p;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: p.id == 'instagram'
          ? const LinearGradient(
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            )
          : null,
      color: p.id == 'instagram' ? null : p.color,
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: Center(
      child: FaIcon(
        p.icon,
        color: p.id == 'snapchat' ? Colors.white : Colors.white,
        size: size * .5,
      ),
    ),
  );
}

class GradText extends StatelessWidget {
  const GradText(this.text, {super.key, this.style, this.gradient = VC.sunset});
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (r) => gradient.createShader(r),
    child: Text(
      text,
      style: (style ?? const TextStyle()).copyWith(color: Colors.white),
    ),
  );
}

// ───────────────────────── avatar & art ─────────────────────────
const _avatarGrads = [
  [Color(0xFF4F5BFF), Color(0xFF8A4DFF)],
  [Color(0xFFF29B4B), Color(0xFFEB6FA3)],
  [Color(0xFF22B8E8), Color(0xFF4F5BFF)],
  [Color(0xFF2FCB92), Color(0xFF22B8E8)],
  [Color(0xFFF2C46B), Color(0xFFF0545F)],
  [Color(0xFF8A4DFF), Color(0xFF22B8E8)],
  [Color(0xFFEB6FA3), Color(0xFFF2C46B)],
  [Color(0xFF4A9BFF), Color(0xFF8A4DFF)],
];
List<Color> avatarGrad(int seed) =>
    _avatarGrads[seed.abs() % _avatarGrads.length];

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.seed = 0,
    this.size = 48,
    this.emoji = '',
    this.online = false,
    this.ring = false,
    this.square = false,
  });
  final String name, emoji;
  final int seed;
  final double size;
  final bool online, ring, square;
  @override
  Widget build(BuildContext context) {
    final g = avatarGrad(seed);
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final ini = parts.isEmpty
        ? '?'
        : (parts.length == 1 ? parts[0][0] : parts[0][0] + parts.last[0])
              .toUpperCase();
    final shape = square ? BoxShape.rectangle : BoxShape.circle;
    Widget face = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: square ? BorderRadius.circular(size * .3) : null,
        gradient: LinearGradient(
          colors: g,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        emoji.isNotEmpty ? emoji : ini,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * (emoji.isNotEmpty ? .46 : .36),
        ),
      ),
    );
    if (ring) {
      face = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: shape,
          gradient: VC.sunset,
          borderRadius: square ? BorderRadius.circular(size * .35) : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: shape,
            color: context.c.bg,
            borderRadius: square ? BorderRadius.circular(size * .32) : null,
          ),
          child: face,
        ),
      );
    }
    if (!online) return face;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        face,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * .26,
            height: size * .26,
            decoration: BoxDecoration(
              color: VC.green,
              shape: BoxShape.circle,
              border: Border.all(color: context.c.card, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Procedural scenic artwork (sunset / sea / palms) used for covers + gallery.
class Scenic extends StatelessWidget {
  const Scenic({
    super.key,
    required this.seed,
    this.radius = 0,
    this.palms = true,
  });
  final int seed;
  final double radius;
  final bool palms;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: CustomPaint(
      painter: _ScenicPainter(seed, palms),
      child: const SizedBox.expand(),
    ),
  );
}

class _ScenicPainter extends CustomPainter {
  _ScenicPainter(this.seed, this.palms);
  final int seed;
  final bool palms;
  static const skies = [
    [
      Color(0xFF14142A),
      Color(0xFF3A3470),
      Color(0xFF8A6A9E),
      Color(0xFFE2B58F),
    ],
    [
      Color(0xFF0E1626),
      Color(0xFF26456E),
      Color(0xFF5F8DAE),
      Color(0xFFE4D3A8),
    ],
    [
      Color(0xFF1C1428),
      Color(0xFF55386E),
      Color(0xFFB07A86),
      Color(0xFFE6C48E),
    ],
    [
      Color(0xFF0C1E20),
      Color(0xFF1F5A58),
      Color(0xFF6BA39A),
      Color(0xFFEADFBC),
    ],
    [
      Color(0xFF241518),
      Color(0xFF6E3A3A),
      Color(0xFFB8795E),
      Color(0xFFE8CF9A),
    ],
  ];
  @override
  void paint(Canvas canvas, Size s) {
    final sky = skies[seed.abs() % skies.length];
    final r = Random(seed * 31 + 7);
    final horizon = s.height * (.58 + r.nextDouble() * .1);
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          colors: sky,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .45, .8, 1],
        ).createShader(Offset.zero & s),
    );
    // stars
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(r.nextDouble() * s.width, r.nextDouble() * horizon * .6),
        r.nextDouble() * 1.1 + .3,
        Paint()..color = Colors.white.withValues(alpha: .5),
      );
    }
    // sun
    final sun = Offset(
      s.width * (.25 + r.nextDouble() * .5),
      horizon - s.height * .02,
    );
    canvas.drawCircle(
      sun,
      s.shortestSide * .34,
      Paint()
        ..shader =
            RadialGradient(
              colors: [Colors.white.withValues(alpha: .55), Colors.transparent],
            ).createShader(
              Rect.fromCircle(center: sun, radius: s.shortestSide * .34),
            ),
    );
    canvas.drawCircle(sun, s.shortestSide * .11, Paint()..color = sky[3]);
    // sea
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, s.width, s.height),
      Paint()
        ..shader = LinearGradient(
          colors: [sky[2].withValues(alpha: .85), sky[0]],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(0, horizon, s.width, s.height)),
    );
    for (var i = 0; i < 6; i++) {
      final y = horizon + (s.height - horizon) * (i / 6) + 4;
      canvas.drawLine(
        Offset(sun.dx - 30 + i * 3.0, y),
        Offset(sun.dx + 30 - i * 3.0, y),
        Paint()
          ..color = sky[3].withValues(alpha: .5)
          ..strokeWidth = 1.3,
      );
    }
    if (!palms) return;
    // palms
    final trunk = Paint()
      ..color = Colors.black.withValues(alpha: .78)
      ..strokeWidth = s.width * .018
      ..strokeCap = StrokeCap.round;
    for (final fx in [.1, .92]) {
      final base = Offset(s.width * fx, s.height + 4);
      final top = Offset(
        s.width * (fx + (fx < .5 ? .05 : -.05)),
        s.height * .42,
      );
      canvas.drawLine(base, top, trunk);
      for (var k = 0; k < 6; k++) {
        final a = -pi / 2 + (k - 2.5) * .62;
        final len = s.width * .15;
        final end = top + Offset(cos(a) * len, sin(a) * len * .7 + len * .25);
        final p = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            top.dx + cos(a) * len * .6,
            top.dy + sin(a) * len * .6 - 6,
            end.dx,
            end.dy,
          );
        canvas.drawPath(
          p,
          Paint()
            ..color = Colors.black.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenicPainter o) => o.seed != seed;
}

// ───────────────────────── logo ─────────────────────────
class VLogo extends StatelessWidget {
  const VLogo({super.key, this.size = 36, this.word = true});
  final double size;
  final bool word;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: VC.brand,
          borderRadius: BorderRadius.circular(size * .3),
          boxShadow: [
            BoxShadow(
              color: VC.violet.withValues(alpha: .2),
              blurRadius: size * .3,
            ),
          ],
        ),
        child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * .66),
      ),
      if (word) ...[
        SizedBox(width: size * .28),
        Text(
          'VibeDrop',
          style: TextStyle(
            fontSize: size * .62,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
        ),
      ],
    ],
  );
}

// ───────────────────────── backdrop ─────────────────────────
class Glow extends StatelessWidget {
  const Glow({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: c.bg)),
        Positioned(
          top: -140,
          right: -90,
          child: _blob(VC.violet.withValues(alpha: c.dark ? .10 : .06), 340),
        ),
        Positioned(
          top: 160,
          left: -140,
          child: _blob(VC.pink.withValues(alpha: c.dark ? .035 : .025), 280),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _blob(Color col, double s) => IgnorePointer(
    child: Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [col, Colors.transparent]),
      ),
    ),
  );
}

class FormLabel extends StatelessWidget {
  const FormLabel(this.t, {super.key});
  final String t;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.c.sub,
      ),
    ),
  );
}

/// A settings-style row: icon, title, subtitle and trailing widget.
class RowTile extends StatelessWidget {
  const RowTile({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.trailing,
    this.onTap,
    this.color,
    this.danger = false,
  });
  final Object icon;
  final String title;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = danger ? VC.red : (color ?? c.accent);
    return Tap(
      onTap: onTap,
      scale: .985,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            RoundIconBg(icon, col, size: 42, radius: 13),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: danger ? VC.red : c.text,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: c.sub,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded, color: c.sub)
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }
}

class Divider1 extends StatelessWidget {
  const Divider1({super.key});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: context.c.border);
}

/// Locks features behind Pro with an upsell sheet.
bool requirePro(BuildContext context, VoidCallback openPaywall) {
  if (context.store.pro) return true;
  openPaywall();
  return false;
}

class Segment extends StatelessWidget {
  const Segment({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == index ? VC.brand : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: i == index ? Colors.white : c.sub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
