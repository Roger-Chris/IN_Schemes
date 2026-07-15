import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'profile_setup_screen.dart';
import 'saved_schemes_screen.dart';
import 'language_selection_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppConstants.cardBorderColor)),
          title: const Text('Confirm Logout', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out from IN schemes?', style: TextStyle(color: AppConstants.secondaryText)),
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
                provider.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final profile = provider.profile;
    final isGuest = provider.isGuest;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Profile Card Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.cardBorderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppConstants.accentColor,
                    radius: 36,
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'G',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name.isNotEmpty ? profile.name : 'Guest User',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGuest ? 'Guest Session' : '+91 ${provider.mobileNumber}',
                          style: const TextStyle(fontSize: 13, color: AppConstants.secondaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'State: ${profile.state}',
                          style: const TextStyle(fontSize: 12, color: AppConstants.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Options List
            _buildOptionTile(
              icon: Icons.edit_outlined,
              title: 'Edit Personal Profile',
              subtitle: 'Update details, education, address',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.track_changes,
              title: 'Eligibility Matcher Wizard',
              subtitle: 'Run wizard to compute matching schemes',
              onTap: () {
                provider.startWizard();
                provider.updateTabIndex(3); // Navigate to wizard tab
              },
            ),
            _buildOptionTile(
              icon: Icons.bookmark_border_outlined,
              title: 'Saved & Bookmarked Schemes',
              subtitle: 'View saved and recently opened schemes',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedSchemesScreen()),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.translate_outlined,
              title: 'Language Preference',
              subtitle: 'Change app language (English / Hindi)',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.settings_outlined,
              title: 'App Settings',
              subtitle: 'Configure dark mode, notifications',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.help_outline_outlined,
              title: 'Help & Support',
              subtitle: 'FAQs, contact information, feedback',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Logout
            _buildOptionTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Clear session data from device',
              color: AppConstants.errorColor,
              onTap: () => _handleLogout(context, provider),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.cardBorderColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppConstants.secondaryColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? AppConstants.primaryText, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppConstants.secondaryText, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppConstants.secondaryText, size: 14),
        onTap: onTap,
      ),
    );
  }
}
