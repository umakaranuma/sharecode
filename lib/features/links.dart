import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

const avatarEmojis = [
  '',
  '😎',
  '🎨',
  '📸',
  '🎸',
  '🚀',
  '🌴',
  '🔥',
  '🐱',
  '⚡',
  '🎧',
  '🌸',
];

/// Photo picker (simulated): choose a style + emoji, or "upload".
Future<(int, String)?> pickAvatar(
  BuildContext context,
  String name,
  int seed,
  String emoji,
) {
  return sheet<(int, String)>(context, (ctx) {
    var s = seed;
    var e = emoji;
    return StatefulBuilder(
      builder: (ctx, set) {
        final c = ctx.c;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile picture',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Center(
                child: Avatar(
                  name: name.isEmpty ? 'You' : name,
                  seed: s,
                  emoji: e,
                  size: 104,
                  ring: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SoftBtn(
                      'Camera',
                      icon: Icons.photo_camera_rounded,
                      height: 48,
                      onTap: () => toast(
                        ctx,
                        'Camera opens on a real device — pick a style below',
                        icon: Icons.info_rounded,
                        color: VC.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SoftBtn(
                      'Gallery',
                      icon: Icons.photo_library_rounded,
                      height: 48,
                      onTap: () => toast(
                        ctx,
                        'Gallery picker + crop appears on device',
                        icon: Icons.info_rounded,
                        color: VC.gold,
                      ),
                    ),
                  ),
                ],
              ),
              const FormLabel('Colour style'),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => Tap(
                    onTap: () => set(() => s = i),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: s == i ? VC.violet : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Avatar(name: name, seed: i, size: 44),
                    ),
                  ),
                ),
              ),
              const FormLabel('Emoji avatar'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final x in avatarEmojis)
                    Tap(
                      onTap: () => set(() => e = x),
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.card2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: e == x ? VC.violet : c.border,
                            width: e == x ? 2 : 1,
                          ),
                        ),
                        child: x.isEmpty
                            ? Icon(Icons.abc_rounded, color: c.sub)
                            : Text(x, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              GradBtn(
                'Use this photo',
                onTap: () => Navigator.pop(ctx, (s, e)),
              ),
            ],
          ),
        );
      },
    );
  });
}

/// Add / edit a social link. Returns true if saved.
Future<void> editLinkSheet(
  BuildContext context, {
  SocialLink? link,
  String? presetPlatform,
  VoidCallback? onPro,
}) {
  final store = context.store;
  return sheet<void>(context, (ctx) {
    var plat = link?.platform ?? presetPlatform ?? 'instagram';
    final handle = TextEditingController(text: link?.handle ?? '');
    final greet = TextEditingController(
      text: link?.greeting ?? 'Hey! Scanned your QR 👋',
    );
    var modes = {
      ...(link?.modes ?? {ProfileMode.social, ProfileMode.work}),
    };
    String? err;
    return StatefulBuilder(
      builder: (ctx, set) {
        final c = ctx.c;
        final p = platformOf(plat);
        final groups = <String, List<Platform>>{};
        for (final x in platforms) {
          groups.putIfAbsent(x.group, () => []).add(x);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                link == null ? 'Add a link' : 'Edit link',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type just the username — we build the deep link.',
                style: TextStyle(color: c.sub),
              ),
              if (link == null)
                for (final g in groups.entries) ...[
                  FormLabel(g.key),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final x in g.value)
                        Tap(
                          onTap: () => set(() => plat = x.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                            decoration: BoxDecoration(
                              color: plat == x.id
                                  ? x.color.withValues(alpha: .18)
                                  : c.card2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: plat == x.id
                                    ? x.color
                                    : Colors.transparent,
                                width: 1.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PlatformBadge(x, size: 30),
                                const SizedBox(width: 8),
                                Text(
                                  x.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              const FormLabel('Username / number'),
              TextField(
                controller: handle,
                keyboardType: plat == 'whatsapp' || plat == 'viber'
                    ? TextInputType.phone
                    : TextInputType.text,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: p.hint,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: PlatformBadge(p, size: 30),
                  ),
                  prefixText: p.prefix == '@' ? '@' : p.prefix,
                  errorText: err,
                ),
              ),
              if (plat == 'whatsapp') ...[
                const FormLabel('Pre-filled greeting (optional)'),
                TextField(
                  controller: greet,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.waving_hand_rounded),
                  ),
                ),
              ],
              const FormLabel('Show this link in'),
              Row(
                children: [
                  for (final m in [ProfileMode.social, ProfileMode.work])
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(
                          m == ProfileMode.social
                              ? 'Chill / Social'
                              : 'Work / Campus',
                        ),
                        selected: modes.contains(m),
                        showCheckmark: false,
                        avatar: Icon(
                          m == ProfileMode.social
                              ? Icons.celebration_rounded
                              : Icons.work_rounded,
                          size: 16,
                          color: modes.contains(m) ? Colors.white : c.sub,
                        ),
                        selectedColor: VC.violet,
                        backgroundColor: c.card2,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: modes.contains(m) ? Colors.white : c.text,
                        ),
                        side: BorderSide.none,
                        onSelected: (v) =>
                            set(() => v ? modes.add(m) : modes.remove(m)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (p.id == 'whatsapp' && handle.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.card2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 18, color: VC.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'wa.me/94${handle.text.replaceAll(RegExp(r'\D'), '')}',
                          style: TextStyle(color: c.sub, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              GradBtn(
                link == null ? 'Add link' : 'Save changes',
                onTap: () {
                  if (handle.text.trim().isEmpty) {
                    set(
                      () => err =
                          'Enter a ${p.id == 'whatsapp' ? 'number' : 'username'}',
                    );
                    return;
                  }
                  if (link == null) {
                    store.addLink(
                      SocialLink(
                        id: 'l${DateTime.now().microsecondsSinceEpoch}',
                        platform: plat,
                        handle: handle.text.trim().replaceFirst('@', ''),
                        modes: modes.isEmpty ? {ProfileMode.social} : modes,
                        greeting: plat == 'whatsapp' ? greet.text : '',
                      ),
                    );
                  } else {
                    link
                      ..handle = handle.text.trim().replaceFirst('@', '')
                      ..modes = modes.isEmpty ? {ProfileMode.social} : modes
                      ..greeting = greet.text;
                    store.touch();
                  }
                  Navigator.pop(ctx);
                  toast(
                    context,
                    link == null ? '${p.name} added' : 'Link updated',
                  );
                },
              ),
              if (link != null) ...[
                const SizedBox(height: 10),
                SoftBtn(
                  'Delete link',
                  icon: Icons.delete_outline_rounded,
                  color: VC.red,
                  onTap: () async {
                    if (await confirm(
                      ctx,
                      'Delete ${p.name}?',
                      'Scanners will no longer see this link.',
                      ok: 'Delete',
                      danger: true,
                    )) {
                      store.removeLink(link.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }, full: true);
}
