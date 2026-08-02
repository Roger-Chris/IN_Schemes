import 'package:flutter/material.dart';

class FloatingLogo extends StatelessWidget {
  const FloatingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/Logo/Logo.png',
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
    );
  }
}
