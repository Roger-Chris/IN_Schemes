-- ===========================================================
-- Migration: 009_search
-- Project : IN Schemes
-- Purpose : Semantic Search using OpenAI Embeddings + pgvector
-- ===========================================================

------------------------------------------------------------
-- Search Documents
------------------------------------------------------------

CREATE TABLE public.search_documents (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    scheme_id UUID NOT NULL
        REFERENCES public.schemes(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    content TEXT NOT NULL,

    embedding VECTOR(1536),

    language TEXT DEFAULT 'English',

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    updated_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.search_documents IS
'Stores searchable content and embeddings for semantic search.';

------------------------------------------------------------
-- Query Cache
------------------------------------------------------------

CREATE TABLE public.query_cache (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    query TEXT NOT NULL,

    embedding VECTOR(1536),

    created_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.query_cache IS
'Caches query embeddings to reduce OpenAI API calls.';