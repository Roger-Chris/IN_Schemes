import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/gradient_scaffold.dart';
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
  bool _darkMode = true; // Default dark mode since we use a premium dark blue theme

  void _handleDeleteAccount(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppConstants.cardBorderColor)),
          title: const Text('Delete Account', style: TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.bold)),
          content: const Text(
            'This action is irreversible. All your saved profiles, bookmarks, and questionnaire answers will be permanently deleted.',
            style: TextStyle(color: AppConstants.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                provider.logout(); // Clears all local storage
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 1. Preferences Section
          const Text('Preferences', style: TextStyle(fontSize: 14, color: AppConstants.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Get alerts on new matching schemes',
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          _buildSwitchTile(
            title: 'App Theme Preference',
            subtitle: 'Enable soft light-theme interface',
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
          ),
          _buildNavigationTile(
            title: 'App Language',
            subtitle: 'Selected language: ${provider.selectedLanguage == 'en' ? 'English' : 'हिन्दी'}',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // 2. Legal Section
          const Text('Legal & About', style: TextStyle(fontSize: 14, color: AppConstants.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          _buildNavigationTile(
            title: 'Privacy Policy',
            subtitle: 'How we protect your profile data',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Displaying Privacy Policy details...')),
              );
            },
          ),
          _buildNavigationTile(
            title: 'Terms & Conditions',
            subtitle: 'Guidelines for using IN schemes matcher',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Displaying Terms & Conditions details...')),
              );
            },
          ),
          
          // Info tile
          ListTile(
            title: const Text('App Version', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('v1.0.0 (National Entrepreneurs\' Day Build)', style: TextStyle(color: AppConstants.secondaryText, fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppConstants.backgroundColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppConstants.cardBorderColor)),
              child: const Text('Stable', style: TextStyle(color: AppConstants.secondaryText, fontSize: 10)),
            ),
          ),
          const SizedBox(height: 24),
          
          // 3. Danger Zone Section
          const Text('Danger Zone', style: TextStyle(fontSize: 14, color: AppConstants.errorColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          _buildDangerTile(
            title: 'Delete My Account',
            subtitle: 'Permanently remove profile details and settings',
            onTap: () => _handleDeleteAccount(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardBorderColor),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppConstants.secondaryText, fontSize: 11)),
        value: value,
        activeThumbColor: AppConstants.primaryColor,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardBorderColor),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppConstants.secondaryText, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppConstants.secondaryText, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.errorColor),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppConstants.secondaryText, fontSize: 11)),
        trailing: const Icon(Icons.delete_forever, color: AppConstants.errorColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}
