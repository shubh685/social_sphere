// dashboard.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:socialee_sphere/login.dart';
import 'analytics_dashboard.dart';
import 'client_dashbaord.dart';
import 'dashboard_shared.dart';

class Dashboard extends StatefulWidget {
  final String agencyName;
  final String agencyEmail;

  const Dashboard({
    super.key,
    this.agencyName = 'Grow Socialee',
    this.agencyEmail = 'admin@grow.io',
  });

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  String _activeSubSection = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, bool> _expandedClients = {};

  final Map<String, bool> _expandedMenus = {
    'clients': false,
    'social': false,
  };

  final List<ClientModel> _clients = [];
  final List<ScheduledPost> _scheduledPosts = [];
  final List<MediaItem> _mediaArchive = [];
  final List<PublishedPost> _publishedPosts = [];
  final List<FailedPost> _failedPosts = [];

  bool _isLoadingClients = false;
  String? _loadError;

  late AnimationController _bgAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _bgAnimation;
  late Animation<double> _glowAnimation;

  static const String _apiBase = 'http://192.168.1.17/socialee_sphere';

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
      CurvedAnimation(parent: _glowAnimationController, curve: Curves.easeInOut),
    );

    // Defer API + static seeding to avoid layout hit-test errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _seedStaticPostsAndMedia();
        _fetchClientsFromApi();
      }
    });
  }

  // ── FETCH CLIENTS (GET API & FALLBACK) ───────────────────────────────────
  Future<void> _fetchClientsFromApi() async {
    if (!mounted) return;
    setState(() {
      _isLoadingClients = true;
      _loadError = null;
    });

    final encodedAgency = Uri.encodeComponent(widget.agencyName);
    final url =
    Uri.parse('$_apiBase/register_company.php?agency_name=$encodedAgency');

    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      final dynamic jsonResponse = jsonDecode(response.body);
      if (jsonResponse is! Map || jsonResponse['status'] != true) {
        throw Exception(
            (jsonResponse is Map ? jsonResponse['message'] : null) ??
                'Invalid API response');
      }

      final List<dynamic> list =
      (jsonResponse['data'] ?? []) as List<dynamic>;
      final parsed = <ClientModel>[];

      for (final raw in list) {
        if (raw is! Map) continue;

        // ── Social handles
        final handles = <String, String>{};
        final rawHandles = (raw['social_media_handel'] ?? '').toString();
        if (rawHandles.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawHandles);
            if (decoded is Map) {
              decoded.forEach((k, v) => handles[k.toString()] = v.toString());
            } else {
              handles['Mention / Details'] = rawHandles;
            }
          } catch (_) {
            handles['Mention / Details'] = rawHandles;
          }
        }

        // ── Logo — prefer resolved URL, fall back to base64
        Uint8List? logoBytes;
        String? logoUrl;

        final String logoPath =
        (raw['logo_path'] ?? '').toString().trim();
        final String logoRaw =
        (raw['logo_raw'] ?? '').toString().trim();

        final String candidate = logoPath.isNotEmpty ? logoPath : logoRaw;

        if (candidate.isNotEmpty) {
          if (candidate.startsWith('http://') ||
              candidate.startsWith('https://')) {
            logoUrl = candidate;
          } else if (candidate.startsWith('uploads/')) {
            final base = _apiBase.endsWith('/')
                ? _apiBase.substring(0, _apiBase.length - 1)
                : _apiBase;
            logoUrl = '$base/$candidate';
          } else if (candidate.startsWith('data:')) {
            try {
              final commaIdx = candidate.indexOf(',');
              if (commaIdx != -1) {
                logoBytes = base64Decode(candidate.substring(commaIdx + 1));
              }
            } catch (e) {
              debugPrint('Data URI logo decode failed: $e');
            }
          } else {
            try {
              logoBytes = base64Decode(candidate);
            } catch (e) {
              debugPrint('Raw base64 logo decode failed: $e');
            }
          }
        }

        // ── Logo color
        Color color = AppColors.purple;
        final rawColor = (raw['logo_color'] ?? '').toString().trim();
        if (rawColor.isNotEmpty) {
          try {
            final v = rawColor.replaceFirst('#', '');
            if (v.length == 6) {
              color = Color(int.parse('FF$v', radix: 16));
            } else if (v.length == 8) {
              color = Color(int.parse(v, radix: 16));
            }
          } catch (_) {}
        }

        parsed.add(ClientModel(
          companyName: (raw['company_name'] ?? '').toString(),
          logoColor: color,
          logoBytes: logoBytes,
          logoUrl: logoUrl, // ← server URL from uploads/
          address: (raw['address'] ?? '').toString(),
          website: (raw['website'] ?? '').toString(),
          mobile: (raw['mobile_number'] ?? '').toString(),
          email: (raw['email_id'] ?? '').toString(),
          socialHandles: handles,
          metaConnected: const {},
        ));
      }

      if (!mounted) return;
      setState(() {
        _clients
          ..clear()
          ..addAll(parsed);
        _isLoadingClients = false;
        if (_clients.isEmpty) {
          _seedDemoData();
        }
      });
    } catch (e) {
      debugPrint('API fetch failed, falling back to static data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingClients = false;
        _loadError = e.toString();
        _seedDemoData();
      });
    }
  }

  // ── SAVE CLIENT (POST API) ────────────────────────────────────────────────
  Future<bool> _saveClientToApi(ClientModel client) async {
    final url = Uri.parse('$_apiBase/register_company.php');

    // ── Build the logo payload.
    // Priority 1: freshly picked bytes → send as data URI so PHP
    //            knows the correct MIME (png/jpg/webp/etc).
    // Priority 2: existing server URL → keep as-is so we don't wipe it.
    String logoData = '';
    if (client.logoBytes != null && client.logoBytes!.isNotEmpty) {
      final b64 = base64Encode(client.logoBytes!);
      final mime = _guessImageMime(client.logoBytes!);
      logoData = 'data:$mime;base64,$b64';
    } else if (client.logoUrl != null && client.logoUrl!.trim().isNotEmpty) {
      logoData = client.logoUrl!;
    }

    final handlesJson = jsonEncode(client.socialHandles);
    final v = client.logoColor.value.toRadixString(16).padLeft(8, '0');
    final colorHex = '#${v.substring(2)}';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agency_name': widget.agencyName,
          'company_name': client.companyName,
          'logo_path': logoData,
          'logo_color': colorHex,
          'address': client.address,
          'website': client.website,
          'mobile_number': client.mobile,
          'email_id': client.email,
          'social_media_handel': handlesJson,
        }),
      );

      if (!mounted) return false;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == true) {
          _showSnack(
              body['message']?.toString() ?? 'Client saved successfully!',
              AppColors.green);
          return true;
        } else {
          _showSnack('Server: ${body['message'] ?? 'save failed'}',
              AppColors.amber);
          return false;
        }
      } else {
        _showSnack('Failed to save (HTTP ${response.statusCode})',
            AppColors.amber);
        return false;
      }
    } catch (e) {
      if (mounted) _showSnack('Network error: $e', AppColors.red);
      return false;
    }
  }

  /// Very small magic-number sniffer so we can send the right MIME
  /// prefix in the data URI. Falls back to image/png.
  String _guessImageMime(Uint8List bytes) {
    if (bytes.length >= 8) {
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      // GIF: 47 49 46 38
      if (bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x38) {
        return 'image/gif';
      }
    }
    if (bytes.length >= 12) {
      // WEBP: RIFF....WEBP
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
    }
    return 'image/png';
  }

  void _seedStaticPostsAndMedia() {
    final now = DateTime.now();
    if (_scheduledPosts.isEmpty) {
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
      ]);
    }
  }

  void _seedDemoData() {
    if (_clients.isNotEmpty) return;
    _clients.addAll([
      ClientModel(
        companyName: 'TechNova Solutions',
        logoColor: AppColors.purple,
        logoBytes: null,
        logoUrl: null,
        address: 'Bengaluru, India',
        website: 'technova.io',
        mobile: '+91 98765 43210',
        email: 'hello@technova.io',
        socialHandles: {
          'Facebook': '@technova',
          'Instagram': '@technova.io',
        },
        metaConnected: {'Facebook': true, 'Instagram': true},
      ),
      ClientModel(
        companyName: 'Bloom Cafe',
        logoColor: AppColors.pink,
        logoBytes: null,
        logoUrl: null,
        address: 'Mumbai, India',
        website: 'bloomcafe.in',
        mobile: '+91 91234 56789',
        email: 'hi@bloomcafe.in',
        socialHandles: {
          'Instagram': '@bloomcafe',
          'YouTube': '@bloomcafe',
        },
        metaConnected: {'Instagram': true},
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
                child: AnimatedBuilder(
                  animation: _bgAnimation,
                  builder: (context, _) => Container(
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
                      child: _buildSidebar(isMobile: false, isTablet: isTablet),
                    ),
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
  }

  // ── SIDEBAR ──────────────────────────────────────────────────────────────
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
                endIndent: 10),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const ClampingScrollPhysics(),
                itemCount: _menuItems.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemBuilder: (context, index) =>
                    _buildMenuItem(index, forceExpanded: true),
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
            colors: [Color(0xFF0A0E27), Color(0xFF1E1B4B), Color(0xFF311042)],
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
                    bottom: MediaQuery.of(context).viewPadding.bottom),
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
            builder: (context, _) => Container(
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
            ),
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
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, _) => Container(
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
                ),
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
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white70, size: 18),
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
    final isExpanded =
        item.isExpandable && (_expandedMenus[item.key] ?? false) && showExpanded;

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
                      ? LinearGradient(colors: [
                    item.color.withOpacity(0.25),
                    item.color.withOpacity(0.08),
                  ])
                      : null,
                  border: isSelected
                      ? Border.all(
                      color: item.color.withOpacity(0.4), width: 1)
                      : null,
                ),
                child: Row(
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
                            color:
                            isSubSelected ? item.color : Colors.white54,
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
          border: Border.all(
              color: AppColors.purple.withOpacity(0.2), width: 1),
        ),
        child: showExpanded
            ? Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.purple.withOpacity(0.3),
              child: Text(
                widget.agencyName.isNotEmpty
                    ? widget.agencyName[0].toUpperCase()
                    : 'AG',
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
                    widget.agencyName,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    widget.agencyEmail,
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
              widget.agencyName.isNotEmpty
                  ? widget.agencyName[0].toUpperCase()
                  : 'AG',
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

  // ── TOP BAR ──────────────────────────────────────────────────────────────
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
            const SizedBox(width: 8),
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
                      widget.agencyName,
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
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
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
              const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
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
                  gradient: LinearGradient(colors: [
                    AppColors.pink.withOpacity(0.22),
                    AppColors.purple.withOpacity(0.10),
                  ]),
                  border: Border.all(
                    color: AppColors.pink.withOpacity(0.45),
                    width: 1.4,
                  ),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.pink, size: 26),
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
                'You will be signed out of your agency workspace. Any unsaved changes will be lost.',
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
                          colors: [AppColors.pink, AppColors.purple],
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
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (ctx) => const LogIN()),
                        ),
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
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // ── MAIN CONTENT ROUTER ──────────────────────────────────────────────────
  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewSection();
      case 1:
        if (_activeSubSection == 'Add Client') return _buildAddClientForm();
        return _buildClientsList();
      case 2:
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

  // ── OVERVIEW SECTION ─────────────────────────────────────────────────────
  Widget _buildOverviewSection() {
    return _scrollWrapper(children: [
      _buildWelcomeBanner(),
      const SizedBox(height: 20),
      _buildStatsRow(),
      const SizedBox(height: 20),
      buildSectionTitle('Quick Actions'),
      const SizedBox(height: 12),
      Row(
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
            child: _actionTile('Open Client Dashboard',
                Icons.dashboard_customize_rounded, AppColors.cyan, () {
                  setState(() {
                    _selectedIndex = 1;
                    _activeSubSection = 'Client List';
                    _expandedMenus['clients'] = true;
                  });
                }),
          ),
        ],
      ),
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
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Text('Tap to open',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppColors.textDarkMuted)),
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
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Welcome back, ${widget.agencyName}! 👋',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                    'Manage your clients and social media publishing queue.',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('Clients', '${_clients.length}',
              Icons.people_alt_rounded, AppColors.purple),
          const SizedBox(width: 12),
          _buildStatCard('Scheduled', '${_scheduledPosts.length}',
              Icons.schedule_rounded, AppColors.cyan),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.textDarkMuted)),
              Text(value,
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  // ── CLIENT LIST SECTION ──────────────────────────────────────────────────
  Widget _buildClientsList() {
    return _scrollWrapper(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildSectionTitle('Client List (${_clients.length})'),
          TextButton.icon(
            onPressed: () => setState(() {
              _activeSubSection = 'Add Client';
              _expandedMenus['clients'] = true;
            }),
            icon: const Icon(Icons.add_rounded,
                size: 16, color: AppColors.purple),
            label: Text('Add Client',
                style: GoogleFonts.outfit(
                    color: AppColors.purple, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Tap a card to open its dashboard. Use "Show more" for details, or "Add Handles" to link social media.',
        style:
        GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textDarkMuted),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          TextButton.icon(
            onPressed: _isLoadingClients ? null : _fetchClientsFromApi,
            icon: Icon(Icons.refresh_rounded,
                size: 16,
                color: _isLoadingClients
                    ? AppColors.textDarkMuted
                    : AppColors.cyan),
            label: Text(
              _isLoadingClients ? 'Refreshing...' : 'Refresh',
              style: GoogleFonts.outfit(
                color: _isLoadingClients
                    ? AppColors.textDarkMuted
                    : AppColors.cyan,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_isLoadingClients && _clients.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_clients.isEmpty)
        buildEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No clients yet',
          subtitle: _loadError == null
              ? 'Register your first client to get started.'
              : 'Could not load clients. Tap Refresh to try again.',
        )
      else
        ..._clients.map((client) => _buildClientCard(client)),
      if (_loadError != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.amber.withOpacity(0.3)),
          ),
          child: Text(
            '⚠ $_loadError',
            style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.amber),
          ),
        ),
      ],
    ]);
  }

  Widget _buildClientCard(ClientModel client) {
    final key = client.companyName;
    final isExpanded = _expandedClients[key] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: client.logoColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: client.logoColor.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => _openClientDashboard(client),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: Radius.circular(isExpanded ? 0 : 16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildClientLogo(client, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.companyName.isNotEmpty
                                ? client.companyName
                                : 'Unnamed Client',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            client.email.isNotEmpty
                                ? client.email
                                : (client.mobile.isNotEmpty
                                ? client.mobile
                                : 'No contact provided'),
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textDarkMuted),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (client.address.isNotEmpty) ...[
                                Icon(Icons.location_on_outlined,
                                    size: 12, color: AppColors.textDarkMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    client.address,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppColors.textDarkMuted),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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
              ),
            ),
            // Bottom Chevron Toggle
            InkWell(
              onTap: () {
                setState(() {
                  _expandedClients[key] = !isExpanded;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: client.logoColor.withOpacity(0.04),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderLight,
                      width: isExpanded ? 0 : 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExpanded ? 'Show less' : 'Show more',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: client.logoColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: client.logoColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expanded details using safe CrossFade
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        Icons.phone_rounded,
                        'Mobile',
                        client.mobile.isNotEmpty ? client.mobile : 'N/A'),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        Icons.location_on_rounded,
                        'Address',
                        client.address.isNotEmpty ? client.address : 'N/A'),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        Icons.language_rounded,
                        'Website',
                        client.website.isNotEmpty ? client.website : 'N/A'),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        Icons.mail_outline_rounded,
                        'Email',
                        client.email.isNotEmpty ? client.email : 'N/A'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Social Handles (${client.socialHandles.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDarkSoft,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openAddHandlesSheet(client),
                          icon: const Icon(Icons.add_rounded,
                              size: 14, color: AppColors.purple),
                          label: Text(
                            client.socialHandles.isEmpty
                                ? 'Add Handles'
                                : 'Edit Handles',
                            style: GoogleFonts.outfit(
                              color: AppColors.purple,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (client.socialHandles.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          'No handles added yet. Tap "Add Handles" to link this client\'s social accounts.',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.textDarkMuted,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: client.socialHandles.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: client.logoColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: client.logoColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: client.logoColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientLogo(ClientModel client, {double size = 52}) {
    // 1) Prefer network URL (uploads/ file stored on server)
    if (client.logoUrl != null && client.logoUrl!.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: client.logoColor.withOpacity(0.4)),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(
            client.logoUrl!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(client.logoColor),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _initialLogo(client, size),
          ),
        ),
      );
    }

    // 2) Fallback: raw bytes (during pick, before upload finishes)
    if (client.logoBytes != null && client.logoBytes!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: client.logoColor.withOpacity(0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.memory(
            client.logoBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _initialLogo(client, size),
          ),
        ),
      );
    }

    // 3) Initial fallback
    return _initialLogo(client, size);
  }

  Widget _initialLogo(ClientModel client, double size) {
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textDarkMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDarkMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  // ── ADD HANDLES SHEET ────────────────────────────────────────────────────
  Future<void> _openAddHandlesSheet(ClientModel client) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddHandlesSheet(
        client: client,
        onSave: (updated) async {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          final ok = await _saveClientToApi(updated);
          if (ok && mounted) {
            await _fetchClientsFromApi();
          }
        },
      ),
    );

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  // ── OPEN CLIENT DASHBOARD ────────────────────────────────────────────────
  void _openClientDashboard(ClientModel client) {
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
            if (mounted) setState(() => _scheduledPosts.add(post));
          },
        ),
      ),
    );
  }

  // ── ADD CLIENT FORM ──────────────────────────────────────────────────────
  Widget _buildAddClientForm() {
    return AddClientForm(
      onSave: (client) async {
        final ok = await _saveClientToApi(client);
        if (!mounted) return;

        setState(() => _activeSubSection = 'Client List');

        if (ok) {
          await _fetchClientsFromApi();
        }

        if (!mounted || !ok) return;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          final addNow = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Company Registered!',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                'Do you want to add social media handles for "${client.companyName}" now?',
                style: GoogleFonts.outfit(fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('Later',
                      style: GoogleFonts.outfit(color: AppColors.textDark)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Add Handles',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );

          if (addNow == true && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openAddHandlesSheet(client);
            });
          }
        });
      },
      onCancel: () => setState(() => _activeSubSection = 'Client List'),
    );
  }

  // ── SOCIAL ACCOUNTS OVERVIEW ─────────────────────────────────────────────
  Widget _buildSocialAccountsOverview() {
    return _scrollWrapper(children: [
      buildSectionTitle('Social Accounts'),
      const SizedBox(height: 16),
      _socialOptionCard(
        title: 'All Platforms',
        subtitle: 'See every connected account.',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textDarkMuted)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPlatformsScreen() {
    final entries = <_ConnectedAccountEntry>[];
    for (final c in _clients) {
      for (final p in kSocialPlatforms) {
        final handle = c.socialHandles[p.name];
        if (handle != null && handle.isNotEmpty) {
          entries.add(_ConnectedAccountEntry(
            client: c,
            platform: p,
            handle: handle,
            metaConnected: c.metaConnected[p.name] ?? false,
          ));
        }
      }
    }

    if (entries.isEmpty) {
      return _scrollWrapper(children: [
        buildSectionTitle('All Platforms'),
        const SizedBox(height: 12),
        buildEmptyState(
          icon: Icons.link_off_rounded,
          title: 'No connected accounts yet',
          subtitle: 'Add handles for a client to see them here.',
        ),
      ]);
    }

    return _scrollWrapper(children: [
      buildSectionTitle('All Platforms (${entries.length})'),
      const SizedBox(height: 12),
      ...entries.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: e.platform.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: e.platform.color.withOpacity(0.15),
                border: Border.all(
                    color: e.platform.color.withOpacity(0.4)),
              ),
              child: Icon(e.platform.icon,
                  color: e.platform.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.client.companyName,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.platform.name} • ${e.handle}',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: e.platform.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    ]);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }
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

class _AddHandlesSheet extends StatefulWidget {
  final ClientModel client;
  final ValueChanged<ClientModel> onSave;

  const _AddHandlesSheet({required this.client, required this.onSave});

  @override
  State<_AddHandlesSheet> createState() => _AddHandlesSheetState();
}

class _AddHandlesSheetState extends State<_AddHandlesSheet> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final p in kSocialPlatforms) {
      final existing = widget.client.socialHandles[p.name] ?? '';
      _controllers[p.name] = TextEditingController(text: existing);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final handles = <String, String>{};
    for (final p in kSocialPlatforms) {
      final text = _controllers[p.name]!.text.trim();
      if (text.isNotEmpty) {
        handles[p.name] =
        text.startsWith(p.handlePrefix) ? text : '${p.handlePrefix}$text';
      }
    }

    widget.onSave(ClientModel(
      companyName: widget.client.companyName,
      logoColor: widget.client.logoColor,
      logoBytes: widget.client.logoBytes,
      logoUrl: widget.client.logoUrl, // preserved
      address: widget.client.address,
      website: widget.client.website,
      mobile: widget.client.mobile,
      email: widget.client.email,
      socialHandles: handles,
      metaConnected: widget.client.metaConnected,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.purple.withOpacity(0.12),
                      ),
                      child: const Icon(Icons.add_link_rounded,
                          color: AppColors.purple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Social Handles',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            widget.client.companyName,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Enter the handle for each platform. Leave blank to skip.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...kSocialPlatforms.map((p) {
                      final ctrl = _controllers[p.name]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: p.color.withOpacity(0.12),
                                border: Border.all(
                                    color: p.color.withOpacity(0.35)),
                              ),
                              child:
                              Icon(p.icon, color: p.color, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: ctrl,
                                style: GoogleFonts.outfit(
                                    color: AppColors.textDark),
                                decoration: InputDecoration(
                                  labelText: p.name,
                                  prefixText: '${p.handlePrefix} ',
                                  prefixStyle: GoogleFonts.outfit(
                                    color: p.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  labelStyle: GoogleFonts.outfit(
                                      color: AppColors.textDarkMuted),
                                  filled: true,
                                  fillColor: AppColors.scaffoldLight,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: AppColors.borderLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: p.color.withOpacity(0.6),
                                        width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white),
                      label: Text(
                        'Save Handles',
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}