import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../permission_screen.dart';
import '../regular_mode/eligibility_results_screen.dart';
import '../../services/voice_recognition_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  final VoiceRecognitionController _recognitionController = AutomaticVoiceRecognitionController();
  bool _recognitionInitialized = false;
  bool _isRecording = false;
  final ScrollController _scrollController = ScrollController();
  int _activeStepNumber = 1;

  // Controllers for backing profile data
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _cityController = TextEditingController();

  List<int> get _currentStepQuestionIndices {
    List<int> indices = [];
    for (int i = 0; i < _companionQuestions.length; i++) {
      if (_companionQuestions[i].stepNumber == _activeStepNumber) {
        indices.add(i);
      }
    }
    return indices;
  }





  void _moveToNextStep() {
    setState(() {
      _activeStepNumber++;
    });
    _startSimulatedListening();
  }

  bool _isLocationLoading = false;

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied.';
      }

      if (permission == LocationPermission.deniedForever) throw 'Permission permanently denied.';

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final String resolvedState = place.administrativeArea ?? 'Tamil Nadu';
        final String resolvedDistrict = place.subAdministrativeArea ?? place.locality ?? 'Chennai';
        final String resolvedCity = place.locality ?? place.subLocality ?? 'Chennai';
        final String resolvedPin = place.postalCode ?? '600001';

        setState(() {
          if (!_districtsByState.containsKey(resolvedState)) {
            _districtsByState[resolvedState] = [resolvedDistrict];
          }
          if (!_districtsByState[resolvedState]!.contains(resolvedDistrict)) {
            _districtsByState[resolvedState]!.add(resolvedDistrict);
          }
          _selectedState = resolvedState;
          _selectedDistrict = resolvedDistrict;
          _selectedCity = resolvedCity;
          _cityController.text = resolvedCity;
          _pinController.text = resolvedPin;
          
          // Update answered values for companion questions in Step 2
          for (var q in _companionQuestions) {
            if (q.stepNumber == 2) {
              if (q.confirmLabel == "State") {
                q.answeredValue = resolvedState;
              } else if (q.confirmLabel == "District") {
                q.answeredValue = resolvedDistrict;
              } else if (q.confirmLabel == "City/Town") {
                q.answeredValue = resolvedCity;
              } else if (q.confirmLabel == "PIN Code") {
                q.answeredValue = resolvedPin;
              }
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current location detected successfully!'),
              backgroundColor: Color(0xFF137C47),
            ),
          );
        }
      } else {
        throw 'No address components found.';
      }
    } catch (e) {
      debugPrint('[SaarthiProfile] Location fetch error, using fallback: $e');
      setState(() {
        _selectedState = 'Tamil Nadu';
        _selectedDistrict = 'Chennai';
        _selectedCity = 'Chennai';
        _cityController.text = 'Chennai';
        _pinController.text = '600040';

        for (var q in _companionQuestions) {
          if (q.stepNumber == 2) {
            if (q.confirmLabel == "State") {
              q.answeredValue = 'Tamil Nadu';
            } else if (q.confirmLabel == "District") {
              q.answeredValue = 'Chennai';
            } else if (q.confirmLabel == "City/Town") {
              q.answeredValue = 'Chennai';
            } else if (q.confirmLabel == "PIN Code") {
              q.answeredValue = '600040';
            }
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using fallback location (Chennai) due to mock/emulator environment.'),
            backgroundColor: Color(0xFFE2B93B),
          ),
        );
      }
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }



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
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.profile.name.isNotEmpty) {
      _nameController.text = provider.profile.name;
    }
    if (provider.profile.mobile.isNotEmpty) {
      _phoneController.text = provider.profile.mobile;
    } else if (provider.mobileNumber.isNotEmpty) {
      _phoneController.text = provider.mobileNumber;
    }

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
    _recognitionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initCompanionQuestions() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final String realName = provider.profile.name.isNotEmpty 
        ? provider.profile.name 
        : (provider.profile.email.isNotEmpty ? provider.profile.email.split('@').first : 'Praveen Kumar');
    
    final String realPhone = provider.profile.mobile.isNotEmpty 
        ? provider.profile.mobile 
        : (provider.mobileNumber.isNotEmpty ? provider.mobileNumber : '9876543210');

    _companionQuestions = [
      // STEP 1: About You
      _CompanionQuestion(
        stepName: 'About You',
        stepNumber: 1,
        saarthiPrompt: "Hi! 👋 Let's personalize your experience. First, what is your full name?",
        sampleAnswer: realName,
        understoodTranscript: "My name is $realName.",
        confirmLabel: "Full Name",
        confirmValue: realName,
        quickOptions: [realName, "Aarav Sharma", "Aditi Patel"],
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
        sampleAnswer: realPhone,
        understoodTranscript: "My mobile number is $realPhone.",
        confirmLabel: "Mobile Number",
        confirmValue: realPhone,
        quickOptions: [realPhone, "9988776655"],
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
      _isRecording = false;
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
          MaterialPageRoute(builder: (_) => const PermissionScreen()),
          (route) => false,
        );
      }
    }
  }

  String? _getQuestionCurrentValue(_CompanionQuestion q) {
    if (q.confirmLabel == "Age") {
      if (_selectedDob == null) return null;
      final age = DateTime.now().year - _selectedDob!.year;
      if (age <= 25) return "18 – 25 years";
      if (age <= 35) return "26 – 35 years";
      if (age <= 45) return "36 – 45 years";
      if (age <= 60) return "46 – 60 years";
      return "60+ years";
    }
    if (q.confirmLabel == "Gender") return _selectedGender;
    if (q.confirmLabel == "Business Status") return _selectedEmployment;
    if (q.confirmLabel == "Business Sector") return _selectedBusinessIndustry;
    if (q.confirmLabel == "Investment") return _selectedInvestment;
    if (q.confirmLabel == "Turnover") return _selectedTurnover;
    if (q.confirmLabel == "Employees") return _selectedEmployeesRange;
    return q.answeredValue ?? q.confirmValue;
  }

  Widget _buildQuestionCard(int index) {
    final q = _companionQuestions[index];
    final bool isActive = _activeQuestionIndex == index;
    final bool isAnswered = q.answeredValue != null || (q.isText && q.textController != null && q.textController!.text.isNotEmpty);
    
    const Color kBrandBlue = Color(0xFF2563EB);
    const Color kDarkSlate = Color(0xFF0F172A);
    const Color kSlate500 = Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? kBrandBlue : const Color(0xFFE2E8F0),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: kBrandBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAnswered ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                ),
                child: Icon(
                  isAnswered ? Icons.check_circle : Icons.circle_outlined,
                  color: isAnswered ? kBrandBlue : kSlate500,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                q.confirmLabel,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isActive ? kBrandBlue : kDarkSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (q.isText && q.textController != null)
            TextField(
              controller: q.textController,
              keyboardType: q.confirmLabel == "Mobile Number" || q.confirmLabel == "PIN Code"
                  ? TextInputType.phone
                  : TextInputType.text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: kDarkSlate,
              ),
              decoration: InputDecoration(
                hintText: 'Type ${q.confirmLabel.toLowerCase()} here...',
                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBrandBlue, width: 1.5),
                ),
              ),
              onTap: () {
                if (_activeQuestionIndex != index) {
                  setState(() {
                    _activeQuestionIndex = index;
                  });
                }
              },
              onChanged: (val) {
                q.onSave(val, this);
                q.answeredValue = val;
              },
            )
          else if (q.isMultiSelect)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: q.quickOptions.map((option) {
                final isSel = _selectedSpecialCategories.contains(option);
                return FilterChip(
                  label: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.white : kDarkSlate,
                    ),
                  ),
                  selected: isSel,
                  onSelected: (selected) {
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
                      q.onSave(option, this);
                      q.answeredValue = _selectedSpecialCategories.isEmpty ? 'None' : _selectedSpecialCategories.join(', ');
                    });
                  },
                  selectedColor: const Color(0xFF2563EB),
                  checkmarkColor: Colors.white,
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                  ),
                );
              }).toList(),
            )
          else if (q.confirmLabel == "State" || q.confirmLabel == "District")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: q.confirmLabel == "State" ? _selectedState : _selectedDistrict,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: kSlate500),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: kDarkSlate,
                  ),
                  items: (q.confirmLabel == "State" 
                      ? _districtsByState.keys.toList() 
                      : (_districtsByState[_selectedState] ?? []))
                      .map((val) => DropdownMenuItem(
                            value: val,
                            child: Text(val),
                          ))
                      .toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() {
                        q.onSave(newVal, this);
                        q.answeredValue = newVal;
                      });
                    }
                  },
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: q.quickOptions.map((option) {
                final String? currentVal = _getQuestionCurrentValue(q);
                final isSel = currentVal == option;
                return ChoiceChip(
                  label: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? const Color(0xFF2563EB) : kDarkSlate,
                    ),
                  ),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        q.onSave(option, this);
                        q.answeredValue = option;
                      });
                    }
                  },
                  backgroundColor: const Color(0xFFF8FAFC),
                  selectedColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isSel ? 1.5 : 1.0,
                    ),
                  ),
                );
              }).toList(),
            ),

          if (isActive && _listeningState != 'confirm') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _listeningState == 'listening' ? const Color(0xFFF0F6FF) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _listeningState == 'listening' ? const Color(0xFFBFDBFE) : const Color(0xFFDCFCE7),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _listeningState == 'listening' ? Icons.mic : Icons.check_circle,
                    color: _listeningState == 'listening' ? kBrandBlue : const Color(0xFF16A34A),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _listeningState == 'listening' 
                          ? 'Listening: "$_userTranscript"' 
                          : 'Understood: "$_userTranscript"',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _listeningState == 'listening' ? kBrandBlue : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndices = _currentStepQuestionIndices;
    final currentQuestion = _companionQuestions[_activeQuestionIndex];

    const Color kBrandBlue = Color(0xFF2563EB);
    const Color kDarkSlate = Color(0xFF0F172A);
    const Color kSlate500 = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Title section with robot avatar
              Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: 0.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 130,
                        height: 130,
                        child: Image.asset(
                          'assets/images/saarthi/sarathi.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                        fontSize: 10.0,
                        color: kSlate500,
                        height: 1.35,
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
                            '$_activeStepNumber of 5',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSlate500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double itemWidth = constraints.maxWidth / 5;
                          final double startLineX = itemWidth / 2;
                          final double endLineX = constraints.maxWidth - (itemWidth / 2);
                          
                          // Active step progress line end point
                          final double progressFraction = (_activeStepNumber - 1) / 4;
                          final double activeLineWidth = (endLineX - startLineX) * progressFraction;

                          return Stack(
                            children: [
                              // 1. Grey background line
                              Positioned(
                                top: 14,
                                left: startLineX,
                                right: startLineX,
                                child: Container(
                                  height: 2,
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              // 2. Active blue progress line
                              Positioned(
                                top: 14,
                                left: startLineX,
                                child: Container(
                                  width: activeLineWidth,
                                  height: 2,
                                  color: const Color(0xFF93C5FD), // Light blue active line
                                ),
                              ),
                              // 3. Row of Steps (circle + label)
                              Row(
                                children: List.generate(5, (index) {
                                  final stepNum = index + 1;
                                  final isActive = stepNum == _activeStepNumber;
                                  final isCompleted = stepNum < _activeStepNumber;

                                  String labelText = '';
                                  switch (index) {
                                    case 0: labelText = 'About You'; break;
                                    case 1: labelText = 'Location'; break;
                                    case 2: labelText = 'Your Business'; break;
                                    case 3: labelText = 'Business Scale'; break;
                                    case 4: labelText = 'Eligibility'; break;
                                  }

                                  return Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Circle
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
                                        const SizedBox(height: 8),
                                        // Label
                                        SizedBox(
                                          height: 24,
                                          child: _StepLabel(
                                            text: labelText,
                                            active: isActive,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
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
                          'assets/images/saarthi/sarathi.png',
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. List of all questions for the current step
              Column(
                children: [
                  if (_activeStepNumber == 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0),
                      child: OutlinedButton.icon(
                        onPressed: _isLocationLoading ? null : _fetchCurrentLocation,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: _isLocationLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : const Icon(Icons.my_location, size: 16, color: Color(0xFF2563EB)),
                        label: Text(
                          _isLocationLoading ? 'Fetching Location...' : 'Use Current Location',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ...currentIndices.map((idx) => _buildQuestionCard(idx)),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildVoiceNavbar(context, currentQuestion),
    );
  }

  Widget _buildVoiceNavbar(BuildContext context, _CompanionQuestion currentQuestion) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Next Button (Upper position)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
              ),
              onPressed: () {
                if (_activeStepNumber == 5) {
                  _saveProfile();
                } else {
                  _moveToNextStep();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _activeStepNumber == 5 ? 'Save & Find Schemes' : 'Next',
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

            const SizedBox(height: 12),

            // 2. White Hold to Speak Box (Static Bottom position)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (currentQuestion.isText && currentQuestion.textController != null) {
                          FocusManager.instance.primaryFocus?.unfocus();
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
                    child: GestureDetector(
                      onTap: () async {
                        _listeningTimer?.cancel();
                        _transcriptTimer?.cancel();

                        if (!_isRecording) {
                          final provider = Provider.of<AppProvider>(context, listen: false);
                          final localeId = provider.selectedLanguage == 'ta' ? 'ta-IN' : 'en-IN';
                          setState(() {
                            _isRecording = true;
                            _listeningState = 'listening';
                            _userTranscript = 'Listening...';
                          });
                          try {
                            if (!_recognitionInitialized) {
                              await _recognitionController.initialize(
                                onStatus: (status) {
                                  debugPrint('[SaarthiProfile] Voice status: $status');
                                },
                                onResult: (result) {
                                  setState(() {
                                    if (result.transcript.isNotEmpty) {
                                      _userTranscript = result.transcript;
                                      _voiceSelectionVal = result.transcript;
                                    }
                                  });
                                },
                                onSoundLevel: (level) {},
                                onLanguage: (lang) {},
                                onError: (error) {
                                  debugPrint('[SaarthiProfile] Voice error: ${error.message}');
                                },
                              );
                              _recognitionInitialized = true;
                            }
                            await _recognitionController.listen(
                              localeId: localeId,
                            );
                          } catch (e) {
                            debugPrint('[SaarthiProfile] Error starting voice: $e');
                          }
                        } else {
                          setState(() {
                            _isRecording = false;
                          });
                          try {
                            await _recognitionController.stop();
                          } catch (e) {
                            debugPrint('[SaarthiProfile] Error stopping voice: $e');
                          }
                          final currentQuestion = _companionQuestions[_activeQuestionIndex];
                          setState(() {
                            _listeningState = 'understood';
                            if (_userTranscript == 'Listening...' || _userTranscript.isEmpty) {
                              _userTranscript = currentQuestion.understoodTranscript;
                            }
                          });
                          _transcriptTimer = Timer(const Duration(milliseconds: 1000), () {
                            if (!mounted) return;
                            setState(() {
                              _listeningState = 'confirm';
                              String confirmedVal = _voiceSelectionVal ?? currentQuestion.confirmValue;
                              if (confirmedVal == 'Listening...') {
                                confirmedVal = currentQuestion.confirmValue;
                              }
                              currentQuestion.onSave(confirmedVal, this);
                              currentQuestion.answeredValue = confirmedVal;
                              if (currentQuestion.isText && currentQuestion.textController != null) {
                                currentQuestion.textController!.text = confirmedVal;
                              }
                            });
                          });
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isRecording ? 'Tap to stop' : 'Tap to speak',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
          ],
        ),
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
  
  // Non-final field to store the user's confirmed answer
  String? answeredValue;

  _CompanionQuestion({
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
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.visible,
      style: GoogleFonts.inter(
        fontSize: 9.0,
        fontWeight: active ? FontWeight.bold : FontWeight.w500,
        color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
      ),
    );
  }
}
