-- ===========================================================
-- Migration: 008_recommendations
-- Project : IN Schemes
-- Purpose : Recommendation results
-- ===========================================================

CREATE TABLE public.recommendations (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    startup_profile_id UUID NOT NULL
        REFERENCES public.startup_profiles(id)
        ON DELETE CASCADE,

    scheme_id UUID NOT NULL
        REFERENCES public.schemes(id)
        ON DELETE CASCADE,

    match_score NUMERIC(5,2) NOT NULL,

    recommendation_rank INTEGER NOT NULL,

    recommendation_reason TEXT,

    generated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(startup_profile_id, scheme_id)

);

COMMENT ON TABLE public.recommendations IS
'Stores generated scheme recommendations for each startup profile.';