import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../services/scheme_repository.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n.dart';
import '../../services/centralized_translator.dart';
import '../../utils/emblem_helper.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final Scheme scheme;

  const SchemeDetailsScreen({super.key, required this.scheme});

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> {
  int _activeTabIndex = 0;

  List<String> _getTabs(BuildContext context) {
    return [
      context.l10n.tabOverview,
      context.l10n.tabBenefits,
      context.l10n.tabEligibility,
      context.l10n.tabDocuments,
      context.l10n.tabServices,
      context.l10n.tabProcess,
    ];
  }

  // Fix 3: GlobalKeys for each scrollable section (for sticky tab auto-scroll)
  final _overviewKey = GlobalKey();
  final _benefitsKey = GlobalKey();
  final _eligibilityKey = GlobalKey();
  final _documentsKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _processKey = GlobalKey();

  // ExpansionTileControllers to programmatically expand the accordions
  // ignore: deprecated_member_use
  final _benefitsController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _eligibilityController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _documentsController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _servicesController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _processController = ExpansionTileController();

  // Fix 4: Accordions closed by default
  bool _benefitsExpanded = false;
  bool _eligibilityExpanded = false;
  bool _documentsExpanded = false;
  bool _servicesExpanded = false;
  bool _processExpanded = false;
  bool _isBookmarked = false;

  // Enriched scheme loaded from the bundled catalog or repository fallback.
  Scheme? _detailedScheme;
  bool _detailsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await SchemeRepository.instance.getSchemeById(
        widget.scheme.id,
      );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keys = [
        _overviewKey,
        _benefitsKey,
        _eligibilityKey,
        _documentsKey,
        _servicesKey,
        _processKey,
      ];
      final key = keys[index];
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _applicationDestination(LocalizedScheme scheme) {
    return [
      scheme.applicationUrl,
      scheme.officialWebsite,
      scheme.guidelinesUrl,
      scheme.sourceUrl,
    ].firstWhere(_isSafeWebUrl, orElse: () => '');
  }

  bool _isSafeWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  Future<void> _openOfficialUrl(String value) async {
    if (!_isSafeWebUrl(value)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noVerifiedLink),
        ),
      );
      return;
    }

    final opened = await launchUrl(
      Uri.parse(value),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenWebsite)),
      );
    }
  }

  String _getImageForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("farmer") || cat.contains("agriculture")) {
      return 'assets/images/Background/new scheme banner.png';
    } else if (cat.contains("student") || cat.contains("education")) {
      return 'assets/images/Background/suggestion banner.png';
    } else {
      return 'assets/images/Background/profile process banner.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawScheme = _detailedScheme ?? widget.scheme;
    final provider = Provider.of<AppProvider>(context);
    final LocalizedScheme scheme = rawScheme.toLocalized(provider.selectedLanguage);

    debugPrint('\n========== [SCHEME DETAILS LOCALIZATION TRACE] ==========');
    debugPrint('Selected App Language: ${provider.selectedLanguage}');
    debugPrint('Raw Scheme ID: ${rawScheme.id}');
    debugPrint('Raw Scheme En Title: ${rawScheme.name}');
    debugPrint('Raw Scheme Ta Title: ${rawScheme.nameTa}');
    debugPrint('Localized Widget Title: ${scheme.name}');
    debugPrint('Localized Widget Overview: ${scheme.overview.length > 50 ? "${scheme.overview.substring(0, 47)}..." : scheme.overview}');
    debugPrint('Localized Widget Benefits: ${scheme.benefits.length > 50 ? "${scheme.benefits.substring(0, 47)}..." : scheme.benefits}');
    if (scheme.documents.isNotEmpty) {
      debugPrint('Localized Widget First Doc: ${scheme.documents.first.name}');
    }
    if (scheme.requiredServices.isNotEmpty) {
      debugPrint('Localized Widget First Service: ${scheme.requiredServices.first.name}');
    }
    if (scheme.applicationProcess.isNotEmpty) {
      debugPrint('Localized Widget First Step: ${scheme.applicationProcess.first}');
    }
    debugPrint('=========================================================\n');

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
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    context.l10n.schemeDetailsTitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
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
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(_getTabs(context).length, (index) {
                            final bool isSelected = _activeTabIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeTabIndex = index;
                                  if (index == 1) {
                                    _benefitsExpanded = true;
                                    _benefitsController.expand();
                                  } else if (index == 2) {
                                    _eligibilityExpanded = true;
                                    _eligibilityController.expand();
                                  } else if (index == 3) {
                                    _documentsExpanded = true;
                                    _documentsController.expand();
                                  } else if (index == 4) {
                                    _servicesExpanded = true;
                                    _servicesController.expand();
                                  } else if (index == 5) {
                                    _processExpanded = true;
                                    _processController.expand();
                                  }
                                });
                                _scrollToSection(index);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 24),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _getTabs(context)[index],
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13.0,
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
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Overview Paragraph
                      Container(
                        key: _overviewKey,
                        child: Text(
                          scheme.overview,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12.0,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Why this matches you card
                      _buildSchemeHighlightsCard(scheme),
                      const SizedBox(height: 12),
                      _buildOfficialSourceCard(scheme),
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
                          controller: _benefitsController,
                          title: context.l10n.benefitsDetails,
                          icon: Icons.card_giftcard_outlined,
                          iconColor: const Color(0xFF047857),
                          iconBg: const Color(0xFFECFDF5),
                          isExpanded: _benefitsExpanded,
                          onToggle: () {
                            setState(() {
                              _benefitsExpanded = !_benefitsExpanded;
                            });
                          },
                          child: _buildBenefitsContent(scheme),
                        ),
                        const SizedBox(height: 12),

                        // Eligibility Expandable Section
                        _ExpandableSection(
                          key: _eligibilityKey,
                          controller: _eligibilityController,
                          title: context.l10n.eligibilityCriteria,
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xFF1D4ED8),
                          iconBg: const Color(0xFFEFF6FF),
                          isExpanded: _eligibilityExpanded,
                          onToggle: () {
                            setState(() {
                              _eligibilityExpanded = !_eligibilityExpanded;
                            });
                          },
                          child: _buildEligibilityContent(scheme),
                        ),
                        const SizedBox(height: 12),

                        // Required Documents Expandable Section
                        _ExpandableSection(
                          key: _documentsKey,
                          controller: _documentsController,
                          title: context.l10n.requiredDocuments,
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF6D28D9),
                          iconBg: const Color(0xFFF5F3FF),
                          isExpanded: _documentsExpanded,
                          onToggle: () {
                            setState(() {
                              _documentsExpanded = !_documentsExpanded;
                            });
                          },
                          child: _buildDocumentsContent(scheme),
                        ),
                        const SizedBox(height: 12),

                        // Required Services Expandable Section
                        _ExpandableSection(
                          key: _servicesKey,
                          controller: _servicesController,
                          title: context.l10n.requiredServices,
                          icon: Icons.support_agent_outlined,
                          iconColor: const Color(0xFF0F766E),
                          iconBg: const Color(0xFFCCFBF1),
                          isExpanded: _servicesExpanded,
                          onToggle: () {
                            setState(() {
                              _servicesExpanded = !_servicesExpanded;
                            });
                          },
                          child: _buildServicesContent(scheme.requiredServices),
                        ),
                        const SizedBox(height: 12),

                        // Process Expandable Section
                        _ExpandableSection(
                          key: _processKey,
                          controller: _processController,
                          title: context.l10n.applicationProcessHeader,
                          icon: Icons.account_tree_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBg: const Color(0xFFFFEDD5),
                          isExpanded: _processExpanded,
                          onToggle: () {
                            setState(() {
                              _processExpanded = !_processExpanded;
                            });
                          },
                          child: _buildProcessContent(
                            scheme.applicationProcess,
                          ),
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
            child: _BottomActionBar(
              isBookmarked: _isBookmarked,
              onBookmarkToggle: () {
                setState(() {
                  _isBookmarked = !_isBookmarked;
                });
              },
              onApply: () => _openOfficialUrl(_applicationDestination(scheme)),
              applyEnabled: _applicationDestination(scheme).isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeHighlightsCard(LocalizedScheme scheme) {
    final matches = [
      scheme.governmentLevel.isNotEmpty
          ? scheme.governmentLevel
          : '',
      scheme.state,
      scheme.sector,
      scheme.targetBeneficiary,
    ].where((value) => value.isNotEmpty).toSet().toList();
    matches.sort((a, b) => a.length.compareTo(b.length));

    final maxPillWidth = MediaQuery.of(context).size.width - 56;

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
              const Icon(
                Icons.track_changes,
                color: Color(0xFF2563EB),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.schemeAtAGlance,
                style: GoogleFonts.poppins(
                  fontSize: 13.0,
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
                constraints: BoxConstraints(maxWidth: maxPillWidth),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2563EB),
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildOfficialSourceCard(LocalizedScheme scheme) {
    final sourceUrl = [
      scheme.sourceUrl,
      scheme.guidelinesUrl,
      scheme.officialWebsite,
    ].firstWhere(_isSafeWebUrl, orElse: () => '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: Color(0xFF047857)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scheme.verificationStatus.isEmpty
                      ? context.l10n.officialInformation
                      : scheme.verificationStatus,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.0,
                  ),
                ),
                if (scheme.lastUpdated.isNotEmpty)
                  Text(
                    context.l10n.lastUpdatedFormat(scheme.lastUpdated),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 9.5,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: sourceUrl.isEmpty
                ? null
                : () => _openOfficialUrl(sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: Text(context.l10n.sourceButton),
          ),
        ],
      ),
    );
  }

  String _formatFunding(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)} crore';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)} lakh';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Widget _buildBenefitsContent(LocalizedScheme scheme) {
    final benefitCards = <Map<String, Object>>[
      if (scheme.subsidyPercentage != null)
        {
          "icon": Icons.percent_rounded,
          "color": const Color(0xFF047857),
          "bg": const Color(0xFFECFDF5),
          "title": context.l10n.benefitSubsidy,
          "desc": "${scheme.subsidyPercentage!.toStringAsFixed(0)}%",
        },
      if (scheme.subsidyAmount.isNotEmpty &&
          scheme.subsidyAmount.toLowerCase() != 'not specified')
        {
          "icon": Icons.payments_outlined,
          "color": const Color(0xFF1D4ED8),
          "bg": const Color(0xFFEFF6FF),
          "title": context.l10n.benefitAmount,
          "desc": scheme.subsidyAmount,
        },
      if (scheme.maxFunding != null)
        {
          "icon": Icons.account_balance_wallet_outlined,
          "color": const Color(0xFF6D28D9),
          "bg": const Color(0xFFF5F3FF),
          "title": context.l10n.benefitMaximum,
          "desc": _formatFunding(scheme.maxFunding!),
        },
      if (scheme.schemeType.isNotEmpty)
        {
          "icon": Icons.category_outlined,
          "color": const Color(0xFFEA580C),
          "bg": const Color(0xFFFFEDD5),
          "title": context.l10n.benefitSupport,
          "desc": scheme.schemeType,
        },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scheme.benefits.isEmpty
              ? CentralizedTranslator.instance.translate('Benefit details are available from the official source.')
              : scheme.benefits,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
        if (benefitCards.isNotEmpty) ...[
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final cardWidth = (screenWidth - 32 - 12) / 2;
              final cardHeight = cardWidth / 2;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: benefitCards.map((card) {
                    return Container(
                      width: cardWidth,
                      height: cardHeight,
                      margin: const EdgeInsets.only(right: 12, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: card["bg"] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            card["icon"] as IconData,
                            color: card["color"] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card["title"] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card["desc"] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEligibilityContent(LocalizedScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...scheme.eligibilityCriteria.map((rule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2563EB),
                    size: 14,
                  ),
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
        }),
        if (scheme.verificationNotes.isNotEmpty) ...[
          const Divider(height: 20),
          Text(
            context.l10n.verificationNote,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scheme.verificationNotes,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsContent(LocalizedScheme scheme) {
    final documents = scheme.documents.isNotEmpty
        ? scheme.documents
        : scheme.requiredDocuments
              .map((name) => SchemeDocument(name: name))
              .toList();
    if (documents.isEmpty) {
      return Text(
        context.l10n.noDocumentsPublished,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11.5,
          height: 1.4,
        ),
      );
    }

    return Column(
      children: documents.map((document) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF2563EB),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.name,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (document.mandatory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: document.isMandatory
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        document.isMandatory ? context.l10n.badgeRequired : document.mandatory,
                        style: GoogleFonts.inter(
                          color: document.isMandatory
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF475569),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (document.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  document.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
              if (document.issuingAuthority.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  context.l10n.issuedByFormat(document.issuingAuthority),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (document.estimatedCost.isNotEmpty &&
                  document.estimatedCost.toLowerCase() != 'not specified')
                Text(
                  context.l10n.estimatedCostFormat(document.estimatedCost),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontSize: 9.0,
                  ),
                ),
              (() {
                final docLink = AppConstants.documentLinks.entries.firstWhere(
                  (entry) {
                    final key = entry.key.toLowerCase();
                    final name = document.name.toLowerCase();
                    return name.contains(key) || key.contains(name);
                  },
                  orElse: () => const MapEntry('', ''),
                ).value;

                if (docLink.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => _openOfficialUrl(docLink),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 13,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.getDocumentOnline,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF2563EB),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              })(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServicesContent(List<SchemeService> services) {
    if (services.isEmpty) {
      return Text(
        context.l10n.noServicesRequiredMsg,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11.0,
        ),
      );
    }

    return Column(
      children: services.map((service) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFCCFBF1),
            child: Icon(
              Icons.support_agent_outlined,
              color: Color(0xFF0F766E),
              size: 18,
            ),
          ),
          title: Text(
            service.name,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            [
              service.category,
              service.description,
            ].where((value) => value.isNotEmpty).join(' • '),
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10.0,
              height: 1.35,
            ),
          ),
          trailing: service.mandatory
              ? const Icon(Icons.check_circle, color: Color(0xFF0F766E))
              : null,
        );
      }).toList(),
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
                      fontSize: 10.5,
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
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.processStepSubtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 9.0,
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
  final LocalizedScheme scheme;
  final String imagePath;

  const _HeroSection({required this.scheme, required this.imagePath});

  Widget _buildSchemeLogo(LocalizedScheme scheme, {double size = 48}) {
    final emblemAsset = EmblemHelper.getEmblemAsset(
      governmentLevel: scheme.governmentLevel,
      state: scheme.state,
      schemeCode: scheme.schemeCode,
      sponsoringBody: scheme.sponsoringBody,
      name: scheme.name,
    );

    return Image.asset(
      emblemAsset,
      fit: BoxFit.contain,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/States assets/Indian emblem.png',
          fit: BoxFit.contain,
          width: size,
          height: size,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = scheme.name;
    final regex = RegExp(r'\(([^)]+)\)');
    final matchObj = regex.firstMatch(title);
    String shortForm = title;
    String fullName = '';

    final bracketText = matchObj?.group(1)?.trim() ?? '';
    if (bracketText.isNotEmpty) {
      final outsideText = title
          .replaceAll(regex, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final isBracketAcronym =
          bracketText.length <= 10 &&
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
            // Left Image (Emblem Container)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  child: ClipOval(
                    child: _buildSchemeLogo(
                      scheme,
                      size: 120,
                    ),
                  ),
                ),
              ),
            ),

            // Right Content Block
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.l10n.levelSchemeFormat(
                              scheme.governmentLevel.isNotEmpty
                                  ? scheme.governmentLevel
                                  : 'Central',
                            ),
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
                            fontSize: 13.5,
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
                              fontSize: 10.0,
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
                          _buildMiniTag(
                            scheme.schemeType,
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                          ),
                        if (scheme.sector.isNotEmpty)
                          _buildMiniTag(
                            scheme.sector,
                            const Color(0xFFECFDF5),
                            const Color(0xFF047857),
                          ),
                        if (scheme.schemeType.isEmpty &&
                            scheme.sector.isEmpty) ...[
                          _buildMiniTag(
                            "Loan",
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                          ),
                          _buildMiniTag(
                            "Subsidy",
                            const Color(0xFFECFDF5),
                            const Color(0xFF047857),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Match Banner (Single-row layout)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF2563EB),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: GoogleFonts.inter(fontSize: 10),
                                children: [
                                  TextSpan(
                                    text: context.l10n.matchPercentageFormat(96),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  TextSpan(
                                    text: " • ${context.l10n.highlyRelevant}",
                                    style: const TextStyle(color: Color(0xFF64748B)),
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
          fontSize: 9.0,
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, height: 48.0, child: child);
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
  // ignore: deprecated_member_use
  final ExpansionTileController controller;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isExpanded,
    required this.controller,
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
          controller: controller,
          initiallyExpanded: isExpanded,
          onExpansionChanged: (_) => onToggle(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 16),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.0,
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
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 4,
              ),
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
  final VoidCallback onApply;
  final bool applyEnabled;

  const _BottomActionBar({
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onApply,
    required this.applyEnabled,
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
                        isBookmarked ? context.l10n.savedSchemeButton : context.l10n.saveSchemeButton,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
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
                onPressed: applyEnabled ? onApply : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
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
                        context.l10n.applyNowButton,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
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
