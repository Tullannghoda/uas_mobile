-- Pastikan pgcrypto terinstall (bawaan Supabase)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Insert 1 Admin, 3 Helpdesk, 1 User
-- Password semuanya: 123456

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, 
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, 
  created_at, updated_at, confirmation_token, email_change, 
  email_change_token_new, recovery_token
) VALUES 
-- 1. Admin
(
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'admin@mail.com', crypt('123456', gen_salt('bf')), 
  now(), '{"provider":"email","providers":["email"]}', '{"name":"Admin Sistem","role":"admin"}', 
  now(), now(), '', '', '', ''
),
-- 2. Dewi Helpdesk
(
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'dewi@mail.com', crypt('123456', gen_salt('bf')), 
  now(), '{"provider":"email","providers":["email"]}', '{"name":"Dewi Helpdesk","role":"helpdesk"}', 
  now(), now(), '', '', '', ''
),
-- 3. Rina Helpdesk
(
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'rina@mail.com', crypt('123456', gen_salt('bf')), 
  now(), '{"provider":"email","providers":["email"]}', '{"name":"Rina Helpdesk","role":"helpdesk"}', 
  now(), now(), '', '', '', ''
),
-- 4. Budi Helpdesk
(
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'budi@mail.com', crypt('123456', gen_salt('bf')), 
  now(), '{"provider":"email","providers":["email"]}', '{"name":"Budi Helpdesk","role":"helpdesk"}', 
  now(), now(), '', '', '', ''
),
-- 5. User Demo
(
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'user@mail.com', crypt('123456', gen_salt('bf')), 
  now(), '{"provider":"email","providers":["email"]}', '{"name":"Budi Santoso","role":"user"}', 
  now(), now(), '', '', '', ''
);
