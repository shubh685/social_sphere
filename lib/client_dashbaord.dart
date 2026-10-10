// client_dashboard.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'analytics_dashboard.dart';
import 'dashboard_shared.dart';
import 'meta_connect.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CONNECTED SOCIAL ACCOUNT MODEL
// ═════════════════════════════════════════════════════════════════════════════
class ConnectedSocialAccount {
  final String platform;
  final String accountId;
  final String accountName;
  final String handle;
  final String? pageAccessToken;
  final String? profilePicUrl;
  final int followers;

  ConnectedSocialAccount({
    required this.platform,
    required this.accountId,
    required this.accountName,
    required this.handle,
    this.pageAccessToken,
    this.profilePicUrl,
    this.followers = 0,
  });

  factory ConnectedSocialAccount.fromJson(Map<String, dynamic> j) {
    final nameRaw = j['account_name'] ?? j['name'] ?? j['username'] ?? j['handle'] ?? '';
    return ConnectedSocialAccount(
      platform: (j['platform'] ?? '').toString(),
      accountId: (j['account_id'] ?? '').toString(),
      accountName: nameRaw.toString(),
      handle: (j['handle'] ?? '').toString(),
      pageAccessToken: j['page_access_token']?.toString(),
      profilePicUrl: (j['account_picture'] ?? j['profile_pic_url'] ?? '')
          .toString()
          .isEmpty
          ? null
          : (j['account_picture'] ?? j['profile_pic_url']).toString(),
      followers: int.tryParse('${j['followers'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'account_id': accountId,
    'account_name': accountName,
    'handle': handle,
    'page_access_token': pageAccessToken,
    'profile_pic_url': profilePicUrl,
    'followers': followers,
  };
}

class ClientDashboard extends StatefulWidget {
  final ClientModel client;
  final List<ScheduledPost> scheduledPosts;
  final List<PublishedPost> publishedPosts;
  final List<FailedPost> failedPosts;
  final List<MediaItem> mediaArchive;
  final ValueChanged<ScheduledPost>? onScheduleNew;

  const ClientDashboard({
    super.key,
    required this.client,
    required this.scheduledPosts,
    required this.publishedPosts,
    required this.failedPosts,
    required this.mediaArchive,
    this.onScheduleNew,
  });

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  // ── Backend config ─────────────────────────────────────────────────────
  static const String _apiBase = 'http://192.168.1.17/socialee_sphere';
  static const String _agencyName = 'Grow Socialee';

  int _tabIndex = 0;

  late final List<_ClientTab> _tabs = [
    _ClientTab('Overview', Icons.dashboard_rounded, AppColors.cyan),
    _ClientTab('Content', Icons.edit_note_rounded, AppColors.green),
    _ClientTab('Social', Icons.share_rounded, AppColors.blue),
    _ClientTab('Calendar', Icons.calendar_month_rounded, AppColors.amber),
    _ClientTab('Queue', Icons.queue_rounded, AppColors.orange),
    _ClientTab('Published', Icons.check_circle_rounded, AppColors.green),
    _ClientTab('Failed', Icons.error_rounded, AppColors.red),
    _ClientTab('Analytics', Icons.analytics_rounded, AppColors.pink),
  ];
  late ClientModel _client;

  final List<ScheduledPost> _localScheduled = [];
  final Map<String, LiveEngagement> _liveEngagement = {};
  Timer? _liveUpdateTimer;
  final Set<String> _expandedPosts = {};

  final Map<String, ConnectedSocialAccount> _connectedAccounts = {};

  bool _isConnecting = false;
  String? _connectError;
  String? _currentlyConnectingPlatform;
  bool _isLoadingAccounts = false;

  DateRangeSelection _analyticsRange = DateRangeSelection(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
    label: 'Last 30 Days',
  );

  DateTime _calendarMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  String _calendarViewMode = 'Monthly';
  String? _calendarPlatformFilter;
  String? _calendarStatusFilter;
  final Set<String> _calendarTypeFilters = {};

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _localScheduled.addAll(widget.scheduledPosts);
    _initializeLiveEngagement();
    _startLiveUpdates();
    _loadConnectedAccountsFromClient();
  }

  void _loadConnectedAccountsFromClient() {
    for (final entry in _client.socialHandles.entries) {
      final platformName = entry.key;
      final handle = entry.value;
      if (handle.isEmpty) continue;

      _connectedAccounts[platformName] = ConnectedSocialAccount(
        platform: platformName,
        accountId: handle,
        accountName: platformName,
        handle: handle,
        profilePicUrl: null,
        followers: 0,
        pageAccessToken: null,
      );
    }
  }

  void _initializeLiveEngagement() {
    for (final post in _localScheduled) {
      final id = _postId(post);
      _liveEngagement[id] = LiveEngagement(
        likes: _randomBase(post.title.hashCode + 1),
        comments: _randomBase(post.title.hashCode + 2) ~/ 8,
        shares: _randomBase(post.title.hashCode + 3) ~/ 12,
        lastUpdated: DateTime.now(),
      );
    }
  }

  int _randomBase(int seed) {
    final n = (seed.abs() * 9301 + 49297) % 233280;
    return (n % 900) + 120;
  }

  void _startLiveUpdates() {
    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _simulateApiFetch();
    });
  }

  void _simulateApiFetch() {
    if (!mounted) return;
    bool changed = false;
    for (final post in _localScheduled) {
      if (post.status != PostStatus.live) continue;
      changed = true;
      break;
    }
    if (!changed) return;

    setState(() {
      for (final post in _localScheduled) {
        final id = _postId(post);
        final cur = _liveEngagement[id];
        if (cur == null) continue;
        if (post.status != PostStatus.live) continue;
        _liveEngagement[id] = cur.increment();
      }
    });
  }

  String _postId(ScheduledPost p) =>
      '${p.title}_${p.clientName}_${p.scheduledAt.millisecondsSinceEpoch}';

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 720;

    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildClientTopBar(isMobile),
            _buildTabsRow(),
            const Divider(height: 1, color: AppColors.borderLight),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildClientTopBar(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.scaffoldLight,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.textDark),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildClientAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.client.companyName,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: isMobile ? 15 : 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_connectedAccounts.length} connected account(s) • ${widget.client.email}',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.textDarkMuted),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (!isMobile)
              ElevatedButton.icon(
                onPressed: () {
                  if (_connectedAccounts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Connect at least one social account first (Social tab).',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                        backgroundColor: AppColors.amber.withOpacity(0.95),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    setState(() => _tabIndex = 2);
                    return;
                  }
                  setState(() => _tabIndex = 1);
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'New Content',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          colors: [
            widget.client.logoColor.withOpacity(0.4),
            widget.client.logoColor.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: widget.client.logoColor.withOpacity(0.5)),
      ),
      child: widget.client.logoBytes != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(widget.client.logoBytes!, fit: BoxFit.cover),
      )
          : Center(
        child: Text(
          widget.client.companyName.isNotEmpty
              ? widget.client.companyName[0].toUpperCase()
              : '?',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTabsRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final t = _tabs[i];
          final isSelected = _tabIndex == i;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _tabIndex = i),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected ? t.color.withOpacity(0.14) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? t.color.withOpacity(0.55)
                        : AppColors.borderLight,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.icon,
                      size: 14,
                      color: isSelected ? t.color : AppColors.textDarkMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.label,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? t.color : AppColors.textDarkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        if (_connectedAccounts.isEmpty) {
          return _buildNoAccountsState();
        }
        return ClientCreateContentForm(
          clients: [_client],
          lockedClient: _client,
          connectedAccounts: Map.unmodifiable(_connectedAccounts),
          onSave: (post) {
            setState(() {
              _localScheduled.add(post);
              _liveEngagement[_postId(post)] = LiveEngagement(
                likes: 0,
                comments: 0,
                shares: 0,
                lastUpdated: DateTime.now(),
              );
            });
            widget.onScheduleNew?.call(post);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Content scheduled for ${_client.companyName}',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.green.withOpacity(0.9),
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _tabIndex = 4);
          },
          onCancel: () => setState(() => _tabIndex = 0),
        );
      case 2:
        return _buildSocialTab();
      case 3:
        return _buildCalendarTab();
      case 4:
        return _buildEnhancedQueue();
      case 5:
        return PublishingSections.buildPublishedSection(
          widget.publishedPosts,
          filterClientName: _client.companyName,
        );
      case 6:
        return PublishingSections.buildFailedSection(
          widget.failedPosts,
          filterClientName: _client.companyName,
        );
      case 7:
        return _buildAnalyticsWithExport();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildNoAccountsState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildSectionTitle('Connect a Social Account First'),
          const SizedBox(height: 4),
          Text(
            'You need to connect at least one social account before you can schedule content.',
            style: GoogleFonts.outfit(
                fontSize: 11.5, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 20),
          buildEmptyState(
            icon: Icons.link_off_rounded,
            title: 'No accounts connected',
            subtitle:
            'Go to the Social tab and connect your business account details.',
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() => _tabIndex = 2),
            icon: const Icon(Icons.link_rounded,
                size: 16, color: Colors.white),
            label: Text(
              'Go to Social Tab',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SOCIAL TAB & META API VERIFICATION
  // ═════════════════════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════════════════
  // SOCIAL TAB & META API VERIFICATION VIA SDK
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildSocialTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: buildSectionTitle('Connect Social Accounts')),
              if (_isLoadingAccounts)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Connect your Facebook and Instagram accounts instantly using Meta Login, or verify individual profile links below.',
            style: GoogleFonts.outfit(
                fontSize: 11.5, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 14),
          // ── One-tap Meta SDK Login Button ──────────
          ElevatedButton.icon(
            onPressed: _connectAllMetaAccountsViaSdk,
            icon: const Icon(Icons.facebook_rounded, size: 18, color: Colors.white),
            label: Text(
              'Connect Meta Accounts via Facebook Login',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.facebook,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
          if (_connectError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectError!,
                      style: GoogleFonts.outfit(
                          fontSize: 11.5, color: AppColors.red),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _connectError = null),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.red),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...kSocialPlatforms
              .map((platform) => _buildPlatformConnectCard(platform)),
          const SizedBox(height: 24),
          buildSectionTitle(
              'Connected Accounts (${_connectedAccounts.length})'),
          const SizedBox(height: 4),
          Text(
            'These accounts are available for scheduling posts.',
            style: GoogleFonts.outfit(
                fontSize: 11.5, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 12),
          _buildConnectedAccountsList(),
        ],
      ),
    );
  }

  /// Automatically authenticates via flutter_facebook_auth and populates all managed pages & IG accounts
  Future<void> _connectAllMetaAccountsViaSdk() async {
    setState(() {
      _isConnecting = true;
      _currentlyConnectingPlatform = 'Facebook';
      _connectError = null;
    });

    try {
      await MetaApiService.loginAndAuthorize();
      final pages = await MetaApiService.fetchFacebookPages();

      for (final page in pages) {
        final pageId = (page['id'] ?? '').toString();
        final pageName = (page['name'] ?? '').toString();
        final pageToken = (page['access_token'] ?? '').toString();
        final fanCount = int.tryParse('${page['followers_count'] ?? page['fan_count'] ?? 0}') ?? 0;
        final picUrl = (page['picture']?['data']?['url'] ?? '').toString();
        final link = (page['link'] ?? 'https://facebook.com/$pageId').toString();

        if (pageId.isNotEmpty) {
          _connectedAccounts['Facebook'] = ConnectedSocialAccount(
            platform: 'Facebook',
            accountId: pageId,
            accountName: pageName,
            handle: link,
            pageAccessToken: pageToken,
            profilePicUrl: picUrl.isEmpty ? null : picUrl,
            followers: fanCount,
          );
        }

        final igRaw = page['instagram_business_account'];
        if (igRaw is Map) {
          final ig = Map<String, dynamic>.from(igRaw);
          final igId = (ig['id'] ?? '').toString();
          final igUsername = (ig['username'] ?? '').toString();
          final igName = (ig['name'] ?? igUsername).toString();
          final igFollowers = int.tryParse('${ig['followers_count'] ?? 0}') ?? 0;
          final igPic = (ig['profile_picture_url'] ?? '').toString();

          if (igId.isNotEmpty && igUsername.isNotEmpty) {
            _connectedAccounts['Instagram'] = ConnectedSocialAccount(
              platform: 'Instagram',
              accountId: igId,
              accountName: igName,
              handle: 'https://instagram.com/$igUsername',
              pageAccessToken: pageToken,
              profilePicUrl: igPic.isEmpty ? null : igPic,
              followers: igFollowers,
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meta accounts connected successfully!',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _connectError = 'Meta connection failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meta connection failed: $e',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppColors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _currentlyConnectingPlatform = null;
        });
      }
    }
  }

  Widget _buildPlatformConnectCard(SocialPlatform platform) {
    final connected = _connectedAccounts[platform.name];
    final isConnected = connected != null;
    final isConnecting = _currentlyConnectingPlatform == platform.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected
              ? platform.color.withOpacity(0.55)
              : AppColors.borderLight,
          width: isConnected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConnected ? platform.color : Colors.black)
                .withOpacity(isConnected ? 0.10 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  platform.color.withOpacity(0.25),
                  platform.color.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: platform.color.withOpacity(0.4)),
            ),
            child: connected?.profilePicUrl != null &&
                connected!.profilePicUrl!.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                connected.profilePicUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(platform.icon, color: platform.color, size: 22),
              ),
            )
                : Icon(platform.icon, color: platform.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        platform.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: AppColors.green.withOpacity(0.15),
                          border: Border.all(
                              color: AppColors.green.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 10, color: AppColors.green),
                            const SizedBox(width: 3),
                            Text(
                              'Connected',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected
                      ? '${connected.accountName} • ${connected.handle} (${connected.followers} followers)'
                      : 'Not connected yet',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: isConnected
                        ? platform.color
                        : AppColors.textDarkMuted,
                    fontWeight:
                    isConnected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isConnecting)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: platform.color.withOpacity(0.12),
                border:
                Border.all(color: platform.color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          platform.color),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Verifying...',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: platform.color,
                    ),
                  ),
                ],
              ),
            )
          else if (isConnected)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => _showConnectDialog(platform),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: platform.color.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Edit',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: platform.color)),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () => _disconnectPlatform(platform),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.red.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Disconnect',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red)),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () => _showConnectDialog(platform),
              icon: const Icon(Icons.link_rounded,
                  size: 14, color: Colors.white),
              label: Text(
                'Connect',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: platform.color,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showConnectDialog(SocialPlatform platform) async {
    final handleController = TextEditingController();

    final existing = _connectedAccounts[platform.name];
    if (existing != null) {
      handleController.text = existing.handle;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(platform.icon, color: platform.color, size: 24),
            const SizedBox(width: 10),
            Text('Connect ${platform.name}',
                style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the official profile link for ${platform.name}. Meta profile lookup works only for accounts the current token is allowed to access. A URL alone does not grant access; ask the client to authorize the account through your app when required.',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppColors.textDarkMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: handleController,
              decoration: InputDecoration(
                labelText: 'Social Handle / Profile Link URL',
                hintText: platform.name == 'Instagram' ||
                    platform.name == 'Facebook'
                    ? 'https://${platform.name.toLowerCase()}.com/yourhandle'
                    : '@yourhandle or profile URL',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.outfit(
                    color: AppColors.textDarkMuted,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final handle = handleController.text.trim();
              if (handle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid handle or profile link',
                        style: GoogleFonts.outfit(color: Colors.white)),
                    backgroundColor: AppColors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _saveManualConnection(platform, handle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: platform.color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Verify & Connect',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveManualConnection(
      SocialPlatform platform, String handle) async {
    setState(() {
      _isConnecting = true;
      _currentlyConnectingPlatform = platform.name;
      _connectError = null;
    });

    try {
      // ── Verify directly via MetaApiService in Flutter frontend ──────────
      final MetaVerifiedAccount? verified = await MetaApiService.resolve(
        platform: platform.name,
        handle: handle,
      );

      if (verified == null) {
        throw Exception(
            'Could not access this ${platform.name} account with the current Meta token. Check the URL and permissions, and confirm the client has authorized this account or that its Page is accessible to the token.');
      }

      final ConnectedSocialAccount enriched = ConnectedSocialAccount(
        platform: platform.name,
        accountId: verified.id,
        accountName: verified.name.isEmpty ? _client.companyName : verified.name,
        handle: verified.profileLink.isEmpty ? handle : verified.profileLink,
        pageAccessToken: verified.pageAccessToken,
        profilePicUrl:
        verified.pictureUrl.isEmpty ? null : verified.pictureUrl,
        followers: verified.followers,
      );

      if (!mounted) return;
      setState(() {
        _connectedAccounts[platform.name] = enriched;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${platform.name} verified and connected successfully!',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _connectError = 'Connection failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection failed: $e',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: AppColors.red.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _currentlyConnectingPlatform = null;
        });
      }
    }
  }

  Future<void> _disconnectPlatform(SocialPlatform platform) async {
    setState(() {
      _connectedAccounts.remove(platform.name);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${platform.name} disconnected.',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.amber.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildConnectedAccountsList() {
    if (_connectedAccounts.isEmpty) {
      return buildEmptyState(
        icon: Icons.link_off_rounded,
        title: 'No accounts connected',
        subtitle:
        'Tap "Connect" on a platform above to enter your business account handle/URL.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _connectedAccounts.values.map((acc) {
        final platform = kSocialPlatforms.firstWhere(
              (p) => p.name == acc.platform,
          orElse: () => kSocialPlatforms.first,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: platform.color.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: platform.color.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      platform.color.withOpacity(0.25),
                      platform.color.withOpacity(0.08),
                    ],
                  ),
                  border:
                  Border.all(color: platform.color.withOpacity(0.4)),
                ),
                child: acc.profilePicUrl != null &&
                    acc.profilePicUrl!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    acc.profilePicUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(platform.icon,
                            color: platform.color, size: 22),
                  ),
                )
                    : Icon(platform.icon, color: platform.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      acc.accountName,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(platform.icon, size: 11, color: platform.color),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${acc.handle} • ${acc.followers} followers',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: platform.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: AppColors.green.withOpacity(0.12),
                  border:
                  Border.all(color: AppColors.green.withOpacity(0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 11, color: AppColors.green),
                    const SizedBox(width: 4),
                    Text(
                      'API connected',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EXPANDABLE POST CARD & QUEUE
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildLivePostCard(ScheduledPost post) {
    final id = _postId(post);
    final live = _liveEngagement[id] ??
        LiveEngagement(
            likes: 0, comments: 0, shares: 0, lastUpdated: DateTime.now());

    final statusColor = _statusColor(post.status);
    final statusLabel = _statusLabel(post.status);
    final isExpanded = _expandedPosts.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: post.color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: post.color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: post.color.withOpacity(0.15),
                    border: Border.all(color: post.color.withOpacity(0.4)),
                  ),
                  child: Icon(_platformIcon(post.platform),
                      color: post.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.platform} • ${post.type}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(statusLabel, statusColor),
                const SizedBox(width: 6),
                _buildExpandChevron(post, id, isExpanded),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _buildExpandedBody(post, live),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandChevron(ScheduledPost post, String id, bool isExpanded) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedPosts.remove(id);
            } else {
              _expandedPosts.add(id);
            }
          });
        },
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.scaffoldLight,
            border: Border.all(
              color: isExpanded
                  ? post.color.withOpacity(0.6)
                  : AppColors.borderLight,
            ),
          ),
          child: Icon(
            isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isExpanded ? post.color : AppColors.textDarkMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedBody(ScheduledPost post, LiveEngagement live) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.caption.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              post.caption,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                color: AppColors.textDarkSoft,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 13, color: AppColors.textDarkMuted),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd MMM • HH:mm').format(post.scheduledAt),
              style: GoogleFonts.outfit(
                  fontSize: 11, color: AppColors.textDarkMuted),
            ),
            const Spacer(),
            const Icon(Icons.person_outline_rounded,
                size: 13, color: AppColors.textDarkMuted),
            const SizedBox(width: 4),
            Text(
              post.ownerName,
              style: GoogleFonts.outfit(
                  fontSize: 11, color: AppColors.textDarkMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.borderLight),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LiveCounter(
                icon: Icons.favorite_rounded,
                label: 'Likes',
                value: live.likes,
                color: AppColors.pink,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LiveCounter(
                icon: Icons.chat_bubble_rounded,
                label: 'Comments',
                value: live.comments,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LiveCounter(
                icon: Icons.share_rounded,
                label: 'Shares',
                value: live.shares,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.sync_rounded,
                size: 11, color: AppColors.textDarkMuted),
            const SizedBox(width: 4),
            Text(
              'Updated ${_timeAgo(live.lastUpdated)}',
              style: GoogleFonts.outfit(
                  fontSize: 9.5, color: AppColors.textDarkMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedQueue() {
    final scoped = _localScheduled
        .where((p) => p.clientName == _client.companyName)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: buildSectionTitle('Publishing Queue (${scoped.length})'),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: AppColors.green.withOpacity(0.12),
                  border: Border.all(color: AppColors.green.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live tracking',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time engagement metrics update automatically. Tap chevron to expand.',
            style: GoogleFonts.outfit(
                fontSize: 11.5, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 14),
          if (scoped.isEmpty)
            buildEmptyState(
              icon: Icons.queue_rounded,
              title: 'Queue is empty',
              subtitle: 'Scheduled posts will appear here.',
            )
          else
            ...scoped.map((post) => _buildLivePostCard(post)),
        ],
      ),
    );
  }

  Color _statusColor(PostStatus s) {
    switch (s) {
      case PostStatus.draft:
        return AppColors.textDarkMuted;
      case PostStatus.pendingApproval:
        return AppColors.amber;
      case PostStatus.scheduled:
        return AppColors.cyan;
      case PostStatus.live:
        return AppColors.green;
      case PostStatus.failed:
        return AppColors.red;
    }
  }

  String _statusLabel(PostStatus s) {
    switch (s) {
      case PostStatus.draft:
        return 'Draft';
      case PostStatus.pendingApproval:
        return 'Approval';
      case PostStatus.scheduled:
        return 'Scheduled';
      case PostStatus.live:
        return 'Live';
      case PostStatus.failed:
        return 'Failed';
    }
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'Live')
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.7), blurRadius: 4),
                ],
              ),
            ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'Facebook':
        return Icons.facebook_rounded;
      case 'Instagram':
        return Icons.camera_alt_rounded;
      case 'Threads':
        return Icons.alternate_email_rounded;
      case 'YouTube':
        return Icons.play_circle_fill_rounded;
      case 'LinkedIn':
        return Icons.business_center_rounded;
      default:
        return Icons.share_rounded;
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    final totalEngagement = widget.publishedPosts.fold<int>(
      0,
          (s, p) => s + p.likes + p.comments + p.shares,
    );

    final draftCount =
        _localScheduled.where((p) => p.status == PostStatus.draft).length;
    final approvalCount = _localScheduled
        .where((p) => p.status == PostStatus.pendingApproval)
        .length;
    final scheduledCount = _localScheduled
        .where((p) => p.status == PostStatus.scheduled)
        .length;
    final liveCount =
        _localScheduled.where((p) => p.status == PostStatus.live).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildSectionTitle('Workflow Snapshot'),
          const SizedBox(height: 12),
          _buildTileGrid([
            _snapTile('Drafts', '$draftCount', Icons.edit_note_rounded,
                AppColors.textDarkMuted),
            _snapTile('Approvals', '$approvalCount',
                Icons.how_to_reg_rounded, AppColors.amber),
            _snapTile('Scheduled', '$scheduledCount',
                Icons.schedule_rounded, AppColors.cyan),
            _snapTile('Live', '$liveCount', Icons.public_rounded,
                AppColors.green),
          ]),
          const SizedBox(height: 20),
          buildSectionTitle('Performance Snapshot'),
          const SizedBox(height: 12),
          _buildTileGrid([
            _snapTile('Published', '${widget.publishedPosts.length}',
                Icons.check_circle_rounded, AppColors.green),
            _snapTile('Failed', '${widget.failedPosts.length}',
                Icons.error_rounded, AppColors.red),
            _snapTile('Total Engagement', _fmtInt(totalEngagement),
                Icons.favorite_rounded, AppColors.pink),
          ]),
          const SizedBox(height: 20),
          buildSectionTitle('Client Info'),
          const SizedBox(height: 12),
          _clientInfoCard(),
          const SizedBox(height: 20),
          buildSectionTitle(
              'Connected Platforms (${_connectedAccounts.length})'),
          const SizedBox(height: 12),
          _connectedPlatformsWrap(),
          const SizedBox(height: 20),
          buildSectionTitle('Recent Scheduled'),
          const SizedBox(height: 12),
          if (_localScheduled.isEmpty)
            buildEmptyState(
              icon: Icons.schedule_rounded,
              title: 'No scheduled posts',
              subtitle: 'Schedule content from the Content tab.',
            )
          else
            ..._localScheduled.take(3).map((p) => _buildLivePostCard(p)),
        ],
      ),
    );
  }

  Widget _buildTileGrid(List<Widget> tiles) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 600;
        if (narrow) {
          return Column(
            children: tiles
                .map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: w,
            ))
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: tiles
              .map((w) => SizedBox(width: (c.maxWidth - 12) / 2, child: w))
              .toList(),
        );
      },
    );
  }

  Widget _snapTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.textDarkMuted)),
                Text(
                  value,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconLine(Icons.mail_outline_rounded, 'Email', widget.client.email),
          const SizedBox(height: 8),
          _iconLine(Icons.phone_outlined, 'Mobile', widget.client.mobile),
          const SizedBox(height: 8),
          _iconLine(
              Icons.location_on_outlined, 'Address', widget.client.address),
          if (widget.client.website.isNotEmpty) ...[
            const SizedBox(height: 8),
            _iconLine(
                Icons.language_rounded, 'Website', widget.client.website),
          ],
        ],
      ),
    );
  }

  Widget _iconLine(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: AppColors.scaffoldLight,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(icon, size: 15, color: AppColors.textDarkMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: AppColors.textDarkMuted)),
              Text(
                value.isEmpty ? '—' : value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _connectedPlatformsWrap() {
    if (_connectedAccounts.isEmpty) {
      return buildEmptyState(
        icon: Icons.link_off_rounded,
        title: 'No accounts connected',
        subtitle: 'Go to the Social tab to connect your pages.',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _connectedAccounts.values.map((acc) {
        final p = kSocialPlatforms.firstWhere(
              (sp) => sp.name == acc.platform,
          orElse: () => kSocialPlatforms.first,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: p.color.withOpacity(0.10),
            border: Border.all(color: p.color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(p.icon, size: 12, color: p.color),
              const SizedBox(width: 6),
              Text(
                '${p.name} • ${acc.accountName} (${acc.handle})',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.color,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CALENDAR TAB
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCalendarStatusSummary(),
          const SizedBox(height: 12),
          _buildCalendarFilterRow(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 900;
              final calendar = _buildCalendar();
              final filteredPosts = _applyCalendarFilters(_localScheduled);
              final postsForDay = filteredPosts
                  .where((p) => _isSameDay(p.scheduledAt, _selectedDate))
                  .toList();

              final postsCol = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildSectionTitle(
                      'Posts on ${DateFormat('EEE, dd MMM yyyy').format(_selectedDate)} (${postsForDay.length})'),
                  const SizedBox(height: 10),
                  if (postsForDay.isEmpty)
                    buildEmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'Nothing scheduled',
                      subtitle: 'Pick another date or adjust filters.',
                    )
                  else
                    ...postsForDay.map((p) => _buildLivePostCard(p)),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: calendar),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: postsCol),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  calendar,
                  const SizedBox(height: 20),
                  postsCol,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStatusSummary() {
    final all = _localScheduled;
    final drafts = all.where((p) => p.status == PostStatus.draft).length;
    final approvals =
        all.where((p) => p.status == PostStatus.pendingApproval).length;
    final scheduled =
        all.where((p) => p.status == PostStatus.scheduled).length;
    final live = all.where((p) => p.status == PostStatus.live).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Workflow',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusSummaryChip('Drafts', drafts, PostStatus.draft),
              _statusSummaryChip(
                  'Approvals', approvals, PostStatus.pendingApproval),
              _statusSummaryChip('Scheduled', scheduled, PostStatus.scheduled),
              _statusSummaryChip('Live', live, PostStatus.live),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusSummaryChip(String label, int count, PostStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDarkSoft,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: color.withOpacity(0.25),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _calendarFilterChip(
              label: 'Monthly',
              selected: _calendarViewMode == 'Monthly',
              color: AppColors.amber,
              onTap: () => setState(() => _calendarViewMode = 'Monthly'),
            ),
            const SizedBox(width: 8),
            _calendarFilterChip(
              label: 'Weekly',
              selected: _calendarViewMode == 'Weekly',
              color: AppColors.amber,
              onTap: () => setState(() => _calendarViewMode = 'Weekly'),
            ),
            const SizedBox(width: 16),
            _calendarPlatformDropdown(),
            const SizedBox(width: 12),
            _calendarStatusDropdown(),
            const SizedBox(width: 12),
            _calendarFilterChip(
              label: 'Post',
              selected: _calendarTypeFilters.contains('Post'),
              color: AppColors.cyan,
              onTap: () => _toggleCalendarType('Post'),
            ),
            const SizedBox(width: 8),
            _calendarFilterChip(
              label: 'Story',
              selected: _calendarTypeFilters.contains('Story'),
              color: AppColors.pink,
              onTap: () => _toggleCalendarType('Story'),
            ),
            const SizedBox(width: 8),
            _calendarFilterChip(
              label: 'Reel',
              selected: _calendarTypeFilters.contains('Reel'),
              color: AppColors.purple,
              onTap: () => _toggleCalendarType('Reel'),
            ),
            const SizedBox(width: 8),
            _calendarFilterChip(
              label: 'Videos',
              selected: _calendarTypeFilters.contains('Video'),
              color: AppColors.red,
              onTap: () => _toggleCalendarType('Video'),
            ),
            if (_calendarPlatformFilter != null ||
                _calendarStatusFilter != null ||
                _calendarTypeFilters.isNotEmpty) ...[
              const SizedBox(width: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _calendarPlatformFilter = null;
                    _calendarStatusFilter = null;
                    _calendarTypeFilters.clear();
                  }),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: AppColors.red.withOpacity(0.10),
                      border: Border.all(color: AppColors.red.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded,
                            size: 12, color: AppColors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _calendarFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color:
            selected ? color.withOpacity(0.16) : AppColors.scaffoldLight,
            border: Border.all(
              color:
              selected ? color.withOpacity(0.65) : AppColors.borderLight,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : AppColors.textDarkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarPlatformDropdown() {
    final available = _connectedAccounts.keys.toList();

    return PopupMenuButton<String?>(
      tooltip: 'Filter by platform',
      onSelected: (value) {
        setState(() => _calendarPlatformFilter = value);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Text(
            'All Platforms',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        ...available.map((name) {
          final p = kSocialPlatforms.firstWhere(
                (sp) => sp.name == name,
            orElse: () => kSocialPlatforms.first,
          );
          return PopupMenuItem<String?>(
            value: p.name,
            child: Row(
              children: [
                Icon(p.icon, size: 14, color: p.color),
                const SizedBox(width: 8),
                Text(
                  p.name,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: _calendarPlatformFilter != null
              ? AppColors.blue.withOpacity(0.16)
              : AppColors.scaffoldLight,
          border: Border.all(
            color: _calendarPlatformFilter != null
                ? AppColors.blue.withOpacity(0.65)
                : AppColors.borderLight,
            width: _calendarPlatformFilter != null ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _calendarPlatformFilter != null
                  ? 'Platform · ${_calendarPlatformFilter!}'
                  : 'Platform wise',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: _calendarPlatformFilter != null
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: _calendarPlatformFilter != null
                    ? AppColors.blue
                    : AppColors.textDarkSoft,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: _calendarPlatformFilter != null
                  ? AppColors.blue
                  : AppColors.textDarkMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarStatusDropdown() {
    return PopupMenuButton<PostStatus?>(
      tooltip: 'Filter by status',
      onSelected: (value) {
        setState(() => _calendarStatusFilter = value?.name);
      },
      itemBuilder: (context) => [
        PopupMenuItem<PostStatus?>(
          value: null,
          child: Text(
            'All Status',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        ...PostStatus.values.map((s) {
          final color = _statusColor(s);
          return PopupMenuItem<PostStatus?>(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(s),
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: _calendarStatusFilter != null
              ? AppColors.amber.withOpacity(0.16)
              : AppColors.scaffoldLight,
          border: Border.all(
            color: _calendarStatusFilter != null
                ? AppColors.amber.withOpacity(0.65)
                : AppColors.borderLight,
            width: _calendarStatusFilter != null ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _calendarStatusFilter != null
                  ? 'Status · $_calendarStatusFilter'
                  : 'Status',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: _calendarStatusFilter != null
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: _calendarStatusFilter != null
                    ? AppColors.amber
                    : AppColors.textDarkSoft,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: _calendarStatusFilter != null
                  ? AppColors.amber
                  : AppColors.textDarkMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCalendarType(String type) {
    setState(() {
      if (_calendarTypeFilters.contains(type)) {
        _calendarTypeFilters.remove(type);
      } else {
        _calendarTypeFilters.add(type);
      }
    });
  }

  List<ScheduledPost> _applyCalendarFilters(List<ScheduledPost> posts) {
    return posts.where((p) {
      if (_calendarPlatformFilter != null) {
        if (p.platform != _calendarPlatformFilter) return false;
      }
      if (_calendarStatusFilter != null) {
        if (p.status.name != _calendarStatusFilter) return false;
      }
      if (_calendarTypeFilters.isNotEmpty) {
        if (!_calendarTypeFilters.contains(p.type)) return false;
      }
      return true;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildCalendar() {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    final filtered = _applyCalendarFilters(_localScheduled);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _calNav(Icons.chevron_left_rounded, () {
                setState(() => _calendarMonth = DateTime(
                    _calendarMonth.year, _calendarMonth.month - 1));
              }),
              Text(
                DateFormat('MMMM yyyy').format(_calendarMonth),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              _calNav(Icons.chevron_right_rounded, () {
                setState(() => _calendarMonth = DateTime(
                    _calendarMonth.year, _calendarMonth.month + 1));
              }),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    color: AppColors.textDarkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.85,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final date =
              DateTime(_calendarMonth.year, _calendarMonth.month, day);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final posts = filtered
                  .where((p) => _isSameDay(p.scheduledAt, date))
                  .toList();

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppColors.amber.withOpacity(0.25)
                        : isToday
                        ? AppColors.cyan.withOpacity(0.15)
                        : AppColors.scaffoldLight,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.amber
                          : isToday
                          ? AppColors.cyan.withOpacity(0.6)
                          : AppColors.borderLight,
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          if (posts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.amber.withOpacity(0.25),
                              ),
                              child: Text(
                                '${posts.length}',
                                style: GoogleFonts.outfit(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: posts
                              .take(2)
                              .map((p) => _miniCalendarChip(p))
                              .toList(),
                        ),
                      ),
                      if (posts.length > 2)
                        Text(
                          '+${posts.length - 2}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDarkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _legend(AppColors.instagram, 'Instagram'),
              _legend(AppColors.facebook, 'Facebook'),
              _legend(AppColors.youtube, 'YouTube'),
              _legend(AppColors.linkedin, 'LinkedIn'),
              _legend(AppColors.threads, 'Threads'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniCalendarChip(ScheduledPost p) {
    final sc = _statusColor(p.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: p.color.withOpacity(0.15),
        border: Border.all(color: p.color.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle, color: sc),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              p.title,
              style: GoogleFonts.outfit(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calNav(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.scaffoldLight,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(icon, size: 15, color: AppColors.textDark),
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 9.5, color: AppColors.textDarkMuted)),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ANALYTICS WITH PDF EXPORT
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsWithExport() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Analytics Report',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportAnalyticsPdf,
                icon: _isExporting
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.picture_as_pdf_rounded,
                    size: 16, color: Colors.white),
                label: Text(
                  _isExporting ? 'Exporting...' : 'Download PDF',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),
        Expanded(
          child: PublishingSections.buildAnalyticsSection(
            widget.publishedPosts,
            filterClientName: _client.companyName,
            dateRange: _analyticsRange,
            onDateRangeTap: _showAnalyticsDateRangePicker,
          ),
        ),
      ],
    );
  }

  Future<void> _exportAnalyticsPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final doc = pw.Document();

      final pw.Font baseFont;
      final pw.Font boldFont;
      final pw.Font headingFont;
      try {
        baseFont = await PdfGoogleFonts.outfitRegular();
        boldFont = await PdfGoogleFonts.outfitBold();
        headingFont = await PdfGoogleFonts.bricolageGrotesqueBold();
      } catch (fontErr) {
        debugPrint('Font load failed: $fontErr');
        throw Exception(
            'Fonts could not be loaded. Please check your internet connection and try again.');
      }

      final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

      final published = widget.publishedPosts
          .where((p) => p.clientName == _client.companyName)
          .toList();
      final scheduled = _localScheduled
          .where((p) => p.clientName == _client.companyName)
          .toList();
      final failed = widget.failedPosts
          .where((p) => p.clientName == _client.companyName)
          .toList();

      final totalLikes = published.fold<int>(0, (s, p) => s + p.likes);
      final totalComments = published.fold<int>(0, (s, p) => s + p.comments);
      final totalShares = published.fold<int>(0, (s, p) => s + p.shares);
      final totalEngagement = totalLikes + totalComments + totalShares;

      final drafts =
          scheduled.where((p) => p.status == PostStatus.draft).length;
      final approvals = scheduled
          .where((p) => p.status == PostStatus.pendingApproval)
          .length;
      final scheduledCount =
          scheduled.where((p) => p.status == PostStatus.scheduled).length;
      final liveCount =
          scheduled.where((p) => p.status == PostStatus.live).length;

      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Socialee Sphere Analytics',
              style: pw.TextStyle(
                font: baseFont,
                fontSize: 8.5,
                color: PdfColors.grey600,
              ),
            ),
          ),
          footer: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                font: baseFont,
                fontSize: 8.5,
                color: PdfColors.grey600,
              ),
            ),
          ),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E1B4B),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _client.companyName,
                    style: pw.TextStyle(
                      font: headingFont,
                      fontSize: 20,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Analytics Report • ${_analyticsRange.label}',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 11,
                      color: PdfColors.grey300,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy • HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 9,
                      color: PdfColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Client Information', headingFont),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfInfoRow(
                      'Company', _client.companyName, baseFont, boldFont),
                  _pdfInfoRow('Email', _client.email, baseFont, boldFont),
                  _pdfInfoRow('Mobile', _client.mobile, baseFont, boldFont),
                  _pdfInfoRow('Address', _client.address, baseFont, boldFont),
                  if (_client.website.isNotEmpty)
                    _pdfInfoRow(
                        'Website', _client.website, baseFont, boldFont),
                  _pdfInfoRow(
                    'Connected Accounts',
                    '${_connectedAccounts.length} connected',
                    baseFont,
                    boldFont,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Key Performance Indicators', headingFont),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _pdfKpiCard('Total Likes', totalLikes, PdfColors.pink700,
                    baseFont, boldFont),
                pw.SizedBox(width: 8),
                _pdfKpiCard('Total Comments', totalComments,
                    PdfColors.cyan700, baseFont, boldFont),
                pw.SizedBox(width: 8),
                _pdfKpiCard('Total Shares', totalShares, PdfColors.green700,
                    baseFont, boldFont),
                pw.SizedBox(width: 8),
                _pdfKpiCard('Total Engagement', totalEngagement,
                    PdfColors.purple700, baseFont, boldFont),
              ],
            ),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Content Workflow Snapshot', headingFont),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _pdfKpiCard('Drafts', drafts, PdfColors.grey600, baseFont,
                    boldFont),
                pw.SizedBox(width: 8),
                _pdfKpiCard('Approvals', approvals, PdfColors.amber700,
                    baseFont, boldFont),
                pw.SizedBox(width: 8),
                _pdfKpiCard('Scheduled', scheduledCount, PdfColors.blue700,
                    baseFont, boldFont),
                pw.SizedBox(width: 8),
                _pdfKpiCard('Live', liveCount, PdfColors.green700, baseFont,
                    boldFont),
              ],
            ),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Published Posts Performance', headingFont),
            pw.SizedBox(height: 8),
            if (published.isEmpty)
              pw.Text('No published posts in this period.',
                  style: pw.TextStyle(font: baseFont, fontSize: 11))
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Post',
                  'Platform',
                  'Published',
                  'Likes',
                  'Comments',
                  'Shares',
                ],
                data: published.map((p) {
                  return [
                    p.title,
                    p.platform,
                    DateFormat('dd MMM yyyy').format(p.publishedAt),
                    '${p.likes}',
                    '${p.comments}',
                    '${p.shares}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF311042),
                ),
                cellStyle: pw.TextStyle(font: baseFont, fontSize: 9.5),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              ),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Scheduled Content Queue', headingFont),
            pw.SizedBox(height: 8),
            if (scheduled.isEmpty)
              pw.Text('No scheduled content.',
                  style: pw.TextStyle(font: baseFont, fontSize: 11))
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Title',
                  'Platform',
                  'Type',
                  'Status',
                  'Scheduled',
                  'Owner',
                ],
                data: scheduled.map((p) {
                  return [
                    p.title,
                    p.platform,
                    p.type,
                    _statusLabel(p.status),
                    DateFormat('dd MMM • HH:mm').format(p.scheduledAt),
                    p.ownerName,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1E1B4B)),
                cellStyle: pw.TextStyle(font: baseFont, fontSize: 9.5),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              ),
            pw.SizedBox(height: 20),
            if (failed.isNotEmpty) ...[
              _pdfSectionTitle('Failed Posts', headingFont),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Title',
                  'Platform',
                  'Failed',
                  'Reason',
                ],
                data: failed.map((p) {
                  return [
                    p.title,
                    p.platform,
                    DateFormat('dd MMM yyyy').format(p.failedAt),
                    p.reason,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFB91C1C)),
                cellStyle: pw.TextStyle(font: baseFont, fontSize: 9.5),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              ),
              pw.SizedBox(height: 20),
            ],
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 6),
            pw.Text(
              'Socialee Sphere • Confidential Analytics Report • ${_client.companyName}',
              style: pw.TextStyle(
                font: baseFont,
                fontSize: 9,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final safeName = _client.companyName
          .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_')
          .trim();
      final filename =
          'analytics_${safeName.isEmpty ? 'client' : safeName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF report generated successfully!',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.green.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('PDF export error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export PDF: $e',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.red.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfSectionTitle(String title, pw.Font fontHeading) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF311042), width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: fontHeading,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF311042),
        ),
      ),
    );
  }

  pw.Widget _pdfInfoRow(
      String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '—' : value,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfKpiCard(
      String label,
      int value,
      PdfColor color,
      pw.Font font,
      pw.Font fontBold,
      ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor(color.red, color.green, color.blue, 0.10),
          border: pw.Border.all(color: color, width: 0.8),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 8.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _fmtInt(value),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAnalyticsDateRangePicker() async {
    final now = DateTime.now();
    final result = await showModalBottomSheet<DateRangeSelection>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Reporting Period',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _presetRange(ctx, 'Last 7 Days', 7, now),
                _presetRange(ctx, 'Last 30 Days', 30, now),
                _presetRange(ctx, 'Last 90 Days', 90, now),
              ],
            ),
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _analyticsRange = result);
    }
  }

  Widget _presetRange(BuildContext ctx, String label, int days, DateTime now) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.cyan.withOpacity(0.12),
        ),
        child: const Icon(Icons.schedule_rounded,
            color: AppColors.cyan, size: 20),
      ),
      title: Text(label,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          )),
      onTap: () {
        Navigator.of(ctx).pop(DateRangeSelection(
          startDate: now.subtract(Duration(days: days)),
          endDate: now,
          label: label,
        ));
      },
    );
  }

  String _fmtInt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LIVE COUNTER WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class _LiveCounter extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _LiveCounter({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatValue(value),
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODELS
// ═════════════════════════════════════════════════════════════════════════════
class LiveEngagement {
  final int likes;
  final int comments;
  final int shares;
  final DateTime lastUpdated;

  LiveEngagement({
    required this.likes,
    required this.comments,
    required this.shares,
    required this.lastUpdated,
  });

  LiveEngagement increment() {
    return LiveEngagement(
      likes: likes + (1 + (DateTime.now().millisecond % 5)),
      comments: comments + (DateTime.now().millisecond % 3 == 0 ? 1 : 0),
      shares: shares + (DateTime.now().millisecond % 7 == 0 ? 1 : 0),
      lastUpdated: DateTime.now(),
    );
  }
}

class _ClientTab {
  final String label;
  final IconData icon;
  final Color color;
  _ClientTab(this.label, this.icon, this.color);
}

// ═════════════════════════════════════════════════════════════════════════════
// CLIENT CREATE CONTENT FORM
// ═════════════════════════════════════════════════════════════════════════════
class ClientCreateContentForm extends StatefulWidget {
  final List<ClientModel> clients;
  final ValueChanged<ScheduledPost> onSave;
  final VoidCallback onCancel;
  final ClientModel? lockedClient;
  final Map<String, ConnectedSocialAccount>? connectedAccounts;

  const ClientCreateContentForm({
    super.key,
    required this.clients,
    required this.onSave,
    required this.onCancel,
    this.lockedClient,
    this.connectedAccounts,
  });

  @override
  State<ClientCreateContentForm> createState() =>
      _ClientCreateContentFormState();
}

class _ClientCreateContentFormState extends State<ClientCreateContentForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _caption = TextEditingController();
  final _owner = TextEditingController(text: 'Admin');

  ClientModel? _selectedClient;
  String? _selectedPlatform;
  String _contentType = 'Post';
  PostStatus _status = PostStatus.draft;
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();

  final List<_PickedMedia> _mediaList = [];
  int? _youTubeThumbnailIndex;
  bool _showPreview = false;

  static const _imageExt = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
  static const _videoExt = ['mp4', 'mov', 'm4v', 'webm'];

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.lockedClient;
  }

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    _owner.dispose();
    super.dispose();
  }

  double _aspectRatioFor(String? platform, String type) {
    if (type == 'Reel' || type == 'Story') return 9 / 16;
    switch (platform) {
      case 'Instagram':
      case 'Threads':
      case 'LinkedIn':
        return 4 / 5;
      case 'Facebook':
        return type == 'Video' ? 16 / 9 : 1.0;
      case 'YouTube':
        return 16 / 9;
      default:
        return 1.0;
    }
  }

  bool get _isYouTube => _selectedPlatform == 'YouTube';
  bool get _isInstagram => _selectedPlatform == 'Instagram';
  bool get _isFacebook => _selectedPlatform == 'Facebook';
  bool get _isThreads => _selectedPlatform == 'Threads';
  bool get _isLinkedIn => _selectedPlatform == 'LinkedIn';

  bool get _hideTitleField =>
      _isInstagram || _isFacebook || _isThreads || _isYouTube;

  List<String> get _allowedContentTypes {
    if (_selectedPlatform == null) {
      return const ['Post', 'Reel', 'Story', 'Video'];
    }
    final matches = kSocialPlatforms
        .where((p) => p.name == _selectedPlatform)
        .toList();
    if (matches.isEmpty) {
      return const ['Post'];
    }
    final types = matches.first.allowedContentTypes;
    return types.isEmpty ? const ['Post'] : types;
  }

  Future<void> _pickMedia() async {
    try {
      final isVideoType = _contentType == 'Reel' || _contentType == 'Video';
      final allowedExt =
      isVideoType ? _videoExt : [..._imageExt, ..._videoExt];

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExt,
        allowMultiple: true,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = <_PickedMedia>[];
        for (final f in result.files) {
          final bytes = f.bytes;
          if (bytes == null) continue;
          final ext = (f.extension ?? '').toLowerCase();
          final isVideo = _videoExt.contains(ext);
          picked.add(_PickedMedia(
            bytes: bytes,
            fileName: f.name,
            isVideo: isVideo,
          ));
        }
        if (!mounted) return;
        setState(() {
          _mediaList.addAll(picked);
          if (_isYouTube && _youTubeThumbnailIndex == null) {
            final firstImage = _mediaList.indexWhere((m) => !m.isVideo);
            if (firstImage != -1) _youTubeThumbnailIndex = firstImage;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick media: $e'),
          backgroundColor: AppColors.red.withOpacity(0.9),
        ),
      );
    }
  }

  void _removeMediaAt(int index) {
    setState(() {
      _mediaList.removeAt(index);
      if (_youTubeThumbnailIndex == index) {
        _youTubeThumbnailIndex = null;
      } else if (_youTubeThumbnailIndex != null &&
          _youTubeThumbnailIndex! > index) {
        _youTubeThumbnailIndex = _youTubeThumbnailIndex! - 1;
      }
    });
  }

  void _clearAllMedia() => setState(() {
    _mediaList.clear();
    _youTubeThumbnailIndex = null;
  });

  @override
  Widget build(BuildContext context) {
    if (widget.clients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Please register a client first.',
            style: GoogleFonts.outfit(color: AppColors.textDarkMuted),
          ),
        ),
      );
    }

    if (_showPreview) return _buildPreviewScreen();
    return _buildFormScreen();
  }

  Widget _stepLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: AppColors.textDarkSoft,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: AppColors.textDarkMuted),
      filled: true,
      fillColor: AppColors.scaffoldLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        BorderSide(color: AppColors.purple.withOpacity(0.6), width: 1.5),
      ),
    );
  }

  Widget _buildFormScreen() {
    final accounts = widget.connectedAccounts ?? const {};
    final availablePlatforms = <SocialPlatform>[];
    for (final name in accounts.keys) {
      final matches =
      kSocialPlatforms.where((p) => p.name == name).toList();
      if (matches.isNotEmpty) availablePlatforms.add(matches.first);
    }

    final allowedTypes = _allowedContentTypes;

    if (_selectedPlatform != null && !allowedTypes.contains(_contentType)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && allowedTypes.isNotEmpty) {
          setState(() => _contentType = allowedTypes.first);
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Content',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _stepLabel('Step 1 — Select Client'),
              const SizedBox(height: 8),
              DropdownButtonFormField<ClientModel>(
                value: _selectedClient,
                dropdownColor: Colors.white,
                decoration: _inputDecoration('Client'),
                items: widget.clients
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.companyName,
                    style:
                    GoogleFonts.outfit(color: AppColors.textDark),
                  ),
                ))
                    .toList(),
                onChanged: widget.lockedClient != null
                    ? null
                    : (c) => setState(() {
                  _selectedClient = c;
                  _selectedPlatform = null;
                  _mediaList.clear();
                  _youTubeThumbnailIndex = null;
                }),
              ),
              const SizedBox(height: 16),
              if (_selectedClient != null) ...[
                _stepLabel('Step 2 — Select Connected Account'),
                const SizedBox(height: 8),
                if (availablePlatforms.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: AppColors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No connected accounts yet. Go to the Social tab to connect your pages.',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: AppColors.amber),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availablePlatforms.map((p) {
                      final isSelected = _selectedPlatform == p.name;
                      final acc = accounts[p.name];
                      if (acc == null) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedPlatform = p.name;
                          _mediaList.clear();
                          _youTubeThumbnailIndex = null;
                          final types = p.allowedContentTypes.isEmpty
                              ? const ['Post']
                              : p.allowedContentTypes;
                          if (!types.contains(_contentType)) {
                            _contentType = types.first;
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isSelected
                                ? p.color.withOpacity(0.15)
                                : AppColors.scaffoldLight,
                            border: Border.all(
                              color: isSelected
                                  ? p.color
                                  : AppColors.borderLight,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(p.icon, size: 16, color: p.color),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    p.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    acc.handle,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      color: AppColors.textDarkMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
              ],
              if (_selectedPlatform != null) ...[
                _stepLabel('Step 3 — Content Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allowedTypes.map((type) {
                    final isSelected = _contentType == type;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _contentType = type;
                        _mediaList.clear();
                        _youTubeThumbnailIndex = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient:
                          isSelected ? AppColors.primaryGradient : null,
                          color: isSelected ? null : AppColors.scaffoldLight,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cyan
                                : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type == 'Reel'
                                  ? Icons.movie_creation_rounded
                                  : type == 'Story'
                                  ? Icons.auto_stories_rounded
                                  : type == 'Video'
                                  ? Icons.videocam_rounded
                                  : Icons.article_rounded,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDarkSoft,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textDarkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedPlatform != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _stepLabel(
                          'Step 4 — Upload Media (multi-select carousel)'),
                    ),
                    if (_mediaList.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearAllMedia,
                        icon: const Icon(Icons.delete_sweep_rounded,
                            size: 14, color: AppColors.red),
                        label: Text(
                          'Clear All',
                          style: GoogleFonts.outfit(
                            color: AppColors.red,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Accepted: .mp4 .mov .webm .png .jpg .jpeg .webp .gif',
                  style: GoogleFonts.outfit(
                      fontSize: 10.5, color: AppColors.textDarkMuted),
                ),
                const SizedBox(height: 10),
                _buildUploadZone(),
                const SizedBox(height: 12),
                if (_mediaList.isNotEmpty) ...[
                  _buildCarousel(),
                  const SizedBox(height: 12),
                  if (_isYouTube) ...[
                    _stepLabel('Choose YouTube Thumbnail'),
                    const SizedBox(height: 6),
                    _buildThumbnailPicker(),
                    const SizedBox(height: 16),
                  ],
                ],
              ],
              if (_selectedPlatform != null) ...[
                _stepLabel('Step 5 — Details'),
                const SizedBox(height: 8),
                if (!_hideTitleField) ...[
                  TextFormField(
                    controller: _title,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                    style: GoogleFonts.outfit(color: AppColors.textDark),
                    decoration: _inputDecoration('Post Title'),
                  ),
                  const SizedBox(height: 12),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: AppColors.cyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.cyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isYouTube
                                ? 'YouTube uses video title from the video itself. Thumbnail selected above.'
                                : 'Title not required for $_selectedPlatform. Only caption will be used.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.textDarkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _caption,
                  maxLines: 3,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                  style: GoogleFonts.outfit(color: AppColors.textDark),
                  decoration: _inputDecoration('Caption & Hashtags'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _owner,
                  style: GoogleFonts.outfit(color: AppColors.textDark),
                  decoration: _inputDecoration('Content Owner'),
                ),
                const SizedBox(height: 12),
                _stepLabel('Workflow Status'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PostStatus.values.map((s) {
                    final color = clientStatusColor(s);
                    final isSelected = _status == s;
                    return GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected
                              ? color.withOpacity(0.15)
                              : AppColors.scaffoldLight,
                          border: Border.all(
                            color:
                            isSelected ? color : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              clientStatusLabel(s),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? color
                                    : AppColors.textDarkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _scheduledDate,
                            firstDate: DateTime.now(),
                            lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _scheduledDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.textDark),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(_scheduledDate),
                          style:
                          GoogleFonts.outfit(color: AppColors.textDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _scheduledTime,
                          );
                          if (picked != null) {
                            setState(() => _scheduledTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time_rounded,
                            size: 16, color: AppColors.textDark),
                        label: Text(
                          _scheduledTime.format(context),
                          style:
                          GoogleFonts.outfit(color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openPreview,
                  icon: const Icon(Icons.visibility_rounded,
                      size: 16, color: Colors.white),
                  label: Text(
                    'Preview & Schedule',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadZone() {
    final aspect = _aspectRatioFor(_selectedPlatform, _contentType);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
        child: AspectRatio(
          aspectRatio: aspect,
          child: GestureDetector(
            onTap: _pickMedia,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _mediaList.isNotEmpty
                      ? AppColors.purple.withOpacity(0.55)
                      : AppColors.borderLight,
                  width: _mediaList.isNotEmpty ? 1.8 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _mediaList.isEmpty
                        ? Icons.cloud_upload_rounded
                        : Icons.add_photo_alternate_rounded,
                    size: 44,
                    color: AppColors.purple.withOpacity(0.75),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _mediaList.isEmpty ? 'Tap to pick media' : 'Add more media',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: AppColors.textDarkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Multiple selection supported',
                    style: GoogleFonts.outfit(
                        fontSize: 10.5, color: AppColors.textDarkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final m = _mediaList[i];
          return Stack(
            children: [
              Container(
                width: 110,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                  border: Border.all(
                    color: m.isVideo
                        ? AppColors.red.withOpacity(0.45)
                        : AppColors.purple.withOpacity(0.35),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: m.isVideo
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded,
                          size: 42, color: AppColors.cyan),
                      const SizedBox(height: 6),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          m.fileName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                      : Image.memory(
                    m.bytes,
                    fit: BoxFit.contain,
                    width: 110,
                    height: 140,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeMediaAt(i),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                      border:
                      Border.all(color: AppColors.red.withOpacity(0.8)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
              if (m.isVideo)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: AppColors.red.withOpacity(0.85),
                    ),
                    child: Text(
                      'VIDEO',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumbnailPicker() {
    final images = <MapEntry<int, _PickedMedia>>[];
    for (var i = 0; i < _mediaList.length; i++) {
      if (!_mediaList[i].isVideo) images.add(MapEntry(i, _mediaList[i]));
    }
    if (images.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withOpacity(0.3)),
        ),
        child: Text(
          'Add at least one image to use as thumbnail.',
          style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.amber),
        ),
      );
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final entry = images[idx];
          final isSelected = _youTubeThumbnailIndex == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _youTubeThumbnailIndex = entry.key),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                  isSelected ? AppColors.purple : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(entry.value.bytes, fit: BoxFit.contain),
                    if (isSelected)
                      Container(
                        color: AppColors.purple.withOpacity(0.25),
                        child: const Center(
                          child: Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPreview() {
    if (!_hideTitleField && !_formKey.currentState!.validate()) return;
    if (_selectedClient == null || _selectedPlatform == null) return;
    if (_mediaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add at least one media item.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppColors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_caption.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add a caption.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppColors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _showPreview = true);
  }

  Widget _buildPreviewScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showPreview = false),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textDark),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Preview — $_selectedPlatform',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPlatformPreview(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.cyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Scheduled at: ${DateFormat('dd/MM/yyyy').format(_scheduledDate)} • ${_scheduledTime.format(context)}',
                        style: GoogleFonts.outfit(
                            fontSize: 12.5, color: AppColors.textDarkSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        color: AppColors.purple, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Owner: ${_owner.text.trim().isEmpty ? 'Admin' : _owner.text.trim()}',
                        style: GoogleFonts.outfit(
                            fontSize: 12.5, color: AppColors.textDarkSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle,
                        color: clientStatusColor(_status), size: 12),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: ${clientStatusLabel(_status)}',
                        style: GoogleFonts.outfit(
                            fontSize: 12.5, color: AppColors.textDarkSoft),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showPreview = false),
                  icon: const Icon(Icons.edit_rounded,
                      size: 16, color: AppColors.textDark),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.outfit(color: AppColors.textDark),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmSchedule,
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  label: Text(
                    'Confirm & Schedule',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformPreview() {
    if (_isInstagram) return _instagramPreview();
    if (_isFacebook) return _facebookPreview();
    if (_isThreads) return _threadsPreview();
    if (_isYouTube) return _youTubePreview();
    if (_isLinkedIn) return _linkedInPreview();
    return _genericPreview();
  }

  Widget _instagramPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.pink, AppColors.purple],
                    ),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Center(
                    child: Text(
                      _clientInitial(),
                      style: GoogleFonts.bricolageGrotesque(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accountHandleFor(_selectedPlatform) ??
                            _selectedClient!.companyName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _contentType == 'Story'
                            ? 'Story'
                            : _contentType == 'Reel'
                            ? 'Reels'
                            : 'Instagram',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded, color: Colors.white),
              ],
            ),
          ),
          _mediaPreviewCarousel(height: 420),
          if (_mediaList.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _mediaList.length,
                      (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? AppColors.cyan : Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                Icon(Icons.favorite_border_rounded,
                    color: Colors.white, size: 22),
                SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white, size: 22),
                SizedBox(width: 12),
                Icon(Icons.send_rounded, color: Colors.white, size: 22),
                Spacer(),
                Icon(Icons.bookmark_border_rounded,
                    color: Colors.white, size: 22),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Text(
              _caption.text.trim(),
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _facebookPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.facebook,
                  ),
                  child: Center(
                    child: Text(
                      _clientInitial(),
                      style: GoogleFonts.bricolageGrotesque(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedClient!.companyName,
                        style: GoogleFonts.outfit(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Just now • Public',
                        style: GoogleFonts.outfit(
                            color: AppColors.textDarkMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded,
                    color: AppColors.textDarkMuted),
              ],
            ),
          ),
          _mediaPreviewCarousel(height: 380),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _caption.text.trim(),
              style: GoogleFonts.outfit(
                  color: AppColors.textDark, fontSize: 12.5, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 18,
              runSpacing: 6,
              children: const [
                _FBPreviewAction(
                    icon: Icons.thumb_up_alt_outlined, label: 'Like'),
                _FBPreviewAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Comment'),
                _FBPreviewAction(
                    icon: Icons.share_outlined, label: 'Share'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _threadsPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: Center(
                  child: Text(
                    _clientInitial(),
                    style: GoogleFonts.bricolageGrotesque(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _accountHandleFor('Threads') ??
                      _selectedClient!.companyName,
                  style: GoogleFonts.outfit(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('2m',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.textDarkMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _caption.text.trim(),
            style: GoogleFonts.outfit(
                color: AppColors.textDark, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 10),
          _mediaPreviewCarousel(height: 320),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: const [
              _SimpleAction(
                  icon: Icons.favorite_border_rounded, label: '0'),
              _SimpleAction(
                  icon: Icons.chat_bubble_outline_rounded, label: '0'),
              _SimpleAction(icon: Icons.repeat_rounded, label: '0'),
              _SimpleAction(icon: Icons.send_outlined, label: ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _youTubePreview() {
    final thumbIndex = _youTubeThumbnailIndex;
    final thumbBytes = (thumbIndex != null &&
        thumbIndex >= 0 &&
        thumbIndex < _mediaList.length)
        ? _mediaList[thumbIndex].bytes
        : (_mediaList.isNotEmpty && !_mediaList.first.isVideo
        ? _mediaList.first.bytes
        : null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: thumbBytes != null
                        ? Image.memory(thumbBytes, fit: BoxFit.contain)
                        : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.white54,
                            size: 42),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.55),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '1:24',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.youtube,
                ),
                child: Center(
                  child: Text(
                    _clientInitial(),
                    style: GoogleFonts.bricolageGrotesque(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _caption.text.trim().isEmpty
                          ? 'Video Title'
                          : _caption.text.trim().split('\n').first,
                      style: GoogleFonts.outfit(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedClient!.companyName} • Just now',
                      style: GoogleFonts.outfit(
                          color: AppColors.textDarkMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert_rounded,
                  color: AppColors.textDarkMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkedInPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.linkedin,
                  ),
                  child: Center(
                    child: Text(
                      _clientInitial(),
                      style: GoogleFonts.bricolageGrotesque(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedClient!.companyName,
                        style: GoogleFonts.outfit(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Just now • 🌐',
                        style: GoogleFonts.outfit(
                            color: AppColors.textDarkMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_title.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _title.text.trim(),
                style: GoogleFonts.outfit(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 8),
          _mediaPreviewCarousel(height: 360),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _caption.text.trim(),
              style: GoogleFonts.outfit(
                  color: AppColors.textDark, fontSize: 12.5, height: 1.4),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 24,
              runSpacing: 6,
              alignment: WrapAlignment.spaceAround,
              children: const [
                _SimpleActionWithLabel(
                    icon: Icons.thumb_up_outlined, label: 'Like'),
                _SimpleActionWithLabel(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Comment'),
                _SimpleActionWithLabel(
                    icon: Icons.repeat_rounded, label: 'Repost'),
                _SimpleActionWithLabel(
                    icon: Icons.send_outlined, label: 'Send'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genericPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _title.text.trim(),
            style: GoogleFonts.outfit(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          _mediaPreviewCarousel(height: 340),
          const SizedBox(height: 10),
          Text(
            _caption.text.trim(),
            style: GoogleFonts.outfit(
                color: AppColors.textDark, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _mediaPreviewCarousel({required double height}) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: _mediaList.length,
        itemBuilder: (context, i) {
          final m = _mediaList[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: m.isVideo
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: AppColors.cyan, size: 64),
                    const SizedBox(height: 8),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        m.fileName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                )
                    : InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.memory(
                      m.bytes,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _clientInitial() {
    final n = _selectedClient?.companyName ?? '?';
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String? _accountHandleFor(String? platformName) {
    if (platformName == null) return null;
    return widget.connectedAccounts?[platformName]?.handle;
  }

  void _confirmSchedule() {
    if (_selectedClient == null || _selectedPlatform == null) return;

    final finalDate = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );
    final platform = kSocialPlatforms.firstWhere(
          (p) => p.name == _selectedPlatform,
      orElse: () => kSocialPlatforms.first,
    );

    final cover = _mediaList.isNotEmpty ? _mediaList.first.bytes : null;

    widget.onSave(ScheduledPost(
      title: _hideTitleField
          ? (_caption.text.trim().isNotEmpty
          ? _caption.text.trim().split('\n').first
          : 'Untitled')
          : _title.text.trim(),
      caption: _caption.text.trim(),
      clientName: _selectedClient!.companyName,
      platform: _selectedPlatform!,
      type: _contentType,
      scheduledAt: finalDate,
      color: platform.color,
      imageBytes: cover,
      status: _status,
      ownerName: _owner.text.trim().isEmpty ? 'Admin' : _owner.text.trim(),
    ));
  }
}

// ── Public status helpers
Color clientStatusColor(PostStatus s) {
  switch (s) {
    case PostStatus.draft:
      return AppColors.textDarkMuted;
    case PostStatus.pendingApproval:
      return AppColors.amber;
    case PostStatus.scheduled:
      return AppColors.cyan;
    case PostStatus.live:
      return AppColors.green;
    case PostStatus.failed:
      return AppColors.red;
  }
}

String clientStatusLabel(PostStatus s) {
  switch (s) {
    case PostStatus.draft:
      return 'Draft';
    case PostStatus.pendingApproval:
      return 'Pending Approval';
    case PostStatus.scheduled:
      return 'Scheduled';
    case PostStatus.live:
      return 'Live';
    case PostStatus.failed:
      return 'Failed';
  }
}

// ── Small reusable action widgets used in previews
class _FBPreviewAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FBPreviewAction({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textDarkMuted),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textDarkMuted)),
      ],
    );
  }
}

class _SimpleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SimpleAction({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textDarkMuted),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textDarkMuted)),
        ],
      ],
    );
  }
}

class _SimpleActionWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SimpleActionWithLabel({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textDarkMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            color: AppColors.textDarkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Internal media item model
class _PickedMedia {
  final Uint8List bytes;
  final String fileName;
  final bool isVideo;
  _PickedMedia({
    required this.bytes,
    required this.fileName,
    required this.isVideo,
  });
}