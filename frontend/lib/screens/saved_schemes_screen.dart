import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/scheme_card.dart';
import '../providers/app_state_provider.dart';
import '../models/scheme_model.dart';
import '../utils/constants.dart';
import 'scheme_details_screen.dart';

class SavedSchemesScreen extends StatefulWidget {
  const SavedSchemesScreen({super.key});

  @override
  State<SavedSchemesScreen> createState() => _SavedSchemesScreenState();
}

class _SavedSchemesScreenState extends State<SavedSchemesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final bookmarks = provider.bookmarkedSchemes;
    final recentlyViewed = provider.recentlyViewedSchemes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Saved Schemes', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: AppConstants.secondaryText,
          tabs: const [
            Tab(text: 'Bookmarked'),
            Tab(text: 'Recently Viewed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSchemesList(provider, bookmarks, 'No bookmarked schemes yet'),
          _buildSchemesList(provider, recentlyViewed, 'No recently viewed schemes yet'),
        ],
      ),
    );
  }

  Widget _buildSchemesList(AppProvider provider, List<Scheme> schemes, String emptyMsg) {
    if (schemes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline, size: 60, color: AppConstants.secondaryText.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: const TextStyle(color: AppConstants.secondaryText, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final scheme = schemes[index];
        // Fetch matching eligibility score
        final result = provider.recommendedSchemes.firstWhere((e) => e.key.id == scheme.id).value;
        
        return SchemeCard(
          scheme: scheme,
          result: result,
          isBookmarked: provider.bookmarkedIds.contains(scheme.id),
          onBookmarkToggle: () => provider.toggleBookmark(scheme.id),
          onTap: () {
            provider.addToRecentlyViewed(scheme.id);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
        );
      },
    );
  }
}
