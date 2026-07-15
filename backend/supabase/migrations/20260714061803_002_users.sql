-- =====================================================
-- Migration: 002_users
-- Project: IN Schemes
-- Description: Application user profiles
-- =====================================================

CREATE TABLE public.users (

    id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    full_name TEXT NOT NULL,

    phone VARCHAR(20),

    profile_photo_url TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

COMMENT ON TABLE public.users IS
'Stores application-specific user information linked to Supabase Auth.';