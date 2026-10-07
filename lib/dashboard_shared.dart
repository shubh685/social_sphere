// dashboard_shared.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────────────────────
// COOL COLOR REFERENCE PALETTE
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const Color cyan = Color(0xFF00F0FF);
  static const Color purple = Color(0xFFA855F7);
  static const Color pink = Color(0xFFFF6B9D);
  static const Color green = Color(0xFF00E5A0);
  static const Color amber = Color(0xFFFFB547);
  static const Color blue = Color(0xFF3B82F6);
  static const Color red = Color(0xFFFF4757);
  static const Color orange = Color(0xFFFF8C42);

  static const Color facebook = Color(0xFF1877F2);
  static const Color instagram = Color(0xFFE4405F);
  static const Color threads = Color(0xFF000000);
  static const Color youtube = Color(0xFFFF0000);
  static const Color linkedin = Color(0xFF0A66C2);

  static const Color cardBg = Color(0xFF0F1529);
  static const Color cardBgLight = Color(0xFF161D35);
  static const Color deepBg = Color(0xFF0A0E27);
  static const Color deepBg2 = Color(0xFF1E1B4B);
  static const Color deepBg3 = Color(0xFF311042);

  static const Color scaffoldLight = Color(0xFFF5F7FB);

  static const Color textDark = Color(0xFF0A0E27);
  static const Color textDarkSoft = Color(0xFF3B4368);
  static const Color textDarkMuted = Color(0xFF6B7391);
  static const Color borderLight = Color(0x1A0A0E27);
  static const Color borderLightSoft = Color(0x140A0E27);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x80FFFFFF);
  static const Color textFaint = Color(0x4DFFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyan, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenCyanGradient = LinearGradient(
    colors: [green, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberOrangeGradient = LinearGradient(
    colors: [amber, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL PLATFORM REGISTRY
// ─────────────────────────────────────────────────────────────────────────────
class SocialPlatform {
  final String name;
  final IconData icon;
  final Color color;
  final String handlePrefix;
  final List<String> allowedContentTypes;
  final bool usesMetaIntegration;

  const SocialPlatform({
    required this.name,
    required this.icon,
    required this.color,
    required this.handlePrefix,
    required this.allowedContentTypes,
    this.usesMetaIntegration = false,
  });
}

const List<SocialPlatform> kSocialPlatforms = [
  SocialPlatform(
    name: 'Facebook',
    icon: Icons.facebook_rounded,
    color: AppColors.facebook,
    handlePrefix: '@',
    allowedContentTypes: ['Post', 'Reel', 'Story', 'Video'],
    usesMetaIntegration: true,
  ),
  SocialPlatform(
    name: 'Instagram',
    icon: Icons.camera_alt_rounded,
    color: AppColors.instagram,
    handlePrefix: '@',
    allowedContentTypes: ['Post', 'Reel', 'Story', 'Video'],
    usesMetaIntegration: true,
  ),
  SocialPlatform(
    name: 'Threads',
    icon: Icons.alternate_email_rounded,
    color: AppColors.threads,
    handlePrefix: '@',
    allowedContentTypes: ['Post'],
    usesMetaIntegration: true,
  ),
  SocialPlatform(
    name: 'YouTube',
    icon: Icons.play_circle_fill_rounded,
    color: AppColors.youtube,
    handlePrefix: '@',
    allowedContentTypes: ['Video', 'Reel'],
    usesMetaIntegration: false,
  ),
  SocialPlatform(
    name: 'LinkedIn',
    icon: Icons.business_center_rounded,
    color: AppColors.linkedin,
    handlePrefix: 'in/',
    allowedContentTypes: ['Post'],
    usesMetaIntegration: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class ClientModel {
  final String companyName;
  final Color logoColor;
  final Uint8List? logoBytes;
  final String address;
  final String website;
  final String mobile;
  final String email;
  final Map<String, String> socialHandles;
  final Map<String, bool> metaConnected;

  ClientModel({
    required this.companyName,
    required this.logoColor,
    required this.logoBytes,
    required this.address,
    required this.website,
    required this.mobile,
    required this.email,
    required this.socialHandles,
    this.metaConnected = const {},
  });
}

class ScheduledPost {
  final String title;
  final String caption;
  final String clientName;
  final String platform;
  final String type;
  final DateTime scheduledAt;
  final Color color;
  final Uint8List? imageBytes;

  ScheduledPost({
    required this.title,
    required this.caption,
    required this.clientName,
    required this.platform,
    required this.type,
    required this.scheduledAt,
    required this.color,
    this.imageBytes,
  });
}

class MediaItem {
  final String title;
  final String caption;
  final String clientName;
  final String platform;
  final String type;
  final DateTime postedAt;
  final Color color;
  final Uint8List? imageBytes;
  final bool isArchived;

  MediaItem({
    required this.title,
    required this.caption,
    required this.clientName,
    required this.platform,
    required this.type,
    required this.postedAt,
    required this.color,
    required this.imageBytes,
    required this.isArchived,
  });
}

class PublishedPost {
  final String title;
  final String clientName;
  final String platform;
  final DateTime publishedAt;
  final int likes;
  final int comments;
  final int shares;
  final Color color;

  PublishedPost({
    required this.title,
    required this.clientName,
    required this.platform,
    required this.publishedAt,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.color,
  });
}

class FailedPost {
  final String title;
  final String clientName;
  final String platform;
  final DateTime failedAt;
  final String reason;
  final Color color;

  FailedPost({
    required this.title,
    required this.clientName,
    required this.platform,
    required this.failedAt,
    required this.reason,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU ITEM MODELS
// ─────────────────────────────────────────────────────────────────────────────
class MenuItemModel {
  final IconData icon;
  final String label;
  final Color color;
  final bool isExpandable;
  final String key;
  final List<SubItemModel>? children;

  const MenuItemModel({
    required this.icon,
    required this.label,
    required this.color,
    this.isExpandable = false,
    this.key = '',
    this.children,
  });
}

class SubItemModel {
  final IconData icon;
  final String label;
  const SubItemModel({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String formatDateTime(DateTime d) =>
    '${d.day} ${monthName(d.month)} ${d.year} • ${formatTime(d)}';

String formatDateLong(DateTime d) => '${d.day} ${monthName(d.month)} ${d.year}';

String formatMonthYear(DateTime d) => '${monthName(d.month)} ${d.year}';

String formatTime(DateTime d) {
  final hr = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
  final min = d.minute.toString().padLeft(2, '0');
  return '$hr:$min ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String monthName(int m) => [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
][m - 1];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Shared empty-state widget used by both dashboard files.
Widget buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purple.withOpacity(0.1),
            border: Border.all(color: AppColors.purple.withOpacity(0.3)),
          ),
          child: Icon(icon, color: AppColors.purple, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Shared section title widget.
Widget buildSectionTitle(String title) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// Shared scheduled-post card widget.
Widget buildPostCard(ScheduledPost post) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: post.color.withOpacity(0.12),
            border: Border.all(color: post.color.withOpacity(0.3)),
          ),
          child: Text(
            formatTime(post.scheduledAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: post.color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                post.caption,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textDarkSoft),
              ),
              const SizedBox(height: 6),
              Text(
                '${post.clientName} • ${post.platform} • ${post.type}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE RANGE MODEL (for Analytics)
// ─────────────────────────────────────────────────────────────────────────────
class DateRangeSelection {
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  DateRangeSelection({
    required this.startDate,
    required this.endDate,
    required this.label,
  });
}