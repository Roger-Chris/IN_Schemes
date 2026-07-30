import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import 'saarthi_profile_setup_screen.dart';

class SaarthiLanguageSelectionScreen extends StatefulWidget {
  const SaarthiLanguageSelectionScreen({super.key});

  @override
  State<SaarthiLanguageSelectionScreen> createState() => _SaarthiLanguageSelectionScreenState();
}

class _SaarthiLanguageSelectionScreenState extends State<SaarthiLanguageSelectionScreen> {
  String _selectedLang = 'en';

  static const Color kBrandBlue = Color(0xFF0D47A1);
  static const Color kDarkSlate = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);


  @override
  void initState() {
    super.initState();
    // Pre-select current language from provider
    final provider = Provider.of<AppProvider>(context, listen: false);
    _selectedLang = provider.selectedLanguage;
  }

  Widget _buildLanguageCard({
    required String code,
    required String title,
    required String subtitle,
    required String circleChar,
    required Color circleBg,
    required Color circleTextColor,
  }) {
    final isSelected = _selectedLang == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLang = code;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kBrandBlue : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.015),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rounded character circle
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                circleChar,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: circleTextColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? kBrandBlue : kDarkSlate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: kSlate500,
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator circle / icon
            isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: kBrandBlue,
                    size: 22,
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 2. Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Section (Texts and Bot)
                    SizedBox(
                      height: screenHeight * 0.26,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background Image grid/gradient
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/companion intro bg.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                          // Waving Robot Image on the right
                          Positioned(
                            right: -10,
                            bottom: -5, // Sit exactly at the bottom of the Stack
                            width: screenWidth * 0.52,
                            child: Image.asset(
                              'assets/saarthi_expressions/Ai companion.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Header Text on the left
                          Positioned(
                            top: 20,
                            left: 20,
                            right: screenWidth * 0.42,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Let's set up\nSaarthi for you",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: kDarkSlate,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Choose your preferred language so Saarthi can talk to you better.",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: kSlate500,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Section Heading: Choose Language
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.language,
                                color: kBrandBlue,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Choose Language",
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: kDarkSlate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: Text(
                              "I will speak in this language",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: kSlate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Language Grid Row (1 per row vertically)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          _buildLanguageCard(
                            code: 'en',
                            title: 'English',
                            subtitle: 'English',
                            circleChar: 'A',
                            circleBg: const Color(0xFFEFF6FF),
                            circleTextColor: kBrandBlue,
                          ),
                          _buildLanguageCard(
                            code: 'ta',
                            title: 'தமிழ்',
                            subtitle: 'Tamil',
                            circleChar: 'அ',
                            circleBg: const Color(0xFFFFF7ED),
                            circleTextColor: const Color(0xFFEA580C),
                          ),
                          _buildLanguageCard(
                            code: 'hi',
                            title: 'हिंदी',
                            subtitle: 'Hindi',
                            circleChar: 'अ', // Fixed character: Hindi Devanagari 'अ'
                            circleBg: const Color(0xFFF0FDF4),
                            circleTextColor: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Info banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: kBrandBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "You can change this anytime in settings.",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: kSlate500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // 3. Action Button and curves at the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                ),
                onPressed: () async {
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  // Update selected language in app state
                  provider.changeLanguage(_selectedLang);

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SaarthiProfileSetupScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Continue",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
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
