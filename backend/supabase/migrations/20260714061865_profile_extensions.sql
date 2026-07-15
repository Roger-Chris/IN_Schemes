-- ===========================================================
-- Migration: 014_profile_extensions
-- Project : IN Schemes
-- Purpose : Add missing onboarding and profile fields to users and startup_profiles
-- ===========================================================

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS dob DATE,
ADD COLUMN IF NOT EXISTS gender VARCHAR(50),
ADD COLUMN IF NOT EXISTS disability VARCHAR(100),
ADD COLUMN IF NOT EXISTS veteran BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS house TEXT,
ADD COLUMN IF NOT EXISTS street TEXT,
ADD COLUMN IF NOT EXISTS area TEXT,
ADD COLUMN IF NOT EXISTS village TEXT,
ADD COLUMN IF NOT EXISTS pin TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS district TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS qualification TEXT,
ADD COLUMN IF NOT EXISTS employment TEXT,
ADD COLUMN IF NOT EXISTS annual_income NUMERIC(15,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS community VARCHAR(100),
ADD COLUMN IF NOT EXISTS language VARCHAR(10) DEFAULT 'en',
ADD COLUMN IF NOT EXISTS notifications BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS theme VARCHAR(20) DEFAULT 'light',
ADD COLUMN IF NOT EXISTS google_user_id TEXT,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS provider TEXT DEFAULT 'google',
ADD COLUMN IF NOT EXISTS last_login_time TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.startup_profiles 
ADD COLUMN IF NOT EXISTS registration_numbers TEXT;
