import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import 'login_screen.dart';
import 'companion_intro_screen.dart';



class NavigationModeScreen extends StatefulWidget {
  const NavigationModeScreen({super.key});

  @override
  State<NavigationModeScreen> createState() => _NavigationModeScreenState();
}

class _NavigationModeScreenState extends State<NavigationModeScreen> {
  String _selectedMode = 'regular'; // 'regular', 'companion'

  Widget _buildSmartphoneIllustration() {
    return Container(
      width: 56,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notch
          Center(
            child: Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Search box
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: const [
                SizedBox(width: 3),
                Icon(Icons.search, size: 5, color: Color(0xFF2563EB)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Grid
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 0.3),
                    ),
                    child: const Center(
                      child: Icon(Icons.account_balance_rounded, size: 8, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 0.3),
                    ),
                    child: const Center(
                      child: Icon(Icons.bookmark_rounded, size: 8, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRobotIllustration() {
    return SizedBox(
      width: 56,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              shape: BoxShape.circle,
            ),
          ),
          // Headset arc
          Positioned(
            top: 22,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF97316), width: 2.0),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Head mask
          Positioned(
            top: 27,
            child: Container(
              width: 34,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: Container(
                width: 26,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ears
          Positioned(
            left: 7,
            top: 31,
            child: Container(
              width: 5,
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(1.5)),
            ),
          ),
          Positioned(
            right: 7,
            top: 31,
            child: Container(
              width: 5,
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(1.5)),
            ),
          ),
          // Speaking Volume
          Positioned(
            right: 3,
            top: 17,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up_rounded, size: 6, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String modeCode,
    required String title,
    required String subtitle,
    required List<String> features,
    required Widget illustration,
    required Color primaryColor,
    required Color bgColor,
    required Color featureIconBgColor,
  }) {
    final isSelected = _selectedMode == modeCode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = modeCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Illustration
                  illustration,
                  const SizedBox(width: 14),
                  // Right: Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? primaryColor : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Features
                        ...features.map((feature) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: featureIconBgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 8,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Continue button (only shown when selected)
                        if (isSelected) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 110,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                elevation: 0,
                              ),
                              onPressed: () {
                                final provider = Provider.of<AppProvider>(context, listen: false);
                                provider.changeNavigationMode(modeCode);
                                if (modeCode == 'companion') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CompanionIntroScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Circular Selection Circle in Top-Right
            Positioned(
              top: 12,
              right: 12,
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mode selection bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Main layout content
          SafeArea(
            child: Column(
              children: [
                // Top Nav Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Back button (arrow only)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Logo (Logo.png, bigger, directly rendered)
                Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      children: const [
                        TextSpan(text: 'Welcome to '),
                        TextSpan(
                          text: 'IN Schemes',
                          style: TextStyle(color: Color(0xFF0D47A1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'How would you like to use the app?',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 30, height: 1.5, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(width: 30, height: 1.5, color: const Color(0xFFCBD5E1)),
                  ],
                ),
                const SizedBox(height: 12),

                // Cards
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Card 1: Regular Navigation
                      _buildOptionCard(
                        modeCode: 'regular',
                        title: 'Regular Navigation',
                        subtitle: 'Browse and explore the app yourself.',
                        features: [
                          'Traditional mobile experience',
                          'Faster navigation',
                          'AI available whenever you need help',
                        ],
                        illustration: _buildSmartphoneIllustration(),
                        primaryColor: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                        featureIconBgColor: const Color(0xFFDBEAFE),
                      ),

                      // Card 2: Companion Navigation
                      _buildOptionCard(
                        modeCode: 'companion',
                        title: 'Companion Navigation',
                        subtitle: 'Let your AI Companion guide you step by step.',
                        features: [
                          'Voice-first experience',
                          'Personalized guidance',
                          'Smart recommendations',
                          'Explains every screen',
                        ],
                        illustration: _buildRobotIllustration(),
                        primaryColor: const Color(0xFFF97316),
                        bgColor: const Color(0xFFFFF7ED),
                        featureIconBgColor: const Color(0xFFFFEDD5),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Info Box Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF1D4ED8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You can switch between these modes anytime from Settings or the Home screen.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }
}

