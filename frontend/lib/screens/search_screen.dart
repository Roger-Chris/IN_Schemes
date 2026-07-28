import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../models/scheme_model.dart';
import '../services/scheme_repository.dart';
import 'scheme_details_screen.dart';
import '../engine/recommendation_engine.dart';

enum SearchState { idle, loading, results }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  SearchState _currentState = SearchState.idle;
  String _activeFilter = "For Me";

  bool get isSearching => _currentState != SearchState.idle;

  // Data list of scheme results from Supabase
  List<Scheme> _searchResults = [];
  List<Scheme> _masterSearchResults = [];
  String _currentSort = "Match";

  void _applySorting() {
    if (_masterSearchResults.isEmpty) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final sorted = List<Scheme>.from(_masterSearchResults);

    if (_currentSort == 'Match %') {
      sorted.sort((a, b) {
        final scoreA = RecommendationEngine.evaluate(provider.profile, a).score;
        final scoreB = RecommendationEngine.evaluate(provider.profile, b).score;
        return scoreB.compareTo(scoreA); // High to Low
      });
    } else if (_currentSort == 'Scheme Name (A-Z)') {
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_currentSort == 'Scheme Name (Z-A)') {
      sorted.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    }
    // "Best Match" just retains the repository search relevance order

    setState(() {
      _searchResults = sorted;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void deactivate() {
    if (_currentState != SearchState.idle) {
      _searchController.clear();
      _currentState = SearchState.idle;
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Public reset method that can be triggered from external Shell controllers
  void resetToIdle() {
    if (_currentState != SearchState.idle) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      if (mounted) {
        setState(() {
          _currentState = SearchState.idle;
        });
      }
    }
  }

  void submitVoiceQuery(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;

    _searchController.value = TextEditingValue(
      text: normalizedQuery,
      selection: TextSelection.collapsed(offset: normalizedQuery.length),
    );
    _searchFocusNode.unfocus();
    _triggerSearch(normalizedQuery);
  }

  void _onSearchTextChanged() {
    // If text gets cleared, instantly revert to idle
    if (_searchController.text.isEmpty && _currentState != SearchState.idle) {
      setState(() {
        _currentState = SearchState.idle;
      });
    }
  }

  void _triggerSearch(String query) async {
    // If query is empty and active filter is "For Me" or "All", go back to idle Categories screen
    if (query.isEmpty &&
        (_activeFilter == 'For Me' || _activeFilter == 'All')) {
      setState(() {
        _currentState = SearchState.idle;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _currentState = SearchState.loading;
    });

    final normalized = query.toLowerCase().trim();
    final bool showAll =
        _activeFilter != 'For Me' ||
        normalized == 'all' ||
        normalized.startsWith('all ') ||
        normalized.endsWith(' all') ||
        normalized.contains(' all ');

    String searchTerm = query;
    if (showAll && normalized != 'all' && _activeFilter == 'For Me') {
      searchTerm = query
          .replaceAll(RegExp(r'\ball\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    try {
      List<Scheme> results;
      if (searchTerm.isEmpty || searchTerm.toLowerCase() == 'all') {
        results = await SchemeRepository.instance.getAllSchemes();
      } else {
        results = await SchemeRepository.instance.searchSchemes(searchTerm);
      }

      if (!mounted) return;

      final provider = Provider.of<AppProvider>(context, listen: false);
      List<Scheme> filteredResults = results;

      if (_activeFilter == 'For Me') {
        filteredResults = results.where((scheme) {
          final eval = RecommendationEngine.evaluate(provider.profile, scheme);
          return eval.score > 0;
        }).toList();
      } else if (_activeFilter == 'Central') {
        filteredResults = results.where((scheme) {
          return scheme.governmentLevel.toLowerCase() == 'central';
        }).toList();
      } else if (_activeFilter == 'State') {
        filteredResults = results.where((scheme) {
          return scheme.governmentLevel.toLowerCase() == 'state' ||
              (scheme.state.isNotEmpty &&
                  scheme.state.toLowerCase() != 'all india');
        }).toList();
      } else if (_activeFilter == 'Loan') {
        filteredResults = results.where((scheme) {
          final type = scheme.schemeType.toLowerCase();
          final category = scheme.category.toLowerCase();
          return type.contains('loan') || category.contains('loan');
        }).toList();
      }

      setState(() {
        _masterSearchResults = filteredResults;
        _currentState = SearchState.results;
      });
      _applySorting();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _masterSearchResults = [];
        _searchResults = [];
        _currentState = SearchState.results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // List of categories matching mockup
    final List<Map<String, dynamic>> categories = [
      {
        "title": "MSME",
        "count": "245 Schemes",
        "icon": Icons.bar_chart,
        "iconColor": const Color(0xFF6D28D9),
        "iconBg": const Color(0xFFF5F3FF),
      },
      {
        "title": "Startup",
        "count": "128 Schemes",
        "icon": Icons.rocket_launch,
        "iconColor": const Color(0xFF1D4ED8),
        "iconBg": const Color(0xFFEFF6FF),
      },
      {
        "title": "Women Entrepreneurs",
        "count": "162 Schemes",
        "icon": Icons.person,
        "iconColor": const Color(0xFFE11D48),
        "iconBg": const Color(0xFFFFE4E6),
      },
      {
        "title": "Students",
        "count": "94 Schemes",
        "icon": Icons.school,
        "iconColor": const Color(0xFF047857),
        "iconBg": const Color(0xFFECFDF5),
      },
      {
        "title": "Farmers",
        "count": "186 Schemes",
        "icon": Icons.agriculture,
        "iconColor": const Color(0xFF16A34A),
        "iconBg": const Color(0xFFDCFCE7),
      },
      {
        "title": "SHG & Artisan",
        "count": "112 Schemes",
        "icon": Icons.groups,
        "iconColor": const Color(0xFFD97706),
        "iconBg": const Color(0xFFFEF3C7),
      },
      {
        "title": "Technology",
        "count": "98 Schemes",
        "icon": Icons.computer,
        "iconColor": const Color(0xFF2563EB),
        "iconBg": const Color(0xFFDBEAFE),
      },
      {
        "title": "Manufacturing",
        "count": "116 Schemes",
        "icon": Icons.factory,
        "iconColor": const Color(0xFFEA580C),
        "iconBg": const Color(0xFFFFEDD5),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // Solid Light Blue
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top header elements
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Custom App Bar
                  _buildCustomAppBar(context, provider),

                  const SizedBox(height: 16),

                  // 2. Search Input Container with dynamic trailing icon
                  _buildSearchInput(context),

                  const SizedBox(height: 8),

                  // Try banner
                  Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Try: Search PMEGP, Startup India, MSME loans...",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  if (isSearching) ...[
                    const SizedBox(height: 16),
                    // 3. Quick Filters Row (Horizontal Scroll)
                    _buildQuickFilters(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. DYNAMIC AREA (AnimatedSwitcher)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildDynamicContent(categories),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Custom App Bar
  Widget _buildCustomAppBar(BuildContext context, AppProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Search",
          style: GoogleFonts.poppins(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const FilterBottomSheet(),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.filter_alt_outlined,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Search Input Container
  Widget _buildSearchInput(BuildContext context) {
    final bool hasText = _searchController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onSubmitted: _triggerSearch,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: "Search schemes...",
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12.5,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF94A3B8),
            size: 18,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentState = SearchState.idle;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (hasText) const SizedBox(width: 8),
              const Icon(Icons.mic, color: Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 12),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  // 3. Quick Filters Row (Horizontal Scroll)
  Widget _buildQuickFilters() {
    final filters = [
      {"name": "For Me", "hasSparkle": true},
      {"name": "All", "hasSparkle": false},
      {"name": "Central", "hasSparkle": false},
      {"name": "State", "hasSparkle": false},
      {"name": "Loan", "hasSparkle": false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Quick Filters",
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  _currentSort = value;
                });
                _applySorting();
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Match %',
                  child: Text('Match %'),
                ),
                const PopupMenuItem<String>(
                  value: 'Scheme Name (A-Z)',
                  child: Text('Scheme Name (A-Z)'),
                ),
                const PopupMenuItem<String>(
                  value: 'Scheme Name (Z-A)',
                  child: Text('Scheme Name (Z-A)'),
                ),
              ],
              child: Row(
                children: [
                  Text(
                    'Sort by: $_currentSort',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: filters.map((filter) {
              final String name = filter["name"] as String;
              final bool hasSparkle = filter["hasSparkle"] as bool;
              final bool isSelected = _activeFilter == name;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _activeFilter = name;
                  });
                  _triggerSearch(_searchController.text);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (hasSparkle) ...[
                        Icon(
                          Icons.auto_awesome,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2563EB),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicContent(List<Map<String, dynamic>> categories) {
    switch (_currentState) {
      case SearchState.loading:
        return _buildLoadingSkeleton();
      case SearchState.results:
        return _buildResultsList();
      case SearchState.idle:
        return _buildIdleContent(categories);
    }
  }

  Widget _buildIdleContent(List<Map<String, dynamic>> categories) {
    return ListView(
      key: const ValueKey("IdleContent"),
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHighlightSummaryCard(),
        const SizedBox(height: 24),
        Text(
          "Browse Categories",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _buildCategoryCard(cat);
          },
        ),
      ],
    );
  }

  // State 2: Shimmer Skeleton List
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      key: const ValueKey("LoadingContent"),
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const _ShimmerSkeletonCard();
      },
    );
  }

  // State 3: Search Results List
  Widget _buildResultsList() {
    final String queryText = _searchController.text.isNotEmpty
        ? _searchController.text
        : _activeFilter;

    if (_searchResults.isEmpty) {
      return ListView(
        key: const ValueKey('ResultsContent'),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.search_off,
                  size: 56,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 16),
                Text(
                  'No schemes found for "$queryText"',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different keyword or browse categories.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      key: const ValueKey('ResultsContent'),
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Results Header Row
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${_searchResults.length} results for ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              TextSpan(
                text: '"$queryText"',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 16),

        // Result Cards List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _ResultSchemeCard(scheme: _searchResults[index]);
          },
        ),
      ],
    );
  }

  // Highlight Card from Idle State
  Widget _buildHighlightSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEFF6FF),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "For Me",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Active",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF047857),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'schemes match your profile.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View Profile Summary",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 4,
                  child: Container(
                    width: 44,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(
                        color: const Color(0xFFDBEAFE),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 14,
                        left: 6,
                        right: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 3,
                            color: const Color(0xFF93C5FD),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 3,
                            color: const Color(0xFF93C5FD),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 20,
                            height: 3,
                            color: const Color(0xFF93C5FD),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF93C5FD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.search,
                      color: Color(0xFF2563EB),
                      size: 20,
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

  // Browse Category Card
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _searchController.text = category["title"] as String;
            _triggerSearch(category["title"] as String);
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category["iconBg"] as Color,
              ),
              alignment: Alignment.center,
              child: Icon(
                category["icon"] as IconData,
                color: category["iconColor"] as Color,
                size: 20,
              ),
            ),
            title: Text(
              category["title"] as String,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              category["count"] as String,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// 5. private helper widget: ResultSchemeCard (uses Scheme model)
class _ResultSchemeCard extends StatelessWidget {
  final Scheme scheme;

  const _ResultSchemeCard({required this.scheme});

  List<String> get _otherTags {
    final List<String> list = [];

    void addSplit(String value) {
      if (value.isNotEmpty) {
        list.addAll(
          value
              .split(',')
              .map((s) => s.trim())
              .where(
                (s) =>
                    s.isNotEmpty &&
                    s.toLowerCase() != 'pending official verification',
              ),
        );
      }
    }

    addSplit(scheme.category);
    addSplit(scheme.schemeType);
    addSplit(scheme.sector);

    final Set<String> seen = {};
    final List<String> uniqueList = [];

    final sponsoringLower = scheme.sponsoringBody.toLowerCase();
    final govLevelLower = scheme.governmentLevel.toLowerCase();
    final stateLower = scheme.state.toLowerCase();

    for (final tag in list) {
      final lower = tag.toLowerCase();
      final isSubtitleTerm =
          sponsoringLower.contains(lower) ||
          govLevelLower.contains(lower) ||
          stateLower.contains(lower) ||
          lower == 'central' ||
          lower == 'state';
      if (!seen.contains(lower) && !isSubtitleTerm) {
        seen.add(lower);
        uniqueList.add(tag);
      }
    }

    return uniqueList.take(4).toList();
  }

  String _getOnlineLogoUrl(
    String schemeCode,
    String category,
    String governmentLevel,
    String state,
  ) {
    final code = schemeCode.toUpperCase();
    final st = state.toLowerCase();

    if (code.contains('MUDRA') || code.contains('PMMY')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Logo_of_the_Pradhan_Mantri_Mudra_Yojana.svg/450px-Logo_of_the_Pradhan_Mantri_Mudra_Yojana.svg.png';
    } else if (code.contains('MSME') ||
        code.contains('CGTMSE') ||
        code.contains('PMEGP')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/MSME_logo_%28colour%29.svg/330px-MSME_logo_%28colour%29.svg.png';
    } else if (code.startsWith('TN_') ||
        st.contains('tamil') ||
        st.contains('tn')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/81/Emblem_of_Tamil_Nadu.svg/360px-Emblem_of_Tamil_Nadu.svg.png';
    } else {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/358px-Emblem_of_India.svg.png';
    }
  }

  Map<String, Color> _getTagColors(String tag, String category) {
    final cleanTag = tag.toLowerCase().trim();
    final cleanCat = category.toLowerCase().trim();

    if (cleanTag == cleanCat) {
      if (cleanCat.contains('farmer') ||
          cleanCat.contains('agri') ||
          cleanCat.contains('rural')) {
        return {'text': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7)};
      } else if (cleanCat.contains('student') ||
          cleanCat.contains('edu') ||
          cleanCat.contains('scholarship')) {
        return {'text': const Color(0xFF6D28D9), 'bg': const Color(0xFFF5F3FF)};
      } else if (cleanCat.contains('business') ||
          cleanCat.contains('msme') ||
          cleanCat.contains('employment')) {
        return {'text': const Color(0xFF1E3A8A), 'bg': const Color(0xFFDBEAFE)};
      } else if (cleanCat.contains('women') ||
          cleanCat.contains('female') ||
          cleanCat.contains('girl') ||
          cleanCat.contains('child')) {
        return {'text': const Color(0xFFBE185D), 'bg': const Color(0xFFFCE7F3)};
      } else {
        return {'text': const Color(0xFF0F766E), 'bg': const Color(0xFFCCFBF1)};
      }
    }

    if (cleanTag.contains('central') ||
        cleanTag.contains('national') ||
        cleanTag.contains('india')) {
      return {'text': const Color(0xFFC2410C), 'bg': const Color(0xFFFFEDD5)};
    } else if (cleanTag.contains('state') ||
        cleanTag.contains('tamil') ||
        cleanTag.contains('tn')) {
      return {'text': const Color(0xFF7C3AED), 'bg': const Color(0xFFF3E8FF)};
    } else if (cleanTag.contains('loan') || cleanTag.contains('credit')) {
      return {'text': const Color(0xFFB91C1C), 'bg': const Color(0xFFFEE2E2)};
    } else if (cleanTag.contains('subsidy') || cleanTag.contains('grant')) {
      return {'text': const Color(0xFF047857), 'bg': const Color(0xFFD1FAE5)};
    } else if (cleanTag.contains('msme')) {
      return {'text': const Color(0xFF15803D), 'bg': const Color(0xFFE8F5E9)};
    }

    final hash = cleanTag.hashCode;
    final index = hash.abs() % 4;
    if (index == 0) {
      return {'text': const Color(0xFF0369A1), 'bg': const Color(0xFFE0F2FE)};
    } else if (index == 1) {
      return {'text': const Color(0xFF0F766E), 'bg': const Color(0xFFE6FFFA)};
    } else if (index == 2) {
      return {'text': const Color(0xFF6D28D9), 'bg': const Color(0xFFF5F3FF)};
    } else {
      return {'text': const Color(0xFFB45309), 'bg': const Color(0xFFFEF3C7)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(_otherTags)..sort((a, b) => a.length.compareTo(b.length));
    final provider = Provider.of<AppProvider>(context);

    // Display the full scheme name as requested

    final logoUrl = _getOnlineLogoUrl(
      scheme.schemeCode,
      scheme.category,
      scheme.governmentLevel,
      scheme.state,
    );

    // Build subtitle combining department and state/central level
    final department = scheme.sponsoringBody.isNotEmpty
        ? scheme.sponsoringBody
        : scheme.issuingBody;
    final level = scheme.state.isNotEmpty && scheme.state != 'All India'
        ? scheme.state
        : scheme.governmentLevel;
    final subtitleText = [
      if (department.isNotEmpty) department,
      if (level.isNotEmpty) level,
    ].join(' • ');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchemeDetailsScreen(scheme: scheme),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main Card Content Row (Enlarged)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Circular Logo Container (Enlarged to 72)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.account_balance,
                          color: Color(0xFF2563EB),
                          size: 28,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Middle Content Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Match Badge Pill
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${RecommendationEngine.evaluate(provider.profile, scheme).percentage}% Match",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF2E7D32),
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Title (Scheme Name) - Full Width
                        Text(
                          scheme.name,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitleText.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitleText,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Chips Row (Others at the bottom)
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: tags.map((tag) {
                            final colors = _getTagColors(tag, scheme.category);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors['bg'],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: colors['text'],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. self-contained Shimmer Skeleton Card Widget
class _ShimmerSkeletonCard extends StatefulWidget {
  const _ShimmerSkeletonCard();

  @override
  State<_ShimmerSkeletonCard> createState() => _ShimmerSkeletonCardState();
}

class _ShimmerSkeletonCardState extends State<_ShimmerSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double opacity = 0.3 + (_controller.value * 0.4);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer Logo Box
              Opacity(
                opacity: opacity,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Shimmer Content Lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 160,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
