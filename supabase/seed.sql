-- seed.sql — local-development seed data.
-- Mirrors Models/SampleData.swift. Runs after `supabase db reset`.
--
-- Creates one test user via auth.users (skipping email confirmation), then
-- inserts the 7 sample items as that user. The trigger in migration 02 will
-- auto-create the matching profile row.

-- Test user — uuid is fixed so tests can reference it.
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_user_meta_data, created_at, updated_at
)
values (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'demo@ku.test',
  crypt('demo-password', gen_salt('bf')),
  now(),
  jsonb_build_object('full_name', 'KU Demo Student', 'faculty', 'Engineering'),
  now(),
  now()
)
on conflict (id) do nothing;

-- Update the auto-created profile with extra fields the trigger doesn't set.
update public.profiles
   set faculty = 'Engineering',
       year    = 4
 where id = '00000000-0000-0000-0000-000000000001';

-- Sample items — port of SampleData.swift.
insert into public.items
  (id, reporter_id, title, description, status, category, emoji,
   location_name, lat, lng, occurred_at, claimed_by, claimed_at)
values
  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
   'Blue backpack',
   'Found near the lobby of Engineering Building 4. Looks like a student backpack with a laptop sleeve.',
   'found', 'bag', '🎒',
   'Engineering Building 4', 13.8460, 100.5685,
   now() - interval '2 hours', null, null),

  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
   'Key ring (3 keys)',
   'I lost my key ring with three silver keys and a small KU lanyard around the cafeteria yesterday afternoon.',
   'lost', 'keys', '🔑',
   'Cafeteria area', 13.8472, 100.5705,
   now() - interval '1 day', null, null),

  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
   'Student ID card',
   'Student ID has been claimed and returned to its owner.',
   'claimed', 'id_card', '💳',
   'Main security office', 13.8458, 100.5712,
   now() - interval '3 days',
   '00000000-0000-0000-0000-000000000001', now() - interval '2 days'),

  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
   'Wireless earbuds',
   'White wireless earbuds in a small charging case. Found on the 2nd floor reading area of the KU Library.',
   'found', 'electronics', '🎧',
   'KU Library, 2nd floor', 13.8482, 100.5700,
   now() - interval '5 hours', null, null),

  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
   'iPhone (black case)',
   'Lost an iPhone with a plain black silicone case yesterday near the main auditorium. Lock screen shows a campus photo.',
   'lost', 'electronics', '📱',
   'Near Auditorium', 13.8447, 100.5690,
   now() - interval '1 day', null, null),

  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
   'Calculus textbook',
   'Calculus textbook with annotations and a yellow KU sticker. Found on a desk in the Science Building.',
   'found', 'books', '📓',
   'Science Building', 13.8478, 100.5680,
   now() - interval '6 hours', null, null),

  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
   'Black KU jacket',
   'Black KU varsity jacket, size M. Last seen at the sports complex changing room two days ago.',
   'lost', 'clothing', '🧥',
   'Sports Complex', 13.8488, 100.5720,
   now() - interval '2 days', null, null);
