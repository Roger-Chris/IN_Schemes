import openpyxl
import uuid
import sys
import os

# Set encoding to UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# Helper function to generate clean UUIDs
def make_uuid(name_seed):
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, f"inschemes.{name_seed}"))

# 35 Schemes data definition
schemes_list = [
    {
        "id": "TN_NEEDS_001",
        "uuid": make_uuid("TN_NEEDS_001"),
        "name": "NEEDS (New Entrepreneur cum Enterprise Development Scheme)",
        "short_name": "NEEDS",
        "gov_level": "State",
        "state": "Tamil Nadu",
        "department": "Department of MSME",
        "agency": "District Industries Centre (DIC)",
        "category": "Business & MSME",
        "subcategory": "First Generation Entrepreneur",
        "beneficiaries": "Entrepreneurs, Unemployed, Women, SC/ST, Minorities",
        "stage": "Idea, Startup",
        "sector": "Manufacturing, Services",
        "special_groups": "Women, SC/ST, BC, MBC, Minorities, Ex-servicemen, Transgenders, Differently-abled",
        "objective": "Promote first-generation entrepreneurs by providing financial assistance, subsidies, and EDP training in Tamil Nadu.",
        "description": "Financial assistance program for educated youth to set up manufacturing or service ventures in Tamil Nadu.",
        "summary": "25% project cost subsidy (up to ₹75 Lakhs) for projects ranging from ₹10 Lakhs to ₹5 Crores.",
        "benefits_summary": "Subsidy, interest subvention, and EDP training course.",
        "assistance_type": "Subsidy + Loan",
        "min_assistance": 1000000.0,
        "max_assistance": 50000000.0,
        "subsidy_pct": 25.0,
        "interest_subsidy": 3.0,
        "margin_money": 10.0,
        "app_mode": "Online",
        "website": "https://www.msmeonline.tn.gov.in/needs/",
        "apply_url": "https://www.msmeonline.tn.gov.in/needs/needs_app.php",
        "keywords": "needs, tamil nadu, chennai, startup loan, first generation, entrepreneur, subsidy, interest subvention, dic",
        "tags": "Tamil Nadu, State Scheme, Subsidy, MSME",
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "21", "label": "Applicant must be 21 or older"},
            {"parameter": "applicant_age", "operator": "<=", "value": "45", "label": "Applicant must be under 45 (for special category)"},
            {"parameter": "nativity", "operator": "=", "value": "Tamil Nadu", "label": "Applicant must be a resident of Tamil Nadu"},
            {"parameter": "qualification", "operator": "IN", "value": "Degree, Diploma, ITI", "label": "Applicant must hold a degree, diploma, or ITI"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "Degree/Diploma Certificate", "Nativity Certificate (TN)", 
            "Community Certificate", "Project Report / Business Plan", "Quotations for machinery/equipment",
            "Passport Size Photograph", "Address Proof"
        ],
        "benefits": [
            {"type": "Subsidy", "value": "25%", "desc": "Capital subsidy of 25% of project cost up to ₹75 Lakhs"},
            {"type": "Interest Subsidy", "value": "3%", "desc": "3% interest subvention for the entire repayment period"},
        ],
        "faqs": [
            {"q": "Can I apply if my project cost is ₹8 Lakhs?", "a": "No, the minimum project cost required for NEEDS is ₹10 Lakhs."},
            {"q": "Is there an income ceiling?", "a": "No, there is no family income ceiling under the NEEDS scheme."},
        ],
        "contacts": [
            {"office": "District Industries Centre, Guindy", "district": "Chennai", "phone": "044-22501461", "email": "dicchennai@tn.gov.in"}
        ]
    },
    {
        "id": "IN_PMEGP_001",
        "uuid": make_uuid("IN_PMEGP_001"),
        "name": "PMEGP (Prime Minister's Employment Generation Programme)",
        "short_name": "PMEGP",
        "gov_level": "Central",
        "state": "All India",
        "department": "Ministry of MSME",
        "agency": "KVIC, KVIB, DIC",
        "category": "Business & MSME",
        "subcategory": "Self Employment",
        "beneficiaries": "Entrepreneurs, Individuals, Women, SC/ST, OBC, Rural",
        "stage": "Idea, Startup",
        "sector": "Manufacturing, Services",
        "special_groups": "Women, SC/ST, OBC, Minorities, Ex-servicemen, North East, Hilly Areas",
        "objective": "Generate continuous self-employment opportunities in rural and urban areas by setting up new micro enterprises.",
        "description": "Credit-linked subsidy scheme by the Government of India for launching manufacturing or service micro businesses.",
        "summary": "Subsidy of 15% to 35% of the project cost. Maximum project cost is ₹50 Lakhs for Manufacturing.",
        "benefits_summary": "15-35% subsidy on project capital, collateral-free credit access.",
        "assistance_type": "Subsidy + Loan",
        "min_assistance": 500000.0,
        "max_assistance": 5000000.0,
        "subsidy_pct": 35.0,
        "interest_subsidy": 0.0,
        "margin_money": 10.0,
        "app_mode": "Online",
        "website": "https://www.kviconline.gov.in/pmegpeportal/",
        "apply_url": "https://www.kviconline.gov.in/pmegpeportal/pmegphome/index.jsp",
        "keywords": "pmegp, kvic, central scheme, loan, manufacturing, rural, urban, subsidy, self employment",
        "tags": "Central Scheme, Subsidy, MSME, Loan",
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "18", "label": "Applicant must be at least 18 years old"},
            {"parameter": "qualification", "operator": "IN", "value": "Standard VIII, Standard X, Degree", "label": "Must have passed VIII Standard for projects above ₹10 Lakhs"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "VIII Standard Pass Certificate", "Community Certificate", 
            "Project Report / Business Plan", "Rural Area Certificate", "Passport Size Photograph"
        ],
        "benefits": [
            {"type": "Subsidy", "value": "35%", "desc": "Up to 35% subsidy in rural areas for special categories"},
            {"type": "Subsidy", "value": "25%", "desc": "Up to 25% subsidy in urban areas for special categories"},
        ],
        "faqs": [
            {"q": "Is there any family income limit?", "a": "No, there is no family income limit under PMEGP."},
            {"q": "Can I expand my existing shop under PMEGP?", "a": "No, the scheme is strictly for establishing new micro enterprises."},
        ],
        "contacts": [
            {"office": "KVIC State Office", "district": "Chennai", "phone": "044-25220668", "email": "so.chennai@kvic.gov.in"}
        ]
    },
    {
        "id": "IN_CGTMSE_001",
        "uuid": make_uuid("IN_CGTMSE_001"),
        "name": "CGTMSE (Credit Guarantee Fund Trust for Micro and Small Enterprises)",
        "short_name": "CGTMSE",
        "gov_level": "Central",
        "state": "All India",
        "department": "Ministry of MSME",
        "agency": "CGTMSE Trust, Member Lending Institutions",
        "category": "Business & MSME",
        "subcategory": "Credit Guarantee",
        "beneficiaries": "MSMEs, Existing Businesses, Startups",
        "stage": "Startup, Existing",
        "sector": "Manufacturing, Services, Retail",
        "special_groups": "Women, SC/ST, Hilly region entrepreneurs",
        "objective": "Provide credit guarantees to financial institutions for extending collateral-free loans to micro and small enterprises.",
        "description": "Collateral-free credit guarantee system facilitating up to ₹5 Crore funding for MSEs.",
        "summary": "Credit guarantee coverage up to 85% of the loan amount for loans up to ₹5 Crores.",
        "benefits_summary": "Collateral-free credit guarantee coverage.",
        "assistance_type": "Credit Guarantee",
        "min_assistance": 100000.0,
        "max_assistance": 50000000.0,
        "subsidy_pct": 0.0,
        "interest_subsidy": 0.0,
        "margin_money": 0.0,
        "app_mode": "Through Banks",
        "website": "https://www.cgtmse.in/",
        "apply_url": "https://www.cgtmse.in/list-of-mlis.html",
        "keywords": "cgtmse, credit guarantee, collateral free loan, msme loan, sidbi, central scheme, startup loan",
        "tags": "Central Scheme, Guarantee, MSME, Loan",
        "rules": [
            {"parameter": "business_type", "operator": "IN", "value": "Micro, Small", "label": "Enterprise must fall under Micro or Small categories"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "UDYAM Registration Certificate", "GST Registration Certificate",
            "Project Report / Business Plan", "IT Returns (if existing)", "Bank Statement"
        ],
        "benefits": [
            {"type": "Guarantee", "value": "85%", "desc": "Guarantee coverage up to 85% for loans up to ₹5 Lakhs"},
            {"type": "Guarantee", "value": "75%", "desc": "Guarantee coverage of 75% for loans up to ₹5 Crores"},
        ],
        "faqs": [
            {"q": "Do I need to submit collateral?", "a": "No, CGTMSE covers the credit guarantee without collateral requirement."},
        ],
        "contacts": [
            {"office": "CGTMSE SIDBI Office", "district": "Mumbai", "phone": "022-67531100", "email": "cgtmse@sidbi.in"}
        ]
    },
    {
        "id": "IN_MUDRA_S_001",
        "uuid": make_uuid("IN_MUDRA_S_001"),
        "name": "Pradhan Mantri MUDRA Yojana - Shishu Loan",
        "short_name": "MUDRA Shishu",
        "gov_level": "Central",
        "state": "All India",
        "department": "Department of Financial Services",
        "agency": "MUDRA Ltd., All Banks, NBFCs",
        "category": "Business & MSME",
        "subcategory": "Micro Credit",
        "beneficiaries": "Individuals, Shopkeepers, Artisans, Small Traders",
        "stage": "Idea, Startup",
        "sector": "Retail, Services, Agriculture Allied",
        "special_groups": "Women, SC/ST, OBC, Minorities",
        "objective": "Provide collateral-free micro loans up to ₹50,000 to tiny and micro business start-ups.",
        "description": "First-tier micro financing program under Mudra targeting budding micro-enterprises and small traders.",
        "summary": "Loans up to ₹50,000 for setting up or promoting small shops and services.",
        "benefits_summary": "Collateral-free micro finance up to ₹50,000, low interest rates.",
        "assistance_type": "Loan",
        "min_assistance": 5000.0,
        "max_assistance": 50000.0,
        "subsidy_pct": 0.0,
        "interest_subsidy": 2.0,
        "margin_money": 0.0,
        "app_mode": "Through Banks / Online",
        "website": "https://www.mudra.org.in/",
        "apply_url": "https://www.udyamimitra.in/",
        "keywords": "mudra, shishu, loan, micro credit, central scheme, shop loan, women loan, micro business",
        "tags": "Central Scheme, Loan, MSME",
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "18", "label": "Applicant must be 18 or older"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "Address Proof", "Identity Proof", "Business Address Proof",
            "Passport Size Photograph", "Bank Passbook Copy"
        ],
        "benefits": [
            {"type": "Loan", "value": "₹50,000", "desc": "Micro funding up to ₹50,000 without collateral"},
        ],
        "faqs": [
            {"q": "What is the interest rate?", "a": "Interest rates vary by bank, but generally range between 9% and 12% per annum."},
        ],
        "contacts": [
            {"office": "Mudra Helpdesk", "district": "New Delhi", "phone": "1800-180-1111", "email": "help@mudra.org.in"}
        ]
    },
    {
        "id": "IN_MUDRA_K_001",
        "uuid": make_uuid("IN_MUDRA_K_001"),
        "name": "Pradhan Mantri MUDRA Yojana - Kishor Loan",
        "short_name": "MUDRA Kishor",
        "gov_level": "Central",
        "state": "All India",
        "department": "Department of Financial Services",
        "agency": "MUDRA Ltd., All Banks, NBFCs",
        "category": "Business & MSME",
        "subcategory": "Micro Credit",
        "beneficiaries": "Entrepreneurs, Retailers, Small Manufacturers",
        "stage": "Startup, Existing",
        "sector": "Manufacturing, Services, Retail",
        "special_groups": "Women, SC/ST, OBC, Minorities",
        "objective": "Provide collateral-free micro loans from ₹50,000 up to ₹5 Lakhs for expanding micro businesses.",
        "description": "Mid-tier micro financing program under Mudra targeting established micro-ventures looking for expansion funding.",
        "summary": "Loans between ₹50,000 and ₹5 Lakhs for machinery and capital expenditures.",
        "benefits_summary": "Collateral-free credit, working capital assistance up to ₹5 Lakhs.",
        "assistance_type": "Loan",
        "min_assistance": 50000.0,
        "max_assistance": 500000.0,
        "subsidy_pct": 0.0,
        "interest_subsidy": 0.0,
        "margin_money": 10.0,
        "app_mode": "Through Banks / Online",
        "website": "https://www.mudra.org.in/",
        "apply_url": "https://www.udyamimitra.in/",
        "keywords": "mudra, kishor, loan, startup, central scheme, business loan, working capital, expansion",
        "tags": "Central Scheme, Loan, MSME",
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "18", "label": "Applicant must be 18 or older"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "UDYAM Registration Certificate", "GST Registration Certificate",
            "Identity Proof", "Address Proof", "Quotations for machinery", "Bank Statements (last 6 months)"
        ],
        "benefits": [
            {"type": "Loan", "value": "₹5 Lakhs", "desc": "Loan facility between ₹50,000 and ₹5 Lakhs"},
        ],
        "faqs": [
            {"q": "Is collateral needed?", "a": "No, Mudra Kishor loans are collateral-free."},
        ],
        "contacts": [
            {"office": "Mudra Helpdesk", "district": "New Delhi", "phone": "1800-180-1111", "email": "help@mudra.org.in"}
        ]
    },
    {
        "id": "IN_MUDRA_T_001",
        "uuid": make_uuid("IN_MUDRA_T_001"),
        "name": "Pradhan Mantri MUDRA Yojana - Tarun Loan",
        "short_name": "MUDRA Tarun",
        "gov_level": "Central",
        "state": "All India",
        "department": "Department of Financial Services",
        "agency": "MUDRA Ltd., All Banks, NBFCs",
        "category": "Business & MSME",
        "subcategory": "Micro Credit",
        "beneficiaries": "Entrepreneurs, Small Industrialists, Service Providers",
        "stage": "Existing",
        "sector": "Manufacturing, Services, Retail",
        "special_groups": "Women, SC/ST, OBC, Minorities",
        "objective": "Provide collateral-free micro loans from ₹5 Lakhs up to ₹10 Lakhs for established enterprises.",
        "description": "High-tier micro financing program under Mudra targeting established micro-enterprises requiring substantial expansion capital.",
        "summary": "Loans between ₹5 Lakhs and ₹10 Lakhs for expansion and growth.",
        "benefits_summary": "Collateral-free credit facility up to ₹10 Lakhs.",
        "assistance_type": "Loan",
        "min_assistance": 500000.0,
        "max_assistance": 1000000.0,
        "subsidy_pct": 0.0,
        "interest_subsidy": 0.0,
        "margin_money": 15.0,
        "app_mode": "Through Banks / Online",
        "website": "https://www.mudra.org.in/",
        "apply_url": "https://www.udyamimitra.in/",
        "keywords": "mudra, tarun, loan, expansion, central scheme, msme loan, credit, machinery loan",
        "tags": "Central Scheme, Loan, MSME",
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "18", "label": "Applicant must be 18 or older"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "UDYAM Registration Certificate", "GST Registration Certificate",
            "Address Proof", "Audited Financials (last 2 years)", "Income Tax Returns", "Bank Statements (last 12 months)"
        ],
        "benefits": [
            {"type": "Loan", "value": "₹10 Lakhs", "desc": "Loan facility between ₹5 Lakhs and ₹10 Lakhs"},
        ],
        "faqs": [
            {"q": "Can I buy a vehicle under this?", "a": "Yes, commercial vehicles used for business can be funded under Mudra Tarun."},
        ],
        "contacts": [
            {"office": "Mudra Helpdesk", "district": "New Delhi", "phone": "1800-180-1111", "email": "help@mudra.org.in"}
        ]
    },
    {
        "id": "IN_STANDUP_001",
        "uuid": make_uuid("IN_STANDUP_001"),
        "name": "Stand Up India Scheme",
        "short_name": "Stand Up India",
        "gov_level": "Central",
        "state": "All India",
        "department": "Department of Financial Services",
        "agency": "SIDBI, National Credit Guarantee Trustee Company (NCGTC), Member Banks",
        "category": "Women & Minorities",
        "subcategory": "Greenfield Venture",
        "beneficiaries": "Women, SC/ST, Entrepreneurs",
        "stage": "Startup",
        "sector": "Manufacturing, Services, Agriculture Allied, Trading",
        "special_groups": "Women, SC, ST",
        "objective": "Promote entrepreneurship among women and SC/ST communities by facilitating greenfield loans.",
        "description": "Government loan program targeting women and SC/ST applicants for establishing their first business venture.",
        "summary": "Loans between ₹10 Lakhs and ₹1 Crore for setting up new greenfield enterprises.",
        "benefits_summary": "Low interest rate loans up to ₹1 Crore, credit guarantee support.",
        "assistance_type": "Loan",
        "min_assistance": 1000000.0,
        "max_assistance": 10000000.0,
        "subsidy_pct": 0.0,
        "interest_subsidy": 0.0,
        "margin_money": 15.0,
        "app_mode": "Through Banks / Online",
        "website": "https://www.standupmitra.in/",
        "apply_url": "https://www.standupmitra.in/Home/RegisterApplicant",
        "keywords": "standup india, women loan, sc/st loan, greenfield loan, startup india, central scheme, sidbi",
        "tags": "Central Scheme, Loan, Women, Startup",
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "18", "label": "Applicant must be 18 or older"},
            {"parameter": "special_group", "operator": "IN", "value": "SC, ST, Women", "label": "Applicant must belong to SC/ST or be a Woman"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "Community / Caste Certificate (SC/ST)", "Identity Proof",
            "Project Report / Business Plan", "Address Proof", "Land ownership proof / lease agreement",
            "Passport Size Photograph", "Bank statement"
        ],
        "benefits": [
            {"type": "Loan", "value": "₹1 Crore", "desc": "Loan facility between ₹10 Lakhs and ₹1 Crore"},
        ],
        "faqs": [
            {"q": "What is a greenfield project?", "a": "A project that is a new venture in manufacturing, services, or trading sectors."},
        ],
        "contacts": [
            {"office": "Standup India Helpdesk", "district": "New Delhi", "phone": "1800-11-2424", "email": "support@standupmitra.in"}
        ]
    },
    {
        "id": "IN_STARTUP_SEED_001",
        "uuid": make_uuid("IN_STARTUP_SEED_001"),
        "name": "Startup India Seed Fund Scheme (SISFS)",
        "short_name": "Startup Seed",
        "gov_level": "Central",
        "state": "All India",
        "department": "Department for Promotion of Industry and Internal Trade (DPIIT)",
        "agency": "DPIIT, Approved Incubators",
        "category": "Startups & Technology",
        "subcategory": "Seed Funding",
        "beneficiaries": "Startups, Tech Entrepreneurs",
        "stage": "Idea, Startup",
        "sector": "Technology, Healthcare, Agriculture, Education, Waste Management, Clean Energy",
        "special_groups": "None",
        "objective": "Provide financial assistance to startups for proof of concept, prototype development, product trials, and market entry.",
        "description": "Seed funding program for early-stage startups in technology and social impact sectors.",
        "summary": "Grants up to ₹20 Lakhs for prototype development and up to ₹50 Lakhs for market entry.",
        "benefits_summary": "Up to ₹50 Lakhs seed funding through incubator channels.",
        "assistance_type": "Grant / Debt",
        "min_assistance": 500000.0,
        "max_assistance": 5000000.0,
        "subsidy_pct": 100.0,
        "interest_subsidy": 0.0,
        "margin_money": 0.0,
        "app_mode": "Online",
        "website": "https://seedfund.startupindia.gov.in/",
        "apply_url": "https://seedfund.startupindia.gov.in/startup/register",
        "keywords": "startup india, sisfs, seed fund, grant, prototype grant, angel investment, tech startup, dpiit",
        "tags": "Central Scheme, Grant, Startup, Technology",
        "rules": [
            {"parameter": "dpiit_recognition", "operator": "=", "value": "Yes", "label": "Startup must be recognized by DPIIT"},
            {"parameter": "incorporation_age", "operator": "<=", "value": "2", "label": "Startup must be incorporated within the last 2 years"},
        ],
        "documents": [
            "DPIIT Recognition Certificate", "Certificate of Incorporation", "PAN of Startup", "Aadhaar of Directors",
            "Project Proposal / Pitch Deck", "Pitch Video / Prototype Link", "Financial Statements (if any)"
        ],
        "benefits": [
            {"type": "Grant", "value": "₹20 Lakhs", "desc": "Up to ₹20 Lakhs grant for proof of concept and prototype development"},
            {"type": "Debt", "value": "₹50 Lakhs", "desc": "Up to ₹50 Lakhs debt or convertible debenture for market entry and scaleup"},
        ],
        "faqs": [
            {"q": "Can I apply directly to the government?", "a": "No, startups apply online and choose up to 3 approved incubators for evaluation."},
        ],
        "contacts": [
            {"office": "Startup India Support", "district": "New Delhi", "phone": "1800-115-565", "email": "dipp-startups@nic.in"}
        ]
    },
    {
        "id": "TN_UYEGP_001",
        "uuid": make_uuid("TN_UYEGP_001"),
        "name": "UYEGP (Unemployed Youth Employment Generation Programme)",
        "short_name": "UYEGP",
        "gov_level": "State",
        "state": "Tamil Nadu",
        "department": "Department of MSME",
        "agency": "District Industries Centre (DIC), State Banks",
        "category": "Business & MSME",
        "subcategory": "Unemployed Youth",
        "beneficiaries": "Individuals, Unemployed Youth, Women, SC/ST",
        "stage": "Idea, Startup",
        "sector": "Manufacturing, Services, Trading",
        "special_groups": "Women, SC/ST, BC, MBC, Minorities, Differently-abled",
        "objective": "Mitigate the unemployment problems of socially and economically backward sections of youth in Tamil Nadu.",
        "description": "Self-employment generation program offering subsidies for micro business setups in Tamil Nadu.",
        "summary": "Subsidy of 25% of the project cost. Maximum project cost is ₹15 Lakhs for Manufacturing.",
        "benefits_summary": "25% capital subsidy, bank credit linkage.",
        "assistance_type": "Subsidy + Loan",
        "min_assistance": 100000.0,
        "max_assistance": 1500000.0,
        "subsidy_pct": 25.0,
        "interest_subsidy": 0.0,
        "margin_money": 10.0,
        "app_mode": "Online",
        "website": "https://www.msmeonline.tn.gov.in/uyegp/",
        "apply_url": "https://www.msmeonline.tn.gov.in/uyegp/uyegp_app.php",
        "keywords": "uyegp, unemployed, youth loan, tamil nadu, subsidy, micro business, trading loan, dic",
        "tags": "Tamil Nadu, State Scheme, Subsidy, MSME",
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "18", "label": "Applicant must be 18 or older"},
            {"parameter": "applicant_age", "operator": "<=", "value": "45", "label": "Applicant must be under 45 (for special category)"},
            {"parameter": "nativity", "operator": "=", "value": "Tamil Nadu", "label": "Applicant must be a resident of Tamil Nadu"},
            {"parameter": "family_income", "operator": "<=", "value": "500000", "label": "Annual family income must not exceed ₹5 Lakhs"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "School Transfer Certificate / Pass Certificate", "Nativity Certificate (TN)",
            "Community Certificate", "Income Certificate (revenue authority)", "Project Report / Business Plan",
            "Quotations for machinery/assets", "Passport size photo"
        ],
        "benefits": [
            {"type": "Subsidy", "value": "25%", "desc": "Capital subsidy of 25% of project cost (up to ₹3.75 Lakhs)"},
        ],
        "faqs": [
            {"q": "What is the educational qualification?", "a": "Must have passed VIII Standard or above."},
        ],
        "contacts": [
            {"office": "District Industries Centre, Guindy", "district": "Chennai", "phone": "044-22501461", "email": "dicchennai@tn.gov.in"}
        ]
    },
    {
        "id": "IN_TREAD_001",
        "uuid": make_uuid("IN_TREAD_001"),
        "name": "TREAD (Trade Related Entrepreneurship Assistance and Development) for Women",
        "short_name": "TREAD",
        "gov_level": "Central",
        "state": "All India",
        "department": "Ministry of MSME",
        "agency": "Ministry of MSME, Registered NGOs",
        "category": "Women & Minorities",
        "subcategory": "Women Empowerment",
        "beneficiaries": "Women, SHGs, Rural Women",
        "stage": "Idea, Startup, Existing",
        "sector": "Retail, Handicrafts, Services, Agriculture Allied",
        "special_groups": "Women",
        "objective": "Empower illiterate or semi-literate women in rural and urban areas by providing credit and training through NGOs.",
        "description": "Central government grant and loan scheme assisting groups of women in trading and allied industries.",
        "summary": "Government grant up to 30% of the project cost; remainder provided as loan by financial institutions through NGOs.",
        "benefits_summary": "30% government grant for project expenditures, training assistance.",
        "assistance_type": "Grant + Loan",
        "min_assistance": 50000.0,
        "max_assistance": 5000000.0,
        "subsidy_pct": 30.0,
        "interest_subsidy": 0.0,
        "margin_money": 0.0,
        "app_mode": "Through NGOs",
        "website": "https://msme.gov.in/",
        "apply_url": "https://msme.gov.in/trade-related-entrepreneurship-assistance-and-development-tread-scheme-women",
        "keywords": "tread, women entrepreneurs, rural women, grant for women, ngo funding, self help group, shg, central scheme",
        "tags": "Central Scheme, Grant, Women, SHG",
        "rules": [
            {"parameter": "gender", "operator": "=", "value": "Female", "label": "Applicant must be Female or a women's self help group"},
        ],
        "documents": [
            "Aadhaar of Members", "PAN of NGO / Members", "NGO Registration Certificate", "Project Report",
            "Audit reports of NGO (last 3 years)", "Bank Account Details", "Resolution copy from SHG"
        ],
        "benefits": [
            {"type": "Grant", "value": "30%", "desc": "Government grant up to 30% of the project cost for women entrepreneurs group"},
            {"type": "Training", "value": "100%", "desc": "Government grant for training and mentorship program"},
        ],
        "faqs": [
            {"q": "Can an individual woman apply directly?", "a": "No, the scheme is routed through registered NGOs who apply on behalf of groups of women."},
        ],
        "contacts": [
            {"office": "Development Commissioner (MSME)", "district": "New Delhi", "phone": "011-23063800", "email": "dcmsme@nic.in"}
        ]
    },
    {
        "id": "IN_ACABC_001",
        "uuid": make_uuid("IN_ACABC_001"),
        "name": "Agri-Clinics and Agri-Business Centres Scheme (ACABC)",
        "short_name": "ACABC",
        "gov_level": "Central",
        "state": "All India",
        "department": "Ministry of Agriculture and Farmers Welfare",
        "agency": "NABARD, MANAGE (National Institute of Agricultural Extension Management)",
        "category": "Agriculture & Farmers",
        "subcategory": "Agri Business",
        "beneficiaries": "Farmers, Agriculture Graduates, Unemployed Youth",
        "stage": "Idea, Startup",
        "sector": "Agriculture, Horticulture, Dairy, Animal Husbandry",
        "special_groups": "Women, SC/ST, North East, Hilly region applicants",
        "objective": "Promote agricultural extension services and self-employment ventures by trained agriculture graduates.",
        "description": "Subsidy program for setting up farm extension, diagnostic, and commercial agri-business hubs.",
        "summary": "Subsidy of 36% (General category) to 44% (Women & SC/ST) of the project cost up to ₹20 Lakhs.",
        "benefits_summary": "36-44% subsidy on project capital, free extension training.",
        "assistance_type": "Subsidy + Loan",
        "min_assistance": 200000.0,
        "max_assistance": 2000000.0,
        "subsidy_pct": 44.0,
        "interest_subsidy": 0.0,
        "margin_money": 10.0,
        "app_mode": "Online",
        "website": "https://www.agriclinics.net/",
        "apply_url": "https://www.agriclinics.net/acabc-apply.html",
        "keywords": "acabc, agri clinic, agri business, nabard loan, agriculture subsidy, agro startup, veterinary clinics, seed supply",
        "tags": "Central Scheme, Subsidy, Farmers, Agriculture",
        "rules": [
            {"parameter": "qualification", "operator": "IN", "value": "Agri Graduate, Agri Diploma, Science Graduate", "label": "Applicant must hold an agricultural or allied sciences degree/diploma"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "Agriculture Degree / Diploma Certificate", "MANAGE training completion certificate",
            "Project Report / Business Plan", "Nativity Certificate", "Bank Account Details", "Land ownership proof (if any)"
        ],
        "benefits": [
            {"type": "Subsidy", "value": "44%", "desc": "Subsidy for Women and SC/ST category applicants (up to ₹8.8 Lakhs)"},
            {"type": "Subsidy", "value": "36%", "desc": "Subsidy for General category applicants (up to ₹7.2 Lakhs)"},
        ],
        "faqs": [
            {"q": "Is training mandatory?", "a": "Yes, applicants must complete a 45-day training program conducted by MANAGE nodal centers."},
        ],
        "contacts": [
            {"office": "NABARD State Office", "district": "Chennai", "phone": "044-28276063", "email": "chennai@nabard.org"}
        ]
    }
]

# Generate more mock schemes to reach 35
for i in range(12, 36):
    is_state = (i % 3 == 0)
    state_name = "Tamil Nadu" if is_state else "All India"
    gov_lvl = "State" if is_state else "Central"
    
    # Cycle categories
    categories = ["Agriculture & Farmers", "Startups & Technology", "Business & MSME", "Women & Minorities", "Students & Education"]
    cat = categories[i % len(categories)]
    
    sid = f"{'TN' if is_state else 'IN'}_MOCK_SCHEME_{i:03d}"
    suuid = make_uuid(sid)
    
    tags = f"{state_name}, {gov_lvl} Scheme"
    if i % 2 == 0:
        tags += ", Loan"
    else:
        tags += ", Subsidy"
        
    schemes_list.append({
        "id": sid,
        "uuid": suuid,
        "name": f"Government Support Scheme Option {i} ({'TN' if is_state else 'GoI'})",
        "short_name": f"GSS {i}",
        "gov_level": gov_lvl,
        "state": state_name,
        "department": f"Ministry of {'Agriculture' if 'Agri' in cat else 'MSME' if 'MSME' in cat else 'Electronics'}",
        "agency": "Implementing Nodal Authority",
        "category": cat,
        "subcategory": "General Business Assistance",
        "beneficiaries": "MSMEs, Farmers, Startups, Women Entrepreneurs",
        "stage": "Startup, Existing",
        "sector": "Agriculture, Manufacturing, Services, Technology",
        "special_groups": "Women, SC/ST, Rural",
        "objective": f"Provide general business promotion and support facilities under scheme option {i}.",
        "description": f"Detailed implementation package for supporting grassroot entrepreneurs and workers in {state_name}.",
        "summary": f"Subsidy of {10 + (i % 20)}% up to ₹{5 + i} Lakhs.",
        "benefits_summary": f"Financial aid, capital subsidy and interest waiver benefits.",
        "assistance_type": "Loan" if i % 2 == 0 else "Subsidy",
        "min_assistance": 50000.0 * (i % 5 + 1),
        "max_assistance": 500000.0 * (i % 10 + 1),
        "subsidy_pct": 10.0 + (i % 25),
        "interest_subsidy": 1.5 + (i % 3),
        "margin_money": 10.0,
        "app_mode": "Online",
        "website": "https://www.india.gov.in/",
        "apply_url": "https://www.india.gov.in/apply",
        "keywords": f"mock, scheme {i}, development, startup, agriculture, loan, subsidy, {state_name.lower()}",
        "tags": tags,
        "rules": [
            {"parameter": "applicant_age", "operator": ">=", "value": "18", "label": "Applicant must be 18 or older"},
        ],
        "documents": [
            "Aadhaar Card", "PAN Card", "UDYAM Registration Certificate", "Address Proof", 
            "Community Certificate", "Project Report", "Passport Size Photograph"
        ],
        "benefits": [
            {"type": "Subsidy", "value": f"{10 + (i % 25)}%", "desc": f"Subsidy on project capital setup of {10 + (i % 25)}%"},
        ],
        "faqs": [
            {"q": "Who can apply?", "a": "Eligible entrepreneurs meeting sector parameters."},
        ],
        "contacts": [
            {"office": "Central Helpdesk", "district": "New Delhi", "phone": "1800-11-0000", "email": "info@gov.in"}
        ]
    })

print(f"Generated data for {len(schemes_list)} schemes.")

# 1. Update Excel workbook
print("Populating Excel sheets...")
excel_path = '../IN_Schemes_Master_Data_Collection_Template.xlsx'
wb = openpyxl.load_workbook(excel_path)

# Clear existing contents under headers for sheet 1, 2, 3, 4, 5, 6
def clear_sheet_data(ws):
    max_r = ws.max_row
    if max_r > 1:
        ws.delete_rows(2, max_r)

# Sheet: 1_Schemes
ws_schemes = wb['1_Schemes']
clear_sheet_data(ws_schemes)
for idx, s in enumerate(schemes_list):
    ws_schemes.append([
        s["id"], s["name"], s["short_name"], s["gov_level"], s["state"], s["department"], s["agency"],
        s["category"], s["subcategory"], s["beneficiaries"], s["stage"], s["sector"], s["special_groups"],
        s["objective"], s["description"], s["summary"], s["benefits_summary"], s["assistance_type"],
        s["min_assistance"], s["max_assistance"], s["subsidy_pct"], s["interest_subsidy"], s["margin_money"],
        s["app_mode"], s["website"], s["apply_url"], "Open", "30 Days", s["keywords"], s["tags"],
        "2026-07-26", "Official guidelines doc", "Mock seed data populated"
    ])

# Sheet: 2_Eligibility_Rules
ws_rules = wb['2_Eligibility_Rules']
clear_sheet_data(ws_rules)
rule_counter = 1
for s in schemes_list:
    for r in s["rules"]:
        ws_rules.append([
            f"R{rule_counter:03d}", s["id"], r["parameter"], r["operator"], r["value"], r["label"], "Y", "Automated mapping rule"
        ])
        rule_counter += 1

# Sheet: 3_Required_Documents
ws_docs = wb['3_Required_Documents']
clear_sheet_data(ws_docs)
doc_counter = 1
for s in schemes_list:
    for doc in s["documents"]:
        ws_docs.append([
            f"D{doc_counter:03d}", s["id"], doc, "Y", "", "Mandatory requirement"
        ])
        doc_counter += 1

# Sheet: 4_Benefits
ws_benefits = wb['4_Benefits']
clear_sheet_data(ws_benefits)
benefit_counter = 1
for s in schemes_list:
    for b in s["benefits"]:
        ws_benefits.append([
            f"B{benefit_counter:03d}", s["id"], b["type"], b["value"], "%" if "%" in b["value"] else "₹", b["desc"], "Subject to parameters"
        ])
        benefit_counter += 1

# Sheet: 5_FAQs
ws_faqs = wb['5_FAQs']
clear_sheet_data(ws_faqs)
faq_counter = 1
for s in schemes_list:
    for f in s["faqs"]:
        ws_faqs.append([
            f"F{faq_counter:03d}", s["id"], f["q"], f["a"]
        ])
        faq_counter += 1

# Sheet: 6_Contacts
ws_contacts = wb['6_Contacts']
clear_sheet_data(ws_contacts)
contact_counter = 1
for s in schemes_list:
    for c in s["contacts"]:
        ws_contacts.append([
            f"C{contact_counter:03d}", s["id"], c["office"], c["district"], c["phone"], c["email"], s["website"]
        ])
        contact_counter += 1

wb.save(excel_path)
print("Excel template sheets populated and saved successfully.")

# 2. Generate seed.sql
print("Generating seed.sql script...")
sql_dir = 'supabase/seed'
os.makedirs(sql_dir, exist_ok=True)
sql_path = os.path.join(sql_dir, 'seed.sql')

# Unique list of document names to build public.document_types
all_doc_names = set()
for s in schemes_list:
    all_doc_names.update(s["documents"])

# Document names UUID mapping
doc_uuid_map = {}
for idx, doc_name in enumerate(sorted(all_doc_names)):
    doc_uuid_map[doc_name] = make_uuid(f"doc_{doc_name}")

with open(sql_path, 'w', encoding='utf-8') as f:
    f.write("-- =========================================================\n")
    f.write("-- Supabase Seed Script - Government Schemes Master Data\n")
    f.write("-- Generated Programmatically\n")
    f.write("-- =========================================================\n\n")

    f.write("BEGIN;\n\n")

    # Clear existing data to prevent conflict
    f.write("DELETE FROM public.scheme_documents;\n")
    f.write("DELETE FROM public.document_types;\n")
    f.write("DELETE FROM public.eligibility_rules;\n")
    f.write("DELETE FROM public.schemes;\n\n")

    # Insert public.document_types
    f.write("-- 1. Insert Master Document Types\n")
    for doc_name, duuid in doc_uuid_map.items():
        escaped_name = doc_name.replace("'", "''")
        f.write(f"INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) \n")
        f.write(f"VALUES ('{duuid}', '{escaped_name}', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);\n")
    f.write("\n")

    # Insert public.schemes
    f.write("-- 2. Insert Schemes\n")
    for s in schemes_list:
        escaped_name = s["name"].replace("'", "''")
        escaped_dept = s["department"].replace("'", "''")
        escaped_agency = s["agency"].replace("'", "''")
        escaped_objective = s["objective"].replace("'", "''")
        escaped_desc = s["description"].replace("'", "''")
        escaped_summary = s["summary"].replace("'", "''")
        escaped_keywords = s["keywords"].replace("'", "''")
        escaped_tags = s["tags"].replace("'", "''")
        
        f.write(f"INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) \n")
        f.write(f"VALUES ('{s['uuid']}', '{s['id']}', '{escaped_name}', '{s['gov_level']}', '{escaped_dept}', '{escaped_agency}', '{s['state']}', '{s['sector']}', '{s['beneficiaries']}', '{s['assistance_type']}', '{s['category']}', '{escaped_desc}', '{escaped_objective}', '{escaped_summary}', {s['subsidy_pct']}, {s['max_assistance']}, {s['min_assistance']}, {s['interest_subsidy']}, '{s['app_mode']}', '{s['website']}', '{s['apply_url']}', '{escaped_keywords}, {escaped_tags}', 'ACTIVE', true);\n")
    f.write("\n")

    # Insert public.eligibility_rules
    f.write("-- 3. Insert Eligibility Rules\n")
    for s in schemes_list:
        for idx, r in enumerate(s["rules"]):
            ruuid = make_uuid(f"rule_{s['id']}_{r['parameter']}_{idx}")
            escaped_val = r["value"].replace("'", "''")
            escaped_label = r["label"].replace("'", "''")
            f.write(f"INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) \n")
            f.write(f"VALUES ('{ruuid}', '{s['uuid']}', '{r['parameter']}', '{r['operator']}', '{escaped_val}', '{escaped_label}');\n")
    f.write("\n")

    # Insert public.scheme_documents
    f.write("-- 4. Insert Scheme Documents Mapping\n")
    for s in schemes_list:
        for doc in s["documents"]:
            doc_uuid = doc_uuid_map[doc]
            sd_uuid = make_uuid(f"sd_{s['id']}_{doc}")
            f.write(f"INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) \n")
            f.write(f"VALUES ('{sd_uuid}', '{s['uuid']}', '{doc_uuid}', true, 'Mandatory for application submission') \n")
            f.write(f"ON CONFLICT (scheme_id, document_type_id) DO NOTHING;\n")
    f.write("\n")

    f.write("COMMIT;\n")

print(f"SQL seed script written successfully to: {sql_path}")
