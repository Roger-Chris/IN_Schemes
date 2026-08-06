-- Migration: self_delete_user
-- Purpose : Allow authenticated users to delete their own account from the auth.users table.

CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the calling user is authenticated and delete their own record
  IF auth.uid() IS NOT NULL THEN
    DELETE FROM auth.users WHERE id = auth.uid();
  ELSE
    RAISE EXCEPTION 'Only authenticated users can delete their account';
  END IF;
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;

-- Fallback RLS Policy: Allow authenticated users to delete their own profile row directly
CREATE POLICY "Profiles delete access" ON public.profiles FOR DELETE TO authenticated USING (auth.uid() = id);
