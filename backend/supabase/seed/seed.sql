-- Seed Data for NEEDS reference implementation

DO $$
DECLARE
    v_user_id UUID;
    v_scheme_id UUID := 'e5f6a7b8-9c0d-1e2f-3a4b-5c6d7e8f9a0b';
    v_profile_id UUID := 'c4d0a1b2-3c4d-5e6f-7a8b-9c0d1e2f3a4b';
    v_session_id UUID := 'qs101010-1010-1010-1010-101010101010';
BEGIN
    -- 1. Retrieve a user from auth.users (to respect the foreign key constraint public.users -> auth.users)
    -- We do NOT insert into auth.users directly.
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'To run this seed script, please first sign up at least one user via Supabase Auth so that a row exists in auth.users.';
    END IF;

    -- 2. Create profile in public.users
    INSERT INTO public.users (id, full_name, phone, is_active)
    VALUES (v_user_id, 'Rajesh Kumar', '+919876543210', true)
    ON CONFLICT (id) DO NOTHING;

    -- 3. Create Startup Profile (Eligible for NEEDS)
    INSERT INTO public.startup_profiles (
        id, user_id, profile_name, description, industry, applicant_type, 
        business_stage, business_registered, funding_required_amount, 
        funding_purpose, is_first_generation_entrepreneur, is_active
    )
    VALUES (
        v_profile_id, v_user_id, 'AgriTech Processing Unit', 
        'Setting up a modern food processing and packaging unit in Madurai.', 
        'Manufacturing', 'MSME', 'Prototype', true, 1500000.00, 
        'Purchase of machinery and factory setup.', true, true
    )
    ON CONFLICT (id) DO NOTHING;

    -- 4. Create NEEDS Scheme
    INSERT INTO public.schemes (
        id, scheme_code, scheme_name, government_level, issuing_department, 
        issuing_body, state, target_sector, target_beneficiary, scheme_type, 
        overview, objectives, benefits_description, subsidy_percentage, 
        subsidy_amount, max_funding_amount, minimum_funding_amount, 
        application_mode, official_website, application_url, guidelines_url, 
        language, search_keywords, status, version, is_active
    )
    VALUES (
        v_scheme_id, 'NEEDS', 'New Entrepreneur-cum-Enterprise Development Scheme (NEEDS)', 
        'State', 'Department of Industries and Commerce', 
        'Tamil Nadu Corporation for Development of Women / MSME Department', 
        'Tamil Nadu', 'Manufacturing, Service', 'First Generation Entrepreneurs', 
        'Subsidy Linked Loan', 
        'The Government of Tamil Nadu has introduced the NEEDS scheme to assist educated youth to become first-generation entrepreneurs by providing them training and financial assistance.', 
        'To promote first-generation entrepreneurs by providing entrepreneurship training and facilitating capital and interest subsidy to start manufacturing or service enterprises.', 
        '25% Capital Subsidy of the project cost (maximum Rs. 50 Lakhs) and 3% interest subvention during the entire repayment period.', 
        25.00, 5000000.00, 50000000.00, 500000.00, 'Online', 'https://www.msmeonline.tn.gov.in', 
        'https://www.msmeonline.tn.gov.in/needs', 'https://www.msmeonline.tn.gov.in/needs/guidelines.pdf', 
        'English', 'Tamil Nadu, NEEDS, subsidy, first generation entrepreneur, manufacturing, service, capital subsidy', 
        'ACTIVE', 1, true
    )
    ON CONFLICT (id) DO NOTHING;

    -- 5. Create Eligibility Rules for NEEDS
    INSERT INTO public.eligibility_rules (id, scheme_id, parameter_name, operator, value, description)
    VALUES
      ('f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', v_scheme_id, 'state', '=', 'Tamil Nadu', 'Business must be situated in Tamil Nadu.'),
      ('f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6d', v_scheme_id, 'is_first_generation_entrepreneur', '=', 'true', 'Applicant must be a first-generation entrepreneur.'),
      ('f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6e', v_scheme_id, 'industry', 'IN', 'Manufacturing, Service', 'Only Manufacturing and Service sectors are eligible (trading excluded).'),
      ('f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6f', v_scheme_id, 'funding_required_amount', 'BETWEEN', '500000, 50000000', 'Project cost must be between Rs. 5 Lakhs and Rs. 5 Crores.')
    ON CONFLICT (id) DO NOTHING;

    -- 6. Create Document Types
    INSERT INTO public.document_types (id, document_name, description, issuing_authority, estimated_processing_days, is_mandatory_default)
    VALUES
      ('d1010101-1010-1010-1010-101010101010', 'Aadhaar Card', 'Identity and address proof issued by UIDAI.', 'UIDAI', 1, true),
      ('d2020202-2020-2020-2020-202020202020', 'Degree or Diploma Certificate', 'Proof of educational qualification.', 'Recognized University / Board', 1, true),
      ('d3030303-3030-3030-3030-303020202020', 'Detailed Project Report (DPR)', 'Project feasibility and financial estimates report.', 'Empaneled Consultants / Self', 7, true),
      ('d4040404-4040-4040-4040-404020202020', 'Community Certificate', 'Required for special category benefits and age relaxation.', 'Revenue Department', 15, false)
    ON CONFLICT (id) DO NOTHING;

    -- 7. Link Documents to NEEDS
    INSERT INTO public.scheme_documents (scheme_id, document_type_id, is_mandatory, remarks)
    VALUES
      (v_scheme_id, 'd1010101-1010-1010-1010-101010101010', true, 'Aadhaar of applicant.'),
      (v_scheme_id, 'd2020202-2020-2020-2020-202020202020', true, 'Must have at least a Degree, Diploma, ITI, or Vocational Training.'),
      (v_scheme_id, 'd3030303-3030-3030-3030-303020202020', true, 'Detailed Project Report specifying machinery and costs.')
    ON CONFLICT (scheme_id, document_type_id) DO NOTHING;

    -- 8. Create Services
    INSERT INTO public.services (id, service_name, category, description, is_active)
    VALUES
      ('s1010101-1010-1010-1010-101010101010', 'Entrepreneurship Development Programme (EDP) Training', 'Training', 'Mandatory 15-day training program conducted by EDII Tamil Nadu.', true),
      ('s2020202-2020-2020-2020-202020202020', 'Project Report Preparation Assistance', 'Consultancy', 'Help with creating Detailed Project Reports.', true)
    ON CONFLICT (id) DO NOTHING;

    -- 9. Link Services to NEEDS
    INSERT INTO public.scheme_services (scheme_id, service_id, is_required, remarks)
    VALUES
      (v_scheme_id, 's1010101-1010-1010-1010-101010101010', true, 'Completion certificate of EDP training is mandatory for loan disbursement.')
    ON CONFLICT (scheme_id, service_id) DO NOTHING;

    -- 10. Create Questionnaire for NEEDS eligibility
    INSERT INTO public.questions (id, question_text, description, field_name, input_type, is_required, display_order)
    VALUES
      ('q1010101-1010-1010-1010-101010101010', 'Are you a first-generation entrepreneur?', 'Select Yes if no one in your immediate family owns an registered business.', 'is_first_generation_entrepreneur', 'SELECT', true, 1),
      ('q2020202-2020-2020-2020-202020202020', 'What is your business sector?', 'NEEDS supports manufacturing and services.', 'industry', 'SELECT', true, 2)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.question_options (id, question_id, option_label, option_value, display_order)
    VALUES
      ('qo101010-1010-1010-1010-101010101010', 'q1010101-1010-1010-1010-101010101010', 'Yes, I am the first in my family', 'true', 1),
      ('qo101010-1010-1010-1010-101010101011', 'q1010101-1010-1010-1010-101010101010', 'No, my family has business background', 'false', 2),
      ('qo202020-2020-2020-2020-202020202020', 'q2020202-2020-2020-2020-202020202020', 'Manufacturing Enterprise', 'Manufacturing', 1),
      ('qo202020-2020-2020-2020-202020202021', 'q2020202-2020-2020-2020-202020202020', 'Service Enterprise', 'Service', 2),
      ('qo202020-2020-2020-2020-202020202022', 'q2020202-2020-2020-2020-202020202020', 'Trading / Retail Enterprise', 'Trading', 3)
    ON CONFLICT (id) DO NOTHING;

    -- 11. Questionnaire Session and Responses for Rajesh
    INSERT INTO public.questionnaire_sessions (id, startup_profile_id, status, completed_percentage)
    VALUES
      (v_session_id, v_profile_id, 'COMPLETED', 100.00)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.user_responses (session_id, question_id, answer)
    VALUES
      (v_session_id, 'q1010101-1010-1010-1010-101010101010', 'true'),
      (v_session_id, 'q2020202-2020-2020-2020-202020202020', 'Manufacturing')
    ON CONFLICT (session_id, question_id) DO NOTHING;

    -- 12. Create recommendations
    INSERT INTO public.recommendations (startup_profile_id, scheme_id, match_score, recommendation_rank, recommendation_reason)
    VALUES (
      v_profile_id, v_scheme_id, 100.00, 1, 
      'Your startup profile perfectly matches all eligibility criteria for this scheme.'
    )
    ON CONFLICT (startup_profile_id, scheme_id) DO NOTHING;

    -- 13. Create a Search Document for NEEDS with mock embedding
    INSERT INTO public.search_documents (id, scheme_id, title, content, embedding, language, is_active)
    VALUES (
      'sd101010-1010-1010-1010-101010101010', v_scheme_id, 
      'New Entrepreneur-cum-Enterprise Development Scheme (NEEDS) Tamil Nadu', 
      'New Entrepreneur-cum-Enterprise Development Scheme (NEEDS) is a flagship scheme of the Government of Tamil Nadu designed to assist educated youth to become first-generation entrepreneurs. Eligible industries include Manufacturing and Service sector projects. Trading and retail businesses are strictly excluded. The scheme requires the applicant to establish the project in the state of Tamil Nadu. First-generation entrepreneurs with a degree, diploma, ITI, or vocational certificate are eligible. The project funding cost ranges from a minimum of Rs 5 Lakhs to a maximum of Rs 5 Crores. Benefits include a 25% capital subsidy of the project cost (capped at Rs 50 Lakhs) and a 3% interest subvention on the loan. Capital subsidy and financial assistance promote regional growth, youth employment, and industrial development within Tamil Nadu.', 
      array_fill(0.0::real, ARRAY[1536])::vector, 
      'English', true
    )
    ON CONFLICT (id) DO NOTHING;

    -- 14. Create a notification
    INSERT INTO public.notifications (user_id, title, message, notification_type, is_read)
    VALUES (
      v_user_id, 'NEEDS Reference Scheme Ready', 
      'The NEEDS scheme reference implementation has been successfully seeded.', 
      'SYSTEM', false
    )
    ON CONFLICT (id) DO NOTHING;

    -- 15. Create admin user
    INSERT INTO public.admin_users (email, full_name, role, is_active)
    VALUES (
      'admin@inschemes.tn.gov.in', 'Admin Officer', 'SUPER_ADMIN', true
    )
    ON CONFLICT (email) DO NOTHING;

END $$;
