import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../services/scheme_repository.dart';
import '../../widgets/voice_assistant_overlay.dart';

import 'scheme_details_screen.dart';
import '../notifications_screen.dart';
import '../login_screen.dart';
import '../../widgets/smart_assessment_bottom_sheet.dart';
import 'discover_results_screen.dart';
import 'profile_setup_screen.dart';
import 'msme_module_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onVoiceQuery, this.onFilterPressed});

  final ValueChanged<String>? onVoiceQuery;
  final VoidCallback? onFilterPressed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselPageController = PageController(viewportFraction: 0.88);
  final ScrollController _recommendedScrollController = ScrollController();
  int _activeCarouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (!provider.isLoggedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      provider.fetchLatestProfile();
    });
  }

  void _startCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselPageController.hasClients) {
        final nextPage = (_activeCarouselIndex + 1) % itemCount;
        _carouselPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _initCarouselTimer(int itemCount) {
    if (_carouselTimer != null) return;
    _startCarouselTimer(itemCount);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselPageController.dispose();
    _recommendedScrollController.dispose();
    super.dispose();
  }

  Future<void> _openVoiceAssistant() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final schemes = provider.allSchemes.isNotEmpty
        ? provider.allSchemes
        : await SchemeRepository.instance.getAllSchemes();
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Voice assistant',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (overlayContext, animation, secondaryAnimation) {
        return VoiceAssistantOverlay(
          onClose: () =>
              Navigator.of(overlayContext, rootNavigator: true).pop(),
          schemes: schemes,
          profile: provider.profile,
          onProfileConfirmed: provider.updateProfile,
          onSearch: (query) =>
              SchemeRepository.instance.searchSchemeMatches(query, limit: 20),
          onSchemeSelected: (scheme) {
            Navigator.of(overlayContext, rootNavigator: true).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
          onSubmit: (query) {
            Navigator.of(overlayContext, rootNavigator: true).pop();
            widget.onVoiceQuery?.call(query);
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: Alignment.bottomRight,
            scale: Tween<double>(begin: 0.72, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.isLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final recommended = provider.allSchemes.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Slate 50 (Premium clean background)
      body: Stack(
        children: [
          // 1. Background image alignment (sky with building)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/Background/Home_screen_bg.webp',
                  width: MediaQuery.of(context).size.width,
                  height: 290,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                Container(
                  height: 290,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.65),
                        const Color(0xFFF8FAFC),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Unified Header
                    _buildHeader(context, provider),

                    const SizedBox(height: 10),

                    // Search Bar & Filter Button
                    _buildSearchAndFilter(context, provider),

                    const SizedBox(height: 10),

                    // Quick search horizontal pills
                    _buildQuickPills(context, provider),

                    if (provider.profileCompletionPercentage < 100) ...[
                      const SizedBox(height: 18),
                      // Profile Completion (Real & Compact)
                      _buildProfileCompleteCard(context, provider),
                    ],

                    const SizedBox(height: 20),

                    // Carousel Cards (Alerts, New Scheme, AI Recommendation)
                    _buildCarouselSection(context),

                    const SizedBox(height: 24),

                    // Choose Your Journey (2x2 Grid)
                    _buildChooseYourJourney(context, provider),

                    const SizedBox(height: 24),

                    // Explore MSME Support (2x4 Grid)
                    _buildExploreMSMESupport(context),

                    const SizedBox(height: 24),

                    // Recommended For You (Horizontal List)
                    _buildRecommendedSection(context, recommended, provider),

                    const SizedBox(height: 24),

                    // Latest Updates Card
                    _buildLatestUpdates(context, provider),

                    const SizedBox(height: 24),

                    // Tip of the Day
                    _buildTipOfTheDay(context),

                    const SizedBox(
                      height: 24,
                    ), // Clean spacing at the bottom of the page
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Action Ask AI widget
          Positioned(bottom: 30, right: 18, child: _buildAskAiFab(context)),
        ],
      ),
    );
  }

  // Unified Header Widget: Greeting on left, Notification/Avatar on right
  Widget _buildHeader(BuildContext context, AppProvider provider) {
    final displayName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ').first
        : 'User';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Good Morning,",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text("👋", style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: provider.isGuest ? 20.0 : 28.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (!provider.isGuest) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ],
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                    if (provider.notifications.any((n) => n['read'] == false))
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Search & Filter Box
  Widget _buildSearchAndFilter(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF2563EB), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                provider.updateTabIndex(1);
              },
              child: Text(
                "Search schemes, benefits or ask anything...",
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (widget.onFilterPressed != null) {
                widget.onFilterPressed!();
              } else {
                provider.updateTabIndex(1);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 14,
                    color: Color(0xFF1E293B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Filter",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Horizontal Pills
  Widget _buildQuickPills(BuildContext context, AppProvider provider) {
    final pills = [
      "Search PMEGP",
      "Search Startup India",
      "Search MSME Loans",
      "Search Women Entrepreneur Schemes",
      "Search ASCEND Workshops",
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pills.length,
        itemBuilder: (context, index) {
          final text = pills[index];
          return GestureDetector(
            onTap: () {
              final query = text.replaceAll("Search ", "");
              if (widget.onVoiceQuery != null) {
                widget.onVoiceQuery!(query);
              } else {
                provider.updateSearchQuery(query);
                provider.updateTabIndex(1);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Profile Completion Card (Mockup Style Redesign)
  Widget _buildProfileCompleteCard(BuildContext context, AppProvider provider) {
    final completion = provider.profileCompletionPercentage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/images/Background/profile process banner.png'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: Progress ring with percent text inside
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: completion / 100.0,
                      strokeWidth: 4.0,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFEFF6FF).withValues(alpha: 0.8),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  Text(
                    "$completion%",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Vertical Divider Line
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),

              // Middle: Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Complete Your Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Unlock personalized scheme recommendations.",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Spacer to prevent text from overlapping the background banner image's built-in graphic
              const SizedBox(width: 84),
            ],
          ),
        ),
      ),
    );
  }



  // Promo Slider Carousel (Snapping PageView with dynamic Supabase integration)
  Widget _buildCarouselSection(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final items = provider.carouselItems;

    // Initialize timer on build once items are fetched
    if (items.isNotEmpty) {
      _initCarouselTimer(items.length);
    }

    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _carouselPageController,
            onPageChanged: (index) {
              setState(() {
                _activeCarouselIndex = index;
              });
              // Restart timer to avoid sliding immediately after manual swipe
              _startCarouselTimer(items.length);
            },
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final gradientColors = [
                _parseHexColor(item['bg_gradient_start'] ?? '#FFF7ED'),
                _parseHexColor(item['bg_gradient_end'] ?? '#FFFFEDD5'),
              ];
              final String? bgImage = item['bg_image'] as String?;

              Widget rightGraphic = const SizedBox();
              if (item['graphic_type'] == 'calendar') {
                rightGraphic = _buildCalendarGraphic();
              } else if (item['graphic_type'] == 'ship') {
                rightGraphic = _buildShipGraphic();
              } else if (item['graphic_type'] == 'progress') {
                final double progress = (item['progress'] as num?)?.toDouble() ?? 0.0;
                rightGraphic = _buildProgressGraphic(progress);
              }

              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.88,
                  child: _buildCarouselCard(
                    bgGradient: LinearGradient(colors: gradientColors),
                    borderColor: _parseHexColor(item['badge_bg_color'] ?? '#E2E8F0'),
                    badgeText: item['badge_text'] ?? '',
                    badgeTextColor: _parseHexColor(item['badge_text_color'] ?? '#0F172A'),
                    badgeBgColor: _parseHexColor(item['badge_bg_color'] ?? '#F1F5F9'),
                    title: item['title'] ?? '',
                    subtitle: item['subtitle'] ?? '',
                    titleColor: const Color(0xFF1E293B),
                    onTap: () {
                      _handleCarouselTap(context, item);
                    },
                    rightGraphic: rightGraphic,
                    bgImage: bgImage,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildDotIndicator(items.length, _activeCarouselIndex, const Color(0xFF2563EB)),
      ],
    );
  }

  Color _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _handleCarouselTap(BuildContext context, Map<String, dynamic> item) {
    final route = item['target_route'] as String?;
    if (route == 'notifications') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    } else if (route == 'discover_results') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DiscoverResultsScreen(
            title: 'Business & MSME',
            type: 'category',
          ),
        ),
      );
    } else if (route == 'draft_session') {
      SmartAssessmentBottomSheet.show(
        context,
        'Business & MSME',
        'category',
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DiscoverResultsScreen(
                title: 'Business & MSME',
                type: 'category',
                isAssessmentCompleted: true,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildProgressGraphic(double progress) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: const Color(0xFFEFF6FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard({
    required Gradient bgGradient,
    required Color borderColor,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBgColor,
    required String title,
    String? subtitle,
    required Color titleColor,
    required VoidCallback onTap,
    required Widget rightGraphic,
    String? bgImage,
  }) {
    String displayTitle = title;
    String displaySubtitle = subtitle ?? '';
    if (displaySubtitle.isEmpty && title.contains(' — ')) {
      final parts = title.split(' — ');
      displayTitle = parts[0];
      displaySubtitle = parts[1];
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: bgImage != null ? null : bgGradient,
            image: bgImage != null
                ? DecorationImage(
                    image: AssetImage(bgImage),
                    fit: BoxFit.cover,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bgImage != null ? Colors.transparent : borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor.withValues(alpha: bgImage != null ? 0.85 : 1.0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                    if (displaySubtitle.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        displaySubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10.0,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (bgImage == null)
                rightGraphic
              else
                // Reserve spacer on the right so text doesn't overlap the background image's built-in icon
                const SizedBox(width: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGraphic() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            padding: const EdgeInsets.only(
              top: 10,
              left: 4,
              right: 4,
              bottom: 3,
            ),
            child: GridView.count(
              crossAxisCount: 4,
              padding: EdgeInsets.zero,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(12, (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: index == 9
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          Positioned(
            top: 2,
            left: 14,
            child: Row(
              children: [
                _buildCalendarRing(),
                const SizedBox(width: 10),
                _buildCalendarRing(),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.access_time_filled,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarRing() {
    return Container(
      width: 5,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFEA580C),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildShipGraphic() {
    return SizedBox(
      width: 60,
      height: 54,
      child: CustomPaint(painter: ShipPainter()),
    );
  }

  // Choose Your Journey (What would you like to do today?)
  Widget _buildChooseYourJourney(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What would you like to do today?",
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildJourneyActionCard(
                context: context,
                title: 'Export Support',
                icon: Icons.public_rounded,
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Grow Business',
                icon: Icons.trending_up_rounded,
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Register UDYAM',
                icon: Icons.app_registration_rounded,
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Find Funding',
                icon: Icons.currency_rupee_rounded,
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Start a Business',
                icon: Icons.rocket_launch_rounded,
                categoryName: 'Business & MSME',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String categoryName,
  }) {
    String formattedTitle = title;
    if (title == "Start a Business") {
      formattedTitle = "Start a\nBusiness";
    } else {
      formattedTitle = title.replaceFirst(' ', '\n');
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DiscoverResultsScreen(
              title: title,
              type: 'category',
              isAssessmentCompleted: false,
            ),
          ),
        );
      },
      child: Container(
        width: 86,
        height: 104,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 26,
            ),
            Text(
              formattedTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recommended For You section (horizontal lists)
  Widget _buildRecommendedSection(
    BuildContext context,
    List<Scheme> schemes,
    AppProvider provider,
  ) {
    final List<Map<String, dynamic>> items = [];

    if (schemes.isNotEmpty) {
      for (int i = 0; i < schemes.length; i++) {
        final s = schemes[i];
        final match = 95 - (i * 3);
        items.add({
          'id': s.id,
          'title': s.name,
          'subtitle': s.overview.isNotEmpty ? s.overview : s.objectives,
          'match': "$match% Match",
          'isBookmarked':
              provider.bookmarkedIds.contains(s.id) ||
              provider.bookmarkedIds.contains(s.schemeCode),
          'schemeCode': s.schemeCode,
          'chips':
              (s.id.toLowerCase() == 'in009' ||
                  s.schemeCode.toLowerCase() == 'in009')
              ? ['Central Scheme', 'Startup India', 'Capacity Building']
              : [
                      if (s.sponsoringBody.isNotEmpty)
                        ...s.sponsoringBody
                            .split(',')
                            .map((x) => x.trim())
                            .where((x) => x.isNotEmpty),
                      s.governmentLevel.isNotEmpty
                          ? s.governmentLevel
                          : 'Central',
                      s.schemeType.isNotEmpty ? s.schemeType : 'Loan',
                    ]
                    .map((x) => x.trim())
                    .where(
                      (x) =>
                          x.isNotEmpty &&
                          x.toLowerCase() != 'pending official verification',
                    )
                    .take(3)
                    .toList(),
          'location': s.state.isNotEmpty ? s.state : 'All India',
          'scheme': s,
        });
      }
    } else {
      items.addAll([
        {
          'id': 'pmegp_loan',
          'title': 'PMEGP Loan',
          'subtitle': "Prime Minister's Employment Generation Programme",
          'match': '95% Match',
          'isBookmarked': false,
          'schemeCode': 'PMEGP',
          'chips': ['Central Scheme', 'Loan', 'Subsidy'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'PMEGP',
          'logoColor': const Color(0xFF9A3412),
        },
        {
          'id': 'msme_loan',
          'title': 'MSME Loan',
          'subtitle': 'Credit Guarantee Fund Trust for MSEs',
          'match': '92% Match',
          'isBookmarked': true,
          'schemeCode': 'MSME',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'MSME',
          'logoColor': const Color(0xFF1E3A8A),
        },
        {
          'id': 'standup_india',
          'title': 'Stand Up India',
          'subtitle': 'Bank Loans for SC/ST & Women Entrepreneurs',
          'match': '88% Match',
          'isBookmarked': false,
          'schemeCode': 'SUI',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'UP India',
          'logoColor': const Color(0xFF15803D),
        },
        {
          'id': 'mudra_loan',
          'title': 'Mudra Loan',
          'subtitle': 'Loans up to ₹10 Lakhs Non-Corporate Business',
          'match': '85% Match',
          'isBookmarked': false,
          'schemeCode': 'Mudra',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'Mudra',
          'logoColor': const Color(0xFFB91C1C),
        },
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recommended For You",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                provider.updateTabIndex(1);
              },
              child: Row(
                children: [
                  Text(
                    "View All",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 215,
          child: ListView.builder(
            controller: _recommendedScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final Scheme? schemeObj = item['scheme'] as Scheme?;
              final isBookmarked = item['isBookmarked'] as bool;

              final double screenWidth = MediaQuery.of(context).size.width;
              final double spacing = 12.0;
              final double cardWidth = (screenWidth - 32 - spacing) / 1.08;

              final title = item['title'] as String;
              final regex = RegExp(r'\(([^)]+)\)');
              final matchObj = regex.firstMatch(title);
              String shortForm = title;
              String fullName = '';

              if (matchObj != null) {
                final bracketText = matchObj.group(1)!.trim();
                final outsideText = title
                    .replaceAll(regex, '')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();
                final isBracketAcronym =
                    bracketText.length <= 10 &&
                    !bracketText.contains(' ') &&
                    bracketText == bracketText.toUpperCase();
                if (isBracketAcronym) {
                  shortForm = bracketText;
                  fullName = outsideText;
                } else if (bracketText.length > outsideText.length) {
                  shortForm = outsideText;
                  fullName = bracketText;
                }
              }

              return GestureDetector(
                onTap: () {
                  if (schemeObj != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SchemeDetailsScreen(scheme: schemeObj),
                      ),
                    );
                  }
                },
                child: Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.015),
                        blurRadius: 6,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match & Bookmark Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['match'] as String,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF15803D),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final sCode = item['schemeCode'] as String;
                              provider.toggleBookmark(sCode);
                            },
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  shortForm,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (fullName.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    "($fullName)",
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Chips Row
                      Builder(
                        builder: (context) {
                          final chipsList = List<String>.from(
                            item['chips'] as List<String>,
                          )..sort((a, b) => a.length.compareTo(b.length));
                          return Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: chipsList.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tip of the Day Card (Yellow theme with custom tip banner bg)
  Widget _buildTipOfTheDay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/Background/tip banner.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFF59E0B),
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Tip of the Day",
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Women Entrepreneurs may receive additional subsidy under PMEGP.",
                  style: GoogleFonts.inter(
                    fontSize: 11.0,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Reserved right spacer to prevent text from overlapping the built-in image graphic
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  // Latest Updates Card
  Widget _buildLatestUpdates(BuildContext context, AppProvider provider) {
    final updates = provider.notifications;
    final latestUpdate = updates.isNotEmpty ? updates.first : null;

    final String tagText;
    if (latestUpdate != null) {
      final category = latestUpdate['category'] as String?;
      if (category == 'new_schemes') {
        tagText = 'New Scheme';
      } else if (category == 'updates') {
        tagText = 'Update';
      } else if (category == 'reminders') {
        tagText = 'Reminder';
      } else {
        tagText = 'Alert';
      }
    } else {
      tagText = 'New Scheme';
    }

    final String titleText = latestUpdate != null
        ? (latestUpdate['title'] as String? ?? '')
        : 'Fisheries and Aquaculture Infra Development Fund Scheme Launched';

    final String timeText = latestUpdate != null
        ? (latestUpdate['time'] as String? ?? '')
        : '2 days ago';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Latest Updates",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const NotificationsScreen(initialFilter: 'updates'),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    "View All",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 13,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tagText,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2563EB),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        titleText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeText,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int count, int activeIndex, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 12 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? color : const Color(0xFFE2E8F0),
          ),
        );
      }),
    );
  }

  // Sticky Floating Action Ask AI widget
  Widget _buildAskAiFab(BuildContext context) {
    return GestureDetector(
      onTap: _openVoiceAssistant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(
                0xFFEFF6FF,
              ), // Soft premium light blue background
              border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.asset(
                'assets/images/saarthi/sarathi.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Ask AI",
            style: GoogleFonts.inter(
              color: const Color(0xFF2563EB),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreMSMESupport(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Explore MSME Support",
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMSMESupportCard(
                context: context,
                id: 'schemes',
                title: 'Schemes',
                subtitle: 'Subsidies, grants & government schemes',
                icon: Icons.card_giftcard,
                iconColor: const Color(0xFF2E7D32),
                themeColor: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildMSMESupportCard(
                context: context,
                id: 'finance',
                title: 'Finance',
                subtitle: 'Loans, credit support & funding options',
                icon: Icons.savings,
                iconColor: const Color(0xFF1565C0),
                themeColor: Colors.blue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMSMESupportCard(
                context: context,
                id: 'tax_gst',
                title: 'Tax & GST',
                subtitle: 'Tax benefits, GST support & compliance',
                icon: Icons.percent,
                iconColor: const Color(0xFFEF6C00),
                themeColor: Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildMSMESupportCard(
                context: context,
                id: 'export',
                title: 'Export',
                subtitle: 'Export incentives, finance & market support',
                icon: Icons.language,
                iconColor: const Color(0xFF6A1B9A),
                themeColor: Colors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMSMESupportCard(
                context: context,
                id: 'treds',
                title: 'TReDS',
                subtitle: 'Invoice discounting & working capital solutions',
                icon: Icons.currency_exchange,
                iconColor: const Color(0xFFC62828),
                themeColor: Colors.red,
              ),
              const SizedBox(width: 12),
              _buildMSMESupportCard(
                context: context,
                id: 'csr',
                title: 'CSR Support',
                subtitle: 'CSR programs, incubators & cluster support',
                icon: Icons.handshake,
                iconColor: const Color(0xFF00695C),
                themeColor: Colors.teal,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMSMESupportCard(
                context: context,
                id: 'govt',
                title: 'Govt. Authorities',
                subtitle: 'Central, State & District government structure',
                icon: Icons.account_balance,
                iconColor: const Color(0xFF0277BD),
                themeColor: Colors.lightBlue,
              ),
              const SizedBox(width: 12),
              _buildMSMESupportCard(
                context: context,
                id: 'institutions',
                title: 'Institutions',
                subtitle: 'SIDBI, NSIC, DIC, KVIC & more organizations',
                icon: Icons.business,
                iconColor: const Color(0xFF4527A0),
                themeColor: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMSMESupportCard({
    required BuildContext context,
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color themeColor,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MSMEModuleDetailsScreen(
                    moduleId: id,
                    title: title,
                    description: subtitle,
                    icon: icon,
                    iconColor: iconColor,
                    themeColor: themeColor,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.0,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFEFF6FF);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 32, paint);

    paint.color = const Color(0xFF93C5FD);
    final waterPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.65,
        size.width * 0.5,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.75,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(waterPath, paint);

    paint.color = const Color(0xFF3B82F6);
    final hullPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.6)
      ..lineTo(size.width * 0.75, size.height * 0.6)
      ..lineTo(size.width * 0.68, size.height * 0.72)
      ..lineTo(size.width * 0.22, size.height * 0.72)
      ..close();
    canvas.drawPath(hullPath, paint);

    paint.color = const Color(0xFF1E3A8A);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.44, 10, 12),
      paint,
    );

    paint.color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.50, 10, 10),
        const Radius.circular(1),
      ),
      paint,
    );
    paint.color = const Color(0xFF10B981);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.36, size.height * 0.50, 10, 10),
        const Radius.circular(1),
      ),
      paint,
    );
    paint.color = const Color(0xFFF59E0B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.47, size.height * 0.50, 10, 10),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
