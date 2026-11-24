import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const profileHost = String.fromEnvironment(
  'PROFILE_HOST',
  defaultValue: 'https://yourapp.lk',
);
bool get cloudEnabled => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

class VibeState extends ChangeNotifier {
  VibeState._(this.profile, this.isDemo, this.history);
  factory VibeState.demo() => VibeState._(VibeProfile.demo(), true, []);
  VibeProfile profile;
  bool isDemo;
  List<String> history;
  int tab = 0;
  int scanCount = 0;
  int clickCount = 0;
  List<Map<String, dynamic>> recentScans = [];
  List<Map<String, dynamic>> waves = [];
  bool busy = false;
  String? error;

  String get publicUrl => '$profileHost/u/${profile.handle}';
  static Future<VibeState> load() async {
    final prefs = SharedPreferencesAsync();
    final saved = await prefs.getString('vibedrop_profile');
    final history = await prefs.getStringList('vibedrop_history') ?? [];
    final state = VibeState._(
      saved == null ? VibeProfile.demo() : decodeProfile(saved),
      saved == null,
      history,
    );
    if (cloudEnabled && Supabase.instance.client.auth.currentUser != null) {
      await state.pullCloud();
    }
    return state;
  }

  void setTab(int value) {
    tab = value;
    notifyListeners();
  }

  Future<void> saveProfile(VibeProfile value) async {
    profile = value;
    isDemo = false;
    notifyListeners();
    await SharedPreferencesAsync().setString(
      'vibedrop_profile',
      encodeProfile(profile),
    );
    if (cloudEnabled && Supabase.instance.client.auth.currentUser != null) {
      await pushCloud();
    }
  }

  Future<void> setMode(ProfileMode mode) async {
    profile.mode = mode;
    await saveProfile(profile);
  }

  Future<void> setGhost(bool value) async {
    profile.ghost = value;
    await saveProfile(profile);
  }

  Future<void> setQrColor(int value) async {
    profile.qrColor = value;
    await saveProfile(profile);
  }

  Future<void> addScan(String url) async {
    if (!history.contains(url)) history.insert(0, url);
    if (history.length > 50) history = history.take(50).toList();
    await SharedPreferencesAsync().setStringList('vibedrop_history', history);
    notifyListeners();
  }

  Future<void> pullCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) {
        profile = VibeProfile(
          handle: 'myvibe',
          name: user.email?.split('@').first ?? 'My Profile',
        );
        isDemo = false;
        notifyListeners();
        return;
      }
      final links = await client
          .from('social_links')
          .select()
          .eq('profile_id', user.id)
          .order('sort_order');
      final qrConfig = await client
          .from('qr_configs')
          .select()
          .eq('profile_id', user.id)
          .maybeSingle();
      profile = VibeProfile(
        handle: row['handle'] as String,
        name: row['display_name'] as String,
        bio: row['bio'] as String? ?? '',
        city: row['city'] as String? ?? '',
        campus: row['campus'] as String? ?? '',
        phone: row['phone'] as String? ?? '',
        email: row['contact_email'] as String? ?? '',
        company: row['company'] as String? ?? '',
        designation: row['designation'] as String? ?? '',
        avatarUrl: row['avatar_url'] as String? ?? '',
        coverUrl: row['cover_url'] as String? ?? '',
        galleryUrls: (row['gallery_urls'] as List? ?? []).cast<String>(),
        mode: ProfileMode.values.byName(
          row['privacy_mode'] as String? ?? 'social',
        ),
        ghost: row['is_paused'] as bool? ?? false,
        saveContact: row['allow_save_contact'] as bool? ?? true,
        qrColor:
            int.tryParse(
              'FF${(qrConfig?['fg_color'] as String? ?? '#6B20E8').replaceFirst('#', '')}',
              radix: 16,
            ) ??
            0xFF6B20E8,
        qrStyle:
            (qrConfig?['dot_style'] as String? ?? 'rounded').toLowerCase() ==
                'classic'
            ? 'Classic'
            : 'Rounded',
        links: links
            .map(
              (link) => VibeLink(
                platform: link['platform'] as String,
                label: link['label'] as String? ?? '',
                value: link['url_or_handle'] as String,
                visibility: link['visibility_mode'] as String? ?? 'both',
                active: link['is_active'] as bool? ?? true,
              ),
            )
            .toList(),
      );
      isDemo = false;
      await SharedPreferencesAsync().setString(
        'vibedrop_profile',
        encodeProfile(profile),
      );
      final scans = await client
          .from('qr_scans')
          .select('id')
          .eq('profile_id', user.id)
          .count(CountOption.exact);
      final clicks = await client
          .from('link_clicks')
          .select('id')
          .eq('profile_id', user.id)
          .count(CountOption.exact);
      scanCount = scans.count;
      clickCount = clicks.count;
      final scanRows = await client
          .from('qr_scans')
          .select('source,device_os,city,scanned_at')
          .eq('profile_id', user.id)
          .order('scanned_at', ascending: false)
          .limit(10);
      recentScans = scanRows.map((e) => Map<String, dynamic>.from(e)).toList();
      error = null;
      unawaited(loadWaves());
    } catch (e) {
      error = 'Could not load cloud profile: $e';
    }
    notifyListeners();
  }

  Future<void> loadWaves() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return;
    try {
      final response = await http
          .get(
            Uri.parse('$profileHost/api/waves'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        waves = (jsonDecode(response.body) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      /* The profile remains usable when the web service is offline. */
    }
  }

  Future<bool> acceptWave(String id) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$profileHost/api/waves/$id/accept'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        await loadWaves();
        return true;
      }
    } catch (_) {
      /* Show an action failure in the UI. */
    }
    return false;
  }

  Future<void> pushCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'handle': profile.handle,
        'display_name': profile.name,
        'bio': profile.bio,
        'city': profile.city,
        'campus': profile.campus,
        'phone': profile.phone,
        'contact_email': profile.email,
        'company': profile.company,
        'designation': profile.designation,
        'avatar_url': profile.avatarUrl.isEmpty ? null : profile.avatarUrl,
        'cover_url': profile.coverUrl.isEmpty ? null : profile.coverUrl,
        'gallery_urls': profile.galleryUrls,
        'privacy_mode': profile.mode.name,
        'is_paused': profile.ghost,
        'allow_save_contact': profile.saveContact,
      });
      await client.from('social_links').delete().eq('profile_id', user.id);
      if (profile.links.isNotEmpty) {
        await client.from('social_links').insert([
          for (var i = 0; i < profile.links.length; i++)
            {
              'profile_id': user.id,
              'platform': profile.links[i].platform,
              'label': profile.links[i].label.isEmpty
                  ? profile.links[i].title
                  : profile.links[i].label,
              'url_or_handle': profile.links[i].value,
              'visibility_mode': profile.links[i].visibility,
              'sort_order': i,
              'is_active': profile.links[i].active,
            },
        ]);
      }
      await client.from('qr_configs').upsert({
        'profile_id': user.id,
        'fg_color':
            '#${profile.qrColor.toRadixString(16).substring(2).toUpperCase()}',
        'dot_style': profile.qrStyle.toLowerCase(),
      });
    } catch (e) {
      error = 'Could not save to cloud: $e';
    }
    busy = false;
    notifyListeners();
  }

  String exportJson() => jsonEncode(profile.toJson());
}
