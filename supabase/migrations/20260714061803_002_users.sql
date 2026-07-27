CREATE TABLE public.users (

    id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    full_name TEXT NOT NULL,

    dob DATE,

    gender TEXT,

    phone VARCHAR(20),

    address TEXT,

    state TEXT,

    district TEXT,

    city TEXT,

    pincode VARCHAR(10),

    community TEXT,

    employment_status TEXT,

    annual_family_income NUMERIC,

    profile_photo_url TEXT,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    updated_at TIMESTAMPTZ DEFAULT NOW()

);