import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scheme_model.dart';
import '../services/scheme_repository.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final Scheme scheme;

  const SchemeDetailsScreen({
    super.key,
    required this.scheme,
  });

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> {
  int _activeTabIndex = 0;
  final List<String> _tabs = ["Overview", "Benefits", "Eligibility", "Documents", "Process"];

  // Fix 3: GlobalKeys for each scrollable section (for sticky tab auto-scroll)
  final _overviewKey = GlobalKey();
  final _benefitsKey = GlobalKey();
  final _eligibilityKey = GlobalKey();
  final _documentsKey = GlobalKey();
  final _processKey = GlobalKey();

  // Fix 4: Accordions closed by default
  bool _benefitsExpanded = false;
  bool _eligibilityExpanded = false;
  bool _documentsExpanded = false;
  bool _processExpanded = false;
  bool _isBookmarked = false;

  // Enriched scheme (loaded from Supabase with eligibility, documents etc.)
  Scheme? _detailedScheme;
  bool _detailsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await SchemeRepository.instance.getSchemeById(widget.scheme.id);
      if (mounted) {
        setState(() {
          _detailedScheme = detail ?? widget.scheme;
          _detailsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _detailsLoading = false);
    }
  }

  /// Fix 3: Scrolls to the section matching the tapped tab index.
  void _scrollToSection(int index) {
    final keys = [_overviewKey, _benefitsKey, _eligibilityKey, _documentsKey, _processKey];
    final key = keys[index];
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getImageForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("farmer") || cat.contains("agriculture")) {
      return 'assets/images/banner_farmer.png';
    } else if (cat.contains("student") || cat.contains("education")) {
      return 'assets/images/banner_students.png';
    } else {
      return 'assets/images/banner_family.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Scheme scheme = _detailedScheme ?? widget.scheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom Layer: CustomScrollView withSticky Tabs
          Positioned.fill(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Custom App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "Scheme Details",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A), size: 24),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // 2. Hero Section
                SliverToBoxAdapter(
                  child: _HeroSection(
                    scheme: scheme,
                    imagePath: _getImageForCategory(scheme.category),
                  ),
                ),

                // 3. Sticky Tab Bar Header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final bool isSelected = _activeTabIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeTabIndex = index;
                                });
                                _scrollToSection(index);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 24),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _tabs[index],
                                  style: GoogleFonts.inter(
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Scrollable Content Body
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Overview Paragraph
                      Container(
                        key: _overviewKey,
                        child: Text(
                          scheme.overview,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Why this matches you card
                      _buildWhyThisMatchesYouCard(),
                      const SizedBox(height: 24),

                      // Show a loading indicator while enriched details load
                      if (_detailsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),

                      if (!_detailsLoading) ...[
                        // Benefits Expandable Section
                        _ExpandableSection(
                          key: _benefitsKey,
                          title: "Benefits Details",
                          icon: Icons.card_giftcard_outlined,
                          iconColor: const Color(0xFF047857),
                          iconBg: const Color(0xFFECFDF5),
                          isExpanded: _benefitsExpanded,
                          onToggle: () {
                            setState(() {
                              _benefitsExpanded = !_benefitsExpanded;
                            });
                          },
                          child: _buildBenefitsContent(scheme.benefits),
                        ),
                        const SizedBox(height: 12),

                        // Eligibility Expandable Section
                        _ExpandableSection(
                          key: _eligibilityKey,
                          title: "Eligibility Criteria",
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xFF1D4ED8),
                          iconBg: const Color(0xFFEFF6FF),
                          isExpanded: _eligibilityExpanded,
                          onToggle: () {
                            setState(() {
                              _eligibilityExpanded = !_eligibilityExpanded;
                            });
                          },
                          child: _buildEligibilityContent(scheme.eligibilityCriteria),
                        ),
                        const SizedBox(height: 12),

                        // Required Documents Expandable Section
                        _ExpandableSection(
                          key: _documentsKey,
                          title: "Required Documents",
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF6D28D9),
                          iconBg: const Color(0xFFF5F3FF),
                          isExpanded: _documentsExpanded,
                          onToggle: () {
                            setState(() {
                              _documentsExpanded = !_documentsExpanded;
                            });
                          },
                          child: _buildDocumentsContent(scheme.requiredDocuments),
                        ),
                        const SizedBox(height: 12),

                        // Process Expandable Section
                        _ExpandableSection(
                          key: _processKey,
                          title: "Application Process",
                          icon: Icons.account_tree_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBg: const Color(0xFFFFEDD5),
                          isExpanded: _processExpanded,
                          onToggle: () {
                            setState(() {
                              _processExpanded = !_processExpanded;
                            });
                          },
                          child: _buildProcessContent(scheme.applicationProcess),
                        ),
                      ], // end if (!_detailsLoading)
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Top Layer: Fixed Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomActionBar(isBookmarked: _isBookmarked, onBookmarkToggle: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyThisMatchesYouCard() {
    final matches = [
      "Startup Business",
      "Tamil Nadu",
      "Manufacturing Sector",
      "Women Entrepreneur",
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: Color(0xFF2563EB), size: 16),
              const SizedBox(width: 6),
              Text(
                "Why this matches you",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matches.map((match) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 11),
                    const SizedBox(width: 4),
                    Text(
                      match,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsContent(String benefitsText) {
    final benefitCards = [
      {"icon": Icons.monetization_on, "color": const Color(0xFF047857), "bg": const Color(0xFFECFDF5), "title": "Subsidies", "desc": "Up to 35% subsidy"},
      {"icon": Icons.credit_card, "color": const Color(0xFF1D4ED8), "bg": const Color(0xFFEFF6FF), "title": "Credit Limit", "desc": "Up to ₹50 Lakh loan"},
      {"icon": Icons.security, "color": const Color(0xFF6D28D9), "bg": const Color(0xFFF5F3FF), "title": "Collateral Free", "desc": "No collateral required"},
      {"icon": Icons.school, "color": const Color(0xFFEA580C), "bg": const Color(0xFFFFEDD5), "title": "EDP Training", "desc": "Free training course"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          benefitsText,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: benefitCards.map((card) {
              return Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.only(right: 12, bottom: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card["bg"] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(card["icon"] as IconData, color: card["color"] as Color, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      card["title"] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card["desc"] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEligibilityContent(List<String> criteria) {
    return Column(
      children: criteria.map((rule) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.check_circle_outline, color: Color(0xFF2563EB), size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rule,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentsContent(List<String> documents) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return Row(
              children: [
                const Icon(Icons.assignment_outlined, color: Color(0xFF2563EB), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    documents[index],
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              "Show less ^",
              style: GoogleFonts.inter(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessContent(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final bool isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${index + 1}",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: const Color(0xFFDBEAFE),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index],
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Complete this phase to progress further.",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 9.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// 2. Extracted Hero Section Widget
class _HeroSection extends StatelessWidget {
  final Scheme scheme;
  final String imagePath;

  const _HeroSection({
    required this.scheme,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final title = scheme.name;
    final regex = RegExp(r'\(([^)]+)\)');
    final matchObj = regex.firstMatch(title);
    String shortForm = title;
    String fullName = '';
    
    if (matchObj != null) {
      final bracketText = matchObj.group(1)!.trim();
      final outsideText = title.replaceAll(regex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
      final isBracketAcronym = bracketText.length <= 10 && 
                               !bracketText.contains(' ') && 
                               bracketText == bracketText.toUpperCase();
      if (isBracketAcronym) {
        shortForm = bracketText;
        fullName = outsideText;
      } else if (bracketText.length > outsideText.length) {
        shortForm = outsideText;
        fullName = bracketText;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Right Content Block
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            scheme.governmentLevel.isNotEmpty
                                ? '${scheme.governmentLevel} Scheme'
                                : 'Central Scheme',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2563EB),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shortForm,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fullName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "($fullName)",
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          scheme.sponsoringBody,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Sponsoring theme tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (scheme.schemeType.isNotEmpty)
                          _buildMiniTag(scheme.schemeType, const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                        if (scheme.sector.isNotEmpty)
                          _buildMiniTag(scheme.sector, const Color(0xFFECFDF5), const Color(0xFF047857)),
                        if (scheme.schemeType.isEmpty && scheme.sector.isEmpty) ...[
                          _buildMiniTag("Loan", const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                          _buildMiniTag("Subsidy", const Color(0xFFECFDF5), const Color(0xFF047857)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Match Banner (Single-row layout)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: GoogleFonts.inter(fontSize: 10),
                                children: [
                                  TextSpan(
                                    text: "96% Match ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: "• Highly relevant",
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  Widget _buildMiniTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: text,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 3. Custom SliverPersistentHeaderDelegate for Sticky Tab Bar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      height: 48.0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

// 4. Reusable ExpandableSection Widget
class _ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (_) => onToggle(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 16),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: const Color(0xFF2563EB),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Extracted Bottom Action Bar Widget
class _BottomActionBar extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const _BottomActionBar({
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Save Scheme Button — Fix 2: FittedBox prevents overflow
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: onBookmarkToggle,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: const Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Save Scheme",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Apply Now Button — Fix 2: FittedBox prevents overflow
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Apply Now",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

