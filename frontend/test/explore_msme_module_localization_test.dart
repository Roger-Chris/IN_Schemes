import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Explore & MSME Support Module-Wise Localization Audit', () {
    final protectedTerms = {
      'MSME',
      'MSMED',
      'GST',
      'CGST',
      'SGST',
      'IGST',
      'PAN',
      'Aadhaar',
      'SIDBI',
      'NSIC',
      'DIC',
      'KVIC',
      'TIIC',
      'SIPCOT',
      'DGFT',
      'TREDS',
      'IEC',
      'RCMC',
      'HS',
      'INR',
      'RBI',
      'PMEGP',
      'CGTMSE',
      'SFURTI',
      'TANSEED',
      'MSEFC',
      'NBFC',
      'RXIL',
      'M1XCHANGE',
      'INVOICEMART',
      'DPIIT',
      'MRR',
      'ARR',
      'KYC',
      'CSR',
      'CODE',
      'EMI',
      'MSME-DI',
      'DI',
    };

    final tamilRegex = RegExp(r'[\u0B80-\u0BFF]');

    void assertNoMixedLanguage(String original, String contextName) {
      final translated = CentralizedTranslator.instance.translate(original);
      expect(
        translated.trim(),
        isNotEmpty,
        reason: '$contextName translated to empty string',
      );

      final tokens = translated.split(RegExp(r'[^a-zA-Z0-9]+'));
      final invalidEnglishWords = tokens.where((token) {
        if (token.length < 3) return false;
        return !protectedTerms.contains(token.toUpperCase());
      }).toList();

      final hasTamil = tamilRegex.hasMatch(translated);
      if (hasTamil && invalidEnglishWords.isNotEmpty) {
        fail(
          'Mixed language sentence in $contextName: "$translated" (Invalid English words: $invalidEnglishWords) from original "$original"',
        );
      }
    }

    test('1. Verify MSME Module What-The-User-Gets Cards', () {
      final valueTexts = [
        'Find government subsidies, grants, and registration schemes you are eligible for, customized to your profile details.',
        'Access loan options, credit guarantees, equipment loans, and SIDBI schemes to finance and expand your enterprise.',
        'Learn about corporate tax reductions, GST threshold relief, composition schemes, and legal interest claims for payment delays.',
        'Discover export incentives, financial credits, credit insurance, and regulatory agencies to expand your business globally.',
        'Discount your trade invoices through online bidding with banks and financial institutions to get immediate cash flow without collateral.',
        'Connect with corporate social responsibility (CSR) programs, tech incubation grants, and specialized skill development clusters.',
        'Understand government department responsibilities and reach the appropriate authority (Central Ministry, State Directorate, or District DIC) for business help.',
        'Identify the right institutions (SIDBI, NSIC, DIC, KVIC, etc.) and explore their service catalogs, contact avenues, and programs.',
      ];

      for (int i = 0; i < valueTexts.length; i++) {
        assertNoMixedLanguage(valueTexts[i], 'What-The-User-Gets Card #$i');
      }
    });

    test('2. Verify Export Readiness Checklist Questions & Tips', () {
      final exportItems = [
        'Export Readiness Assessment',
        'Complete this checklist to identify missing links for international trade registration.',
        'Do you have an Import Export Code (IEC) from DGFT?',
        'Apply online on dgft.gov.in. It is issued instantly against PAN.',
        'Do you have an active Bank Account and AD Code registration?',
        'Request an AD (Authorized Dealer) Code from your bank and register it with Customs.',
        'Have you identified the HS Code (Harmonized System Code) for your product?',
        'HS Codes classify products globally. Search online or consult a customs broker.',
        'Is your business registered under Udyam (MSME Registration)?',
        'Free registration on udyamregistration.gov.in. Required for export subsidies.',
        'Do you have an RCMC from an Export Promotion Council?',
        'Registration cum Membership Certificate (RCMC) is needed to claim duty refunds/incentives.',
      ];

      for (final text in exportItems) {
        assertNoMixedLanguage(text, 'Export Checklist Item "$text"');
      }
    });

    test('3. Verify TReDS Invoice Discounting Flow Steps', () {
      final tredsItems = [
        'TReDS Invoice Discounting Flow',
        '1. Invoice Upload',
        'MSME Seller uploads the invoice for goods/services delivered to the Corporate Buyer on the TReDS platform (RXIL/M1xchange/Invoicemart).',
        'Seller uploads invoice & supporting documents.',
        '2. Buyer Acceptance',
        'The Corporate Buyer logs into the TReDS portal, verifies the details, and digitally accepts the uploaded invoice.',
        'Buyer approves invoice; it becomes a legally binding payment obligation.',
        '3. Bank Bidding',
        'Multiple Financiers (Banks and NBFCs) compete by placing bids with their discount rates (interest rates) to buy the invoice.',
        'Banks bid anonymously based on the Buyer\'s credit rating.',
        '4. Funds Disbursal',
        'Seller selects the best bid (lowest discount rate). Funds are credited to the Seller\'s bank account within 24-48 hours (T+1 or T+2) minus the discount.',
        'Seller gets instant working capital; Buyer pays the Bank on the due date.',
      ];

      for (final text in tredsItems) {
        assertNoMixedLanguage(text, 'TReDS Flow Item "$text"');
      }
    });

    test('4. Verify Government Portal Hierarchy Tree', () {
      final govtItems = [
        'Government Authorities Tree',
        'Central',
        'State',
        'District',
        'Ministry of Micro, Small and Medium Enterprises (M/o MSME)',
        'Located in Udyog Bhawan, New Delhi. Operates MSME Development Institutes (MSME-DI) nationwide.',
        'State Directorate of Industries / Commissionerate',
        'In Tamil Nadu, this is the Department of Industries and Commerce (MSME Department).',
        'District Industries Centre (DIC)',
        'Each district in India has a DIC, headed by a General Manager.',
      ];

      for (final text in govtItems) {
        assertNoMixedLanguage(text, 'Govt Authority Item "$text"');
      }
    });

    test('5. Verify Support Institutions Directory Profiles', () {
      final instItems = [
        'Search Support Institutions',
        'Principal financial institution for MSME promotion, financing, and development.',
        'Direct lending, venture capital, refinance to banks, startup funding.',
        'Government enterprise facilitating marketing, technology, and raw material support.',
        'Raw Material Assistance Scheme, Single Point Registration Scheme for govt tenders.',
        'District-level nodal agency providing single-window assistance for setting up MSMEs.',
        'Udyam registration support, state subsidy verification, local clearances, PMEGP implementation.',
        'Nodal agency implementing rural employment and cottage industry schemes.',
        'Subsidies, training centers, khadi production support, sales outlets.',
        'State-level financial institution providing term loans to MSMEs in Tamil Nadu.',
        'Term loans for land, building, and machinery acquisition.',
        'Nodal agencies for fostering startup ecosystem and facilitating MSMEs in Tamil Nadu.',
        'TANSEED seed fund, incubator support, marketing assistance, buyer-seller meets.',
        'Industrial infrastructure development agency.',
        'Allotment of plots/sheds in industrial parks, basic infrastructure provisions.',
      ];

      for (final text in instItems) {
        assertNoMixedLanguage(text, 'Institution Item "$text"');
      }
    });

    test('6. Verify Business Utilities & Tools Modals', () {
      final utilityItems = [
        'Business Utilities & Tools',
        'Udyam Classifier',
        'Check MSME tier',
        'Subsidy Estimator',
        'Machinery subsidies',
        'GST Calculator',
        'Compute GST invoice',
        'EMI Calculator',
        'Calculate loan EMIs',
        'DPIIT Eligibility',
        'Check startup criteria',
        'Valuation Estimator',
        'Seed valuation ranges',
        'Doc Checklist',
        'Business setup docs',
        'Udyam MSME Classifier',
        'Classify your business under official government guidelines.',
        'Investment in Plant & Machinery',
        'Enter original purchase value of machinery in Crores',
        'Annual Turnover',
        'Enter total revenue/sales of last financial year in Crores',
        'Classification Result',
        'Calculate Classification',
        'MICRO Enterprise',
        'SMALL Enterprise',
        'MEDIUM Enterprise',
        'GST / Tax Calculator',
        'Calculate CGST, SGST, and Total invoice amounts.',
        'Base Amount',
        'Enter net value of goods or services before GST',
        'Calculate Tax',
        'Business Loan EMI Calculator',
        'Calculate monthly payments for your business loan.',
        'Loan Amount',
        'Enter total business loan sum required',
        'Calculate EMI',
        'DPIIT Recognition Checklist',
        'Evaluate if your business qualifies as a startup under DPIIT rules.',
      ];

      for (final text in utilityItems) {
        assertNoMixedLanguage(text, 'Business Utility Item "$text"');
      }
    });
  });
}
