import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';
import 'regular_mode/profile_setup_screen.dart';
import 'regular_mode/language_selection_screen.dart';
import 'regular_mode/settings_screen.dart';
import 'regular_mode/help_support_screen.dart';
import 'notifications_screen.dart';
import '../widgets/custom_confirm_dialog.dart';
import '../utils/responsive.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context, AppProvider provider) {
    CustomConfirmDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFFEF4444),
      iconBgColor: const Color(0xFFFEE2E2),
      title: context.l10n.confirmLogoutTitle,
      message: context.l10n.confirmLogoutMsg,
      confirmLabel: context.l10n.logoutButton,
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () => provider.logout(context),
    );
  }

  String _getLocalizedIncomeRange(double income, BuildContext context) {
    if (income <= 150000) return context.l10n.incUnder1_5;
    if (income <= 300000) return context.l10n.inc1_5To3;
    if (income <= 500000) return context.l10n.inc3To5;
    if (income <= 800000) return context.l10n.inc5To8;
    return context.l10n.incAbove8;
  }

  String _getLocalizedProfileValue(String val, BuildContext context) {
    final lower = val.trim().toLowerCase();
    if (lower == 'male') return context.l10n.genderMale;
    if (lower == 'female') return context.l10n.genderFemale;
    if (lower == 'other' || lower == 'others') return context.l10n.genderOther;

    if (lower == 'student') return context.l10n.empStudent;
    if (lower == 'farmer') return context.l10n.empFarmer;
    if (lower == 'salaried') return context.l10n.empSalaried;
    if (lower == 'self-employed' || lower == 'self employed') return context.l10n.empSelfEmployed;
    if (lower == 'unemployed') return context.l10n.empUnemployed;
    if (lower == 'retired') return context.l10n.empRetired;

    if (lower == 'general') return context.l10n.commGeneral;
    if (lower == 'obc') return context.l10n.commObc;
    if (lower == 'ews') return context.l10n.commEws;
    if (lower == 'sc') return context.l10n.commSc;
    if (lower == 'st') return context.l10n.commSt;

    if (lower == 'yes') return context.l10n.valYes;
    if (lower == 'no' || lower == 'none') return context.l10n.valNo;
    if (lower == 'tamil' || lower == 'ta') return 'தமிழ்';
    if (lower == 'english' || lower == 'en') return 'English';

    return val;
  }

  // Info Column Helper for the Grid
  Widget _buildInfoCol(String label, String value, int flex, {bool isTamil = false}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTamil ? 10.0 : 10.5,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              height: isTamil ? 1.35 : 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTamil ? 11.0 : 11.5,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              height: isTamil ? 1.35 : 1.2,
            ),
            maxLines: 2,
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
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FitOneLine(
                      child: Text(
                        trailingText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                  context.l10n.profilePhotoTitle,
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
                  context.l10n.chooseFromGallery,
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
                  context.l10n.takePhoto,
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
                    context.l10n.removePhoto,
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

    final isTa = provider.selectedLanguage == 'ta';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          context.l10n.profileTitle,
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
                                    backgroundImage: () {
                                      final photo = provider.profile.profilePhoto;
                                      if (photo.isEmpty) {
                                        return const AssetImage('assets/images/supporting assets/user_avatar.png') as ImageProvider;
                                      }
                                      if (photo.startsWith('http://') || photo.startsWith('https://')) {
                                        return NetworkImage(photo) as ImageProvider;
                                      }
                                      if (File(photo).existsSync()) {
                                        return FileImage(File(photo)) as ImageProvider;
                                      }
                                      return const AssetImage('assets/images/supporting assets/user_avatar.png') as ImageProvider;
                                    }(),
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
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      profile.name.isNotEmpty ? profile.name : '-',
                                      style: GoogleFonts.poppins(
                                        fontSize: provider.selectedLanguage == 'ta' ? 15.0 : 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: provider.selectedLanguage == 'ta' ? 1.35 : 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                                                ? context.l10n.profileVerified
                                                : context.l10n.profileIncomplete,
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
                                    Flexible(
                                      child: FitOneLine(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          profile.mobile.isNotEmpty
                                              ? '+91 ${profile.mobile}'
                                              : '-',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: Colors.white.withAlpha(230),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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
                                            : '-',
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
                      Expanded(
                        child: Text(
                          context.l10n.userInformation,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          context.l10n.editProfile,
                          style: GoogleFonts.inter(
                            fontSize: isTa ? 9.5 : 10.5,
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCol(
                        context.l10n.labelFullName,
                        profile.name.isNotEmpty ? profile.name : '-',
                        5,
                        isTamil: isTa,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        context.l10n.labelAge,
                        profile.dob != null ? '${profile.age}' : '-',
                        2,
                        isTamil: isTa,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCol(
                        context.l10n.labelGender,
                        profile.gender.isNotEmpty ? _getLocalizedProfileValue(profile.gender, context) : '-',
                        5,
                        isTamil: isTa,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        context.l10n.labelLocation,
                        profile.district.isNotEmpty
                            ? '${profile.district}, ${profile.state}'
                            : '-',
                        5,
                        isTamil: isTa,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2b. Eligibility & Professional Details Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
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
                          Icons.assignment_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.eligibilityProfessionalDetails,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Details Row 1: Qualification & Employment
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCol(
                        context.l10n.labelEducationLevel,
                        profile.qualification.isNotEmpty ? _getLocalizedProfileValue(profile.qualification, context) : '-',
                        1,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        context.l10n.labelEmployment,
                        profile.employmentStatus.isNotEmpty ? _getLocalizedProfileValue(profile.employmentStatus, context) : '-',
                        1,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),

                  // Details Row 2: Community & Income
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCol(
                        context.l10n.labelCommunityCategory,
                        profile.community.isNotEmpty ? _getLocalizedProfileValue(profile.community, context) : '-',
                        1,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        context.l10n.labelAnnualIncome,
                        _getLocalizedIncomeRange(profile.annualIncome, context),
                        1,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),

                  // Details Row 3: Special Statuses (Disability & Veteran)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCol(
                        context.l10n.labelDifferentlyAbled,
                        profile.disability.isNotEmpty && profile.disability != 'None'
                            ? _getLocalizedProfileValue(profile.disability, context)
                            : context.l10n.valNo,
                        1,
                      ),
                      _buildDividerCol(),
                      _buildInfoCol(
                        context.l10n.labelExServiceman,
                        profile.veteran ? context.l10n.valYes : context.l10n.valNo,
                        1,
                      ),
                    ],
                  ),

                  // Business Details (Optional)
                  if (profile.existingBusiness) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Color(0xFFF1F5F9), height: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.businessInformation,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCol(
                          context.l10n.labelBusinessStage,
                          profile.businessStage.isNotEmpty ? _getLocalizedProfileValue(profile.businessStage, context) : '-',
                          1,
                        ),
                        _buildDividerCol(),
                        _buildInfoCol(
                          context.l10n.labelIndustry,
                          profile.businessIndustry.isNotEmpty ? _getLocalizedProfileValue(profile.businessIndustry, context) : '-',
                          1,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Color(0xFFF1F5F9), height: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCol(
                          context.l10n.labelFundingRequired,
                          profile.fundingRequired > 0 
                              ? '₹${profile.fundingRequired.toStringAsFixed(0)}' 
                              : '-',
                          1,
                        ),
                        _buildDividerCol(),
                        _buildInfoCol(
                          context.l10n.labelRegNumbers,
                          profile.registrationNumbers.isNotEmpty ? profile.registrationNumbers : '-',
                          1,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            _buildGroupCard([
              _buildProfileTile(
                icon: Icons.bookmark_border_outlined,
                iconColor: const Color(0xFFEA580C),
                iconBgColor: const Color(0xFFFFF3E0),
                title: context.l10n.navSaved,
                subtitle: context.l10n.subSavedSchemes,
                onTap: () {
                  provider.updateTabIndex(3);
                },
              ),
              _buildProfileTile(
                icon: Icons.language_outlined,
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFF3E8FF),
                title: context.l10n.languageSetting,
                subtitle: context.l10n.subLanguage,
                trailingText: provider.selectedLanguage == 'ta'
                    ? 'தமிழ்'
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
                title: context.l10n.profileSettingsTitle,
                subtitle: context.l10n.subSettings,
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
                title: context.l10n.privacyPolicySetting,
                subtitle: context.l10n.subPrivacy,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.privacyPolicySetting),
                      content: Text(
                        context.l10n.privacyPolicyContent,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.l10n.dialogDone),
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
                title: context.l10n.helpFaqSetting,
                subtitle: context.l10n.subHelpSupport,
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
                title: context.l10n.aboutTitle,
                subtitle: context.l10n.subAbout,
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
                      Text(
                        context.l10n.aboutAppDescription,
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
                title: context.l10n.logoutButton,
                subtitle: context.l10n.subLogout,
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
