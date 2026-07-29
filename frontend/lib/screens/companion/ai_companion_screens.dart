import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import 'search_results_screen.dart';
import 'custom_navigation_drawer.dart';

// Brand colors matching the app palette
const Color kBrandOrange = Color(0xFFEA580C);
const Color kBrandOrangeLight = Color(0xFFFFF7ED);
const Color kDarkSlate = Color(0xFF0F172A);
const Color kSlate500 = Color(0xFF64748B);
const Color kGreyBorder = Color(0xFFE2E8F0);

class AiCompanionHomeScreen extends StatefulWidget {
  const AiCompanionHomeScreen({super.key});

  @override
  State<AiCompanionHomeScreen> createState() => _AiCompanionHomeScreenState();
}

class _AiCompanionHomeScreenState extends State<AiCompanionHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: const CustomNavigationDrawer(activeItem: 'Home'),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Fixed & Centered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hamburger Menu Button
                  Builder(
                    builder: (context) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: kDarkSlate, size: 18),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      );
                    }
                  ),
                  
                  // Center Title & Soundwave
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "✨ AI Companion Mode",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kDarkSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Soundwave graphic mimic
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(15, (index) {
                          final double height = [4, 10, 16, 12, 6, 14, 20, 12, 16, 8, 14, 10, 6, 12, 4][index].toDouble();
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 2.5,
                            height: height,
                            decoration: BoxDecoration(
                              color: kBrandOrange,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  // Counters-balance SizedBox to align title perfectly in the center
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // 2. Hero Section (Avatar & Bubbles)
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Large glowing circular gradient in the center-right
                  // Large glowing circular gradient in the center-right
                  Positioned(
                    right: -30,
                    top: 0,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kBrandOrange.withValues(alpha: 0.18),
                            kBrandOrange.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Floating Text (Top Left)
                  Positioned(
                    left: 20,
                    top: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, I'm",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: kDarkSlate,
                          ),
                        ),
                        Text(
                          "Saarthi",
                          style: GoogleFonts.inter(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: kBrandOrange,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 160,
                          child: Text(
                            "Your AI guide for finding the right MSME schemes.",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: kSlate500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3D Saarthi Avatar image positioned in the center/right
                  Positioned(
                    right: -10,
                    top: -5,
                    bottom: -20,
                    child: Image.asset(
                      'assets/saarthi_expressions/01_happy.png',
                      width: 215,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kBrandOrange.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            size: 70,
                            color: kBrandOrange,
                          ),
                        );
                      },
                    ),
                  ),

                  // Floating Chat Bubble (Middle Left)
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: kGreyBorder.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.volume_up, color: kBrandOrange, size: 12),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "I can help you find schemes, check eligibility, and guide you step by step.",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: kDarkSlate,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Action Area (Center)
            Center(
              child: Text(
                "How can I help you today?",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kDarkSlate,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left: Type instead
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SearchWithSaarthiScreen(),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: kGreyBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.keyboard_outlined, color: kSlate500, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Type instead",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: kSlate500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center: Large glowing mic button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kBrandOrange.withValues(alpha: 0.3),
                            blurRadius: 18,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.mic, color: kBrandOrange, size: 30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap to speak",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: kBrandOrange,
                      ),
                    ),
                  ],
                ),

                // Right: Talk to Saarthi
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: kGreyBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.headset_outlined, color: kSlate500, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Talk to Saarthi",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: kSlate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBrandOrange, width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              icon: const Icon(Icons.search, color: kBrandOrange, size: 14),
              label: Text(
                "Search schemes manually",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: kBrandOrange,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainTabsContainer()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),

            // 4. Suggestions Bottom Sheet (Bottom)
            Container(
              decoration: const BoxDecoration(
                color: kBrandOrangeLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      const Icon(Icons.history, color: kBrandOrange, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "You can ask me things like",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: kDarkSlate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Suggestions list
                  SuggestionTile(
                    icon: Icons.search,
                    iconColor: Colors.purple,
                    iconBgColor: const Color(0xFFF3E8FF),
                    title: "Which scheme is best for my business?",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchResultsScreen(
                            searchQuery: "Which scheme is best for my business?",
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  SuggestionTile(
                    icon: Icons.security,
                    iconColor: Colors.green,
                    iconBgColor: const Color(0xFFDCFCE7),
                    title: "Am I eligible for the NEEDS scheme?",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchResultsScreen(
                            searchQuery: "NEEDS scheme",
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  SuggestionTile(
                    icon: Icons.description,
                    iconColor: Colors.orange,
                    iconBgColor: const Color(0xFFFFEDD5),
                    title: "What documents do I need for registration?",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchResultsScreen(
                            searchQuery: "registration documents",
                          ),
                        ),
                      );
                    },
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

class SuggestionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final VoidCallback? onTap;

  const SuggestionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFEE2E2).withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: kDarkSlate,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: kSlate500, size: 16),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Part 2: SearchWithSaarthiScreen
// -------------------------------------------------------------

class SearchWithSaarthiScreen extends StatefulWidget {
  const SearchWithSaarthiScreen({super.key});

  @override
  State<SearchWithSaarthiScreen> createState() => _SearchWithSaarthiScreenState();
}

class _SearchWithSaarthiScreenState extends State<SearchWithSaarthiScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circular Back Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: kDarkSlate, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Center Title
                  Text(
                    "Search with Saarthi ✨",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kDarkSlate,
                    ),
                  ),

                  // Voice Tips Action button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: kBrandOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: Text(
                      "Voice Tips",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Chat Intro Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saarthi Avatar Headshot
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kBrandOrange.withValues(alpha: 0.4), width: 1.5),
                            image: const DecorationImage(
                              image: AssetImage('assets/saarthi_expressions/01_happy.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Speech Bubble
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kBrandOrangeLight,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border.all(color: const Color(0xFFFEE2E2).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              "Tell me what you're looking for. I'll find the best schemes for you.",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: kDarkSlate,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. Search Input Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: kGreyBorder),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(fontSize: 13, color: kDarkSlate),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SearchResultsScreen(
                                      searchQuery: value.trim(),
                                    ),
                                  ),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "Search anything...",
                              hintStyle: GoogleFonts.inter(color: kSlate500, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: kBrandOrange, size: 18),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, color: kSlate500, size: 16),
                                onPressed: () => _searchController.clear(),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: kGreyBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: kGreyBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: kBrandOrange, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Microphone button below
                          GestureDetector(
                            onTap: () {
                              final query = _searchController.text.trim();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SearchResultsScreen(
                                    searchQuery: query.isNotEmpty ? query : "MSME Scheme",
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: kBrandOrange, width: 1.5),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.mic, color: kBrandOrange, size: 24),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Tap to speak",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: kBrandOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Popular Searches (Wrap)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.whatshot, color: kBrandOrange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Popular Searches",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kDarkSlate,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "View all",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: kBrandOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PopularSearchPill(
                          icon: Icons.business_center,
                          iconColor: Colors.purple,
                          label: "MSME Loan",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "MSME Loan",
                              ),
                            ),
                          ),
                        ),
                        PopularSearchPill(
                          icon: Icons.person,
                          iconColor: Colors.pink,
                          label: "Women Entrepreneur",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "Women Entrepreneur",
                              ),
                            ),
                          ),
                        ),
                        PopularSearchPill(
                          icon: Icons.precision_manufacturing,
                          iconColor: Colors.orange,
                          label: "Manufacturing",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "Manufacturing",
                              ),
                            ),
                          ),
                        ),
                        PopularSearchPill(
                          icon: Icons.rocket_launch,
                          iconColor: Colors.green,
                          label: "Startup",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "Startup",
                              ),
                            ),
                          ),
                        ),
                        PopularSearchPill(
                          icon: Icons.location_city,
                          iconColor: Colors.blue,
                          label: "Tamil Nadu",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "Tamil Nadu",
                              ),
                            ),
                          ),
                        ),
                        PopularSearchPill(
                          icon: Icons.card_giftcard,
                          iconColor: Colors.deepPurple,
                          label: "Subsidy",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                  searchQuery: "Subsidy",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // 5. Recent Searches (List)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history, color: kBrandOrange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Recent Searches",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kDarkSlate,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Clear all",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: kBrandOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        RecentSearchRow(
                          query: "PMEGP scheme",
                          timeAgo: "2 hours ago",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "PMEGP scheme",
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: kGreyBorder),
                        RecentSearchRow(
                          query: "NEEDS scheme eligibility",
                          timeAgo: "Yesterday",
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "NEEDS scheme eligibility",
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: kGreyBorder),
                        RecentSearchRow(
                          query: "Mudra loan for business",
                          timeAgo: "2 days ago",
                          isLast: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchResultsScreen(
                                searchQuery: "Mudra loan for business",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 6. Bottom Tip Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBrandOrangeLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFEE2E2).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lightbulb, color: kBrandOrange, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "You can ask in your own words too!",
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: kDarkSlate,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "“Loans for women entrepreneurs in Tamil Nadu”",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: kSlate500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/saarthi_expressions/01_happy.png'),
                                fit: BoxFit.contain,
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
}

class PopularSearchPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const PopularSearchPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreyBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: kDarkSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentSearchRow extends StatelessWidget {
  final String query;
  final String timeAgo;
  final bool isLast;
  final VoidCallback? onTap;

  const RecentSearchRow({
    super.key,
    required this.query,
    required this.timeAgo,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: 10.0,
          bottom: isLast ? 0.0 : 10.0,
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: kBrandOrange, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kDarkSlate,
                ),
              ),
            ),
            Text(
              timeAgo,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: kSlate500,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.close, color: kSlate500, size: 14),
          ],
        ),
      ),
    );
  }
}
