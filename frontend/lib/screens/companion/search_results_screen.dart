import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../engine/recommendation_engine.dart';
import 'scheme_details_screen.dart';
import 'filter_bottom_sheet.dart';

// Technical Constraints: Mock SchemeModel class at the top of the file
class SchemeModel {
  final String id;
  final String title;
  final String subtitle;
  final String shortDescription;
  final String summary;
  final double rating;
  final int matchScore; // 0-100
  final List<String> tags;
  final String sector;
  final String implementingAgency;
  final String schemeType;
  final String targetBeneficiary;
  final String launchDate;
  final String lastUpdated;
  final String applicationMode;
  final String officialWebsite;
  final List<String> overview;
  final List<String> benefits;
  final List<String> eligibility;
  final List<String> documents;
  final List<String> applicationProcess;
  final List<String> importantLinks;

  const SchemeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.shortDescription,
    required this.summary,
    required this.rating,
    required this.matchScore,
    required this.tags,
    required this.sector,
    required this.implementingAgency,
    required this.schemeType,
    required this.targetBeneficiary,
    required this.launchDate,
    required this.lastUpdated,
    required this.applicationMode,
    required this.officialWebsite,
    required this.overview,
    required this.benefits,
    required this.eligibility,
    required this.documents,
    required this.applicationProcess,
    required this.importantLinks,
  });

  // Helper factory to map the database Scheme to SchemeModel
  factory SchemeModel.fromScheme(Scheme scheme, int score) {
    // Generate clean values from db scheme fields
    final tags = <String>[];
    if (scheme.category.isNotEmpty) tags.add(scheme.category);
    if (scheme.sector.isNotEmpty) tags.add(scheme.sector);
    if (scheme.state.isNotEmpty && scheme.state.toLowerCase() != 'all india') {
      tags.add(scheme.state);
    } else {
      tags.add("Central");
    }

    // Rating approximation (derived deterministically from id or matchScore)
    final double rating = 3.5 + ((scheme.name.length % 4) * 0.5);

    return SchemeModel(
      id: scheme.id,
      title: scheme.name,
      subtitle: scheme.sponsoringBody.isNotEmpty ? scheme.sponsoringBody : "MSME Department",
      shortDescription: scheme.overview.length > 100
          ? "${scheme.overview.substring(0, 97)}..."
          : scheme.overview,
      summary: scheme.objectives.isNotEmpty ? scheme.objectives : scheme.overview,
      rating: rating,
      matchScore: score,
      tags: tags,
      sector: scheme.sector.isNotEmpty ? scheme.sector : "MSME",
      implementingAgency: scheme.issuingBody.isNotEmpty ? scheme.issuingBody : "Government Authority",
      schemeType: scheme.schemeType.isNotEmpty ? scheme.schemeType : "Assistance / Subsidies",
      targetBeneficiary: scheme.targetBeneficiary.isNotEmpty ? scheme.targetBeneficiary : "Entrepreneurs",
      launchDate: scheme.lastUpdated.isNotEmpty ? scheme.lastUpdated : "15 Aug 2017",
      lastUpdated: scheme.lastUpdated.isNotEmpty ? scheme.lastUpdated : "12 May 2024",
      applicationMode: scheme.applicationMode.isNotEmpty ? scheme.applicationMode : "Online",
      officialWebsite: scheme.officialWebsite.isNotEmpty ? scheme.officialWebsite : "https://msme.gov.in",
      overview: [scheme.overview],
      benefits: scheme.benefits.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      eligibility: scheme.eligibilityCriteria.isNotEmpty ? scheme.eligibilityCriteria : ["MSMEs in active sectors"],
      documents: scheme.requiredDocuments.isNotEmpty ? scheme.requiredDocuments : ["Aadhaar", "GST registration"],
      applicationProcess: scheme.applicationProcess.isNotEmpty ? scheme.applicationProcess : ["Apply via official website"],
      importantLinks: [scheme.officialWebsite],
    );
  }
}

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  String _activeFilter = 'All'; // 'All', 'High', 'Medium', 'Other'
  bool _isListView = true;

  // Local filters state map matching FilterBottomSheet options
  Map<String, dynamic> _filters = {
    'matchScore': 'All',
    'schemeType': 'All Types',
    'businessStage': 'All Stages',
    'sector': 'All Sectors',
    'location': 'All Locations',
    'beneficiary': 'All Beneficiaries',
    'womenOnly': false,
    'newlyAdded': false,
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allSchemes = provider.allSchemes;

    // Evaluate scores for all schemes
    final List<MapEntry<Scheme, RecommendationResult>> evaluated = allSchemes.map((s) {
      final res = RecommendationEngine.evaluate(provider.profile, s);
      return MapEntry(s, res);
    }).toList();

    // Text query filtering
    final String query = widget.searchQuery.toLowerCase();
    final filteredByQuery = evaluated.where((entry) {
      if (query.isEmpty) return true;
      final name = entry.key.name.toLowerCase();
      final category = entry.key.category.toLowerCase();
      final sector = entry.key.sector.toLowerCase();
      final keywords = entry.key.searchKeywords.toLowerCase();
      return name.contains(query) ||
          category.contains(query) ||
          sector.contains(query) ||
          keywords.contains(query);
    }).toList();

    // Sort by match score descending
    filteredByQuery.sort((a, b) => b.value.score.compareTo(a.value.score));

    // Map to SchemeModel
    final List<SchemeModel> allModels = filteredByQuery.map((entry) {
      return SchemeModel.fromScheme(entry.key, entry.value.percentage);
    }).toList();

    // Apply Bottom Sheet Filters Map
    final List<SchemeModel> filteredModels = allModels.where((m) {
      // 1. Match Score Filter
      final ms = _filters['matchScore'];
      if (ms != 'All') {
        if (ms == 'High' && m.matchScore < 75) return false;
        if (ms == 'Medium' && (m.matchScore < 50 || m.matchScore >= 75)) return false;
        if (ms == 'Low' && m.matchScore >= 50) return false;
      }
      
      // 2. Scheme Type Filter
      final st = _filters['schemeType'];
      if (st != 'All Types') {
        final typeStr = m.schemeType.toLowerCase();
        if (!typeStr.contains(st.toString().toLowerCase())) return false;
      }

      // 3. Business Stage Filter
      final bs = _filters['businessStage'];
      if (bs != 'All Stages') {
        final stageStr = bs.toString().toLowerCase().replaceAll(' stage', '');
        final matchKeywords = "${m.shortDescription.toLowerCase()} ${m.sector.toLowerCase()}";
        if (!matchKeywords.contains(stageStr)) return false;
      }

      // 4. Sector Filter
      final sec = _filters['sector'];
      if (sec != 'All Sectors') {
        if (!m.sector.toLowerCase().contains(sec.toString().toLowerCase())) return false;
      }

      // 5. Location Filter
      final loc = _filters['location'];
      if (loc != 'All Locations') {
        final locationMatch = m.tags.any((t) => t.toLowerCase().contains(loc.toString().toLowerCase()));
        if (!locationMatch) return false;
      }

      // 6. Target Beneficiary Filter
      final ben = _filters['beneficiary'];
      if (ben != 'All Beneficiaries') {
        final benLower = ben.toString().toLowerCase().split(' ').first;
        if (!m.targetBeneficiary.toLowerCase().contains(benLower)) return false;
      }

      // 7. Women Entrepreneurs Filter
      if (_filters['womenOnly'] == true) {
        final hasWomenTag = m.tags.any((t) => t.toLowerCase().contains('women') || t.toLowerCase().contains('female')) ||
            m.targetBeneficiary.toLowerCase().contains('women') ||
            m.targetBeneficiary.toLowerCase().contains('female');
        if (!hasWomenTag) return false;
      }

      // 8. Newly Added Filter Simulation
      if (_filters['newlyAdded'] == true) {
        if (m.title.length % 2 == 0) return false;
      }

      return true;
    }).toList();

    // Categorize scores of filtered models
    final highModels = filteredModels.where((m) => m.matchScore >= 80).toList();
    final mediumModels = filteredModels.where((m) => m.matchScore >= 60 && m.matchScore < 80).toList();
    final otherModels = filteredModels.where((m) => m.matchScore < 60).toList();

    // Selected models based on active quick filter tab pill
    List<SchemeModel> displayedModels = [];
    if (_activeFilter == 'All') {
      displayedModels = filteredModels;
    } else if (_activeFilter == 'High') {
      displayedModels = highModels;
    } else if (_activeFilter == 'Medium') {
      displayedModels = mediumModels;
    } else {
      displayedModels = otherModels;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Search Results ✨",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFFEA580C)),
            onPressed: () async {
              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FilterBottomSheet(initialFilters: _filters),
              );
              if (result != null) {
                setState(() {
                  _filters = result;
                });
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Chat Intro Header Bubble
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.4), width: 1.5),
                          image: const DecorationImage(
                            image: AssetImage('assets/saarthi_expressions/01_happy.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border.all(color: const Color(0xFFFEE2E2).withOpacity(0.4)),
                          ),
                          child: Text(
                            "Great! I found ${allModels.length} schemes that match your search for \"${widget.searchQuery}\"",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal scrollable row of filter pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      _buildFilterPill("All (${allModels.length})", 'All'),
                      const SizedBox(width: 8),
                      _buildFilterPill("High Match (${highModels.length})", 'High'),
                      const SizedBox(width: 8),
                      _buildFilterPill("Medium Match (${mediumModels.length})", 'Medium'),
                      const SizedBox(width: 8),
                      _buildFilterPill("Other (${otherModels.length})", 'Other'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Sorted by match score & View layout toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sort, color: Color(0xFF64748B), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Sorted by match score ↑↓",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "View as",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _isListView = true),
                            child: Icon(
                              Icons.reorder,
                              color: _isListView ? const Color(0xFFEA580C) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _isListView = false),
                            child: Icon(
                              Icons.grid_view,
                              color: !_isListView ? const Color(0xFFEA580C) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main results display list
                Expanded(
                  child: displayedModels.isEmpty
                      ? Center(
                          child: Text(
                            "No matching schemes found.",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        )
                      : _isListView
                          ? ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 84.0),
                              itemCount: displayedModels.length,
                              itemBuilder: (context, index) {
                                final model = displayedModels[index];
                                return SearchResultCard(scheme: model);
                              },
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 84.0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: displayedModels.length,
                              itemBuilder: (context, index) {
                                final model = displayedModels[index];
                                return SearchResultCard(scheme: model, isGridMode: true);
                              },
                            ),
                ),
              ],
            ),

            // Floating Action Bar (Bottom)
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Color(0xFFEA580C), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Need help choosing the right scheme? Just ask me!",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/saarthi_expressions/01_happy.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEA580C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

// Reusable SearchResultCard Stateless Widget
class SearchResultCard extends StatelessWidget {
  final SchemeModel scheme;
  final bool isGridMode;

  const SearchResultCard({
    super.key,
    required this.scheme,
    this.isGridMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHighMatch = scheme.matchScore >= 80;
    final matchColor = isHighMatch ? const Color(0xFF166534) : const Color(0xFFC2410C);
    final matchBg = isHighMatch ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED);
    final matchLabel = isHighMatch ? "HIGH MATCH" : "MEDIUM MATCH";

    // Sector base icons mapping
    IconData sectorIcon = Icons.business;
    if (scheme.sector.toLowerCase().contains('manufacturing')) {
      sectorIcon = Icons.precision_manufacturing;
    } else if (scheme.sector.toLowerCase().contains('startup')) {
      sectorIcon = Icons.rocket_launch;
    } else if (scheme.sector.toLowerCase().contains('women')) {
      sectorIcon = Icons.person;
    }

    if (isGridMode) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SchemeDetailsScreen(schemeId: scheme.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: matchBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      matchLabel,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: matchColor,
                      ),
                    ),
                  ),
                  Text(
                    "${scheme.matchScore}%",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: matchColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheme.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        scheme.shortDescription,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "View details",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 12, color: Color(0xFFEA580C)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchemeDetailsScreen(schemeId: scheme.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row Match Label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: matchBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    matchLabel,
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: matchColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mid Row layout (Left Icon, Center Details, Right Match Score)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sector Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: matchBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(sectorIcon, color: matchColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Center Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.title,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          final double currentStar = index + 1;
                          final isFilled = currentStar <= scheme.rating;
                          return Icon(
                            Icons.star,
                            color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                            size: 12,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scheme.shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right Score Card
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: matchBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: matchColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${scheme.matchScore}%",
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: matchColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Match Score",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: matchColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Bottom tags wrap & View Details button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: scheme.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SchemeDetailsScreen(schemeId: scheme.id),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        "View Details",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 12, color: Color(0xFFEA580C)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
