-- Drop existing tables if they exist
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

-- CUSTOM ENUM TYPES
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

-- HOSTELS TABLE
CREATE TABLE hostels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    address TEXT,
    gender_allowed gender_type NOT NULL,
    warden_name VARCHAR(100),
    warden_contact VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ROOMS TABLE
CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    hostel_id INTEGER NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    floor INTEGER NOT NULL CHECK (floor >= 0),
    room_sequence INTEGER,
    room_type room_type NOT NULL DEFAULT 'double',
    capacity INTEGER NOT NULL CHECK (capacity > 0 AND capacity <= 10),
    current_occupancy INTEGER NOT NULL DEFAULT 0,
    rent_amount DECIMAL(10, 2) NOT NULL CHECK (rent_amount >= 0),
    has_ac BOOLEAN DEFAULT FALSE,
    has_attached_bathroom BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_room_hostel 
        FOREIGN KEY (hostel_id) 
        REFERENCES hostels(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT unique_room_per_hostel UNIQUE (hostel_id, room_number)
);

CREATE INDEX idx_rooms_hostel ON rooms(hostel_id);

-- STUDENTS TABLE
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    registration_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    gender gender_type NOT NULL,
    date_of_birth DATE,
    address TEXT,
    guardian_name VARCHAR(100),
    guardian_phone VARCHAR(20),
    department VARCHAR(100),
    year_of_study INTEGER CHECK (year_of_study >= 1 AND year_of_study <= 6),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_reg ON students(registration_number);

-- ALLOCATIONS TABLE
CREATE TABLE allocations (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    room_id INTEGER NOT NULL,
    allocation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_checkout DATE,
    actual_checkout DATE,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    
    CONSTRAINT fk_allocation_student 
        FOREIGN KEY (student_id) 
        REFERENCES students(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_allocation_room 
        FOREIGN KEY (room_id) 
        REFERENCES rooms(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT valid_checkout_dates 
        CHECK (expected_checkout IS NULL OR expected_checkout >= allocation_date)
);

CREATE UNIQUE INDEX idx_one_active_allocation 
    ON allocations(student_id) 
    WHERE is_active = TRUE;

CREATE INDEX idx_allocations_room ON allocations(room_id);

-- MAINTENANCE STAFF TABLE
CREATE TABLE maintenance_staff (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) NOT NULL,
    specialization complaint_category,
    is_available BOOLEAN DEFAULT TRUE,
    hostel_id INTEGER,
    
    CONSTRAINT fk_staff_hostel 
        FOREIGN KEY (hostel_id) 
        REFERENCES hostels(id) 
        ON DELETE SET NULL
);

-- COMPLAINTS TABLE
CREATE TABLE complaints (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    room_id INTEGER NOT NULL,
    category complaint_category NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    status complaint_status DEFAULT 'open',
    priority INTEGER DEFAULT 3 CHECK (priority >= 1 AND priority <= 5),
    assigned_staff_id INTEGER,
    resolution_notes TEXT,
    assigned_at TIMESTAMP,
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
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

CREATE INDEX idx_complaints_student ON complaints(student_id);
CREATE INDEX idx_complaints_room ON complaints(room_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_category ON complaints(category);
CREATE INDEX idx_complaints_created ON complaints(created_at);

-- COMPLAINT LOGS TABLE
CREATE TABLE complaint_logs (
    complaint_id INTEGER NOT NULL,
    old_status complaint_status,
    new_status complaint_status NOT NULL,
    changed_by VARCHAR(100),
    notes TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_log_complaint 
        FOREIGN KEY (complaint_id) 
        REFERENCES complaints(id) 
        ON DELETE CASCADE
);

CREATE INDEX idx_complaint_logs_complaint ON complaint_logs(complaint_id);

-- PAYMENTS TABLE
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    allocation_id INTEGER,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    payment_status payment_status DEFAULT 'pending',
    payment_method VARCHAR(50),
    receipt_number VARCHAR(50),
    transaction_id VARCHAR(50),
    semester VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
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
