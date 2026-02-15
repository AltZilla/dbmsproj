-- CLEAR EXISTING DATA
TRUNCATE TABLE hostels, rooms, students, allocations, maintenance_staff, complaints, complaint_logs, payments RESTART IDENTITY CASCADE;

-- HOSTELS (6 hostels)
INSERT INTO hostels (name, address, gender_allowed, warden_name, warden_contact) VALUES
('Alpha Hostel', '123 University Road, Block A', 'male', 'Dr. Rajesh Kumar', '+91-9876543210'),
('Beta Hostel', '124 University Road, Block B', 'male', 'Mr. Suresh Sharma', '+91-9876543211'),
('Gamma Hostel', '125 University Road, Block C', 'female', 'Dr. Priya Singh', '+91-9876543212'),
('Delta Hostel', '126 University Road, Block D', 'female', 'Mrs. Anjali Verma', '+91-9876543213'),
('Epsilon Hostel', '127 University Road, Block E', 'male', 'Dr. Arun Mehta', '+91-9876543214'),
('Zeta Hostel', '128 University Road, Block F', 'female', 'Ms. Deepa Rao', '+91-9876543215');

-- ROOMS (40+ rooms across 6 hostels)

-- Alpha Hostel (id=1) - Male — rooms 1-8
INSERT INTO rooms (hostel_id, room_number, room_sequence, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(1, 'A-101', 1, 1, 'double', 2, 5000.00, FALSE, FALSE),
(1, 'A-102', 2, 1, 'double', 2, 5000.00, FALSE, FALSE),
(1, 'A-103', 3, 1, 'triple', 3, 4500.00, FALSE, FALSE),
(1, 'A-201', 1, 2, 'single', 1, 8000.00, TRUE, TRUE),
(1, 'A-202', 2, 2, 'double', 2, 6000.00, TRUE, FALSE),
(1, 'A-203', 3, 2, 'double', 2, 6000.00, TRUE, FALSE),
(1, 'A-301', 1, 3, 'single', 1, 8500.00, TRUE, TRUE),
(1, 'A-302', 2, 3, 'double', 2, 6500.00, TRUE, TRUE);

-- Beta Hostel (id=2) - Male — rooms 9-15
INSERT INTO rooms (hostel_id, room_number, room_sequence, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(2, 'B-101', 1, 1, 'triple', 3, 4000.00, FALSE, FALSE),
(2, 'B-102', 2, 1, 'triple', 3, 4000.00, FALSE, FALSE),
(2, 'B-103', 3, 1, 'double', 2, 4500.00, FALSE, FALSE),
(2, 'B-201', 1, 2, 'double', 2, 5500.00, TRUE, FALSE),
(2, 'B-202', 2, 2, 'double', 2, 5500.00, TRUE, FALSE),
(2, 'B-301', 1, 3, 'single', 1, 7500.00, TRUE, TRUE),
(2, 'B-302', 2, 3, 'single', 1, 7500.00, TRUE, TRUE);

-- Gamma Hostel (id=3) - Female — rooms 16-22
INSERT INTO rooms (hostel_id, room_number, room_sequence, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(3, 'C-101', 1, 1, 'double', 2, 5500.00, FALSE, TRUE),
(3, 'C-102', 2, 1, 'double', 2, 5500.00, FALSE, TRUE),
(3, 'C-103', 3, 1, 'triple', 3, 4800.00, FALSE, FALSE),
(3, 'C-201', 1, 2, 'single', 1, 8500.00, TRUE, TRUE),
(3, 'C-202', 2, 2, 'double', 2, 6500.00, TRUE, TRUE),
(3, 'C-301', 1, 3, 'double', 2, 6800.00, TRUE, TRUE),
(3, 'C-302', 2, 3, 'single', 1, 9000.00, TRUE, TRUE);

-- Delta Hostel (id=4) - Female — rooms 23-28
INSERT INTO rooms (hostel_id, room_number, room_sequence, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(4, 'D-101', 1, 1, 'double', 2, 5000.00, FALSE, FALSE),
(4, 'D-102', 2, 1, 'double', 2, 5000.00, FALSE, FALSE),
(4, 'D-201', 1, 2, 'triple', 3, 4500.00, FALSE, FALSE),
(4, 'D-202', 2, 2, 'double', 2, 6000.00, TRUE, FALSE),
(4, 'D-301', 1, 3, 'double', 2, 6200.00, TRUE, TRUE),
(4, 'D-302', 2, 3, 'single', 1, 7800.00, TRUE, TRUE);

-- Epsilon Hostel (id=5) - Male — rooms 29-35
INSERT INTO rooms (hostel_id, room_number, room_sequence, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(5, 'E-101', 1, 1, 'triple', 3, 3800.00, FALSE, FALSE),
(5, 'E-102', 2, 1, 'triple', 3, 3800.00, FALSE, FALSE),
(5, 'E-103', 3, 1, 'double', 2, 4200.00, FALSE, FALSE),
(5, 'E-201', 1, 2, 'double', 2, 5200.00, TRUE, FALSE),
(5, 'E-202', 2, 2, 'double', 2, 5200.00, TRUE, FALSE),
(5, 'E-301', 1, 3, 'single', 1, 7000.00, TRUE, TRUE),
(5, 'E-302', 2, 3, 'single', 1, 7000.00, TRUE, TRUE);

-- Zeta Hostel (id=6) - Female — rooms 36-41
INSERT INTO rooms (hostel_id, room_number, room_sequence, floor, room_type, capacity, rent_amount, has_ac, has_attached_bathroom) VALUES
(6, 'F-101', 1, 1, 'double', 2, 5300.00, FALSE, TRUE),
(6, 'F-102', 2, 1, 'double', 2, 5300.00, FALSE, TRUE),
(6, 'F-103', 3, 1, 'triple', 3, 4600.00, FALSE, FALSE),
(6, 'F-201', 1, 2, 'double', 2, 6200.00, TRUE, TRUE),
(6, 'F-202', 2, 2, 'single', 1, 8200.00, TRUE, TRUE),
(6, 'F-301', 1, 3, 'double', 2, 6800.00, TRUE, TRUE);

-- STUDENTS (30 students)
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
('REG010', 'Pooja', 'Joshi', 'pooja.joshi@university.edu', '+91-9123456710', 'female', '2003-06-12', '12 Aundh Road, Pune', 'Harish Joshi', '+91-9123456910', 'Civil', 1),
('REG011', 'Siddharth', 'Malhotra', 'siddharth.malhotra@university.edu', '+91-9123456711', 'male', '2002-11-08', '90 Sector 14, Gurgaon', 'Vijay Malhotra', '+91-9123456911', 'Computer Science', 2),
('REG012', 'Kartik', 'Agarwal', 'kartik.agarwal@university.edu', '+91-9123456712', 'male', '2003-05-20', '15 Station Road, Agra', 'Sanjay Agarwal', '+91-9123456912', 'Electronics', 1),
('REG013', 'Deepak', 'Chauhan', 'deepak.chauhan@university.edu', '+91-9123456713', 'male', '2001-09-17', '88 Mall Road, Shimla', 'Rakesh Chauhan', '+91-9123456913', 'Civil', 3),
('REG014', 'Nikhil', 'Saxena', 'nikhil.saxena@university.edu', '+91-9123456714', 'male', '2002-02-25', '33 Hazratganj, Lucknow', 'Pankaj Saxena', '+91-9123456914', 'Mechanical', 2),
('REG015', 'Ravi', 'Tiwari', 'ravi.tiwari@university.edu', '+91-9123456715', 'male', '2003-07-30', '71 Kanpur Road, Allahabad', 'Suresh Tiwari', '+91-9123456915', 'Computer Science', 1),
('REG016', 'Meera', 'Deshmukh', 'meera.deshmukh@university.edu', '+91-9123456716', 'female', '2002-04-14', '22 FC Road, Pune', 'Pravin Deshmukh', '+91-9123456916', 'Electronics', 2),
('REG017', 'Ishita', 'Kapoor', 'ishita.kapoor@university.edu', '+91-9123456717', 'female', '2001-12-03', '55 Connaught Place, Delhi', 'Rakesh Kapoor', '+91-9123456917', 'Computer Science', 3),
('REG018', 'Divya', 'Menon', 'divya.menon@university.edu', '+91-9123456718', 'female', '2003-08-19', '66 MG Road, Ernakulam', 'Suresh Menon', '+91-9123456918', 'Civil', 1),
('REG019', 'Tanvi', 'Bhat', 'tanvi.bhat@university.edu', '+91-9123456719', 'female', '2002-06-22', '44 Brigade Road, Bangalore', 'Mohan Bhat', '+91-9123456919', 'Mechanical', 2),
('REG020', 'Shreya', 'Pillai', 'shreya.pillai@university.edu', '+91-9123456720', 'female', '2001-10-11', '77 Beach Road, Vizag', 'Ganesh Pillai', '+91-9123456920', 'Computer Science', 3),
('REG021', 'Harsh', 'Pandey', 'harsh.pandey@university.edu', '+91-9123456721', 'male', '2002-01-28', '19 Civil Lines, Varanasi', 'Shyam Pandey', '+91-9123456921', 'Electronics', 2),
('REG022', 'Aditya', 'Bhatt', 'aditya.bhatt@university.edu', '+91-9123456722', 'male', '2003-03-05', '38 Lal Darwaja, Ahmedabad', 'Kiran Bhatt', '+91-9123456922', 'Civil', 1),
('REG023', 'Manish', 'Yadav', 'manish.yadav@university.edu', '+91-9123456723', 'male', '2001-08-16', '52 Boring Road, Patna', 'Rajendra Yadav', '+91-9123456923', 'Mechanical', 3),
('REG024', 'Nisha', 'Srinivasan', 'nisha.srinivasan@university.edu', '+91-9123456724', 'female', '2002-12-09', '63 T Nagar, Chennai', 'Ramesh Srinivasan', '+91-9123456924', 'Computer Science', 2),
('REG025', 'Ritu', 'Ahluwalia', 'ritu.ahluwalia@university.edu', '+91-9123456725', 'female', '2003-04-17', '81 Model Town, Jalandhar', 'Sanjay Ahluwalia', '+91-9123456925', 'Electronics', 1),
('REG026', 'Swati', 'Kulkarni', 'swati.kulkarni@university.edu', '+91-9123456726', 'female', '2001-06-30', '27 Baner Road, Pune', 'Ashish Kulkarni', '+91-9123456926', 'Civil', 3),
('REG027', 'Varun', 'Chandra', 'varun.chandra@university.edu', '+91-9123456727', 'male', '2002-09-12', '46 MG Marg, Gangtok', 'Sudhir Chandra', '+91-9123456927', 'Computer Science', 2),
('REG028', 'Karan', 'Khanna', 'karan.khanna@university.edu', '+91-9123456728', 'male', '2003-11-21', '14 Mall Road, Chandigarh', 'Vivek Khanna', '+91-9123456928', 'Mechanical', 1),
('REG029', 'Pallavi', 'Mishra', 'pallavi.mishra@university.edu', '+91-9123456729', 'female', '2002-07-04', '92 Gomti Nagar, Lucknow', 'Prakash Mishra', '+91-9123456929', 'Electronics', 2),
('REG030', 'Anjali', 'Dubey', 'anjali.dubey@university.edu', '+91-9123456730', 'female', '2001-02-14', '35 Ashok Nagar, Bhopal', 'Dinesh Dubey', '+91-9123456930', 'Computer Science', 3);

-- ALLOCATIONS (30 students allocated)
-- Male students → male hostels (Alpha=1, Beta=2, Epsilon=5)
-- Female students → female hostels (Gamma=3, Delta=4, Zeta=6)
INSERT INTO allocations (student_id, room_id, allocation_date, expected_checkout) VALUES
-- Alpha Hostel rooms (1-8)
(1, 1, '2024-07-01', '2025-05-31'),
(2, 1, '2024-07-01', '2025-05-31'),
(3, 2, '2024-07-01', '2025-05-31'),
(7, 3, '2024-07-01', '2025-05-31'),
(8, 3, '2024-07-01', '2025-05-31'),
(11, 4, '2024-07-01', '2025-05-31'),
(12, 5, '2024-07-01', '2025-05-31'),
(13, 5, '2024-07-01', '2025-05-31'),
-- Beta Hostel rooms (9-15)
(14, 9, '2024-07-01', '2025-05-31'),
(15, 9, '2024-07-01', '2025-05-31'),
(21, 10, '2024-07-01', '2025-05-31'),
(22, 11, '2024-07-01', '2025-05-31'),
(23, 12, '2024-07-01', '2025-05-31'),
-- Epsilon Hostel rooms (29-35)
(27, 29, '2024-07-01', '2025-05-31'),
(28, 31, '2024-07-01', '2025-05-31'),
-- Gamma Hostel rooms (16-22)
(4, 16, '2024-07-01', '2025-05-31'),
(5, 16, '2024-07-01', '2025-05-31'),
(6, 18, '2024-07-01', '2025-05-31'),
(9, 19, '2024-07-01', '2025-05-31'),
(16, 20, '2024-07-01', '2025-05-31'),
(17, 21, '2024-07-01', '2025-05-31'),
-- Delta Hostel rooms (23-28)
(10, 23, '2024-07-01', '2025-05-31'),
(18, 23, '2024-07-01', '2025-05-31'),
(19, 25, '2024-07-01', '2025-05-31'),
(24, 26, '2024-07-01', '2025-05-31'),
-- Zeta Hostel rooms (36-41)
(20, 36, '2024-07-01', '2025-05-31'),
(25, 36, '2024-07-01', '2025-05-31'),
(26, 38, '2024-07-01', '2025-05-31'),
(29, 39, '2024-07-01', '2025-05-31'),
(30, 41, '2024-07-01', '2025-05-31');

-- MAINTENANCE STAFF (10 staff)
INSERT INTO maintenance_staff (name, email, phone, specialization, is_available, hostel_id) VALUES
('Mohan Electrician', 'mohan@university.edu', '+91-9234567801', 'electrical', TRUE, 1),
('Suresh Plumber', 'suresh@university.edu', '+91-9234567802', 'plumbing', TRUE, 1),
('Ramesh Carpenter', 'ramesh@university.edu', '+91-9234567803', 'furniture', TRUE, 2),
('Ganesh Cleaner', 'ganesh@university.edu', '+91-9234567804', 'cleaning', TRUE, 3),
('Vijay Technician', 'vijay@university.edu', '+91-9234567805', 'internet', TRUE, NULL),
('Prakash Pest Control', 'prakash@university.edu', '+91-9234567806', 'pest_control', TRUE, NULL),
('Raju Electrician', 'raju@university.edu', '+91-9234567807', 'electrical', TRUE, 5),
('Dinesh Plumber', 'dinesh.p@university.edu', '+91-9234567808', 'plumbing', TRUE, 4),
('Bala Security', 'bala@university.edu', '+91-9234567809', 'security', TRUE, 6),
('Gopal Carpenter', 'gopal.c@university.edu', '+91-9234567810', 'furniture', FALSE, 3);

-- COMPLAINTS (30 complaints across all statuses)

-- Open complaints (8)
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, created_at) VALUES
(1, 1, 'electrical', 'Tube light not working', 'The tube light in the study area is flickering and needs replacement.', 'open', 2, NOW() - INTERVAL '2 days'),
(4, 16, 'plumbing', 'Leaking tap in bathroom', 'The bathroom tap is constantly dripping and wasting water.', 'open', 3, NOW() - INTERVAL '1 day'),
(7, 3, 'internet', 'Slow WiFi connection', 'Internet speed is very slow in our room, affecting studies.', 'open', 2, NOW() - INTERVAL '3 hours'),
(12, 5, 'furniture', 'Cupboard door broken', 'The cupboard door hinge snapped off, cannot close it properly.', 'open', 3, NOW() - INTERVAL '5 hours'),
(14, 9, 'electrical', 'Power fluctuation', 'Frequent voltage fluctuations causing devices to restart.', 'open', 4, NOW() - INTERVAL '4 hours'),
(20, 36, 'cleaning', 'Dusty common area', 'The common study room is extremely dusty and not cleaned regularly.', 'open', 2, NOW() - INTERVAL '12 hours'),
(27, 29, 'security', 'Broken window lock', 'Ground floor window lock is broken, security concern at night.', 'open', 5, NOW() - INTERVAL '6 hours'),
(29, 39, 'pest_control', 'Ants in kitchen area', 'Large colony of ants near the shared kitchen counter.', 'open', 2, NOW() - INTERVAL '1 day');

-- In-progress complaints (6)
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, assigned_staff_id, assigned_at, created_at) VALUES
(3, 2, 'electrical', 'Fan making noise', 'Ceiling fan is making a grinding noise when running.', 'in_progress', 3, 1, NOW() - INTERVAL '2 days', NOW() - INTERVAL '4 days'),
(6, 18, 'plumbing', 'Low water pressure', 'Water pressure in the shower is very low.', 'in_progress', 2, 2, NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 days'),
(11, 4, 'internet', 'No WiFi signal', 'WiFi signal does not reach our room at all.', 'in_progress', 4, 5, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '2 days'),
(16, 20, 'furniture', 'Bed frame cracked', 'Wooden bed frame has a large crack, unsafe to sleep.', 'in_progress', 5, 3, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '1 day'),
(22, 11, 'cleaning', 'Bathroom mold', 'Black mold growing on the bathroom ceiling, health hazard.', 'in_progress', 4, 4, NOW() - INTERVAL '3 days', NOW() - INTERVAL '5 days'),
(28, 31, 'electrical', 'Socket sparking', 'Wall socket sparks when plugging in charger.', 'in_progress', 5, 7, NOW() - INTERVAL '4 hours', NOW() - INTERVAL '1 day');

-- Resolved complaints (10)
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, assigned_staff_id, assigned_at, resolved_at, created_at) VALUES
(8, 3, 'electrical', 'Power outlet not working', 'One power outlet near the window stopped working.', 'resolved', 2, 1, NOW() - INTERVAL '10 days', NOW() - INTERVAL '8 days', NOW() - INTERVAL '12 days'),
(9, 19, 'pest_control', 'Cockroach problem', 'Seeing cockroaches in the room frequently.', 'resolved', 1, 6, NOW() - INTERVAL '20 days', NOW() - INTERVAL '18 days', NOW() - INTERVAL '21 days'),
(1, 1, 'furniture', 'Wobbly table', 'Study table is not stable.', 'resolved', 4, 3, NOW() - INTERVAL '25 days', NOW() - INTERVAL '24 days', NOW() - INTERVAL '27 days'),
(4, 16, 'internet', 'No internet connection', 'Room has no internet access.', 'resolved', 1, 5, NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days', NOW() - INTERVAL '16 days'),
(10, 23, 'cleaning', 'Room not cleaned properly', 'Cleaning staff missed our room.', 'resolved', 5, 4, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '6 days'),
(15, 9, 'plumbing', 'Clogged drain', 'Bathroom drain is completely blocked.', 'resolved', 3, 2, NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '9 days'),
(21, 10, 'electrical', 'Light switch broken', 'Main room light switch crumbled when pressed.', 'resolved', 2, 7, NOW() - INTERVAL '12 days', NOW() - INTERVAL '11 days', NOW() - INTERVAL '14 days'),
(17, 21, 'security', 'Door hinge loose', 'Main door hinge is loose, door does not close properly.', 'resolved', 3, 10, NOW() - INTERVAL '18 days', NOW() - INTERVAL '16 days', NOW() - INTERVAL '20 days'),
(24, 26, 'furniture', 'Broken mirror', 'Wall mirror fell and cracked, glass hazard.', 'resolved', 4, 3, NOW() - INTERVAL '7 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '8 days'),
(26, 38, 'pest_control', 'Lizard infestation', 'Multiple lizards spotted in the room every evening.', 'resolved', 2, 6, NOW() - INTERVAL '22 days', NOW() - INTERVAL '20 days', NOW() - INTERVAL '24 days');

-- Closed complaints (6)
INSERT INTO complaints (student_id, room_id, category, title, description, status, priority, assigned_staff_id, assigned_at, resolved_at, closed_at, created_at) VALUES
(2, 1, 'security', 'Lock needs replacement', 'Room door lock is difficult to open.', 'closed', 2, 3, NOW() - INTERVAL '35 days', NOW() - INTERVAL '33 days', NOW() - INTERVAL '30 days', NOW() - INTERVAL '37 days'),
(5, 16, 'electrical', 'Switch spark issue', 'Main switch sparks when turned on.', 'closed', 1, 1, NOW() - INTERVAL '40 days', NOW() - INTERVAL '38 days', NOW() - INTERVAL '35 days', NOW() - INTERVAL '42 days'),
(13, 5, 'plumbing', 'Toilet flush broken', 'Flush mechanism not working, needs manual water pouring.', 'closed', 3, 8, NOW() - INTERVAL '30 days', NOW() - INTERVAL '28 days', NOW() - INTERVAL '25 days', NOW() - INTERVAL '32 days'),
(19, 25, 'cleaning', 'Stains on wall', 'Water damage stains on room wall from leaking pipe above.', 'closed', 2, 4, NOW() - INTERVAL '45 days', NOW() - INTERVAL '42 days', NOW() - INTERVAL '38 days', NOW() - INTERVAL '48 days'),
(23, 12, 'internet', 'Ethernet port dead', 'Wired ethernet port stopped working entirely.', 'closed', 2, 5, NOW() - INTERVAL '50 days', NOW() - INTERVAL '48 days', NOW() - INTERVAL '45 days', NOW() - INTERVAL '52 days'),
(30, 41, 'furniture', 'Desk drawer stuck', 'Desk drawer is jammed and cannot be opened.', 'closed', 3, 10, NOW() - INTERVAL '28 days', NOW() - INTERVAL '26 days', NOW() - INTERVAL '22 days', NOW() - INTERVAL '30 days');

-- PAYMENTS (50+ payments)

-- Fall 2024 - Paid payments (all 30 students)
INSERT INTO payments (student_id, allocation_id, amount, payment_date, due_date, payment_status, payment_method, transaction_id, receipt_number, semester) VALUES
(1, 1, 5000.00, '2024-07-15', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234567', 'RCP-2024-001', 'Fall 2024'),
(2, 2, 5000.00, '2024-07-20', '2024-07-31', 'paid', 'upi', 'TXN001234568', 'RCP-2024-002', 'Fall 2024'),
(3, 3, 5000.00, '2024-07-25', '2024-07-31', 'paid', 'card', 'TXN001234569', 'RCP-2024-003', 'Fall 2024'),
(4, 16, 5500.00, '2024-07-18', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234570', 'RCP-2024-004', 'Fall 2024'),
(5, 17, 5500.00, '2024-07-22', '2024-07-31', 'paid', 'upi', 'TXN001234571', 'RCP-2024-005', 'Fall 2024'),
(6, 18, 5500.00, '2024-07-28', '2024-07-31', 'paid', 'cash', NULL, 'RCP-2024-006', 'Fall 2024'),
(7, 4, 4500.00, '2024-07-16', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234572', 'RCP-2024-007', 'Fall 2024'),
(8, 5, 4500.00, '2024-07-19', '2024-07-31', 'paid', 'upi', 'TXN001234573', 'RCP-2024-008', 'Fall 2024'),
(9, 19, 8500.00, '2024-07-21', '2024-07-31', 'paid', 'card', 'TXN001234574', 'RCP-2024-009', 'Fall 2024'),
(10, 22, 5000.00, '2024-07-24', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234575', 'RCP-2024-010', 'Fall 2024'),
(11, 6, 8000.00, '2024-07-14', '2024-07-31', 'paid', 'upi', 'TXN001234576', 'RCP-2024-011', 'Fall 2024'),
(12, 7, 6000.00, '2024-07-17', '2024-07-31', 'paid', 'card', 'TXN001234577', 'RCP-2024-012', 'Fall 2024'),
(13, 8, 6000.00, '2024-07-29', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234578', 'RCP-2024-013', 'Fall 2024'),
(14, 9, 4000.00, '2024-07-23', '2024-07-31', 'paid', 'upi', 'TXN001234579', 'RCP-2024-014', 'Fall 2024'),
(15, 10, 4000.00, '2024-07-26', '2024-07-31', 'paid', 'cash', NULL, 'RCP-2024-015', 'Fall 2024'),
(16, 20, 6500.00, '2024-07-13', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234580', 'RCP-2024-016', 'Fall 2024'),
(17, 21, 6800.00, '2024-07-18', '2024-07-31', 'paid', 'upi', 'TXN001234581', 'RCP-2024-017', 'Fall 2024'),
(18, 23, 5000.00, '2024-07-27', '2024-07-31', 'paid', 'card', 'TXN001234582', 'RCP-2024-018', 'Fall 2024'),
(19, 24, 4500.00, '2024-07-20', '2024-07-31', 'paid', 'upi', 'TXN001234583', 'RCP-2024-019', 'Fall 2024'),
(20, 26, 5300.00, '2024-07-15', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234584', 'RCP-2024-020', 'Fall 2024'),
(21, 11, 4000.00, '2024-07-22', '2024-07-31', 'paid', 'upi', 'TXN001234585', 'RCP-2024-021', 'Fall 2024'),
(22, 12, 4500.00, '2024-07-19', '2024-07-31', 'paid', 'card', 'TXN001234586', 'RCP-2024-022', 'Fall 2024'),
(23, 13, 5500.00, '2024-07-25', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234587', 'RCP-2024-023', 'Fall 2024'),
(24, 25, 6000.00, '2024-07-16', '2024-07-31', 'paid', 'upi', 'TXN001234588', 'RCP-2024-024', 'Fall 2024'),
(25, 27, 5300.00, '2024-07-21', '2024-07-31', 'paid', 'card', 'TXN001234589', 'RCP-2024-025', 'Fall 2024'),
(26, 28, 4600.00, '2024-07-28', '2024-07-31', 'paid', 'upi', 'TXN001234590', 'RCP-2024-026', 'Fall 2024'),
(27, 14, 3800.00, '2024-07-17', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234591', 'RCP-2024-027', 'Fall 2024'),
(28, 15, 4200.00, '2024-07-24', '2024-07-31', 'paid', 'cash', NULL, 'RCP-2024-028', 'Fall 2024'),
(29, 29, 6200.00, '2024-07-19', '2024-07-31', 'paid', 'upi', 'TXN001234592', 'RCP-2024-029', 'Fall 2024'),
(30, 30, 6800.00, '2024-07-23', '2024-07-31', 'paid', 'bank_transfer', 'TXN001234593', 'RCP-2024-030', 'Fall 2024');

-- Spring 2025 - Pending payments (15 students)
INSERT INTO payments (student_id, allocation_id, amount, due_date, payment_status, semester) VALUES
(1, 1, 5000.00, '2025-01-15', 'pending', 'Spring 2025'),
(2, 2, 5000.00, '2025-01-15', 'pending', 'Spring 2025'),
(3, 3, 5000.00, '2025-01-15', 'pending', 'Spring 2025'),
(4, 16, 5500.00, '2025-01-15', 'pending', 'Spring 2025'),
(5, 17, 5500.00, '2025-01-15', 'pending', 'Spring 2025'),
(11, 6, 8000.00, '2025-01-15', 'pending', 'Spring 2025'),
(14, 9, 4000.00, '2025-01-15', 'pending', 'Spring 2025'),
(16, 20, 6500.00, '2025-01-15', 'pending', 'Spring 2025'),
(19, 24, 4500.00, '2025-01-15', 'pending', 'Spring 2025'),
(21, 11, 4000.00, '2025-01-15', 'pending', 'Spring 2025'),
(24, 25, 6000.00, '2025-01-15', 'pending', 'Spring 2025'),
(25, 27, 5300.00, '2025-01-15', 'pending', 'Spring 2025'),
(27, 14, 3800.00, '2025-01-15', 'pending', 'Spring 2025'),
(29, 29, 6200.00, '2025-01-15', 'pending', 'Spring 2025'),
(30, 30, 6800.00, '2025-01-15', 'pending', 'Spring 2025');

-- Spring 2025 - Overdue payments (8 students)
INSERT INTO payments (student_id, allocation_id, amount, due_date, payment_status, semester) VALUES
(6, 18, 5500.00, '2024-12-15', 'overdue', 'Spring 2025'),
(7, 4, 4500.00, '2024-12-20', 'overdue', 'Spring 2025'),
(9, 19, 8500.00, '2024-12-10', 'overdue', 'Spring 2025'),
(12, 7, 6000.00, '2024-12-18', 'overdue', 'Spring 2025'),
(15, 10, 4000.00, '2024-12-22', 'overdue', 'Spring 2025'),
(17, 21, 6800.00, '2024-12-12', 'overdue', 'Spring 2025'),
(22, 12, 4500.00, '2024-12-25', 'overdue', 'Spring 2025'),
(26, 28, 4600.00, '2024-12-28', 'overdue', 'Spring 2025');

-- Partial payments (4 students)
INSERT INTO payments (student_id, allocation_id, amount, payment_date, due_date, payment_status, payment_method, notes, semester) VALUES
(8, 5, 2000.00, '2024-12-28', '2024-12-31', 'partial', 'upi', 'Partial payment received. Balance: Rs 2500', 'Spring 2025'),
(10, 22, 2500.00, '2024-12-30', '2024-12-31', 'partial', 'bank_transfer', 'Partial payment received. Balance: Rs 2500', 'Spring 2025'),
(13, 8, 3000.00, '2025-01-05', '2024-12-31', 'partial', 'card', 'Partial payment received. Balance: Rs 3000', 'Spring 2025'),
(28, 15, 2000.00, '2025-01-02', '2024-12-31', 'partial', 'upi', 'Partial payment received. Balance: Rs 2200', 'Spring 2025');

-- Spring 2025 - Paid (remaining students who paid on time)
INSERT INTO payments (student_id, allocation_id, amount, payment_date, due_date, payment_status, payment_method, transaction_id, receipt_number, semester) VALUES
(18, 23, 5000.00, '2025-01-10', '2025-01-15', 'paid', 'upi', 'TXN002234601', 'RCP-2025-001', 'Spring 2025'),
(20, 26, 5300.00, '2025-01-08', '2025-01-15', 'paid', 'bank_transfer', 'TXN002234602', 'RCP-2025-002', 'Spring 2025'),
(23, 13, 5500.00, '2025-01-12', '2025-01-15', 'paid', 'card', 'TXN002234603', 'RCP-2025-003', 'Spring 2025');
