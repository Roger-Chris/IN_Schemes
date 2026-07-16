import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../models/scheme_model.dart';
import '../utils/constants.dart';
import '../engine/recommendation_engine.dart';

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
  bool _overviewExpanded = true;
  bool _benefitsExpanded = true;
  bool _eligibilityExpanded = true;

  void _showDocumentHelpDialog(BuildContext context, String docName, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppConstants.cardBorderColor),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppConstants.primaryColor),
              const SizedBox(width: 10),
              Text(
                'Document Assistance',
                style: GoogleFonts.poppins(
                  color: AppConstants.primaryText,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to be redirected to the official government portal to apply for your $docName.',
                style: GoogleFonts.inter(
                  color: AppConstants.secondaryText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  url,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1D4ED8),
                    fontSize: 11.5,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppConstants.secondaryText, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Redirecting to official portal for $docName...'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              },
              child: Text(
                'Open Portal',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerHeader(String category, RecommendationResult evaluation) {
    String imagePath = 'assets/images/banner_family.png';
    final cat = category.toLowerCase();
    if (cat.contains('education') || cat.contains('student')) {
      imagePath = 'assets/images/banner_students.png';
    } else if (cat.contains('agriculture') || cat.contains('farmer')) {
      imagePath = 'assets/images/banner_farmer.png';
    }

    return Container(
      height: 168,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 135.0, top: 16.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.scheme.name,
                    style: GoogleFonts.poppins(
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.scheme.overview,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsoringBodyBlock() {
    final isTN = widget.scheme.sponsoringBody.toLowerCase().contains('tamil nadu');
    final govText = isTN ? 'Government of Tamil Nadu' : 'Government of India';
    
    final isState = widget.scheme.sponsoringBody.toLowerCase().contains('tamil nadu') || widget.scheme.sponsoringBody.toLowerCase().contains('state');
    final badgeText = isState ? 'State Scheme' : 'Central Scheme';
    final badgeColor = isState ? const Color(0xFFFF9933) : const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF0D47A1),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.scheme.sponsoringBody.split(',').first,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (widget.scheme.sponsoringBody.contains(',')) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.scheme.sponsoringBody.substring(widget.scheme.sponsoringBody.indexOf(',') + 1).trim(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      govText,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 12),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Active',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF16A34A),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required int number,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    bool isExpandable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$number. $title',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
            if (isExpandable)
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF64748B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 1,
          title: 'Overview',
          icon: Icons.description_outlined,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
          isExpandable: true,
          isExpanded: _overviewExpanded,
          onTap: () {
            setState(() {
              _overviewExpanded = !_overviewExpanded;
            });
          },
        ),
        if (_overviewExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.scheme.overview,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    final benefitsList = widget.scheme.benefits
        .split(RegExp(r'(?<=\.)\s+|\n+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 2,
          title: 'Benefits',
          icon: Icons.redeem_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          isExpandable: true,
          isExpanded: _benefitsExpanded,
          onTap: () {
            setState(() {
              _benefitsExpanded = !_benefitsExpanded;
            });
          },
        ),
        if (_benefitsExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: benefitsList.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
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

  Widget _buildEligibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 3,
          title: 'Eligibility Criteria',
          icon: Icons.assignment_ind_outlined,
          iconColor: const Color(0xFF7C3AED),
          iconBgColor: const Color(0xFFF3E8FF),
          isExpandable: true,
          isExpanded: _eligibilityExpanded,
          onTap: () {
            setState(() {
              _eligibilityExpanded = !_eligibilityExpanded;
            });
          },
        ),
        if (_eligibilityExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: widget.scheme.eligibilityCriteria.map((criterion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.check_circle_outline, color: Color(0xFF7C3AED), size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          criterion,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
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

  Widget _buildRequiredDocumentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 4,
          title: 'Required Documents',
          icon: Icons.file_present_outlined,
          iconColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
          trailing: TextButton(
            onPressed: () {
              if (widget.scheme.requiredDocuments.isNotEmpty) {
                final doc = widget.scheme.requiredDocuments.first;
                final url = AppConstants.documentLinks[doc] ?? 'https://www.india.gov.in/';
                _showDocumentHelpDialog(context, doc, url);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View Sample',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.scheme.requiredDocuments.map((doc) {
              return InkWell(
                onTap: () {
                  final url = AppConstants.documentLinks[doc] ?? 'https://www.india.gov.in/';
                  _showDocumentHelpDialog(context, doc, url);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        doc,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF334155),
                          fontWeight: FontWeight.w500,
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

  Widget _buildApplicationProcessSection() {
    final steps = widget.scheme.applicationProcess;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 5,
          title: 'Application Process',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFFEA580C),
          iconBgColor: const Color(0xFFFFEDD5),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(steps.length, (index) {
                final isLast = index == steps.length - 1;
                
                IconData getStepIcon(int idx) {
                  switch (idx) {
                    case 0: return Icons.language;
                    case 1: return Icons.person_add_alt_1_outlined;
                    case 2: return Icons.cloud_upload_outlined;
                    default: return Icons.send_outlined;
                  }
                }
                
                String getStepTitle(int idx) {
                  switch (idx) {
                    case 0: return 'Visit Official Portal';
                    case 1: return 'Register';
                    case 2: return 'Fill & Upload';
                    case 3: return 'Submit';
                    default: return 'Step ${idx + 1}';
                  }
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 112,
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Icon(
                              getStepIcon(index),
                              color: const Color(0xFF2563EB),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            getStepTitle(index),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Step ${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) => Container(
                            width: 4,
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            color: const Color(0xFFCBD5E1),
                          ))..add(Container(
                            margin: const EdgeInsets.only(left: 1.5),
                            child: const Icon(Icons.chevron_right, size: 10, color: Color(0xFFCBD5E1)),
                          )),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportantDatesSection() {
    Widget buildDateCard(String title, String date, Color textColor, Color bgColor) {
      return Container(
        width: 140,
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            Text(
              date,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 6,
          title: 'Important Dates',
          icon: Icons.calendar_month_outlined,
          iconColor: const Color(0xFFDB2777),
          iconBgColor: const Color(0xFFFCE7F3),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildDateCard('Application Start Date', '01 Jul 2026', const Color(0xFFDB2777), const Color(0xFFFFF1F2)),
                const SizedBox(width: 8),
                buildDateCard('Last Date to Apply', '31 Oct 2026', const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
                const SizedBox(width: 8),
                buildDateCard('Institute Verification', '15 Nov 2026', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
                const SizedBox(width: 8),
                buildDateCard('Last Date for Renewal', '30 Nov 2026', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialWebsiteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 7,
          title: 'Official Website',
          icon: Icons.public,
          iconColor: const Color(0xFF0D9488),
          iconBgColor: const Color(0xFFCCFBF1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visit the official website for more information and to apply online.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening official portal: ${widget.scheme.officialWebsite}'),
                      backgroundColor: AppConstants.primaryColor,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.scheme.officialWebsite,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D4ED8),
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 16, color: Color(0xFF1D4ED8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqsSection() {
    if (widget.scheme.faqs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          number: 8,
          title: 'FAQs',
          icon: Icons.help_outline,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: widget.scheme.faqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      faq['question'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    iconColor: const Color(0xFF2563EB),
                    collapsedIconColor: const Color(0xFF64748B),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      Text(
                        faq['answer'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                          height: 1.4,
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final evaluation = provider.recommendedSchemes.firstWhere((e) => e.key.id == widget.scheme.id).value;
    final isBookmarked = provider.bookmarkedIds.contains(widget.scheme.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scheme Details',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? const Color(0xFF0D47A1) : const Color(0xFF64748B),
            ),
            onPressed: () => provider.toggleBookmark(widget.scheme.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scheme link copied to clipboard!'),
                  backgroundColor: AppConstants.successColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBannerHeader(widget.scheme.category, evaluation),
                  _buildSponsoringBodyBlock(),
                  
                  // Content Sections Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Overview
                        _buildOverviewSection(),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        
                        // Section 2: Benefits
                        _buildBenefitsSection(),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        
                        // Section 3: Eligibility Criteria
                        _buildEligibilitySection(),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        
                        // Section 4: Required Documents
                        _buildRequiredDocumentsSection(context),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        
                        // Section 5: Application Process
                        _buildApplicationProcessSection(),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        
                        // Section 6: Important Dates
                        _buildImportantDatesSection(),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        
                        // Section 7: Official Website
                        _buildOfficialWebsiteSection(),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        
                        // Section 8: FAQs
                        _buildFaqsSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Bookmark Symbol (Left)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => provider.toggleBookmark(widget.scheme.id),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? const Color(0xFF0D47A1) : const Color(0xFF475569),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Apply Now Button (Middle)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening official portal: ${widget.scheme.officialWebsite}'),
                            backgroundColor: AppConstants.primaryColor,
                          ),
                        );
                      },
                      icon: const Icon(Icons.launch, size: 18),
                      label: Text(
                        'Apply Now',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share Symbol (Right)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scheme link copied to clipboard!'),
                          backgroundColor: AppConstants.successColor,
                        ),
                      );
                    },
                    child: const Icon(Icons.share_outlined, color: Color(0xFF475569), size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
