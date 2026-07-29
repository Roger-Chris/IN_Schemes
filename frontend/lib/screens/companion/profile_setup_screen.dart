import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../providers/app_state_provider.dart';
import 'saarthi_welcome_screen.dart'; // To use SaarthiFocusRegion and SaarthiAttentionController
import 'ai_companion_screens.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late ConfettiController _confettiController;
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0-indexed (0 to 6 for 7 steps)
  bool _isLocating = false;
  bool _showSuccessScreen = false;

  // Form State Variables (Step 1 & 2)
  final TextEditingController _ageController = TextEditingController();
  String _selectedGender = 'Male';
  String? _selectedState;
  String? _selectedDistrict;
  final TextEditingController _pincodeController = TextEditingController();

  // Step 3 Variables (Business Details)
  String _selectedStatus = 'Student / Aspiring Entrepreneur';
  String _selectedBusinessType = 'Select business type';
  String _selectedSector = 'Manufacturing';

  // Step 4 Variables (Plans)
  String _selectedInvestment = '₹1 Lakh - ₹10 Lakhs';
  String _selectedTurnover = '₹5 - ₹25 Lakhs';
  String _selectedEmployees = '2 - 5 people';

  // Step 5 Variables (Special Category)
  final Set<String> _selectedCategories = {'Woman Entrepreneur'};

  // Step 6 Variables (Optional Details)
  String? _selectedExperience;
  String _udyamRegistration = 'No';
  String _gstRegistration = 'No';
  final List<String> _experienceOptions = [
    'Less than 1 year',
    '1 - 3 years',
    '3 - 5 years',
    'More than 5 years',
  ];

  final List<String> _states = [
    'Tamil Nadu',
    'Karnataka',
    'Kerala',
    'Maharashtra',
    'Delhi',
  ];
  final List<String> _districts = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Trichy',
    'Salem',
  ];
  final List<String> _businessTypes = [
    'Proprietorship',
    'Partnership',
    'Private Limited Company',
    'One Person Company (OPC)',
    'Limited Liability Partnership (LLP)',
    'Cooperative Society',
    'Other / Unregistered',
  ];

  // Speech bubble text per page
  final List<Map<String, String>> _saarthiSpeeches = [
    {
      'title': 'Hi Roger! 👋',
      'body':
          "I've already filled in your name and email from your Google account. Let's complete the remaining details.",
      'expression': 'assets/saarthi_expressions/01_happy.png',
    },
    {
      'title': 'Location Check 📍',
      'body':
          'I can automatically detect your location, or you can enter it manually below.',
      'expression': 'assets/saarthi_expressions/03_explaining.png',
    },
    {
      'title': 'Business Type 💼',
      'body':
          "Great! Now, let's understand what kind of business you're planning or running.",
      'expression': 'assets/saarthi_expressions/03_explaining.png',
    },
    {
      'title': 'Funding & Scale 📊',
      'body':
          'Perfect! This information helps me find the most suitable schemes for you.',
      'expression': 'assets/saarthi_expressions/04_excited.png',
    },
    {
      'title': 'Special Categories 🌟',
      'body':
          "Let's check if you qualify for any special category benefits to unlock extra schemes.",
      'expression': 'assets/saarthi_expressions/03_explaining.png',
    },
    {
      'title': 'Optional Registrations 📋',
      'body':
          "UDYAM and GST details help personalize your scheme results, but they are completely optional.",
      'expression': 'assets/saarthi_expressions/01_happy.png',
    },
  ];

  @override
  void initState() {
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    super.initState();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pageController.dispose();
    _ageController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentStep < 6) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Completed last step -> Save and Sync profile to database
      setState(() {
        _isLocating = true; // Use this as general action loading state
      });

      try {
        final provider = Provider.of<AppProvider>(context, listen: false);
        final currentProfile = provider.profile;

        final ageVal = int.tryParse(_ageController.text) ?? 25;
        final estimatedDob = DateTime(DateTime.now().year - ageVal, 1, 1);

        final updatedProfile = currentProfile.copyWith(
          dob: estimatedDob,
          gender: _selectedGender,
          state: _selectedState ?? currentProfile.state,
          district: _selectedDistrict ?? currentProfile.district,
          pinCode: _pincodeController.text,
          profileCompleted: true,
        );

        debugPrint(
          '[ProfileSetupScreen] Submitting completed profile to DB for user: ${updatedProfile.googleUserId}',
        );
        await provider.updateProfile(updatedProfile);
        debugPrint('[ProfileSetupScreen] Profile saved successfully.');

        if (mounted) {
          setState(() {
            _showSuccessScreen = true;
          });
          _confettiController.play();
        }
      } catch (e) {
        debugPrint('[ProfileSetupScreen] Error saving profile to database: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLocating = false;
          });
        }
      }
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccessScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: _buildSuccessScreen(),
      );
    }

    final speechInfo = _currentStep < _saarthiSpeeches.length
        ? _saarthiSpeeches[_currentStep]
        : _saarthiSpeeches[0];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Fixed)
            _buildHeader(),

            // 2. Form Body (Expanded PageView)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Managed via buttons
                children: [
                  _buildStep1PersonalDetails(),
                  _buildStep2Location(),
                  _buildStep3BusinessDetails(),
                  _buildStep4Plans(),
                  _buildStep5SpecialCategory(),
                  _buildStep6OptionalDetails(),
                  _buildStep7ReviewDetails(),
                ],
              ),
            ),

            // Keyboard-aware spacer: if keyboard is open, collapse or hide conversational bars
            if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
              // 3. Saarthi Conversational Bar (Fixed Bottom-ish)
              _buildSaarthiConversationalBar(speechInfo),
              const SizedBox(height: 12),
            ],

            // 4. Bottom Navigation (Fixed Bottom)
            _buildBottomNavigation(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Header & Stepper widget
  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _prevPage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "Let's set up your profile",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40), // Balance back button
            ],
          ),
        ),

        // Stepper Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thin connecting line
              Container(height: 2, color: const Color(0xFFE2E8F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  final isNext = index == _currentStep + 1;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentStep = index;
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.white
                            : (isActive
                                  ? const Color(0xFFEA580C)
                                  : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (isActive || isNext
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFFCBD5E1)),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Color(0xFF10B981),
                                size: 14,
                              )
                            : Text(
                                (index + 1).toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : (isNext
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFF64748B)),
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Step ${_currentStep + 1} of 7",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFEA580C),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // STEP 1 Form Page
  Widget _buildStep1PersonalDetails() {
    final provider = Provider.of<AppProvider>(context);
    final userProfile = provider.profile;
    final String displayName = userProfile.name.isNotEmpty
        ? userProfile.name
        : "Roger Christopher";
    final String displayEmail = userProfile.email.isNotEmpty
        ? userProfile.email
        : "rogerchristopher@gmail.com";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's get to know you 👋",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "I'll use this to find the best schemes for you.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Locked fields (mocking Google info)
          LockedFieldCard(
            label: "Full Name",
            value: displayName,
            icon: Icons.person_outline,
            iconColor: const Color(0xFFEA580C),
          ),
          const SizedBox(height: 12),
          LockedFieldCard(
            label: "Email Address",
            value: displayEmail,
            icon: Icons.mail_outline,
            iconColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),

          // Age Input wrapped in SaarthiFocusRegion
          SaarthiFocusRegion(
            id: 'age_input',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your age',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Gender Selection Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gender',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildGenderPill('Male'),
                          const SizedBox(width: 8),
                          _buildGenderPill('Female'),
                          const SizedBox(width: 8),
                          _buildGenderPill('Other'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Gender Pill helper
  Widget _buildGenderPill(String gender) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              gender,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // STEP 2 Form Page
  Widget _buildStep2Location() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Where are you located?",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This helps me find schemes available in your area.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // GPS Location Card
          SaarthiFocusRegion(
            id: 'location_gps',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFFDBA74)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gps_fixed,
                      color: Color(0xFFEA580C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Current Location',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Get your state, district and pincode automatically.',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLocating
                        ? null
                        : () async {
                            setState(() {
                              _isLocating = true;
                            });
                            try {
                              final provider = Provider.of<AppProvider>(
                                context,
                                listen: false,
                              );
                              final locationData = await provider
                                  .fetchLocationAndPopulate();
                              if (locationData != null && mounted) {
                                setState(() {
                                  _selectedState = locationData['state'];
                                  final String rawDist =
                                      locationData['district'] ?? '';
                                  final String rawCity =
                                      locationData['city'] ?? '';
                                  _selectedDistrict = rawDist.isNotEmpty
                                      ? rawDist
                                      : (rawCity.isNotEmpty
                                            ? rawCity
                                            : 'Chennai');
                                  _pincodeController.text =
                                      locationData['pinCode'] ?? '';
                                });
                              }
                            } catch (e) {
                              debugPrint(
                                '[ProfileSetupScreen] Error fetching location: $e',
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLocating = false;
                                });
                              }
                            }
                          },
                    icon: _isLocating
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 1.5,
                            ),
                          )
                        : const Icon(Icons.send, size: 12),
                    label: Text(
                      _isLocating ? 'Fetching...' : 'Fetch My Location',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 16),

          // Manual State Field
          _buildDropdownCard(
            label: "State",
            value: _selectedState ?? "Select your state",
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF8B5CF6),
            onTap: () {
              // Open simple selector sheet
              _showSelectorSheet("Select State", _states, (val) {
                setState(() {
                  _selectedState = val;
                });
              });
            },
          ),
          const SizedBox(height: 12),

          // Manual District & Pincode half-width row
          Row(
            children: [
              Expanded(
                child: _buildDropdownCard(
                  label: "District",
                  value: _selectedDistrict ?? "Select your district",
                  icon: Icons.location_city_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  onTap: () {
                    _showSelectorSheet("Select District", _districts, (val) {
                      setState(() {
                        _selectedDistrict = val;
                      });
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pin_outlined,
                          color: Color(0xFF8B5CF6),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pincode',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter pincode',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep3BusinessDetails() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tell me about your business",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This helps me find the right schemes for you.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Question 1: What is your current status?
          Text(
            "What is your current status?",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SaarthiFocusRegion(
                  id: 'status_student',
                  child: LargeSelectionCard(
                    title: "Student /\nAspiring Entrepreneur",
                    icon: Icons.school_outlined,
                    isSelected:
                        _selectedStatus == 'Student / Aspiring Entrepreneur',
                    onTap: () {
                      setState(() {
                        _selectedStatus = 'Student / Aspiring Entrepreneur';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LargeSelectionCard(
                  title: "Existing\nBusiness Owner",
                  icon: Icons.person_outline,
                  isSelected: _selectedStatus == 'Existing Business Owner',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Existing Business Owner';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LargeSelectionCard(
                  title: "Self Help Group\n(SHG)",
                  icon: Icons.group_outlined,
                  isSelected: _selectedStatus == 'Self Help Group (SHG)',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Self Help Group (SHG)';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question 2: What type of business are you planning or running?
          Text(
            "What type of business are you planning or running?",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildDropdownCard(
            label: "Select business type",
            value: _selectedBusinessType,
            icon: Icons.factory_outlined,
            iconColor: const Color(0xFF8B5CF6),
            onTap: () {
              _showSelectorSheet("Select Business Type", _businessTypes, (val) {
                setState(() {
                  _selectedBusinessType = val;
                });
              });
            },
          ),
          const SizedBox(height: 20),

          // Question 3: Choose your business sector
          Text(
            "Choose your business sector",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              SaarthiFocusRegion(
                id: 'sector_manufacturing',
                child: SelectionPill(
                  label: "Manufacturing",
                  icon: Icons.factory_outlined,
                  isSelected: _selectedSector == 'Manufacturing',
                  onTap: () {
                    setState(() {
                      _selectedSector = 'Manufacturing';
                    });
                  },
                ),
              ),
              SelectionPill(
                label: "Services",
                icon: Icons.construction_outlined,
                isSelected: _selectedSector == 'Services',
                onTap: () {
                  setState(() {
                    _selectedSector = 'Services';
                  });
                },
              ),
              SelectionPill(
                label: "Agriculture",
                icon: Icons.agriculture_outlined,
                isSelected: _selectedSector == 'Agriculture',
                onTap: () {
                  setState(() {
                    _selectedSector = 'Agriculture';
                  });
                },
              ),
              SelectionPill(
                label: "Retail / Trading",
                icon: Icons.shopping_cart_outlined,
                isSelected: _selectedSector == 'Retail / Trading',
                onTap: () {
                  setState(() {
                    _selectedSector = 'Retail / Trading';
                  });
                },
              ),
              SelectionPill(
                label: "Technology",
                icon: Icons.computer_outlined,
                isSelected: _selectedSector == 'Technology',
                onTap: () {
                  setState(() {
                    _selectedSector = 'Technology';
                  });
                },
              ),
              SelectionPill(
                label: "Other",
                icon: Icons.more_horiz_outlined,
                isSelected: _selectedSector == 'Other',
                onTap: () {
                  setState(() {
                    _selectedSector = 'Other';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep4Plans() {
    final investmentOptions = [
      "Below ₹1 Lakh",
      "₹1 Lakh - ₹10 Lakhs",
      "₹10 Lakhs - ₹50 Lakhs",
      "₹50 Lakhs - ₹1 Crore",
      "Above ₹1 Crore",
    ];

    final turnoverOptions = [
      "Below ₹5 Lakhs",
      "₹5 - ₹25 Lakhs",
      "₹25 Lakhs - ₹1 Crore",
      "Above ₹1 Crore",
      "Not Applicable",
    ];

    final employeeOptions = [
      "Just me",
      "2 - 5 people",
      "6 - 20 people",
      "21 - 50 people",
      "More than 50 people",
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's understand your plans",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This helps me match relevant funding schemes.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Question 1
          Text(
            "What is your expected investment range?",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: investmentOptions.map((opt) {
              final isSelected = _selectedInvestment == opt;
              final pill = SelectionPill(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedInvestment = opt;
                  });
                },
              );

              if (opt == "₹1 Lakh - ₹10 Lakhs") {
                return SaarthiFocusRegion(id: 'investment_1_10', child: pill);
              }
              return pill;
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Question 2
          Text(
            "What is your expected annual turnover?",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: turnoverOptions.map((opt) {
              final isSelected = _selectedTurnover == opt;
              final pill = SelectionPill(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedTurnover = opt;
                  });
                },
              );

              if (opt == "₹5 - ₹25 Lakhs") {
                return SaarthiFocusRegion(id: 'turnover_5_25', child: pill);
              }
              return pill;
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Question 3
          Text(
            "How many people will be working in your business?",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: employeeOptions.map((opt) {
              final isSelected = _selectedEmployees == opt;
              return SelectionPill(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedEmployees = opt;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep5SpecialCategory() {
    final bool isNoneSelected = _selectedCategories.contains(
      'None of the above',
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Do you belong to any special category?",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This helps me find additional benefits for you.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Form Container Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Select all that apply ",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "(Optional)",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Grid options
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    SaarthiFocusRegion(
                      id: 'category_woman',
                      child: CustomCheckboxRow(
                        label: "Woman Entrepreneur",
                        icon: Icons.face_3_outlined,
                        iconColor: const Color(0xFFEF4444),
                        isChecked: _selectedCategories.contains(
                          'Woman Entrepreneur',
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedCategories.remove('None of the above');
                              _selectedCategories.add('Woman Entrepreneur');
                            } else {
                              _selectedCategories.remove('Woman Entrepreneur');
                            }
                          });
                        },
                      ),
                    ),
                    CustomCheckboxRow(
                      label: "SC",
                      icon: Icons.gavel_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      isChecked: _selectedCategories.contains('SC'),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCategories.remove('None of the above');
                            _selectedCategories.add('SC');
                          } else {
                            _selectedCategories.remove('SC');
                          }
                        });
                      },
                    ),
                    CustomCheckboxRow(
                      label: "ST",
                      icon: Icons.forest_outlined,
                      iconColor: const Color(0xFF10B981),
                      isChecked: _selectedCategories.contains('ST'),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCategories.remove('None of the above');
                            _selectedCategories.add('ST');
                          } else {
                            _selectedCategories.remove('ST');
                          }
                        });
                      },
                    ),
                    CustomCheckboxRow(
                      label: "OBC",
                      icon: Icons.people_alt_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      isChecked: _selectedCategories.contains('OBC'),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCategories.remove('None of the above');
                            _selectedCategories.add('OBC');
                          } else {
                            _selectedCategories.remove('OBC');
                          }
                        });
                      },
                    ),
                    CustomCheckboxRow(
                      label: "Minority",
                      icon: Icons.star_half_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      isChecked: _selectedCategories.contains('Minority'),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCategories.remove('None of the above');
                            _selectedCategories.add('Minority');
                          } else {
                            _selectedCategories.remove('Minority');
                          }
                        });
                      },
                    ),
                    CustomCheckboxRow(
                      label: "Differently Abled",
                      icon: Icons.accessible_outlined,
                      iconColor: const Color(0xFFEC4899),
                      isChecked: _selectedCategories.contains(
                        'Differently Abled',
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCategories.remove('None of the above');
                            _selectedCategories.add('Differently Abled');
                          } else {
                            _selectedCategories.remove('Differently Abled');
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // None of the above option (Full Width)
                CustomCheckboxRow(
                  label: "None of the above",
                  icon: Icons.block_outlined,
                  iconColor: const Color(0xFF64748B),
                  isChecked: isNoneSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedCategories.clear();
                        _selectedCategories.add('None of the above');
                      } else {
                        _selectedCategories.remove('None of the above');
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep6OptionalDetails() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "A few optional details (You can skip)",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This helps me personalize your recommendations better.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Card 1: Experience
          SaarthiFocusRegion(
            id: 'optional_experience',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: Color(0xFFEA580C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Years of experience in this field",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSimpleDropdownField(
                    value: _selectedExperience ?? "Select experience",
                    onTap: () {
                      _showSelectorSheet(
                        "Select Experience",
                        _experienceOptions,
                        (val) {
                          setState(() {
                            _selectedExperience = val;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: UDYAM Registration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Do you have UDYAM registration?",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomRadioGroup(
                  selectedValue: _udyamRegistration,
                  options: const ['Yes', 'No', 'Not yet'],
                  onChanged: (val) {
                    setState(() {
                      _udyamRegistration = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 3: GST Registration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Do you have GST registration?",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomRadioGroup(
                  selectedValue: _gstRegistration,
                  options: const ['Yes', 'No', 'Not yet'],
                  onChanged: (val) {
                    setState(() {
                      _gstRegistration = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep7ReviewDetails() {
    final provider = Provider.of<AppProvider>(context);
    final userProfile = provider.profile;

    final String nameEmailStr =
        "${userProfile.name}, ${_ageController.text}, $_selectedGender";
    final String contactStr =
        "${userProfile.email}, ${userProfile.mobile.isNotEmpty ? userProfile.mobile : (provider.mobileNumber.isNotEmpty ? '+91 ${provider.mobileNumber}' : '+91 98765 43210')}";
    final String locationStr =
        "${_selectedDistrict ?? 'Chennai'}, ${_selectedState ?? 'Tamil Nadu'} - ${_pincodeController.text.isNotEmpty ? _pincodeController.text : '600097'}";
    final String businessStr = "$_selectedStatus, $_selectedSector";
    final String investmentStr =
        "$_selectedInvestment, $_selectedTurnover, $_selectedEmployees";
    final String categoryStr =
        _selectedCategories.isEmpty ||
            _selectedCategories.contains('None of the above')
        ? 'None'
        : _selectedCategories.join(', ');
    final String registrationStr =
        "UDYAM: $_udyamRegistration, GST: $_gstRegistration";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's review your details",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Please confirm if everything looks good.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          SaarthiFocusRegion(
            id: 'review_summary_card',
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildReviewRow(
                    label: "Personal Details",
                    value: nameEmailStr,
                    icon: Icons.person_outline,
                    onEdit: () => _goToStep(0),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildReviewRow(
                    label: "Contact",
                    value: contactStr,
                    icon: Icons.phone_outlined,
                    onEdit: () => _goToStep(0),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildReviewRow(
                    label: "Location",
                    value: locationStr,
                    icon: Icons.location_on_outlined,
                    onEdit: () => _goToStep(1),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildReviewRow(
                    label: "Business Profile",
                    value: businessStr,
                    icon: Icons.business_center_outlined,
                    onEdit: () => _goToStep(2),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildReviewRow(
                    label: "Investment & Turnover",
                    value: investmentStr,
                    icon: Icons.currency_rupee_outlined,
                    onEdit: () => _goToStep(3),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildReviewRow(
                    label: "Special Category",
                    value: categoryStr,
                    icon: Icons.people_outline,
                    onEdit: () => _goToStep(4),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildReviewRow(
                    label: "Registrations",
                    value: registrationStr,
                    icon: Icons.description_outlined,
                    onEdit: () => _goToStep(5),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _goToStep(int stepIndex) {
    setState(() {
      _currentStep = stepIndex;
    });
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildReviewRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFEA580C), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Text(
              "Edit",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEA580C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final provider = Provider.of<AppProvider>(context);
    final userProfile = provider.profile;

    final String locationText =
        "${_selectedDistrict ?? 'Chennai'}, ${_selectedState ?? 'Tamil Nadu'}";
    final String categoryText =
        _selectedCategories.isEmpty ||
            _selectedCategories.contains('None of the above')
        ? 'None'
        : _selectedCategories.join(', ');

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // Header glowing circle checkmark
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA580C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Success Titles
                Center(
                  child: Text(
                    "Great job, Roger! 🎉",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    "Your profile is all set.\nI can now find the best schemes for you.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: User name, tag, badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFEDD5),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFFEA580C),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile.name.isNotEmpty
                                      ? userProfile.name
                                      : "Roger Christopher",
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFFEDD5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.school,
                                        color: Color(0xFFEA580C),
                                        size: 10,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _selectedStatus,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFEA580C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "100% Complete",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),

                      // Lower fields
                      _buildSuccessSummaryRow(
                        Icons.location_on_outlined,
                        locationText,
                      ),
                      _buildSuccessSummaryRow(
                        Icons.factory_outlined,
                        _selectedSector,
                      ),
                      _buildSuccessSummaryRow(
                        Icons.currency_rupee_outlined,
                        "Investment Range: $_selectedInvestment",
                      ),
                      _buildSuccessSummaryRow(
                        Icons.group_outlined,
                        "Team Size: $_selectedEmployees",
                      ),
                      _buildSuccessSummaryRow(
                        Icons.people_outline,
                        "Special Category: $categoryText",
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Saarthi Conversational Bar (Success State)
                _buildSaarthiSuccessBar(),
                const SizedBox(height: 20),

                // 3. Bottom Action buttons
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const AiCompanionHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Continue",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Footer security disclaimer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF94A3B8),
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Your information is secure and private.",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFEA580C),
              Color(0xFF3B82F6),
              Color(0xFF10B981),
              Color(0xFF8B5CF6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessSummaryRow(
    IconData icon,
    String text, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0.0 : 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaarthiSuccessBar() {
    final avatarWidget = Image.asset(
      'assets/saarthi_expressions/05_helpful.png',
      width: 105,
      height: 120,
      fit: BoxFit.contain,
    );

    final speechBubbleWidget = Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 95,
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF).withValues(alpha: 0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFFD8B4FE).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '18 Match Found! 🚀',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B21A8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "I've found 18 schemes that match your profile. Let's explore them and find the perfect ones for your business. 🚀",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF4A044E),
                    height: 1.25,
                  ),
                ),
              ],
            ),
            Row(
              children: List.generate(24, (index) {
                final isOrange = index % 2 == 0;
                return Container(
                  width: 2,
                  height: (index % 3 + 1) * 2.5 + (index % 2 * 3),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isOrange
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              speechBubbleWidget,
              const SizedBox(width: 8),
              avatarWidget,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDropdownField({
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: value.startsWith('Select')
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF0F172A),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Conversational bar
  Widget _buildSaarthiConversationalBar(Map<String, String> speechInfo) {
    final bool isAvatarRight = _currentStep == 2 || _currentStep == 3;

    final avatarWidget = Image.asset(
      speechInfo['expression'] ?? 'assets/saarthi_expressions/01_happy.png',
      width: 105,
      height: 120,
      fit: BoxFit.contain,
    );

    final speechBubbleWidget = Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 95,
        decoration: BoxDecoration(
          color: const Color(
            0xFFF3E8FF,
          ).withValues(alpha: 0.5), // Low opacity light purple
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isAvatarRight
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isAvatarRight
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFD8B4FE).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speechInfo['title'] ?? 'Hi Roger! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B21A8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  speechInfo['body'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF4A044E),
                    height: 1.25,
                  ),
                ),
              ],
            ),

            // Animated voice wave bars graphic
            Row(
              children: List.generate(24, (index) {
                final isOrange = index % 2 == 0;
                return Container(
                  width: 2,
                  height: (index % 3 + 1) * 2.5 + (index % 2 * 3),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isOrange
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: isAvatarRight
                ? [speechBubbleWidget, const SizedBox(width: 8), avatarWidget]
                : [avatarWidget, const SizedBox(width: 8), speechBubbleWidget],
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Row
  Widget _buildBottomNavigation() {
    if (_currentStep == 6) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Back button (arrow icon + "Back" text)
            GestureDetector(
              onTap: _prevPage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF0F172A),
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right: Confirm & Continue gradient button
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm & Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
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
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left back circular button
          GestureDetector(
            onTap: _prevPage,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
          ),

          // Center Mic Button (Tap to speak)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Color(0xFFEA580C),
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to speak',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),

          // Right forward circular button
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFEA580C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown card helper
  Widget _buildDropdownCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Simple bottom sheet selector helper
  void _showSelectorSheet(
    String title,
    List<String> options,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return ListTile(
                      title: Text(
                        option,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      onTap: () {
                        onSelect(option);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Locked Field Card component for Google profile fields
class LockedFieldCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const LockedFieldCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Leading icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Labels & values
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Mock Google Logo or 'G' text
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'G',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'From Google',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trailing lock icon
          const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 18),
        ],
      ),
    );
  }
}

class LargeSelectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const LargeSelectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA580C)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF8B5CF6),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionPill({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA580C)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF8B5CF6),
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCheckboxRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const CustomCheckboxRow({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked
                ? const Color(0xFFEA580C)
                : const Color(0xFFE2E8F0),
            width: isChecked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                  color: isChecked
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFFEA580C) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isChecked
                      ? const Color(0xFFEA580C)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRadioGroup extends StatelessWidget {
  final String selectedValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const CustomRadioGroup({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((opt) {
        final isSelected = selectedValue == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEA580C)
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEA580C)
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isSelected
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA580C),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
