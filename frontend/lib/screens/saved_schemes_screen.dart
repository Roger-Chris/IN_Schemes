import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../models/scheme_model.dart';
import 'scheme_details_screen.dart';
import 'notifications_screen.dart';

class SavedSchemesScreen extends StatefulWidget {
  const SavedSchemesScreen({super.key});

  @override
  State<SavedSchemesScreen> createState() => _SavedSchemesScreenState();
}

class _SavedSchemesScreenState extends State<SavedSchemesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  // Section keys for scroll synchronization
  final GlobalKey _bookmarkKey = GlobalKey();
  final GlobalKey _recentKey = GlobalKey();
  final GlobalKey _downloadKey = GlobalKey();

  int _activeTab = 0;
  bool _isManualScrolling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Scroll listener to update active tab based on scroll position
  void _onScroll() {
    if (_isManualScrolling) return;

    final double? recentY = _getYPosition(_recentKey);
    final double? downloadY = _getYPosition(_downloadKey);

    int newTab = 0;
    // We check if sections are scrolling past a threshold (approx height of headers/appbar)
    if (downloadY != null && downloadY < 280) {
      newTab = 2;
    } else if (recentY != null && recentY < 280) {
      newTab = 1;
    } else {
      newTab = 0;
    }

    if (newTab != _activeTab) {
      setState(() {
        _activeTab = newTab;
        _tabController.animateTo(newTab);
      });
    }
  }

  double? _getYPosition(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero).dy;
  }

  // Scroll to section when tab is tapped
  void _scrollToSection(int tabIndex) async {
    _isManualScrolling = true;
    setState(() {
      _activeTab = tabIndex;
    });

    GlobalKey key;
    if (tabIndex == 0) {
      key = _bookmarkKey;
    } else if (tabIndex == 1) {
      key = _recentKey;
    } else {
      key = _downloadKey;
    }

    final context = key.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Small delay to allow scroll animation to settle
    await Future.delayed(const Duration(milliseconds: 100));
    _isManualScrolling = false;
  }

  // Tags builder helper
  Widget _buildTag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          color: textCol,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Bottom details helper
  Widget _buildBottomDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Bookmarked Scheme Card (recreating the mockup)
  Widget _buildBookmarkedCard(BuildContext context, Scheme scheme, AppProvider provider) {
    Color iconColor;
    Color iconBgColor;
    IconData icon;

    switch (scheme.category) {
      case 'Education':
        icon = Icons.school;
        iconColor = const Color(0xFF16A34A);
        iconBgColor = const Color(0xFFDCFCE7);
        break;
      case 'Women & Child Welfare':
        icon = Icons.family_restroom;
        iconColor = const Color(0xFFD81B60);
        iconBgColor = const Color(0xFFFCE4EC);
        break;
      case 'Housing':
        icon = Icons.home_outlined;
        iconColor = const Color(0xFF2563EB);
        iconBgColor = const Color(0xFFDBEAFE);
        break;
      default:
        icon = Icons.article_outlined;
        iconColor = const Color(0xFF475569);
        iconBgColor = const Color(0xFFF1F5F9);
    }

    String benefitText = 'Up to ₹1,00,000';
    String targetText = 'Students';
    String deadlineText = 'Apply by 31 Nov 2024';

    if (scheme.id == 'PM_MATRU_VANDANA') {
      benefitText = '₹5,000 per installment';
      targetText = 'Women';
      deadlineText = 'Apply by 31 Dec 2024';
    } else if (scheme.id == 'PM_AWAS') {
      benefitText = 'Up to ₹2,50,000';
      targetText = 'Families';
      deadlineText = 'Apply by 30 Jun 2025';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          provider.addToRecentlyViewed(scheme.id);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SchemeDetailsScreen(scheme: scheme)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheme.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildTag(scheme.category, const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
                            _buildTag('Central Scheme', const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
                            _buildTag('Active', const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark, color: Color(0xFF2563EB)),
                        onPressed: () => provider.toggleBookmark(scheme.id),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B), size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied to clipboard!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                scheme.overview,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildBottomDetailItem(Icons.currency_rupee, benefitText),
                  _buildBottomDetailItem(Icons.people_outline, targetText),
                  _buildBottomDetailItem(Icons.calendar_today_outlined, deadlineText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recently Viewed Card Widget
  Widget _buildRecentlyViewedCard(BuildContext context, Scheme scheme, AppProvider provider) {
    Color iconColor;
    Color iconBgColor;
    IconData icon;

    switch (scheme.category) {
      case 'Education':
        icon = Icons.school;
        iconColor = const Color(0xFF16A34A);
        iconBgColor = const Color(0xFFDCFCE7);
        break;
      case 'Transport':
        icon = Icons.two_wheeler_outlined;
        iconColor = const Color(0xFFEA580C);
        iconBgColor = const Color(0xFFFFEDD5);
        break;
      case 'Health':
      case 'Healthcare':
        icon = Icons.favorite_border;
        iconColor = const Color(0xFFE11D48);
        iconBgColor = const Color(0xFFFFE4E6);
        break;
      default:
        icon = Icons.business_center_outlined;
        iconColor = const Color(0xFF7C3AED);
        iconBgColor = const Color(0xFFF3E8FF);
    }

    String timeText = '2 mins ago';
    if (scheme.id == 'PM_EDRIVE') {
      timeText = '1 hour ago';
    } else if (scheme.id == 'AYUSHMAN_BHARAT') {
      timeText = '3 hours ago';
    } else if (scheme.id == 'MUDRA') {
      timeText = 'Yesterday';
    }

    String shortTitle = scheme.name;
    if (scheme.id == 'NSP_PORTAL') shortTitle = 'National Scholarship\nPortal (NSP)';
    if (scheme.id == 'PM_EDRIVE') shortTitle = 'PM E-DRIVE\nScheme';
    if (scheme.id == 'AYUSHMAN_BHARAT') shortTitle = 'Ayushman Bharat\nYojana';
    if (scheme.id == 'MUDRA') shortTitle = 'PM Mudra\nYojana';

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          provider.addToRecentlyViewed(scheme.id);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SchemeDetailsScreen(scheme: scheme)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  shortTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              _buildTag(scheme.category, iconBgColor.withValues(alpha: 0.5), iconColor),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Download Document Item Widget
  Widget _buildDownloadItem(BuildContext context, Map<String, dynamic> doc, AppProvider provider) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.picture_as_pdf, color: Color(0xFFD32F2F), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['title'] ?? '',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${doc['fileType'] ?? 'PDF'} • ${doc['size'] ?? '1.0 MB'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc['date'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download_done, color: Color(0xFF16A34A), size: 18),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                if (value == 'delete') {
                  provider.removeDownloadedDoc(doc['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted "${doc['title']}"'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } else if (value == 'open') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening PDF file...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, size: 18),
                      SizedBox(width: 8),
                      Text('Open File'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Color(0xFFD32F2F)),
                      SizedBox(width: 8),
                      Text('Delete Guide', style: TextStyle(color: Color(0xFFD32F2F))),
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

  // Section header builder helper
  Widget _buildSectionHeader({
    required GlobalKey key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onViewAll,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 14, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Empty state placeholder builder helper
  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // View All Bottom Sheets
  void _showViewAllBottomSheet(BuildContext context, String title, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final bookmarks = provider.bookmarkedSchemes;
    final recentlyViewed = provider.recentlyViewedSchemes;
    final downloads = provider.downloadedDocs;
    final unreadCount = provider.notifications.where((n) => !n['read']).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => provider.updateTabIndex(0),
        ),
        titleSpacing: 8,
        title: Text(
          'Saved Schemes',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0F172A), size: 24),
            onPressed: () => provider.updateTabIndex(2),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF0D47A1),
                      size: 24,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        alignment: Alignment.center,
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle fully visible at the top of the body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              "All the schemes you've saved, viewed and downloaded",
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          // Segmented styled TabBar
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF2563EB),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal),
              onTap: _scrollToSection,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline, size: 14),
                      SizedBox(width: 6),
                      Text('Bookmarked Schemes'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14),
                      SizedBox(width: 6),
                      Text('Recently Viewed'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_download_outlined, size: 14),
                      SizedBox(width: 6),
                      Text('Downloaded Information'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable sections
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Bookmarked Schemes Section
                  _buildSectionHeader(
                    key: _bookmarkKey,
                    icon: Icons.bookmark_outline,
                    title: 'Bookmarked Schemes',
                    subtitle: 'Schemes you have bookmarked',
                    onViewAll: () => _showViewAllBottomSheet(
                      context,
                      'Bookmarked Schemes',
                      bookmarks.isEmpty
                          ? _buildEmptyState(Icons.bookmark_outline, 'No bookmarked schemes yet')
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: bookmarks.length,
                              itemBuilder: (context, idx) => _buildBookmarkedCard(context, bookmarks[idx], provider),
                            ),
                    ),
                  ),
                  if (bookmarks.isEmpty)
                    _buildEmptyState(Icons.bookmark_outline, 'No bookmarked schemes yet')
                  else
                    ...bookmarks.take(3).map((s) => _buildBookmarkedCard(context, s, provider)),

                  // Recently Viewed Section
                  _buildSectionHeader(
                    key: _recentKey,
                    icon: Icons.access_time,
                    title: 'Recently Viewed',
                    subtitle: 'Schemes you viewed recently',
                    onViewAll: () => _showViewAllBottomSheet(
                      context,
                      'Recently Viewed Schemes',
                      recentlyViewed.isEmpty
                          ? _buildEmptyState(Icons.access_time, 'No recently viewed schemes yet')
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.88, // Adjusted to prevent vertical overflow on narrow screens
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: recentlyViewed.length,
                              itemBuilder: (context, idx) => _buildRecentlyViewedCard(context, recentlyViewed[idx], provider),
                            ),
                    ),
                  ),
                  if (recentlyViewed.isEmpty)
                    _buildEmptyState(Icons.access_time, 'No recently viewed schemes yet')
                  else
                    SizedBox(
                      height: 155, // Increased from 145 to prevent vertical card title overflow
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        scrollDirection: Axis.horizontal,
                        itemCount: recentlyViewed.length,
                        itemBuilder: (context, index) {
                          return _buildRecentlyViewedCard(context, recentlyViewed[index], provider);
                        },
                      ),
                    ),

                  // Downloaded Information Section
                  _buildSectionHeader(
                    key: _downloadKey,
                    icon: Icons.file_download_outlined,
                    title: 'Downloaded Information',
                    subtitle: 'Information you have downloaded',
                    onViewAll: () => _showViewAllBottomSheet(
                      context,
                      'Downloaded Information',
                      downloads.isEmpty
                          ? _buildEmptyState(Icons.file_download_outlined, 'No downloaded guides yet')
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: downloads.length,
                              itemBuilder: (context, idx) => _buildDownloadItem(context, downloads[idx], provider),
                            ),
                    ),
                  ),
                  if (downloads.isEmpty)
                    _buildEmptyState(Icons.file_download_outlined, 'No downloaded guides yet')
                  else
                    ...downloads.take(3).map((doc) => _buildDownloadItem(context, doc, provider)),

                  // Large padding block to ensure scroll-spy reaches the bottom tab smoothly
                  const SizedBox(height: 320),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
