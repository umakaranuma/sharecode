import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'links.dart';

class WizardPage extends StatefulWidget {
  const WizardPage({super.key});
  @override
  State<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends State<WizardPage> {
  int step = 0;
  final user = TextEditingController(),
      name = TextEditingController(),
      bio = TextEditingController();
  String? userMsg;
  bool? userOk;
  bool checking = false;
  Timer? deb;
  int avatarSeed = 0;
  String emoji = '';
  String city = 'Jaffna';
  final picked = <String, TextEditingController>{
    'instagram': TextEditingController(),
    'whatsapp': TextEditingController(),
  };
  final ctrl = PageController();
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final me = context.store.me;
    user.text = me.username;
    name.text = me.name;
    bio.text = me.bio;
    avatarSeed = me.avatarSeed;
    emoji = me.emoji;
    if (me.city.isNotEmpty) city = me.city;
    if (user.text.isNotEmpty) userOk = true;
    for (final l in me.links) {
      picked[l.platform]?.text = l.handle;
    }
  }

  @override
  void dispose() {
    deb?.cancel();
    super.dispose();
  }

  void onUser(String v) {
    deb?.cancel();
    final clean = v.toLowerCase();
    if (clean.isEmpty) {
      setState(() {
        userOk = null;
        userMsg = null;
        checking = false;
      });
      return;
    }
    if (!RegExp(r'^[a-z0-9_]*$').hasMatch(clean)) {
      setState(() {
        userOk = false;
        userMsg = 'Only letters, numbers and underscores';
        checking = false;
      });
      return;
    }
    if (clean.length < 3) {
      setState(() {
        userOk = false;
        userMsg = 'At least 3 characters';
        checking = false;
      });
      return;
    }
    setState(() => checking = true);
    deb = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final free = context.store.usernameFree(clean);
      setState(() {
        checking = false;
        userOk = free;
        userMsg = free ? '@$clean is available 🎉' : '@$clean is already taken';
      });
    });
  }

  bool get canNext => switch (step) {
    0 => userOk == true && !checking,
    1 => name.text.trim().isNotEmpty,
    _ => true,
  };

  void next() {
    final s = context.store;
    if (step == 0) {
      s.me.username = user.text.toLowerCase();
    } else if (step == 1) {
      s.me
        ..name = name.text.trim()
        ..bio = bio.text.trim().isEmpty ? 'New on VibeDrop ✨' : bio.text.trim()
        ..avatarSeed = avatarSeed
        ..emoji = emoji
        ..city = city;
    }
    if (step == 2) {
      picked.forEach((k, v) {
        if (v.text.trim().isNotEmpty) {
          s.me.links.removeWhere((l) => l.platform == k);
          s.me.links.insert(
            0,
            SocialLink(
              id: 'w$k',
              platform: k,
              handle: v.text.trim().replaceFirst('@', ''),
              modes: {ProfileMode.social, ProfileMode.work, ProfileMode.custom},
            ),
          );
        }
      });
      s.qrReady = true;
      s.touch();
      Navigator.pop(context);
      toast(
        context,
        'Your QR is live! Share it from Home 🎉',
        icon: Icons.qr_code_2_rounded,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => step++);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final titles = ['Claim your handle', 'Make it yours', 'Add your top links'];
    final subs = [
      'This becomes your permanent link: vibedrop.lk/u/handle',
      'Add a photo, name and a one-line bio.',
      'Add 2 links so your QR is live in seconds.',
    ];
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Glow(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => step == 0
                          ? Navigator.pop(context)
                          : setState(() => step--),
                      icon: Icon(
                        step == 0
                            ? Icons.close_rounded
                            : Icons.arrow_back_rounded,
                        color: c.text,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 6,
                                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                decoration: BoxDecoration(
                                  gradient: i <= step ? VC.brand : null,
                                  color: i <= step ? null : c.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${step + 1}/3',
                      style: TextStyle(
                        color: c.sub,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titles[step],
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subs[step],
                        style: TextStyle(
                          color: c.sub,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      [_stepUser(c), _stepProfile(c), _stepLinks(c)][step],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: GradBtn(
                  step == 2 ? 'Generate my QR' : 'Continue',
                  icon: step == 2
                      ? Icons.qr_code_2_rounded
                      : Icons.arrow_forward_rounded,
                  onTap: canNext ? next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepUser(VC c) {
    final suggestions = ['kavi_dev', 'kavishan.lk', 'its_kavi'];
    final col = userOk == null ? c.sub : (userOk! ? VC.green : VC.red);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: user,
          onChanged: onUser,
          autocorrect: false,
          inputFormatters: [LengthLimitingTextInputFormatter(24)],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: 'username',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 6),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '@',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: c.accent,
                  ),
                ),
              ),
            ),
            suffixIcon: checking
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                : (userOk == null
                      ? null
                      : Icon(
                          userOk!
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: col,
                        )),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            userMsg ?? ' ',
            key: ValueKey(userMsg),
            style: TextStyle(color: col, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 22),
        Box(
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: VC.violet),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'vibedrop.lk/u/${user.text.isEmpty ? 'yourname' : user.text.toLowerCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Need ideas?',
          style: TextStyle(
            color: c.sub,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in suggestions)
              Tap(
                onTap: () {
                  user.text = s;
                  onUser(s);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    '@$s',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepProfile(VC c) {
    final cities = ['Jaffna', 'Colombo', 'Kandy', 'Galle', 'UoJ', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Tap(
            onTap: () async {
              final r = await pickAvatar(context, name.text, avatarSeed, emoji);
              if (r != null) {
                setState(() {
                  avatarSeed = r.$1;
                  emoji = r.$2;
                });
              }
            },
            child: Stack(
              children: [
                Avatar(
                  name: name.text.isEmpty ? 'You' : name.text,
                  seed: avatarSeed,
                  size: 112,
                  emoji: emoji,
                  ring: true,
                ),
                Positioned(
                  right: 0,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: VC.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const FormLabel('Display name'),
        TextField(
          controller: name,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Kavishan Tharmaraj / கவிஷன் / කවිශාන්',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const FormLabel('One-line bio'),
        TextField(
          controller: bio,
          maxLength: 150,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Designer • Coffee lover • தமிழ் / English / සිංහල',
          ),
        ),
        const FormLabel('City / campus badge'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in cities)
              ChoiceChip(
                label: Text(x),
                selected: city == x,
                showCheckmark: false,
                selectedColor: VC.violet,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: city == x ? Colors.white : c.text,
                ),
                backgroundColor: c.card,
                side: BorderSide(color: c.border),
                onSelected: (_) => setState(() => city = x),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepLinks(VC c) {
    return Column(
      children: [
        for (final e in picked.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Box(
              pad: 14,
              child: Row(
                children: [
                  PlatformBadge(platformOf(e.key), size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      onChanged: (_) => setState(() {}),
                      keyboardType: e.key == 'whatsapp'
                          ? TextInputType.phone
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: platformOf(e.key).name,
                        hintText: platformOf(e.key).hint,
                        prefixText: platformOf(e.key).prefix == '@'
                            ? '@'
                            : platformOf(e.key).prefix,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (e.value.text.trim().isNotEmpty)
                    const Icon(Icons.check_circle_rounded, color: VC.green),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Add more platforms',
              style: TextStyle(
                color: c.sub,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final p in platforms)
              if (!picked.containsKey(p.id))
                Tap(
                  onTap: () =>
                      setState(() => picked[p.id] = TextEditingController()),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlatformBadge(p, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.add_rounded, size: 16, color: c.accent),
                      ],
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VC.violet.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.tips_and_updates_rounded,
                color: VC.violet,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Just type your username — we build the deep link for you. You can add more later.',
                  style: TextStyle(color: c.sub, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
