import 'package:flutter/material.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/custom_button.dart';
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

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue or enter feedback.'), backgroundColor: AppConstants.errorColor),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate submission latency
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your ticket has been submitted to support team.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        _feedbackController.clear();
        _emailController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQs Title
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
            ),
            const SizedBox(height: 12),
            
            _buildFAQTile(
              question: 'How does the recommendation scoring work?',
              answer: 'We evaluate your profile (residency, age, gender, education, and community) against the criteria set by each scheme. A match score is calculated out of 100% depending on the percentage of conditions met.',
            ),
            _buildFAQTile(
              question: 'Is my personal data shared with the government?',
              answer: 'No. IN schemes is a recommendation tool that runs fully on your device. We do not share your profile details with external departments. You apply directly on official portals.',
            ),
            _buildFAQTile(
              question: 'How do I obtain missing documents?',
              answer: 'In the Scheme Details view, any document marked as "Missing" has a "Get Document" link that redirects you directly to the official portal (e.g., UIDAI for Aadhaar, NSDL for PAN).',
            ),
            const SizedBox(height: 24),
            
            // Contact Channels
            const Text(
              'Quick Contact Channels',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email_outlined,
                    label: 'Email Support',
                    detail: 'support@inschemes.in',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening mail client...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.phone_outlined,
                    label: 'Toll-Free Phone',
                    detail: '1800-425-6789',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling Support Hotline...')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // Report issue form
            const Text(
              'Report an Issue or Send Feedback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
            ),
            const SizedBox(height: 12),
            
            Theme(
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
                ),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _issueCategory,
                    dropdownColor: AppConstants.surfaceColor,
                    style: const TextStyle(color: AppConstants.primaryText),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'General Inquiry', child: Text('General Inquiry')),
                      DropdownMenuItem(value: 'Eligibility Matcher Bug', child: Text('Eligibility Matcher Bug')),
                      DropdownMenuItem(value: 'Wrong Scheme Details', child: Text('Wrong Scheme Details')),
                      DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _issueCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppConstants.primaryText),
                    decoration: const InputDecoration(
                      labelText: 'Contact Email Address',
                      hintText: 'Enter your email for follow-up',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: const TextStyle(color: AppConstants.primaryText),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the issue or feedback in detail...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Submit Support Ticket',
                      isLoading: _isSubmitting,
                      onPressed: _submitFeedback,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardBorderColor),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        iconColor: AppConstants.accentColor,
        collapsedIconColor: AppConstants.secondaryText,
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(color: AppConstants.secondaryText, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String detail,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.cardBorderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppConstants.secondaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(color: AppConstants.secondaryText, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
