import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'home.dart';
import 'pro.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int range = 1; // 0 = 7d, 1 = 14d
  int? sel;

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final data = range == 0 ? s.daily.sublist(7) : s.daily;
    final total = data.fold<int>(0, (a, b) => a + b);
    final maxLink = s.me.links.fold<int>(1, (a, l) => max(a, l.clicks));
    final cityTotal = s.cityScans.values.fold<int>(0, (a, b) => a + b);
    final devTotal = s.deviceScans.values.fold<int>(0, (a, b) => a + b);

    Widget locked(Widget child, String what) {
      if (s.pro) return child;
      return Stack(
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: IgnorePointer(child: child),
          ),
          Positioned.fill(
            child: Center(
              child: Tap(
                onTap: () => pushPage(context, ProPage(reason: what)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: VC.proGrad,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: VC.orange.withValues(alpha: .2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Unlock with Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Glow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
          children: [
            Row(
              children: [
                Expanded(
                  child: _big(
                    context,
                    Icons.qr_code_2_rounded,
                    fmt(s.totalScans),
                    'Lifetime scans',
                    VC.violet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _big(
                    context,
                    Icons.ads_click_rounded,
                    fmt(s.totalClicks),
                    'Link clicks',
                    VC.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _big(
                    context,
                    Icons.contact_page_rounded,
                    '${s.savedContacts}',
                    'Contacts saved',
                    VC.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _big(
                    context,
                    Icons.waving_hand_rounded,
                    '${s.waves.length}',
                    'Waves',
                    VC.orange,
                  ),
                ),
              ],
            ),
            SectionTitle(
              'Scans over time',
              sub: 'Daily scans',
              action: s.pro ? null : 'PRO',
            ),
            locked(
              Box(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('scans', style: TextStyle(color: c.sub)),
                        const Spacer(),
                        SizedBox(
                          width: 150,
                          child: Segment(
                            items: const ['7 days', '14 days'],
                            index: range,
                            onChanged: (i) => setState(() {
                              range = i;
                              sel = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 160,
                      child: LayoutBuilder(
                        builder: (_, b) {
                          final bw = b.maxWidth / data.length;
                          return GestureDetector(
                            onTapDown: (d) => setState(
                              () => sel = (d.localPosition.dx / bw)
                                  .floor()
                                  .clamp(0, data.length - 1),
                            ),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(range),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (_, t, _) => CustomPaint(
                                size: Size(b.maxWidth, 160),
                                painter: _Bars(data, t, sel, c),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (sel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Pill(
                          '${data[sel!]} scans • day ${sel! + 1}',
                          color: c.accent,
                        ),
                      ),
                  ],
                ),
              ),
              'Daily & weekly scan graphs',
            ),
            const SectionTitle(
              'Link-by-link breakdown',
              sub:
                  '42 scans → 31 clicked Instagram, 8 WhatsApp, 3 saved contact',
            ),
            locked(
              Box(
                child: Column(
                  children: [
                    for (final l in ([
                      ...s.me.links,
                    ]..sort((a, b) => b.clicks.compareTo(a.clicks))))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            PlatformBadge(l.meta, size: 38),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        l.meta.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${l.clicks}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0,
                                      end: l.clicks / maxLink,
                                    ),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, _) => ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: v,
                                        minHeight: 8,
                                        backgroundColor: c.card2,
                                        valueColor: AlwaysStoppedAnimation(
                                          l.meta.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              'Link-by-link analytics',
            ),
            const SectionTitle(
              'Where people scan from',
              sub: 'Approximate city-level location',
            ),
            locked(
              Box(
                child: Column(
                  children: [
                    for (final e in s.cityScans.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 18,
                              color: c.accent,
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 74,
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: e.value / cityTotal * 2,
                                  minHeight: 8,
                                  backgroundColor: c.card2,
                                  valueColor: const AlwaysStoppedAnimation(
                                    VC.fuchsia,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(e.value / cityTotal * 100).round()}%',
                              style: TextStyle(
                                color: c.sub,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              'City-level scan locations',
            ),
            const SectionTitle('Devices'),
            locked(
              Box(
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: _Donut(s.deviceScans.values.toList(), const [
                          VC.violet,
                          VC.pink,
                        ]),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          for (final (i, e) in s.deviceScans.entries.indexed)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: [VC.violet, VC.pink][i],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(e.value / devTotal * 100).round()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              'Device breakdown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _big(
    BuildContext context,
    IconData i,
    String v,
    String l,
    Color col,
  ) => Box(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoundIconBg(i, col, size: 38, radius: 12),
        const SizedBox(height: 12),
        Text(
          v,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        Text(l, style: TextStyle(color: context.c.sub, fontSize: 13)),
      ],
    ),
  );
}

class _Bars extends CustomPainter {
  _Bars(this.d, this.t, this.sel, this.c);
  final List<int> d;
  final double t;
  final int? sel;
  final VC c;
  @override
  void paint(Canvas canvas, Size s) {
    final mx = d.reduce(max).toDouble();
    final bw = s.width / d.length;
    for (var i = 0; i < d.length; i++) {
      final h = (d[i] / mx) * (s.height - 12) * t;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * bw + bw * .18, s.height - h, bw * .64, h),
        const Radius.circular(8),
      );
      final on = sel == null || sel == i;
      canvas.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
            colors: on ? [VC.fuchsia, VC.violet] : [c.border, c.border],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(r.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Bars o) => o.t != t || o.sel != sel || o.d != d;
}

class _Donut extends CustomPainter {
  _Donut(this.v, this.cols);
  final List<int> v;
  final List<Color> cols;
  @override
  void paint(Canvas canvas, Size s) {
    final tot = v.fold<int>(0, (a, b) => a + b);
    var a = -pi / 2;
    final r = Rect.fromLTWH(10, 10, s.width - 20, s.height - 20);
    for (var i = 0; i < v.length; i++) {
      final sw = v[i] / tot * 2 * pi;
      canvas.drawArc(
        r,
        a,
        sw - .06,
        false,
        Paint()
          ..color = cols[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );
      a += sw;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
