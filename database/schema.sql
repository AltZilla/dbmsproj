-- ============================================================================
-- SMART HOSTEL MANAGEMENT SYSTEM - DATABASE SCHEMA
-- ============================================================================
-- This file defines the complete normalized relational schema for the
-- hostel management system. Key DBMS concepts demonstrated:
-- 
-- 1. NORMALIZATION: Tables are in 3NF (Third Normal Form) to reduce redundancy
-- 2. PRIMARY KEYS: Unique identifier for each record (id columns)
-- 3. FOREIGN KEYS: Establish relationships between tables with referential integrity
-- 4. CONSTRAINTS: CHECK constraints ensure data validity
-- 5. ENUM TYPES: Custom types for status fields ensure data consistency
-- ============================================================================

-- Drop existing tables if they exist (for fresh setup)
DROP TABLE IF EXISTS complaint_logs CASCADE;
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS allocations CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS hostels CASCADE;
DROP TABLE IF EXISTS maintenance_staff CASCADE;

-- Drop custom types if they exist
DROP TYPE IF EXISTS complaint_status CASCADE;
DROP TYPE IF EXISTS complaint_category CASCADE;
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS room_type CASCADE;
DROP TYPE IF EXISTS gender_type CASCADE;

-- ============================================================================
-- CUSTOM ENUM TYPES
-- ============================================================================
-- ENUM types ensure only valid values can be inserted, providing data integrity
-- at the database level rather than relying on application-level validation.

CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE room_type AS ENUM ('single', 'double', 'triple', 'dormitory');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'overdue', 'partial');
CREATE TYPE complaint_status AS ENUM ('open', 'assigned', 'in_progress', 'resolved', 'closed');
CREATE TYPE complaint_category AS ENUM (
    'electrical',
    'plumbing', 
    'furniture',
    'cleaning',
    'pest_control',
    'internet',
    'security',
    'other'
);

-- ============================================================================
-- HOSTELS TABLE
-- ============================================================================
-- Represents individual hostel buildings. This is the parent table for rooms.
-- Demonstrates: PRIMARY KEY, NOT NULL constraints, DEFAULT values

CREATE TABLE hostels (
    id SERIAL PRIMARY KEY,                          -- Auto-incrementing primary key
    name VARCHAR(100) NOT NULL UNIQUE,              -- Hostel name must be unique
    address TEXT,                                   -- Full address
    gender_allowed gender_type NOT NULL,            -- Which gender can stay
    total_rooms INTEGER DEFAULT 0,                  -- Denormalized for quick access
    warden_name VARCHAR(100),                       -- Warden in charge
    warden_contact VARCHAR(20),                     -- Contact number
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ROOMS TABLE
-- ============================================================================
-- Represents individual rooms within hostels.
-- Demonstrates: FOREIGN KEY with ON DELETE CASCADE, CHECK constraints

CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    hostel_id INTEGER NOT NULL,
    room_number VARCHAR(20) NOT NULL,               -- e.g., "A-101", "B-205"
    floor INTEGER NOT NULL CHECK (floor >= 0),      -- Floor number (0 = ground)
    room_type room_type NOT NULL DEFAULT 'double',
    capacity INTEGER NOT NULL CHECK (capacity > 0 AND capacity <= 10),
    current_occupancy INTEGER DEFAULT 0 CHECK (current_occupancy >= 0),
    rent_amount DECIMAL(10, 2) NOT NULL CHECK (rent_amount >= 0),
    has_ac BOOLEAN DEFAULT FALSE,
    has_attached_bathroom BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,             -- For maintenance/blocking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key relationship with hostels table
    -- ON DELETE CASCADE: If hostel is deleted, all its rooms are also deleted
    CONSTRAINT fk_room_hostel 
        FOREIGN KEY (hostel_id) 
        REFERENCES hostels(id) 
        ON DELETE CASCADE,
    
    -- Composite unique constraint: room number must be unique within a hostel
    CONSTRAINT unique_room_per_hostel UNIQUE (hostel_id, room_number),
    
    -- Ensure occupancy never exceeds capacity
    CONSTRAINT check_occupancy CHECK (current_occupancy <= capacity)
);

-- Create index for faster hostel-based queries
CREATE INDEX idx_rooms_hostel ON rooms(hostel_id);

-- ============================================================================
-- STUDENTS TABLE
-- ============================================================================
-- Stores student/resident information.
-- Demonstrates: UNIQUE constraints, CHECK constraints for email validation

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    registration_number VARCHAR(50) NOT NULL UNIQUE, -- University registration
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    gender gender_type NOT NULL,
    date_of_birth DATE,
    address TEXT,                                    -- Permanent address
    guardian_name VARCHAR(100),
    guardian_phone VARCHAR(20),
    department VARCHAR(100),                         -- Academic department
    year_of_study INTEGER CHECK (year_of_study >= 1 AND year_of_study <= 6),
    is_active BOOLEAN DEFAULT TRUE,                  -- Active student status
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Basic email format validation using regex
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Create indexes for frequently queried columns
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_reg ON students(registration_number);

-- ============================================================================
-- ALLOCATIONS TABLE
-- ============================================================================
-- Junction table linking students to rooms (Many-to-Many relationship).
-- Demonstrates: Composite foreign keys, date-based constraints

CREATE TABLE allocations (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    room_id INTEGER NOT NULL,
    allocation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_checkout DATE,                          -- When student expected to leave
    actual_checkout DATE,                            -- When student actually left
    is_active BOOLEAN DEFAULT TRUE,                  -- Current allocation status
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key to students table
    CONSTRAINT fk_allocation_student 
        FOREIGN KEY (student_id) 
        REFERENCES students(id) 
        ON DELETE CASCADE,
    
    -- Foreign key to rooms table
    CONSTRAINT fk_allocation_room 
        FOREIGN KEY (room_id) 
        REFERENCES rooms(id) 
        ON DELETE CASCADE,
    
    -- A student can only have one active allocation at a time
    -- This is enforced via a partial unique index (see below)
    
    -- Checkout date must be after allocation date
    CONSTRAINT valid_checkout_dates 
        CHECK (expected_checkout IS NULL OR expected_checkout >= allocation_date)
);

-- Partial unique index: Only one active allocation per student
-- This is a powerful PostgreSQL feature for conditional uniqueness
CREATE UNIQUE INDEX idx_one_active_allocation 
    ON allocations(student_id) 
    WHERE is_active = TRUE;

CREATE INDEX idx_allocations_room ON allocations(room_id);

-- ============================================================================
-- MAINTENANCE STAFF TABLE
-- ============================================================================
-- Stores information about maintenance personnel.

CREATE TABLE maintenance_staff (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) NOT NULL,
    specialization complaint_category,              -- What type of issues they handle
    is_available BOOLEAN DEFAULT TRUE,
    hostel_id INTEGER,                              -- Assigned hostel (optional)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_staff_hostel 
        FOREIGN KEY (hostel_id) 
        REFERENCES hostels(id) 
        ON DELETE SET NULL
);

-- ============================================================================
-- COMPLAINTS TABLE
-- ============================================================================
-- Tracks maintenance complaints raised by students.
-- Demonstrates: Multiple foreign keys, status tracking, timestamps

CREATE TABLE complaints (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    room_id INTEGER NOT NULL,
    category complaint_category NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    status complaint_status DEFAULT 'open',
    priority INTEGER DEFAULT 3 CHECK (priority >= 1 AND priority <= 5), -- 1=highest
    assigned_staff_id INTEGER,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP,
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key relationships
    CONSTRAINT fk_complaint_student 
        FOREIGN KEY (student_id) 
        REFERENCES students(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_complaint_room 
        FOREIGN KEY (room_id) 
        REFERENCES rooms(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_complaint_staff 
        FOREIGN KEY (assigned_staff_id) 
        REFERENCES maintenance_staff(id) 
        ON DELETE SET NULL
);

-- Indexes for common query patterns
CREATE INDEX idx_complaints_student ON complaints(student_id);
CREATE INDEX idx_complaints_room ON complaints(room_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_category ON complaints(category);
CREATE INDEX idx_complaints_created ON complaints(created_at);

-- ============================================================================
-- COMPLAINT LOGS TABLE
-- ============================================================================
-- Audit table to track all status changes for complaints.
-- This table is populated by a trigger (see triggers.sql).
-- Demonstrates: Audit logging pattern, denormalization for historical records

CREATE TABLE complaint_logs (
    id SERIAL PRIMARY KEY,
    complaint_id INTEGER NOT NULL,
    old_status complaint_status,
    new_status complaint_status NOT NULL,
    changed_by VARCHAR(100),                        -- Who made the change
    notes TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_log_complaint 
        FOREIGN KEY (complaint_id) 
        REFERENCES complaints(id) 
        ON DELETE CASCADE
);

CREATE INDEX idx_complaint_logs_complaint ON complaint_logs(complaint_id);

-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================
-- Tracks fee payments for students.
-- Demonstrates: Financial data handling, date-based queries

CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    allocation_id INTEGER,                          -- Link to specific allocation
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    payment_status payment_status DEFAULT 'pending',
    payment_method VARCHAR(50),                     -- cash, card, bank transfer, etc.
    transaction_id VARCHAR(100),                    -- External transaction reference
    receipt_number VARCHAR(50),
    semester VARCHAR(20),                           -- e.g., "Fall 2024"
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_payment_student 
        FOREIGN KEY (student_id) 
        REFERENCES students(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_payment_allocation 
        FOREIGN KEY (allocation_id) 
        REFERENCES allocations(id) 
        ON DELETE SET NULL
);

CREATE INDEX idx_payments_student ON payments(student_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_due_date ON payments(due_date);

-- ============================================================================
-- COMMENTS ON TABLES (Documentation)
-- ============================================================================
-- PostgreSQL allows adding comments to database objects for documentation

COMMENT ON TABLE hostels IS 'Stores hostel building information';
COMMENT ON TABLE rooms IS 'Individual rooms within hostels with capacity constraints';
COMMENT ON TABLE students IS 'Student/resident personal and academic information';
COMMENT ON TABLE allocations IS 'Room allocation records linking students to rooms';
COMMENT ON TABLE maintenance_staff IS 'Maintenance personnel information';
COMMENT ON TABLE complaints IS 'Maintenance complaints raised by students';
COMMENT ON TABLE complaint_logs IS 'Audit log for complaint status changes';
COMMENT ON TABLE payments IS 'Fee payment records for students';

COMMENT ON COLUMN rooms.current_occupancy IS 'Denormalized field updated by trigger';
COMMENT ON COLUMN complaints.priority IS '1=Highest priority, 5=Lowest priority';
