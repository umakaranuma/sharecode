import 'dart:convert';

enum ProfileMode { social, work, custom }

class VibeLink {
  VibeLink({
    required this.platform,
    required this.value,
    this.label = '',
    this.visibility = 'both',
    this.active = true,
  });
  String platform;
  String value;
  String label;
  String visibility;
  bool active;

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'value': value,
    'label': label,
    'visibility': visibility,
    'active': active,
  };
  factory VibeLink.fromJson(Map<String, dynamic> json) => VibeLink(
    platform: json['platform'] as String? ?? 'website',
    value: json['value'] as String? ?? '',
    label: json['label'] as String? ?? '',
    visibility: json['visibility'] as String? ?? 'both',
    active: json['active'] as bool? ?? true,
  );

  String get title =>
      label.isEmpty ? platform[0].toUpperCase() + platform.substring(1) : label;

  String? get url {
    final clean = value.trim();
    if (clean.isEmpty) return null;
    if (clean.startsWith('https://') || clean.startsWith('http://')) {
      return clean;
    }
    final handle = clean.replaceFirst(RegExp(r'^@'), '');
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'https://instagram.com/$handle';
      case 'whatsapp':
        final number = clean.replaceAll(RegExp(r'[^0-9]'), '');
        return 'https://wa.me/${number.startsWith('0') ? '94${number.substring(1)}' : number}';
      case 'tiktok':
        return 'https://www.tiktok.com/@$handle';
      case 'snapchat':
        return 'https://www.snapchat.com/add/$handle';
      case 'linkedin':
        return 'https://www.linkedin.com/in/$handle';
      case 'spotify':
        return 'https://open.spotify.com/user/$handle';
      case 'youtube':
        return 'https://www.youtube.com/@$handle';
      case 'telegram':
        return 'https://t.me/$handle';
      case 'facebook':
        return 'https://facebook.com/$handle';
      case 'x':
        return 'https://x.com/$handle';
      case 'threads':
        return 'https://www.threads.net/@$handle';
      case 'behance':
        return 'https://www.behance.net/$handle';
      case 'viber':
        return 'viber://chat?number=$handle';
      case 'email':
        return 'mailto:$clean';
      case 'phone':
        return 'tel:$clean';
      default:
        return 'https://$clean';
    }
  }
}

class VibeProfile {
  VibeProfile({
    required this.handle,
    required this.name,
    this.bio = '',
    this.city = '',
    this.campus = '',
    this.phone = '',
    this.email = '',
    this.company = '',
    this.designation = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.galleryUrls = const [],
    this.mode = ProfileMode.social,
    this.ghost = false,
    this.saveContact = true,
    this.qrColor = 0xFF6C22E9,
    this.qrStyle = 'Rounded',
    this.links = const [],
  });
  String handle;
  String name;
  String bio;
  String city;
  String campus;
  String phone;
  String email;
  String company;
  String designation;
  String avatarUrl;
  String coverUrl;
  List<String> galleryUrls;
  ProfileMode mode;
  bool ghost;
  bool saveContact;
  int qrColor;
  String qrStyle;
  List<VibeLink> links;

  String get url => 'https://yourapp.lk/u/$handle';
  List<VibeLink> get visibleLinks => ghost
      ? []
      : links
            .where(
              (link) =>
                  link.active &&
                  (mode == ProfileMode.custom ||
                      link.visibility == 'both' ||
                      link.visibility == mode.name),
            )
            .toList();
  Map<String, dynamic> toJson() => {
    'handle': handle,
    'name': name,
    'bio': bio,
    'city': city,
    'campus': campus,
    'phone': phone,
    'email': email,
    'company': company,
    'designation': designation,
    'avatarUrl': avatarUrl,
    'coverUrl': coverUrl,
    'galleryUrls': galleryUrls,
    'mode': mode.name,
    'ghost': ghost,
    'saveContact': saveContact,
    'qrColor': qrColor,
    'qrStyle': qrStyle,
    'links': links.map((e) => e.toJson()).toList(),
  };
  factory VibeProfile.fromJson(Map<String, dynamic> json) => VibeProfile(
    handle: json['handle'] as String? ?? 'myvibe',
    name: json['name'] as String? ?? 'My Profile',
    bio: json['bio'] as String? ?? '',
    city: json['city'] as String? ?? '',
    campus: json['campus'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    company: json['company'] as String? ?? '',
    designation: json['designation'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    coverUrl: json['coverUrl'] as String? ?? '',
    galleryUrls: (json['galleryUrls'] as List? ?? []).cast<String>(),
    mode: ProfileMode.values.byName(json['mode'] as String? ?? 'social'),
    ghost: json['ghost'] as bool? ?? false,
    saveContact: json['saveContact'] as bool? ?? true,
    qrColor: json['qrColor'] as int? ?? 0xFF6C22E9,
    qrStyle: json['qrStyle'] as String? ?? 'Rounded',
    links: ((json['links'] as List?) ?? [])
        .map((e) => VibeLink.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  static VibeProfile demo() => VibeProfile(
    handle: 'kavishan',
    name: 'Kavishan Tharmaraj',
    bio: 'Tech undergrad at UoJ  |  Developer  |  Music  |  Travel ✈️',
    city: 'Jaffna, Sri Lanka',
    campus: 'UoJ',
    links: [
      VibeLink(
        platform: 'instagram',
        value: 'kavishan_99',
        visibility: 'social',
      ),
      VibeLink(
        platform: 'whatsapp',
        value: '+94 77 123 4567',
        visibility: 'work',
      ),
      VibeLink(platform: 'spotify', value: 'kavishan', visibility: 'social'),
    ],
  );
}

String encodeProfile(VibeProfile profile) => jsonEncode(profile.toJson());
VibeProfile decodeProfile(String value) =>
    VibeProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
