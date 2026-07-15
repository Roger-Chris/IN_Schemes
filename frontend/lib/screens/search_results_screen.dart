import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/scheme_card.dart';
import '../widgets/filter_panel.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'scheme_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String title;

  const SearchResultsScreen({
    super.key,
    required this.title,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  String _sortBy = 'Relevance'; // Relevance, Name, Sponsoring Body

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterPanel(),
    );
  }

  int _getActiveFilterCount(Map<String, dynamic> filters) {
    int count = 0;
    filters.forEach((key, val) {
      if (val != null && val != 'All' && val != false) {
        count++;
      }
    });
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final filters = provider.filters;
    final activeFilterCount = _getActiveFilterCount(filters);
    final query = _searchController.text.toLowerCase();

    // Fetch and filter schemes dynamically
    var results = provider.recommendedSchemes.where((entry) {
      final scheme = entry.key;

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

    // Sorting logic
    if (_sortBy == 'Name') {
      results.sort((a, b) => a.key.name.compareTo(b.key.name));
    } else if (_sortBy == 'Sponsoring Body') {
      results.sort((a, b) => a.key.sponsoringBody.compareTo(b.key.sponsoringBody));
    } else {
      // Default: Match Score descending / Relevance
      results.sort((a, b) => b.value.score.compareTo(a.value.score));
    }

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Back button, Search input, Filter button with badge)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0F172A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Pill Search Bar
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(color: AppConstants.primaryText, fontSize: 14),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search schemes...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  child: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                                )
                              : const Icon(Icons.mic_none, color: Color(0xFF64748B), size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter Button with Badge
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

            // Results count and Sort dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${results.length} ',
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
                  Row(
                    children: [
                      Text(
                        'Sort by',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          elevation: 2,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 16),
                          items: ['Relevance', 'Name', 'Sponsoring Body'].map((String val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortBy = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Active Filter Chips Scroll Row
            _buildActiveFiltersChipsRow(provider),

            // ListView of results matching the query
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 60, color: Color(0xFF94A3B8)),
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
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: results.length + 1, // Add 1 for the bottom loading banner!
                      itemBuilder: (context, index) {
                        if (index == results.length) {
                          // Display Mockup Loading Footer Banner
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

                        final entry = results[index];
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChipsRow(AppProvider provider) {
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
}
