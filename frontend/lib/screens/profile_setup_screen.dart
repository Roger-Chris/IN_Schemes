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
  
  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinController = TextEditingController();

  DateTime? _selectedDob;
  String? _selectedGender = 'Female';
  String? _selectedState = 'Tamil Nadu';
  String? _selectedDistrict = 'Chennai';
  String? _selectedCity = 'Chennai';
  String _selectedCommunity = 'General';
  String _selectedEmployment = 'Student';
  String? _selectedIncomeRange = 'Under ₹1.5 Lakhs';

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
      iconColor: Color(0xFF2563EB), // Blue 600
      iconBgColor: Color(0xFFDBEAFE), // Blue 100
    ),
    EmploymentOption(
      title: 'Farmer',
      icon: Icons.agriculture_outlined,
      iconColor: Color(0xFF16A34A), // Green 600
      iconBgColor: Color(0xFFDCFCE7), // Green 100
    ),
    EmploymentOption(
      title: 'Salaried',
      icon: Icons.business_center_outlined,
      iconColor: Color(0xFF7C3AED), // Purple 600
      iconBgColor: Color(0xFFF3E8FF), // Purple 100
    ),
    EmploymentOption(
      title: 'Self-employed',
      icon: Icons.person_outline,
      iconColor: Color(0xFFD97706), // Amber 600
      iconBgColor: Color(0xFFFEF3C7), // Amber 100
    ),
    EmploymentOption(
      title: 'Business Owner',
      icon: Icons.storefront_outlined,
      iconColor: Color(0xFF0F172A), // Slate 900
      iconBgColor: Color(0xFFF1F5F9), // Slate 100
    ),
    EmploymentOption(
      title: 'Homemaker',
      icon: Icons.home_outlined,
      iconColor: Color(0xFFE11D48), // Rose 600
      iconBgColor: Color(0xFFFFE4E6), // Rose 100
    ),
    EmploymentOption(
      title: 'Unemployed',
      icon: Icons.search_outlined,
      iconColor: Color(0xFFDC2626), // Red 600
      iconBgColor: Color(0xFFFEE2E2), // Red 100
    ),
    EmploymentOption(
      title: 'Retired',
      icon: Icons.directions_walk,
      iconColor: Color(0xFF0D9488), // Teal 600
      iconBgColor: Color(0xFFCCFBF1), // Teal 100
    ),
    EmploymentOption(
      title: 'Other',
      icon: Icons.more_horiz_outlined,
      iconColor: Color(0xFF475569), // Slate 600
      iconBgColor: Color(0xFFE2E8F0), // Slate 200
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final profile = provider.profile;
      
      _nameController.text = profile.name;
      _addressController.text = profile.address;
      _pinController.text = profile.pinCode;
      
      setState(() {
        _selectedDob = profile.dob;
        if (profile.gender.isNotEmpty) _selectedGender = profile.gender;
        if (profile.state.isNotEmpty) _selectedState = profile.state;
        
        // Safety check state exists in dictionary keys
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
        
        _selectedIncomeRange = _mapIncomeToRange(profile.annualIncome);
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _pinController.dispose();
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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final income = _mapRangeToIncome(_selectedIncomeRange ?? 'Under ₹1.5 Lakhs');

    final updatedProfile = provider.profile.copyWith(
      name: _nameController.text.trim(),
      dob: _selectedDob,
      gender: _selectedGender ?? 'Female',
      address: _addressController.text.trim(),
      state: _selectedState ?? 'Tamil Nadu',
      district: _selectedDistrict ?? '',
      city: _selectedCity ?? '',
      pinCode: _pinController.text.trim(),
      community: _selectedCommunity,
      employmentStatus: _selectedEmployment,
      annualIncome: income,
    );

    provider.updateProfile(updatedProfile);

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

  InputDecoration _getInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF94A3B8), // Slate 400
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)), // Slate 300
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0D47A1)), // Royal Blue
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
        color: const Color(0xFF1E293B), // Slate 800
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
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D47A1), // Royal Blue
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
            // 1. Top background image with map overlay
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
            
            // 2. Fading gradient overlay (prevent black gradient tint)
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

            // 3. Scrollable Content
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // Brand Logo
                      Image.asset(
                        'assets/images/Logo.png',
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      
                      // Title
                      Text(
                        'Complete Your Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A), // Slate 900
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Subtitle
                      Text(
                        'Help us build your eligibility profile to\nfind the most relevant schemes for you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B), // Slate 500
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0x05000000), // 2% opacity
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
                            
                            // Full Name (Separate Row)
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
                            
                            // Date of Birth & Gender Row
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
                            
                            // Mobile Number (Separate Row)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Mobile Number'),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9), // Grayed out background
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    provider.mobileNumber.isNotEmpty ? '+91 ${provider.mobileNumber}' : '+91 98765 43210',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B), // Slate 500
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Address Row
                            _buildInputLabel('Address'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _addressController,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                              decoration: _getInputDecoration(
                                'House No., Street, Locality',
                                suffixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF64748B),
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // State & District Row
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
                            
                            // City/Village & PIN Code Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('City / Village'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedCity,
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                        decoration: _getInputDecoration('Select city / village'),
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
                                        decoration: _getInputDecoration('Enter PIN code').copyWith(counterText: ''),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Required';
                                          if (val.length != 6 || int.tryParse(val) == null) return 'Enter 6-digit PIN';
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
                            
                            // SECTION 2: Social Details
                            _buildSectionHeader('Social Details', Icons.people_outline),
                            const SizedBox(height: 16),
                            
                            _buildInputLabel('Category / Community'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedCommunity,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                              decoration: _getInputDecoration('Select category / community'),
                              items: _communityOptions.map((opt) {
                                return DropdownMenuItem(value: opt, child: Text(opt));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCommunity = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                            const SizedBox(height: 16),
                            
                            // SECTION 3: Employment
                            _buildSectionHeader('Employment', Icons.business_center_outlined),
                            const SizedBox(height: 16),
                            
                            _buildInputLabel('Employment Status'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedEmployment,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                              decoration: _getInputDecoration('Select employment status'),
                              items: _employmentOptions.map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt.title,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: opt.iconBgColor,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          opt.icon,
                                          color: opt.iconColor,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(opt.title),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedEmployment = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                            const SizedBox(height: 16),
                            
                            // SECTION 4: Financial
                            _buildSectionHeader('Financial', Icons.currency_rupee),
                            const SizedBox(height: 16),
                            
                            _buildInputLabel('Annual Family Income'),
                            const SizedBox(height: 6),
                            
                            DropdownButtonFormField<String>(
                              initialValue: _selectedIncomeRange,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                              decoration: _getInputDecoration('Select annual income range'),
                              items: const [
                                DropdownMenuItem(value: 'Under ₹1.5 Lakhs', child: Text('Under ₹1.5 Lakhs')),
                                DropdownMenuItem(value: '₹1.5 Lakhs - ₹3 Lakhs', child: Text('₹1.5 Lakhs - ₹3 Lakhs')),
                                DropdownMenuItem(value: '₹3 Lakhs - ₹5 Lakhs', child: Text('₹3 Lakhs - ₹5 Lakhs')),
                                DropdownMenuItem(value: '₹5 Lakhs - ₹8 Lakhs', child: Text('₹5 Lakhs - ₹8 Lakhs')),
                                DropdownMenuItem(value: 'Above ₹8 Lakhs', child: Text('Above ₹8 Lakhs')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedIncomeRange = val);
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Save & Continue Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D47A1), // Royal Blue
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
