import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import 'edit_profile_screen.dart';
import 'search_results_screen.dart';
import 'notifications_screen.dart';
import '../settings_screen.dart';

class CustomNavigationDrawer extends StatelessWidget {
  final String activeItem; // e.g., 'Home', 'Search Schemes', etc.

  const CustomNavigationDrawer({
    super.key,
    required this.activeItem,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final profile = provider.profile;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Close ('X') button right-aligned
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF0F172A), size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // User Profile Snippet
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 3D Avatar image container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            backgroundImage: profile.profilePhoto.isNotEmpty && File(profile.profilePhoto).existsSync()
                                ? FileImage(File(profile.profilePhoto))
                                : const AssetImage('assets/saarthi_expressions/01_happy.png') as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name.isNotEmpty ? profile.name : "Not Set",
                                style: GoogleFonts.inter(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "View Profile >",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Navigation List (Expanded ListView to prevent overflow)
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  DrawerItem(
                    icon: Icons.home_outlined,
                    text: "Home",
                    isSelected: activeItem == "Home",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  DrawerItem(
                    icon: Icons.search,
                    text: "Search Schemes",
                    isSelected: activeItem == "Search Schemes",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchResultsScreen(searchQuery: ''),
                        ),
                      );
                    },
                  ),
                  DrawerItem(
                    icon: Icons.bookmark_border,
                    text: "Saved Schemes",
                    isSelected: activeItem == "Saved Schemes",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  DrawerItem(
                    icon: Icons.assignment_outlined,
                    text: "My Applications",
                    isSelected: activeItem == "My Applications",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  DrawerItem(
                    icon: Icons.person_outline,
                    text: "Profile",
                    isSelected: activeItem == "Profile",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                  ),
                  DrawerItem(
                    icon: Icons.settings_outlined,
                    text: "Settings",
                    isSelected: activeItem == "Settings",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  DrawerItem(
                    icon: Icons.notifications_none,
                    text: "Notifications",
                    isSelected: activeItem == "Notifications",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CompanionNotificationsScreen()),
                      );
                    },
                  ),
                  DrawerItem(
                    icon: Icons.help_outline,
                    text: "Help & Support",
                    isSelected: activeItem == "Help & Support",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  DrawerItem(
                    icon: Icons.info_outline,
                    text: "About Saarthi",
                    isSelected: activeItem == "About Saarthi",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Action (Fixed at bottom)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEA580C),
                  side: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable DrawerItem private widget
class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
