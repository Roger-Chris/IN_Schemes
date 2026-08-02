import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/constants.dart';
import 'regular_mode/profile_setup_screen.dart';
import 'regular_mode/language_selection_screen.dart';
import 'regular_mode/settings_screen.dart';
import 'regular_mode/help_support_screen.dart';
import 'notifications_screen.dart';
import '../widgets/custom_confirm_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context, AppProvider provider) {
    CustomConfirmDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFFEF4444),
      iconBgColor: const Color(0xFFFEE2E2),
      title: 'Confirm Logout',
      message: 'Are you sure you want to log out from MSS?',
      confirmLabel: 'Logout',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () => provider.logout(context),
    );
  }

  // Info Column Helper for the Grid
  Widget _buildInfoCol(String label, String value, int flex) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Vertical Divider Helper for the Grid
  Widget _buildDividerCol() {
    return Container(
      height: 28,
      width: 1,
      color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // Grouped Card container for Settings Tiles
  Widget _buildGroupCard(List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: tiles),
    );
  }

  // Custom Settings ListTile builder
  Widget _buildProfileTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
    bool showDivider = true,
    Color? textColor,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    trailingText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            color: Color(0xFFF1F5F9),
            height: 1,
            indent: 68,
            endIndent: 16,
          ),
      ],
    );
  }

  Future<void> _changeProfilePicture(
    BuildContext context,
    AppProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Profile Photo',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF2563EB),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    await _savePickedImage(pickedFile.path, provider);
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF2563EB),
                ),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    await _savePickedImage(pickedFile.path, provider);
                  }
                },
              ),
              if (provider.profile.profilePhoto.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  title: Text(
                    'Remove Photo',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.updateProfilePhoto('');
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePickedImage(String tempPath, AppProvider provider) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String extension = tempPath.split('.').last;
      final String newFileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String newPath = '${appDir.path}/$newFileName';

      final File tempFile = File(tempPath);
      await tempFile.copy(newPath);
      await provider.updateProfilePhoto(newPath);
    } catch (e) {
      debugPrint('Error saving picked profile photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final profile = provider.profile;
    final unreadCount = provider.notifications.where((n) => !n['read']).length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Notification Bell with Badge
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                         ),
                        alignment: Alignment.center,
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Profile Banner (Blue Gradient Card)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1976D2),
                    Color(0xFF1E88E5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Decorative patterns resembling mockup background
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Opacity(
                        opacity: 0.1,
                        child: const Icon(
                          Icons.account_balance,
                          size: 160,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          // Avatar Stack with Camera Overlay
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _changeProfilePicture(context, provider),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundImage:
                                        provider
                                                .profile
                                                .profilePhoto
                                                .isNotEmpty &&
                                            File(
                                              provider.profile.profilePhoto,
                                            ).existsSync()
                                        ? FileImage(
                                            File(provider.profile.profilePhoto),
                                          )
                                        : const AssetImage(
                                                'assets/supporting assets/user_avatar.png',
                                              )
                                              as ImageProvider,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _changeProfilePicture(context, provider),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // User Name, Badges & Contacts
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.name.isNotEmpty
                                            ? profile.name
                                            : 'Not Set',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(25),
                                        border: Border.all(
                                          color: profile.profileCompleted
                                              ? const Color(0xFF4ADE80)
                                              : const Color(0xFFF59E0B),
                                          width: 0.8,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            profile.profileCompleted
                                                ? Icons.check_circle
                                                : Icons.warning_amber_rounded,
                                            color: profile.profileCompleted
                                                ? const Color(0xFF4ADE80)
                                                : const Color(0xFFF59E0B),
                                            size: 10,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            profile.profileCompleted
                                                ? 'Profile Verified'
                                                : 'Incomplete',
                                            style: GoogleFonts.inter(
                                              fontSize: 8.5,
                                              color: profile.profileCompleted
                                                  ? const Color(0xFF4ADE80)
                                                  : const Color(0xFFF59E0B),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      color: Colors.white70,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      profile.mobile.isNotEmpty
                                          ? '+91 ${profile.mobile}'
                                          : 'Not Set',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: Colors.white.withAlpha(230),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.mail_outline,
                                      color: Colors.white70,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        profile.email.isNotEmpty
                                            ? profile.email
                                            : 'Not Set',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: Colors.white.withAlpha(230),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
            ),

            // 2. User Information Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title Header with Edit Profile Action
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'User Information',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileSetupScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF2563EB),
                          size: 13,
                        ),
                        label: Text(
                          'Edit Profile',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0xFFBFDBFE),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Information Details Grid
                  Row(
                    children: [
                      _buildInfoCol(
                        'Full Name',
                        profile.name.isNotEmpty ? profile.name : 'Not Set',
                        5,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        'Age',
                        profile.dob != null ? '${profile.age}' : 'Not Set',
                        2,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        'Gender',
                        profile.gender.isNotEmpty ? profile.gender : 'Not Set',
                        3,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        'Location',
                        profile.district.isNotEmpty
                            ? '${profile.district}, ${profile.state}'
                            : 'Not Set',
                        6,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Grouped Navigation Actions: Card 1
            _buildGroupCard([
              _buildProfileTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFDCFCE7),
                title: 'Eligibility Profile',
                subtitle: 'View and update your eligibility details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSetupScreen(),
                    ),
                  );
                },
              ),
              _buildProfileTile(
                icon: Icons.bookmark_border_outlined,
                iconColor: const Color(0xFFEA580C),
                iconBgColor: const Color(0xFFFFF3E0),
                title: 'Saved Schemes',
                subtitle: 'View your bookmarked schemes',
                onTap: () {
                  provider.updateTabIndex(3);
                },
              ),
              _buildProfileTile(
                icon: Icons.language_outlined,
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFF3E8FF),
                title: 'Language',
                subtitle: 'Choose your preferred language',
                trailingText: provider.selectedLanguage == 'hi'
                    ? 'Hindi'
                    : 'English',
                showDivider: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );
                },
              ),
            ]),

            // 4. Grouped Navigation Actions: Card 2
            _buildGroupCard([
              _buildProfileTile(
                icon: Icons.settings_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Settings',
                subtitle: 'Manage app preferences',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              _buildProfileTile(
                icon: Icons.lock_outline,
                iconColor: const Color(0xFF0D9488),
                iconBgColor: const Color(0xFFCCFBF1),
                title: 'Privacy',
                subtitle: 'Privacy policy and data settings',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const Text(
                        'Your privacy is important to us. All personal data is encrypted and saved locally on this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildProfileTile(
                icon: Icons.chat_bubble_outline,
                iconColor: const Color(0xFFDB2777),
                iconBgColor: const Color(0xFFFCE7F3),
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),
              _buildProfileTile(
                icon: Icons.info_outline,
                iconColor: const Color(0xFFCA8A04),
                iconBgColor: const Color(0xFFFEF9C3),
                title: 'About',
                subtitle: 'About MSS app',
                showDivider: false,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'MSS',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(
                      Icons.info,
                      color: Color(0xFF2563EB),
                    ),
                    children: [
                      const Text(
                        'Empowering citizens with real-time tracking, eligibility scanning and downloads for all state and central Government schemes in India.',
                      ),
                    ],
                  );
                },
              ),
            ]),

            // 5. Logout Card
            _buildGroupCard([
              _buildProfileTile(
                icon: Icons.logout_outlined,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Logout',
                subtitle: 'Logout from your account',
                textColor: const Color(0xFFDC2626),
                showDivider: false,
                onTap: () => _handleLogout(context, provider),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
