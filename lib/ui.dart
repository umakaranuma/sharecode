import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_state.dart';
import 'model.dart';

const ink = Color(0xFF11102F);
const purple = Color(0xFF6B20E8);
const violet = Color(0xFF9F62F6);
const pale = Color(0xFFF1EAFF);
const border = Color(0xFFE7DFFC);
const grad = LinearGradient(
  colors: [Color(0xFFB777F5), Color(0xFF6C21E9), Color(0xFF4E0BB9)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

void notice(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

Widget surface({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(16),
  Color color = Colors.white,
  Border? customBorder,
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(20),
    border: customBorder ?? Border.all(color: border),
    boxShadow: const [
      BoxShadow(color: Color(0x090B0735), blurRadius: 14, offset: Offset(0, 5)),
    ],
  ),
  child: Material(type: MaterialType.transparency, child: child),
);

Widget sectionTitle(String text, {Widget? trailing}) => Padding(
  padding: const EdgeInsets.only(top: 22, bottom: 10),
  child: Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
      ),
      ?trailing,
    ],
  ),
);

Widget primaryButton(
  String text,
  IconData icon,
  VoidCallback onTap, {
  bool expanded = false,
}) {
  final button = FilledButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 19),
    label: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    style: FilledButton.styleFrom(
      backgroundColor: purple,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
  return expanded ? SizedBox(width: double.infinity, child: button) : button;
}

Widget softButton(String text, IconData icon, VoidCallback onTap) =>
    FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: pale,
        foregroundColor: const Color(0xFF4F11B6),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

Widget avatar(VibeProfile p, {double radius = 27}) => CircleAvatar(
  radius: radius,
  backgroundColor: pale,
  backgroundImage: p.avatarUrl.isNotEmpty ? NetworkImage(p.avatarUrl) : null,
  child: p.avatarUrl.isEmpty
      ? Text(
          p.name.isEmpty ? 'V' : p.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: radius,
            fontWeight: FontWeight.w900,
            color: purple,
          ),
        )
      : null,
);

Widget qr(VibeState state, double size, {Color? color}) => QrImageView(
  data: state.publicUrl,
  version: QrVersions.auto,
  size: size,
  eyeStyle: QrEyeStyle(
    eyeShape: QrEyeShape.square,
    color: color ?? Color(state.profile.qrColor),
  ),
  dataModuleStyle: QrDataModuleStyle(
    dataModuleShape: state.profile.qrStyle == 'Rounded'
        ? QrDataModuleShape.circle
        : QrDataModuleShape.square,
    color: color ?? Color(state.profile.qrColor),
  ),
  errorCorrectionLevel: QrErrorCorrectLevel.H,
  padding: const EdgeInsets.all(6),
  backgroundColor: Colors.white,
);

Future<void> shareUrl(BuildContext context, VibeState state) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: state.publicUrl,
        subject: '${state.profile.name} on VibeDrop',
      ),
    );
  } catch (e) {
    if (context.mounted) notice(context, 'Could not share: $e');
  }
}

Future<void> shareQr(
  BuildContext context,
  VibeState state, {
  int size = 2048,
  bool transparent = false,
}) async {
  try {
    final painter = QrPainter(
      data: state.publicUrl,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      eyeStyle: QrEyeStyle(
        eyeShape: state.profile.qrStyle == 'Soft'
            ? QrEyeShape.circle
            : QrEyeShape.square,
        color: Color(state.profile.qrColor),
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: state.profile.qrStyle == 'Classic'
            ? QrDataModuleShape.square
            : QrDataModuleShape.circle,
        color: Color(state.profile.qrColor),
      ),
      // QrPainter's off-screen export still uses emptyColor for background pixels.
      // ignore: deprecated_member_use
      emptyColor: transparent ? Colors.transparent : Colors.white,
    );
    final bytes = await painter.toImageData(
      size.toDouble(),
      format: ui.ImageByteFormat.png,
    );
    if (bytes == null) throw StateError('QR rendering failed');
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'vibedrop-${state.profile.handle}.png',
          ),
        ],
        text: state.publicUrl,
      ),
    );
  } catch (e) {
    if (context.mounted) notice(context, 'Could not export QR: $e');
  }
}

Future<void> shareCard(
  BuildContext context,
  VibeState state, {
  bool wallpaper = false,
}) async {
  try {
    final width = wallpaper
        ? (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
              .round()
        : 1080;
    final height = wallpaper
        ? (MediaQuery.sizeOf(context).height *
                  MediaQuery.devicePixelRatioOf(context))
              .round()
        : 1920;
    final codeBytes = await QrPainter(
      data: state.publicUrl,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      eyeStyle: QrEyeStyle(
        eyeShape: state.profile.qrStyle == 'Soft'
            ? QrEyeShape.circle
            : QrEyeShape.square,
        color: Color(state.profile.qrColor),
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: state.profile.qrStyle == 'Classic'
            ? QrDataModuleShape.square
            : QrDataModuleShape.circle,
        color: Color(state.profile.qrColor),
      ),
      // ignore: deprecated_member_use
      emptyColor: Colors.white,
    ).toImageData(600, format: ui.ImageByteFormat.png);
    if (codeBytes == null) throw StateError('QR rendering failed');
    final codec = await ui.instantiateImageCodec(
      codeBytes.buffer.asUint8List(),
    );
    final codeImage = (await codec.getNextFrame()).image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(width.toDouble(), height.toDouble()),
          [
            const Color(0xFF1B104F),
            const Color(0xFF873FC6),
            const Color(0xFFFFA76B),
          ],
        ),
    );
    final codeSize = width * 0.56;
    final top = wallpaper ? height * 0.57 : height * 0.42;
    final left = (width - codeSize) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 24, top - 24, codeSize + 48, codeSize + 48),
        const Radius.circular(32),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawImageRect(
      codeImage,
      Rect.fromLTWH(
        0,
        0,
        codeImage.width.toDouble(),
        codeImage.height.toDouble(),
      ),
      Rect.fromLTWH(left, top, codeSize, codeSize),
      Paint(),
    );
    void drawText(
      String value,
      double y,
      double fontSize, {
      FontWeight weight = FontWeight.w700,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: weight,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      painter.layout(maxWidth: width * 0.86);
      painter.paint(canvas, Offset((width - painter.width) / 2, y));
    }

    if (!wallpaper) {
      drawText(state.profile.name, height * 0.24, 58, weight: FontWeight.w900);
      drawText('Scan to connect', height * 0.30, 32);
    }
    drawText('@${state.profile.handle}', top + codeSize + 42, 37);
    final image = await recorder.endRecording().toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Card rendering failed');
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes.buffer.asUint8List(),
            mimeType: 'image/png',
            name: wallpaper ? 'vibedrop-wallpaper.png' : 'vibedrop-story.png',
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) notice(context, 'Could not export card: $e');
  }
}

class VibeShell extends StatelessWidget {
  const VibeShell({super.key, required this.state});
  final VibeState state;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: switch (state.tab) {
          0 => HomePage(state: state),
          1 => StudioPage(state: state),
          2 => ScannerPage(state: state),
          3 => ConnectionsPage(state: state),
          _ => ProfilePage(state: state),
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nav(context, 0, Icons.home_rounded, 'Home'),
                _nav(context, 1, Icons.layers_rounded, 'Studio'),
                _nav(
                  context,
                  2,
                  Icons.qr_code_scanner_rounded,
                  'Scan',
                  special: true,
                ),
                _nav(context, 3, Icons.people_outline_rounded, 'Connections'),
                _nav(context, 4, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _nav(
    BuildContext context,
    int index,
    IconData icon,
    String title, {
    bool special = false,
  }) => InkWell(
    onTap: () => state.setTab(index),
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: special ? 66 : 63,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: special ? 48 : 36,
            height: special ? 43 : 34,
            decoration: BoxDecoration(
              gradient: special ? grad : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: special
                  ? Colors.white
                  : state.tab == index
                  ? purple
                  : const Color(0xFF52557E),
              size: special ? 26 : 23,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: state.tab == index
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: state.tab == index ? purple : const Color(0xFF52557E),
            ),
          ),
        ],
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.state});
  final VibeState state;
  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: purple, size: 26),
            const SizedBox(width: 7),
            const Text(
              'VibeDrop',
              style: TextStyle(
                color: ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => state.setTab(3),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey ${p.name.split(' ').first}! 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  Text(
                    state.isDemo
                        ? 'Your starter digital identity is ready.'
                        : 'Your digital identity is ready.',
                    style: const TextStyle(color: Color(0xFF5D5B76)),
                  ),
                ],
              ),
            ),
            avatar(p),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(23),
            boxShadow: const [
              BoxShadow(
                color: Color(0x477030DC),
                blurRadius: 18,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: qr(state, 130),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar(p, radius: 30),
                    const SizedBox(height: 12),
                    Text(
                      '@${p.handle}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.publicUrl.replaceFirst('https://', ''),
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        sectionTitle('Active Mode'),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrivacyPage(state: state)),
          ),
          child: surface(
            child: Row(
              children: [
                Icon(
                  p.ghost
                      ? Icons.visibility_off_outlined
                      : p.mode == ProfileMode.work
                      ? Icons.work_outline
                      : Icons.groups_rounded,
                  color: purple,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.ghost
                        ? 'Ghost Mode'
                        : p.mode == ProfileMode.work
                        ? 'Work / Campus Mode'
                        : p.mode == ProfileMode.custom
                        ? 'Custom Mode'
                        : 'Social Mode',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: primaryButton(
                'Share QR',
                Icons.share_outlined,
                () => shareUrl(context, state),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: softButton(
                'Customize',
                Icons.edit_outlined,
                () => state.setTab(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _stat(
                Icons.qr_code_scanner,
                '${state.scanCount}',
                'Total Scans',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(Icons.link, '${state.clickCount}', 'Link Clicks'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExportPage(state: state)),
          ),
          child: surface(
            color: pale,
            child: const Row(
              children: [
                Icon(Icons.download_rounded, color: purple, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export your QR',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Share an image or create a lock screen card',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              state.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _stat(IconData icon, String number, String label) => surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: purple),
        const SizedBox(height: 9),
        Text(
          number,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF5D5B76), fontSize: 12),
        ),
      ],
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});
  final VibeState state;
  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios_new, size: 19),
              const Spacer(),
              Text(
                state.publicUrl.replaceFirst('https://', ''),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => shareUrl(context, state),
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 145,
              decoration: BoxDecoration(
                image: p.coverUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(p.coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF261050),
                    Color(0xFFAF5EBA),
                    Color(0xFFFFB278),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: p.coverUrl.isNotEmpty
                  ? null
                  : const Center(
                      child: Icon(
                        Icons.wb_twilight_rounded,
                        color: Color(0x88FFFFFF),
                        size: 90,
                      ),
                    ),
            ),
            Positioned(
              left: 21,
              bottom: -42,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: avatar(p, radius: 44),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 53, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(state: state),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, color: purple),
                  ),
                ],
              ),
              Text(
                '@${p.handle}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF363250),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                p.bio.isEmpty
                    ? 'Add a bio to tell people about yourself.'
                    : p.bio,
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (p.city.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.location_on_outlined, size: 16),
                      label: Text(p.city),
                    ),
                  if (p.campus.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.school_outlined, size: 16),
                      label: Text(p.campus),
                    ),
                ],
              ),
              if (!p.ghost &&
                  p.mode != ProfileMode.work &&
                  p.galleryUrls.isNotEmpty) ...[
                sectionTitle('Photos'),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final url in p.galleryUrls)
                        Padding(
                          padding: const EdgeInsets.only(right: 9),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              url,
                              width: 112,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              sectionTitle(
                'Your links',
                trailing: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(state: state),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              if (p.ghost)
                surface(
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: purple),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('This profile is currently private.'),
                      ),
                    ],
                  ),
                )
              else if (p.visibleLinks.isEmpty)
                surface(
                  child: const Text(
                    'No links are visible in this mode. Edit your profile to add links.',
                  ),
                )
              else
                ...p.visibleLinks.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () async {
                        final url = link.url;
                        if (url != null) {
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: surface(
                        padding: const EdgeInsets.symmetric(
                          vertical: 11,
                          horizontal: 13,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: pale,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                platformIcon(link.platform),
                                color: purple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    link.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    link.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF595673),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: primaryButton(
                      'Save Contact',
                      Icons.download_rounded,
                      () => shareVcard(context, state),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: softButton(
                      'Wave 👋',
                      Icons.waving_hand_outlined,
                      () => notice(
                        context,
                        'Waves are available after connecting the backend.',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData platformIcon(String platform) => switch (platform.toLowerCase()) {
  'instagram' => Icons.camera_alt_outlined,
  'whatsapp' => Icons.chat_bubble_outline,
  'spotify' => Icons.music_note,
  'linkedin' => Icons.work_outline,
  'youtube' => Icons.play_circle_outline,
  'email' => Icons.mail_outline,
  'phone' => Icons.phone_outlined,
  'tiktok' => Icons.music_video_outlined,
  _ => Icons.link,
};

Future<void> shareVcard(BuildContext context, VibeState state) async {
  final p = state.profile;
  if (!p.saveContact || p.ghost || p.mode == ProfileMode.social) {
    notice(context, 'Contact saving is disabled in this mode.');
    return;
  }
  String escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
  final card =
      'BEGIN:VCARD\r\nVERSION:3.0\r\nFN:${escape(p.name)}\r\nTEL:${escape(p.phone)}\r\nEMAIL:${escape(p.email)}\r\nORG:${escape(p.company)}\r\nTITLE:${escape(p.designation)}\r\nEND:VCARD\r\n';
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(card)),
          mimeType: 'text/vcard',
          name: '${p.handle}.vcf',
        ),
      ],
    ),
  );
}

class StudioPage extends StatefulWidget {
  const StudioPage({super.key, required this.state});
  final VibeState state;
  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  int selected = 0;
  bool showAvatar = true;
  bool frame = true;
  final colors = const [
    0xFF6B20E8,
    0xFF1167F2,
    0xFFE72B91,
    0xFFFF8A24,
    0xFF20B86B,
    0xFF171725,
  ];
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => state.setTab(0),
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'QR Studio',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => notice(
                context,
                'Your QR always links to your dynamic profile URL.',
              ),
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        ['My QR', 'Styles', 'Frames'][i],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    selected: selected == i,
                    onSelected: (_) => setState(() => selected = i),
                    selectedColor: purple,
                    labelStyle: TextStyle(
                      color: selected == i ? Colors.white : ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EFFF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x336922DC),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    qr(state, 230),
                    if (showAvatar)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: avatar(state.profile, radius: 20),
                      ),
                  ],
                ),
              ),
              if (frame)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '✨ @${state.profile.handle}',
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        sectionTitle('QR Style'),
        Row(
          children: [
            for (final style in ['Classic', 'Rounded', 'Dots', 'Soft'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: InkWell(
                    onTap: () async {
                      state.profile.qrStyle = style;
                      await state.saveProfile(state.profile);
                    },
                    child: surface(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      color: state.profile.qrStyle == style
                          ? pale
                          : Colors.white,
                      customBorder: Border.all(
                        color: state.profile.qrStyle == style ? purple : border,
                        width: state.profile.qrStyle == style ? 2 : 1,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            style == 'Classic'
                                ? Icons.qr_code
                                : style == 'Dots'
                                ? Icons.blur_on
                                : Icons.grid_view_rounded,
                            color: purple,
                          ),
                          Text(
                            style,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
        sectionTitle('Colors'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final value in colors)
              InkWell(
                onTap: () => state.setQrColor(value),
                child: Container(
                  width: 39,
                  height: 39,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: state.profile.qrColor == value
                          ? purple
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(backgroundColor: Color(value)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Show profile photo in center'),
                value: showAvatar,
                onChanged: (v) => setState(() => showAvatar = v),
                activeThumbColor: purple,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Add handle frame'),
                value: frame,
                onChanged: (v) => setState(() => frame = v),
                activeThumbColor: purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        primaryButton(
          'Export QR',
          Icons.download_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExportPage(state: state)),
          ),
          expanded: true,
        ),
      ],
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, required this.state});
  final VibeState state;
  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy & Modes',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Profile Modes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const Text(
            'Control what others see when they scan your QR.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5D5B76)),
          ),
          const SizedBox(height: 14),
          _mode(
            context,
            ProfileMode.social,
            Icons.groups_outlined,
            'Chill / Social Mode',
            'Show social links and hide phone and email.',
          ),
          _mode(
            context,
            ProfileMode.work,
            Icons.work_outline,
            'Work / Campus Mode',
            'Show professional links and contact details.',
          ),
          _mode(
            context,
            ProfileMode.custom,
            Icons.tune,
            'Custom Mode',
            'Show your selected active links.',
          ),
          sectionTitle('Privacy & Safety Shield'),
          surface(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.visibility_off_outlined,
                color: purple,
              ),
              title: const Text('Ghost Mode'),
              subtitle: const Text('Pause your public profile temporarily.'),
              value: p.ghost,
              onChanged: state.setGhost,
              activeThumbColor: purple,
            ),
          ),
          const SizedBox(height: 10),
          surface(
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: purple),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secret Question / PIN Lock',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Available with Pro and a configured backend.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          surface(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.contact_page_outlined, color: purple),
              title: const Text('Allow Save Contact'),
              subtitle: const Text('Available in Work mode.'),
              value: p.saveContact,
              onChanged: (v) {
                p.saveContact = v;
                state.saveProfile(p);
              },
              activeThumbColor: purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mode(
    BuildContext context,
    ProfileMode mode,
    IconData icon,
    String title,
    String subtitle,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: InkWell(
      onTap: () => state.setMode(mode),
      child: surface(
        customBorder: Border.all(
          color: state.profile.mode == mode ? purple : border,
          width: state.profile.mode == mode ? 2 : 1,
        ),
        child: Row(
          children: [
            Icon(icon, color: purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Icon(
              state.profile.mode == mode
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: purple,
            ),
          ],
        ),
      ),
    ),
  );
}

class ExportPage extends StatelessWidget {
  const ExportPage({super.key, required this.state});
  final VibeState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Export & Download',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
      children: [
        Container(
          height: 230,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFCA9AFF), Color(0xFFF6E7FF)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 118,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: grad,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ink, width: 5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '9:41',
                          style: TextStyle(color: Colors.white, fontSize: 27),
                        ),
                        const SizedBox(height: 21),
                        Container(color: Colors.white, child: qr(state, 86)),
                        const SizedBox(height: 8),
                        Text(
                          '@${state.profile.handle}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QR Lock Screen Wallpaper',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Keep your code ready to share.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 9),
                      FilledButton(
                        onPressed: () =>
                            shareCard(context, state, wallpaper: true),
                        child: const Text('Generate'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        sectionTitle('Export Options'),
        _option(
          context,
          Icons.auto_awesome,
          'Instagram Story (9:16)',
          'Share your QR on stories',
          () => shareCard(context, state),
        ),
        _option(
          context,
          Icons.image_outlined,
          'PNG (High Quality)',
          '2048 × 2048 image',
          () => shareQr(context, state),
        ),
        _option(
          context,
          Icons.layers_outlined,
          'Transparent PNG',
          'QR with transparent background',
          () => shareQr(context, state, transparent: true),
        ),
        _option(
          context,
          Icons.description_outlined,
          'SVG / PDF',
          'Print-ready vector export · Pro',
          () => notice(context, 'Vector export requires Pro.'),
        ),
        _option(
          context,
          Icons.wallet_outlined,
          'Add to Wallet',
          'Apple / Google Wallet pass',
          () => notice(
            context,
            'Wallet passes require a configured pass issuer.',
          ),
        ),
      ],
    ),
  );
  Widget _option(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback tap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: tap,
      child: surface(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class ScannedProfilePage extends StatefulWidget {
  const ScannedProfilePage({super.key, required this.handle});
  final String handle;
  @override
  State<ScannedProfilePage> createState() => _ScannedProfilePageState();
}

class _ScannedProfilePageState extends State<ScannedProfilePage> {
  late final Future<Map<String, dynamic>> loading = _load();
  Future<Map<String, dynamic>> _load() async {
    final response = await http.get(
      Uri.parse('$profileHost/api/profile/${widget.handle}'),
    );
    if (response.statusCode != 200) throw StateError('Profile unavailable');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _wave() async {
    if (!cloudEnabled || Supabase.instance.client.auth.currentSession == null) {
      notice(context, 'Sign in to send a wave.');
      return;
    }
    final note = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send a wave 👋'),
        content: TextField(
          controller: note,
          maxLength: 150,
          decoration: const InputDecoration(
            labelText: 'Add a short note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, note.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    note.dispose();
    if (value == null) return;
    try {
      final response = await http.post(
        Uri.parse('$profileHost/api/waves'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession!.accessToken}',
        },
        body: jsonEncode({'handle': widget.handle, 'note': value}),
      );
      if (mounted) {
        notice(
          context,
          response.statusCode == 200 ? 'Wave sent!' : 'Could not send wave.',
        );
      }
    } catch (e) {
      if (mounted) notice(context, 'Could not send wave: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('VibeDrop Profile')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final p = snapshot.data!;
        final links = (p['links'] as List? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          children: [
            Container(
              height: 130,
              decoration: const BoxDecoration(gradient: grad),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: pale,
                    backgroundImage: p['avatarUrl'] != null
                        ? NetworkImage(p['avatarUrl'] as String)
                        : null,
                    child: p['avatarUrl'] == null
                        ? Text(
                            (p['name'] as String)[0],
                            style: const TextStyle(fontSize: 30, color: purple),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p['name'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  Text(
                    '@${p['handle']}',
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (p['paused'] == true)
                    surface(
                      child: const Text('This profile is currently private.'),
                    )
                  else ...[
                    Text(p['bio'] as String? ?? ''),
                    if ((p['city'] as String? ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(p['city'] as String),
                      ),
                    if ((p['galleryUrls'] as List? ?? []).isNotEmpty) ...[
                      sectionTitle('Photos'),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final url
                                in (p['galleryUrls'] as List).cast<String>())
                              Padding(
                                padding: const EdgeInsets.only(right: 9),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    url,
                                    width: 112,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    sectionTitle('Links'),
                    for (final link in links)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => launchUrl(
                            Uri.parse('$profileHost/l/${link['id']}'),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: surface(
                            child: Row(
                              children: [
                                Icon(
                                  platformIcon(link['platform'] as String),
                                  color: purple,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    (link['label'] as String?)?.isNotEmpty ==
                                            true
                                        ? link['label'] as String
                                        : link['platform'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.open_in_new),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (p['canSaveContact'] == true)
                      primaryButton(
                        'Save Contact',
                        Icons.download,
                        () => launchUrl(
                          Uri.parse(
                            '$profileHost/u/${widget.handle}/vcard.vcf',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                        expanded: true,
                      ),
                    const SizedBox(height: 10),
                    softButton(
                      'Send Wave 👋',
                      Icons.waving_hand_outlined,
                      _wave,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.state});
  final VibeState state;
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final controller = MobileScannerController();
  bool processing = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handle(String value) async {
    if (processing) return;
    processing = true;
    await widget.state.addScan(value);
    if (!mounted) return;
    final uri = Uri.tryParse(value);
    final handle =
        uri?.host == Uri.parse(profileHost).host &&
            uri?.pathSegments.length == 2 &&
            uri?.pathSegments.first == 'u'
        ? uri!.pathSegments.last
        : null;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(handle == null ? 'QR scanned' : '@$handle'),
        content: Text(value),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (handle != null) {
                await Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (_) => ScannedProfilePage(handle: handle),
                  ),
                );
              } else if (uri != null &&
                  (uri.scheme == 'https' || uri.scheme == 'http')) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
    processing = false;
  }

  Future<void> _gallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final capture = await controller.analyzeImage(image.path);
    if (capture == null ||
        capture.barcodes.isEmpty ||
        capture.barcodes.first.rawValue == null) {
      if (mounted) notice(context, 'No QR code found in this image.');
      return;
    }
    await _handle(capture.barcodes.first.rawValue!);
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final value = capture.barcodes.firstOrNull?.rawValue;
          if (value != null) _handle(value);
        },
      ),
      Container(
        color: const Color(0x990D052C),
        height: 100,
        child: const Center(
          child: Text(
            'Scan a VibeDrop QR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.icon(
                onPressed: () => controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on),
                label: const Text('Flashlight'),
              ),
              FilledButton.icon(
                onPressed: _gallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key, required this.state});
  final VibeState state;
  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Connections',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
          ),
          if (cloudEnabled)
            IconButton(
              onPressed: widget.state.pullCloud,
              icon: const Icon(Icons.refresh, color: purple),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: ChoiceChip(
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(
                      ['Activity', 'Waves', 'Scans'][i],
                      textAlign: TextAlign.center,
                    ),
                  ),
                  selected: selected == i,
                  onSelected: (_) => setState(() => selected = i),
                  selectedColor: purple,
                  labelStyle: TextStyle(
                    color: selected == i ? Colors.white : ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      if (selected == 0) ...[
        sectionTitle('Recent Scans'),
        ..._scanTiles(),
        sectionTitle('Mutual Waves'),
        ..._waveTiles(),
      ] else if (selected == 1) ...[
        sectionTitle('Waves'),
        ..._waveTiles(),
      ] else ...[
        sectionTitle('Your scan history'),
        if (widget.state.history.isEmpty)
          _empty(
            'Nothing scanned yet',
            'Use the Scan tab to save a profile to your history.',
            Icons.history,
          )
        else
          ...widget.state.history.map(
            (url) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                onTap: () {
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: surface(
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, color: purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
      sectionTitle('Scanner Access'),
      surface(
        color: pale,
        child: const Row(
          children: [
            Icon(Icons.bar_chart, color: purple),
            SizedBox(width: 12),
            Expanded(
              child: Text('Detailed scan analytics are available with Pro.'),
            ),
          ],
        ),
      ),
    ],
  );
  List<Widget> _scanTiles() {
    if (widget.state.recentScans.isEmpty) {
      return [
        _empty(
          'No recent scans',
          'Scan activity will appear here when your QR is used.',
          Icons.qr_code_scanner,
        ),
      ];
    }
    return [
      for (final scan in widget.state.recentScans)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: surface(
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan['source'] == 'app' ? 'In-app scan' : 'Web scan',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${scan['device_os'] ?? 'Unknown device'} · ${scan['city'] ?? 'Location unavailable'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _waveTiles() {
    if (widget.state.waves.isEmpty) {
      return [
        _empty(
          'No waves yet',
          'Share your QR to start connecting.',
          Icons.waving_hand_outlined,
        ),
      ];
    }
    return [
      for (final wave in widget.state.waves)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: surface(
            child: Row(
              children: [
                const Icon(Icons.waving_hand_outlined, color: purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (wave['sender'] as Map?)?['display_name'] as String? ??
                            'VibeDrop user',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        (wave['note'] as String?)?.isNotEmpty == true
                            ? wave['note'] as String
                            : 'Waved at you',
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (wave['status'] == 'accepted')
                        const Text(
                          'Mutual Wave ✓',
                          style: TextStyle(
                            fontSize: 12,
                            color: purple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (wave['status'] == 'pending')
                  TextButton(
                    onPressed: () async {
                      final ok = await widget.state.acceptWave(
                        wave['id'] as String,
                      );
                      if (mounted) {
                        notice(
                          context,
                          ok ? 'Wave accepted!' : 'Could not accept wave.',
                        );
                      }
                    },
                    child: const Text('Wave back'),
                  ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _empty(String title, String subtitle, IconData icon) => surface(
    child: Row(
      children: [
        Icon(icon, color: purple, size: 29),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.state});
  final VibeState state;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final form = GlobalKey<FormState>();
  late final handle = TextEditingController(text: widget.state.profile.handle);
  late final name = TextEditingController(text: widget.state.profile.name);
  late final bio = TextEditingController(text: widget.state.profile.bio);
  late final city = TextEditingController(text: widget.state.profile.city);
  late final campus = TextEditingController(text: widget.state.profile.campus);
  late final phone = TextEditingController(text: widget.state.profile.phone);
  late final email = TextEditingController(text: widget.state.profile.email);
  late final company = TextEditingController(
    text: widget.state.profile.company,
  );
  late final designation = TextEditingController(
    text: widget.state.profile.designation,
  );
  late final links = widget.state.profile.links
      .map((e) => VibeLink.fromJson(e.toJson()))
      .toList();
  Future<void> _pickAvatar() async {
    if (!cloudEnabled) {
      notice(context, 'Connect Supabase to upload an avatar.');
      return;
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (image == null) return;
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final path = '${user.id}/avatar.jpg';
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      widget.state.profile.avatarUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);
      await widget.state.saveProfile(widget.state.profile);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) notice(context, 'Could not upload photo: $e');
    }
  }

  Future<void> _pickCover() async {
    if (!cloudEnabled) {
      notice(context, 'Connect Supabase to upload a cover.');
      return;
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (image == null) return;
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final path = '${user.id}/cover.jpg';
      await Supabase.instance.client.storage
          .from('covers')
          .uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      widget.state.profile.coverUrl = Supabase.instance.client.storage
          .from('covers')
          .getPublicUrl(path);
      await widget.state.saveProfile(widget.state.profile);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) notice(context, 'Could not upload cover: $e');
    }
  }

  Future<void> _pickGallery() async {
    if (!cloudEnabled) {
      notice(context, 'Connect Supabase to upload photos.');
      return;
    }
    if (widget.state.profile.galleryUrls.length >= 3) {
      notice(context, 'Free profiles can show up to 3 photos.');
      return;
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (image == null) return;
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('gallery')
          .uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      widget.state.profile.galleryUrls = [
        ...widget.state.profile.galleryUrls,
        Supabase.instance.client.storage.from('gallery').getPublicUrl(path),
      ];
      await widget.state.saveProfile(widget.state.profile);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) notice(context, 'Could not upload photo: $e');
    }
  }

  @override
  void dispose() {
    for (final c in [
      handle,
      name,
      bio,
      city,
      campus,
      phone,
      email,
      company,
      designation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    final p = widget.state.profile;
    p.handle = handle.text.trim().toLowerCase();
    p.name = name.text.trim();
    p.bio = bio.text.trim();
    p.city = city.text.trim();
    p.campus = campus.text.trim();
    p.phone = phone.text.trim();
    p.email = email.text.trim();
    p.company = company.text.trim();
    p.designation = designation.text.trim();
    p.links = links;
    await widget.state.saveProfile(p);
    if (mounted) {
      Navigator.pop(context);
      notice(context, widget.state.error ?? 'Profile saved');
    }
  }

  Future<void> _editLink({VibeLink? link}) async {
    final platform = TextEditingController(text: link?.platform ?? 'instagram');
    final value = TextEditingController(text: link?.value ?? '');
    String visibility = link?.visibility ?? 'both';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(link == null ? 'Add link' : 'Edit link'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: platform,
                  decoration: const InputDecoration(
                    labelText: 'Platform (e.g. instagram)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: value,
                  decoration: const InputDecoration(
                    labelText: 'Username, phone, or URL',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: const InputDecoration(labelText: 'Visible in'),
                  items: const [
                    DropdownMenuItem(value: 'both', child: Text('Both modes')),
                    DropdownMenuItem(value: 'social', child: Text('Social')),
                    DropdownMenuItem(value: 'work', child: Text('Work')),
                  ],
                  onChanged: (v) => update(() => visibility = v ?? 'both'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == true &&
        platform.text.trim().isNotEmpty &&
        value.text.trim().isNotEmpty) {
      setState(() {
        if (link == null) {
          links.add(
            VibeLink(
              platform: platform.text.trim().toLowerCase(),
              value: value.text.trim(),
              visibility: visibility,
            ),
          );
        } else {
          link.platform = platform.text.trim().toLowerCase();
          link.value = value.text.trim();
          link.visibility = visibility;
        }
      });
    }
    platform.dispose();
    value.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit Profile'),
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Column(
              children: [
                avatar(widget.state.profile, radius: 42),
                TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Change photo'),
                ),
                TextButton.icon(
                  onPressed: _pickCover,
                  icon: const Icon(Icons.wallpaper_outlined),
                  label: const Text('Change cover'),
                ),
              ],
            ),
          ),
          sectionTitle('Your identity'),
          _field(name, 'Display name', required: true),
          _field(
            handle,
            'Username',
            required: true,
            validator: (v) => RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(v ?? '')
                ? null
                : 'Use 3–24 lowercase letters, numbers or underscores.',
          ),
          _field(bio, 'Bio', maxLength: 150),
          _field(city, 'City'),
          _field(campus, 'Campus'),
          sectionTitle(
            'Gallery',
            trailing: IconButton(
              onPressed: _pickGallery,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: purple,
              ),
            ),
          ),
          if (widget.state.profile.galleryUrls.isEmpty)
            const Text('Add up to 3 photos to your social profile.')
          else
            SizedBox(
              height: 95,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (
                    var i = 0;
                    i < widget.state.profile.galleryUrls.length;
                    i++
                  )
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.state.profile.galleryUrls[i],
                              width: 95,
                              height: 95,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: IconButton.filledTonal(
                              onPressed: () async {
                                widget.state.profile.galleryUrls.removeAt(i);
                                await widget.state.saveProfile(
                                  widget.state.profile,
                                );
                                if (mounted) setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          sectionTitle('Contact details'),
          _field(phone, 'Phone number', keyboard: TextInputType.phone),
          _field(email, 'Email', keyboard: TextInputType.emailAddress),
          _field(company, 'Company / university'),
          _field(designation, 'Designation'),
          sectionTitle(
            'Social links',
            trailing: IconButton(
              onPressed: () => _editLink(),
              icon: const Icon(Icons.add_circle, color: purple),
            ),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: links.length,
            onReorderItem: (old, next) => setState(() {
              final item = links.removeAt(old);
              links.insert(next, item);
            }),
            itemBuilder: (context, i) => Padding(
              key: ValueKey(links[i]),
              padding: const EdgeInsets.only(bottom: 7),
              child: surface(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.drag_handle, color: purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _editLink(link: links[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                links[i].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                links[i].value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Switch(
                      value: links[i].active,
                      onChanged: (v) => setState(() => links[i].active = v),
                    ),
                    IconButton(
                      onPressed: () => setState(() => links.removeAt(i)),
                      icon: const Icon(Icons.delete_outline, size: 19),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          primaryButton('Save Profile', Icons.check, _save, expanded: true),
          if (cloudEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: TextButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('Sign out'),
              ),
            ),
        ],
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int? maxLength,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (v) =>
              required && (v == null || v.trim().isEmpty) ? 'Required' : null,
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onSignedIn});
  final VoidCallback onSignedIn;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool signup = false;
  bool busy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => busy = true);
    try {
      if (signup) {
        await Supabase.instance.client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );
        if (mounted) {
          notice(context, 'Check your email to verify your account.');
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
        widget.onSignedIn();
      }
    } catch (e) {
      if (mounted) notice(context, '$e');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _resetPassword() async {
    if (email.text.trim().isEmpty) {
      notice(context, 'Enter your email first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.text.trim(),
      );
      if (mounted) notice(context, 'Password reset email sent.');
    } catch (e) {
      if (mounted) notice(context, '$e');
    }
  }

  Future<void> _phoneOtp() async {
    final phone = TextEditingController();
    final token = TextEditingController();
    final number = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue with phone'),
        content: TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone with country code',
            hintText: '+94771234567',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, phone.text.trim()),
            child: const Text('Send code'),
          ),
        ],
      ),
    );
    if (number == null || number.isEmpty) {
      phone.dispose();
      token.dispose();
      return;
    }
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: number);
      if (!mounted) return;
      final code = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter SMS code'),
          content: TextField(
            controller: token,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'One-time code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, token.text.trim()),
              child: const Text('Verify'),
            ),
          ],
        ),
      );
      if (code != null && code.isNotEmpty) {
        await Supabase.instance.client.auth.verifyOTP(
          phone: number,
          token: code,
          type: OtpType.sms,
        );
        widget.onSignedIn();
      }
    } catch (e) {
      if (mounted) notice(context, '$e');
    }
    phone.dispose();
    token.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        children: [
          const Icon(Icons.auto_awesome, color: purple, size: 60),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'VibeDrop',
              style: TextStyle(
                color: ink,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Center(child: Text('Your digital identity, one QR.')),
          const SizedBox(height: 45),
          Text(
            signup ? 'Create your account' : 'Welcome back',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 16),
          primaryButton(
            signup ? 'Create account' : 'Sign in',
            Icons.arrow_forward,
            busy ? () {} : _submit,
            expanded: true,
          ),
          TextButton(
            onPressed: () => setState(() => signup = !signup),
            child: Text(
              signup
                  ? 'Already have an account? Sign in'
                  : 'New here? Create an account',
            ),
          ),
          if (!signup)
            TextButton(
              onPressed: _resetPassword,
              child: const Text('Forgot password?'),
            ),
          const SizedBox(height: 25),
          softButton('Continue with phone', Icons.phone_android, _phoneOtp),
          const SizedBox(height: 9),
          softButton(
            'Continue with Google',
            Icons.g_mobiledata,
            () => Supabase.instance.client.auth.signInWithOAuth(
              OAuthProvider.google,
            ),
          ),
          const SizedBox(height: 9),
          softButton(
            'Continue with Apple',
            Icons.apple,
            () => Supabase.instance.client.auth.signInWithOAuth(
              OAuthProvider.apple,
            ),
          ),
        ],
      ),
    ),
  );
}
