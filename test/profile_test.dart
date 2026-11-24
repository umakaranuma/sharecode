import 'package:flutter_test/flutter_test.dart';
import 'package:sharecode/model.dart';

void main() {
  test('dynamic QR URL does not change with privacy mode', () {
    final profile = VibeProfile.demo();
    final url = profile.url;
    profile.mode = ProfileMode.work;
    profile.ghost = true;
    expect(profile.url, url);
    expect(profile.visibleLinks, isEmpty);
  });

  test('social and work modes filter links', () {
    final profile = VibeProfile.demo();
    expect(profile.visibleLinks.map((e) => e.platform), contains('instagram'));
    expect(
      profile.visibleLinks.map((e) => e.platform),
      isNot(contains('whatsapp')),
    );
    profile.mode = ProfileMode.work;
    expect(profile.visibleLinks.map((e) => e.platform), contains('whatsapp'));
    expect(
      profile.visibleLinks.map((e) => e.platform),
      isNot(contains('instagram')),
    );
  });

  test('WhatsApp local number becomes international wa.me URL', () {
    final link = VibeLink(platform: 'whatsapp', value: '077 123 4567');
    expect(link.url, 'https://wa.me/94771234567');
  });

  test('profile round trip preserves settings and links', () {
    final profile = VibeProfile.demo()
      ..mode = ProfileMode.custom
      ..qrColor = 0xFF1167F2
      ..galleryUrls = ['https://example.com/photo.jpg'];
    final restored = decodeProfile(encodeProfile(profile));
    expect(restored.mode, ProfileMode.custom);
    expect(restored.qrColor, 0xFF1167F2);
    expect(restored.links.length, 3);
    expect(restored.galleryUrls, ['https://example.com/photo.jpg']);
  });
}
