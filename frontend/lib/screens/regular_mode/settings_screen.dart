import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n.dart';
import 'language_selection_screen.dart';
import 'basic_profile_screen.dart';
import 'help_support_screen.dart';
import '../../widgets/custom_confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;

  void _handleDeleteAccount(BuildContext context, AppProvider provider) {
    CustomConfirmDialog.show(
      context,
      icon: Icons.delete_forever_rounded,
      iconColor: AppConstants.errorColor,
      iconBgColor: const Color(0xFFFEE2E2),
      title: context.l10n.deleteAccountTitle,
      message: context.l10n.deleteAccountMsg,
      confirmLabel: context.l10n.deleteButton,
      confirmColor: AppConstants.errorColor,
      onConfirm: () => provider.deleteAccount(context),
      isDestructive: true,
    );
  }

  void _showNavigationModePopup(
    BuildContext context,
    AppProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.navigationModeSetting,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose your preferred layout mode for navigating schemes and services.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                _buildModeOption(
                  context: context,
                  provider: provider,
                  mode: 'regular',
                  title: 'Regular Navigation',
                  subtitle: 'Traditional clean list and tab view layout',
                  icon: Icons.layers_outlined,
                ),
                const SizedBox(height: 12),
                _buildModeOption(
                  context: context,
                  provider: provider,
                  mode: 'companion',
                  title: 'AI Companion (Saarthi)',
                  subtitle: 'Voice-first AI guided conversational view',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required AppProvider provider,
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = provider.navigationMode == mode;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        provider.changeNavigationMode(mode);
        provider.updateTabIndex(0);
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mode == 'companion' 
                  ? 'Switched to AI Companion (Saarthi) Navigation' 
                  : 'Switched to Regular Navigation',
            ),
            backgroundColor: const Color(0xFF2563EB),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
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
          context.l10n.profileSettingsTitle,
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
            // Adaptive Profile Header Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      provider.profile.name.isNotEmpty ? provider.profile.name[0].toUpperCase() : 'U',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.profile.name.isNotEmpty ? provider.profile.name : 'User',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: provider.selectedLanguage == 'ta' ? 14.5 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            height: provider.selectedLanguage == 'ta' ? 1.35 : 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.profile.mobile.isNotEmpty
                              ? provider.profile.mobile
                              : (provider.mobileNumber.isNotEmpty ? provider.mobileNumber : '+91'),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.profileCompletionFormat(provider.profileCompletionPercentage),
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // GROUP 0: Profile
            _buildGroupHeader(context.l10n.profileGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.person_outline,
                title: context.l10n.completeProfileTitle,
                value: context.l10n.profileCompletionFormat(provider.profileCompletionPercentage),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BasicProfileScreen(),
                    ),
                  );
                },
                isLast: true,
              ),
            ]),

            // GROUP 1: Preferences
            _buildGroupHeader(context.l10n.preferencesGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.language,
                title: context.l10n.languageSetting,
                value: provider.selectedLanguage == 'ta' ? 'தமிழ்' : 'English',
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
                title: context.l10n.navigationModeSetting,
                value: provider.navigationMode == 'companion'
                    ? context.l10n.navigationModeCompanion
                    : context.l10n.navigationModeRegular,
                onTap: () => _showNavigationModePopup(context, provider),
                isLast: true,
              ),
            ]),

            // GROUP 3: Notifications
            _buildGroupHeader(context.l10n.notificationsGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.notifications_none,
                title: context.l10n.pushNotificationsSetting,
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
                                ? context.l10n.notificationsEnabled
                                : context.l10n.notificationsDisabled,
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF2563EB),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ]),

            // GROUP 4: Security & Privacy
            _buildGroupHeader(context.l10n.securityPrivacyGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.security,
                title: context.l10n.privacyPolicySetting,
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
                        context.l10n.privacyPolicySetting,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        context.l10n.privacyPolicyContent,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            context.l10n.dialogDone,
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
              _buildSettingRow(
                icon: Icons.article_outlined,
                title: context.l10n.termsConditionsSetting,
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
                        context.l10n.termsConditionsSetting,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        context.l10n.termsConditionsContent,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            context.l10n.dialogDone,
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
              _buildSettingRow(
                icon: Icons.delete_outline,
                title: context.l10n.deleteAccountSetting,
                titleColor: const Color(0xFFDC2626),
                onTap: () => _handleDeleteAccount(context, provider),
                isLast: true,
              ),
            ]),

            // GROUP 5: Support
            _buildGroupHeader(context.l10n.supportGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.help_outline,
                title: context.l10n.helpFaqSetting,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(initialMode: 'faq'),
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.contact_support_outlined,
                title: context.l10n.contactUsSetting,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(initialMode: 'contact'),
                    ),
                  );
                },
                isLast: true,
              ),
            ]),
            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(
                context.l10n.logoutButton,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
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
            color: titleColor ?? const Color(0xFF2563EB),
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
