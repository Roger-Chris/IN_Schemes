import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'eligibility_results_screen.dart';

class FindMySchemesScreen extends StatefulWidget {
  const FindMySchemesScreen({super.key});

  @override
  State<FindMySchemesScreen> createState() => _FindMySchemesScreenState();
}

class _FindMySchemesScreenState extends State<FindMySchemesScreen> {
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];
  
  // Controllers
  final _nameController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinController = TextEditingController();
  final _incomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize wizard in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.startWizard();
      
      // Load controllers from wizard initial state
      final answers = provider.wizardAnswers;
      _nameController.text = answers['name'] ?? '';
      _districtController.text = answers['district'] ?? '';
      _cityController.text = answers['city'] ?? '';
      _pinController.text = answers['pinCode'] ?? '';
      if (answers['annualIncome'] != null && answers['annualIncome'] > 0) {
        _incomeController.text = (answers['annualIncome'] as double).toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _pinController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _nextStep(AppProvider provider) {
    final currentStep = provider.wizardStep;
    
    // Validate current step form
    if (!_formKeys[currentStep].currentState!.validate()) {
      return;
    }

    // Save controller inputs to wizard answers
    if (currentStep == 0) {
      provider.updateWizardAnswer('name', _nameController.text.trim());
      provider.updateWizardAnswer('district', _districtController.text.trim());
      provider.updateWizardAnswer('city', _cityController.text.trim());
      provider.updateWizardAnswer('pinCode', _pinController.text.trim());
    } else if (currentStep == 1) {
      provider.updateWizardAnswer('annualIncome', double.tryParse(_incomeController.text.trim()) ?? 0.0);
    }

    if (currentStep < 2) {
      provider.nextWizardStep();
    } else {
      // Submit wizard on final step
      provider.submitWizard();
      
      // Route to Eligibility Results screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const EligibilityResultsScreen(),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, AppProvider provider, DateTime currentDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDob,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.updateWizardAnswer('dob', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final answers = provider.wizardAnswers;
    final currentStep = provider.wizardStep;

    if (answers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Find My Schemes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Progress Indicator
            _buildProgressBar(currentStep),
            const SizedBox(height: 24),
            
            // Questionnaire Card
            Expanded(
              child: Card(
                elevation: 4,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppConstants.cardBorderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: const TextStyle(color: AppConstants.secondaryText),
                        hintStyle: const TextStyle(color: AppConstants.secondaryText),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppConstants.cardBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppConstants.primaryColor),
                        ),
                        errorStyle: const TextStyle(color: AppConstants.errorColor),
                      ),
                    ),
                    child: Form(
                      key: _formKeys[currentStep],
                      child: IndexedStack(
                        index: currentStep,
                        children: [
                          _buildStep1(provider, answers),
                          _buildStep2(provider, answers),
                          _buildStep3(provider, answers),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Bottom Action buttons (Back / Next)
            Row(
              children: [
                if (currentStep > 0) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Back',
                      isSecondary: true,
                      onPressed: () {
                        // Unfocus text fields
                        FocusScope.of(context).unfocus();
                        provider.previousWizardStep();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: CustomButton(
                    text: currentStep == 2 ? 'Submit & Match' : 'Next',
                    onPressed: () => _nextStep(provider),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assessment Step ${step + 1} of 3',
              style: const TextStyle(color: AppConstants.secondaryText, fontSize: 13),
            ),
            Text(
              '${((step + 1) / 3 * 100).round()}% Completed',
              style: const TextStyle(color: AppConstants.accentColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (step + 1) / 3,
            backgroundColor: AppConstants.cardBorderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // STEP 1: Personal & Location Details
  Widget _buildStep1(AppProvider provider, Map<String, dynamic> answers) {
    final dob = answers['dob'] as DateTime? ?? DateTime(1998, 1, 1);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal & Location Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'Name as in Aadhaar'),
            validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: answers['gender'] ?? 'Female',
            dropdownColor: AppConstants.surfaceColor,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const [
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Transgender', child: Text('Transgender')),
            ],
            onChanged: (val) => provider.updateWizardAnswer('gender', val),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context, provider, dob),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date of Birth'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${dob.day}/${dob.month}/${dob.year} (Age: ${DateTime.now().year - dob.year})',
                    style: const TextStyle(color: AppConstants.primaryText),
                  ),
                  const Icon(Icons.calendar_today, color: AppConstants.secondaryText, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: answers['state'] ?? 'Tamil Nadu',
            dropdownColor: AppConstants.surfaceColor,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'State'),
            items: const [
              DropdownMenuItem(value: 'Tamil Nadu', child: Text('Tamil Nadu')),
              DropdownMenuItem(value: 'Karnataka', child: Text('Karnataka')),
              DropdownMenuItem(value: 'Kerala', child: Text('Kerala')),
              DropdownMenuItem(value: 'Maharashtra', child: Text('Maharashtra')),
            ],
            onChanged: (val) => provider.updateWizardAnswer('state', val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _districtController,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'District'),
            validator: (val) => val == null || val.isEmpty ? 'Please enter your district' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'City / Town / Village'),
            validator: (val) => val == null || val.isEmpty ? 'Please enter your city/village' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'PIN Code'),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter PIN code';
              if (val.length != 6 || int.tryParse(val) == null) return 'Enter 6 digit PIN';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // STEP 2: Income Details
  Widget _buildStep2(AppProvider provider, Map<String, dynamic> answers) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your family income decides your eligibility for subsidies and grant limits.',
            style: TextStyle(color: AppConstants.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(
              labelText: 'Annual Family Income (₹)',
              hintText: 'e.g. 350000',
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter annual income';
              if (double.tryParse(val) == null) return 'Enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Short notice on privacy
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: AppConstants.accentColor, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your data is securely stored locally and only used to match schemes.',
                    style: TextStyle(color: AppConstants.secondaryText, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Education & Social Details
  Widget _buildStep3(AppProvider provider, Map<String, dynamic> answers) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Education & Social Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: answers['educationLevel'] ?? 'Undergraduate',
            dropdownColor: AppConstants.surfaceColor,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'Education Level'),
            items: const [
              DropdownMenuItem(value: 'School', child: Text('School Level (Primary/Secondary)')),
              DropdownMenuItem(value: 'Diploma', child: Text('Diploma / ITI')),
              DropdownMenuItem(value: 'Undergraduate', child: Text('Undergraduate (Degree)')),
              DropdownMenuItem(value: 'Postgraduate', child: Text('Postgraduate (Master\'s)')),
              DropdownMenuItem(value: 'Ph.D.', child: Text('Ph.D. / Research')),
            ],
            onChanged: (val) => provider.updateWizardAnswer('educationLevel', val),
          ),
          const SizedBox(height: 16),
          
          // First Generation Graduate switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'First Generation Graduate?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryText, fontSize: 14),
                  ),
                  Text(
                    'No one in your direct family has a degree',
                    style: TextStyle(color: AppConstants.secondaryText, fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: answers['firstGenGraduate'] ?? false,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: (val) => provider.updateWizardAnswer('firstGenGraduate', val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: answers['community'] ?? 'General',
            dropdownColor: AppConstants.surfaceColor,
            style: const TextStyle(color: AppConstants.primaryText),
            decoration: const InputDecoration(labelText: 'Community / Caste Category'),
            items: const [
              DropdownMenuItem(value: 'General', child: Text('General')),
              DropdownMenuItem(value: 'OBC', child: Text('OBC')),
              DropdownMenuItem(value: 'EWS', child: Text('EWS')),
              DropdownMenuItem(value: 'SC', child: Text('SC')),
              DropdownMenuItem(value: 'ST', child: Text('ST')),
            ],
            onChanged: (val) => provider.updateWizardAnswer('community', val),
          ),
        ],
      ),
    );
  }
}
