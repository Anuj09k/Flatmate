-- =============================================================================
-- Phase 1: Foundation Migration
-- Extensions, Config, Users, Profiles, Photos, Listings, Prompts, Triggers & RLS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('lister', 'seeker', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE account_status AS ENUM ('limited', 'active', 'locked', 'suspended');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE photo_type AS ENUM ('profile', 'interior', 'exterior', 'extra', 'video_tour');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE review_status AS ENUM (
    'pending',
    'approved',
    'flagged_duplicate',
    'flagged_unsafe',
    'flagged_location_mismatch',
    'rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE furnishing_type AS ENUM ('furnished', 'semi_furnished', 'unfurnished');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE room_type AS ENUM ('private_room', 'shared_room', 'entire_flat');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE bathroom_type AS ENUM ('attached', 'dedicated_outside', 'shared');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.config (key, value, description) VALUES
  ('verification_window_days', '15'::jsonb, 'Days from sign up to complete ID + face verification'),
  ('unverified_lock_days', '75'::jsonb, 'Days account stays locked if not verified within window'),
  ('min_face_captures', '2'::jsonb, 'Minimum clear face captures required during liveness scan'),
  ('face_scan_directions', '["straight", "left", "right", "up"]'::jsonb, 'Required camera directions for face scan'),
  ('max_verification_attempts_per_day', '3'::jsonb, 'Failed verification tries in a day before 24h cooldown'),
  ('verification_cooldown_hours', '24'::jsonb, 'Cooldown hours after max failed daily verification tries'),
  ('verification_reminder_days', '[1, 7, 12, 14, 15]'::jsonb, 'Days after sign-up to send verification reminders'),
  ('free_right_swipes_per_week', '5'::jsonb, 'Weekly right swipe limit for Free plan'),
  ('plus_right_swipes_per_week', '25'::jsonb, 'Weekly right swipe limit for Plus plan'),
  ('pro_right_swipes_per_week', '-1'::jsonb, 'Unlimited (-1) weekly right swipes for Pro plan'),
  ('weekly_reset_day_ist', '"MONDAY"'::jsonb, 'Day of week for quota reset in Asia/Kolkata'),
  ('weekly_reset_hour_ist', '0'::jsonb, 'Hour of day (00:00 IST) for quota reset'),
  ('min_lister_interior_photos', '2'::jsonb, 'Minimum non-duplicate interior photos required for Listers'),
  ('min_lister_exterior_photos', '1'::jsonb, 'Minimum exterior building/entrance photos required for Listers'),
  ('min_profile_photos', '2'::jsonb, 'Minimum verified profile photos required'),
  ('max_profile_photos', '6'::jsonb, 'Maximum profile photos allowed'),
  ('phash_duplicate_threshold', '8'::jsonb, 'Maximum 64-bit Hamming distance considered a duplicate image'),
  ('max_photo_location_mismatch_km', '5.0'::jsonb, 'Max distance (km) between photo EXIF GPS and listing locality before manual review'),
  ('prompts_per_profile', '3'::jsonb, 'Required number of profile prompts'),
  ('prompt_answer_max_chars', '150'::jsonb, 'Maximum characters per prompt answer'),
  ('superchat_note_max_chars', '200'::jsonb, 'Maximum characters for a Superchat note'),
  ('chat_early_message_contact_lock_count', '5'::jsonb, 'Number of initial match messages where contact info and photos are blocked'),
  ('strike_warning_max', '3'::jsonb, 'Strikes 1..3 block message and warn; next strike suspends'),
  ('suspension_days_schedule', '[3, 7, 30]'::jsonb, 'Suspension durations in days for strike 4, 5, 6+'),
  ('strike_reset_clean_days', '90'::jsonb, 'Clean days required before strikes reset to 0'),
  ('boost_duration_hours', '24'::jsonb, 'Base duration of 1 boost in hours'),
  ('boost_stack_bonus_hours', '12'::jsonb, 'One-time bonus hours when stacking 2 or 3 boosts'),
  ('free_boosts_per_week', '1'::jsonb, 'Weekly boosts for Free plan'),
  ('plus_boosts_per_week', '2'::jsonb, 'Weekly boosts for Plus plan'),
  ('pro_boosts_per_week', '3'::jsonb, 'Weekly boosts for Pro plan'),
  ('free_superchats_per_week', '1'::jsonb, 'Weekly Superchats for Free plan'),
  ('plus_superchats_per_week', '5'::jsonb, 'Weekly Superchats for Plus plan'),
  ('pro_superchats_per_week', '10'::jsonb, 'Weekly Superchats for Pro plan'),
  ('new_profile_lift_hours', '48'::jsonb, 'Hours a newly active profile receives a ranking lift'),
  ('new_profile_lift_points', '5.0'::jsonb, 'Score lift points for a new profile within 48h'),
  ('boost_max_lift_points', '12.0'::jsonb, 'Score lift points for a boosted profile (never beats +15 higher match)'),
  ('boost_never_beats_score_gap', '15.0'::jsonb, 'Maximum compatibility gap a boost is allowed to overcome'),
  ('min_age_years', '18'::jsonb, 'Minimum user age in years'),
  ('gst_rate_percent', '18'::jsonb, 'GST percentage on plans in India')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();

CREATE OR REPLACE FUNCTION public.get_config_int(p_key TEXT, p_default INT)
RETURNS INT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE((SELECT (value#>>'{}')::INT FROM public.config WHERE key = p_key), p_default);
$$;

CREATE OR REPLACE FUNCTION public.get_config_float(p_key TEXT, p_default DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE((SELECT (value#>>'{}')::DOUBLE PRECISION FROM public.config WHERE key = p_key), p_default);
$$;

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE,
  role user_role NOT NULL DEFAULT 'seeker',
  date_of_birth DATE NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('man', 'woman', 'lgbtq')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status account_status NOT NULL DEFAULT 'limited',
  verification_deadline TIMESTAMPTZ NOT NULL,
  lock_ends_at TIMESTAMPTZ
);

CREATE OR REPLACE FUNCTION public.before_insert_user_defaults()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_min_age INT;
  v_window_days INT;
BEGIN
  v_min_age := public.get_config_int('min_age_years', 18);
  v_window_days := public.get_config_int('verification_window_days', 15);

  IF EXTRACT(YEAR FROM age(CURRENT_DATE, NEW.date_of_birth)) < v_min_age THEN
    RAISE EXCEPTION 'AGE_BELOW_MINIMUM: User must be at least % years old.', v_min_age;
  END IF;

  IF NEW.created_at IS NULL THEN
    NEW.created_at := NOW();
  END IF;

  IF NEW.verification_deadline IS NULL THEN
    NEW.verification_deadline := NEW.created_at + make_interval(days => v_window_days);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_before_insert ON public.users;
CREATE TRIGGER trg_users_before_insert
BEFORE INSERT ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.before_insert_user_defaults();

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.contains_contact_details(p_text TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_normalized TEXT;
  v_digit_count INT;
BEGIN
  IF p_text IS NULL OR btrim(p_text) = '' THEN
    RETURN FALSE;
  END IF;

  v_normalized := lower(p_text);

  IF v_normalized ~* '([a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,})'
     OR v_normalized ~* '(instagram|insta|ig|snapchat|snap|telegram|tg|whatsapp|wa\.me|t\.me|linkedin|facebook|fb)\b'
     OR v_normalized ~* '(\bdm\s+me\b|\btext\s+me\s+on\b|\bhmu\s+on\b|\bping\s+me\s+on\b|@[a-z0-9_.]{3,})' THEN
    RETURN TRUE;
  END IF;

  v_normalized := regexp_replace(v_normalized, '\m(zero|oh)\M', '0', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(one|ek)\M', '1', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(two|do)\M', '2', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(three|teen)\M', '3', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(four|char)\M', '4', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(five|paanch)\M', '5', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(six|cheh)\M', '6', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(seven|saat)\M', '7', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(eight|aath)\M', '8', 'gi');
  v_normalized := regexp_replace(v_normalized, '\m(nine|nau)\M', '9', 'gi');

  v_digit_count := length(regexp_replace(v_normalized, '[^0-9]', '', 'g'));
  IF v_digit_count >= 7 THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$;

CREATE TABLE IF NOT EXISTS public.profiles (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(btrim(name)) BETWEEN 2 AND 80),
  bio TEXT NOT NULL DEFAULT '' CHECK (char_length(bio) <= 500),
  occupation TEXT NOT NULL DEFAULT '',
  college_or_company TEXT NOT NULL DEFAULT '',
  languages TEXT[] NOT NULL DEFAULT ARRAY['English']::TEXT[],
  last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  membership_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.validate_profile_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_min_photos INT;
  v_max_photos INT;
  v_req_prompts INT;
  v_profile_photo_count INT;
  v_prompt_count INT;
  v_role user_role;
  v_listing_verified BOOLEAN;
BEGIN
  IF public.contains_contact_details(NEW.bio) THEN
    RAISE EXCEPTION 'CONTACT_DETAILS_BLOCKED: Contact details are not allowed in bio.';
  END IF;

  IF NEW.onboarding_completed = TRUE THEN
    v_min_photos := public.get_config_int('min_profile_photos', 2);
    v_max_photos := public.get_config_int('max_profile_photos', 6);
    v_req_prompts := public.get_config_int('prompts_per_profile', 3);

    SELECT COUNT(*) INTO v_profile_photo_count
    FROM public.photos
    WHERE user_id = NEW.user_id
      AND type = 'profile'
      AND review_status = 'approved';

    IF v_profile_photo_count < v_min_photos OR v_profile_photo_count > v_max_photos THEN
      RAISE EXCEPTION 'PROFILE_PHOTO_COUNT_INVALID: User must have between % and % approved profile photos.', v_min_photos, v_max_photos;
    END IF;

    SELECT COUNT(*) INTO v_prompt_count
    FROM public.prompt_answers
    WHERE user_id = NEW.user_id;

    IF v_prompt_count <> v_req_prompts THEN
      RAISE EXCEPTION 'PROMPT_COUNT_INVALID: User must complete exactly % profile prompts.', v_req_prompts;
    END IF;

    SELECT role INTO v_role FROM public.users WHERE id = NEW.user_id;
    IF v_role = 'lister' THEN
      SELECT photos_verified INTO v_listing_verified
      FROM public.listings
      WHERE user_id = NEW.user_id;

      IF COALESCE(v_listing_verified, FALSE) = FALSE THEN
        RAISE EXCEPTION 'LISTER_FLAT_PHOTOS_REQUIRED: Listers must have verified flat photos (2 non-duplicate interior + 1 exterior) before going live.';
      END IF;
    END IF;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS public.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type photo_type NOT NULL,
  url TEXT NOT NULL,
  display_order INT NOT NULL DEFAULT 0,
  perceptual_hash BIGINT NOT NULL,
  exif_lat DOUBLE PRECISION,
  exif_lng DOUBLE PRECISION,
  is_group_photo BOOLEAN NOT NULL DEFAULT FALSE,
  has_sunglasses BOOLEAN NOT NULL DEFAULT FALSE,
  review_status review_status NOT NULL DEFAULT 'approved',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.phash_hamming_distance(hash_a BIGINT, hash_b BIGINT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT length(replace((hash_a # hash_b)::bit(64)::text, '0', ''));
$$;

CREATE OR REPLACE FUNCTION public.validate_photo_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_dup_threshold INT;
  v_max_profile_photos INT;
  v_existing_profile_count INT;
  v_sunglasses_count INT;
  v_dup_exists BOOLEAN;
  v_cross_user_dup BOOLEAN;
BEGIN
  v_dup_threshold := public.get_config_int('phash_duplicate_threshold', 8);
  v_max_profile_photos := public.get_config_int('max_profile_photos', 6);

  IF NEW.type = 'profile' AND NEW.display_order = 0 AND NEW.is_group_photo = TRUE THEN
    RAISE EXCEPTION 'GROUP_PHOTO_FIRST_NOT_ALLOWED: The first profile photo cannot be a group photo.';
  END IF;

  IF NEW.type = 'profile' THEN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE has_sunglasses = TRUE)
    INTO v_existing_profile_count, v_sunglasses_count
    FROM public.photos
    WHERE user_id = NEW.user_id AND type = 'profile';

    IF v_existing_profile_count >= v_max_profile_photos THEN
      RAISE EXCEPTION 'MAX_PROFILE_PHOTOS_EXCEEDED: Cannot upload more than % profile photos.', v_max_profile_photos;
    END IF;

    IF v_existing_profile_count >= 1
       AND v_sunglasses_count = v_existing_profile_count
       AND NEW.has_sunglasses = TRUE THEN
      RAISE EXCEPTION 'SUNGLASSES_ALL_PHOTOS: You cannot wear sunglasses in all of your profile photos.';
    END IF;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.photos
    WHERE user_id = NEW.user_id
      AND id <> COALESCE(NEW.id, gen_random_uuid())
      AND public.phash_hamming_distance(perceptual_hash, NEW.perceptual_hash) <= v_dup_threshold
  ) INTO v_dup_exists;

  IF v_dup_exists THEN
    RAISE EXCEPTION 'DUPLICATE_PHOTO_REJECTED: This photo is identical or nearly identical to another photo you uploaded.';
  END IF;

  IF NEW.type IN ('interior', 'exterior', 'extra') THEN
    SELECT EXISTS (
      SELECT 1 FROM public.photos
      WHERE user_id <> NEW.user_id
        AND type IN ('interior', 'exterior', 'extra')
        AND public.phash_hamming_distance(perceptual_hash, NEW.perceptual_hash) <= v_dup_threshold
    ) INTO v_cross_user_dup;

    IF v_cross_user_dup THEN
      NEW.review_status := 'flagged_duplicate';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_photos_before_insert ON public.photos;
CREATE TRIGGER trg_photos_before_insert
BEFORE INSERT ON public.photos
FOR EACH ROW
EXECUTE FUNCTION public.validate_photo_before_insert();

CREATE TABLE IF NOT EXISTS public.listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  city TEXT NOT NULL DEFAULT 'Mumbai',
  locality TEXT NOT NULL,
  location GEOGRAPHY(Point, 4326) NOT NULL,
  rent INT NOT NULL CHECK (rent > 0),
  deposit INT NOT NULL CHECK (deposit >= 0),
  furnishing furnishing_type NOT NULL DEFAULT 'semi_furnished',
  room_type room_type NOT NULL DEFAULT 'private_room',
  bathroom_type bathroom_type NOT NULL DEFAULT 'attached',
  amenities TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  rent_split TEXT NOT NULL DEFAULT 'equal',
  maid_share BOOLEAN NOT NULL DEFAULT TRUE,
  utilities_split TEXT NOT NULL DEFAULT 'equal',
  available_from DATE NOT NULL,
  min_stay_months INT NOT NULL DEFAULT 6 CHECK (min_stay_months >= 1),
  notice_period_days INT NOT NULL DEFAULT 30 CHECK (notice_period_days >= 0),
  house_rules JSONB NOT NULL DEFAULT '{}'::jsonb,
  photos_verified BOOLEAN NOT NULL DEFAULT FALSE,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  review_status review_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.verify_and_publish_listing(p_user_id UUID)
RETURNS public.listings
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_min_interior INT;
  v_min_exterior INT;
  v_max_mismatch_km DOUBLE PRECISION;
  v_interior_count INT;
  v_exterior_count INT;
  v_flagged_count INT;
  v_location_mismatch BOOLEAN;
  v_listing public.listings;
BEGIN
  SELECT * INTO v_listing FROM public.listings WHERE user_id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'LISTING_NOT_FOUND: No listing found for user %', p_user_id;
  END IF;

  v_min_interior := public.get_config_int('min_lister_interior_photos', 2);
  v_min_exterior := public.get_config_int('min_lister_exterior_photos', 1);
  v_max_mismatch_km := public.get_config_float('max_photo_location_mismatch_km', 5.0);

  SELECT
    COUNT(*) FILTER (WHERE type = 'interior' AND review_status = 'approved'),
    COUNT(*) FILTER (WHERE type = 'exterior' AND review_status = 'approved'),
    COUNT(*) FILTER (WHERE type IN ('interior', 'exterior', 'extra') AND review_status IN ('flagged_duplicate', 'flagged_unsafe'))
  INTO v_interior_count, v_exterior_count, v_flagged_count
  FROM public.photos
  WHERE user_id = p_user_id;

  IF v_flagged_count > 0 THEN
    UPDATE public.listings
    SET photos_verified = FALSE,
        is_published = FALSE,
        review_status = 'flagged_duplicate',
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_listing;
    RAISE EXCEPTION 'LISTING_PHOTOS_FLAGGED: One or more flat photos were flagged and sent for manual review.';
  END IF;

  IF v_interior_count < v_min_interior THEN
    RAISE EXCEPTION 'INSUFFICIENT_INTERIOR_PHOTOS: At least % non-duplicate interior photos are required (found %).', v_min_interior, v_interior_count;
  END IF;

  IF v_exterior_count < v_min_exterior THEN
    RAISE EXCEPTION 'INSUFFICIENT_EXTERIOR_PHOTOS: At least % exterior building/entrance photo is required (found %).', v_min_exterior, v_exterior_count;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.photos
    WHERE user_id = p_user_id
      AND type IN ('interior', 'exterior')
      AND exif_lat IS NOT NULL
      AND exif_lng IS NOT NULL
      AND (ST_Distance(
            v_listing.location,
            ST_SetSRID(ST_MakePoint(exif_lng, exif_lat), 4326)::geography
          ) / 1000.0) > v_max_mismatch_km
  ) INTO v_location_mismatch;

  IF v_location_mismatch THEN
    UPDATE public.listings
    SET photos_verified = FALSE,
        is_published = FALSE,
        review_status = 'flagged_location_mismatch',
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_listing;
    RETURN v_listing;
  END IF;

  UPDATE public.listings
  SET photos_verified = TRUE,
      is_published = TRUE,
      review_status = 'approved',
      updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING * INTO v_listing;

  RETURN v_listing;
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_listing_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_min_interior INT;
  v_min_exterior INT;
  v_interior_count INT;
  v_exterior_count INT;
BEGIN
  IF NEW.photos_verified = TRUE OR NEW.is_published = TRUE THEN
    v_min_interior := public.get_config_int('min_lister_interior_photos', 2);
    v_min_exterior := public.get_config_int('min_lister_exterior_photos', 1);

    SELECT
      COUNT(*) FILTER (WHERE type = 'interior' AND review_status = 'approved'),
      COUNT(*) FILTER (WHERE type = 'exterior' AND review_status = 'approved')
    INTO v_interior_count, v_exterior_count
    FROM public.photos
    WHERE user_id = NEW.user_id;

    IF v_interior_count < v_min_interior OR v_exterior_count < v_min_exterior THEN
      RAISE EXCEPTION 'LISTING_CANNOT_PUBLISH_WITHOUT_PHOTOS: Requires at least % interior and % exterior approved photos.', v_min_interior, v_min_exterior;
    END IF;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_listings_before_write ON public.listings;
CREATE TRIGGER trg_listings_before_write
BEFORE INSERT OR UPDATE ON public.listings
FOR EACH ROW
EXECUTE FUNCTION public.validate_listing_before_write();

CREATE TABLE IF NOT EXISTS public.prompts_catalog (
  id TEXT PRIMARY KEY,
  group_name TEXT NOT NULL,
  heading TEXT NOT NULL,
  lister_only BOOLEAN NOT NULL DEFAULT FALSE,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO public.prompts_catalog (id, group_name, heading, lister_only, active) VALUES
  ('daily_1', 'Daily life', 'A normal weekday at home looks like...', FALSE, TRUE),
  ('daily_2', 'Daily life', 'My ideal weekend at home is...', FALSE, TRUE),
  ('daily_3', 'Daily life', 'My morning routine is...', FALSE, TRUE),
  ('daily_4', 'Daily life', 'Our kitchen would be...', FALSE, TRUE),
  ('living_1', 'Living together', 'My flatmate rule that never changes is...', FALSE, TRUE),
  ('living_2', 'Living together', 'Something that drives me up the wall is...', FALSE, TRUE),
  ('living_3', 'Living together', 'Cleaning in my world means...', FALSE, TRUE),
  ('living_4', 'Living together', 'Guests and friends over means...', FALSE, TRUE),
  ('about_1', 'About me', 'You will find me at home when I am...', FALSE, TRUE),
  ('about_2', 'About me', 'My comfort food is...', FALSE, TRUE),
  ('about_3', 'About me', 'I am weirdly good at...', FALSE, TRUE),
  ('about_4', 'About me', 'The best flatmate I had taught me...', FALSE, TRUE),
  ('flags_1', 'Green flags and deal breakers', 'My biggest green flag is...', FALSE, TRUE),
  ('flags_2', 'Green flags and deal breakers', 'My deal breaker is...', FALSE, TRUE),
  ('flags_3', 'Green flags and deal breakers', 'First week together, I would suggest...', FALSE, TRUE),
  ('lister_1', 'For listers', 'What makes this flat special is...', TRUE, TRUE),
  ('lister_2', 'For listers', 'The neighbourhood is best known for...', TRUE, TRUE),
  ('lister_3', 'For listers', 'What is not perfect about this flat is...', TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.prompt_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  prompt_id TEXT NOT NULL REFERENCES public.prompts_catalog(id),
  answer TEXT NOT NULL,
  position INT NOT NULL CHECK (position BETWEEN 0 AND 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, position),
  UNIQUE (user_id, prompt_id)
);

CREATE OR REPLACE FUNCTION public.validate_prompt_answer_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_max_chars INT;
BEGIN
  v_max_chars := public.get_config_int('prompt_answer_max_chars', 150);

  IF char_length(btrim(NEW.answer)) = 0 OR char_length(NEW.answer) > v_max_chars THEN
    RAISE EXCEPTION 'PROMPT_ANSWER_LENGTH_INVALID: Prompt answer must be between 1 and % characters.', v_max_chars;
  END IF;

  IF public.contains_contact_details(NEW.answer) THEN
    RAISE EXCEPTION 'CONTACT_DETAILS_BLOCKED: Contact details are not allowed in prompt answers.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prompt_answers_before_write ON public.prompt_answers;
CREATE TRIGGER trg_prompt_answers_before_write
BEFORE INSERT OR UPDATE ON public.prompt_answers
FOR EACH ROW
EXECUTE FUNCTION public.validate_prompt_answer_before_write();

DROP TRIGGER IF EXISTS trg_profiles_before_write ON public.profiles;
CREATE TRIGGER trg_profiles_before_write
BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.validate_profile_before_write();

ALTER TABLE public.config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompts_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY config_read_all ON public.config FOR SELECT USING ( TRUE );
CREATE POLICY config_admin_write ON public.config FOR ALL USING ( public.is_admin() ) WITH CHECK ( public.is_admin() );

CREATE POLICY users_select_own_or_admin ON public.users FOR SELECT USING ( auth.uid() = id OR public.is_admin() );
CREATE POLICY users_insert_own ON public.users FOR INSERT WITH CHECK ( auth.uid() = id OR public.is_admin() );
CREATE POLICY users_update_own_or_admin ON public.users FOR UPDATE USING ( auth.uid() = id OR public.is_admin() );

CREATE POLICY profiles_select_visible ON public.profiles FOR SELECT USING ( auth.uid() = user_id OR onboarding_completed = TRUE OR public.is_admin() );
CREATE POLICY profiles_write_own ON public.profiles FOR ALL USING ( auth.uid() = user_id OR public.is_admin() ) WITH CHECK ( auth.uid() = user_id OR public.is_admin() );

CREATE POLICY photos_select_approved_or_own ON public.photos FOR SELECT USING ( auth.uid() = user_id OR review_status = 'approved' OR public.is_admin() );
CREATE POLICY photos_write_own ON public.photos FOR ALL USING ( auth.uid() = user_id OR public.is_admin() ) WITH CHECK ( auth.uid() = user_id OR public.is_admin() );

CREATE POLICY listings_select_published_or_own ON public.listings FOR SELECT USING ( auth.uid() = user_id OR is_published = TRUE OR public.is_admin() );
CREATE POLICY listings_write_own ON public.listings FOR ALL USING ( auth.uid() = user_id OR public.is_admin() ) WITH CHECK ( auth.uid() = user_id OR public.is_admin() );

CREATE POLICY prompts_catalog_read_all ON public.prompts_catalog FOR SELECT USING ( TRUE );
CREATE POLICY prompts_catalog_admin_write ON public.prompts_catalog FOR ALL USING ( public.is_admin() ) WITH CHECK ( public.is_admin() );

CREATE POLICY prompt_answers_read_all ON public.prompt_answers FOR SELECT USING ( TRUE );
CREATE POLICY prompt_answers_write_own ON public.prompt_answers FOR ALL USING ( auth.uid() = user_id OR public.is_admin() ) WITH CHECK ( auth.uid() = user_id OR public.is_admin() );
