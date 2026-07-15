-- ===========================================================
-- Migration: 007_services
-- Project : IN Schemes
-- Purpose : Entrepreneur support services
-- ===========================================================

------------------------------------------------------------
-- Master Services
------------------------------------------------------------

CREATE TABLE public.services (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    service_name TEXT NOT NULL UNIQUE,

    category TEXT,

    description TEXT,

    icon TEXT,

    official_website TEXT,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    updated_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.services IS
'Master list of entrepreneur support services.';

------------------------------------------------------------
-- Scheme Services
------------------------------------------------------------

CREATE TABLE public.scheme_services (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    scheme_id UUID NOT NULL
        REFERENCES public.schemes(id)
        ON DELETE CASCADE,

    service_id UUID NOT NULL
        REFERENCES public.services(id)
        ON DELETE CASCADE,

    is_required BOOLEAN DEFAULT FALSE,

    remarks TEXT,

    display_order INTEGER DEFAULT 1,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(scheme_id, service_id)

);

COMMENT ON TABLE public.scheme_services IS
'Maps entrepreneur support services to schemes.';