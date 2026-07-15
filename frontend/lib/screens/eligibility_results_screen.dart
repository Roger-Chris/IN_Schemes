import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/scheme_card.dart';
import '../providers/app_state_provider.dart';
import 'scheme_details_screen.dart';

class EligibilityResultsScreen extends StatelessWidget {
  const EligibilityResultsScreen({super.key});



  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allMatches = provider.recommendedSchemes;
    
    // Eligible schemes are those with a match score > 0%
    final eligibleMatches = allMatches.where((entry) => entry.value.score > 0).toList();

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          'Eligibility Results',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF0D47A1)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing eligibility results...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Custom Vector Success Illustration Stack
                  // Image-based Success Illustration from assets
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Image.asset(
                      'assets/images/eligibility_banner.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Great News Header
                  Text(
                    'Great News! 🎉',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF137C47),
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      children: [
                        const TextSpan(text: 'You are eligible for\n'),
                        TextSpan(
                          text: '${eligibleMatches.length} Government Schemes',
                          style: const TextStyle(
                            color: Color(0xFF137C47),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'based on the information you provided',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Recommended Schemes Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recommended Schemes',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Expand/View all matching schemes
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF137C47),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Color(0xFF137C47),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Recommended cards list
                  if (eligibleMatches.isEmpty)
                    Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Text(
                        'No matching schemes found. Adjust your profile details to expand matching rules.',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...eligibleMatches.map((entry) => SchemeCard(
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
                        )),
                  
                  const SizedBox(height: 16),
                  
                  // Info Alert Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA3D9C9).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF137C47),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These schemes are sorted based on your profile match and eligibility criteria.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF137C47),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Bottom Bar Action Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137C47), // Solid green theme button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Results saved to your eligibility profile!'),
                          backgroundColor: Color(0xFF137C47),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_outline, size: 20),
                    label: Text(
                      'Save Results',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Your information is secure and private',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
