import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scheme_model.dart';
import '../engine/recommendation_engine.dart';

class SchemeCard extends StatelessWidget {
  final Scheme scheme;
  final RecommendationResult result;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.result,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTap,
  });

  Map<String, dynamic> _getCategoryStyle(String category, String id) {
    switch (id) {
      case 'POST_MATRIC':
        return {
          'icon': Icons.school_outlined,
          'iconColor': const Color(0xFF137C47), // Green
          'backgroundColor': const Color(0xFFE8F5E9), // Light Green
        };
      case 'MERIT_MEANS':
        return {
          'icon': Icons.currency_rupee_outlined,
          'iconColor': const Color(0xFFEA580C), // Orange
          'backgroundColor': const Color(0xFFFFF7ED), // Light Orange
        };
      case 'INSPIRE':
        return {
          'icon': Icons.local_library_outlined,
          'iconColor': const Color(0xFF7C3AED), // Purple
          'backgroundColor': const Color(0xFFF5F3FF), // Light Purple
        };
      case 'PRAGATI':
        return {
          'icon': Icons.laptop_chromebook_outlined,
          'iconColor': const Color(0xFF2563EB), // Blue
          'backgroundColor': const Color(0xFFEFF6FF), // Light Blue
        };
    }
    switch (category.toLowerCase()) {
      case 'agriculture':
        return {
          'icon': Icons.grass_outlined,
          'iconColor': const Color(0xFF16A34A), // Green 600
          'backgroundColor': const Color(0xFFF0FDF4), // Green 50
        };
      case 'scholarship':
        return {
          'icon': Icons.school_outlined,
          'iconColor': const Color(0xFFF43F5E), // Rose 500
          'backgroundColor': const Color(0xFFFFF1F2), // Rose 50
        };
      case 'education':
        return {
          'icon': Icons.book_outlined,
          'iconColor': const Color(0xFF16A34A), // Green 600
          'backgroundColor': const Color(0xFFF0FDF4), // Green 50
        };
      case 'healthcare':
        return {
          'icon': Icons.favorite_border_outlined,
          'iconColor': const Color(0xFFD32F2F),
          'backgroundColor': const Color(0xFFFFEBEE),
        };
      case 'housing':
        return {
          'icon': Icons.home_outlined,
          'iconColor': const Color(0xFFEA580C),
          'backgroundColor': const Color(0xFFFFF7ED),
        };
      case 'business':
      case 'employment':
        return {
          'icon': Icons.business_center_outlined,
          'iconColor': const Color(0xFF2563EB),
          'backgroundColor': const Color(0xFFEFF6FF),
        };
      default:
        return {
          'icon': Icons.assignment_outlined,
          'iconColor': const Color(0xFF7C3AED), // Purple 500
          'backgroundColor': const Color(0xFFF5F3FF), // Purple 50
        };
    }
  }

  // Helper method to resolve detailed layout attributes dynamically
  Map<String, String> _getSchemeDetails() {
    // Exact detail strings for the popular schemes shown in the mockup
    final Map<String, Map<String, String>> specialDetails = {
      'NSP': {
        'benefit': 'Up to ₹75,000',
        'target': 'UG, PG, PhD',
        'deadline': 'Apply by 31 Dec 2026',
        'tag1': 'Central Scheme',
        'tag2': 'Education',
        'tag3': 'Students',
      },
      'POST_MATRIC': {
        'benefit': 'Up to ₹1,00,000',
        'target': 'Class 11 to PhD',
        'deadline': 'Apply by 31 Nov 2026',
        'tag1': 'Central Scheme',
        'tag2': 'Education',
        'tag3': 'Students',
      },
      'MERIT_MEANS': {
        'benefit': 'Up to ₹20,000',
        'target': 'UG & PG',
        'deadline': 'Apply by 30 Nov 2026',
        'tag1': 'Central Scheme',
        'tag2': 'Education',
        'tag3': 'Students',
      },
      'INSPIRE': {
        'benefit': 'Up to ₹80,000',
        'target': 'UG (Science)',
        'deadline': 'Apply by 31 Oct 2026',
        'tag1': 'Central Scheme',
        'tag2': 'Education',
        'tag3': 'Students',
      },
      'PRAGATI': {
        'benefit': 'Up to ₹50,000',
        'target': 'Diploma, UG, PG',
        'deadline': 'Apply by 31 Dec 2026',
        'tag1': 'Central Scheme',
        'tag2': 'Education',
        'tag3': 'Women Students',
      },
    };

    if (specialDetails.containsKey(scheme.id)) {
      return specialDetails[scheme.id]!;
    }

    // Default fallbacks based on scheme attributes
    final isCentral = !scheme.sponsoringBody.toLowerCase().contains('tamil nadu') && 
                      !scheme.sponsoringBody.toLowerCase().contains('state');
    return {
      'benefit': scheme.benefits.contains('₹') 
          ? 'Up to ${scheme.benefits.substring(scheme.benefits.indexOf('₹')).split(' ').first}'
          : 'Financial Aid',
      'target': scheme.category.toLowerCase().contains('women') ? 'Women' : 'General',
      'deadline': 'Apply by 31 Dec 2026',
      'tag1': isCentral ? 'Central Scheme' : 'State Scheme',
      'tag2': scheme.category,
      'tag3': 'All Citizens',
    };
  }

  @override
  Widget build(BuildContext context) {
    final catStyle = _getCategoryStyle(scheme.category, scheme.id);
    final details = _getSchemeDetails();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Soft category background color circle with icon (52x52)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: catStyle['backgroundColor'],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    catStyle['icon'],
                    color: catStyle['iconColor'],
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Middle column: Title, tags, description, details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        scheme.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A), // Slate 900
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Row of Pill Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Tag 1 (Scheme Type: Central/State)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // Blue 50
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              details['tag1']!,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB), // Blue 600
                              ),
                            ),
                          ),
                          // Tag 2 (Category)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF), // Purple 50
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              details['tag2']!,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7C3AED), // Purple 600
                              ),
                            ),
                          ),
                          // Tag 3 (Target / Type)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4), // Green 50
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              details['tag3']!,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A), // Green 600
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Overview / Description
                      Text(
                        scheme.overview,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF475569), // Slate 600
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      // Bottom Details row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Detail 1: Rupee icon
                            Row(
                              children: [
                                const Icon(Icons.help_outline, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 3),
                                Text(
                                  details['benefit']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Detail 2: Group icon
                            Row(
                              children: [
                                const Icon(Icons.people_outline, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 3),
                                Text(
                                  details['target']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Detail 3: Calendar icon
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 3),
                                Text(
                                  details['deadline']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                
                // Far Right: Bookmark & Share Actions Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onBookmarkToggle,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDBEAFE)), // Light blue 100
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: const Color(0xFF2563EB), // Blue 600
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // Share Action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sharing "${scheme.name}"...'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDBEAFE)), // Light blue 100
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: Color(0xFF2563EB), // Blue 600
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
