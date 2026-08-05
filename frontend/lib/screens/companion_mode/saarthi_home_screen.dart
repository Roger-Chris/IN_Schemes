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
}
