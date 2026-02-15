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
import { query, getClient } from '@/lib/db';
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
        const { status, assigned_staff_id, priority, admin_note } = body;

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
        const validStatuses = ['open', 'in_progress', 'resolved', 'closed'];
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

        // If no complaint field changes but admin_note is provided, we still proceed
        const hasFieldUpdates = updates.length > 0;
        const hasAdminNote = admin_note && admin_note.trim();

        if (!hasFieldUpdates && !hasAdminNote) {
            return NextResponse.json(
                { success: false, error: 'No fields to update' },
                { status: 400 }
            );
        }

        params.push(complaintId);

        const client = await getClient();
        try {
            await client.query('BEGIN');

            let resultRow = existing;

            // Update complaint fields if any changed
            if (hasFieldUpdates) {
                const result = await client.query<Complaint>(
                    `UPDATE complaints 
                     SET ${updates.join(', ')}
                     WHERE id = $${paramIndex}
                     RETURNING *`,
                    params
                );
                resultRow = result.rows[0];
            }

            // Handle admin note in complaint_logs
            if (hasAdminNote) {
                const statusChanged = status && status !== existing.status;
                if (statusChanged && hasFieldUpdates) {
                    // Status changed — trigger already created a log entry on this connection.
                    // Update that entry with the admin note instead of creating a duplicate.
                    await client.query(
                        `UPDATE complaint_logs
                         SET notes = $1, changed_by = 'admin'
                         WHERE complaint_id = $2
                           AND changed_at = (SELECT MAX(changed_at) FROM complaint_logs WHERE complaint_id = $2)`,
                        [admin_note.trim(), complaintId]
                    );
                } else {
                    // No status change — insert a standalone note entry.
                    await client.query(
                        `INSERT INTO complaint_logs (complaint_id, old_status, new_status, changed_by, notes, changed_at)
                         VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)`,
                        [complaintId, existing.status, existing.status, 'admin', admin_note.trim()]
                    );
                }
            }

            await client.query('COMMIT');

            return NextResponse.json({
                success: true,
                data: resultRow,
                message: 'Complaint updated successfully'
            });
        } catch (txError) {
            await client.query('ROLLBACK');
            throw txError;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Complaint detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
