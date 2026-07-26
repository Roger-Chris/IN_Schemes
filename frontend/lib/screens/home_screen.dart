import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../models/scheme_model.dart';
import 'scheme_details_screen.dart';
import 'profile_setup_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAiMode = true;
  final ScrollController _highlightScrollController = ScrollController();
  final ScrollController _recommendedScrollController = ScrollController();
  final ScrollController _newsScrollController = ScrollController();

  int _activeHighlightIndex = 0;
  int _activeRecommendedIndex = 0;
  int _activeNewsIndex = 0;

  @override
  void initState() {
    super.initState();

    _highlightScrollController.addListener(() {
      if (_highlightScrollController.hasClients) {
        final index = (_highlightScrollController.offset / 280).round();
        if (index != _activeHighlightIndex) {
          setState(() {
            _activeHighlightIndex = index.clamp(0, 1);
          });
        }
      }
    });

    _recommendedScrollController.addListener(() {
      if (_recommendedScrollController.hasClients) {
        final index = (_recommendedScrollController.offset / 220).round();
        if (index != _activeRecommendedIndex) {
          setState(() {
            _activeRecommendedIndex = index.clamp(0, 2);
          });
        }
      }
    });

    _newsScrollController.addListener(() {
      if (_newsScrollController.hasClients) {
        final index = (_newsScrollController.offset / 260).round();
        if (index != _activeNewsIndex) {
          setState(() {
            _activeNewsIndex = index.clamp(0, 2);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _highlightScrollController.dispose();
    _recommendedScrollController.dispose();
    _newsScrollController.dispose();
    super.dispose();
  }

  /// Returns icon + background colors based on scheme category keyword.
  Map<String, Color> _schemeColors(String category) {
    final c = category.toLowerCase();
    if (c.contains('agriculture') || c.contains('farmer')) {
      return {'icon': const Color(0xFF047857), 'bg': const Color(0xFFECFDF5)};
    } else if (c.contains('education') || c.contains('student')) {
      return {'icon': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD)};
    } else if (c.contains('women')) {
      return {'icon': const Color(0xFFD81B60), 'bg': const Color(0xFFFCE4EC)};
    } else if (c.contains('startup') || c.contains('innovation')) {
      return {'icon': const Color(0xFF6D28D9), 'bg': const Color(0xFFF5F3FF)};
    } else if (c.contains('msme') || c.contains('business')) {
      return {'icon': const Color(0xFF1D4ED8), 'bg': const Color(0xFFEFF6FF)};
    } else if (c.contains('health')) {
      return {'icon': const Color(0xFFE65100), 'bg': const Color(0xFFFFF3E0)};
    } else {
      return {'icon': const Color(0xFF047857), 'bg': const Color(0xFFECFDF5)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final recommended = provider.allSchemes.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Layer (Clean Light Blue to White Gradient)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE0F2FE), // Clean Light Blue (Sky 100)
                    Color(0xFFEFF6FF), // Soft light blue (Blue 50)
                    Colors.white,      // White
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.40, 0.75],
                ),
              ),
            ),
          ),
          // Foreground Layer
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Custom App Bar
                  _buildCustomAppBar(context),

                  // 2. Greeting Section
                  _buildGreetingSection(),

                  // 3. Search Bar
                  _buildSearchBar(context, provider),

                  // 4. Quick AI Prompts
                  _buildQuickAiPrompts(),

                  const SizedBox(height: 16),

                  // 5. Highlight Dashboard Cards
                  _buildHighlightDashboardCards(context, provider),

                  const SizedBox(height: 20),

                  // 6. Choose Your Journey (Enhanced & Standardized Styling)
                  _buildChooseYourJourney(),

                  const SizedBox(height: 24),

                  // 7. Recommended for You
                  _buildRecommendedSection(context, recommended, provider),

                  const SizedBox(height: 24),

                  // 9. Government News
                  _buildGovernmentNewsSection(context, provider),

                  const SizedBox(height: 24),

                  // 8. Tip of the Day Banner
                  _buildTipOfTheDayBanner(),
                  const SizedBox(height: 100), // Bottom padding to prevent FAB overlap
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCustomFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 1. Custom App Bar
  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0F172A), size: 28),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/images/Logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'iN Schemes',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              // AI toggle switch
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAiMode = !_isAiMode;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 54,
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _isAiMode ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    color: _isAiMode ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 4,
                        child: Text(
                          'AI',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _isAiMode ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _isAiMode ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAiMode ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/user_avatar.png'),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Greeting Section
  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Good Afternoon,",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A), // Dark Blue
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Roger Christopher!',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), // Dark Blue
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF475569), size: 14), // Slate 600
              const SizedBox(width: 4),
              Text(
                "Personalized just for you",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF475569), // Slate 600
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Search Bar
  Widget _buildSearchBar(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          readOnly: true,
          onTap: () {
            provider.updateTabIndex(2);
          },
          decoration: InputDecoration(
            hintText: "Search PMEGP...",
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 15,
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 22),
            suffixIcon: const Icon(Icons.mic, color: Color(0xFF64748B), size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAiPrompts() {
    final prompts = [
      {"icon": Icons.search, "theme": "purple", "text": "Search PMEGP..."},
      {"icon": Icons.trending_up, "theme": "blue", "text": "Search Startup India..."},
      {"icon": Icons.currency_rupee, "theme": "green", "text": "Search MSME loans..."},
      {"icon": Icons.business_center_outlined, "theme": "purple", "text": "Search by business type..."},
      {"icon": Icons.person_outline, "theme": "blue", "text": "Ask for women entrepreneur schemes..."},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          final item = prompts[index];
          Color iconColor;
          switch (item["theme"]) {
            case "green":
              iconColor = const Color(0xFF047857);
              break;
            case "purple":
              iconColor = const Color(0xFF6D28D9);
              break;
            case "blue":
            default:
              iconColor = const Color(0xFF1D4ED8);
              break;
          }

          return InteractiveCard(
            width: 110,
            height: 98,
            margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  item["icon"] as IconData,
                  color: iconColor,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    item["text"] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                      height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
  }

  // 5. Highlight Dashboard Cards
  Widget _buildHighlightDashboardCards(BuildContext context, AppProvider provider) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: ListView(
            controller: _highlightScrollController,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Card 1: Profile Progress
              InteractiveCard(
                width: 290,
                height: 148,
                margin: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFFEFF6FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSetupScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          width: 78,
                          height: 78,
                          child: CircularProgressIndicator(
                            value: 0.75,
                            strokeWidth: 8,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "75%",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                            Text(
                              "Complete",
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Complete Your Profile",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Complete your Business Profile to unlock personalized scheme recommendations.",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: const LinearProgressIndicator(
                              value: 0.75,
                              minHeight: 4,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Continue",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1D4ED8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 10, color: Color(0xFF1D4ED8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card 2: Important Alert
              InteractiveCard(
                width: 290,
                height: 148,
                margin: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFFFFFBEB),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "New",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFEF3C7),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.notifications, color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Important Alert",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "PMEGP scheme deadline extended to 31st May 2025.",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "View Details",
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFD97706),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 10, color: Color(0xFFD97706)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildDotIndicator(2, _activeHighlightIndex, const Color(0xFF2563EB)),
      ],
    );
  }

  // 6. Choose Your Journey (Enhanced Styling & Uniform Sizing)
  Widget _buildChooseYourJourney() {
    final journeys = [
      {"icon": Icons.rocket_launch, "color": const Color(0xFF6D28D9), "bg": const Color(0xFFF5F3FF), "title": "Start a Business"},
      {"icon": Icons.storefront, "color": const Color(0xFF047857), "bg": const Color(0xFFECFDF5), "title": "Existing Business"},
      {"icon": Icons.search, "color": const Color(0xFF1D4ED8), "bg": const Color(0xFFEFF6FF), "title": "Find Schemes"},
      {"icon": Icons.book, "color": const Color(0xFFD97706), "bg": const Color(0xFFFEF3C7), "title": "Learn"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose Your Journey",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: journeys.map((item) {
              return Expanded(
                child: Container(
                  height: 120, // Strict uniform dimensions
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vertically centered inner content
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item["bg"] as Color,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          item["icon"] as IconData,
                          color: item["color"] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item["title"] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 7. Recommended for You
  Widget _buildRecommendedSection(BuildContext context, List<Scheme> schemes, AppProvider provider) {
    // Build display list from live schemes (fall back to placeholder on empty)
    final List<Map<String, dynamic>> list = schemes.isNotEmpty
        ? schemes.map((s) {
            final colors = _schemeColors(s.category);
            final tags = [
              if (s.governmentLevel.isNotEmpty) s.governmentLevel,
              if (s.schemeType.isNotEmpty) s.schemeType,
              if (s.sector.isNotEmpty) s.sector,
            ].take(3).toList();
            return {
              'title': s.name,
              'subtitle': s.overview.isNotEmpty ? s.overview : s.objectives,
              'icon': Icons.account_balance,
              'iconColor': colors['icon']!,
              'iconBg': colors['bg']!,
              'status': s.governmentLevel == 'State' ? 'State' : 'Central',
              'statusColor': colors['icon']!,
              'statusBg': colors['bg']!,
              'chips': tags,
              'chipBg': colors['bg']!,
              'chipText': colors['icon']!,
              'scheme': s,
            };
          }).toList()
        : [
            {
              'title': 'PM Mudra Yojana',
              'subtitle': 'Collateral free loans up to ₹10 lakh for micro and small enterprises.',
              'icon': Icons.account_balance,
              'iconColor': const Color(0xFF047857),
              'iconBg': const Color(0xFFECFDF5),
              'status': 'New',
              'statusColor': const Color(0xFF047857),
              'statusBg': const Color(0xFFECFDF5),
              'chips': ['Loan', 'MSME', 'Central'],
              'chipBg': const Color(0xFFECFDF5),
              'chipText': const Color(0xFF047857),
              'scheme': null,
            },
            {
              'title': 'Stand Up India Scheme',
              'subtitle': 'Loans between ₹10 lakh – ₹1 crore for SC/ST & women entrepreneurs.',
              'icon': Icons.favorite,
              'iconColor': const Color(0xFF1D4ED8),
              'iconBg': const Color(0xFFEFF6FF),
              'status': 'Trending',
              'statusColor': const Color(0xFF1D4ED8),
              'statusBg': const Color(0xFFEFF6FF),
              'chips': ['Startup', 'Credit', 'Central'],
              'chipBg': const Color(0xFFEFF6FF),
              'chipText': const Color(0xFF1D4ED8),
              'scheme': null,
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recommended for You",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
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
                        color: const Color(0xFF2563EB),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 12, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.builder(
            controller: _recommendedScrollController,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final Scheme? schemeObj = item['scheme'] as Scheme?;
              return InteractiveCard(
                width: 220,
                height: 183,
                margin: const EdgeInsets.only(right: 16, bottom: 6, top: 4),
                padding: const EdgeInsets.all(12),
                onTap: () {
                  if (schemeObj != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SchemeDetailsScreen(scheme: schemeObj),
                    ));
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item["iconBg"] as Color,
                          ),
                          alignment: Alignment.center,
                          child: Icon(item["icon"] as IconData, color: item["iconColor"] as Color, size: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item["statusBg"] as Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item["status"] as String,
                            style: GoogleFonts.inter(
                              color: item["statusColor"] as Color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item["title"] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item["subtitle"] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: (item["chips"] as List<String>).map((chip) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item["chipBg"] as Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            chip,
                            style: GoogleFonts.inter(
                              color: item["chipText"] as Color,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildDotIndicator(list.length, _activeRecommendedIndex, const Color(0xFF2563EB)),
      ],
    );
  }

  // 9. Government News Section
  Widget _buildGovernmentNewsSection(BuildContext context, AppProvider provider) {
    final newsList = [
      {
        "title": "National Seed Grant Portal Launched",
        "description": "Prime Minister rolls out a new digital seed grant initiative targeted at young startups and researchers.",
        "tag": "Startups",
        "tagBg": const Color(0xFFEFF6FF),
        "tagText": const Color(0xFF1D4ED8),
        "time": "2 hours ago",
      },
      {
        "title": "MSME department increases NEEDS subsidy ceiling",
        "description": "NEEDS scheme subsidy maximum limit increased to ₹75 Lakhs for aspiring women and minority business owners.",
        "tag": "Subsidy",
        "tagBg": const Color(0xFFECFDF5),
        "tagText": const Color(0xFF047857),
        "time": "1 day ago",
      },
      {
        "title": "Mudra Shishu Loan threshold raised to ₹1 Lakh",
        "description": "Government expands limit for collateral-free micro credit access to promote rural retail growth.",
        "tag": "Mudra Loan",
        "tagBg": const Color(0xFFF5F3FF),
        "tagText": const Color(0xFF6D28D9),
        "time": "3 days ago",
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Government News",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            controller: _newsScrollController,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return InteractiveCard(
                width: 260,
                height: 138,
                margin: const EdgeInsets.only(right: 16, bottom: 6, top: 4),
                padding: const EdgeInsets.all(16),
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: news["tagBg"] as Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            news["tag"] as String,
                            style: GoogleFonts.inter(
                              color: news["tagText"] as Color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          news["time"] as String,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      news["title"] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        news["description"] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildDotIndicator(newsList.length, _activeNewsIndex, const Color(0xFF2563EB)),
      ],
    );
  }

  // 8. Tip of the Day Banner
  Widget _buildTipOfTheDayBanner() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        border: Border.all(color: const Color(0xFF6D28D9).withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6D28D9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Tip of the Day ✨",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Women entrepreneurs can avail additional benefits under several government schemes.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                _buildBulletPoint("Special funding & subsidies available"),
                const SizedBox(height: 4),
                _buildBulletPoint("Priority in many Central & State schemes"),
                const SizedBox(height: 4),
                _buildBulletPoint("Lower interest loans for women-led businesses"),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 70,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Container(
                      width: 64,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        border: Border.all(color: const Color(0xFF047857), width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 22,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        border: Border.all(color: const Color(0xFF1D4ED8), width: 1.5),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 44,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFF047857),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 8,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF047857),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 8,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFF047857),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: Icon(Icons.check_circle_outline, color: Color(0xFF6D28D9), size: 12),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
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

  Widget _buildCustomFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 28,
              ),
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
    );
  }
}

// 3. Tactile Interactive Card with Highlight State Border Feedback
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const InteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
    this.backgroundColor = Colors.white,
    this.boxShadow,
    required this.height,
    this.width,
    this.margin,
    this.padding,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHighlighted = true),
      onTapCancel: () => setState(() => _isHighlighted = false),
      onTapUp: (_) {
        setState(() => _isHighlighted = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isHighlighted ? const Color(0xFF1D4ED8) : const Color(0xFFBAE6FD),
            width: _isHighlighted ? 2.0 : 1.5,
          ),
          boxShadow: widget.boxShadow,
        ),
        child: widget.child,
      ),
    );
  }
}
