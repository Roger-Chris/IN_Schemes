import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import 'discover_results_screen.dart';

class MSMEModuleDetailsScreen extends StatefulWidget {
  final String moduleId; // 'schemes', 'finance', 'tax_gst', 'export', 'treds', 'csr', 'govt', 'institutions'
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color themeColor;

  const MSMEModuleDetailsScreen({
    super.key,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.themeColor,
  });

  @override
  State<MSMEModuleDetailsScreen> createState() => _MSMEModuleDetailsScreenState();
}

class _MSMEModuleDetailsScreenState extends State<MSMEModuleDetailsScreen> {
  // GST Late Payment Interest Calculator variables
  final _invoiceController = TextEditingController(text: '100000');
  final _daysController = TextEditingController(text: '60');
  double _calculatedInterest = 0.0;
  double _totalAmount = 0.0;
  final double _annualRate = 0.2025; // 3x RBI Bank Rate (6.75% * 3 = 20.25%)

  // Export readiness checklist state
  final List<Map<String, dynamic>> _exportChecklist = [
    {
      'question': 'Do you have an Import Export Code (IEC) from DGFT?',
      'checked': false,
      'tip': 'Apply online on dgft.gov.in. It is issued instantly against PAN.'
    },
    {
      'question': 'Do you have an active Bank Account and AD Code registration?',
      'checked': false,
      'tip': 'Request an AD (Authorized Dealer) Code from your bank and register it with Customs.'
    },
    {
      'question': 'Have you identified the HS Code (Harmonized System Code) for your product?',
      'checked': false,
      'tip': 'HS Codes classify products globally. Search online or consult a customs broker.'
    },
    {
      'question': 'Is your business registered under Udyam (MSME Registration)?',
      'checked': false,
      'tip': 'Free registration on udyamregistration.gov.in. Required for export subsidies.'
    },
    {
      'question': 'Do you have an RCMC from an Export Promotion Council?',
      'checked': false,
      'tip': 'Registration cum Membership Certificate (RCMC) is needed to claim duty refunds/incentives.'
    },
  ];

  // TReDS stepper current index
  int _tredsStepIndex = 0;
  final List<Map<String, String>> _tredsSteps = [
    {
      'title': '1. Invoice Upload',
      'desc': 'MSME Seller uploads the invoice for goods/services delivered to the Corporate Buyer on the TReDS platform (RXIL/M1xchange/Invoicemart).',
      'action': 'Seller uploads invoice & supporting documents.'
    },
    {
      'title': '2. Buyer Acceptance',
      'desc': 'The Corporate Buyer logs into the TReDS portal, verifies the details, and digitally accepts the uploaded invoice.',
      'action': 'Buyer approves invoice; it becomes a legally binding payment obligation.'
    },
    {
      'title': '3. Bank Bidding',
      'desc': 'Multiple Financiers (Banks and NBFCs) compete by placing bids with their discount rates (interest rates) to buy the invoice.',
      'action': 'Banks bid anonymously based on the Buyer\'s credit rating.'
    },
    {
      'title': '4. Funds Disbursal',
      'desc': 'Seller selects the best bid (lowest discount rate). Funds are credited to the Seller\'s bank account within 24-48 hours (T+1 or T+2) minus the discount.',
      'action': 'Seller gets instant working capital; Buyer pays the Bank on the due date.'
    },
  ];

  // Udyam stepper current index & steps
  int _udyamStepIndex = 0;
  final List<Map<String, String>> _udyamSteps = [
    {
      'title': '1. Aadhaar & PAN Validation',
      'desc': 'Enter entrepreneur Aadhaar Number & Name as per Aadhaar. Validate via OTP. Next, enter Organization Type & PAN details for automatic GSTIN verification.',
      'action': 'Aadhaar OTP authentication & PAN details entry.'
    },
    {
      'title': '2. Enterprise & Location Details',
      'desc': 'Provide Enterprise Name, Plant/Unit Addresses, Official Email, Mobile Number, Bank Account Number, and IFSC Code.',
      'action': 'Fill unit addresses, mobile, email & bank details.'
    },
    {
      'title': '3. NIC Code & Investment Details',
      'desc': 'Select Major Activity (Manufacturing / Service), search & select 2/4/5-digit NIC Codes, enter number of employees, and investment in Plant & Machinery.',
      'action': 'Select NIC classification code & enter investment/turnover.'
    },
    {
      'title': '4. Final Submit & e-Certificate',
      'desc': 'Review summary, submit final OTP. A unique 16-digit Udyam Registration Number (URN) and e-Certificate with QR code are issued instantly with zero registration fee.',
      'action': 'Final OTP submission; download instant e-Certificate.'
    },
  ];

  // Govt hierarchy tab
  int _selectedGovtTab = 0; // 0: Central, 1: State, 2: District

  // Institutions search filter
  String _institutionsSearch = '';
  final List<Map<String, dynamic>> _institutions = [
    {
      'name': 'SIDBI',
      'fullName': 'Small Industries Development Bank of India',
      'role': 'Principal financial institution for MSME promotion, financing, and development.',
      'services': 'Direct lending, venture capital, refinance to banks, startup funding.',
      'schemes': 'SMILE (SIDBI Make in India Loan for Enterprises), ARISE, Speed Plus.'
    },
    {
      'name': 'NSIC',
      'fullName': 'National Small Industries Corporation',
      'role': 'Government enterprise facilitating marketing, technology, and raw material support.',
      'services': 'Raw Material Assistance Scheme, Single Point Registration Scheme for govt tenders.',
      'schemes': 'Consortia and Tender Marketing, Raw Material Distribution.'
    },
    {
      'name': 'DIC',
      'fullName': 'District Industries Centre',
      'role': 'District-level nodal agency providing single-window assistance for setting up MSMEs.',
      'services': 'Udyam registration support, state subsidy verification, local clearances, PMEGP implementation.',
      'schemes': 'Prime Minister\'s Employment Generation Programme (PMEGP), State-specific capital subsidies.'
    },
    {
      'name': 'KVIC',
      'fullName': 'Khadi and Village Industries Commission',
      'role': 'Nodal agency implementing rural employment and cottage industry schemes.',
      'services': 'Subsidies, training centers, khadi production support, sales outlets.',
      'schemes': 'PMEGP (Nodal Agency), Scheme of Fund for Regeneration of Traditional Industries (SFURTI).'
    },
    {
      'name': 'TIIC',
      'fullName': 'Tamil Nadu Industrial Investment Corporation',
      'role': 'State-level financial institution providing term loans to MSMEs in Tamil Nadu.',
      'services': 'Term loans for land, building, and machinery acquisition.',
      'schemes': 'NEEDS (New Entrepreneur cum Enterprise Development Scheme), Capital Subsidy Scheme.'
    },
    {
      'name': 'StartupTN / FaMeTN',
      'fullName': 'Startup Tamil Nadu & Facilitating MSMEs Tamil Nadu',
      'role': 'Nodal agencies for fostering startup ecosystem and facilitating MSMEs in Tamil Nadu.',
      'services': 'TANSEED seed fund, incubator support, marketing assistance, buyer-seller meets.',
      'schemes': 'TANSEED Grants, MSME Trade Portal Assistance, Cluster Development.'
    },
    {
      'name': 'SIPCOT',
      'fullName': 'State Industries Promotion Corporation of Tamil Nadu',
      'role': 'Industrial infrastructure development agency.',
      'services': 'Allotment of plots/sheds in industrial parks, basic infrastructure provisions.',
      'schemes': 'Industrial Park Infrastructure Support, Environmental Clearance Guidance.'
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.moduleId == 'tax_gst') {
      _calculateLateInterest();
    }
  }

  void _calculateLateInterest() {
    final double invoiceVal = double.tryParse(_invoiceController.text) ?? 0.0;
    final int delayDays = int.tryParse(_daysController.text) ?? 0;
    if (invoiceVal <= 0 || delayDays <= 0) {
      setState(() {
        _calculatedInterest = 0.0;
        _totalAmount = invoiceVal;
      });
      return;
    }

    // Formula: Compounded with monthly rests (every 30 days)
    // Monthly rate = r / 12
    // Number of months = delayDays / 30
    final double monthlyRate = _annualRate / 12;
    final double months = delayDays / 30.0;
    final double finalVal = invoiceVal * pow(1 + monthlyRate, months);
    
    setState(() {
      _calculatedInterest = finalVal - invoiceVal;
      _totalAmount = finalVal;
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module Header Card
            _buildModuleHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // What the User Gets Section
                  _buildWhatUserGets(),

                  const SizedBox(height: 24),

                  // Interactive Feature Panel (The Core Function)
                  _buildInteractiveFeaturePanel(),

                  const SizedBox(height: 24),

                  // Main Features Inside Section
                  _buildMainFeaturesList(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatUserGets() {
    String valueText = '';
    switch (widget.moduleId) {
      case 'schemes':
        valueText = 'Find government subsidies, grants, and registration schemes you are eligible for, customized to your profile details.';
        break;
      case 'finance':
        valueText = 'Access loan options, credit guarantees, equipment loans, and SIDBI schemes to finance and expand your enterprise.';
        break;
      case 'tax_gst':
        valueText = 'Learn about corporate tax reductions, GST threshold relief, composition schemes, and legal interest claims for payment delays.';
        break;
      case 'export':
        valueText = 'Discover export incentives, financial credits, credit insurance, and regulatory agencies to expand your business globally.';
        break;
      case 'treds':
        valueText = 'Discount your trade invoices through online bidding with banks and financial institutions to get immediate cash flow without collateral.';
        break;
      case 'csr':
        valueText = 'Connect with corporate social responsibility (CSR) programs, tech incubation grants, and specialized skill development clusters.';
        break;
      case 'govt':
        valueText = 'Understand government department responsibilities and reach the appropriate authority (Central Ministry, State Directorate, or District DIC) for business help.';
        break;
      case 'institutions':
        valueText = 'Identify the right institutions (SIDBI, NSIC, DIC, KVIC, etc.) and explore their service catalogs, contact avenues, and programs.';
        break;
      case 'udyam':
        valueText = 'Complete official MSME Udyam registration for free to unlock priority sector bank loans, 15% capital subsidies, collateral-free credit (CGTMSE), and Government tender exemptions.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.themeColor.withValues(alpha: 0.05),
            widget.themeColor.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: widget.iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'WHAT THE USER GETS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.iconColor,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valueText,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF1E293B),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveFeaturePanel() {
    switch (widget.moduleId) {
      case 'schemes':
        return _buildSchemesInteractivePanel();
      case 'finance':
        return _buildFinanceInteractivePanel();
      case 'tax_gst':
        return _buildTaxGstInteractivePanel();
      case 'export':
        return _buildExportInteractivePanel();
      case 'treds':
        return _buildTredsInteractivePanel();
      case 'csr':
        return _buildCsrInteractivePanel();
      case 'govt':
        return _buildGovtInteractivePanel();
      case 'institutions':
        return _buildInstitutionsInteractivePanel();
      case 'udyam':
        return _buildUdyamInteractivePanel();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSchemesInteractivePanel() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interactive Tools & Actions',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your profile or explore schemes with the search engine to get smart matching results.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.iconColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      provider.updateTabIndex(1); // Navigate to search
                      Navigator.of(context).pop(); // Dismiss detail
                    },
                    child: Text(
                      'Search Schemes',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.iconColor,
                      side: BorderSide(color: widget.iconColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      provider.updateTabIndex(4); // Navigate to profile
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Complete Profile',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceInteractivePanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Funding Options',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Instantly search our database for credit support, collateral-free business loans, and SIDBI programs.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiscoverResultsScreen(
                        title: 'Loan',
                        type: 'category',
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.currency_rupee, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Search MSME Loans & Funding',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxGstInteractivePanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: widget.iconColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delayed Payment Interest Calculator',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Under the MSMED Act Section 15/16, buyers must pay 3x the RBI Bank Rate as compound interest with monthly rests for delays exceeding 45 days.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Invoice Amount (₹)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Days Delayed (Post 45d)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _invoiceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => _calculateLateInterest(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => _calculateLateInterest(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Interest Rate (3x Bank Rate):',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${(_annualRate * 100).toStringAsFixed(2)}% p.a.',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calculated Interest:',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${_calculatedInterest.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                  const Divider(height: 12, color: Color(0xFFCBD5E1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Claimable Amount:',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: widget.iconColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportInteractivePanel() {
    int checkedCount = _exportChecklist.where((item) => item['checked'] == true).length;
    double progress = checkedCount / _exportChecklist.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Readiness Assessment',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete this checklist to identify missing links for international trade registration.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_exportChecklist.length, (index) {
              final item = _exportChecklist[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: item['checked'],
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      item['question'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    activeColor: widget.iconColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        item['checked'] = val ?? false;
                      });
                    },
                  ),
                  if (item['checked'] == false)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb, color: Color(0xFFD97706), size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['tip'],
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTredsInteractivePanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TReDS Invoice Discounting Flow',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_tredsSteps.length, (idx) {
                  final isSelected = idx == _tredsStepIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tredsStepIndex = idx;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? widget.iconColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Step ${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.themeColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tredsSteps[_tredsStepIndex]['title']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tredsSteps[_tredsStepIndex]['desc']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF334155),
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _tredsSteps[_tredsStepIndex]['action']!,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUdyamInteractivePanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Udyam Registration Flow',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Step Selector Pills (Step 1, Step 2, Step 3, Step 4)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_udyamSteps.length, (idx) {
                  final isSelected = idx == _udyamStepIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _udyamStepIndex = idx;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? widget.iconColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Step ${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Step Details Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.themeColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _udyamSteps[_udyamStepIndex]['title']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _udyamSteps[_udyamStepIndex]['desc']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF334155),
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _udyamSteps[_udyamStepIndex]['action']!,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Button to official Udyam portal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Go to Official Udyam Portal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final Uri url = Uri.parse('https://udyamregistration.gov.in/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsrInteractivePanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore CSR & Technology Clusters',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for schemes offering cluster development, technology upgrades, and incubator grants.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiscoverResultsScreen(
                        title: 'Cluster',
                        type: 'category',
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hub, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Search Cluster / Tech Schemes',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovtInteractivePanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Government Authorities Tree',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGovtTabHeader(0, 'Central'),
                _buildGovtTabHeader(1, 'State'),
                _buildGovtTabHeader(2, 'District'),
              ],
            ),
            const SizedBox(height: 16),
            _buildGovtTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGovtTabHeader(int tabIndex, String title) {
    final isSelected = tabIndex == _selectedGovtTab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGovtTab = tabIndex;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? widget.iconColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? widget.iconColor : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGovtTabContent() {
    String name = '';
    String roles = '';
    String details = '';

    if (_selectedGovtTab == 0) {
      name = 'Ministry of Micro, Small and Medium Enterprises (M/o MSME)';
      roles = '• Formulation and administration of rules, regulations, and laws.\n• Designs apex developmental schemes (PMEGP, CGTMSE, SFURTI).\n• Coordinates with other central ministries for national policy.';
      details = 'Located in Udyog Bhawan, New Delhi. Operates MSME Development Institutes (MSME-DI) nationwide.';
    } else if (_selectedGovtTab == 1) {
      name = 'State Directorate of Industries / Commissionerate';
      roles = '• Implements central and state industrial policies.\n• Handles state capital incentives, interest subsidies, and power tariff concessions.\n• Coordinates development of industrial parks and estates.';
      details = 'In Tamil Nadu, this is the Department of Industries and Commerce (MSME Department).';
    } else {
      name = 'District Industries Centre (DIC)';
      roles = '• Nodal agency at the grass-roots level providing Udyam registration assistance.\n• Recommends loan approvals to banks under PMEGP.\n• Performs spot verification of industrial units for subsidy release.\n• Resolves local vendor issues via Micro & Small Enterprises Facilitation Council (MSEFC).';
      details = 'Each district in India has a DIC, headed by a General Manager.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roles,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF475569),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  details,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionsInteractivePanel() {
    final filtered = _institutions.where((inst) {
      final text = _institutionsSearch.toLowerCase();
      return inst['name'].toLowerCase().contains(text) ||
          inst['fullName'].toLowerCase().contains(text) ||
          inst['role'].toLowerCase().contains(text);
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Support Institutions',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _institutionsSearch = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search SIDBI, NSIC, DIC...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final inst = filtered[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          inst['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.iconColor,
                          ),
                        ),
                        subtitle: Text(
                          inst['fullName'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        childrenPadding: const EdgeInsets.all(12),
                        children: [
                          _buildExpansionItem('Role', inst['role']),
                          const SizedBox(height: 6),
                          _buildExpansionItem('Key Services', inst['services']),
                          const SizedBox(height: 6),
                          _buildExpansionItem('Top Schemes', inst['schemes']),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: widget.iconColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF1E293B),
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainFeaturesList() {
    List<String> features = [];
    switch (widget.moduleId) {
      case 'schemes':
        features = [
          'Personalized schemes matched to business profile',
          'Central vs. State schemes filter',
          'Comprehensive eligibility checker',
          'Search by scheme categories',
          'Capital subsidies, grants & interest subventions',
          'Reminders for registration deadlines',
          'Lists of required documents & checklists',
          'Clear, step-by-step application guidelines',
          'Scheme save & side-by-side comparison'
        ];
        break;
      case 'finance':
        features = [
          'Collateral-free business term loans & working capital',
          'SIDBI specialized credit schemes for machinery & tools',
          'Credit Guarantees (CGTMSE) for collateral-free bank options',
          'Equipment & machinery financing models',
          'Detailed comparisons of loan interest rates',
          'Direct contact pathways to SIDBI & partner commercial banks',
          'SME IPO listing requirements (BSE SME & NSE Emerge)'
        ];
        break;
      case 'tax_gst':
        features = [
          'MSME Corporate Income-Tax benefits',
          'GST registration threshold limits (₹40/₹20 Lakhs exemptions)',
          'GST Composition Scheme parameters (1% tax, easier filings)',
          'Section 43B(h) Income Tax protection (45-day payment rule)',
          'Late payment interest claim calculator (3x Bank Rate)',
          'Export tax refunds & LUT (Letter of Undertaking) rules',
          'MSME Samadhaan portal recovery guidelines'
        ];
        break;
      case 'export':
        features = [
          'Duty refund schemes (RoDTEP, RoSCTL) & Drawbacks',
          'Pre-shipment & Post-shipment export credit financing',
          'Interest subvention on foreign currency loans',
          'ECGC credit risk insurance coverage policies',
          'MDA & MAI schemes for foreign exhibition participation',
          'Directory of Export Councils & DGFT field offices',
          'HS Code classifications & AD Code registration guide'
        ];
        break;
      case 'treds':
        features = [
          'Invoice Discounting multi-party platforms explainer',
          'Onboarding guidelines for MSME Sellers',
          'RXIL, M1xchange & Invoicemart registration steps',
          'Acceptance guidelines for Corporate Buyers',
          'Financier bidding flow (anonymized auction for best rates)',
          'Payment settlement pathways (T+1 credit cycles)',
          'Recourse vs. Non-recourse factoring definitions'
        ];
        break;
      case 'csr':
        features = [
          'Corporate CSR-backed cluster development funding',
          'Access to corporate incubation grants for prototype support',
          'Specialized green-energy & waste-management cluster programs',
          'Skill development & technology upgrade programs',
          'List of CSR implementing agencies & NGOs',
          'Eligibility checklists & application pathways'
        ];
        break;
      case 'govt':
        features = [
          'Ministry of MSME (Central Govt) policies & initiatives',
          'State Directorate of Industries / Dept of Commerce role',
          'District Industries Centre (DIC) local assistance offices',
          'Clear hierarchies: Central -> State -> District levels',
          'Key contact directories & nodal officer lists',
          'Authority-specific schemes (PMEGP vs State subsidies)'
        ];
        break;
      case 'institutions':
        features = [
          'SIDBI (Small Industries Development Bank of India) credit portals',
          'NSIC (National Small Industries Corporation) raw material support',
          'DIC (District Industries Centre) single-window registrations',
          'KVIC (Khadi and Village Industries Commission) rural projects',
          'TIIC, StartupTN, FaMeTN, SIPCOT regional service descriptions',
          'Program services catalog & contact application routes'
        ];
        break;
      case 'udyam':
        features = [
          '100% Free & Paperless Instant Portal Registration',
          'Lifetime Validity with QR Code e-Certificate',
          'Automatic CGTMSE Collateral-Free Credit & TReDS Eligibility',
          'Exemption from Earnest Money Deposit (EMD) in Govt Tenders',
          'Eligible for 15% CLCSS Technology & Capital Subsidies',
          'Concessional Electricity & Patent Registration Fee Waiver'
        ];
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main Features Inside',
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...features.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: widget.iconColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF334155),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
