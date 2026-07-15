import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../models/scheme_model.dart';
import 'scheme_details_screen.dart';
import 'profile_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final profile = provider.profile;

    // Retrieve Recommended Schemes based on specific ids shown in the mockup
    final recIds = ['PM_SCHOLARSHIP', 'AYUSHMAN_BHARAT', 'PM_AWAS', 'PM_KISAN'];
    final recommended = Scheme.seedData.where((s) => recIds.contains(s.id)).toList();
    recommended.sort((a, b) => recIds.indexOf(a.id).compareTo(recIds.indexOf(b.id)));

    // Retrieve Popular Schemes based on mockup icons
    final popIds = ['PM_KISAN', 'SOIL_HEALTH', 'MUDRA', 'BETI_BACHAO', 'STARTUP_INDIA', 'JAL_JEEVAN'];
    final popular = Scheme.seedData.where((s) => popIds.contains(s.id)).toList();
    popular.sort((a, b) => popIds.indexOf(a.id).compareTo(popIds.indexOf(b.id)));

    // Retrieve Recently Added Schemes
    final recAddedIds = ['PM_VISHWAKARMA', 'PM_SURYA_GHAR', 'JAL_JEEVAN'];
    final recentlyAdded = Scheme.seedData.where((s) => recAddedIds.contains(s.id)).toList();
    recentlyAdded.sort((a, b) => recAddedIds.indexOf(a.id).compareTo(recAddedIds.indexOf(b.id)));

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent gradient container
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        title: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Image.asset(
            'assets/images/Logo icon.png',
            height: 56,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => provider.updateTabIndex(4),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF), // Soft blue
                radius: 24,
                backgroundImage: const AssetImage('assets/images/user_avatar.png'),
                child: const SizedBox.shrink(), // Hides initials to display only the human avatar
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            
            // Greetings Section (Entire greeting bold and smaller size)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()} ${profile.name.isNotEmpty ? profile.name : 'Guest User'}! 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Find schemes that empower you',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar Widget (Redirects to Search Tab)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => provider.updateTabIndex(2), // Search Tab
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
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
                      const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search for schemes, benefits...',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.mic_none, color: Color(0xFF64748B), size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Swipeable Rectangular Carousel Banners
            const _BannerCarousel(),
            const SizedBox(height: 16),
            
            // Recommended Schemes Section (Row-based wide cards scrolling horizontally)
            _buildSectionHeader(
              title: 'Recommended Schemes',
              onTapViewAll: () => provider.updateTabIndex(2), // Search / Schemes list
            ),
            SizedBox(
              height: 135, // Aligned with the height of Recently Added cards
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                itemBuilder: (context, index) {
                  return _buildRecommendedCard(context, recommended[index], provider);
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Popular Schemes Section
            _buildSectionHeader(
              title: 'Popular Schemes',
              onTapViewAll: () => provider.updateTabIndex(1), // Categories Tab
            ),
            SizedBox(
              height: 120, // Accommodates 2 text lines without truncation
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: popular.length,
                itemBuilder: (context, index) {
                  return _buildPopularIconBtn(context, popular[index], provider);
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Recently Added Section (Row-based wide cards scrolling horizontally)
            _buildSectionHeader(
              title: 'Recently Added',
              onTapViewAll: () => provider.updateTabIndex(2), // Search
            ),
            SizedBox(
              height: 135,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: recentlyAdded.length,
                itemBuilder: (context, index) {
                  return _buildRecentlyAddedCard(context, recentlyAdded[index], provider);
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Latest Government Announcements
            _buildSectionHeader(
              title: 'Latest Government Announcements',
              onTapViewAll: () {
                provider.updateTabIndex(3); // Notifications Tab
              },
            ),
            _buildAnnouncementsFeedSection(context, provider),
            const SizedBox(height: 16),
            
            // Continue Eligibility Check Card
            _buildCheckEligibilityCardSection(context, provider),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onTapViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          InkWell(
            onTap: onTapViewAll,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0D47A1),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Row-based wide recommended card similar to Recently Added card
  Widget _buildRecommendedCard(BuildContext context, Scheme scheme, AppProvider provider) {
    Color iconColor;
    Color iconBgColor;
    Color tagBgColor;
    Color tagTextColor;
    IconData icon;
    
    switch (scheme.category) {
      case 'Education':
        icon = Icons.school;
        iconColor = const Color(0xFF16A34A);
        iconBgColor = const Color(0xFFDCFCE7);
        tagTextColor = const Color(0xFF16A34A);
        tagBgColor = const Color(0xFFDCFCE7);
        break;
      case 'Health':
        icon = Icons.favorite;
        iconColor = const Color(0xFFE11D48);
        iconBgColor = const Color(0xFFFFE4E6);
        tagTextColor = const Color(0xFFE11D48);
        tagBgColor = const Color(0xFFFFE4E6);
        break;
      case 'Housing':
        icon = Icons.home;
        iconColor = const Color(0xFFD97706);
        iconBgColor = const Color(0xFFFEF3C7);
        tagTextColor = const Color(0xFFD97706);
        tagBgColor = const Color(0xFFFEF3C7);
        break;
      case 'Agriculture':
        icon = Icons.agriculture;
        iconColor = const Color(0xFF2563EB);
        iconBgColor = const Color(0xFFDBEAFE);
        tagTextColor = const Color(0xFF2563EB);
        tagBgColor = const Color(0xFFDBEAFE);
        break;
      default:
        icon = Icons.article;
        iconColor = const Color(0xFF475569);
        iconBgColor = const Color(0xFFF1F5F9);
        tagTextColor = const Color(0xFF475569);
        tagBgColor = const Color(0xFFF1F5F9);
    }
    
    return Container(
      width: 285, // Same width as recently added cards
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            provider.addToRecentlyViewed(scheme.id);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scheme.overview,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              scheme.category,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: tagTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularIconBtn(BuildContext context, Scheme scheme, AppProvider provider) {
    Color iconColor;
    Color iconBgColor;
    IconData icon;
    
    switch (scheme.id) {
      case 'PM_KISAN':
        icon = Icons.directions_walk;
        iconColor = const Color(0xFF7C3AED);
        iconBgColor = const Color(0xFFF3E8FF);
        break;
      case 'SOIL_HEALTH':
        icon = Icons.spa_outlined;
        iconColor = const Color(0xFF16A34A);
        iconBgColor = const Color(0xFFDCFCE7);
        break;
      case 'MUDRA':
        icon = Icons.business_center_outlined;
        iconColor = const Color(0xFF2563EB);
        iconBgColor = const Color(0xFFDBEAFE);
        break;
      case 'BETI_BACHAO':
        icon = Icons.face;
        iconColor = const Color(0xFFE11D48);
        iconBgColor = const Color(0xFFFFE4E6);
        break;
      case 'STARTUP_INDIA':
        icon = Icons.lightbulb_outline;
        iconColor = const Color(0xFFEA580C);
        iconBgColor = const Color(0xFFFFEDD5);
        break;
      case 'JAL_JEEVAN':
        icon = Icons.opacity;
        iconColor = const Color(0xFF0D9488);
        iconBgColor = const Color(0xFFCCFBF1);
        break;
      default:
        icon = Icons.article_outlined;
        iconColor = const Color(0xFF475569);
        iconBgColor = const Color(0xFFE2E8F0);
    }
    
    String shortTitle = scheme.name;
    if (scheme.id == 'PM_KISAN') shortTitle = 'PM Kisan\nSamman Nidhi';
    if (scheme.id == 'SOIL_HEALTH') shortTitle = 'Soil Health\nCard Scheme';
    if (scheme.id == 'MUDRA') shortTitle = 'Mudra Loan\nScheme';
    if (scheme.id == 'BETI_BACHAO') shortTitle = 'Beti Bachao\nBeti Padhao';
    if (scheme.id == 'STARTUP_INDIA') shortTitle = 'Startup India\nInitiative';
    if (scheme.id == 'JAL_JEEVAN') shortTitle = 'Jal Jeevan\nMission';
    
    return Container(
      width: 90, // Prevents horizontal ellipsis truncation
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              provider.addToRecentlyViewed(scheme.id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SchemeDetailsScreen(scheme: scheme),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            shortTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              height: 1.2,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAddedCard(BuildContext context, Scheme scheme, AppProvider provider) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;
    String addedTime;
    
    switch (scheme.id) {
      case 'PM_VISHWAKARMA':
        icon = Icons.verified_user_outlined;
        iconColor = const Color(0xFF2563EB);
        iconBgColor = const Color(0xFFDBEAFE);
        addedTime = 'Added 2 days ago';
        break;
      case 'PM_SURYA_GHAR':
        icon = Icons.solar_power_outlined;
        iconColor = const Color(0xFF16A34A);
        iconBgColor = const Color(0xFFDCFCE7);
        addedTime = 'Added 5 days ago';
        break;
      case 'JAL_JEEVAN':
        icon = Icons.water_drop_outlined;
        iconColor = const Color(0xFF0D9488);
        iconBgColor = const Color(0xFFCCFBF1);
        addedTime = 'Added 1 week ago';
        break;
      default:
        icon = Icons.add_circle_outline;
        iconColor = const Color(0xFF475569);
        iconBgColor = const Color(0xFFE2E8F0);
        addedTime = 'Added recently';
    }
    
    return Container(
      width: 285, // Allows full scheme title to render without truncation
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            provider.addToRecentlyViewed(scheme.id);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scheme.overview,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              addedTime,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Announcements card updated to look exactly similar to recently added cards
  Widget _buildAnnouncementsFeedSection(BuildContext context, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            provider.updateTabIndex(3); // Route to Notifications Tab
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Changed from 16 to 12
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mega phone icon inside a light blue circle (36x36)
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.campaign, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                
                // Right Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget 2024: Major Announcements',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5, // Standardized title size
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'New initiatives launched for youth empowerment, skill development and rural growth.',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Footer: Date tag and Chevron
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'May 15, 2024',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckEligibilityCardSection(BuildContext context, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue Eligibility Check',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete your profile to find schemes you are eligible for.',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              provider.startWizard();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileSetupScreen(fromEligibilityCheck: true),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Swipeable PageView Carousel with 3 rectangular banners using user uploaded graphics
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = [
      _buildBannerItem(
        context: context,
        title: 'Har Ghar Suraksha',
        subtitle: 'Building a secure future\nfor every Indian family.',
        imagePath: 'assets/images/banner_family.png',
        schemeId: 'AYUSHMAN_BHARAT',
      ),
      _buildBannerItem(
        context: context,
        title: 'PM Kisan Yojana',
        subtitle: 'Financial support of\n₹6,000 for Indian farmers.',
        imagePath: 'assets/images/banner_farmer.png',
        schemeId: 'PM_KISAN',
      ),
      _buildBannerItem(
        context: context,
        title: 'PM Scholarship',
        subtitle: 'Empowering youth with\nfinancial study assistance.',
        imagePath: 'assets/images/banner_students.png',
        schemeId: 'PM_SCHOLARSHIP',
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return banners[index];
            },
          ),
        ),
        const SizedBox(height: 10),
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isSelected = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isSelected ? const Color(0xFF0D47A1) : const Color(0xFFCBD5E1),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBannerItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required String schemeId,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.04),
            blurRadius: 15,
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1E293B),
                      fontSize: 11.5,
                      height: 1.3,
                      fontWeight: FontWeight.w600, // Semi-bold for high readability on image sky background
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final scheme = Scheme.seedData.firstWhere(
                          (s) => s.id == schemeId,
                          orElse: () => Scheme.seedData.first,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SchemeDetailsScreen(scheme: scheme),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Know More',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
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
    );
  }
}
