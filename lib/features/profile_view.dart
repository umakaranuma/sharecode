import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'chat.dart';
import 'home.dart';

/// Everything the visitor-facing profile needs, independent of the source.
class ViewData {
  ViewData({
    required this.name,
    required this.handle,
    required this.bio,
    required this.city,
    required this.seed,
    required this.coverSeed,
    required this.links,
    this.emoji = '',
    this.campus = '',
    this.ghost = false,
    this.pin,
    this.question,
    this.answer,
    this.isMe = false,
    this.mode = ProfileMode.social,
    this.gallery = const [],
    this.phone = '',
    this.email = '',
    this.contact,
  });
  final String name, handle, bio, city, campus, emoji, phone, email;
  final int seed, coverSeed;
  final List<List<String>> links; // [platform, handle]
  final bool ghost, isMe;
  final String? pin, question, answer;
  final ProfileMode mode;
  final List<int> gallery;
  final Contact? contact;

  bool get locked => pin != null || question != null;

  factory ViewData.fromMe(AppStore s) => ViewData(
    name: s.me.name,
    handle: s.me.username,
    bio: s.me.bio,
    city: s.me.city,
    campus: s.me.campus,
    seed: s.me.avatarSeed,
    coverSeed: s.me.coverSeed,
    emoji: s.me.emoji,
    links: [
      for (final l in s.visibleLinks) [l.platform, l.handle],
    ],
    ghost: s.ghost,
    pin: s.lockOn && s.lockIsPin ? s.lockPin : null,
    question: s.lockOn && !s.lockIsPin ? s.lockQuestion : null,
    answer: s.lockOn && !s.lockIsPin ? s.lockAnswer : null,
    isMe: true,
    mode: s.mode,
    gallery: s.me.gallery,
    phone: s.mode == ProfileMode.work ? s.me.phone : '',
    email: s.mode == ProfileMode.work ? s.me.email : '',
  );

  factory ViewData.fromContact(Contact c) => ViewData(
    name: c.name,
    handle: c.handle,
    bio: c.bio,
    city: c.city,
    seed: c.seed,
    coverSeed: c.seed + 2,
    emoji: c.emoji,
    links: c.links,
    ghost: c.ghost,
    pin: c.pin,
    question: c.question,
    answer: c.answer,
    mode: c.mode,
    gallery: [c.seed + 1, c.seed + 4, c.seed + 6],
    contact: c,
  );
}

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({
    super.key,
    required this.data,
    this.preview = false,
    this.fromScan = false,
  });
  final ViewData data;
  final bool preview, fromScan;
  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  bool unlocked = false;
  bool web = false;
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  ViewData get d => widget.data;

  @override
  void initState() {
    super.initState();
    if (widget.fromScan && d.contact != null) {
      // Scanning in the app auto-saves into "My Wallet".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!d.ghost && mounted) context.store.saveToWallet(d.contact!);
      });
    }
  }

  void openLink(List<String> l) {
    final p = platformOf(l[0]);
    final s = context.store;
    if (d.isMe) {
      final i = s.me.links.indexWhere((e) => e.platform == l[0]);
      if (i >= 0) s.me.links[i].clicks++;
      s.totalClicks++;
      s.touch();
    }
    sheet(context, (ctx) => _OpenLinkSheet(p: p, handle: l[1], web: web));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.store;
    final canSee = !d.ghost && (!d.locked || unlocked);
    final waved = s.waved.contains(d.handle);
    final mutual = s.waves.any(
      (w) => w.handle == d.handle && w.status == WaveStatus.mutual,
    );
    return Scaffold(
      body: Glow(
        child: Stack(
          children: [
            CustomScrollView(
              controller: scroll,
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                    child: d.ghost ? _ghost(c) : _body(context, canSee),
                  ),
                ),
              ],
            ),
            // top bar scrim (fades in while scrolling)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: scroll,
                  builder: (_, _) {
                    final t = scroll.hasClients
                        ? (scroll.offset / 140).clamp(0.0, 1.0)
                        : 0.0;
                    return Container(
                      height: MediaQuery.paddingOf(context).top + 62,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            c.bg.withValues(alpha: .35 + .65 * t),
                            c.bg.withValues(alpha: t * .94),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(
                  children: [
                    _glass(
                      Icons.arrow_back_rounded,
                      () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Tap(
                        onTap: () => copyText(
                          context,
                          'https://vibedrop.lk/u/${d.handle}',
                          'Link copied',
                        ),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'vibedrop.lk/u/${d.handle}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _glass(Icons.more_horiz_rounded, () => _menu(context)),
                  ],
                ),
              ),
            ),
            // bottom bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (web)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: VC.brand,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const VLogo(size: 30, word: false),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Get VibeDrop to Wave & chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Tap(
                            onTap: () => toast(
                              context,
                              'Opens the App Store / Play Store',
                              icon: Icons.download_rounded,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Install',
                                style: TextStyle(
                                  color: VC.violet,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!d.ghost)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                      decoration: BoxDecoration(
                        color: c.bg.withValues(alpha: .94),
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: GradBtn(
                                'Save Contact',
                                icon: Icons.download_rounded,
                                height: 52,
                                onTap: () => _saveContact(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: d.isMe
                                  ? SoftBtn(
                                      'Share',
                                      icon: Icons.ios_share_rounded,
                                      height: 52,
                                      onTap: () => copyText(
                                        context,
                                        'https://vibedrop.lk/u/${d.handle}',
                                        'Link copied',
                                      ),
                                    )
                                  : mutual
                                  ? SoftBtn(
                                      'Chat',
                                      icon: Icons.chat_bubble_rounded,
                                      height: 52,
                                      color: VC.green,
                                      onTap: () => pushPage(
                                        context,
                                        ChatPage(
                                          handle: d.handle,
                                          name: d.name,
                                          seed: d.seed,
                                        ),
                                      ),
                                    )
                                  : SoftBtn(
                                      waved ? 'Waved ✓' : 'Wave 👋',
                                      height: 52,
                                      color: waved ? c.sub : VC.orange,
                                      onTap: waved
                                          ? null
                                          : () => _wave(context),
                                    ),
                            ),
                          ],
                        ),
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

  Widget _glass(IconData i, VoidCallback f) => Tap(
    onTap: f,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        shape: BoxShape.circle,
      ),
      child: Icon(i, color: Colors.white, size: 22),
    ),
  );

  Widget _header(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 210,
            child: Scenic(seed: d.coverSeed),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 150,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, c.bg],
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 150,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
              child: Avatar(
                name: d.name,
                seed: d.seed,
                emoji: d.emoji,
                size: 112,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 226,
            child: Segment2(
              web: web,
              onChanged: (v) => setState(() => web = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ghost(VC c) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VC.violet.withValues(alpha: .14),
          ),
          child: const Icon(
            Icons.visibility_off_rounded,
            size: 54,
            color: VC.violet,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'This profile is currently private',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          '${d.name.split(' ').first} has paused sharing. Check back later.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.sub, height: 1.4),
        ),
        if (d.isMe) ...[
          const SizedBox(height: 24),
          SoftBtn(
            'Turn off Ghost mode',
            icon: Icons.visibility_rounded,
            onTap: () {
              context.store.setGhost(false);
              toast(context, 'Ghost mode off — you\'re visible again');
            },
          ),
        ],
      ],
    ),
  );

  Widget _body(BuildContext context, bool canSee) {
    final c = context.c;
    final s = context.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                d.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.verified_rounded, color: VC.violet, size: 22),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '@${d.handle}',
          style: TextStyle(color: c.sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Pill(
          '${modeName(d.mode)} mode',
          icon: modeIcon(d.mode),
          color: modeColor(d.mode),
        ),
        const SizedBox(height: 12),
        Text(d.bio, style: const TextStyle(fontSize: 15.5, height: 1.45)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (d.city.isNotEmpty)
              Pill(
                d.city.contains(',') ? d.city : '${d.city}, Sri Lanka',
                icon: Icons.place_rounded,
                color: c.sub,
              ),
            if (d.campus.isNotEmpty)
              Pill(d.campus, icon: Icons.school_rounded, color: c.sub),
            if (s.inWallet(d.handle) && !d.isMe)
              const Pill(
                'In your wallet',
                icon: Icons.bookmark_rounded,
                color: VC.green,
              ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 96,
          child: Row(
            children: [
              for (var i = 0; i < min(3, d.gallery.length); i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    child: Tap(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: const EdgeInsets.all(20),
                          child: AspectRatio(
                            aspectRatio: .8,
                            child: Scenic(seed: d.gallery[i], radius: 24),
                          ),
                        ),
                      ),
                      child: Scenic(seed: d.gallery[i], radius: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (!canSee)
          _lockCard(context)
        else ...[
          if (d.phone.isNotEmpty || d.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Box(
                pad: 4,
                child: Column(
                  children: [
                    if (d.phone.isNotEmpty)
                      RowTile(
                        icon: Icons.phone_rounded,
                        title: d.phone,
                        sub: 'Mobile',
                        color: VC.green,
                        trailing: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: c.sub,
                        ),
                        onTap: () => copyText(context, d.phone),
                      ),
                    if (d.phone.isNotEmpty && d.email.isNotEmpty)
                      const Divider1(),
                    if (d.email.isNotEmpty)
                      RowTile(
                        icon: Icons.mail_rounded,
                        title: d.email,
                        sub: 'Email',
                        color: VC.blue,
                        trailing: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: c.sub,
                        ),
                        onTap: () => copyText(context, d.email),
                      ),
                  ],
                ),
              ),
            ),
          if (d.links.isEmpty)
            Box(
              child: Center(
                child: Text(
                  'No links visible in this mode',
                  style: TextStyle(color: c.sub),
                ),
              ),
            )
          else
            for (var i = 0; i < d.links.length; i++)
              Reveal(
                i: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Box(
                    pad: 12,
                    onTap: () => openLink(d.links[i]),
                    child: Row(
                      children: [
                        PlatformBadge(platformOf(d.links[i][0]), size: 46),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                platformOf(d.links[i][0]).name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _disp(d.links[i]),
                                style: TextStyle(color: c.sub, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.north_east_rounded, color: c.sub, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  String _disp(List<String> l) {
    final p = platformOf(l[0]);
    return p.prefix == '@' ? '@${l[1]}' : '${p.prefix}${l[1]}';
  }

  // ───────── lock UI ─────────
  Widget _lockCard(BuildContext context) => _LockCard(
    d: d,
    onUnlock: () {
      setState(() => unlocked = true);
      toast(
        context,
        'Unlocked! Links revealed 🔓',
        icon: Icons.lock_open_rounded,
      );
    },
  );

  void _menu(BuildContext context) {
    final s = context.store;
    sheet(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RowTile(
              icon: Icons.link_rounded,
              title: 'Copy profile link',
              onTap: () {
                Navigator.pop(ctx);
                copyText(
                  context,
                  'https://vibedrop.lk/u/${d.handle}',
                  'Link copied',
                );
              },
            ),
            RowTile(
              icon: Icons.contact_page_rounded,
              title: 'Save contact (.vcf)',
              color: VC.green,
              onTap: () {
                Navigator.pop(ctx);
                _saveContact(context);
              },
            ),
            if (!d.isMe) ...[
              RowTile(
                icon: Icons.flag_rounded,
                title: s.reported.contains(d.handle)
                    ? 'Reported'
                    : 'Report profile',
                sub: 'Abuse, spam or impersonation',
                color: VC.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  _report(context);
                },
              ),
              RowTile(
                icon: Icons.block_rounded,
                title: s.blocked.contains(d.handle)
                    ? 'Unblock user'
                    : 'Block user',
                danger: true,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (s.blocked.contains(d.handle)) {
                    s.unblock(d.handle);
                    toast(context, 'Unblocked');
                  } else if (await confirm(
                    context,
                    'Block @${d.handle}?',
                    'They won\'t be able to send you waves.',
                    ok: 'Block',
                    danger: true,
                  )) {
                    s.block(d.handle);
                    if (context.mounted) {
                      toast(
                        context,
                        'Blocked @${d.handle}',
                        icon: Icons.block_rounded,
                        color: VC.red,
                      );
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _report(BuildContext context) {
    final s = context.store;
    sheet(context, (ctx) {
      var reason = '';
      return StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report this profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              RadioGroup<String>(
                groupValue: reason,
                onChanged: (v) => set(() => reason = v!),
                child: Column(
                  children: [
                    for (final r in [
                      'Impersonation / fake profile',
                      'Abusive or harassing',
                      'Spam or scam',
                      'Inappropriate photos',
                      'Something else',
                    ])
                      RadioListTile<String>(
                        value: r,
                        activeColor: VC.violet,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          r,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GradBtn(
                'Submit report',
                onTap: reason.isEmpty
                    ? null
                    : () {
                        s.report(d.handle);
                        Navigator.pop(ctx);
                        toast(
                          context,
                          'Thanks — our team will review it',
                          icon: Icons.flag_rounded,
                        );
                      },
              ),
            ],
          ),
        ),
      );
    });
  }

  void _saveContact(BuildContext context) {
    final s = context.store;
    sheet(context, (ctx) {
      final c = ctx.c;
      final phone = d.phone.isNotEmpty
          ? d.phone
          : (d.links
                    .where((l) => l[0] == 'whatsapp')
                    .map((l) => '+94 ${l[1]}')
                    .firstOrNull ??
                '—');
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save to Contacts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Box(
              child: Column(
                children: [
                  Avatar(name: d.name, seed: d.seed, emoji: d.emoji, size: 64),
                  const SizedBox(height: 10),
                  Text(
                    d.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _vrow(c, Icons.phone_rounded, phone),
                  _vrow(
                    c,
                    Icons.alternate_email_rounded,
                    d.email.isEmpty ? '@${d.handle}' : d.email,
                  ),
                  _vrow(
                    c,
                    Icons.place_rounded,
                    d.city.isEmpty ? 'Sri Lanka' : d.city,
                  ),
                  _vrow(c, Icons.attach_file_rounded, '${d.handle}.vcf • 1 KB'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradBtn(
              'Download .vcf',
              icon: Icons.download_rounded,
              onTap: () {
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                if (d.contact != null) s.saveToWallet(d.contact!);
                toast(
                  context,
                  '${d.name} saved to contacts',
                  icon: Icons.contact_page_rounded,
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _vrow(VC c, IconData i, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(i, size: 18, color: c.sub),
        const SizedBox(width: 12),
        Expanded(
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  void _wave(BuildContext context) {
    final s = context.store;
    final note = TextEditingController();
    final chips = [
      'Saw you at Cargills Square!',
      'Loved your playlist 🎧',
      'Let\'s connect!',
      'Nice meeting you 😊',
    ];
    sheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final c = ctx.c;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Wave at ${d.name.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'They get a notification. If they wave back, you both unlock chat.',
                  style: TextStyle(color: c.sub, height: 1.4),
                ),
                const FormLabel('Add a note (optional)'),
                TextField(
                  controller: note,
                  maxLength: 60,
                  onChanged: (_) => set(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Saw you at Cargills Square!',
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final x in chips)
                      ActionChip(
                        label: Text(
                          x,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: c.card2,
                        side: BorderSide.none,
                        onPressed: () => set(() => note.text = x),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                GradBtn(
                  'Send Wave',
                  icon: Icons.waving_hand_rounded,
                  gradient: const LinearGradient(colors: [VC.orange, VC.pink]),
                  onTap: () {
                    final contact =
                        d.contact ??
                        Contact(
                          name: d.name,
                          handle: d.handle,
                          bio: d.bio,
                          city: d.city,
                          seed: d.seed,
                        );
                    s.sendWave(
                      contact,
                      note.text.trim().isEmpty
                          ? 'Waved at you 👋'
                          : note.text.trim(),
                    );
                    Navigator.pop(ctx);
                    toast(
                      context,
                      'Wave sent to ${d.name.split(' ').first} 👋',
                      icon: Icons.waving_hand_rounded,
                      color: VC.orange,
                    );
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

class Segment2 extends StatelessWidget {
  const Segment2({super.key, required this.web, required this.onChanged});
  final bool web;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget b(String t, IconData i, bool on, VoidCallback f) => GestureDetector(
      onTap: f,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? VC.violet : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            Icon(i, size: 14, color: on ? Colors.white : c.sub),
            const SizedBox(width: 4),
            Text(
              t,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: on ? Colors.white : c.sub,
              ),
            ),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          b('In app', Icons.phone_iphone_rounded, !web, () => onChanged(false)),
          b('Web', Icons.language_rounded, web, () => onChanged(true)),
        ],
      ),
    );
  }
}

class _OpenLinkSheet extends StatelessWidget {
  const _OpenLinkSheet({
    required this.p,
    required this.handle,
    required this.web,
  });
  final Platform p;
  final String handle;
  final bool web;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final scheme = switch (p.id) {
      'instagram' => 'instagram://user?username=$handle',
      'whatsapp' => 'https://wa.me/94${handle.replaceAll(RegExp(r'\D'), '')}',
      'spotify' => 'spotify://user/$handle',
      _ => 'https://${p.id}.com/$handle',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformBadge(p, size: 72),
          const SizedBox(height: 16),
          Text(
            'Open ${p.name}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            web
                ? 'Opens in your browser'
                : 'Opens the ${p.name} app, falls back to web',
            style: TextStyle(color: c.sub),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.card2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              scheme,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.sub, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 18),
          GradBtn(
            'Open ${p.name}',
            icon: Icons.north_east_rounded,
            onTap: () {
              Navigator.pop(context);
              toast(
                context,
                'Launching ${p.name}…',
                icon: Icons.rocket_launch_rounded,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LockCard extends StatefulWidget {
  const _LockCard({required this.d, required this.onUnlock});
  final ViewData d;
  final VoidCallback onUnlock;
  @override
  State<_LockCard> createState() => _LockCardState();
}

class _LockCardState extends State<_LockCard>
    with SingleTickerProviderStateMixin {
  String pin = '';
  final ans = TextEditingController();
  bool wrong = false;
  late final AnimationController shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    shake.dispose();
    super.dispose();
  }

  void fail() {
    HapticFeedback.heavyImpact();
    shake.forward(from: 0);
    setState(() {
      wrong = true;
      pin = '';
    });
  }

  void press(String k) {
    setState(() {
      wrong = false;
      if (k == '<') {
        if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
      } else if (pin.length < 4) {
        pin += k;
      }
    });
    if (pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        pin == widget.d.pin ? widget.onUnlock() : fail();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isPin = widget.d.pin != null;
    return AnimatedBuilder(
      animation: shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(sin(shake.value * pi * 6) * 10 * (1 - shake.value), 0),
        child: child,
      ),
      child: Box(
        pad: 20,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: VC.violet.withValues(alpha: .15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: VC.violet, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              isPin ? 'Links are PIN locked' : 'Answer to unlock',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              isPin
                  ? 'Enter the 4-digit PIN ${widget.d.name.split(' ').first} shared with you.'
                  : widget.d.question!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.sub,
                height: 1.4,
                fontWeight: isPin ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            if (isPin) ...[
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
                            ? (wrong ? VC.red : VC.violet)
                            : Colors.transparent,
                        border: Border.all(
                          color: wrong
                              ? VC.red
                              : (i < pin.length ? VC.violet : c.sub),
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 22,
                child: Text(
                  wrong
                      ? 'Wrong PIN — try again'
                      : (widget.d.isMe
                            ? 'Hint: your PIN'
                            : 'Demo PIN: ${widget.d.pin}'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: wrong ? VC.red : c.sub,
                  ),
                ),
              ),
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
                            ? const SizedBox(height: 56)
                            : Tap(
                                onTap: () => press(k),
                                child: SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: k == '<'
                                        ? const Icon(Icons.backspace_outlined)
                                        : Text(
                                            k,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
            ] else ...[
              TextField(
                controller: ans,
                onChanged: (_) => setState(() => wrong = false),
                decoration: InputDecoration(
                  hintText: 'Your answer',
                  errorText: wrong ? 'Not quite — try again' : null,
                  prefixIcon: const Icon(Icons.psychology_alt_rounded),
                ),
              ),
              const SizedBox(height: 14),
              GradBtn(
                'Unlock',
                onTap: () {
                  if (ans.text.trim().toLowerCase() ==
                      (widget.d.answer ?? '').toLowerCase()) {
                    widget.onUnlock();
                  } else {
                    fail();
                  }
                },
              ),
              const SizedBox(height: 6),
              Text(
                widget.d.isMe
                    ? 'Hint: your answer is "${widget.d.answer}"'
                    : 'Demo answer: ${widget.d.answer}',
                style: TextStyle(color: c.sub, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
