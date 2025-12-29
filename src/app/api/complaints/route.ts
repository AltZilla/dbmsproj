/**
 * Complaints API Routes (App Router)
 * ====================================
 * RESTful API for managing maintenance complaints.
 * 
 * Endpoints:
 * - GET /api/complaints - List all complaints with filtering
 * - POST /api/complaints - Raise a new complaint
 * 
 * DBMS CONCEPTS:
 * - TRIGGER logs all status changes automatically
 * - Multiple JOINs for enriched data
 * - Filtering and sorting
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { PaginatedResponse, Complaint } from '@/lib/types';

/**
 * GET /api/complaints
 * 
 * Retrieves complaints with student, room, and staff information.
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
        const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20')));
        const offset = (page - 1) * limit;

        const status = searchParams.get('status');
        const category = searchParams.get('category');
        const studentId = searchParams.get('student_id');
        const roomId = searchParams.get('room_id');
        const hostelId = searchParams.get('hostel_id');
        const priority = searchParams.get('priority');
        const assigned = searchParams.get('assigned');
        const unassigned = searchParams.get('unassigned');

        const conditions: string[] = [];
        const params: (string | number)[] = [];
        let paramIndex = 1;

        if (status) {
            conditions.push(`c.status = $${paramIndex++}`);
            params.push(status);
        }

        if (category) {
            conditions.push(`c.category = $${paramIndex++}`);
            params.push(category);
        }

        if (studentId) {
            conditions.push(`c.student_id = $${paramIndex++}`);
            params.push(parseInt(studentId));
        }

        if (roomId) {
            conditions.push(`c.room_id = $${paramIndex++}`);
            params.push(parseInt(roomId));
        }

        if (hostelId) {
            conditions.push(`r.hostel_id = $${paramIndex++}`);
            params.push(parseInt(hostelId));
        }

        if (priority) {
            conditions.push(`c.priority = $${paramIndex++}`);
            params.push(parseInt(priority));
        }

        if (assigned === 'true') {
            conditions.push(`c.assigned_staff_id IS NOT NULL`);
        }

        if (unassigned === 'true') {
            conditions.push(`c.assigned_staff_id IS NULL`);
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const countResult = await query<{ count: string }>(
            `SELECT COUNT(*) as count 
             FROM complaints c
             INNER JOIN rooms r ON c.room_id = r.id
             ${whereClause}`,
            params
        );
        const total = parseInt(countResult.rows[0].count);

        const dataResult = await query<Complaint>(
            `SELECT 
              c.*,
              s.first_name || ' ' || s.last_name as student_name,
              s.registration_number,
              r.room_number,
              h.name as hostel_name,
              ms.name as staff_name,
              ms.phone as staff_phone,
              EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - c.created_at)) / 3600 as hours_since_creation
             FROM complaints c
             INNER JOIN students s ON c.student_id = s.id
             INNER JOIN rooms r ON c.room_id = r.id
             INNER JOIN hostels h ON r.hostel_id = h.id
             LEFT JOIN maintenance_staff ms ON c.assigned_staff_id = ms.id
             ${whereClause}
             ORDER BY 
               CASE c.status 
                 WHEN 'open' THEN 1 
                 WHEN 'assigned' THEN 2 
                 WHEN 'in_progress' THEN 3 
                 ELSE 4 
               END,
               c.priority ASC,
               c.created_at DESC
             LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
            [...params, limit, offset]
        );

        return NextResponse.json<PaginatedResponse<Complaint>>({
            success: true,
            data: dataResult.rows,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error('Complaints API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * POST /api/complaints
 * 
 * Creates a new maintenance complaint.
 */
export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { student_id, room_id, category, title, description, priority } = body;

        // Validate required fields
        if (!student_id || !room_id || !category || !title || !description) {
            return NextResponse.json(
                { success: false, error: 'Missing required fields: student_id, room_id, category, title, description' },
                { status: 400 }
            );
        }

        // Validate category
        const validCategories = [
            'electrical', 'plumbing', 'furniture', 'cleaning',
            'pest_control', 'internet', 'security', 'other'
        ];
        if (!validCategories.includes(category)) {
            return NextResponse.json(
                { success: false, error: `Invalid category. Must be one of: ${validCategories.join(', ')}` },
                { status: 400 }
            );
        }

        // Validate priority if provided
        const finalPriority = priority || 3;
        if (finalPriority < 1 || finalPriority > 5) {
            return NextResponse.json(
                { success: false, error: 'Priority must be between 1 (highest) and 5 (lowest)' },
                { status: 400 }
            );
        }

        // Verify student exists
        const studentCheck = await query(
            'SELECT id FROM students WHERE id = $1 AND is_active = TRUE',
            [student_id]
        );
        if (studentCheck.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Student not found or is not active' },
                { status: 400 }
            );
        }

        // Verify room exists
        const roomCheck = await query(
            'SELECT id FROM rooms WHERE id = $1',
            [room_id]
        );
        if (roomCheck.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Room not found' },
                { status: 400 }
            );
        }

        const result = await query<Complaint>(
            `INSERT INTO complaints (
              student_id, room_id, category, title, description, priority, status
            ) VALUES ($1, $2, $3, $4, $5, $6, 'open')
            RETURNING *`,
            [student_id, room_id, category, title, description, finalPriority]
        );

        return NextResponse.json(
            { success: true, data: result.rows[0], message: 'Complaint raised successfully' },
            { status: 201 }
        );
    } catch (error) {
        console.error('Complaints API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
