-- ===========================================================
-- Migration: 010_notifications
-- Project : IN Schemes
-- Purpose : User notifications
-- ===========================================================

CREATE TABLE public.notifications (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.users(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    message TEXT NOT NULL,

    notification_type TEXT,

    is_read BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW()

);

COMMENT ON TABLE public.notifications IS
'Stores notifications for users.';