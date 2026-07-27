-- =========================================================
-- Supabase Seed Script - Government Schemes Master Data
-- Generated Programmatically
-- =========================================================

BEGIN;

DELETE FROM public.scheme_documents;
DELETE FROM public.document_types;
DELETE FROM public.eligibility_rules;
DELETE FROM public.schemes;

-- 1. Insert Master Document Types
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('316044f7-27be-5646-ae5c-67c7a0db401e', 'Aadhaar Card', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('9f22c2d9-c1da-57a1-90bb-dca7e10d4e8b', 'Aadhaar of Directors', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('f8182a7e-0813-5ddc-9de2-8901f2801f6d', 'Aadhaar of Members', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('564d837b-2d9c-5be7-ba86-46d2113a2275', 'Address Proof', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('e7f143c4-3c59-5f3b-980f-2969c85330c1', 'Agriculture Degree / Diploma Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('87d8ef88-a4b8-5e89-b789-a743ff945277', 'Audit reports of NGO (last 3 years)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('3076b16a-de21-5588-8065-903fb19a37cc', 'Audited Financials (last 2 years)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('d4899977-6624-5910-8fc9-f2f4c1d2a9ab', 'Bank Account Details', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('52b17f6e-2c16-5b92-86d6-b030b5bfb5ac', 'Bank Passbook Copy', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('70473fbb-84b7-5463-b0aa-55fd3a862a3c', 'Bank Statement', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('7987f1a7-f141-56d7-9f48-b07f96628055', 'Bank Statements (last 12 months)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('ae8cd091-82a3-55d9-b09b-b9fa6a8b1bac', 'Bank Statements (last 6 months)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('52155b74-bb8c-509f-8dab-d7114981ee18', 'Bank statement', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('406a09be-b85b-52a7-a5b4-9bfe75884853', 'Business Address Proof', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('7199c673-6870-567b-9a54-a35819a0f49e', 'Certificate of Incorporation', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('4d091234-5124-56e4-8180-96d1522c0a87', 'Community / Caste Certificate (SC/ST)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('a3275c7b-23e5-5d90-83c8-57bd3c32176d', 'Community Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('346d0f57-468a-5fe3-b303-393c36bd4062', 'DPIIT Recognition Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('6a59ab39-f399-59e3-b938-d07e2ea3efbd', 'Degree/Diploma Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('48de5cac-ea77-52c7-ba63-e4a7942cd12a', 'Financial Statements (if any)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('2ce101d4-496c-57d1-90ed-caff777ee628', 'GST Registration Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('19947f64-ceb3-5f83-aa1e-88a3f664ebae', 'IT Returns (if existing)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('38181376-4501-5ac8-aad0-e70f506a75f3', 'Identity Proof', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('c70d6afa-5bd6-52a7-b0b0-b1742e0162e3', 'Income Certificate (revenue authority)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('5b5128a7-bdbd-5dff-8e07-38133279733c', 'Income Tax Returns', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('31d15d58-5edd-5e3d-af25-7243e57e4602', 'Land ownership proof (if any)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('d51027eb-acb5-5c00-8009-50224abcf860', 'Land ownership proof / lease agreement', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('f050980a-36b0-5917-932e-47e0931fa213', 'MANAGE training completion certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('cb0e3305-a1bc-5c0c-88d5-d0e5307b5b78', 'NGO Registration Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('ff8e52cb-9969-5307-a94d-7fdc31ee3193', 'Nativity Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('67ff56d2-6341-5e68-b0c8-3454b81a73cc', 'Nativity Certificate (TN)', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('2fabebf3-2b71-564d-937e-a9dd05d29222', 'PAN Card', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('e072fc21-38f6-5dc4-ada9-d674f8d510d0', 'PAN of NGO / Members', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('65b189b3-5bf8-5245-af4b-099730999c78', 'PAN of Startup', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('19c5350f-5d20-5b7a-9c0c-89f0a58b4081', 'Passport Size Photograph', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('d9cd70a9-71da-5614-ae11-060c54d14122', 'Passport size photo', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('1bea7b49-aab3-5f27-958f-34ae8a48b5c0', 'Pitch Video / Prototype Link', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('412640c8-e878-5935-87c6-46603031c311', 'Project Proposal / Pitch Deck', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('cdda014a-f46f-527f-9c89-c276c81fe06a', 'Project Report', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('04216e5d-06d6-5eb7-aa5d-bd20acebc85a', 'Project Report / Business Plan', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('bf75b04e-48ac-5098-9c49-4b50816fd066', 'Quotations for machinery', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('d526ae38-7b52-5991-9aeb-cbee69d6328c', 'Quotations for machinery/assets', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('442d1640-4f67-544d-8890-850c6219a2a5', 'Quotations for machinery/equipment', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('3e4be862-56d6-592a-831f-7e29b80e743c', 'Resolution copy from SHG', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('92859012-cf5f-5fa9-bea5-e46867321392', 'Rural Area Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('efbb1cb4-e52a-5aec-909f-dddc572134bc', 'School Transfer Certificate / Pass Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('7f4b917f-56d4-52fa-af8d-a24c700e51b3', 'UDYAM Registration Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);
INSERT INTO public.document_types (id, document_name, description, issuing_authority, official_apply_url, estimated_processing_days, is_mandatory_default) 
VALUES ('c2a303c4-f726-5d02-b430-f73942ada6a0', 'VIII Standard Pass Certificate', 'Required certificate verification for schemes', 'Competent Authority', 'https://serviceonline.gov.in/', 15, true);

-- 2. Insert Schemes
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('7b90a62c-5a9f-5582-8716-fd9f4eddee46', 'TN_NEEDS_001', 'NEEDS (New Entrepreneur cum Enterprise Development Scheme)', 'State', 'Department of MSME', 'District Industries Centre (DIC)', 'Tamil Nadu', 'Manufacturing, Services', 'Entrepreneurs, Unemployed, Women, SC/ST, Minorities', 'Subsidy + Loan', 'Business & MSME', 'Financial assistance program for educated youth to set up manufacturing or service ventures in Tamil Nadu.', 'Promote first-generation entrepreneurs by providing financial assistance, subsidies, and EDP training in Tamil Nadu.', '25% project cost subsidy (up to ₹75 Lakhs) for projects ranging from ₹10 Lakhs to ₹5 Crores.', 25.0, 50000000.0, 1000000.0, 3.0, 'Online', 'https://www.msmeonline.tn.gov.in/needs/', 'https://www.msmeonline.tn.gov.in/needs/needs_app.php', 'needs, tamil nadu, chennai, startup loan, first generation, entrepreneur, subsidy, interest subvention, dic, Tamil Nadu, State Scheme, Subsidy, MSME', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('876a916f-8d9a-5865-baf2-1e8711262699', 'IN_PMEGP_001', 'PMEGP (Prime Minister''s Employment Generation Programme)', 'Central', 'Ministry of MSME', 'KVIC, KVIB, DIC', 'All India', 'Manufacturing, Services', 'Entrepreneurs, Individuals, Women, SC/ST, OBC, Rural', 'Subsidy + Loan', 'Business & MSME', 'Credit-linked subsidy scheme by the Government of India for launching manufacturing or service micro businesses.', 'Generate continuous self-employment opportunities in rural and urban areas by setting up new micro enterprises.', 'Subsidy of 15% to 35% of the project cost. Maximum project cost is ₹50 Lakhs for Manufacturing.', 35.0, 5000000.0, 500000.0, 0.0, 'Online', 'https://www.kviconline.gov.in/pmegpeportal/', 'https://www.kviconline.gov.in/pmegpeportal/pmegphome/index.jsp', 'pmegp, kvic, central scheme, loan, manufacturing, rural, urban, subsidy, self employment, Central Scheme, Subsidy, MSME, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('91f355a4-d70d-500d-ad36-3f91215eed22', 'IN_CGTMSE_001', 'CGTMSE (Credit Guarantee Fund Trust for Micro and Small Enterprises)', 'Central', 'Ministry of MSME', 'CGTMSE Trust, Member Lending Institutions', 'All India', 'Manufacturing, Services, Retail', 'MSMEs, Existing Businesses, Startups', 'Credit Guarantee', 'Business & MSME', 'Collateral-free credit guarantee system facilitating up to ₹5 Crore funding for MSEs.', 'Provide credit guarantees to financial institutions for extending collateral-free loans to micro and small enterprises.', 'Credit guarantee coverage up to 85% of the loan amount for loans up to ₹5 Crores.', 0.0, 50000000.0, 100000.0, 0.0, 'Through Banks', 'https://www.cgtmse.in/', 'https://www.cgtmse.in/list-of-mlis.html', 'cgtmse, credit guarantee, collateral free loan, msme loan, sidbi, central scheme, startup loan, Central Scheme, Guarantee, MSME, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('575e7644-fc9c-5eb3-905a-f960abe82c8b', 'IN_MUDRA_S_001', 'Pradhan Mantri MUDRA Yojana - Shishu Loan', 'Central', 'Department of Financial Services', 'MUDRA Ltd., All Banks, NBFCs', 'All India', 'Retail, Services, Agriculture Allied', 'Individuals, Shopkeepers, Artisans, Small Traders', 'Loan', 'Business & MSME', 'First-tier micro financing program under Mudra targeting budding micro-enterprises and small traders.', 'Provide collateral-free micro loans up to ₹50,000 to tiny and micro business start-ups.', 'Loans up to ₹50,000 for setting up or promoting small shops and services.', 0.0, 50000.0, 5000.0, 2.0, 'Through Banks / Online', 'https://www.mudra.org.in/', 'https://www.udyamimitra.in/', 'mudra, shishu, loan, micro credit, central scheme, shop loan, women loan, micro business, Central Scheme, Loan, MSME', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('a353d28d-d965-5b8c-8b67-69a13746dc38', 'IN_MUDRA_K_001', 'Pradhan Mantri MUDRA Yojana - Kishor Loan', 'Central', 'Department of Financial Services', 'MUDRA Ltd., All Banks, NBFCs', 'All India', 'Manufacturing, Services, Retail', 'Entrepreneurs, Retailers, Small Manufacturers', 'Loan', 'Business & MSME', 'Mid-tier micro financing program under Mudra targeting established micro-ventures looking for expansion funding.', 'Provide collateral-free micro loans from ₹50,000 up to ₹5 Lakhs for expanding micro businesses.', 'Loans between ₹50,000 and ₹5 Lakhs for machinery and capital expenditures.', 0.0, 500000.0, 50000.0, 0.0, 'Through Banks / Online', 'https://www.mudra.org.in/', 'https://www.udyamimitra.in/', 'mudra, kishor, loan, startup, central scheme, business loan, working capital, expansion, Central Scheme, Loan, MSME', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', 'IN_MUDRA_T_001', 'Pradhan Mantri MUDRA Yojana - Tarun Loan', 'Central', 'Department of Financial Services', 'MUDRA Ltd., All Banks, NBFCs', 'All India', 'Manufacturing, Services, Retail', 'Entrepreneurs, Small Industrialists, Service Providers', 'Loan', 'Business & MSME', 'High-tier micro financing program under Mudra targeting established micro-enterprises requiring substantial expansion capital.', 'Provide collateral-free micro loans from ₹5 Lakhs up to ₹10 Lakhs for established enterprises.', 'Loans between ₹5 Lakhs and ₹10 Lakhs for expansion and growth.', 0.0, 1000000.0, 500000.0, 0.0, 'Through Banks / Online', 'https://www.mudra.org.in/', 'https://www.udyamimitra.in/', 'mudra, tarun, loan, expansion, central scheme, msme loan, credit, machinery loan, Central Scheme, Loan, MSME', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('fcef7084-2537-50ec-9ffd-cd4a8df88ca4', 'IN_STANDUP_001', 'Stand Up India Scheme', 'Central', 'Department of Financial Services', 'SIDBI, National Credit Guarantee Trustee Company (NCGTC), Member Banks', 'All India', 'Manufacturing, Services, Agriculture Allied, Trading', 'Women, SC/ST, Entrepreneurs', 'Loan', 'Women & Minorities', 'Government loan program targeting women and SC/ST applicants for establishing their first business venture.', 'Promote entrepreneurship among women and SC/ST communities by facilitating greenfield loans.', 'Loans between ₹10 Lakhs and ₹1 Crore for setting up new greenfield enterprises.', 0.0, 10000000.0, 1000000.0, 0.0, 'Through Banks / Online', 'https://www.standupmitra.in/', 'https://www.standupmitra.in/Home/RegisterApplicant', 'standup india, women loan, sc/st loan, greenfield loan, startup india, central scheme, sidbi, Central Scheme, Loan, Women, Startup', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('e2beaad6-ae91-5b85-8a76-ed988628097d', 'IN_STARTUP_SEED_001', 'Startup India Seed Fund Scheme (SISFS)', 'Central', 'Department for Promotion of Industry and Internal Trade (DPIIT)', 'DPIIT, Approved Incubators', 'All India', 'Technology, Healthcare, Agriculture, Education, Waste Management, Clean Energy', 'Startups, Tech Entrepreneurs', 'Grant / Debt', 'Startups & Technology', 'Seed funding program for early-stage startups in technology and social impact sectors.', 'Provide financial assistance to startups for proof of concept, prototype development, product trials, and market entry.', 'Grants up to ₹20 Lakhs for prototype development and up to ₹50 Lakhs for market entry.', 100.0, 5000000.0, 500000.0, 0.0, 'Online', 'https://seedfund.startupindia.gov.in/', 'https://seedfund.startupindia.gov.in/startup/register', 'startup india, sisfs, seed fund, grant, prototype grant, angel investment, tech startup, dpiit, Central Scheme, Grant, Startup, Technology', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('7f190a84-19b6-58e5-9379-f49d65677f6f', 'TN_UYEGP_001', 'UYEGP (Unemployed Youth Employment Generation Programme)', 'State', 'Department of MSME', 'District Industries Centre (DIC), State Banks', 'Tamil Nadu', 'Manufacturing, Services, Trading', 'Individuals, Unemployed Youth, Women, SC/ST', 'Subsidy + Loan', 'Business & MSME', 'Self-employment generation program offering subsidies for micro business setups in Tamil Nadu.', 'Mitigate the unemployment problems of socially and economically backward sections of youth in Tamil Nadu.', 'Subsidy of 25% of the project cost. Maximum project cost is ₹15 Lakhs for Manufacturing.', 25.0, 1500000.0, 100000.0, 0.0, 'Online', 'https://www.msmeonline.tn.gov.in/uyegp/', 'https://www.msmeonline.tn.gov.in/uyegp/uyegp_app.php', 'uyegp, unemployed, youth loan, tamil nadu, subsidy, micro business, trading loan, dic, Tamil Nadu, State Scheme, Subsidy, MSME', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('76ab2a18-e781-5dc0-a858-fbbb720b2b68', 'IN_TREAD_001', 'TREAD (Trade Related Entrepreneurship Assistance and Development) for Women', 'Central', 'Ministry of MSME', 'Ministry of MSME, Registered NGOs', 'All India', 'Retail, Handicrafts, Services, Agriculture Allied', 'Women, SHGs, Rural Women', 'Grant + Loan', 'Women & Minorities', 'Central government grant and loan scheme assisting groups of women in trading and allied industries.', 'Empower illiterate or semi-literate women in rural and urban areas by providing credit and training through NGOs.', 'Government grant up to 30% of the project cost; remainder provided as loan by financial institutions through NGOs.', 30.0, 5000000.0, 50000.0, 0.0, 'Through NGOs', 'https://msme.gov.in/', 'https://msme.gov.in/trade-related-entrepreneurship-assistance-and-development-tread-scheme-women', 'tread, women entrepreneurs, rural women, grant for women, ngo funding, self help group, shg, central scheme, Central Scheme, Grant, Women, SHG', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('26ac575c-7e9a-5cae-bb67-fdbda7a95c05', 'IN_ACABC_001', 'Agri-Clinics and Agri-Business Centres Scheme (ACABC)', 'Central', 'Ministry of Agriculture and Farmers Welfare', 'NABARD, MANAGE (National Institute of Agricultural Extension Management)', 'All India', 'Agriculture, Horticulture, Dairy, Animal Husbandry', 'Farmers, Agriculture Graduates, Unemployed Youth', 'Subsidy + Loan', 'Agriculture & Farmers', 'Subsidy program for setting up farm extension, diagnostic, and commercial agri-business hubs.', 'Promote agricultural extension services and self-employment ventures by trained agriculture graduates.', 'Subsidy of 36% (General category) to 44% (Women & SC/ST) of the project cost up to ₹20 Lakhs.', 44.0, 2000000.0, 200000.0, 0.0, 'Online', 'https://www.agriclinics.net/', 'https://www.agriclinics.net/acabc-apply.html', 'acabc, agri clinic, agri business, nabard loan, agriculture subsidy, agro startup, veterinary clinics, seed supply, Central Scheme, Subsidy, Farmers, Agriculture', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('da9494d8-19c7-5a96-bf42-f1d584f3d0b3', 'TN_MOCK_SCHEME_012', 'Government Support Scheme Option 12 (TN)', 'State', 'Ministry of MSME', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Business & MSME', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 12.', 'Subsidy of 22% up to ₹17 Lakhs.', 22.0, 1500000.0, 150000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 12, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('33d41122-0c16-574f-98f7-405765cd1266', 'IN_MOCK_SCHEME_013', 'Government Support Scheme Option 13 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Women & Minorities', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 13.', 'Subsidy of 23% up to ₹18 Lakhs.', 23.0, 2000000.0, 200000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 13, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('593d0482-7aec-5927-9ef5-6b3f709a83b5', 'IN_MOCK_SCHEME_014', 'Government Support Scheme Option 14 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Students & Education', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 14.', 'Subsidy of 24% up to ₹19 Lakhs.', 24.0, 2500000.0, 250000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 14, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('7b628679-2c36-5f2c-a4d5-a20c573dc555', 'TN_MOCK_SCHEME_015', 'Government Support Scheme Option 15 (TN)', 'State', 'Ministry of Agriculture', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Agriculture & Farmers', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 15.', 'Subsidy of 25% up to ₹20 Lakhs.', 25.0, 3000000.0, 50000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 15, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('03398ee9-aa95-5605-8df2-e26edf9d3ace', 'IN_MOCK_SCHEME_016', 'Government Support Scheme Option 16 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Startups & Technology', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 16.', 'Subsidy of 26% up to ₹21 Lakhs.', 26.0, 3500000.0, 100000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 16, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('7b21c70a-194e-595f-9841-625c977279e7', 'IN_MOCK_SCHEME_017', 'Government Support Scheme Option 17 (GoI)', 'Central', 'Ministry of MSME', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Business & MSME', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 17.', 'Subsidy of 27% up to ₹22 Lakhs.', 27.0, 4000000.0, 150000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 17, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('81725b58-efde-561d-8c01-84161ef16e18', 'TN_MOCK_SCHEME_018', 'Government Support Scheme Option 18 (TN)', 'State', 'Ministry of Electronics', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Women & Minorities', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 18.', 'Subsidy of 28% up to ₹23 Lakhs.', 28.0, 4500000.0, 200000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 18, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('f929b97e-9095-572e-8044-e029dc18d9ee', 'IN_MOCK_SCHEME_019', 'Government Support Scheme Option 19 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Students & Education', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 19.', 'Subsidy of 29% up to ₹24 Lakhs.', 29.0, 5000000.0, 250000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 19, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('c3e18264-e689-55b1-b996-f206d36b4c6c', 'IN_MOCK_SCHEME_020', 'Government Support Scheme Option 20 (GoI)', 'Central', 'Ministry of Agriculture', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Agriculture & Farmers', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 20.', 'Subsidy of 10% up to ₹25 Lakhs.', 30.0, 500000.0, 50000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 20, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('faa1db28-887d-5d07-a2c3-c166634bdf9e', 'TN_MOCK_SCHEME_021', 'Government Support Scheme Option 21 (TN)', 'State', 'Ministry of Electronics', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Startups & Technology', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 21.', 'Subsidy of 11% up to ₹26 Lakhs.', 31.0, 1000000.0, 100000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 21, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('2dd6f328-3cf4-50fd-a807-9c10416c7d74', 'IN_MOCK_SCHEME_022', 'Government Support Scheme Option 22 (GoI)', 'Central', 'Ministry of MSME', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Business & MSME', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 22.', 'Subsidy of 12% up to ₹27 Lakhs.', 32.0, 1500000.0, 150000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 22, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', 'IN_MOCK_SCHEME_023', 'Government Support Scheme Option 23 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Women & Minorities', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 23.', 'Subsidy of 13% up to ₹28 Lakhs.', 33.0, 2000000.0, 200000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 23, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('fed1ccc6-fff2-5106-9848-422bd743461b', 'TN_MOCK_SCHEME_024', 'Government Support Scheme Option 24 (TN)', 'State', 'Ministry of Electronics', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Students & Education', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 24.', 'Subsidy of 14% up to ₹29 Lakhs.', 34.0, 2500000.0, 250000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 24, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('ff669557-7cd2-56c3-8498-25283d2949a5', 'IN_MOCK_SCHEME_025', 'Government Support Scheme Option 25 (GoI)', 'Central', 'Ministry of Agriculture', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Agriculture & Farmers', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 25.', 'Subsidy of 15% up to ₹30 Lakhs.', 10.0, 3000000.0, 50000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 25, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', 'IN_MOCK_SCHEME_026', 'Government Support Scheme Option 26 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Startups & Technology', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 26.', 'Subsidy of 16% up to ₹31 Lakhs.', 11.0, 3500000.0, 100000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 26, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('dc6a5d9f-f94f-5170-889f-5e01bb305de1', 'TN_MOCK_SCHEME_027', 'Government Support Scheme Option 27 (TN)', 'State', 'Ministry of MSME', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Business & MSME', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 27.', 'Subsidy of 17% up to ₹32 Lakhs.', 12.0, 4000000.0, 150000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 27, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', 'IN_MOCK_SCHEME_028', 'Government Support Scheme Option 28 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Women & Minorities', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 28.', 'Subsidy of 18% up to ₹33 Lakhs.', 13.0, 4500000.0, 200000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 28, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('48f79ae7-467e-51d4-8387-faab0c297cbb', 'IN_MOCK_SCHEME_029', 'Government Support Scheme Option 29 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Students & Education', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 29.', 'Subsidy of 19% up to ₹34 Lakhs.', 14.0, 5000000.0, 250000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 29, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('4d2a8775-44da-5d08-a10b-3355335deef6', 'TN_MOCK_SCHEME_030', 'Government Support Scheme Option 30 (TN)', 'State', 'Ministry of Agriculture', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Agriculture & Farmers', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 30.', 'Subsidy of 20% up to ₹35 Lakhs.', 15.0, 500000.0, 50000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 30, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('82d6e296-9739-56e7-8f09-3e8b58ec8991', 'IN_MOCK_SCHEME_031', 'Government Support Scheme Option 31 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Startups & Technology', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 31.', 'Subsidy of 21% up to ₹36 Lakhs.', 16.0, 1000000.0, 100000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 31, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('ed534cdc-5692-5316-9ea3-c1340a7ce67e', 'IN_MOCK_SCHEME_032', 'Government Support Scheme Option 32 (GoI)', 'Central', 'Ministry of MSME', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Business & MSME', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 32.', 'Subsidy of 22% up to ₹37 Lakhs.', 17.0, 1500000.0, 150000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 32, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', 'TN_MOCK_SCHEME_033', 'Government Support Scheme Option 33 (TN)', 'State', 'Ministry of Electronics', 'Implementing Nodal Authority', 'Tamil Nadu', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Women & Minorities', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in Tamil Nadu.', 'Provide general business promotion and support facilities under scheme option 33.', 'Subsidy of 23% up to ₹38 Lakhs.', 18.0, 2000000.0, 200000.0, 1.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 33, development, startup, agriculture, loan, subsidy, tamil nadu, Tamil Nadu, State Scheme, Subsidy', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('3f04aef7-33d6-53d3-89f0-66bc66058ede', 'IN_MOCK_SCHEME_034', 'Government Support Scheme Option 34 (GoI)', 'Central', 'Ministry of Electronics', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Loan', 'Students & Education', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 34.', 'Subsidy of 24% up to ₹39 Lakhs.', 19.0, 2500000.0, 250000.0, 2.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 34, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Loan', 'ACTIVE', true);
INSERT INTO public.schemes (id, scheme_code, scheme_name, government_level, issuing_department, issuing_body, state, target_sector, target_beneficiary, scheme_type, scheme_category, overview, objectives, benefits_description, subsidy_percentage, max_funding_amount, minimum_funding_amount, interest_subvention_rate, application_mode, official_website, application_url, search_keywords, status, is_active) 
VALUES ('fc139cd6-973c-5ba0-aeca-4c459f2f377b', 'IN_MOCK_SCHEME_035', 'Government Support Scheme Option 35 (GoI)', 'Central', 'Ministry of Agriculture', 'Implementing Nodal Authority', 'All India', 'Agriculture, Manufacturing, Services, Technology', 'MSMEs, Farmers, Startups, Women Entrepreneurs', 'Subsidy', 'Agriculture & Farmers', 'Detailed implementation package for supporting grassroot entrepreneurs and workers in All India.', 'Provide general business promotion and support facilities under scheme option 35.', 'Subsidy of 25% up to ₹40 Lakhs.', 20.0, 3000000.0, 50000.0, 3.5, 'Online', 'https://www.india.gov.in/', 'https://www.india.gov.in/apply', 'mock, scheme 35, development, startup, agriculture, loan, subsidy, all india, All India, Central Scheme, Subsidy', 'ACTIVE', true);

-- 3. Insert Eligibility Rules
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('7a0cccf3-36d4-5fb7-9df7-e210de31be9f', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', 'applicant_age', '>=', '21', 'Applicant must be 21 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('35fccb6c-518d-56f8-b382-d02f5a2c856e', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', 'applicant_age', '<=', '45', 'Applicant must be under 45 (for special category)');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('5582800a-c1a1-5301-a218-89c7a2061a5c', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', 'nativity', '=', 'Tamil Nadu', 'Applicant must be a resident of Tamil Nadu');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('9dcc2189-c2a5-56f3-83e1-8976e62115d6', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', 'qualification', 'IN', 'Degree, Diploma, ITI', 'Applicant must hold a degree, diploma, or ITI');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('0b50651d-5bdf-5006-a047-d2bbce43b076', '876a916f-8d9a-5865-baf2-1e8711262699', 'applicant_age', '>=', '18', 'Applicant must be at least 18 years old');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('8ffd6c94-c2ca-5b96-8530-9dd2755bb33a', '876a916f-8d9a-5865-baf2-1e8711262699', 'qualification', 'IN', 'Standard VIII, Standard X, Degree', 'Must have passed VIII Standard for projects above ₹10 Lakhs');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('bc94f700-f0b8-50fa-bc40-e79c51aeeb2a', '91f355a4-d70d-500d-ad36-3f91215eed22', 'business_type', 'IN', 'Micro, Small', 'Enterprise must fall under Micro or Small categories');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('67c77784-0c87-5859-85a7-35c278877704', '575e7644-fc9c-5eb3-905a-f960abe82c8b', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('62e8fee0-6401-5993-a25b-8726630153b1', 'a353d28d-d965-5b8c-8b67-69a13746dc38', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('fa07f08a-391f-5745-a424-5ec75b740b0b', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('b8778610-b631-523f-bd60-a25b5873c191', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('600ce30f-6d80-5fec-96b2-dc674b97b6aa', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', 'special_group', 'IN', 'SC, ST, Women', 'Applicant must belong to SC/ST or be a Woman');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('3820b909-4ce7-5fe2-bdfc-7a1ac8e3af79', 'e2beaad6-ae91-5b85-8a76-ed988628097d', 'dpiit_recognition', '=', 'Yes', 'Startup must be recognized by DPIIT');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('75e6a720-400d-5f11-aaf1-d61ddee00f54', 'e2beaad6-ae91-5b85-8a76-ed988628097d', 'incorporation_age', '<=', '2', 'Startup must be incorporated within the last 2 years');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('ce64eb8b-c11d-5c1c-9c98-0bf293945b0f', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('e6379613-3c24-5b36-9ce0-d46b0d7c6550', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'applicant_age', '<=', '45', 'Applicant must be under 45 (for special category)');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('7d87ee15-789f-5029-b496-13c5f277426c', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'nativity', '=', 'Tamil Nadu', 'Applicant must be a resident of Tamil Nadu');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('b4e9bd4b-6426-5939-a67c-6905ddcf90af', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'family_income', '<=', '500000', 'Annual family income must not exceed ₹5 Lakhs');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('151cf81d-6f90-5765-9e71-7a5ed7f9d9c4', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', 'gender', '=', 'Female', 'Applicant must be Female or a women''s self help group');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('b9953de1-07c4-5223-bd96-8baf57222b76', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', 'qualification', 'IN', 'Agri Graduate, Agri Diploma, Science Graduate', 'Applicant must hold an agricultural or allied sciences degree/diploma');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('221ca5ec-d29b-5179-9802-b2f893ac8c28', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('9eb154b7-1ad1-54f5-8353-acdfbcd505a2', '33d41122-0c16-574f-98f7-405765cd1266', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('a0be839a-7029-5128-8f6a-e65708337981', '593d0482-7aec-5927-9ef5-6b3f709a83b5', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('53ccad36-dcc0-5062-96dc-a3c0f21cfe29', '7b628679-2c36-5f2c-a4d5-a20c573dc555', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('4a8e0d31-ece6-5bf9-be93-3891b550fe13', '03398ee9-aa95-5605-8df2-e26edf9d3ace', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('2e5a10f8-bb3f-5b63-b556-bb00eb957f7a', '7b21c70a-194e-595f-9841-625c977279e7', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('0a90fcbc-cd0c-5b91-a6c4-e1b9b8619158', '81725b58-efde-561d-8c01-84161ef16e18', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('164364a3-5c5e-5a4b-9cc8-3ceaa7ed8993', 'f929b97e-9095-572e-8044-e029dc18d9ee', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('ae1fb1a2-1b32-535e-aa57-d479cc4e5f8d', 'c3e18264-e689-55b1-b996-f206d36b4c6c', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('78ae5225-c355-5449-aa76-fb77b072aca9', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('52012e89-2625-581b-96b4-c44525131083', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('45d108fe-7192-5dbf-abb7-dab5cbd6d538', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('eea78404-8122-55d8-9397-97d311a5cf3b', 'fed1ccc6-fff2-5106-9848-422bd743461b', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('5a09c582-0f96-59bb-b23f-7977bbab2196', 'ff669557-7cd2-56c3-8498-25283d2949a5', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('2e7685d1-9ca0-5e54-afe9-dba7537c7a6e', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('a7e0a282-e3aa-5bb3-835a-b2ce9ea52686', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('39e02067-f15c-53c2-8402-b6c628b0478f', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('126f4f38-90ba-5196-b1bb-33eeb30a1221', '48f79ae7-467e-51d4-8387-faab0c297cbb', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('3452dfe0-d2cc-54c0-af33-381a914ffee4', '4d2a8775-44da-5d08-a10b-3355335deef6', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('72858bdf-dd9a-5957-b3a5-de53d0ac945e', '82d6e296-9739-56e7-8f09-3e8b58ec8991', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('de6384d7-dd35-5702-83c6-086a550a1c52', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('da67c7cb-b50b-5267-9c3b-e5433ba3c8c0', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('51f0baa3-b11b-5a29-be7d-9d222953299c', '3f04aef7-33d6-53d3-89f0-66bc66058ede', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');
INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description) 
VALUES ('3dcb20fd-aa3b-5bb6-944e-5a5f32f0366d', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', 'applicant_age', '>=', '18', 'Applicant must be 18 or older');

-- 4. Insert Scheme Documents Mapping
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ec817001-0ae9-5ec5-b2ce-f72ae815a250', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('88e1f35d-0fb2-55ed-99fd-a4ecb7587b5c', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f2bee680-36b0-5be6-87fa-5bc76fcdc9eb', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '6a59ab39-f399-59e3-b938-d07e2ea3efbd', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('afa92cf4-9429-53b3-98c3-6a9eb7fd2333', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '67ff56d2-6341-5e68-b0c8-3454b81a73cc', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5ea4a104-eb54-517c-93bb-a480d38674df', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c83a8587-21ec-5fb1-87cb-d4838acccbaf', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '04216e5d-06d6-5eb7-aa5d-bd20acebc85a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d394517f-90cf-57db-a7ef-22b18c1d6fe3', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '442d1640-4f67-544d-8890-850c6219a2a5', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6adccdb5-b403-5ced-a79c-037ee393a20e', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('01e835fe-77ba-50ae-9d4d-ed9bf0f38666', '7b90a62c-5a9f-5582-8716-fd9f4eddee46', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('61bcb4bc-bbcc-5176-9d5b-f03b8502ae6b', '876a916f-8d9a-5865-baf2-1e8711262699', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c5e5ff0e-f89c-5242-851a-7298402e68c5', '876a916f-8d9a-5865-baf2-1e8711262699', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('24fe571d-3cc1-5e31-9bdd-97699694d919', '876a916f-8d9a-5865-baf2-1e8711262699', 'c2a303c4-f726-5d02-b430-f73942ada6a0', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3e4705a2-899a-5035-83e1-cab5197471df', '876a916f-8d9a-5865-baf2-1e8711262699', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('2ae5e482-dec6-5360-a934-4d25a1d074d9', '876a916f-8d9a-5865-baf2-1e8711262699', '04216e5d-06d6-5eb7-aa5d-bd20acebc85a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('bfe4d3b3-0311-5120-8df7-a512151674c2', '876a916f-8d9a-5865-baf2-1e8711262699', '92859012-cf5f-5fa9-bea5-e46867321392', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9ebadc32-d3ec-585c-b88c-3d217e478593', '876a916f-8d9a-5865-baf2-1e8711262699', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('670bd5e3-8d57-5aa7-ae24-933ec8f919b6', '91f355a4-d70d-500d-ad36-3f91215eed22', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('eca02e1d-aecb-51b9-bf82-f3a336e8389f', '91f355a4-d70d-500d-ad36-3f91215eed22', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b0bca0dc-e857-5652-920f-08c3c56369ee', '91f355a4-d70d-500d-ad36-3f91215eed22', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('68669cd1-dda2-58e4-a829-5ee66cbe4625', '91f355a4-d70d-500d-ad36-3f91215eed22', '2ce101d4-496c-57d1-90ed-caff777ee628', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('627f251e-5e8a-5fbb-80b2-de490144dc27', '91f355a4-d70d-500d-ad36-3f91215eed22', '04216e5d-06d6-5eb7-aa5d-bd20acebc85a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f0023c54-121a-5d4d-89f3-1bfe6228c55d', '91f355a4-d70d-500d-ad36-3f91215eed22', '19947f64-ceb3-5f83-aa1e-88a3f664ebae', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a2020acc-6267-5d88-9193-01ea92fccbe3', '91f355a4-d70d-500d-ad36-3f91215eed22', '70473fbb-84b7-5463-b0aa-55fd3a862a3c', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('8d7a1274-519e-5580-a782-31e9aa8de098', '575e7644-fc9c-5eb3-905a-f960abe82c8b', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('eb90e7cb-2a1d-52d7-aab3-dfe35025fd79', '575e7644-fc9c-5eb3-905a-f960abe82c8b', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3a2c9999-681f-596b-a8af-11eb04e6a90d', '575e7644-fc9c-5eb3-905a-f960abe82c8b', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f9975078-7610-513a-8bb1-6d9f620e6d1d', '575e7644-fc9c-5eb3-905a-f960abe82c8b', '38181376-4501-5ac8-aad0-e70f506a75f3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9e5b952e-623b-5c95-9846-fb47ceb30520', '575e7644-fc9c-5eb3-905a-f960abe82c8b', '406a09be-b85b-52a7-a5b4-9bfe75884853', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('59e6dfeb-8278-5e2e-b980-8af9d2945075', '575e7644-fc9c-5eb3-905a-f960abe82c8b', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a3cb6181-896f-5d6e-aa22-eb512df376ec', '575e7644-fc9c-5eb3-905a-f960abe82c8b', '52b17f6e-2c16-5b92-86d6-b030b5bfb5ac', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('197e1058-8122-5594-9721-4ad94f9d7e31', 'a353d28d-d965-5b8c-8b67-69a13746dc38', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('16860d2a-562d-5a49-b754-c4ce83ad3b6b', 'a353d28d-d965-5b8c-8b67-69a13746dc38', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('0230eac4-1706-5ae3-95a1-98011ef96999', 'a353d28d-d965-5b8c-8b67-69a13746dc38', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('bf9084de-85b4-5bd2-a182-9e0d007a58b3', 'a353d28d-d965-5b8c-8b67-69a13746dc38', '2ce101d4-496c-57d1-90ed-caff777ee628', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9ff2620a-5db2-5ca8-a28e-4a331632f837', 'a353d28d-d965-5b8c-8b67-69a13746dc38', '38181376-4501-5ac8-aad0-e70f506a75f3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7b5920d0-c007-52ae-b8d3-ad2e1ffb86f0', 'a353d28d-d965-5b8c-8b67-69a13746dc38', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('8542b96c-9dc0-57a0-a3d3-c7b87276778b', 'a353d28d-d965-5b8c-8b67-69a13746dc38', 'bf75b04e-48ac-5098-9c49-4b50816fd066', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('80593921-e8ae-5c36-acfd-34f33e284a80', 'a353d28d-d965-5b8c-8b67-69a13746dc38', 'ae8cd091-82a3-55d9-b09b-b9fa6a8b1bac', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b4c648cb-1f28-5183-84e3-fde0d1a34e0f', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a2c58607-9943-5177-a86d-91a6ecad4db2', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('2182f579-9ef4-56c2-8958-143416b1dd34', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7ba54a52-7faa-592a-a3b8-ab4fc611a134', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '2ce101d4-496c-57d1-90ed-caff777ee628', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b0d205d7-9ed8-5f26-a7e1-e6d96c5fa48d', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9b550a05-0123-5288-acb7-bbde1af182cc', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '3076b16a-de21-5588-8065-903fb19a37cc', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6924fc89-beb6-5d76-bd5f-e51bfe6f515d', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '5b5128a7-bdbd-5dff-8e07-38133279733c', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('178aceda-4b97-562e-afb4-d5ee7c43b03e', '1e3dd5e7-b1fd-50d8-b6bf-f09ca04e0e3c', '7987f1a7-f141-56d7-9f48-b07f96628055', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('8c9c7c63-43b6-54f5-af6f-6dbc9051cb80', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('593509e7-06c7-51cf-bf32-cfe00310258a', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c61fcc44-3ee5-570b-832f-f84b60d06b54', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '4d091234-5124-56e4-8180-96d1522c0a87', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('4b38266b-a113-57ff-9150-60dcfceef704', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '38181376-4501-5ac8-aad0-e70f506a75f3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('43994086-e160-5353-939b-d1cdcb0d348c', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '04216e5d-06d6-5eb7-aa5d-bd20acebc85a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e23f68c3-7c61-5d26-925e-b349f627305d', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('76913445-7113-5694-bd70-8acb9290d3e7', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', 'd51027eb-acb5-5c00-8009-50224abcf860', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1d5bf762-d3d2-5d02-8a88-a3d386d5a899', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('24dcc13a-da25-53a8-be0e-55156a607dc3', 'fcef7084-2537-50ec-9ffd-cd4a8df88ca4', '52155b74-bb8c-509f-8dab-d7114981ee18', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ce1924bd-1fde-5a2e-bb30-6071d742949b', 'e2beaad6-ae91-5b85-8a76-ed988628097d', '346d0f57-468a-5fe3-b303-393c36bd4062', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('378b890c-00ae-5eff-944c-4834f964acb5', 'e2beaad6-ae91-5b85-8a76-ed988628097d', '7199c673-6870-567b-9a54-a35819a0f49e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('df1a8d09-5074-5dad-b919-242ea6309a2f', 'e2beaad6-ae91-5b85-8a76-ed988628097d', '65b189b3-5bf8-5245-af4b-099730999c78', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c7c3fe50-5acf-59b2-9745-6f8e5165c93f', 'e2beaad6-ae91-5b85-8a76-ed988628097d', '9f22c2d9-c1da-57a1-90bb-dca7e10d4e8b', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('43cfc486-d9c7-5653-a552-d754b2f361ea', 'e2beaad6-ae91-5b85-8a76-ed988628097d', '412640c8-e878-5935-87c6-46603031c311', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5f0b0de9-e8a5-56ba-860d-6e43e79130c1', 'e2beaad6-ae91-5b85-8a76-ed988628097d', '1bea7b49-aab3-5f27-958f-34ae8a48b5c0', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('30195dae-aca2-5d55-9823-13463092c045', 'e2beaad6-ae91-5b85-8a76-ed988628097d', '48de5cac-ea77-52c7-ba63-e4a7942cd12a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('60f28c2a-dcf7-53d8-85a7-4eadf902d3fd', '7f190a84-19b6-58e5-9379-f49d65677f6f', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('20d6a4c9-f19d-5d0e-b428-cdde6758a951', '7f190a84-19b6-58e5-9379-f49d65677f6f', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a22d5dc4-937b-54a6-a2db-d93a3ea21e16', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'efbb1cb4-e52a-5aec-909f-dddc572134bc', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6bb9bad6-abcb-565d-b893-2f7662fd942a', '7f190a84-19b6-58e5-9379-f49d65677f6f', '67ff56d2-6341-5e68-b0c8-3454b81a73cc', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('91a3fa13-edf1-519f-88c1-b8de3f713e44', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('45c01565-0159-5404-9414-0a4f072bf9b4', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'c70d6afa-5bd6-52a7-b0b0-b1742e0162e3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('bfd94292-e4bc-57cf-84ab-3ad51bc6128b', '7f190a84-19b6-58e5-9379-f49d65677f6f', '04216e5d-06d6-5eb7-aa5d-bd20acebc85a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ce1b2357-de56-598d-946e-b3760fcbd1e2', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'd526ae38-7b52-5991-9aeb-cbee69d6328c', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ed739715-eb3b-5c25-92c8-394405d09e15', '7f190a84-19b6-58e5-9379-f49d65677f6f', 'd9cd70a9-71da-5614-ae11-060c54d14122', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('8f27f121-63d7-57f5-9608-53454016553d', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', 'f8182a7e-0813-5ddc-9de2-8901f2801f6d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e20628f0-9344-5b0d-b386-e5b77138ca7f', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', 'e072fc21-38f6-5dc4-ada9-d674f8d510d0', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3d5875d8-da70-5f82-9485-28c8bd9e7e1a', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', 'cb0e3305-a1bc-5c0c-88d5-d0e5307b5b78', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('754603da-6357-5f56-bea1-52a38d7b4677', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('8e2df333-446e-5d2a-85b1-74076bfddd91', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', '87d8ef88-a4b8-5e89-b789-a743ff945277', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('4ed54e17-f97d-53a7-8061-83bd2cd4cd51', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', 'd4899977-6624-5910-8fc9-f2f4c1d2a9ab', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('aa8d1364-f502-5c4e-82c5-4ddeb62da10c', '76ab2a18-e781-5dc0-a858-fbbb720b2b68', '3e4be862-56d6-592a-831f-7e29b80e743c', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1543e5c9-d9dd-5347-92fb-7d98151f25a8', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('2a4a75b3-32d1-5533-a04e-950918f0223d', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ff3f766b-dc3b-52ed-9118-5598da1d26ec', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', 'e7f143c4-3c59-5f3b-980f-2969c85330c1', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d0bfefd8-2bb9-5d63-af89-22360deee9bc', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', 'f050980a-36b0-5917-932e-47e0931fa213', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('65d5228c-2c34-50a8-976d-2724a4d5e4dd', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', '04216e5d-06d6-5eb7-aa5d-bd20acebc85a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('2a6f2990-36a7-58df-accd-28ecb25c9724', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', 'ff8e52cb-9969-5307-a94d-7fdc31ee3193', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('213b28ce-27de-5a6e-b8de-6bde26f8039b', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', 'd4899977-6624-5910-8fc9-f2f4c1d2a9ab', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f0a922d8-f516-5b28-a345-74fcdcc7c29e', '26ac575c-7e9a-5cae-bb67-fdbda7a95c05', '31d15d58-5edd-5e3d-af25-7243e57e4602', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6a341558-5e6d-5561-bada-c910c2d5ff1e', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d37115cc-5bde-5f07-a65a-cb6960d31134', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('2594a38c-a9df-55f9-88bf-bc61962017ce', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('698dea39-8b2b-59cb-a0aa-75281cbe85fd', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e205d333-8df9-560c-ab17-b26fa009a139', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f4728daf-48cc-56c8-bc0b-7b48fd70a6aa', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a25f59c2-3730-506b-a226-f733d93c1d59', 'da9494d8-19c7-5a96-bf42-f1d584f3d0b3', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('352fe783-6330-52bc-b42a-2edc85fa5e26', '33d41122-0c16-574f-98f7-405765cd1266', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c43780e4-eeb6-5b12-ba7d-5429e23a34b6', '33d41122-0c16-574f-98f7-405765cd1266', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6fc9ce16-cb37-5ce8-a0e2-0d6460aba19e', '33d41122-0c16-574f-98f7-405765cd1266', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6adfc27d-bc59-5cce-8574-1483942884f3', '33d41122-0c16-574f-98f7-405765cd1266', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b7ff8b96-73ef-5182-b2e2-780d49d678c5', '33d41122-0c16-574f-98f7-405765cd1266', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c8cf7cd6-ae46-512b-9e05-7f077fd32c8a', '33d41122-0c16-574f-98f7-405765cd1266', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1fec16a6-9db2-57b2-92e9-f2e21ff57d51', '33d41122-0c16-574f-98f7-405765cd1266', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a1a15c25-7f6e-5a13-b456-cc43c357ede2', '593d0482-7aec-5927-9ef5-6b3f709a83b5', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6d648be6-8517-58f8-9abb-d6b24b1f6aa6', '593d0482-7aec-5927-9ef5-6b3f709a83b5', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9daa087d-800f-526c-88b2-d3abfec409a3', '593d0482-7aec-5927-9ef5-6b3f709a83b5', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('bc7c350d-1b6f-5361-ada3-38aa2de8ef20', '593d0482-7aec-5927-9ef5-6b3f709a83b5', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('101634b8-f8fa-543c-9c24-2e1a8b91e60b', '593d0482-7aec-5927-9ef5-6b3f709a83b5', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d36eb56f-0999-5e3a-b9a3-b4312c68abc2', '593d0482-7aec-5927-9ef5-6b3f709a83b5', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3355aed2-5db1-5ac1-ad81-ab3e4d6a2a1a', '593d0482-7aec-5927-9ef5-6b3f709a83b5', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b9c6d0c8-b959-53af-9b52-ffd9f7ce529d', '7b628679-2c36-5f2c-a4d5-a20c573dc555', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c8b5bf25-476d-5753-b13f-9d8448e8a955', '7b628679-2c36-5f2c-a4d5-a20c573dc555', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('2a74bb0c-8277-5fd8-b9a7-b3ca9f85ce68', '7b628679-2c36-5f2c-a4d5-a20c573dc555', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('964be14e-da29-5bba-9770-3044ea005f0b', '7b628679-2c36-5f2c-a4d5-a20c573dc555', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5bb79636-a614-598f-9397-c6626c378aee', '7b628679-2c36-5f2c-a4d5-a20c573dc555', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ec091200-7cdf-5c8a-9128-f11def891281', '7b628679-2c36-5f2c-a4d5-a20c573dc555', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('66f1f96f-7884-5926-9040-dbbdfd83e5e9', '7b628679-2c36-5f2c-a4d5-a20c573dc555', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c695daaf-4005-57c0-83c3-5d059474690a', '03398ee9-aa95-5605-8df2-e26edf9d3ace', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('52c897ec-0509-5b98-8b1b-2d750f1d93e3', '03398ee9-aa95-5605-8df2-e26edf9d3ace', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6d815ac9-7bb4-57a1-a0cb-0c9bc5eb9c13', '03398ee9-aa95-5605-8df2-e26edf9d3ace', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ea6bf31d-638e-53c5-a63c-66e5a45ba3fb', '03398ee9-aa95-5605-8df2-e26edf9d3ace', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('37b3189c-59b9-58d8-8d87-05f7e48cecc6', '03398ee9-aa95-5605-8df2-e26edf9d3ace', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('563d7afc-bea4-5ea3-8df5-863bfdc1543f', '03398ee9-aa95-5605-8df2-e26edf9d3ace', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7682201d-8760-58e0-ada8-26d4012b5b73', '03398ee9-aa95-5605-8df2-e26edf9d3ace', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7ec842d8-edfd-57c2-ac00-db73044f34f1', '7b21c70a-194e-595f-9841-625c977279e7', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('4ffaa55c-2de3-551a-884a-ddf3825ad317', '7b21c70a-194e-595f-9841-625c977279e7', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9293e7c0-87be-5229-824c-633223e77bb3', '7b21c70a-194e-595f-9841-625c977279e7', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1d6ba76e-c61f-5888-98c5-be0a0abae9b8', '7b21c70a-194e-595f-9841-625c977279e7', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('18c8dc97-577b-5e81-b1f2-e76a16434933', '7b21c70a-194e-595f-9841-625c977279e7', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c301a6b3-d449-56cc-bd45-5315bbb86a07', '7b21c70a-194e-595f-9841-625c977279e7', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('73d59749-addd-587d-9986-496716c1599f', '7b21c70a-194e-595f-9841-625c977279e7', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a3093530-3ea5-5ea9-a758-b7073e885608', '81725b58-efde-561d-8c01-84161ef16e18', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('18c48cd8-0d6f-56ba-9ee4-580a0ca19c8f', '81725b58-efde-561d-8c01-84161ef16e18', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('054a2615-6743-5ed1-82f6-15262d4c1665', '81725b58-efde-561d-8c01-84161ef16e18', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b56bd533-6f37-5947-b78d-0ea735e38aa4', '81725b58-efde-561d-8c01-84161ef16e18', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('0514439a-fe59-53a7-ba53-e304e455ff1f', '81725b58-efde-561d-8c01-84161ef16e18', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a8315385-bbab-5d5a-8582-20381220b68e', '81725b58-efde-561d-8c01-84161ef16e18', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('dd828703-1343-51c4-ba0e-fef1f46f0dfa', '81725b58-efde-561d-8c01-84161ef16e18', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c5444581-7fa2-5629-b159-278f116e64a6', 'f929b97e-9095-572e-8044-e029dc18d9ee', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('57f38265-0b50-5ac9-b5b2-0b3b41238648', 'f929b97e-9095-572e-8044-e029dc18d9ee', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9854223d-cc2f-5bad-8292-5df91a02b2e2', 'f929b97e-9095-572e-8044-e029dc18d9ee', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('81275dd7-40c7-587f-b1a0-96f23e11d9fe', 'f929b97e-9095-572e-8044-e029dc18d9ee', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('cf553d05-3153-5575-8623-c8eb6618bcc7', 'f929b97e-9095-572e-8044-e029dc18d9ee', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5f89e780-292d-51b7-a28a-90b7dd3f21e5', 'f929b97e-9095-572e-8044-e029dc18d9ee', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('43db0dd4-ac70-5e71-95f7-1da2d9c24054', 'f929b97e-9095-572e-8044-e029dc18d9ee', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('82cad40e-f15e-5b91-b3f6-bb0325c2c630', 'c3e18264-e689-55b1-b996-f206d36b4c6c', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d201460d-a09e-50f7-b9c5-8b08009527f5', 'c3e18264-e689-55b1-b996-f206d36b4c6c', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9a23e6dc-2d54-50ea-94cd-e01e68fac85a', 'c3e18264-e689-55b1-b996-f206d36b4c6c', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ad581986-8d5b-530f-b820-44060f5555d2', 'c3e18264-e689-55b1-b996-f206d36b4c6c', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f75b8982-5863-53f1-99a8-2d3c91a6223e', 'c3e18264-e689-55b1-b996-f206d36b4c6c', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a9a3192e-d93f-5640-9152-3f792c66b06b', 'c3e18264-e689-55b1-b996-f206d36b4c6c', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('8dae4d8e-7da1-547e-8dae-6023c840bc38', 'c3e18264-e689-55b1-b996-f206d36b4c6c', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('4351deaf-898f-52f4-99e0-aa18e2ce7d9e', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('274b7903-a424-56fe-a629-e0735e27ec61', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('36d5c1e0-e3f5-5009-8979-0c83546a6157', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6900b194-0321-5eca-9d0e-5c5ff7396ae5', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('42875ee2-bdb9-59e4-ad26-f588fd1e1865', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('0a8ce2b1-800a-5e36-a4c9-36ee5bfc92c4', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5a913be6-63b7-5707-848f-777e49ec2a76', 'faa1db28-887d-5d07-a2c3-c166634bdf9e', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('72b410ff-fee0-5076-ada8-a069773d794d', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1967403e-a3b0-5454-8e9b-8d938d4708ef', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('bd9142f2-ca0d-51e8-8d1d-a3efd8653004', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f67de7e5-831f-5b7c-be54-3c71ed5142ad', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('632e5859-d2a1-500f-891a-ddb44aecadc8', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ff0a4d2c-8c15-52e5-8990-0f6729658a6e', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f0b5e321-6937-5191-a8eb-526fda948070', '2dd6f328-3cf4-50fd-a807-9c10416c7d74', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7b936c71-a780-51be-9554-163b13be2731', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('88afb5c0-f097-5dfe-94d8-08276bf6c9f3', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('28079ae4-b367-58cc-ae25-290e28a1b614', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('76d84557-592b-594f-815c-81dd29b5949b', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('dc0ef556-6437-5e94-8258-1e9a59c8461e', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('cbbde3a6-3efa-5b72-9c09-7ac00e0d87f6', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f25a2e23-2225-5d5c-862a-da75fda0e2d4', '6c5520cc-bc1e-5aaa-bc7d-1ad45790db63', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c7ff1b0c-c31f-55a1-adea-a8ae0a8caddc', 'fed1ccc6-fff2-5106-9848-422bd743461b', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7f613310-3104-5a49-b224-ee5adc9b83a5', 'fed1ccc6-fff2-5106-9848-422bd743461b', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3ae9b52f-a717-5a90-a54c-f059cab34981', 'fed1ccc6-fff2-5106-9848-422bd743461b', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a2c0278f-87c6-5ca4-b2ca-aac1c903ad86', 'fed1ccc6-fff2-5106-9848-422bd743461b', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('0cebd3f7-bc92-5f99-8a2c-9464a4e2a8f1', 'fed1ccc6-fff2-5106-9848-422bd743461b', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c1fc089e-4691-52cc-9acb-f35fc7fc28ca', 'fed1ccc6-fff2-5106-9848-422bd743461b', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('09bbc8b6-69ba-5e53-bc63-655a00465ac1', 'fed1ccc6-fff2-5106-9848-422bd743461b', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('4c6aeb05-499a-5eee-9282-a1c23a1b5874', 'ff669557-7cd2-56c3-8498-25283d2949a5', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3933f3d6-430e-5b92-b543-c1dfe217f9f6', 'ff669557-7cd2-56c3-8498-25283d2949a5', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5adb0e7f-1f21-5bd8-a193-02424c890a4c', 'ff669557-7cd2-56c3-8498-25283d2949a5', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('94c37ac0-1b5f-5aba-b789-8d7534312492', 'ff669557-7cd2-56c3-8498-25283d2949a5', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('34a1de4a-c0de-5ebd-ae7d-aabc058c5302', 'ff669557-7cd2-56c3-8498-25283d2949a5', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d5752cc6-0bc8-55f4-8141-5a75bb9cd1af', 'ff669557-7cd2-56c3-8498-25283d2949a5', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('35c57975-b78e-59b6-bb9a-4b8ddff85b30', 'ff669557-7cd2-56c3-8498-25283d2949a5', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('0b4775f4-2241-5fe4-9873-6157009eb081', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('af7b0eed-651c-56ca-8d5d-d3f0392ca8bb', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('fcb858f6-a098-5295-b9c2-fb5f513f2e4d', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('27b70930-8126-5509-8727-6b01a6910dba', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d18856a7-8fd7-51f3-8f12-fa2d123786ea', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ff5e9583-9be1-5388-8133-642abdf4fb1a', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('16fdf8ef-7a71-5012-a43b-af40510cd543', '711dd13f-28d8-5141-ba1f-a2a2b3ffd04a', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c4885da5-d046-5d9c-b070-ad7baa987cff', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('4fd2e574-3e98-5c44-a415-c07ecacd8631', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3936375e-c18f-5429-b5b7-f57a409556a8', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e0e16be1-05e7-5d53-9429-377974db6a0b', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('56236531-2674-5bc9-a7a5-32c3bea88382', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('acdc187a-2e23-58dd-984a-593727e98dd6', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('55168174-8ca2-5035-9e18-74bcfbab0899', 'dc6a5d9f-f94f-5170-889f-5e01bb305de1', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('9dc8151b-c021-58bf-9ad9-7a3a18c4a50d', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('85aa55f8-08b2-53eb-8f5e-6591ee535bec', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e1e8ad32-96f4-5073-b5d9-b5edee3c0b36', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('80f6b6e0-7877-5ce8-bfcd-32d599216752', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('51a37cae-7dd3-5a18-847c-7135bcd948d4', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('13315c8e-9814-59cc-8e80-0c75b6bf005c', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('788f97c7-11ac-5117-940a-649472446ddb', 'f85a2231-f2b4-55be-ba93-b5af3dfd1ceb', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b0abed1e-0ba5-5cfb-8f72-82e3a0c64cf3', '48f79ae7-467e-51d4-8387-faab0c297cbb', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e46aee71-5e16-5936-85dc-12e8462bf7f6', '48f79ae7-467e-51d4-8387-faab0c297cbb', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3cc103c7-9960-5174-b3a0-44ee40db4e3a', '48f79ae7-467e-51d4-8387-faab0c297cbb', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3ca4ad70-66dc-563d-adc9-0a8c298e9a9a', '48f79ae7-467e-51d4-8387-faab0c297cbb', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('8e150368-ca72-5e21-b8bb-7fad908c4fb0', '48f79ae7-467e-51d4-8387-faab0c297cbb', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('048d70fe-5b9e-59b7-a69f-b810a551c21b', '48f79ae7-467e-51d4-8387-faab0c297cbb', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f5147651-bd92-5df3-8acc-2015ebb0c7c8', '48f79ae7-467e-51d4-8387-faab0c297cbb', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('49dc651b-c114-50b2-b242-27a54a183318', '4d2a8775-44da-5d08-a10b-3355335deef6', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('13db066f-c218-5e79-90ec-95c307774e88', '4d2a8775-44da-5d08-a10b-3355335deef6', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ae9ce08d-77e0-57e5-8836-8b2ddc417761', '4d2a8775-44da-5d08-a10b-3355335deef6', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('28651c3f-b26c-521c-80a6-cd2b945d2bea', '4d2a8775-44da-5d08-a10b-3355335deef6', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b7845e5c-445b-5859-901c-abcb98b06dc3', '4d2a8775-44da-5d08-a10b-3355335deef6', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('56986fbe-258a-555e-a322-56f22ef9e171', '4d2a8775-44da-5d08-a10b-3355335deef6', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7eaa3489-d9ae-524f-aacc-b0c7482689df', '4d2a8775-44da-5d08-a10b-3355335deef6', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3d880a7c-b0f7-5f25-8395-552810966c59', '82d6e296-9739-56e7-8f09-3e8b58ec8991', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f6e401c3-2e33-5573-89a9-ef29c3240080', '82d6e296-9739-56e7-8f09-3e8b58ec8991', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5100b2ce-ee3d-5e0a-8702-648c61238b7e', '82d6e296-9739-56e7-8f09-3e8b58ec8991', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('315852a3-2b04-5961-a240-0dcfdf9b72f9', '82d6e296-9739-56e7-8f09-3e8b58ec8991', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('2569e095-e28c-52cb-813f-7e61b69d5546', '82d6e296-9739-56e7-8f09-3e8b58ec8991', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('26c9e886-2f0f-5ccc-b221-e50be7fc4f0f', '82d6e296-9739-56e7-8f09-3e8b58ec8991', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('cdc7b5ad-e32a-5ffd-820b-0ffbd0176c52', '82d6e296-9739-56e7-8f09-3e8b58ec8991', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a11bfd56-3710-5912-89cc-76de334940db', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('93f4fa14-c367-5fba-82d1-20751a9d9332', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7eaa6d52-adf7-5c2d-a63c-9b97937f08ae', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('69a6dca4-a7d7-5dd2-ade1-20610260867c', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ef502726-6f8b-5a43-a77c-127114e80d1e', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('5460103b-5156-53b5-80cb-8f8a253f0138', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c95d76ae-a25d-59a8-bc50-34a5bbe1b7ca', 'ed534cdc-5692-5316-9ea3-c1340a7ce67e', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e8f64291-a005-541a-92d7-f574367023af', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('a5e45ce7-c305-53f9-acda-2026f018740d', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1a800536-2d7d-5993-a77a-add51fb92404', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('b6d0ce32-6563-5fc6-8591-26111bf75c6a', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1b8e4b8f-6044-5636-ab1e-3e663a2d66d1', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('3c113bf7-d8ab-531a-b920-586ed38ef9b0', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('f83072ec-8c6a-5eb9-b61c-ca889762563e', '6a9333ff-fd36-5c80-82a8-1ddedfa4f7a3', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('1317152e-b0e2-5dd2-83e2-2919a13dc902', '3f04aef7-33d6-53d3-89f0-66bc66058ede', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('bd670c27-abbb-596a-9bae-c6c72669af71', '3f04aef7-33d6-53d3-89f0-66bc66058ede', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('6fc98c4b-cbcc-5a5b-82e9-246800ef69bc', '3f04aef7-33d6-53d3-89f0-66bc66058ede', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7d068ac1-7dfd-5935-bbcf-cc4d1e628c4f', '3f04aef7-33d6-53d3-89f0-66bc66058ede', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('ba0c1877-f8a2-52f2-9b77-9e190e2ef2db', '3f04aef7-33d6-53d3-89f0-66bc66058ede', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('c1a77c65-749d-5e0d-aaa4-4d1ab8698014', '3f04aef7-33d6-53d3-89f0-66bc66058ede', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('e576aeab-7a50-51ef-941f-f96036113c7a', '3f04aef7-33d6-53d3-89f0-66bc66058ede', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('fddb53d0-57af-520d-8783-5787e6770cb5', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', '316044f7-27be-5646-ae5c-67c7a0db401e', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('fef58e8e-bd8d-529f-904a-236f8a218ba1', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', '2fabebf3-2b71-564d-937e-a9dd05d29222', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('07fe7672-9ee4-531c-8c06-62661e7263f8', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', '7f4b917f-56d4-52fa-af8d-a24c700e51b3', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d4570c52-0a11-5add-8f59-a520aa5af4fc', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', '564d837b-2d9c-5be7-ba86-46d2113a2275', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('82ff3945-ffed-53a1-9ae7-30b8dd2306d7', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', 'a3275c7b-23e5-5d90-83c8-57bd3c32176d', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('7e7b7a5b-41d8-5226-a19d-7cb5000b73f8', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', 'cdda014a-f46f-527f-9c89-c276c81fe06a', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;
INSERT INTO public.scheme_documents (id, scheme_id, document_type_id, is_mandatory, remarks) 
VALUES ('d3d13bc8-4a1b-5a8e-be39-6d494ce97f3b', 'fc139cd6-973c-5ba0-aeca-4c459f2f377b', '19c5350f-5d20-5b7a-9c0c-89f0a58b4081', true, 'Mandatory for application submission') 
ON CONFLICT (scheme_id, document_type_id) DO NOTHING;

COMMIT;
