// client_dashboard.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analytics_dashboard.dart';
import 'dashboard_shared.dart';

/// Dedicated dashboard for a single client, opened from the Client List.
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

class _ClientDashboardState extends State<ClientDashboard>
    with TickerProviderStateMixin {
  /// 0 = Overview, 1 = Content, 2 = Social, 3 = Calendar, 4 = Queue,
  /// 5 = Published, 6 = Failed, 7 = Analytics
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
  late AnimationController _bgAnimationController;
  late Animation<double> _bgAnimation;

  final List<ScheduledPost> _localScheduled = [];

  // ── Date range for analytics
  DateRangeSelection _analyticsRange = DateRangeSelection(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
    label: 'Last 30 Days',
  );

  // ── Calendar state
  DateTime _calendarMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  // ── Calendar filter state
  String _calendarViewMode = 'Monthly';
  String? _calendarPlatformFilter;
  final Set<String> _calendarTypeFilters = {};

  bool _showSocialForm = false;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _localScheduled.addAll(widget.scheduledPosts);
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 720;

    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldLight,
          body: SafeArea(
            child: Column(
              children: [
                _buildClientTopBar(isMobile),
                _buildTabsRow(isMobile),
                const Divider(height: 1, color: AppColors.borderLight),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── HEADER: Back + Client identity + mini stats
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
            Container(
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
                border:
                Border.all(color: widget.client.logoColor.withOpacity(0.5)),
              ),
              child: widget.client.logoBytes != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(widget.client.logoBytes!,
                    fit: BoxFit.cover),
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
            ),
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
                    '${widget.client.socialHandles.length} social handle(s) • ${widget.client.email}',
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
                onPressed: () => setState(() => _tabIndex = 1),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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

  // ── TAB ROW
  Widget _buildTabsRow(bool isMobile) {
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected
                      ? t.color.withOpacity(0.14)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? t.color.withOpacity(0.55)
                        : AppColors.borderLight,
                    width: isSelected ? 1.4 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: t.color.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.icon,
                      size: 14,
                      color: isSelected
                          ? t.color
                          : AppColors.textDarkMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.label,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? t.color
                            : AppColors.textDarkSoft,
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

  // ── TAB CONTENT ROUTER
  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return CreateContentForm(
          clients: [_client],
          lockedClient: _client,
          onSave: (post) {
            setState(() => _localScheduled.add(post));
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
            setState(() => _tabIndex = 4); // Queue
          },
          onCancel: () => setState(() => _tabIndex = 0),
        );
      case 2:
        return _buildSocialTab();
      case 3:
        return _buildCalendarTab();
      case 4:
        return PublishingSections.buildPublishingQueue(
          _localScheduled,
          filterClientName: _client.companyName,
        );
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
        return PublishingSections.buildAnalyticsSection(
          widget.publishedPosts,
          filterClientName: _client.companyName,
          dateRange: _analyticsRange,
          onDateRangeTap: _showAnalyticsDateRangePicker,
        );
      default:
        return _buildOverviewTab();
    }
  }

  // ── SOCIAL TAB
  Widget _buildSocialTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildSectionTitle('Social Accounts'),
          const SizedBox(height: 4),
          Text(
            'Manage every social handle linked to ${_client.companyName}.',
            style: GoogleFonts.outfit(
                fontSize: 11.5, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 16),
          if (_showSocialForm)
            _buildInlineSocialForm()
          else
            _socialOptionCard(
              title: 'Add Handles',
              subtitle:
              'Link or update ${_client.companyName}\'s social media accounts.',
              icon: Icons.add_link_rounded,
              color: AppColors.purple,
              onTap: () => setState(() => _showSocialForm = true),
            ),
          const SizedBox(height: 20),
          buildSectionTitle(
              'Connected Platforms (${_client.socialHandles.length})'),
          const SizedBox(height: 4),
          Text(
            'Every platform linked to this client, shown as a clean list.',
            style: GoogleFonts.outfit(
                fontSize: 11.5, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 12),
          _buildConnectedPlatformsListView(),
        ],
      ),
    );
  }

  Widget _buildInlineSocialForm() {
    return SocialHandlesForm(
      client: _client,
      onSave: (updated) {
        setState(() {
          _client = updated;
          _showSocialForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Social handles saved for ${updated.companyName}',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.green.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onCancel: () => setState(() => _showSocialForm = false),
    );
  }

  Widget _socialOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.25),
                      color.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textDarkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedPlatformsListView() {
    final entries = <_ClientPlatformEntry>[];
    for (final p in kSocialPlatforms) {
      final handle = _client.socialHandles[p.name];
      if (handle != null && handle.isNotEmpty) {
        entries.add(_ClientPlatformEntry(
          platform: p,
          handle: handle,
          metaConnected: _client.metaConnected[p.name] ?? false,
        ));
      }
    }

    if (entries.isEmpty) {
      return buildEmptyState(
        icon: Icons.link_off_rounded,
        title: 'No platforms connected',
        subtitle: 'Tap "Add Handles" above to link this client\'s accounts.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: entries
          .map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _clientPlatformRow(e),
      ))
          .toList(),
    );
  }

  Widget _clientPlatformRow(_ClientPlatformEntry e) {
    final p = e.platform;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: p.color.withOpacity(0.06),
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
                  p.color.withOpacity(0.25),
                  p.color.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: p.color.withOpacity(0.4)),
            ),
            child: Icon(p.icon, color: p.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(p.icon, size: 11, color: p.color),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        e.handle,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: p.color,
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
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color:
              (e.metaConnected ? AppColors.green : AppColors.amber)
                  .withOpacity(0.15),
              border: Border.all(
                color:
                (e.metaConnected ? AppColors.green : AppColors.amber)
                    .withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  e.metaConnected
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  size: 11,
                  color: e.metaConnected
                      ? AppColors.green
                      : AppColors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  e.metaConnected ? 'Connected' : 'Pending',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: e.metaConnected
                        ? AppColors.green
                        : AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── OVERVIEW TAB
  Widget _buildOverviewTab() {
    final totalEngagement = widget.publishedPosts.fold<int>(
      0,
          (s, p) => s + p.likes + p.comments + p.shares,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildSectionTitle('Snapshot'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 600;
              final tiles = [
                _snapTile('Scheduled', '${_localScheduled.length}',
                    Icons.schedule_rounded, AppColors.cyan),
                _snapTile('Published', '${widget.publishedPosts.length}',
                    Icons.check_circle_rounded, AppColors.green),
                _snapTile('Failed', '${widget.failedPosts.length}',
                    Icons.error_rounded, AppColors.red),
                _snapTile('Engagement', _fmtInt(totalEngagement),
                    Icons.favorite_rounded, AppColors.pink),
              ];
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
                    .map((w) =>
                    SizedBox(width: (c.maxWidth - 12) / 2, child: w))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          buildSectionTitle('Client Info'),
          const SizedBox(height: 12),
          _clientInfoCard(),
          const SizedBox(height: 20),
          buildSectionTitle('Connected Platforms'),
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
            ..._localScheduled.take(3).map(buildPostCard),
        ],
      ),
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
    if (widget.client.socialHandles.isEmpty) {
      return buildEmptyState(
        icon: Icons.link_off_rounded,
        title: 'No handles linked',
        subtitle: 'Add handles from Social Accounts → Add Handles.',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.client.socialHandles.entries.map((e) {
        final p = kSocialPlatforms.firstWhere(
              (sp) => sp.name == e.key,
          orElse: () => SocialPlatform(
            name: e.key,
            icon: Icons.share_rounded,
            color: AppColors.cyan,
            handlePrefix: '@',
            allowedContentTypes: const ['Post'],
          ),
        );
        final meta = widget.client.metaConnected[e.key] ?? false;
        return Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                '${p.name} ${e.value}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.color,
                ),
              ),
              if (meta) ...[
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
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── CALENDAR TAB
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCalendarFilterRow(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 900;
              final calendar = _buildCalendar();
              final filteredPosts = _applyCalendarFilters(_localScheduled);
              final postsForDay = filteredPosts
                  .where((p) => isSameDay(p.scheduledAt, _selectedDate))
                  .toList();

              final postsCol = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildSectionTitle(
                      'Posts on ${formatDateLong(_selectedDate)}'),
                  const SizedBox(height: 10),
                  if (postsForDay.isEmpty)
                    buildEmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'Nothing scheduled',
                      subtitle: 'Pick another date or adjust filters.',
                    )
                  else
                    ...postsForDay.map(buildPostCard),
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
            const SizedBox(width: 16),
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
                _calendarTypeFilters.isNotEmpty) ...[
              const SizedBox(width: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _calendarPlatformFilter = null;
                    _calendarTypeFilters.clear();
                  }),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: AppColors.red.withOpacity(0.10),
                      border: Border.all(
                          color: AppColors.red.withOpacity(0.4)),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: selected
                ? color.withOpacity(0.16)
                : AppColors.scaffoldLight,
            border: Border.all(
              color: selected
                  ? color.withOpacity(0.65)
                  : AppColors.borderLight,
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
    final available = kSocialPlatforms
        .where((p) => (_client.socialHandles[p.name] ?? '').isNotEmpty)
        .toList();

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
        ...available.map((p) => PopupMenuItem<String?>(
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
        )),
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
              'Platform wise',
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
            if (_calendarPlatformFilter != null) ...[
              const SizedBox(width: 6),
              Text(
                '· ${_calendarPlatformFilter!}',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
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
      if (_calendarTypeFilters.isNotEmpty) {
        if (!_calendarTypeFilters.contains(p.type)) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    final filtered = _applyCalendarFilters(_localScheduled);

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
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
                  formatMonthYear(_calendarMonth),
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
                childAspectRatio: 1.05,
              ),
              itemCount: startWeekday + daysInMonth,
              itemBuilder: (context, i) {
                if (i < startWeekday) return const SizedBox();
                final day = i - startWeekday + 1;
                final date =
                DateTime(_calendarMonth.year, _calendarMonth.month, day);
                final isSelected = isSameDay(date, _selectedDate);
                final isToday = isSameDay(date, DateTime.now());
                final posts = filtered
                    .where((p) => isSameDay(p.scheduledAt, date))
                    .toList();

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
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
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (posts.isNotEmpty)
                          Positioned(
                            bottom: 3,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: posts.take(3).map((p) {
                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.color,
                                  ),
                                );
                              }).toList(),
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

  // ── Analytics date range
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

  Widget _presetRange(
      BuildContext ctx, String label, int days, DateTime now) {
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

class _ClientTab {
  final String label;
  final IconData icon;
  final Color color;
  _ClientTab(this.label, this.icon, this.color);
}

class _ClientPlatformEntry {
  final SocialPlatform platform;
  final String handle;
  final bool metaConnected;

  _ClientPlatformEntry({
    required this.platform,
    required this.handle,
    required this.metaConnected,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// CREATE CONTENT FORM — MULTI-MEDIA CAROUSEL + PLATFORM PREVIEW
// ═════════════════════════════════════════════════════════════════════════════
class CreateContentForm extends StatefulWidget {
  final List<ClientModel> clients;
  final ValueChanged<ScheduledPost> onSave;
  final VoidCallback onCancel;
  final ClientModel? lockedClient;

  const CreateContentForm({
    super.key,
    required this.clients,
    required this.onSave,
    required this.onCancel,
    this.lockedClient,
  });

  @override
  State<CreateContentForm> createState() => _CreateContentFormState();
}

class _CreateContentFormState extends State<CreateContentForm> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _caption = TextEditingController();

  ClientModel? _selectedClient;
  String? _selectedPlatform;
  String _contentType = 'Post';
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();

  /// Media items selected by the user (multi-select).
  final List<_PickedMedia> _mediaList = [];

  /// Index of the YouTube thumbnail selection (only used for YouTube).
  int? _youTubeThumbnailIndex;

  bool _showPreview = false;

  /// Accepted extensions for the picker.
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
    super.dispose();
  }

  // ── Aspect ratio per platform/type
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

  /// Platforms that don't require a title (title-less UI).
  bool get _hideTitleField =>
      _isInstagram || _isFacebook || _isThreads || _isYouTube;

  List<String> get _allowedContentTypes {
    if (_selectedPlatform == null) {
      return const ['Post', 'Reel', 'Story', 'Video'];
    }
    final platform = kSocialPlatforms.firstWhere(
          (p) => p.name == _selectedPlatform,
      orElse: () => kSocialPlatforms.first,
    );
    return platform.allowedContentTypes;
  }

  // ── Multi-file picker
  Future<void> _pickMedia() async {
    try {
      final isVideoType = _contentType == 'Reel' || _contentType == 'Video';
      final allowedExt = isVideoType
          ? _videoExt
          : [..._imageExt, ..._videoExt]; // allow mixing for posts
      final fileType = isVideoType
          ? FileType.custom
          : FileType.custom;

      final result = await FilePicker.platform.pickFiles(
        type: fileType,
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
          // Auto-pick first image as YouTube thumbnail if none yet
          if (_isYouTube && _youTubeThumbnailIndex == null) {
            final firstImage =
            _mediaList.indexWhere((m) => !m.isVideo);
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

    if (_showPreview) {
      return _buildPreviewScreen();
    }

    return _buildFormScreen();
  }

  // ── MAIN FORM
  Widget _buildFormScreen() {
    final availablePlatforms = _selectedClient == null
        ? <SocialPlatform>[]
        : kSocialPlatforms
        .where((p) => _selectedClient!.socialHandles.containsKey(p.name))
        .toList();

    final allowedTypes = _allowedContentTypes;

    if (_selectedPlatform != null && !allowedTypes.contains(_contentType)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _contentType = allowedTypes.first);
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

              // ── Step 1: Client
              Text(
                'Step 1 — Select Client',
                style: GoogleFonts.outfit(
                  color: AppColors.textDarkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ClientModel>(
                value: _selectedClient,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Client',
                  labelStyle:
                  GoogleFonts.outfit(color: AppColors.textDarkMuted),
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
                    borderSide: BorderSide(
                        color: AppColors.purple.withOpacity(0.6), width: 1.5),
                  ),
                ),
                items: widget.clients
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.companyName,
                    style: GoogleFonts.outfit(color: AppColors.textDark),
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

              // ── Step 2: Social account
              if (_selectedClient != null) ...[
                Text(
                  'Step 2 — Select Social Account',
                  style: GoogleFonts.outfit(
                    color: AppColors.textDarkSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
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
                    child: Text(
                      'This client has no social handles configured.',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.amber),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availablePlatforms.map((p) {
                      final isSelected = _selectedPlatform == p.name;
                      final handle =
                          _selectedClient!.socialHandles[p.name] ?? '';
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedPlatform = p.name;
                          _mediaList.clear();
                          _youTubeThumbnailIndex = null;
                          if (!p.allowedContentTypes.contains(_contentType)) {
                            _contentType = p.allowedContentTypes.first;
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
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
                                  if (handle.isNotEmpty)
                                    Text(
                                      handle,
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.5,
                                        color: AppColors.textDarkMuted,
                                      ),
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

              // ── Step 3: Content type
              if (_selectedPlatform != null) ...[
                Text(
                  'Step 3 — Content Type',
                  style: GoogleFonts.outfit(
                    color: AppColors.textDarkSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
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

              // ── Step 4: Media (multi-select carousel)
              if (_selectedPlatform != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Step 4 — Upload Media (multi-select carousel)',
                        style: GoogleFonts.outfit(
                          color: AppColors.textDarkSoft,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
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

                // Upload / dropzone
                _buildUploadZone(),
                const SizedBox(height: 12),

                // Carousel preview of picked media
                if (_mediaList.isNotEmpty) ...[
                  _buildCarousel(),
                  const SizedBox(height: 12),

                  // YouTube thumbnail picker
                  if (_isYouTube) ...[
                    Text(
                      'Choose YouTube Thumbnail',
                      style: GoogleFonts.outfit(
                        color: AppColors.textDarkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildThumbnailPicker(),
                    const SizedBox(height: 16),
                  ],
                ],
              ],

              // ── Step 5: Details (title hidden for IG/FB/Threads/YT)
              if (_selectedPlatform != null) ...[
                Text(
                  'Step 5 — Details',
                  style: GoogleFonts.outfit(
                    color: AppColors.textDarkSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (!_hideTitleField) ...[
                  TextFormField(
                    controller: _title,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: GoogleFonts.outfit(color: AppColors.textDark),
                    decoration: InputDecoration(
                      labelText: 'Post Title',
                      labelStyle:
                      GoogleFonts.outfit(color: AppColors.textDarkMuted),
                      filled: true,
                      fillColor: AppColors.scaffoldLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  style: GoogleFonts.outfit(color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Caption & Hashtags',
                    labelStyle:
                    GoogleFonts.outfit(color: AppColors.textDarkMuted),
                    filled: true,
                    fillColor: AppColors.scaffoldLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date + time
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
                          '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
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

                // Preview button
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

  // ── Upload zone
  Widget _buildUploadZone() {
    final aspect = _aspectRatioFor(_selectedPlatform, _contentType);
    return Center(
      child: ConstrainedBox(
        constraints:
        const BoxConstraints(maxHeight: 260, maxWidth: 320),
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
                    _mediaList.isEmpty
                        ? 'Tap to pick media'
                        : 'Add more media',
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

  // ── Carousel of picked media
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6),
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
                    fit: BoxFit.cover,
                    width: 110,
                    height: 140,
                  ),
                ),
              ),
              // Remove button
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
                      border: Border.all(
                          color: AppColors.red.withOpacity(0.8)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
              // Video badge
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

  // ── YouTube thumbnail picker
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
          style:
          GoogleFonts.outfit(fontSize: 11.5, color: AppColors.amber),
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
            onTap: () =>
                setState(() => _youTubeThumbnailIndex = entry.key),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.purple
                      : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(entry.value.bytes, fit: BoxFit.cover),
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

  // ── Open preview
  void _openPreview() {
    if (!_formKey.currentState!.validate() &&
        !_hideTitleField) {
      return;
    }
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

  // ── PREVIEW SCREEN (platform-specific)
  Widget _buildPreviewScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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

          // Platform-specific preview
          _buildPlatformPreview(),

          const SizedBox(height: 20),

          // Summary row (schedule at)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.cyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Scheduled at: ${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year} • ${_scheduledTime.format(context)}',
                    style: GoogleFonts.outfit(
                        fontSize: 12.5, color: AppColors.textDarkSoft),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showPreview = false),
                  icon: const Icon(Icons.edit_rounded,
                      size: 16, color: AppColors.textDark),
                  label: Text(
                    'Edit',
                    style:
                    GoogleFonts.outfit(color: AppColors.textDark),
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

  // ── Platform-specific preview builder
  Widget _buildPlatformPreview() {
    if (_isInstagram) return _instagramPreview();
    if (_isFacebook) return _facebookPreview();
    if (_isThreads) return _threadsPreview();
    if (_isYouTube) return _youTubePreview();
    if (_isLinkedIn) return _linkedInPreview();
    return _genericPreview();
  }

  // ── Instagram preview (multi-image carousel, no title)
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
          // Header row
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
                        _selectedClient!.socialHandles['Instagram'] ??
                            _selectedClient!.companyName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
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
          // Media carousel
          _mediaPreviewCarousel(
            height: 380,
            aspectRatio: _aspectRatioFor(_selectedPlatform, _contentType),
          ),
          // Indicator dots
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
          // Action row
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
          // Caption
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

  // ── Facebook preview (no title)
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
                  decoration: BoxDecoration(
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
          _mediaPreviewCarousel(
            height: 340,
            aspectRatio: _aspectRatioFor(_selectedPlatform, _contentType),
          ),
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
            child: Row(
              children: const [
                Icon(Icons.thumb_up_alt_outlined,
                    size: 18, color: AppColors.textDarkMuted),
                SizedBox(width: 6),
                Text('Like',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textDarkMuted)),
                SizedBox(width: 18),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: AppColors.textDarkMuted),
                SizedBox(width: 6),
                Text('Comment',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textDarkMuted)),
                SizedBox(width: 18),
                Icon(Icons.share_outlined,
                    size: 18, color: AppColors.textDarkMuted),
                SizedBox(width: 6),
                Text('Share',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textDarkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Threads preview
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
                  _selectedClient!.socialHandles['Threads'] ??
                      _selectedClient!.companyName,
                  style: GoogleFonts.outfit(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '2m',
                style: GoogleFonts.outfit(
                    fontSize: 11, color: AppColors.textDarkMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _caption.text.trim(),
            style: GoogleFonts.outfit(
                color: AppColors.textDark, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 10),
          _mediaPreviewCarousel(
            height: 280,
            aspectRatio: 4 / 5,
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.favorite_border_rounded,
                  size: 18, color: AppColors.textDarkMuted),
              SizedBox(width: 6),
              Text('0',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDarkMuted)),
              SizedBox(width: 18),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: AppColors.textDarkMuted),
              SizedBox(width: 6),
              Text('0',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDarkMuted)),
              SizedBox(width: 18),
              Icon(Icons.repeat_rounded,
                  size: 18, color: AppColors.textDarkMuted),
              SizedBox(width: 6),
              Text('0',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDarkMuted)),
              SizedBox(width: 18),
              Icon(Icons.send_outlined,
                  size: 18, color: AppColors.textDarkMuted),
            ],
          ),
        ],
      ),
    );
  }

  // ── YouTube preview (thumbnail-based)
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
          // Thumbnail
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: thumbBytes != null
                        ? Image.memory(thumbBytes, fit: BoxFit.cover)
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

  // ── LinkedIn preview
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
          _mediaPreviewCarousel(
            height: 320,
            aspectRatio: _aspectRatioFor(_selectedPlatform, _contentType),
          ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _LinkedInAction(icon: Icons.thumb_up_outlined, label: 'Like'),
                _LinkedInAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Comment'),
                _LinkedInAction(
                    icon: Icons.repeat_rounded, label: 'Repost'),
                _LinkedInAction(
                    icon: Icons.send_outlined, label: 'Send'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic preview (fallback)
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
          _mediaPreviewCarousel(
            height: 300,
            aspectRatio: _aspectRatioFor(_selectedPlatform, _contentType),
          ),
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

  // ── PageView carousel of selected media for preview
  Widget _mediaPreviewCarousel({
    required double height,
    required double aspectRatio,
  }) {
    final controller = PageController();
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: controller,
        itemCount: _mediaList.length,
        itemBuilder: (context, i) {
          final m = _mediaList[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: m.isVideo
                  ? Container(
                color: Colors.black,
                child: Column(
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
                ),
              )
                  : Image.memory(
                m.bytes,
                fit: BoxFit.cover,
                width: double.infinity,
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

  // ── Confirm & schedule
  void _confirmSchedule() {
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

    // Use first media's bytes as cover for the ScheduledPost model.
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
    ));
  }
}

// ── Small helper for LinkedIn action row
class _LinkedInAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LinkedInAction({required this.icon, required this.label});

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