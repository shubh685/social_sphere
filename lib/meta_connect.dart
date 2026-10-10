// meta_connect.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Thrown when Meta Graph API returns an error we can surface to the UI.
class MetaApiException implements Exception {
  final String message;
  final int? code;
  final String? type;
  MetaApiException(this.message, {this.code, this.type});
  @override
  String toString() => 'MetaApiException($code/$type): $message';
}

/// Result object returned by MetaApiService methods.
class MetaVerifiedAccount {
  final String id;
  final String name;
  final String username;
  final int followers;
  final String pictureUrl;
  final String profileLink;
  final String pageId;
  final String pageAccessToken;

  MetaVerifiedAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.followers,
    required this.pictureUrl,
    required this.profileLink,
    this.pageId = '',
    this.pageAccessToken = '',
  });

  Map<String, dynamic> toJson() => {
    'account_id': id,
    'account_name': name,
    'username': username,
    'followers': followers,
    'profile_pic_url': pictureUrl,
    'profile_link': profileLink,
    'page_id': pageId,
    'page_access_token': pageAccessToken,
  };
}

class MetaApiService {
  /// Temporary or OAuth-authorized user access token from flutter_facebook_auth.
  static String userAccessToken = '';

  static const String graphVersion = 'v21.0';
  static const String _base = 'https://graph.facebook.com';

  /// Toggle to print every Graph API call + raw response.
  static bool debugLog = false;

  // ───────────────────────────────────────────────────────────────────────
  // FLUTTER_FACEBOOK_AUTH 7.2.0 INTEGRATION
  // ───────────────────────────────────────────────────────────────────────

  /// Triggers native Facebook Login using flutter_facebook_auth ^7.2.0
  /// and stores the resulting user access token.
  static Future<bool> loginAndAuthorize() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: [
          'public_profile',
          'email',
          'pages_show_list',
          'pages_read_engagement',
          'pages_manage_posts',
          'instagram_basic',
          'instagram_manage_insights',
        ],
      );

      if (result.status == LoginStatus.success && result.accessToken != null) {
        userAccessToken = result.accessToken!.tokenString;
        return true;
      }
      throw MetaApiException('Facebook login failed or was cancelled: ${result.status}');
    } catch (e) {
      if (e is MetaApiException) rethrow;
      throw MetaApiException('Facebook Auth error: $e');
    }
  }

  /// Checks if an active session already exists in flutter_facebook_auth.
  static Future<bool> checkExistingLogin() async {
    try {
      final tokenData = await FacebookAuth.instance.accessToken;
      if (tokenData != null) {
        userAccessToken = tokenData.tokenString;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Logs out from Facebook Auth.
  static Future<void> logout() async {
    try {
      await FacebookAuth.instance.logOut();
      userAccessToken = '';
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────────────────────────
  // SLUG EXTRACTORS
  // ───────────────────────────────────────────────────────────────────────
  static String extractFacebookSlug(String input) {
    input = input.trim();
    final uri = Uri.tryParse(input);
    if (uri != null &&
        (uri.host.toLowerCase() == 'facebook.com' ||
            uri.host.toLowerCase().endsWith('.facebook.com'))) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty && segments.first.toLowerCase() == 'people') {
        if (segments.length >= 3 && RegExp(r'^\d+$').hasMatch(segments[2])) {
          return segments[2];
        }
        if (segments.length >= 2) return Uri.decodeComponent(segments[1]);
      }
      if (segments.isNotEmpty) return Uri.decodeComponent(segments.first);
    }
    return input
        .replaceAll(RegExp(r'^[@/]+'), '')
        .split(RegExp(r'[?#]'))
        .first;
  }

  static String _normalizePageMatch(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String extractInstagramSlug(String input) {
    input = input.trim();
    final m = RegExp(
      r'https?://(?:www\.|m\.)?instagram\.com/([^/?#]+)',
      caseSensitive: false,
    ).firstMatch(input);
    if (m != null) return Uri.decodeComponent(m.group(1)!);
    return input.replaceAll(RegExp(r'^[@/]+'), '').split(RegExp(r'[?#]')).first;
  }

  static String extractThreadsSlug(String input) {
    input = input.trim();
    final m = RegExp(
      r'https?://(?:www\.|m\.)?threads\.(?:net|com)/@?([^/?#]+)',
      caseSensitive: false,
    ).firstMatch(input);
    if (m != null) return Uri.decodeComponent(m.group(1)!);
    return input.replaceAll(RegExp(r'^[@/]+'), '').split(RegExp(r'[?#]')).first;
  }

  static String extractYouTubeSlug(String input) {
    input = input.trim();
    final m = RegExp(
      r'https?://(?:www\.)?youtube\.com/(?:channel/|c/|@)?([^/?#]+)',
      caseSensitive: false,
    ).firstMatch(input);
    if (m != null) return Uri.decodeComponent(m.group(1)!);
    return input.replaceAll(RegExp(r'^[@/]+'), '').split(RegExp(r'[?#]')).first;
  }

  static String extractLinkedInSlug(String input) {
    input = input.trim();
    final m = RegExp(
      r'https?://(?:www\.)?linkedin\.com/(?:company|in)/([^/?#]+)',
      caseSensitive: false,
    ).firstMatch(input);
    if (m != null) return Uri.decodeComponent(m.group(1)!);
    return input.replaceAll(RegExp(r'^[@/]+'), '').split(RegExp(r'[?#]')).first;
  }

  // ───────────────────────────────────────────────────────────────────────
  // LOW-LEVEL GET
  // ───────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(Uri url) async {
    if (userAccessToken.isEmpty) {
      throw MetaApiException(
        'Meta access token is missing. Please authenticate via Facebook Login first.',
      );
    }

    final resp = await http.get(url).timeout(const Duration(seconds: 25));
    final raw = utf8.decode(resp.bodyBytes);

    if (debugLog) {
      print('[MetaGET] $url\n→ ${resp.statusCode} $raw');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw MetaApiException(
        'Non-JSON response (HTTP ${resp.statusCode}). Body: $raw',
      );
    }

    if (decoded is! Map) {
      throw MetaApiException('Unexpected response shape: $decoded');
    }
    final map = Map<String, dynamic>.from(decoded);

    final err = map['error'];
    if (err is Map) {
      throw MetaApiException(
        (err['message'] ?? 'Unknown Graph error').toString(),
        code: int.tryParse('${err['code'] ?? ''}'),
        type: err['type']?.toString(),
      );
    }
    return map;
  }

  static Future<Map<String, dynamic>?> _tryGet(Uri url) async {
    try {
      return await _get(url);
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // FACEBOOK
  // ───────────────────────────────────────────────────────────────────────
  static Future<MetaVerifiedAccount?> resolveFacebook(String handle) async {
    final slug = extractFacebookSlug(handle);
    if (slug.isEmpty) return null;

    final direct = await _tryGet(Uri.parse(
      '$_base/$graphVersion/${Uri.encodeComponent(slug)}'
          '?fields=id,name,username,fan_count,followers_count,link,picture.type(large)'
          '&access_token=$userAccessToken',
    ));
    if (direct != null && direct['id'] != null) {
      return _facebookFromNode(direct, slug);
    }

    final pages = await _fetchManagedPages();
    final target = _normalizePageMatch(slug);
    for (final page in pages) {
      final username = _normalizePageMatch((page['username'] ?? '').toString());
      final name = _normalizePageMatch((page['name'] ?? '').toString());
      final id = (page['id'] ?? '').toString().toLowerCase();
      if (id == slug.toLowerCase() ||
          (target.isNotEmpty && (username == target || name == target))) {
        return _facebookFromNode(page, slug);
      }
    }

    return null;
  }

  static MetaVerifiedAccount _facebookFromNode(
      Map<String, dynamic> node,
      String fallbackSlug,
      ) {
    return MetaVerifiedAccount(
      id: (node['id'] ?? '').toString(),
      name: (node['name'] ?? fallbackSlug).toString(),
      username: (node['username'] ?? fallbackSlug).toString(),
      followers: int.tryParse(
        '${node['followers_count'] ?? node['fan_count'] ?? 0}',
      ) ??
          0,
      pictureUrl: (node['picture']?['data']?['url'] ?? '').toString(),
      profileLink:
      (node['link'] ?? 'https://facebook.com/$fallbackSlug').toString(),
      pageId: (node['id'] ?? '').toString(),
      pageAccessToken: (node['access_token'] ?? '').toString(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // MANAGED PAGES
  // ───────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> _fetchManagedPages() async {
    final pages = <Map<String, dynamic>>[];

    final base = await _tryGet(Uri.parse(
      '$_base/$graphVersion/me/accounts'
          '?fields=id,name,username,link,fan_count,followers_count,access_token,picture.type(large)'
          '&limit=200'
          '&access_token=$userAccessToken',
    ));
    if (base != null && base['data'] is List) {
      for (final raw in base['data'] as List) {
        if (raw is Map) pages.add(Map<String, dynamic>.from(raw));
      }
    }

    for (final page in pages) {
      final id = page['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final ig = await _tryGet(Uri.parse(
        '$_base/$graphVersion/$id'
            '?fields=instagram_business_account{id,username,name,followers_count,profile_picture_url,biography,website}'
            '&access_token=$userAccessToken',
      ));
      if (ig != null && ig['instagram_business_account'] is Map) {
        page['instagram_business_account'] = ig['instagram_business_account'];
      }
    }
    return pages;
  }

  // ───────────────────────────────────────────────────────────────────────
  // INSTAGRAM
  // ───────────────────────────────────────────────────────────────────────
  static Future<MetaVerifiedAccount?> resolveInstagram(String handle) async {
    final username = extractInstagramSlug(handle);
    if (username.isEmpty) return null;

    final pages = await _fetchManagedPages();
    final target = username.toLowerCase();

    for (final page in pages) {
      final igRaw = page['instagram_business_account'];
      if (igRaw is! Map) continue;
      final ig = Map<String, dynamic>.from(igRaw);
      final u = (ig['username'] ?? '').toString().toLowerCase();
      if (u != target) continue;

      return MetaVerifiedAccount(
        id: (ig['id'] ?? '').toString(),
        name: (ig['name'] ?? ig['username'] ?? username).toString(),
        username: (ig['username'] ?? username).toString(),
        followers: int.tryParse('${ig['followers_count'] ?? 0}') ?? 0,
        pictureUrl: (ig['profile_picture_url'] ?? '').toString(),
        profileLink: 'https://instagram.com/${ig['username'] ?? username}',
        pageId: (page['id'] ?? '').toString(),
        pageAccessToken: (page['access_token'] ?? '').toString(),
      );
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────
  // NON-META PLATFORMS
  // ───────────────────────────────────────────────────────────────────────
  static Future<MetaVerifiedAccount?> resolveThreads(String handle) async {
    final username = extractThreadsSlug(handle);
    if (username.isEmpty) return null;
    return MetaVerifiedAccount(
      id: 'threads_$username',
      name: username,
      username: username,
      followers: 0,
      pictureUrl: '',
      profileLink: 'https://threads.net/@$username',
    );
  }

  static Future<MetaVerifiedAccount?> resolveYouTube(String handle) async {
    final slug = extractYouTubeSlug(handle);
    if (slug.isEmpty) return null;
    return MetaVerifiedAccount(
      id: 'yt_$slug',
      name: slug,
      username: slug,
      followers: 0,
      pictureUrl: '',
      profileLink: 'https://youtube.com/@$slug',
    );
  }

  static Future<MetaVerifiedAccount?> resolveLinkedIn(String handle) async {
    final slug = extractLinkedInSlug(handle);
    if (slug.isEmpty) return null;
    return MetaVerifiedAccount(
      id: 'li_$slug',
      name: slug,
      username: slug,
      followers: 0,
      pictureUrl: '',
      profileLink: 'https://linkedin.com/company/$slug',
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // MAIN ENTRY
  // ───────────────────────────────────────────────────────────────────────
  static Future<MetaVerifiedAccount?> resolve({
    required String platform,
    required String handle,
  }) async {
    switch (platform) {
      case 'Facebook':
        return resolveFacebook(handle);
      case 'Instagram':
        return resolveInstagram(handle);
      case 'Threads':
        return resolveThreads(handle);
      case 'YouTube':
        return resolveYouTube(handle);
      case 'LinkedIn':
        return resolveLinkedIn(handle);
    }
    return null;
  }

  static Future<List<String>> debugPermissions() async {
    final res = await _get(Uri.parse(
      '$_base/$graphVersion/me/permissions?access_token=$userAccessToken',
    ));
    final list = (res['data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .where((m) => m['status'] == 'granted')
        .map((m) => m['permission'].toString())
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchFacebookPages() async {
    return _fetchManagedPages();
  }
}