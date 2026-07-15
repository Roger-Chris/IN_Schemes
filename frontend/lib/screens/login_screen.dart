import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../main.dart';
import 'otp_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    setState(() {
      _phoneError = null;
    });

    final phone = _phoneController.text.trim();
    if (phone.length != 10 || double.tryParse(phone) == null) {
      setState(() {
        _phoneError = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network latency
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to +91 $phone (Use 123456 to test)'),
            backgroundColor: AppConstants.successColor,
          ),
        );

        // Direct user to separate OTP Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(phoneNumber: phone),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Content (Fit to page, scrollable only when keyboard is visible to prevent overflow)
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            children: [
                              const Spacer(flex: 1),
                              
                              // Brand Logo
                              Image.asset(
                                'assets/images/Logo.png',
                                height: 125,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              
                              // Title
                              Text(
                                'Welcome!',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A), // Slate 900
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Subtitle
                              Text(
                                'Login or sign up to discover and explore government schemes that empower you.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B), // Slate 500
                                  height: 1.3,
                                ),
                              ),
                              
                              const Spacer(flex: 1),
                              
                              // Main Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Color(0x08000000), // 3% opacity
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: _buildLoginForm(),
                              ),
                              
                              const Spacer(flex: 2),
                              
                              // Bottom Privacy Policy & Terms Section
                              _buildPrivacySection(),
                              
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Login with Mobile Number',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A), // Slate 900
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We\'ll send a 6-digit OTP to verify your identity.',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF64748B), // Slate 500
          ),
        ),
        const SizedBox(height: 16),
        
        // Form Label
        Text(
          'Mobile Number',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B), // Slate 800
          ),
        ),
        const SizedBox(height: 6),
        
        // Input Box Row with Country Code & Text Field
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Code +91 box
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // Slate 50
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)), // Slate 300
              ),
              child: Row(
                children: [
                  Text(
                    '+91',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0xFFCBD5E1), // Vertical Divider
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            
            // Phone number text field
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit number',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8), // Slate 400
                  ),
                  counterText: '',
                  errorText: _phoneError,
                  errorStyle: const TextStyle(color: AppConstants.errorColor),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)), // Slate 300
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D47A1)), // Royal Blue
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppConstants.errorColor),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppConstants.errorColor),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        
        // Send OTP Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1), // Royal Blue
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _sendOtp,
            child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Send OTP',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
          ),
        ),
        const SizedBox(height: 16),
        
        // OR Divider
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 16),
        
        // Social Media Buttons
        Row(
          children: [
            // Google Button
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  fixedSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          final provider = Provider.of<AppProvider>(context, listen: false);
                          final success = await provider.loginWithGoogle();
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Successfully logged in with Google!'),
                                backgroundColor: AppConstants.successColor,
                              ),
                            );
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const ProfileSetupScreen(),
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Google Sign-In failed or was cancelled.'),
                                backgroundColor: AppConstants.errorColor,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppConstants.errorColor,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoogleIcon(size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Google',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569), // Slate 600
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Apple Button
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  fixedSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.apple,
                      color: Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Apple',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569), // Slate 600
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Continue as Guest Box
        _buildGuestBox(),
      ],
    );
  }

  Widget _buildGuestBox() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return InkWell(
      onTap: () {
        provider.continueAsGuest();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainTabsContainer(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF), // Blue 50
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDBEAFE)), // Blue 100
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDBEAFE), // Blue 100
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF1D4ED8), // Blue 700
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue as Guest',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D4ED8), // Blue 700
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Explore the app without signing in.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B), // Slate 500
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: Color(0xFF1D4ED8), // Blue 700
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.white70,
          height: 1.5,
        ),
        children: const [
          TextSpan(text: 'By continuing, you agree to our\n'),
          TextSpan(
            text: 'Terms & Conditions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Notice',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: '.'),
        ],
      ),
    );
  }
}

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double s = w / 24.0; // scale factor based on 24x24 standard viewport

    final paint = Paint()..style = PaintingStyle.fill;

    // Red (Top Arc)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0 * s, 5.04 * s)
      ..cubicTo(13.94 * s, 5.04 * s, 15.73 * s, 5.71 * s, 17.12 * s, 7.01 * s)
      ..lineTo(20.94 * s, 3.19 * s)
      ..cubicTo(18.57 * s, 1.05 * s, 15.52 * s, 0, 12.0 * s, 0)
      ..cubicTo(7.35 * s, 0, 3.32 * s, 2.67 * s, 1.34 * s, 6.57 * s)
      ..lineTo(5.67 * s, 9.93 * s)
      ..cubicTo(6.7 * s, 7.04 * s, 9.11 * s, 5.04 * s, 12.0 * s, 5.04 * s)
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow (Left Arc)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.67 * s, 14.07 * s)
      ..cubicTo(5.41 * s, 13.3 * s, 5.26 * s, 12.47 * s, 5.26 * s, 11.5 * s)
      ..cubicTo(5.26 * s, 10.53 * s, 5.41 * s, 9.7 * s, 5.67 * s, 8.93 * s)
      ..lineTo(1.34 * s, 5.57 * s)
      ..cubicTo(0.48 * s, 7.29 * s, 0, 9.22 * s, 0, 11.5 * s)
      ..cubicTo(0, 13.78 * s, 0.48 * s, 15.71 * s, 1.34 * s, 17.43 * s)
      ..lineTo(5.67 * s, 14.07 * s)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green (Bottom Arc)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0 * s, 18.96 * s)
      ..cubicTo(9.11 * s, 18.96 * s, 6.7 * s, 16.96 * s, 5.67 * s, 14.07 * s)
      ..lineTo(1.34 * s, 17.43 * s)
      ..cubicTo(3.32 * s, 21.33 * s, 7.35 * s, 24.0 * s, 12.0 * s, 24.0 * s)
      ..cubicTo(15.19 * s, 24.0 * s, 18.07 * s, 22.95 * s, 20.16 * s, 21.14 * s)
      ..lineTo(16.15 * s, 18.03 * s)
      ..cubicTo(15.01 * s, 18.8 * s, 13.56 * s, 18.96 * s, 12.0 * s, 18.96 * s)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue (Right & Bar)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.49 * s, 12.27 * s)
      ..cubicTo(23.49 * s, 11.46 * s, 23.42 * s, 10.65 * s, 23.29 * s, 9.87 * s)
      ..lineTo(12.0 * s, 9.87 * s)
      ..lineTo(12.0 * s, 14.41 * s)
      ..lineTo(18.44 * s, 14.41 * s)
      ..cubicTo(18.16 * s, 15.88 * s, 17.33 * s, 17.12 * s, 16.08 * s, 17.96 * s)
      ..lineTo(20.09 * s, 21.07 * s)
      ..cubicTo(22.43 * s, 18.91 * s, 23.49 * s, 15.73 * s, 23.49 * s, 12.27 * s)
      ..close();
    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
