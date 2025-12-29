/**
 * Rooms API Routes (App Router)
 * ==============================
 * RESTful API for managing hostel rooms.
 * 
 * Endpoints:
 * - GET /api/rooms - List all rooms with hostel info
 * - POST /api/rooms - Create a new room
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { PaginatedResponse, Room } from '@/lib/types';

/**
 * GET /api/rooms
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
        const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20')));
        const offset = (page - 1) * limit;

        const hostelId = searchParams.get('hostel_id');
        const roomType = searchParams.get('room_type');
        const available = searchParams.get('available');
        const hasVacancy = searchParams.get('has_vacancy');

        const conditions: string[] = [];
        const params: (string | number | boolean)[] = [];
        let paramIndex = 1;

        if (hostelId) {
            conditions.push(`r.hostel_id = $${paramIndex++}`);
            params.push(parseInt(hostelId));
        }

        if (roomType && ['single', 'double', 'triple', 'dormitory'].includes(roomType)) {
            conditions.push(`r.room_type = $${paramIndex++}`);
            params.push(roomType);
        }

        if (available === 'true') {
            conditions.push(`r.is_available = TRUE`);
        } else if (available === 'false') {
            conditions.push(`r.is_available = FALSE`);
        }

        if (hasVacancy === 'true') {
            conditions.push(`r.current_occupancy < r.capacity`);
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const countResult = await query<{ count: string }>(
            `SELECT COUNT(*) as count 
             FROM rooms r 
             INNER JOIN hostels h ON r.hostel_id = h.id
             ${whereClause}`,
            params
        );
        const total = parseInt(countResult.rows[0].count);

        const dataResult = await query<Room>(
            `SELECT 
              r.*,
              h.name as hostel_name,
              h.gender_allowed,
              (r.capacity - r.current_occupancy) as available_beds
             FROM rooms r
             INNER JOIN hostels h ON r.hostel_id = h.id
             ${whereClause}
             ORDER BY h.name, r.room_number
             LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
            [...params, limit, offset]
        );

        return NextResponse.json<PaginatedResponse<Room>>({
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
        console.error('Rooms API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}

/**
 * POST /api/rooms
 */
export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const {
            hostel_id,
            room_number,
            floor,
            room_type,
            capacity,
            rent_amount,
            has_ac,
            has_attached_bathroom
        } = body;

        if (!hostel_id || !room_number || floor === undefined || !capacity || !rent_amount) {
            return NextResponse.json(
                { success: false, error: 'Missing required fields: hostel_id, room_number, floor, capacity, rent_amount' },
                { status: 400 }
            );
        }

        const hostelCheck = await query('SELECT id FROM hostels WHERE id = $1', [hostel_id]);
        if (hostelCheck.rows.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Hostel not found' },
                { status: 400 }
            );
        }

        const result = await query<Room>(
            `INSERT INTO rooms (
              hostel_id, room_number, floor, room_type, capacity,
              rent_amount, has_ac, has_attached_bathroom
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *`,
            [
                hostel_id,
                room_number,
                floor,
                room_type || 'double',
                capacity,
                rent_amount,
                has_ac || false,
                has_attached_bathroom || false
            ]
        );

        return NextResponse.json(
            { success: true, data: result.rows[0], message: 'Room created successfully' },
            { status: 201 }
        );
    } catch (error) {
        console.error('Rooms API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
