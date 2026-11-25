import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';

/// In-memory app state. No backend: every action mutates local mock data so
/// the whole UI flow is interactive.
class AppStore extends ChangeNotifier {
  AppStore() {
    _seed();
    // Dev convenience: `flutter run --dart-define=SKIP_ONBOARDING=true`
    if (const bool.fromEnvironment('SKIP_ONBOARDING')) {
      seenIntro = signedIn = onboarded = qrReady = true;
    }
  }

  // ───────── session ─────────
  bool dark = true;
  bool seenIntro = false;
  bool signedIn = false;
  bool onboarded = false;
  bool qrReady = false; // false until the user sets up their profile on Home
  String authEmail = '';
  Tier tier = Tier.free;
  String proPlan = '';
  int tab = 0;
  String language = 'English';

  // ───────── profile ─────────
  late Profile me;
  ProfileMode mode = ProfileMode.social;
  bool ghost = false;
  bool lockOn = false;
  bool lockIsPin = true;
  String lockPin = '';
  String lockQuestion = 'Which café did we meet at?';
  String lockAnswer = '';
  DateTime? tempLinkUntil;
  late QrConfig qr;
  bool get pro => tier == Tier.pro;

  // ───────── stats ─────────
  int totalScans = 1842;
  int totalClicks = 326;
  int savedContacts = 41;
  final List<int> daily = [
    12,
    18,
    9,
    24,
    31,
    22,
    40,
    28,
    35,
    52,
    44,
    61,
    38,
    57,
  ];
  final Map<String, int> cityScans = {
    'Jaffna': 812,
    'Colombo': 604,
    'Kandy': 188,
    'Galle': 121,
    'Other': 117,
  };
  final Map<String, int> deviceScans = {'Android': 1120, 'iOS': 722};

  // ───────── social ─────────
  List<ScanEvent> scans = [];
  List<Wave> waves = [];
  List<Contact> wallet = [];
  final Map<String, List<ChatMsg>> chats = {};
  List<AppNotif> notifs = [];
  final Set<String> blocked = {};
  final Set<String> reported = {};
  List<Order> orders = [];
  final Set<String> waved = {};

  // ───────── settings ─────────
  bool nScans = true, nWaves = true, nMilestones = true, nMarketing = false;
  bool showCity = true, discoverable = true;

  // ───────── mock directory (people you can "scan") ─────────
  late final List<Contact> directory;
  int _scanCursor = 0;

  static const takenUsernames = {
    'admin',
    'vibedrop',
    'kavi',
    'nisha',
    'jaffna',
    'colombo',
    'test',
  };

  void _seed() {
    me = Profile(
      username: 'kavishan',
      name: 'Kavishan Tharmaraj',
      bio: 'Tech undergrad at UoJ | Developer | Music | Travel ✈️',
      city: 'Jaffna',
      campus: 'UoJ',
      phone: '+94 77 123 4567',
      phone2: '',
      email: 'kavishan@uoj.lk',
      company: 'University of Jaffna',
      designation: 'Software Developer',
      avatarSeed: 1,
      coverSeed: 2,
      gallery: [2, 5, 8],
      links: [
        SocialLink(
          id: 'l1',
          platform: 'instagram',
          handle: 'kavishan_99',
          modes: {ProfileMode.social},
          clicks: 142,
        ),
        SocialLink(
          id: 'l2',
          platform: 'whatsapp',
          handle: '77 123 4567',
          modes: {ProfileMode.work, ProfileMode.social},
          clicks: 88,
          greeting: 'Hey! Scanned your QR 👋',
        ),
        SocialLink(
          id: 'l3',
          platform: 'spotify',
          handle: 'kavishan',
          modes: {ProfileMode.social},
          clicks: 54,
        ),
        SocialLink(
          id: 'l4',
          platform: 'linkedin',
          handle: 'kavishan-t',
          modes: {ProfileMode.work},
          clicks: 31,
        ),
        SocialLink(
          id: 'l5',
          platform: 'snapchat',
          handle: 'kavi.snap',
          modes: {ProfileMode.social},
          clicks: 11,
        ),
      ],
    );
    for (final l in me.links) {
      l.modes = {...l.modes, ProfileMode.custom};
    }
    qr = QrConfig();
    lockAnswer = 'cargills';

    scans = [
      ScanEvent(
        'Nisha Ravi',
        const Duration(minutes: 5),
        city: 'Jaffna',
        os: 'iOS',
        seed: 3,
        fresh: true,
      ),
      ScanEvent(
        'Thivyan S.',
        const Duration(minutes: 18),
        city: 'Colombo',
        os: 'Android',
        seed: 4,
        fresh: true,
      ),
      ScanEvent(
        'Yalini K.',
        const Duration(hours: 1, minutes: 2),
        city: 'Jaffna',
        os: 'Android',
        seed: 6,
      ),
      ScanEvent(
        'Guest (web)',
        const Duration(hours: 3),
        city: 'Kandy',
        os: 'iOS',
        seed: 7,
      ),
      ScanEvent(
        'Dinesh P.',
        const Duration(hours: 5),
        city: 'Galle',
        os: 'Android',
        seed: 9,
      ),
      ScanEvent(
        'Guest (web)',
        const Duration(hours: 9),
        city: 'Colombo',
        os: 'Android',
        seed: 10,
      ),
    ];

    waves = [
      Wave(
        id: 'w1',
        name: 'Arjun Dev',
        handle: 'arjun.dev',
        note: 'Saw you at Cargills Square!',
        ago: '2h ago',
        status: WaveStatus.incoming,
        seed: 11,
      ),
      Wave(
        id: 'w2',
        name: 'Heshani M.',
        handle: 'heshani_m',
        note: 'Loved your playlist 🎧',
        ago: '5h ago',
        status: WaveStatus.mutual,
        seed: 12,
      ),
      Wave(
        id: 'w3',
        name: 'Rukshan F.',
        handle: 'rukshan.f',
        note: 'Hey from the UoJ hackathon',
        ago: '1d ago',
        status: WaveStatus.incoming,
        seed: 13,
      ),
      Wave(
        id: 'w4',
        name: 'Sanjay K.',
        handle: 'sanjay.k',
        note: 'Nice setup!',
        ago: '2d ago',
        status: WaveStatus.sent,
        seed: 14,
      ),
    ];
    chats['heshani_m'] = [
      ChatMsg('You both waved 🎉', false, '5h'),
      ChatMsg('Hey Heshani! Thanks for the wave 👋', true, '5h'),
      ChatMsg('Hi Kavishan! Your Spotify mix is 🔥', false, '4h'),
    ];

    directory = [
      Contact(
        name: 'Nisha Ravi',
        handle: 'nisha_r',
        bio: 'Designer • Coffee • Jaffna sunsets',
        city: 'Jaffna',
        seed: 3,
        emoji: '🎨',
        links: [
          ['instagram', 'nisha.designs'],
          ['whatsapp', '76 555 0101'],
          ['spotify', 'nisha'],
        ],
      ),
      Contact(
        name: 'Thivyan Selvam',
        handle: 'thivyan',
        bio: 'Photographer | Drone | Travel',
        city: 'Colombo',
        seed: 4,
        emoji: '📸',
        links: [
          ['instagram', 'thivyan.frames'],
          ['youtube', 'thivyanfilms'],
          ['whatsapp', '71 222 3344'],
        ],
      ),
      Contact(
        name: 'Dilan Perera',
        handle: 'dilan_p',
        bio: 'Final-year engineer. Say hi!',
        city: 'Kandy',
        seed: 5,
        emoji: '⚙️',
        pin: '1234',
        links: [
          ['instagram', 'dilan.p'],
          ['linkedin', 'dilan-perera'],
          ['whatsapp', '70 888 1212'],
        ],
      ),
      Contact(
        name: 'Anjali Fernando',
        handle: 'anjali.f',
        bio: 'Riddle me this 🤔',
        city: 'Colombo',
        seed: 6,
        emoji: '🌸',
        question: 'Which café did we meet at?',
        answer: 'cargills',
        links: [
          ['instagram', 'anjali.f'],
          ['snapchat', 'anjali.snap'],
          ['tiktok', 'anjali.tok'],
        ],
      ),
      Contact(
        name: 'Mathu Kumar',
        handle: 'mathu',
        bio: 'Musician. DM for gigs 🎸',
        city: 'Jaffna',
        seed: 7,
        emoji: '🎸',
        mode: ProfileMode.work,
        links: [
          ['spotify', 'mathukumar'],
          ['youtube', 'mathumusic'],
          ['whatsapp', '77 900 4411'],
        ],
      ),
      Contact(
        name: 'Private User',
        handle: 'ghost_one',
        bio: '',
        city: '',
        seed: 8,
        ghost: true,
      ),
    ];

    notifs = [
      AppNotif(
        'Someone in Jaffna scanned your QR',
        'Nisha Ravi • 5 min ago',
        '5m',
        Icons.qr_code_scanner_rounded,
        VC.violet,
      ),
      AppNotif(
        'You received a new Wave 👋',
        'Arjun Dev: “Saw you at Cargills Square!”',
        '2h',
        Icons.waving_hand_rounded,
        VC.orange,
        kind: 'wave',
      ),
      AppNotif(
        'Your QR card hit 1,800 scans!',
        'Milestone unlocked — share your win',
        '1d',
        Icons.emoji_events_rounded,
        VC.gold,
        unread: false,
        kind: 'milestone',
      ),
      AppNotif(
        'Mutual Wave with Heshani M.',
        'You can now chat in-app',
        '1d',
        Icons.favorite_rounded,
        VC.pink,
        unread: false,
        kind: 'wave',
      ),
    ];

    wallet = [
      Contact(
        name: 'Mathu Kumar',
        handle: 'mathu',
        bio: 'Musician. DM for gigs 🎸',
        city: 'Jaffna',
        seed: 7,
        emoji: '🎸',
        saved: true,
        when: 'Yesterday',
        links: [
          ['spotify', 'mathukumar'],
          ['whatsapp', '77 900 4411'],
        ],
      ),
      Contact(
        name: 'Heshani M.',
        handle: 'heshani_m',
        bio: 'Marketing student • Cat mom',
        city: 'Colombo',
        seed: 12,
        emoji: '🐱',
        saved: true,
        when: '2 days ago',
        links: [
          ['instagram', 'heshani_m'],
          ['tiktok', 'heshani.tok'],
        ],
      ),
    ];

    orders = [Order('VD-20481', 'Epoxy QR Sticker × 2', 2, 1580, 3, '12 Nov')];
  }

  // ───────── generic ─────────
  void touch() => notifyListeners();

  void toggleTheme() {
    dark = !dark;
    notifyListeners();
  }

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  // ───────── auth ─────────
  void signIn(String email) {
    signedIn = true;
    onboarded = true; // straight to Home; profile is set up there
    authEmail = email;
    if (!qrReady) {
      final base = email
          .split('@')
          .first
          .replaceAll(RegExp(r'[^A-Za-z0-9_ ]'), '');
      me
        ..username = ''
        ..name = base.isEmpty ? 'New user' : base
        ..bio = ''
        ..city = ''
        ..campus = ''
        ..emoji = ''
        ..links = []
        ..gallery = [];
    }
    notifyListeners();
  }

  void completeOnboarding() {
    onboarded = true;
    tab = 0;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    onboarded = false;
    tab = 0;
    notifyListeners();
  }

  bool usernameFree(String u) => !takenUsernames.contains(u.toLowerCase());

  // ───────── profile ─────────
  List<SocialLink> get visibleLinks {
    if (ghost) return [];
    return me.links.where((l) => l.modes.contains(mode)).toList();
  }

  void setMode(ProfileMode m) {
    mode = m;
    notifyListeners();
  }

  void setGhost(bool v) {
    ghost = v;
    notifyListeners();
  }

  void reorderLinks(int a, int b) {
    final l = me.links.removeAt(a);
    me.links.insert(b, l);
    notifyListeners();
  }

  void addLink(SocialLink l) {
    l.modes.add(ProfileMode.custom);
    me.links.add(l);
    notifyListeners();
  }

  void removeLink(String id) {
    me.links.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  void startTempLink() {
    tempLinkUntil = DateTime.now().add(const Duration(hours: 24));
    notifyListeners();
  }

  void endTempLink() {
    tempLinkUntil = null;
    notifyListeners();
  }

  // ───────── scanning loop ─────────
  Contact nextScan() {
    final c = directory[_scanCursor % directory.length];
    _scanCursor++;
    return c;
  }

  Contact? contactByHandle(String h) {
    for (final c in [...directory, ...wallet]) {
      if (c.handle == h) return c;
    }
    return null;
  }

  bool inWallet(String handle) => wallet.any((c) => c.handle == handle);

  void saveToWallet(Contact c) {
    if (!inWallet(c.handle)) {
      c.saved = true;
      wallet.insert(
        0,
        Contact(
          name: c.name,
          handle: c.handle,
          bio: c.bio,
          city: c.city,
          seed: c.seed,
          emoji: c.emoji,
          links: c.links,
          saved: true,
          when: 'Just now',
        ),
      );
      notifyListeners();
    }
  }

  void removeFromWallet(String handle) {
    wallet.removeWhere((c) => c.handle == handle);
    notifyListeners();
  }

  // ───────── waves ─────────
  void sendWave(Contact c, String note) {
    waved.add(c.handle);
    waves.insert(
      0,
      Wave(
        id: 'w${DateTime.now().microsecondsSinceEpoch}',
        name: c.name,
        handle: c.handle,
        note: note,
        ago: 'Just now',
        status: WaveStatus.sent,
        seed: c.seed,
      ),
    );
    notifyListeners();
    // Simulated reply: some people wave back after a moment.
    if (c.handle != 'ghost_one') {
      Timer(const Duration(seconds: 6), () {
        final i = waves.indexWhere(
          (w) => w.handle == c.handle && w.status == WaveStatus.sent,
        );
        if (i >= 0 && Random().nextBool()) {
          waves[i].status = WaveStatus.mutual;
          chats.putIfAbsent(
            c.handle,
            () => [ChatMsg('You both waved 🎉', false, 'now')],
          );
          notifs.insert(
            0,
            AppNotif(
              '${c.name} waved back!',
              'It\'s a Mutual Wave — say hi',
              'now',
              Icons.favorite_rounded,
              VC.pink,
              kind: 'wave',
            ),
          );
          notifyListeners();
        }
      });
    }
  }

  void acceptWave(String id) {
    final w = waves.firstWhere((e) => e.id == id);
    w.status = WaveStatus.mutual;
    chats.putIfAbsent(
      w.handle,
      () => [ChatMsg('You both waved 🎉', false, 'now')],
    );
    notifyListeners();
  }

  void dismissWave(String id) {
    waves.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  void sendChat(String handle, String text) {
    final list = chats.putIfAbsent(handle, () => []);
    list.add(ChatMsg(text, true, 'now'));
    notifyListeners();
    const replies = [
      'Haha nice 😄',
      'Totally! Let\'s catch up soon',
      'Sent you my number on WhatsApp 📲',
      'Love that 🔥',
      'Sure, sounds good!',
    ];
    Timer(const Duration(milliseconds: 1400), () {
      list.add(
        ChatMsg(replies[Random().nextInt(replies.length)], false, 'now'),
      );
      notifyListeners();
    });
  }

  // ───────── safety ─────────
  void block(String handle) {
    blocked.add(handle);
    waves.removeWhere((w) => w.handle == handle);
    notifyListeners();
  }

  void unblock(String handle) {
    blocked.remove(handle);
    notifyListeners();
  }

  void report(String handle) {
    reported.add(handle);
    notifyListeners();
  }

  // ───────── notifications ─────────
  int get unreadCount => notifs.where((n) => n.unread).length;
  void markAllRead() {
    for (final n in notifs) {
      n.unread = false;
    }
    notifyListeners();
  }

  // ───────── pro ─────────
  void upgrade(String plan) {
    tier = Tier.pro;
    proPlan = plan;
    notifyListeners();
  }

  void downgrade() {
    tier = Tier.free;
    proPlan = '';
    if (mode == ProfileMode.custom) mode = ProfileMode.social;
    lockOn = false;
    notifyListeners();
  }

  // ───────── merch ─────────
  Order placeOrder(MerchProduct p, int qty) {
    final o = Order(
      'VD-${20482 + orders.length}',
      '${p.name} × $qty',
      qty,
      p.price * qty + 350,
      0,
      'Today',
    );
    orders.insert(0, o);
    notifyListeners();
    return o;
  }
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);
  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension StoreCtx on BuildContext {
  AppStore get store => AppScope.of(this);
}
