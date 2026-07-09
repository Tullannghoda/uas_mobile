-- ============================================
-- E-Helpdesk v2.0.0 — Supabase Database Schema
-- ============================================

-- 1. PROFILES (extends Supabase Auth)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'helpdesk', 'admin')),
  phone TEXT,
  department TEXT,
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view profiles" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Allow insert for auth trigger" ON profiles
  FOR INSERT WITH CHECK (true);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role, phone, department)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'department'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 2. TICKETS
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'send'
    CHECK (status IN ('send', 'open', 'in_progress', 'resolved', 'closed')),
  priority TEXT NOT NULL DEFAULT 'medium'
    CHECK (priority IN ('low', 'medium', 'high')),
  category TEXT NOT NULL,
  user_id UUID REFERENCES profiles(id),
  user_name TEXT NOT NULL,
  assigned_to_id UUID REFERENCES profiles(id),
  assigned_to_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  assigned_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  in_progress_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ
);

ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own tickets" ON tickets
  FOR SELECT USING (
    auth.uid() = user_id
    OR auth.uid() = assigned_to_id
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can create tickets" ON tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staff can update tickets" ON tickets
  FOR UPDATE USING (
    auth.uid() = user_id
    OR auth.uid() = assigned_to_id
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'helpdesk'))
  );

CREATE POLICY "Admin can delete tickets" ON tickets
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. COMMENTS
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  user_name TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone involved can see comments" ON comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = comments.ticket_id
      AND (
        t.user_id = auth.uid()
        OR t.assigned_to_id = auth.uid()
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
      )
    )
  );

CREATE POLICY "Authenticated users can add comments" ON comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. ATTACHMENTS
CREATE TABLE attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  uploaded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone involved can see attachments" ON attachments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = attachments.ticket_id
      AND (
        t.user_id = auth.uid()
        OR t.assigned_to_id = auth.uid()
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
      )
    )
  );

CREATE POLICY "Authenticated users can add attachments" ON attachments
  FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

-- 5. NOTIFICATIONS
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  ticket_id UUID REFERENCES tickets(id),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications" ON notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- 6. TICKET_HISTORY
CREATE TABLE ticket_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  performed_by_id UUID REFERENCES profiles(id),
  performed_by_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE ticket_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone involved can see history" ON ticket_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_history.ticket_id
      AND (
        t.user_id = auth.uid()
        OR t.assigned_to_id = auth.uid()
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
      )
    )
  );

CREATE POLICY "Authenticated users can add history" ON ticket_history
  FOR INSERT WITH CHECK (auth.uid() = performed_by_id);

-- ============================================
-- Enable Realtime for notifications
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================
-- Storage bucket for attachments
-- ============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', true);

CREATE POLICY "Anyone can view attachments" ON storage.objects
  FOR SELECT USING (bucket_id = 'attachments');

CREATE POLICY "Authenticated users can upload attachments" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'attachments' AND auth.role() = 'authenticated');

CREATE POLICY "Users can delete own attachments" ON storage.objects
  FOR DELETE USING (bucket_id = 'attachments' AND auth.uid()::text = (storage.foldername(name))[1]);
