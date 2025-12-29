/**
 * Payment Update API
 * ====================
 * PUT /api/payments/[id] - Update a payment record (e.g., mark as paid)
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';

export async function PUT(
    request: NextRequest,
    context: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await context.params;
        const paymentId = parseInt(id);

        if (isNaN(paymentId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid payment ID' },
                { status: 400 }
            );
        }

        const body = await request.json();
        const { payment_status, payment_date, receipt_number } = body;

        // Build update query dynamically based on provided fields
        const updates: string[] = [];
        const values: (string | number)[] = [];
        let paramIndex = 1;

        if (payment_status) {
            updates.push(`payment_status = $${paramIndex++}`);
            values.push(payment_status);
        }

        if (payment_date) {
            updates.push(`payment_date = $${paramIndex++}`);
            values.push(payment_date);
        }

        if (receipt_number) {
            updates.push(`receipt_number = $${paramIndex++}`);
            values.push(receipt_number);
        }

        if (updates.length === 0) {
            return NextResponse.json(
                { success: false, error: 'No fields to update' },
                { status: 400 }
            );
        }

        // Add updated_at timestamp
        updates.push(`updated_at = NOW()`);

        // Add the payment ID as the last parameter
        values.push(paymentId);

        const updateQuery = `
            UPDATE payments 
            SET ${updates.join(', ')}
            WHERE id = $${paramIndex}
            RETURNING *
        `;

        const result = await query(updateQuery, values);

        if (result.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Payment not found' },
                { status: 404 }
            );
        }

        return NextResponse.json({
            success: true,
            data: result.rows[0],
            message: 'Payment updated successfully'
        });

    } catch (error) {
        console.error('Payment update error:', error);
        return NextResponse.json(
            { success: false, error: 'Failed to update payment' },
            { status: 500 }
        );
    }
}

export async function GET(
    request: NextRequest,
    context: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await context.params;
        const paymentId = parseInt(id);

        if (isNaN(paymentId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid payment ID' },
                { status: 400 }
            );
        }

        const result = await query(
            `SELECT p.*, s.first_name, s.last_name, s.registration_number
             FROM payments p
             JOIN students s ON p.student_id = s.id
             WHERE p.id = $1`,
            [paymentId]
        );

        if (result.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Payment not found' },
                { status: 404 }
            );
        }

        return NextResponse.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Payment fetch error:', error);
        return NextResponse.json(
            { success: false, error: 'Failed to fetch payment' },
            { status: 500 }
        );
    }
}
