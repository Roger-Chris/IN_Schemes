-- ===========================================================
-- Migration: 003_startup_profiles
-- Project : IN Schemes
-- Purpose : Stores multiple startup ideas created by a user
-- ===========================================================

CREATE TABLE public.startup_profiles (

    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Owner of this startup profile
    user_id UUID NOT NULL
        REFERENCES public.users(id)
        ON DELETE CASCADE,

    ------------------------------------------------------------
    -- Startup Information
    ------------------------------------------------------------

    profile_name TEXT NOT NULL,

    description TEXT,

    industry TEXT NOT NULL,

    applicant_type TEXT NOT NULL,

    business_stage TEXT NOT NULL,

    business_registered BOOLEAN NOT NULL DEFAULT FALSE,

    funding_required_amount NUMERIC(15,2),

    funding_purpose TEXT,

    is_first_generation_entrepreneur BOOLEAN NOT NULL DEFAULT FALSE,

    ------------------------------------------------------------
    -- Profile Status
    ------------------------------------------------------------

    is_active BOOLEAN NOT NULL DEFAULT FALSE,

    last_used_at TIMESTAMPTZ,

    ------------------------------------------------------------
    -- Audit Fields
    ------------------------------------------------------------

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    ------------------------------------------------------------
    -- Constraints
    ------------------------------------------------------------

    CONSTRAINT chk_funding_amount
        CHECK (
            funding_required_amount IS NULL
            OR funding_required_amount >= 0
        ),

    CONSTRAINT chk_business_stage
        CHECK (
            business_stage IN (
                'Idea',
                'Prototype',
                'Registered',
                'Operational',
                'Expansion'
            )
        )

);

------------------------------------------------------------
-- Comments
------------------------------------------------------------

COMMENT ON TABLE public.startup_profiles IS
'Stores multiple startup ideas created by an entrepreneur.';

COMMENT ON COLUMN public.startup_profiles.profile_name IS
'Friendly name of the startup idea. Example: AI Startup';

COMMENT ON COLUMN public.startup_profiles.industry IS
'Technology, Agriculture, Manufacturing, Healthcare, etc.';

COMMENT ON COLUMN public.startup_profiles.applicant_type IS
'Student, Woman Entrepreneur, SHG, Farmer, Artisan, MSME, etc.';

COMMENT ON COLUMN public.startup_profiles.business_stage IS
'Current stage of the startup.';

COMMENT ON COLUMN public.startup_profiles.funding_required_amount IS
'Estimated funding required for the startup.';