import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/floating_logo.dart';
import '../login_screen.dart';

class LanguageOption {
  final String code;
  final String nativeTitle;
  final String englishTitle;
  final String circleText;
  final Color circleBgColor;
  final Color circleTextColor;

  const LanguageOption({
    required this.code,
    required this.nativeTitle,
    required this.englishTitle,
    required this.circleText,
    required this.circleBgColor,
    required this.circleTextColor,
  });
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'en';

  final List<LanguageOption> _languages = const [
    LanguageOption(
      code: 'en',
      nativeTitle: 'English',
      englishTitle: 'English',
      circleText: 'EN',
      circleBgColor: Color(0xFFEFF6FF), // Blue 50
      circleTextColor: Color(0xFF1D4ED8), // Blue 700
    ),
    LanguageOption(
      code: 'ta',
      nativeTitle: 'தமிழ்',
      englishTitle: 'Tamil',
      circleText: 'தமிழ்',
      circleBgColor: Color(0xFFECFDF5), // Emerald 50
      circleTextColor: Color(0xFF047857), // Emerald 700
    ),
    LanguageOption(
      code: 'hi',
      nativeTitle: 'हिंदी',
      englishTitle: 'Hindi',
      circleText: 'हिंदी',
      circleBgColor: Color(0xFFF5F3FF), // Purple 50
      circleTextColor: Color(0xFF6D28D9), // Purple 700
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      setState(() {
        _selectedLang = provider.selectedLanguage;
      });
    });
  }

  void _onLanguageSelected(String langCode) {
    setState(() {
      _selectedLang = langCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image from Asset
          Positioned.fill(
            child: Image.asset(
              'assets/images/Login_bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Main content structure (No scrolling)
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),

                    // 3. Isolated Floating Logo
                    const FloatingLogo(),
                    
                    const Spacer(flex: 2),
                    
                    // 4. Title & Subtitle
                    Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B), // Slate 800
                            ),
                            children: const [
                              TextSpan(text: 'Choose Your '),
                              TextSpan(
                                text: 'Language',
                                style: TextStyle(
                                  color: Color(0xFF2563EB), // Premium Blue Accent
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your preferred language to explore government schemes in your language.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B), // Slate 500
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // 5. Restricted Language List (English, Tamil, Hindi)
                    Column(
                      children: _languages.map((option) {
                        final isSelected = _selectedLang == option.code;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildLanguageItem(option, isSelected),
                        );
                      }).toList(),
                    ),

                    const Spacer(flex: 1),

                    // 6. Info Box Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Blue 50
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)), // Blue 200
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFDBEAFE),
                            ),
                            child: const Icon(
                              Icons.language,
                              color: Color(0xFF2563EB), // Blue 600
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Language, Your Experience',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E3A8A), // Blue 900
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Change it anytime from Settings.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF1D4ED8), // Blue 700
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // 7. Continue Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1), // Royal Blue
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: () {
                          provider.changeLanguage(_selectedLang);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
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
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(LanguageOption option, bool isSelected) {
    return InkWell(
      onTap: () => _onLanguageSelected(option.code),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0), // Blue 500 or Slate 200
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Colored circle with native symbol/text
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: option.circleBgColor,
              ),
              alignment: Alignment.center,
              child: Text(
                option.circleText,
                style: TextStyle(
                  fontSize: option.circleText.length > 3 ? 10 : 13,
                  fontWeight: FontWeight.bold,
                  color: option.circleTextColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.nativeTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A), // Slate 900
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.englishTitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B), // Slate 500
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator (Checked circle vs empty circle)
            isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2563EB),
                    size: 22,
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCBD5E1), // Slate 300
                        width: 1.5,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}


