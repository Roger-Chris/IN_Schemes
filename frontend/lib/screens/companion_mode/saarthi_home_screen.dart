import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import 'companion_voice_agent_launcher.dart';

class SaarthiHomeScreen extends StatefulWidget {
  const SaarthiHomeScreen({super.key});

  @override
  State<SaarthiHomeScreen> createState() => _SaarthiHomeScreenState();
}

class _SaarthiHomeScreenState extends State<SaarthiHomeScreen> {
  // Mock data for recent conversations
  final List<Map<String, String>> _recentChats = [
    {
      'title': 'How can I get a loan for my textile business?',
      'subtitle': 'Saarthi • Today, 10:30 AM',
    },
    {
      'title': 'Explain PMEGP scheme in detail',
      'subtitle': 'Saarthi • Yesterday',
    },
    {
      'title': 'Documents needed for UDYAM registration',
      'subtitle': 'Saarthi • 2 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final userName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ')[0]
        : 'Praveen';

    const Color kBrandBlue = Color(0xFF2563EB);
    const Color kDarkSlate = Color(0xFF0F172A);
    const Color kSlate500 = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable upper content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 28.0,
                  bottom: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top bar: Language Pill & Notifications / Profile Avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Language Pill selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language,
                                color: kBrandBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'English',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: kDarkSlate,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: kSlate500,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        // Notification icon & Profile photo
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: kDarkSlate,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                if (provider.notifications.any((n) => n['read'] == false))
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: ClipOval(
                                  child: () {
                                    final photo = provider.profile.profilePhoto;
                                    if (photo.isEmpty) {
                                      return Image.asset(
                                        'assets/images/supporting assets/user_avatar.png',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    if (photo.startsWith('http://') || photo.startsWith('https://')) {
                                      return Image.network(
                                        photo,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.person,
                                          color: kBrandBlue,
                                          size: 18,
                                        ),
                                      );
                                    }
                                    final file = File(photo);
                                    if (file.existsSync()) {
                                      return Image.file(
                                        file,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Image.asset(
                                      'assets/images/supporting assets/user_avatar.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    );
                                  }(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Character Welcome Banner with Sparkles
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Character Avatar Card
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                                width: 4,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/saarthi/sarathi.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Sparkles (decorations)
                          const Positioned(
                            left: 0,
                            top: 55,
                            child: Icon(
                              Icons.star,
                              color: Color(0xFF93C5FD),
                              size: 14,
                            ),
                          ),
                          const Positioned(
                            right: 0,
                            top: 45,
                            child: Icon(
                              Icons.star,
                              color: Color(0xFF93C5FD),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kDarkSlate,
                          ),
                          children: [
                            const TextSpan(text: 'Good Morning, '),
                            TextSpan(
                              text: '$userName! 👋',
                              style: const TextStyle(color: kBrandBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: kDarkSlate,
                          ),
                          children: const [
                            TextSpan(text: "I'm "),
                            TextSpan(
                              text: 'Saarthi',
                              style: TextStyle(
                                color: kBrandBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ', your AI companion for\nMSME success.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Try Asking Saarthi Quick Action Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Try asking Saarthi',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: kDarkSlate,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildQuickActionCard(
                                title: 'Start a Business',
                                icon: Icons.rocket_launch_rounded,
                                iconColor: const Color(0xFF2563EB),
                                bgColor: const Color(0xFFEFF6FF),
                                onTap: () => openCompanionVoiceAgent(
                                  context,
                                  initialText: 'How do I start a business?',
                                ),
                              ),
                              _buildQuickActionCard(
                                title: 'Find Funding',
                                icon: Icons.currency_rupee_rounded,
                                iconColor: const Color(0xFF16A34A),
                                bgColor: const Color(0xFFDCFCE7),
                                onTap: () => openCompanionVoiceAgent(
                                  context,
                                  initialText:
                                      'How can I get business funding?',
                                ),
                              ),
                              _buildQuickActionCard(
                                title: 'Register UDYAM',
                                icon: Icons.business_rounded,
                                iconColor: const Color(0xFF9333EA),
                                bgColor: const Color(0xFFF3E8FF),
                                onTap: () => openCompanionVoiceAgent(
                                  context,
                                  initialText:
                                      'Show me steps for UDYAM registration',
                                ),
                              ),
                              _buildQuickActionCard(
                                title: 'Grow Business',
                                icon: Icons.trending_up_rounded,
                                iconColor: const Color(0xFFEA580C),
                                bgColor: const Color(0xFFFFF7ED),
                                onTap: () => openCompanionVoiceAgent(
                                  context,
                                  initialText:
                                      'Tips to grow my small business?',
                                ),
                              ),
                              _buildQuickActionCard(
                                title: 'Export Support',
                                icon: Icons.public_rounded,
                                iconColor: const Color(0xFF0D9488),
                                bgColor: const Color(0xFFF0FDFA),
                                onTap: () => openCompanionVoiceAgent(
                                  context,
                                  initialText:
                                      'Explain export assistance schemes',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 4. Recent Conversations Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Conversations',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: kDarkSlate,
                              ),
                            ),
                            Text(
                              'View All',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: kBrandBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentChats.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFFE2E8F0),
                            ),
                            itemBuilder: (context, index) {
                              final chat = _recentChats[index];
                              return ListTile(
                                onTap: () => openCompanionVoiceAgent(
                                  context,
                                  initialText: chat['title'],
                                ),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: kBrandBlue,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  chat['title']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kDarkSlate,
                                  ),
                                ),
                                subtitle: Text(
                                  chat['subtitle']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: kSlate500,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: kSlate500,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Fixed bottom panel (Ask Saarthi Card & Mic static)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ask Saarthi Card (The Box)
                  GestureDetector(
                    onTap: () => openCompanionVoiceAgent(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEFF6FF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kBrandBlue.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Ask Saarthi anything...',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: kDarkSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap the mic to speak or type your question',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: kSlate500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Text Box Type Container
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Type your question...',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: kSlate500,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard,
                                  color: kBrandBlue,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mic and Waves (Outside the Box)
                  GestureDetector(
                    onTap: () => openCompanionVoiceAgent(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left Waveform
                          Row(
                            children: List.generate(8, (index) {
                              final h = (index % 3 == 0)
                                  ? 14.0
                                  : ((index % 2 == 0) ? 8.0 : 4.0);
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                width: 2,
                                height: h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF93C5FD),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 16),
                          // Microphone Circular Pulse Button
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kBrandBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: kBrandBlue.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right Waveform
                          Row(
                            children: List.generate(8, (index) {
                              final h = (index % 3 == 0)
                                  ? 14.0
                                  : ((index % 2 == 0) ? 8.0 : 4.0);
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                width: 2,
                                height: h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF93C5FD),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            }),
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
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
