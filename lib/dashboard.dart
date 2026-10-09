// dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialee_sphere/login.dart';
import 'analytics_dashboard.dart';
import 'client_dashbaord.dart';
import 'dashboard_shared.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  String? _allPlatformsClientFilter;
  String _activeSubSection = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ClientModel? _selectedClient;
  ClientModel? _socialHandlesClient;

  final Map<String, bool> _expandedMenus = {
    'clients': false,
    'social': false,
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

  // ── SIMPLIFIED SIDEBAR: Dashboard, Clients, Social Accounts
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
    const MenuItemModel(
      icon: Icons.share_rounded,
      label: 'Social Accounts',
      color: AppColors.blue,
      isExpandable: true,
      key: 'social',
      children: [
        SubItemModel(icon: Icons.apps_rounded, label: 'All Platforms'),
      ],
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
    final title = '$baseTitle$sub';

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
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 18,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  _buildLogoutButton(isMobile: isMobile, isTablet: isTablet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => const LogIN())),
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
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MAIN CONTENT ROUTER — now simplified (only 3 top-level sections)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewSection();
      case 1:
        if (_activeSubSection == 'Add Client') return _buildAddClientForm();
        return _buildClientsList();
      case 2:
        if (_activeSubSection == 'Add Handles') {
          return _buildAddSocialHandlesForm();
        }
        if (_activeSubSection == 'All Platforms') {
          return _buildAllPlatformsScreen();
        }
        return _buildSocialAccountsOverview();
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

  // ── OVERVIEW (Dashboard) ──────────────────────────────────────────────
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
                _actionTile('Open Client Dashboard',
                    Icons.dashboard_customize_rounded, AppColors.cyan, () {
                      setState(() {
                        _selectedIndex = 1;
                        _activeSubSection = 'Client List';
                        _expandedMenus['clients'] = true;
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
                child: _actionTile(
                    'Open Client Dashboard',
                    Icons.dashboard_customize_rounded,
                    AppColors.cyan, () {
                  setState(() {
                    _selectedIndex = 1;
                    _activeSubSection = 'Client List';
                    _expandedMenus['clients'] = true;
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
                  'Open a client dashboard to manage their content, calendar, publishing queue, and analytics.',
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

  // ── CLIENTS ──────────────────────────────────────────────────────────
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
        'Tap a client card to open its dedicated dashboard.',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // ── TAP → open separate Client Dashboard page
          onTap: () => _openClientDashboard(client),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: client.logoColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: client.logoColor.withOpacity(0.08),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: client.logoColor.withOpacity(0.12),
                              border: Border.all(
                                  color: client.logoColor.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: client.logoColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 11, color: client.logoColor),
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

  void _openClientDashboard(ClientModel client) {
    // Scope all posts to this client and open the dedicated page.
    final clientScheduled = _scheduledPosts
        .where((p) => p.clientName == client.companyName)
        .toList();
    final clientPublished = _publishedPosts
        .where((p) => p.clientName == client.companyName)
        .toList();
    final clientFailed = _failedPosts
        .where((p) => p.clientName == client.companyName)
        .toList();
    final clientMedia = _mediaArchive
        .where((m) => m.clientName == client.companyName)
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDashboard(
          client: client,
          scheduledPosts: clientScheduled,
          publishedPosts: clientPublished,
          failedPosts: clientFailed,
          mediaArchive: clientMedia,
          onScheduleNew: (post) {
            setState(() => _scheduledPosts.add(post));
          },
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
          _selectedIndex = 2;
          _activeSubSection = 'Add Handles';
          _socialHandlesClient = client;
          _expandedMenus['social'] = true;
        });
        _showSnack(
          'Client "${client.companyName}" registered! Now add their social handles.',
          AppColors.green,
        );
      },
      onCancel: () => setState(() => _activeSubSection = 'Client List'),
    );
  }

  // ── SOCIAL ACCOUNTS ──────────────────────────────────────────────────
  Widget _buildSocialAccountsOverview() {
    return _scrollWrapper(children: [
      buildSectionTitle('Social Accounts'),
      const SizedBox(height: 4),
      Text(
        'Manage connected handles for every client in one place.',
        style: GoogleFonts.outfit(
            fontSize: 11.5, color: AppColors.textDarkMuted),
      ),
      const SizedBox(height: 16),
      _socialOptionCard(
        title: 'Add Handles',
        subtitle: 'Pick a client and link their social media accounts.',
        icon: Icons.add_link_rounded,
        color: AppColors.purple,
        onTap: () => setState(() {
          _activeSubSection = 'Add Handles';
          _expandedMenus['social'] = true;
        }),
      ),
      const SizedBox(height: 12),
      _socialOptionCard(
        title: 'All Platforms',
        subtitle: 'See every connected account across all clients.',
        icon: Icons.apps_rounded,
        color: AppColors.blue,
        onTap: () => setState(() {
          _activeSubSection = 'All Platforms';
          _expandedMenus['social'] = true;
        }),
      ),
    ]);
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

  // ── ADD HANDLES ──────────────────────────────────────────────────────
  Widget _buildAddSocialHandlesForm() {
    if (_socialHandlesClient == null && _clients.isEmpty) {
      return _scrollWrapper(children: [
        buildSectionTitle('Add Social Handles'),
        const SizedBox(height: 8),
        buildEmptyState(
          icon: Icons.person_add_alt_1_rounded,
          title: 'No clients registered',
          subtitle: 'Register a client first from Clients → Add Client.',
        ),
      ]);
    }

    if (_socialHandlesClient == null) {
      return _scrollWrapper(children: [
        buildSectionTitle('Select a Client'),
        const SizedBox(height: 4),
        Text(
          'Pick the client whose social handles you want to add or edit.',
          style: GoogleFonts.outfit(
              fontSize: 11.5, color: AppColors.textDarkMuted),
        ),
        const SizedBox(height: 12),
        ..._clients.map((c) => _socialHandlesClientPickerTile(c)),
      ]);
    }

    return SocialHandlesForm(
      client: _socialHandlesClient!,
      onSave: (updated) {
        setState(() {
          final idx = _clients
              .indexWhere((c) => c.companyName == updated.companyName);
          if (idx != -1) _clients[idx] = updated;
          _socialHandlesClient = null;
          _activeSubSection = '';
        });
        _showSnack(
            'Social handles saved for "${updated.companyName}"!',
            AppColors.green);
      },
      onCancel: () => setState(() {
        _socialHandlesClient = null;
        _activeSubSection = '';
      }),
    );
  }

  Widget _socialHandlesClientPickerTile(ClientModel c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _socialHandlesClient = c),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.logoColor.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: c.logoColor.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(
                      colors: [
                        c.logoColor.withOpacity(0.4),
                        c.logoColor.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(color: c.logoColor.withOpacity(0.4)),
                  ),
                  child: c.logoBytes != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                    Image.memory(c.logoBytes!, fit: BoxFit.cover),
                  )
                      : Center(
                    child: Text(
                      c.companyName.isNotEmpty
                          ? c.companyName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.companyName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.socialHandles.isEmpty
                            ? 'No handles yet'
                            : '${c.socialHandles.length} handle(s)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: c.logoColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
// ALL PLATFORMS — combined responsive list of every connected account
// with a client filter (All Clients / specific client)
// ═══════════════════════════════════════════════════════════════════════
  Widget _buildAllPlatformsScreen() {
    // Build a flat list: one entry per (client, platform) pair
    final allEntries = <_ConnectedAccountEntry>[];
    for (final c in _clients) {
      for (final p in kSocialPlatforms) {
        final handle = c.socialHandles[p.name];
        if (handle != null && handle.isNotEmpty) {
          allEntries.add(_ConnectedAccountEntry(
            client: c,
            platform: p,
            handle: handle,
            metaConnected: c.metaConnected[p.name] ?? false,
          ));
        }
      }
    }

    // Apply client filter
    final entries = _allPlatformsClientFilter == null
        ? allEntries
        : allEntries
        .where((e) => e.client.companyName == _allPlatformsClientFilter)
        .toList();

    return _scrollWrapper(children: [
      buildSectionTitle('All Connected Platforms (${entries.length})'),
      const SizedBox(height: 4),
      Text(
        'Every social account linked across all clients — filter by client to focus.',
        style: GoogleFonts.outfit(
            fontSize: 11.5, color: AppColors.textDarkMuted),
      ),
      const SizedBox(height: 12),

      // ── Client filter row
      _clientFilterRow(),
      const SizedBox(height: 12),

      // ── Compact stats summary strip
      _allPlatformsSummary(entries),
      const SizedBox(height: 16),

      if (entries.isEmpty)
        buildEmptyState(
          icon: Icons.link_off_rounded,
          title: _allPlatformsClientFilter == null
              ? 'No connected platforms yet'
              : 'No platforms for this client',
          subtitle: _allPlatformsClientFilter == null
              ? 'Use Social Accounts → Add Handles to link a client\'s accounts.'
              : 'Add handles for ${_allPlatformsClientFilter!} from Add Handles.',
        )
      else
      // ── Responsive list (1 col on mobile, 2 col on tablet, 3 col on desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final columns = w > 1100
                ? 3
                : w > 720
                ? 2
                : 1;

            if (columns == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: entries
                    .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _allPlatformsCard(e),
                ))
                    .toList(),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 2 ? 2.6 : 2.8,
              ),
              itemCount: entries.length,
              itemBuilder: (context, i) => _allPlatformsCard(entries[i]),
            );
          },
        ),
    ]);
  }

// ── Client filter row (dropdown-style chips)
  Widget _clientFilterRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.purple.withOpacity(0.12),
              border: Border.all(color: AppColors.purple.withOpacity(0.3)),
            ),
            child: const Icon(Icons.filter_alt_rounded,
                size: 18, color: AppColors.purple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filter by Client',
                  style: GoogleFonts.outfit(
                      fontSize: 10.5, color: AppColors.textDarkMuted),
                ),
                const SizedBox(height: 2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _clientFilterChip(
                        label: 'All Clients',
                        color: AppColors.purple,
                        isSelected: _allPlatformsClientFilter == null,
                        onTap: () => setState(
                                () => _allPlatformsClientFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ..._clients.map((c) {
                        final isSelected =
                            _allPlatformsClientFilter == c.companyName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _clientFilterChip(
                            label: c.companyName,
                            color: c.logoColor,
                            isSelected: isSelected,
                            onTap: () => setState(() =>
                            _allPlatformsClientFilter = c.companyName),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Clear (X) button, shown only when a filter is applied
          if (_allPlatformsClientFilter != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    setState(() => _allPlatformsClientFilter = null),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.scaffoldLight,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.textDarkMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _clientFilterChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: isSelected
                ? color.withOpacity(0.14)
                : AppColors.scaffoldLight,
            border: Border.all(
              color: isSelected ? color : AppColors.borderLight,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle_rounded, size: 12, color: color),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color:
                  isSelected ? color : AppColors.textDarkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _allPlatformsSummary(List<_ConnectedAccountEntry> entries) {
    final Map<String, int> countsPerPlatform = {};
    for (final e in entries) {
      countsPerPlatform[e.platform.name] =
          (countsPerPlatform[e.platform.name] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Summary',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSocialPlatforms.map((p) {
              final count = countsPerPlatform[p.name] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: p.color.withOpacity(0.10),
                  border: Border.all(color: p.color.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p.icon, size: 12, color: p.color),
                    const SizedBox(width: 6),
                    Text(
                      '${p.name}: ',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDarkSoft,
                      ),
                    ),
                    Text(
                      '$count',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _allPlatformsCard(_ConnectedAccountEntry e) {
    final p = e.platform;
    final c = e.client;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Tap → open Add Handles for this client (so you can edit)
          setState(() {
            _socialHandlesClient = c;
            _activeSubSection = 'Add Handles';
            _expandedMenus['social'] = true;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              // Platform icon
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
              // Middle: client name + handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.companyName,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: p.color.withOpacity(0.12),
                          ),
                          child: Text(
                            p.name,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: p.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
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
        ),
      ),
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

class _ConnectedAccountEntry {
  final ClientModel client;
  final SocialPlatform platform;
  final String handle;
  final bool metaConnected;

  _ConnectedAccountEntry({
    required this.client,
    required this.platform,
    required this.handle,
    required this.metaConnected,
  });
}