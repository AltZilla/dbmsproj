/**
 * Student Payments API Route (App Router)
 * ========================================
 * Get payment history for a specific student.
 * 
 * Endpoint: GET /api/payments/student/[id]
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse, Payment } from '@/lib/types';

interface PaymentSummary {
    payments: Payment[];
    summary: {
        total_paid: number;
        total_pending: number;
        total_overdue: number;
        payment_count: number;
    };
}

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/payments/student/[id]
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

        // Verify student exists
        const studentCheck = await query(
            'SELECT id FROM students WHERE id = $1',
            [studentId]
        );
        if (studentCheck.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Student not found' },
                { status: 404 }
            );
        }

        // Get all payments for this student
        const paymentsResult = await query<Payment>(
            `SELECT 
                p.*,
                CURRENT_DATE - p.due_date as days_overdue
             FROM payments p
             WHERE p.student_id = $1
             ORDER BY p.due_date DESC`,
            [studentId]
        );

        // Calculate payment summary
        const summaryResult = await query<{
            total_paid: string;
            total_pending: string;
            total_overdue: string;
            payment_count: string;
        }>(
            `SELECT 
                COALESCE(SUM(amount) FILTER (WHERE payment_status = 'paid'), 0) as total_paid,
                COALESCE(SUM(amount) FILTER (WHERE payment_status = 'pending'), 0) as total_pending,
                COALESCE(SUM(amount) FILTER (WHERE payment_status = 'overdue'), 0) as total_overdue,
                COUNT(*) as payment_count
             FROM payments
             WHERE student_id = $1`,
            [studentId]
        );

        const summary = summaryResult.rows[0];

        return NextResponse.json<ApiResponse<PaymentSummary>>({
            success: true,
            data: {
                payments: paymentsResult.rows,
                summary: {
                    total_paid: parseFloat(summary.total_paid),
                    total_pending: parseFloat(summary.total_pending),
                    total_overdue: parseFloat(summary.total_overdue),
                    payment_count: parseInt(summary.payment_count)
                }
            }
        });
    } catch (error) {
        console.error('Student payments API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
