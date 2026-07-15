import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../main.dart';
import 'eligibility_results_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool fromEligibilityCheck;
  const ProfileSetupScreen({super.key, this.fromEligibilityCheck = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class EmploymentOption {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const EmploymentOption({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLocating = false;

  // Controllers
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _villageController = TextEditingController();
  final _pinController = TextEditingController();
  final _disabilityController = TextEditingController();
  final _fundingController = TextEditingController();
  final _regNumbersController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  DateTime? _selectedDob;
  String? _selectedGender = 'Female';
  String? _selectedState = 'Tamil Nadu';
  String? _selectedDistrict = 'Chennai';
  String? _selectedCity = 'Chennai';
  String _selectedCommunity = 'General';
  String _selectedEmployment = 'Student';
  String? _selectedIncomeRange = 'Under ₹1.5 Lakhs';

  bool _isVeteran = false;
  bool _hasDisability = false;
  bool _existingBusiness = false;
  String _selectedQualification = 'Undergraduate';
  String _selectedBusinessStage = 'Idea';
  String _selectedBusinessIndustry = 'Technology';

  final Map<String, List<String>> _districtsByState = {
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Trichy', 'Salem'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru', 'Hubli', 'Belagavi'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
  };

  final List<String> _communityOptions = const [
    'General',
    'OBC',
    'EWS',
    'SC',
    'ST',
    'Others',
  ];

  final List<EmploymentOption> _employmentOptions = const [
    EmploymentOption(
      title: 'Student',
      icon: Icons.school_outlined,
      iconColor: Color(0xFF2563EB),
      iconBgColor: Color(0xFFDBEAFE),
    ),
    EmploymentOption(
      title: 'Farmer',
      icon: Icons.agriculture_outlined,
      iconColor: Color(0xFF16A34A),
      iconBgColor: Color(0xFFDCFCE7),
    ),
    EmploymentOption(
      title: 'Salaried',
      icon: Icons.business_center_outlined,
      iconColor: Color(0xFF7C3AED),
      iconBgColor: Color(0xFFF3E8FF),
    ),
    EmploymentOption(
      title: 'Self-employed',
      icon: Icons.person_outline,
      iconColor: Color(0xFFD97706),
      iconBgColor: Color(0xFFFEF3C7),
    ),
    EmploymentOption(
      title: 'Business Owner',
      icon: Icons.storefront_outlined,
      iconColor: Color(0xFF0F172A),
      iconBgColor: Color(0xFFF1F5F9),
    ),
    EmploymentOption(
      title: 'Homemaker',
      icon: Icons.home_outlined,
      iconColor: Color(0xFFE11D48),
      iconBgColor: Color(0xFFFFE4E6),
    ),
    EmploymentOption(
      title: 'Unemployed',
      icon: Icons.search_outlined,
      iconColor: Color(0xFFDC2626),
      iconBgColor: Color(0xFFFEE2E2),
    ),
    EmploymentOption(
      title: 'Retired',
      icon: Icons.directions_walk,
      iconColor: Color(0xFF0D9488),
      iconBgColor: Color(0xFFCCFBF1),
    ),
    EmploymentOption(
      title: 'Other',
      icon: Icons.more_horiz_outlined,
      iconColor: Color(0xFF475569),
      iconBgColor: Color(0xFFE2E8F0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final profile = provider.profile;

    _nameController.text = profile.name;
    _houseController.text = profile.house;
    _streetController.text = profile.street;
    _areaController.text = profile.area;
    _villageController.text = profile.village;
    _pinController.text = profile.pinCode;
    _disabilityController.text = profile.disability == 'None' ? '' : profile.disability;
    _fundingController.text = profile.fundingRequired > 0 ? profile.fundingRequired.toString() : '';
    _regNumbersController.text = profile.registrationNumbers;

    setState(() {
      _selectedDob = profile.dob;
      if (profile.gender.isNotEmpty) _selectedGender = profile.gender;
      if (profile.state.isNotEmpty) _selectedState = profile.state;

      if (!_districtsByState.containsKey(_selectedState)) {
        _selectedState = 'Tamil Nadu';
      }

      if (profile.district.isNotEmpty && (_districtsByState[_selectedState] ?? []).contains(profile.district)) {
        _selectedDistrict = profile.district;
      } else {
        _selectedDistrict = _districtsByState[_selectedState]!.first;
      }

      if (profile.city.isNotEmpty && (_districtsByState[_selectedState] ?? []).contains(profile.city)) {
        _selectedCity = profile.city;
      } else {
        _selectedCity = _selectedDistrict;
      }

      if (profile.community.isNotEmpty) _selectedCommunity = profile.community;
      if (profile.employmentStatus.isNotEmpty) _selectedEmployment = profile.employmentStatus;

      _isVeteran = profile.veteran;
      _hasDisability = profile.disability != 'None' && profile.disability.isNotEmpty;
      _existingBusiness = profile.existingBusiness;
      if (profile.qualification.isNotEmpty) _selectedQualification = profile.qualification;
      if (profile.businessStage.isNotEmpty) _selectedBusinessStage = profile.businessStage;
      if (profile.businessIndustry.isNotEmpty) _selectedBusinessIndustry = profile.businessIndustry;

      _selectedIncomeRange = _mapIncomeToRange(profile.annualIncome);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _villageController.dispose();
    _pinController.dispose();
    _disabilityController.dispose();
    _fundingController.dispose();
    _regNumbersController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String _mapIncomeToRange(double income) {
    if (income <= 0) return 'Under ₹1.5 Lakhs';
    if (income <= 150000) return 'Under ₹1.5 Lakhs';
    if (income <= 300000) return '₹1.5 Lakhs - ₹3 Lakhs';
    if (income <= 500000) return '₹3 Lakhs - ₹5 Lakhs';
    if (income <= 800000) return '₹5 Lakhs - ₹8 Lakhs';
    return 'Above ₹8 Lakhs';
  }

  double _mapRangeToIncome(String range) {
    switch (range) {
      case 'Under ₹1.5 Lakhs':
        return 120000.0;
      case '₹1.5 Lakhs - ₹3 Lakhs':
        return 220000.0;
      case '₹3 Lakhs - ₹5 Lakhs':
        return 400000.0;
      case '₹5 Lakhs - ₹8 Lakhs':
        return 650000.0;
      case 'Above ₹8 Lakhs':
        return 1000000.0;
      default:
        return 0.0;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1998, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final hasUserEnteredText = _houseController.text.isNotEmpty ||
        _streetController.text.isNotEmpty ||
        _areaController.text.isNotEmpty ||
        _villageController.text.isNotEmpty ||
        _pinController.text.isNotEmpty ||
        (_selectedState != null && _selectedState != 'Tamil Nadu') ||
        (_selectedDistrict != null && _selectedDistrict != 'Chennai') ||
        (_selectedCity != null && _selectedCity != 'Chennai');

    if (hasUserEnteredText) {
      final shouldOverwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.cardBorderColor),
          ),
          title: Text(
            'Overwrite details?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'You have already entered some address details. Do you want to overwrite them with your current location?',
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Overwrite',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (shouldOverwrite != true) {
        return;
      }
    }

    setState(() {
      _isLocating = true;
    });

    try {
      final locData = await provider.fetchLocationAndPopulate();

      if (locData != null) {
        _houseController.text = locData['house'] ?? '';
        _streetController.text = locData['street'] ?? '';
        _areaController.text = locData['area'] ?? '';
        _villageController.text = locData['village'] ?? '';
        _pinController.text = locData['pinCode'] ?? '';
        _latitudeController.text = (locData['latitude'] ?? '').toString();
        _longitudeController.text = (locData['longitude'] ?? '').toString();

        setState(() {
          final stateVal = locData['state'] as String;
          if (stateVal.isNotEmpty) {
            _selectedState = stateVal;
            if (!_districtsByState.containsKey(_selectedState)) {
              _districtsByState[_selectedState!] = [locData['district'] ?? ''];
            }
          }

          final distVal = locData['district'] as String;
          if (distVal.isNotEmpty) {
            _selectedDistrict = distVal;
            if (!(_districtsByState[_selectedState] ?? []).contains(_selectedDistrict)) {
              _districtsByState[_selectedState!] = [_selectedDistrict!, ...?_districtsByState[_selectedState]];
            }
          }

          final cityVal = locData['city'] as String;
          if (cityVal.isNotEmpty) {
            _selectedCity = cityVal;
            if (!(_districtsByState[_selectedState] ?? []).contains(_selectedCity)) {
              _districtsByState[_selectedState!] = [_selectedCity!, ...?_districtsByState[_selectedState]];
            }
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location fetched and populated successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch location: $e'),
            backgroundColor: AppConstants.errorColor,
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

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final income = _mapRangeToIncome(_selectedIncomeRange ?? 'Under ₹1.5 Lakhs');

    final updatedProfile = provider.profile.copyWith(
      name: _nameController.text.trim(),
      dob: _selectedDob,
      gender: _selectedGender ?? 'Female',
      house: _houseController.text.trim(),
      street: _streetController.text.trim(),
      area: _areaController.text.trim(),
      village: _villageController.text.trim(),
      address: '${_houseController.text.trim()}, ${_streetController.text.trim()}, ${_areaController.text.trim()}',
      state: _selectedState ?? 'Tamil Nadu',
      district: _selectedDistrict ?? '',
      city: _selectedCity ?? '',
      pinCode: _pinController.text.trim(),
      community: _selectedCommunity,
      employmentStatus: _selectedEmployment,
      annualIncome: income,
      veteran: _isVeteran,
      disability: _hasDisability ? _disabilityController.text.trim() : 'None',
      qualification: _selectedQualification,
      existingBusiness: _existingBusiness,
      businessStage: _selectedBusinessStage,
      businessIndustry: _selectedBusinessIndustry,
      fundingRequired: double.tryParse(_fundingController.text.trim()) ?? 0.0,
      registrationNumbers: _regNumbersController.text.trim(),
      profileCompleted: true,
    );

    await provider.updateProfile(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );

      if (widget.fromEligibilityCheck) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const EligibilityResultsScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainTabsContainer(),
          ),
        );
      }
    }
  }

  InputDecoration _getInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0D47A1)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.errorColor),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0D47A1),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D47A1),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.35,
              child: Image.asset(
                'assets/images/splash_screen.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.35,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x00F8FAFC),
                      Color(0xFFF8FAFC),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/Logo.png',
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete Your Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Help us build your eligibility profile to\nfind the most relevant schemes for you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Profile Completion Percentage Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Profile Completion',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                ),
                                Text(
                                  '${provider.profileCompletionPercentage}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: provider.profileCompletionPercentage / 100,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            if (provider.missingProfileSections.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Missing: ${provider.missingProfileSections.join(', ')}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.redAccent.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            // SECTION 1: Personal Information
                            _buildSectionHeader('Personal Information', Icons.person_outline),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Full Name (as per Aadhaar)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                  decoration: _getInputDecoration('Enter full name'),
                                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Date of Birth / Age'),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => _selectDate(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _selectedDob == null
                                                      ? 'DD/MM/YYYY'
                                                      : '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: _selectedDob == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                color: Color(0xFF64748B),
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Gender'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedGender,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Select gender'),
                                        items: const [
                                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                                          DropdownMenuItem(value: 'Transgender', child: Text('Transgender')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedGender = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Mobile Number'),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    provider.mobileNumber.isNotEmpty ? '+91 ${provider.mobileNumber}' : '+91 98765 43210',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                            const SizedBox(height: 16),

                            // SECTION 2: Address with Use Current Location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildSectionHeader('Address Details', Icons.location_on_outlined),
                                ),
                                Flexible(
                                  child: TextButton.icon(
                                    onPressed: _isLocating ? null : _useCurrentLocation,
                                    icon: _isLocating
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D47A1)),
                                          )
                                        : const Icon(Icons.my_location, size: 14, color: Color(0xFF0D47A1)),
                                    label: Text(
                                      _isLocating ? 'Locating...' : 'Use Current Location',
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('House No.'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _houseController,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('E.g. 42-A'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Street'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _streetController,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('E.g. Park Street'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Area / Locality'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _areaController,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('E.g. T. Nagar'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Village (Optional)'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _villageController,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Enter village'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('State'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedState,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Select state'),
                                        items: _districtsByState.keys.map((s) {
                                          return DropdownMenuItem(value: s, child: Text(s));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedState = val;
                                              _selectedDistrict = _districtsByState[val]!.first;
                                              _selectedCity = _districtsByState[val]!.first;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('District'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedDistrict,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Select district'),
                                        items: (_districtsByState[_selectedState] ?? []).map((d) {
                                          return DropdownMenuItem(value: d, child: Text(d));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedDistrict = val;
                                              _selectedCity = val;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('City / Town'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedCity,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Select city'),
                                        items: (_districtsByState[_selectedState] ?? []).map((c) {
                                          return DropdownMenuItem(value: c, child: Text(c));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedCity = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('PIN Code'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _pinController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Enter PIN').copyWith(counterText: ''),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Required';
                                          if (val.length != 6 || int.tryParse(val) == null) return 'Invalid';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                            const SizedBox(height: 16),

                            // SECTION 3: Social & Special Categories
                            _buildSectionHeader('Social & Special Details', Icons.people_outline),
                            const SizedBox(height: 16),
                            _buildInputLabel('Category / Community'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedCommunity,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                              decoration: _getInputDecoration('Select category'),
                              items: _communityOptions.map((opt) {
                                return DropdownMenuItem(value: opt, child: Text(opt));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCommunity = val);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Veteran & Disability Row
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('Veteran Status', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                    value: _isVeteran,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _isVeteran = val);
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('Disability', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                    value: _hasDisability,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _hasDisability = val;
                                          if (!val) _disabilityController.clear();
                                        });
                                      }
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                              ],
                            ),
                            if (_hasDisability) ...[
                              const SizedBox(height: 12),
                              _buildInputLabel('Describe Disability'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _disabilityController,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                decoration: _getInputDecoration('Enter details (e.g. Visual 40%)'),
                              ),
                            ],
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                            const SizedBox(height: 16),

                            // SECTION 4: Education & Employment
                            _buildSectionHeader('Education & Employment', Icons.school_outlined),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Qualification'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedQualification,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Select qualification'),
                                        items: const [
                                          DropdownMenuItem(value: 'School', child: Text('School')),
                                          DropdownMenuItem(value: 'Diploma', child: Text('Diploma')),
                                          DropdownMenuItem(value: 'Undergraduate', child: Text('Undergraduate')),
                                          DropdownMenuItem(value: 'Postgraduate', child: Text('Postgraduate')),
                                          DropdownMenuItem(value: 'Ph.D.', child: Text('Ph.D.')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedQualification = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Employment Status'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedEmployment,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Select employment'),
                                        items: _employmentOptions.map((opt) {
                                          return DropdownMenuItem<String>(
                                            value: opt.title,
                                            child: Text(opt.title),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedEmployment = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                            const SizedBox(height: 16),

                            // SECTION 5: Business Details
                            _buildSectionHeader('Business Details', Icons.storefront_outlined),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Existing Business / Entrepreneur', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              value: _existingBusiness,
                              onChanged: (val) {
                                setState(() => _existingBusiness = val);
                              },
                              activeThumbColor: const Color(0xFF0D47A1),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _existingBusiness
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildInputLabel('Business Stage'),
                                                  const SizedBox(height: 6),
                                                  DropdownButtonFormField<String>(
                                                    isExpanded: true,
                                                    initialValue: _selectedBusinessStage,
                                                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                                    decoration: _getInputDecoration('Select stage'),
                                                    items: const [
                                                      DropdownMenuItem(value: 'Idea', child: Text('Idea')),
                                                      DropdownMenuItem(value: 'Prototype', child: Text('Prototype')),
                                                      DropdownMenuItem(value: 'Registered', child: Text('Registered')),
                                                      DropdownMenuItem(value: 'Operational', child: Text('Operational')),
                                                      DropdownMenuItem(value: 'Expansion', child: Text('Expansion')),
                                                    ],
                                                    onChanged: (val) {
                                                      if (val != null) setState(() => _selectedBusinessStage = val);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildInputLabel('Industry Sector'),
                                                  const SizedBox(height: 6),
                                                  DropdownButtonFormField<String>(
                                                    isExpanded: true,
                                                    initialValue: _selectedBusinessIndustry,
                                                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                                    decoration: _getInputDecoration('Select industry'),
                                                    items: const [
                                                      DropdownMenuItem(value: 'Technology', child: Text('Technology')),
                                                      DropdownMenuItem(value: 'Agriculture', child: Text('Agriculture')),
                                                      DropdownMenuItem(value: 'Manufacturing', child: Text('Manufacturing')),
                                                      DropdownMenuItem(value: 'Healthcare', child: Text('Healthcare')),
                                                      DropdownMenuItem(value: 'Retail / Services', child: Text('Retail / Services')),
                                                    ],
                                                    onChanged: (val) {
                                                      if (val != null) setState(() => _selectedBusinessIndustry = val);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInputLabel('Funding Required (₹)'),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _fundingController,
                                              keyboardType: TextInputType.number,
                                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                              decoration: _getInputDecoration('Enter funding required'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInputLabel('Annual Income (₹)'),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              initialValue: _selectedIncomeRange,
                                              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF1E293B)),
                                              decoration: _getInputDecoration('Select income range'),
                                              items: const [
                                                DropdownMenuItem(value: 'Under ₹1.5 Lakhs', child: Text('Below ₹1.5 Lakh')),
                                                DropdownMenuItem(value: '₹1.5 Lakhs - ₹3 Lakhs', child: Text('₹1.5 Lakh - ₹3 Lakh')),
                                                DropdownMenuItem(value: '₹3 Lakhs - ₹5 Lakhs', child: Text('₹3 Lakh - ₹5 Lakh')),
                                                DropdownMenuItem(value: '₹5 Lakhs - ₹8 Lakhs', child: Text('₹5 Lakh - ₹8 Lakh')),
                                                DropdownMenuItem(value: 'Above ₹8 Lakhs', child: Text('Above ₹8 Lakh')),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) setState(() => _selectedIncomeRange = val);
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInputLabel('Registration Numbers (GST/UDYAM/PAN)'),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _regNumbersController,
                                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                              decoration: _getInputDecoration('E.g. GSTIN / UDYAM Reg No.'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D47A1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _saveProfile,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Save & Continue',
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
