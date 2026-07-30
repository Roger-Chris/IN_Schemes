import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'saarthi_language_selection_screen.dart';

class SaarthiWelcomeScreen extends StatefulWidget {
  const SaarthiWelcomeScreen({super.key});

  @override
  State<SaarthiWelcomeScreen> createState() => _SaarthiWelcomeScreenState();
}

class _SaarthiWelcomeScreenState extends State<SaarthiWelcomeScreen> {
  static const Color kBrandBlue = Color(0xFF2563EB);
  static const Color kDarkBlue = Color(0xFF1E3A8A);
  static const Color kBrandOrange = Color(0xFFEA580C);
  static const Color kDarkSlate = Color(0xFF0F172A);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kGreenBg = Color(0xFFF0FDF4);
  static const Color kGreenBorder = Color(0xFFDCFCE7);
  static const Color kGreenText = Color(0xFF15803D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                        clipBehavior: Clip.none,
                        children: [
                          // Background Image Overlay
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.8,
                              child: Image.asset(
                                'assets/images/companion intro bg.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              right: 20.0,
                              top: 24.0,
                              bottom: 40.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Header Text
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Meet',
                                        style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: kDarkSlate,
                                          height: 1.1,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'MSS ',
                                            style: GoogleFonts.poppins(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: kBrandOrange,
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
                                      // Orange curvy underline below MSS
                                      Container(
                                        width: 56,
                                        height: 4,
                                        margin: const EdgeInsets.only(top: 4, bottom: 10),
                                        decoration: BoxDecoration(
                                          color: kBrandOrange,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      Text(
                                        'Your AI guide for MSME\nschemes and growth.',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: kSlate500,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Right Bot Avatar
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    height: 140,
                                    alignment: Alignment.topRight,
                                    child: Image.asset(
                                      'assets/saarthi_expressions/Ai companion.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.android,
                                        size: 80,
                                        color: kBrandBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Overlapping White Speech Card
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: -24,
                            child: Container(
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 44),

                    // 2. "Saarthi can help you with" Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Saarthi can help you with',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
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
                          const SizedBox(height: 14),

                          // 2x2 Feature Cards Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.mic_none_rounded,
                                  title: 'Talk Naturally',
                                  subtitle: 'Speak or type in your language.',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.language_outlined,
                                  title: 'Find Right Schemes',
                                  subtitle: 'Personalized scheme recommendations.',
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
                                  subtitle: 'Step-by-step plan for your business growth.',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.assignment_outlined,
                                  title: 'Application Support',
                                  subtitle: 'Guidance for documents and applications.',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 3. Privacy Security Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kGreenBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kGreenBorder),
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
                                    Icons.shield_outlined,
                                    color: Color(0xFF16A34A),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your privacy is our priority',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: kDarkSlate,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your conversations are secure and never shared with anyone.',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: kSlate500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kGreenBorder,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: kGreenText,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '100% Secure',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: kGreenText,
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

                    const SizedBox(height: 20),
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SaarthiLanguageSelectionScreen(),
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
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: kBrandBlue,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: kDarkSlate,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              color: kSlate500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
