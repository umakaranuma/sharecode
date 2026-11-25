import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/models.dart';
import '../core/qr_view.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'export.dart';
import 'pro.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});
  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  int tab = 0;
  late final TextEditingController txt = TextEditingController(
    text: context.store.qr.frameText,
  );

  void proGate(BuildContext context, String what) {
    pushPage<void>(context, ProPage(reason: what));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final q = s.qr;
    final pal = qrPalettes[q.paletteIndex];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'QR Studio',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                  ),
                ),
              ),
              IconCircle(
                Icons.restart_alt_rounded,
                onTap: () {
                  s.qr = QrConfig();
                  s.touch();
                  toast(
                    context,
                    'Reset to default style',
                    icon: Icons.restart_alt_rounded,
                  );
                },
              ),
              const SizedBox(width: 10),
              IconCircle(
                Icons.help_outline_rounded,
                onTap: () => toast(
                  context,
                  'Logo mode auto-uses max error correction so it always scans',
                  icon: Icons.verified_rounded,
                  color: VC.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Segment(
            items: const ['My QR', 'Styles', 'Frames'],
            index: tab,
            onChanged: (i) => setState(() => tab = i),
          ),
          const SizedBox(height: 16),
          // preview
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  pal.a.withValues(alpha: .22),
                  pal.b.withValues(alpha: .12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: c.border),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: MyQr(
                  key: ValueKey(
                    '${q.dots}${q.eyes}${q.paletteIndex}${q.showAvatar}${q.frame}${q.frameStyle}${q.frameText}${q.centerIcon}',
                  ),
                  size: 218,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (tab == 0) ..._myQr(context, s, c),
          if (tab == 1) ..._styles(context, s, c),
          if (tab == 2) ..._frames(context, s, c),
          const SizedBox(height: 20),
          GradBtn(
            'Export QR',
            icon: Icons.download_rounded,
            onTap: () => pushPage(context, const ExportPage()),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    BuildContext context,
    IconData icon,
    String t,
    bool v,
    ValueChanged<bool> f, {
    String? sub,
  }) => Box(
    pad: 14,
    margin: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        RoundIconBg(icon, context.c.accent, size: 40, radius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (sub != null)
                Text(sub, style: TextStyle(color: context.c.sub, fontSize: 12)),
            ],
          ),
        ),
        Switch(value: v, onChanged: f),
      ],
    ),
  );

  List<Widget> _myQr(BuildContext context, AppStore s, VC c) {
    final q = s.qr;
    return [
      const Text(
        'Colors',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      _paletteRow(context, s),
      const SizedBox(height: 18),
      _toggle(
        context,
        Icons.account_circle_rounded,
        'Show profile photo in center',
        q.showAvatar,
        (v) {
          q.showAvatar = v;
          s.touch();
        },
        sub: 'Error correction auto-set to H (30%)',
      ),
      _toggle(context, Icons.crop_free_rounded, 'Add brand frame', q.frame, (
        v,
      ) {
        q.frame = v;
        s.touch();
      }),
      if (q.showAvatar) ...[
        const SizedBox(height: 6),
        const Text(
          'Center logo',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final e in [
              ('avatar', 'Avatar', Icons.account_circle_rounded, false),
              ('instagram', 'Instagram', FontAwesomeIcons.instagram, true),
              ('monogram', 'Monogram', Icons.text_fields_rounded, false),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _choice(context, e.$3, e.$2, q.centerIcon == e.$1, () {
                    if (e.$4 && !s.pro) {
                      return proGate(
                        context,
                        'Platform logo in your QR centre',
                      );
                    }
                    q.centerIcon = e.$1;
                    s.touch();
                  }, pro: e.$4 && !s.pro),
                ),
              ),
          ],
        ),
      ],
    ];
  }

  Widget _choice(
    BuildContext context,
    Object i,
    String t,
    bool on,
    VoidCallback f, {
    bool pro = false,
  }) {
    final c = context.c;
    return Tap(
      onTap: f,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: on ? VC.violet.withValues(alpha: .16) : c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: on ? VC.violet : c.border,
            width: on ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                anyIcon(i, color: on ? c.accent : c.sub, size: 26),
                if (pro)
                  const Positioned(
                    right: -20,
                    top: -8,
                    child: Icon(Icons.lock_rounded, size: 13, color: VC.gold),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: on ? c.accent : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paletteRow(BuildContext context, AppStore s) {
    final c = context.c;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: qrPalettes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = qrPalettes[i];
          final on = s.qr.paletteIndex == i;
          final locked = p.neon && !s.pro;
          return Tap(
            onTap: () {
              if (locked) return proGate(context, 'Neon & dark QR presets');
              s.qr.paletteIndex = i;
              s.touch();
            },
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: on ? c.accent : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [p.a, p.b],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: locked
                        ? const Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : (on
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: c.sub,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _styles(BuildContext context, AppStore s, VC c) {
    final q = s.qr;
    final dotNames = {
      QrDots.classic: 'Classic',
      QrDots.rounded: 'Rounded',
      QrDots.dots: 'Dots',
      QrDots.soft: 'Liquid',
      QrDots.diamond: 'Diamond',
    };
    final eyeNames = {
      QrEyes.square: 'Square',
      QrEyes.rounded: 'Rounded',
      QrEyes.circle: 'Circle',
    };
    Widget mini(QrDots d, QrEyes e) => SizedBox(
      width: 44,
      height: 44,
      child: VibeQr(
        data: 'https://vibedrop.lk/u/x',
        cfg: QrConfig(
          dots: d,
          eyes: e,
          showAvatar: false,
          paletteIndex: q.paletteIndex,
          frame: false,
        ),
        me: s.me,
        size: 44,
        transparent: true,
      ),
    );
    return [
      const Text(
        'Dot style',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 98,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final e in dotNames.entries)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Tap(
                  onTap: () {
                    if ((e.key == QrDots.soft || e.key == QrDots.diamond) &&
                        !s.pro) {
                      return proGate(context, '${e.value} dot style');
                    }
                    q.dots = e.key;
                    s.touch();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 82,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: q.dots == e.key
                          ? VC.violet.withValues(alpha: .16)
                          : c.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: q.dots == e.key ? VC.violet : c.border,
                        width: q.dots == e.key ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              color: Colors.white,
                              child: mini(e.key, q.eyes),
                            ),
                            if ((e.key == QrDots.soft ||
                                    e.key == QrDots.diamond) &&
                                !s.pro)
                              const Positioned(
                                right: -4,
                                top: -4,
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: VC.gold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: q.dots == e.key ? c.accent : c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Eye style',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final e in eyeNames.entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Tap(
                  onTap: () {
                    q.eyes = e.key;
                    s.touch();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: q.eyes == e.key
                          ? VC.violet.withValues(alpha: .16)
                          : c.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: q.eyes == e.key ? VC.violet : c.border,
                        width: q.eyes == e.key ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          color: Colors.white,
                          child: mini(q.dots, e.key),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: q.eyes == e.key ? c.accent : c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      const Text(
        'Colors',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      _paletteRow(context, s),
    ];
  }

  List<Widget> _frames(BuildContext context, AppStore s, VC c) {
    final q = s.qr;
    return [
      _toggle(
        context,
        Icons.crop_free_rounded,
        'Show call-to-action frame',
        q.frame,
        (v) {
          q.frame = v;
          s.touch();
        },
      ),
      const SizedBox(height: 6),
      const Text(
        'Frame style',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < frameNames.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(frameNames[i]),
                  selected: q.frameStyle == i,
                  showCheckmark: false,
                  selectedColor: VC.violet,
                  backgroundColor: c.card,
                  side: BorderSide(color: c.border),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: q.frameStyle == i ? Colors.white : c.text,
                  ),
                  onSelected: (_) {
                    q.frameStyle = i;
                    q.frame = true;
                    s.touch();
                  },
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Call-to-action text',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        'English, Tamil or Sinhala',
        style: TextStyle(color: c.sub, fontSize: 13),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in frameTexts)
            ChoiceChip(
              label: Text(t),
              selected: q.frameText == t,
              showCheckmark: false,
              selectedColor: VC.violet,
              backgroundColor: c.card,
              side: BorderSide(color: c.border),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: q.frameText == t ? Colors.white : c.text,
              ),
              onSelected: (_) {
                q.frameText = t;
                txt.text = t;
                s.touch();
              },
            ),
        ],
      ),
      const SizedBox(height: 14),
      TextField(
        controller: txt,
        maxLength: 24,
        decoration: const InputDecoration(
          hintText: 'Custom text',
          prefixIcon: Icon(Icons.edit_rounded),
        ),
        onChanged: (v) {
          q.frameText = v.isEmpty ? 'Scan to connect' : v;
          s.touch();
        },
      ),
    ];
  }
}
