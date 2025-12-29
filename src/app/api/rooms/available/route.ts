/**
 * Available Rooms API (App Router)
 * =================================
 * Fetches rooms that have available capacity for new allocations.
 * 
 * Uses the available_rooms VIEW defined in views.sql.
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

interface AvailableRoom {
    room_id: number;
    room_number: string;
    hostel_name: string;
    gender_allowed: string;
    floor: number;
    room_type: string;
    capacity: number;
    current_occupancy: number;
    available_beds: number;
    rent_amount: number;
    has_ac: boolean;
    has_attached_bathroom: boolean;
}

/**
 * GET /api/rooms/available
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const gender = searchParams.get('gender');
        const hostelId = searchParams.get('hostel_id');

        const conditions: string[] = [];
        const params: (string | number)[] = [];
        let paramIndex = 1;

        if (gender && ['male', 'female', 'other'].includes(gender)) {
            conditions.push(`gender_allowed = $${paramIndex++}`);
            params.push(gender);
        }

        if (hostelId) {
            conditions.push(`hostel_name = (SELECT name FROM hostels WHERE id = $${paramIndex++})`);
            params.push(parseInt(hostelId));
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const result = await query<AvailableRoom>(
            `SELECT * FROM available_rooms ${whereClause} ORDER BY hostel_name, room_number`,
            params
        );

        return NextResponse.json<ApiResponse<AvailableRoom[]>>({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Available rooms API error:', error);

        // If the view doesn't exist yet, fall back to direct query
        if ((error as { code?: string }).code === '42P01') {
            try {
                const result = await query<AvailableRoom>(`
                    SELECT 
                      r.id as room_id,
                      r.room_number,
                      h.name as hostel_name,
                      h.gender_allowed,
                      r.floor,
                      r.room_type,
                      r.capacity,
                      r.current_occupancy,
                      r.capacity - r.current_occupancy as available_beds,
                      r.rent_amount,
                      r.has_ac,
                      r.has_attached_bathroom
                    FROM rooms r
                    INNER JOIN hostels h ON r.hostel_id = h.id
                    WHERE r.is_available = TRUE
                      AND r.current_occupancy < r.capacity
                    ORDER BY h.name, r.room_number
                `);

                return NextResponse.json<ApiResponse<AvailableRoom[]>>({
                    success: true,
                    data: result.rows
                });
            } catch (fallbackError) {
                return NextResponse.json(
                    { success: false, error: fallbackError instanceof Error ? fallbackError.message : 'Internal server error' },
                    { status: 500 }
                );
            }
        }

        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
