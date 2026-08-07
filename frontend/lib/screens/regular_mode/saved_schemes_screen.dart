import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../l10n/l10n.dart';
import 'scheme_details_screen.dart';
import '../../utils/responsive.dart';

class SavedSchemesScreen extends StatefulWidget {
  const SavedSchemesScreen({super.key});

  @override
  State<SavedSchemesScreen> createState() => _SavedSchemesScreenState();
}

class _SavedSchemesScreenState extends State<SavedSchemesScreen> {
  int _activeTab = 0; // 0 = All Saved, 1 = Recently Added
  bool _isManageMode = false;

  Widget _buildFolderIllustration() {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Folder icon
          const Icon(Icons.folder_rounded, color: Color(0xFF3B82F6), size: 38),
          // Heart icon layered on folder
          Positioned(
            right: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFF2563EB),
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int savedCount) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isTa = provider.selectedLanguage == 'ta';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isTa ? 12 : 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    context.l10n.allSavedTabFormat(savedCount),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: isTa ? 10.5 : 11.5,
                      fontWeight: FontWeight.bold,
                      color: _activeTab == 0
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isTa ? 12 : 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    context.l10n.recentlyAddedTab,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: isTa ? 10.5 : 11.5,
                      fontWeight: FontWeight.bold,
                      color: _activeTab == 1
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(
    BuildContext context,
    Scheme scheme,
    AppProvider provider,
  ) {
    final locScheme = scheme.toLocalized(provider.selectedLanguage);
    IconData iconData = Icons.rocket_launch_rounded;
    Color iconColor = const Color(0xFF2563EB);
    Color iconBgColor = const Color(0xFFEFF6FF);

    if (scheme.category.toLowerCase().contains('loan') ||
        scheme.category.toLowerCase().contains('business') ||
        scheme.category.toLowerCase().contains('finance') ||
        scheme.category.toLowerCase().contains('msme')) {
      iconData = Icons.currency_rupee_rounded;
      iconColor = const Color(0xFF2563EB);
      iconBgColor = const Color(0xFFEFF6FF);
    } else if (scheme.category.toLowerCase().contains('guarantee') ||
        scheme.category.toLowerCase().contains('cgtmse')) {
      iconData = Icons.shield_outlined;
      iconColor = const Color(0xFF16A34A);
      iconBgColor = const Color(0xFFF0FDF4);
    } else {
      iconData = Icons.article_rounded;
      iconColor = const Color(0xFF2563EB);
      iconBgColor = const Color(0xFFEFF6FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locScheme.name,
                        style: GoogleFonts.inter(
                          fontSize: provider.selectedLanguage == 'ta'
                              ? 12.5
                              : 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          height: provider.selectedLanguage == 'ta'
                              ? 1.35
                              : 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        locScheme.category,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isManageMode
                        ? IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            onPressed: () {
                              provider.toggleBookmark(scheme.id);
                            },
                          )
                        : PopupMenuButton<String>(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            onSelected: (value) {
                              if (value == 'remove') {
                                provider.toggleBookmark(scheme.id);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(
                                  provider.selectedLanguage == 'ta'
                                      ? 'சேமிக்கப்பட்டதை நீக்கு'
                                      : 'Remove Saved',
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              locScheme.overview,
              style: GoogleFonts.inter(
                fontSize: 11.0,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Icon(
                        Icons.bookmark_added_outlined,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      Text(
                        locScheme.governmentLevel,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(
                        Icons.local_offer_outlined,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      Text(
                        locScheme.schemeType.isNotEmpty
                            ? locScheme.schemeType
                            : locScheme.category,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SchemeDetailsScreen(scheme: scheme),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FitOneLine(
                          child: Text(
                            provider.selectedLanguage == 'ta'
                                ? 'விவரங்களைப் பார்க்க'
                                : 'View Details',
                            style: GoogleFonts.inter(
                              fontSize: 10.0,
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 11,
                        color: Color(0xFF2563EB),
                      ),
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

  Widget _buildManageListBanner() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Keep your list updated!",
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Remove schemes you're no longer interested in.",
                  style: GoogleFonts.inter(
                    fontSize: 10.0,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isManageMode = !_isManageMode;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: Icon(
              _isManageMode
                  ? Icons.check_circle_outline_rounded
                  : Icons.delete_outline_rounded,
              color: _isManageMode
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF2563EB),
              size: 13,
            ),
            label: Text(
              _isManageMode
                  ? context.l10n.doneManaging
                  : context.l10n.manageSaved,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: _isManageMode
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: Color(0xFF94A3B8),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noSavedSchemes,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.noSavedSchemesDesc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                provider.updateTabIndex(2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                context.l10n.navDiscover,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

    final List<Scheme> displaySchemes = _activeTab == 0
        ? bookmarks
        : recentlyViewed;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.savedTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.noSavedSchemesDesc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFolderIllustration(),
                ],
              ),
            ),
            _buildTabBar(bookmarks.length),
            Expanded(
              child: displaySchemes.isEmpty
                  ? _buildEmptyState(context, provider)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: displaySchemes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == displaySchemes.length) {
                          return _buildManageListBanner();
                        }
                        return _buildSchemeCard(
                          context,
                          displaySchemes[index],
                          provider,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
