import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../permission_screen.dart';

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

  // List of roles data
  final List<RoleModel> _roles = [
    RoleModel(
      id: 'student',
      title: 'Student',
      subtitle: 'Looking for learning, innovation and startup opportunities.',
      imagePath: 'assets/images/roles/student.webp',
      icon: Icons.school_outlined,
      color: const Color(0xFF3B82F6),
    ),
    RoleModel(
      id: 'entrepreneur',
      title: 'Aspiring Entrepreneur',
      subtitle: 'I have an idea and want to start a business.',
      imagePath: 'assets/images/roles/entrepreneur.webp',
      icon: Icons.lightbulb_outline,
      color: const Color(0xFFF59E0B),
    ),
    RoleModel(
      id: 'existing_business',
      title: 'Existing Business',
      subtitle: 'I already run a registered or unregistered business.',
      imagePath: 'assets/images/roles/business.webp',
      icon: Icons.business_center_outlined,
      color: const Color(0xFF6366F1),
    ),
    RoleModel(
      id: 'msme',
      title: 'MSME Owner',
      subtitle: 'I own a micro, small or medium enterprise.',
      imagePath: 'assets/images/roles/msme.webp',
      icon: Icons.storefront_outlined,
      color: const Color(0xFF10B981),
    ),
    RoleModel(
      id: 'farmer',
      title: 'Farmer',
      subtitle: 'I am involved in farming or agriculture.',
      imagePath: 'assets/images/roles/farmer.webp',
      icon: Icons.agriculture_outlined,
      color: const Color(0xFF14B8A6),
    ),
    RoleModel(
      id: 'artisan',
      title: 'Artisan / SHG Member',
      subtitle: 'I am an artisan or part of a Self Help Group.',
      imagePath: 'assets/images/roles/artisan.webp',
      icon: Icons.palette_outlined,
      color: const Color(0xFFEC4899),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                          icon: const Icon(Icons.arrow_back, color: kSlate800, size: 24),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        Text(
                          'Complete Your Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kSlate900,
                          ),
                        ),
                        const SizedBox(width: 40), // Balance centering
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Main Card Container (Expanded to take remaining space)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0), // Tight card padding
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
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Progress Stepper & Header Group
                                    Row(
                                      children: [
                                        Expanded(child: _buildProgressSegment(true)),
                                        const SizedBox(width: 4),
                                        Expanded(child: _buildProgressSegment(true)),
                                        const SizedBox(width: 4),
                                        Expanded(child: _buildProgressSegment(true)),
                                        const SizedBox(width: 4),
                                        Expanded(child: _buildProgressSegment(false)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        '3/4 Complete',
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
                                      'Tell Us About You',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: kSlate900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Choose the option that best describes you.',
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
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _roles.length,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.88, // Balanced compact aspect ratio
                                      ),
                                      itemBuilder: (context, index) {
                                        final role = _roles[index];
                                        final isSelected = _selectedRole == role.id;

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
                                backgroundColor: _selectedRole != null ? kPrimaryBlue : Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size.fromHeight(50),
                                elevation: 0,
                              ),
                              onPressed: _selectedRole != null
                                  ? () async {
                                      final provider = Provider.of<AppProvider>(context, listen: false);
                                      final selectedRoleModel = _roles.firstWhere((r) => r.id == _selectedRole);
                                      final roleTitle = selectedRoleModel.title;

                                      final updatedProfile = provider.profile.copyWith(
                                        employmentStatus: roleTitle,
                                        profileCompleted: true,
                                      );

                                      await provider.updateProfile(updatedProfile);

                                      if (!context.mounted) return;
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) => const PermissionScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedRole != null ? Colors.white : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: _selectedRole != null ? Colors.white : Colors.grey.shade500,
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
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
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
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      )
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
                      child: Icon(
                        role.icon,
                        color: role.color,
                        size: 22,
                      ),
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
