import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'home.dart';
import 'profile_view.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    Widget modeCard(ProfileMode m, String desc) {
      final on = s.mode == m && !s.ghost;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Box(
          pad: 16,
          color: on ? VC.violet.withValues(alpha: c.dark ? .16 : .08) : null,
          onTap: () {
            s.setMode(m);
            if (s.ghost) s.setGhost(false);
            if (m == ProfileMode.custom) _customSheet(context);
          },
          child: Row(
            children: [
              RoundIconBg(modeIcon(m), modeColor(m), size: 50, radius: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          modeName(m),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (on)
                          const Pill('Active', color: VC.green, filled: true),
                        
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        color: c.sub,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                on
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: on ? VC.violet : c.sub,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Modes'),
        actions: [
          IconButton(
            tooltip: 'See what scanners see',
            onPressed: () => pushPage(
              context,
              PublicProfilePage(data: ViewData.fromMe(s), preview: true),
            ),
            icon: const Icon(Icons.visibility_rounded),
          ),
        ],
      ),
      body: Glow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
          children: [
            const SectionTitle(
              'Profile modes',
              sub: 'Control what others see when they scan your QR.',
            ),
            modeCard(
              ProfileMode.social,
              'Show Instagram, Snapchat, TikTok, Spotify and photos only.',
            ),
            modeCard(
              ProfileMode.work,
              'Show phone, WhatsApp, email, LinkedIn and portfolio.',
            ),
            modeCard(
              ProfileMode.custom,
              'Choose exactly which links are visible to others.',
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: c.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${s.visibleLinks.length} of ${s.me.links.length} links are visible right now. Your QR never changes.',
                      style: TextStyle(color: c.sub, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Privacy & Safety Shield'),
            Box(
              pad: 16,
              child: Column(
                children: [
                  RowTile(
                    icon: Icons.visibility_off_rounded,
                    title: 'Ghost Mode (Pause Profile)',
                    sub:
                        'Temporarily disable your QR link. Scanners see “This profile is currently private”.',
                    color: c.accent,
                    trailing: Switch(
                      value: s.ghost,
                      onChanged: (v) {
                        s.setGhost(v);
                        toast(
                          context,
                          v
                              ? 'Ghost mode on — you\'re hidden'
                              : 'Ghost mode off',
                          icon: Icons.visibility_off_rounded,
                        );
                      },
                    ),
                  ),
                  const Divider1(),
                  RowTile(
                    icon: Icons.lock_rounded,
                    title: 'Secret Question / PIN Lock',
                    sub:
                        'Require a riddle answer or 4-digit PIN to view your links.',
                    color: VC.gold,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        const SizedBox(width: 6),
                        Switch(
                          value: s.lockOn,
                          onChanged: (v) {
                            s.lockOn = v;
                            s.touch();
                          },
                        ),
                      ],
                    ),
                  ),
                  if (s.lockOn) ...[
                    const SizedBox(height: 8),
                    Segment(
                      items: const ['PIN (4-digit)', 'Secret Question'],
                      index: s.lockIsPin ? 0 : 1,
                      onChanged: (i) {
                        s.lockIsPin = i == 0;
                        s.touch();
                      },
                    ),
                    const SizedBox(height: 14),
                    if (s.lockIsPin)
                      Tap(
                        onTap: () => _pinSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: c.card2,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(
                                s.lockPin.isEmpty
                                    ? 'Tap to set a PIN'
                                    : '● ● ● ●',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                  color: s.lockPin.isEmpty ? c.sub : c.text,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.edit_rounded, size: 18, color: c.sub),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      _QaField(
                        initial: s.lockQuestion,
                        label: 'Question',
                        icon: Icons.help_outline_rounded,
                        onChanged: (v) => s.lockQuestion = v,
                      ),
                      const SizedBox(height: 10),
                      _QaField(
                        initial: s.lockAnswer,
                        label: 'Answer',
                        icon: Icons.key_rounded,
                        onChanged: (v) => s.lockAnswer = v,
                      ),
                    ],
                    const SizedBox(height: 12),
                    SoftBtn(
                      'Test as a scanner',
                      icon: Icons.play_arrow_rounded,
                      height: 46,
                      onTap: () => pushPage(
                        context,
                        PublicProfilePage(
                          data: ViewData.fromMe(s),
                          preview: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Box(
              pad: 16,
              child: Column(
                children: [
                  RowTile(
                    icon: Icons.timer_rounded,
                    title: 'Auto-expiring burner link',
                    sub: s.tempLinkUntil == null
                        ? 'A 24-hour QR for parties & events. Self-destructs automatically.'
                        : 'Active — expires in ${s.tempLinkUntil!.difference(DateTime.now()).inHours}h',
                    color: VC.orange,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        const SizedBox(width: 6),
                        Switch(
                          value: s.tempLinkUntil != null,
                          onChanged: (v) {
                            v ? s.startTempLink() : s.endTempLink();
                            toast(
                              context,
                              v
                                  ? '24-hour burner link created'
                                  : 'Burner link ended',
                              icon: Icons.timer_rounded,
                              color: VC.orange,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (s.tempLinkUntil != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.card2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'vibedrop.lk/t/${s.me.username}-x8f2',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => copyText(
                              context,
                              'https://vibedrop.lk/t/${s.me.username}-x8f2',
                            ),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: c.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SectionTitle('Report & block'),
            Box(
              pad: 16,
              child: Column(
                children: [
                  RowTile(
                    icon: Icons.block_rounded,
                    title: 'Blocked users',
                    sub: s.blocked.isEmpty
                        ? 'No one blocked'
                        : '${s.blocked.length} blocked',
                    color: VC.red,
                    onTap: () => _blocked(context),
                  ),
                  const Divider1(),
                  RowTile(
                    icon: Icons.location_city_rounded,
                    title: 'Show my city in scan stats',
                    sub: 'Approximate city only',
                    trailing: Switch(
                      value: s.showCity,
                      onChanged: (v) {
                        s.showCity = v;
                        s.touch();
                      },
                    ),
                  ),
                  const Divider1(),
                  RowTile(
                    icon: Icons.waving_hand_rounded,
                    title: 'Allow waves from anyone',
                    sub: 'Off = only people with your PIN',
                    color: VC.orange,
                    trailing: Switch(
                      value: s.discoverable,
                      onChanged: (v) {
                        s.discoverable = v;
                        s.touch();
                      },
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

  void _blocked(BuildContext context) {
    final s = context.store;
    sheet(
      context,
      (ctx) => ListenableBuilder(
        listenable: s,
        builder: (_, _) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blocked users',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (s.blocked.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Nobody blocked 🎉',
                      style: TextStyle(color: ctx.c.sub),
                    ),
                  ),
                ),
              for (final b in s.blocked.toList())
                RowTile(
                  icon: Icons.person_off_rounded,
                  title: b.startsWith('Guest') ? b : '@$b',
                  color: VC.red,
                  trailing: TextButton(
                    onPressed: () => s.unblock(b),
                    child: const Text('Unblock'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _pinSheet(BuildContext context) {
    final s = context.store;
    var pin = '';
    sheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final c = ctx.c;
          void press(String k) {
            set(() {
              if (k == '<') {
                if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
              } else if (pin.length < 4) {
                pin += k;
              }
            });
            if (pin.length == 4) {
              HapticFeedback.mediumImpact();
              s.lockPin = pin;
              s.touch();
              Future.delayed(const Duration(milliseconds: 250), () {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  toast(context, 'PIN saved', icon: Icons.lock_rounded);
                }
              });
            }
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set a 4-digit PIN',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share it only with people you trust.',
                  style: TextStyle(color: c.sub),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < pin.length
                              ? VC.violet
                              : Colors.transparent,
                          border: Border.all(
                            color: i < pin.length ? VC.violet : c.sub,
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                for (final row in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['', '0', '<'],
                ])
                  Row(
                    children: [
                      for (final k in row)
                        Expanded(
                          child: k.isEmpty
                              ? const SizedBox(height: 58)
                              : Tap(
                                  onTap: () => press(k),
                                  child: SizedBox(
                                    height: 58,
                                    child: Center(
                                      child: k == '<'
                                          ? const Icon(Icons.backspace_outlined)
                                          : Text(
                                              k,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _customSheet(BuildContext context) {
    final s = context.store;
    sheet(
      context,
      (ctx) => ListenableBuilder(
        listenable: s,
        builder: (_, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Custom visibility',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                'Pick the links scanners can see in Custom mode.',
                style: TextStyle(color: ctx.c.sub),
              ),
              const SizedBox(height: 10),
              for (final l in s.me.links)
                RowTile(
                  icon: l.meta.icon,
                  title: l.meta.name,
                  sub: l.display,
                  color: l.meta.color,
                  trailing: Switch(
                    value: l.modes.contains(ProfileMode.custom),
                    onChanged: (v) {
                      v
                          ? l.modes.add(ProfileMode.custom)
                          : l.modes.remove(ProfileMode.custom);
                      s.touch();
                    },
                  ),
                ),
              const SizedBox(height: 10),
              GradBtn('Done', onTap: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QaField extends StatelessWidget {
  const _QaField({
    required this.initial,
    required this.label,
    required this.icon,
    required this.onChanged,
  });
  final String initial, label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initial,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );
}
