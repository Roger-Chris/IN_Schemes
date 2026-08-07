import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/profile_l10n.dart';
import '../../main.dart';
import '../../utils/responsive.dart';

class AboutYouProfileScreen extends StatefulWidget {
  const AboutYouProfileScreen({super.key});

  @override
  State<AboutYouProfileScreen> createState() => _AboutYouProfileScreenState();
}

class _AboutYouProfileScreenState extends State<AboutYouProfileScreen> {
  String? _selectedRole;

  // Constants
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate800 = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);

  // List of roles data. title/subtitle are localized at build time (see
  // _buildRoles) since ProfileL10n.t() needs the current locale, which
  // isn't known yet at field-initializer time.
  List<RoleModel> _buildRoles(String Function(String) l) => [
    RoleModel(
      id: 'student',
      title: l('student'),
      subtitle: l('student_subtitle'),
      imagePath: 'assets/images/roles/student.webp',
      icon: Icons.school_outlined,
      color: const Color(0xFF3B82F6),
    ),
    RoleModel(
      id: 'entrepreneur',
      title: l('aspiring_entrepreneur'),
      subtitle: l('aspiring_entrepreneur_subtitle'),
      imagePath: 'assets/images/roles/entrepreneur.webp',
      icon: Icons.lightbulb_outline,
      color: const Color(0xFFF59E0B),
    ),
    RoleModel(
      id: 'existing_business',
      title: l('existing_business'),
      subtitle: l('existing_business_subtitle'),
      imagePath: 'assets/images/roles/business.webp',
      icon: Icons.business_center_outlined,
      color: const Color(0xFF6366F1),
    ),
    RoleModel(
      id: 'msme',
      title: l('msme_owner'),
      subtitle: l('msme_owner_subtitle'),
      imagePath: 'assets/images/roles/msme.webp',
      icon: Icons.storefront_outlined,
      color: const Color(0xFF10B981),
    ),
    RoleModel(
      id: 'farmer',
      title: l('farmer'),
      subtitle: l('farmer_subtitle'),
      imagePath: 'assets/images/roles/farmer.webp',
      icon: Icons.agriculture_outlined,
      color: const Color(0xFF14B8A6),
    ),
    RoleModel(
      id: 'artisan',
      title: l('artisan_shg'),
      subtitle: l('artisan_shg_subtitle'),
      imagePath: 'assets/images/roles/artisan.webp',
      icon: Icons.palette_outlined,
      color: const Color(0xFFEC4899),
    ),
  ];

  static String _canonicalRoleTitle(String roleId) => switch (roleId) {
    'student' => 'Student',
    'entrepreneur' => 'Aspiring Entrepreneur',
    'existing_business' => 'Existing Business',
    'msme' => 'MSME Owner',
    'farmer' => 'Farmer',
    'artisan' => 'Artisan / SHG Member',
    _ => roleId,
  };

  @override
  Widget build(BuildContext context) {
    final isTa = context.select<AppProvider, bool>(
      (provider) => provider.selectedLanguage == 'ta',
    );
    String l(String key) => ProfileL10n.t(key, isTa);
    final roles = _buildRoles(l);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background/Login_bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          // Foreground Layout (Strictly zero scrolling)
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar (Outside the card)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: kSlate800,
                            size: 24,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        FlexText(
                          child: Text(
                            l('complete_your_profile'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kSlate900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), // Balance centering
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Main Card Container (Expanded to take remaining space)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(
                          16.0,
                        ), // Tight card padding
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Scrollable area for content
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Progress Stepper & Header Group
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildProgressSegment(true),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: _buildProgressSegment(true),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: _buildProgressSegment(true),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        l('step_3_of_3'),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Header Text
                                    Text(
                                      l('tell_us_about_you'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: kSlate900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l('about_you_subtitle'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: kSlate500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 2x3 Grid Area (non-scrollable itself, scrolls with parent)
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: roles.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio:
                                                MediaQuery.sizeOf(
                                                      context,
                                                    ).width <
                                                    360
                                                ? 0.78
                                                : 0.88,
                                          ),
                                      itemBuilder: (context, index) {
                                        final role = roles[index];
                                        final isSelected =
                                            _selectedRole == role.id;

                                        return _buildRoleCard(role, isSelected);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Sticky Action Button (Bottom of card, outside scrollable area)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedRole != null
                                    ? kPrimaryBlue
                                    : Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size.fromHeight(50),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                final selectedRole = _selectedRole;
                                if (selectedRole == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l('about_you_subtitle'),
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFFDC2626),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                final provider = Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                );
                                final updatedProfile = provider.profile
                                    .copyWith(
                                      employmentStatus: _canonicalRoleTitle(
                                        selectedRole,
                                      ),
                                      profileCompleted: true,
                                    );

                                await provider.updateProfile(updatedProfile);

                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MainTabsContainer(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FitOneLine(
                                      child: Text(
                                        l('continue'),
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedRole != null
                                              ? Colors.white
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: _selectedRole != null
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                    size: 20,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSegment(bool isCompleted) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isCompleted ? kPrimaryBlue : kBorderGrey,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildRoleCard(RoleModel role, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8.0), // Compact padding
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Micro Radio Button indicator
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryBlue : Colors.white,
                  border: Border.all(
                    color: isSelected ? kPrimaryBlue : kBorderGrey,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 10)
                    : null,
              ),
            ),

            // Drastically reduced character image size
            Expanded(
              child: Center(
                child: Image.asset(
                  role.imagePath,
                  height: 48, // Reduced to fit within non-scrolling grid bounds
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: role.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(role.icon, color: role.color, size: 22),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Role Title
            Text(
              role.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: kSlate900,
              ),
            ),
            const SizedBox(height: 2),

            // Role Description
            Text(
              role.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: kSlate500,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Model helper class
class RoleModel {
  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;

  RoleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
  });
}
