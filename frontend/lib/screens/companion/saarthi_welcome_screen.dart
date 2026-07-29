import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_setup_screen.dart';
import '../../services/voice_agent_preferences.dart';
import '../../services/voice_agent_preview_service.dart';

// Controller to manage widget attention/focus inside AI Companion Mode
class SaarthiAttentionController {
  static final ValueNotifier<String?> activeFocusId = ValueNotifier<String?>(null);

  static void focus(String? id) {
    activeFocusId.value = id;
  }
}

// Pass-through wrapper widget to highlight critical regions in AI Companion Mode
class SaarthiFocusRegion extends StatelessWidget {
  final String id;
  final Widget child;
  final BorderRadius? borderRadius;

  const SaarthiFocusRegion({
    super.key,
    required this.id,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: SaarthiAttentionController.activeFocusId,
      builder: (context, activeId, childWidget) {
        final isFocused = activeId == id;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withOpacity(0.5), // Saarthi Orange glow
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: childWidget,
        );
      },
      child: child,
    );
  }
}

class SaarthiWelcomeScreen extends StatefulWidget {
  const SaarthiWelcomeScreen({super.key});

  @override
  State<SaarthiWelcomeScreen> createState() => _SaarthiWelcomeScreenState();
}

class _SaarthiWelcomeScreenState extends State<SaarthiWelcomeScreen> {
  String _selectedLanguage = 'English';
  String _selectedVoice = VoiceAgentPreferences.defaultVoice;
  bool _debugPanelExpanded = false;
  String? _previewingVoice;

  // Constant colors for premium theme matching description
  static const Color kBgCream = Color(0xFFFFFDF9);
  static const Color kBrandOrange = Color(0xFFEA580C);
  static const Color kBrandOrangeLight = Color(0xFFFFF7ED);
  static const Color kDarkSlate = Color(0xFF0F172A);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    VoiceAgentPreferences.loadVoice().then((voice) {
      if (mounted) setState(() => _selectedVoice = voice);
    });
  }

  Future<void> _selectVoice(String voice) async {
    setState(() => _selectedVoice = voice);
    await VoiceAgentPreferences.saveVoice(voice);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${voice == 'marin' ? 'Marin' : 'Cedar'} is selected. Device speech stays private.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _previewVoice(String voice) async {
    if (_previewingVoice != null) return;
    setState(() => _previewingVoice = voice);
    try {
      await VoiceAgentPreviewService.preview(voice);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _previewingVoice = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 const SizedBox(height: 12),
                
                // 1. Header Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Welcome to',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kDarkSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MSS',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: kBrandOrange,
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(
                              Icons.star,
                              color: kBrandOrange,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                      // Soft orange curved underline decoration
                      Container(
                        width: 80,
                        height: 3,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: kBrandOrange.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'Find the right MSME schemes with confidence.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kDarkSlate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),

                // 2. Hero Avatar Section
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 155,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Circle
                        Positioned(
                          left: 30,
                          bottom: 10,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: const BoxDecoration(
                              color: kBrandOrangeLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Avatar Image
                        Positioned(
                          left: 20,
                          bottom: 0,
                          child: Image.asset(
                            'assets/saarthi_expressions/01_happy.png',
                            width: 145,
                            height: 145,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Elegant fallback if the asset is missing
                              return Container(
                                width: 130,
                                height: 130,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFED7AA),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.support_agent,
                                  size: 55,
                                  color: kBrandOrange,
                                ),
                              );
                            },
                          ),
                        ),
                        // Speech Bubble
                        Positioned(
                          right: 10,
                          top: 15,
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: kDarkSlate,
                                    ),
                                    children: const [
                                      TextSpan(text: "Hi! I'm "),
                                      TextSpan(
                                        text: "Saarthi",
                                        style: TextStyle(color: kBrandOrange),
                                      ),
                                      TextSpan(text: ", your AI companion."),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "I'll help you discover government schemes, check eligibility, and guide you every step of the way.",
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: kSlate500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Personalization Section
                _buildSectionDivider("Let's personalize your experience"),
                const SizedBox(height: 6),
                
                Row(
                  children: [
                    // Language Card
                    Expanded(
                      child: SaarthiFocusRegion(
                        id: 'language_card',
                        child: _buildPersonalizationCard(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: 'Choose your preferred language',
                          child: Container(
                            height: 66,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: kBorderGrey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                isDense: true,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: kBrandOrange, size: 18),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: kDarkSlate,
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedLanguage = newValue;
                                    });
                                  }
                                },
                                items: <String>['English', 'Hindi', 'Tamil']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Voice Card
                    Expanded(
                      child: _buildPersonalizationCard(
                        icon: Icons.volume_up,
                        title: 'Voice',
                        subtitle: 'Choose how Saarthi speaks to you',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Marin voice selection
                            Expanded(
                              child: SaarthiFocusRegion(
                                id: 'voice_marin',
                                child: GestureDetector(
                                  onTap: () => _selectVoice('marin'),
                                  child: _buildVoiceAvatar(
                                    label: 'Marin',
                                    imageAsset: 'assets/images/support_agent.png',
                                    isSelected: _selectedVoice == 'marin',
                                    onPreview: () => _previewVoice('marin'),
                                    isPreviewing: _previewingVoice == 'marin',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Cedar voice selection
                            Expanded(
                              child: SaarthiFocusRegion(
                                id: 'voice_cedar',
                                child: GestureDetector(
                                  onTap: () => _selectVoice('cedar'),
                                  child: _buildVoiceAvatar(
                                    label: 'Cedar',
                                    imageAsset: 'assets/images/user_avatar.png',
                                    isSelected: _selectedVoice == 'cedar',
                                    onPreview: () => _previewVoice('cedar'),
                                    isPreviewing: _previewingVoice == 'cedar',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                 const SizedBox(height: 10),

                // 4. Features Section
                _buildSectionDivider("Saarthi can help you"),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(
                      icon: Icons.search,
                      iconColor: const Color(0xFF3B82F6),
                      bgColor: const Color(0xFFEFF6FF),
                      label: "Find suitable\nschemes",
                    ),
                    _buildFeatureItem(
                      icon: Icons.verified_user_outlined,
                      iconColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      label: "Check eligibility\n& benefits",
                    ),
                    _buildFeatureItem(
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFF5F3FF),
                      label: "Understand\nscheme details",
                    ),
                    _buildFeatureItem(
                      icon: Icons.format_list_bulleted,
                      iconColor: const Color(0xFFEC4899),
                      bgColor: const Color(0xFFFDF2F8),
                      label: "Guide you\nstep by step",
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 5. Bottom Action Button
                SaarthiFocusRegion(
                  id: 'start_button',
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kBrandOrange, Color(0xFFF97316)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: kBrandOrange.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () {
                        // Navigate to companion ProfileSetupScreen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileSetupScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Start with Saarthi',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 6. AI Companion Debug Section (Dev Only)
                if (kDebugMode) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _debugPanelExpanded = !_debugPanelExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200, width: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bug_report, size: 14, color: Colors.amber.shade800),
                              const SizedBox(width: 6),
                              Text(
                                'AI Companion Debug (Dev Only)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _debugPanelExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 14,
                            color: Colors.amber.shade900,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_debugPanelExpanded) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200, width: 0.8),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildDebugButton('[Test Language]', 'language_card'),
                          _buildDebugButton('[Test Voice Marin]', 'voice_marin'),
                          _buildDebugButton('[Test Voice Cedar]', 'voice_cedar'),
                          _buildDebugButton('[Test Start Button]', 'start_button'),
                          _buildDebugButton('[Test Business Type]', 'business_type'),
                          _buildDebugButton('[Test Upload Document]', 'upload_document'),
                          _buildDebugButton('[Test Apply Button]', 'apply_button'),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => SaarthiAttentionController.focus(null),
                            child: Text('Clear Focus', style: GoogleFonts.inter(fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildDebugButton(String label, String targetId) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: kBrandOrange,
        side: const BorderSide(color: kBrandOrange, width: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => SaarthiAttentionController.focus(targetId),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11)),
    );
  }

  // Section divider widget with orange lines and text
  Widget _buildSectionDivider(String text) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBrandOrange.withOpacity(0.01), kBrandOrange.withOpacity(0.4)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kDarkSlate,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBrandOrange.withOpacity(0.4), kBrandOrange.withOpacity(0.01)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Private helper for personalization cards
  Widget _buildPersonalizationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDBA74).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kBrandOrange, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: kDarkSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: kSlate500,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // Private helper for voice avatar items
  Widget _buildVoiceAvatar({
    required String label,
    required String imageAsset,
    required bool isSelected,
    required VoidCallback onPreview,
    required bool isPreviewing,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? kBrandOrange : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.record_voice_over,
                    color: isSelected ? kBrandOrange : kSlate500,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? kBrandOrange : kSlate500,
          ),
        ),
        SizedBox(
          width: 32,
          height: 28,
          child: IconButton(
            key: Key('preview-${label.toLowerCase()}'),
            tooltip: 'Preview $label',
            padding: EdgeInsets.zero,
            onPressed: onPreview,
            icon: isPreviewing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline, size: 18),
          ),
        ),
      ],
    );
  }

  // Private helper for feature item columns
  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: kDarkSlate,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
