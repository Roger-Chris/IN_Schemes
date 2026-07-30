import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../engine/recommendation_engine.dart';
import '../../widgets/scheme_card.dart';
import '../../widgets/filter_panel.dart';
import 'scheme_details_screen.dart';
import '../companion_mode/saarthi_welcome_screen.dart';

class DiscoverResultsScreen extends StatefulWidget {
  final String title;
  final String type;

  const DiscoverResultsScreen({
    super.key,
    required this.title,
    required this.type,
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
    final searchKeyword = widget.title.toLowerCase();

    return provider.recommendedSchemes.where((entry) {
      final scheme = entry.key;
      final result = entry.value;

      // 1. Only show eligible schemes (score > 0)
      if (result.score <= 0.0) return false;

      // 2. Filter by Category/Ministry/State Title match
      final nameMatch = scheme.name.toLowerCase().contains(searchKeyword);
      final catMatch = scheme.category.toLowerCase().contains(searchKeyword);
      final sponsorMatch = scheme.sponsoringBody.toLowerCase().contains(
        searchKeyword,
      );
      final stateMatch = scheme.state.toLowerCase().contains(searchKeyword);

      bool titleMatch = nameMatch || catMatch || sponsorMatch || stateMatch;
      if (!titleMatch) {
        final words = searchKeyword.split(' ');
        for (var word in words) {
          if (word.length > 3 &&
              (scheme.name.toLowerCase().contains(word) ||
                  scheme.category.toLowerCase().contains(word))) {
            titleMatch = true;
            break;
          }
        }
      }
      if (!titleMatch) return false;

      // 3. Dropdown Chips Filters
      if (_selectedType != 'All') {
        if (!scheme.targetBeneficiary.toLowerCase().contains(
          _selectedType.toLowerCase(),
        )) {
          return false;
        }
      }
      if (_selectedBenefit != 'All') {
        if (!scheme.benefits.toLowerCase().contains(
          _selectedBenefit.toLowerCase(),
        )) {
          return false;
        }
      }
      if (_selectedMinistry != 'All') {
        if (!scheme.sponsoringBody.toLowerCase().contains(
          _selectedMinistry.toLowerCase(),
        )) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterPanel(),
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
        title: Column(
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Image.asset(
                'assets/saarthi_expressions/Ai companion.png',
                width: 26,
                height: 26,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.android,
                    color: Color(0xFF2563EB),
                    size: 20,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24.0),
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
                    "Best matches for your answers",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 5. Schemes List
            if (filteredSchemes.isEmpty)
              Center(
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
                        "Try retaking the assessment or editing your profile details to match more criteria.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSchemes.length,
                itemBuilder: (context, index) {
                  final entry = filteredSchemes[index];
                  return SchemeCard(
                    scheme: entry.key,
                    result: entry.value,
                    isBookmarked: provider.bookmarkedIds.contains(entry.key.id),
                    onBookmarkToggle: () =>
                        provider.toggleBookmark(entry.key.id),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SchemeDetailsScreen(scheme: entry.key),
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 16),

            // 6. Want more accurate results? Banner
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
                                const SaarthiWelcomeScreen(), // Redirects to Saarthi setup/profile
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

            const SizedBox(height: 12),

            // 7. Companion Help Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Image.asset(
                      'assets/saarthi_expressions/Ai companion.png',
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.android, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need help choosing the right scheme?",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Ask our AI Companion for personalized guidance.",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.9),
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
                            builder: (_) => const SaarthiWelcomeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Ask AI",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
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
