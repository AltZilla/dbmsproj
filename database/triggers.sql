-- TRIGGER 1: PREVENT ROOM CAPACITY OVERFLOW
CREATE OR REPLACE FUNCTION check_room_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current_occupancy INTEGER;
    v_room_number VARCHAR(20);
    v_hostel_name VARCHAR(100);
BEGIN
    SELECT r.capacity, r.current_occupancy, r.room_number, h.name
    INTO v_capacity, v_current_occupancy, v_room_number, v_hostel_name
    FROM rooms r
    JOIN hostels h ON r.hostel_id = h.id
    WHERE r.id = NEW.room_id;
    
    IF TG_OP = 'INSERT' AND NEW.is_active = TRUE THEN
        IF v_current_occupancy >= v_capacity THEN
            RAISE EXCEPTION 'Room % in % is at full capacity (% / %). Cannot allocate more students.',
                v_room_number, v_hostel_name, v_current_occupancy, v_capacity;
        END IF;
        
        UPDATE rooms SET 
            current_occupancy = current_occupancy + 1
        WHERE id = NEW.room_id;
        
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.is_active = TRUE AND NEW.is_active = FALSE THEN
            UPDATE rooms SET 
                current_occupancy = GREATEST(0, current_occupancy - 1)
            WHERE id = NEW.room_id;
        ELSIF OLD.is_active = FALSE AND NEW.is_active = TRUE THEN
            IF v_current_occupancy >= v_capacity THEN
                RAISE EXCEPTION 'Room % in % is at full capacity. Cannot reactivate allocation.',
                    v_room_number, v_hostel_name;
            END IF;
            
            UPDATE rooms SET 
                current_occupancy = current_occupancy + 1
            WHERE id = NEW.room_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_room_capacity ON allocations;
CREATE TRIGGER trg_check_room_capacity
    BEFORE INSERT OR UPDATE ON allocations
    FOR EACH ROW
    EXECUTE FUNCTION check_room_capacity();

CREATE OR REPLACE FUNCTION handle_allocation_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.is_active = TRUE THEN
        UPDATE rooms SET 
            current_occupancy = GREATEST(0, current_occupancy - 1)
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

-- TRIGGER 2: LOG COMPLAINT STATUS CHANGES
CREATE OR REPLACE FUNCTION log_complaint_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
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
        
        IF NEW.status = 'assigned' AND OLD.status != 'assigned' THEN
            NEW.assigned_at := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
            NEW.resolved_at := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'closed' AND OLD.status != 'closed' THEN
            NEW.closed_at := CURRENT_TIMESTAMP;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_complaint_status ON complaints;
CREATE TRIGGER trg_log_complaint_status
    BEFORE UPDATE ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION log_complaint_status_change();

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



-- TRIGGER 3: AUTO-GENERATE ROOM NUMBER
-- TRIGGER 3: AUTO-GENERATE ROOM NUMBER
CREATE OR REPLACE FUNCTION generate_room_number_format()
RETURNS TRIGGER AS $$
DECLARE
    v_hostel_char VARCHAR(1);
BEGIN
    IF NEW.room_sequence IS NOT NULL THEN
        SELECT SUBSTRING(name, 1, 1) INTO v_hostel_char
        FROM hostels
        WHERE id = NEW.hostel_id;
        
        IF v_hostel_char IS NOT NULL THEN
            NEW.room_number = v_hostel_char || '-' || NEW.floor || LPAD(NEW.room_sequence::TEXT, 2, '0');
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_room_number ON rooms;
CREATE TRIGGER trg_generate_room_number
    BEFORE INSERT OR UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION generate_room_number_format();

