import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../models/user_profile.dart';

class SmartAssessmentBottomSheet extends StatefulWidget {
  final String cardTitle;
  final String cardType; // 'category', 'ministry', 'state'
  final VoidCallback onCompleted;

  const SmartAssessmentBottomSheet({
    super.key,
    required this.cardTitle,
    required this.cardType,
    required this.onCompleted,
  });

  static void show(BuildContext context, String title, String type, VoidCallback onCompleted) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartAssessmentBottomSheet(
        cardTitle: title,
        cardType: type,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<SmartAssessmentBottomSheet> createState() => _SmartAssessmentBottomSheetState();
}

class _SmartAssessmentBottomSheetState extends State<SmartAssessmentBottomSheet> {
  late String _currentQuestionId;
  final Map<String, String> _answers = {};
  final List<String> _questionHistory = [];

  // Define Question Flows for different cards
  late Map<String, _QuestionNode> _questionFlow;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  void _initializeFlow() {
    // Normalize target name for key matching
    final title = widget.cardTitle.toLowerCase().trim();

    if (widget.cardType == 'category') {
      if (title.contains('agri') || title.contains('farm')) {
        _questionFlow = _getAgricultureFlow();
        _currentQuestionId = 'agri_q1';
      } else if (title.contains('educat') || title.contains('scholar') || title.contains('student')) {
        _questionFlow = _getEducationFlow();
        _currentQuestionId = 'edu_q1';
      } else if (title.contains('women') || title.contains('child') || title.contains('matern')) {
        _questionFlow = _getWomenFlow();
        _currentQuestionId = 'women_q1';
      } else if (title.contains('senior') || title.contains('pension') || title.contains('elder')) {
        _questionFlow = _getSeniorFlow();
        _currentQuestionId = 'senior_q1';
      } else if (title.contains('health') || title.contains('well')) {
        _questionFlow = _getHealthFlow();
        _currentQuestionId = 'health_q1';
      } else if (title.contains('business') || title.contains('msme') || title.contains('start') || title.contains('artisan')) {
        _questionFlow = _getBusinessFlow();
        _currentQuestionId = 'biz_q1';
      } else {
        // Default category flow
        _questionFlow = _getDefaultCategoryFlow();
        _currentQuestionId = 'cat_q1';
      }
    } else if (widget.cardType == 'state') {
      _questionFlow = _getStateFlow(widget.cardTitle);
      _currentQuestionId = 'state_q1';
    } else {
      // Ministry or general default flow
      _questionFlow = _getMinistryFlow(widget.cardTitle);
      _currentQuestionId = 'min_q1';
    }
  }

  Color _getThemeColor() {
    return const Color(0xFF2563EB); // Unified Royal Blue theme
  }

  void _onOptionSelected(String option) {
    setState(() {
      _answers[_currentQuestionId] = option;
      _questionHistory.add(_currentQuestionId);

      final currentNode = _questionFlow[_currentQuestionId]!;
      final nextId = currentNode.nextId(option);

      if (nextId != null && _questionFlow.containsKey(nextId)) {
        _currentQuestionId = nextId;
      } else {
        _submitAnswers();
      }
    });
  }

  void _goBack() {
    if (_questionHistory.isNotEmpty) {
      setState(() {
        _currentQuestionId = _questionHistory.removeLast();
        _answers.remove(_currentQuestionId);
      });
    }
  }

  void _submitAnswers() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final profile = provider.profile;

    // Create a copy of user profile to modify
    String gender = profile.gender;
    String state = profile.state;
    String community = profile.community;
    double income = profile.annualIncome;
    String employment = profile.employmentStatus;
    bool existingBiz = profile.existingBusiness;
    String bizStage = profile.businessStage;

    // Apply values based on answered flows
    _answers.forEach((qId, ans) {
      if (qId.contains('income') || qId.contains('turnover') || qId.endsWith('q5')) {
        // Income mapper
        if (ans.contains('Under ₹1') || ans.contains('Under ₹1.2') || ans.contains('Under ₹1.5') || ans.contains('Under ₹1.8')) {
          income = 120000.0;
        } else if (ans.contains('₹1.2') || ans.contains('₹1.5') || ans.contains('Under ₹2') || ans.contains('Under ₹2.5')) {
          income = 200000.0;
        } else if (ans.contains('₹2.5') || ans.contains('₹1.8 - ₹3') || ans.contains('₹2 - ₹8')) {
          income = 450000.0;
        } else if (ans.contains('Over ₹8') || ans.contains('Over ₹6') || ans.contains('Over ₹10')) {
          income = 900000.0;
        }
      }

      if (qId.contains('caste') || qId.contains('category') || qId.contains('reservation')) {
        if (ans.contains('SC')) {
          community = 'SC';
        } else if (ans.contains('ST')) {
          community = 'ST';
        } else if (ans.contains('OBC') || ans.contains('BC') || ans.contains('SEBC') || ans.contains('MBC')) {
          community = 'OBC';
        } else if (ans.contains('EWS')) {
          community = 'EWS';
        } else {
          community = 'General';
        }
      }

      if (qId.contains('gender')) {
        if (ans.contains('Female') || ans.contains('woman') || ans.contains('Women')) {
          gender = 'Female';
        } else {
          gender = 'Male';
        }
      }

      if (qId.contains('livelihood') || qId.contains('profession') || qId.contains('occupation')) {
        if (ans.contains('Farmer')) {
          employment = 'Farmer';
        } else if (ans.contains('Student')) {
          employment = 'Student';
        } else if (ans.contains('Business') || ans.contains('Startup') || ans.contains('entrepreneur')) {
          employment = 'Business Owner';
        } else if (ans.contains('Self-employed')) {
          employment = 'Self-employed';
        } else if (ans.contains('Unemployed')) {
          employment = 'Unemployed';
        }
      }

      if (qId.contains('business') || qId.contains('startup')) {
        if (ans.contains('Yes')) existingBiz = true;
        if (ans.contains('Idea')) bizStage = 'Idea';
        if (ans.contains('Prototype')) bizStage = 'Prototype';
        if (ans.contains('Operational') || ans.contains('Registered')) bizStage = 'Operational';
      }
    });

    // Set state or category filter directly in AppProvider
    provider.clearFilters();
    if (widget.cardType == 'state') {
      state = widget.cardTitle;
      provider.updateFilter('state', state);
    } else if (widget.cardType == 'category') {
      provider.updateFilter('category', widget.cardTitle);
    } else if (widget.cardType == 'ministry') {
      provider.updateFilter('ministry', widget.cardTitle);
    }

    // Save updated profile
    final updatedProfile = UserProfile(
      name: profile.name,
      dob: profile.dob,
      gender: gender,
      mobile: profile.mobile,
      email: profile.email,
      address: profile.address,
      state: state,
      district: profile.district,
      city: profile.city,
      pinCode: profile.pinCode,
      community: community,
      religion: profile.religion,
      educationLevel: profile.educationLevel,
      firstGenGraduate: profile.firstGenGraduate,
      annualIncome: income,
      employmentStatus: employment,
      existingBusiness: existingBiz,
      businessStage: bizStage,
      businessIndustry: profile.businessIndustry,
      fundingRequired: profile.fundingRequired,
      registrationNumbers: profile.registrationNumbers,
      profileCompleted: profile.profileCompleted,
      disability: profile.disability,
      language: profile.language,
      navigationMode: profile.navigationMode,
    );

    // Trigger update asynchronously (background Supabase sync)
    provider.updateProfile(updatedProfile);
    
    // Dismiss sheet and transition immediately to avoid network blocking lag
    Navigator.pop(context);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final node = _questionFlow[_currentQuestionId];
    if (node == null) return const SizedBox.shrink();

    final themeColor = _getThemeColor();
    final totalSteps = 5;
    final currentStep = _questionHistory.length + 1;
    final progress = currentStep / totalSteps;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: widget.cardType == 'state' ? EdgeInsets.zero : const EdgeInsets.all(6),
                    decoration: widget.cardType == 'state'
                        ? null
                        : BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                    child: widget.cardType == 'state'
                        ? Image.asset(
                            _getStateMapAsset(widget.cardTitle),
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return CustomPaint(
                                size: const Size(32, 32),
                                painter: StateMapPainter(widget.cardTitle),
                              );
                            },
                          )
                        : Icon(
                            widget.cardType == 'ministry'
                                ? Icons.account_balance_rounded
                                : Icons.grid_view_rounded,
                            color: themeColor,
                            size: 16,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.cardTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFEFF6FF),
                    color: themeColor,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Step $currentStep of $totalSteps",
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Animated Question Box
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<String>(_currentQuestionId),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.questionText,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Options list
                ...node.options.map((option) {
                  final isSelected = _answers[_currentQuestionId] == option;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _onOptionSelected(option),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        alignment: Alignment.centerLeft,
                        backgroundColor: isSelected ? themeColor.withValues(alpha: 0.06) : Colors.white,
                        side: BorderSide(
                          color: isSelected ? themeColor : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? themeColor : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_questionHistory.isNotEmpty)
                TextButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(
                    "Back",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                )
              else
                const SizedBox.shrink(),
              TextButton(
                onPressed: _submitAnswers,
                style: TextButton.styleFrom(foregroundColor: themeColor),
                child: Text(
                  "Skip to Results",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- QUESTION FLOW GENERATORS ---

  Map<String, _QuestionNode> _getAgricultureFlow() {
    return {
      'agri_q1': _QuestionNode(
        questionText: "Do you own cultivable agricultural land?",
        options: ["Yes, I am a land owner", "No, I am a tenant farmer / laborer"],
        nextId: (ans) => ans.contains("Yes") ? "agri_q2_owner" : "agri_q2_landless",
      ),
      'agri_q2_owner': _QuestionNode(
        questionText: "What is the total size of your land holding?",
        options: [
          "Marginal (Less than 1 Hectare)",
          "Small (1 to 2 Hectares)",
          "Medium (2 to 5 Hectares)",
          "Large (Over 5 Hectares)"
        ],
        nextId: (ans) => ans.contains("Marginal") || ans.contains("Small") ? "agri_q3_small" : "agri_q3_large",
      ),
      'agri_q2_landless': _QuestionNode(
        questionText: "What describes your farm activity best?",
        options: [
          "Allied Activities (Dairy / Poultry / Fisheries)",
          "Manual Farm Laborer",
        ],
        nextId: (ans) => ans.contains("Allied") ? "agri_q3_allied" : "agri_q3_labor",
      ),
      'agri_q3_small': _QuestionNode(
        questionText: "Are you registered under PM-KISAN database?",
        options: ["Yes, registered", "No, not registered"],
        nextId: (_) => "agri_q4_owner",
      ),
      'agri_q3_large': _QuestionNode(
        questionText: "Do you have access to a permanent borewell/irrigation source?",
        options: ["Yes, full irrigation", "No, rain-fed only"],
        nextId: (_) => "agri_q4_owner",
      ),
      'agri_q3_allied': _QuestionNode(
        questionText: "Do you hold a Kisan Credit Card (KCC) for allied activities?",
        options: ["Yes, active KCC", "No, need credit support"],
        nextId: (_) => "agri_q4_allied",
      ),
      'agri_q3_labor': _QuestionNode(
        questionText: "Do you possess an active MGNREGA Job Card or E-Shram card?",
        options: ["Yes, possess one", "No, neither"],
        nextId: (_) => "agri_q4_labor",
      ),
      'agri_q4_owner': _QuestionNode(
        questionText: "Which equipment subsidy do you require most?",
        options: ["Solar Water Pumps (PM-KUSUM)", "Drip/Sprinkler Irrigation kits", "Tractor & farm machinery", "Crop Insurance coverage"],
        nextId: (_) => "agri_income",
      ),
      'agri_q4_allied': _QuestionNode(
        questionText: "What capital support do you need for livestock/feed?",
        options: ["Micro-loan under ₹1 Lakh", "Subsidized dairy/poultry tools", "Cold storage infrastructure grant"],
        nextId: (_) => "agri_income",
      ),
      'agri_q4_labor': _QuestionNode(
        questionText: "What type of support would benefit you most?",
        options: ["Personal accident insurance", "Subsidized ration card benefits", "Skill training in allied crafts"],
        nextId: (_) => "agri_income",
      ),
      'agri_income': _QuestionNode(
        questionText: "What is your annual family income?",
        options: [
          "Under ₹1.2 Lakhs",
          "₹1.2 Lakhs - ₹2.5 Lakhs",
          "₹2.5 Lakhs - ₹6 Lakhs",
          "Over ₹6 Lakhs"
        ],
        nextId: (_) => null, // Ends flow
      ),
    };
  }

  Map<String, _QuestionNode> _getEducationFlow() {
    return {
      'edu_q1': _QuestionNode(
        questionText: "What is your current level of education?",
        options: ["Schooling (Up to 12th)", "Undergraduate", "Postgraduate", "Ph.D. & Research"],
        nextId: (ans) => ans.contains("Schooling") ? "edu_q2_school" : ans.contains("Research") ? "edu_q2_research" : "edu_q2_college",
      ),
      'edu_q2_school': _QuestionNode(
        questionText: "What class/grade are you currently enrolled in?",
        options: ["Class 1 - 8 (Primary)", "Class 9 - 10 (Secondary)", "Class 11 - 12 (Higher Secondary)"],
        nextId: (_) => "edu_q3_school",
      ),
      'edu_q2_college': _QuestionNode(
        questionText: "What is your primary stream of study?",
        options: ["STEM (Science/Engineering/IT)", "Arts, Commerce & Humanities", "Medical & Nursing", "Agricultural Studies"],
        nextId: (_) => "edu_q3_college",
      ),
      'edu_q2_research': _QuestionNode(
        questionText: "What is your research specialization domain?",
        options: ["STEM Research & Patents", "Humanities & Social Sciences", "Agricultural/Biological Sciences"],
        nextId: (_) => "edu_q3_research",
      ),
      'edu_q3_school': _QuestionNode(
        questionText: "What type of aid is most important right now?",
        options: ["Pre-matric Scholarship", "Free textbooks & uniforms", "Hostel accommodation subsidy"],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q3_college': _QuestionNode(
        questionText: "Are you interested in a low-interest student education loan?",
        options: ["Yes, need education loan", "No, seeking tuition scholarships only"],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q3_research': _QuestionNode(
        questionText: "Are you seeking a research fellowship or international study grant?",
        options: ["National Fellowship grant", "International study allowance", "Merit publication awards"],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q4_caste': _QuestionNode(
        questionText: "What is your caste/social reservation category?",
        options: ["General", "OBC", "SC / ST", "EWS / Minority"],
        nextId: (_) => "edu_q5_income",
      ),
      'edu_q5_income': _QuestionNode(
        questionText: "What is your family's annual household income?",
        options: ["Under ₹2.5 Lakhs", "₹2.5 Lakhs - ₹8 Lakhs", "Over ₹8 Lakhs"],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, _QuestionNode> _getWomenFlow() {
    return {
      'women_q1': _QuestionNode(
        questionText: "Who is the primary beneficiary of the scheme?",
        options: ["Pregnant or Lactating Mother", "Girl Child (Parent applying)", "Woman Entrepreneur", "Single Woman / Widow in distress"],
        nextId: (ans) => ans.contains("Mother") ? "women_q2_maternal" : ans.contains("Child") ? "women_q2_girl" : ans.contains("Entrepreneur") ? "women_q2_biz" : "women_q2_welfare",
      ),
      'women_q2_maternal': _QuestionNode(
        questionText: "Is this your first or second pregnancy?",
        options: ["First pregnancy", "Second pregnancy", "More than two"],
        nextId: (_) => "women_q3_matern_reg",
      ),
      'women_q2_girl': _QuestionNode(
        questionText: "What is the age of the girl child?",
        options: ["Newborn (0 - 1 Year)", "Child (2 - 10 Years)", "Adolescent (11 - 18 Years)"],
        nextId: (ans) => ans.contains("Adolescent") ? "women_q3_girl_edu" : "women_q3_girl_save",
      ),
      'women_q2_biz': _QuestionNode(
        questionText: "Do women hold at least a 51% ownership stake in the enterprise?",
        options: ["Yes, fully owned by women", "No, minor/shared stake"],
        nextId: (_) => "women_q3_biz_credit",
      ),
      'women_q2_welfare': _QuestionNode(
        questionText: "Do you possess a BPL (Below Poverty Line) Ration Card?",
        options: ["Yes, BPL Cardholder", "No, APL / General"],
        nextId: (_) => "women_q3_welfare_pension",
      ),
      'women_q3_matern_reg': _QuestionNode(
        questionText: "Are you registered at your local Anganwadi/Health center?",
        options: ["Yes, registered", "No, not registered yet"],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_girl_save': _QuestionNode(
        questionText: "Would you like to open a long-term savings account (Sukanya Samriddhi)?",
        options: ["Yes, open savings account", "No, seeking educational scholarships"],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_girl_edu': _QuestionNode(
        questionText: "Is the girl child currently enrolled in school/college?",
        options: ["Yes, attending school/college", "No, discontinued education"],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_biz_credit': _QuestionNode(
        questionText: "What capital support size are you seeking for your business?",
        options: ["Micro-credit (Under ₹1 Lakh)", "SME Loan (₹1 Lakh - ₹10 Lakhs)", "Stand-Up India loan (Over ₹10 Lakhs)"],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_welfare_pension': _QuestionNode(
        questionText: "Are you currently receiving any monthly social pension?",
        options: ["Yes, receiving widow pension", "No pension received"],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q4_caste': _QuestionNode(
        questionText: "What is your caste/social category?",
        options: ["General", "OBC", "SC / ST", "Minority / EWS"],
        nextId: (_) => "women_q5_income",
      ),
      'women_q5_income': _QuestionNode(
        questionText: "What is your family's annual income?",
        options: ["Under ₹1.5 Lakhs", "₹1.5 Lakhs - ₹5 Lakhs", "Over ₹5 Lakhs"],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, _QuestionNode> _getSeniorFlow() {
    return {
      'senior_q1': _QuestionNode(
        questionText: "What is the age of the senior applicant?",
        options: ["60 - 69 Years", "70 - 79 Years", "80 Years and above"],
        nextId: (ans) => ans.contains("80") ? "senior_q2_super" : "senior_q2_active",
      ),
      'senior_q2_active': _QuestionNode(
        questionText: "What is your primary requirement?",
        options: ["Monthly Social Security Pension", "Health Insurance Cover", "Savings interest schemes"],
        nextId: (ans) => ans.contains("Pension") ? "senior_q3_pension" : "senior_q3_health",
      ),
      'senior_q2_super': _QuestionNode(
        questionText: "Do you require home-care assistance or medical devices?",
        options: ["Yes, need wheelchair/assistive aids", "No, looking for pension"],
        nextId: (ans) => ans.contains("pension") ? "senior_q3_pension" : "senior_q3_health",
      ),
      'senior_q3_pension': _QuestionNode(
        questionText: "What is your employment background?",
        options: ["Retired from unorganized manual labor", "Retired from organized/corporate sector", "No formal employment"],
        nextId: (_) => "senior_q4_ration",
      ),
      'senior_q3_health': _QuestionNode(
        questionText: "Do you hold an active Ayushman Bharat PM-JAY health card?",
        options: ["Yes, active card", "No, not registered"],
        nextId: (_) => "senior_q4_ration",
      ),
      'senior_q4_ration': _QuestionNode(
        questionText: "What type of ration card do you possess?",
        options: ["BPL (Below Poverty Line)", "AAY (Antyodaya Anna Yojana)", "APL / General / None"],
        nextId: (_) => "senior_q5_income",
      ),
      'senior_q5_income': _QuestionNode(
        questionText: "What is your annual family income?",
        options: ["Under ₹1.5 Lakhs", "Over ₹1.5 Lakhs"],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, _QuestionNode> _getHealthFlow() {
    return {
      'health_q1': _QuestionNode(
        questionText: "Do you have an active health insurance card (Ayushman Card)?",
        options: ["Yes, active card", "No, do not have one"],
        nextId: (ans) => ans.contains("Yes") ? "health_q2_card" : "health_q2_nocard",
      ),
      'health_q2_card': _QuestionNode(
        questionText: "What type of medical support are you seeking?",
        options: ["Cashless surgery & hospitalization", "Critical care / Cancer support", "Daily medicines discounts"],
        nextId: (_) => "health_q3_income",
      ),
      'health_q2_nocard': _QuestionNode(
        questionText: "What describes your primary livelihood sector?",
        options: ["Unorganized manual laborer", "Small-scale farmer", "Salaried / Organized employee", "Self-employed trader"],
        nextId: (_) => "health_q3_income",
      ),
      'health_q3_income': _QuestionNode(
        questionText: "What is your family's annual income?",
        options: ["Under ₹1.2 Lakhs", "₹1.2 Lakhs - ₹3 Lakhs", "Over ₹3 Lakhs"],
        nextId: (_) => "health_q4_patient",
      ),
      'health_q4_patient': _QuestionNode(
        questionText: "Who is the primary patient requiring coverage?",
        options: ["Senior Citizen (60+)", "Pregnant Mother", "Child (Under 14)", "General Adult"],
        nextId: (_) => "health_q5_ration",
      ),
      'health_q5_ration': _QuestionNode(
        questionText: "What type of ration card does your family hold?",
        options: ["BPL Card", "AAY Card", "APL Card / General", "None"],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, _QuestionNode> _getBusinessFlow() {
    return {
      'biz_q1': _QuestionNode(
        questionText: "Is your business legally registered?",
        options: ["Yes, under MSME Udyam", "Yes, as a DPIIT Startup", "No, operating as individual trader/artisan", "No, it is in idea stage"],
        nextId: (ans) => ans.contains("MSME") ? "biz_q2_msme" : ans.contains("Startup") ? "biz_q2_startup" : ans.contains("trader") ? "biz_q2_artisan" : "biz_q2_idea",
      ),
      'biz_q2_msme': _QuestionNode(
        questionText: "What is the total investment in machinery/equipment?",
        options: ["Micro (Under ₹1 Crore)", "Small (₹1 Crore - ₹10 Crore)", "Medium (Over ₹10 Crore)"],
        nextId: (_) => "biz_q3_msme_need",
      ),
      'biz_q2_startup': _QuestionNode(
        questionText: "What stage is your startup currently in?",
        options: ["Prototype / MVP development", "Early Revenue / Validation", "Scaling & expansion"],
        nextId: (_) => "biz_q3_startup_need",
      ),
      'biz_q2_artisan': _QuestionNode(
        questionText: "Do you hold a valid PM Vishwakarma Card or Artisan ID?",
        options: ["Yes, active card", "No, not registered"],
        nextId: (_) => "biz_q3_artisan_need",
      ),
      'biz_q2_idea': _QuestionNode(
        questionText: "Do you have a business project report prepared?",
        options: ["Yes, report is ready", "No, need project guidance"],
        nextId: (_) => "biz_q3_msme_need",
      ),
      'biz_q3_msme_need': _QuestionNode(
        questionText: "What primary credit/loan support do you need?",
        options: ["Collateral-free Mudra Loan", "Working capital guarantee (CGTMSE)", "Equipment purchase capital subsidy"],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q3_startup_need': _QuestionNode(
        questionText: "Are you seeking equity funding or tax exemptions?",
        options: ["Government Seed Funding", "Section 80-IAC Tax Exemption", "Incubator mentoring grant"],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q3_artisan_need': _QuestionNode(
        questionText: "What support does your craft require?",
        options: ["Free toolkit upgrade voucher", "Exhibition & stall subsidies", "Individual craft micro-loan"],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q4_demographics': _QuestionNode(
        questionText: "Is the primary owner a Woman or SC/ST entrepreneur?",
        options: ["Yes, woman entrepreneur", "Yes, SC/ST entrepreneur", "Yes, both SC/ST & Woman", "General category Male"],
        nextId: (_) => "biz_q5_turnover",
      ),
      'biz_q5_turnover': _QuestionNode(
        questionText: "What is the annual turnover or estimated revenue of the business?",
        options: ["Under ₹10 Lakhs", "₹10 Lakhs - ₹50 Lakhs", "₹50 Lakhs - ₹2 Crores", "Over ₹2 Crores"],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, _QuestionNode> _getDefaultCategoryFlow() {
    return {
      'cat_q1': _QuestionNode(
        questionText: "What describes your current employment status?",
        options: ["Student", "Farmer", "Business Owner / Self-employed", "Unemployed / Worker"],
        nextId: (_) => "cat_q2",
      ),
      'cat_q2': _QuestionNode(
        questionText: "Are you seeking financial credit or direct subsidy grants?",
        options: ["Business / Study Loans", "Subsidies & welfare grants", "Free skill training / services"],
        nextId: (_) => "cat_q3",
      ),
      'cat_q3': _QuestionNode(
        questionText: "What is your gender?",
        options: ["Female", "Male", "Other"],
        nextId: (_) => "cat_q4",
      ),
      'cat_q4': _QuestionNode(
        questionText: "What is your social caste category?",
        options: ["General", "OBC", "SC / ST", "EWS / Minority"],
        nextId: (_) => "cat_q5",
      ),
      'cat_q5': _QuestionNode(
        questionText: "What is your annual family income?",
        options: ["Under ₹2.5 Lakhs", "₹2.5 Lakhs - ₹8 Lakhs", "Over ₹8 Lakhs"],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, _QuestionNode> _getStateFlow(String stateName) {
    return {
      'state_q1': _QuestionNode(
        questionText: "Are you a permanent resident/domicile of $stateName?",
        options: ["Yes, I hold a domicile certificate", "No, I am a temporary resident"],
        nextId: (_) => "state_q2",
      ),
      'state_q2': _QuestionNode(
        questionText: "What is your category in the $stateName state reservation list?",
        options: ["BC / SEBC / OBC", "SC / ST", "EWS / Minority", "General / Open"],
        nextId: (_) => "state_q3",
      ),
      'state_q3': _QuestionNode(
        questionText: "What is your primary livelihood sector in $stateName?",
        options: ["Agriculture / Farmer", "MSME / Startup owner", "Weaving / Traditional Crafts", "Student / Higher studies"],
        nextId: (_) => "state_q4",
      ),
      'state_q4': _QuestionNode(
        questionText: "What type of state assistance are you targeting?",
        options: ["Monthly cash allowances", "Education fee waivers", "Business subsidies", "Agricultural input support"],
        nextId: (_) => "state_q5",
      ),
      'state_q5': _QuestionNode(
        questionText: "What is your total family annual income?",
        options: ["Under ₹1.5 Lakhs", "₹1.5 Lakhs - ₹5 Lakhs", "Over ₹5 Lakhs"],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, _QuestionNode> _getMinistryFlow(String ministryName) {
    return {
      'min_q1': _QuestionNode(
        questionText: "What is your primary objective within this ministry's portal?",
        options: ["Applying for business subsidy / credit", "Seeking educational scholarships", "Seeking farmer agricultural aid", "Seeking rural infrastructure / SHG help"],
        nextId: (_) => "min_q2",
      ),
      'min_q2': _QuestionNode(
        questionText: "What is the applicant's current age?",
        options: ["18 - 35 Years", "36 - 59 Years", "60 Years and above"],
        nextId: (_) => "min_q3",
      ),
      'min_q3': _QuestionNode(
        questionText: "Do you have any registered ID linked to this ministry?",
        options: ["Yes, Udyam / PM-KISAN / Scholar ID", "No, not registered yet"],
        nextId: (_) => "min_q4",
      ),
      'min_q4': _QuestionNode(
        questionText: "What is your social category?",
        options: ["General", "OBC", "SC / ST", "Minority / PwD"],
        nextId: (_) => "min_q5",
      ),
      'min_q5': _QuestionNode(
        questionText: "What is your annual household income?",
        options: ["Under ₹2.5 Lakhs", "₹2.5 Lakhs - ₹8 Lakhs", "Over ₹8 Lakhs"],
        nextId: (_) => null,
      ),
    };
  }
}

class _QuestionNode {
  final String questionText;
  final List<String> options;
  final String? Function(String selectedOption) nextId;

  const _QuestionNode({
    required this.questionText,
    required this.options,
    required this.nextId,
  });
}

String _getStateMapAsset(String stateName) {
  switch (stateName.toLowerCase().trim()) {
    case 'tamil nadu':
      return 'assets/images/States and UTs/States/Tamil nadu.png';
    case 'maharashtra':
      return 'assets/images/States and UTs/States/maharashtra.png';
    case 'uttar pradesh':
      return 'assets/images/States and UTs/States/uttar_pradesh.png';
    case 'karnataka':
      return 'assets/images/States and UTs/States/karnataka.png';
    case 'gujarat':
      return 'assets/images/States and UTs/States/gujarat.png';
    case 'arunachal pradesh':
      return 'assets/images/States and UTs/States/Anrunachal pradhesh.png';
    case 'assam':
      return 'assets/images/States and UTs/States/Assam.png';
    case 'bihar':
      return 'assets/images/States and UTs/States/Bihar.png';
    case 'chhattisgarh':
      return 'assets/images/States and UTs/States/Chhatishgar.png';
    case 'kerala':
      return 'assets/images/States and UTs/States/Kerala.png';
    case 'andhra pradesh':
      return 'assets/images/States and UTs/States/andhra pradesh.png';
    case 'goa':
      return 'assets/images/States and UTs/States/goa.png';
    case 'haryana':
      return 'assets/images/States and UTs/States/haryana.png';
    case 'himachal pradesh':
      return 'assets/images/States and UTs/States/himachal pradesh.png';
    case 'jharkhand':
      return 'assets/images/States and UTs/States/jharkhand.png';
    case 'madhya pradesh':
      return 'assets/images/States and UTs/States/madhya pradesh.png';
    case 'manipur':
      return 'assets/images/States and UTs/States/manipur.png';
    case 'meghalaya':
      return 'assets/images/States and UTs/States/meghalaya.png';
    case 'mizoram':
      return 'assets/images/States and UTs/States/mizoram.png';
    case 'nagaland':
      return 'assets/images/States and UTs/States/nagaland.png';
    case 'odisha':
      return 'assets/images/States and UTs/States/odisha.png';
    case 'punjab':
      return 'assets/images/States and UTs/States/punjab.png';
    case 'rajasthan':
      return 'assets/images/States and UTs/States/rajasthan.png';
    case 'sikkim':
      return 'assets/images/States and UTs/States/sikkim.png';
    case 'telangana':
      return 'assets/images/States and UTs/States/telangana.png';
    case 'tripura':
      return 'assets/images/States and UTs/States/tripura.png';
    case 'uttarakhand':
    case 'uttarkhand':
      return 'assets/images/States and UTs/States/uttarkhand.png';
    case 'west bengal':
      return 'assets/images/States and UTs/States/west bengal.png';
    default:
      return 'assets/images/States and UTs/States/Tamil nadu.png';
  }
}

class StateMapPainter extends CustomPainter {
  final String stateName;
  StateMapPainter(this.stateName);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (stateName == 'Tamil Nadu') {
      path.moveTo(w * 0.2, h * 0.1);
      path.quadraticBezierTo(w * 0.6, h * 0.05, w * 0.85, h * 0.15);
      path.lineTo(w * 0.8, h * 0.55);
      path.quadraticBezierTo(w * 0.65, h * 0.85, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.35, h * 0.85, w * 0.25, h * 0.55);
      path.close();
    } else if (stateName == 'Maharashtra') {
      path.moveTo(w * 0.1, h * 0.4);
      path.lineTo(w * 0.3, h * 0.15);
      path.lineTo(w * 0.75, h * 0.2);
      path.lineTo(w * 0.9, h * 0.38);
      path.lineTo(w * 0.82, h * 0.78);
      path.lineTo(w * 0.48, h * 0.82);
      path.lineTo(w * 0.2, h * 0.65);
      path.close();
    } else if (stateName == 'Uttar Pradesh') {
      path.moveTo(w * 0.08, h * 0.35);
      path.lineTo(w * 0.35, h * 0.2);
      path.lineTo(w * 0.8, h * 0.25);
      path.lineTo(w * 0.92, h * 0.5);
      path.lineTo(w * 0.72, h * 0.78);
      path.lineTo(w * 0.52, h * 0.68);
      path.lineTo(w * 0.32, h * 0.78);
      path.lineTo(w * 0.18, h * 0.52);
      path.close();
    } else if (stateName == 'Karnataka') {
      path.moveTo(w * 0.35, h * 0.08);
      path.quadraticBezierTo(w * 0.75, h * 0.22, w * 0.6, h * 0.52);
      path.quadraticBezierTo(w * 0.8, h * 0.72, w * 0.65, h * 0.92);
      path.lineTo(w * 0.4, h * 0.88);
      path.quadraticBezierTo(w * 0.2, h * 0.58, w * 0.35, h * 0.32);
      path.close();
    } else if (stateName == 'Gujarat') {
      path.moveTo(w * 0.25, h * 0.22);
      path.lineTo(w * 0.52, h * 0.12);
      path.lineTo(w * 0.78, h * 0.22);
      path.lineTo(w * 0.82, h * 0.52);
      path.lineTo(w * 0.58, h * 0.82);
      path.lineTo(w * 0.42, h * 0.58);
      path.lineTo(w * 0.12, h * 0.48);
      path.lineTo(w * 0.22, h * 0.34);
      path.close();
    } else {
      path.moveTo(w * 0.5, h * 0.1);
      path.quadraticBezierTo(w * 0.8, h * 0.1, w * 0.8, h * 0.45);
      path.quadraticBezierTo(w * 0.8, h * 0.75, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.2, h * 0.75, w * 0.2, h * 0.45);
      path.quadraticBezierTo(w * 0.2, h * 0.1, w * 0.5, h * 0.1);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
