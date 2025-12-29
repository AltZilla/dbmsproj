-- ============================================================================
-- SMART HOSTEL MANAGEMENT SYSTEM - DATABASE TRIGGERS
-- ============================================================================
-- This file contains trigger functions that enforce business rules at the
-- database level. Triggers are automatically executed in response to certain
-- events (INSERT, UPDATE, DELETE) on tables.
--
-- KEY DBMS CONCEPTS DEMONSTRATED:
-- 1. TRIGGERS: Automatic execution of code in response to data changes
-- 2. TRIGGER FUNCTIONS: PL/pgSQL functions that implement trigger logic
-- 3. BEFORE vs AFTER triggers: Control when the trigger fires
-- 4. NEW and OLD pseudo-records: Access to row data before/after changes
-- 5. RAISE EXCEPTION: Abort transaction and rollback changes
-- ============================================================================

-- ============================================================================
-- TRIGGER 1: PREVENT ROOM CAPACITY OVERFLOW
-- ============================================================================
-- This trigger prevents allocating more students to a room than its capacity
-- allows. It fires BEFORE an allocation INSERT to validate the operation.
--
-- Business Rule: current_occupancy must never exceed capacity
-- 
-- How it works:
-- 1. On new allocation INSERT, check if room has space
-- 2. If room is full, RAISE EXCEPTION to abort the INSERT
-- 3. If room has space, increment current_occupancy
-- 4. Also handles deallocation (when is_active changes to FALSE)

CREATE OR REPLACE FUNCTION check_room_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current_occupancy INTEGER;
    v_room_number VARCHAR(20);
    v_hostel_name VARCHAR(100);
BEGIN
    -- Get room capacity and current occupancy
    SELECT r.capacity, r.current_occupancy, r.room_number, h.name
    INTO v_capacity, v_current_occupancy, v_room_number, v_hostel_name
    FROM rooms r
    JOIN hostels h ON r.hostel_id = h.id
    WHERE r.id = NEW.room_id;
    
    -- For new allocations (INSERT with is_active = TRUE)
    IF TG_OP = 'INSERT' AND NEW.is_active = TRUE THEN
        -- Check if room has capacity
        IF v_current_occupancy >= v_capacity THEN
            -- RAISE EXCEPTION aborts the transaction and prevents the INSERT
            RAISE EXCEPTION 'Room % in % is at full capacity (% / %). Cannot allocate more students.',
                v_room_number, v_hostel_name, v_current_occupancy, v_capacity;
        END IF;
        
        -- Increment room occupancy
        UPDATE rooms SET 
            current_occupancy = current_occupancy + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.room_id;
        
    -- For updates (deallocation)
    ELSIF TG_OP = 'UPDATE' THEN
        -- If allocation is being deactivated
        IF OLD.is_active = TRUE AND NEW.is_active = FALSE THEN
            -- Decrement room occupancy
            UPDATE rooms SET 
                current_occupancy = GREATEST(0, current_occupancy - 1),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.room_id;
        -- If allocation is being reactivated
        ELSIF OLD.is_active = FALSE AND NEW.is_active = TRUE THEN
            -- Check capacity again
            IF v_current_occupancy >= v_capacity THEN
                RAISE EXCEPTION 'Room % in % is at full capacity. Cannot reactivate allocation.',
                    v_room_number, v_hostel_name;
            END IF;
            
            UPDATE rooms SET 
                current_occupancy = current_occupancy + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.room_id;
        END IF;
    END IF;
    
    -- Return NEW to allow the operation to proceed
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on allocations table
-- BEFORE INSERT ensures we can prevent the INSERT if room is full
DROP TRIGGER IF EXISTS trg_check_room_capacity ON allocations;
CREATE TRIGGER trg_check_room_capacity
    BEFORE INSERT OR UPDATE ON allocations
    FOR EACH ROW
    EXECUTE FUNCTION check_room_capacity();

-- Also handle allocation deletions
CREATE OR REPLACE FUNCTION handle_allocation_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Only decrement if the allocation was active
    IF OLD.is_active = TRUE THEN
        UPDATE rooms SET 
            current_occupancy = GREATEST(0, current_occupancy - 1),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.room_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_handle_allocation_delete ON allocations;
CREATE TRIGGER trg_handle_allocation_delete
    BEFORE DELETE ON allocations
    FOR EACH ROW
    EXECUTE FUNCTION handle_allocation_delete();

-- ============================================================================
-- TRIGGER 2: LOG COMPLAINT STATUS CHANGES
-- ============================================================================
-- This trigger creates an audit trail by logging every status change
-- in the complaint_logs table. This is essential for:
-- 1. Tracking complaint resolution workflow
-- 2. Calculating resolution times
-- 3. Accountability and transparency
-- 4. Analytics on complaint handling efficiency
--
-- It also automatically sets timestamps when status changes occur.

CREATE OR REPLACE FUNCTION log_complaint_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        -- Insert a log entry
        INSERT INTO complaint_logs (
            complaint_id,
            old_status,
            new_status,
            changed_by,
            notes,
            changed_at
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            COALESCE(current_setting('app.current_user', TRUE), 'system'),
            CASE 
                WHEN NEW.status = 'assigned' THEN 'Assigned to staff ID: ' || COALESCE(NEW.assigned_staff_id::TEXT, 'N/A')
                WHEN NEW.status = 'resolved' THEN 'Resolution: ' || COALESCE(NEW.resolution_notes, 'No notes')
                ELSE NULL
            END,
            CURRENT_TIMESTAMP
        );
        
        -- Set timestamp fields based on new status
        IF NEW.status = 'assigned' AND OLD.status != 'assigned' THEN
            NEW.assigned_at := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
            NEW.resolved_at := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'closed' AND OLD.status != 'closed' THEN
            NEW.closed_at := CURRENT_TIMESTAMP;
        END IF;
    END IF;
    
    -- Update the updated_at timestamp
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_log_complaint_status ON complaints;
CREATE TRIGGER trg_log_complaint_status
    BEFORE UPDATE ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION log_complaint_status_change();

-- Also log initial complaint creation
CREATE OR REPLACE FUNCTION log_complaint_creation()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO complaint_logs (
        complaint_id,
        old_status,
        new_status,
        changed_by,
        notes,
        changed_at
    ) VALUES (
        NEW.id,
        NULL,
        NEW.status,
        COALESCE(current_setting('app.current_user', TRUE), 'system'),
        'Complaint created',
        CURRENT_TIMESTAMP
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_complaint_creation ON complaints;
CREATE TRIGGER trg_log_complaint_creation
    AFTER INSERT ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION log_complaint_creation();

-- ============================================================================
-- TRIGGER 3: UPDATE ROOM COUNT IN HOSTELS (Denormalization)
-- ============================================================================
-- This trigger maintains the total_rooms count in the hostels table.
-- This is an example of controlled denormalization for performance.
-- Instead of counting rooms every time (expensive for large datasets),
-- we maintain a counter that's updated on room INSERT/DELETE.

CREATE OR REPLACE FUNCTION update_hostel_room_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE hostels SET 
            total_rooms = total_rooms + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.hostel_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE hostels SET 
            total_rooms = GREATEST(0, total_rooms - 1),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.hostel_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_room_count ON rooms;
CREATE TRIGGER trg_update_room_count
    AFTER INSERT OR DELETE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_hostel_room_count();

-- ============================================================================
-- TRIGGER 4: AUTO-UPDATE TIMESTAMPS
-- ============================================================================
-- Generic trigger to update the updated_at column automatically.
-- Applied to all tables that have an updated_at column.

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all relevant tables
DROP TRIGGER IF EXISTS trg_update_timestamp_hostels ON hostels;
CREATE TRIGGER trg_update_timestamp_hostels
    BEFORE UPDATE ON hostels
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_timestamp_rooms ON rooms;
CREATE TRIGGER trg_update_timestamp_rooms
    BEFORE UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_timestamp_students ON students;
CREATE TRIGGER trg_update_timestamp_students
    BEFORE UPDATE ON students
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_timestamp_allocations ON allocations;
CREATE TRIGGER trg_update_timestamp_allocations
    BEFORE UPDATE ON allocations
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_timestamp_payments ON payments;
CREATE TRIGGER trg_update_timestamp_payments
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();
