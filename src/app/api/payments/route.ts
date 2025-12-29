/**
 * Payments API Routes (App Router)
 * =================================
 * RESTful API for managing fee payments.
 * 
 * Endpoints:
 * - GET /api/payments - List all payments
 * - POST /api/payments - Record a new payment
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { PaginatedResponse, Payment } from '@/lib/types';

/**
 * GET /api/payments
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
        const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20')));
        const offset = (page - 1) * limit;

        const studentId = searchParams.get('student_id');
        const status = searchParams.get('status');
        const semester = searchParams.get('semester');
        const overdue = searchParams.get('overdue');

        const conditions: string[] = [];
        const params: (string | number)[] = [];
        let paramIndex = 1;

        if (studentId) {
            conditions.push(`p.student_id = $${paramIndex++}`);
            params.push(parseInt(studentId));
        }

        if (status && ['pending', 'paid', 'overdue', 'partial'].includes(status)) {
            conditions.push(`p.payment_status = $${paramIndex++}`);
            params.push(status);
        }

        if (semester) {
            conditions.push(`p.semester = $${paramIndex++}`);
            params.push(semester);
        }

        if (overdue === 'true') {
            conditions.push(`p.due_date < CURRENT_DATE AND p.payment_status IN ('pending', 'overdue')`);
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const countResult = await query<{ count: string }>(
            `SELECT COUNT(*) as count FROM payments p ${whereClause}`,
            params
        );
        const total = parseInt(countResult.rows[0].count);

        const dataResult = await query<Payment>(
            `SELECT 
              p.*,
              s.first_name || ' ' || s.last_name as student_name,
              s.registration_number,
              s.email as student_email,
              CURRENT_DATE - p.due_date as days_overdue
             FROM payments p
             INNER JOIN students s ON p.student_id = s.id
             ${whereClause}
             ORDER BY 
               CASE p.payment_status 
                 WHEN 'overdue' THEN 1 
                 WHEN 'pending' THEN 2 
                 WHEN 'partial' THEN 3 
                 ELSE 4 
               END,
               p.due_date ASC
             LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
            [...params, limit, offset]
        );

        return NextResponse.json<PaginatedResponse<Payment>>({
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
        console.error('Payments API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * POST /api/payments
 */
export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const {
            student_id,
            allocation_id,
            amount,
            due_date,
            payment_date,
            payment_status,
            payment_method,
            transaction_id,
            receipt_number,
            semester,
            notes
        } = body;

        if (!student_id || !amount || !due_date) {
            return NextResponse.json(
                { success: false, error: 'Missing required fields: student_id, amount, due_date' },
                { status: 400 }
            );
        }

        if (amount <= 0) {
            return NextResponse.json(
                { success: false, error: 'Amount must be greater than 0' },
                { status: 400 }
            );
        }

        const studentCheck = await query(
            'SELECT id FROM students WHERE id = $1',
            [student_id]
        );
        if (studentCheck.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Student not found' },
                { status: 400 }
            );
        }

        let finalStatus = payment_status || 'pending';
        if (payment_date && !payment_status) {
            finalStatus = 'paid';
        }

        let finalReceiptNumber = receipt_number;
        if (finalStatus === 'paid' && !receipt_number) {
            const year = new Date().getFullYear();
            const countResult = await query<{ count: string }>(
                `SELECT COUNT(*) as count FROM payments WHERE EXTRACT(YEAR FROM created_at) = $1`,
                [year]
            );
            const count = parseInt(countResult.rows[0].count) + 1;
            finalReceiptNumber = `RCP-${year}-${count.toString().padStart(4, '0')}`;
        }

        const result = await query<Payment>(
            `INSERT INTO payments (
              student_id, allocation_id, amount, due_date, payment_date,
              payment_status, payment_method, transaction_id, receipt_number,
              semester, notes
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING *`,
            [
                student_id,
                allocation_id || null,
                amount,
                due_date,
                payment_date || null,
                finalStatus,
                payment_method || null,
                transaction_id || null,
                finalReceiptNumber || null,
                semester || null,
                notes || null
            ]
        );

        return NextResponse.json(
            { success: true, data: result.rows[0], message: 'Payment recorded successfully' },
            { status: 201 }
        );
    } catch (error) {
        console.error('Payments API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
