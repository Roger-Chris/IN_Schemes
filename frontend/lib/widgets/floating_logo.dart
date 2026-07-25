import 'package:flutter/material.dart';

class FloatingLogo extends StatefulWidget {
  const FloatingLogo({super.key});

  @override
  State<FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<FloatingLogo> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/Logo.png',
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 16, height: 1.5, color: const Color(0xFFF97316)), // Orange
              const SizedBox(width: 8),
              const Text(
                'Discover every Government Scheme in India',
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 16, height: 1.5, color: const Color(0xFF15803D)), // Green
            ],
          ),
        ],
      ),
    );
  }
}
