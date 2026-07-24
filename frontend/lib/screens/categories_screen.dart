import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import 'search_results_screen.dart';
import 'notifications_screen.dart';

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
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Define the 23 categories with scheme counts matching the screenshot
  static const List<CategoryItem> categories = [
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Filter categories list in real time based on search input
    final filteredCategories = categories.where((cat) {
      return cat.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Parent provides blueGradient
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        title: Image.asset(
          'assets/images/Logo icon.png',
          height: 56, // Bold logo size matching Home Page
          fit: BoxFit.contain,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF0D47A1),
                      size: 24,
                    ),
                  ),
                  if (provider.notifications.where((n) => !n['read']).isNotEmpty)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        alignment: Alignment.center,
                        child: Text(
                          '${provider.notifications.where((n) => !n['read']).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // User profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => provider.updateTabIndex(4),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                radius: 24, // Consistent with Home Page enlarge update
                backgroundImage: const AssetImage('assets/images/user_avatar.png'),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Page Header Title (fontSize 17 bold matching Home Screen greeting)
              Text(
                'Categories',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle from the screenshot
              Text(
                'Browse schemes by category and find what matters most to you.',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B), // Slate 500
                ),
              ),
              const SizedBox(height: 16),
              // Search categories input bar
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8), // Slate 400
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF64748B), // Slate 500
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Recreated 3-column Grid
              filteredCategories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'No categories found matching "$_searchQuery"',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78, // Adjusted to prevent vertical title overflow on small screens
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        return _buildCategoryCard(context, category, provider);
                      },
                    ),
              const SizedBox(height: 24),
              // "Can't find what you're looking for?" Banner
              _buildBottomBanner(context, provider),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryItem category, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
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
            // Apply category filter in state
            provider.clearFilters();
            provider.updateFilter('category', category.title);

            // Redirect to Search Results screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchResultsScreen(
                  title: category.title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Soft background color circle with icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: category.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: category.iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                // Centered category title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    category.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A), // Slate 900
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

  Widget _buildBottomBanner(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)), // Light blue 100
        image: const DecorationImage(
          image: AssetImage('assets/images/search_banner.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Can't find what you're looking for?",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A), // Navy
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Use our smart search to find schemes, benefits and services tailored for you.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF475569), // Slate 600
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    provider.updateTabIndex(2); // Go to Search Tab
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1), // Royal Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Advanced Search',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
