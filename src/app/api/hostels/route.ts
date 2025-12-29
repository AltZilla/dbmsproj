/**
 * Hostels API Routes (App Router)
 * ================================
 * RESTful API for managing hostels.
 * 
 * Endpoints:
 * - GET /api/hostels - List all hostels
 * - POST /api/hostels - Create a new hostel
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse, Hostel } from '@/lib/types';

/**
 * GET /api/hostels
 */
export async function GET() {
    try {
        const result = await query<Hostel>(
            `SELECT * FROM hostels ORDER BY name`
        );

        return NextResponse.json<ApiResponse<Hostel[]>>({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Hostels API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * POST /api/hostels
 */
export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { name, address, gender_allowed, warden_name, warden_contact } = body;

        if (!name || !gender_allowed) {
            return NextResponse.json(
                { success: false, error: 'Missing required fields: name, gender_allowed' },
                { status: 400 }
            );
        }

        if (!['male', 'female', 'other'].includes(gender_allowed)) {
            return NextResponse.json(
                { success: false, error: 'Invalid gender_allowed. Must be male, female, or other' },
                { status: 400 }
            );
        }

        const result = await query<Hostel>(
            `INSERT INTO hostels (name, address, gender_allowed, warden_name, warden_contact)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [name, address || null, gender_allowed, warden_name || null, warden_contact || null]
        );

        return NextResponse.json(
            { success: true, data: result.rows[0], message: 'Hostel created successfully' },
            { status: 201 }
        );
    } catch (error) {
        console.error('Hostels API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
