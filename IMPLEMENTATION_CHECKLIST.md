# Books at Doorsteps - Implementation Checklist

**Project**: Two-sided book marketplace (Deepshikha Digital pivot)  
**Status**: Early-stage (UI complete, backend integration in progress)  
**Last Updated**: 2026-07-14

---

## 📋 Phase 1: Core Setup & Configuration

### Authentication & User Management
- [ ] **Supabase Project Setup**
  - [ ] Verify Supabase credentials in `booksatdoorsteps_live.html` (lines 347-349)
  - [ ] Test connection: Open browser console, run `sb.auth.getSession()`
  - [ ] Expected: Returns current session or `null`

- [ ] **Database Tables Verification**
  - [ ] `profiles` table exists with columns:
    - `id` (UUID, PK, from auth.users)
    - `category` (enum: publisher, school, institution, individual)
    - `full_name` (text)
    - `organisation` (text, nullable)
    - `phone` (text, nullable)
    - `is_admin` (boolean, default: false)
    - `created_at` (timestamp)
  - [ ] `listings` table exists with columns:
    - `id` (UUID, PK)
    - `publisher_id` (UUID, FK → auth.users)
    - `title` (text)
    - `category` (text)
    - `origin` (enum: Indian, Foreign)
    - `mrp` (numeric, nullable)
    - `price` (numeric)
    - `image_url` (text, nullable)
    - `description` (text, nullable)
    - `status` (enum: pending, approved, rejected, default: pending)
    - `created_at` (timestamp)
  - [ ] `book_requests` table exists with columns:
    - `id` (UUID, PK)
    - `requester_id` (UUID, FK → auth.users)
    - `book_title` (text)
    - `notes` (text, nullable)
    - `status` (text, default: open)
    - `created_at` (timestamp)
  - [ ] `contact_requests` table exists with columns:
    - `id` (UUID, PK)
    - `name` (text)
    - `email` (text)
    - `phone` (text, nullable)
    - `message` (text)
    - `created_at` (timestamp)

- [ ] **Row-Level Security (RLS) Policies**
  - [ ] `profiles`: Users can read own profile; admins can read all
  - [ ] `listings`: Anyone can read approved; publishers can write own; admins approve/reject
  - [ ] `book_requests`: Users can read own requests; admins can read all
  - [ ] `contact_requests`: Admins can read all

### Sign Up / Login Testing
- [ ] Test sign-up as **Publisher** (booksatdoorsteps_live.html, signup pane, lines 164-203)
  - [ ] Navigate to Login view
  - [ ] Click "Sign Up" tab
  - [ ] Select category: "Publisher"
  - [ ] Fill form: name, org, phone, email, password
  - [ ] Click "Create Account"
  - [ ] Expected: Success message; profile row created in `profiles` table

- [ ] Test sign-up as **School**
  - [ ] Repeat above; select "School" category
  - [ ] Verify `category` = 'school' in profiles table

- [ ] Test login
  - [ ] Click "Log In" tab
  - [ ] Enter email + password from above
  - [ ] Expected: Redirect to My Account; welcome message shows logged-in user

- [ ] Test logout (line 423-427)
  - [ ] Click "Log Out" button
  - [ ] Expected: Redirect to Browse; auth nav items swap

---

## 📋 Phase 2: Public Browse & Discovery

### Book Catalog Display
- [ ] **Browse View Loading** (lines 431-483)
  - [ ] Navigate to "Browse Books" (click logo or nav)
  - [ ] Query runs: `listings` table, filter `status = 'approved'`
  - [ ] Display: Grid of book cards with cover images
  - [ ] Expected: 68 books from CSV show up (see `Supabase Snippet Untitled query (1).csv`)
  - [ ] Verify columns rendered: origin tag (Indian/Foreign), title, price, MRP strikethrough

- [ ] **Search Functionality** (line 484)
  - [ ] Type book title in search box (e.g., "Spell Smart")
  - [ ] Grid filters in real-time
  - [ ] Expected: Shows matching books only

- [ ] **Category Filtering** (lines 439-453)
  - [ ] Extract unique categories from books
  - [ ] Display filter buttons: "All", "Phonics", "Colouring", "Maths", etc.
  - [ ] Click each category button
  - [ ] Expected: Grid updates to show only that category

- [ ] **Empty State** (lines 95-98, 462)
  - [ ] Search for non-existent book (e.g., "xyz123")
  - [ ] Expected: "No books yet in this category" message

### Book Card Styling
- [ ] **Visual Elements** (reference screenshots #10-35)
  - [ ] Book cover: 3:4 aspect ratio, rounded corners
  - [ ] Origin tag: Blue pill for Indian, Pink for Foreign
  - [ ] Title: Bold, truncate if too long
  - [ ] Price display: Current price in bold + strikethrough MRP
  - [ ] Hover effect: Slight upward lift (CSS: `transform: translateY(-3px)`)

---

## 📋 Phase 3: User Account Features

### Publisher Portal
- [ ] **List a New Book** (lines 219-265)
  - [ ] Log in as publisher (from Phase 1)
  - [ ] Click "My Account"
  - [ ] Publisher panel visible (not buyer panel)
  - [ ] Form fields: title, category, origin, MRP, offer price, image URL, description
  - [ ] Submit form
  - [ ] Expected: Book inserted into `listings` with `status = 'pending'`
  - [ ] Verify: Book appears in "Your submissions" table with "pending" badge

- [ ] **View Submission Status** (lines 515-522)
  - [ ] "Your submissions" table shows all published books
  - [ ] Status badges: pending (yellow), approved (green), rejected (red)
  - [ ] Can see MRP, price, category

### Buyer Portal
- [ ] **Request a Book** (lines 276-303)
  - [ ] Log in as school/institution (from Phase 1)
  - [ ] Click "My Account"
  - [ ] Buyer panel visible (not publisher)
  - [ ] Form fields: book title (author/ISBN), notes (quantity, deadline, etc.)
  - [ ] Submit form
  - [ ] Expected: Record inserted into `book_requests` with `status = 'open'`
  - [ ] Verify: Book appears in "Your requests" table

- [ ] **View Request History** (lines 524-531)
  - [ ] "Your requests" table shows all submitted requests
  - [ ] Can see: book title, notes, status

### Public Contact Form
- [ ] **Contact Page** (lines 102-137)
  - [ ] Click "Contact Us" in navbar
  - [ ] Form fields: name, email, phone, message
  - [ ] No login required
  - [ ] Submit
  - [ ] Expected: Record inserted into `contact_requests`
  - [ ] Success message: "We'll get back to you shortly"
  - [ ] Display contact info: support@booksatdoorsteps.com, WhatsApp +91 95559 87368

---

## 📋 Phase 4: Admin Dashboard

### Admin Access Control
- [ ] **Admin Flag Setup**
  - [ ] Manually set `is_admin = true` for a test user in `profiles` table
  - [ ] Log in as that user
  - [ ] Expected: "Admin" link appears in navbar (line 74)

- [ ] **Admin View Access** (lines 309-334)
  - [ ] Click "Admin" in navbar
  - [ ] Three sections load: Pending Listings, Book Requests, Contact Messages

### Listing Moderation (lines 564-609)
- [ ] **Pending Listings Table** (lines 312-317)
  - [ ] Shows books with `status = 'pending'`
  - [ ] Columns: book title, origin, price (with MRP), status, action buttons
  - [ ] Click "Approve" button (line 578)
    - [ ] Expected: `listings.status` updates to 'approved'
    - [ ] Book now appears in Browse view for public
  - [ ] Click "Reject" button (line 579)
    - [ ] Expected: `listings.status` updates to 'rejected'
    - [ ] Book hidden from Browse view

### Book Requests Queue (lines 585-591)
- [ ] **Requests Table** (lines 319-324)
  - [ ] Shows all records from `book_requests`
  - [ ] Columns: book name, notes, status
  - [ ] No action buttons (display-only for now)

### Contact Messages (lines 593-599)
- [ ] **Messages Table** (lines 326-331)
  - [ ] Shows all records from `contact_requests`
  - [ ] Columns: name, contact (email + phone), message, received timestamp
  - [ ] Verify: Messages from Phase 3 "Contact" form appear here

---

## 📋 Phase 5: Dashboard (Admin Portal UI)

### Dashboard Home (reference `dashboard.html`)
- [ ] **Navigation Sidebar** (lines 15-64)
  - [ ] Sticky navigation with logo "DD" + "Deepshikha"
  - [ ] Menu items: Dashboard, Orders, Sample Orders, Store Locator, Users, Resources, Careers, Conditions
  - [ ] User dropdown: Profile, Settings, Sign out
  - [ ] Verify all links navigate correctly

- [ ] **Stat Cards** (lines 77-114)
  - [ ] Today's Orders: 128 (placeholder)
  - [ ] Pending Acks: 9 (placeholder)
  - [ ] Sample Orders: 32 (placeholder)
  - [ ] Job Requests: 5 (placeholder)
  - [ ] Note: These are static in current build; connect to database later

- [ ] **Recent Orders Table** (lines 116-166)
  - [ ] Shows recent orders with search/filter
  - [ ] Columns: Order No., School/Partner, City, Status, Invoice, Updated
  - [ ] Statuses shown: "Processed" (green), "Pending Ack." (yellow), "In Process" (blue)
  - [ ] Test search by school name or city

- [ ] **Quick Store Lookup** (lines 168-196)
  - [ ] Form fields: State, City
  - [ ] Search button
  - [ ] Note: Connect to store_locations table (future phase)

- [ ] **Job Requests Snapshot** (lines 198-222)
  - [ ] List of recent jobs: Sales Executive – Delhi, Academic Coordinator – Jaipur, etc.
  - [ ] Status badges: "New", "In Review", "Shortlisted"

---

## 📋 Phase 6: Orders Management (reference `orders-list.html`)

### Order Listing & Filtering
- [ ] **Orders Table** (lines 108-155)
  - [ ] Columns: Order No., School/Partner, City, Status, Process, Invoice, Last Updated
  - [ ] Sample data shown (placeholders)
  - [ ] Status values: "Processed", "Pending Ack.", "In Process"

- [ ] **Filter Form** (lines 77-106)
  - [ ] Filters: Order No., School/Partner, City, Status
  - [ ] "Filter" button triggers search
  - [ ] Note: Implement filtering logic

- [ ] **Row Actions**
  - [ ] Click Order No. → Open order detail (future page)
  - [ ] "View process list" → Show order items, fulfillment status
  - [ ] "Start processing" → Change status to "In Process"
  - [ ] "Download" / "Preview" → Show invoice (reference `invoice.html`)

---

## 📋 Phase 7: Sample Orders & Details

### Sample Orders List (reference `sample-orders.html`)
- [ ] Display list of sample book orders
- [ ] Columns: Sample Order ID, School, Books Requested, Status, Date
- [ ] Statuses: "Pending", "Processing", "Shipped", "Delivered"

### Order Details (reference `sample-order-detail.html`)
- [ ] Order header: Order ID, school name, order date
- [ ] Order items table: Book title, quantity, unit price, total
- [ ] Order total & shipping
- [ ] Status timeline: Order placed → Processing → Shipped → Delivered

---

## 📋 Phase 8: Invoice Generation (reference `invoice.html`)

### Invoice Display & Download
- [ ] **Invoice Layout**
  - [ ] Header: Company logo, invoice #, issue date, due date
  - [ ] Bill to: School/customer name, address, contact
  - [ ] Items table: Book title, ISBN, qty, unit price, line total
  - [ ] Totals: Subtotal, GST (if applicable), grand total
  - [ ] Payment terms & notes

- [ ] **PDF Export**
  - [ ] "Download" button generates PDF
  - [ ] Filename: `Invoice_ORD-2025-00123.pdf`

- [ ] **Print Function**
  - [ ] "Print" button opens print dialog (browser native)

---

## 📋 Phase 9: Store Locator (reference `store-locator.html`, screenshots #46-48)

### Store Location Management
- [ ] **Create `store_locations` table** (if not exists)
  - Columns: id (UUID), state, city, vendor_name, contact_person, phone, address, created_at
  - Sample data: Delhi/New Delhi/ABC Book Depot, Mumbai/Bright Kids Store, etc.

- [ ] **Store Locator UI** (lines 76-140)
  - [ ] Filters: State, City, Vendor
  - [ ] Search button
  - [ ] Results table: State, City, Vendor Name, Contact, Phone, Address
  - [ ] Verify sample stores display (screenshots #46-48)

- [ ] **Future Enhancement: Map Integration**
  - [ ] Add Leaflet or Google Maps
  - [ ] Show store pins on map
  - [ ] Zoom to state/city
  - [ ] Reference: Screenshots #46-48 show UI layout

---

## 📋 Phase 10: Users Management (reference `users.html`, screenshots #49)

### User Directory
- [ ] **Create `user_profiles` view or query** (combines auth.users + profiles table)
  - Columns: id, full_name, category (role), school/organization, mobile, email, status

- [ ] **Users Page UI** (lines 68-124)
  - [ ] Tabs: "Parents", "School Professionals"
  - [ ] Click tab → filter users by category
  - [ ] Table: Name, Role, School/City, Mobile, Email, Status, Edit button

- [ ] **User Status**
  - [ ] Badge: "Active" (green), "Inactive" (gray)
  - [ ] Manually set in `profiles` table or add `status` column

- [ ] **Edit User**
  - [ ] Click "Edit" → Open modal/form to update profile info
  - [ ] Fields: Full name, organization, phone, status

- [ ] **Add New User**
  - [ ] "Add New User" button → Form to create user (admin-only invite)

---

## 📋 Phase 11: Careers / Job Requests (reference `careers.html`, screenshot #44)

### Job Management System
- [ ] **Create `job_requests` table**
  - Columns: id (UUID), title (text), location (text), role_description (text), salary_range (text), applicant_name (text), applicant_email (text), applicant_phone (text), resume_url (text), status (enum: new, in_review, shortlisted, rejected), submitted_at (timestamp), acknowledged_by_admin (boolean), acknowledged_at (timestamp)

- [ ] **Important Workflow**: "No delete without acknowledgement" (screenshot #44)
  - [ ] Job request can only be deleted if `acknowledged_by_admin = true`
  - [ ] Add button: "Acknowledge" before allowing delete
  - [ ] Update UI: "Acknowledged ✓" status, then show "Delete" button

- [ ] **Careers Page** (reference `careers.html`)
  - [ ] Public job listings: Title, location, description
  - [ ] Application form: Name, email, phone, attach resume, submit

- [ ] **Admin Jobs Panel** (future: add to dashboard)
  - [ ] List all job requests with status
  - [ ] "Acknowledge" button → Mark as reviewed
  - [ ] "Delete" button → Only enabled after acknowledgement
  - [ ] "Shortlist" button → Update status

---

## 📋 Phase 12: Resources & Conditions (reference `resources.html`, `conditions.html`)

### Resources Page (screenshot #39, reference `resources.html`)
- [ ] Static content page or CMS integration
- [ ] Sections: Learning materials, guides, FAQs, downloadables
- [ ] No database required initially (can hardcode HTML)

### Terms & Conditions (screenshot #45, reference `conditions.html`)
- [ ] Static T&C page
- [ ] Sections: User agreement, book purchase terms, liability, privacy policy
- [ ] Link in footer

---

## 🔧 Phase 13: CSS Styling & Responsive Design

### Create `css/styles.css`
- [ ] **Referenced in all HTML files** (line 8 in each template)
- [ ] **Current content**: Empty (all styles inline via Bootstrap + `<style>` tags)

### Build Complete Stylesheet
- [ ] **Sidebar styling** (`.sidebar`, `.sidebar-brand`, `.nav-pills`)
- [ ] **Main panel layout** (`.main-panel`, `.dashboard-shell`)
- [ ] **Card styling** (`.card`, `.stat-card`, `.book-card`, `.rounded-4`)
- [ ] **Badge styling** (`.badge`, status colors)
- [ ] **Table styling** (`.table-responsive`, `.table-light`)
- [ ] **Form styling** (`.form-control`, `.form-select`, `.btn`)
- [ ] **Responsive breakpoints** (sm, md, lg, xl)
- [ ] **Print styles** (for invoice printing)

### Responsive Testing
- [ ] Desktop (1920px, 1440px, 1024px)
- [ ] Tablet (768px)
- [ ] Mobile (375px, 414px)
- [ ] Verify: Sidebar collapses, tables scroll horizontally, forms stack vertically

---

## 🔧 Phase 14: Data Population & Testing

### Load Sample Data
- [ ] **Import CSV to `listings` table**
  - [ ] File: `Supabase Snippet Untitled query (1).csv`
  - [ ] Columns match: title, category, origin, price, mrp, image_url, status (set to 'approved')
  - [ ] Expected: 68 books inserted

- [ ] **Create test users**
  - [ ] 1 admin user
  - [ ] 2 publisher users
  - [ ] 3 school users
  - [ ] 2 individual users

- [ ] **Create test orders**
  - [ ] 3-5 sample orders with different statuses
  - [ ] Link to schools, include order items

### End-to-End Testing
- [ ] **User flow: Publisher**
  - [ ] Sign up as publisher → Log in → List book → Admin approves → Book appears in browse
  
- [ ] **User flow: Buyer**
  - [ ] Sign up as school → Log in → Request book → Admin reviews → Status updates

- [ ] **User flow: Admin**
  - [ ] Log in as admin → Review pending listings → Approve/reject → Moderate requests

---

## 📊 Phase 15: Performance & Optimization

### Database Optimization
- [ ] **Add indexes**
  - [ ] `listings`: (status, publisher_id), (category), (created_at DESC)
  - [ ] `profiles`: (category)
  - [ ] `book_requests`: (requester_id, created_at DESC)

- [ ] **Query optimization**
  - [ ] Use `.select()` to fetch only needed columns
  - [ ] Implement pagination (LIMIT 50) for large result sets
  - [ ] Cache static data (categories list) in frontend

### Frontend Optimization
- [ ] **Lazy load images** in book grid (Intersection Observer API)
- [ ] **Debounce search input** (e.g., 300ms delay before query)
- [ ] **Minify CSS/JS** (if using build process)
- [ ] **Code splitting** (separate admin bundle from public site)

### Security
- [ ] **Enable RLS** (Row-Level Security) on all tables
- [ ] **Validate all inputs** (server-side in Supabase policies or Edge Functions)
- [ ] **Rate limit** auth endpoints (Supabase default: 3/minute)
- [ ] **Hide sensitive data** (don't expose internal URLs, API keys in JS)

---

## 📲 Phase 16: Payment Integration (Future)

### Stripe / Razorpay Setup
- [ ] Research best payment gateway for India (Razorpay recommended for INR)
- [ ] Set up merchant account
- [ ] Add payment checkout flow (after order confirmation)
- [ ] Store payment records in new `payments` table

### Order Flow with Payments
- [ ] Order created → Payment form → Payment processed → Order confirmed → Invoice generated

---

## 🚀 Phase 17: Deployment Prep

### Environment Configuration
- [ ] Create `.env.local` (local dev)
  - SUPABASE_URL
  - SUPABASE_KEY (anon/public key only)
- [ ] Create `.env.production` (production)
  - Different Supabase project (recommend separate prod DB)
  - Production URLs, API keys

### Frontend Hosting Options
- [ ] **Vercel** (recommended for Next.js, but works with static too)
- [ ] **Netlify** (great for static sites + serverless functions)
- [ ] **GitHub Pages** (free, simple, no backend)
- [ ] **AWS S3 + CloudFront** (scalable, more setup)

### Pre-Launch Checklist
- [ ] [ ] All 17 phases complete
- [ ] [ ] User testing: Minimum 5 users per role (admin, publisher, buyer)
- [ ] [ ] Browser testing: Chrome, Firefox, Safari, Edge
- [ ] [ ] Mobile testing: iOS Safari, Android Chrome
- [ ] [ ] Accessibility: WCAG AA compliance (keyboard nav, screen readers, color contrast)
- [ ] [ ] Performance: Lighthouse score >90
- [ ] [ ] Security audit: No console errors, XSS/CSRF protected
- [ ] [ ] Privacy policy & T&Cs published
- [ ] [ ] Analytics setup (Google Analytics, Sentry for error tracking)

---

## 📞 Support & Troubleshooting

### Common Issues

**Q: Browse page shows no books**
- A: Check if `listings` table has records with `status = 'approved'`
- A: Verify Supabase URL/KEY in lines 347-349 of `booksatdoorsteps_live.html`
- A: Check browser console for auth errors

**Q: Login doesn't work**
- A: Confirm user exists in Supabase `auth.users` table
- A: Check `profiles` table has matching user ID
- A: Verify email is confirmed (check auth.users email_confirmed_at)

**Q: Admin features not showing**
- A: Log in as user with `profiles.is_admin = true`
- A: Check browser console for RLS errors

**Q: Images not loading on book cards**
- A: Verify `image_url` in `listings` is a valid HTTPS URL
- A: Check CORS settings (should work with Supabase-hosted images)

### Next Steps if Stuck
1. Check Supabase dashboard → Tables → Inspect data
2. Open browser DevTools → Console → Check for JavaScript errors
3. Open DevTools → Network → Check API calls to Supabase
4. Review Supabase RLS policies → Ensure user role has read/write access

---

**Last Updated**: 2026-07-14  
**Checklist Version**: 1.0  
**Maintained By**: greenraw26

---
