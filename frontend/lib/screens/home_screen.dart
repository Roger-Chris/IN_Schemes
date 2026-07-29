import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../models/scheme_model.dart';
import '../services/scheme_repository.dart';
import 'scheme_details_screen.dart';
import 'notifications_screen.dart';
import '../widgets/voice_assistant_overlay.dart';
import 'find_my_schemes_screen.dart';
import 'companion/saarthi_welcome_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onVoiceQuery});

  final ValueChanged<String>? onVoiceQuery;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _carouselScrollController = ScrollController();
  final ScrollController _recommendedScrollController = ScrollController();
  int _activeCarouselIndex = 0;

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
    _carouselScrollController.addListener(() {
      if (_carouselScrollController.hasClients) {
        final index = (_carouselScrollController.offset / 300).round();
        if (index != _activeCarouselIndex) {
          setState(() {
            _activeCarouselIndex = index.clamp(0, 2);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _carouselScrollController.dispose();
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
          onClose: () => Navigator.of(overlayContext, rootNavigator: true).pop(),
          schemes: schemes,
          profile: provider.profile,
          onProfileConfirmed: provider.updateProfile,
          onSearch: (query) => SchemeRepository.instance.searchSchemeMatches(
            query,
            limit: 20,
          ),
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final recommended = provider.allSchemes.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 (Premium clean background)
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
                    
                    const SizedBox(height: 100), // Spacing for sticky floating Ask AI button
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Floating Action Ask AI widget
          Positioned(
            bottom: 24,
            right: 18,
            child: _buildAskAiFab(context),
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
                Text(
                  "👋",
                  style: GoogleFonts.inter(fontSize: 14),
                ),
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
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showLocationSelectionDialog(context, provider),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF475569),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${provider.profile.city.isNotEmpty ? provider.profile.city : 'Chennai'}, ${provider.profile.state}",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF475569),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                provider.updateTabIndex(4);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: provider.profile.profilePhoto.isNotEmpty &&
                          File(provider.profile.profilePhoto).existsSync()
                      ? FileImage(File(provider.profile.profilePhoto))
                      : const AssetImage('assets/images/user_avatar.png') as ImageProvider,
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLocationSelectionDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Select Location',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Chennai, Tamil Nadu'),
                onTap: () {
                  provider.updateProfile(provider.profile.copyWith(
                    city: 'Chennai',
                    state: 'Tamil Nadu',
                  ));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Coimbatore, Tamil Nadu'),
                onTap: () {
                  provider.updateProfile(provider.profile.copyWith(
                    city: 'Coimbatore',
                    state: 'Tamil Nadu',
                  ));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Madurai, Tamil Nadu'),
                onTap: () {
                  provider.updateProfile(provider.profile.copyWith(
                    city: 'Madurai',
                    state: 'Tamil Nadu',
                  ));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
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
          const Icon(
            Icons.search,
            color: Color(0xFF2563EB),
            size: 22,
          ),
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
          Container(
            height: 20,
            width: 1,
            color: const Color(0xFFE2E8F0),
          ),
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
                  const Icon(
                    Icons.search,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
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

  // Profile Completion Card (Real & Compact)
  Widget _buildProfileCompleteCard(BuildContext context, AppProvider provider) {
    final completion = provider.profileCompletionPercentage;
    final isComplete = completion == 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFDBEAFE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Progress ring with checkmark or percent text
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: completion / 100.0,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFFEFF6FF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                  ),
                ),
              ),
              if (isComplete)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 15,
                  ),
                )
              else
                Text(
                  "$completion%",
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          
          // Middle: Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      isComplete ? "Profile Complete!" : "Complete Your Profile",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isComplete ? const Color(0xFF0D9488) : const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isComplete ? "🎉" : "📋",
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  "$completion%",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isComplete
                      ? "Your profile is complete! You'll get the best scheme recommendations."
                      : "Add details to unlock personalized scheme recommendations.",
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          
          // Right: Dynamic Checklist Clipboard
          _buildClipboardGraphic(isComplete, completion),
        ],
      ),
    );
  }

  Widget _buildClipboardGraphic(bool isComplete, int completion) {
    final line1Checked = completion >= 30;
    final line2Checked = completion >= 60;
    final line3Checked = completion == 100;

    return SizedBox(
      width: 44,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 3,
            child: Container(
              width: 38,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isComplete ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(top: 10, left: 4, right: 4, bottom: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClipboardLine(checked: line1Checked),
                  _buildClipboardLine(checked: line2Checked),
                  _buildClipboardLine(checked: line3Checked),
                ],
              ),
            ),
          ),
          Positioned(
            top: 2,
            child: Container(
              width: 18,
              height: 9,
              decoration: BoxDecoration(
                color: isComplete ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isComplete)
                  Positioned(
                    bottom: -3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: 0.3,
                          child: Container(width: 4, height: 9, color: const Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 1),
                        Transform.rotate(
                          angle: -0.3,
                          child: Container(width: 4, height: 9, color: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isComplete ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isComplete ? Icons.check : Icons.more_horiz,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipboardLine({bool checked = true}) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check : Icons.circle_outlined,
          size: 7,
          color: checked ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }

  // Promo Slider Carousel (Simplified & Compact)
  Widget _buildCarouselSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 124,
          child: ListView(
            controller: _carouselScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCarouselCard(
                width: 290,
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                ),
                borderColor: const Color(0xFFFFD8A8),
                badgeText: "Alert",
                badgeTextColor: const Color(0xFFEA580C),
                badgeBgColor: const Color(0xFFFFEAD5),
                title: "PMEGP (Closing in 5 Days)",
                titleColor: const Color(0xFF1E293B),
                btnText: "View Details",
                btnColor: const Color(0xFFEA580C),
                onBtnTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
                rightGraphic: _buildCalendarGraphic(),
              ),
              _buildCarouselCard(
                width: 290,
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                ),
                borderColor: const Color(0xFFB9F6CA),
                badgeText: "New Scheme",
                badgeTextColor: const Color(0xFF16A34A),
                badgeBgColor: const Color(0xFFDCFCE7),
                title: "TN Export Promotion Scheme",
                titleColor: const Color(0xFF1E293B),
                btnText: "Explore",
                btnColor: const Color(0xFF16A34A),
                onBtnTap: () {
                  // Explore action
                },
                rightGraphic: _buildShipGraphic(),
              ),
              _buildCarouselCard(
                width: 290,
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                ),
                borderColor: const Color(0xFFDDD6FE),
                badgeText: "AI Recommended",
                badgeTextColor: const Color(0xFF7C3AED),
                badgeBgColor: const Color(0xFFEDE9FE),
                title: "12 Schemes Match Your Profile",
                titleColor: const Color(0xFF1E293B),
                btnText: "Explore",
                btnColor: const Color(0xFF7C3AED),
                onBtnTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SaarthiWelcomeScreen()),
                  );
                },
                rightGraphic: Image.asset(
                  'assets/images/compoanion bot.png',
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildDotIndicator(3, _activeCarouselIndex, const Color(0xFF2563EB)),
      ],
    );
  }

  Widget _buildCarouselCard({
    required double width,
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
      width: width,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
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
            padding: const EdgeInsets.only(top: 10, left: 4, right: 4, bottom: 3),
            child: GridView.count(
              crossAxisCount: 4,
              padding: EdgeInsets.zero,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(12, (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: index == 9 ? const Color(0xFFDC2626) : const Color(0xFFEFF6FF),
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
              child: const Icon(Icons.access_time_filled, size: 10, color: Colors.white),
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
      child: CustomPaint(
        painter: ShipPainter(),
      ),
    );
  }

  // Choose Your Journey (2x2 Grid)
  Widget _buildChooseYourJourney(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Choose Your Journey",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                provider.updateTabIndex(2);
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
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildJourneyCard(
                title: "Start Business",
                icon: Icons.rocket_launch,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  provider.updateSearchQuery("Startup");
                  provider.updateTabIndex(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildJourneyCard(
                title: "Existing Business",
                icon: Icons.storefront,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                onTap: () {
                  provider.updateSearchQuery("MSME");
                  provider.updateTabIndex(1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildJourneyCard(
                title: "Find Schemes",
                icon: Icons.search_sharp,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FindMySchemesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildJourneyCard(
                title: "Learn",
                icon: Icons.menu_book,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
                onTap: () {
                  provider.updateTabIndex(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJourneyCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // Recommended For You section (horizontal lists)
  Widget _buildRecommendedSection(BuildContext context, List<Scheme> schemes, AppProvider provider) {
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
          'isBookmarked': provider.bookmarkedIds.contains(s.id) || provider.bookmarkedIds.contains(s.schemeCode),
          'schemeCode': s.schemeCode,
          'chips': [
            if (s.sponsoringBody.isNotEmpty)
              ...s.sponsoringBody.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty),
            s.governmentLevel.isNotEmpty ? s.governmentLevel : 'Central',
            s.schemeType.isNotEmpty ? s.schemeType : 'Loan',
          ]
              .map((x) => x.trim())
              .where((x) => x.isNotEmpty && x.toLowerCase() != 'pending official verification')
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
                final outsideText = title.replaceAll(regex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
                final isBracketAcronym = bracketText.length <= 10 && 
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
                      MaterialPageRoute(builder: (_) => SchemeDetailsScreen(scheme: schemeObj)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
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
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (item['logoText'] ?? 'IN') as String,
                              style: GoogleFonts.poppins(
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                color: (item['logoColor'] ?? const Color(0xFF2563EB)) as Color,
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
                          final chipsList = List<String>.from(item['chips'] as List<String>)
                            ..sort((a, b) => a.length.compareTo(b.length));
                          return Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: chipsList.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          colors: [
            Color(0xFFFFFDF5),
            Color(0xFFFEF3C7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEF3C7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
          ),
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
                Positioned(
                  left: 2,
                  top: 15,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "₹",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                // Navigate to Updates list
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              color: const Color(0xFFEFF6FF), // Soft premium light blue background
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
            child: Image.asset(
              'assets/images/compoanion bot.png',
              fit: BoxFit.contain,
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
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.65, size.width * 0.5, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.75, size.width, size.height * 0.7)
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
    canvas.drawRect(Rect.fromLTWH(size.width * 0.6, size.height * 0.44, 10, 12), paint);

    paint.color = const Color(0xFFEF4444);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.25, size.height * 0.50, 10, 10), const Radius.circular(1)), paint);
    paint.color = const Color(0xFF10B981);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.36, size.height * 0.50, 10, 10), const Radius.circular(1)), paint);
    paint.color = const Color(0xFFF59E0B);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.47, size.height * 0.50, 10, 10), const Radius.circular(1)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
