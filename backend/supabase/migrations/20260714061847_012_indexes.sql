-- ===========================================================
-- Migration: 012_indexes
-- Project : IN Schemes
-- Purpose : Performance Indexes
-- ===========================================================

------------------------------------------------------------
-- Users
------------------------------------------------------------

CREATE INDEX idx_users_phone
ON public.users(phone);

------------------------------------------------------------
-- Startup Profiles
------------------------------------------------------------

CREATE INDEX idx_startup_profiles_user
ON public.startup_profiles(user_id);

CREATE INDEX idx_startup_profiles_active
ON public.startup_profiles(is_active);

------------------------------------------------------------
-- Schemes
------------------------------------------------------------

CREATE INDEX idx_schemes_name
ON public.schemes(scheme_name);

CREATE INDEX idx_schemes_code
ON public.schemes(scheme_code);

CREATE INDEX idx_schemes_state
ON public.schemes(state);

CREATE INDEX idx_schemes_category
ON public.schemes(scheme_category);

CREATE INDEX idx_schemes_active
ON public.schemes(is_active);

------------------------------------------------------------
-- Eligibility Rules
------------------------------------------------------------

CREATE INDEX idx_rules_scheme
ON public.eligibility_rules(scheme_id);

------------------------------------------------------------
-- Documents
------------------------------------------------------------

CREATE INDEX idx_scheme_documents_scheme
ON public.scheme_documents(scheme_id);

------------------------------------------------------------
-- Questionnaire
------------------------------------------------------------

CREATE INDEX idx_question_options_question
ON public.question_options(question_id);

CREATE INDEX idx_user_responses_session
ON public.user_responses(session_id);

------------------------------------------------------------
-- Services
------------------------------------------------------------

CREATE INDEX idx_scheme_services_scheme
ON public.scheme_services(scheme_id);

------------------------------------------------------------
-- Recommendations
------------------------------------------------------------

CREATE INDEX idx_recommendations_profile
ON public.recommendations(startup_profile_id);

CREATE INDEX idx_recommendations_score
ON public.recommendations(match_score DESC);

------------------------------------------------------------
-- Notifications
------------------------------------------------------------

CREATE INDEX idx_notifications_user
ON public.notifications(user_id);

------------------------------------------------------------
-- Search
------------------------------------------------------------

CREATE INDEX idx_search_documents_scheme
ON public.search_documents(scheme_id);

CREATE INDEX idx_query_cache_query
ON public.query_cache(query);

------------------------------------------------------------
-- pgvector Index
------------------------------------------------------------

CREATE INDEX idx_search_embedding
ON public.search_documents
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);