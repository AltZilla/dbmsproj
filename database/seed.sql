-- ============================================================================
-- SMART HOSTEL MANAGEMENT SYSTEM - SEED DATA
-- ============================================================================
-- This file contains sample data for testing the application.
-- Run this after schema.sql, triggers.sql, and views.sql
-- ============================================================================

-- ============================================================================
-- HOSTELS
-- ============================================================================
INSERT INTO hostels (name, address, gender_allowed, warden_name, warden_contact) VALUES
('Alpha Hostel', '123 University Road, Block A', 'male', 'Dr. Rajesh Kumar', '+91-9876543210'),
('Beta Hostel', '124 University Road, Block B', 'male', 'Mr. Suresh Sharma', '+91-9876543211'),
('Gamma Hostel', '125 University Road, Block C', 'female', 'Dr. Priya Singh', '+91-9876543212'),
('Delta Hostel', '126 University Road, Block D', 'female', 'Mrs. Anjali Verma', '+91-9876543213');

-- ============================================================================
-- ROOMS
-- ============================================================================
-- Alpha Hostel (id=1) - Male
INSERT INTO rooms (hostel_id, room_number, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(1, 'A-101', 1, 'double', 2, 5000.00, FALSE, FALSE),
(1, 'A-102', 1, 'double', 2, 5000.00, FALSE, FALSE),
(1, 'A-103', 1, 'triple', 3, 4500.00, FALSE, FALSE),
(1, 'A-201', 2, 'single', 1, 8000.00, TRUE, TRUE),
(1, 'A-202', 2, 'double', 2, 6000.00, TRUE, FALSE),
(1, 'A-203', 2, 'double', 2, 6000.00, TRUE, FALSE);

-- Beta Hostel (id=2) - Male
INSERT INTO rooms (hostel_id, room_number, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(2, 'B-101', 1, 'triple', 3, 4000.00, FALSE, FALSE),
(2, 'B-102', 1, 'triple', 3, 4000.00, FALSE, FALSE),
(2, 'B-201', 2, 'double', 2, 5500.00, TRUE, FALSE),
(2, 'B-202', 2, 'double', 2, 5500.00, TRUE, FALSE),
(2, 'B-301', 3, 'single', 1, 7500.00, TRUE, TRUE);

-- Gamma Hostel (id=3) - Female
INSERT INTO rooms (hostel_id, room_number, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(3, 'C-101', 1, 'double', 2, 5500.00, FALSE, TRUE),
(3, 'C-102', 1, 'double', 2, 5500.00, FALSE, TRUE),
(3, 'C-103', 1, 'triple', 3, 4800.00, FALSE, FALSE),
(3, 'C-201', 2, 'single', 1, 8500.00, TRUE, TRUE),
(3, 'C-202', 2, 'double', 2, 6500.00, TRUE, TRUE);

-- Delta Hostel (id=4) - Female
INSERT INTO rooms (hostel_id, room_number, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(4, 'D-101', 1, 'double', 2, 5000.00, FALSE, FALSE),
(4, 'D-102', 1, 'double', 2, 5000.00, FALSE, FALSE),
(4, 'D-201', 2, 'triple', 3, 4500.00, FALSE, FALSE),
(4, 'D-202', 2, 'double', 2, 6000.00, TRUE, FALSE);

-- ============================================================================
-- STUDENTS
-- ============================================================================
INSERT INTO students (registration_number, first_name, last_name, email, phone, gender, date_of_birth, address, guardian_name, guardian_phone, department, year_of_study) VALUES
('REG001', 'Amit', 'Patel', 'amit.patel@university.edu', '+91-9123456701', 'male', '2002-03-15', '45 Gandhi Nagar, Mumbai', 'Ramesh Patel', '+91-9123456901', 'Computer Science', 2),
('REG002', 'Rahul', 'Sharma', 'rahul.sharma@university.edu', '+91-9123456702', 'male', '2001-07-22', '12 Nehru Street, Delhi', 'Sunil Sharma', '+91-9123456902', 'Electronics', 3),
('REG003', 'Vikram', 'Singh', 'vikram.singh@university.edu', '+91-9123456703', 'male', '2003-01-10', '78 Lake View, Jaipur', 'Dinesh Singh', '+91-9123456903', 'Mechanical', 1),
('REG004', 'Priya', 'Gupta', 'priya.gupta@university.edu', '+91-9123456704', 'female', '2002-05-18', '34 MG Road, Bangalore', 'Anil Gupta', '+91-9123456904', 'Computer Science', 2),
('REG005', 'Sneha', 'Reddy', 'sneha.reddy@university.edu', '+91-9123456705', 'female', '2001-11-25', '56 Jubilee Hills, Hyderabad', 'Krishna Reddy', '+91-9123456905', 'Civil', 3),
('REG006', 'Ananya', 'Iyer', 'ananya.iyer@university.edu', '+91-9123456706', 'female', '2003-02-28', '89 Anna Nagar, Chennai', 'Venkat Iyer', '+91-9123456906', 'Electronics', 1),
('REG007', 'Arjun', 'Kumar', 'arjun.kumar@university.edu', '+91-9123456707', 'male', '2002-08-14', '23 Park Street, Kolkata', 'Manoj Kumar', '+91-9123456907', 'Computer Science', 2),
('REG008', 'Rohit', 'Verma', 'rohit.verma@university.edu', '+91-9123456708', 'male', '2001-04-05', '67 Civil Lines, Lucknow', 'Ashok Verma', '+91-9123456908', 'Mechanical', 3),
('REG009', 'Kavya', 'Nair', 'kavya.nair@university.edu', '+91-9123456709', 'female', '2002-09-30', '45 Marine Drive, Kochi', 'Gopal Nair', '+91-9123456909', 'Computer Science', 2),
('REG010', 'Pooja', 'Joshi', 'pooja.joshi@university.edu', '+91-9123456710', 'female', '2003-06-12', '12 Aundh Road, Pune', 'Harish Joshi', '+91-9123456910', 'Civil', 1);

-- ============================================================================
-- ALLOCATIONS
-- ============================================================================
-- Note: The trigger will automatically update room occupancy
INSERT INTO allocations (student_id, room_id, allocation_date, expected_checkout) VALUES
(1, 1, '2024-07-01', '2025-05-31'),  -- Amit -> A-101
(2, 1, '2024-07-01', '2025-05-31'),  -- Rahul -> A-101 (roommate)
(3, 2, '2024-07-01', '2025-05-31'),  -- Vikram -> A-102
(4, 12, '2024-07-01', '2025-05-31'), -- Priya -> C-101
(5, 12, '2024-07-01', '2025-05-31'), -- Sneha -> C-101 (roommate)
(6, 13, '2024-07-01', '2025-05-31'), -- Ananya -> C-102
(7, 3, '2024-07-01', '2025-05-31'),  -- Arjun -> A-103
(8, 3, '2024-07-01', '2025-05-31'),  -- Rohit -> A-103 (roommate)
(9, 15, '2024-07-01', '2025-05-31'), -- Kavya -> C-201
(10, 17, '2024-07-01', '2025-05-31'); -- Pooja -> D-101

-- ============================================================================
-- MAINTENANCE STAFF
-- ============================================================================
INSERT INTO maintenance_staff (name, email, phone, specialization, is_available, hostel_id) VALUES
('Mohan Electrician', 'mohan@university.edu', '+91-9234567801', 'electrical', TRUE, 1),
('Suresh Plumber', 'suresh@university.edu', '+91-9234567802', 'plumbing', TRUE, 1),
('Ramesh Carpenter', 'ramesh@university.edu', '+91-9234567803', 'furniture', TRUE, 2),
('Ganesh Cleaner', 'ganesh@university.edu', '+91-9234567804', 'cleaning', TRUE, 3),
('Vijay Technician', 'vijay@university.edu', '+91-9234567805', 'internet', TRUE, NULL),
('Prakash Pest Control', 'prakash@university.edu', '+91-9234567806', 'pest_control', TRUE, NULL);

-- ============================================================================
-- COMPLAINTS (with various statuses for analytics)
-- ============================================================================
-- Open complaints
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, created_at) VALUES
(1, 1, 'electrical', 'Tube light not working', 'The tube light in the study area is flickering and needs replacement.', 'open', 2, NOW() - INTERVAL '2 days'),
(4, 12, 'plumbing', 'Leaking tap in bathroom', 'The bathroom tap is constantly dripping and wasting water.', 'open', 3, NOW() - INTERVAL '1 day'),
(7, 3, 'internet', 'Slow WiFi connection', 'Internet speed is very slow in our room, affecting studies.', 'open', 2, NOW() - INTERVAL '3 hours');

-- Assigned complaints
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, assigned_staff_id, assigned_at, created_at) VALUES
(2, 1, 'furniture', 'Broken chair', 'One of the study chairs has a broken leg.', 'assigned', 4, 3, NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 days'),
(5, 12, 'cleaning', 'Common area needs cleaning', 'The common room has not been cleaned in days.', 'assigned', 3, 4, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '1 day');

-- In-progress complaints
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, assigned_staff_id, assigned_at, created_at) VALUES
(3, 2, 'electrical', 'Fan making noise', 'Ceiling fan is making a grinding noise when running.', 'in_progress', 3, 1, NOW() - INTERVAL '2 days', NOW() - INTERVAL '4 days'),
(6, 13, 'plumbing', 'Low water pressure', 'Water pressure in the shower is very low.', 'in_progress', 2, 2, NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 days');

-- Resolved complaints (for analytics)
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, assigned_staff_id, resolution_notes, assigned_at, resolved_at, created_at) VALUES
(8, 3, 'electrical', 'Power outlet not working', 'One power outlet near the window stopped working.', 'resolved', 2, 1, 'Replaced faulty wiring and outlet.', NOW() - INTERVAL '10 days', NOW() - INTERVAL '8 days', NOW() - INTERVAL '12 days'),
(9, 15, 'pest_control', 'Cockroach problem', 'Seeing cockroaches in the room frequently.', 'resolved', 1, 6, 'Applied pest control treatment. Follow-up in 2 weeks.', NOW() - INTERVAL '20 days', NOW() - INTERVAL '18 days', NOW() - INTERVAL '21 days'),
(1, 1, 'furniture', 'Wobbly table', 'Study table is not stable.', 'resolved', 4, 3, 'Fixed table legs and tightened screws.', NOW() - INTERVAL '25 days', NOW() - INTERVAL '24 days', NOW() - INTERVAL '27 days'),
(4, 12, 'internet', 'No internet connection', 'Room has no internet access.', 'resolved', 1, 5, 'Reset network switch and reconfigured router.', NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days', NOW() - INTERVAL '16 days'),
(10, 17, 'cleaning', 'Room not cleaned properly', 'Cleaning staff missed our room.', 'resolved', 5, 4, 'Scheduled additional cleaning.', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '6 days');

-- Closed complaints
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, assigned_staff_id, resolution_notes, assigned_at, resolved_at, closed_at, created_at) VALUES
(2, 1, 'security', 'Lock needs replacement', 'Room door lock is difficult to open.', 'closed', 2, 3, 'Replaced entire lock mechanism.', NOW() - INTERVAL '35 days', NOW() - INTERVAL '33 days', NOW() - INTERVAL '30 days', NOW() - INTERVAL '37 days'),
(5, 12, 'electrical', 'Switch spark issue', 'Main switch sparks when turned on.', 'closed', 1, 1, 'Replaced switch and checked wiring. Safe now.', NOW() - INTERVAL '40 days', NOW() - INTERVAL '38 days', NOW() - INTERVAL '35 days', NOW() - INTERVAL '42 days');

-- ============================================================================
-- PAYMENTS
-- ============================================================================
-- Paid payments
INSERT INTO payments (student_id, allocation_id, amount, payment_date, due_date, payment_status, payment_method, transaction_id, receipt_number, semester) VALUES
(1, 1, 5000.00, '2024-07-15', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234567', 'RCP-2024-001', 'Fall 2024'),
(2, 2, 5000.00, '2024-07-20', '2024-07-31', 'paid', 'upi', 'TXN001234568', 'RCP-2024-002', 'Fall 2024'),
(3, 3, 5000.00, '2024-07-25', '2024-07-31', 'paid', 'card', 'TXN001234569', 'RCP-2024-003', 'Fall 2024'),
(4, 4, 5500.00, '2024-07-18', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234570', 'RCP-2024-004', 'Fall 2024'),
(5, 5, 5500.00, '2024-07-22', '2024-07-31', 'paid', 'upi', 'TXN001234571', 'RCP-2024-005', 'Fall 2024'),
(6, 6, 5500.00, '2024-07-28', '2024-07-31', 'paid', 'cash', NULL, 'RCP-2024-006', 'Fall 2024'),
(7, 7, 4500.00, '2024-07-16', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234572', 'RCP-2024-007', 'Fall 2024'),
(8, 8, 4500.00, '2024-07-19', '2024-07-31', 'paid', 'upi', 'TXN001234573', 'RCP-2024-008', 'Fall 2024'),
(9, 9, 8500.00, '2024-07-21', '2024-07-31', 'paid', 'card', 'TXN001234574', 'RCP-2024-009', 'Fall 2024'),
(10, 10, 5000.00, '2024-07-24', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234575', 'RCP-2024-010', 'Fall 2024');

-- Pending payments (current semester)
INSERT INTO payments (student_id, allocation_id, amount, due_date, payment_status, semester) VALUES
(1, 1, 5000.00, '2025-01-15', 'pending', 'Spring 2025'),
(2, 2, 5000.00, '2025-01-15', 'pending', 'Spring 2025'),
(3, 3, 5000.00, '2025-01-15', 'pending', 'Spring 2025'),
(4, 4, 5500.00, '2025-01-15', 'pending', 'Spring 2025'),
(5, 5, 5500.00, '2025-01-15', 'pending', 'Spring 2025');

-- Overdue payments
INSERT INTO payments (student_id, allocation_id, amount, due_date, payment_status, semester) VALUES
(6, 6, 5500.00, '2024-12-15', 'overdue', 'Spring 2025'),
(7, 7, 4500.00, '2024-12-20', 'overdue', 'Spring 2025');

-- Partial payment
INSERT INTO payments (student_id, allocation_id, amount, payment_date, due_date, payment_status, payment_method, notes, semester) VALUES
(8, 8, 2000.00, '2024-12-28', '2024-12-31', 'partial', 'upi', 'Partial payment received. Balance: Rs 2500', 'Spring 2025');

-- ============================================================================
-- VERIFY DATA
-- ============================================================================
-- Uncomment to verify the seed data was inserted correctly

-- SELECT 'Hostels' as entity, COUNT(*) as count FROM hostels
-- UNION ALL SELECT 'Rooms', COUNT(*) FROM rooms
-- UNION ALL SELECT 'Students', COUNT(*) FROM students
-- UNION ALL SELECT 'Allocations', COUNT(*) FROM allocations
-- UNION ALL SELECT 'Maintenance Staff', COUNT(*) FROM maintenance_staff
-- UNION ALL SELECT 'Complaints', COUNT(*) FROM complaints
-- UNION ALL SELECT 'Payments', COUNT(*) FROM payments;
