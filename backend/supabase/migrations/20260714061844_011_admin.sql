-- ===========================================================
-- Migration: 011_admin
-- Project : IN Schemes
-- Purpose : Admin management
-- ===========================================================

CREATE TABLE public.admin_users (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email TEXT UNIQUE NOT NULL,

    full_name TEXT NOT NULL,

    role TEXT DEFAULT 'CONTENT_EDITOR',

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.admin_users IS
'Administrators who manage schemes.';