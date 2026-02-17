# 🏠 Smart Hostel Management & Analytics System

## Comprehensive Project Overview

---

## 1. Project Abstract

The **Smart Hostel Management & Analytics System** is a full-stack application designed to digitize and streamline the end-to-end management of university hostel operations. It handles **student registration**, **room allocation**, **fee payment tracking**, **maintenance complaint management**, and provides **powerful analytics dashboards** — all backed by a robust relational database demonstrating core DBMS concepts.

The system features a **three-tier architecture**:
1. **Database Layer** — PostgreSQL with normalized schema, triggers, views, and indexes
2. **Web Server (API Layer)** — Next.js REST API with connection pooling, parameterized queries, and CORS middleware
3. **Application (Presentation Layer)** — A Flutter cross-platform mobile application (Android/iOS/Web)

---

## 2. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Database** | PostgreSQL (Neon Cloud) | Relational data storage with advanced features |
| **Web Server** | Next.js 16.1 (App Router) | RESTful API endpoints via Route Handlers |
| **Application** | Flutter (Dart) | Cross-platform mobile client (Android/iOS/Web) |
| **State Mgmt** | Provider (Flutter) | App state management |
| **HTTP Client** | `pg` (Node.js), `http` (Dart) | Database and API communication |
| **Deployment** | Vercel (API Server), Neon (Database) | Cloud hosting |
| **Fonts** | Google Fonts (Flutter) | Modern typography |

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER (Flutter)                   │
│                                                                 │
│  ┌─────────────────┐ ┌──────────────────┐ ┌─────────────────┐  │
│  │ Student Portal  │ │  Admin Portal    │ │  Analytics      │  │
│  │  - Dashboard    │ │  - Students      │ │  - Charts       │  │
│  │  - Profile      │ │  - Rooms         │ │  - Reports      │  │
│  │  - Complaints   │ │  - Hostels       │ │  - Trends       │  │
│  │  - Payments     │ │  - Allocations   │ │                 │  │
│  │  - Room Info    │ │  - Complaints    │ │                 │  │
│  │                 │ │  - Payments      │ │                 │  │
│  └─────────────────┘ └──────────────────┘ └─────────────────┘  │
│                                                                 │
│  Provider (State Mgmt) │ API Service (HTTP) │ Dart Models      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS REST API Calls
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   WEB SERVER (Next.js API Layer)                │
│              Next.js Route Handlers (App Router)                │
│                                                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐  │
│  │/students │ │ /rooms   │ │/complaints│ │   /analytics      │  │
│  ├──────────┤ ├──────────┤ ├──────────┤ │  /categories      │  │
│  │/payments │ │/allocations│/hostels   │ │  /hostels         │  │
│  │          │ │          │ │          │ │  /resolution       │  │
│  │          │ │/available │ │          │ │  /rooms  /trends   │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  CORS Middleware (src/middleware.ts)                       │  │
│  │  - Handles preflight OPTIONS requests                     │  │
│  │  - Adds CORS headers to all /api/* responses              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Database Module (src/lib/db.ts)                          │  │
│  │  - Connection pooling, parameterized queries, transactions│  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Connection Pool (pg) over SSL
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATABASE LAYER                            │
│                    PostgreSQL (Neon Cloud)                       │
│                                                                 │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌─────────────┐  │
│  │  Tables    │ │  Triggers  │ │   Views    │ │   Indexes   │  │
│  │  (8)       │ │  (5)       │ │   (9)      │ │   (11)      │  │
│  └────────────┘ └────────────┘ └────────────┘ └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Database Design (PostgreSQL)

### 4.1 Entity-Relationship Overview

The database follows a **normalized relational schema** with **8 tables**, **5 custom ENUM types**, **5 triggers**, **9 views**, and **11 indexes**.

### 4.2 Custom ENUM Types

| Type | Values | Purpose |
|---|---|---|
| `gender_type` | `male`, `female`, `other` | Gender classification for students and hostels |
| `room_type` | `single`, `double`, `triple`, `dormitory` | Room capacity classification |
| `payment_status` | `pending`, `paid`, `overdue`, `partial` | Payment lifecycle states |
| `complaint_status` | `open`, `assigned`, `in_progress`, `resolved`, `closed` | Complaint workflow states |
| `complaint_category` | `electrical`, `plumbing`, `furniture`, `cleaning`, `pest_control`, `internet`, `security`, `other` | Complaint classification |

### 4.3 Tables

#### 4.3.1 `hostels` — Hostel Master Data
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `SERIAL` | PRIMARY KEY | Auto-incremented hostel ID |
| `name` | `VARCHAR(100)` | NOT NULL, UNIQUE | Hostel name (e.g., "Alpha Hostel") |
| `address` | `TEXT` | — | Physical address |
| `gender_allowed` | `gender_type` | NOT NULL | Gender restriction for the hostel |
| `warden_name` | `VARCHAR(100)` | — | Name of the hostel warden |
| `warden_contact` | `VARCHAR(20)` | — | Warden contact number |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | Record creation time |

#### 4.3.2 `rooms` — Room Information
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `SERIAL` | PRIMARY KEY | Auto-incremented room ID |
| `hostel_id` | `INTEGER` | FK → hostels(id) ON DELETE CASCADE | Parent hostel reference |
| `room_number` | `VARCHAR(20)` | NOT NULL | Room identifier (e.g., "A-101") |
| `floor` | `INTEGER` | CHECK (floor >= 0) | Floor number |
| `room_sequence` | `INTEGER` | — | Sequence for auto-generation of room numbers |
| `room_type` | `room_type` | DEFAULT 'double' | Room type classification |
| `capacity` | `INTEGER` | CHECK (1..10) | Maximum occupancy |
| `current_occupancy` | `INTEGER` | DEFAULT 0 | Current number of students (managed by trigger) |
| `rent_amount` | `DECIMAL(10,2)` | CHECK >= 0 | Monthly/semester rent |
| `has_ac` | `BOOLEAN` | DEFAULT FALSE | AC availability |
| `has_attached_bathroom` | `BOOLEAN` | DEFAULT FALSE | Bathroom availability |
| `is_available` | `BOOLEAN` | DEFAULT TRUE | Room availability flag |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | Record creation time |

**Constraints:** `UNIQUE(hostel_id, room_number)` — No duplicate room numbers within a hostel.

#### 4.3.3 `students` — Student/Resident Records
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `SERIAL` | PRIMARY KEY | Auto-incremented student ID |
| `registration_number` | `VARCHAR(50)` | NOT NULL, UNIQUE | University registration number |
| `first_name` | `VARCHAR(50)` | NOT NULL | First name |
| `last_name` | `VARCHAR(50)` | NOT NULL | Last name |
| `email` | `VARCHAR(100)` | NOT NULL, UNIQUE, CHECK (regex) | Email with regex validation |
| `phone` | `VARCHAR(20)` | — | Contact number |
| `gender` | `gender_type` | NOT NULL | Student gender |
| `date_of_birth` | `DATE` | — | Date of birth |
| `address` | `TEXT` | — | Permanent address |
| `guardian_name` | `VARCHAR(100)` | — | Parent/guardian name |
| `guardian_phone` | `VARCHAR(20)` | — | Guardian contact |
| `department` | `VARCHAR(100)` | — | Academic department |
| `year_of_study` | `INTEGER` | CHECK (1..6) | Current academic year |
| `is_active` | `BOOLEAN` | DEFAULT TRUE | Soft-delete flag |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | Record creation time |

#### 4.3.4 `allocations` — Student-Room Assignments
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `SERIAL` | PRIMARY KEY | Allocation ID |
| `student_id` | `INTEGER` | FK → students(id) ON DELETE CASCADE | Assigned student |
| `room_id` | `INTEGER` | FK → rooms(id) ON DELETE CASCADE | Assigned room |
| `allocation_date` | `DATE` | DEFAULT CURRENT_DATE | Check-in date |
| `expected_checkout` | `DATE` | CHECK >= allocation_date | Expected departure |
| `actual_checkout` | `DATE` | — | Actual departure date |
| `is_active` | `BOOLEAN` | DEFAULT TRUE | Active allocation flag |
| `notes` | `TEXT` | — | Additional notes |

**Constraints:** `UNIQUE INDEX on (student_id) WHERE is_active = TRUE` — Ensures each student has at most **one active allocation**.

#### 4.3.5 `maintenance_staff` — Maintenance Personnel
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `SERIAL` | PRIMARY KEY | Staff ID |
| `name` | `VARCHAR(100)` | NOT NULL | Staff name |
| `email` | `VARCHAR(100)` | UNIQUE | Email address |
| `phone` | `VARCHAR(20)` | NOT NULL | Contact number |
| `specialization` | `complaint_category` | — | Area of expertise |
| `is_available` | `BOOLEAN` | DEFAULT TRUE | Availability status |
| `hostel_id` | `INTEGER` | FK → hostels(id) ON DELETE SET NULL | Assigned hostel (nullable) |

#### 4.3.6 `complaints` — Maintenance Complaints
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `SERIAL` | PRIMARY KEY | Complaint ID |
| `student_id` | `INTEGER` | FK → students(id) ON DELETE CASCADE | Reporting student |
| `room_id` | `INTEGER` | FK → rooms(id) ON DELETE CASCADE | Associated room |
| `category` | `complaint_category` | NOT NULL | Complaint type |
| `title` | `VARCHAR(200)` | NOT NULL | Short title |
| `description` | `TEXT` | NOT NULL | Detailed description |
| `status` | `complaint_status` | DEFAULT 'open' | Current status |
| `priority` | `INTEGER` | CHECK (1..5), DEFAULT 3 | Priority (1=highest, 5=lowest) |
| `assigned_staff_id` | `INTEGER` | FK → maintenance_staff(id) ON DELETE SET NULL | Assigned technician |
| `assigned_at` | `TIMESTAMP` | — | When staff was assigned |
| `resolved_at` | `TIMESTAMP` | — | Resolution timestamp |
| `closed_at` | `TIMESTAMP` | — | Closure timestamp |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | Creation time |

#### 4.3.7 `complaint_logs` — Complaint Audit Trail
| Column | Type | Description |
|---|---|---|
| `complaint_id` | `INTEGER` | FK → complaints(id) ON DELETE CASCADE |
| `old_status` | `complaint_status` | Previous status (NULL for creation) |
| `new_status` | `complaint_status` | New status |
| `changed_by` | `VARCHAR(100)` | User who made the change |
| `notes` | `TEXT` | Change notes |
| `changed_at` | `TIMESTAMP` | Timestamp of the change |

#### 4.3.8 `payments` — Fee Payment Records
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `SERIAL` | PRIMARY KEY | Payment ID |
| `student_id` | `INTEGER` | FK → students(id) ON DELETE CASCADE | Paying student |
| `allocation_id` | `INTEGER` | FK → allocations(id) ON DELETE SET NULL | Associated allocation |
| `amount` | `DECIMAL(10,2)` | CHECK > 0 | Payment amount |
| `payment_date` | `DATE` | DEFAULT CURRENT_DATE | Date of payment |
| `due_date` | `DATE` | NOT NULL | Payment deadline |
| `payment_status` | `payment_status` | DEFAULT 'pending' | Current status |
| `payment_method` | `VARCHAR(50)` | — | Method (UPI, card, bank_transfer, cash) |
| `receipt_number` | `VARCHAR(50)` | — | Generated receipt number |
| `transaction_id` | `VARCHAR(50)` | — | External transaction reference |
| `semester` | `VARCHAR(50)` | — | Academic semester |
| `notes` | `TEXT` | — | Additional notes |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | Record creation time |

### 4.4 Database Triggers (5 Triggers, 4 Functions)

| # | Trigger Name | Table | Event | Function | Purpose |
|---|---|---|---|---|---|
| 1 | `trg_check_room_capacity` | `allocations` | BEFORE INSERT/UPDATE | `check_room_capacity()` | Prevents room overflow; auto-updates `rooms.current_occupancy` on allocation/deactivation |
| 2 | `trg_handle_allocation_delete` | `allocations` | BEFORE DELETE | `handle_allocation_delete()` | Decrements `rooms.current_occupancy` when allocation is deleted |
| 3 | `trg_log_complaint_status` | `complaints` | BEFORE UPDATE | `log_complaint_status_change()` | Logs status transitions and auto-fills `assigned_at`, `resolved_at`, `closed_at` timestamps |
| 4 | `trg_log_complaint_creation` | `complaints` | AFTER INSERT | `log_complaint_creation()` | Creates initial audit log entry when a complaint is created |
| 5 | `trg_generate_room_number` | `rooms` | BEFORE INSERT/UPDATE | `generate_room_number_format()` | Auto-generates room number in `{HostelInitial}-{Floor}{Sequence}` format (e.g., A-101) |

### 4.5 Database Views (9 Views)

| # | View Name | Purpose | Key Aggregations |
|---|---|---|---|
| 1 | `complaint_category_stats` | Complaint counts by category | GROUP BY category with status breakdown |
| 2 | `room_complaint_summary` | Per-room complaint statistics | COUNT, MODE (most common category), MAX (last complaint date) |
| 3 | `hostel_complaint_summary` | Hostel-level complaint metrics | Complaints per room, complaints per student |
| 4 | `resolution_time_analytics` | Resolution time by category | AVG, MIN, MAX resolution hours, SLA breach count (>48h) |
| 5 | `monthly_complaint_trends` | Monthly complaint breakdown | Category-wise monthly counts, resolution rate |
| 6 | `student_dashboard` | Consolidated student info | JOINs across students, allocations, rooms, hostels, payments, complaints |
| 7 | `available_rooms` | Rooms with open capacity | Filters rooms where `current_occupancy < capacity` |
| 8 | `payment_dues_report` | Students with pending/overdue payments | Calculates `days_overdue` |
| 9 | `staff_workload` | Maintenance staff performance | Active/resolved complaint counts, avg resolution hours |

### 4.6 Indexes (11 Indexes)

| Table | Index | Columns | Type |
|---|---|---|---|
| `rooms` | `idx_rooms_hostel` | `hostel_id` | B-Tree |
| `students` | `idx_students_email` | `email` | B-Tree |
| `students` | `idx_students_reg` | `registration_number` | B-Tree |
| `allocations` | `idx_one_active_allocation` | `student_id` WHERE `is_active = TRUE` | Unique Partial |
| `allocations` | `idx_allocations_room` | `room_id` | B-Tree |
| `complaints` | `idx_complaints_student` | `student_id` | B-Tree |
| `complaints` | `idx_complaints_room` | `room_id` | B-Tree |
| `complaints` | `idx_complaints_status` | `status` | B-Tree |
| `complaints` | `idx_complaints_category` | `category` | B-Tree |
| `complaints` | `idx_complaints_created` | `created_at` | B-Tree |
| `complaint_logs` | `idx_complaint_logs_complaint` | `complaint_id` | B-Tree |
| `payments` | `idx_payments_student` | `student_id` | B-Tree |
| `payments` | `idx_payments_status` | `payment_status` | B-Tree |
| `payments` | `idx_payments_due_date` | `due_date` | B-Tree |

### 4.7 Seed Data Summary

| Entity | Count | Details |
|---|---|---|
| Hostels | 6 | 3 Male (Alpha, Beta, Epsilon) + 3 Female (Gamma, Delta, Zeta) |
| Rooms | 41 | Across all hostels, floors 1-3, types: single/double/triple |
| Students | 30 | Mixed departments (CS, ECE, Civil, Mechanical), years 1-3 |
| Allocations | 30 | All students allocated to gender-appropriate hostels |
| Maintenance Staff | 10 | Specialized by category (electrical, plumbing, etc.) |
| Complaints | 30 | 8 open, 6 in-progress, 10 resolved, 6 closed |
| Payments | 57 | 30 paid (Fall), 15 pending + 8 overdue + 4 partial (Spring) |

---

## 5. Web Server — API Layer (Next.js Route Handlers)

### 5.1 Connection & Security

The database module (`src/lib/db.ts`) provides:

- **Connection Pooling** — Singleton `Pool` from `pg` with configurable limits (10 max for serverless, 20 for local)
- **Parameterized Queries** — All queries use `$1, $2, ...` placeholders to prevent **SQL injection**
- **Transaction Support** — `transaction()` helper wraps multiple queries in `BEGIN/COMMIT/ROLLBACK` for atomicity
- **SSL Support** — Automatic SSL for production environments
- **Query Logging** — Duration and row count logging in development mode

### 5.2 CORS Middleware (`src/middleware.ts`)

A global middleware intercepts all `/api/*` requests to:
- Handle **preflight OPTIONS** requests with 200 status
- Attach `Access-Control-Allow-*` headers for cross-origin access (required by Flutter app)
- Support methods: `GET, POST, PUT, DELETE, PATCH, OPTIONS`

### 5.3 API Endpoints Summary

#### 5.3.1 Core CRUD Endpoints

| Method | Endpoint | Description | Key Features |
|---|---|---|---|
| `GET` | `/api/students` | List students (paginated) | Search, gender filter, active filter |
| `POST` | `/api/students` | Create student | Validation, unique registration/email |
| `GET` | `/api/students/[id]` | Student details | JOINs with allocation, room, hostel, payments, complaints |
| `PUT` | `/api/students/[id]` | Update student | Dynamic field updates |
| `DELETE` | `/api/students/[id]` | Deactivate student | Soft delete (sets `is_active = FALSE`) |
| `GET` | `/api/rooms` | List rooms (paginated) | Filter by hostel, type, available, has_vacancy |
| `POST` | `/api/rooms` | Create room | Validates hostel exists; trigger auto-generates room number |
| `GET` | `/api/rooms/available` | Available rooms | Uses `available_rooms` VIEW (or fallback query) |
| `GET` | `/api/hostels` | List all hostels | Includes room count subquery |
| `POST` | `/api/hostels` | Create hostel | Gender validation |
| `GET` | `/api/allocations` | List allocations (paginated) | Filter by student, room, hostel, active status |
| `POST` | `/api/allocations` | Create allocation | Gender check, capacity check, auto-deactivates previous allocation |
| `GET` | `/api/allocations/[id]` | Allocation details | Enriched with student, room, hostel info |
| `PUT` | `/api/allocations/[id]` | Update allocation | Update checkout date and notes |
| `DELETE` | `/api/allocations/[id]` | End allocation (checkout) | Sets `is_active = FALSE`, trigger updates room occupancy |
| `GET` | `/api/complaints` | List complaints (paginated) | Filter by status, category, student, room, hostel, priority, assigned/unassigned |
| `POST` | `/api/complaints` | Raise complaint | Validates student, room, category, priority |
| `GET` | `/api/complaints/[id]` | Complaint detail + history | Includes full audit log from `complaint_logs` |
| `PUT` | `/api/complaints/[id]` | Update complaint | Status transitions, staff assignment, uses transactions |
| `GET` | `/api/payments` | List payments (paginated) | Filter by student, status, semester, overdue |
| `POST` | `/api/payments` | Record payment | Auto-generates receipt number, auto-sets status |
| `GET` | `/api/payments/[id]` | Payment details | Enriched with student info |
| `PUT` | `/api/payments/[id]` | Update payment | Mark as paid, update status/date/receipt |
| `GET` | `/api/payments/student/[id]` | Student-specific payments | Payments for a specific student |

#### 5.3.2 Analytics Endpoints

| Method | Endpoint | Description | Key SQL |
|---|---|---|---|
| `GET` | `/api/analytics/categories` | Complaint stats by category | GROUP BY category, FILTER, percentage calculation |
| `GET` | `/api/analytics/hostels` | Hostel occupancy & complaints | Correlated subqueries, occupancy rate |
| `GET` | `/api/analytics/resolution` | Resolution time metrics | AVG/MIN/MAX on timestamp differences, by category & priority |
| `GET` | `/api/analytics/rooms` | Room occupancy analytics | Breakdown by room type and floor, full/empty/partial counts |
| `GET` | `/api/analytics/trends` | Monthly complaint trends | DATE_TRUNC, resolution rate over time |

### 5.4 API Response Format

All endpoints follow a consistent response structure:

```json
// Success (List)
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}

// Success (Single)
{
  "success": true,
  "data": { ... },
  "message": "Operation successful"
}

// Error
{
  "success": false,
  "error": "Error description"
}
```

---

---

## 6. Application — Flutter Mobile App

### 6.1 Architecture

The Flutter app is the **sole user-facing application** of this project. It follows the **Provider pattern** for state management and a **service-based architecture** for API communication. It communicates with the Next.js web server via REST API calls over HTTPS.

```
hostel_app/lib/
├── config/
│   └── api_config.dart          # Base URL configuration (local/production)
├── main.dart                     # App entry point, Provider setup, MaterialApp
├── models/
│   ├── complaint.dart            # Complaint data model
│   ├── payment.dart              # Payment data model
│   ├── room.dart                 # Room data model
│   └── student.dart              # Student data model
├── providers/
│   └── student_provider.dart     # Student state management (ChangeNotifier)
├── screens/
│   ├── admin/
│   │   ├── admin_allocations_screen.dart   # Room allocation management
│   │   ├── admin_complaints_screen.dart    # Complaint management
│   │   ├── admin_hostels_screen.dart       # Hostel management
│   │   ├── admin_payments_screen.dart      # Payment management
│   │   ├── admin_rooms_screen.dart         # Room management
│   │   └── admin_students_screen.dart      # Student management
│   ├── admin_dashboard_screen.dart         # Admin overview
│   ├── analytics_screen.dart               # Analytics charts
│   ├── complaints_screen.dart              # Student complaints
│   ├── dashboard_screen.dart               # Main student dashboard
│   ├── payments_screen.dart                # Student payments
│   ├── profile_screen.dart                 # Student profile
│   └── room_screen.dart                    # Room details
├── services/
│   └── api_service.dart          # Centralized HTTP API client
├── theme/
│   └── app_theme.dart            # Custom Material theme
└── widgets/
    ├── app_drawer.dart           # Navigation drawer (sidebar)
    ├── info_card.dart            # Reusable info card component
    ├── quick_action_card.dart    # Quick action button card
    └── stat_card.dart            # Statistics display card
```

### 6.2 Screens & Features

The app provides three main portals accessible via a navigation drawer:

#### Student Portal Screens

| Screen | File | Description |
|---|---|---|
| **Dashboard** | `dashboard_screen.dart` | Personalized home with time-based greeting, quick stats, room info, payment summary, quick actions |
| **Profile** | `profile_screen.dart` | View and edit personal details (name, email, phone, department, year) |
| **Room Details** | `room_screen.dart` | Current room assignment info, roommates, hostel details |
| **Complaints** | `complaints_screen.dart` | View complaint history, raise new complaints, track status |
| **Payments** | `payments_screen.dart` | View payment history, pending/overdue amounts |

#### Admin Portal Screens

| Screen | File | Description |
|---|---|---|
| **Admin Dashboard** | `admin_dashboard_screen.dart` | System overview with total counts and quick actions |
| **Manage Students** | `admin/admin_students_screen.dart` | Full CRUD on student records with search and pagination |
| **Manage Rooms** | `admin/admin_rooms_screen.dart` | Room management with hostel/type filters |
| **Manage Hostels** | `admin/admin_hostels_screen.dart` | Hostel creation and management with room statistics |
| **Manage Allocations** | `admin/admin_allocations_screen.dart` | Assign students to rooms, handle checkouts |
| **Manage Complaints** | `admin/admin_complaints_screen.dart` | Complaint status updates, staff assignment |
| **Manage Payments** | `admin/admin_payments_screen.dart` | Payment tracking and status updates |

#### Analytics Screen

| Screen | File | Description |
|---|---|---|
| **Analytics** | `analytics_screen.dart` | Charts and reports for complaint categories, resolution times, trends |

### 6.3 Key Features

- **Centralized API Service** — All HTTP calls go through `ApiService` with `GET`, `POST`, `PUT`, `DELETE` helpers
- **Production URL** — Points to `https://dbmsproj-xi.vercel.app` (Vercel deployment)
- **Navigation Drawer** — Sidebar navigation between Student Portal, Admin Portal, and Analytics
- **Dart Models** — Strongly-typed models for `Student`, `Complaint`, `Payment`, `Room`
- **Provider State Management** — Reactive state updates using `ChangeNotifier`
- **Custom Theme** — Consistent visual design via `AppTheme.lightTheme`
- **Cross-Platform** — Supports Android, iOS, and Web (runs via `flutter run -d chrome`)

### 6.4 UI/UX Features

- **Navigation Drawer** — Sidebar menu for switching between Student, Admin, and Analytics portals
- **Custom Theme** — Consistent Material Design styling via `AppTheme.lightTheme`
- **Google Fonts** — Clean Inter font for modern typography
- **Reusable Widgets** — `StatCard`, `InfoCard`, `QuickActionCard`, `AppDrawer` for DRY UI code
- **Loading States** — Progress indicators during API calls
- **Error Handling** — User-friendly error messages with retry options
- **Status Badges** — Color-coded indicators for complaint/payment statuses
- **Responsive Layout** — Adapts to mobile and web viewports

### 6.5 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `http` | ^1.2.0 | HTTP client for REST API calls |
| `provider` | ^6.1.1 | State management |
| `google_fonts` | ^6.1.0 | Inter font integration |
| `intl` | ^0.19.0 | Date formatting and localization |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

---

## 7. DBMS Concepts Demonstrated

This project comprehensively demonstrates the following database management system concepts:

| Concept | Implementation |
|---|---|
| **Normalized Schema** | Tables decomposed to 3NF; no data redundancy (hostels → rooms → allocations → students) |
| **Primary Keys** | Auto-incrementing `SERIAL` IDs on all entity tables |
| **Foreign Keys** | 10+ FK constraints with `ON DELETE CASCADE` and `ON DELETE SET NULL` |
| **CHECK Constraints** | Data validation at DB level (capacity 1-10, priority 1-5, email regex, floor >= 0) |
| **UNIQUE Constraints** | Unique emails, registration numbers, room numbers per hostel |
| **Custom ENUM Types** | 5 domain-specific types for strong typing |
| **Partial Unique Index** | Ensures only one active allocation per student |
| **Triggers** | 5 triggers for business logic automation (capacity management, audit logging, auto-generation) |
| **SQL Views** | 9 views for complex aggregations and dashboard data |
| **JOINs** | INNER JOIN, LEFT JOIN across 4+ tables in single queries |
| **Aggregate Functions** | COUNT, SUM, AVG, MIN, MAX, MODE with FILTER clauses |
| **GROUP BY** | Category-wise, hostel-wise, room-wise, monthly aggregations |
| **Window Functions** | DATE_TRUNC for time-series analysis |
| **Subqueries** | Correlated subqueries in views and analytics endpoints |
| **Transactions** | BEGIN/COMMIT/ROLLBACK for multi-operation atomicity |
| **Connection Pooling** | Singleton pool with configurable limits for performance |
| **Parameterized Queries** | `$1, $2, ...` placeholders to prevent SQL injection |
| **Soft Deletes** | `is_active` flags instead of hard deletes for data preservation |
| **Pagination** | LIMIT/OFFSET with total count for efficient data retrieval |
| **Indexes** | B-Tree and partial indexes on frequently queried columns |
| **ILIKE** | Case-insensitive pattern matching for search functionality |

---

## 8. Deployment Architecture

```
┌────────────────────────────┐       ┌──────────────────────┐
│         Vercel              │       │     Neon Cloud        │
│  (Next.js API Server)       │──────▶│  (PostgreSQL DB)      │
│                             │  SSL  │                       │
│  URL: dbmsproj-xi.          │       │  Connection pooling   │
│  vercel.app/api/*           │       │  via DATABASE_URL     │
└────────────┬───────────────┘       └───────────────────────┘
             │
             │ HTTPS REST API
             ▼
      ┌────────────────┐
      │  Flutter App   │
      │  (Android /    │
      │   iOS / Web)   │
      └────────────────┘
```

- **API Server** → Deployed on **Vercel** (serverless functions for API routes)
- **Database** → Hosted on **Neon Cloud** (serverless PostgreSQL)
- **Flutter App** → Connects to the Vercel API (`https://dbmsproj-xi.vercel.app/api/*`)
- **Environment Variables** → `DATABASE_URL` stored securely in Vercel project settings

---

## 9. Project Structure

```
dbmsproj/
│
├── database/                        # DATABASE — SQL scripts
│   ├── schema.sql                   # Table definitions, types, constraints, indexes
│   ├── seed.sql                     # Sample data (6 hostels, 41 rooms, 30 students, etc.)
│   ├── triggers.sql                 # 5 trigger functions and trigger definitions
│   └── views.sql                    # 9 database views
│
├── src/                             # WEB SERVER — Next.js API source code
│   ├── app/
│   │   └── api/                     # REST API route handlers (17 route files)
│   │       ├── allocations/         # CRUD + detail endpoints
│   │       ├── analytics/           # 5 analytics endpoints
│   │       │   ├── categories/
│   │       │   ├── hostels/
│   │       │   ├── resolution/
│   │       │   ├── rooms/
│   │       │   └── trends/
│   │       ├── complaints/          # CRUD + detail + history
│   │       ├── hostels/             # CRUD endpoints
│   │       ├── payments/            # CRUD + student-specific
│   │       ├── rooms/               # CRUD + available rooms
│   │       └── students/            # CRUD + detail endpoints
│   ├── lib/
│   │   ├── db.ts                    # Database connection module (pool, query, transaction)
│   │   └── types.ts                 # TypeScript type definitions
│   └── middleware.ts                # CORS middleware for API routes
├── package.json                     # Node.js dependencies
├── next.config.ts                   # Next.js configuration
├── tsconfig.json                    # TypeScript configuration
├── .env.local                       # Environment variables (DATABASE_URL, etc.)
│
└── hostel_app/                      # APPLICATION — Flutter mobile app
    ├── lib/                         # Dart source code
    │   ├── config/                  # API configuration (base URL)
    │   ├── models/                  # Data models (4 files: Student, Room, Complaint, Payment)
    │   ├── providers/               # State management (StudentProvider)
    │   ├── screens/                 # UI screens (12 files, including admin/)
    │   │   ├── admin/               # 6 admin management screens
    │   │   ├── dashboard_screen.dart
    │   │   ├── admin_dashboard_screen.dart
    │   │   ├── analytics_screen.dart
    │   │   ├── complaints_screen.dart
    │   │   ├── payments_screen.dart
    │   │   ├── profile_screen.dart
    │   │   └── room_screen.dart
    │   ├── services/                # API service layer (ApiService)
    │   ├── theme/                   # App theme (AppTheme.lightTheme)
    │   ├── widgets/                 # Reusable widgets (4: AppDrawer, InfoCard, QuickActionCard, StatCard)
    │   └── main.dart                # Entry point, Provider setup, MaterialApp
    └── pubspec.yaml                 # Flutter dependencies
```

---

## 10. How to Run Locally

### Prerequisites
- Node.js 18+
- PostgreSQL (local or Neon cloud)
- Flutter SDK

### Step 1: Database Setup
```sql
-- Execute in PostgreSQL in this order:
-- 1. database/schema.sql    (tables, types, constraints, indexes)
-- 2. database/triggers.sql  (trigger functions and triggers)
-- 3. database/views.sql     (9 database views)
-- 4. database/seed.sql      (sample data)
```

### Step 2: Web Server (API)
```bash
# Install dependencies
npm install

# Set up environment variables in .env.local
# DATABASE_URL=postgresql://user:password@host/database

# Start the API server
npm run dev
# API available at http://localhost:3000/api/*
```

### Step 3: Flutter App
```bash
cd hostel_app

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Android emulator
flutter run -d emulator
```

> **Note:** For local development, update `hostel_app/lib/config/api_config.dart` to point to `http://localhost:3000` (or `http://10.0.2.2:3000` for Android emulator).

---

## 11. Key Workflows

### Student Complaint Lifecycle
```
Student raises complaint → Status: OPEN
        ↓ (Trigger logs creation)
Admin assigns staff → Status: ASSIGNED
        ↓ (Trigger logs status change, sets assigned_at)
Staff begins work → Status: IN_PROGRESS
        ↓ (Trigger logs status change)
Staff completes → Status: RESOLVED
        ↓ (Trigger sets resolved_at)
Admin closes → Status: CLOSED
        ↓ (Trigger sets closed_at)
```

### Room Allocation Flow
```
Admin selects student + room
        ↓
API checks: student active? room available? gender match? capacity?
        ↓
If student has existing allocation → auto-deactivates old one (trigger reduces occupancy)
        ↓
New allocation created → Trigger increments room.current_occupancy
        ↓
On checkout → is_active = FALSE → Trigger decrements room.current_occupancy
```

### Payment Tracking Flow
```
Payment record created with due_date → Status: PENDING
        ↓
If due_date passes without payment → Admin marks as OVERDUE
        ↓
Student makes partial payment → Status: PARTIAL
        ↓
Full payment received → Status: PAID, receipt_number generated
```

---

*Document generated on: February 16, 2026*
*Project: Smart Hostel Management & Analytics System (DBMS Project)*
