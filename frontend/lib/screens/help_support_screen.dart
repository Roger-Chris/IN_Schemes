import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  String _issueCategory = 'General Inquiry';
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I check my eligibility for a scheme?',
      'answer': 'Go to the \'Find My Schemes\' tab, fill out your profile details (age, gender, state, income, etc.), and the matcher engine will instantly show your eligibility score for all available schemes!'
    },
    {
      'question': 'How can I apply for a scheme?',
      'answer': 'Select any scheme to see its detailed description, benefits, and required documents. Tap the \'Apply Now\' button to open the official government application portal in your browser.'
    },
    {
      'question': 'Where can I track my application status?',
      'answer': 'Since application submissions are processed directly on official government portals, you can track your status by logging into the respective portal using the application ID provided during submission.'
    },
    {
      'question': 'Is IN Schemes app free to use?',
      'answer': 'Yes, IN Schemes is completely free to use. Our goal is to make citizen benefits and government schemes accessible to everyone in India without any hidden fees.'
    },
    {
      'question': 'How often is new data updated?',
      'answer': 'Our database is updated daily to reflect the latest announcements, schemes, subsidies, and application guidelines from the central and state ministries.'
    },
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFAQBottomSheet(String question, String answer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'FAQ Answer',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                question,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAllFAQsBottomSheet() {
    final allFaqs = [
      ..._faqs,
      {
        'question': 'How does the recommendation scoring work?',
        'answer': 'We evaluate your profile (residency, age, gender, education, and community) against the criteria set by each scheme. A match score is calculated out of 100% depending on the percentage of conditions met.'
      },
      {
        'question': 'Is my personal data shared with the government?',
        'answer': 'No. IN schemes is a recommendation tool that runs fully on your device. We do not share your profile details with external departments. You apply directly on official portals.'
      },
      {
        'question': 'How do I obtain missing documents?',
        'answer': 'In the Scheme Details view, any document marked as "Missing" has a "Get Document" link that redirects you directly to the official portal (e.g., UIDAI for Aadhaar, NSDL for PAN).'
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'All FAQs',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = allFaqs[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            faq['question']!,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          iconColor: const Color(0xFF2563EB),
                          collapsedIconColor: const Color(0xFF64748B),
                          shape: const Border(),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Text(
                              faq['answer']!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportIssueBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bug_report_outlined, color: Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Report an Issue',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Facing a problem? Fill out the details below and our team will get back to you shortly.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _issueCategory,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'General Inquiry', child: Text('General Inquiry')),
                      DropdownMenuItem(value: 'Eligibility Matcher Bug', child: Text('Eligibility Matcher Bug')),
                      DropdownMenuItem(value: 'Wrong Scheme Details', child: Text('Wrong Scheme Details')),
                      DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _issueCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Contact Email Address',
                      hintText: 'Enter your email for follow-up',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the issue in detail...',
                      alignLabelWithHint: true,
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting 
                        ? null 
                        : () {
                            final text = _feedbackController.text.trim();
                            if (text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please describe the issue.')),
                              );
                              return;
                            }
                            setModalState(() => _isSubmitting = true);
                            Future.delayed(const Duration(milliseconds: 1200), () {
                              if (context.mounted) {
                                setModalState(() => _isSubmitting = false);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thank you! Your ticket has been submitted.'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                                _feedbackController.clear();
                                _emailController.clear();
                              }
                            });
                          },
                      child: _isSubmitting 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Submit Ticket',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFeedbackBottomSheet() {
    double rating = 5.0;
    final feedbackTextController = TextEditingController();
    bool submittingFeedback = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFEA580C), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Share Feedback',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We value your feedback. Let us know how we can improve your experience!',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Rate your experience',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starRating = index + 1;
                            return IconButton(
                              icon: Icon(
                                starRating <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 36,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  rating = starRating.toDouble();
                                });
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: feedbackTextController,
                    maxLines: 3,
                    style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Your suggestions',
                      hintText: 'What can we do better?',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: submittingFeedback 
                        ? null 
                        : () {
                            setModalState(() => submittingFeedback = true);
                            Future.delayed(const Duration(milliseconds: 1000), () {
                              if (context.mounted) {
                                setModalState(() => submittingFeedback = false);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thank you for your valuable feedback!'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              }
                            });
                          },
                      child: submittingFeedback 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Submit Feedback',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    double size = 44,
    double iconSize = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF0F172A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Help & Support',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're here to help you",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: FAQs Group
            _buildGroupCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildCircleIcon(
                        icon: Icons.help_outline_rounded,
                        bgColor: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FAQs',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Find answers to common questions',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                ..._faqs.map((faq) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        title: Text(
                          faq['question']!,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                        onTap: () => _showFAQBottomSheet(faq['question']!, faq['answer']!),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                    ],
                  );
                }),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Text(
                    'View all FAQs',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB), size: 18),
                  onTap: _showAllFAQsBottomSheet,
                ),
              ],
            ),

            // Card 2: Contact Support Group
            _buildGroupCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildCircleIcon(
                        icon: Icons.headset_mic_outlined,
                        bgColor: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Support',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Get in touch with our support team',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCircleIcon(
                                icon: Icons.mail_outline_rounded,
                                bgColor: const Color(0xFFEFF6FF),
                                iconColor: const Color(0xFF2563EB),
                                size: 36,
                                iconSize: 18,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Email Us',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _copyToClipboard(
                                  'support@inschemes.gov.in',
                                  'Support email copied to clipboard!',
                                ),
                                child: Text(
                                  'support@inschemes.gov.in',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF2563EB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We typically reply within 24 hours',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCircleIcon(
                                icon: Icons.phone_outlined,
                                bgColor: const Color(0xFFEFF6FF),
                                iconColor: const Color(0xFF2563EB),
                                size: 36,
                                iconSize: 18,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Call Us',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _copyToClipboard(
                                  '1800 123 4567',
                                  'Support hotline copied to clipboard!',
                                ),
                                child: Text(
                                  '1800 123 4567',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF2563EB),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mon – Sat | 9:00 AM – 6:00 PM',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
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

            // Card 3: Report & Feedback Group
            _buildGroupCard(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildCircleIcon(
                    icon: Icons.bug_report_outlined,
                    bgColor: const Color(0xFFF0FDF4),
                    iconColor: const Color(0xFF16A34A),
                  ),
                  title: Text(
                    'Report an Issue',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Facing a problem? Let us know.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                  onTap: _showReportIssueBottomSheet,
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildCircleIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    bgColor: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFEA580C),
                  ),
                  title: Text(
                    'Feedback',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Share your suggestions to help us improve.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                  onTap: _showFeedbackBottomSheet,
                ),
              ],
            ),

            // Still need help Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 110, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCircleIcon(
                          icon: Icons.verified_user_outlined,
                          bgColor: Colors.white,
                          iconColor: const Color(0xFF16A34A),
                          size: 36,
                          iconSize: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Still need help?',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Our support team is always ready to assist you.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -5,
                    child: Image.asset(
                      'assets/images/support_agent.png',
                      height: 85,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

