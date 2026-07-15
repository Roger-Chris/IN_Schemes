import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'profile_setup_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;
  String? _otpError;
  
  // Timer State
  int _secondsRemaining = 116; // 1:56 matching screenshot default
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 116;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime() {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _resendOtp() {
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new OTP has been sent to your number. (Use 123456 to test)'),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  void _verifyOtp() {
    setState(() {
      _otpError = null;
    });

    final otpStr = _controllers.map((c) => c.text).join();
    if (otpStr.length < 6) {
      setState(() {
        _otpError = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    if (otpStr != '123456') {
      setState(() {
        _otpError = 'Invalid OTP. Enter 123456 to continue.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Login user in provider
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.login(widget.phoneNumber);

        // Redirect to profile setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen(),
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
          
          // 2. Content Layout
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
                              // Top Back Button & Header Row
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Color(0xFF0F172A),
                                      size: 24,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              
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
                                'Verify Your Mobile Number',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A), // Slate 900
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Subtitle
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'We have sent a 6-digit OTP to ',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    '+91 ${widget.phoneNumber.substring(0, 5)} ${widget.phoneNumber.substring(5)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D47A1), // Royal Blue
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: Color(0xFF0D47A1),
                                      size: 13,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const Spacer(flex: 1),
                              
                              // Input Box Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Color(0x08000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Enter the 6-digit OTP',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // 6 separate digit input fields
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(6, (index) {
                                        return SizedBox(
                                          width: 42,
                                          height: 52,
                                          child: TextFormField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            maxLength: 1,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0D47A1),
                                            ),
                                            decoration: InputDecoration(
                                              counterText: '',
                                              contentPadding: EdgeInsets.zero,
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                if (index < 5) {
                                                  _focusNodes[index + 1].requestFocus();
                                                } else {
                                                  _focusNodes[index].unfocus();
                                                  _verifyOtp();
                                                }
                                              } else {
                                                if (index > 0) {
                                                  _focusNodes[index - 1].requestFocus();
                                                }
                                              }
                                            },
                                          ),
                                        );
                                      }),
                                    ),
                                    
                                    if (_otpError != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _otpError!,
                                        style: GoogleFonts.inter(
                                          color: AppConstants.errorColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 14),
                                    
                                    // Timer display
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Color(0xFF0D47A1),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: const Color(0xFF64748B),
                                            ),
                                            children: [
                                              const TextSpan(text: 'OTP expires in '),
                                              TextSpan(
                                                text: _formatTime(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D47A1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    
                                    // Security Info Box
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF), // Blue 50
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFDBEAFE)), // Blue 100
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.verified_user_outlined,
                                            color: Color(0xFF2563EB),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'For your security, do not share this OTP with anyone.',
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    
                                    // Verify & Continue Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D47A1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: _verifyOtp,
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
                                                    'Verify & Continue',
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
                                    const SizedBox(height: 14),
                                    
                                    // Resend text
                                    GestureDetector(
                                      onTap: _resendOtp,
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                          children: const [
                                            TextSpan(text: 'Didn\'t receive OTP? '),
                                            TextSpan(
                                              text: 'Resend OTP',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0D47A1),
                                              ),
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
                                    
                                    // Change Mobile Number
                                    InkWell(
                                      onTap: () => Navigator.of(context).pop(),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.chat_bubble_outline,
                                              color: Color(0xFF0D47A1),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Change Mobile Number',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF0D47A1),
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF0D47A1),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const Spacer(flex: 2),
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
}
