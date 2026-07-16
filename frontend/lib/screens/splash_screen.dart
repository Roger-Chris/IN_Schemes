import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'language_selection_screen.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Auto navigate after 3.2 seconds
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        if (provider.isLoggedIn || provider.isGuest) {
          provider.updateTabIndex(0); // Ensure home page is the first page shown
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MainTabsContainer(),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LanguageSelectionScreen(),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full screen background
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Animated Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                   const Spacer(flex: 2),
                  
                  // Brand Logo centered
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Image.asset(
                        'assets/images/Logo.png',
                        width: size.width * 0.60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.account_balance,
                                size: 80,
                                color: AppConstants.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'IN schemes',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 5),
                  
                  // Loading Section at the bottom overlaying the blue wave
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: size.width * 0.5,
                          child: const ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading...',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we prepare\nsomething amazing for you',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
