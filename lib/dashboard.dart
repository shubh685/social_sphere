// dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialee_sphere/login.dart';
import 'analytics_dashboard.dart';
import 'dashboard_shared.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  String _activeSubSection = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Currently selected client — when non-null, menu sections show
  /// only that client's data.
  ClientModel? _selectedClient;

  /// Date range for analytics.
  DateRangeSelection _analyticsRange = DateRangeSelection(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
    label: 'Last 30 Days',
  );

  final Map<String, bool> _expandedMenus = {
    'clients': false,
    'social': false,
    'content': false,
  };

  final List<ClientModel> _clients = [];
  final List<ScheduledPost> _scheduledPosts = [];
  final List<MediaItem> _mediaArchive = [];
  final List<PublishedPost> _publishedPosts = [];
  final List<FailedPost> _failedPosts = [];

  late AnimationController _bgAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _bgAnimation;
  late Animation<double> _glowAnimation;

  late final List<MenuItemModel> _menuItems = [
    const MenuItemModel(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      color: AppColors.cyan,
    ),
    const MenuItemModel(
      icon: Icons.people_alt_rounded,
      label: 'Clients',
      color: AppColors.purple,
      isExpandable: true,
      key: 'clients',
      children: [
        SubItemModel(icon: Icons.list_alt_rounded, label: 'Client List'),
        SubItemModel(icon: Icons.person_add_alt_1_rounded, label: 'Add Client'),
      ],
    ),
    MenuItemModel(
      icon: Icons.share_rounded,
      label: 'Social Accounts',
      color: AppColors.blue,
      isExpandable: true,
      key: 'social',
      children: kSocialPlatforms
          .map((p) => SubItemModel(icon: p.icon, label: p.name))
          .toList(),
    ),
    const MenuItemModel(
      icon: Icons.article_rounded,
      label: 'Content',
      color: AppColors.green,
      isExpandable: true,
      key: 'content',
      children: [
        SubItemModel(icon: Icons.edit_note_rounded, label: 'Create Content'),
        SubItemModel(icon: Icons.drafts_rounded, label: 'Drafts'),
        SubItemModel(icon: Icons.perm_media_rounded, label: 'Media Archive'),
      ],
    ),
    const MenuItemModel(
      icon: Icons.calendar_month_rounded,
      label: 'Calendar',
      color: AppColors.amber,
    ),
    const MenuItemModel(
      icon: Icons.queue_rounded,
      label: 'Publishing Queue',
      color: AppColors.orange,
    ),
    const MenuItemModel(
      icon: Icons.check_circle_rounded,
      label: 'Published',
      color: AppColors.green,
    ),
    const MenuItemModel(
      icon: Icons.error_rounded,
      label: 'Failed',
      color: AppColors.red,
    ),
    const MenuItemModel(
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
      CurvedAnimation(
          parent: _glowAnimationController, curve: Curves.easeInOut),
    );

    _seedDemoData();
  }

  void _seedDemoData() {
    _clients.addAll([
      ClientModel(
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
      ClientModel(
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
      ClientModel(
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
      ScheduledPost(
        title: 'Summer Campaign Reel',
        caption: 'Beat the heat with our new collection! #summer',
        clientName: 'TechNova Solutions',
        platform: 'Instagram',
        type: 'Reel',
        scheduledAt: DateTime(now.year, now.month, now.day + 1, 10, 30),
        color: AppColors.purple,
      ),
      ScheduledPost(
        title: 'Morning Brew Story',
        caption: 'Start your day right ☕',
        clientName: 'Bloom Café',
        platform: 'Instagram',
        type: 'Story',
        scheduledAt: DateTime(now.year, now.month, now.day + 2, 8, 0),
        color: AppColors.pink,
      ),
      ScheduledPost(
        title: 'Fitness Challenge Post',
        caption: 'Join our 30-day challenge!',
        clientName: 'FitPulse Gym',
        platform: 'Facebook',
        type: 'Post',
        scheduledAt: DateTime(now.year, now.month, now.day + 3, 18, 0),
        color: AppColors.green,
      ),
      ScheduledPost(
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
      MediaItem(
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
      MediaItem(
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
      MediaItem(
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
      MediaItem(
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
      PublishedPost(
        title: 'Welcome Post',
        clientName: 'TechNova Solutions',
        platform: 'Facebook',
        publishedAt: DateTime(now.year, now.month, now.day - 5, 10, 0),
        likes: 245,
        comments: 32,
        shares: 18,
        color: AppColors.facebook,
      ),
      PublishedPost(
        title: 'New Menu Reveal',
        clientName: 'Bloom Café',
        platform: 'Instagram',
        publishedAt: DateTime(now.year, now.month, now.day - 6, 12, 30),
        likes: 892,
        comments: 67,
        shares: 45,
        color: AppColors.instagram,
      ),
      PublishedPost(
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
      FailedPost(
        title: 'Flash Sale Announcement',
        clientName: 'TechNova Solutions',
        platform: 'Instagram',
        failedAt: DateTime(now.year, now.month, now.day - 1, 9, 0),
        reason: 'API rate limit exceeded',
        color: AppColors.red,
      ),
      FailedPost(
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isTablet = size.width >= 768 && size.width < 1200;

    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.scaffoldLight,
          drawer: isMobile ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: _sidebarCollapsed ? 92 : (isTablet ? 220 : 260),
                  child: ClipRect(
                    child: Container(
                      margin: const EdgeInsets.all(10),
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.cyan.withOpacity(0.2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child:
                        _buildSidebar(isMobile: false, isTablet: isTablet),
                      ),
                    ),
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

  Widget _buildSidebar({required bool isMobile, required bool isTablet}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsed = constraints.maxWidth < 160;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebarBrand(forceExpanded: !collapsed),
            const SizedBox(height: 6),
            Divider(
              color: Colors.white.withOpacity(0.08),
              height: 1,
              indent: 10,
              endIndent: 10,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) =>
                    _buildMenuItem(index, forceExpanded: !collapsed),
              ),
            ),
            _buildSidebarFooter(forceExpanded: !collapsed),
          ],
        );
      },
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
            children: [
              _buildSidebarBrand(forceExpanded: true),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  physics: const ClampingScrollPhysics(),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) =>
                      _buildMenuItem(index, forceExpanded: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom,
                ),
                child: _buildSidebarFooter(forceExpanded: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarBrand({bool forceExpanded = false}) {
    final showExpanded = forceExpanded;

    if (!showExpanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Center(
          child: AnimatedBuilder(
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
                      color: AppColors.cyan
                          .withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 22),
              );
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 10, 8),
      child: SizedBox(
        height: 40,
        child: ClipRect(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                          color: AppColors.cyan
                              .withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 22),
                  );
                },
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Socialee',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _sidebarCollapsed = true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.06),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, {bool forceExpanded = false}) {
    final item = _menuItems[index];
    final isSelected = _selectedIndex == index;
    final showExpanded = forceExpanded;
    final isExpanded = item.isExpandable &&
        (_expandedMenus[item.key] ?? false) &&
        showExpanded;

    if (!showExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _activeSubSection = '';
                if (item.isExpandable && item.children != null) {
                  _sidebarCollapsed = false;
                  _expandedMenus[item.key] = true;
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? item.color.withOpacity(0.18)
                    : Colors.white.withOpacity(0.04),
                border: isSelected
                    ? Border.all(color: item.color.withOpacity(0.4), width: 1)
                    : null,
              ),
              child: Icon(
                item.icon,
                color: isSelected ? item.color : Colors.white70,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (item.isExpandable) {
                  setState(() {
                    _expandedMenus[item.key] =
                    !(_expandedMenus[item.key] ?? false);
                  });
                } else {
                  setState(() {
                    _selectedIndex = index;
                    _activeSubSection = '';
                  });
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    _scaffoldKey.currentState?.closeDrawer();
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      ? Border.all(
                      color: item.color.withOpacity(0.4), width: 1)
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSelected
                            ? item.color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected ? item.color : Colors.white70,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    if (item.isExpandable)
                      Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded && item.children != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: item.children!.map((sub) {
                final isSubSelected = _activeSubSection == sub.label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeSubSection = sub.label;
                        _selectedIndex = index;
                      });
                      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                        _scaffoldKey.currentState?.closeDrawer();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSubSelected
                            ? item.color.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sub.icon,
                            size: 15,
                            color: isSubSelected
                                ? item.color
                                : Colors.white54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.label,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: isSubSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: isSubSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
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

  Widget _buildSidebarFooter({bool forceExpanded = false}) {
    final showExpanded = forceExpanded;

    return Padding(
      padding: EdgeInsets.all(showExpanded ? 8 : 6),
      child: Container(
        padding: EdgeInsets.all(showExpanded ? 8 : 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              AppColors.purple.withOpacity(0.15),
              AppColors.cyan.withOpacity(0.08),
            ],
          ),
          border:
          Border.all(color: AppColors.purple.withOpacity(0.2), width: 1),
        ),
        child: showExpanded
            ? Row(
          children: [
            CircleAvatar(
              radius: 14,
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
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Agency Admin',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    'admin@grow.io',
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        )
            : Center(
          child: CircleAvatar(
            radius: 14,
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
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isMobile, bool isTablet) {
    final baseTitle = _menuItems[_selectedIndex].label;
    final sub = _activeSubSection.isEmpty ? '' : ' • $_activeSubSection';
    final clientTag =
    _selectedClient == null ? '' : ' • ${_selectedClient!.companyName}';
    final title = '$baseTitle$sub$clientTag';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
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
            if (isMobile)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: AppColors.textDark),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  _sidebarCollapsed
                      ? Icons.menu_open_rounded
                      : Icons.menu_rounded,
                  color: AppColors.textDark,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 12),
            if (_selectedClient != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedClient = null),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: AppColors.purple.withOpacity(0.12),
                      border: Border.all(
                          color: AppColors.purple.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_rounded,
                            size: 12, color: _selectedClient!.logoColor),
                        const SizedBox(width: 5),
                        Text(
                          _selectedClient!.companyName,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close_rounded,
                            size: 12, color: AppColors.textDarkMuted),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
            if (!isMobile && !isTablet)
              Container(
                width: 200,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(Icons.search_rounded,
                        size: 16, color: AppColors.textDarkMuted),
                    const SizedBox(width: 8),
                    Text(
                      'Search...',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textDarkMuted),
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
                    color: AppColors.scaffoldLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.notifications_rounded,
                      size: 18, color: AppColors.textDarkSoft),
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
                        BoxShadow(
                            color: AppColors.pink.withOpacity(0.6),
                            blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // ── Logout button (responsive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Avatar
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 14, color: Colors.white),
                  ),

                  // ── "Admin" text (hidden on mobile/tablet)
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

                  // ── Divider between identity and action
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 18,
                    color: Colors.white.withOpacity(0.25),
                  ),

                  // ── Logout icon-button
                  _buildLogoutButton(isMobile: isMobile, isTablet: isTablet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Beautiful responsive logout button — icon only on mobile/tablet,
  /// icon + label on desktop. Shows a confirmation dialog before logging out.
  Widget _buildLogoutButton({
    required bool isMobile,
    required bool isTablet,
  }) {
    final showLabel = !isMobile && !isTablet;
    final accent = AppColors.pink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirmLogout(),
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 12 : 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.85),
                AppColors.purple.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 14,
                color: Colors.white,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  'Logout',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Confirmation dialog + logout action.
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.pink.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pink.withOpacity(0.2),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pink.withOpacity(0.22),
                      AppColors.purple.withOpacity(0.10),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.pink.withOpacity(0.45),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.pink,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Log out?',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You will be signed out of your agency workspace. '
                    'Any unsaved changes will be lost.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: AppColors.textDarkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Logout
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.pink,
                            AppColors.purple,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => LogIN())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true && mounted) {
      // Simulated logout → navigate to login screen.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewSection();
      case 1:
        if (_activeSubSection == 'Add Client') return _buildAddClientForm();
        return _buildClientsList();
      case 2:
        if (_activeSubSection.isNotEmpty) {
          return _buildPlatformAccounts(_activeSubSection);
        }
        return _buildSocialAccounts();
      case 3:
        if (_activeSubSection == 'Create Content') {
          return _buildCreateContentForm();
        }
        if (_activeSubSection == 'Drafts') return _buildDrafts();
        if (_activeSubSection == 'Media Archive') return _buildMediaArchive();
        return _buildCreateContentForm();
      case 4:
        return _buildCalendarSection();
      case 5:
        return PublishingSections.buildPublishingQueue(
          _scheduledPosts,
          filterClientName: _selectedClient?.companyName,
        );
      case 6:
        return PublishingSections.buildPublishedSection(
          _publishedPosts,
          filterClientName: _selectedClient?.companyName,
        );
      case 7:
        return PublishingSections.buildFailedSection(
          _failedPosts,
          filterClientName: _selectedClient?.companyName,
        );
      case 8:
        return PublishingSections.buildAnalyticsSection(
          _publishedPosts,
          filterClientName: _selectedClient?.companyName,
          dateRange: _analyticsRange,
          onDateRangeTap: _showAnalyticsDateRangePicker,
        );
      default:
        return _buildOverviewSection();
    }
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
                _presetRange(ctx, 'Year to Date',
                    now.difference(DateTime(now.year, 1, 1)).inDays, now),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.purple.withOpacity(0.12),
                    ),
                    child: const Icon(Icons.date_range_rounded,
                        color: AppColors.purple, size: 20),
                  ),
                  title: Text('Custom Range',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      )),
                  subtitle: Text('Pick start & end dates',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.textDarkMuted)),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: DateTimeRange(
                        start: _analyticsRange.startDate,
                        end: _analyticsRange.endDate,
                      ),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.purple,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppColors.textDark,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null && ctx.mounted) {
                      Navigator.of(ctx).pop(DateRangeSelection(
                        startDate: picked.start,
                        endDate: picked.end,
                        label:
                        '${formatDateLong(picked.start)} → ${formatDateLong(picked.end)}',
                      ));
                    }
                  },
                ),
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

  Widget _buildOverviewSection() {
    return _scrollWrapper(children: [
      _buildWelcomeBanner(),
      const SizedBox(height: 20),
      _buildStatsRow(),
      const SizedBox(height: 20),
      buildSectionTitle('Quick Actions'),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              children: [
                _actionTile('Add Client', Icons.person_add_alt_1_rounded,
                    AppColors.purple, () {
                      setState(() {
                        _selectedIndex = 1;
                        _activeSubSection = 'Add Client';
                        _expandedMenus['clients'] = true;
                      });
                    }),
                const SizedBox(height: 12),
                _actionTile('Create Content', Icons.edit_note_rounded,
                    AppColors.cyan, () {
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
              Expanded(
                child: _actionTile('Add Client',
                    Icons.person_add_alt_1_rounded, AppColors.purple, () {
                      setState(() {
                        _selectedIndex = 1;
                        _activeSubSection = 'Add Client';
                        _expandedMenus['clients'] = true;
                      });
                    }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionTile('Create Content', Icons.edit_note_rounded,
                    AppColors.cyan, () {
                      setState(() {
                        _selectedIndex = 3;
                        _activeSubSection = 'Create Content';
                        _expandedMenus['content'] = true;
                      });
                    }),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      buildSectionTitle('Recent Scheduled Posts'),
      const SizedBox(height: 12),
      if (_scheduledPosts.isEmpty)
        buildEmptyState(
          icon: Icons.schedule_rounded,
          title: 'No scheduled posts',
          subtitle: 'Schedule your first content to see it here.',
        )
      else
        ..._scheduledPosts.take(3).map((post) => buildPostCard(post)),
    ]);
  }

  Widget _actionTile(
      String label, IconData icon, Color color, VoidCallback onTap) {
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
            border: Border.all(color: color.withOpacity(0.35), width: 1),
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
                  color: color.withOpacity(0.12),
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
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to open',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textDarkMuted,
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
        gradient: const LinearGradient(
          colors: [Color(0xFF0A0E27), Color(0xFF1E1B4B), Color(0xFF311042)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.purple.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.18),
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
                  _selectedClient == null
                      ? 'Manage client registrations, content scheduling, and calendar in one place. Tap any client card to focus on their data.'
                      : 'Viewing data for ${_selectedClient!.companyName}.',
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
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 28),
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
      _Stat('Clients', '${_clients.length}', Icons.people_alt_rounded,
          AppColors.purple),
      _Stat('Scheduled', '${_scheduledPosts.length}', Icons.schedule_rounded,
          AppColors.cyan),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.color.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: s.color.withOpacity(0.1),
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
                    color: s.color.withOpacity(0.12),
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
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppColors.textDarkMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        s.value,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20,
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
        },
      ),
    );
  }

  Widget _buildClientsList() {
    return _scrollWrapper(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: buildSectionTitle('Client List (${_clients.length})')),
          TextButton.icon(
            onPressed: () => setState(() {
              _activeSubSection = 'Add Client';
              _expandedMenus['clients'] = true;
            }),
            icon: const Icon(Icons.add_rounded,
                size: 16, color: AppColors.purple),
            label: Text(
              'Add Client',
              style: GoogleFonts.outfit(
                  color: AppColors.purple, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Tap a client card to focus every section on that client.',
        style: GoogleFonts.outfit(
            fontSize: 11.5, color: AppColors.textDarkMuted),
      ),
      const SizedBox(height: 12),
      if (_clients.isEmpty)
        buildEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No clients yet',
          subtitle: 'Register your first client to get started.',
        )
      else
        ..._clients.map((client) => _buildClientCard(client)),
    ]);
  }

  Widget _buildClientCard(ClientModel client) {
    final isSelected = _selectedClient?.companyName == client.companyName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedClient = isSelected ? null : client;
            });
            _showSnack(
              isSelected
                  ? 'Cleared client filter'
                  : 'Focused on ${client.companyName}',
              isSelected ? AppColors.amber : client.logoColor,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? client.logoColor
                    : client.logoColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: client.logoColor
                      .withOpacity(isSelected ? 0.2 : 0.08),
                  blurRadius: isSelected ? 22 : 16,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              client.companyName,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: client.logoColor.withOpacity(0.15),
                                border: Border.all(
                                    color:
                                    client.logoColor.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 11, color: client.logoColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Selected',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: client.logoColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildIconText(Icons.mail_outline_rounded, client.email),
                      _buildIconText(Icons.phone_outlined, client.mobile),
                      _buildIconText(
                          Icons.location_on_outlined, client.address),
                      if (client.website.isNotEmpty)
                        _buildIconText(
                            Icons.language_rounded, client.website),
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
                            final metaConnected =
                                client.metaConnected[e.key] ?? false;
                            return _buildSocialChip(p, e.value,
                                metaConnected: metaConnected);
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientLogo(ClientModel client, {double size = 52}) {
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
          colors: [
            client.logoColor.withOpacity(0.4),
            client.logoColor.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: client.logoColor.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          client.companyName.isNotEmpty
              ? client.companyName[0].toUpperCase()
              : '?',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialChip(SocialPlatform p, String handle,
      {bool metaConnected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: p.color.withOpacity(0.1),
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
                  BoxShadow(
                      color: AppColors.green.withOpacity(0.6), blurRadius: 4),
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
          Icon(icon, size: 12, color: AppColors.textDarkMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppColors.textDarkSoft),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddClientForm() {
    return AddClientForm(
      onSave: (client) {
        setState(() {
          _clients.add(client);
          _activeSubSection = 'Client List';
        });
        _showSnack('Client "${client.companyName}" registered successfully!',
            AppColors.green);
      },
      onCancel: () => setState(() => _activeSubSection = 'Client List'),
    );
  }

  Widget _buildSocialAccounts() {
    final scopedClients = _selectedClient == null
        ? _clients
        : _clients
        .where((c) => c.companyName == _selectedClient!.companyName)
        .toList();

    final Map<String, int> platformCounts = {};
    final Map<String, int> metaConnectedCounts = {};
    for (final c in scopedClients) {
      for (final p in c.socialHandles.keys) {
        platformCounts[p] = (platformCounts[p] ?? 0) + 1;
        if (c.metaConnected[p] == true) {
          metaConnectedCounts[p] = (metaConnectedCounts[p] ?? 0) + 1;
        }
      }
    }

    return _scrollWrapper(children: [
      buildSectionTitle('Social Accounts'),
      if (_selectedClient != null) ...[
        const SizedBox(height: 4),
        Text(
          'Filtered by: ${_selectedClient!.companyName}',
          style: GoogleFonts.outfit(
              fontSize: 11.5, color: AppColors.textDarkMuted),
        ),
      ],
      const SizedBox(height: 4),
      Text(
        'All platforms are connected via Meta Business Suite for unified publishing.',
        style: GoogleFonts.outfit(
            fontSize: 11.5, color: AppColors.textDarkMuted),
      ),
      const SizedBox(height: 12),
      ...kSocialPlatforms.map((p) {
        final count = platformCounts[p.name] ?? 0;
        final metaCount = metaConnectedCounts[p.name] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.color.withOpacity(0.35)),
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
                    colors: [
                      p.color.withOpacity(0.25),
                      p.color.withOpacity(0.08),
                    ],
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
                        Flexible(
                          child: Text(
                            p.name,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.usesMetaIntegration) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: AppColors.blue.withOpacity(0.15),
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
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textDarkMuted),
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

    final sourceClients = _selectedClient == null
        ? _clients
        : _clients
        .where((c) => c.companyName == _selectedClient!.companyName)
        .toList();

    final entries = <MapEntry<ClientModel, String>>[];
    for (final c in sourceClients) {
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
                colors: [
                  platform.color.withOpacity(0.25),
                  platform.color.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: platform.color.withOpacity(0.4)),
            ),
            child: Icon(platform.icon, color: platform.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              platform.name,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            '${entries.length} account${entries.length == 1 ? '' : 's'}',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textDarkMuted),
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
              platform.usesMetaIntegration
                  ? Icons.verified_rounded
                  : Icons.info_outline_rounded,
              size: 14,
              color: platform.usesMetaIntegration
                  ? AppColors.blue
                  : AppColors.amber,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                platform.usesMetaIntegration
                    ? 'Connected via Meta Business Suite — unified login & publishing.'
                    : 'Connected via native ${platform.name} API.',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: platform.usesMetaIntegration
                      ? AppColors.blue
                      : AppColors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (entries.isEmpty)
        buildEmptyState(
          icon: platform.icon,
          title: 'No ${platform.name} accounts',
          subtitle:
          'Register a client with a ${platform.name} handle to see it here.',
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
              color: Colors.white,
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
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(platform.icon,
                              size: 12, color: platform.color),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: (isMetaConnected ? AppColors.green : AppColors.amber)
                        .withOpacity(0.15),
                    border: Border.all(
                      color:
                      (isMetaConnected ? AppColors.green : AppColors.amber)
                          .withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMetaConnected
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        size: 11,
                        color: isMetaConnected
                            ? AppColors.green
                            : AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMetaConnected ? 'Connected' : 'Pending',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isMetaConnected
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
        }),
    ]);
  }

  Widget _buildCreateContentForm() {
    return CreateContentForm(
      clients: _clients,
      lockedClient: _selectedClient,
      onSave: (post) {
        setState(() {
          _scheduledPosts.add(post);
          final isArchiveType = post.type == 'Story' || post.type == 'Reel';
          if (isArchiveType) {
            _mediaArchive.add(MediaItem(
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
        _showSnack(
            'Content successfully created and scheduled!', AppColors.green);
      },
      onCancel: () => setState(() => _activeSubSection = ''),
    );
  }

  Widget _buildDrafts() {
    return _scrollWrapper(children: [
      buildSectionTitle('Drafts'),
      const SizedBox(height: 12),
      buildEmptyState(
        icon: Icons.drafts_rounded,
        title: 'No drafts',
        subtitle: 'Your saved drafts will appear here.',
      ),
    ]);
  }

  Widget _buildMediaArchive() {
    var items = _mediaArchive;
    if (_selectedClient != null) {
      items = items
          .where((m) => m.clientName == _selectedClient!.companyName)
          .toList();
    }
    final archived = items.where((m) => m.isArchived).toList();
    final active = items.where((m) => !m.isArchived).toList();

    return _scrollWrapper(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: buildSectionTitle('Media Archive (${archived.length})')),
          Text(
            _selectedClient == null
                ? 'Stories & Reels auto-archived'
                : 'For ${_selectedClient!.companyName}',
            style: GoogleFonts.outfit(
                fontSize: 11, color: AppColors.textDarkMuted),
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
            color: AppColors.textDarkSoft,
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
          color: AppColors.textDarkSoft,
        ),
      ),
      const SizedBox(height: 8),
      if (archived.isEmpty)
        buildEmptyState(
          icon: Icons.photo_library_outlined,
          title: 'No archived media',
          subtitle:
          'Stories & Reels you post will be archived here automatically.',
        )
      else
        _buildMediaGrid(archived),
    ]);
  }

  Widget _buildMediaGrid(List<MediaItem> items) {
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
                color: Colors.white,
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
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13)),
                      child: m.imageBytes != null
                          ? Image.memory(m.imageBytes!, fit: BoxFit.cover)
                          : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              m.color.withOpacity(0.25),
                              m.color.withOpacity(0.08),
                            ],
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: m.color.withOpacity(0.15),
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
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.caption,
                          style: GoogleFonts.outfit(
                              fontSize: 10, color: AppColors.textDarkSoft),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.clientName} • ${m.platform}',
                          style: GoogleFonts.outfit(
                              fontSize: 9.5, color: AppColors.textDarkMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(m.postedAt),
                          style: GoogleFonts.outfit(
                              fontSize: 9, color: AppColors.amber),
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

  DateTime _calendarMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  Widget _buildCalendarSection() {
    return _scrollWrapper(children: [
      // ── Header row (title + pick date)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: buildSectionTitle('Content Calendar')),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                builder: (context, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.purple,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: AppColors.textDark,
                    ),
                    dialogBackgroundColor: Colors.white,
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
            icon: const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.purple),
            label: Text(
              'Pick Date',
              style: GoogleFonts.outfit(
                  color: AppColors.purple, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      if (_selectedClient != null) ...[
        const SizedBox(height: 4),
        Text(
          'Filtered by: ${_selectedClient!.companyName}',
          style: GoogleFonts.outfit(
              fontSize: 11.5, color: AppColors.textDarkMuted),
        ),
      ],
      const SizedBox(height: 12),

      // ═════════════════════════════════════════════════════════════════
      // RESPONSIVE SPLIT: Calendar (left) + Scheduled Posts (right)
      //
      // • Wide (>= 900px): two columns side-by-side.
      //     - Left  : calendar (flex 4)
      //     - Right : scheduled posts for the selected date (flex 5)
      // • Narrow (< 900px): stacked vertically (calendar on top,
      //   posts below) so nothing gets cramped.
      // ═════════════════════════════════════════════════════════════════
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          final calendarSide = _buildCalendarWidget();

          final postsSide = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildSectionTitle(
                  'Scheduled Posts on ${formatDateLong(_selectedDate)}'),
              const SizedBox(height: 10),
              _buildPostsForSelectedDate(),
            ],
          );

          if (isWide) {
            // ── Side-by-side layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar column (fixed-ish, matches its own max width)
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: calendarSide,
                  ),
                ),
                const SizedBox(width: 16),
                // Scheduled posts column
                Expanded(
                  flex: 5,
                  child: postsSide,
                ),
              ],
            );
          }

          // ── Stacked layout (mobile / tablet)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              calendarSide,
              const SizedBox(height: 20),
              postsSide,
            ],
          );
        },
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SINGLE, RESPONSIVE CALENDAR WIDGET
  //
  // • Width is capped (max 720 px) so it stays card-like on wide screens
  //   — matching Photo 1 — instead of stretching across the whole area.
  // • Cell height is FIXED at a compact value (56–70 px) so it never
  //   stretches vertically — matching Photo 1 rather than Photo 2.
  // • On small screens the calendar shrinks fluidly.
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCalendarWidget() {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Align(
      alignment: Alignment.topLeft,
      child: LayoutBuilder(
        builder: (context, outer) {
          // Cap width so calendar doesn't get huge on desktop.
          final cardWidth = outer.maxWidth.clamp(280.0, 640.0);

          // Adaptive, but capped, cell height based on available width.
          // - Narrow (< 380 px content): 60 px  → compact like Photo 1
          // - Medium  (380–520 px)     : 66 px
          // - Wide    (> 520 px)       : 72 px (capped, so it doesn't
          //                                    stretch like Photo 2)
          final cellHeight = cardWidth < 380
              ? 60.0
              : cardWidth < 520
              ? 66.0
              : 72.0;

          const crossSpacing = 6.0;
          final innerWidth = cardWidth - 24; // minus padding
          final cellWidth = (innerWidth - crossSpacing * 6) / 7;
          final ratio = cellWidth / cellHeight;

          return SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.amber.withOpacity(0.3), width: 1),
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
                  // ── Month header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _calNavBtn(
                        Icons.chevron_left_rounded,
                            () => setState(() {
                          _calendarMonth = DateTime(
                              _calendarMonth.year, _calendarMonth.month - 1);
                        }),
                      ),
                      Text(
                        formatMonthYear(_calendarMonth),
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      _calNavBtn(
                        Icons.chevron_right_rounded,
                            () => setState(() {
                          _calendarMonth = DateTime(
                              _calendarMonth.year, _calendarMonth.month + 1);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Weekday header
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

                  // ── Day grid (fixed compact cell height)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: crossSpacing,
                      childAspectRatio: ratio,
                    ),
                    itemCount: startWeekday + daysInMonth,
                    itemBuilder: (context, i) {
                      if (i < startWeekday) return const SizedBox();
                      final day = i - startWeekday + 1;
                      final date = DateTime(
                          _calendarMonth.year, _calendarMonth.month, day);
                      final isSelected = isSameDay(date, _selectedDate);
                      final isToday = isSameDay(date, DateTime.now());
                      final scopedPosts = _selectedClient == null
                          ? _scheduledPosts
                          : _scheduledPosts
                          .where((p) =>
                      p.clientName ==
                          _selectedClient!.companyName)
                          .toList();
                      final postsOnDay = scopedPosts
                          .where((p) => isSameDay(p.scheduledAt, date))
                          .toList();

                      return _calendarDayCell(
                        day: day,
                        isSelected: isSelected,
                        isToday: isToday,
                        postsOnDay: postsOnDay,
                        onTap: () =>
                            setState(() => _selectedDate = date),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // ── Legend
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _calendarLegend(AppColors.instagram, 'Instagram'),
                      _calendarLegend(AppColors.facebook, 'Facebook'),
                      _calendarLegend(AppColors.youtube, 'YouTube'),
                      _calendarLegend(AppColors.linkedin, 'LinkedIn'),
                      _calendarLegend(AppColors.threads, 'Threads'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mini nav button for the calendar header.
  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
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

  /// Compact single day cell (day number + platform dots).
  Widget _calendarDayCell({
    required int day,
    required bool isSelected,
    required bool isToday,
    required List<ScheduledPost> postsOnDay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                  fontWeight:
                  isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (postsOnDay.isNotEmpty)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: postsOnDay.take(3).map((p) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: p.color),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Legend chip.
  Widget _calendarLegend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 9.5, color: AppColors.textDarkMuted),
        ),
      ],
    );
  }

  Widget _buildPostsForSelectedDate() {
    final scoped = _selectedClient == null
        ? _scheduledPosts
        : _scheduledPosts
        .where((p) => p.clientName == _selectedClient!.companyName)
        .toList();
    final posts =
    scoped.where((p) => isSameDay(p.scheduledAt, _selectedDate)).toList();

    if (posts.isEmpty) {
      return buildEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No posts on this date',
        subtitle: 'Select another date or schedule new content.',
      );
    }

    // Wrap the list in a Column with stretch so card widths match the
    // right-hand column nicely.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: posts.map((post) => buildPostCard(post)).toList(),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _Stat(this.label, this.value, this.icon, this.color);
}