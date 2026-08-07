import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-page detailed Privacy Policy Screen for IN Schemes
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate700 = Color(0xFF334155);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);
  static const Color kBgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kSlate900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            color: kSlate900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryBlue.withValues(alpha: 0.08),
                      const Color(0xFFEFF6FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kPrimaryBlue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kPrimaryBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IN Schemes Privacy Commitment',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kSlate900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last Updated: August 2026 • Version 2.0',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: kSlate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Your privacy and data protection are fundamental to our mission. This policy outlines how IN Schemes handles, stores, and protects your information.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: kSlate700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Information We Collect
              _buildSectionCard(
                icon: Icons.person_search_rounded,
                title: '1. Information We Collect',
                content: [
                  '• Profile Details: Name, Mobile Number, Email Address, Gender, and Date of Birth provided during profile setup.',
                  '• Location Data: State, District, Area, and Pincode collected via GPS or manual input to filter regional government schemes.',
                  '• Enterprise & Category Details: Target Role (Student, Entrepreneur, MSME, Farmer) and income bracket used for eligibility matching.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: How We Use Your Data
              _buildSectionCard(
                icon: Icons.tune_rounded,
                title: '2. How We Use Your Information',
                content: [
                  '• Scheme Eligibility Assessment: To evaluate your profile against 1000+ Central and State Government schemes.',
                  '• Personalization & Localization: To deliver tailored notifications and app content in your preferred language.',
                  '• System Improvement: Anonymized operational metrics to enhance scheme search speed.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: Data Security & Storage
              _buildSectionCard(
                icon: Icons.lock_outline_rounded,
                title: '3. Data Security & Storage',
                content: [
                  '• Local Device Encryption: Your personal profile data is cached securely on your local device.',
                  '• Encrypted Backend: Authentication and cloud synchronization use SSL/TLS encrypted pathways via Supabase.',
                  '• Zero Data Monetization: Your data is never sold, leased, or rented to third-party marketing brokers.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 4: Official External Links
              _buildSectionCard(
                icon: Icons.open_in_browser_rounded,
                title: '4. External Official Portals',
                content: [
                  '• Redirection to Official Webpages: Tapping registration links (such as Udyam Registration, PMEGP, or MUDRA) opens official government domains (.gov.in / .nic.in).',
                  '• Independent Credentials: IN Schemes does not store or access your credentials on external government portals.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 5: Your Rights & Control
              _buildSectionCard(
                icon: Icons.account_circle_outlined,
                title: '5. Your Rights & Control',
                content: [
                  '• Right to Access & Edit: You can update your profile details at any time from the Settings screen.',
                  '• Right to Erasure: You can permanently delete your profile and account history using the "Delete Account" button.',
                ],
              ),
              const SizedBox(height: 24),

              // Contact Footer Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBgLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          color: kPrimaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Have Privacy Questions?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kSlate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'If you have questions regarding data privacy or consent, contact our support desk at support@inschemes.gov.in.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: kSlate500,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimaryBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: kSlate900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                point,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: kSlate700,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-page detailed Terms & Conditions Screen for IN Schemes
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate700 = Color(0xFF334155);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);
  static const Color kBgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kSlate900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.poppins(
            color: kSlate900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryBlue.withValues(alpha: 0.08),
                      const Color(0xFFEFF6FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kPrimaryBlue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kPrimaryBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IN Schemes Terms of Service',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kSlate900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last Updated: August 2026 • Version 2.0',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: kSlate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'By accessing or using the IN Schemes application, you agree to be bound by these Terms & Conditions. Please read them carefully.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: kSlate700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Purpose & Scope
              _buildSectionCard(
                icon: Icons.info_outline_rounded,
                title: '1. App Purpose & Guidance',
                content: [
                  '• Platform Role: IN Schemes is an independent digital assistance platform designed to help citizens and businesses discover, understand, and navigate Indian Central and State Government schemes.',
                  '• Non-Governmental Entity: IN Schemes provides scheme aggregation and eligibility guidance. Final sanction and approval rest exclusively with respective Government Departments.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: User Responsibilities
              _buildSectionCard(
                icon: Icons.assignment_ind_outlined,
                title: '2. User Responsibilities',
                content: [
                  '• Accurate Profile Setup: Users are responsible for providing accurate profile details (location, income, role) to ensure reliable scheme recommendation results.',
                  '• Fair Usage: Users agree not to attempt unauthorized access, reverse engineering, or automated scraping of the IN Schemes database.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: Intellectual Property & Emblems
              _buildSectionCard(
                icon: Icons.verified_user_outlined,
                title: '3. Intellectual Property & Emblems',
                content: [
                  '• Official Emblems & Trademarks: Government emblems, state seals, and scheme logos displayed within the app belong to their respective Ministries and State Authorities.',
                  '• Application Content: Interface designs, matching algorithms, and curated guides are protected under intellectual property rights.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 4: External Links & Disclaimer
              _buildSectionCard(
                icon: Icons.link_rounded,
                title: '4. External Links & Disclaimer',
                content: [
                  '• Official Government Links: Direct application routes open official government portals (.gov.in / .nic.in). We are not responsible for external site downtime or server maintenance.',
                  '• Policy Updates: IN Schemes reserves the right to update these terms to reflect legal or feature changes.',
                ],
              ),
              const SizedBox(height: 24),

              // Agreement Footer Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBgLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: kPrimaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Terms Agreement',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kSlate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Continued use of IN Schemes signifies your acceptance of these Terms & Conditions.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: kSlate500,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimaryBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: kSlate900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                point,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: kSlate700,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
