import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../engine/recommendation_engine.dart';
import '../../widgets/scheme_card.dart';
import '../../widgets/filter_panel.dart';
import 'scheme_details_screen.dart';
import 'profile_setup_screen.dart';
import 'search_results_screen.dart';

class DiscoverResultsScreen extends StatefulWidget {
  final String title;
  final String type;
  final bool isAssessmentCompleted;

  const DiscoverResultsScreen({
    super.key,
    required this.title,
    required this.type,
    this.isAssessmentCompleted = false,
  });

  @override
  State<DiscoverResultsScreen> createState() => _DiscoverResultsScreenState();
}

class _DiscoverResultsScreenState extends State<DiscoverResultsScreen> {
  String _sortBy = 'Relevance';
  String _selectedType = 'All';
  String _selectedBenefit = 'All';
  String _selectedMinistry = 'All';

  // Filter and sort the schemes list based on the criteria
  List<MapEntry<Scheme, RecommendationResult>> _getFilteredSchemes(
    AppProvider provider,
  ) {
    final searchKeyword = widget.title.toLowerCase().trim();

    final filtered = provider.recommendedSchemes.where((entry) {
      final scheme = entry.key;

      // 1. Filter by category keyword match in searchKeywords, name, category, or sponsoringBody
      final nameMatch = scheme.name.toLowerCase().contains(searchKeyword);
      final catMatch = scheme.category.toLowerCase().contains(searchKeyword);
      final sponsorMatch = scheme.sponsoringBody.toLowerCase().contains(searchKeyword);
      final stateMatch = scheme.state.toLowerCase().contains(searchKeyword);
      final keywordMatch = scheme.searchKeywords.toLowerCase().contains(searchKeyword);

      bool titleMatch = nameMatch || catMatch || sponsorMatch || stateMatch || keywordMatch;

      // Split fallback for multi-word titles
      if (!titleMatch) {
        final words = searchKeyword.split(RegExp(r'[\s&/,-]+'));
        for (var word in words) {
          if (word.length > 2 &&
              (scheme.name.toLowerCase().contains(word) ||
                  scheme.category.toLowerCase().contains(word) ||
                  scheme.searchKeywords.toLowerCase().contains(word))) {
            titleMatch = true;
            break;
          }
        }
      }
      if (!titleMatch) return false;

      // 2. Dropdown Chips Filters: Type (Loan, Subsidy, etc.)
      if (_selectedType != 'All') {
        final typeKeyword = _selectedType.toLowerCase();
        final matchesType = scheme.schemeType.toLowerCase().contains(typeKeyword) ||
            scheme.name.toLowerCase().contains(typeKeyword) ||
            scheme.category.toLowerCase().contains(typeKeyword) ||
            scheme.overview.toLowerCase().contains(typeKeyword);
        if (!matchesType) {
          return false;
        }
      }

      // 3. Dropdown Chips Filters: Benefit Type
      if (_selectedBenefit != 'All') {
        final benefitLower = _selectedBenefit.toLowerCase();
        bool matchesBenefit = false;
        if (benefitLower == 'financial') {
          matchesBenefit = scheme.benefits.toLowerCase().contains('financial') ||
              scheme.benefits.toLowerCase().contains('subsidy') ||
              scheme.benefits.toLowerCase().contains('funding') ||
              scheme.benefits.toLowerCase().contains('grant') ||
              scheme.benefits.toLowerCase().contains('loan') ||
              scheme.benefits.toLowerCase().contains('pension') ||
              scheme.benefits.toLowerCase().contains('reimbursement') ||
              scheme.benefits.toLowerCase().contains('₹') ||
              scheme.benefits.toLowerCase().contains('rs.') ||
              scheme.schemeType.toLowerCase().contains('subsidy') ||
              scheme.schemeType.toLowerCase().contains('loan') ||
              scheme.schemeType.toLowerCase().contains('grant');
        } else if (benefitLower == 'skill training') {
          matchesBenefit = scheme.benefits.toLowerCase().contains('skill') ||
              scheme.benefits.toLowerCase().contains('training') ||
              scheme.benefits.toLowerCase().contains('workshop') ||
              scheme.benefits.toLowerCase().contains('placement') ||
              scheme.benefits.toLowerCase().contains('capacity building') ||
              scheme.benefits.toLowerCase().contains('mentorship') ||
              scheme.overview.toLowerCase().contains('training') ||
              scheme.overview.toLowerCase().contains('skill');
        } else if (benefitLower == 'infrastructure') {
          matchesBenefit = scheme.benefits.toLowerCase().contains('infrastructure') ||
              scheme.benefits.toLowerCase().contains('facility') ||
              scheme.benefits.toLowerCase().contains('technology') ||
              scheme.benefits.toLowerCase().contains('plant') ||
              scheme.benefits.toLowerCase().contains('machinery') ||
              scheme.benefits.toLowerCase().contains('incubation') ||
              scheme.overview.toLowerCase().contains('infrastructure') ||
              scheme.overview.toLowerCase().contains('technology');
        } else {
          matchesBenefit = scheme.benefits.toLowerCase().contains(benefitLower) ||
              scheme.overview.toLowerCase().contains(benefitLower);
        }
        if (!matchesBenefit) {
          return false;
        }
      }

      // 4. Dropdown Chips Filters: Ministry
      if (_selectedMinistry != 'All') {
        final ministryLower = _selectedMinistry.toLowerCase();
        final matchesMinistry = scheme.sponsoringBody.toLowerCase().contains(ministryLower) ||
            scheme.issuingBody.toLowerCase().contains(ministryLower) ||
            scheme.category.toLowerCase().contains(ministryLower) ||
            scheme.name.toLowerCase().contains(ministryLower);
        if (!matchesMinistry) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort the list
    if (_sortBy == 'Benefits: High to Low') {
      filtered.sort((a, b) {
        final aBenefit = a.key.maxFunding ?? a.key.minFunding ?? 0.0;
        final bBenefit = b.key.maxFunding ?? b.key.minFunding ?? 0.0;
        return bBenefit.compareTo(aBenefit);
      });
    } else if (_sortBy == 'Match %') {
      filtered.sort((a, b) => b.value.percentage.compareTo(a.value.percentage));
    } else {
      // Relevance (Default score)
      filtered.sort((a, b) => b.value.score.compareTo(a.value.score));
    }

    return filtered;
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
                title: widget.title,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownChip(
    String label,
    List<String> options,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        onSelected: onChanged,
        itemBuilder: (context) => options
            .map((opt) => PopupMenuItem(value: opt, child: Text(opt)))
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentValue == 'All' ? label : '$label: $currentValue',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final filteredSchemes = _getFilteredSchemes(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: !widget.isAssessmentCompleted
            ? Text(
                "Discover Results",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Discover Results",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Based on your answers",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "5/5 Completed",
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header and Filters
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 3. Filters Strip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Filter Button
                      OutlinedButton.icon(
                        onPressed: _openFilterPanel,
                        icon: const Icon(
                          Icons.filter_list,
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
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Dropdowns
                      _buildDropdownChip(
                        'Sort',
                        ['Relevance', 'Benefits: High to Low', 'Match %'],
                        _sortBy,
                        (v) => setState(() => _sortBy = v),
                      ),
                      _buildDropdownChip(
                        'Type',
                        ['All', 'Loan', 'Subsidy', 'Scholarship', 'Pension'],
                        _selectedType,
                        (v) => setState(() => _selectedType = v),
                      ),
                      _buildDropdownChip(
                        'Benefit Type',
                        ['All', 'Financial', 'Skill training', 'Infrastructure'],
                        _selectedBenefit,
                        (v) => setState(() => _selectedBenefit = v),
                      ),
                      _buildDropdownChip(
                        'Ministry',
                        ['All', 'MSME', 'Education', 'Finance', 'Agriculture'],
                        _selectedMinistry,
                        (v) => setState(() => _selectedMinistry = v),
                      ),

                      // Clear All
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _sortBy = 'Relevance';
                            _selectedType = 'All';
                            _selectedBenefit = 'All';
                            _selectedMinistry = 'All';
                          });
                        },
                        child: Text(
                          "Clear All",
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Recommended Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Top Recommended Schemes (${filteredSchemes.length})",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                      Text(
                        widget.isAssessmentCompleted
                            ? "Best matches for your answers"
                            : "Best matches for ${widget.title}",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // 5. Schemes List or Loader / Empty States
          if (provider.schemesLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 64.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
              ),
            )
          else if (provider.schemesError != null)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        "Failed to Load Schemes",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.schemesError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filteredSchemes.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48.0,
                    horizontal: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No Matching Schemes Found",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isAssessmentCompleted
                            ? "Try retaking the assessment or editing your profile details to match more criteria."
                            : "Try searching for other keywords or editing your profile details to match more criteria.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Helpful Debug Summary for developer verification
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Debug Information:",
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "• Title/Query: '${widget.title}'\n"
                              "• Type: '${widget.type}'\n"
                              "• Total Schemes in Database: ${provider.allSchemes.length}\n"
                              "• Recommended Schemes: ${provider.recommendedSchemes.length}\n"
                              "• Active Filters: Type='$_selectedType', Benefit='$_selectedBenefit', Ministry='$_selectedMinistry'",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = filteredSchemes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SchemeCard(
                      scheme: entry.key,
                      result: entry.value,
                      isBookmarked: provider.bookmarkedIds.contains(entry.key.id),
                      onBookmarkToggle: () =>
                          provider.toggleBookmark(entry.key.id),
                      showActions: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SchemeDetailsScreen(scheme: entry.key),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: filteredSchemes.length,
              ),
            ),

          // 6. Want more accurate results? Banner
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: Color(0xFF2563EB),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Want more accurate results?",
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Add a few more details to unlock additional relevant schemes.",
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ProfileSetupScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Update Profile",
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
