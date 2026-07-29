import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1 controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;
  String _gender = "Female";
  String _nationality = "Indian";

  // Step 2 controllers
  String _businessStage = "Early Stage";
  String _businessSector = "Technology / FinTech";
  String _businessSubSector = "Software Development";
  String _businessType = "Private Limited";
  late TextEditingController _companyNameController;
  late TextEditingController _incorporationYearController;
  String _registrationType = "MSME Udyam";

  // Step 3 controllers
  late TextEditingController _summaryController;
  late TextEditingController _productsController;
  late TextEditingController _targetMarketController;
  String _teamSize = "1-10 employees";
  String _annualTurnover = "Under ₹10 Lakhs";

  // Step 4 controllers
  late TextEditingController _designationController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarController;
  bool _obscureAadhaar = true;
  String _qualification = "Undergraduate";
  late TextEditingController _collegeController;
  String _workExperience = "2-5 Years";

  // Step 5 controllers
  late TextEditingController _addressController;
  String _state = "Maharashtra";
  String _city = "Mumbai";
  late TextEditingController _pincodeController;
  late TextEditingController _localityController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppProvider>(context, listen: false).profile;

    // Step 1 Init
    _fullNameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _mobileController = TextEditingController(text: profile.mobile.replaceAll('+91 ', ''));
    _dobController = TextEditingController(text: profile.dob != null ? "${profile.dob!.day.toString().padLeft(2, '0')}/${profile.dob!.month.toString().padLeft(2, '0')}/${profile.dob!.year}" : "");
    if (["Male", "Female", "Other"].contains(profile.gender)) {
      _gender = profile.gender;
    }

    // Step 2 Init
    _companyNameController = TextEditingController();
    _incorporationYearController = TextEditingController();
    final initialStage = profile.businessStage;
    if (["Idea Stage", "Early Stage", "Growth Stage", "Mature Stage"].contains(initialStage)) {
      _businessStage = initialStage;
    }

    // Step 3 Init
    _summaryController = TextEditingController(text: profile.address);
    _productsController = TextEditingController();
    _targetMarketController = TextEditingController();

    // Step 4 Init
    _designationController = TextEditingController();
    _panController = TextEditingController();
    _aadhaarController = TextEditingController();
    _collegeController = TextEditingController();

    // Step 5 Init
    _addressController = TextEditingController();
    _pincodeController = TextEditingController(text: profile.pinCode);
    _localityController = TextEditingController();
    if (profile.state.isNotEmpty) {
      _state = profile.state;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _companyNameController.dispose();
    _incorporationYearController.dispose();
    _summaryController.dispose();
    _productsController.dispose();
    _targetMarketController.dispose();
    _designationController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _collegeController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _localityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < 5) {
      _goToStep(_currentStep + 1);
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _saveProfile() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final profile = provider.profile;

    // Parse DOB safely
    DateTime? dobVal;
    try {
      if (_dobController.text.isNotEmpty) {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          dobVal = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (e) {
      debugPrint('[EditProfile] Error parsing DOB: $e');
    }

    final updated = profile.copyWith(
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim().isNotEmpty ? "+91 ${_mobileController.text.trim()}" : profile.mobile,
      gender: _gender,
      dob: dobVal ?? profile.dob,
      businessStage: _businessStage,
      businessIndustry: _businessSector,
      state: _state,
      city: _city,
      district: _city,
      pinCode: _pincodeController.text.trim(),
      address: _summaryController.text.trim(),
    );

    // Show indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))),
    );

    try {
      await provider.updateProfile(updated);
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        Navigator.of(context).pop(); // Go back to drawer/home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile details saved to database successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  String _getSaarthiTip() {
    switch (_currentStep) {
      case 0:
        return "Don't worry! You can always update your personal information later.";
      case 1:
        return "Providing accurate sector details helps me match sector-specific subsidies correctly!";
      case 2:
        return "Tell me about your services so I can look for target-market grants and incubator programs.";
      case 3:
        return "Your credentials are safe. Secure hashing keeps sensitive Aadhaar and PAN data fully private.";
      case 4:
        return "Locality verification helps find location-based state MSME subsidies!";
      case 5:
        return "Review everything carefully. Once verified, we will generate your custom scheme compatibility score!";
      default:
        return "Don't worry! You can always update these details later.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 18),
              onPressed: () {
                if (_currentStep > 0) {
                  _prevStep();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _saveProfile,
                  child: Text(
                    "Save",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "Step ${_currentStep + 1} of 6",
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal Stepper Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(
                children: List.generate(11, (index) {
                  if (index % 2 == 1) {
                    // Line connector
                    final stepIndex = index ~/ 2;
                    final isPassed = _currentStep > stepIndex;
                    return Expanded(
                      child: Container(
                        height: 2.2,
                        color: isPassed ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                      ),
                    );
                  } else {
                    // Circle step
                    final stepIndex = index ~/ 2;
                    final isCompleted = _currentStep > stepIndex;
                    final isActive = _currentStep == stepIndex;

                    return Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isCompleted || isActive ? const Color(0xFFEA580C) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(color: const Color(0xFFEA580C), width: 1)
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : Text(
                                "${stepIndex + 1}",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted || isActive ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                      ),
                    );
                  }
                }),
              ),
            ),

            // Dynamic Step Title Header Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Step ${_currentStep + 1} of 6",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStepTitle(),
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStepSubtitle(),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Small waving Saarthi image
                  Image.asset(
                    'assets/saarthi_expressions/01_happy.png',
                    width: 48,
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.support_agent,
                      size: 34,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Form PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                  _buildStep6(),
                ],
              ),
            ),

            // Fixed bottom Saarthi Tip Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                border: Border(top: BorderSide(color: Color(0xFFFFEDD5))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/saarthi_expressions/01_happy.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.support_agent,
                        size: 20,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getSaarthiTip(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF7C2D12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Soundwave visualizer representation
                  Row(
                    children: List.generate(5, (index) {
                      final double height = [4, 12, 8, 14, 4][index].toDouble();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 2,
                        height: height,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Fixed Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        side: const BorderSide(color: Color(0xFFEA580C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: Text(
                        "Back",
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStep == 5 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _nextStep,
                      icon: Icon(
                        _currentStep == 5 ? Icons.check_circle_outline : Icons.arrow_forward,
                        color: Colors.white,
                        size: 14,
                      ),
                      label: Text(
                        _currentStep == 5 ? "Save Profile" : "Next",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "Personal Information";
      case 1:
        return "Business Information";
      case 2:
        return "Business Details";
      case 3:
        return "Owner / Founder Details";
      case 4:
        return "Business Address";
      case 5:
        return "Review & Confirm";
      default:
        return "";
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return "Tell us about yourself.";
      case 1:
        return "Key registration and sector details.";
      case 2:
        return "Describe what your business does.";
      case 3:
        return "Verify your credential details.";
      case 4:
        return "Where is your business located?";
      case 5:
        return "Check if everything looks correct.";
      default:
        return "";
    }
  }

  // --- STEP 1 UI ---
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledTextField(label: "Full Name", controller: _fullNameController, isRequired: true),
          const SizedBox(height: 16),
          LabeledTextField(label: "Email ID", controller: _emailController, isRequired: true),
          const SizedBox(height: 16),
          
          // Mobile Number with Flag Widget Prefix
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text("Mobile Number", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text(" *", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text("🇮🇳", style: GoogleFonts.inter(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text("+91", style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          LabeledTextField(
            label: "Date of Birth",
            controller: _dobController,
            isRequired: true,
            suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(height: 16),

          // Custom Radio Gender Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text("Gender", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text(" *", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: ["Male", "Female", "Other"].map((g) {
                  final isSel = _gender == g;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = g),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFF7ED) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            g,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          LabeledDropdown(
            label: "Nationality",
            value: _nationality,
            onChanged: (val) {
              if (val != null) setState(() => _nationality = val);
            },
            items: const ["Indian", "NRI", "Other"],
            isRequired: true,
          ),
        ],
      ),
    );
  }

  // --- STEP 2 UI ---
  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledDropdown(
            label: "Business Stage",
            value: _businessStage,
            onChanged: (val) {
              if (val != null) setState(() => _businessStage = val);
            },
            items: const ["Idea Stage", "Early Stage", "Growth Stage", "Mature Stage"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "Business Sector",
            value: _businessSector,
            onChanged: (val) {
              if (val != null) setState(() => _businessSector = val);
            },
            items: const ["Technology / FinTech", "Manufacturing", "Retail / Services", "Agriculture"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "Business Sub-sector",
            value: _businessSubSector,
            onChanged: (val) {
              if (val != null) setState(() => _businessSubSector = val);
            },
            items: const ["Software Development", "Hardware & IoT", "Ecommerce", "Consulting"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "Business Type",
            value: _businessType,
            onChanged: (val) {
              if (val != null) setState(() => _businessType = val);
            },
            items: const ["Private Limited", "Partnership LLP", "Sole Proprietorship", "One Person Company"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledTextField(label: "Company / Business Name", controller: _companyNameController, isRequired: true),
          const SizedBox(height: 16),
          LabeledTextField(
            label: "Year of Incorporation / Start",
            controller: _incorporationYearController,
            isRequired: true,
            suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "Registration Type",
            value: _registrationType,
            onChanged: (val) {
              if (val != null) setState(() => _registrationType = val);
            },
            items: const ["MSME Udyam", "Startup India DPIIT", "GST Registered", "None / Unregistered"],
            isRequired: true,
          ),
        ],
      ),
    );
  }

  // --- STEP 3 UI ---
  Widget _buildStep3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledMultilineField(label: "Business Summary / Description", controller: _summaryController, isRequired: true, maxChars: 300),
          const SizedBox(height: 16),
          LabeledMultilineField(label: "Products / Services Offered", controller: _productsController, isRequired: true, maxChars: 300),
          const SizedBox(height: 16),
          LabeledMultilineField(label: "Target Customer / Market", controller: _targetMarketController, isRequired: true, maxChars: 300),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "Current Team Size",
            value: _teamSize,
            onChanged: (val) {
              if (val != null) setState(() => _teamSize = val);
            },
            items: const ["1-10 employees", "11-50 employees", "51-200 employees", "200+ employees"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "Current Annual Turnover (Approx.)",
            value: _annualTurnover,
            onChanged: (val) {
              if (val != null) setState(() => _annualTurnover = val);
            },
            items: const ["Under ₹10 Lakhs", "₹10 Lakhs - ₹50 Lakhs", "₹50 Lakhs - ₹2 Crore", "₹2 Crore - ₹5 Crore", "₹5 Crore+"],
            isRequired: true,
          ),
        ],
      ),
    );
  }

  // --- STEP 4 UI ---
  Widget _buildStep4() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledTextField(label: "Designation / Role", controller: _designationController, isRequired: true),
          const SizedBox(height: 16),
          LabeledTextField(label: "PAN Number", controller: _panController, isRequired: true),
          const SizedBox(height: 16),
          
          // Aadhaar password visibility textfield
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text("Aadhaar Number", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text(" *", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _aadhaarController,
                obscureText: _obscureAadhaar,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureAadhaar ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF64748B), size: 18),
                    onPressed: () => setState(() => _obscureAadhaar = !_obscureAadhaar),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          LabeledDropdown(
            label: "Highest Education Qualification",
            value: _qualification,
            onChanged: (val) {
              if (val != null) setState(() => _qualification = val);
            },
            items: const ["High School", "Diploma", "Undergraduate", "Postgraduate", "Doctorate"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledTextField(label: "College / University", controller: _collegeController, isRequired: true),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "Total Work Experience (Years)",
            value: _workExperience,
            onChanged: (val) {
              if (val != null) setState(() => _workExperience = val);
            },
            items: const ["0-1 Year", "1-2 Years", "2-5 Years", "5-10 Years", "10+ Years"],
            isRequired: true,
          ),
        ],
      ),
    );
  }

  // --- STEP 5 UI ---
  Widget _buildStep5() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledMultilineField(label: "Registered Address", controller: _addressController, isRequired: true, maxChars: 300),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "State",
            value: _state,
            onChanged: (val) {
              if (val != null) setState(() => _state = val);
            },
            items: const ["Maharashtra", "Tamil Nadu", "Delhi", "Karnataka", "Uttar Pradesh"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledDropdown(
            label: "City",
            value: _city,
            onChanged: (val) {
              if (val != null) setState(() => _city = val);
            },
            items: const ["Mumbai", "Chennai", "New Delhi", "Bengaluru", "Noida"],
            isRequired: true,
          ),
          const SizedBox(height: 16),
          LabeledTextField(label: "Pincode", controller: _pincodeController, isRequired: true),
          const SizedBox(height: 16),
          LabeledTextField(label: "Area / Locality", controller: _localityController, isRequired: true),
        ],
      ),
    );
  }

  // --- STEP 6 UI: REVIEW & CONFIRM ---
  Widget _buildStep6() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReviewCard(
            title: "Personal Information",
            stepTarget: 0,
            rows: [
              _buildReviewRowItem(Icons.person_outline, "Full Name", _fullNameController.text),
              _buildReviewRowItem(Icons.mail_outline, "Email ID", _emailController.text),
              _buildReviewRowItem(Icons.phone_outlined, "Mobile Number", "+91 ${_mobileController.text}"),
              _buildReviewRowItem(Icons.calendar_month_outlined, "Date of Birth", _dobController.text),
              _buildReviewRowItem(Icons.wc_outlined, "Gender", _gender),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: "Business Information",
            stepTarget: 1,
            rows: [
              _buildReviewRowItem(Icons.trending_up, "Business Stage", _businessStage),
              _buildReviewRowItem(Icons.business_center_outlined, "Business Sector", _businessSector),
              _buildReviewRowItem(Icons.category_outlined, "Sub-sector", _businessSubSector),
              _buildReviewRowItem(Icons.badge_outlined, "Company Name", _companyNameController.text.isNotEmpty ? _companyNameController.text : "Not Provided"),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: "Business Details",
            stepTarget: 2,
            rows: [
              _buildReviewRowItem(Icons.description_outlined, "Summary", _summaryController.text.isNotEmpty ? _summaryController.text : "Not Provided"),
              _buildReviewRowItem(Icons.groups_outlined, "Team Size", _teamSize),
              _buildReviewRowItem(Icons.currency_rupee, "Turnover", _annualTurnover),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: "Founder Details",
            stepTarget: 3,
            rows: [
              _buildReviewRowItem(Icons.work_outline, "Designation", _designationController.text.isNotEmpty ? _designationController.text : "Not Provided"),
              _buildReviewRowItem(Icons.credit_card_outlined, "PAN Number", _panController.text.isNotEmpty ? _panController.text : "Not Provided"),
              _buildReviewRowItem(Icons.school_outlined, "Qualification", _qualification),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: "Business Address",
            stepTarget: 4,
            rows: [
              _buildReviewRowItem(Icons.location_on_outlined, "State", _state),
              _buildReviewRowItem(Icons.location_city, "City", _city),
              _buildReviewRowItem(Icons.pin_drop_outlined, "Pincode", _pincodeController.text),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required int stepTarget,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () => _goToStep(stepTarget),
                  child: Text(
                    "Edit",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRowItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.isNotEmpty ? value : "Not Set",
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable LabeledTextField stateless helper
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final Widget? suffixIcon;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (isRequired)
              Text(
                " *",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable LabeledDropdown stateless helper
class LabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> items;
  final bool isRequired;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.items,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (isRequired)
              Text(
                " *",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable LabeledMultilineField stateful helper to handle character count dynamically
class LabeledMultilineField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final int maxChars;

  const LabeledMultilineField({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.maxChars = 300,
  });

  @override
  State<LabeledMultilineField> createState() => _LabeledMultilineFieldState();
}

class _LabeledMultilineFieldState extends State<LabeledMultilineField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCount);
    super.dispose();
  }

  void _updateCount() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (widget.isRequired)
              Text(
                " *",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  maxLength: widget.maxChars,
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: "Enter details here...",
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  "${widget.controller.text.length}/${widget.maxChars}",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
