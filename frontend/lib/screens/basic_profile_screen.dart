import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'location_profile_screen.dart';

class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({super.key});

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  // Form controllers with default values
  final _nameController = TextEditingController(text: 'Roger Christopher');
  final _emailController = TextEditingController(text: 'rogerchristopher@gmail.com');
  final _phoneController = TextEditingController(text: '98765 43210'); // reserved prefix
  final _dobController = TextEditingController(text: '04-Oct-2001'); // DOB calendar selector

  String _selectedGender = 'Male';
  DateTime _selectedDob = DateTime(2001, 10, 4);

  // Constants
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate800 = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);
  static const Color kInfoBlueBg = Color(0xFFF0F5FA);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/Login_bg.webp', // Matching the verified webp asset
              fit: BoxFit.cover,
            ),
          ),

          // 2. Foreground Layer
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: kSlate800, size: 24),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2), // Tighter spacing between back button and heading

                    // Header Text (Moved out of the card)
                    Text(
                      'Complete Your Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kSlate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let's start with your basic details.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: kSlate500,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced spacing below header

                    // Main Card Container
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Inner Scrollable Content
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Custom Stepper
                                    _buildStepper(),
                                    const SizedBox(height: 12),

                                    // Completion Pill
                                    Center(child: _buildProgressPill()),
                                    const SizedBox(height: 20),

                                    // Form Fields
                                    CustomInputField(
                                      label: 'Full Name',
                                      controller: _nameController,
                                      leadingIcon: Icons.person_outline,
                                      trailingIcon: Icons.edit_outlined,
                                    ),
                                    const SizedBox(height: 16),

                                    CustomInputField(
                                      label: 'Email Address',
                                      controller: _emailController,
                                      leadingIcon: Icons.mail_outline,
                                      trailingIcon: Icons.edit_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),

                                    CustomInputField(
                                      label: 'Phone Number',
                                      controller: _phoneController,
                                      leadingIcon: Icons.phone_outlined,
                                      trailingIcon: Icons.edit_outlined,
                                      keyboardType: TextInputType.phone,
                                      prefixText: '+91 ', // Reserve +91 country code
                                    ),
                                    const SizedBox(height: 16),

                                    // Gender Selector (Now spans full card width)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gender',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: kSlate900,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(child: _buildGenderBox('Male', Icons.male)),
                                            const SizedBox(width: 6),
                                            Expanded(child: _buildGenderBox('Female', Icons.female)),
                                            const SizedBox(width: 6),
                                            Expanded(child: _buildGenderBox('Other', Icons.transgender)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // DOB Selector (Moved to a new line)
                                    CustomInputField(
                                      label: 'Date of Birth (DOB)',
                                      controller: _dobController,
                                      leadingIcon: Icons.calendar_today_outlined,
                                      trailingIcon: Icons.arrow_drop_down,
                                      readOnly: true,
                                      onTap: () => _selectDob(context),
                                    ),
                                    const SizedBox(height: 24),

                                    // Info Box
                                    _buildInfoBox(),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),

                            // Sticky Continue Button at the bottom of the card
                             ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LocationProfileScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // Segmented progress stepper matching LocationProfileScreen styling
  Widget _buildStepper() {
    return Row(
      children: [
        Expanded(child: _buildProgressSegment(true)),
        const SizedBox(width: 4),
        Expanded(child: _buildProgressSegment(false)),
        const SizedBox(width: 4),
        Expanded(child: _buildProgressSegment(false)),
        const SizedBox(width: 4),
        Expanded(child: _buildProgressSegment(false)),
      ],
    );
  }

  Widget _buildProgressSegment(bool isCompleted) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isCompleted ? kPrimaryBlue : kBorderGrey,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildProgressPill() {
    return Text(
      '1/4 Complete',
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kPrimaryBlue,
      ),
    );
  }

  Widget _buildGenderBox(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    final activeBg = const Color(0xFFF0F5FF);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryBlue : kSlate500,
              size: 13, // Tighter icon size
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                gender,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11, // Reduced font size to fit inside 6.5px boundary
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? kPrimaryBlue : kSlate800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kInfoBlueBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: kPrimaryBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "We'll use this information to personalize your IN Schemes experience and keep you updated.",
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: kSlate500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year, // Start in year mode so users can instantly select year/month
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryBlue,
              onPrimary: Colors.white,
              onSurface: kSlate900,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryBlue, // Smooth, responsive button color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        // Format: dd-MMM-yyyy
        final day = picked.day.toString().padLeft(2, '0');
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthStr = months[picked.month - 1];
        final year = picked.year;
        _dobController.text = '$day-$monthStr-$year';
      });
    }
  }
}

// Reusable Custom Input Field Widget
class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? prefixText;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.leadingIcon,
    required this.trailingIcon,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                prefixIcon: Icon(leadingIcon, color: const Color(0xFF64748B), size: 20),
                prefixText: prefixText,
                prefixStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                suffixIcon: Icon(trailingIcon, color: const Color(0xFF64748B), size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
