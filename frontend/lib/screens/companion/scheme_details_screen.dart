import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../../engine/recommendation_engine.dart';
import 'search_results_screen.dart' show SchemeModel;

class SchemeDetailsScreen extends StatefulWidget {
  final String schemeId;

  const SchemeDetailsScreen({
    super.key,
    required this.schemeId,
  });

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> {
  String _activeTab = 'Overview'; // Overview, Benefits, Eligibility, Documents
  bool _isBookmarked = false;

  // Scroll Anchors using GlobalKey
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _benefitsKey = GlobalKey();
  final GlobalKey _eligibilityKey = GlobalKey();
  final GlobalKey _documentsKey = GlobalKey();

  void _scrollToSection(GlobalKey key, String tabName) {
    setState(() {
      _activeTab = tabName;
    });
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    final cleanUrl = urlString.trim();
    if (cleanUrl.isEmpty) return;
    try {
      final uri = Uri.parse(cleanUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the official website.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link: $cleanUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allSchemes = provider.allSchemes;

    // Find the scheme matching schemeId
    final scheme = allSchemes.firstWhere(
      (s) => s.id == widget.schemeId,
      orElse: () => allSchemes.first,
    );

    // Calculate match score
    final recommendation = RecommendationEngine.evaluate(provider.profile, scheme);
    final int matchScore = recommendation.percentage;
    final model = SchemeModel.fromScheme(scheme, matchScore);

    final isHighMatch = model.matchScore >= 80;
    final matchColor = isHighMatch ? const Color(0xFF166534) : const Color(0xFFC2410C);
    final matchBg = isHighMatch ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED);
    final matchLabel = isHighMatch ? "HIGH MATCH" : "MEDIUM MATCH";

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. App Bar (Pinned)
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                "Scheme Details",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: const Color(0xFFEA580C),
                  ),
                  onPressed: () {
                    setState(() {
                      _isBookmarked = !_isBookmarked;
                    });
                  },
                ),
              ],
            ),

            // 2. Sticky Tab Bar Persistent Header (Pinned)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildTabButton("Overview", Icons.info_outline, _overviewKey),
                        _buildTabButton("Benefits", Icons.stars_outlined, _benefitsKey),
                        _buildTabButton("Eligibility", Icons.verified_user_outlined, _eligibilityKey),
                        _buildTabButton("Documents", Icons.description_outlined, _documentsKey),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Scrollable Content Body
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // A. Hero Card (Overview Anchor)
                  Container(
                    key: _overviewKey,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF4FBF7), Color(0xFFE6F7F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 8),
                              Text(
                                model.title,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                model.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: model.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tag,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              // Callout box
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFDCFCE7)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.stars, color: Color(0xFF166534), size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        model.summary,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          color: const Color(0xFF166534),
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${model.matchScore}%",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: matchColor,
                                      ),
                                    ),
                                    Text(
                                      "Match Score",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Image.asset(
                                'assets/saarthi_expressions/01_happy.png',
                                width: 68,
                                height: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.support_agent,
                                  size: 44,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // B. AI Insight Card
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology, color: Color(0xFFEA580C), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Why this scheme?",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "This scheme is highly aligned with your profile because it offers special financial benefits for entrepreneurs matching your business sector, state registry, and capital requirements.",
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(12, (index) {
                            final double height = [4, 12, 16, 8, 14, 10, 6, 8, 12, 14, 6, 4][index].toDouble();
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 3,
                              height: height,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // C. Scheme Highlights Grid (Clean Row/Column Layout)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: HighlightGridItem(
                              icon: Icons.payments_outlined,
                              title: "Funding Support",
                              value: scheme.maxFunding != null ? "Up to ₹${(scheme.maxFunding! / 100000).toStringAsFixed(0)} Lakh" : "Up to ₹10 Lakh",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HighlightGridItem(
                              icon: Icons.schedule,
                              title: "Repayment Tenure",
                              value: "Up to 3 Years",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: HighlightGridItem(
                              icon: Icons.percent,
                              title: "Interest Subsidy",
                              value: scheme.subsidyPercentage != null ? "${scheme.subsidyPercentage}% Subsidy" : "3% Subvention",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HighlightGridItem(
                              icon: Icons.touch_app_outlined,
                              title: "Application Process",
                              value: model.applicationMode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // D. Scheme Information Table (Eligibility Anchor)
                  Text(
                    "Scheme Information",
                    key: _eligibilityKey,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        InfoTableRow(
                          label: "Scheme ID",
                          value: scheme.schemeCode.isNotEmpty ? scheme.schemeCode : "N/A",
                          icon: Icons.tag,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        InfoTableRow(
                          label: "Implementing Agency",
                          value: model.implementingAgency,
                          icon: Icons.business,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        InfoTableRow(
                          label: "Scheme Type",
                          value: model.schemeType,
                          icon: Icons.category,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        InfoTableRow(
                          label: "Target Beneficiary",
                          value: model.targetBeneficiary,
                          icon: Icons.people_outline,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        InfoTableRow(
                          label: "Launch Date",
                          value: model.launchDate,
                          icon: Icons.calendar_today,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        InfoTableRow(
                          label: "Last Updated",
                          value: model.lastUpdated,
                          icon: Icons.update,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        InfoTableRow(
                          label: "Application Mode",
                          value: model.applicationMode,
                          icon: Icons.laptop,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        InfoTableRow(
                          label: "Official Website",
                          value: model.officialWebsite,
                          icon: Icons.language,
                          isLast: true,
                          onTap: () => _launchURL(model.officialWebsite),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // E. Section Header: "Benefits You Get" (Benefits Anchor)
                  Text(
                    "Benefits You Get",
                    key: _benefitsKey,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // F. Benefits List (4 items)
                  const BenefitCard(
                    title: "Internet & Cloud Subsidy",
                    description: "50% refund on high-speed internet lease line and certified cloud hosting subscription services.",
                    icon: Icons.cloud_done_outlined,
                  ),
                  const BenefitCard(
                    title: "Patent Filing Fee Refund",
                    description: "Up to 75% reimbursement on official filing fees for local patents and registered copyrights.",
                    icon: Icons.copyright_outlined,
                  ),
                  const BenefitCard(
                    title: "Quality Certification Cost",
                    description: "Grants covering up to ₹2 Lakh for procuring standard ISO and industry-specific trade labels.",
                    icon: Icons.verified_outlined,
                  ),
                  const BenefitCard(
                    title: "Marketing & Exhibition Allowance",
                    description: "Travel and stall rent subventions for national conventions and MSME trade events.",
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 12),

                  // G. Total Potential Benefit Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.savings_outlined, color: Color(0xFF166534), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Potential Benefit",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Save up to ₹1.5 Lakh per year!",
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // H. Important Links (Documents Anchor)
                  Text(
                    "Important Links & Documents",
                    key: _documentsKey,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.description, color: Color(0xFFEA580C)),
                          title: Text(
                            "Scheme Guidelines PDF",
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Official policy document. Rules, requirements and limits.",
                            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                          ),
                          trailing: const Icon(Icons.download_for_offline, color: Color(0xFFEA580C)),
                          onTap: () => _launchURL(scheme.guidelinesUrl.isNotEmpty ? scheme.guidelinesUrl : model.officialWebsite),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ListTile(
                          leading: const Icon(Icons.link, color: Color(0xFFEA580C)),
                          title: Text(
                            "Official Registration Webpage",
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            model.officialWebsite,
                            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                          ),
                          trailing: const Icon(Icons.open_in_new, color: Color(0xFFEA580C)),
                          onTap: () => _launchURL(model.officialWebsite),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // I. Saarthi Tip Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFFEA580C), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Saarthi Tip",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFC2410C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Make sure you keep your MSME registration certificate and financial balance sheets ready before launching the online form for a faster process.",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF7C2D12),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ],
        ),
      ),

      // 4. Fixed Bottom Action Bar (Crucial Cleanup)
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 6.0),
                child: Row(
                  children: [
                    // Ghost Listen Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.volume_up, size: 16),
                      label: Text(
                        "Listen",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),

                    // Apply Now OR Check Eligibility Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEA580C).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _launchURL(model.officialWebsite),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Apply Now",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Ghost Share Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.share, size: 16),
                      label: Text(
                        "Share",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Bottom Row (Saarthi Chat Bar with distinct shade)
              Container(
                color: const Color(0xFFFDFBF7),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/saarthi_expressions/01_happy.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Looks interesting, right? Let's check if you are eligible!",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Small voice wave visualizer representation
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(8, (index) {
                        final double height = [4, 12, 16, 8, 14, 10, 6, 4][index].toDouble();
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 2,
                          height: height,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, GlobalKey key) {
    final isSelected = _activeTab == label;
    return GestureDetector(
      onTap: () => _scrollToSection(key, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Persistent Sticky Header Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 2.0 : 0.0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

// Reusable HighlightGridItem stateless widget
class HighlightGridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const HighlightGridItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFEA580C), size: 18),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable BenefitCard stateless widget
class BenefitCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const BenefitCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable InfoTableRow stateless widget
class InfoTableRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;
  final VoidCallback? onTap;

  const InfoTableRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFEA580C), size: 16),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: onTap != null ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
