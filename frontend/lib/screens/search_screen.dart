import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/scheme_card.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../widgets/filter_panel.dart';
import 'scheme_details_screen.dart';

class PopularSearchItem {
  final String title;
  final String term;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final bool isCategoryRedirect;

  const PopularSearchItem({
    required this.title,
    required this.term,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.isCategoryRedirect = false,
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final List<String> _recentSearches = [
    'PM Kisan Samman Nidhi', 
    'Scholarship for Girls', 
    'PM Awas Yojana',
    'Ayushman Bharat Yojana',
    'Startup India',
    'Skill Development'
  ];

  static const List<PopularSearchItem> popularSearches = [
    PopularSearchItem(
      title: 'PM Kisan Yojana',
      term: 'PM Kisan Samman Nidhi',
      icon: Icons.grass,
      iconColor: Color(0xFF2E7D32),
      backgroundColor: Color(0xFFE8F5E9),
    ),
    PopularSearchItem(
      title: 'PM Scholarship',
      term: 'Scholarships',
      icon: Icons.school,
      iconColor: Color(0xFF1565C0),
      backgroundColor: Color(0xFFE3F2FD),
    ),
    PopularSearchItem(
      title: 'Ayushman Bharat',
      term: 'Ayushman Bharat',
      icon: Icons.favorite,
      iconColor: Color(0xFFD32F2F),
      backgroundColor: Color(0xFFFFEBEE),
    ),
    PopularSearchItem(
      title: 'PM Awas Yojana',
      term: 'Pradhan Mantri Awas Yojana',
      icon: Icons.home,
      iconColor: Color(0xFFE65100),
      backgroundColor: Color(0xFFFFF3E0),
    ),
    PopularSearchItem(
      title: 'Atal Pension Yojana',
      term: 'Atal Pension Yojana',
      icon: Icons.accessible,
      iconColor: Color(0xFF9C27B0),
      backgroundColor: Color(0xFFF3E5F5),
    ),
    PopularSearchItem(
      title: 'PM Kisan Samman Nidhi',
      term: 'PM Kisan Samman Nidhi',
      icon: Icons.agriculture,
      iconColor: Color(0xFFFBC02D),
      backgroundColor: Color(0xFFFFFDE7),
    ),
    PopularSearchItem(
      title: 'Transport Schemes',
      term: 'Transport',
      icon: Icons.directions_bus,
      iconColor: Color(0xFF00796B),
      backgroundColor: Color(0xFFE0F2F1),
    ),
    PopularSearchItem(
      title: 'Employment Schemes',
      term: 'Employment',
      icon: Icons.business_center,
      iconColor: Color(0xFF6A1B9A),
      backgroundColor: Color(0xFFF3E5F5),
    ),
    PopularSearchItem(
      title: 'Women & Child Welfare',
      term: 'Women & Child',
      icon: Icons.family_restroom,
      iconColor: Color(0xFF4CAF50),
      backgroundColor: Color(0xFFE8F5E9),
    ),
    PopularSearchItem(
      title: 'More Categories',
      term: '',
      icon: Icons.arrow_forward_outlined,
      iconColor: Color(0xFF1E88E5),
      backgroundColor: Color(0xFFE3F2FD),
      isCategoryRedirect: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _searchController.text = provider.searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _triggerSearch(String query) {
    if (query.isEmpty) return;
    
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateSearchQuery(query);

    setState(() {
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 6) _recentSearches.removeLast();
      }
    });
    
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateSearchQuery('');
  }

  void _simulateVoiceSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listening... Speak now'),
        backgroundColor: AppConstants.primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _searchController.text = 'Mudra';
        _triggerSearch('Mudra');
      }
    });
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final query = provider.searchQuery.toLowerCase();
    final activeFilterCount = provider.filters.values.where((v) => v != null && v != 'All' && v != false).length;
    
    // Filter schemes based on search query AND active filters
    final filteredSchemes = provider.recommendedSchemes.where((entry) {
      final scheme = entry.key;
      final filters = provider.filters;

      // 1. Text Search query match
      bool queryMatch = true;
      if (query.isNotEmpty) {
        final nameMatch = scheme.name.toLowerCase().contains(query);
        final overviewMatch = scheme.overview.toLowerCase().contains(query);
        final sponsorMatch = scheme.sponsoringBody.toLowerCase().contains(query);
        final categoryMatch = scheme.category.toLowerCase().contains(query);
        queryMatch = nameMatch || overviewMatch || sponsorMatch || categoryMatch;
      }

      // 2. Active filters match
      bool stateMatch = true;
      if (filters['state'] != null && filters['state'] != 'All') {
        final st = filters['state'].toString().toLowerCase();
        if (st != 'tamil nadu' && ['NEEDS', 'STARTUP_TN', 'KALAIGNAR_KAIVINAI'].contains(scheme.id)) {
          stateMatch = false;
        }
      }

      bool categoryMatch = true;
      if (filters['category'] != null && filters['category'] != 'All') {
        categoryMatch = scheme.category.toLowerCase() == filters['category'].toString().toLowerCase();
      }

      bool genderMatch = true;
      if (filters['gender'] != null && filters['gender'] != 'All') {
        final isFemale = filters['gender'] == 'Female';
        if (!isFemale && ['TREAD', 'WEP'].contains(scheme.id)) {
          genderMatch = false;
        }
      }

      bool ministryMatch = true;
      if (filters['ministry'] != null && filters['ministry'] != 'All') {
        final minVal = filters['ministry'].toString().toLowerCase().replaceAll('ministry of ', '');
        ministryMatch = scheme.sponsoringBody.toLowerCase().contains(minVal);
      }

      bool schemeTypeMatch = true;
      if (filters['schemeType'] != null && filters['schemeType'] != 'All') {
        if (filters['schemeType'] == 'Central Government') {
          schemeTypeMatch = !scheme.sponsoringBody.toLowerCase().contains('tamil nadu') && !scheme.sponsoringBody.toLowerCase().contains('state');
        } else if (filters['schemeType'] == 'State Government') {
          schemeTypeMatch = scheme.sponsoringBody.toLowerCase().contains('tamil nadu') || scheme.sponsoringBody.toLowerCase().contains('state');
        }
      }

      bool studentMatch = true;
      if (filters['occupation'] == 'Student') {
        studentMatch = scheme.overview.toLowerCase().contains('student') || scheme.category.toLowerCase().contains('education') || scheme.name.toLowerCase().contains('student');
      }

      bool farmerMatch = true;
      if (filters['occupation'] == 'Farmer') {
        farmerMatch = scheme.overview.toLowerCase().contains('farmer') || scheme.category.toLowerCase().contains('agriculture') || scheme.name.toLowerCase().contains('farmer') || scheme.category.toLowerCase().contains('artisan');
      }

      bool firstGenMatch = true;
      if (filters['firstGen'] == true) {
        firstGenMatch = scheme.overview.toLowerCase().contains('first') || scheme.overview.toLowerCase().contains('graduate') || scheme.eligibilityCriteria.any((e) => e.toLowerCase().contains('graduate')) || scheme.name.toLowerCase().contains('graduate');
      }

      return queryMatch && stateMatch && categoryMatch && genderMatch && ministryMatch && schemeTypeMatch && studentMatch && farmerMatch && firstGenMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        title: Image.asset(
          'assets/images/Logo icon.png',
          height: 56, // Same bold logo size as Home Page
          fit: BoxFit.contain,
        ),
        actions: [
          // User profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => provider.updateTabIndex(4),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                radius: 24, // Consistent header design
                backgroundImage: const AssetImage('assets/images/user_avatar.png'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Page Header Title & Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A), // Slate 900
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find schemes, benefits and services',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B), // Slate 500
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search input bar row with integrated Filter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
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
                      focusNode: _searchFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: AppConstants.primaryText, fontSize: 15),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _triggerSearch,
                      decoration: InputDecoration(
                        hintText: 'Search for schemes, benefits, services...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8), // Slate 400
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                                onPressed: _clearSearch,
                              )
                            : IconButton(
                                icon: const Icon(Icons.mic_none, color: Color(0xFF64748B)),
                                onPressed: _simulateVoiceSearch,
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _openFilterPanel,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.filter_alt_outlined,
                          size: 22,
                          color: Color(0xFF2563EB), // Blue 600
                        ),
                      ),
                    ),
                    if (activeFilterCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB), // Blue 600
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Active filter chips row
          _buildFilterChipsRow(provider),

          const SizedBox(height: 12),

          // Scrollable area combining Recent Searches, Popular Searches, and Results
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show Recent Searches & Popular Searches only when search input is empty
                  if (query.isEmpty) ...[
                    // 1. Recent Searches Section
                    if (_recentSearches.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Searches',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5, 
                                fontWeight: FontWeight.bold, 
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _recentSearches.clear()),
                              child: Text(
                                'Clear All', 
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0D47A1), 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            childAspectRatio: 3.8,
                          ),
                          itemCount: _recentSearches.length,
                          itemBuilder: (context, index) {
                            final term = _recentSearches[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _searchController.text = term;
                                        _triggerSearch(term);
                                      },
                                      child: Text(
                                        term,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _recentSearches.remove(term);
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 12, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 2. Popular Searches Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Popular Searches',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5, 
                          fontWeight: FontWeight.bold, 
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: popularSearches.length,
                        itemBuilder: (context, index) {
                          final item = popularSearches[index];
                          return _buildPopularSearchCard(context, item, provider);
                        },
                      ),
                    ),
                  ],

                  // Show Results list only when there is an active search query
                  if (query.isNotEmpty) ...[
                    // 3. Results Section Header Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${filteredSchemes.length} ',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF0D47A1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Results found',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Dropdown-style sort indicator
                          Row(
                            children: [
                              Text(
                                'Sorted by Relevance',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 4. Results List
                    if (filteredSchemes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: AppConstants.secondaryText.withAlpha(76)),
                              const SizedBox(height: 16),
                              const Text(
                                'No matching schemes found',
                                style: TextStyle(color: AppConstants.primaryText, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try adjusting your search terms or filter settings.',
                                style: TextStyle(color: AppConstants.secondaryText, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSchemes.length + 1, // Add 1 for the loading footer
                        itemBuilder: (context, index) {
                          if (index == filteredSchemes.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Loading more results...',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          'Pull up to load more',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final entry = filteredSchemes[index];
                          return SchemeCard(
                            scheme: entry.key,
                            result: entry.value,
                            isBookmarked: provider.bookmarkedIds.contains(entry.key.id),
                            onBookmarkToggle: () => provider.toggleBookmark(entry.key.id),
                            onTap: () {
                              provider.addToRecentlyViewed(entry.key.id);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SchemeDetailsScreen(scheme: entry.key),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],

                  const SizedBox(height: 24),

                  // 5. Bottom Help Banner (Always at the bottom)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildBottomBanner(context, provider),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(AppProvider provider) {
    final filters = provider.filters;
    final List<MapEntry<String, String>> activeChips = [];

    filters.forEach((key, val) {
      if (val != null && val != 'All' && val != false) {
        String label = val.toString();
        if (key == 'state') label = 'State: $val';
        if (key == 'district') label = 'District: $val';
        if (key == 'ministry') label = 'Ministry: $val';
        if (key == 'department') label = 'Dept: $val';
        if (key == 'schemeStatus') label = 'Status: $val';
        if (key == 'onlineOffline') label = 'Type: $val';
        if (key == 'schemeType') {
          label = val == 'Central Government' ? 'Central Scheme' : 'State Scheme';
        }
        activeChips.add(MapEntry(key, label));
      }
    });

    if (activeChips.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...activeChips.map((chip) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chip.value,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        provider.updateFilter(chip.key, 'All');
                      },
                      child: const Icon(Icons.close, size: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              )),
          GestureDetector(
            onTap: () => provider.clearFilters(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSearchCard(BuildContext context, PopularSearchItem item, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item.isCategoryRedirect) {
              provider.updateTabIndex(1); // Redirect to Categories Screen (Tab 1)
            } else {
              _searchController.text = item.title;
              _triggerSearch(item.term);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A), // Deep Navy
                        ),
                      ),
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
                  onPressed: _openFilterPanel, // Opens advanced filter modal
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
