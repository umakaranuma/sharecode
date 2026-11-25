import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/models.dart';
import '../core/qr_view.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  bool splash = true;
  final ctrl = PageController();
  int page = 0;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => splash = false);
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Glow(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: splash ? const _Splash() : _slides(context),
        ),
      ),
    );
  }

  Widget _slides(BuildContext context) {
    final c = context.c;
    final slides = [
      _Slide(
        'One QR.\nAll your links.',
        'Instagram, WhatsApp, Spotify and more — in a single, always-up-to-date digital card.',
        const _QrArt(),
      ),
      _Slide(
        'You control\nwho sees what',
        'Switch between Chill and Work modes in one tap. Ghost mode, PIN locks, temporary links.',
        const _PrivacyArt(),
      ),
      _Slide(
        'Scan. Wave.\nConnect.',
        'Scanners don\'t even need the app. Send a Wave and unlock chat when it\'s mutual.',
        const _WaveArt(),
      ),
    ];
    return SafeArea(
      key: const ValueKey('slides'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
            child: Row(
              children: [
                const VLogo(size: 30),
                const Spacer(),
                TextButton(
                  onPressed: () => context.store
                    ..seenIntro = true
                    ..touch(),
                  child: Text(
                    'Skip',
                    style: TextStyle(color: c.sub, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: ctrl,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Expanded(child: Center(child: slides[i].art)),
                    Text(
                      slides[i].title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      slides[i].body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: c.sub,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == page ? 26 : 8,
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: GradBtn(
              page == slides.length - 1 ? 'Get Started' : 'Next',
              icon: page == slides.length - 1
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              onTap: () {
                if (page == slides.length - 1) {
                  context.store
                    ..seenIntro = true
                    ..touch();
                } else {
                  ctrl.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  _Slide(this.title, this.body, this.art);
  final String title, body;
  final Widget art;
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey('splash'),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.elasticOut,
      builder: (_, v, _) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.scale(
          scale: .6 + v * .4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VLogo(size: 76, word: false),
              const SizedBox(height: 22),
              const Text(
                'VibeDrop',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your digital identity • One QR',
                style: TextStyle(
                  color: context.c.sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QrArt extends StatelessWidget {
  const _QrArt();
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final cfg = QrConfig()..frame = false;
    final icons = [
      (FontAwesomeIcons.instagram, const Color(0xFFE1306C), -.9, -.7),
      (FontAwesomeIcons.whatsapp, const Color(0xFF25D366), .95, -.35),
      (FontAwesomeIcons.spotify, const Color(0xFF1DB954), -1.0, .45),
      (FontAwesomeIcons.linkedinIn, const Color(0xFF0A66C2), .85, .8),
    ];
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: VC.violet.withValues(alpha: .5),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: VibeQr(
            data: 'https://vibedrop.lk/u/you',
            cfg: cfg,
            me: s.me,
            size: 210,
          ),
        ),
        for (final i in icons)
          Align(
            alignment: Alignment(i.$3, i.$4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (_, v, _) => Transform.scale(
                scale: v,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: i.$2,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: i.$2.withValues(alpha: .5),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Center(child: anyIcon(i.$1, color: Colors.white, size: 22)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PrivacyArt extends StatelessWidget {
  const _PrivacyArt();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget mode(String t, IconData i, Color col, bool on) => Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: on ? col : c.border, width: on ? 2 : 1),
        boxShadow: on
            ? [BoxShadow(color: col.withValues(alpha: .3), blurRadius: 24)]
            : null,
      ),
      child: Row(
        children: [
          RoundIconBg(i, col),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              t,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          Icon(
            on
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: on ? col : c.sub,
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mode('Chill / Social', Icons.celebration_rounded, VC.pink, true),
        mode('Work / Campus', Icons.work_rounded, VC.blue, false),
        mode('Ghost Mode', Icons.visibility_off_rounded, VC.violet, false),
      ],
    );
  }
}

class _WaveArt extends StatefulWidget {
  const _WaveArt();
  @override
  State<_WaveArt> createState() => _WaveArtState();
}

class _WaveArtState extends State<_WaveArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: a,
    builder: (_, _) => Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 120.0 + i * 70 + a.value * 14,
            height: 120.0 + i * 70 + a.value * 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: VC.violet.withValues(alpha: .35 - i * .1),
                width: 2,
              ),
            ),
          ),
        Transform.rotate(
          angle: sin(a.value * pi * 2) * .25,
          child: const Text('👋', style: TextStyle(fontSize: 84)),
        ),
        const Align(
          alignment: Alignment(-.9, -.6),
          child: Avatar(name: 'Nisha Ravi', seed: 3, size: 56, ring: true),
        ),
        const Align(
          alignment: Alignment(.95, .55),
          child: Avatar(name: 'Arjun Dev', seed: 11, size: 56, ring: true),
        ),
      ],
    ),
  );
}
