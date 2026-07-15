-- ===========================================================
-- Migration: 005_documents
-- Project : IN Schemes
-- Purpose : Required documents for government schemes
-- ===========================================================

---------------------------------------------------------------
-- Master Document Types
---------------------------------------------------------------

CREATE TABLE public.document_types (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    document_name TEXT NOT NULL UNIQUE,

    description TEXT,

    issuing_authority TEXT,

    official_apply_url TEXT,

    official_verify_url TEXT,

    estimated_processing_days INTEGER,

    is_mandatory_default BOOLEAN DEFAULT TRUE,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    updated_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.document_types IS
'Master list of all document types used across schemes.';

---------------------------------------------------------------
-- Scheme Documents
---------------------------------------------------------------

CREATE TABLE public.scheme_documents (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    scheme_id UUID NOT NULL
        REFERENCES public.schemes(id)
        ON DELETE CASCADE,

    document_type_id UUID NOT NULL
        REFERENCES public.document_types(id)
        ON DELETE CASCADE,

    is_mandatory BOOLEAN DEFAULT TRUE,

    remarks TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (scheme_id, document_type_id)

);

COMMENT ON TABLE public.scheme_documents IS
'Maps required documents to government schemes.';
