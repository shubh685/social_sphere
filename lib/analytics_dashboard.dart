// analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dashboard_shared.dart';

// ═════════════════════════════════════════════════════════════════════════
// PUBLISHING SECTIONS
// ═════════════════════════════════════════════════════════════════════════
class PublishingSections {
  static Widget _wrap(List<Widget> children) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  static Widget buildPublishingQueue(
      List<ScheduledPost> scheduledPosts, {
        String? filterClientName,
      }) {
    final posts = filterClientName == null
        ? scheduledPosts
        : scheduledPosts.where((p) => p.clientName == filterClientName).toList();

    return _wrap([
      buildSectionTitle('Publishing Queue (${posts.length})'),
      if (filterClientName != null) ...[
        const SizedBox(height: 4),
        Text(
          'Filtered by: $filterClientName',
          style: GoogleFonts.outfit(
              fontSize: 11.5, color: AppColors.textDarkMuted),
        ),
      ],
      const SizedBox(height: 12),
      if (posts.isEmpty)
        buildEmptyState(
          icon: Icons.queue_rounded,
          title: 'Queue is empty',
          subtitle: 'Scheduled posts will appear here.',
        )
      else
        ...posts.map((post) => buildPostCard(post)),
    ]);
  }

  static Widget buildPublishedSection(
      List<PublishedPost> publishedPosts, {
        String? filterClientName,
      }) {
    final posts = filterClientName == null
        ? publishedPosts
        : publishedPosts
        .where((p) => p.clientName == filterClientName)
        .toList();

    return _wrap([
      buildSectionTitle('Published (${posts.length})'),
      if (filterClientName != null) ...[
        const SizedBox(height: 4),
        Text(
          'Filtered by: $filterClientName',
          style: GoogleFonts.outfit(
              fontSize: 11.5, color: AppColors.textDarkMuted),
        ),
      ],
      const SizedBox(height: 12),
      if (posts.isEmpty)
        buildEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Nothing published yet',
          subtitle: 'Published posts will appear here.',
        )
      else
        ...posts.map((post) => _publishedCard(post)),
    ]);
  }

  static Widget _publishedCard(PublishedPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: post.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: post.color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: post.color.withOpacity(0.15),
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: post.color, size: 18),
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
                    ),
                    Text(
                      '${post.clientName} • ${post.platform}',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.textDarkMuted),
                    ),
                  ],
                ),
              ),
              Text(
                formatDateTime(post.publishedAt),
                style:
                GoogleFonts.outfit(fontSize: 10, color: AppColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip(
                  Icons.favorite_rounded, '${post.likes}', AppColors.pink),
              _metricChip(
                  Icons.comment_rounded, '${post.comments}', AppColors.cyan),
              _metricChip(
                  Icons.share_rounded, '${post.shares}', AppColors.green),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _metricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFailedSection(
      List<FailedPost> failedPosts, {
        String? filterClientName,
      }) {
    final posts = filterClientName == null
        ? failedPosts
        : failedPosts.where((p) => p.clientName == filterClientName).toList();

    return _wrap([
      buildSectionTitle('Failed (${posts.length})'),
      if (filterClientName != null) ...[
        const SizedBox(height: 4),
        Text(
          'Filtered by: $filterClientName',
          style: GoogleFonts.outfit(
              fontSize: 11.5, color: AppColors.textDarkMuted),
        ),
      ],
      const SizedBox(height: 12),
      if (posts.isEmpty)
        buildEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No failed posts',
          subtitle: 'Everything is running smoothly.',
        )
      else
        ...posts.map((post) => _failedCard(post)),
    ]);
  }

  static Widget _failedCard(FailedPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.red.withOpacity(0.12),
              border: Border.all(color: AppColors.red.withOpacity(0.3)),
            ),
            child: const Icon(Icons.error_rounded,
                color: AppColors.red, size: 20),
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
                ),
                const SizedBox(height: 2),
                Text(
                  '${post.clientName} • ${post.platform}',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.textDarkMuted),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.red.withOpacity(0.1),
                  ),
                  child: Text(
                    post.reason,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDateTime(post.failedAt),
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: AppColors.textDarkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAnalyticsSection(
      List<PublishedPost> publishedPosts, {
        String? filterClientName,
        DateRangeSelection? dateRange,
        VoidCallback? onDateRangeTap,
        List<ScheduledPost> scheduledPosts = const [],
        DateTime? calendarMonth,
        DateTime? selectedDate,
        ValueChanged<DateTime>? onCalendarMonthChanged,
        ValueChanged<DateTime>? onSelectedDateChanged,
      }) {
    final platforms = _demoPlatformAnalytics();

    return _wrap([
      buildSectionTitle('Advanced Analytics & Social Metrics'),
      const SizedBox(height: 4),
      Text(
        filterClientName == null
            ? 'Deep breakdown by platform with inline scheduled-post calendar.'
            : 'Analytics for $filterClientName — platform-wise breakdown with inline calendar.',
        style: GoogleFonts.outfit(
            fontSize: 11.5, color: AppColors.textDarkMuted),
      ),
      const SizedBox(height: 12),
      _buildDateRangeRow(dateRange, onDateRangeTap),
      const SizedBox(height: 16),
      _buildGlobalKpiStrip(platforms),
      const SizedBox(height: 20),
      buildSectionTitle('Platform Depth Breakdown'),
      const SizedBox(height: 12),
      ...platforms.map((p) => _platformDeepCard(p)),
      const SizedBox(height: 20),
      buildSectionTitle('Top Performing Posts Across Channels'),
      const SizedBox(height: 12),
      ...publishedPosts
          .where((p) =>
      filterClientName == null || p.clientName == filterClientName)
          .map((post) => _topPostRow(post, publishedPosts)),
    ]);
  }

  static Widget _buildDateRangeRow(
      DateRangeSelection? dateRange, VoidCallback? onTap) {
    final label = dateRange?.label ?? 'Last 30 Days';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.08),
            blurRadius: 16,
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
              borderRadius: BorderRadius.circular(10),
              color: AppColors.purple.withOpacity(0.12),
              border: Border.all(color: AppColors.purple.withOpacity(0.3)),
            ),
            child: const Icon(Icons.date_range_rounded,
                color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reporting Period',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.textDarkMuted)),
                Text(label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    )),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month_rounded,
                size: 16, color: AppColors.purple),
            label: Text(
              'Change',
              style: GoogleFonts.outfit(
                  color: AppColors.purple, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static List<PlatformAnalytics> _demoPlatformAnalytics() {
    return [
      PlatformAnalytics(
        platform: 'Facebook',
        color: AppColors.facebook,
        icon: Icons.facebook_rounded,
        followers: 12540,
        following: 420,
        followerGrowth7d: 312,
        followerGrowthPct: 2.5,
        totalImpressions: 98400,
        totalReach: 72100,
        totalEngagement: 6840,
        totalShares: 920,
        avgEngagementRate: 0.0695,
        byType: [
          ContentTypeStats(
              type: 'Post',
              published: 24,
              impressions: 45200,
              reach: 33100,
              likes: 3120,
              comments: 480,
              shares: 540,
              saves: 210,
              clicks: 980),
          ContentTypeStats(
              type: 'Reel',
              published: 12,
              impressions: 32400,
              reach: 24800,
              likes: 1980,
              comments: 260,
              shares: 280,
              saves: 120,
              clicks: 410,
              avgWatchSeconds: 6.4,
              completionRate: 0.42),
          ContentTypeStats(
              type: 'Story',
              published: 18,
              impressions: 16800,
              reach: 11200,
              likes: 640,
              comments: 90,
              shares: 60,
              saves: 20,
              clicks: 140),
          ContentTypeStats(
              type: 'Video',
              published: 6,
              impressions: 4000,
              reach: 3000,
              likes: 320,
              comments: 60,
              shares: 40,
              saves: 15,
              clicks: 90,
              avgWatchSeconds: 42.0,
              completionRate: 0.31),
        ],
        bestTimes: const [
          BestTimeSlot('Mon', 19, 82),
          BestTimeSlot('Tue', 20, 91),
          BestTimeSlot('Wed', 19, 88),
          BestTimeSlot('Thu', 21, 95),
          BestTimeSlot('Fri', 18, 76),
          BestTimeSlot('Sat', 11, 68),
          BestTimeSlot('Sun', 20, 84),
        ],
      ),
      PlatformAnalytics(
        platform: 'Instagram',
        color: AppColors.instagram,
        icon: Icons.camera_alt_rounded,
        followers: 28400,
        following: 312,
        followerGrowth7d: 890,
        followerGrowthPct: 3.2,
        totalImpressions: 214000,
        totalReach: 158000,
        totalEngagement: 18600,
        totalShares: 1420,
        avgEngagementRate: 0.0869,
        byType: [
          ContentTypeStats(
              type: 'Post',
              published: 32,
              impressions: 88400,
              reach: 64100,
              likes: 7420,
              comments: 640,
              shares: 380,
              saves: 1210,
              clicks: 890),
          ContentTypeStats(
              type: 'Reel',
              published: 28,
              impressions: 98600,
              reach: 76200,
              likes: 8940,
              comments: 720,
              shares: 840,
              saves: 2140,
              clicks: 1240,
              avgWatchSeconds: 8.9,
              completionRate: 0.58),
          ContentTypeStats(
              type: 'Story',
              published: 44,
              impressions: 22800,
              reach: 15200,
              likes: 1640,
              comments: 210,
              shares: 160,
              saves: 80,
              clicks: 340),
          ContentTypeStats(
              type: 'Video',
              published: 8,
              impressions: 4200,
              reach: 2500,
              likes: 600,
              comments: 30,
              shares: 40,
              saves: 30,
              clicks: 60,
              avgWatchSeconds: 12.0,
              completionRate: 0.36),
        ],
        bestTimes: const [
          BestTimeSlot('Mon', 11, 74),
          BestTimeSlot('Tue', 19, 88),
          BestTimeSlot('Wed', 12, 92),
          BestTimeSlot('Thu', 20, 96),
          BestTimeSlot('Fri', 17, 79),
          BestTimeSlot('Sat', 10, 71),
          BestTimeSlot('Sun', 21, 85),
        ],
      ),
      PlatformAnalytics(
        platform: 'Threads',
        color: AppColors.threads,
        icon: Icons.alternate_email_rounded,
        followers: 4210,
        following: 128,
        followerGrowth7d: 210,
        followerGrowthPct: 5.2,
        totalImpressions: 34200,
        totalReach: 25100,
        totalEngagement: 2140,
        totalShares: 380,
        avgEngagementRate: 0.0626,
        byType: [
          ContentTypeStats(
              type: 'Post',
              published: 36,
              impressions: 34200,
              reach: 25100,
              likes: 1840,
              comments: 210,
              shares: 380,
              saves: 90,
              clicks: 210),
        ],
        bestTimes: const [
          BestTimeSlot('Mon', 9, 62),
          BestTimeSlot('Tue', 13, 78),
          BestTimeSlot('Wed', 10, 84),
          BestTimeSlot('Thu', 21, 92),
          BestTimeSlot('Fri', 18, 74),
          BestTimeSlot('Sat', 15, 66),
          BestTimeSlot('Sun', 20, 88),
        ],
      ),
      PlatformAnalytics(
        platform: 'YouTube',
        color: AppColors.youtube,
        icon: Icons.play_circle_fill_rounded,
        subscribers: 18400,
        followerGrowth7d: 620,
        followerGrowthPct: 3.5,
        totalImpressions: 328000,
        totalReach: 214000,
        totalEngagement: 24200,
        totalShares: 1840,
        avgEngagementRate: 0.0738,
        byType: [
          ContentTypeStats(
              type: 'Video',
              published: 12,
              impressions: 298000,
              reach: 192000,
              likes: 21400,
              comments: 1980,
              shares: 1640,
              saves: 840,
              clicks: 4200,
              avgWatchSeconds: 186.0,
              completionRate: 0.44),
          ContentTypeStats(
              type: 'Reel',
              published: 10,
              impressions: 30000,
              reach: 22000,
              likes: 2800,
              comments: 180,
              shares: 200,
              saves: 140,
              clicks: 480,
              avgWatchSeconds: 22.0,
              completionRate: 0.61),
        ],
        bestTimes: const [
          BestTimeSlot('Mon', 17, 72),
          BestTimeSlot('Tue', 18, 80),
          BestTimeSlot('Wed', 19, 88),
          BestTimeSlot('Thu', 17, 84),
          BestTimeSlot('Fri', 20, 91),
          BestTimeSlot('Sat', 11, 96),
          BestTimeSlot('Sun', 15, 93),
        ],
      ),
      PlatformAnalytics(
        platform: 'LinkedIn',
        color: AppColors.linkedin,
        icon: Icons.business_center_rounded,
        followers: 8900,
        totalConnections: 2460,
        followerGrowth7d: 180,
        followerGrowthPct: 2.1,
        totalImpressions: 62000,
        totalReach: 41800,
        totalEngagement: 3980,
        totalShares: 420,
        avgEngagementRate: 0.0642,
        byType: [
          ContentTypeStats(
              type: 'Post',
              published: 18,
              impressions: 62000,
              reach: 41800,
              likes: 3240,
              comments: 420,
              shares: 420,
              saves: 120,
              clicks: 640),
        ],
        bestTimes: const [
          BestTimeSlot('Mon', 8, 84),
          BestTimeSlot('Tue', 9, 90),
          BestTimeSlot('Wed', 8, 92),
          BestTimeSlot('Thu', 10, 88),
          BestTimeSlot('Fri', 9, 72),
          BestTimeSlot('Sat', 11, 34),
          BestTimeSlot('Sun', 18, 48),
        ],
      ),
    ];
  }

  static Widget _buildGlobalKpiStrip(List<PlatformAnalytics> platforms) {
    int totalImpr = 0, totalReach = 0, totalEng = 0, totalShares = 0;
    for (final p in platforms) {
      totalImpr += p.totalImpressions;
      totalReach += p.totalReach;
      totalEng += p.totalEngagement;
      totalShares += p.totalShares;
    }

    final kpis = [
      _kpi('Total Views / Impr', totalImpr, Icons.visibility_rounded,
          AppColors.cyan),
      _kpi('Unique Reach', totalReach, Icons.people_alt_rounded,
          AppColors.purple),
      _kpi('Total Engagement', totalEng, Icons.favorite_rounded,
          AppColors.pink),
      _kpi('Total Shares', totalShares, Icons.share_rounded, AppColors.green),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 600;
        if (narrow) {
          return Column(
            children: kpis
                .map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12), child: w))
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kpis
              .map((w) => SizedBox(width: (c.maxWidth - 12) / 2, child: w))
              .toList(),
        );
      },
    );
  }

  static Widget _kpi(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
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
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.textDarkMuted)),
                Text(
                  _fmtInt(value),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
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

  static Widget _platformDeepCard(PlatformAnalytics p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: p.color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        initiallyExpanded:
        p.platform == 'Instagram' || p.platform == 'YouTube',
        leading: Container(
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
        title: Text(
          p.platform,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _platformHeadline(p),
            style: GoogleFonts.outfit(
                fontSize: 11.5, color: AppColors.textDarkMuted),
          ),
        ),
        children: [
          const SizedBox(height: 8),
          _accountStatsRow(p),
          const SizedBox(height: 16),
          _miniKpiWrap(p),
          const SizedBox(height: 16),
          Text('Content Type Depth Breakdown (Posts, Reels, Stories, Videos)',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDarkSoft,
              )),
          const SizedBox(height: 8),
          ...p.byType.map((t) => _contentTypeRow(t, p.color)),
          const SizedBox(height: 16),
          Text('Best Time to Post & Audience Peak Activity',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDarkSoft,
              )),
          const SizedBox(height: 8),
          _bestTimeHeatmap(p),
        ],
      ),
    );
  }

  static String _platformHeadline(PlatformAnalytics p) {
    if (p.platform == 'YouTube') {
      return '${_fmtInt(p.subscribers)} Subscribers  •  +${_fmtInt(p.followerGrowth7d)} (${p.followerGrowthPct.toStringAsFixed(1)}% this week)';
    }
    if (p.platform == 'LinkedIn') {
      return '${_fmtInt(p.followers)} Followers  •  ${_fmtInt(p.totalConnections)} Connections  •  +${p.followerGrowthPct.toStringAsFixed(1)}%';
    }
    final hasFollowing = p.following > 0;
    return '${_fmtInt(p.followers)} Followers${hasFollowing ? '  •  ${_fmtInt(p.following)} Following' : ''}  •  +${_fmtInt(p.followerGrowth7d)} (${p.followerGrowthPct.toStringAsFixed(1)}%)';
  }

  static Widget _accountStatsRow(PlatformAnalytics p) {
    final chips = <Widget>[];
    if (p.platform == 'YouTube') {
      chips.add(_statChip('Subscribers', _fmtInt(p.subscribers), p.color));
      chips.add(_statChip(
          'Videos',
          '${p.byType.where((t) => t.type == 'Video').fold<int>(0, (s, t) => s + t.published)}',
          p.color));
      chips.add(_statChip(
          'Reels/Shorts',
          '${p.byType.where((t) => t.type == 'Reel').fold<int>(0, (s, t) => s + t.published)}',
          p.color));
    } else if (p.platform == 'LinkedIn') {
      chips.add(_statChip('Followers', _fmtInt(p.followers), p.color));
      chips.add(_statChip(
          'Connections', _fmtInt(p.totalConnections), p.color));
      chips.add(_statChip(
          'Posts Published',
          '${p.byType.fold<int>(0, (s, t) => s + t.published)}',
          p.color));
    } else {
      chips.add(_statChip('Followers', _fmtInt(p.followers), p.color));
      if (p.following > 0) {
        chips.add(_statChip('Following', _fmtInt(p.following), p.color));
      }
      chips.add(_statChip(
          'Total Published',
          '${p.byType.fold<int>(0, (s, t) => s + t.published)}',
          p.color));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  static Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 10, color: AppColors.textDarkMuted)),
          Text(value,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              )),
        ],
      ),
    );
  }

  static Widget _miniKpiWrap(PlatformAnalytics p) {
    final items = [
      _miniKpi('Total Views / Impr', _fmtInt(p.totalImpressions),
          Icons.visibility_rounded, p.color),
      _miniKpi('Unique Reach', _fmtInt(p.totalReach),
          Icons.people_alt_rounded, p.color),
      _miniKpi('Total Engagement', _fmtInt(p.totalEngagement),
          Icons.favorite_rounded, p.color),
      _miniKpi('Total Shares', _fmtInt(p.totalShares), Icons.share_rounded,
          p.color),
      _miniKpi('Avg Eng. Rate',
          '${(p.avgEngagementRate * 100).toStringAsFixed(2)}%',
          Icons.trending_up_rounded, p.color),
      _miniKpi('Frequency Index', '${p.frequencyIndex.toStringAsFixed(1)}x',
          Icons.repeat_rounded, AppColors.amber),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        if (narrow) {
          return Column(
            children: items
                .map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8), child: w))
                .toList(),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((w) => SizedBox(width: (c.maxWidth - 8) / 2, child: w))
              .toList(),
        );
      },
    );
  }

  static Widget _miniKpi(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11.5, color: AppColors.textDarkMuted),
                overflow: TextOverflow.ellipsis),
          ),
          Text(value,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              )),
        ],
      ),
    );
  }

  static Widget _contentTypeRow(ContentTypeStats t, Color platformColor) {
    final typeColor = _typeColor(t.type, platformColor);
    final isVideoType =
        t.type == 'Reel' || t.type == 'Video' || t.type == 'Story';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: typeColor.withOpacity(0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon(t.type), size: 11, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      t.type,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${t.published} published',
                  style: GoogleFonts.outfit(
                      fontSize: 10.5, color: AppColors.textDarkMuted)),
              const Spacer(),
              Text('${(t.engagementRate * 100).toStringAsFixed(2)}% ER',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _metricMini('Views/Impr', _fmtInt(t.impressions),
                  Icons.visibility_rounded),
              _metricMini('Reach', _fmtInt(t.reach),
                  Icons.people_alt_rounded),
              _metricMini('Frequency', '${t.frequency.toStringAsFixed(1)}x',
                  Icons.repeat_rounded),
              _metricMini('Likes', _fmtInt(t.likes), Icons.favorite_rounded),
              _metricMini(
                  'Comments', _fmtInt(t.comments), Icons.comment_rounded),
              _metricMini('Shares', _fmtInt(t.shares), Icons.share_rounded),
              _metricMini('Saves', _fmtInt(t.saves), Icons.bookmark_rounded),
              _metricMini('Clicks', _fmtInt(t.clicks), Icons.touch_app_rounded),
              if (isVideoType && t.avgWatchSeconds > 0)
                _metricMini('Avg Watch',
                    '${t.avgWatchSeconds.toStringAsFixed(1)}s',
                    Icons.timer_rounded),
              if (isVideoType && t.completionRate > 0)
                _metricMini(
                    'Completion',
                    '${(t.completionRate * 100).toStringAsFixed(0)}%',
                    Icons.check_circle_rounded),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _metricMini(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textDarkMuted),
          const SizedBox(width: 4),
          Text('$label ',
              style: GoogleFonts.outfit(
                  fontSize: 10, color: AppColors.textDarkMuted)),
          Text(value,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              )),
        ],
      ),
    );
  }

  static Color _typeColor(String type, Color fallback) {
    switch (type) {
      case 'Post':
        return AppColors.blue;
      case 'Reel':
        return AppColors.purple;
      case 'Story':
        return AppColors.pink;
      case 'Video':
        return AppColors.red;
      default:
        return fallback;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'Post':
        return Icons.article_rounded;
      case 'Reel':
        return Icons.movie_creation_rounded;
      case 'Story':
        return Icons.auto_stories_rounded;
      case 'Video':
        return Icons.videocam_rounded;
      default:
        return Icons.image_rounded;
    }
  }

  static Widget _bestTimeHeatmap(PlatformAnalytics p) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final byDay = <String, BestTimeSlot>{};
    for (final s in p.bestTimes) {
      final existing = byDay[s.day];
      if (existing == null || s.audienceScore > existing.audienceScore) {
        byDay[s.day] = s;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: days
                .map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDarkMuted,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 6),
          Row(
            children: days.map((d) {
              final slot = byDay[d];
              final score = slot?.audienceScore ?? 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: p.color
                          .withOpacity(0.10 + 0.55 * (score / 100)),
                      border: Border.all(
                          color: p.color.withOpacity(0.35), width: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot == null ? '—' : _hourLabel(slot.hour),
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$score',
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Darker color = higher audience peak activity. Best time slot: ${_bestDayLabel(byDay)}',
            style: GoogleFonts.outfit(
                fontSize: 10, color: AppColors.textDarkMuted),
          ),
        ],
      ),
    );
  }

  static String _bestDayLabel(Map<String, BestTimeSlot> byDay) {
    if (byDay.isEmpty) return '—';
    final best = byDay.entries.reduce(
            (a, b) => a.value.audienceScore >= b.value.audienceScore ? a : b);
    return '${best.key} at ${_hourLabel(best.value.hour)}';
  }

  static String _hourLabel(int hour24) {
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$h$ampm';
  }

  static Widget _topPostRow(PublishedPost post, List<PublishedPost> all) {
    final total = post.likes + post.comments + post.shares;
    final maxTotal = all.fold<int>(
      0,
          (m, p) => (p.likes + p.comments + p.shares) > m
          ? (p.likes + p.comments + p.shares)
          : m,
    );
    final ratio = maxTotal == 0 ? 0.0 : total / maxTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: post.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: post.color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                _fmtInt(total),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: post.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.scaffoldLight,
              valueColor: AlwaysStoppedAnimation<Color>(post.color),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtInt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class ContentTypeStats {
  final String type;
  final int published;
  final int impressions;
  final int reach;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int clicks;
  final double avgWatchSeconds;
  final double completionRate;

  ContentTypeStats({
    required this.type,
    required this.published,
    required this.impressions,
    required this.reach,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saves,
    required this.clicks,
    this.avgWatchSeconds = 0,
    this.completionRate = 0,
  });

  int get engagement => likes + comments + shares + saves;
  double get engagementRate => impressions == 0 ? 0 : engagement / impressions;
  double get frequency => reach == 0 ? 0 : impressions / reach;
}

class BestTimeSlot {
  final String day;
  final int hour;
  final int audienceScore;
  const BestTimeSlot(this.day, this.hour, this.audienceScore);
}

class PlatformAnalytics {
  final String platform;
  final Color color;
  final IconData icon;

  final int followers;
  final int following;
  final int totalConnections;
  final int subscribers;
  final int followerGrowth7d;
  final double followerGrowthPct;

  final int totalImpressions;
  final int totalReach;
  final int totalEngagement;
  final int totalShares;
  final double avgEngagementRate;

  final List<ContentTypeStats> byType;
  final List<BestTimeSlot> bestTimes;

  PlatformAnalytics({
    required this.platform,
    required this.color,
    required this.icon,
    this.followers = 0,
    this.following = 0,
    this.totalConnections = 0,
    this.subscribers = 0,
    required this.followerGrowth7d,
    required this.followerGrowthPct,
    required this.totalImpressions,
    required this.totalReach,
    required this.totalEngagement,
    required this.totalShares,
    required this.avgEngagementRate,
    required this.byType,
    required this.bestTimes,
  });

  double get frequencyIndex =>
      totalReach == 0 ? 0 : totalImpressions / totalReach;
}

// ═════════════════════════════════════════════════════════════════════════
// ADD CLIENT FORM
// ═════════════════════════════════════════════════════════════════════════
class AddClientForm extends StatefulWidget {
  final ValueChanged<ClientModel> onSave;
  final VoidCallback onCancel;

  const AddClientForm({
    super.key,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<AddClientForm> createState() => _AddClientFormState();
}

class _AddClientFormState extends State<AddClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();

  final Color _pickedColor = AppColors.purple;
  Uint8List? _logoBytes;
  String? _logoFileName;

  @override
  void dispose() {
    _companyName.dispose();
    _address.dispose();
    _website.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null && mounted) {
          setState(() {
            _logoBytes = bytes;
            _logoFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppColors.red.withOpacity(0.9),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Company Registration',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Register the client. You can add their social handles next from the Social Accounts section.',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: AppColors.textDarkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _logoBytes == null
                            ? LinearGradient(
                          colors: [
                            _pickedColor.withOpacity(0.4),
                            _pickedColor.withOpacity(0.15),
                          ],
                        )
                            : null,
                        border: Border.all(
                            color: _pickedColor.withOpacity(0.5), width: 1.5),
                      ),
                      child: _logoBytes != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_logoBytes!,
                            fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              color: _pickedColor, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            'Add Logo',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Logo',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _logoFileName ?? 'Pick from your device.',
                          style: GoogleFonts.outfit(
                              fontSize: 11.5, color: AppColors.textDarkMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.folder_open_rounded,
                                  size: 14, color: AppColors.purple),
                              label: Text(
                                _logoBytes == null ? 'Choose File' : 'Change',
                                style: GoogleFonts.outfit(
                                    color: AppColors.purple, fontSize: 12),
                              ),
                            ),
                            if (_logoBytes != null)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _logoBytes = null;
                                  _logoFileName = null;
                                }),
                                icon: const Icon(Icons.close_rounded,
                                    size: 14, color: AppColors.red),
                                label: Text(
                                  'Remove',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Company Name *', _companyName,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField('Address *', _address,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField('Website (Optional)', _website),
              const SizedBox(height: 12),
              _buildField('Mobile Number *', _mobile,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField('Email ID *', _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  widget.onSave(ClientModel(
                    companyName: _companyName.text.trim(),
                    logoColor: _pickedColor,
                    logoBytes: _logoBytes,
                    address: _address.text.trim(),
                    website: _website.text.trim(),
                    mobile: _mobile.text.trim(),
                    email: _email.text.trim(),
                    socialHandles: const {},
                    metaConnected: const {},
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Register Company',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(color: AppColors.textDark),
      decoration: InputDecoration(
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
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}