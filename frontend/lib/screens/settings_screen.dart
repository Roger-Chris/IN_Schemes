import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'language_selection_screen.dart';
import 'profile_setup_screen.dart';

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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: Text(
            'Delete Account',
            style: GoogleFonts.inter(
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
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppConstants.secondaryText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: provider.isLoggingOut
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      provider.deleteAccount(context);
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

  void _showNavigationModeBottomSheet(
    BuildContext context,
    AppProvider provider,
  ) {
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
                          color: Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.explore_outlined,
                          color: Color(0xFFEA580C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Choose Navigation Mode',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Regular Navigation',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Traditional mobile experience',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    trailing: provider.navigationMode == 'regular'
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFEA580C),
                            size: 24,
                          )
                        : const Icon(
                            Icons.circle_outlined,
                            color: Color(0xFFCBD5E1),
                            size: 24,
                          ),
                    onTap: () {
                      provider.changeNavigationMode('regular');
                      setModalState(() {});
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(
                      'Companion Navigation',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Voice-first guided experience',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    trailing: provider.navigationMode == 'companion'
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFEA580C),
                            size: 24,
                          )
                        : const Icon(
                            Icons.circle_outlined,
                            color: Color(0xFFCBD5E1),
                            size: 24,
                          ),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Settings",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          children: [
            // GROUP 0: Profile
            _buildGroupHeader("Profile"),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.person_outline,
                title: "Complete Profile",
                value: "${provider.profileCompletionPercentage}% completed",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSetupScreen(),
                    ),
                  );
                },
                isLast: true,
              ),
            ]),

            // GROUP 1: Preferences
            _buildGroupHeader("Preferences"),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.language,
                title: "Language",
                value: provider.selectedLanguage == 'hi' ? 'हिन्दी' : 'English',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.explore_outlined,
                title: "Navigation Mode",
                value: provider.navigationMode == 'companion'
                    ? 'Companion'
                    : 'Regular',
                onTap: () => _showNavigationModeBottomSheet(context, provider),
              ),
              _buildSettingRow(
                icon: Icons.nightlight_outlined,
                title: "Dark Mode",
                widget: SizedBox(
                  height: 24,
                  child: Switch(
                    value: _darkMode,
                    onChanged: (val) => setState(() => _darkMode = val),
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFFEA580C),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ]),

            // GROUP 2: Notifications
            _buildGroupHeader("Notifications"),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.notifications_none,
                title: "Push Notifications",
                widget: SizedBox(
                  height: 24,
                  child: Switch(
                    value: _pushNotifications,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
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
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFFEA580C),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ]),

            // GROUP 3: Security & Privacy
            _buildGroupHeader("Security & Privacy"),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.security,
                title: "Privacy Policy",
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'Your privacy is important to us. All personal data is encrypted and saved locally on this device.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Done',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.article_outlined,
                title: "Terms & Conditions",
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'By using IN Schemes, you agree to our terms of service. All scheme information is aggregated from official government portals.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Done',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.delete_outline,
                title: "Delete Account",
                titleColor: const Color(0xFFDC2626),
                onTap: () => _handleDeleteAccount(context, provider),
                isLast: true,
              ),
            ]),

            // GROUP 4: Support
            _buildGroupHeader("Support"),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.help_outline,
                title: "Help & FAQ",
                onTap: () {},
              ),
              _buildSettingRow(
                icon: Icons.contact_support_outlined,
                title: "Contact Us",
                onTap: () {},
                isLast: true,
              ),
            ]),
            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEA580C),
                side: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(
                "Logout",
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                provider.logout(context);
              },
            ),
            const SizedBox(height: 16),

            // Centered App Version Footer
            Center(
              child: Text(
                "App Version 1.2.0",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? value,
    Widget? widget,
    VoidCallback? onTap,
    Color? titleColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Icon(
            icon,
            color: titleColor ?? const Color(0xFFEA580C),
            size: 20,
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: titleColor ?? const Color(0xFF0F172A),
            ),
          ),
          trailing:
              widget ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                ],
              ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}
