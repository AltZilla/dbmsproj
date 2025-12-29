/**
 * Allocations API Routes (App Router)
 * =====================================
 * RESTful API for managing room allocations.
 * 
 * Endpoints:
 * - GET /api/allocations - List all allocations
 * - POST /api/allocations - Create a new allocation
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { PaginatedResponse } from '@/lib/types';

interface Allocation {
    id: number;
    student_id: number;
    room_id: number;
    allocation_date: Date;
    expected_checkout: Date | null;
    actual_checkout: Date | null;
    is_active: boolean;
    notes: string | null;
    created_at: Date;
    updated_at: Date;
    // Joined fields
    student_name?: string;
    registration_number?: string;
    room_number?: string;
    hostel_name?: string;
}

/**
 * GET /api/allocations
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
        const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20')));
        const offset = (page - 1) * limit;

        const studentId = searchParams.get('student_id');
        const roomId = searchParams.get('room_id');
        const hostelId = searchParams.get('hostel_id');
        const isActive = searchParams.get('is_active');

        const conditions: string[] = [];
        const params: (string | number | boolean)[] = [];
        let paramIndex = 1;

        if (studentId) {
            conditions.push(`a.student_id = $${paramIndex++}`);
            params.push(parseInt(studentId));
        }

        if (roomId) {
            conditions.push(`a.room_id = $${paramIndex++}`);
            params.push(parseInt(roomId));
        }

        if (hostelId) {
            conditions.push(`r.hostel_id = $${paramIndex++}`);
            params.push(parseInt(hostelId));
        }

        if (isActive === 'true') {
            conditions.push(`a.is_active = TRUE`);
        } else if (isActive === 'false') {
            conditions.push(`a.is_active = FALSE`);
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const countResult = await query<{ count: string }>(
            `SELECT COUNT(*) as count 
             FROM allocations a
             INNER JOIN rooms r ON a.room_id = r.id
             ${whereClause}`,
            params
        );
        const total = parseInt(countResult.rows[0].count);

        const dataResult = await query<Allocation>(
            `SELECT 
              a.*,
              s.first_name || ' ' || s.last_name as student_name,
              s.registration_number,
              r.room_number,
              h.name as hostel_name
             FROM allocations a
             INNER JOIN students s ON a.student_id = s.id
             INNER JOIN rooms r ON a.room_id = r.id
             INNER JOIN hostels h ON r.hostel_id = h.id
             ${whereClause}
             ORDER BY a.allocation_date DESC
             LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
            [...params, limit, offset]
        );

        return NextResponse.json<PaginatedResponse<Allocation>>({
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
        console.error('Allocations API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * POST /api/allocations
 * 
 * Creates a new room allocation for a student.
 * The database trigger will automatically:
 * - Update the room's current_occupancy
 * - Deactivate previous allocations for the student
 */
export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { student_id, room_id, expected_checkout, notes } = body;

        if (!student_id || !room_id) {
            return NextResponse.json(
                { success: false, error: 'Missing required fields: student_id, room_id' },
                { status: 400 }
            );
        }

        // Verify student exists and is active
        const studentCheck = await query(
            'SELECT id, gender FROM students WHERE id = $1 AND is_active = TRUE',
            [student_id]
        );
        if (studentCheck.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Student not found or is not active' },
                { status: 400 }
            );
        }

        // Verify room exists and has capacity
        const roomCheck = await query<{
            id: number;
            capacity: number;
            current_occupancy: number;
            gender_allowed: string;
        }>(
            `SELECT r.id, r.capacity, r.current_occupancy, h.gender_allowed 
             FROM rooms r
             INNER JOIN hostels h ON r.hostel_id = h.id
             WHERE r.id = $1 AND r.is_available = TRUE`,
            [room_id]
        );

        if (roomCheck.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Room not found or not available' },
                { status: 400 }
            );
        }

        const room = roomCheck.rows[0];
        if (room.current_occupancy >= room.capacity) {
            return NextResponse.json(
                { success: false, error: 'Room is at full capacity' },
                { status: 400 }
            );
        }

        // Check gender compatibility
        const student = studentCheck.rows[0] as { id: number; gender: string };
        if (room.gender_allowed !== 'other' && student.gender !== room.gender_allowed) {
            return NextResponse.json(
                { success: false, error: `Room is for ${room.gender_allowed} students only` },
                { status: 400 }
            );
        }

        // Check if student already has an active allocation
        const existingAllocation = await query(
            'SELECT id FROM allocations WHERE student_id = $1 AND is_active = TRUE',
            [student_id]
        );

        if (existingAllocation.rows.length > 0) {
            // Deactivate existing allocation
            await query(
                `UPDATE allocations 
                 SET is_active = FALSE, actual_checkout = CURRENT_DATE 
                 WHERE student_id = $1 AND is_active = TRUE`,
                [student_id]
            );
        }

        // Create the allocation
        const result = await query<Allocation>(
            `INSERT INTO allocations (
              student_id, room_id, allocation_date, expected_checkout, notes, is_active
            ) VALUES ($1, $2, CURRENT_DATE, $3, $4, TRUE)
            RETURNING *`,
            [student_id, room_id, expected_checkout || null, notes || null]
        );

        // Update room occupancy
        await query(
            'UPDATE rooms SET current_occupancy = current_occupancy + 1 WHERE id = $1',
            [room_id]
        );

        return NextResponse.json(
            { success: true, data: result.rows[0], message: 'Allocation created successfully' },
            { status: 201 }
        );
    } catch (error) {
        console.error('Allocations API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
