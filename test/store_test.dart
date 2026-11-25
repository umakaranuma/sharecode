import 'package:flutter_test/flutter_test.dart';
import 'package:sharecode/core/models.dart';
import 'package:sharecode/core/store.dart';

void main() {
  test('username availability', () {
    final s = AppStore();
    expect(s.usernameFree('kavi_dev'), isTrue);
    expect(s.usernameFree('Admin'), isFalse);
  });

  test('all modes are selectable; modes filter links', () {
    final s = AppStore();
    s.setMode(ProfileMode.custom);
    expect(s.mode, ProfileMode.custom);
    s.setMode(ProfileMode.social);
    final social = s.visibleLinks.length;
    s.setMode(ProfileMode.work);
    expect(s.visibleLinks.any((l) => l.platform == 'linkedin'), isTrue);
    expect(s.visibleLinks.length, isNot(social));
    s.setGhost(true);
    expect(s.visibleLinks, isEmpty);
  });

  test('upgrade unlocks pro and downgrade resets pro-only state', () {
    final s = AppStore()..upgrade('Yearly');
    s.setMode(ProfileMode.custom);
    expect(s.mode, ProfileMode.custom);
    s.downgrade();
    expect(s.pro, isFalse);
    expect(s.mode, ProfileMode.social);
  });

  test('waves: accept makes mutual and opens a chat', () {
    final s = AppStore();
    final w = s.waves.firstWhere((w) => w.status == WaveStatus.incoming);
    s.acceptWave(w.id);
    expect(w.status, WaveStatus.mutual);
    expect(s.chats[w.handle], isNotEmpty);
  });

  test('scanning saves to wallet once', () {
    final s = AppStore();
    final before = s.wallet.length;
    final c = s.nextScan();
    s.saveToWallet(c);
    s.saveToWallet(c);
    expect(s.wallet.length, before + 1);
  });

  test('reorder links', () {
    final s = AppStore();
    final first = s.me.links.first.id;
    s.reorderLinks(0, 2);
    expect(s.me.links[2].id, first);
  });
}
