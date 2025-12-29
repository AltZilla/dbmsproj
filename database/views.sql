-- ============================================================================
-- SMART HOSTEL MANAGEMENT SYSTEM - SQL VIEWS FOR ANALYTICS
-- ============================================================================
-- This file creates SQL views that provide pre-computed analytics data.
-- Views are virtual tables based on SELECT queries that simplify complex
-- query logic and improve code reusability.
--
-- KEY DBMS CONCEPTS DEMONSTRATED:
-- 1. VIEWS: Virtual tables that encapsulate complex queries
-- 2. JOINs: Combining data from multiple tables
-- 3. GROUP BY: Aggregating data by categories
-- 4. Aggregate Functions: COUNT, AVG, SUM, MAX, MIN
-- 5. Window Functions: Calculations across related rows
-- 6. Date/Time Functions: Extracting and manipulating dates
-- 7. COALESCE: Handling NULL values
-- 8. CASE Expressions: Conditional logic in queries
-- ============================================================================

-- ============================================================================
-- VIEW 1: COMPLAINT CATEGORY STATISTICS
-- ============================================================================
-- Shows the count and percentage of complaints by category.
-- Useful for identifying the most frequent types of issues.
--
-- DBMS Concepts: GROUP BY, COUNT, Subquery for percentage calculation

DROP VIEW IF EXISTS complaint_category_stats;
CREATE VIEW complaint_category_stats AS
SELECT 
    category,
    COUNT(*) as total_complaints,
    -- Calculate percentage of total complaints
    ROUND(
        COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM complaints), 0),
        2
    ) as percentage,
    -- Count by status
    COUNT(*) FILTER (WHERE status = 'open') as open_count,
    COUNT(*) FILTER (WHERE status = 'assigned') as assigned_count,
    COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_count,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved_count,
    COUNT(*) FILTER (WHERE status = 'closed') as closed_count
FROM complaints
GROUP BY category
ORDER BY total_complaints DESC;

-- Add comment explaining the view
COMMENT ON VIEW complaint_category_stats IS 
    'Aggregated complaint counts by category with status breakdown';

-- ============================================================================
-- VIEW 2: ROOM-WISE COMPLAINT SUMMARY
-- ============================================================================
-- Shows complaint statistics for each room.
-- Includes room details and complaint metrics.
--
-- DBMS Concepts: LEFT JOIN (to include rooms with no complaints),
--                GROUP BY with multiple columns, COALESCE for NULL handling

DROP VIEW IF EXISTS room_complaint_summary;
CREATE VIEW room_complaint_summary AS
SELECT 
    r.id as room_id,
    r.room_number,
    h.name as hostel_name,
    r.floor,
    r.room_type,
    r.capacity,
    r.current_occupancy,
    -- Complaint metrics (COALESCE handles NULL when no complaints exist)
    COALESCE(COUNT(c.id), 0) as total_complaints,
    COALESCE(COUNT(c.id) FILTER (WHERE c.status IN ('open', 'assigned', 'in_progress')), 0) as active_complaints,
    COALESCE(COUNT(c.id) FILTER (WHERE c.status IN ('resolved', 'closed')), 0) as resolved_complaints,
    -- Most common issue category for this room
    MODE() WITHIN GROUP (ORDER BY c.category) as most_common_category,
    -- Last complaint date
    MAX(c.created_at) as last_complaint_date
FROM rooms r
-- LEFT JOIN ensures rooms with no complaints are still included
LEFT JOIN complaints c ON r.id = c.room_id
-- INNER JOIN to get hostel name
INNER JOIN hostels h ON r.hostel_id = h.id
GROUP BY r.id, r.room_number, h.name, r.floor, r.room_type, r.capacity, r.current_occupancy
ORDER BY total_complaints DESC, h.name, r.room_number;

COMMENT ON VIEW room_complaint_summary IS 
    'Per-room complaint statistics with occupancy information';

-- ============================================================================
-- VIEW 3: HOSTEL-WISE COMPLAINT SUMMARY
-- ============================================================================
-- Aggregates complaint data at the hostel level.
-- Useful for comparing maintenance needs across hostels.
--
-- DBMS Concepts: Multiple JOINs, nested aggregation, arithmetic operations

DROP VIEW IF EXISTS hostel_complaint_summary;
CREATE VIEW hostel_complaint_summary AS
SELECT 
    h.id as hostel_id,
    h.name as hostel_name,
    h.warden_name,
    h.total_rooms,
    -- Calculate total capacity and current students
    COALESCE(SUM(r.capacity), 0) as total_capacity,
    COALESCE(SUM(r.current_occupancy), 0) as total_occupancy,
    -- Complaint metrics
    COALESCE(COUNT(DISTINCT c.id), 0) as total_complaints,
    COALESCE(COUNT(DISTINCT c.id) FILTER (WHERE c.status = 'open'), 0) as open_complaints,
    COALESCE(COUNT(DISTINCT c.id) FILTER (WHERE c.status IN ('resolved', 'closed')), 0) as resolved_complaints,
    -- Complaints per room (normalized metric)
    CASE 
        WHEN h.total_rooms > 0 THEN 
            ROUND(COUNT(DISTINCT c.id)::DECIMAL / h.total_rooms, 2)
        ELSE 0 
    END as complaints_per_room,
    -- Complaints per student
    CASE 
        WHEN COALESCE(SUM(r.current_occupancy), 0) > 0 THEN 
            ROUND(COUNT(DISTINCT c.id)::DECIMAL / SUM(r.current_occupancy), 2)
        ELSE 0 
    END as complaints_per_student
FROM hostels h
LEFT JOIN rooms r ON r.hostel_id = h.id
LEFT JOIN complaints c ON c.room_id = r.id
GROUP BY h.id, h.name, h.warden_name, h.total_rooms
ORDER BY total_complaints DESC;

COMMENT ON VIEW hostel_complaint_summary IS 
    'Hostel-level complaint aggregations with normalized metrics';

-- ============================================================================
-- VIEW 4: AVERAGE RESOLUTION TIME ANALYTICS
-- ============================================================================
-- Calculates average time taken to resolve complaints.
-- Broken down by category for performance analysis.
--
-- DBMS Concepts: Date arithmetic, EXTRACT function, INTERVAL calculations,
--                FILTER clause, CASE expressions

DROP VIEW IF EXISTS resolution_time_analytics;
CREATE VIEW resolution_time_analytics AS
SELECT 
    category,
    COUNT(*) FILTER (WHERE status IN ('resolved', 'closed')) as resolved_count,
    -- Average time from creation to resolution (in hours)
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
        ) FILTER (WHERE resolved_at IS NOT NULL),
        2
    ) as avg_resolution_hours,
    -- Average time from creation to assignment (in hours)
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (assigned_at - created_at)) / 3600
        ) FILTER (WHERE assigned_at IS NOT NULL),
        2
    ) as avg_assignment_hours,
    -- Minimum resolution time
    ROUND(
        MIN(
            EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
        ) FILTER (WHERE resolved_at IS NOT NULL),
        2
    ) as min_resolution_hours,
    -- Maximum resolution time
    ROUND(
        MAX(
            EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
        ) FILTER (WHERE resolved_at IS NOT NULL),
        2
    ) as max_resolution_hours,
    -- Count complaints taking more than 48 hours (SLA breach indicator)
    COUNT(*) FILTER (
        WHERE resolved_at IS NOT NULL 
        AND EXTRACT(EPOCH FROM (resolved_at - created_at)) > 172800  -- 48 hours in seconds
    ) as sla_breaches
FROM complaints
GROUP BY category
ORDER BY avg_resolution_hours DESC NULLS LAST;

COMMENT ON VIEW resolution_time_analytics IS 
    'Resolution time metrics by complaint category';

-- ============================================================================
-- VIEW 5: MONTHLY COMPLAINT TRENDS
-- ============================================================================
-- Shows complaint trends over time for trend analysis.
--
-- DBMS Concepts: DATE_TRUNC for grouping by month, time series analysis

DROP VIEW IF EXISTS monthly_complaint_trends;
CREATE VIEW monthly_complaint_trends AS
SELECT 
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as total_complaints,
    COUNT(*) FILTER (WHERE category = 'electrical') as electrical,
    COUNT(*) FILTER (WHERE category = 'plumbing') as plumbing,
    COUNT(*) FILTER (WHERE category = 'furniture') as furniture,
    COUNT(*) FILTER (WHERE category = 'cleaning') as cleaning,
    COUNT(*) FILTER (WHERE category = 'pest_control') as pest_control,
    COUNT(*) FILTER (WHERE category = 'internet') as internet,
    COUNT(*) FILTER (WHERE category = 'security') as security,
    COUNT(*) FILTER (WHERE category = 'other') as other,
    -- Resolution rate for that month
    ROUND(
        COUNT(*) FILTER (WHERE status IN ('resolved', 'closed')) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) as resolution_rate
FROM complaints
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

COMMENT ON VIEW monthly_complaint_trends IS 
    'Monthly breakdown of complaints by category with resolution rate';

-- ============================================================================
-- VIEW 6: STUDENT DASHBOARD VIEW
-- ============================================================================
-- Provides a consolidated view for student portal.
-- Combines student, room, allocation, and payment information.
--
-- DBMS Concepts: Multiple JOINs, subqueries, window functions

DROP VIEW IF EXISTS student_dashboard;
CREATE VIEW student_dashboard AS
SELECT 
    s.id as student_id,
    s.registration_number,
    s.first_name || ' ' || s.last_name as full_name,
    s.email,
    -- Current room information (from active allocation)
    r.room_number,
    h.name as hostel_name,
    r.floor,
    r.room_type,
    a.allocation_date,
    -- Payment summary
    (
        SELECT COALESCE(SUM(amount), 0)
        FROM payments p 
        WHERE p.student_id = s.id AND p.payment_status = 'paid'
    ) as total_paid,
    (
        SELECT COALESCE(SUM(amount), 0)
        FROM payments p 
        WHERE p.student_id = s.id AND p.payment_status IN ('pending', 'overdue')
    ) as total_pending,
    -- Complaint summary
    (
        SELECT COUNT(*)
        FROM complaints c 
        WHERE c.student_id = s.id
    ) as total_complaints,
    (
        SELECT COUNT(*)
        FROM complaints c 
        WHERE c.student_id = s.id AND c.status IN ('open', 'assigned', 'in_progress')
    ) as active_complaints
FROM students s
LEFT JOIN allocations a ON a.student_id = s.id AND a.is_active = TRUE
LEFT JOIN rooms r ON a.room_id = r.id
LEFT JOIN hostels h ON r.hostel_id = h.id
WHERE s.is_active = TRUE
ORDER BY s.last_name, s.first_name;

COMMENT ON VIEW student_dashboard IS 
    'Consolidated student information for dashboard display';

-- ============================================================================
-- VIEW 7: ROOM AVAILABILITY VIEW
-- ============================================================================
-- Shows rooms with available capacity for new allocations.
--
-- DBMS Concepts: Calculated columns, filtering with WHERE

DROP VIEW IF EXISTS available_rooms;
CREATE VIEW available_rooms AS
SELECT 
    r.id as room_id,
    r.room_number,
    h.name as hostel_name,
    h.gender_allowed,
    r.floor,
    r.room_type,
    r.capacity,
    r.current_occupancy,
    r.capacity - r.current_occupancy as available_beds,
    r.rent_amount,
    r.has_ac,
    r.has_attached_bathroom
FROM rooms r
INNER JOIN hostels h ON r.hostel_id = h.id
WHERE r.is_available = TRUE
  AND r.current_occupancy < r.capacity
ORDER BY h.name, r.room_number;

COMMENT ON VIEW available_rooms IS 
    'Rooms with available capacity for new allocations';

-- ============================================================================
-- VIEW 8: PAYMENT DUES REPORT
-- ============================================================================
-- Shows students with pending/overdue payments.
--
-- DBMS Concepts: Date comparisons, conditional aggregation

DROP VIEW IF EXISTS payment_dues_report;
CREATE VIEW payment_dues_report AS
SELECT 
    s.id as student_id,
    s.registration_number,
    s.first_name || ' ' || s.last_name as full_name,
    s.email,
    s.phone,
    p.id as payment_id,
    p.amount,
    p.due_date,
    p.payment_status,
    p.semester,
    -- Days overdue (negative means not yet due)
    CURRENT_DATE - p.due_date as days_overdue,
    r.room_number,
    h.name as hostel_name
FROM payments p
INNER JOIN students s ON p.student_id = s.id
LEFT JOIN allocations a ON a.student_id = s.id AND a.is_active = TRUE
LEFT JOIN rooms r ON a.room_id = r.id
LEFT JOIN hostels h ON r.hostel_id = h.id
WHERE p.payment_status IN ('pending', 'overdue')
  AND s.is_active = TRUE
ORDER BY p.due_date ASC, s.last_name;

COMMENT ON VIEW payment_dues_report IS 
    'Students with pending or overdue payments';

-- ============================================================================
-- VIEW 9: MAINTENANCE STAFF WORKLOAD
-- ============================================================================
-- Shows current workload of each maintenance staff member.

DROP VIEW IF EXISTS staff_workload;
CREATE VIEW staff_workload AS
SELECT 
    ms.id as staff_id,
    ms.name as staff_name,
    ms.specialization,
    ms.phone,
    h.name as assigned_hostel,
    ms.is_available,
    COUNT(c.id) FILTER (WHERE c.status IN ('assigned', 'in_progress')) as active_complaints,
    COUNT(c.id) FILTER (WHERE c.status IN ('resolved', 'closed')) as resolved_complaints,
    -- Average resolution time for this staff member
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (c.resolved_at - c.assigned_at)) / 3600
        ) FILTER (WHERE c.resolved_at IS NOT NULL),
        2
    ) as avg_resolution_hours
FROM maintenance_staff ms
LEFT JOIN hostels h ON ms.hostel_id = h.id
LEFT JOIN complaints c ON c.assigned_staff_id = ms.id
GROUP BY ms.id, ms.name, ms.specialization, ms.phone, h.name, ms.is_available
ORDER BY active_complaints DESC;

COMMENT ON VIEW staff_workload IS 
    'Current workload and performance metrics for maintenance staff';
