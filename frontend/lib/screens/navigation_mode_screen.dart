import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'companion_mode/saarthi_welcome_screen.dart';
import 'regular_mode/language_selection_screen.dart';
import 'regular_mode/basic_profile_screen.dart';
import '../providers/app_state_provider.dart';

enum NavigationMode { regular, companion }

class NavigationModeScreen extends StatefulWidget {
  final Function(NavigationMode)? onContinue;

  const NavigationModeScreen({
    super.key,
    this.onContinue,
  });

  @override
  State<NavigationModeScreen> createState() => _NavigationModeScreenState();
}

class _NavigationModeScreenState extends State<NavigationModeScreen> {
  NavigationMode _selectedMode = NavigationMode.regular;

  // Constants for design consistency
  static const double kPaddingSide = 24.0;
  static const double kCardRadius = 28.0;
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate800 = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/Login_bg.webp', // Using webp asset from the project
              fit: BoxFit.cover,
            ),
          ),

          // 2. Foreground Layer
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button (Top Left)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: kSlate800, size: 24),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LanguageSelectionScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Middle Content (Flexibly fits the remaining height, strictly no scrolling)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kPaddingSide),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Tighter distribution
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // App Logo (Maintained at height 80 as in language selection screen)
                          Image.asset(
                            'assets/images/Logo.png',
                            height: 80,
                            fit: BoxFit.contain,
                          ),

                          // Header Text Group
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontSize: 22, // Slightly reduced
                                    fontWeight: FontWeight.bold,
                                    color: kSlate800,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Choose Your '),
                                    TextSpan(
                                      text: 'Experience',
                                      style: TextStyle(color: kPrimaryBlue),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select the navigation style that best suits you.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5, // Slightly reduced
                                  color: kSlate500,
                                ),
                              ),
                            ],
                          ),

                          // Option Cards Group (Tightly clustered together)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Option Card 1: Regular Navigation
                              NavigationOptionCard(
                                mode: NavigationMode.regular,
                                isSelected: _selectedMode == NavigationMode.regular,
                                title: 'Regular Navigation',
                                subtitle: 'Browse and explore the app independently.',
                                icon: Icons.explore_rounded,
                                iconColor: kPrimaryBlue,
                                iconBgColor: const Color(0xFFEFF6FF),
                                chips: const [
                                  ChipInfo(Icons.bolt, 'Fast & Simple'),
                                  ChipInfo(Icons.phone_android, 'Traditional UI'),
                                  ChipInfo(Icons.touch_app, 'Self-paced browsing'), // 4th balancing chip
                                  ChipInfo(Icons.auto_awesome, 'AI available anytime'),
                                ],
                                onTap: () {
                                  setState(() {
                                    _selectedMode = NavigationMode.regular;
                                  });
                                },
                              ),
                              
                              const SizedBox(height: 8), // Closer spacing between cards

                              // Option Card 2: AI Companion
                              NavigationOptionCard(
                                mode: NavigationMode.companion,
                                isSelected: _selectedMode == NavigationMode.companion,
                                title: 'AI Companion',
                                subtitle: 'Let your AI guide you step by step.',
                                icon: Icons.support_agent_rounded,
                                iconColor: const Color(0xFFEA580C),
                                iconBgColor: const Color(0xFFFFF7ED),
                                chips: const [
                                  ChipInfo(Icons.mic, 'Voice-first experience'),
                                  ChipInfo(Icons.person, 'Personalized guidance'),
                                  ChipInfo(Icons.lightbulb_outline, 'Smart recommendations'),
                                  ChipInfo(Icons.co_present, 'Explains every screen'),
                                ],
                                onTap: () {
                                  setState(() {
                                    _selectedMode = NavigationMode.companion;
                                  });
                                },
                              ),
                            ],
                          ),

                          // Info Card (Compact padding/height)
                          const InfoCard(
                            title: 'Switch Anytime',
                            description: 'You can change your navigation mode later from Settings.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Navigation Bar Area for Sticky Button
                  Container(
                    color: Colors.transparent, // Background waves must remain visible
                    padding: const EdgeInsets.only(bottom: 16.0, top: 10.0),
                    alignment: Alignment.center,
                    child: PrimaryButton(
                      width: screenWidth * 0.78, // Width is ~78% of screen width
                      onPressed: () {
                        final provider = Provider.of<AppProvider>(context, listen: false);
                        provider.changeNavigationMode(
                          _selectedMode == NavigationMode.companion ? 'companion' : 'regular',
                        );

                        if (widget.onContinue != null) {
                          widget.onContinue!(_selectedMode);
                        } else {
                          // Default UI transition flow
                          if (_selectedMode == NavigationMode.companion) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SaarthiWelcomeScreen(),
                              ),
                            );
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const BasicProfileScreen(),
                              ),
                            );
                          }
                        }
                      },
                    ),
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

class NavigationOptionCard extends StatelessWidget {
  final NavigationMode mode;
  final bool isSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final List<ChipInfo> chips;
  final VoidCallback onTap;

  const NavigationOptionCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = mode == NavigationMode.regular ? const Color(0xFF2563EB) : const Color(0xFFF97316);
    final activeBg = mode == NavigationMode.regular ? const Color(0xFFF0F5FF) : const Color(0xFFFFF7ED);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0), // Reduced card padding
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(_NavigationModeScreenState.kCardRadius), // Radius 28
          border: Border.all(
            color: isSelected ? activeColor : _NavigationModeScreenState.kBorderGrey,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content layout (Row)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Illustration / Icon on the left (Slightly smaller padding)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24, // Slightly smaller
                  ),
                ),
                const SizedBox(width: 12),

                // Middle Text & Chips Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15.5, // Tighter font sizing
                          fontWeight: FontWeight.bold,
                          color: _NavigationModeScreenState.kSlate800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.5, // Tighter font sizing
                          color: _NavigationModeScreenState.kSlate500,
                        ),
                      ),
                      const SizedBox(height: 8), // Tighter spacing

                      // Vertical Layout for Feature Chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < chips.length; i++) ...[
                            if (i > 0) const SizedBox(height: 4), // Reduced chip spacing
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : iconBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(chips[i].icon, color: iconColor, size: 9),
                                  const SizedBox(width: 4),
                                  Text(
                                    chips[i].label,
                                    style: GoogleFonts.inter(
                                      fontSize: 10, // Compact chip size
                                      fontWeight: FontWeight.w600,
                                      color: iconColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),

            // Radio Button in top right corner
            Positioned(
              top: 0,
              right: 0,
              child: isSelected
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String description;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // More compact padding
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Blue tinted background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF2563EB),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13, // Slightly more compact
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11, // Slightly more compact
                    color: const Color(0xFF1D4ED8),
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
  }
}

class PrimaryButton extends StatelessWidget {
  final double width;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.width,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 58, // Height is exactly 58 as specified
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Large radius
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // Blue filled
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ChipInfo {
  final IconData icon;
  final String label;

  const ChipInfo(this.icon, this.label);
}


