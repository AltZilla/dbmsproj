/**
 * Students API Routes (App Router)
 * =================================
 * RESTful API for managing students/residents.
 * 
 * Endpoints:
 * - GET /api/students - List all students with pagination
 * - POST /api/students - Create a new student
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { PaginatedResponse, Student } from '@/lib/types';

/**
 * GET /api/students
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
        const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '10')));
        const offset = (page - 1) * limit;
        const search = searchParams.get('search');
        const gender = searchParams.get('gender');
        const active = searchParams.get('active');

        const conditions: string[] = [];
        const params: (string | number | boolean)[] = [];
        let paramIndex = 1;

        if (search) {
            conditions.push(`(
                first_name ILIKE $${paramIndex} OR 
                last_name ILIKE $${paramIndex} OR 
                registration_number ILIKE $${paramIndex} OR
                email ILIKE $${paramIndex}
            )`);
            params.push(`%${search}%`);
            paramIndex++;
        }

        if (gender && ['male', 'female', 'other'].includes(gender)) {
            conditions.push(`gender = $${paramIndex}`);
            params.push(gender);
            paramIndex++;
        }

        if (active === 'true' || active === 'false') {
            conditions.push(`is_active = $${paramIndex}`);
            params.push(active === 'true');
            paramIndex++;
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const countResult = await query<{ count: string }>(
            `SELECT COUNT(*) as count FROM students ${whereClause}`,
            params
        );
        const total = parseInt(countResult.rows[0].count);

        const dataResult = await query<Student>(
            `SELECT * FROM students 
             ${whereClause}
             ORDER BY created_at DESC, last_name, first_name
             LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
            [...params, limit, offset]
        );

        return NextResponse.json<PaginatedResponse<Student>>({
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
        console.error('Students API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * POST /api/students
 */
export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const {
            registration_number,
            first_name,
            last_name,
            email,
            phone,
            gender,
            date_of_birth,
            address,
            guardian_name,
            guardian_phone,
            department,
            year_of_study
        } = body;

        if (!registration_number || !first_name || !last_name || !email || !gender) {
            return NextResponse.json(
                { success: false, error: 'Missing required fields: registration_number, first_name, last_name, email, gender' },
                { status: 400 }
            );
        }

        if (!['male', 'female', 'other'].includes(gender)) {
            return NextResponse.json(
                { success: false, error: 'Invalid gender. Must be male, female, or other' },
                { status: 400 }
            );
        }

        const result = await query<Student>(
            `INSERT INTO students (
              registration_number, first_name, last_name, email, phone, gender,
              date_of_birth, address, guardian_name, guardian_phone, department, year_of_study
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING *`,
            [
                registration_number,
                first_name,
                last_name,
                email,
                phone || null,
                gender,
                date_of_birth || null,
                address || null,
                guardian_name || null,
                guardian_phone || null,
                department || null,
                year_of_study || null
            ]
        );

        return NextResponse.json(
            { success: true, data: result.rows[0], message: 'Student created successfully' },
            { status: 201 }
        );
    } catch (error) {
        console.error('Students API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
