-- ===========================================================
-- SQL Test Verification Queries
-- Project : IN Schemes
-- Purpose : Verification of DB functions, integrity, RLS & performance
-- ===========================================================

------------------------------------------------------------
-- 1. Test Recommendation Engine
------------------------------------------------------------
SELECT 
    scheme_id,
    scheme_name,
    match_score,
    recommendation_reason,
    matched_rules::jsonb,
    failed_rules::jsonb
FROM public.recommend_schemes('c4d0a1b2-3c4d-5e6f-7a8b-9c0d1e2f3a4b'::uuid);

------------------------------------------------------------
-- 2. Test Semantic Search
------------------------------------------------------------
-- Test search_schemes using a zero-vector mock embedding
SELECT 
    scheme_id,
    scheme_code,
    scheme_name,
    similarity_score,
    issuing_department
FROM public.search_schemes(array_fill(0.0::real, ARRAY[1536])::vector);

------------------------------------------------------------
-- 3. Verify Foreign Keys and Reference Integrity
------------------------------------------------------------
-- Schemes referencing documents
SELECT s.scheme_name, dt.document_name, sd.is_mandatory
FROM public.scheme_documents sd
JOIN public.schemes s ON sd.scheme_id = s.id
JOIN public.document_types dt ON sd.document_type_id = dt.id;

-- Schemes referencing services
SELECT s.scheme_name, sv.service_name, ss.is_required
FROM public.scheme_services ss
JOIN public.schemes s ON ss.scheme_id = s.id
JOIN public.services sv ON ss.service_id = sv.id;

-- User responses referencing questions
SELECT qs.startup_profile_id, q.question_text, ur.answer
FROM public.user_responses ur
JOIN public.questionnaire_sessions qs ON ur.session_id = qs.id
JOIN public.questions q ON ur.question_id = q.id;

------------------------------------------------------------
-- 4. Test RLS (Row Level Security) Policies
------------------------------------------------------------
-- Set role and mock user ID to verify RLS
SET local role authenticated;
SET local request.jwt.claim.sub = 'a6b18c0f-081b-4632-a5be-bf463dc36df8';

-- Verify the user can read their own startup profile
SELECT id, profile_name FROM public.startup_profiles;

-- Verify the user can read their own responses
SELECT * FROM public.user_responses;

-- Verify the user CANNOT read other users' responses (should return 0 rows if tested with different sub)
SET local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000000';
SELECT * FROM public.user_responses;

-- Reset role to admin/postgres for further checks
RESET role;

------------------------------------------------------------
-- 5. Verify Indexes are Present and Valid
------------------------------------------------------------
SELECT 
    tablename,
    indexname,
    indexdef
FROM 
    pg_indexes
WHERE 
    schemaname = 'public'
ORDER BY 
    tablename, 
    indexname;
