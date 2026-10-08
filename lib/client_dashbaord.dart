// client_dashboard.dart
import 'package:flutter/material.dart';
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
  /// 0 = Overview, 1 = Content, 2 = Calendar, 3 = Queue, 4 = Published,
  /// 5 = Failed, 6 = Analytics
  int _tabIndex = 0;

  late final List<_ClientTab> _tabs = [
    _ClientTab('Overview', Icons.dashboard_rounded, AppColors.cyan),
    _ClientTab('Content', Icons.edit_note_rounded, AppColors.green),
    _ClientTab('Calendar', Icons.calendar_month_rounded, AppColors.amber),
    _ClientTab('Queue', Icons.queue_rounded, AppColors.orange),
    _ClientTab('Published', Icons.check_circle_rounded, AppColors.green),
    _ClientTab('Failed', Icons.error_rounded, AppColors.red),
    _ClientTab('Analytics', Icons.analytics_rounded, AppColors.pink),
  ];

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

  @override
  void initState() {
    super.initState();
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
            // Client logo
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
            // Client name + subtitle
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
            // Quick "Add content" pill
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

  // ── TAB ROW (scrollable on mobile)
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
          clients: [widget.client],
          lockedClient: widget.client,
          onSave: (post) {
            setState(() => _localScheduled.add(post));
            widget.onScheduleNew?.call(post);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Content scheduled for ${widget.client.companyName}',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.green.withOpacity(0.9),
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _tabIndex = 3); // jump to Queue
          },
          onCancel: () => setState(() => _tabIndex = 0),
        );
      case 2:
        return _buildCalendarTab();
      case 3:
        return PublishingSections.buildPublishingQueue(
          _localScheduled,
          filterClientName: widget.client.companyName,
        );
      case 4:
        return PublishingSections.buildPublishedSection(
          widget.publishedPosts,
          filterClientName: widget.client.companyName,
        );
      case 5:
        return PublishingSections.buildFailedSection(
          widget.failedPosts,
          filterClientName: widget.client.companyName,
        );
      case 6:
        return PublishingSections.buildAnalyticsSection(
          widget.publishedPosts,
          filterClientName: widget.client.companyName,
          dateRange: _analyticsRange,
          onDateRangeTap: _showAnalyticsDateRangePicker,
        );
      default:
        return _buildOverviewTab();
    }
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

  // ── CALENDAR TAB (mini calendar + selected-day posts)
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 900;

          final calendar = _buildCalendar();
          final postsForDay = _localScheduled
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
                  subtitle: 'Pick another date or add new content.',
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
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

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
                final posts = _localScheduled
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

  // ── Analytics date range (reused from dashboard)
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