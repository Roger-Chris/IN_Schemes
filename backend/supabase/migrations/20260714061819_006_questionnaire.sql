-- ===========================================================
-- Migration: 006_questionnaire
-- Project : IN Schemes
-- Purpose : Dynamic questionnaire engine
-- ===========================================================

------------------------------------------------------------
-- Questions
------------------------------------------------------------

CREATE TABLE public.questions (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    question_text TEXT NOT NULL,

    description TEXT,

    field_name TEXT NOT NULL,

    input_type TEXT NOT NULL,

    is_required BOOLEAN DEFAULT TRUE,

    display_order INTEGER DEFAULT 1,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    updated_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.questions IS
'Master list of questionnaire questions.';

------------------------------------------------------------
-- Question Options
------------------------------------------------------------

CREATE TABLE public.question_options (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    question_id UUID NOT NULL
        REFERENCES public.questions(id)
        ON DELETE CASCADE,

    option_label TEXT NOT NULL,

    option_value TEXT NOT NULL,

    next_question_id UUID
        REFERENCES public.questions(id)
        ON DELETE SET NULL,

    display_order INTEGER DEFAULT 1,

    created_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.question_options IS
'Options available for select-type questions.';

------------------------------------------------------------
-- Questionnaire Sessions
------------------------------------------------------------

CREATE TABLE public.questionnaire_sessions (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    startup_profile_id UUID NOT NULL
        REFERENCES public.startup_profiles(id)
        ON DELETE CASCADE,

    status TEXT DEFAULT 'IN_PROGRESS',

    completed_percentage NUMERIC(5,2) DEFAULT 0,

    started_at TIMESTAMPTZ DEFAULT NOW(),

    completed_at TIMESTAMPTZ

);

COMMENT ON TABLE public.questionnaire_sessions IS
'Tracks questionnaire progress for a startup profile.';

------------------------------------------------------------
-- User Responses
------------------------------------------------------------

CREATE TABLE public.user_responses (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    session_id UUID NOT NULL
        REFERENCES public.questionnaire_sessions(id)
        ON DELETE CASCADE,

    question_id UUID NOT NULL
        REFERENCES public.questions(id)
        ON DELETE CASCADE,

    answer TEXT,

    answered_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(session_id, question_id)

);

COMMENT ON TABLE public.user_responses IS
'Stores answers given during questionnaire.';