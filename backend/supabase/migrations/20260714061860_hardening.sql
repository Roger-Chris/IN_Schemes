-- ===========================================================
-- Migration: 015_hardening
-- Project : IN Schemes
-- Purpose : Database hardening, safe evaluation, constraint validation, RLS, and HNSW index.
-- ===========================================================

------------------------------------------------------------
-- 1. Table Constraints on Eligibility Rules
------------------------------------------------------------

ALTER TABLE public.eligibility_rules
    ADD CONSTRAINT chk_operator 
    CHECK (operator IN ('=', 'IN', 'BETWEEN', '>', '>=', '<', '<='));

ALTER TABLE public.eligibility_rules
    ADD CONSTRAINT chk_between_format 
    CHECK (operator <> 'BETWEEN' OR value ~ '^\s*-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?\s*$');

------------------------------------------------------------
-- 2. Safe Numeric Casting Helper
------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.safe_cast_to_numeric(val text)
RETURNS numeric AS $$
BEGIN
    RETURN val::numeric;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

------------------------------------------------------------
-- 3. Robust Recommendation Engine Function
------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.recommend_schemes(startup_profile_id UUID)
RETURNS TABLE (
    scheme_id UUID,
    scheme_name TEXT,
    match_score NUMERIC,
    matched_rules JSONB,
    failed_rules JSONB,
    recommendation_reason TEXT
) AS $$
DECLARE
    sp_row public.startup_profiles%ROWTYPE;
    sp_json jsonb;
    s_row record;
    r_row record;
    rule_passed boolean;
    val_text text;
    rule_val_numeric numeric;
    rule_val_min numeric;
    rule_val_max numeric;
    rule_single_numeric numeric;
    temp_matched jsonb;
    temp_failed jsonb;
    total_rules int;
    passed_rules int;
    final_score numeric;
    reason text;
BEGIN
    -- Get startup profile
    SELECT * INTO sp_row FROM public.startup_profiles WHERE id = startup_profile_id;
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- TODO: The startup_profiles table currently lacks a 'state' column.
    -- Once a 'state' column is added to public.startup_profiles, it should be read
    -- directly from the profile row instead of using hardcoded fallbacks.
    sp_json := to_jsonb(sp_row);

    -- Loop through all active schemes
    FOR s_row IN SELECT * FROM public.schemes WHERE is_active = true LOOP
        temp_matched := '[]'::jsonb;
        temp_failed := '[]'::jsonb;
        total_rules := 0;
        passed_rules := 0;
        
        -- Loop through rules for this scheme
        FOR r_row IN SELECT * FROM public.eligibility_rules WHERE scheme_id = s_row.id LOOP
            total_rules := total_rules + 1;
            rule_passed := false;
            
            -- Get value from startup profile
            val_text := sp_json->>r_row.parameter_name;
            
            IF val_text IS NOT NULL THEN
                -- Evaluate based on operator
                IF r_row.operator = '=' THEN
                    IF lower(val_text) = lower(r_row.value) THEN
                        rule_passed := true;
                    END IF;
                ELSIF r_row.operator = '!=' THEN
                    IF lower(val_text) != lower(r_row.value) THEN
                        rule_passed := true;
                    END IF;
                ELSIF r_row.operator = 'IN' THEN
                    -- Check if val_text is in comma-separated rule values
                    IF EXISTS (
                        SELECT 1 FROM unnest(string_to_array(r_row.value, ',')) AS elem
                        WHERE trim(lower(elem)) = trim(lower(val_text))
                    ) THEN
                        rule_passed := true;
                    END IF;
                ELSIF r_row.operator = 'NOT IN' THEN
                    -- Check if val_text is NOT in comma-separated rule values
                    IF NOT EXISTS (
                        SELECT 1 FROM unnest(string_to_array(r_row.value, ',')) AS elem
                        WHERE trim(lower(elem)) = trim(lower(val_text))
                    ) THEN
                        rule_passed := true;
                    END IF;
                ELSIF r_row.operator = 'CONTAINS' THEN
                    -- Case-insensitive string containment check
                    IF position(lower(r_row.value) in lower(val_text)) > 0 THEN
                        rule_passed := true;
                    END IF;
                ELSIF r_row.operator = 'BETWEEN' THEN
                    rule_val_numeric := public.safe_cast_to_numeric(val_text);
                    rule_val_min := public.safe_cast_to_numeric(split_part(r_row.value, ',', 1));
                    rule_val_max := public.safe_cast_to_numeric(split_part(r_row.value, ',', 2));
                    
                    IF rule_val_numeric IS NOT NULL AND rule_val_min IS NOT NULL AND rule_val_max IS NOT NULL THEN
                        IF rule_val_numeric >= rule_val_min AND rule_val_numeric <= rule_val_max THEN
                            rule_passed := true;
                        END IF;
                    END IF;
                ELSIF r_row.operator = '>' THEN
                    rule_val_numeric := public.safe_cast_to_numeric(val_text);
                    rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
                    IF rule_val_numeric IS NOT NULL AND rule_single_numeric IS NOT NULL THEN
                        IF rule_val_numeric > rule_single_numeric THEN
                            rule_passed := true;
                        END IF;
                    END IF;
                ELSIF r_row.operator = '>=' THEN
                    rule_val_numeric := public.safe_cast_to_numeric(val_text);
                    rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
                    IF rule_val_numeric IS NOT NULL AND rule_single_numeric IS NOT NULL THEN
                        IF rule_val_numeric >= rule_single_numeric THEN
                            rule_passed := true;
                        END IF;
                    END IF;
                ELSIF r_row.operator = '<' THEN
                    rule_val_numeric := public.safe_cast_to_numeric(val_text);
                    rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
                    IF rule_val_numeric IS NOT NULL AND rule_single_numeric IS NOT NULL THEN
                        IF rule_val_numeric < rule_single_numeric THEN
                            rule_passed := true;
                        END IF;
                    END IF;
                ELSIF r_row.operator = '<=' THEN
                    rule_val_numeric := public.safe_cast_to_numeric(val_text);
                    rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
                    IF rule_val_numeric IS NOT NULL AND rule_single_numeric IS NOT NULL THEN
                        IF rule_val_numeric <= rule_single_numeric THEN
                            rule_passed := true;
                        END IF;
                    END IF;
                END IF;
            END IF;
            
            IF rule_passed THEN
                passed_rules := passed_rules + 1;
                temp_matched := temp_matched || jsonb_build_object(
                    'rule_id', r_row.id,
                    'parameter', r_row.parameter_name,
                    'description', r_row.description
                );
            ELSE
                temp_failed := temp_failed || jsonb_build_object(
                    'rule_id', r_row.id,
                    'parameter', r_row.parameter_name,
                    'description', r_row.description
                );
            END IF;
        END LOOP;
        
        -- Calculate score
        IF total_rules > 0 THEN
            final_score := round((passed_rules::numeric / total_rules::numeric) * 100, 2);
        ELSE
            final_score := 100.00;
        END IF;
        
        -- Recommendation reason
        IF jsonb_array_length(temp_failed) = 0 THEN
            reason := 'Your startup profile perfectly matches all eligibility criteria for this scheme.';
        ELSIF jsonb_array_length(temp_failed) <= 1 THEN
            reason := 'Your startup profile matches most of the eligibility criteria.';
        ELSE
            reason := 'Your startup profile does not meet several eligibility criteria.';
        END IF;
        
        scheme_id := s_row.id;
        scheme_name := s_row.scheme_name;
        match_score := final_score;
        matched_rules := temp_matched;
        failed_rules := temp_failed;
        recommendation_reason := reason;
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------
-- 4. Enable RLS & Add Public View Policies on Remaining Tables
------------------------------------------------------------

ALTER TABLE public.scheme_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view scheme documents" ON public.scheme_documents;
CREATE POLICY "Public can view scheme documents" 
ON public.scheme_documents FOR SELECT USING (true);

ALTER TABLE public.scheme_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view scheme services" ON public.scheme_services;
CREATE POLICY "Public can view scheme services" 
ON public.scheme_services FOR SELECT USING (true);

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view questions" ON public.questions;
CREATE POLICY "Public can view questions" 
ON public.questions FOR SELECT USING (true);

ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view question options" ON public.question_options;
CREATE POLICY "Public can view question options" 
ON public.question_options FOR SELECT USING (true);

ALTER TABLE public.search_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view search documents" ON public.search_documents;
CREATE POLICY "Public can view search documents" 
ON public.search_documents FOR SELECT USING (true);

ALTER TABLE public.query_cache ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can manage query cache" ON public.query_cache;
CREATE POLICY "Anyone can manage query cache" 
ON public.query_cache FOR ALL USING (true);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view admin users" ON public.admin_users;
CREATE POLICY "Admins can view admin users" 
ON public.admin_users FOR SELECT USING (true);

------------------------------------------------------------
-- 5. Upgrade pgvector Index to HNSW (Supabase Postgres Compatible)
------------------------------------------------------------

DROP INDEX IF EXISTS public.idx_search_embedding;

CREATE INDEX idx_search_embedding
ON public.search_documents
USING hnsw (embedding vector_cosine_ops);
