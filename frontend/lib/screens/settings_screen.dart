import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = false;

  void _handleDeleteAccount(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: Text(
            'Delete Account',
            style: GoogleFonts.poppins(
              color: AppConstants.errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This action is irreversible. All your saved profiles, bookmarks, and questionnaire answers will be permanently deleted.',
            style: GoogleFonts.inter(color: AppConstants.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppConstants.secondaryText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                provider.logout(); // Clears all local storage
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(
                'Delete Permanently',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNavigationModeBottomSheet(BuildContext context, AppProvider provider) {
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3E8FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.explore_outlined, color: Color(0xFF7C3AED), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Choose Navigation Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Regular Navigation', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    subtitle: Text('Traditional mobile experience', style: GoogleFonts.inter(fontSize: 12)),
                    trailing: provider.navigationMode == 'regular'
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 24)
                        : const Icon(Icons.circle_outlined, color: Color(0xFFCBD5E1), size: 24),
                    onTap: () {
                      provider.changeNavigationMode('regular');
                      setModalState(() {});
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Companion Navigation', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    subtitle: Text('Voice-first guided experience', style: GoogleFonts.inter(fontSize: 12)),
                    trailing: provider.navigationMode == 'companion'
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFF97316), size: 24)
                        : const Icon(Icons.circle_outlined, color: Color(0xFFCBD5E1), size: 24),
                    onTap: () {
                      provider.changeNavigationMode('companion');
                      setModalState(() {});
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildSettingCard({
    required Widget leadingIcon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? cardColor,
    Color? borderColor,
    Color? titleColor,
    Color? subtitleColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                leadingIcon,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: subtitleColor ?? const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF0F172A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your app preferences and account settings',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Language Card
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.public_rounded,
                bgColor: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
              ),
              title: 'Language',
              subtitle: 'Choose your preferred language',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.selectedLanguage == 'hi' ? 'हिन्दी' : 'English',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                );
              },
            ),

            // 2. Notifications Card
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.notifications_none_rounded,
                bgColor: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF97316),
              ),
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _pushNotifications ? 'On' : 'Off',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
              onTap: () {
                setState(() {
                  _pushNotifications = !_pushNotifications;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _pushNotifications 
                        ? 'Notifications enabled' 
                        : 'Notifications disabled',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),

            // 3. Dark Mode Card
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.nightlight_outlined,
                bgColor: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
              ),
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              trailing: SizedBox(
                height: 24,
                child: Switch(
                  value: _darkMode,
                  onChanged: (val) {
                    setState(() {
                      _darkMode = val;
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF2563EB),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE2E8F0),

                ),
              ),
            ),

            // 3.5. Navigation Mode Card
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.explore_outlined,
                bgColor: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
              ),
              title: 'Navigation Mode',
              subtitle: 'Choose between Regular and Companion mode',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.navigationMode == 'companion' ? 'Companion' : 'Regular',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: provider.navigationMode == 'companion' ? const Color(0xFFF97316) : const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
              onTap: () => _showNavigationModeBottomSheet(context, provider),
            ),

            // 4. Privacy Card
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.shield_outlined,
                bgColor: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
              ),
              title: 'Privacy',
              subtitle: 'Manage your privacy and data settings',
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Your privacy is important to us. All personal data is encrypted and saved locally on this device.',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 5. Terms & Conditions Card
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.article_outlined,
                bgColor: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
              ),
              title: 'Terms & Conditions',
              subtitle: 'Read our terms and conditions',
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    title: Text(
                      'Terms & Conditions',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'By using IN Schemes, you agree to our terms of service. All scheme information is aggregated from official government portals.',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 6. App Version Card
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.info_outline_rounded,
                bgColor: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
              ),
              title: 'App Version',
              subtitle: 'Current version and updates',
              trailing: Text(
                '1.2.0 (120)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),

            // 7. Delete Account Card (Styled Red/Pink)
            _buildSettingCard(
              leadingIcon: _buildCircleIcon(
                icon: Icons.delete_outline_rounded,
                bgColor: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
              ),
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              cardColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFEE2E2),
              titleColor: const Color(0xFFDC2626),
              subtitleColor: const Color(0xFF991B1B).withAlpha(180),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFDC2626),
                size: 18,
              ),
              onTap: () => _handleDeleteAccount(context, provider),
            ),

            const SizedBox(height: 32),

            // Centered Security Footer
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your data is secure with us',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'We respect your privacy and protect your information',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

