-- ===========================================================
-- Migration: 004_schemes
-- Project : IN Schemes
-- Purpose : Master table for all Government Schemes
-- ===========================================================

CREATE TABLE public.schemes (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    scheme_code VARCHAR(50) UNIQUE NOT NULL,

    scheme_name TEXT NOT NULL,

    government_level TEXT NOT NULL,

    issuing_department TEXT,

    issuing_body TEXT,

    state TEXT,

    target_sector TEXT,

    target_beneficiary TEXT,

    scheme_type TEXT,

    scheme_category TEXT,

    overview TEXT,

    objectives TEXT,

    benefits_description TEXT,

    subsidy_percentage NUMERIC(5,2),

    subsidy_amount NUMERIC(15,2),

    interest_subvention_rate NUMERIC(5,2),

    max_funding_amount NUMERIC(15,2),

    minimum_funding_amount NUMERIC(15,2),

    application_mode TEXT,

    official_website TEXT,

    application_url TEXT,

    guidelines_url TEXT,

    language TEXT DEFAULT 'English',

    search_keywords TEXT,

    status TEXT DEFAULT 'ACTIVE',

    version INTEGER DEFAULT 1,

    is_active BOOLEAN DEFAULT TRUE,

    last_verified_at DATE,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    updated_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.schemes IS
'Master table storing all Government Schemes.';

------------------------------------------------------------
-- Eligibility Rules
------------------------------------------------------------

CREATE TABLE public.eligibility_rules (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    scheme_id UUID NOT NULL
        REFERENCES public.schemes(id)
        ON DELETE CASCADE,

    parameter_name TEXT NOT NULL,

    operator VARCHAR(50) NOT NULL,

    value TEXT NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    updated_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.eligibility_rules IS
'Rules defining eligibility criteria for schemes.';