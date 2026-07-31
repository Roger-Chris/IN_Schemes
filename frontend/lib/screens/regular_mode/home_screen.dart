import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';

import 'scheme_details_screen.dart';
import '../notifications_screen.dart';
import '../login_screen.dart';
import '../../widgets/smart_assessment_bottom_sheet.dart';
import 'discover_results_screen.dart';
import 'profile_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onVoiceQuery});

  final ValueChanged<String>? onVoiceQuery;

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
                  'assets/images/Home_screen_bg.webp',
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
                    const SizedBox(height: 12),

                    // Unified Header
                    _buildHeader(context, provider),

                    const SizedBox(height: 16),

                    // Search Bar & Filter Button
                    _buildSearchAndFilter(context, provider),

                    const SizedBox(height: 14),

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
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              provider.updateTabIndex(1);
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
    final isComplete = completion == 100;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
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
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      value: completion / 100.0,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFEFF6FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  Text(
                    "$completion%",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Vertical Divider Line
              Container(
                width: 1,
                height: 44,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 16),

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
                    const SizedBox(height: 4),
                    Text(
                      "Help personalize scheme recommendations that match your business needs.",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right: Clipboard Graphic
              _buildClipboardGraphic(isComplete, completion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClipboardGraphic(bool isComplete, int completion) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background light circular overlay
          Positioned(
            left: 2,
            top: 10,
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Sparkle top-left
          const Positioned(
            left: 0,
            top: 2,
            child: Icon(
              Icons.star,
              color: Color(0xFF93C5FD),
              size: 10,
            ),
          ),
          // Sparkle top-right
          const Positioned(
            right: 0,
            top: 12,
            child: Icon(
              Icons.star,
              color: Color(0xFF93C5FD),
              size: 8,
            ),
          ),
          // Clipboard body
          Positioned(
            top: 10,
            child: Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(top: 12, left: 6, right: 6, bottom: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Person icon
                  const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF3B82F6),
                    size: 14,
                  ),
                  // Mock lines
                  Container(
                    width: 24,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFDBFE),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFDBFE),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Symmetrical clip top
          Positioned(
            top: 6,
            child: Container(
              width: 18,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Blue shield with check badge bottom-right
          Positioned(
            right: 2,
            bottom: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 11,
                ),
              ],
            ),
          ),
        ],
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
          height: 124,
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
                    titleColor: const Color(0xFF1E293B),
                    btnText: item['btn_text'] ?? 'View Details',
                    btnColor: _parseHexColor(item['btn_color'] ?? '#2563EB'),
                    onBtnTap: () {
                      _handleCarouselTap(context, item);
                    },
                    rightGraphic: rightGraphic,
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
    required Color titleColor,
    required String btnText,
    required Color btnColor,
    required VoidCallback onBtnTap,
    required Widget rightGraphic,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
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
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                GestureDetector(
                  onTap: onBtnTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        btnText,
                        style: GoogleFonts.inter(
                          color: btnColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward, size: 11, color: btnColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          rightGraphic,
        ],
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
                iconColor: const Color(0xFF0D9488),
                bgColor: const Color(0xFFF0FDFA),
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Grow Business',
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Register UDYAM',
                icon: Icons.app_registration_rounded,
                iconColor: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFF7ED),
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Find Funding',
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: 'Start a Business',
                icon: Icons.rocket_launch_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
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
    required Color iconColor,
    required Color bgColor,
    required String categoryName,
  }) {
    return GestureDetector(
      onTap: () {
        SmartAssessmentBottomSheet.show(
          context,
          categoryName,
          'category',
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiscoverResultsScreen(
                  title: categoryName,
                  type: 'category',
                ),
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
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
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (item['logoText'] ?? 'IN') as String,
                              style: GoogleFonts.poppins(
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                color:
                                    (item['logoColor'] ??
                                            const Color(0xFF2563EB))
                                        as Color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  maxLines: 1,
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
                                    maxLines: 1,
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

  // Tip of the Day Card (Yellow theme)
  Widget _buildTipOfTheDay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDF5), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEF3C7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Tip of the Day",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
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
                    fontSize: 11.5,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // Tip details
                  },
                  child: Text(
                    "Know More ->",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: -10,
                  right: -5,
                  child: Image.asset(
                    'assets/images/support_agent.png',
                    height: 95,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Latest Updates Card
  Widget _buildLatestUpdates(BuildContext context, AppProvider provider) {
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
        Container(
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
                        "New Scheme",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Fisheries and Aquaculture Infra Development Fund Scheme Launched",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "2 days ago",
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
