INSERT INTO public.users (id, phone, email, role, date_of_birth, gender, status)
VALUES
  ('11111111-1111-1111-1111-111111111111', '+919820011111', 'aarav@example.com', 'lister', '1998-05-14', 'man', 'limited'),
  ('22222222-2222-2222-2222-222222222222', '+919820022222', 'diya@example.com', 'seeker', '1999-09-21', 'woman', 'limited'),
  ('99999999-9999-9999-9999-999999999999', '+919820099999', 'admin@flatmate.in', 'admin', '1992-01-10', 'woman', 'active')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.photos (user_id, type, url, display_order, perceptual_hash, exif_lat, exif_lng, is_group_photo, has_sunglasses)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'profile', 'https://example.com/aarav_1.jpg', 0, 1000000000000001, 19.1363, 72.8277, FALSE, FALSE),
  ('11111111-1111-1111-1111-111111111111', 'profile', 'https://example.com/aarav_2.jpg', 1, 2000000000000002, 19.1363, 72.8277, FALSE, TRUE),
  ('11111111-1111-1111-1111-111111111111', 'interior', 'https://example.com/flat_living.jpg', 0, 3000000000000003, 19.1363, 72.8277, FALSE, FALSE),
  ('11111111-1111-1111-1111-111111111111', 'interior', 'https://example.com/flat_bedroom.jpg', 1, 4000000000000004, 19.1363, 72.8277, FALSE, FALSE),
  ('11111111-1111-1111-1111-111111111111', 'exterior', 'https://example.com/flat_building.jpg', 2, 5000000000000005, 19.1363, 72.8277, FALSE, FALSE);

INSERT INTO public.listings (
  user_id, city, locality, location, rent, deposit, furnishing, room_type, bathroom_type,
  amenities, rent_split, maid_share, utilities_split, available_from, min_stay_months, notice_period_days, house_rules
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Mumbai',
  'Andheri West',
  ST_SetSRID(ST_MakePoint(72.8277, 19.1363), 4326)::geography,
  28000,
  75000,
  'furnished',
  'private_room',
  'attached',
  ARRAY['AC', 'Wi-Fi', 'Lift', 'Balcony', 'Washing Machine'],
  'equal',
  TRUE,
  'equal',
  '2026-12-01',
  11,
  30,
  '{"smoking": "non_smoker", "drinking": "social", "pets": "allowed", "guests": "anytime_with_heads_up", "cleaning_schedule": "daily_maid"}'::jsonb
);

SELECT public.verify_and_publish_listing('11111111-1111-1111-1111-111111111111');

INSERT INTO public.prompt_answers (user_id, prompt_id, answer, position) VALUES
  ('11111111-1111-1111-1111-111111111111', 'daily_1', 'Quick filter coffee at 8 AM, work from office in BKC, and unwind with evening runs.', 0),
  ('11111111-1111-1111-1111-111111111111', 'living_1', 'Keep the kitchen counter clean after cooking late-night snacks.', 1),
  ('11111111-1111-1111-1111-111111111111', 'lister_1', 'Huge sunlit balcony facing a quiet tree-lined lane 5 mins from metro.', 2);

INSERT INTO public.profiles (user_id, name, bio, occupation, college_or_company, languages, onboarding_completed)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Aarav Mehta',
  'Product designer working in BKC. Easygoing, love weekend treks and filter coffee.',
  'Product Designer',
  'Razorpay',
  ARRAY['English', 'Hindi', 'Gujarati'],
  TRUE
);
