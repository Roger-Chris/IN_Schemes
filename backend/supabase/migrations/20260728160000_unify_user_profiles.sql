-- ===========================================================
-- Migration: unify_user_profiles
-- Project : IN Schemes
-- Purpose : Add columns from public.users to public.profiles, repoint constraints, and drop public.users.
-- ===========================================================

-- 1. Add missing demographic/preferences columns to public.profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS dob DATE,
ADD COLUMN IF NOT EXISTS gender VARCHAR(50),
ADD COLUMN IF NOT EXISTS disability VARCHAR(100),
ADD COLUMN IF NOT EXISTS veteran BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS house TEXT,
ADD COLUMN IF NOT EXISTS street TEXT,
ADD COLUMN IF NOT EXISTS area TEXT,
ADD COLUMN IF NOT EXISTS village TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS qualification TEXT,
ADD COLUMN IF NOT EXISTS annual_income NUMERIC(15,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS community VARCHAR(100),
ADD COLUMN IF NOT EXISTS notifications BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS theme VARCHAR(20) DEFAULT 'light',
ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- 2. Data migration (Copy existing records from public.users to public.profiles)
-- We use a fallback email since email is NOT NULL in public.profiles.
INSERT INTO public.profiles (
    id, email, name, photo_url, language, navigation_mode, applicant_type, state, district, pincode, is_profile_complete, created_at, updated_at, last_login_at,
    dob, gender, disability, veteran, house, street, area, village, city, qualification, annual_income, community, notifications, theme, phone
)
SELECT
    id, 
    COALESCE(google_user_id, id::text || '@placeholder.com'), 
    full_name, 
    profile_photo_url, 
    language, 
    'regular', 
    employment, 
    state, 
    district, 
    pin, 
    profile_completed, 
    created_at, 
    updated_at, 
    last_login_time,
    dob, 
    gender, 
    disability, 
    veteran, 
    house, 
    street, 
    area, 
    village, 
    city, 
    qualification, 
    annual_income, 
    community, 
    notifications, 
    theme, 
    phone
FROM public.users
ON CONFLICT (id) DO UPDATE SET
    dob = EXCLUDED.dob,
    gender = EXCLUDED.gender,
    disability = EXCLUDED.disability,
    veteran = EXCLUDED.veteran,
    house = EXCLUDED.house,
    street = EXCLUDED.street,
    area = EXCLUDED.area,
    village = EXCLUDED.village,
    city = EXCLUDED.city,
    qualification = EXCLUDED.qualification,
    annual_income = EXCLUDED.annual_income,
    community = EXCLUDED.community,
    notifications = EXCLUDED.notifications,
    theme = EXCLUDED.theme,
    phone = EXCLUDED.phone;

-- 3. Repoint foreign keys in public.startup_profiles to reference public.profiles(id)
ALTER TABLE public.startup_profiles DROP CONSTRAINT IF EXISTS startup_profiles_user_id_fkey;

ALTER TABLE public.startup_profiles
ADD CONSTRAINT startup_profiles_user_id_fkey
FOREIGN KEY (user_id) REFERENCES public.profiles(id)
ON DELETE CASCADE;

-- 4. Drop the redundant public.users table
DROP TABLE IF EXISTS public.users CASCADE;
