/**
 * Complaint Detail API Route (App Router)
 * ========================================
 * Handle operations on individual complaints.
 * 
 * Endpoints:
 * - GET /api/complaints/[id] - Get complaint details with history
 * - PUT /api/complaints/[id] - Update complaint (status, assign staff, resolve)
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse, Complaint } from '@/lib/types';

interface ComplaintLog {
    id: number;
    old_status: string | null;
    new_status: string;
    changed_by: string | null;
    notes: string | null;
    changed_at: Date;
}

interface ComplaintWithHistory extends Complaint {
    history: ComplaintLog[];
}

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/complaints/[id]
 */
export async function GET(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const complaintId = parseInt(id);

        if (isNaN(complaintId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid complaint ID' },
                { status: 400 }
            );
        }

        // Get complaint details
        const complaintResult = await query<Complaint>(
            `SELECT 
              c.*,
              s.first_name || ' ' || s.last_name as student_name,
              s.registration_number,
              s.email as student_email,
              s.phone as student_phone,
              r.room_number,
              r.floor,
              h.name as hostel_name,
              h.warden_name,
              h.warden_contact,
              ms.name as staff_name,
              ms.phone as staff_phone,
              ms.specialization as staff_specialization
             FROM complaints c
             INNER JOIN students s ON c.student_id = s.id
             INNER JOIN rooms r ON c.room_id = r.id
             INNER JOIN hostels h ON r.hostel_id = h.id
             LEFT JOIN maintenance_staff ms ON c.assigned_staff_id = ms.id
             WHERE c.id = $1`,
            [complaintId]
        );

        if (complaintResult.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Complaint not found' },
                { status: 404 }
            );
        }

        // Get complaint history
        const historyResult = await query<ComplaintLog>(
            `SELECT * FROM complaint_logs 
             WHERE complaint_id = $1 
             ORDER BY changed_at DESC`,
            [complaintId]
        );

        return NextResponse.json<ApiResponse<ComplaintWithHistory>>({
            success: true,
            data: {
                ...complaintResult.rows[0],
                history: historyResult.rows
            }
        });
    } catch (error) {
        console.error('Complaint detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * PUT /api/complaints/[id]
 */
export async function PUT(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const complaintId = parseInt(id);

        if (isNaN(complaintId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid complaint ID' },
                { status: 400 }
            );
        }

        const body = await request.json();
        const { status, assigned_staff_id, resolution_notes, priority } = body;

        // Check if complaint exists
        const existingResult = await query<Complaint>(
            'SELECT * FROM complaints WHERE id = $1',
            [complaintId]
        );

        if (existingResult.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Complaint not found' },
                { status: 404 }
            );
        }

        const existing = existingResult.rows[0];

        // Validate status transition
        const validStatuses = ['open', 'assigned', 'in_progress', 'resolved', 'closed'];
        if (status && !validStatuses.includes(status)) {
            return NextResponse.json(
                { success: false, error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` },
                { status: 400 }
            );
        }

        // Build UPDATE query dynamically
        const updates: string[] = [];
        const params: (string | number | null)[] = [];
        let paramIndex = 1;

        // Handle status change
        if (status && status !== existing.status) {
            updates.push(`status = $${paramIndex++}`);
            params.push(status);

            if (status === 'assigned' && !assigned_staff_id && !existing.assigned_staff_id) {
                return NextResponse.json(
                    { success: false, error: 'Cannot set status to assigned without assigning staff' },
                    { status: 400 }
                );
            }
        }

        // Handle staff assignment
        if (assigned_staff_id !== undefined) {
            if (assigned_staff_id !== null) {
                const staffCheck = await query(
                    'SELECT id FROM maintenance_staff WHERE id = $1 AND is_available = TRUE',
                    [assigned_staff_id]
                );
                if (staffCheck.rows.length === 0) {
                    return NextResponse.json(
                        { success: false, error: 'Staff not found or not available' },
                        { status: 400 }
                    );
                }
            }

            updates.push(`assigned_staff_id = $${paramIndex++}`);
            params.push(assigned_staff_id);

            if (assigned_staff_id && existing.status === 'open' && !status) {
                updates.push(`status = $${paramIndex++}`);
                params.push('assigned');
            }
        }

        // Handle resolution notes
        if (resolution_notes !== undefined) {
            updates.push(`resolution_notes = $${paramIndex++}`);
            params.push(resolution_notes);
        }

        // Handle priority change
        if (priority !== undefined) {
            if (priority < 1 || priority > 5) {
                return NextResponse.json(
                    { success: false, error: 'Priority must be between 1 and 5' },
                    { status: 400 }
                );
            }
            updates.push(`priority = $${paramIndex++}`);
            params.push(priority);
        }

        if (updates.length === 0) {
            return NextResponse.json(
                { success: false, error: 'No fields to update' },
                { status: 400 }
            );
        }

        params.push(complaintId);

        const result = await query<Complaint>(
            `UPDATE complaints 
             SET ${updates.join(', ')}
             WHERE id = $${paramIndex}
             RETURNING *`,
            params
        );

        return NextResponse.json({
            success: true,
            data: result.rows[0],
            message: 'Complaint updated successfully'
        });
    } catch (error) {
        console.error('Complaint detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
