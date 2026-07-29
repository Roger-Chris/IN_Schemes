import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../widgets/filter_panel.dart';
import 'companion/saarthi_welcome_screen.dart';
import '../widgets/smart_assessment_bottom_sheet.dart';
import 'discover_results_screen.dart';

class CategoryItem {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String schemeCount;

  const CategoryItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.schemeCount,
  });
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.onCategorySelected});

  final ValueChanged<String>? onCategorySelected;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';


  // Section keys for scrolling
  final GlobalKey _categorySectionKey = GlobalKey();
  final GlobalKey _ministrySectionKey = GlobalKey();
  final GlobalKey _stateSectionKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Full 23 categories for the "View All" bottom sheet
  static const List<CategoryItem> allCategoriesList = [
    CategoryItem(
      title: 'Agriculture',
      description: 'Crop loans, subsidies for fertilizers, machinery, and allied fields',
      icon: Icons.grass,
      iconColor: Color(0xFF2E7D32),
      backgroundColor: Color(0xFFE8F5E9),
      schemeCount: '128 Schemes',
    ),
    CategoryItem(
      title: 'Education',
      description: 'Financial aid, student loans, and research grants',
      icon: Icons.school,
      iconColor: Color(0xFF1565C0),
      backgroundColor: Color(0xFFE3F2FD),
      schemeCount: '156 Schemes',
    ),
    CategoryItem(
      title: 'Women & Child Welfare',
      description: 'Financial support, safety, self-employment, and skill development',
      icon: Icons.family_restroom,
      iconColor: Color(0xFFD81B60),
      backgroundColor: Color(0xFFFCE4EC),
      schemeCount: '142 Schemes',
    ),
    CategoryItem(
      title: 'Senior Citizens',
      description: 'Pension plans, healthcare, and savings schemes for seniors',
      icon: Icons.elderly,
      iconColor: Color(0xFFE65100),
      backgroundColor: Color(0xFFFFF3E0),
      schemeCount: '98 Schemes',
    ),
    CategoryItem(
      title: 'Healthcare',
      description: 'Insurance policies, medical aids, and hospital treatments',
      icon: Icons.favorite,
      iconColor: Color(0xFFD32F2F),
      backgroundColor: Color(0xFFFFEBEE),
      schemeCount: '132 Schemes',
    ),
    CategoryItem(
      title: 'Employment',
      description: 'Self-employment grants, work guarantees, and jobs training',
      icon: Icons.business_center,
      iconColor: Color(0xFF6A1B9A),
      backgroundColor: Color(0xFFF3E5F5),
      schemeCount: '110 Schemes',
    ),
    CategoryItem(
      title: 'Housing',
      description: 'Subsidies for building houses and urban/rural housing loans',
      icon: Icons.home,
      iconColor: Color(0xFFFBC02D),
      backgroundColor: Color(0xFFFFFDE7),
      schemeCount: '95 Schemes',
    ),
    CategoryItem(
      title: 'Business & MSME',
      description: 'Subsidies, loans, and setups for micro, small & medium businesses',
      icon: Icons.domain,
      iconColor: Color(0xFF00796B),
      backgroundColor: Color(0xFFE0F2F1),
      schemeCount: '123 Schemes',
    ),
    CategoryItem(
      title: 'Students',
      description: 'Specialized student entrepreneurship and incubation programs',
      icon: Icons.school_outlined,
      iconColor: Color(0xFF1976D2),
      backgroundColor: Color(0xFFE3F2FD),
      schemeCount: '85 Schemes',
    ),
    CategoryItem(
      title: 'Farmers',
      description: 'Direct income transfers, seed distributions, and equipment grants',
      icon: Icons.agriculture,
      iconColor: Color(0xFF4CAF50),
      backgroundColor: Color(0xFFE8F5E9),
      schemeCount: '143 Schemes',
    ),
    CategoryItem(
      title: 'Transport',
      description: 'Loans for commercial vehicles, transport subsidies, and licenses',
      icon: Icons.directions_bus,
      iconColor: Color(0xFFFF9800),
      backgroundColor: Color(0xFFFFF3E0),
      schemeCount: '76 Schemes',
    ),
    CategoryItem(
      title: 'Disability',
      description: 'Aids, monthly pensions, and special vocational training',
      icon: Icons.accessible,
      iconColor: Color(0xFF9C27B0),
      backgroundColor: Color(0xFFF3E5F5),
      schemeCount: '68 Schemes',
    ),
    CategoryItem(
      title: 'Pension',
      description: 'Social security pensions, old age, and widow pension schemes',
      icon: Icons.blind,
      iconColor: Color(0xFFFFB300),
      backgroundColor: Color(0xFFFFF8E1),
      schemeCount: '74 Schemes',
    ),
    CategoryItem(
      title: 'Finance',
      description: 'Collateral-free loans, interest subvention, and banking schemes',
      icon: Icons.account_balance,
      iconColor: Color(0xFF0D47A1),
      backgroundColor: Color(0xFFE0F2FE),
      schemeCount: '92 Schemes',
    ),
    CategoryItem(
      title: 'Marriage Assistance',
      description: 'Support grants for marriages of daughters from low-income groups',
      icon: Icons.favorite_border,
      iconColor: Color(0xFFEC407A),
      backgroundColor: Color(0xFFFCE4EC),
      schemeCount: '67 Schemes',
    ),
    CategoryItem(
      title: 'Insurance',
      description: 'Accident insurance, life covers, and health insurance plans',
      icon: Icons.shield,
      iconColor: Color(0xFF00897B),
      backgroundColor: Color(0xFFE0F2F1),
      schemeCount: '58 Schemes',
    ),
    CategoryItem(
      title: 'Startup',
      description: 'Seed funding, grants, incubation, and equity assistance programs',
      icon: Icons.rocket_launch,
      iconColor: Color(0xFF7B1FA2),
      backgroundColor: Color(0xFFF3E5F5),
      schemeCount: '64 Schemes',
    ),
    CategoryItem(
      title: 'Youth',
      description: 'Skill development programs and sports initiatives',
      icon: Icons.emoji_people,
      iconColor: Color(0xFF00ACC1),
      backgroundColor: Color(0xFFE0F7FA),
      schemeCount: '81 Schemes',
    ),
    CategoryItem(
      title: 'Minority Welfare',
      description: 'Subsidized loans and educational aids for minority groups',
      icon: Icons.location_city,
      iconColor: Color(0xFF8D6E63),
      backgroundColor: Color(0xFFEFEBE9),
      schemeCount: '63 Schemes',
    ),
    CategoryItem(
      title: 'Scholarships',
      description: 'Pre-matric, post-matric, and merit-cum-means scholarships',
      icon: Icons.menu_book,
      iconColor: Color(0xFF1E88E5),
      backgroundColor: Color(0xFFE3F2FD),
      schemeCount: '96 Schemes',
    ),
    CategoryItem(
      title: 'Skill Development',
      description: 'Free vocational training and skill certs for employment',
      icon: Icons.trending_up,
      iconColor: Color(0xFF43A047),
      backgroundColor: Color(0xFFE8F5E9),
      schemeCount: '88 Schemes',
    ),
    CategoryItem(
      title: 'Digital India',
      description: 'Digital training, internet vouchers, and tech startups assistance',
      icon: Icons.desktop_windows,
      iconColor: Color(0xFF1E88E5),
      backgroundColor: Color(0xFFE3F2FD),
      schemeCount: '77 Schemes',
    ),
    CategoryItem(
      title: 'Artisan',
      description: 'Support, toolkits distribution, and exhibitions for craftsmen',
      icon: Icons.brush,
      iconColor: Color(0xFF4E342E),
      backgroundColor: Color(0xFFD7CCC8),
      schemeCount: '54 Schemes',
    ),
  ];

  // core curated horizontal collections matching mockup
  final List<Map<String, dynamic>> _displayCategories = [
    {
      'title': 'Business & Entrepreneurship',
      'count': '312 Schemes',
      'icon': Icons.business_center,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Education & Skill Development',
      'count': '256 Schemes',
      'icon': Icons.school,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Loans & Credit Support',
      'count': '198 Schemes',
      'icon': Icons.monetization_on,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Housing & Infrastructure',
      'count': '142 Schemes',
      'icon': Icons.home,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Health & Wellness',
      'count': '98 Schemes',
      'icon': Icons.favorite,
      'color': const Color(0xFF2563EB),
    },
  ];

  final List<Map<String, dynamic>> _displayMinistries = [
    {
      'title': 'Ministry of MSME',
      'count': '186 Schemes',
    },
    {
      'title': 'Ministry of Education',
      'count': '158 Schemes',
    },
    {
      'title': 'Ministry of Finance',
      'count': '142 Schemes',
    },
    {
      'title': 'Ministry of Agriculture',
      'count': '118 Schemes',
    },
    {
      'title': 'Ministry of Rural Development',
      'count': '96 Schemes',
    },
  ];

  final List<Map<String, dynamic>> _displayStates = [
    {
      'title': 'Tamil Nadu',
      'count': '185 Schemes',
    },
    {
      'title': 'Maharashtra',
      'count': '212 Schemes',
    },
    {
      'title': 'Uttar Pradesh',
      'count': '198 Schemes',
    },
    {
      'title': 'Karnataka',
      'count': '154 Schemes',
    },
    {
      'title': 'Gujarat',
      'count': '126 Schemes',
    },
  ];

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterPanel(),
    );
  }



  void _onCategorySelected(String categoryName, AppProvider provider) {
    SmartAssessmentBottomSheet.show(context, categoryName, 'category', () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiscoverResultsScreen(title: categoryName, type: 'category'),
        ),
      );
    });
  }

  void _onMinistrySelected(String ministryName, AppProvider provider) {
    SmartAssessmentBottomSheet.show(context, ministryName, 'ministry', () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiscoverResultsScreen(title: ministryName, type: 'ministry'),
        ),
      );
    });
  }

  void _onStateSelected(String stateName, AppProvider provider) {
    SmartAssessmentBottomSheet.show(context, stateName, 'state', () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiscoverResultsScreen(title: stateName, type: 'state'),
        ),
      );
    });
  }

  void _openLifeStageSelector(AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final stages = [
          {'title': 'Student', 'desc': 'Scholarships, education loans, and skill dev', 'icon': Icons.school},
          {'title': 'Youth', 'desc': 'Self-employment schemes and incubation setups', 'icon': Icons.emoji_people},
          {'title': 'Senior Citizen', 'desc': 'Pension plans, insurance, savings schemes', 'icon': Icons.elderly},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Life Stage',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...stages.map((stage) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Icon(stage['icon'] as IconData, color: const Color(0xFF2563EB)),
                    ),
                    title: Text(stage['title'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Text(stage['desc'] as String, style: GoogleFonts.inter(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      provider.clearFilters();
                      if (stage['title'] == 'Student') {
                        provider.updateFilter('occupation', 'Student');
                      } else if (stage['title'] == 'Senior Citizen') {
                        provider.updateFilter('age', 'Senior Citizen');
                      }
                      _onCategorySelected(stage['title'] as String, provider);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses MainTabsContainer blue gradient background
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header (Discover, Search, AI avatar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Explore government schemes and opportunities',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          provider.updateTabIndex(1); // Go to Search Screen tab
                        },
                        icon: const Icon(Icons.search, color: Color(0xFF0F172A), size: 24),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SaarthiWelcomeScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/compoanion bot.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.android, color: AppConstants.primaryColor);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Search Bar with Integrated Filter Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      _onCategorySelected(query, provider);
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    hintText: 'Search schemes, benefits, departments...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: Container(
                      margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                      child: TextButton.icon(
                        onPressed: _openFilterPanel,
                        icon: const Icon(Icons.tune_outlined, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          "Filter",
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // Horizontal Circle Quick-Links row
                    _buildQuickLinksRow(provider),
                    const SizedBox(height: 16),

                    // Section 1: By Category
                    _buildSectionHeader(
                      key: _categorySectionKey,
                      title: 'By Category',
                      onViewAll: () => _showAllCategoriesBottomSheet(context, provider),
                    ),
                    _buildCategoryHorizontalList(provider),
                    const SizedBox(height: 16),

                    // Section 2: By Ministry
                    _buildSectionHeader(
                      key: _ministrySectionKey,
                      title: 'By Ministry',
                      onViewAll: () => _showAllMinistriesBottomSheet(context, provider),
                    ),
                    _buildMinistryHorizontalList(provider),
                    const SizedBox(height: 16),

                    // Section 3: By State
                    _buildSectionHeader(
                      key: _stateSectionKey,
                      title: 'By State',
                      onViewAll: () => _showAllStatesBottomSheet(context, provider),
                    ),
                    _buildStateHorizontalList(provider),
                    const SizedBox(height: 16),

                    // AI Companion Help Banner
                    _buildAICompanionBanner(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksRow(AppProvider provider) {
    final List<Map<String, dynamic>> items = [
      {'title': 'All Categories', 'icon': Icons.grid_view_rounded, 'action': () => _scrollToSection(_categorySectionKey)},
      {'title': 'All Ministries', 'icon': Icons.account_balance_rounded, 'action': () => _scrollToSection(_ministrySectionKey)},
      {'title': 'All States', 'icon': Icons.location_on_rounded, 'action': () => _scrollToSection(_stateSectionKey)},
      {'title': 'By Life Stage', 'icon': Icons.people_alt_rounded, 'action': () => _openLifeStageSelector(provider)},
      {'title': 'Popular', 'icon': Icons.star_rounded, 'action': () {
        _onCategorySelected('Popular Schemes', provider);
      }},
      {'title': 'Newly Added', 'icon': Icons.fiber_new_rounded, 'action': () {
        _onCategorySelected('Newly Added Schemes', provider);
      }},
    ];

    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: item['action'] as VoidCallback,
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
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

  Widget _buildSectionHeader({
    required GlobalKey key,
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          InkWell(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHorizontalList(AppProvider provider) {
    return SizedBox(
      height: 124,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: _displayCategories.length,
        itemBuilder: (context, index) {
          final item = _displayCategories[index];
          final String title = item['title'] as String;
          final String count = item['count'] as String;
          final IconData icon = item['icon'] as IconData;

          return Container(
            width: 128,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => _onCategorySelected(title, provider),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinistryHorizontalList(AppProvider provider) {
    return SizedBox(
      height: 124,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: _displayMinistries.length,
        itemBuilder: (context, index) {
          final item = _displayMinistries[index];
          final String title = item['title'] as String;
          final String count = item['count'] as String;

          return Container(
            width: 128,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => _onMinistrySelected(title, provider),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ministry emblem stylized circle
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2), width: 1),
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4), width: 1),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: Color(0xFF2563EB),
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getStateMapAsset(String stateName) {
    switch (stateName.toLowerCase()) {
      case 'tamil nadu':
        return 'assets/images/tamil_nadu.png';
      case 'maharashtra':
        return 'assets/images/maharashtra.png';
      case 'uttar pradesh':
        return 'assets/images/uttar_pradesh.png';
      case 'karnataka':
        return 'assets/images/karnataka.png';
      case 'gujarat':
        return 'assets/images/gujarat.png';
      default:
        return 'assets/images/tamil_nadu.png';
    }
  }

  Widget _buildStateHorizontalList(AppProvider provider) {
    return SizedBox(
      height: 124,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: _displayStates.length,
        itemBuilder: (context, index) {
          final item = _displayStates[index];
          final String title = item['title'] as String;
          final String count = item['count'] as String;

          return Container(
            width: 128,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => _onStateSelected(title, provider),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // State Map Image representation without background
                    Image.asset(
                      _getStateMapAsset(title),
                      width: 36,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return CustomPaint(
                          size: const Size(36, 32),
                          painter: StateMapPainter(title),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildAICompanionBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Not sure what to explore?",
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ask our AI Companion to find the right schemes for you.",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SaarthiWelcomeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF1E3A8A)),
                    label: Text(
                      'Ask AI',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Avatar
            Image.asset(
              'assets/images/compoanion bot.png',
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.android,
                size: 50,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllCategoriesBottomSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = allCategoriesList.where((cat) {
              return cat.title.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Categories',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setModalState(() {
                              _searchQuery = '';
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() {
                            _searchQuery = val;
                          });
                        },
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search categories...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        return _buildCategoryCard(context, category, provider);
                      },
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

  Widget _buildCategoryCard(BuildContext context, CategoryItem category, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Close sheet
            _onCategorySelected(category.title, provider);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: category.iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    category.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllMinistriesBottomSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final ministries = [
          'Ministry of MSME',
          'Ministry of Education',
          'Ministry of Finance',
          'Ministry of Agriculture',
          'Ministry of Rural Development',
          'Ministry of Skill Development',
          'Ministry of Social Justice',
          'Ministry of Housing',
          'Ministry of Health',
        ];

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Ministries',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: ministries.length,
                  itemBuilder: (context, index) {
                    final title = ministries[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 18),
                      ),
                      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _onMinistrySelected(title, provider);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllStatesBottomSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final states = [
          'Tamil Nadu',
          'Maharashtra',
          'Uttar Pradesh',
          'Karnataka',
          'Gujarat',
          'Kerala',
          'Delhi',
          'Andhra Pradesh',
          'Telangana',
          'Rajasthan',
          'Punjab',
          'Haryana',
        ];

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All States & UTs',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: states.length,
                  itemBuilder: (context, index) {
                    final title = states[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: CustomPaint(
                        size: const Size(36, 32),
                        painter: StateMapPainter(title),
                      ),
                      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _onStateSelected(title, provider);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StateMapPainter extends CustomPainter {
  final String stateName;
  StateMapPainter(this.stateName);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (stateName == 'Tamil Nadu') {
      path.moveTo(w * 0.2, h * 0.1);
      path.quadraticBezierTo(w * 0.6, h * 0.05, w * 0.85, h * 0.15);
      path.lineTo(w * 0.8, h * 0.55);
      path.quadraticBezierTo(w * 0.65, h * 0.85, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.35, h * 0.85, w * 0.25, h * 0.55);
      path.close();
    } else if (stateName == 'Maharashtra') {
      path.moveTo(w * 0.1, h * 0.4);
      path.lineTo(w * 0.3, h * 0.15);
      path.lineTo(w * 0.75, h * 0.2);
      path.lineTo(w * 0.9, h * 0.38);
      path.lineTo(w * 0.82, h * 0.78);
      path.lineTo(w * 0.48, h * 0.82);
      path.lineTo(w * 0.2, h * 0.65);
      path.close();
    } else if (stateName == 'Uttar Pradesh') {
      path.moveTo(w * 0.08, h * 0.35);
      path.lineTo(w * 0.35, h * 0.2);
      path.lineTo(w * 0.8, h * 0.25);
      path.lineTo(w * 0.92, h * 0.5);
      path.lineTo(w * 0.72, h * 0.78);
      path.lineTo(w * 0.52, h * 0.68);
      path.lineTo(w * 0.32, h * 0.78);
      path.lineTo(w * 0.18, h * 0.52);
      path.close();
    } else if (stateName == 'Karnataka') {
      path.moveTo(w * 0.35, h * 0.08);
      path.quadraticBezierTo(w * 0.75, h * 0.22, w * 0.6, h * 0.52);
      path.quadraticBezierTo(w * 0.8, h * 0.72, w * 0.65, h * 0.92);
      path.lineTo(w * 0.4, h * 0.88);
      path.quadraticBezierTo(w * 0.2, h * 0.58, w * 0.35, h * 0.32);
      path.close();
    } else if (stateName == 'Gujarat') {
      path.moveTo(w * 0.25, h * 0.22);
      path.lineTo(w * 0.52, h * 0.12);
      path.lineTo(w * 0.78, h * 0.22);
      path.lineTo(w * 0.82, h * 0.52);
      path.lineTo(w * 0.58, h * 0.82);
      path.lineTo(w * 0.42, h * 0.58);
      path.lineTo(w * 0.12, h * 0.48);
      path.lineTo(w * 0.22, h * 0.34);
      path.close();
    } else {
      // General map locator shape fallback
      path.moveTo(w * 0.5, h * 0.1);
      path.quadraticBezierTo(w * 0.8, h * 0.1, w * 0.8, h * 0.45);
      path.quadraticBezierTo(w * 0.8, h * 0.75, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.2, h * 0.75, w * 0.2, h * 0.45);
      path.quadraticBezierTo(w * 0.2, h * 0.1, w * 0.5, h * 0.1);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
