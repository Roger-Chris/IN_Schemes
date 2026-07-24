import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_state_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_schemes_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://houpzsxmwemoztpuigmo.supabase.co',
    publishableKey: 'sb_publishable_SwlgaGsCt5N-97WwEq7tQw_aNT25VUI',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const InSchemesApp(),
    ),
  );
}

class InSchemesApp extends StatelessWidget {
  const InSchemesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'IN schemes',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppConstants.primaryColor,
            scaffoldBackgroundColor: AppConstants.backgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryColor,
              primary: AppConstants.primaryColor,
              secondary: AppConstants.secondaryColor,
              error: AppConstants.errorColor,
            ),
            useMaterial3: true,
            textTheme: TextTheme(
              // Poppins for App Logo & Titles
              headlineLarge: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
              titleLarge: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
              titleMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: AppConstants.primaryText),
              titleSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.primaryText),
              
              // Inter for Body and Form Elements
              bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: AppConstants.primaryText),
              bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.normal, color: AppConstants.primaryText),
              bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal, color: AppConstants.secondaryText),
              
              labelLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), // Button
              labelMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.secondaryText), // Form Label
              labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: AppConstants.secondaryText), // Small Info
            ),
            // Styling for premium light cards
            cardTheme: CardThemeData(
              color: AppConstants.surfaceColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppConstants.cardBorderColor),
              ),
            ),
          ),
          // Set initial screen based on login state
          home: const SplashScreen(),
        );
      },
    );
  }
}

// Wrapper for Persistent Bottom Navigation Tabs Container
class MainTabsContainer extends StatelessWidget {
  const MainTabsContainer({super.key});

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    AppProvider provider,
  ) {
    final isSelected = provider.currentTabIndex == index;
    final color = isSelected ? const Color(0xFF0D47A1) : const Color(0xFF64748B);

    Widget iconWidget = Icon(
      isSelected ? activeIcon : icon,
      color: color,
      size: 24,
    );

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => provider.updateTabIndex(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // List of screens matching tabs
    final List<Widget> tabs = [
      const HomeScreen(),
      const CategoriesScreen(),
      const SearchScreen(),
      const SavedSchemesScreen(),
      const ProfileScreen(),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: AppConstants.blueGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: provider.currentTabIndex,
          children: tabs,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', provider),
                _buildNavItem(1, Icons.grid_view_outlined, Icons.grid_view, 'Categories', provider),
                _buildNavItem(2, Icons.search, Icons.search_sharp, 'Search', provider),
                _buildNavItem(3, Icons.bookmark_border, Icons.bookmark, 'Saved', provider),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile', provider),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
