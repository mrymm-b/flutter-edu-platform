-- ============================================
-- STEP 1: Create ENUMs
-- ============================================

CREATE TYPE user_role AS ENUM ('student', 'teacher', 'admin');
CREATE TYPE session_status AS ENUM ('scheduled', 'live', 'ended');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
CREATE TYPE item_type AS ENUM ('course', 'book', 'private_lesson');
CREATE TYPE notification_type AS ENUM ('course', 'live', 'announcement', 'payment', 'message');

-- ============================================
-- STEP 2: Create Tables
-- ============================================

-- Subjects Table
CREATE TABLE subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subjects_name ON subjects(name);
CREATE INDEX idx_subjects_is_active ON subjects(is_active);

-- Users Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url TEXT,
  role user_role NOT NULL,
  grade_level TEXT,
  subject_id UUID REFERENCES subjects(id),
  phone_verified BOOLEAN DEFAULT false,
  must_change_password BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);

-- Courses Table
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id),
  price DECIMAL(10,2) NOT NULL,
  thumbnail_url TEXT,
  is_active BOOLEAN DEFAULT true,
  students_count INTEGER DEFAULT 0,
  created_by_admin_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_courses_teacher_id ON courses(teacher_id);
CREATE INDEX idx_courses_subject_id ON courses(subject_id);
CREATE INDEX idx_courses_is_active ON courses(is_active);

-- Books Table
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id),
  subject_id UUID NOT NULL REFERENCES subjects(id),
  price DECIMAL(10,2) NOT NULL,
  pdf_url TEXT NOT NULL,
  thumbnail_url TEXT,
  pages_count INTEGER,
  file_size INTEGER,
  is_active BOOLEAN DEFAULT true,
  downloads_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_books_teacher_id ON books(teacher_id);
CREATE INDEX idx_books_course_id ON books(course_id);
CREATE INDEX idx_books_subject_id ON books(subject_id);
CREATE INDEX idx_books_is_active ON books(is_active);

-- Enrollments Table
CREATE TABLE enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  purchased_at TIMESTAMPTZ NOT NULL,
  price_paid DECIMAL(10,2) NOT NULL,
  payment_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, course_id)
);

CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_course_id ON enrollments(course_id);

-- Book Purchases Table
CREATE TABLE book_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  purchased_at TIMESTAMPTZ NOT NULL,
  price_paid DECIMAL(10,2) NOT NULL,
  payment_id UUID,
  download_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, book_id)
);

CREATE INDEX idx_book_purchases_student_id ON book_purchases(student_id);
CREATE INDEX idx_book_purchases_book_id ON book_purchases(book_id);

-- Live Sessions Table
CREATE TABLE live_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status session_status NOT NULL,
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  recording_url TEXT,
  agora_channel_name TEXT NOT NULL,
  viewers_count INTEGER DEFAULT 0,
  duration_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_live_sessions_course_id ON live_sessions(course_id);
CREATE INDEX idx_live_sessions_teacher_id ON live_sessions(teacher_id);
CREATE INDEX idx_live_sessions_status ON live_sessions(status);
CREATE INDEX idx_live_sessions_scheduled_at ON live_sessions(scheduled_at);

-- Conversations Table
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id),
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count_student INTEGER DEFAULT 0,
  unread_count_teacher INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, teacher_id)
);

CREATE INDEX idx_conversations_student_id ON conversations(student_id);
CREATE INDEX idx_conversations_teacher_id ON conversations(teacher_id);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at);

-- Messages Table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_sent_at ON messages(sent_at);
CREATE INDEX idx_messages_conversation_sent ON messages(conversation_id, sent_at);
CREATE INDEX idx_messages_is_read ON messages(is_read);

-- Announcements Table
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_announcements_teacher_id ON announcements(teacher_id);
CREATE INDEX idx_announcements_course_id ON announcements(course_id);
CREATE INDEX idx_announcements_sent_at ON announcements(sent_at);

-- Payments Table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'BHD',
  stripe_payment_id TEXT UNIQUE,
  status payment_status NOT NULL,
  item_type item_type NOT NULL,
  item_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_item_type ON payments(item_type);
CREATE INDEX idx_payments_stripe_payment_id ON payments(stripe_payment_id);
CREATE INDEX idx_payments_created_at ON payments(created_at);

-- Cart Table
CREATE TABLE cart (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_type item_type NOT NULL,
  course_id UUID REFERENCES courses(id),
  book_id UUID REFERENCES books(id),
  private_lesson_booking_id UUID,
  added_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cart_user_id ON cart(user_id);

-- Notifications Table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type notification_type NOT NULL,
  reference_id UUID,
  is_read BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_sent_at ON notifications(sent_at);
CREATE INDEX idx_notifications_type ON notifications(type);

-- Teacher Availability Table
CREATE TABLE teacher_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id),
  price_per_hour DECIMAL(10,2) NOT NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_teacher_availability_teacher_id ON teacher_availability(teacher_id);
CREATE INDEX idx_teacher_availability_subject_id ON teacher_availability(subject_id);
CREATE INDEX idx_teacher_availability_day_of_week ON teacher_availability(day_of_week);
CREATE INDEX idx_teacher_availability_is_available ON teacher_availability(is_available);

-- Private Lesson Bookings Table
CREATE TABLE private_lesson_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id),
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  duration_hours INTEGER NOT NULL CHECK (duration_hours IN (1, 2)),
  price_per_hour DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  status booking_status NOT NULL,
  payment_id UUID,
  meeting_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_private_lesson_bookings_student_id ON private_lesson_bookings(student_id);
CREATE INDEX idx_private_lesson_bookings_teacher_id ON private_lesson_bookings(teacher_id);
CREATE INDEX idx_private_lesson_bookings_subject_id ON private_lesson_bookings(subject_id);
CREATE INDEX idx_private_lesson_bookings_booking_date ON private_lesson_bookings(booking_date);
CREATE INDEX idx_private_lesson_bookings_status ON private_lesson_bookings(status);

-- Add Foreign Keys for cart and enrollments/book_purchases
ALTER TABLE cart ADD CONSTRAINT fk_cart_private_lesson 
  FOREIGN KEY (private_lesson_booking_id) REFERENCES private_lesson_bookings(id);

ALTER TABLE enrollments ADD CONSTRAINT fk_enrollments_payment 
  FOREIGN KEY (payment_id) REFERENCES payments(id);

ALTER TABLE book_purchases ADD CONSTRAINT fk_book_purchases_payment 
  FOREIGN KEY (payment_id) REFERENCES payments(id);

ALTER TABLE private_lesson_bookings ADD CONSTRAINT fk_bookings_payment 
  FOREIGN KEY (payment_id) REFERENCES payments(id);

-- ============================================
-- STEP 3: Cart Validation
-- ============================================

ALTER TABLE cart ADD CONSTRAINT cart_item_check CHECK (
  (item_type = 'course' AND course_id IS NOT NULL AND book_id IS NULL AND private_lesson_booking_id IS NULL) OR
  (item_type = 'book' AND book_id IS NOT NULL AND course_id IS NULL AND private_lesson_booking_id IS NULL) OR
  (item_type = 'private_lesson' AND private_lesson_booking_id IS NOT NULL AND course_id IS NULL AND book_id IS NULL)
);

-- ============================================
-- STEP 4: Updated_at Triggers
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at 
  BEFORE UPDATE ON courses
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_books_updated_at 
  BEFORE UPDATE ON books
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at 
  BEFORE UPDATE ON payments
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_private_lesson_bookings_updated_at
  BEFORE UPDATE ON private_lesson_bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 5: Table RLS Policies
-- ============================================

-- users: anon can look up by phone (needed for login)
CREATE POLICY "anon_phone_lookup"
  ON public.users FOR SELECT TO anon USING (true);

-- cart: allow all operations (anon sessions used in dev bypass)
CREATE POLICY "allow_cart_all"
  ON public.cart FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

-- live_sessions: teachers manage their own sessions
CREATE POLICY "teachers_can_manage_sessions"
  ON public.live_sessions FOR ALL TO authenticated
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

-- ============================================
-- STEP 6: Storage Bucket RLS Policies
-- ============================================
-- All 4 buckets blocked by default (RLS on, no policies).
-- These are the minimum required for the app to function.

CREATE POLICY "books_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING  (bucket_id = 'books')
  WITH CHECK (bucket_id = 'books');

CREATE POLICY "recordings_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING  (bucket_id = 'recordings')
  WITH CHECK (bucket_id = 'recordings');

CREATE POLICY "avatars_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING  (bucket_id = 'avatars')
  WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "thumbnails_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING  (bucket_id = 'course-thumbnails')
  WITH CHECK (bucket_id = 'course-thumbnails');
