import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';

import '../../widgets/filter_panel.dart';

import '../../widgets/smart_assessment_bottom_sheet.dart';
import 'discover_results_screen.dart';
import 'search_results_screen.dart';

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
      title: 'Business & MSME',
      description:
          'Subsidized loans, credit guarantees, and setup support for micro, small & medium businesses',
      icon: Icons.domain,
      iconColor: Color(0xFF00796B),
      backgroundColor: Color(0xFFE0F2F1),
      schemeCount: '123 Schemes',
    ),
    CategoryItem(
      title: 'Startup',
      description:
          'Seed funding, grants, incubation, and equity assistance programs',
      icon: Icons.rocket_launch,
      iconColor: Color(0xFF7B1FA2),
      backgroundColor: Color(0xFFF3E5F5),
      schemeCount: '64 Schemes',
    ),
    CategoryItem(
      title: 'Finance',
      description:
          'Collateral-free loans, interest subvention, and banking schemes',
      icon: Icons.account_balance,
      iconColor: Color(0xFF2563EB),
      backgroundColor: Color(0xFFE0F2FE),
      schemeCount: '92 Schemes',
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
      title: 'Artisan',
      description:
          'Support, toolkits distribution, and exhibitions for craftsmen',
      icon: Icons.brush,
      iconColor: Color(0xFF4E342E),
      backgroundColor: Color(0xFFD7CCC8),
      schemeCount: '54 Schemes',
    ),
    CategoryItem(
      title: 'Digital India',
      description:
          'Digital training, internet vouchers, and tech startups assistance',
      icon: Icons.desktop_windows,
      iconColor: Color(0xFF1E88E5),
      backgroundColor: Color(0xFFE3F2FD),
      schemeCount: '77 Schemes',
    ),
    CategoryItem(
      title: 'Women Entrepreneurs',
      description:
          'Specialized finance, capital subsidies, and resources for women-owned businesses',
      icon: Icons.person,
      iconColor: Color(0xFFD81B60),
      backgroundColor: Color(0xFFFCE4EC),
      schemeCount: '142 Schemes',
    ),
    CategoryItem(
      title: 'Student Startups',
      description:
          'Specialized student entrepreneurship and incubation programs',
      icon: Icons.school_outlined,
      iconColor: Color(0xFF1976D2),
      backgroundColor: Color(0xFFE3F2FD),
      schemeCount: '85 Schemes',
    ),
  ];

  // core curated horizontal collections matching mockup
  final List<Map<String, dynamic>> _displayCategories = [
    {
      'title': 'Business & MSME',
      'count': '123 Schemes',
      'icon': Icons.domain,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Startup & Incubation',
      'count': '64 Schemes',
      'icon': Icons.rocket_launch,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Loans & Credit Support',
      'count': '92 Schemes',
      'icon': Icons.monetization_on,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Women Entrepreneurship',
      'count': '142 Schemes',
      'icon': Icons.person,
      'color': const Color(0xFF2563EB),
    },
  ];

  final List<Map<String, dynamic>> _displayMinistries = [
    {'title': 'Ministry of MSME', 'count': '186 Schemes'},
    {'title': 'Ministry of Finance', 'count': '142 Schemes'},
    {'title': 'Ministry of Rural Development', 'count': '96 Schemes'},
  ];

  final List<Map<String, dynamic>> _displayStates = [
    {'title': 'Tamil Nadu', 'count': '185 Schemes'},
    {'title': 'Maharashtra', 'count': '212 Schemes'},
    {'title': 'Uttar Pradesh', 'count': '198 Schemes'},
    {'title': 'Karnataka', 'count': '154 Schemes'},
    {'title': 'Gujarat', 'count': '126 Schemes'},
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
      builder: (context) => FilterPanel(
        onApplied: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SearchResultsScreen(
                title: _searchController.text,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCategorySelected(String categoryName, AppProvider provider) {
    SmartAssessmentBottomSheet.show(context, categoryName, 'category', () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              DiscoverResultsScreen(title: categoryName, type: 'category', isAssessmentCompleted: true),
        ),
      );
    });
  }

  void _onMinistrySelected(String ministryName, AppProvider provider) {
    SmartAssessmentBottomSheet.show(context, ministryName, 'ministry', () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              DiscoverResultsScreen(title: ministryName, type: 'ministry', isAssessmentCompleted: true),
        ),
      );
    });
  }

  void _onStateSelected(String stateName, AppProvider provider) {
    SmartAssessmentBottomSheet.show(context, stateName, 'state', () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              DiscoverResultsScreen(title: stateName, type: 'state', isAssessmentCompleted: true),
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
          {
            'title': 'Idea Stage',
            'desc': 'Mentorship, seed funding, and business registrations',
            'icon': Icons.lightbulb_outline,
          },
          {
            'title': 'Startup Stage',
            'desc': 'Equity funding, scaling grants, and incubation facilities',
            'icon': Icons.rocket_launch,
          },
          {
            'title': 'Growth Stage',
            'desc': 'Credit guarantees, term loans, and technology scaling',
            'icon': Icons.trending_up,
          },
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Business Stage',
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
                      child: Icon(
                        stage['icon'] as IconData,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    title: Text(
                      stage['title'] as String,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      stage['desc'] as String,
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      provider.clearFilters();
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
      backgroundColor:
          Colors.transparent, // Uses MainTabsContainer blue gradient background
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header (Discover, Search, AI avatar)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
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
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF0F172A),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar with Integrated Filter Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    hintText: 'Search schemes, benefits, departments...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: Container(
                      margin: const EdgeInsets.only(
                        right: 6,
                        top: 4,
                        bottom: 4,
                      ),
                      child: TextButton.icon(
                        onPressed: _openFilterPanel,
                        icon: const Icon(
                          Icons.tune_outlined,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
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
                      onViewAll: () =>
                          _showAllCategoriesBottomSheet(context, provider),
                    ),
                    _buildCategoryHorizontalList(provider),
                    const SizedBox(height: 16),

                    // Section 2: By Ministry
                    _buildSectionHeader(
                      key: _ministrySectionKey,
                      title: 'By Ministry',
                      onViewAll: () =>
                          _showAllMinistriesBottomSheet(context, provider),
                    ),
                    _buildMinistryHorizontalList(provider),
                    const SizedBox(height: 16),

                    // Section 3: By State
                    _buildSectionHeader(
                      key: _stateSectionKey,
                      title: 'By State',
                      onViewAll: () =>
                          _showAllStatesBottomSheet(context, provider),
                    ),
                    _buildStateHorizontalList(provider),
                    const SizedBox(height: 16),
                    _buildBusinessUtilitiesSection(),
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
      {
        'title': 'All Categories',
        'icon': Icons.grid_view_rounded,
        'action': () => _scrollToSection(_categorySectionKey),
      },
      {
        'title': 'All Ministries',
        'icon': Icons.account_balance_rounded,
        'action': () => _scrollToSection(_ministrySectionKey),
      },
      {
        'title': 'All States',
        'icon': Icons.location_on_rounded,
        'action': () => _scrollToSection(_stateSectionKey),
      },
      {
        'title': 'By Stage',
        'icon': Icons.trending_up_rounded,
        'action': () => _openLifeStageSelector(provider),
      },
      {
        'title': 'Popular',
        'icon': Icons.star_rounded,
        'action': () {
          _onCategorySelected('Popular Schemes', provider);
        },
      },
      {
        'title': 'Newly Added',
        'icon': Icons.fiber_new_rounded,
        'action': () {
          _onCategorySelected('Newly Added Schemes', provider);
        },
      },
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
                      border: Border.all(
                        color: const Color(0xFFEFF6FF),
                        width: 1.5,
                      ),
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
                      child: Icon(
                        icon,
                        color: const Color(0xFF2563EB),
                        size: 18,
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
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.4),
                              width: 1,
                            ),
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
    switch (stateName.toLowerCase().trim()) {
      case 'tamil nadu':
        return 'assets/images/States and UTs/States/Tamil nadu.png';
      case 'maharashtra':
        return 'assets/images/States and UTs/States/maharashtra.png';
      case 'uttar pradesh':
        return 'assets/images/States and UTs/States/uttar_pradesh.png';
      case 'karnataka':
        return 'assets/images/States and UTs/States/karnataka.png';
      case 'gujarat':
        return 'assets/images/States and UTs/States/gujarat.png';
      case 'arunachal pradesh':
        return 'assets/images/States and UTs/States/Anrunachal pradhesh.png';
      case 'assam':
        return 'assets/images/States and UTs/States/Assam.png';
      case 'bihar':
        return 'assets/images/States and UTs/States/Bihar.png';
      case 'chhattisgarh':
        return 'assets/images/States and UTs/States/Chhatishgar.png';
      case 'kerala':
        return 'assets/images/States and UTs/States/Kerala.png';
      case 'andhra pradesh':
        return 'assets/images/States and UTs/States/andhra pradesh.png';
      case 'goa':
        return 'assets/images/States and UTs/States/goa.png';
      case 'haryana':
        return 'assets/images/States and UTs/States/haryana.png';
      case 'himachal pradesh':
        return 'assets/images/States and UTs/States/himachal pradesh.png';
      case 'jharkhand':
        return 'assets/images/States and UTs/States/jharkhand.png';
      case 'madhya pradesh':
        return 'assets/images/States and UTs/States/madhya pradesh.png';
      case 'manipur':
        return 'assets/images/States and UTs/States/manipur.png';
      case 'meghalaya':
        return 'assets/images/States and UTs/States/meghalaya.png';
      case 'mizoram':
        return 'assets/images/States and UTs/States/mizoram.png';
      case 'nagaland':
        return 'assets/images/States and UTs/States/nagaland.png';
      case 'odisha':
        return 'assets/images/States and UTs/States/odisha.png';
      case 'punjab':
        return 'assets/images/States and UTs/States/punjab.png';
      case 'rajasthan':
        return 'assets/images/States and UTs/States/rajasthan.png';
      case 'sikkim':
        return 'assets/images/States and UTs/States/sikkim.png';
      case 'telangana':
        return 'assets/images/States and UTs/States/telangana.png';
      case 'tripura':
        return 'assets/images/States and UTs/States/tripura.png';
      case 'uttarakhand':
      case 'uttarkhand':
        return 'assets/images/States and UTs/States/uttarkhand.png';
      case 'west bengal':
        return 'assets/images/States and UTs/States/west bengal.png';
      default:
        return 'assets/images/States and UTs/States/Tamil nadu.png';
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



  void _showAllCategoriesBottomSheet(
    BuildContext context,
    AppProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = allCategoriesList.where((cat) {
              return cat.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
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
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                          ),
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
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryItem category,
    AppProvider provider,
  ) {
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

  void _showAllMinistriesBottomSheet(
    BuildContext context,
    AppProvider provider,
  ) {
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
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
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
          'Andhra Pradesh',
          'Arunachal Pradesh',
          'Assam',
          'Bihar',
          'Chhattisgarh',
          'Delhi',
          'Goa',
          'Gujarat',
          'Haryana',
          'Himachal Pradesh',
          'Jammu & Kashmir',
          'Jharkhand',
          'Karnataka',
          'Kerala',
          'Ladakh',
          'Madhya Pradesh',
          'Maharashtra',
          'Manipur',
          'Meghalaya',
          'Mizoram',
          'Nagaland',
          'Odisha',
          'Puducherry',
          'Punjab',
          'Rajasthan',
          'Sikkim',
          'Tamil Nadu',
          'Telangana',
          'Tripura',
          'Uttar Pradesh',
          'Uttarakhand',
          'West Bengal',
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
                      leading: Image.asset(
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
                      title: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
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

  Widget _buildBusinessUtilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Business Utilities & Tools",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildUtilityCard(
                icon: Icons.domain_verification,
                title: "Udyam Classifier",
                desc: "Check MSME tier",
                onTap: _openUdyamClassifier,
              ),
              _buildUtilityCard(
                icon: Icons.calculate_outlined,
                title: "Subsidy Estimator",
                desc: "Machinery subsidies",
                onTap: _openSubsidyEstimator,
              ),
              _buildUtilityCard(
                icon: Icons.percent_outlined,
                title: "GST Calculator",
                desc: "Compute GST invoice",
                onTap: _openGstCalculator,
              ),
              _buildUtilityCard(
                icon: Icons.monetization_on_outlined,
                title: "EMI Calculator",
                desc: "Calculate loan EMIs",
                onTap: _openEmiCalculator,
              ),
              _buildUtilityCard(
                icon: Icons.rocket_launch_outlined,
                title: "DPIIT Eligibility",
                desc: "Check startup criteria",
                onTap: _openDpiitChecklist,
              ),
              _buildUtilityCard(
                icon: Icons.trending_up_outlined,
                title: "Valuation Estimator",
                desc: "Seed valuation ranges",
                onTap: _openValuationEstimator,
              ),
              _buildUtilityCard(
                icon: Icons.rule_folder_outlined,
                title: "Doc Checklist",
                desc: "Business setup docs",
                onTap: _openDocumentChecklist,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUtilityCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 142,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(height: 6),
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
              Text(
                desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUdyamClassifier() {
    final investmentController = TextEditingController();
    final turnoverController = TextEditingController();
    String result = '';
    String subResult = '';
    Color resultColor = const Color(0xFF1E293B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.domain_verification,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Udyam MSME Classifier',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Classify your business under official government guidelines.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Investment in Plant & Machinery',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: investmentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '0.5',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixText: '₹ ',
                      suffixText: 'Cr',
                      helperText: 'Enter original purchase value of machinery in Crores',
                      helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                      suffixStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      prefixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Annual Turnover',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: turnoverController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '3.0',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixText: '₹ ',
                      suffixText: 'Cr',
                      helperText: 'Enter total revenue/sales of last financial year in Crores',
                      helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                      suffixStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      prefixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (result.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: resultColor.withValues(alpha: 0.2)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: resultColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Classification Result',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      result,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: resultColor,
                                      ),
                                    ),
                                    if (subResult.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subResult,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double invest = double.tryParse(investmentController.text) ?? 0;
                        final double turn = double.tryParse(turnoverController.text) ?? 0;

                        if (invest <= 0 || turn <= 0) {
                          setModalState(() {
                            result = 'Invalid Input';
                            subResult = 'Please enter valid values greater than 0';
                            resultColor = const Color(0xFFDC2626);
                          });
                          return;
                        }

                        String category = '';
                        if (invest <= 1 && turn <= 5) {
                          category = 'MICRO Enterprise';
                          resultColor = const Color(0xFF0D9488); // Teal
                        } else if (invest <= 10 && turn <= 50) {
                          category = 'SMALL Enterprise';
                          resultColor = const Color(0xFF2563EB); // Royal Blue
                        } else if (invest <= 50 && turn <= 250) {
                          category = 'MEDIUM Enterprise';
                          resultColor = const Color(0xFFD97706); // Amber
                        } else {
                          category = 'Large Enterprise (Beyond MSME Limits)';
                          resultColor = const Color(0xFFDC2626); // Red
                        }

                        setModalState(() {
                          result = category;
                          subResult = 'Limits: Micro (≤1cr / ≤5cr) | Small (≤10cr / ≤50cr) | Medium (≤50cr / ≤250cr)';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Calculate Classification',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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

  void _openGstCalculator() {
    final amountController = TextEditingController();
    double gstPercentage = 18.0;
    double baseVal = 0.0;
    double cgstVal = 0.0;
    double sgstVal = 0.0;
    double totalVal = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.percent_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GST / Tax Calculator',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              'Calculate CGST, SGST, and Total invoice amounts.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Base Amount',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '50000',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixText: '₹ ',
                      helperText: 'Enter net value of goods or services before GST',
                      helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                      prefixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'GST Rate (%)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [5.0, 12.0, 18.0, 28.0].map((rate) {
                      final isSelected = gstPercentage == rate;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                '$rate%',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setModalState(() => gstPercentage = rate);
                            },
                            selectedColor: const Color(0xFFEFF6FF),
                            backgroundColor: Colors.white,
                            checkmarkColor: const Color(0xFF2563EB),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (baseVal > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Base Price', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                              Text('₹ ${baseVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CGST (${(gstPercentage / 2).toStringAsFixed(1)}%)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${cgstVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SGST (${(gstPercentage / 2).toStringAsFixed(1)}%)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${sgstVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Invoice', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              Text('₹ ${totalVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double base = double.tryParse(amountController.text) ?? 0;
                        if (base <= 0) {
                          setModalState(() {
                            error = 'Please enter a valid base amount';
                            baseVal = 0;
                          });
                          return;
                        }
                        final double gstAmount = base * (gstPercentage / 100);
                        setModalState(() {
                          error = '';
                          baseVal = base;
                          cgstVal = gstAmount / 2;
                          sgstVal = gstAmount / 2;
                          totalVal = base + gstAmount;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Calculate Tax',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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

  void _openEmiCalculator() {
    final loanController = TextEditingController();
    final rateController = TextEditingController();
    final tenureController = TextEditingController();
    double emiVal = 0.0;
    double principalVal = 0.0;
    double interestVal = 0.0;
    double totalVal = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Loan EMI Calculator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Calculate monthly payments for your business loan.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loan Amount',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: loanController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '500000',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixText: '₹ ',
                      helperText: 'Enter total business loan sum required',
                      helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                      prefixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interest Rate (% p.a.)',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: rateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: '9.5',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                suffixText: '%',
                                helperText: 'Enter annual rate',
                                helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tenure (Months)',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: tenureController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: '60',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                suffixText: 'Mo',
                                helperText: 'Enter term in months',
                                helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (emiVal > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Monthly EMI', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              Text('₹ ${emiVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Principal Amount', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${principalVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Interest Payable', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${interestVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount (Principal + Int)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${totalVal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double p = double.tryParse(loanController.text) ?? 0;
                        final double annualRate = double.tryParse(rateController.text) ?? 0;
                        final double n = double.tryParse(tenureController.text) ?? 0;

                        if (p <= 0 || annualRate <= 0 || n <= 0) {
                          setModalState(() {
                            error = 'Please enter valid inputs';
                            emiVal = 0;
                          });
                          return;
                        }

                        final double r = (annualRate / 12) / 100;
                        final double emi = (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
                        final double totalPayable = emi * n;
                        final double totalInterest = totalPayable - p;

                        setModalState(() {
                          error = '';
                          emiVal = emi;
                          principalVal = p;
                          interestVal = totalInterest;
                          totalVal = totalPayable;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Calculate EMI',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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

  void _openDpiitChecklist() {
    bool isPvtLtdOrLlp = false;
    bool isUnder10Years = false;
    bool turnoverUnder100Cr = false;
    bool isInnovative = false;
    String result = '';
    Color resultColor = const Color(0xFF2563EB);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DPIIT Recognition Checklist',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Evaluate if your business qualifies as a startup under DPIIT rules.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Registered as Pvt Ltd / LLP / Partnership', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Must be registered in India', style: TextStyle(fontSize: 9.5)),
                          value: isPvtLtdOrLlp,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(() => isPvtLtdOrLlp = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: const Text('Incorporation age is under 10 years', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('From incorporation date', style: TextStyle(fontSize: 9.5)),
                          value: isUnder10Years,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(() => isUnder10Years = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: const Text('Annual turnover has never exceeded ₹100 Cr', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('For any financial year', style: TextStyle(fontSize: 9.5)),
                          value: turnoverUnder100Cr,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(() => turnoverUnder100Cr = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: const Text('Working towards innovation/scaling', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Developing new products/processes', style: TextStyle(fontSize: 9.5)),
                          value: isInnovative,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(() => isInnovative = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (result.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: resultColor.withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              resultColor == const Color(0xFF047857) ? Icons.check_circle : Icons.cancel,
                              color: resultColor,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                result,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: resultColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final eligible = isPvtLtdOrLlp && isUnder10Years && turnoverUnder100Cr && isInnovative;
                        setModalState(() {
                          if (eligible) {
                            result = 'Highly Eligible for DPIIT Startup India Recognition!';
                            resultColor = const Color(0xFF0D9488); // Teal Green
                          } else {
                            result = 'Not Eligible. Startups must satisfy all 4 criteria to qualify.';
                            resultColor = const Color(0xFFDC2626); // Red
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Check Eligibility',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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

  void _openValuationEstimator() {
    final mrrController = TextEditingController();
    final growthController = TextEditingController();
    String selectedSector = 'SaaS / Tech';
    double lowEstimate = 0.0;
    double highEstimate = 0.0;
    double arrVal = 0.0;
    double appliedMultiple = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formatVal(double val) {
              if (val >= 10000000) return '₹ ${(val / 10000000).toStringAsFixed(2)} Crores';
              return '₹ ${(val / 100000).toStringAsFixed(2)} Lakhs';
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.trending_up_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Startup Valuation Estimator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Get a ballpark pre-seed/seed valuation range based on MRR.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Monthly Recurring Revenue (MRR)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: mrrController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '200000',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixText: '₹ ',
                      helperText: 'Enter monthly revenue in Rupees',
                      helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                      prefixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MoM Growth (%)',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: growthController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: '15',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                suffixText: '%',
                                helperText: 'Enter month-on-month rate',
                                helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Sector',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedSector,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: ['SaaS / Tech', 'E-commerce', 'Fintech', 'AgriTech'].map((String sector) {
                                return DropdownMenuItem<String>(value: sector, child: Text(sector, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedSector = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (lowEstimate > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Valuation Range', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              Text('${formatVal(lowEstimate)} - ${formatVal(highEstimate)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Calculated ARR', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${(arrVal / 100000).toStringAsFixed(1)} Lakhs', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Applied ARR Multiple', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('${appliedMultiple.toStringAsFixed(1)}x', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double mrr = double.tryParse(mrrController.text) ?? 0;
                        final double growth = double.tryParse(growthController.text) ?? 0;

                        if (mrr <= 0) {
                          setModalState(() {
                            error = 'Please enter a valid MRR';
                            lowEstimate = 0;
                          });
                          return;
                        }

                        double baseMultiple = 10;
                        if (selectedSector == 'Fintech') baseMultiple = 12;
                        if (selectedSector == 'E-commerce') baseMultiple = 6;
                        if (selectedSector == 'AgriTech') baseMultiple = 8;

                        if (growth > 20) {
                          baseMultiple += 4;
                        } else if (growth > 10) {
                          baseMultiple += 2;
                        }

                        final double arr = mrr * 12;
                        setModalState(() {
                          error = '';
                          arrVal = arr;
                          appliedMultiple = baseMultiple;
                          lowEstimate = arr * baseMultiple;
                          highEstimate = arr * (baseMultiple + 3);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Estimate Valuation',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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

  void _openDocumentChecklist() {
    String selectedType = 'Private Limited';
    List<String> checklist = [
      'Digital Signature Certificate (DSC)',
      'Director Identification Number (DIN)',
      'MOA & AOA Drafting',
      'Certificate of Incorporation (COI)',
      'Company PAN & TAN Cards',
      'Corporate Bank Account'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.rule_folder_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setup Document Checklist',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Checklist of documents needed to set up your business.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Business Entity Type',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['Private Limited', 'Partnership', 'One Person Company (OPC)', 'LLP'].map((String type) {
                      return DropdownMenuItem<String>(value: type, child: Text(type, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedType = val;
                          if (val == 'Partnership') {
                            checklist = [
                              'Partnership Deed drafting',
                              'Deed Registration with Registrar',
                              'PAN & TAN cards of Firm',
                              'Firm Bank Account',
                              'GST Registration (Optional)'
                            ];
                          } else if (val == 'LLP') {
                            checklist = [
                              'LLP Name Approval (RUN-LLP)',
                              'FiLLiP Form (LLP Incorporation)',
                              'LLP Agreement Drafting',
                              'LLP PAN & TAN Cards',
                              'LLP Bank Account'
                            ];
                          } else {
                            checklist = [
                              'Digital Signature Certificate (DSC)',
                              'Director Identification Number (DIN)',
                              'MOA & AOA Drafting',
                              'Certificate of Incorporation (COI)',
                              'Company PAN & TAN Cards',
                              'Corporate Bank Account'
                            ];
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Required Documents',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: checklist.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEFF2F5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  checklist[index],
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Close Checklist',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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

  void _openSubsidyEstimator() {
    final costController = TextEditingController();
    final subsidyController = TextEditingController();
    double costVal = 0.0;
    double subsidyPercentVal = 0.0;
    double subsidyAmountVal = 0.0;
    double netCostVal = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Subsidy Estimator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Estimate capital subsidies and net loan commitments for machinery.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Project / Machinery Cost (Lakhs)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '25',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixText: '₹ ',
                      suffixText: 'Lakhs',
                      helperText: 'Enter machinery or project cost in Lakhs',
                      helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                      suffixStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      prefixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Expected Subsidy Percentage (%)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subsidyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '15',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      suffixText: '%',
                      helperText: 'Enter expected subsidy rate percentage',
                      helperStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                      suffixStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (costVal > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Original Project Cost', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${costVal.toStringAsFixed(2)} Lakhs', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Expected Subsidy (${subsidyPercentVal.toStringAsFixed(1)}%)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                              Text('₹ ${subsidyAmountVal.toStringAsFixed(2)} Lakhs', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Net Cost to Business', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              Text('₹ ${netCostVal.toStringAsFixed(2)} Lakhs', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double cost = double.tryParse(costController.text) ?? 0;
                        final double percent = double.tryParse(subsidyController.text) ?? 0;

                        if (cost <= 0 || percent <= 0 || percent > 100) {
                          setModalState(() {
                            error = 'Please enter valid values (Subsidy % must be between 0 and 100)';
                            costVal = 0;
                          });
                          return;
                        }

                        final double subsidyAmount = cost * (percent / 100);
                        final double netAmount = cost - subsidyAmount;

                        setModalState(() {
                          error = '';
                          costVal = cost;
                          subsidyPercentVal = percent;
                          subsidyAmountVal = subsidyAmount;
                          netCostVal = netAmount;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Calculate Subsidy',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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
