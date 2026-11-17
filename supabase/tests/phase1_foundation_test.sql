BEGIN;

DO $$
DECLARE
  v_underage_id UUID := gen_random_uuid();
  v_lister_id UUID := '33333333-3333-3333-3333-333333333333';
  v_user_row public.users;
  v_listing_row public.listings;
  v_caught BOOLEAN;
BEGIN
  v_caught := FALSE;
  BEGIN
    INSERT INTO public.users (id, phone, role, date_of_birth, gender)
    VALUES (v_underage_id, '+919000000001', 'seeker', CURRENT_DATE - INTERVAL '16 years', 'man');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%AGE_BELOW_MINIMUM%' THEN
      v_caught := TRUE;
    END IF;
  END;
  ASSERT v_caught = TRUE, 'Expected underage user sign-up to be rejected by server trigger';

  INSERT INTO public.users (id, phone, role, date_of_birth, gender)
  VALUES (v_lister_id, '+919000000002', 'lister', '1997-04-10', 'woman')
  RETURNING * INTO v_user_row;

  ASSERT v_user_row.status = 'limited', 'New user must start in limited status';
  ASSERT EXTRACT(DAY FROM (v_user_row.verification_deadline - v_user_row.created_at)) = 15,
    'Verification deadline must be 15 days from sign-up';

  v_caught := FALSE;
  BEGIN
    INSERT INTO public.photos (user_id, type, url, display_order, perceptual_hash, is_group_photo)
    VALUES (v_lister_id, 'profile', 'https://example.com/group.jpg', 0, 1111111111111111, TRUE);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%GROUP_PHOTO_FIRST_NOT_ALLOWED%' THEN
      v_caught := TRUE;
    END IF;
  END;
  ASSERT v_caught = TRUE, 'First profile photo must reject group photos';

  INSERT INTO public.photos (user_id, type, url, display_order, perceptual_hash, is_group_photo, has_sunglasses)
  VALUES
    (v_lister_id, 'profile', 'https://example.com/p1.jpg', 0, 1111111111111111, FALSE, FALSE),
    (v_lister_id, 'profile', 'https://example.com/p2.jpg', 1, 2222222222222222, FALSE, FALSE);

  INSERT INTO public.listings (
    user_id, city, locality, location, rent, deposit, available_from
  ) VALUES (
    v_lister_id, 'Mumbai', 'Bandra West',
    ST_SetSRID(ST_MakePoint(72.8295, 19.0596), 4326)::geography,
    35000, 100000, '2026-12-01'
  );

  INSERT INTO public.photos (user_id, type, url, display_order, perceptual_hash)
  VALUES (v_lister_id, 'interior', 'https://example.com/int1.jpg', 0, 3333333333333333);

  v_caught := FALSE;
  BEGIN
    PERFORM public.verify_and_publish_listing(v_lister_id);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%INSUFFICIENT_INTERIOR_PHOTOS%' THEN
      v_caught := TRUE;
    END IF;
  END;
  ASSERT v_caught = TRUE, 'Lister publish must fail when < 2 interior photos exist';

  v_caught := FALSE;
  BEGIN
    INSERT INTO public.photos (user_id, type, url, display_order, perceptual_hash)
    VALUES (v_lister_id, 'interior', 'https://example.com/int1_dup.jpg', 1, 3333333333333332);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%DUPLICATE_PHOTO_REJECTED%' THEN
      v_caught := TRUE;
    END IF;
  END;
  ASSERT v_caught = TRUE, 'Near-duplicate interior photo must be rejected by pHash check';

  INSERT INTO public.photos (user_id, type, url, display_order, perceptual_hash)
  VALUES (v_lister_id, 'interior', 'https://example.com/int2.jpg', 1, 7777777777777777);

  v_caught := FALSE;
  BEGIN
    PERFORM public.verify_and_publish_listing(v_lister_id);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%INSUFFICIENT_EXTERIOR_PHOTOS%' THEN
      v_caught := TRUE;
    END IF;
  END;
  ASSERT v_caught = TRUE, 'Lister publish must fail without exterior photo';

  INSERT INTO public.photos (user_id, type, url, display_order, perceptual_hash)
  VALUES (v_lister_id, 'exterior', 'https://example.com/ext1.jpg', 2, 8888888888888888);

  v_listing_row := public.verify_and_publish_listing(v_lister_id);
  ASSERT v_listing_row.photos_verified = TRUE AND v_listing_row.is_published = TRUE,
    'Listing must be marked photos_verified and published once 2 distinct interior + 1 exterior photos pass';

  v_caught := FALSE;
  BEGIN
    INSERT INTO public.prompt_answers (user_id, prompt_id, answer, position)
    VALUES (v_lister_id, 'daily_1', 'Call me on nine eight two zero one two three four five six', 0);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%CONTACT_DETAILS_BLOCKED%' THEN
      v_caught := TRUE;
    END IF;
  END;
  ASSERT v_caught = TRUE, 'Spelled-out phone numbers in prompt answers must be blocked';

  INSERT INTO public.prompt_answers (user_id, prompt_id, answer, position) VALUES
    (v_lister_id, 'daily_1', 'Quiet mornings with chai and reading.', 0),
    (v_lister_id, 'living_1', 'Respect quiet hours after 11 PM on weeknights.', 1),
    (v_lister_id, 'lister_1', 'Sea-breeze cross ventilation in every room.', 2);

  INSERT INTO public.profiles (user_id, name, bio, occupation, college_or_company, onboarding_completed)
  VALUES (v_lister_id, 'Riya Sharma', 'Architect based in Bandra.', 'Architect', 'Studio Lotus', TRUE);

  PERFORM set_config('request.jwt.claim.sub', v_lister_id::text, true);
  PERFORM set_config('role', 'authenticated', true);
  ASSERT public.is_admin() = FALSE, 'Regular lister must not be recognized as admin';
END $$;

ROLLBACK;
