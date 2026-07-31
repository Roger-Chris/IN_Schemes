import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../main.dart';
import '../regular_mode/eligibility_results_screen.dart';

class SaarthiProfileSetupScreen extends StatefulWidget {
  final bool fromEligibilityCheck;
  const SaarthiProfileSetupScreen({
    super.key,
    this.fromEligibilityCheck = false,
  });

  @override
  State<SaarthiProfileSetupScreen> createState() =>
      _SaarthiProfileSetupScreenState();
}

class _SaarthiProfileSetupScreenState extends State<SaarthiProfileSetupScreen> {
  // State variables for voice interaction
  int _activeQuestionIndex = 0;
  String _listeningState = 'listening'; // 'listening', 'understood', 'confirm'
  String _userTranscript = '';
  String? _voiceSelectionVal;
  Timer? _listeningTimer;
  Timer? _transcriptTimer;
  late final List<_CompanionQuestion> _companionQuestions;

  // Controllers for backing profile data
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _cityController = TextEditingController();

  DateTime? _selectedDob;
  String? _selectedGender = 'Female';
  String? _selectedState = 'Tamil Nadu';
  String? _selectedDistrict = 'Chennai';
  String? _selectedCity = 'Chennai';
  String _selectedEmployment = 'Student';
  String _selectedBusinessIndustry = 'Manufacturing';

  // New variables for Scale & Eligibility
  String _selectedCommunity = 'General';
  String _selectedInvestment = '< ₹1 Lakh';
  String _selectedTurnover = 'Not Started';
  String _selectedEmployeesRange = 'Just Me';
  final List<String> _selectedSpecialCategories = [];

  bool _isVeteran = false;
  bool _hasDisability = false;
  bool _existingBusiness = false;
  bool _firstGenGraduate = false;

  final Map<String, List<String>> _districtsByState = {
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Tirunelveli',
      'Erode',
      'Vellore',
    ],
    'Karnataka': [
      'Bengaluru',
      'Mysuru',
      'Hubballi',
      'Mangaluru',
      'Belagavi',
      'Davangere',
      'Ballari',
    ],
    'Kerala': [
      'Thiruvananthapuram',
      'Kochi',
      'Kozhikode',
      'Thrissur',
      'Kollam',
      'Palakkad',
      'Kannur',
    ],
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Nagpur',
      'Thane',
      'Nashik',
      'Solapur',
    ],
    'Delhi': [
      'New Delhi',
      'North Delhi',
      'South Delhi',
      'East Delhi',
      'West Delhi',
      'Central Delhi',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Prefill name and phone from google session if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.profile.name.isNotEmpty) {
        _nameController.text = provider.profile.name;
      }
      if (provider.profile.mobile.isNotEmpty) {
        _phoneController.text = provider.profile.mobile;
      } else if (provider.mobileNumber.isNotEmpty) {
        _phoneController.text = provider.mobileNumber;
      }
    });

    _initCompanionQuestions();
    _startSimulatedListening();
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _transcriptTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _initCompanionQuestions() {
    _companionQuestions = [
      // STEP 1: About You
      _CompanionQuestion(
        stepName: 'About You',
        stepNumber: 1,
        saarthiPrompt: "Hi! 👋 Let's personalize your experience. First, what is your full name?",
        sampleAnswer: "Praveen Kumar",
        understoodTranscript: "My name is Praveen Kumar.",
        confirmLabel: "Full Name",
        confirmValue: "Praveen Kumar",
        quickOptions: const ["Praveen Kumar", "Aarav Sharma", "Aditi Patel"],
        isText: true,
        textController: _nameController,
        onSave: (val, state) {
          state._nameController.text = val;
        },
      ),
      _CompanionQuestion(
        stepName: 'About You',
        stepNumber: 1,
        saarthiPrompt: "Great! Can I have your mobile number?",
        sampleAnswer: "9876543210",
        understoodTranscript: "My mobile number is 9876543210.",
        confirmLabel: "Mobile Number",
        confirmValue: "9876543210",
        quickOptions: const ["9876543210", "9988776655"],
        isText: true,
        textController: _phoneController,
        onSave: (val, state) {
          state._phoneController.text = val;
        },
      ),
      _CompanionQuestion(
        stepName: 'About You',
        stepNumber: 1,
        saarthiPrompt: "Got it! How old are you?",
        sampleAnswer: "I am 28.",
        understoodTranscript: "I am twenty eight years old.",
        confirmLabel: "Age",
        confirmValue: "26 – 35 years",
        quickOptions: const [
          "18 – 25 years",
          "26 – 35 years",
          "36 – 45 years",
          "46 – 60 years",
          "60+ years",
        ],
        onSave: (val, state) {
          int age = 28;
          if (val.contains('18')) {
            age = 21;
          } else if (val.contains('26')) {
            age = 30;
          } else if (val.contains('36')) {
            age = 40;
          } else if (val.contains('46')) {
            age = 52;
          } else if (val.contains('60')) {
            age = 65;
          }
          state._selectedDob = DateTime(DateTime.now().year - age, 6, 15);
        },
      ),
      _CompanionQuestion(
        stepName: 'About You',
        stepNumber: 1,
        saarthiPrompt: "And what is your gender?",
        sampleAnswer: "Male.",
        understoodTranscript: "I am male.",
        confirmLabel: "Gender",
        confirmValue: "Male",
        quickOptions: const ["Male", "Female", "Other", "Prefer not to say"],
        onSave: (val, state) {
          state._selectedGender = val;
        },
      ),

      // STEP 2: Business Location
      _CompanionQuestion(
        stepName: 'Location',
        stepNumber: 2,
        saarthiPrompt: "Where is your business located? Which state do you reside in?",
        sampleAnswer: "Tamil Nadu.",
        understoodTranscript: "My business is in Tamil Nadu.",
        confirmLabel: "State",
        confirmValue: "Tamil Nadu",
        quickOptions: const ["Tamil Nadu", "Karnataka", "Kerala", "Maharashtra", "Delhi"],
        onSave: (val, state) {
          state._selectedState = val;
          state._selectedDistrict = state._districtsByState[val]?.first ?? 'Chennai';
          state._selectedCity = state._selectedDistrict;
        },
      ),
      _CompanionQuestion(
        stepName: 'Location',
        stepNumber: 2,
        saarthiPrompt: "Perfect. And which district is your business located in?",
        sampleAnswer: "Chennai.",
        understoodTranscript: "It is in Chennai district.",
        confirmLabel: "District",
        confirmValue: "Chennai",
        quickOptions: const ["Chennai", "Coimbatore", "Bengaluru", "Mumbai", "New Delhi"],
        onSave: (val, state) {
          state._selectedDistrict = val;
        },
      ),
      _CompanionQuestion(
        stepName: 'Location',
        stepNumber: 2,
        saarthiPrompt: "Got it. Can you tell me the city or town?",
        sampleAnswer: "Chennai.",
        understoodTranscript: "The city name is Chennai.",
        confirmLabel: "City/Town",
        confirmValue: "Chennai",
        quickOptions: const ["Chennai", "Coimbatore", "Bengaluru", "Mumbai", "New Delhi"],
        isText: true,
        textController: _cityController,
        onSave: (val, state) {
          state._cityController.text = val;
          state._selectedCity = val;
        },
      ),
      _CompanionQuestion(
        stepName: 'Location',
        stepNumber: 2,
        saarthiPrompt: "Lastly for location, what is your PIN Code? (Optional)",
        sampleAnswer: "600001",
        understoodTranscript: "My PIN Code is 600001.",
        confirmLabel: "PIN Code",
        confirmValue: "600001",
        quickOptions: const ["600001", "560001", "400001", "110001"],
        isText: true,
        textController: _pinController,
        onSave: (val, state) {
          state._pinController.text = val;
        },
      ),

      // STEP 3: Your Business
      _CompanionQuestion(
        stepName: 'Your Business',
        stepNumber: 3,
        saarthiPrompt: "Excellent. Let's talk about your business status. Tell me about your business.",
        sampleAnswer: "Existing MSME.",
        understoodTranscript: "I run an existing MSME business.",
        confirmLabel: "Business Status",
        confirmValue: "Existing MSME",
        quickOptions: const [
          "Student",
          "Aspiring Entrepreneur",
          "Existing MSME",
          "Startup",
          "Retail Shop",
          "Manufacturer",
          "Service Provider",
          "Self-employed",
          "Freelancer",
          "Home-based Business",
          "Other"
        ],
        onSave: (val, state) {
          state._selectedEmployment = val;
          state._existingBusiness = (val != "Student" && val != "Aspiring Entrepreneur");
        },
      ),
      _CompanionQuestion(
        stepName: 'Your Business',
        stepNumber: 3,
        saarthiPrompt: "Which sector does your business belong to?",
        sampleAnswer: "Manufacturing.",
        understoodTranscript: "We are in the manufacturing sector.",
        confirmLabel: "Business Sector",
        confirmValue: "Manufacturing",
        quickOptions: const [
          "Manufacturing",
          "Services",
          "Retail",
          "Food Processing",
          "Agriculture",
          "Textile",
          "Handicrafts",
          "IT",
          "Healthcare",
          "Education",
          "Logistics",
          "Tourism",
          "Other"
        ],
        onSave: (val, state) {
          state._selectedBusinessIndustry = val;
        },
      ),

      // STEP 4: Business Scale
      _CompanionQuestion(
        stepName: 'Business Scale',
        stepNumber: 4,
        saarthiPrompt: "Now tell me about your business scale. What is your business investment?",
        sampleAnswer: "₹1–5 Lakhs.",
        understoodTranscript: "Our investment is one to five lakhs.",
        confirmLabel: "Investment",
        confirmValue: "₹1–5 Lakhs",
        quickOptions: const [
          "< ₹1 Lakh",
          "₹1–5 Lakhs",
          "₹5–25 Lakhs",
          "₹25–50 Lakhs",
          "₹50 Lakhs+"
        ],
        onSave: (val, state) {
          state._selectedInvestment = val;
        },
      ),
      _CompanionQuestion(
        stepName: 'Business Scale',
        stepNumber: 4,
        saarthiPrompt: "What is your business annual turnover?",
        sampleAnswer: "₹5–40 Lakhs.",
        understoodTranscript: "Annual turnover is five to forty lakhs.",
        confirmLabel: "Turnover",
        confirmValue: "₹5–40 Lakhs",
        quickOptions: const [
          "Not Started",
          "< ₹5 Lakhs",
          "₹5–40 Lakhs",
          "₹40 Lakhs–₹5 Crores",
          "Above ₹5 Crores"
        ],
        onSave: (val, state) {
          state._selectedTurnover = val;
        },
      ),
      _CompanionQuestion(
        stepName: 'Business Scale',
        stepNumber: 4,
        saarthiPrompt: "And how many employees do you have in your business?",
        sampleAnswer: "2–10.",
        understoodTranscript: "We have two to ten employees.",
        confirmLabel: "Employees",
        confirmValue: "2–10",
        quickOptions: const [
          "Just Me",
          "2–10",
          "11–50",
          "51–250",
          "250+"
        ],
        onSave: (val, state) {
          state._selectedEmployeesRange = val;
        },
      ),

      // STEP 5: Eligibility
      _CompanionQuestion(
        stepName: 'Eligibility',
        stepNumber: 5,
        saarthiPrompt: "Lastly, do any of these special categories apply to you?",
        sampleAnswer: "Woman Entrepreneur.",
        understoodTranscript: "Yes, I am a woman entrepreneur.",
        confirmLabel: "Eligibility",
        confirmValue: "None",
        isMultiSelect: true,
        quickOptions: const [
          "Woman Entrepreneur",
          "SC",
          "ST",
          "OBC",
          "Minority",
          "Person with Disability",
          "Veteran / Ex-serviceman",
          "First Generation Entrepreneur",
          "None"
        ],
        onSave: (val, state) {
          state._isVeteran = state._selectedSpecialCategories.contains('Veteran / Ex-serviceman');
          state._hasDisability = state._selectedSpecialCategories.contains('Person with Disability');
          state._firstGenGraduate = state._selectedSpecialCategories.contains('First Generation Entrepreneur');
          if (state._selectedSpecialCategories.contains('Woman Entrepreneur')) {
            state._selectedGender = 'Female';
          }
          if (state._selectedSpecialCategories.contains('SC')) {
            state._selectedCommunity = 'SC';
          } else if (state._selectedSpecialCategories.contains('ST')) {
            state._selectedCommunity = 'ST';
          } else if (state._selectedSpecialCategories.contains('OBC')) {
            state._selectedCommunity = 'OBC';
          } else {
            state._selectedCommunity = 'General';
          }
        },
      ),
    ];
  }

  void _startSimulatedListening() {
    _listeningTimer?.cancel();
    _transcriptTimer?.cancel();

    setState(() {
      _listeningState = 'listening';
      _userTranscript = '';
      _voiceSelectionVal = null;
    });

    final currentQuestion = _companionQuestions[_activeQuestionIndex];

    _listeningTimer = Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      setState(() {
        _listeningState = 'understood';
        _userTranscript = currentQuestion.understoodTranscript;
      });

      _transcriptTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() {
          _listeningState = 'confirm';
          if (currentQuestion.isMultiSelect) {
            _voiceSelectionVal = _selectedSpecialCategories.isEmpty ? 'None' : _selectedSpecialCategories.join(', ');
          } else {
            _voiceSelectionVal = currentQuestion.confirmValue;
          }
        });
      });
    });
  }

  void _handleQuickOptionSelect(String option) {
    final currentQuestion = _companionQuestions[_activeQuestionIndex];
    _listeningTimer?.cancel();
    _transcriptTimer?.cancel();

    if (currentQuestion.isMultiSelect) {
      setState(() {
        if (option == "None") {
          _selectedSpecialCategories.clear();
          _selectedSpecialCategories.add("None");
        } else {
          _selectedSpecialCategories.remove("None");
          if (_selectedSpecialCategories.contains(option)) {
            _selectedSpecialCategories.remove(option);
          } else {
            _selectedSpecialCategories.add(option);
          }
        }
        _listeningState = 'confirm';
        _userTranscript = 'I choose ${_selectedSpecialCategories.join(", ")}.';
        _voiceSelectionVal = _selectedSpecialCategories.isEmpty ? 'None' : _selectedSpecialCategories.join(', ');
      });
    } else {
      setState(() {
        _listeningState = 'confirm';
        _userTranscript = 'I choose $option.';
        _voiceSelectionVal = option;
        if (currentQuestion.isText && currentQuestion.textController != null) {
          currentQuestion.textController!.text = option;
        }
      });
    }
  }

  void _handleConfirmCorrect() {
    final currentQuestion = _companionQuestions[_activeQuestionIndex];
    final selectedVal = _voiceSelectionVal ?? currentQuestion.confirmValue;

    currentQuestion.onSave(selectedVal, this);

    if (_activeQuestionIndex == _companionQuestions.length - 1) {
      _saveProfile();
    } else {
      setState(() {
        _activeQuestionIndex++;
      });
      _startSimulatedListening();
    }
  }

  double _mapTurnoverToIncome(String turnover) {
    if (turnover.contains('< ₹5 Lakhs')) return 300000.0;
    if (turnover.contains('₹5–40 Lakhs')) return 2000000.0;
    if (turnover.contains('₹40 Lakhs–₹5 Crores')) return 15000000.0;
    if (turnover.contains('Above ₹5 Crores')) return 60000000.0;
    return 0.0; // Not Started
  }

  double _mapInvestmentToFunding(String investment) {
    if (investment.contains('< ₹1 Lakh')) return 50000.0;
    if (investment.contains('₹1–5 Lakhs')) return 300000.0;
    if (investment.contains('₹5–25 Lakhs')) return 1500000.0;
    if (investment.contains('₹25–50 Lakhs')) return 3500000.0;
    if (investment.contains('₹50 Lakhs+')) return 7500000.0;
    return 0.0;
  }

  void _saveProfile() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final updatedProfile = provider.profile.copyWith(
      name: _nameController.text.isEmpty
          ? 'MSS User'
          : _nameController.text.trim(),
      mobile: _phoneController.text.isEmpty
          ? (provider.profile.mobile.isNotEmpty
              ? provider.profile.mobile
              : provider.mobileNumber)
          : _phoneController.text.trim(),
      dob: _selectedDob ?? DateTime(1998, 1, 1),
      gender: _selectedGender ?? 'Female',
      house: 'G-12',
      street: 'Main Road',
      area: 'Vasanth Nagar',
      village: '',
      address: 'G-12, Main Road, Vasanth Nagar',
      state: _selectedState ?? 'Tamil Nadu',
      district: _selectedDistrict ?? '',
      city: _selectedCity ?? '',
      pinCode: _pinController.text.isEmpty
          ? '560001'
          : _pinController.text.trim(),
      community: _selectedCommunity,
      employmentStatus: _selectedEmployment,
      annualIncome: _mapTurnoverToIncome(_selectedTurnover),
      veteran: _isVeteran,
      disability: _hasDisability ? 'Visual 40%' : 'None',
      firstGenGraduate: _firstGenGraduate,
      existingBusiness: _existingBusiness,
      businessStage: _existingBusiness ? 'Operational' : 'Idea',
      businessIndustry: _selectedBusinessIndustry,
      fundingRequired: _mapInvestmentToFunding(_selectedInvestment),
      profileCompleted: true,
    );

    debugPrint('Saving MSME Profile with employees range: $_selectedEmployeesRange');

    await provider.updateProfile(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MSME Profile onboarding successfully completed!'),
          backgroundColor: Color(0xFF137C47),
        ),
      );

      if (widget.fromEligibilityCheck) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EligibilityResultsScreen()),
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainTabsContainer()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _companionQuestions[_activeQuestionIndex];

    const Color kBrandBlue = Color(0xFF2563EB);
    const Color kDarkSlate = Color(0xFF0F172A);
    const Color kSlate500 = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Title section with robot avatar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Let's build your\nMSME profile",
                            style: GoogleFonts.poppins(
                              fontSize: 19.0,
                              fontWeight: FontWeight.bold,
                              color: kDarkSlate,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "I'll ask a few simple questions using voice conversation.",
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: kSlate500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        'assets/saarthi_expressions/Ai companion.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Conversation Progress Section (5 steps)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Conversation Progress',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: kDarkSlate,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                  Icons.info_outline,
                                  color: kSlate500,
                                  size: 13,
                              ),
                            ],
                          ),
                          Text(
                            '${currentQuestion.stepNumber} of 5',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSlate500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final stepNum = index + 1;
                          final isActive =
                              stepNum == currentQuestion.stepNumber;
                          final isCompleted =
                              stepNum < currentQuestion.stepNumber;

                          return Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? kBrandBlue
                                        : (isCompleted
                                              ? const Color(0xFFEFF6FF)
                                              : Colors.white),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isActive
                                          ? kBrandBlue
                                          : (isCompleted
                                                ? const Color(0xFFBFDBFE)
                                                : const Color(0xFFCBD5E1)),
                                      width: isActive ? 2 : 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '$stepNum',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.white
                                          : (isCompleted
                                                ? kBrandBlue
                                                : kSlate500),
                                    ),
                                  ),
                                ),
                                if (index < 4)
                                  Expanded(
                                    child: Container(
                                      height: 1.5,
                                      color: isCompleted
                                          ? const Color(0xFFBFDBFE)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepLabel(
                            text: 'About You',
                            active: currentQuestion.stepNumber == 1,
                          ),
                          _StepLabel(
                            text: 'Location',
                            active: currentQuestion.stepNumber == 2,
                          ),
                          _StepLabel(
                            text: 'Your Business',
                            active: currentQuestion.stepNumber == 3,
                          ),
                          _StepLabel(
                            text: 'Business Scale',
                            active: currentQuestion.stepNumber == 4,
                          ),
                          _StepLabel(
                            text: 'Eligibility',
                            active: currentQuestion.stepNumber == 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Chat Bubble (Saarthi speech)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEFF6FF),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/saarthi_expressions/Ai companion.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                currentQuestion.saarthiPrompt,
                                style: GoogleFonts.inter(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: kDarkSlate,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.volume_up_outlined,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Interactive Panel Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: _listeningState == 'listening'
                    ? _buildListeningPanel(currentQuestion)
                    : (_listeningState == 'understood'
                          ? _buildUnderstoodPanel(currentQuestion)
                          : _buildConfirmPanel(currentQuestion)),
              ),

              // 5. Quick Options row
              if (currentQuestion.isMultiSelect)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose all that apply',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kSlate500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentQuestion.quickOptions.map((opt) {
                          final isSelected = _selectedSpecialCategories.contains(opt);
                          return ChoiceChip(
                            label: Text(opt),
                            selected: isSelected,
                            onSelected: (selected) {
                              _handleQuickOptionSelect(opt);
                            },
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF0D47A1)
                                  : const Color(0xFF475569),
                            ),
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFFEFF6FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF0D47A1)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // 6. Bottom controls bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 6.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (currentQuestion.quickOptions.isNotEmpty) {
                              _handleQuickOptionSelect(
                                currentQuestion.quickOptions.first,
                              );
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.keyboard_alt_outlined,
                                color: Color(0xFF64748B),
                                size: 18,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Keyboard',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2563EB),
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hold to speak',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {},
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mic_off_outlined,
                                color: Color(0xFF64748B),
                                size: 18,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mute',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
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

              // 7. Tip Banner
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFBFDBFE),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/saarthi_expressions/Ai companion.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 Tip from Saarthi',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            Text(
                              'You can answer in your own words. I understand natural language very well!',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: const Color(0xFF2563EB),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 8. Bottom Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(52),
                    elevation: 0,
                  ),
                  onPressed: _handleConfirmCorrect,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _activeQuestionIndex == _companionQuestions.length - 1
                            ? 'Save & Find Schemes'
                            : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListeningPanel(_CompanionQuestion currentQuestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic, color: Color(0xFF2563EB), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Listening...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(15, (index) {
                    final h = (index % 3 == 0)
                        ? 14.0
                        : ((index % 2 == 0) ? 8.0 : 4.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 2.5,
                      height: h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                if (currentQuestion.isText && currentQuestion.textController != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TextField(
                      controller: currentQuestion.textController,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      keyboardType: currentQuestion.confirmLabel == "Mobile Number" || currentQuestion.confirmLabel == "PIN Code"
                          ? TextInputType.phone
                          : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        _voiceSelectionVal = val;
                      },
                    ),
                  )
                else
                  Text(
                    "Speak naturally. For example:\n\"${currentQuestion.sampleAnswer}\"",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _handleQuickOptionSelect(
                        currentQuestion.quickOptions.isNotEmpty
                            ? currentQuestion.quickOptions.first
                            : "None",
                      );
                    },
                    icon: const Icon(
                      Icons.keyboard_alt_outlined,
                      size: 14,
                      color: Color(0xFF1E293B),
                    ),
                    label: Text(
                      'Type instead',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderstoodPanel(_CompanionQuestion currentQuestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF16A34A),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'I understood this',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion.isText && currentQuestion.textController != null && currentQuestion.textController!.text.isNotEmpty
                            ? '"${currentQuestion.textController!.text}"'
                            : '"$_userTranscript"',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(20, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 2,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _listeningState = 'confirm';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPanel(_CompanionQuestion currentQuestion) {
    String getDisplayValue() {
      if (currentQuestion.isText && currentQuestion.textController != null && currentQuestion.textController!.text.isNotEmpty) {
        return currentQuestion.textController!.text;
      }
      return _voiceSelectionVal ?? currentQuestion.confirmValue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Please confirm',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          // Full-width extended name box
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF15803D),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion.confirmLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        getDisplayValue(),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Actions below
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _listeningState = 'listening';
                  });
                },
                icon: const Icon(Icons.edit, size: 12),
                label: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFDCFCE7),
                  foregroundColor: const Color(0xFF15803D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                  ),
                ),
                onPressed: _handleConfirmCorrect,
                icon: const Icon(Icons.check, size: 12),
                label: Text(
                  'Correct',
                  style: GoogleFonts.inter(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanionQuestion {
  final String stepName;
  final int stepNumber;
  final String saarthiPrompt;
  final String sampleAnswer;
  final String understoodTranscript;
  final String confirmLabel;
  final String confirmValue;
  final List<String> quickOptions;
  final bool isText;
  final TextEditingController? textController;
  final bool isMultiSelect;
  final void Function(String val, _SaarthiProfileSetupScreenState state) onSave;

  const _CompanionQuestion({
    required this.stepName,
    required this.stepNumber,
    required this.saarthiPrompt,
    required this.sampleAnswer,
    required this.understoodTranscript,
    required this.confirmLabel,
    required this.confirmValue,
    required this.quickOptions,
    this.isText = false,
    this.textController,
    this.isMultiSelect = false,
    required this.onSave,
  });
}

class _StepLabel extends StatelessWidget {
  final String text;
  final bool active;
  const _StepLabel({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 7.5,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
          color: active ? const Color(0xFF0D47A1) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
