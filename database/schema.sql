-- ============================================
-- BOOKS AT DOORSTEPS - SUPABASE SCHEMA
-- ============================================
-- Database: Supabase PostgreSQL
-- Purpose: Two-sided book marketplace (Deepshikha Digital pivot)
-- Last Updated: 2026-07-14

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
-- Extended user profile linked to Supabase auth.users
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('publisher', 'school', 'institution', 'individual')),
  full_name TEXT,
  organisation TEXT,
  phone TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Users can read own profile; admins can read all
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins can read all profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Index for faster lookups
CREATE INDEX idx_profiles_category ON profiles(category);
CREATE INDEX idx_profiles_is_admin ON profiles(is_admin);

-- ============================================
-- 2. LISTINGS TABLE
-- (Books published by publishers)
-- ============================================
CREATE TABLE IF NOT EXISTS listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  publisher_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT,
  origin TEXT NOT NULL CHECK (origin IN ('Indian', 'Foreign')),
  mrp NUMERIC(10, 2),
  price NUMERIC(10, 2) NOT NULL,
  image_url TEXT,
  description TEXT,
  isbn TEXT,
  sku TEXT,
  binding TEXT,
  no_of_pages INTEGER,
  age_band TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Anyone can read approved; publishers can write own; admins approve/reject
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read approved listings"
  ON listings FOR SELECT
  USING (status = 'approved');

CREATE POLICY "Publishers can read own listings"
  ON listings FOR SELECT
  USING (auth.uid() = publisher_id);

CREATE POLICY "Admins can read all listings"
  ON listings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Publishers can insert listings"
  ON listings FOR INSERT
  WITH CHECK (auth.uid() = publisher_id);

CREATE POLICY "Publishers can update own listings"
  ON listings FOR UPDATE
  USING (auth.uid() = publisher_id)
  WITH CHECK (auth.uid() = publisher_id);

CREATE POLICY "Admins can update all listings"
  ON listings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes for faster queries
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_publisher_id ON listings(publisher_id);
CREATE INDEX idx_listings_category ON listings(category);
CREATE INDEX idx_listings_created_at ON listings(created_at DESC);
CREATE INDEX idx_listings_status_created ON listings(status, created_at DESC);

-- ============================================
-- 3. BOOK_REQUESTS TABLE
-- (Buyer requests for books)
-- ============================================
CREATE TABLE IF NOT EXISTS book_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  book_title TEXT NOT NULL,
  author TEXT,
  isbn TEXT,
  notes TEXT,
  quantity INTEGER DEFAULT 1,
  urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('normal', 'urgent', 'asap')),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'fulfilled', 'rejected', 'closed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Users can read own requests; admins can read all
ALTER TABLE book_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own requests"
  ON book_requests FOR SELECT
  USING (auth.uid() = requester_id);

CREATE POLICY "Admins can read all requests"
  ON book_requests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Users can insert requests"
  ON book_requests FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Admins can update requests"
  ON book_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes
CREATE INDEX idx_book_requests_requester_id ON book_requests(requester_id);
CREATE INDEX idx_book_requests_status ON book_requests(status);
CREATE INDEX idx_book_requests_created_at ON book_requests(created_at DESC);

-- ============================================
-- 4. CONTACT_REQUESTS TABLE
-- (Public contact form submissions)
-- ============================================
CREATE TABLE IF NOT EXISTS contact_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'replied', 'closed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Only admins can read contact messages
ALTER TABLE contact_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read all contact requests"
  ON contact_requests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Anyone can insert contact requests"
  ON contact_requests FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "Admins can update contact requests"
  ON contact_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes
CREATE INDEX idx_contact_requests_status ON contact_requests(status);
CREATE INDEX idx_contact_requests_created_at ON contact_requests(created_at DESC);

-- ============================================
-- 5. STUDENT_PROGRESS TABLE
-- (Per-letter mastery for learning games)
-- ============================================
CREATE TABLE IF NOT EXISTS student_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  game_key TEXT NOT NULL,
  letter TEXT NOT NULL CHECK (letter ~ '^[A-Z]$'),
  stars INTEGER DEFAULT 0 CHECK (stars >= 0 AND stars <= 3),
  mastered BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, game_key, letter)
);

ALTER TABLE student_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own student progress"
  ON student_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own student progress"
  ON student_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own student progress"
  ON student_progress FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_student_progress_user_game ON student_progress(user_id, game_key);

-- ============================================
-- 6. GAME_SCORES TABLE
-- (Leaderboard scores for games)
-- ============================================
CREATE TABLE IF NOT EXISTS game_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  game_key TEXT NOT NULL,
  mode TEXT NOT NULL,
  best_score INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, game_key, mode)
);

ALTER TABLE game_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read game scores"
  ON game_scores FOR SELECT
  USING (TRUE);

CREATE POLICY "Users can insert own game scores"
  ON game_scores FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own game scores"
  ON game_scores FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_game_scores_game_key_score ON game_scores(game_key, best_score DESC);

-- ============================================
-- 7. ORDERS TABLE
-- (Customer orders for books)
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL, -- e.g., ORD-2025-00123
  buyer_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  school_name TEXT,
  city TEXT,
  state TEXT,
  total_amount NUMERIC(12, 2),
  gst_amount NUMERIC(12, 2),
  status TEXT DEFAULT 'pending_ack' CHECK (status IN ('pending_ack', 'in_process', 'processed', 'shipped', 'delivered', 'cancelled')),
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Users can read own orders; admins can read all
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own orders"
  ON orders FOR SELECT
  USING (auth.uid() = buyer_id);

CREATE POLICY "Admins can read all orders"
  ON orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Admins can insert orders"
  ON orders FOR INSERT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Admins can update orders"
  ON orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes
CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE UNIQUE INDEX idx_orders_order_number ON orders(order_number);

-- ============================================
-- 8. ORDER_ITEMS TABLE
-- (Line items in orders)
-- ============================================
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES listings ON DELETE SET NULL,
  book_title TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10, 2) NOT NULL,
  line_total NUMERIC(12, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Inherit from orders table (via order_id)
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read order items of own orders"
  ON order_items FOR SELECT
  USING (
    order_id IN (
      SELECT id FROM orders WHERE buyer_id = auth.uid()
    )
  );

CREATE POLICY "Admins can read all order items"
  ON order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_listing_id ON order_items(listing_id);

-- ============================================
-- 9. STORE_LOCATIONS TABLE
-- (Physical store locations for fulfillment)
-- ============================================
CREATE TABLE IF NOT EXISTS store_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state TEXT NOT NULL,
  city TEXT NOT NULL,
  vendor_name TEXT NOT NULL,
  contact_person TEXT,
  phone TEXT NOT NULL,
  email TEXT,
  address TEXT NOT NULL,
  latitude NUMERIC(10, 8),
  longitude NUMERIC(11, 8),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Anyone can read active stores; admins manage
ALTER TABLE store_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active stores"
  ON store_locations FOR SELECT
  USING (status = 'active');

CREATE POLICY "Admins can read all stores"
  ON store_locations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Admins can insert stores"
  ON store_locations FOR INSERT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Admins can update stores"
  ON store_locations FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes
CREATE INDEX idx_store_locations_state ON store_locations(state);
CREATE INDEX idx_store_locations_city ON store_locations(state, city);
CREATE INDEX idx_store_locations_status ON store_locations(status);

-- ============================================
-- 10. JOB_REQUESTS TABLE
-- (Career/job applications)
-- ============================================
CREATE TABLE IF NOT EXISTS job_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_title TEXT NOT NULL,
  location TEXT NOT NULL,
  role_description TEXT,
  applicant_name TEXT NOT NULL,
  applicant_email TEXT NOT NULL,
  applicant_phone TEXT NOT NULL,
  resume_url TEXT,
  cover_letter TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'in_review', 'shortlisted', 'rejected')),
  acknowledged_by_admin BOOLEAN DEFAULT FALSE,
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Admins manage job requests; applicants can view own
ALTER TABLE job_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read all job requests"
  ON job_requests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Anyone can insert job requests"
  ON job_requests FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "Admins can update job requests"
  ON job_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Important: Cannot delete job_request unless acknowledged_by_admin = TRUE
-- This is enforced via trigger (see below)
ALTER TABLE job_requests ADD CONSTRAINT check_delete_acknowledged 
  CHECK (acknowledged_by_admin OR id IS NULL);

-- Indexes
CREATE INDEX idx_job_requests_status ON job_requests(status);
CREATE INDEX idx_job_requests_acknowledged ON job_requests(acknowledged_by_admin);
CREATE INDEX idx_job_requests_submitted_at ON job_requests(submitted_at DESC);

-- ============================================
-- 11. INVOICES TABLE
-- (Generated invoices for orders)
-- ============================================
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES orders ON DELETE CASCADE,
  invoice_number TEXT UNIQUE NOT NULL, -- e.g., INV-2025-00123
  subtotal NUMERIC(12, 2) NOT NULL,
  gst_rate NUMERIC(5, 2) DEFAULT 5.00,
  gst_amount NUMERIC(12, 2),
  grand_total NUMERIC(12, 2) NOT NULL,
  issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  due_at TIMESTAMP WITH TIME ZONE,
  paid_at TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'issued' CHECK (status IN ('issued', 'due', 'overdue', 'paid', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Users can read own invoices; admins manage all
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own invoices"
  ON invoices FOR SELECT
  USING (
    order_id IN (
      SELECT id FROM orders WHERE buyer_id = auth.uid()
    )
  );

CREATE POLICY "Admins can read all invoices"
  ON invoices FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes
CREATE INDEX idx_invoices_order_id ON invoices(order_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE UNIQUE INDEX idx_invoices_invoice_number ON invoices(invoice_number);

-- ============================================
-- 12. AUDIT_LOG TABLE
-- (Track all admin actions)
-- ============================================
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users ON DELETE SET NULL,
  action TEXT NOT NULL,
  table_name TEXT,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policy: Only admins can read audit logs
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read audit log"
  ON audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Indexes
CREATE INDEX idx_audit_log_admin_id ON audit_log(admin_id);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp DESC);

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Dashboard stats
CREATE OR REPLACE VIEW dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE) as today_orders,
  (SELECT COUNT(*) FROM orders WHERE status = 'pending_ack') as pending_acks,
  (SELECT COUNT(*) FROM orders WHERE DATE(created_at) >= CURRENT_DATE - INTERVAL '30 days') as sample_orders_this_month,
  (SELECT COUNT(*) FROM job_requests WHERE status = 'new') as pending_job_requests;

-- View: Publisher analytics
CREATE OR REPLACE VIEW publisher_analytics AS
SELECT
  publisher_id,
  COUNT(*) as total_listings,
  SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_listings,
  SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_listings,
  SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected_listings,
  COUNT(DISTINCT category) as categories_covered
FROM listings
GROUP BY publisher_id;

-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

-- Note: In production, use proper seed scripts
-- Sample users are created via Supabase Auth UI or API

-- Example: Insert sample stores (only if needed for testing)
-- INSERT INTO store_locations (state, city, vendor_name, contact_person, phone, address, status)
-- VALUES
--   ('Delhi', 'New Delhi', 'ABC Book Depot', 'Mr. Sharma', '9812345678', 'Karol Bagh, New Delhi', 'active'),
--   ('Maharashtra', 'Mumbai', 'Bright Kids Store', 'Ms. Rao', '9987654321', 'Andheri West, Mumbai', 'active');

-- ============================================
-- TRIGGERS & FUNCTIONS
-- ============================================

-- Trigger: Prevent deletion of job_request without acknowledgement
CREATE OR REPLACE FUNCTION check_job_request_acknowledged()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.acknowledged_by_admin = FALSE THEN
    RAISE EXCEPTION 'Cannot delete job request without acknowledgement. Set acknowledged_by_admin = TRUE first.';
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER job_request_delete_trigger
BEFORE DELETE ON job_requests
FOR EACH ROW
EXECUTE FUNCTION check_job_request_acknowledged();

-- Trigger: Auto-set acknowledged_at timestamp
CREATE OR REPLACE FUNCTION set_job_request_acknowledged_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.acknowledged_by_admin = TRUE AND OLD.acknowledged_by_admin = FALSE THEN
    NEW.acknowledged_at = CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER job_request_acknowledge_trigger
BEFORE UPDATE ON job_requests
FOR EACH ROW
EXECUTE FUNCTION set_job_request_acknowledged_at();

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at column
CREATE TRIGGER profiles_update_timestamp
BEFORE UPDATE ON profiles FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER listings_update_timestamp
BEFORE UPDATE ON listings FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER book_requests_update_timestamp
BEFORE UPDATE ON book_requests FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER contact_requests_update_timestamp
BEFORE UPDATE ON contact_requests FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER student_progress_update_timestamp
BEFORE UPDATE ON student_progress FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER game_scores_update_timestamp
BEFORE UPDATE ON game_scores FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER orders_update_timestamp
BEFORE UPDATE ON orders FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER store_locations_update_timestamp
BEFORE UPDATE ON store_locations FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER job_requests_update_timestamp
BEFORE UPDATE ON job_requests FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER invoices_update_timestamp
BEFORE UPDATE ON invoices FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- ============================================
-- END OF SCHEMA
-- ============================================
