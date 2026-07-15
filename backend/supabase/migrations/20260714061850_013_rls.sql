-- ===========================================================
-- Migration: 013_rls
-- Project : IN Schemes
-- Purpose : Row Level Security
-- ===========================================================

------------------------------------------------------------
-- Enable RLS
------------------------------------------------------------

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.startup_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questionnaire_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

------------------------------------------------------------
-- USERS
------------------------------------------------------------

CREATE POLICY "Users can manage their own profile"
ON public.users
FOR ALL
USING (auth.uid() = id);

------------------------------------------------------------
-- STARTUP PROFILES
------------------------------------------------------------

CREATE POLICY "Users manage own startup profiles"
ON public.startup_profiles
FOR ALL
USING (auth.uid() = user_id);

------------------------------------------------------------
-- QUESTIONNAIRE
------------------------------------------------------------

CREATE POLICY "Users manage own questionnaire sessions"
ON public.questionnaire_sessions
FOR ALL
USING (
    startup_profile_id IN (
        SELECT id
        FROM public.startup_profiles
        WHERE user_id = auth.uid()
    )
);

------------------------------------------------------------
-- USER RESPONSES
------------------------------------------------------------

CREATE POLICY "Users manage own responses"
ON public.user_responses
FOR ALL
USING (
    EXISTS (
        SELECT 1
        FROM public.questionnaire_sessions qs
        JOIN public.startup_profiles sp ON qs.startup_profile_id = sp.id
        WHERE qs.id = user_responses.session_id
          AND sp.user_id = auth.uid()
    )
);

------------------------------------------------------------
-- RECOMMENDATIONS
------------------------------------------------------------

CREATE POLICY "Users view own recommendations"
ON public.recommendations
FOR ALL
USING (
    startup_profile_id IN (
        SELECT id
        FROM public.startup_profiles
        WHERE user_id = auth.uid()
    )
);

------------------------------------------------------------
-- NOTIFICATIONS
------------------------------------------------------------

CREATE POLICY "Users manage own notifications"
ON public.notifications
FOR ALL
USING (
    user_id = auth.uid()
);

------------------------------------------------------------
-- Public Read Access
------------------------------------------------------------

ALTER TABLE public.schemes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view schemes"
ON public.schemes
FOR SELECT
USING (true);

ALTER TABLE public.document_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view documents"
ON public.document_types
FOR SELECT
USING (true);

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view services"
ON public.services
FOR SELECT
USING (true);

ALTER TABLE public.eligibility_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view eligibility rules"
ON public.eligibility_rules
FOR SELECT
USING (true);