// dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
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

  // Social platform brand colors
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

  // White main background (for empty content state)
  static const Color scaffoldLight = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF0A0E27);

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
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  String _activeSubSection = '';

  final Map<String, bool> _expandedMenus = {
    'clients': false,
    'social': false,
    'content': false,
  };

  final List<_Client> _clients = [];
  final List<_ScheduledPost> _scheduledPosts = [];
  final List<_MediaItem> _mediaArchive = [];
  final List<_PublishedPost> _publishedPosts = [];
  final List<_FailedPost> _failedPosts = [];

  late AnimationController _bgAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _bgAnimation;
  late Animation<double> _glowAnimation;

  late final List<_MenuItem> _menuItems = [
    const _MenuItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      color: AppColors.cyan,
    ),
    const _MenuItem(
      icon: Icons.people_alt_rounded,
      label: 'Clients',
      color: AppColors.purple,
      isExpandable: true,
      key: 'clients',
      children: [
        _SubItem(icon: Icons.list_alt_rounded, label: 'Client List'),
        _SubItem(icon: Icons.person_add_alt_1_rounded, label: 'Add Client'),
      ],
    ),
    _MenuItem(
      icon: Icons.share_rounded,
      label: 'Social Accounts',
      color: AppColors.blue,
      isExpandable: true,
      key: 'social',
      children: kSocialPlatforms
          .map((p) => _SubItem(icon: p.icon, label: p.name))
          .toList(),
    ),
    const _MenuItem(
      icon: Icons.article_rounded,
      label: 'Content',
      color: AppColors.green,
      isExpandable: true,
      key: 'content',
      children: [
        _SubItem(icon: Icons.edit_note_rounded, label: 'Create Content'),
        _SubItem(icon: Icons.drafts_rounded, label: 'Drafts'),
        _SubItem(icon: Icons.perm_media_rounded, label: 'Media Archive'),
      ],
    ),
    const _MenuItem(
      icon: Icons.calendar_month_rounded,
      label: 'Calendar',
      color: AppColors.amber,
    ),
    const _MenuItem(
      icon: Icons.queue_rounded,
      label: 'Publishing Queue',
      color: AppColors.orange,
    ),
    const _MenuItem(
      icon: Icons.check_circle_rounded,
      label: 'Published',
      color: AppColors.green,
    ),
    const _MenuItem(
      icon: Icons.error_rounded,
      label: 'Failed',
      color: AppColors.red,
    ),
    const _MenuItem(
      icon: Icons.analytics_rounded,
      label: 'Analytics',
      color: AppColors.pink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowAnimationController, curve: Curves.easeInOut),
    );

    _seedDemoData();
  }

  void _seedDemoData() {
    _clients.addAll([
      _Client(
        companyName: 'TechNova Solutions',
        logoColor: AppColors.purple,
        logoBytes: null,
        address: 'Bengaluru, India',
        website: 'technova.io',
        mobile: '+91 98765 43210',
        email: 'hello@technova.io',
        socialHandles: {
          'Facebook': '@technova',
          'Instagram': '@technova.io',
          'Threads': '@technova',
          'YouTube': '@technova',
          'LinkedIn': 'in/technova',
        },
        metaConnected: {
          'Facebook': true,
          'Instagram': true,
          'Threads': true,
        },
      ),
      _Client(
        companyName: 'Bloom Café',
        logoColor: AppColors.pink,
        logoBytes: null,
        address: 'Mumbai, India',
        website: 'bloomcafe.in',
        mobile: '+91 91234 56789',
        email: 'hi@bloomcafe.in',
        socialHandles: {
          'Instagram': '@bloomcafe',
          'Threads': '@bloomcafe',
          'YouTube': '@bloomcafe',
        },
        metaConnected: {
          'Instagram': true,
          'Threads': true,
        },
      ),
      _Client(
        companyName: 'FitPulse Gym',
        logoColor: AppColors.green,
        logoBytes: null,
        address: 'Delhi, India',
        website: 'fitpulse.fit',
        mobile: '+91 99887 76655',
        email: 'team@fitpulse.fit',
        socialHandles: {
          'Facebook': '@fitpulse',
          'Instagram': '@fitpulse.fit',
          'LinkedIn': 'in/fitpulse',
        },
        metaConnected: {
          'Facebook': true,
          'Instagram': true,
        },
      ),
    ]);

    final now = DateTime.now();
    _scheduledPosts.addAll([
      _ScheduledPost(
        title: 'Summer Campaign Reel',
        caption: 'Beat the heat with our new collection! #summer',
        clientName: 'TechNova Solutions',
        platform: 'Instagram',
        type: 'Reel',
        scheduledAt: DateTime(now.year, now.month, now.day + 1, 10, 30),
        color: AppColors.purple,
      ),
      _ScheduledPost(
        title: 'Morning Brew Story',
        caption: 'Start your day right ☕',
        clientName: 'Bloom Café',
        platform: 'Instagram',
        type: 'Story',
        scheduledAt: DateTime(now.year, now.month, now.day + 2, 8, 0),
        color: AppColors.pink,
      ),
      _ScheduledPost(
        title: 'Fitness Challenge Post',
        caption: 'Join our 30-day challenge!',
        clientName: 'FitPulse Gym',
        platform: 'Facebook',
        type: 'Post',
        scheduledAt: DateTime(now.year, now.month, now.day + 3, 18, 0),
        color: AppColors.green,
      ),
      _ScheduledPost(
        title: 'Product Launch Video',
        caption: 'Something big is coming...',
        clientName: 'TechNova Solutions',
        platform: 'YouTube',
        type: 'Video',
        scheduledAt: DateTime(now.year, now.month, now.day + 1, 14, 0),
        color: AppColors.cyan,
      ),
    ]);

    _mediaArchive.addAll([
      _MediaItem(
        title: 'Product Launch Reel',
        caption: 'Our biggest launch yet! 🚀',
        clientName: 'TechNova Solutions',
        platform: 'Instagram',
        type: 'Reel',
        postedAt: DateTime(now.year, now.month, now.day - 1, 11, 30),
        color: AppColors.purple,
        imageBytes: null,
        isArchived: true,
      ),
      _MediaItem(
        title: 'Coffee Art Story',
        caption: 'Latte art perfection ☕',
        clientName: 'Bloom Café',
        platform: 'Instagram',
        type: 'Story',
        postedAt: DateTime(now.year, now.month, now.day - 2, 9, 15),
        color: AppColors.pink,
        imageBytes: null,
        isArchived: true,
      ),
      _MediaItem(
        title: 'Gym Motivation Post',
        caption: 'No excuses. Just results.',
        clientName: 'FitPulse Gym',
        platform: 'Facebook',
        type: 'Post',
        postedAt: DateTime(now.year, now.month, now.day - 3, 17, 0),
        color: AppColors.green,
        imageBytes: null,
        isArchived: false,
      ),
      _MediaItem(
        title: 'Behind the Scenes',
        caption: 'A peek inside our studio',
        clientName: 'TechNova Solutions',
        platform: 'YouTube',
        type: 'Video',
        postedAt: DateTime(now.year, now.month, now.day - 4, 13, 45),
        color: AppColors.cyan,
        imageBytes: null,
        isArchived: true,
      ),
    ]);

    _publishedPosts.addAll([
      _PublishedPost(
        title: 'Welcome Post',
        clientName: 'TechNova Solutions',
        platform: 'Facebook',
        publishedAt: DateTime(now.year, now.month, now.day - 5, 10, 0),
        likes: 245,
        comments: 32,
        shares: 18,
        color: AppColors.facebook,
      ),
      _PublishedPost(
        title: 'New Menu Reveal',
        clientName: 'Bloom Café',
        platform: 'Instagram',
        publishedAt: DateTime(now.year, now.month, now.day - 6, 12, 30),
        likes: 892,
        comments: 67,
        shares: 45,
        color: AppColors.instagram,
      ),
      _PublishedPost(
        title: 'Member Spotlight',
        clientName: 'FitPulse Gym',
        platform: 'LinkedIn',
        publishedAt: DateTime(now.year, now.month, now.day - 7, 16, 0),
        likes: 534,
        comments: 41,
        shares: 22,
        color: AppColors.linkedin,
      ),
    ]);

    _failedPosts.addAll([
      _FailedPost(
        title: 'Flash Sale Announcement',
        clientName: 'TechNova Solutions',
        platform: 'Instagram',
        failedAt: DateTime(now.year, now.month, now.day - 1, 9, 0),
        reason: 'API rate limit exceeded',
        color: AppColors.red,
      ),
      _FailedPost(
        title: 'Weekend Special',
        clientName: 'Bloom Café',
        platform: 'Facebook',
        failedAt: DateTime(now.year, now.month, now.day - 2, 11, 30),
        reason: 'Invalid media format',
        color: AppColors.orange,
      ),
    ]);
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isTablet = size.width >= 768 && size.width < 1200;

    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, _) {
        return Scaffold(
          // ── Light/white main background (matches Login palette)
          backgroundColor: AppColors.scaffoldLight,
          drawer: isMobile ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: _sidebarCollapsed ? 78 : (isTablet ? 220 : 260),
                  // ── Sidebar keeps the animated gradient
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(const Color(0xFF0A0E27),
                              const Color(0xFF1A0B2E), _bgAnimation.value)!,
                          Color.lerp(const Color(0xFF1E1B4B),
                              const Color(0xFF2D1B69), _bgAnimation.value)!,
                          Color.lerp(const Color(0xFF311042),
                              const Color(0xFF0F172A), _bgAnimation.value)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: _buildSidebar(isMobile: false, isTablet: isTablet),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isMobile, isTablet),
                    Expanded(child: _buildMainContent()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SIDEBAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSidebar({required bool isMobile, required bool isTablet}) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebarBrand(),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.08), height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) => _buildMenuItem(index),
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      width: 280,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1E1B4B),
              Color(0xFF311042),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSidebarBrand(forceExpanded: true),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) =>
                      _buildMenuItem(index, forceExpanded: true),
                ),
              ),
              _buildSidebarFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarBrand({bool forceExpanded = false}) {
    final showExpanded = forceExpanded || !_sidebarCollapsed;
    return Padding(
      padding: EdgeInsets.fromLTRB(showExpanded ? 16 : 12, 20, showExpanded ? 16 : 12, 8),
      child: Row(
        mainAxisAlignment: showExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
              );
            },
          ),
          if (showExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: Text('Social', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2)),
                  ),
                  Text('Sphere', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, {bool forceExpanded = false}) {
    final item = _menuItems[index];
    final isSelected = _selectedIndex == index;
    final showExpanded = forceExpanded || !_sidebarCollapsed;
    final isExpanded = item.isExpandable && (_expandedMenus[item.key] ?? false) && showExpanded;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (item.isExpandable && showExpanded) {
                  setState(() {
                    _expandedMenus[item.key] = !(_expandedMenus[item.key] ?? false);
                  });
                } else {
                  setState(() {
                    _selectedIndex = index;
                    _activeSubSection = '';
                  });
                  if (forceExpanded && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: showExpanded ? 14 : 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [
                      item.color.withOpacity(0.25),
                      item.color.withOpacity(0.08),
                    ],
                  )
                      : null,
                  border: isSelected
                      ? Border.all(color: item.color.withOpacity(0.4), width: 1)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: showExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSelected ? item.color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: isSelected ? item.color.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: isSelected ? item.color : AppColors.textSecondary,
                      ),
                    ),
                    if (showExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isExpandable)
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (item.isExpandable && isExpanded && showExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Column(
              children: item.children!.map((sub) {
                final isSubActive = _selectedIndex == index && _activeSubSection == sub.label;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        _activeSubSection = sub.label;
                      });
                      if (forceExpanded && Navigator.canPop(context)) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSubActive ? item.color.withOpacity(0.12) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.color.withOpacity(isSubActive ? 1 : 0.6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(sub.icon, size: 15, color: isSubActive ? item.color : AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.label,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: isSubActive ? FontWeight.w700 : FontWeight.w500,
                                color: isSubActive ? Colors.white : AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [AppColors.purple.withOpacity(0.15), AppColors.cyan.withOpacity(0.08)],
          ),
          border: Border.all(color: AppColors.purple.withOpacity(0.2), width: 1),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.purple.withOpacity(0.3),
                child: Text(
                  'GS',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!_sidebarCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Agency Admin',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'admin@grow.io',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isMobile, bool isTablet) {
    final title = _activeSubSection.isEmpty
        ? _menuItems[_selectedIndex].label
        : '${_menuItems[_selectedIndex].label} • $_activeSubSection';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: Row(
          children: [
            if (isMobile)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  _sidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isMobile && !isTablet)
              Container(
                width: 200,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'Search...',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            if (!isMobile && !isTablet) const SizedBox(width: 12),
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Icon(Icons.notifications_rounded, size: 18, color: AppColors.textSecondary),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pink,
                      boxShadow: [
                        BoxShadow(color: AppColors.pink.withOpacity(0.6), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    child: const Icon(Icons.person_rounded, size: 14, color: Colors.white),
                  ),
                  if (!isMobile && !isTablet) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Admin',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MAIN CONTENT ROUTER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 1:
        if (_activeSubSection == 'Add Client') return _buildAddClientForm();
        return _buildClientsList();
      case 2:
        if (_activeSubSection.isNotEmpty) {
          return _buildPlatformAccounts(_activeSubSection);
        }
        return _buildSocialAccounts();
      case 3:
        if (_activeSubSection == 'Create Content') return _buildCreateContentForm();
        if (_activeSubSection == 'Drafts') return _buildDrafts();
        if (_activeSubSection == 'Media Archive') return _buildMediaArchive();
        return _buildCreateContentForm();
      case 4:
        return _buildCalendarSection();
      case 5:
        return _buildPublishingQueue();
      case 6:
        return _buildPublishedSection();
      case 7:
        return _buildFailedSection();
      case 8:
        return _buildAnalyticsSection();
      default:
        return _buildOverviewSection();
    }
  }

  Widget _scrollWrapper({required List<Widget> children}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // OVERVIEW SECTION
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewSection() {
    return _scrollWrapper(children: [
      _buildWelcomeBanner(),
      const SizedBox(height: 20),
      _buildStatsRow(),
      const SizedBox(height: 20),
      _buildSectionTitle('Quick Actions'),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              children: [
                _actionTile('Add Client', Icons.person_add_alt_1_rounded, AppColors.purple, () {
                  setState(() {
                    _selectedIndex = 1;
                    _activeSubSection = 'Add Client';
                    _expandedMenus['clients'] = true;
                  });
                }),
                const SizedBox(height: 12),
                _actionTile('Create Content', Icons.edit_note_rounded, AppColors.cyan, () {
                  setState(() {
                    _selectedIndex = 3;
                    _activeSubSection = 'Create Content';
                    _expandedMenus['content'] = true;
                  });
                }),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: _actionTile('Add Client', Icons.person_add_alt_1_rounded, AppColors.purple, () {
                setState(() {
                  _selectedIndex = 1;
                  _activeSubSection = 'Add Client';
                  _expandedMenus['clients'] = true;
                });
              })),
              const SizedBox(width: 12),
              Expanded(child: _actionTile('Create Content', Icons.edit_note_rounded, AppColors.cyan, () {
                setState(() {
                  _selectedIndex = 3;
                  _activeSubSection = 'Create Content';
                  _expandedMenus['content'] = true;
                });
              })),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      _buildSectionTitle('Recent Scheduled Posts'),
      const SizedBox(height: 12),
      if (_scheduledPosts.isEmpty)
        _buildEmptyState(
          icon: Icons.schedule_rounded,
          title: 'No scheduled posts',
          subtitle: 'Schedule your first content to see it here.',
        )
      else
        ..._scheduledPosts.take(3).map((post) => _buildPostCard(post)),
    ]);
  }

  Widget _buildSectionTitle(String title) {
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
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _actionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to open',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
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

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppColors.purple.withOpacity(0.18), AppColors.cyan.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.purple.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back, Admin! 👋',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage client registrations, content scheduling, and calendar in one place.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 500)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int totalAccounts = 0;
    for (final c in _clients) {
      totalAccounts += c.socialHandles.length;
    }

    final stats = [
      _Stat('Clients', '${_clients.length}', Icons.people_alt_rounded, AppColors.purple),
      _Stat('Scheduled', '${_scheduledPosts.length}', Icons.schedule_rounded, AppColors.cyan),
      _Stat('Accounts', '$totalAccounts', Icons.share_rounded, AppColors.pink),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final s = stats[i];
          return Container(
            width: 160,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.color.withOpacity(0.25), width: 1),
              boxShadow: [
                BoxShadow(
                  color: s.color.withOpacity(0.08),
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
                    borderRadius: BorderRadius.circular(12),
                    color: s.color.withOpacity(0.15),
                    border: Border.all(color: s.color.withOpacity(0.3)),
                  ),
                  child: Icon(s.icon, color: s.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.label,
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        s.value,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CLIENTS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildClientsList() {
    return _scrollWrapper(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('Client List (${_clients.length})'),
          TextButton.icon(
            onPressed: () => setState(() {
              _activeSubSection = 'Add Client';
              _expandedMenus['clients'] = true;
            }),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.cyan),
            label: Text(
              'Add Client',
              style: GoogleFonts.outfit(color: AppColors.cyan, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_clients.isEmpty)
        _buildEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No clients yet',
          subtitle: 'Register your first client to get started.',
        )
      else
        ..._clients.map((client) => _buildClientCard(client)),
    ]);
  }

  Widget _buildClientCard(_Client client) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: client.logoColor.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: client.logoColor.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientLogo(client, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.companyName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildIconText(Icons.mail_outline_rounded, client.email),
                  _buildIconText(Icons.phone_outlined, client.mobile),
                  _buildIconText(Icons.location_on_outlined, client.address),
                  if (client.website.isNotEmpty) _buildIconText(Icons.language_rounded, client.website),
                  if (client.socialHandles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: client.socialHandles.entries.map((e) {
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
                        final metaConnected = client.metaConnected[e.key] ?? false;
                        return _buildSocialChip(p, e.value, metaConnected: metaConnected);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientLogo(_Client client, {double size = 52}) {
    if (client.logoBytes != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: client.logoColor.withOpacity(0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.memory(client.logoBytes!, fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [client.logoColor.withOpacity(0.4), client.logoColor.withOpacity(0.15)],
        ),
        border: Border.all(color: client.logoColor.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          client.companyName.isNotEmpty ? client.companyName[0].toUpperCase() : '?',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialChip(SocialPlatform p, String handle, {bool metaConnected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: p.color.withOpacity(0.12),
        border: Border.all(color: p.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(p.icon, size: 10, color: p.color),
          const SizedBox(width: 4),
          Text(
            handle,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: p.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (metaConnected) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green,
                boxShadow: [
                  BoxShadow(color: AppColors.green.withOpacity(0.6), blurRadius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddClientForm() {
    return AddClientForm(
      accentCyan: AppColors.cyan,
      accentPurple: AppColors.purple,
      cardBg: AppColors.cardBg,
      onSave: (client) {
        setState(() {
          _clients.add(client);
          _activeSubSection = 'Client List';
        });
        _showSnack('Client "${client.companyName}" registered successfully!', AppColors.green);
      },
      onCancel: () => setState(() => _activeSubSection = 'Client List'),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SOCIAL ACCOUNTS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSocialAccounts() {
    final Map<String, int> platformCounts = {};
    final Map<String, int> metaConnectedCounts = {};
    for (final c in _clients) {
      for (final p in c.socialHandles.keys) {
        platformCounts[p] = (platformCounts[p] ?? 0) + 1;
        if (c.metaConnected[p] == true) {
          metaConnectedCounts[p] = (metaConnectedCounts[p] ?? 0) + 1;
        }
      }
    }

    return _scrollWrapper(children: [
      _buildSectionTitle('Social Accounts'),
      const SizedBox(height: 4),
      Text(
        'All platforms are connected via Meta Business Suite for unified publishing.',
        style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
      ),
      const SizedBox(height: 12),
      ...kSocialPlatforms.map((p) {
        final count = platformCounts[p.name] ?? 0;
        final metaCount = metaConnectedCounts[p.name] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: p.color.withOpacity(0.08),
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
                    colors: [p.color.withOpacity(0.3), p.color.withOpacity(0.1)],
                  ),
                  border: Border.all(color: p.color.withOpacity(0.4)),
                ),
                child: Icon(p.icon, color: p.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (p.usesMetaIntegration) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: AppColors.blue.withOpacity(0.2),
                            ),
                            child: Text(
                              'META',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'No accounts connected'
                          : '$count connected • $metaCount via Meta',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                    _activeSubSection = p.name;
                  });
                },
                child: Text(
                  'View',
                  style: GoogleFonts.outfit(
                    color: p.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _buildPlatformAccounts(String platformName) {
    final platform = kSocialPlatforms.firstWhere(
          (p) => p.name == platformName,
      orElse: () => kSocialPlatforms.first,
    );

    final entries = <MapEntry<_Client, String>>[];
    for (final c in _clients) {
      if (c.socialHandles.containsKey(platformName)) {
        entries.add(MapEntry(c, c.socialHandles[platformName]!));
      }
    }

    return _scrollWrapper(children: [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [platform.color.withOpacity(0.3), platform.color.withOpacity(0.1)],
              ),
              border: Border.all(color: platform.color.withOpacity(0.4)),
            ),
            child: Icon(platform.icon, color: platform.color, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            platform.name,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            '${entries.length} account${entries.length == 1 ? '' : 's'}',
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: platform.usesMetaIntegration
              ? AppColors.blue.withOpacity(0.08)
              : AppColors.amber.withOpacity(0.08),
          border: Border.all(
            color: platform.usesMetaIntegration
                ? AppColors.blue.withOpacity(0.3)
                : AppColors.amber.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              platform.usesMetaIntegration ? Icons.verified_rounded : Icons.info_outline_rounded,
              size: 14,
              color: platform.usesMetaIntegration ? AppColors.blue : AppColors.amber,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                platform.usesMetaIntegration
                    ? 'Connected via Meta Business Suite — unified login & publishing.'
                    : 'Connected via native ${platform.name} API.',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: platform.usesMetaIntegration ? AppColors.blue : AppColors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (entries.isEmpty)
        _buildEmptyState(
          icon: platform.icon,
          title: 'No ${platform.name} accounts',
          subtitle: 'Register a client with a ${platform.name} handle to see it here.',
        )
      else
        ...entries.map((e) {
          final client = e.key;
          final handle = e.value;
          final isMetaConnected = client.metaConnected[platformName] ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: platform.color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: platform.color.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildClientLogo(client, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.companyName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(platform.icon, size: 12, color: platform.color),
                          const SizedBox(width: 6),
                          Text(
                            handle,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: platform.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: (isMetaConnected ? AppColors.green : AppColors.amber).withOpacity(0.15),
                    border: Border.all(
                      color: (isMetaConnected ? AppColors.green : AppColors.amber).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMetaConnected ? Icons.verified_rounded : Icons.warning_amber_rounded,
                        size: 11,
                        color: isMetaConnected ? AppColors.green : AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMetaConnected ? 'Connected' : 'Pending',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isMetaConnected ? AppColors.green : AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
    ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CONTENT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCreateContentForm() {
    return CreateContentForm(
      clients: _clients,
      accentCyan: AppColors.cyan,
      accentPurple: AppColors.purple,
      accentPink: AppColors.pink,
      cardBg: AppColors.cardBg,
      onSave: (post) {
        setState(() {
          _scheduledPosts.add(post);
          final isArchiveType = post.type == 'Story' || post.type == 'Reel';
          if (isArchiveType) {
            _mediaArchive.add(_MediaItem(
              title: post.title,
              caption: post.caption,
              clientName: post.clientName,
              platform: post.platform,
              type: post.type,
              postedAt: post.scheduledAt,
              color: post.color,
              imageBytes: post.imageBytes,
              isArchived: true,
            ));
          }
        });
        _showSnack('Content successfully created and scheduled!', AppColors.green);
      },
      onCancel: () => setState(() => _activeSubSection = ''),
    );
  }

  Widget _buildDrafts() {
    return _scrollWrapper(children: [
      _buildSectionTitle('Drafts'),
      const SizedBox(height: 12),
      _buildEmptyState(
        icon: Icons.drafts_rounded,
        title: 'No drafts',
        subtitle: 'Your saved drafts will appear here.',
      ),
    ]);
  }

  Widget _buildMediaArchive() {
    final archived = _mediaArchive.where((m) => m.isArchived).toList();
    final active = _mediaArchive.where((m) => !m.isArchived).toList();

    return _scrollWrapper(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('Media Archive (${archived.length})'),
          Text(
            'Stories & Reels auto-archived',
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (active.isNotEmpty) ...[
        Text(
          'Recent',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _buildMediaGrid(active),
        const SizedBox(height: 20),
      ],
      Text(
        'Archive',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      if (archived.isEmpty)
        _buildEmptyState(
          icon: Icons.photo_library_outlined,
          title: 'No archived media',
          subtitle: 'Stories & Reels you post will be archived here automatically.',
        )
      else
        _buildMediaGrid(archived),
    ]);
  }

  Widget _buildMediaGrid(List<_MediaItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final m = items[i];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: m.color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: m.color.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                      child: m.imageBytes != null
                          ? Image.memory(m.imageBytes!, fit: BoxFit.cover)
                          : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [m.color.withOpacity(0.3), m.color.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          m.type == 'Reel'
                              ? Icons.movie_creation_rounded
                              : m.type == 'Story'
                              ? Icons.auto_stories_rounded
                              : m.type == 'Video'
                              ? Icons.videocam_rounded
                              : Icons.image_rounded,
                          size: 40,
                          color: m.color,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: m.color.withOpacity(0.2),
                              ),
                              child: Text(
                                m.type,
                                style: GoogleFonts.outfit(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: m.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.title,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.caption,
                          style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.clientName} • ${m.platform}',
                          style: GoogleFonts.outfit(fontSize: 9.5, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(m.postedAt),
                          style: GoogleFonts.outfit(fontSize: 9, color: AppColors.amber),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CALENDAR
  // ───────────────────────────────────────────────────────────────────────────
  DateTime _calendarMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  Widget _buildCalendarSection() {
    return _scrollWrapper(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('Content Calendar'),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.amber,
                      onPrimary: Colors.black,
                      surface: AppColors.cardBg,
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: AppColors.cardBg,
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _calendarMonth = DateTime(picked.year, picked.month);
                });
              }
            },
            icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.amber),
            label: Text(
              'Pick Date',
              style: GoogleFonts.outfit(color: AppColors.amber, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildCalendarWidget(),
      const SizedBox(height: 20),
      _buildSectionTitle('Scheduled Posts on ${_formatDateLong(_selectedDate)}'),
      const SizedBox(height: 10),
      _buildPostsForSelectedDate(),
    ]);
  }

  Widget _buildCalendarWidget() {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                }),
              ),
              Text(
                _formatMonthYear(_calendarMonth),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final postsOnDay = _scheduledPosts.where((p) => _isSameDay(p.scheduledAt, date)).toList();

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppColors.amber.withOpacity(0.3)
                        : isToday
                        ? AppColors.cyan.withOpacity(0.1)
                        : Colors.white.withOpacity(0.04),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.amber
                          : isToday
                          ? AppColors.cyan.withOpacity(0.5)
                          : Colors.white24,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$day',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.amber : Colors.white,
                          ),
                        ),
                      ),
                      if (postsOnDay.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: postsOnDay.take(3).map((p) {
                              return Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: p.color),
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
        ],
      ),
    );
  }

  Widget _buildPostsForSelectedDate() {
    final posts = _scheduledPosts.where((p) => _isSameDay(p.scheduledAt, _selectedDate)).toList();

    if (posts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No posts on this date',
        subtitle: 'Select another date or schedule new content.',
      );
    }

    return Column(
      children: posts.map((post) => _buildPostCard(post)).toList(),
    );
  }

  Widget _buildPostCard(_ScheduledPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.75),
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
              color: post.color.withOpacity(0.15),
              border: Border.all(color: post.color.withOpacity(0.3)),
            ),
            child: Text(
              _formatTime(post.scheduledAt),
              style: GoogleFonts.bricolageGrotesque(
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
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  post.caption,
                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  '${post.clientName} • ${post.platform} • ${post.type}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.cyan,
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

  // ───────────────────────────────────────────────────────────────────────────
  // PUBLISHING QUEUE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPublishingQueue() {
    return _scrollWrapper(children: [
      _buildSectionTitle('Publishing Queue (${_scheduledPosts.length})'),
      const SizedBox(height: 12),
      if (_scheduledPosts.isEmpty)
        _buildEmptyState(
          icon: Icons.queue_rounded,
          title: 'Queue is empty',
          subtitle: 'Scheduled posts will appear here.',
        )
      else
        ..._scheduledPosts.map((post) => _buildPostCard(post)),
    ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PUBLISHED
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPublishedSection() {
    return _scrollWrapper(children: [
      _buildSectionTitle('Published (${_publishedPosts.length})'),
      const SizedBox(height: 12),
      if (_publishedPosts.isEmpty)
        _buildEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Nothing published yet',
          subtitle: 'Published posts will appear here.',
        )
      else
        ..._publishedPosts.map((post) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: post.color.withOpacity(0.3)),
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
                    child: Icon(Icons.check_circle_rounded, color: post.color, size: 18),
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
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${post.clientName} • ${post.platform}',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDateTime(post.publishedAt),
                    style: GoogleFonts.outfit(fontSize: 10, color: AppColors.amber),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricChip(Icons.favorite_rounded, '${post.likes}', AppColors.pink),
                  const SizedBox(width: 8),
                  _buildMetricChip(Icons.comment_rounded, '${post.comments}', AppColors.cyan),
                  const SizedBox(width: 8),
                  _buildMetricChip(Icons.share_rounded, '${post.shares}', AppColors.green),
                ],
              ),
            ],
          ),
        )),
    ]);
  }

  Widget _buildMetricChip(IconData icon, String value, Color color) {
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

  // ───────────────────────────────────────────────────────────────────────────
  // FAILED
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFailedSection() {
    return _scrollWrapper(children: [
      _buildSectionTitle('Failed (${_failedPosts.length})'),
      const SizedBox(height: 12),
      if (_failedPosts.isEmpty)
        _buildEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No failed posts',
          subtitle: 'Everything is running smoothly.',
        )
      else
        ..._failedPosts.map((post) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.red.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.red.withOpacity(0.15),
                  border: Border.all(color: AppColors.red.withOpacity(0.3)),
                ),
                child: const Icon(Icons.error_rounded, color: AppColors.red, size: 20),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${post.clientName} • ${post.platform}',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      _formatDateTime(post.failedAt),
                      style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
    ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ANALYTICS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAnalyticsSection() {
    final totalLikes = _publishedPosts.fold<int>(0, (s, p) => s + p.likes);
    final totalComments = _publishedPosts.fold<int>(0, (s, p) => s + p.comments);
    final totalShares = _publishedPosts.fold<int>(0, (s, p) => s + p.shares);
    final engagement = totalLikes + totalComments + totalShares;

    return _scrollWrapper(children: [
      _buildSectionTitle('Analytics Overview'),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final cards = [
            _buildAnalyticsCard('Total Likes', '$totalLikes', Icons.favorite_rounded, AppColors.pink),
            _buildAnalyticsCard('Total Comments', '$totalComments', Icons.comment_rounded, AppColors.cyan),
            _buildAnalyticsCard('Total Shares', '$totalShares', Icons.share_rounded, AppColors.green),
            _buildAnalyticsCard('Engagement', '$engagement', Icons.trending_up_rounded, AppColors.amber),
          ];
          if (isNarrow) {
            return Column(
              children: cards
                  .map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c))
                  .toList(),
            );
          }
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c))
                .toList(),
          );
        },
      ),
      const SizedBox(height: 20),
      _buildSectionTitle('Top Performing Posts'),
      const SizedBox(height: 12),
      ..._publishedPosts.map((post) {
        final total = post.likes + post.comments + post.shares;
        final maxTotal = _publishedPosts.fold<int>(
          0,
              (m, p) => (p.likes + p.comments + p.shares) > m ? (p.likes + p.comments + p.shares) : m,
        );
        final ratio = maxTotal == 0 ? 0.0 : total / maxTotal;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: post.color.withOpacity(0.25)),
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '$total',
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
                  backgroundColor: Colors.white.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(post.color),
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
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
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  value,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SETTINGS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSettingsSection() {
    return _scrollWrapper(children: [
      _buildSectionTitle('Settings'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Sphere Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withOpacity(0.1),
              border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────────────────────
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateTime(DateTime d) =>
      '${d.day} ${_monthName(d.month)} ${d.year} • ${_formatTime(d)}';

  String _formatDateLong(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';

  String _formatMonthYear(DateTime d) => '${_monthName(d.month)} ${d.year}';

  String _formatTime(DateTime d) {
    final hr = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    return '$hr:$min ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _monthName(int m) => [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m - 1];

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _Client {
  final String companyName;
  final Color logoColor;
  final Uint8List? logoBytes;
  final String address;
  final String website;
  final String mobile;
  final String email;
  final Map<String, String> socialHandles;
  final Map<String, bool> metaConnected;

  _Client({
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

class _ScheduledPost {
  final String title;
  final String caption;
  final String clientName;
  final String platform;
  final String type;
  final DateTime scheduledAt;
  final Color color;
  final Uint8List? imageBytes;

  _ScheduledPost({
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

class _MediaItem {
  final String title;
  final String caption;
  final String clientName;
  final String platform;
  final String type;
  final DateTime postedAt;
  final Color color;
  final Uint8List? imageBytes;
  final bool isArchived;

  _MediaItem({
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

class _PublishedPost {
  final String title;
  final String clientName;
  final String platform;
  final DateTime publishedAt;
  final int likes;
  final int comments;
  final int shares;
  final Color color;

  _PublishedPost({
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

class _FailedPost {
  final String title;
  final String clientName;
  final String platform;
  final DateTime failedAt;
  final String reason;
  final Color color;

  _FailedPost({
    required this.title,
    required this.clientName,
    required this.platform,
    required this.failedAt,
    required this.reason,
    required this.color,
  });
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _Stat(this.label, this.value, this.icon, this.color);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final bool isExpandable;
  final String key;
  final List<_SubItem>? children;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.isExpandable = false,
    this.key = '',
    this.children,
  });
}

class _SubItem {
  final IconData icon;
  final String label;
  const _SubItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD CLIENT FORM (with logo picker + social handles)
// ─────────────────────────────────────────────────────────────────────────────
class AddClientForm extends StatefulWidget {
  final Color accentCyan;
  final Color accentPurple;
  final Color cardBg;
  final ValueChanged<_Client> onSave;
  final VoidCallback onCancel;

  const AddClientForm({
    super.key,
    required this.accentCyan,
    required this.accentPurple,
    required this.cardBg,
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

  final Map<String, TextEditingController> _handleControllers = {
    for (final p in kSocialPlatforms) p.name: TextEditingController(),
  };

  Color _pickedColor = AppColors.purple;
  Uint8List? _logoBytes;
  String? _logoFileName;

  final List<Color> _colorOptions = const [
    AppColors.cyan,
    AppColors.purple,
    AppColors.pink,
    AppColors.green,
    AppColors.amber,
    AppColors.blue,
    AppColors.facebook,
    AppColors.instagram,
    AppColors.threads,
    AppColors.youtube,
    AppColors.linkedin,
  ];

  @override
  void dispose() {
    _companyName.dispose();
    _address.dispose();
    _website.dispose();
    _mobile.dispose();
    _email.dispose();
    for (final c in _handleControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      // Use file_picker for cross-platform (web, windows, mobile)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // required for web/mobile to get bytes
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          if (!mounted) return;
          setState(() {
            _logoBytes = bytes;
            _logoFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: AppColors.red.withOpacity(0.9),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Logo picker
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
                      border: Border.all(color: _pickedColor.withOpacity(0.5), width: 1.5),
                    ),
                    child: _logoBytes != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(_logoBytes!, fit: BoxFit.cover),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, color: _pickedColor, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          'Add Logo',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white,
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _logoFileName ?? 'Pick from your device. Works on web, desktop & mobile.',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _pickLogo,
                            icon: const Icon(Icons.folder_open_rounded, size: 14, color: AppColors.cyan),
                            label: Text(
                              _logoBytes == null ? 'Choose File' : 'Change',
                              style: GoogleFonts.outfit(color: AppColors.cyan, fontSize: 12),
                            ),
                          ),
                          if (_logoBytes != null)
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _logoBytes = null;
                                _logoFileName = null;
                              }),
                              icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.red),
                              label: Text(
                                'Remove',
                                style: GoogleFonts.outfit(color: AppColors.red, fontSize: 12),
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

            Text(
              'Company Logo Color (used if no image)',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions
                  .map((c) => GestureDetector(
                onTap: () => setState(() => _pickedColor = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(
                      color: _pickedColor == c ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: _pickedColor == c
                        ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 12)]
                        : null,
                  ),
                ),
              ))
                  .toList(),
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
            const SizedBox(height: 20),

            // Social Handles
            Row(
              children: [
                Icon(Icons.share_rounded, size: 16, color: AppColors.cyan),
                const SizedBox(width: 6),
                Text(
                  'Social Media Handles (optional)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Add handles for platforms this client uses. Facebook, Instagram & Threads connect via Meta Business Suite.',
              style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            ...kSocialPlatforms.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: p.color.withOpacity(0.15),
                        border: Border.all(color: p.color.withOpacity(0.35)),
                      ),
                      child: Icon(p.icon, color: p.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _handleControllers[p.name],
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          prefixText: '${p.handlePrefix} ',
                          prefixStyle: GoogleFonts.outfit(
                            color: p.color,
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: '${p.name} handle',
                          hintStyle: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white12,
                          isDense: true,
                          suffixIcon: p.usesMetaIntegration
                              ? Tooltip(
                            message: 'Connects via Meta Business Suite',
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColors.blue.withOpacity(0.7),
                              ),
                            ),
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: p.color.withOpacity(0.6), width: 1.5),
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;

                final Map<String, String> handles = {};
                final Map<String, bool> metaConn = {};
                for (final p in kSocialPlatforms) {
                  final text = _handleControllers[p.name]!.text.trim();
                  if (text.isNotEmpty) {
                    handles[p.name] = text.startsWith(p.handlePrefix)
                        ? text
                        : '${p.handlePrefix}$text';
                    if (p.usesMetaIntegration) {
                      metaConn[p.name] = true;
                    }
                  }
                }

                widget.onSave(_Client(
                  companyName: _companyName.text.trim(),
                  logoColor: _pickedColor,
                  logoBytes: _logoBytes,
                  address: _address.text.trim(),
                  website: _website.text.trim(),
                  mobile: _mobile.text.trim(),
                  email: _email.text.trim(),
                  socialHandles: handles,
                  metaConnected: metaConn,
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
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.6), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE CONTENT FORM (platform-aware content types + cross-platform file picker)
// ─────────────────────────────────────────────────────────────────────────────
class CreateContentForm extends StatefulWidget {
  final List<_Client> clients;
  final Color accentCyan;
  final Color accentPurple;
  final Color accentPink;
  final Color cardBg;
  final ValueChanged<_ScheduledPost> onSave;
  final VoidCallback onCancel;

  const CreateContentForm({
    super.key,
    required this.clients,
    required this.accentCyan,
    required this.accentPurple,
    required this.accentPink,
    required this.cardBg,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<CreateContentForm> createState() => _CreateContentFormState();
}

class _CreateContentFormState extends State<CreateContentForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _caption = TextEditingController();

  _Client? _selectedClient;
  String? _selectedPlatform;
  String _contentType = 'Post';
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  Uint8List? _mediaBytes;
  String? _mediaFileName;
  bool _isVideo = false;

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    super.dispose();
  }

  // Get allowed content types for the selected platform
  List<String> get _allowedContentTypes {
    if (_selectedPlatform == null) return const ['Post', 'Reel', 'Story', 'Video'];
    final platform = kSocialPlatforms.firstWhere(
          (p) => p.name == _selectedPlatform,
      orElse: () => kSocialPlatforms.first,
    );
    return platform.allowedContentTypes;
  }

  Future<void> _pickMedia() async {
    try {
      // Determine allowed file types based on selected content type
      // Reels/Videos -> video files; Posts/Stories -> image files
      final isVideoType = _contentType == 'Reel' ||
          _contentType == 'Video';
      final type = isVideoType ? FileType.video : FileType.image;

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: false,
        withData: true, // required for web & mobile
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          if (!mounted) return;
          setState(() {
            _mediaBytes = bytes;
            _mediaFileName = file.name;
            _isVideo = isVideoType;
          });
        }
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

  @override
  Widget build(BuildContext context) {
    if (widget.clients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Please register a client first.',
            style: GoogleFonts.outfit(color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Available platforms for the selected client
    final availablePlatforms = _selectedClient == null
        ? <SocialPlatform>[]
        : kSocialPlatforms
        .where((p) => _selectedClient!.socialHandles.containsKey(p.name))
        .toList();

    final allowedTypes = _allowedContentTypes;

    // Reset content type if current selection not allowed by platform
    if (_selectedPlatform != null && !allowedTypes.contains(_contentType)) {
      // Auto-select first allowed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _contentType = allowedTypes.first);
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // ── STEP 1: Select Client ──
            Text(
              'Step 1 — Select Client',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<_Client>(
              value: _selectedClient,
              dropdownColor: widget.cardBg,
              decoration: InputDecoration(
                labelText: 'Client',
                labelStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.6), width: 1.5),
                ),
              ),
              items: widget.clients
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(
                  c.companyName,
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
              ))
                  .toList(),
              onChanged: (c) => setState(() {
                _selectedClient = c;
                _selectedPlatform = null;
                // Reset media if platform changes
                _mediaBytes = null;
                _mediaFileName = null;
              }),
            ),
            const SizedBox(height: 16),

            // ── STEP 2: Select Platform ──
            if (_selectedClient != null) ...[
              Text(
                'Step 2 — Select Social Account',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
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
                    border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                  ),
                  child: Text(
                    'This client has no social handles configured. Add handles in Add Client form.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.amber),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availablePlatforms.map((p) {
                    final isSelected = _selectedPlatform == p.name;
                    final handle = _selectedClient!.socialHandles[p.name] ?? '';
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedPlatform = p.name;
                        _mediaBytes = null;
                        _mediaFileName = null;
                        // Ensure content type valid for new platform
                        if (!p.allowedContentTypes.contains(_contentType)) {
                          _contentType = p.allowedContentTypes.first;
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected ? p.color.withOpacity(0.2) : Colors.white12,
                          border: Border.all(
                            color: isSelected ? p.color : Colors.white.withOpacity(0.1),
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
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                                if (handle.isNotEmpty)
                                  Text(
                                    handle,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      color: isSelected ? Colors.white70 : AppColors.textMuted,
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

            // ── STEP 3: Content Type (filtered per platform) ──
            if (_selectedPlatform != null) ...[
              Text(
                'Step 3 — Content Type',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Only ${allowedTypes.join(' • ')} available for $_selectedPlatform',
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
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
                      // Reset media if the type changes category (image vs video)
                      final wasVideo = _isVideo;
                      final isNowVideo = type == 'Reel' || type == 'Video';
                      if (wasVideo != isNowVideo) {
                        _mediaBytes = null;
                        _mediaFileName = null;
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected ? null : Colors.white12,
                        border: Border.all(
                          color: isSelected ? AppColors.cyan : Colors.white.withOpacity(0.1),
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
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
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

            // ── STEP 4: Media Upload ──
            if (_selectedPlatform != null) ...[
              Text(
                'Step 4 — Upload Media',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _contentType == 'Reel' || _contentType == 'Video'
                    ? 'Upload video file (mp4, mov, webm supported)'
                    : 'Upload image file (jpg, png, webp supported)',
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  // ── Vertical preview: taller than wide, 9:16 friendly
                  height: 420,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F1E).withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _mediaBytes != null
                          ? AppColors.cyan.withOpacity(0.55)
                          : Colors.white.withOpacity(0.12),
                      width: _mediaBytes != null ? 1.8 : 1,
                    ),
                    boxShadow: _mediaBytes != null
                        ? [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                        : null,
                  ),
                  child: _mediaBytes != null
                      ? Stack(
                    children: [
                      // ── Preview fills the vertical frame
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _isVideo
                            ? Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_fill_rounded,
                                size: 72,
                                color: AppColors.cyan.withOpacity(0.95),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _mediaFileName ?? 'Video selected',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                  AppColors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                      color: AppColors.green.withOpacity(0.4)),
                                ),
                                child: Text(
                                  'Video attached',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            : Image.memory(
                          _mediaBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // ── Top-right action buttons
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            _iconBtn(Icons.swap_horiz_rounded, AppColors.cyan,
                                _pickMedia),
                            const SizedBox(width: 6),
                            _iconBtn(
                              Icons.close_rounded,
                              AppColors.red,
                                  () => setState(() {
                                _mediaBytes = null;
                                _mediaFileName = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      // ── Bottom filename overlay (images only)
                      if (_mediaFileName != null && !_isVideo)
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _mediaFileName!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _contentType == 'Reel' || _contentType == 'Video'
                            ? Icons.video_library_rounded
                            : Icons.cloud_upload_rounded,
                        size: 48,
                        color: AppColors.cyan.withOpacity(0.75),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _contentType == 'Reel' || _contentType == 'Video'
                            ? 'Tap to pick video file'
                            : 'Tap to pick image file',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vertical preview (9:16)',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Works on web, desktop & mobile',
                        style: GoogleFonts.outfit(
                            fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── STEP 5: Details ──
            if (_selectedPlatform != null) ...[
              Text(
                'Step 5 — Post Details',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Post Title',
                  labelStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.6), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caption,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Caption',
                  labelStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.6), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _scheduledDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _scheduledDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white),
                      label: Text(
                        '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.cyan.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        if (picked != null) setState(() => _scheduledTime = picked);
                      },
                      icon: const Icon(Icons.access_time_rounded, size: 16, color: Colors.white),
                      label: Text(
                        _scheduledTime.format(context),
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.cyan.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate() ||
                      _selectedClient == null ||
                      _selectedPlatform == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields and select platform')),
                    );
                    return;
                  }
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
                  widget.onSave(_ScheduledPost(
                    title: _title.text.trim(),
                    caption: _caption.text.trim(),
                    clientName: _selectedClient!.companyName,
                    platform: _selectedPlatform!,
                    type: _contentType,
                    scheduledAt: finalDate,
                    color: platform.color,
                    imageBytes: _mediaBytes,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Schedule Content',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _contentType == 'Story' || _contentType == 'Reel'
                    ? 'ℹ️ ${_contentType}s are automatically archived to Media Archive after posting.'
                    : 'ℹ️ Post will appear in Publishing Queue & Published sections.',
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ] else if (_selectedClient != null && availablePlatforms.isEmpty) ...[
              // Client selected but no platforms
              const SizedBox(height: 8),
            ] else if (_selectedClient == null) ...[
              // No client selected yet — show hint
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: AppColors.cyan.withOpacity(0.6), size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Select a client to begin creating content',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}