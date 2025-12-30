/**
 * Student Detail API Route (App Router)
 * ======================================
 * Handle operations on individual students by ID.
 * 
 * Endpoints:
 * - GET /api/students/[id] - Get student details with allocation info
 * - PUT /api/students/[id] - Update student information
 * - DELETE /api/students/[id] - Soft delete (deactivate) student
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse, Student } from '@/lib/types';

interface StudentWithDetails extends Student {
    room_id?: number;
    room_number?: string;
    hostel_name?: string;
    allocation_date?: Date;
    total_paid?: number;
    total_pending?: number;
    active_complaints?: number;
}

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/students/[id]
 */
export async function GET(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const studentId = parseInt(id);

        if (isNaN(studentId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid student ID' },
                { status: 400 }
            );
        }

        const result = await query<StudentWithDetails>(`
            SELECT 
              s.*,
              r.id as room_id,
              r.room_number,
              h.name as hostel_name,
              a.allocation_date,
              COALESCE((
                SELECT SUM(amount) 
                FROM payments 
                WHERE student_id = s.id AND payment_status = 'paid'
              ), 0) as total_paid,
              COALESCE((
                SELECT SUM(amount) 
                FROM payments 
                WHERE student_id = s.id AND payment_status IN ('pending', 'overdue')
              ), 0) as total_pending,
              COALESCE((
                SELECT COUNT(*) 
                FROM complaints 
                WHERE student_id = s.id AND status IN ('open', 'assigned', 'in_progress')
              ), 0) as active_complaints
            FROM students s
            LEFT JOIN allocations a ON a.student_id = s.id AND a.is_active = TRUE
            LEFT JOIN rooms r ON a.room_id = r.id
            LEFT JOIN hostels h ON r.hostel_id = h.id
            WHERE s.id = $1
        `, [studentId]);

        if (result.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Student not found' },
                { status: 404 }
            );
        }

        return NextResponse.json<ApiResponse<StudentWithDetails>>({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Student detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * PUT /api/students/[id]
 */
export async function PUT(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const studentId = parseInt(id);

        if (isNaN(studentId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid student ID' },
                { status: 400 }
            );
        }

        const body = await request.json();
        const {
            first_name,
            last_name,
            email,
            phone,
            date_of_birth,
            address,
            guardian_name,
            guardian_phone,
            department,
            year_of_study
        } = body;

        const updates: string[] = [];
        const params: (string | number | boolean | null)[] = [];
        let paramIndex = 1;

        if (first_name !== undefined) {
            updates.push(`first_name = $${paramIndex++}`);
            params.push(first_name);
        }
        if (last_name !== undefined) {
            updates.push(`last_name = $${paramIndex++}`);
            params.push(last_name);
        }
        if (email !== undefined) {
            updates.push(`email = $${paramIndex++}`);
            params.push(email);
        }
        if (phone !== undefined) {
            updates.push(`phone = $${paramIndex++}`);
            params.push(phone);
        }
        if (date_of_birth !== undefined) {
            updates.push(`date_of_birth = $${paramIndex++}`);
            params.push(date_of_birth);
        }
        if (address !== undefined) {
            updates.push(`address = $${paramIndex++}`);
            params.push(address);
        }
        if (guardian_name !== undefined) {
            updates.push(`guardian_name = $${paramIndex++}`);
            params.push(guardian_name);
        }
        if (guardian_phone !== undefined) {
            updates.push(`guardian_phone = $${paramIndex++}`);
            params.push(guardian_phone);
        }
        if (department !== undefined) {
            updates.push(`department = $${paramIndex++}`);
            params.push(department);
        }
        if (year_of_study !== undefined) {
            updates.push(`year_of_study = $${paramIndex++}`);
            params.push(year_of_study);
        }

        if (updates.length === 0) {
            return NextResponse.json(
                { success: false, error: 'No fields to update' },
                { status: 400 }
            );
        }

        params.push(studentId);

        const result = await query<Student>(
            `UPDATE students 
             SET ${updates.join(', ')} 
             WHERE id = $${paramIndex}
             RETURNING *`,
            params
        );

        if (result.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Student not found' },
                { status: 404 }
            );
        }

        return NextResponse.json({
            success: true,
            data: result.rows[0],
            message: 'Student updated successfully'
        });
    } catch (error) {
        console.error('Student detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * DELETE /api/students/[id]
 */
export async function DELETE(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const studentId = parseInt(id);

        if (isNaN(studentId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid student ID' },
                { status: 400 }
            );
        }

        // Soft delete - just mark as inactive
        const result = await query<Student>(
            `UPDATE students 
             SET is_active = FALSE 
             WHERE id = $1
             RETURNING *`,
            [studentId]
        );

        if (result.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Student not found' },
                { status: 404 }
            );
        }

        // Also deactivate any active allocation
        await query(
            `UPDATE allocations 
             SET is_active = FALSE, actual_checkout = CURRENT_DATE
             WHERE student_id = $1 AND is_active = TRUE`,
            [studentId]
        );

        return NextResponse.json({
            success: true,
            data: result.rows[0],
            message: 'Student deactivated successfully'
        });
    } catch (error) {
        console.error('Student detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
