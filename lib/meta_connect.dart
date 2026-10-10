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

/// Snapshot of the currently authenticated Meta user + their managed assets.
class MetaSessionSnapshot {
  final String userId;
  final String userName;
  final String userAccessToken;
  final List<MetaVerifiedAccount> facebookPages;
  final List<MetaVerifiedAccount> instagramAccounts;
  final List<MetaVerifiedAccount> allAccounts;

  MetaSessionSnapshot({
    required this.userId,
    required this.userName,
    required this.userAccessToken,
    required this.facebookPages,
    required this.instagramAccounts,
    required this.allAccounts,
  });
}

class MetaApiService {
  /// User access token obtained from Facebook Login SDK.
  /// This is the *long-lived* user token (60 days) — used for all Graph API calls.
  static String userAccessToken = '';

  /// Short-lived token returned by the SDK (used only during exchange).
  static String _shortLivedToken = '';

  /// Detected user id for debugging.
  static String currentUserId = '';
  static String currentUserName = '';

  static const String graphVersion = 'v21.0';
  static const String _base = 'https://graph.facebook.com';

  /// Toggle to print every Graph API call + raw response.
  static bool debugLog = true;

  // ───────────────────────────────────────────────────────────────────────
  // FACEBOOK LOGIN (OAuth) — flutter_facebook_auth ^7.2.0
  // ───────────────────────────────────────────────────────────────────────

  /// Triggers native Facebook Login and returns true on success.
  /// Automatically exchanges the short-lived token for a long-lived one.
  static Future<bool> loginAndAuthorize() async {
    try {
      // 1) Ask Facebook for a short-lived user access token + permissions.
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: [
          'public_profile',
          'email',
          'pages_show_list',
          'pages_read_engagement',
          'pages_manage_posts',
          'pages_read_user_content',
          'instagram_basic',
          'instagram_manage_insights',
          'instagram_content_publish',
          'business_management',
        ],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw MetaApiException(
          'Facebook login failed or was cancelled: ${result.status}'
              '${result.message != null ? " — ${result.message}" : ""}',
        );
      }

      _shortLivedToken = result.accessToken!.tokenString;

      // 2) Exchange short-lived token for a long-lived one (60 days).
      final longLived = await _exchangeForLongLivedToken(_shortLivedToken);

      if (longLived != null && longLived.isNotEmpty) {
        userAccessToken = longLived;
      } else {
        // Fallback: use the short-lived token if exchange fails.
        userAccessToken = _shortLivedToken;
      }

      // 3) Cache the current user's id + name.
      await _loadCurrentUser();

      // 4) Optional: debug print permissions granted.
      if (debugLog) {
        try {
          final perms = await debugPermissions();
          print('[MetaAuth] Granted permissions: $perms');
          print('[MetaAuth] User: $currentUserName ($currentUserId)');
        } catch (_) {}
      }

      return true;
    } catch (e) {
      if (e is MetaApiException) rethrow;
      throw MetaApiException('Facebook Auth error: $e');
    }
  }

  /// Exchange a short-lived token for a 60-day long-lived user token.
  /// Requires an app access token of the form `{app-id}|{app-secret}`.
  static Future<String?> _exchangeForLongLivedToken(String shortToken) async {
    // NOTE: For security in production, the app secret should NOT live in
    // the client. In that case, route this exchange through your PHP backend.
    // For this build we call the Graph API directly using the app id + secret
    // that matches the Facebook App configured in flutter_facebook_auth.
    const appId = 'YOUR_FACEBOOK_APP_ID';        // <-- replace
    const appSecret = 'YOUR_FACEBOOK_APP_SECRET'; // <-- replace

    if (appId.startsWith('YOUR_') || appSecret.startsWith('YOUR_')) {
      if (debugLog) {
        print('[MetaAuth] App credentials not set — skipping long-lived exchange.');
      }
      return null;
    }

    try {
      final uri = Uri.parse(
        '$_base/oauth/access_token'
            '?grant_type=fb_exchange_token'
            '&client_id=$appId'
            '&client_secret=$appSecret'
            '&fb_exchange_token=$shortToken',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      final raw = utf8.decode(resp.bodyBytes);
      if (debugLog) print('[MetaAuth][exchange] $raw');
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['access_token'] is String) {
        return decoded['access_token'] as String;
      }
    } catch (e) {
      if (debugLog) print('[MetaAuth][exchange] failed: $e');
    }
    return null;
  }

  /// Loads the currently authenticated user's id and name.
  static Future<void> _loadCurrentUser() async {
    if (userAccessToken.isEmpty) return;
    try {
      final res = await _get(Uri.parse(
        '$_base/$graphVersion/me?fields=id,name&access_token=$userAccessToken',
      ));
      currentUserId = (res['id'] ?? '').toString();
      currentUserName = (res['name'] ?? '').toString();
    } catch (_) {}
  }

  /// Checks if an active session already exists in flutter_facebook_auth.
  static Future<bool> checkExistingLogin() async {
    try {
      final tokenData = await FacebookAuth.instance.accessToken;
      if (tokenData != null && tokenData.tokenString.isNotEmpty) {
        userAccessToken = tokenData.tokenString;
        await _loadCurrentUser();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Logs out from Facebook Auth.
  static Future<void> logout() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    userAccessToken = '';
    _shortLivedToken = '';
    currentUserId = '';
    currentUserName = '';
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

  static String _normalizePageMatch(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

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
  // MANAGED PAGES (Facebook + linked Instagram Business Accounts)
  // ───────────────────────────────────────────────────────────────────────

  /// Fetches every Facebook Page the authenticated user manages, together
  /// with the linked Instagram Business Account (if any). This is the
  /// canonical source of truth for the client dashboard.
  static Future<List<Map<String, dynamic>>> fetchFacebookPages() async {
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

    // For each page, fetch its linked Instagram Business Account.
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

  /// Convenience wrapper that converts raw page maps into [MetaVerifiedAccount].
  static Future<List<MetaVerifiedAccount>> fetchManagedPagesAsAccounts() async {
    final raw = await fetchFacebookPages();
    final out = <MetaVerifiedAccount>[];
    for (final page in raw) {
      out.add(_facebookFromNode(page, (page['username'] ?? page['id'] ?? '').toString()));
    }
    return out;
  }

  /// Convenience wrapper that converts linked IG accounts into [MetaVerifiedAccount].
  static Future<List<MetaVerifiedAccount>> fetchManagedInstagramAccounts() async {
    final raw = await fetchFacebookPages();
    final out = <MetaVerifiedAccount>[];
    for (final page in raw) {
      final igRaw = page['instagram_business_account'];
      if (igRaw is! Map) continue;
      final ig = Map<String, dynamic>.from(igRaw);
      out.add(MetaVerifiedAccount(
        id: (ig['id'] ?? '').toString(),
        name: (ig['name'] ?? ig['username'] ?? '').toString(),
        username: (ig['username'] ?? '').toString(),
        followers: int.tryParse('${ig['followers_count'] ?? 0}') ?? 0,
        pictureUrl: (ig['profile_picture_url'] ?? '').toString(),
        profileLink: 'https://instagram.com/${ig['username'] ?? ''}',
        pageId: (page['id'] ?? '').toString(),
        pageAccessToken: (page['access_token'] ?? '').toString(),
      ));
    }
    return out;
  }

  // ───────────────────────────────────────────────────────────────────────
  // FACEBOOK — single handle resolution
  // ───────────────────────────────────────────────────────────────────────
  static Future<MetaVerifiedAccount?> resolveFacebook(String handle) async {
    final slug = extractFacebookSlug(handle);
    if (slug.isEmpty) return null;

    // 1) Direct node lookup (works for page id or username).
    final direct = await _tryGet(Uri.parse(
      '$_base/$graphVersion/${Uri.encodeComponent(slug)}'
          '?fields=id,name,username,fan_count,followers_count,link,picture.type(large)'
          '&access_token=$userAccessToken',
    ));
    if (direct != null && direct['id'] != null) {
      return _facebookFromNode(direct, slug);
    }

    // 2) Fallback: match against managed pages.
    final pages = await fetchFacebookPages();
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
  // INSTAGRAM — single handle resolution
  // ───────────────────────────────────────────────────────────────────────
  static Future<MetaVerifiedAccount?> resolveInstagram(String handle) async {
    final username = extractInstagramSlug(handle);
    if (username.isEmpty) return null;

    final pages = await fetchFacebookPages();
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
  // NON-META PLATFORMS (local slug validation only)
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

  // ───────────────────────────────────────────────────────────────────────
  // DEBUG
  // ───────────────────────────────────────────────────────────────────────
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
}