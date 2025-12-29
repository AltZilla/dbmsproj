/**
 * Allocation Detail API Route (App Router)
 * =========================================
 * Handle operations on individual allocations.
 * 
 * Endpoints:
 * - GET /api/allocations/[id] - Get allocation details
 * - PUT /api/allocations/[id] - Update allocation
 * - DELETE /api/allocations/[id] - End allocation (checkout)
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

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
    student_name?: string;
    registration_number?: string;
    room_number?: string;
    hostel_name?: string;
}

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/allocations/[id]
 */
export async function GET(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const allocationId = parseInt(id);

        if (isNaN(allocationId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid allocation ID' },
                { status: 400 }
            );
        }

        const result = await query<Allocation>(
            `SELECT 
              a.*,
              s.first_name || ' ' || s.last_name as student_name,
              s.registration_number,
              s.email as student_email,
              s.phone as student_phone,
              r.room_number,
              r.floor,
              r.room_type,
              r.rent_amount,
              h.name as hostel_name,
              h.warden_name,
              h.warden_contact
             FROM allocations a
             INNER JOIN students s ON a.student_id = s.id
             INNER JOIN rooms r ON a.room_id = r.id
             INNER JOIN hostels h ON r.hostel_id = h.id
             WHERE a.id = $1`,
            [allocationId]
        );

        if (result.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Allocation not found' },
                { status: 404 }
            );
        }

        return NextResponse.json<ApiResponse<Allocation>>({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Allocation detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * PUT /api/allocations/[id]
 */
export async function PUT(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const allocationId = parseInt(id);

        if (isNaN(allocationId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid allocation ID' },
                { status: 400 }
            );
        }

        const body = await request.json();
        const { expected_checkout, notes } = body;

        const updates: string[] = [];
        const params: (string | number | null)[] = [];
        let paramIndex = 1;

        if (expected_checkout !== undefined) {
            updates.push(`expected_checkout = $${paramIndex++}`);
            params.push(expected_checkout);
        }

        if (notes !== undefined) {
            updates.push(`notes = $${paramIndex++}`);
            params.push(notes);
        }

        if (updates.length === 0) {
            return NextResponse.json(
                { success: false, error: 'No fields to update' },
                { status: 400 }
            );
        }

        params.push(allocationId);

        const result = await query<Allocation>(
            `UPDATE allocations 
             SET ${updates.join(', ')}
             WHERE id = $${paramIndex}
             RETURNING *`,
            params
        );

        if (result.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Allocation not found' },
                { status: 404 }
            );
        }

        return NextResponse.json({
            success: true,
            data: result.rows[0],
            message: 'Allocation updated successfully'
        });
    } catch (error) {
        console.error('Allocation detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * DELETE /api/allocations/[id]
 * 
 * Ends an allocation (checkout)
 */
export async function DELETE(request: NextRequest, context: RouteContext) {
    try {
        const { id } = await context.params;
        const allocationId = parseInt(id);

        if (isNaN(allocationId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid allocation ID' },
                { status: 400 }
            );
        }

        // Get allocation details first
        const existingResult = await query<Allocation>(
            'SELECT * FROM allocations WHERE id = $1',
            [allocationId]
        );

        if (existingResult.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Allocation not found' },
                { status: 404 }
            );
        }

        const existing = existingResult.rows[0];

        if (!existing.is_active) {
            return NextResponse.json(
                { success: false, error: 'Allocation is already inactive' },
                { status: 400 }
            );
        }

        // Deactivate the allocation
        const result = await query<Allocation>(
            `UPDATE allocations 
             SET is_active = FALSE, actual_checkout = CURRENT_DATE
             WHERE id = $1
             RETURNING *`,
            [allocationId]
        );

        // Decrease room occupancy
        await query(
            'UPDATE rooms SET current_occupancy = GREATEST(0, current_occupancy - 1) WHERE id = $1',
            [existing.room_id]
        );

        return NextResponse.json({
            success: true,
            data: result.rows[0],
            message: 'Allocation ended successfully (checkout)'
        });
    } catch (error) {
        console.error('Allocation detail API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
