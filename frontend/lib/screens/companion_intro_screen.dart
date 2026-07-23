import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';


class CompanionIntroScreen extends StatefulWidget {
  const CompanionIntroScreen({super.key});

  @override
  State<CompanionIntroScreen> createState() => _CompanionIntroScreenState();
}

class _CompanionIntroScreenState extends State<CompanionIntroScreen> {
  String _selectedLanguage = 'English';
  String _selectedVoice = 'Female';

  Widget _buildSecureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security_rounded, color: Color(0xFF2563EB), size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '100% Secure',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              Text(
                'Your data is protected',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftChatBubble() {
    return CustomPaint(
      painter: ChatBubblePainter(color: const Color(0xFFEFF6FF), isLeft: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
            children: const [
              TextSpan(text: 'Hello, '),
              TextSpan(
                text: 'Praveen!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              TextSpan(text: ' 👋'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightChatBubble() {
    return CustomPaint(
      painter: ChatBubblePainter(color: Colors.white, isLeft: false),
      child: Container(
        width: 120,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                    height: 1.3,
                  ),
                  children: const [
                    TextSpan(text: "I'm here to\nhelp you at\n"),
                    TextSpan(
                      text: 'every step!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Padding(
              padding: EdgeInsets.only(top: 2.0),
              child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 12),
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
    required Color primaryColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
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

  Widget _buildDropdown({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueryTag({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Companion Language',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('English'),
                trailing: _selectedLanguage == 'English' ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
                onTap: () {
                  setState(() => _selectedLanguage = 'English');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Tamil (தமிழ்)'),
                trailing: _selectedLanguage == 'Tamil (தமிழ்)' ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
                onTap: () {
                  setState(() => _selectedLanguage = 'Tamil (தமிழ்)');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoiceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Companion Voice',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Female'),
                trailing: _selectedVoice == 'Female' ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
                onTap: () {
                  setState(() => _selectedVoice = 'Female');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Male'),
                trailing: _selectedVoice == 'Male' ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
                onTap: () {
                  setState(() => _selectedVoice = 'Male');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/companion intro bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                // Top Nav Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      _buildSecureBadge(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Top visual stack containing Bot & Chat bubbles & Meet Your IN Companion text
                Container(
                  height: 230,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 10,
                        left: 0,
                        child: _buildLeftChatBubble(),
                      ),
                      // Main title column
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Meet Your',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'IN Companion',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 32,
                              height: 3.5,
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: size.width * 0.50,
                              child: Text(
                                'Your AI guide for discovering government schemes across India.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side: Bot waving with sparkles bubble centered above
                      Positioned(
                        right: -10,
                        top: 20,
                        width: 170,
                        height: 210,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned(
                              top: 40,
                              right: 0,
                              width: 150,
                              height: 160,
                              child: Image.asset(
                                'assets/images/compoanion bot.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: -10,
                              left: -32,
                              child: _buildRightChatBubble(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2x2 Feature Cards Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.search_rounded,
                          title: 'Smart Search',
                          subtitle: 'Find schemes in everyday language.',
                          primaryColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.mic_rounded,
                          title: 'Voice Assistance',
                          subtitle: 'Talk naturally in your language.',
                          primaryColor: const Color(0xFF10B981),
                          iconBgColor: const Color(0xFFECFDF5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.description_outlined,
                          title: 'Document Help',
                          subtitle: 'Know what documents you need.',
                          primaryColor: const Color(0xFF8B5CF6),
                          iconBgColor: const Color(0xFFF5F3FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.lightbulb_outline_rounded,
                          title: 'Instant Explanations',
                          subtitle: 'Understand eligibility in simple words.',
                          primaryColor: const Color(0xFFF97316),
                          iconBgColor: const Color(0xFFFFF7ED),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Language & Voice selectors
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildDropdown(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF2563EB),
                        label: 'Language',
                        value: _selectedLanguage,
                        onTap: _showLanguageSelector,
                      ),
                      const SizedBox(width: 12),
                      _buildDropdown(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFFEC4899),
                        label: 'Voice',
                        value: _selectedVoice,
                        onTap: _showVoiceSelector,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Try asking me about section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Try asking me about',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildQueryTag(
                        icon: Icons.school_rounded,
                        iconColor: const Color(0xFF2563EB),
                        text: 'Scholarship',
                        textColor: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      _buildQueryTag(
                        icon: Icons.eco_rounded,
                        iconColor: const Color(0xFF10B981),
                        text: 'Farmer',
                        textColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      _buildQueryTag(
                        icon: Icons.business_center_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        text: 'Business',
                        textColor: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 8),
                      _buildQueryTag(
                        icon: Icons.payments_rounded,
                        iconColor: const Color(0xFFF97316),
                        text: 'Loan',
                        textColor: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Get Started Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
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
                            "Let's Get Started",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom disclaimer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'You can turn me off anytime from Home.',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubblePainter extends CustomPainter {
  final Color color;
  final bool isLeft;

  ChatBubblePainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    path.addRRect(rrect);

    if (isLeft) {
      // Tail at bottom-left corner pointing down-left
      path.moveTo(24, size.height);
      path.quadraticBezierTo(14, size.height + 6, 8, size.height + 12);
      path.quadraticBezierTo(18, size.height + 4, 36, size.height);
    } else {
      // Tail at bottom-right corner pointing down-right to robot head
      path.moveTo(size.width - 24, size.height);
      path.quadraticBezierTo(size.width - 14, size.height + 6, size.width - 8, size.height + 12);
      path.quadraticBezierTo(size.width - 18, size.height + 4, size.width - 36, size.height);
    }

    canvas.drawShadow(path, Colors.black.withAlpha(20), 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

