class Scheme {
  final String id;
  final String name;
  final String category;
  final String sponsoringBody;
  final String overview;
  final String benefits;
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final List<String> applicationProcess;
  final String officialWebsite;
  final List<Map<String, String>> faqs;

  Scheme({
    required this.id,
    required this.name,
    required this.category,
    required this.sponsoringBody,
    required this.overview,
    required this.benefits,
    required this.eligibilityCriteria,
    required this.requiredDocuments,
    required this.applicationProcess,
    required this.officialWebsite,
    required this.faqs,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      sponsoringBody: json['sponsoringBody'] as String,
      overview: json['overview'] as String,
      benefits: json['benefits'] as String,
      eligibilityCriteria: List<String>.from(json['eligibilityCriteria']),
      requiredDocuments: List<String>.from(json['requiredDocuments']),
      applicationProcess: List<String>.from(json['applicationProcess']),
      officialWebsite: json['officialWebsite'] as String,
      faqs: List<Map<String, String>>.from(
        (json['faqs'] as List).map(
          (e) => Map<String, String>.from(e as Map),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sponsoringBody': sponsoringBody,
      'overview': overview,
      'benefits': benefits,
      'eligibilityCriteria': eligibilityCriteria,
      'requiredDocuments': requiredDocuments,
      'applicationProcess': applicationProcess,
      'officialWebsite': officialWebsite,
      'faqs': faqs,
    };
  }

  // Pre-seeded Phase 1 Schemes
  static final List<Scheme> seedData = [
    Scheme(
      id: 'NEEDS',
      name: 'NEEDS (New Entrepreneur cum Enterprise Development Scheme)',
      category: 'Business & MSME',
      sponsoringBody: 'Department of MSME, Government of Tamil Nadu',
      overview: 'Promotes first-generation entrepreneurs by providing financial assistance, training, and subsidies for starting manufacturing or service enterprises in Tamil Nadu.',
      benefits: '25% project cost subsidy (up to ₹75 Lakhs) for projects ranging from ₹10 Lakhs to ₹5 Crores. Also includes a 3% interest subvention during the entire loan repayment period.',
      eligibilityCriteria: [
        'Must be a resident of Tamil Nadu.',
        'Must be a first-generation entrepreneur (no family business background in similar line).',
        'Must hold a degree, diploma, ITI certificate, or vocational certificate.',
        'Age must be between 21 and 35 years for General category, and between 21 and 45 years for Special categories (Women, SC/ST, BC, MBC, Minorities, Ex-servicemen, Transgenders, Differently-abled).',
        'Project cost must be between ₹10 Lakhs and ₹5 Crores.',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'PAN Card',
        'Degree/Diploma Certificate',
        'Nativity Certificate (TN)',
        'Community Certificate',
        'Project Report / Business Plan',
        'Quotations for machinery/equipment',
      ],
      applicationProcess: [
        'Create a project profile and register on the TN MSME/NEEDS portal.',
        'Prepare and upload the Detailed Project Report (DPR) along with required certificates.',
        'Attend the selection committee interview at the District Industries Centre (DIC).',
        'Upon selection, complete the mandatory entrepreneurship development training (EDP).',
        'Obtain bank loan sanction and apply for release of subsidy.'
      ],
      officialWebsite: 'https://www.msmeonline.tn.gov.in/needs/',
      faqs: [
        {
          'question': 'Can I apply if my project cost is ₹8 Lakhs?',
          'answer': 'No, the minimum project cost required for NEEDS is ₹10 Lakhs. For smaller budgets, Mudra or PMEGP are more suitable.'
        },
        {
          'question': 'Is there an income ceiling for parents under this scheme?',
          'answer': 'No, there is currently no income ceiling for parents or family to apply for NEEDS.'
        },
        {
          'question': 'What is the training period?',
          'answer': 'The selected candidates must undergo a compulsory entrepreneurship development training program (typically 2-4 weeks) conducted by EDII-TN.'
        }
      ],
    ),
    Scheme(
      id: 'PMEGP',
      name: 'PMEGP (Prime Minister\'s Employment Generation Programme)',
      category: 'Business & MSME',
      sponsoringBody: 'Ministry of MSME, Government of India & KVIC',
      overview: 'A credit-linked subsidy scheme for setting up micro-enterprises in manufacturing or service sectors to generate self-employment in rural and urban areas.',
      benefits: 'Subsidy ranging from 15% (General category, Urban) to 35% (Special category, Rural) of the project cost. Maximum project cost is ₹50 Lakhs for Manufacturing and ₹20 Lakhs for Services.',
      eligibilityCriteria: [
        'Any individual above 18 years of age.',
        'Must have passed at least VIII Standard for manufacturing projects costing above ₹10 Lakhs and service projects costing above ₹5 Lakhs.',
        'No upper age limit and no income ceiling.',
        'Scheme is only for setting up new micro-enterprises (not for expansion of existing ones).',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'PAN Card',
        'VIII Standard Pass Certificate (or higher educational proof)',
        'Community / Caste Certificate (if SC/ST/OBC/Minority/Special)',
        'Population Certificate (for Rural projects, issued by Panchayat/Revenue authorities)',
        'Project Report / Business Proposal',
      ],
      applicationProcess: [
        'Fill out the online application on the KVIC PMEGP portal.',
        'Upload required documents and select the sponsoring agency (DIC, KVIC, KVIB) and financing bank branch.',
        'The sponsoring agency checks the application and forwards it to the bank.',
        'The bank conducts feasibility checks and sanctions the loan.',
        'Submit Margin Money (subsidy) claim after loan disbursement.'
      ],
      officialWebsite: 'https://www.kviconline.gov.in/pmegpeportal/pmegphome/index.jsp',
      faqs: [
        {
          'question': 'Can I apply for PMEGP to expand my existing shop?',
          'answer': 'No. PMEGP is strictly for setting up brand new micro-enterprises. Existing units are not eligible.'
        },
        {
          'question': 'What is the rural area definition under PMEGP?',
          'answer': 'Any area classified as rural by the Census or revenue records, or any place under a Panchayat. A population certificate from the local body is required.'
        }
      ],
    ),
    Scheme(
      id: 'STANDUP_INDIA',
      name: 'Stand-Up India',
      category: 'Startup',
      sponsoringBody: 'Department of Financial Services, Ministry of Finance, Government of India',
      overview: 'Facilitates bank loans between ₹10 Lakhs and ₹1 Crore to at least one Scheduled Caste (SC) or Scheduled Tribe (ST) borrower and at least one woman borrower per bank branch for setting up a greenfield enterprise.',
      benefits: 'Collateral-free bank loans ranging from ₹10 Lakhs to ₹1 Crore covering up to 75% of the project cost. Interest rate will be the lowest applicable rate of the bank (MCLR + 3% + Tenor Premium).',
      eligibilityCriteria: [
        'Must be SC/ST and/or a Woman entrepreneur.',
        'Above 18 years of age.',
        'Must be a Greenfield project (first-time venture in manufacturing, services, agri-allied, or trading).',
        'In case of non-individual enterprises, at least 51% of shareholding and controlling stake must be held by an SC/ST and/or Woman entrepreneur.',
        'Borrower should not be in default to any bank or financial institution.',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'PAN Card',
        'Caste Certificate (for SC/ST borrowers)',
        'Project Report / DPR',
        'Business Registration Certificate / Incorporation Documents',
        'Lease / Rental Agreement or Property Deeds for business site',
        'Last 3 years balance sheet (if applicable) or income details',
      ],
      applicationProcess: [
        'Register online on the Stand-Up India portal.',
        'Answer eligibility questions and choose whether you need handholding support (trainee) or are ready to apply.',
        'Select the bank from which you want the loan.',
        'Submit the application and track the sanction status online through the portal.'
      ],
      officialWebsite: 'https://www.standupmitra.in/',
      faqs: [
        {
          'question': 'What does "Greenfield" mean?',
          'answer': 'Greenfield denotes the first-time venture of the beneficiary in the manufacturing, services, trading, or agri-allied sector.'
        },
        {
          'question': 'Can a partnership firm apply?',
          'answer': 'Yes, provided that 51% or more of the shareholding and controlling stake is held by either an SC/ST or a Woman entrepreneur.'
        }
      ],
    ),
    Scheme(
      id: 'MUDRA',
      name: 'Mudra Yojana (Pradhan Mantri MUDRA Yojana)',
      category: 'Finance',
      sponsoringBody: 'MUDRA Ltd., Government of India',
      overview: 'Provides collateral-free loans up to ₹10 Lakhs to non-corporate, non-farm small/micro enterprises for income-generating activities.',
      benefits: 'No collateral required. Three loan categories based on development stage: Shishu (up to ₹50,000), Kishor (₹50,000 to ₹5 Lakhs), and Tarun (₹5 Lakhs to ₹10 Lakhs).',
      eligibilityCriteria: [
        'Any Indian citizen who has a business plan for a non-farm income-generating activity.',
        'Applies to small manufacturing units, service sector units, shopkeepers, fruits/vegetable vendors, artisans, and agriculture-allied activities (like dairy, poultry, beekeeping).',
        'No educational qualification or minimum age bar (except being of legal age to enter a contract).',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'PAN Card',
        'Identity Proof (Voter ID, Driving License, Passport)',
        'Address Proof (Utility Bills, Rent Agreement)',
        'Business Identity and Address Proof',
        'Price Quotation of machinery/equipment or items to be purchased',
      ],
      applicationProcess: [
        'Prepare your business proposal and purchase quotations.',
        'Download the Mudra application form (Shishu, Kishor, or Tarun) from the official website or register on the Udyam Mitra portal.',
        'Submit the form and documents to your preferred bank, NBFC, or Microfinance institution.',
        'Upon validation, the bank sanctions the loan and issues a MUDRA Card (RuPay debit card).'
      ],
      officialWebsite: 'https://www.mudra.org.in/',
      faqs: [
        {
          'question': 'Is there any subsidy in MUDRA loan?',
          'answer': 'No, MUDRA is a loan scheme with competitive interest rates and does not offer direct capital subsidies. For subsidies, check PMEGP or NEEDS.'
        },
        {
          'question': 'What is the purpose of the MUDRA Card?',
          'answer': 'The MUDRA Card is a RuPay debit card associated with the working capital portion of your loan. It allows you to withdraw cash or pay for raw materials digitally.'
        }
      ],
    ),
    Scheme(
      id: 'WEP',
      name: 'WEP (Women Entrepreneurship Platform)',
      category: 'Women & Child Welfare',
      sponsoringBody: 'NITI Aayog, Government of India',
      overview: 'A unified aggregator portal that brings together resources, mentorship, incubation support, and financial networks for women entrepreneurs across India.',
      benefits: 'Connects women entrepreneurs to funding partners (loans/grants), business mentoring networks, free corporate packages, incubation programs, and learning courses.',
      eligibilityCriteria: [
        'Open to all Indian women entrepreneurs, founders, co-founders, or women planning to start a venture.',
        'Both early-stage ideas and established businesses are supported.',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'PAN Card',
        'Udyam Registration Certificate (optional, required to access certain credit link opportunities)',
      ],
      applicationProcess: [
        'Visit the WEP portal and click on Register.',
        'Create a profile as an Entrepreneur.',
        'Complete the profile setup by providing details of your business or idea.',
        'Explore and apply to various services, mentorship sessions, and partner offers listed on the portal dashboard.'
      ],
      officialWebsite: 'https://wep.gov.in/',
      faqs: [
        {
          'question': 'Does WEP directly give loans or grants?',
          'answer': 'No. WEP is an aggregator platform. It connects you to partner organizations, banks, venture capitals, and government departments that offer loans and grants.'
        },
        {
          'question': 'Is there any fee to join WEP?',
          'answer': 'No, registering and accessing all primary resources on the Women Entrepreneurship Platform is completely free of charge.'
        }
      ],
    ),
    Scheme(
      id: 'TREAD',
      name: 'TREAD (Trade Related Entrepreneurship Assistance and Development)',
      category: 'Women & Child Welfare',
      sponsoringBody: 'Ministry of MSME, Government of India',
      overview: 'Empowers poor, illiterate, or marginalized women in both rural and urban areas by providing financial assistance (grants) and training via NGOs for trading and self-employment activities.',
      benefits: 'Government of India provides a grant up to 30% of the project cost through registered NGOs. The remaining 70% is sanctioned as a loan by lending banks to the NGO for disbursement to beneficiaries.',
      eligibilityCriteria: [
        'Group of women or individual women seeking self-employment.',
        'Applications must be routed through an active, registered Non-Governmental Organization (NGO).',
        'The NGO must have a proven track record of handling micro-credit and women development programs.',
      ],
      requiredDocuments: [
        'Aadhaar Cards of beneficiaries',
        'PAN Cards of beneficiaries',
        'NGO Registration Certificate & Audited Financial Statements for last 3 years',
        'Detailed Project Report (DPR) detailing the trade/business activity',
      ],
      applicationProcess: [
        'Approach a local qualified NGO working in your area.',
        'The NGO compiles the details of the women beneficiaries and drafts a consolidated project report.',
        'The NGO submits the project proposal to the MSME Development Institute or directly online.',
        'After approval, the government grants 30% and the bank lends 70% to the NGO, which then distributes the tools/capital to the women.'
      ],
      officialWebsite: 'https://msme.gov.in/',
      faqs: [
        {
          'question': 'Can I apply for TREAD directly as an individual to the bank?',
          'answer': 'No, TREAD requires applications to be routed through an eligible NGO. The NGO acts as the mediator and assumes loan repayment responsibility.'
        },
        {
          'question': 'What kind of activities are covered?',
          'answer': 'A wide range of trading, cottage industries, agriculture-allied activities, tailoring, handicrafts, retail shops, and other micro-businesses.'
        }
      ],
    ),
    Scheme(
      id: 'KALAIGNAR_KAIVINAI',
      name: 'Kalaignar Kaivinai Thittam',
      category: 'Artisan',
      sponsoringBody: 'Tamil Nadu Handicrafts Development Corporation (Poompuhar), Govt of TN',
      overview: 'Supports traditional artisans and handicraft workers in Tamil Nadu by distributing modern toolkits, providing skill training, and offering subsidized credit.',
      benefits: 'Free distribution of modern toolkits worth up to ₹10,000, welfare board registrations, marketing assistance in Poompuhar exhibitions, and small micro-credit assistance.',
      eligibilityCriteria: [
        'Must be an artisan residing in Tamil Nadu.',
        'Must possess a valid Artisan Identity Card issued by the Development Commissioner (Handicrafts), Ministry of Textiles, Government of India.',
        'Must be actively practicing a registered traditional craft (e.g. wood carving, bronze casting, stone carving, clay pottery, weaving).'
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Artisan Identity Card (DC Handicrafts)',
        'Nativity Certificate (TN)',
        'Community Certificate',
        'Bank Passbook Copy',
      ],
      applicationProcess: [
        'Submit a physical or online application to the nearest Poompuhar showroom, DIC, or District Handicrafts Officer.',
        'Attach copies of your Artisan Identity Card and residency proof.',
        'Handicrafts officers will visit your workshop/residence for verification.',
        'Approved artisans will be called for toolkits distribution or training workshops.'
      ],
      officialWebsite: 'https://www.tnhandicrafts-art.gov.in/',
      faqs: [
        {
          'question': 'How can I get the Artisan Identity Card?',
          'answer': 'You can apply for the Artisan Card online on the Ministry of Textiles portal (Pehchan portal) or visit the local office of the Development Commissioner for Handicrafts.'
        },
        {
          'question': 'Are there age restrictions under this scheme?',
          'answer': 'No, as long as the artisan is actively working and holds a valid Pehchan Artisan Card.'
        }
      ],
    ),
    Scheme(
      id: 'STARTUP_TN',
      name: 'StartupTN Support & TANSEED Grant',
      category: 'Startup',
      sponsoringBody: 'Tamil Nadu Startup and Innovation Mission (TANSIM), Govt of TN',
      overview: 'Provides seed funding, incubation support, and global mentorship to early-stage innovative startups registered and operating in Tamil Nadu.',
      benefits: 'TANSEED (Tamil Nadu Startup Seed Grant Fund) provides equity-free grant up to ₹15 Lakhs. Access to government procurement, co-working space subsidies, and acceleration bootcamps.',
      eligibilityCriteria: [
        'Startup must be registered in Tamil Nadu.',
        'Must hold a valid DPIIT Recognition Certificate.',
        'Must be registered on the StartupTN portal.',
        'Must have an innovative product, service, or business model with potential for scalability and employment generation.',
        'Must be less than 10 years old from the date of incorporation.'
      ],
      requiredDocuments: [
        'DPIIT Certificate of Recognition',
        'StartupTN Portal Registration Number',
        'Certificate of Incorporation (Pvt Ltd / LLP / Registered Partnership)',
        'Detailed Pitch Deck & Business Plan',
        'Company PAN Card',
        'Aadhaar Cards of all founding members',
      ],
      applicationProcess: [
        'Register your company on the StartupTN portal (startuptn.in) and obtain a registration ID.',
        'When a TANSEED application cycle opens, submit your application form, Pitch Deck, and DPIIT certificate.',
        'Undergo initial screening and pitching evaluations.',
        'Shortlisted startups pitch to the high-level committee for final approval of the grant.'
      ],
      officialWebsite: 'https://startuptn.in/',
      faqs: [
        {
          'question': 'Is TANSEED loan or equity-free grant?',
          'answer': 'TANSEED is a 100% equity-free grant, meaning the government does not take any stake or charge interest on the funding.'
        },
        {
          'question': 'Can a proprietorship firm apply?',
          'answer': 'No, the startup must be incorporated as a Private Limited Company, Limited Liability Partnership (LLP), or a Registered Partnership firm.'
        }
      ],
    ),
    Scheme(
      id: 'POST_MATRIC',
      name: 'Post Matric Scholarship Scheme',
      category: 'Education',
      sponsoringBody: 'Ministry of Minority Affairs / Dept of Higher Education, Govt of India',
      overview: 'Provides financial assistance to students belonging to SC, ST, OBC and Minority communities.',
      benefits: 'Up to ₹1,00,000',
      eligibilityCriteria: [
        'Must belong to SC, ST, OBC, or Minority communities.',
        'Must be studying in Class 11, 12, Diploma, Graduation, Post-Graduation, or PhD levels.',
        'Annual family income must be under ₹2.5 Lakhs.'
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Mark sheets',
        'Admission Letter',
        'Community Certificate',
        'Income Certificate',
        'Bank Passbook Copy'
      ],
      applicationProcess: [
        'Register on the National Scholarship Portal (NSP).',
        'Fill in the application form for Post Matric Scholarship.',
        'Upload required documents and submit for institute verification.',
        'After state/board verification, scholarship is disbursed directly to the bank account.'
      ],
      officialWebsite: 'https://scholarships.gov.in/',
      faqs: [
        {
          'question': 'Who can apply for this scheme?',
          'answer': 'Students belonging to SC, ST, OBC, and Minority communities who are studying in Class 11 up to PhD levels.'
        }
      ],
    ),
    Scheme(
      id: 'MERIT_MEANS',
      name: 'Merit cum Means Scholarship',
      category: 'Education',
      sponsoringBody: 'Ministry of Minority Affairs, Govt of India',
      overview: 'Supports meritorious students from economically weaker sections to pursue higher education.',
      benefits: 'Up to ₹20,000',
      eligibilityCriteria: [
        'Must be pursuing technical or professional courses at UG or PG level.',
        'Must have secured not less than 50% marks in the previous final examination.',
        'Annual family income from all sources must not exceed ₹2.5 Lakhs.'
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Income Certificate',
        'Community Certificate',
        'Previous Exam Marksheet',
        'Fee Receipt of Current Course'
      ],
      applicationProcess: [
        'Apply online through the National Scholarship Portal (NSP).',
        'Select the Merit cum Means Scholarship Scheme for Minority Communities.',
        'Submit the application and get it verified by the college.'
      ],
      officialWebsite: 'https://scholarships.gov.in/',
      faqs: [],
    ),
    Scheme(
      id: 'INSPIRE',
      name: 'Inspire Scholarship for Higher Education',
      category: 'Education',
      sponsoringBody: 'Department of Science & Technology (DST), Govt of India',
      overview: 'Scholarship for top 1% rank holders in Class 12 to pursue science studies at the UG level.',
      benefits: 'Up to ₹80,000',
      eligibilityCriteria: [
        'Must be between 17 and 22 years of age.',
        'Must be in the top 1% of successful candidates in Class 12 board examinations.',
        'Must be pursuing courses in Natural and Basic Sciences at BSc, BS, or Integrated MSc/MS level.'
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Class 12 Marksheet',
        'Eligibility/Advisory Note from Board',
        'Admission Certificate from College/University',
        'Recommendation Letter'
      ],
      applicationProcess: [
        'Register online on the INSPIRE web portal.',
        'Fill in the application form and upload scanned copies of required documents.',
        'Await validation and release of scholarship list by DST.'
      ],
      officialWebsite: 'https://online-inspire.gov.in/',
      faqs: [],
    ),
    Scheme(
      id: 'PRAGATI',
      name: 'AICTE Pragati Scholarship',
      category: 'Education',
      sponsoringBody: 'AICTE, Ministry of Education, Govt of India',
      overview: 'Empowers girl students to pursue technical education by providing financial support.',
      benefits: 'Up to ₹50,000',
      eligibilityCriteria: [
        'Must be a female student admitted to a technical degree or diploma course.',
        'Maximum two girl children per family are eligible.',
        'Annual family income must be less than ₹8 Lakhs.'
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Class 10 and 12 Marksheets',
        'Admission Letter from AICTE approved institution',
        'Income Certificate',
        'Declaration from Parents regarding number of girl children'
      ],
      applicationProcess: [
        'Apply online on the National Scholarship Portal (NSP).',
        'Select AICTE Pragati Scholarship Scheme (Degree/Diploma).',
        'Get verification done at the level of institute and AICTE.'
      ],
      officialWebsite: 'https://scholarships.gov.in/',
      faqs: [],
    ),
    Scheme(
      id: 'PM_SCHOLARSHIP',
      name: 'PM Scholarship Scheme',
      category: 'Education',
      sponsoringBody: 'Department of Higher Education, Govt of India',
      overview: 'Financial support for students to continue their education.',
      benefits: 'Scholarships up to ₹3,000 per month for undergraduate and postgraduate courses.',
      eligibilityCriteria: ['Must be a student enrolled in a recognized professional course.', 'Must have scored at least 60% in Class XII.'],
      requiredDocuments: ['Aadhaar Card', 'Mark sheets', 'Admission Letter', 'Bank Account details'],
      applicationProcess: ['Apply online on the National Scholarship Portal (NSP).', 'Submit certificates and verify with the educational institution.'],
      officialWebsite: 'https://scholarships.gov.in/',
      faqs: [
        {'question': 'What is the scholarship amount?', 'answer': '₹2,500/month for boys and ₹3,000/month for girls.'}
      ],
    ),
    Scheme(
      id: 'AYUSHMAN_BHARAT',
      name: 'Ayushman Bharat Yojana',
      category: 'Health',
      sponsoringBody: 'National Health Authority, Govt of India',
      overview: 'Health coverage up to ₹5 lakh for your family.',
      benefits: 'Cashless health insurance cover of up to ₹5,000,000 annually per family.',
      eligibilityCriteria: ['Must be listed in the SECC 2011 database.', 'No limit on family size.'],
      requiredDocuments: ['Aadhaar Card', 'Ration Card', 'Mobile Number'],
      applicationProcess: ['Check eligibility online or at PMJAY kiosks.', 'Get Ayushman Golden Card from nearest CSC.'],
      officialWebsite: 'https://pmjay.gov.in/',
      faqs: [
        {'question': 'Is it applicable in private hospitals?', 'answer': 'Yes, in all government and empanelled private hospitals.'}
      ],
    ),
    Scheme(
      id: 'PM_AWAS',
      name: 'PM Awas Yojana (Gramin)',
      category: 'Housing',
      sponsoringBody: 'Ministry of Rural Development, Govt of India',
      overview: 'Affordable housing for rural families.',
      benefits: 'Financial assistance of ₹1.2 Lakhs in plains and ₹1.3 Lakhs in hilly areas.',
      eligibilityCriteria: ['Must not own a brick house.', 'Must belong to Below Poverty Line (BPL) category.'],
      requiredDocuments: ['Aadhaar Card', 'BPL Card', 'Bank Passbook', 'Land ownership proof'],
      applicationProcess: ['Gram Sabha selects beneficiaries.', 'Register and apply through the AwaasSoft portal.'],
      officialWebsite: 'https://pmayg.nic.in/',
      faqs: [
        {'question': 'How is the payment received?', 'answer': 'Transferred directly to the bank account in 3 installments based on building progress.'}
      ],
    ),
    Scheme(
      id: 'PM_KISAN',
      name: 'PM Kisan Samman Nidhi',
      category: 'Agriculture',
      sponsoringBody: 'Ministry of Agriculture and Farmers Welfare, Govt of India',
      overview: 'Financial assistance for farmers.',
      benefits: 'Income support of ₹6,000 per year in three equal installments of ₹2,000 directly to bank accounts.',
      eligibilityCriteria: ['Must be a landholding farmer family.', 'Cultivable land must be in the name of the applicant.'],
      requiredDocuments: ['Aadhaar Card', 'Land holding documents', 'Bank Passbook'],
      applicationProcess: ['Register on PM-Kisan portal or through local CSCs.', 'Submit land and bank details for verification.'],
      officialWebsite: 'https://pmkisan.gov.in/',
      faqs: [
        {'question': 'Are institutional landowners eligible?', 'answer': 'No, institutional landowners and high income professionals are excluded.'}
      ],
    ),
    Scheme(
      id: 'SOIL_HEALTH',
      name: 'Soil Health Card Scheme',
      category: 'Agriculture',
      sponsoringBody: 'Ministry of Agriculture and Farmers Welfare, Govt of India',
      overview: 'Assists State Governments to issue Soil Health Cards to all farmers in the country.',
      benefits: 'Gives details of soil health, nutrient status, and dosage recommendations for fertilizer.',
      eligibilityCriteria: ['Open to all farmers holding cultivable land in India.'],
      requiredDocuments: ['Aadhaar Card', 'Land ownership records', 'Soil sample registration number'],
      applicationProcess: ['Submit soil sample to the nearest soil testing lab.', 'Receive Soil Health Card with suggestions.'],
      officialWebsite: 'https://soilhealth.dac.gov.in/',
      faqs: [
        {'question': 'How often is the card updated?', 'answer': 'The card is issued once every 3 years to monitor soil health changes.'}
      ],
    ),
    Scheme(
      id: 'BETI_BACHAO',
      name: 'Beti Bachao Beti Padhao',
      category: 'Women & Child Welfare',
      sponsoringBody: 'Ministry of Women and Child Development, Govt of India',
      overview: 'A campaign to generate awareness and improve the efficiency of welfare services intended for girls.',
      benefits: 'Ensures survival, protection, and education of girl child through financial savings incentives.',
      eligibilityCriteria: ['Open to all Indian families with a girl child.'],
      requiredDocuments: ['Birth Certificate of the girl child', 'Parent Aadhaar Card', 'Address Proof'],
      applicationProcess: ['Open a Sukanya Samriddhi account at a post office or bank.', 'Deposit savings and earn tax-free interest.'],
      officialWebsite: 'https://wcd.nic.in/bbbp-schemes',
      faqs: [
        {'question': 'What is Sukanya Samriddhi account?', 'answer': 'A savings scheme for girl children with high interest rates and tax exemptions.'}
      ],
    ),
    Scheme(
      id: 'STARTUP_INDIA',
      name: 'Startup India Initiative',
      category: 'Startup',
      sponsoringBody: 'Department for Promotion of Industry and Internal Trade, Govt of India',
      overview: 'Intended to build a strong ecosystem that is conducive for the growth of startup businesses.',
      benefits: 'Tax exemptions for 3 years, patent registration fee rebates up to 80%, and self-certification compliance.',
      eligibilityCriteria: ['Startup must be incorporated as Pvt Ltd, LLP or Registered Partnership.', 'Turnover must be under ₹100 Crores.'],
      requiredDocuments: ['Incorporation Certificate', 'Pitch deck / business concept write-up', 'DPIIT Recognition proof'],
      applicationProcess: ['Register on the Startup India portal.', 'Apply for DPIIT Recognition and tax benefits.'],
      officialWebsite: 'https://www.startupindia.gov.in/',
      faqs: [
        {'question': 'How long is DPIIT recognition valid?', 'answer': 'Up to 10 years from the date of incorporation.'}
      ],
    ),
    Scheme(
      id: 'JAL_JEEVAN',
      name: 'Jal Jeevan Mission',
      category: 'Infrastructure',
      sponsoringBody: 'Ministry of Jal Shakti, Govt of India',
      overview: 'Providing safe and clean drinking water to every rural household.',
      benefits: 'Ensures supply of 55 litres of water per person per day to every rural household.',
      eligibilityCriteria: ['Rural household currently lacking a functional tap water connection.'],
      requiredDocuments: ['Aadhaar Card', 'Ration Card', 'House ownership proof / address proof'],
      applicationProcess: ['Submit request through local Gram Panchayat.', 'Water connection will be installed by department.'],
      officialWebsite: 'https://jaljeevanmission.gov.in/',
      faqs: [
        {'question': 'Who maintains the water supply?', 'answer': 'The local Village Water and Sanitation Committee (VWSC) or Gram Panchayat.'}
      ],
    ),
    Scheme(
      id: 'PM_VISHWAKARMA',
      name: 'PM Vishwakarma Yojana',
      category: 'Artisan',
      sponsoringBody: 'Ministry of Micro, Small and Medium Enterprises, Govt of India',
      overview: 'Empowering traditional artisans and craftspeople with skill training and financial support.',
      benefits: 'Skill training stipend, toolkit incentive of ₹15,000, and credit support up to ₹3 Lakhs at 5% interest.',
      eligibilityCriteria: ['Must be an artisan or craftsperson working in one of 18 specified traditional trades.', 'Minimum age of 18 years.'],
      requiredDocuments: ['Aadhaar Card', 'Artisan registration certificate', 'Bank Account details', 'Mobile Number'],
      applicationProcess: ['Register on the PM Vishwakarma portal.', 'Submit for verification through three stages (Gram Panchayat, District, State).'],
      officialWebsite: 'https://pmvishwakarma.gov.in/',
      faqs: [
        {'question': 'What are the 18 trades covered?', 'answer': 'Carpenter, Boat Maker, Blacksmith, Potter, Sculptor, Cobbler, Tailor, Weaver, and others.'}
      ],
    ),
    Scheme(
      id: 'PM_SURYA_GHAR',
      name: 'PM Surya Ghar Yojana',
      category: 'Energy',
      sponsoringBody: 'Ministry of New and Renewable Energy, Govt of India',
      overview: 'Get subsidy for installing solar rooftop systems at your home.',
      benefits: 'Subsidy up to ₹78,000 for installing solar panels up to 3kW, and free solar power up to 300 units monthly.',
      eligibilityCriteria: ['Must be an owner of a residential house with suitable roof space.', 'Must have an active electricity connection.'],
      requiredDocuments: ['Electricity bill', 'Roof space availability proof', 'Aadhaar Card', 'Bank account details'],
      applicationProcess: ['Register on the National Portal for Rooftop Solar.', 'Apply for feasibility and install panels through a registered vendor.', 'Apply for subsidy release after inspection.'],
      officialWebsite: 'https://pmsuryaghar.gov.in/',
      faqs: [
        {'question': 'What is the lifetime of solar panels?', 'answer': 'Typically 25 years with minimum maintenance.'}
      ],
    ),
    Scheme(
      id: 'NSP_PORTAL',
      name: 'National Scholarship Portal (NSP)',
      category: 'Education',
      sponsoringBody: 'Ministry of Electronics and Information Technology, Govt of India',
      overview: 'A one-stop solution through which various services starting from student application receipt, processing, sanction and disbursal of various scholarships to students are enabled.',
      benefits: 'Simplifies access to multiple central and state government scholarships.',
      eligibilityCriteria: ['Indian students studying at any recognized institution.', 'Must fulfill specific scholarship criteria.'],
      requiredDocuments: ['Aadhaar Card', 'Educational Certificates', 'Bank details'],
      applicationProcess: ['Register on the NSP portal.', 'Apply for matching scholarships.'],
      officialWebsite: 'https://scholarships.gov.in/',
      faqs: [],
    ),
    Scheme(
      id: 'PM_EDRIVE',
      name: 'PM E-DRIVE Scheme',
      category: 'Transport',
      sponsoringBody: 'Ministry of Heavy Industries, Govt of India',
      overview: 'Promotes electric vehicle adoption and infrastructure setup across India.',
      benefits: 'Subsidies and incentives for EV buyers and charging stations.',
      eligibilityCriteria: ['Individual buying an electric vehicle.', 'Charging station developers.'],
      requiredDocuments: ['Aadhaar Card', 'EV Purchase Invoice', 'RC Book'],
      applicationProcess: ['Buy EV from authorized dealer.', 'Dealer applies for subsidy on government portal.'],
      officialWebsite: 'https://heavyindustries.gov.in/',
      faqs: [],
    ),
    Scheme(
      id: 'PM_MATRU_VANDANA',
      name: 'Pradhan Mantri Matru Vandana Yojana',
      category: 'Women & Child Welfare',
      sponsoringBody: 'Ministry of Women and Child Development, Govt of India',
      overview: 'Provides financial support to pregnant women and lactating mothers.',
      benefits: '₹5,000 per installment',
      eligibilityCriteria: ['Must be a pregnant or lactating mother.', 'First-time mothers get priority.'],
      requiredDocuments: ['Aadhaar Card', 'Mother & Child Protection Card', 'Bank Passbook'],
      applicationProcess: ['Register at the local Anganwadi centre.', 'Submit form and documents for verification.'],
      officialWebsite: 'https://wcd.nic.in/',
      faqs: [],
    ),
  ];
}
