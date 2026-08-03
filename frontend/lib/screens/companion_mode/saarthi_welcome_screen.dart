import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/voice_agent_preferences.dart';
import '../../services/voice_agent_preview_service.dart';
import 'saarthi_profile_setup_screen.dart';

class SaarthiWelcomeScreen extends StatefulWidget {
  const SaarthiWelcomeScreen({super.key});

  @override
  State<SaarthiWelcomeScreen> createState() => _SaarthiWelcomeScreenState();
}

class _SaarthiWelcomeScreenState extends State<SaarthiWelcomeScreen> {
  String _selectedLang = 'en';
  String _selectedVoice = VoiceAgentPreferences.defaultVoice;
  bool _previewingVoice = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _selectedLang = provider.selectedLanguage;
    VoiceAgentPreferences.loadVoice().then((voice) {
      if (mounted) setState(() => _selectedVoice = voice);
    });
  }

  Future<void> _selectVoice(String voice) async {
    setState(() => _selectedVoice = voice);
    await VoiceAgentPreferences.saveVoice(voice);
  }

  Future<void> _previewVoice() async {
    if (_previewingVoice) return;
    setState(() => _previewingVoice = true);
    try {
      await VoiceAgentPreviewService.preview(_selectedVoice);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _previewingVoice = false);
    }
  }

  static const Color kBrandBlue = Color(0xFF2563EB);
  static const Color kDarkBlue = Color(0xFF1E3A8A);
  static const Color kDarkSlate = Color(0xFF0F172A);
  static const Color kSlate500 = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Blue Section with Background & Avatar
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEBF5FF),
                    Color(0xFFF8FAFC),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background Image Overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.asset(
                        'assets/images/Background/companion intro bg.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      top: 44.0,
                      bottom: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Heading: Meet Saarthi
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Meet',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: kDarkSlate,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'Saarthi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: kBrandBlue,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Avatar right above the card (aligned to the right)
                            Expanded(
                              flex: 4,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Transform.translate(
                                  offset: const Offset(0, 10), // Shifting avatar down to sit on the card
                                  child: SizedBox(
                                    height: 100,
                                    child: Image.asset(
                                      'assets/images/saarthi/sarathi.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.android,
                                        size: 60,
                                        color: kBrandBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        // Speech Card inside the blue header area
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: kBrandBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "I'm Saarthi, your smart assistant.",
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: kDarkBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "I'll help you discover the right schemes, explain everything simply, and guide you at every step.",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2 & 3. Flexibly distributed middle area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. "Saarthi can help you with" Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Saarthi can help you with',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: kDarkSlate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.mic_none_rounded,
                                title: 'Talk Naturally',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.language_outlined,
                                title: 'Find Right Schemes',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.alt_route_outlined,
                                title: 'Business Roadmap',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.assignment_outlined,
                                title: 'Application Support',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 3. Choose Language Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.language,
                              color: kBrandBlue,
                              size: 20,
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
                        Text(
                          "Choose your preferred language so Saarthi can talk to you better.",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: kSlate500,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.record_voice_over_outlined,
                              color: kBrandBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voice',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: kDarkSlate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text('Natural'),
                              selected: _selectedVoice == 'natural',
                              onSelected: (_) => _selectVoice('natural'),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Clear'),
                              selected: _selectedVoice == 'clear',
                              onSelected: (_) => _selectVoice('clear'),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Preview in English and Tamil',
                              onPressed: _previewingVoice ? null : _previewVoice,
                              icon: _previewingVoice
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.play_circle_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Info banner
                        Row(
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
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Action Button at Bottom
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 16.0,
                top: 8.0,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final provider = Provider.of<AppProvider>(context, listen: false);
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
                      "Let's Begin",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: kBrandBlue,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: kDarkSlate,
            ),
          ),
        ],
      ),
    );
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
}
