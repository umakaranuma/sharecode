import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum ProfileMode { social, work, custom }

enum Tier { free, pro }

/// Social / contact platforms supported by the link builder.
class Platform {
  const Platform(
    this.id,
    this.name,
    this.icon,
    this.color,
    this.group, {
    this.prefix = '@',
    this.hint = 'username',
  });
  final String id, name, group, prefix, hint;
  final FaIconData icon;
  final Color color;
}

const platforms = <Platform>[
  Platform(
    'instagram',
    'Instagram',
    FontAwesomeIcons.instagram,
    Color(0xFFE1306C),
    'Social',
    hint: 'kavishan_99',
  ),
  Platform(
    'snapchat',
    'Snapchat',
    FontAwesomeIcons.snapchat,
    Color(0xFFFFFC00),
    'Social',
    hint: 'kavi.snap',
  ),
  Platform(
    'tiktok',
    'TikTok',
    FontAwesomeIcons.tiktok,
    Color(0xFF000000),
    'Social',
    hint: 'kavi.tok',
  ),
  Platform(
    'facebook',
    'Facebook',
    FontAwesomeIcons.facebookF,
    Color(0xFF1877F2),
    'Social',
    prefix: 'fb.com/',
    hint: 'kavishan.t',
  ),
  Platform(
    'x',
    'X (Twitter)',
    FontAwesomeIcons.xTwitter,
    Color(0xFF000000),
    'Social',
    hint: 'kavishan',
  ),
  Platform(
    'threads',
    'Threads',
    FontAwesomeIcons.threads,
    Color(0xFF101010),
    'Social',
    hint: 'kavishan_99',
  ),
  Platform(
    'youtube',
    'YouTube',
    FontAwesomeIcons.youtube,
    Color(0xFFFF0033),
    'Social',
    hint: 'kavishan',
  ),
  Platform(
    'whatsapp',
    'WhatsApp',
    FontAwesomeIcons.whatsapp,
    Color(0xFF25D366),
    'Messaging',
    prefix: '+94 ',
    hint: '77 123 4567',
  ),
  Platform(
    'telegram',
    'Telegram',
    FontAwesomeIcons.telegram,
    Color(0xFF2AABEE),
    'Messaging',
    hint: 'kavishan',
  ),
  Platform(
    'viber',
    'Viber',
    FontAwesomeIcons.viber,
    Color(0xFF7360F2),
    'Messaging',
    prefix: '+94 ',
    hint: '77 123 4567',
  ),
  Platform(
    'spotify',
    'Spotify',
    FontAwesomeIcons.spotify,
    Color(0xFF1DB954),
    'Music & Lifestyle',
    hint: 'kavishan',
  ),
  Platform(
    'linkedin',
    'LinkedIn',
    FontAwesomeIcons.linkedinIn,
    Color(0xFF0A66C2),
    'Music & Lifestyle',
    prefix: 'in/',
    hint: 'kavishan-t',
  ),
  Platform(
    'behance',
    'Behance',
    FontAwesomeIcons.behance,
    Color(0xFF1769FF),
    'Music & Lifestyle',
    prefix: 'be/',
    hint: 'kavishan',
  ),
  Platform(
    'website',
    'Website',
    FontAwesomeIcons.globe,
    Color(0xFF8B5CF6),
    'Music & Lifestyle',
    prefix: 'https://',
    hint: 'kavishan.dev',
  ),
];

Platform platformOf(String id) =>
    platforms.firstWhere((p) => p.id == id, orElse: () => platforms.last);

class SocialLink {
  SocialLink({
    required this.id,
    required this.platform,
    required this.handle,
    this.modes = const {ProfileMode.social, ProfileMode.work},
    this.clicks = 0,
    this.greeting = '',
  });
  final String id;
  String platform;
  String handle;
  Set<ProfileMode> modes;
  int clicks;
  String greeting; // WhatsApp pre-filled message

  Platform get meta => platformOf(platform);
  String get display =>
      meta.prefix == '@' ? '@$handle' : '${meta.prefix}$handle';
  String get deepLink => switch (platform) {
    'whatsapp' => 'wa.me/94${handle.replaceAll(RegExp(r'\D'), '')}',
    'instagram' => 'instagram.com/$handle',
    _ => '$platform.com/$handle',
  };
}

class Profile {
  Profile({
    required this.username,
    required this.name,
    required this.bio,
    this.city = '',
    this.campus = '',
    this.verified = true,
    this.phone = '',
    this.phone2 = '',
    this.email = '',
    this.company = '',
    this.designation = '',
    this.avatarSeed = 0,
    this.coverSeed = 0,
    this.emoji = '',
    this.saveContact = true,
    List<SocialLink>? links,
    List<int>? gallery,
  }) : links = links ?? [],
       gallery = gallery ?? [];
  String username,
      name,
      bio,
      city,
      campus,
      phone,
      phone2,
      email,
      company,
      designation,
      emoji;
  bool verified, saveContact;
  int avatarSeed, coverSeed;
  List<SocialLink> links;
  List<int> gallery; // scenic seeds

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get url => 'vibedrop.lk/u/$username';
}

class QrConfig {
  QrConfig({
    this.dots = QrDots.rounded,
    this.eyes = QrEyes.rounded,
    this.paletteIndex = 0,
    this.showAvatar = true,
    this.frame = true,
    this.frameStyle = 0,
    this.frameText = 'Scan to connect',
    this.centerIcon = 'avatar',
    this.bgIndex = 0,
  });
  QrDots dots;
  QrEyes eyes;
  int paletteIndex;
  bool showAvatar, frame;
  int frameStyle;
  String frameText;
  String centerIcon; // avatar | instagram | monogram
  int bgIndex;

  QrConfig copy() => QrConfig(
    dots: dots,
    eyes: eyes,
    paletteIndex: paletteIndex,
    showAvatar: showAvatar,
    frame: frame,
    frameStyle: frameStyle,
    frameText: frameText,
    centerIcon: centerIcon,
    bgIndex: bgIndex,
  );
}

enum QrDots { classic, rounded, dots, soft, diamond }

enum QrEyes { square, rounded, circle }

class QrPalette {
  const QrPalette(
    this.name,
    this.a,
    this.b, {
    this.bg = Colors.white,
    this.neon = false,
  });
  final String name;
  final Color a, b, bg;
  final bool neon;
}

const qrPalettes = <QrPalette>[
  QrPalette('Indigo', Color(0xFFB93C0A), Color(0xFFFF8A3D)),
  QrPalette('Ocean', Color(0xFF1D4ED8), Color(0xFF06B6D4)),
  QrPalette('Rose', Color(0xFFBE185D), Color(0xFFF97316)),
  QrPalette('Sunset', Color(0xFFEA580C), Color(0xFFDB2777)),
  QrPalette('Forest', Color(0xFF166534), Color(0xFF65A30D)),
  QrPalette('Mono', Color(0xFF111827), Color(0xFF111827)),
  QrPalette(
    'Neon',
    Color(0xFF22D3EE),
    Color(0xFFE879F9),
    bg: Color(0xFF0B0820),
    neon: true,
  ),
  QrPalette(
    'Matrix',
    Color(0xFF4ADE80),
    Color(0xFF22C55E),
    bg: Color(0xFF04140A),
    neon: true,
  ),
];

class ScanEvent {
  ScanEvent(
    this.who,
    this.when, {
    this.city = 'Jaffna',
    this.os = 'Android',
    this.seed = 0,
    this.fresh = false,
  });
  final String who, city, os;
  final Duration when;
  final int seed;
  final bool fresh;
}

enum WaveStatus { incoming, sent, mutual }

class Wave {
  Wave({
    required this.id,
    required this.name,
    required this.handle,
    required this.note,
    required this.ago,
    required this.status,
    this.seed = 0,
  });
  final String id, name, handle, note, ago;
  final int seed;
  WaveStatus status;
}

class ChatMsg {
  ChatMsg(this.text, this.mine, this.time);
  final String text, time;
  final bool mine;
}

/// A saved card in "My Wallet" (people the user scanned).
class Contact {
  Contact({
    required this.name,
    required this.handle,
    required this.bio,
    required this.city,
    required this.seed,
    this.links = const [],
    this.saved = false,
    this.when = 'Just now',
    this.pin,
    this.question,
    this.answer,
    this.ghost = false,
    this.mode = ProfileMode.social,
    this.emoji = '',
  });
  final String name, handle, bio, city, when, emoji;
  final int seed;
  final List<List<String>> links; // [platform, handle]
  bool saved;
  final String? pin, question, answer;
  final bool ghost;
  final ProfileMode mode;
}

class AppNotif {
  AppNotif(
    this.title,
    this.body,
    this.ago,
    this.icon,
    this.color, {
    this.unread = true,
    this.kind = 'scan',
  });
  final String title, body, ago, kind;
  final IconData icon;
  final Color color;
  bool unread;
}

class MerchProduct {
  const MerchProduct(
    this.id,
    this.name,
    this.desc,
    this.price,
    this.icon,
    this.tag,
    this.colors,
  );
  final String id, name, desc, tag;
  final int price;
  final IconData icon;
  final List<Color> colors;
}

const merch = <MerchProduct>[
  MerchProduct(
    'sticker',
    'Epoxy QR Sticker',
    'Waterproof phone-back sticker, glossy dome finish.',
    790,
    Icons.smartphone_rounded,
    'Bestseller',
    [Color(0xFFF2711C), Color(0xFFEC4899)],
  ),
  MerchProduct(
    'keychain',
    'Acrylic Keychain',
    'Clear acrylic keychain with your QR and handle.',
    1290,
    Icons.key_rounded,
    'New',
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ),
  MerchProduct(
    'card',
    'Matte Black Tap Card',
    'PVC / metal NFC card. Tap or scan to connect.',
    2490,
    Icons.credit_card_rounded,
    'NFC',
    [Color(0xFF111827), Color(0xFF6B7280)],
  ),
];

class Order {
  Order(this.id, this.product, this.qty, this.total, this.status, this.date);
  final String id, product, date;
  final int qty, total;
  int status; // 0 placed 1 printing 2 shipped 3 delivered
}
