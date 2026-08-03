import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../main.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _locationGranted = false;
  bool _micGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locStatus = await Geolocator.checkPermission();
    final locationGranted = locStatus == LocationPermission.always || locStatus == LocationPermission.whileInUse;

    bool micGranted = false;
    try {
      final speech = stt.SpeechToText();
      micGranted = await speech.hasPermission;
    } catch (e) {
      debugPrint('Error checking mic permission: $e');
    }

    setState(() {
      _locationGranted = locationGranted;
      _micGranted = micGranted;
    });
  }

  Future<void> _requestLocation() async {
    final status = await Geolocator.requestPermission();
    setState(() {
      _locationGranted = status == LocationPermission.always || status == LocationPermission.whileInUse;
    });
  }

  Future<void> _requestMicrophone() async {
    try {
      final speech = stt.SpeechToText();
      final hasPermission = await speech.initialize();
      setState(() {
        _micGranted = hasPermission;
      });
    } catch (e) {
      debugPrint('Error requesting mic permission: $e');
    }
  }

  void _proceedToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainTabsContainer(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching app intro screens
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background/Login_bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),

                    // Top Icon Illustration
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
                        ),
                        child: const Icon(
                          Icons.security_outlined,
                          color: Color(0xFF2563EB),
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header Title
                    Text(
                      'Access Permissions',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'To provide the best personalized experience, MSS requests access to the following features:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Permission Card: Location
                    _buildPermissionCard(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBgColor: const Color(0xFFEFF6FF),
                      title: 'Location Services',
                      description: 'Used to filter and suggest regional/state schemes in your area.',
                      isGranted: _locationGranted,
                      onTap: _requestLocation,
                    ),

                    const SizedBox(height: 16),

                    // Permission Card: Microphone
                    _buildPermissionCard(
                      icon: Icons.mic_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: const Color(0xFFF5F3FF),
                      title: 'Microphone & Audio',
                      description: 'Used for Saarthi Voice Assistant commands and voice search queries.',
                      isGranted: _micGranted,
                      onTap: _requestMicrophone,
                    ),

                    const Spacer(flex: 3),

                    // Bottom Navigation Buttons
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                      ),
                      onPressed: _proceedToApp,
                      child: Text(
                        'Continue to App',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Status Button / Badge
          isGranted
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Color(0xFF15803D), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Allowed',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    'Grant',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
