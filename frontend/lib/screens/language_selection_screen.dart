import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import 'navigation_mode_screen.dart';



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
      circleText: 'En',
      circleBgColor: Color(0xFFEFF6FF),
      circleTextColor: Color(0xFF1D4ED8),
    ),
    LanguageOption(
      code: 'hi',
      nativeTitle: 'हिंदी',
      englishTitle: 'Hindi',
      circleText: 'हिं',
      circleBgColor: Color(0xFFEFF6FF),
      circleTextColor: Color(0xFF1D4ED8),
    ),
    LanguageOption(
      code: 'ta',
      nativeTitle: 'தமிழ்',
      englishTitle: 'Tamil',
      circleText: 'தமிழ்',
      circleBgColor: Color(0xFFECFDF5),
      circleTextColor: Color(0xFF047857),
    ),
    LanguageOption(
      code: 'te',
      nativeTitle: 'తెలుగు',
      englishTitle: 'Telugu',
      circleText: 'తెలు',
      circleBgColor: Color(0xFFF5F3FF),
      circleTextColor: Color(0xFF6D28D9),
    ),
    LanguageOption(
      code: 'bn',
      nativeTitle: 'বাংলা',
      englishTitle: 'Bengali',
      circleText: 'বাংলা',
      circleBgColor: Color(0xFFFEF3C7),
      circleTextColor: Color(0xFFD97706),
    ),
    LanguageOption(
      code: 'mr',
      nativeTitle: 'मराठी',
      englishTitle: 'Marathi',
      circleText: 'मर',
      circleBgColor: Color(0xFFFEE2E2),
      circleTextColor: Color(0xFFB91C1C),
    ),
    LanguageOption(
      code: 'gu',
      nativeTitle: 'ગુજરાતી',
      englishTitle: 'Gujarati',
      circleText: 'ગુજ',
      circleBgColor: Color(0xFFE6FFFA),
      circleTextColor: Color(0xFF0D9488),
    ),
    LanguageOption(
      code: 'kn',
      nativeTitle: 'ಕನ್ನಡ',
      englishTitle: 'Kannada',
      circleText: 'ಕನ್ನ',
      circleBgColor: Color(0xFFEFF6FF),
      circleTextColor: Color(0xFF1D4ED8),
    ),
    LanguageOption(
      code: 'pa',
      nativeTitle: 'ਪੰਜਾਬੀ',
      englishTitle: 'Punjabi',
      circleText: 'ਪੰਜਾ',
      circleBgColor: Color(0xFFFDF2F8),
      circleTextColor: Color(0xFFBE185D),
    ),
    LanguageOption(
      code: 'or',
      nativeTitle: 'ଓଡ଼ିଆ',
      englishTitle: 'Odia',
      circleText: 'ଓଡ଼ି',
      circleBgColor: Color(0xFFECFDF5),
      circleTextColor: Color(0xFF047857),
    ),
    LanguageOption(
      code: 'as',
      nativeTitle: 'অসমীয়া',
      englishTitle: 'Assamese',
      circleText: 'অস',
      circleBgColor: Color(0xFFF5F3FF),
      circleTextColor: Color(0xFF6D28D9),
    ),
    LanguageOption(
      code: 'sa',
      nativeTitle: 'संस्कृतम्',
      englishTitle: 'Sanskrit',
      circleText: 'संस्कृ',
      circleBgColor: Color(0xFFFEF3C7),
      circleTextColor: Color(0xFFD97706),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default language from provider
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
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Top background image with map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          
          // 2. Gradient overlay to fade background into clean background color
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00F8FAFC),
                    Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Scrollable content
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Small Brand Logo
                    Image.asset(
                      'assets/images/Logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      'Choose Your Language',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A), // Slate 900
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Subtitle
                    Text(
                      'Select your preferred language to explore government schemes in your language.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B), // Slate 500
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 12-language Grid (6 rows of 2 columns)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _languages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final option = _languages[index];
                        final isSelected = _selectedLang == option.code;
                        return _buildLanguageItem(option, isSelected);
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Info Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Blue 50
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)), // Blue 100
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            color: Color(0xFF1D4ED8), // Blue 700
                            size: 24,
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
                                   'You can change the language anytime from the app settings.',
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
                    const SizedBox(height: 24),
                    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1), // Royal Blue
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          provider.changeLanguage(_selectedLang);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const NavigationModeScreen(),
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
                    const SizedBox(height: 20),
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D47A1) : const Color(0xFFE2E8F0), // Slate 200
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x330D47A1), // 20% opacity
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x05000000), // 2% opacity
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            if (option.code != 'en' && !isSelected) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: option.circleBgColor,
                ),
                alignment: Alignment.center,
                child: Text(
                  option.circleText,
                  style: TextStyle(
                    fontSize: option.circleText.length > 3 ? 9 : 12,
                    fontWeight: FontWeight.bold,
                    color: option.circleTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
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
                      color: isSelected ? Colors.white : const Color(0xFF1E293B), // Slate 800
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    option.englishTitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isSelected ? const Color(0xCCFFFFFF) : const Color(0xFF64748B), // Slate 500 (80% opacity for white)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
