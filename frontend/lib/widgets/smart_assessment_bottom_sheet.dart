import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../models/user_profile.dart';
import '../services/centralized_translator.dart';
import '../utils/responsive.dart';

/// Pre-localized questionnaire node for UI rendering.
class LocalizedQuestionNode {
  final String id;
  final String questionText;
  final String? subtitleText;
  final List<String> options;
  final QuestionNode rawNode;

  const LocalizedQuestionNode({
    required this.id,
    required this.questionText,
    this.subtitleText,
    required this.options,
    required this.rawNode,
  });

  String? nextId(String selectedLocalizedOption) {
    final index = options.indexOf(selectedLocalizedOption);
    final rawOption = (index >= 0 && index < rawNode.options.length)
        ? rawNode.options[index]
        : selectedLocalizedOption;
    return rawNode.nextId?.call(rawOption);
  }
}

/// Questionnaire node model supporting 3-tier localization:
/// Priority 1: Direct Tamil fields (questionTextTa, optionsTa, subtitleTextTa)
/// Priority 2: CentralizedTranslator fallback
/// Priority 3: English default
class QuestionNode {
  final String id;
  final String questionText;
  final String? questionTextTa;
  final String? subtitleText;
  final String? subtitleTextTa;
  final List<String> options;
  final List<String>? optionsTa;
  final String? Function(String selectedOption)? nextId;

  const QuestionNode({
    required this.id,
    required this.questionText,
    this.questionTextTa,
    this.subtitleText,
    this.subtitleTextTa,
    required this.options,
    this.optionsTa,
    this.nextId,
  });

  LocalizedQuestionNode toLocalized(String language) {
    final isTamil = language == 'ta';

    final String qText = isTamil
        ? ((questionTextTa != null && questionTextTa!.trim().isNotEmpty)
              ? questionTextTa!
              : CentralizedTranslator.instance.translate(questionText))
        : questionText;

    String? subText;
    if (subtitleText != null) {
      subText = isTamil
          ? ((subtitleTextTa != null && subtitleTextTa!.trim().isNotEmpty)
                ? subtitleTextTa!
                : CentralizedTranslator.instance.translate(subtitleText!))
          : subtitleText;
    }

    final List<String> locOptions = [];
    for (int i = 0; i < options.length; i++) {
      final rawOpt = options[i];
      if (isTamil) {
        if (optionsTa != null &&
            i < optionsTa!.length &&
            optionsTa![i].trim().isNotEmpty) {
          locOptions.add(optionsTa![i]);
        } else {
          locOptions.add(CentralizedTranslator.instance.translate(rawOpt));
        }
      } else {
        locOptions.add(rawOpt);
      }
    }

    return LocalizedQuestionNode(
      id: id,
      questionText: qText,
      subtitleText: subText,
      options: List.unmodifiable(locOptions),
      rawNode: this,
    );
  }
}

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

  static void show(
    BuildContext context,
    String title,
    String type,
    VoidCallback onCompleted,
  ) {
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
  State<SmartAssessmentBottomSheet> createState() =>
      _SmartAssessmentBottomSheetState();
}

class _SmartAssessmentBottomSheetState
    extends State<SmartAssessmentBottomSheet> {
  late String _currentQuestionId;
  final Map<String, String> _answers = {};
  final List<String> _questionHistory = [];

  // Define Question Flows for different categories, states, and ministries
  late Map<String, QuestionNode> _questionFlow;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  void _initializeFlow() {
    final title = widget.cardTitle.toLowerCase().trim();

    if (widget.cardType == 'category') {
      if (title.contains('educat') ||
          title.contains('scholar') ||
          title.contains('student')) {
        _questionFlow = _getEducationFlow();
        _currentQuestionId = 'edu_q1';
      } else if (title.contains('women') ||
          title.contains('child') ||
          title.contains('matern')) {
        _questionFlow = _getWomenFlow();
        _currentQuestionId = 'women_q1';
      } else if (title.contains('agri') ||
          title.contains('farm') ||
          title.contains('crop')) {
        _questionFlow = _getAgricultureFlow();
        _currentQuestionId = 'agri_q1';
      } else if (title.contains('skill') ||
          title.contains('employ') ||
          title.contains('job')) {
        _questionFlow = _getSkillFlow();
        _currentQuestionId = 'skill_q1';
      } else if (title.contains('tech') ||
          title.contains('export') ||
          title.contains('trade')) {
        _questionFlow = _getTechExportFlow();
        _currentQuestionId = 'te_q1';
      } else if (title.contains('business') ||
          title.contains('msme') ||
          title.contains('start') ||
          title.contains('artisan') ||
          title.contains('loan') ||
          title.contains('credit')) {
        _questionFlow = _getBusinessFlow();
        _currentQuestionId = 'biz_q1';
      } else {
        _questionFlow = _getDefaultCategoryFlow();
        _currentQuestionId = 'cat_q1';
      }
    } else if (widget.cardType == 'state') {
      _questionFlow = _getStateFlow(widget.cardTitle);
      _currentQuestionId = 'state_q1';
    } else {
      _questionFlow = _getMinistryFlow(widget.cardTitle);
      _currentQuestionId = 'min_q1';
    }
  }

  Color _getThemeColor() {
    return const Color(0xFF2563EB); // Unified Royal Blue theme
  }

  void _onOptionSelected(
    String selectedLocalizedOption,
    LocalizedQuestionNode localizedNode,
  ) {
    setState(() {
      // Find raw option string for downstream answer logic
      final index = localizedNode.options.indexOf(selectedLocalizedOption);
      final rawOption =
          (index >= 0 && index < localizedNode.rawNode.options.length)
          ? localizedNode.rawNode.options[index]
          : selectedLocalizedOption;

      _answers[_currentQuestionId] = rawOption;
      _questionHistory.add(_currentQuestionId);

      final nextId = localizedNode.nextId(selectedLocalizedOption);

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

    String gender = profile.gender;
    String state = profile.state;
    String community = profile.community;
    double income = profile.annualIncome;
    String employment = profile.employmentStatus;
    bool existingBiz = profile.existingBusiness;
    String bizStage = profile.businessStage;

    _answers.forEach((qId, ans) {
      if (qId.contains('income') ||
          qId.contains('turnover') ||
          qId.endsWith('q5') ||
          qId.contains('q4_income')) {
        if (ans.contains('Under ₹1') ||
            ans.contains('Under ₹1.2') ||
            ans.contains('Under ₹1.5') ||
            ans.contains('Under ₹1.8')) {
          income = 120000.0;
        } else if (ans.contains('₹1.2') ||
            ans.contains('₹1.5') ||
            ans.contains('Under ₹2') ||
            ans.contains('Under ₹2.5')) {
          income = 200000.0;
        } else if (ans.contains('₹2.5') ||
            ans.contains('₹1.8 - ₹3') ||
            ans.contains('₹2 - ₹8') ||
            ans.contains('₹1.5 - ₹5')) {
          income = 450000.0;
        } else if (ans.contains('Over ₹8') ||
            ans.contains('Over ₹6') ||
            ans.contains('Over ₹10') ||
            ans.contains('Over ₹5')) {
          income = 900000.0;
        }
      }

      if (qId.contains('caste') ||
          qId.contains('category') ||
          qId.contains('reservation')) {
        if (ans.contains('SC')) {
          community = 'SC';
        } else if (ans.contains('ST')) {
          community = 'ST';
        } else if (ans.contains('OBC') ||
            ans.contains('BC') ||
            ans.contains('SEBC') ||
            ans.contains('MBC')) {
          community = 'OBC';
        } else if (ans.contains('EWS')) {
          community = 'EWS';
        } else {
          community = 'General';
        }
      }

      if (qId.contains('gender')) {
        if (ans.contains('Female') ||
            ans.contains('woman') ||
            ans.contains('Women')) {
          gender = 'Female';
        } else {
          gender = 'Male';
        }
      }

      if (qId.contains('livelihood') ||
          qId.contains('profession') ||
          qId.contains('occupation') ||
          qId.contains('employment')) {
        if (ans.contains('Farmer') || ans.contains('Agri')) {
          employment = 'Farmer';
        } else if (ans.contains('Student')) {
          employment = 'Student';
        } else if (ans.contains('Business') ||
            ans.contains('Startup') ||
            ans.contains('entrepreneur')) {
          employment = 'Business Owner';
        } else if (ans.contains('Self-employed') || ans.contains('artisan')) {
          employment = 'Self-employed';
        } else if (ans.contains('Unemployed') || ans.contains('Worker')) {
          employment = 'Unemployed';
        }
      }

      if (qId.contains('business') || qId.contains('startup')) {
        if (ans.contains('Yes')) existingBiz = true;
        if (ans.contains('Idea')) bizStage = 'Idea';
        if (ans.contains('Prototype')) bizStage = 'Prototype';
        if (ans.contains('Operational') || ans.contains('Registered')) {
          bizStage = 'Operational';
        }
      }
    });

    provider.clearFilters();
    if (widget.cardType == 'state') {
      state = widget.cardTitle;
      provider.updateFilter('state', state);
    } else if (widget.cardType == 'category') {
      provider.updateFilter('category', widget.cardTitle);
    } else if (widget.cardType == 'ministry') {
      provider.updateFilter('ministry', widget.cardTitle);
    }

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

    provider.updateProfile(updatedProfile);
    Navigator.pop(context);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final language = provider.selectedLanguage;
    final isTamil = language == 'ta';

    final rawNode = _questionFlow[_currentQuestionId];
    if (rawNode == null) return const SizedBox.shrink();

    final localizedNode = rawNode.toLocalized(language);
    final cardTitleLocalized = _getLocalizedCardTitle(
      widget.cardTitle,
      language,
    );

    final themeColor = _getThemeColor();
    final totalSteps = 5;
    final currentStep = _questionHistory.length + 1;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    final stepLabel = isTamil
        ? "படி $currentStep / $totalSteps"
        : "Step $currentStep of $totalSteps";
    final backLabel = isTamil ? "பின்செல்" : "Back";
    final skipLabel = isTamil ? "முடிவுகளுக்குச் செல்" : "Skip to Results";

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
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: widget.cardType == 'state'
                          ? EdgeInsets.zero
                          : const EdgeInsets.all(6),
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
                    Flexible(
                      child: Text(
                        cardTitleLocalized,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          fontSize: isTamil ? 13.0 : 14.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
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
                stepLabel,
                style: GoogleFonts.inter(
                  fontSize: isTamil ? 9.5 : 10.5,
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
                  localizedNode.questionText,
                  style: GoogleFonts.poppins(
                    fontSize: isTamil ? 13.8 : 15.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: isTamil ? 1.35 : 1.25,
                  ),
                ),
                if (localizedNode.subtitleText != null &&
                    localizedNode.subtitleText!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    localizedNode.subtitleText!,
                    style: GoogleFonts.inter(
                      fontSize: isTamil ? 10.5 : 11.5,
                      color: const Color(0xFF64748B),
                      height: isTamil ? 1.35 : 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Options list
                ...List.generate(localizedNode.options.length, (index) {
                  final optionLocalized = localizedNode.options[index];
                  final rawOption = rawNode.options[index];
                  final isSelected = _answers[_currentQuestionId] == rawOption;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          _onOptionSelected(optionLocalized, localizedNode),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 16,
                        ),
                        alignment: Alignment.centerLeft,
                        backgroundColor: isSelected
                            ? themeColor.withValues(alpha: 0.06)
                            : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? themeColor
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        optionLocalized,
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.inter(
                          fontSize: isTamil ? 11.5 : 12.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? themeColor
                              : const Color(0xFF334155),
                          height: isTamil ? 1.35 : 1.25,
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
                Flexible(
                  child: TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: FitOneLine(
                      child: Text(
                        backLabel,
                        style: GoogleFonts.inter(
                          fontSize: isTamil ? 11.0 : 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Flexible(
                child: TextButton(
                  onPressed: _submitAnswers,
                  style: TextButton.styleFrom(foregroundColor: themeColor),
                  child: FitOneLine(
                    child: Text(
                      skipLabel,
                      style: GoogleFonts.inter(
                        fontSize: isTamil ? 11.0 : 12.0,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocalizedCardTitle(String rawTitle, String language) {
    if (language != 'ta') return rawTitle;
    return CentralizedTranslator.instance.translateTag(rawTitle);
  }

  // --- QUESTION FLOW GENERATORS ---

  Map<String, QuestionNode> _getEducationFlow() {
    return {
      'edu_q1': QuestionNode(
        id: 'edu_q1',
        questionText: "What is your current level of education?",
        questionTextTa: "உங்கள் தற்போதைய கல்வித் தகுதி என்ன?",
        options: [
          "Schooling (Up to 12th)",
          "Undergraduate",
          "Postgraduate",
          "Ph.D. & Research",
        ],
        optionsTa: [
          "பள்ளி கல்வி (12 ஆம் வகுப்பு வரை)",
          "இளங்கலை (UG)",
          "முதுகலை (PG)",
          "முனைவர் பட்டம் & ஆராய்ச்சி",
        ],
        nextId: (ans) => ans.contains("Schooling")
            ? "edu_q2_school"
            : ans.contains("Research")
            ? "edu_q2_research"
            : "edu_q2_college",
      ),
      'edu_q2_school': QuestionNode(
        id: 'edu_q2_school',
        questionText: "What class/grade are you currently enrolled in?",
        questionTextTa: "நீங்கள் தற்போது எந்த வகுப்பில் படிக்கிறீர்கள்?",
        options: [
          "Class 1 - 8 (Primary)",
          "Class 9 - 10 (Secondary)",
          "Class 11 - 12 (Higher Secondary)",
        ],
        optionsTa: [
          "வகுப்பு 1 - 8 (தொடக்கப்பள்ளி)",
          "வகுப்பு 9 - 10 (உயர்நிலைப்பள்ளி)",
          "வகுப்பு 11 - 12 (மேல்நிலைப்பள்ளி)",
        ],
        nextId: (_) => "edu_q3_school",
      ),
      'edu_q2_college': QuestionNode(
        id: 'edu_q2_college',
        questionText: "What is your primary stream of study?",
        questionTextTa: "உங்கள் முதன்மை கல்விப் பிரிவு என்ன?",
        options: [
          "STEM (Science/Engineering/IT)",
          "Arts, Commerce & Humanities",
          "Medical & Nursing",
          "Agricultural Studies",
        ],
        optionsTa: [
          "STEM (அறிவியல்/பொறியியல்/IT)",
          "கலை, வணிகவியல் & மானுடவியல்",
          "மருத்துவம் & செவிலியர்",
          "வேளாண் படிப்புகள்",
        ],
        nextId: (_) => "edu_q3_college",
      ),
      'edu_q2_research': QuestionNode(
        id: 'edu_q2_research',
        questionText: "What is your research specialization domain?",
        questionTextTa: "உங்கள் ஆராய்ச்சி துறை என்ன?",
        options: [
          "STEM Research & Patents",
          "Humanities & Social Sciences",
          "Agricultural/Biological Sciences",
        ],
        optionsTa: [
          "STEM ஆராய்ச்சி & காப்புரிமை",
          "மானுடவியல் & சமூக அறிவியல்",
          "வேளாண் / உயிரியல் அறிவியல்",
        ],
        nextId: (_) => "edu_q3_research",
      ),
      'edu_q3_school': QuestionNode(
        id: 'edu_q3_school',
        questionText: "What type of aid is most important right now?",
        questionTextTa: "தற்போது உங்களுக்கு எந்த வகையான உதவி தேவைப்படுகிறது?",
        options: [
          "Pre-matric Scholarship",
          "Free textbooks & uniforms",
          "Hostel accommodation subsidy",
        ],
        optionsTa: [
          "பள்ளிப்படிப்பு உதவித்தொகை (Pre-matric)",
          "இலவச பாடப்புத்தகங்கள் & சீருடைகள்",
          "விடுதி தங்குமிட மானியம்",
        ],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q3_college': QuestionNode(
        id: 'edu_q3_college',
        questionText:
            "Are you interested in a low-interest student education loan?",
        questionTextTa: "குறைந்த வட்டி கல்விக்கடனில் ஆர்வமாக உள்ளீர்களா?",
        options: [
          "Yes, need education loan",
          "No, seeking tuition scholarships only",
        ],
        optionsTa: [
          "ஆம், கல்விக்கடன் தேவை",
          "இல்லை, கல்வி உதவித்தொகை மட்டும் தேவை",
        ],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q3_research': QuestionNode(
        id: 'edu_q3_research',
        questionText:
            "Are you seeking a research fellowship or international study grant?",
        questionTextTa:
            "ஆராய்ச்சி உதவித்தொகை அல்லது வெளிநாட்டு கல்வி நிதி எதிர்பார்க்கிறீர்களா?",
        options: [
          "National Fellowship grant",
          "International study allowance",
          "Merit publication awards",
        ],
        optionsTa: [
          "தேசிய ஆராய்ச்சி நிதி (Fellowship)",
          "வெளிநாட்டு கல்வி உதவித்தொகை",
          "ஆராய்ச்சி கட்டுரை விருதுகள்",
        ],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q4_caste': QuestionNode(
        id: 'edu_q4_caste',
        questionText: "What is your caste/social reservation category?",
        questionTextTa: "உங்கள் சமூகப் பிரிவு என்ன?",
        options: ["General", "OBC", "SC / ST", "EWS / Minority"],
        optionsTa: [
          "பொதுப்பிரிவு (General)",
          "பிற்படுத்தப்பட்டோர் (OBC/BC)",
          "பட்டியல் வகுப்பினர் (SC / ST)",
          "பொருளாதாரத்தில் பின்தங்கியோர் / சிறுபான்மையினர்",
        ],
        nextId: (_) => "edu_q5_income",
      ),
      'edu_q5_income': QuestionNode(
        id: 'edu_q5_income',
        questionText: "What is your family's annual household income?",
        questionTextTa: "உங்கள் குடும்பத்தின் ஆண்டு வருமானம் என்ன?",
        options: ["Under ₹2.5 Lakhs", "₹2.5 Lakhs - ₹8 Lakhs", "Over ₹8 Lakhs"],
        optionsTa: [
          "₹2.5 இலட்சத்திற்குக் கீழ்",
          "₹2.5 இலட்சம் - ₹8 இலட்சம்",
          "₹8 இலட்சத்திற்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getWomenFlow() {
    return {
      'women_q1': QuestionNode(
        id: 'women_q1',
        questionText: "Who is the primary beneficiary of the scheme?",
        questionTextTa: "திட்டத்தின் முதன்மை பயனாளி யார்?",
        options: [
          "Pregnant or Lactating Mother",
          "Girl Child (Parent applying)",
          "Woman Entrepreneur",
          "Single Woman / Widow in distress",
        ],
        optionsTa: [
          "கர்ப்பிணி அல்லது பாலூட்டும் தாய்",
          "பெண் குழந்தை (பெற்றோர் விண்ணப்பிக்கின்றனர்)",
          "பெண் தொழில்முனைவோர்",
          "தனித்து வாழும் பெண் / விதவை தாய்",
        ],
        nextId: (ans) => ans.contains("Mother")
            ? "women_q2_maternal"
            : ans.contains("Child")
            ? "women_q2_girl"
            : ans.contains("Entrepreneur")
            ? "women_q2_biz"
            : "women_q2_welfare",
      ),
      'women_q2_maternal': QuestionNode(
        id: 'women_q2_maternal',
        questionText: "Is this your first or second pregnancy?",
        questionTextTa: "இது உங்கள் முதலாவது அல்லது இரண்டாவது கர்ப்பமா?",
        options: ["First pregnancy", "Second pregnancy", "More than two"],
        optionsTa: [
          "முதல் கர்ப்பம்",
          "இரண்டாவது கர்ப்பம்",
          "இரண்டிற்கும் மேற்பட்டவை",
        ],
        nextId: (_) => "women_q3_matern_reg",
      ),
      'women_q2_girl': QuestionNode(
        id: 'women_q2_girl',
        questionText: "What is the age of the girl child?",
        questionTextTa: "பெண் குழந்தையின் வயது என்ன?",
        options: [
          "Newborn (0 - 1 Year)",
          "Child (2 - 10 Years)",
          "Adolescent (11 - 18 Years)",
        ],
        optionsTa: [
          "பிறந்த குழந்தை (0 - 1 வயது)",
          "குழந்தை (2 - 10 வயது)",
          "இளம் பெண் (11 - 18 வயது)",
        ],
        nextId: (ans) => ans.contains("Adolescent")
            ? "women_q3_girl_edu"
            : "women_q3_girl_save",
      ),
      'women_q2_biz': QuestionNode(
        id: 'women_q2_biz',
        questionText:
            "Do women hold at least a 51% ownership stake in the enterprise?",
        questionTextTa:
            "நிறுவனத்தில் பெண்களுக்கு குறைந்தது 51% பங்கீடு உள்ளதா?",
        options: ["Yes, fully owned by women", "No, minor/shared stake"],
        optionsTa: [
          "ஆம், முழுவதும் பெண்கள் உரிமையிலானது",
          "இல்லை, குறைந்த பங்கீடு",
        ],
        nextId: (_) => "women_q3_biz_credit",
      ),
      'women_q2_welfare': QuestionNode(
        id: 'women_q2_welfare',
        questionText: "Do you possess a BPL (Below Poverty Line) Ration Card?",
        questionTextTa:
            "உங்களிடம் வறுமைக் கோட்டிற்கு கீழ் (BPL) குடும்ப அட்டை உள்ளதா?",
        options: ["Yes, BPL Cardholder", "No, APL / General"],
        optionsTa: ["ஆம், BPL அட்டைதாரர்", "இல்லை, APL / பொதுப்பிரிவு"],
        nextId: (_) => "women_q3_welfare_pension",
      ),
      'women_q3_matern_reg': QuestionNode(
        id: 'women_q3_matern_reg',
        questionText:
            "Are you registered at your local Anganwadi/Health center?",
        questionTextTa:
            "உள்ளூர் அங்கன்வாடி / சுகாதார மையத்தில் பதிவு செய்துள்ளீர்களா?",
        options: ["Yes, registered", "No, not registered yet"],
        optionsTa: [
          "ஆம், பதிவு செய்யப்பட்டுள்ளது",
          "இல்லை, இன்னும் பதிவு செய்யவில்லை",
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_girl_save': QuestionNode(
        id: 'women_q3_girl_save',
        questionText:
            "Would you like to open a long-term savings account (Sukanya Samriddhi)?",
        questionTextTa:
            "செல்வமகள் சேமிப்பு கணக்கு (Sukanya Samriddhi) தொடங்க விரும்புகிறீர்களா?",
        options: [
          "Yes, open savings account",
          "No, seeking educational scholarships",
        ],
        optionsTa: [
          "ஆம், சேமிப்பு கணக்கு தொடங்க வேண்டும்",
          "இல்லை, கல்வி உதவித்தொகை தேவை",
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_girl_edu': QuestionNode(
        id: 'women_q3_girl_edu',
        questionText: "Is the girl child currently enrolled in school/college?",
        questionTextTa: "பெண் குழந்தை தற்போது பள்ளி / கல்லூரியில் படிக்கிறாரா?",
        options: [
          "Yes, attending school/college",
          "No, discontinued education",
        ],
        optionsTa: [
          "ஆம், பள்ளி / கல்லூரியில் படிக்கிறார்",
          "இல்லை, படிப்பை நிறுத்திவிட்டார்",
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_biz_credit': QuestionNode(
        id: 'women_q3_biz_credit',
        questionText:
            "What capital support size are you seeking for your business?",
        questionTextTa: "உங்கள் தொழிலுக்கு எவ்வளவு மூலதன நிதி தேவை?",
        options: [
          "Micro-credit (Under ₹1 Lakh)",
          "SME Loan (₹1 Lakh - ₹10 Lakhs)",
          "Stand-Up India loan (Over ₹10 Lakhs)",
        ],
        optionsTa: [
          "குறுங்கடன் (₹1 இலட்சத்திற்கு கீழ்)",
          "MSME கடன் (₹1 இலட்சம் - ₹10 இலட்சம்)",
          "ஸ்டாண்ட்-அப் இந்தியா கடன் (₹10 இலட்சத்திற்கு மேல்)",
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_welfare_pension': QuestionNode(
        id: 'women_q3_welfare_pension',
        questionText: "Are you currently receiving any monthly social pension?",
        questionTextTa: "தற்போது மாதந்தோறும் அரசு ஓய்வூதியம் பெறுகிறீர்களா?",
        options: ["Yes, receiving widow pension", "No pension received"],
        optionsTa: [
          "ஆம், விதவை ஓய்வூதியம் பெறுகிறேன்",
          "இல்லை, ஓய்வூதியம் பெறவில்லை",
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q4_caste': QuestionNode(
        id: 'women_q4_caste',
        questionText: "What is your caste/social category?",
        questionTextTa: "உங்கள் சமூகப் பிரிவு என்ன?",
        options: ["General", "OBC", "SC / ST", "Minority / EWS"],
        optionsTa: [
          "பொதுப்பிரிவு (General)",
          "பிற்படுத்தப்பட்டோர் (OBC/BC)",
          "பட்டியல் வகுப்பினர் (SC / ST)",
          "சிறுபான்மையினர் / EWS",
        ],
        nextId: (_) => "women_q5_income",
      ),
      'women_q5_income': QuestionNode(
        id: 'women_q5_income',
        questionText: "What is your family's annual income?",
        questionTextTa: "உங்கள் குடும்பத்தின் ஆண்டு வருமானம் என்ன?",
        options: ["Under ₹1.5 Lakhs", "₹1.5 Lakhs - ₹5 Lakhs", "Over ₹5 Lakhs"],
        optionsTa: [
          "₹1.5 இலட்சத்திற்குக் கீழ்",
          "₹1.5 இலட்சம் - ₹5 இலட்சம்",
          "₹5 இலட்சத்திற்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getBusinessFlow() {
    return {
      'biz_q1': QuestionNode(
        id: 'biz_q1',
        questionText: "Is your business legally registered?",
        questionTextTa: "உங்கள் தொழில் முறைப்படி பதிவு செய்யப்பட்டுள்ளதா?",
        options: [
          "Yes, under MSME Udyam",
          "Yes, as a DPIIT Startup",
          "No, operating as individual trader/artisan",
          "No, it is in idea stage",
        ],
        optionsTa: [
          "ஆம், MSME உத்யம் மூலம்",
          "ஆம், DPIIT ஸ்டார்ட்அப்பாக",
          "இல்லை, தனிநபர் வியாபாரி / கைவினைஞராக",
          "இல்லை, யோசனை நிலையில் உள்ளது",
        ],
        nextId: (ans) => ans.contains("MSME")
            ? "biz_q2_msme"
            : ans.contains("Startup")
            ? "biz_q2_startup"
            : ans.contains("trader")
            ? "biz_q2_artisan"
            : "biz_q2_idea",
      ),
      'biz_q2_msme': QuestionNode(
        id: 'biz_q2_msme',
        questionText: "What is the total investment in machinery/equipment?",
        questionTextTa: "இயந்திரங்கள் / உபகரணங்களில் மொத்த முதலீடு எவ்வளவு?",
        options: [
          "Micro (Under ₹1 Crore)",
          "Small (₹1 Crore - ₹10 Crore)",
          "Medium (Over ₹10 Crore)",
        ],
        optionsTa: [
          "குறுந்தொழில் (₹1 கோடிக்கு கீழ்)",
          "சிறு தொழில் (₹1 கோடி - ₹10 கோடி)",
          "நடுத்தர தொழில் (₹10 கோடிக்கு மேல்)",
        ],
        nextId: (_) => "biz_q3_msme_need",
      ),
      'biz_q2_startup': QuestionNode(
        id: 'biz_q2_startup',
        questionText: "What stage is your startup currently in?",
        questionTextTa: "உங்கள் ஸ்டார்ட்அப் தற்போது எந்த நிலையில் உள்ளது?",
        options: [
          "Prototype / MVP development",
          "Early Revenue / Validation",
          "Scaling & expansion",
        ],
        optionsTa: [
          "மாதிரி வடிவம் / MVP உருவாக்கம்",
          "ஆரம்ப வருவாய் / சந்தை சரிபார்ப்பு",
          "தொழில் விரிவாக்கம்",
        ],
        nextId: (_) => "biz_q3_startup_need",
      ),
      'biz_q2_artisan': QuestionNode(
        id: 'biz_q2_artisan',
        questionText: "Do you hold a valid PM Vishwakarma Card or Artisan ID?",
        questionTextTa:
            "உங்களிடம் பிஎம் விஸ்வகர்மா அட்டை / கைவினைஞர் சான்றிதழ் உள்ளதா?",
        options: ["Yes, active card", "No, not registered"],
        optionsTa: [
          "ஆம், செயலில் உள்ள அட்டை உள்ளது",
          "இல்லை, பதிவு செய்யவில்லை",
        ],
        nextId: (_) => "biz_q3_artisan_need",
      ),
      'biz_q2_idea': QuestionNode(
        id: 'biz_q2_idea',
        questionText: "Do you have a business project report prepared?",
        questionTextTa: "தொழில் திட்ட அறிக்கை தயாரித்துள்ளீர்களா?",
        options: ["Yes, report is ready", "No, need project guidance"],
        optionsTa: [
          "ஆம், திட்ட அறிக்கை தயார்",
          "இல்லை, திட்ட வழிகாட்டுதல் தேவை",
        ],
        nextId: (_) => "biz_q3_msme_need",
      ),
      'biz_q3_msme_need': QuestionNode(
        id: 'biz_q3_msme_need',
        questionText: "What primary credit/loan support do you need?",
        questionTextTa: "உங்களுக்கு முதன்மையாக எந்த கடன் உதவி தேவை?",
        options: [
          "Collateral-free Mudra Loan",
          "Working capital guarantee (CGTMSE)",
          "Equipment purchase capital subsidy",
        ],
        optionsTa: [
          "பிணையமில்லா முத்ரா கடன்",
          "நடைமுறை மூலதன உத்தரவாதம் (CGTMSE)",
          "இயந்திரங்கள் வாங்குவதற்கான மூலதன மானியம்",
        ],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q3_startup_need': QuestionNode(
        id: 'biz_q3_startup_need',
        questionText: "Are you seeking equity funding or tax exemptions?",
        questionTextTa:
            "பங்கு மூலதன நிதி அல்லது வரி விலக்கு எதிர்பார்க்கிறீர்களா?",
        options: [
          "Government Seed Funding",
          "Section 80-IAC Tax Exemption",
          "Incubator mentoring grant",
        ],
        optionsTa: [
          "அரசு தொடக்க நிதி (Seed Funding)",
          "பிரிவு 80-IAC வரி விலக்கு",
          "இன்குபேட்டர் வழிகாட்டுதல் மானியம்",
        ],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q3_artisan_need': QuestionNode(
        id: 'biz_q3_artisan_need',
        questionText: "What support does your craft require?",
        questionTextTa: "உங்கள் கைவினைத் தொழிலுக்கு என்ன உதவி தேவை?",
        options: [
          "Free toolkit upgrade voucher",
          "Exhibition & stall subsidies",
          "Individual craft micro-loan",
        ],
        optionsTa: [
          "இலவச கருவித்தொகுப்பு (Toolkit) வவுச்சர்",
          "கண்காட்சி மற்றும் அரங்கு மானியம்",
          "கைவினைஞர்களுக்கான தனிநபர் குறுங்கடன்",
        ],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q4_demographics': QuestionNode(
        id: 'biz_q4_demographics',
        questionText: "Is the primary owner a Woman or SC/ST entrepreneur?",
        questionTextTa: "முதன்மையாளர் பெண் அல்லது SC/ST தொழில்முனைவோரா?",
        options: [
          "Yes, woman entrepreneur",
          "Yes, SC/ST entrepreneur",
          "Yes, both SC/ST & Woman",
          "General category Male",
        ],
        optionsTa: [
          "ஆம், பெண் தொழில்முனைவோர்",
          "ஆம், SC/ST தொழில்முனைவோர்",
          "ஆம், SC/ST மற்றும் பெண்",
          "பொதுப்பிரிவு ஆண்",
        ],
        nextId: (_) => "biz_q5_turnover",
      ),
      'biz_q5_turnover': QuestionNode(
        id: 'biz_q5_turnover',
        questionText:
            "What is the annual turnover or estimated revenue of the business?",
        questionTextTa: "தொழிலின் ஆண்டு விற்றுமுதல் (Turnover) எவ்வளவு?",
        options: [
          "Under ₹10 Lakhs",
          "₹10 Lakhs - ₹50 Lakhs",
          "₹50 Lakhs - ₹2 Crores",
          "Over ₹2 Crores",
        ],
        optionsTa: [
          "₹10 இலட்சத்திற்குக் கீழ்",
          "₹10 இலட்சம் - ₹50 இலட்சம்",
          "₹50 இலட்சம் - ₹2 கோடி",
          "₹2 கோடிக்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getAgricultureFlow() {
    return {
      'agri_q1': QuestionNode(
        id: 'agri_q1',
        questionText: "What is your landholding size for farming?",
        questionTextTa: "உங்கள் விவசாய நிலத்தின் பரப்பளவு எவ்வளவு?",
        options: [
          "Small / Marginal (Under 2 Hectares)",
          "Medium (2 - 5 Hectares)",
          "Large / Commercial (Over 5 Hectares)",
          "Tenant / Landless Farmer",
        ],
        optionsTa: [
          "சிறு / குறு விவசாயி (2 ஹெக்டேருக்கு கீழ்)",
          "நடுத்தர விவசாயி (2 - 5 ஹெக்டேர்)",
          "பெரிய விவசாயி (5 ஹெக்டேருக்கு மேல்)",
          "குத்தகை / நிலமற்ற விவசாயி",
        ],
        nextId: (_) => "agri_q2",
      ),
      'agri_q2': QuestionNode(
        id: 'agri_q2',
        questionText: "What agricultural support do you need urgently?",
        questionTextTa: "உங்களுக்கு உடனடியாக தேவைப்படும் விவசாய உதவி என்ன?",
        options: [
          "PM-KISAN Cash Transfer",
          "Drip Irrigation / Equipment Subsidy",
          "Crop Insurance & Disaster Relief",
          "Kisan Credit Card (KCC) Loan",
        ],
        optionsTa: [
          "PM-KISAN நேரடி நிதி உதவி",
          "சொட்டு நீர் பாசனம் / உபகரண மானியம்",
          "பயிர் காப்பீடு & பேரிடர் நிவாரணம்",
          "கிசான் கிரெடிட் கார்டு (KCC) கடன்",
        ],
        nextId: (_) => "agri_q3_caste",
      ),
      'agri_q3_caste': QuestionNode(
        id: 'agri_q3_caste',
        questionText: "What is your social category?",
        questionTextTa: "உங்கள் சமூகப் பிரிவு என்ன?",
        options: ["General", "OBC", "SC / ST", "Small Farmer Special"],
        optionsTa: [
          "பொதுப்பிரிவு (General)",
          "பிற்படுத்தப்பட்டோர் (OBC/BC)",
          "பட்டியல் வகுப்பினர் (SC / ST)",
          "சிறப்பு விவசாயி பிரிவு",
        ],
        nextId: (_) => "agri_q4_income",
      ),
      'agri_q4_income': QuestionNode(
        id: 'agri_q4_income',
        questionText: "What is your total family annual income?",
        questionTextTa: "உங்கள் குடும்பத்தின் ஆண்டு வருமானம் என்ன?",
        options: ["Under ₹1.5 Lakhs", "₹1.5 Lakhs - ₹5 Lakhs", "Over ₹5 Lakhs"],
        optionsTa: [
          "₹1.5 இலட்சத்திற்குக் கீழ்",
          "₹1.5 இலட்சம் - ₹5 இலட்சம்",
          "₹5 இலட்சத்திற்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getSkillFlow() {
    return {
      'skill_q1': QuestionNode(
        id: 'skill_q1',
        questionText: "What is your current employment or skill level?",
        questionTextTa: "உங்கள் தற்போதைய தொழில் / திறன் நிலை என்ன?",
        options: [
          "Unemployed youth seeking job",
          "School/College dropout",
          "Traditional artisan / Worker",
          "Employed seeking skill upgrade",
        ],
        optionsTa: [
          "வேலைதேடும் இளைஞர்",
          "பள்ளி / கல்லூரி இடைநின்றவர்",
          "பாரம்பரிய தொழிலாளி / பணியாளர்",
          "திறன் மேம்பாடு விரும்பும் பணியாளர்",
        ],
        nextId: (_) => "skill_q2",
      ),
      'skill_q2': QuestionNode(
        id: 'skill_q2',
        questionText: "Which skill training area interests you?",
        questionTextTa: "எந்தத் துறையில் பயிற்சி பெற விரும்புகிறீர்கள்?",
        options: [
          "IT, Digital & Electronics",
          "Apparel, Textile & Handicrafts",
          "Automotive & Mechanical",
          "Healthcare & Hospitality",
        ],
        optionsTa: [
          "தகவல் தொழில்நுட்பம் & எலக்ட்ரானிக்ஸ்",
          "ஆடை வடிவமைப்பு & கைவினை",
          "வாகனம் & மெக்கானிக்கல்",
          "சுகாதாரம் & விருந்தோம்பல்",
        ],
        nextId: (_) => "skill_q3",
      ),
      'skill_q3': QuestionNode(
        id: 'skill_q3',
        questionText:
            "Are you looking for government-certified PMKVY training?",
        questionTextTa:
            "அரசு அங்கீகாரம் பெற்ற இலவசப் பயிற்சி பெற விரும்புகிறீர்களா?",
        options: [
          "Yes, need certified training",
          "No, seeking self-employment stipend",
        ],
        optionsTa: [
          "ஆம், சான்றிதழ் பயிற்சி தேவை",
          "இல்லை, சுயதொழில் உதவித்தொகை தேவை",
        ],
        nextId: (_) => "skill_q4_income",
      ),
      'skill_q4_income': QuestionNode(
        id: 'skill_q4_income',
        questionText: "What is your annual family income?",
        questionTextTa: "உங்கள் குடும்பத்தின் ஆண்டு வருமானம் என்ன?",
        options: ["Under ₹2.5 Lakhs", "₹2.5 Lakhs - ₹8 Lakhs", "Over ₹8 Lakhs"],
        optionsTa: [
          "₹2.5 இலட்சத்திற்குக் கீழ்",
          "₹2.5 இலட்சம் - ₹8 இலட்சம்",
          "₹8 இலட்சத்திற்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getTechExportFlow() {
    return {
      'te_q1': QuestionNode(
        id: 'te_q1',
        questionText: "What is your primary enterprise focus?",
        questionTextTa: "உங்கள் நிறுவனத்தின் முதன்மை கவனம் என்ன?",
        options: [
          "Technology / R&D Innovation",
          "Export & Trade Expansion",
          "Manufacturing Production Unit",
          "Digital Infrastructure",
        ],
        optionsTa: [
          "தொழில்நுட்பம் / R&D ஆராய்ச்சி",
          "ஏற்றுமதி & வர்த்தக விரிவாக்கம்",
          "உற்பத்தி ஆலை (Manufacturing)",
          "டிஜிட்டல் கட்டமைப்பு",
        ],
        nextId: (_) => "te_q2",
      ),
      'te_q2': QuestionNode(
        id: 'te_q2',
        questionText: "What specific government scheme support do you require?",
        questionTextTa: "உங்களுக்கு அரசிடமிருந்து என்ன உதவி தேவைப்படுகிறது?",
        options: [
          "Capital Investment Subsidy",
          "Patent & R&D Filing Reimbursement",
          "Market Access & International Fair Grant",
          "Software & Hardware Infrastructure Support",
        ],
        optionsTa: [
          "மூலதன முதலீட்டு மானியம்",
          "காப்புரிமை & R&D கட்டணத் திரும்பப்பெறுதல்",
          "சர்வதேச வர்த்தகக் கண்காட்சி மானியம்",
          "மென்பொருள் & வன்பொருள் கட்டமைப்பு",
        ],
        nextId: (_) => "te_q3_turnover",
      ),
      'te_q3_turnover': QuestionNode(
        id: 'te_q3_turnover',
        questionText: "What is your enterprise annual turnover?",
        questionTextTa: "உங்கள் நிறுவனத்தின் ஆண்டு விற்றுமுதல் எவ்வளவு?",
        options: ["Under ₹50 Lakhs", "₹50 Lakhs - ₹5 Crores", "Over ₹5 Crores"],
        optionsTa: [
          "₹50 இலட்சத்திற்குக் கீழ்",
          "₹50 இலட்சம் - ₹5 கோடி",
          "₹5 கோடிக்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getDefaultCategoryFlow() {
    return {
      'cat_q1': QuestionNode(
        id: 'cat_q1',
        questionText: "What describes your current employment status?",
        questionTextTa: "உங்கள் தற்போதைய வேலைவாய்ப்பு நிலை என்ன?",
        options: [
          "Student",
          "Farmer",
          "Business Owner / Self-employed",
          "Unemployed / Worker",
        ],
        optionsTa: [
          "மாணவர்",
          "விவசாயி",
          "தொழிலதிபர் / சுயதொழில்",
          "வேலையில்லாதவர் / பணியாளர்",
        ],
        nextId: (_) => "cat_q2",
      ),
      'cat_q2': QuestionNode(
        id: 'cat_q2',
        questionText:
            "Are you seeking financial credit or direct subsidy grants?",
        questionTextTa:
            "நிதிக் கடன் அல்லது நேரடி மானியங்களை எதிர்பார்க்கிறீர்களா?",
        options: [
          "Business / Study Loans",
          "Subsidies & welfare grants",
          "Free skill training / services",
        ],
        optionsTa: [
          "தொழில் / கல்வி கடன்கள்",
          "மானியங்கள் & நலத்திட்ட உதவிகள்",
          "இலவச திறன் பயிற்சி / சேவைகள்",
        ],
        nextId: (_) => "cat_q3",
      ),
      'cat_q3': QuestionNode(
        id: 'cat_q3',
        questionText: "What is your gender?",
        questionTextTa: "உங்கள் பாலினம் என்ன?",
        options: ["Female", "Male", "Other"],
        optionsTa: ["பெண்", "ஆண்", "இதர"],
        nextId: (_) => "cat_q4",
      ),
      'cat_q4': QuestionNode(
        id: 'cat_q4',
        questionText: "What is your social caste category?",
        questionTextTa: "உங்கள் சமூகப் பிரிவு என்ன?",
        options: ["General", "OBC", "SC / ST", "EWS / Minority"],
        optionsTa: [
          "பொதுப்பிரிவு (General)",
          "பிற்படுத்தப்பட்டோர் (OBC/BC)",
          "பட்டியல் வகுப்பினர் (SC / ST)",
          "பொருளாதாரத்தில் பின்தங்கியோர் / சிறுபான்மையினர்",
        ],
        nextId: (_) => "cat_q5",
      ),
      'cat_q5': QuestionNode(
        id: 'cat_q5',
        questionText: "What is your annual family income?",
        questionTextTa: "உங்கள் குடும்பத்தின் ஆண்டு வருமானம் என்ன?",
        options: ["Under ₹2.5 Lakhs", "₹2.5 Lakhs - ₹8 Lakhs", "Over ₹8 Lakhs"],
        optionsTa: [
          "₹2.5 இலட்சத்திற்குக் கீழ்",
          "₹2.5 இலட்சம் - ₹8 இலட்சம்",
          "₹8 இலட்சத்திற்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getStateFlow(String stateName) {
    return {
      'state_q1': QuestionNode(
        id: 'state_q1',
        questionText: "Are you a permanent resident/domicile of $stateName?",
        questionTextTa: "நீங்கள் $stateName மாநிலத்தின் நிரந்தர குடியாசியா?",
        options: [
          "Yes, I hold a domicile certificate",
          "No, I am a temporary resident",
        ],
        optionsTa: [
          "ஆம், இருப்பிட சான்றிதழ் உள்ளது",
          "இல்லை, தற்காலிகமாக வசிக்கிறேன்",
        ],
        nextId: (_) => "state_q2",
      ),
      'state_q2': QuestionNode(
        id: 'state_q2',
        questionText:
            "What is your category in the $stateName state reservation list?",
        questionTextTa:
            "$stateName மாநில இடஒதுக்கீடு பட்டியலில் உங்கள் பிரிவு என்ன?",
        options: [
          "BC / SEBC / OBC",
          "SC / ST",
          "EWS / Minority",
          "General / Open",
        ],
        optionsTa: [
          "BC / MBC / OBC",
          "SC / ST",
          "EWS / சிறுபான்மையினர்",
          "பொதுப்பிரிவு (Open)",
        ],
        nextId: (_) => "state_q3",
      ),
      'state_q3': QuestionNode(
        id: 'state_q3',
        questionText: "What is your primary livelihood sector in $stateName?",
        questionTextTa:
            "$stateName மாநிலத்தில் உங்கள் முதன்மை வாழ்வாதாரத் துறை என்ன?",
        options: [
          "Agriculture / Farmer",
          "MSME / Startup owner",
          "Weaving / Traditional Crafts",
          "Student / Higher studies",
        ],
        optionsTa: [
          "வேளாண்மை / விவசாயி",
          "MSME / ஸ்டார்ட்அப் உரிமையாளர்",
          "நெசவு / பாரம்பரிய கைவினைஞர்கள்",
          "மாணவர் / உயர்கல்வி",
        ],
        nextId: (_) => "state_q4",
      ),
      'state_q4': QuestionNode(
        id: 'state_q4',
        questionText: "What type of state assistance are you targeting?",
        questionTextTa: "மாநில அரசின் எந்த உதவிகளை எதிர்பார்க்கிறீர்கள்?",
        options: [
          "Monthly cash allowances",
          "Education fee waivers",
          "Business subsidies",
          "Agricultural input support",
        ],
        optionsTa: [
          "மாதாந்திர நிதியுதவி / உதவித்தொகை",
          "கல்விக் கட்டண விலக்கு",
          "தொழில் மானியங்கள்",
          "விவசாய உறைவிட உதவிகள்",
        ],
        nextId: (_) => "state_q5",
      ),
      'state_q5': QuestionNode(
        id: 'state_q5',
        questionText: "What is your total family annual income?",
        questionTextTa: "உங்கள் குடும்பத்தின் ஆண்டு வருமானம் என்ன?",
        options: ["Under ₹1.5 Lakhs", "₹1.5 Lakhs - ₹5 Lakhs", "Over ₹5 Lakhs"],
        optionsTa: [
          "₹1.5 இலட்சத்திற்குக் கீழ்",
          "₹1.5 இலட்சம் - ₹5 இலட்சம்",
          "₹5 இலட்சத்திற்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getMinistryFlow(String ministryName) {
    return {
      'min_q1': QuestionNode(
        id: 'min_q1',
        questionText:
            "What is your primary objective within this ministry's portal?",
        questionTextTa: "இத்துறையின் மூலம் உங்கள் முதன்மை நோக்கம் என்ன?",
        options: [
          "Applying for business subsidy / credit",
          "Seeking educational scholarships",
          "Seeking farmer agricultural aid",
          "Seeking rural infrastructure / SHG help",
        ],
        optionsTa: [
          "தொழில் மானியம் / கடனுக்கு விண்ணப்பித்தல்",
          "கல்வி உதவித்தொகை பெறுதல்",
          "விவசாய நிதி உதவிகள் பெறுதல்",
          "ஊரக மகளிர் சுயஉதவிக் குழு உதவிகள்",
        ],
        nextId: (_) => "min_q2",
      ),
      'min_q2': QuestionNode(
        id: 'min_q2',
        questionText: "What is the applicant's current age?",
        questionTextTa: "விண்ணப்பதாரரின் தற்போதைய வயது என்ன?",
        options: ["18 - 35 Years", "36 - 59 Years", "60 Years and above"],
        optionsTa: [
          "18 - 35 வயது",
          "36 - 59 வயது",
          "60 வயது மற்றும் அதற்கு மேல்",
        ],
        nextId: (_) => "min_q3",
      ),
      'min_q3': QuestionNode(
        id: 'min_q3',
        questionText: "Do you have any registered ID linked to this ministry?",
        questionTextTa: "இமைச்சகத்துடன் பதிவு செய்யப்பட்ட எண் உள்ளதா?",
        options: [
          "Yes, Udyam / PM-KISAN / Scholar ID",
          "No, not registered yet",
        ],
        optionsTa: [
          "ஆம், உத்யம் / PM-KISAN / மாணவர் சான்று எண்",
          "இல்லை, இன்னும் பதிவு செய்யவில்லை",
        ],
        nextId: (_) => "min_q4",
      ),
      'min_q4': QuestionNode(
        id: 'min_q4',
        questionText: "What is your social category?",
        questionTextTa: "உங்கள் சமூகப் பிரிவு என்ன?",
        options: ["General", "OBC", "SC / ST", "Minority / PwD"],
        optionsTa: [
          "பொதுப்பிரிவு (General)",
          "பிற்படுத்தப்பட்டோர் (OBC/BC)",
          "பட்டியல் வகுப்பினர் (SC / ST)",
          "சிறுபான்மையினர் / மாற்றுத்திறனாளி",
        ],
        nextId: (_) => "min_q5",
      ),
      'min_q5': QuestionNode(
        id: 'min_q5',
        questionText: "What is your annual household income?",
        questionTextTa: "உங்கள் குடும்பத்தின் ஆண்டு வருமானம் என்ன?",
        options: ["Under ₹2.5 Lakhs", "₹2.5 Lakhs - ₹8 Lakhs", "Over ₹8 Lakhs"],
        optionsTa: [
          "₹2.5 இலட்சத்திற்குக் கீழ்",
          "₹2.5 இலட்சம் - ₹8 இலட்சம்",
          "₹8 இலட்சத்திற்கு மேல்",
        ],
        nextId: (_) => null,
      ),
    };
  }
}

String _getStateMapAsset(String stateName) {
  final rawPath = _getStateMapAssetRaw(stateName);
  return rawPath.replaceAll(
    'assets/images/States and UTs/',
    'assets/images/States assets/',
  );
}

String _getStateMapAssetRaw(String stateName) {
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
