import 'package:flutter/material.dart';

class AntiGravityHeroSection extends StatefulWidget {
  final int activeDotIndex;
  
  const AntiGravityHeroSection({
    super.key,
    this.activeDotIndex = 0,
  });

  @override
  State<AntiGravityHeroSection> createState() => _AntiGravityHeroSectionState();
}

class _AntiGravityHeroSectionState extends State<AntiGravityHeroSection> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
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
    final size = MediaQuery.of(context).size;
    final heroHeight = size.height * 0.38; // Covering 35-40% of the screen

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Layer 1: Sky Gradient (Very light, no dark shadows)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8F3FC), 
                    Color(0xFFF4F9FF),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // Layer 2: Soft Blurry Clouds (Using MaskFilter.blur for soft dispersed clouds)
          Positioned.fill(
            child: CustomPaint(
              painter: SoftCloudPainter(),
            ),
          ),

          // Layer 3: The India Map & Logo Floating Group
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // MAP PLACEHOLDER
                    Opacity(
                      opacity: 0.05,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueGrey, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text("SVG Map Here")),
                      ),
                    ),

                    // Radial Glow behind logo
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8BB4F6).withValues(alpha: 0.2), 
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),

                    // Logo, Tagline, and Onboarding Dots
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- CUSTOM 'iN' LOGO ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF97316), // Orange
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 14,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1644A6), // Blue
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Text(
                                  'N',
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1644A6),
                                    height: 1.0,
                                    letterSpacing: -4,
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: 10,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF15803D), // Green
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.settings, 
                                        color: Colors.white, 
                                        size: 11
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'IN Schemes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1644A6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 12, height: 1.5, color: Colors.orange),
                            const SizedBox(width: 6),
                            const Text(
                              'Discover every Government Scheme in India',
                              style: TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(width: 12, height: 1.5, color: Colors.green),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Onboarding indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isActive = index == widget.activeDotIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 8.0 : 6.0,
                              height: isActive ? 8.0 : 6.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? const Color(0xFF1644A6) // Primary blue accent
                                    : const Color(0xFFCBD5E1), // Neutral grey
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to render soft, feathered clouds without dark shadows
class SoftCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill
      // This MaskFilter ensures the shapes render as soft clouds, not hard shapes
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40); 

    // Cloud Top Left
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.1), 50, paint);
    
    // Cloud Top Right
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.25), 70, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.15), 60, paint);

    // Cloud Bottom Left (Atmosphere)
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.7), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
