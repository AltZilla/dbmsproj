/**
 * Analytics - Rooms API (App Router)
 * ====================================
 * Get room occupancy analytics.
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

interface RoomStats {
    total_rooms: number;
    total_capacity: number;
    total_occupancy: number;
    overall_occupancy_rate: number;
    rooms_full: number;
    rooms_empty: number;
    rooms_partial: number;
    by_type: {
        room_type: string;
        count: number;
        capacity: number;
        occupancy: number;
        rate: number;
    }[];
    by_floor: {
        floor: number;
        count: number;
        capacity: number;
        occupancy: number;
        rate: number;
    }[];
}

/**
 * GET /api/analytics/rooms
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const hostelId = searchParams.get('hostel_id');

        let hostelFilter = '';
        const params: number[] = [];

        if (hostelId) {
            hostelFilter = `WHERE r.hostel_id = $1`;
            params.push(parseInt(hostelId));
        }

        // Overall stats
        const overallResult = await query<{
            total_rooms: string;
            total_capacity: string;
            total_occupancy: string;
            rooms_full: string;
            rooms_empty: string;
            rooms_partial: string;
        }>(`
            SELECT 
                COUNT(*) as total_rooms,
                COALESCE(SUM(r.capacity), 0) as total_capacity,
                COALESCE(SUM(r.current_occupancy), 0) as total_occupancy,
                COUNT(*) FILTER (WHERE r.current_occupancy >= r.capacity) as rooms_full,
                COUNT(*) FILTER (WHERE r.current_occupancy = 0) as rooms_empty,
                COUNT(*) FILTER (WHERE r.current_occupancy > 0 AND r.current_occupancy < r.capacity) as rooms_partial
            FROM rooms r
            ${hostelFilter}
        `, params);

        // By room type
        const byTypeResult = await query<{
            room_type: string;
            count: string;
            capacity: string;
            occupancy: string;
        }>(`
            SELECT 
                r.room_type,
                COUNT(*) as count,
                SUM(r.capacity) as capacity,
                SUM(r.current_occupancy) as occupancy
            FROM rooms r
            ${hostelFilter}
            GROUP BY r.room_type
            ORDER BY count DESC
        `, params);

        // By floor
        const byFloorResult = await query<{
            floor: number;
            count: string;
            capacity: string;
            occupancy: string;
        }>(`
            SELECT 
                r.floor,
                COUNT(*) as count,
                SUM(r.capacity) as capacity,
                SUM(r.current_occupancy) as occupancy
            FROM rooms r
            ${hostelFilter}
            GROUP BY r.floor
            ORDER BY r.floor ASC
        `, params);

        const overall = overallResult.rows[0];
        const totalCapacity = parseInt(overall.total_capacity);
        const totalOccupancy = parseInt(overall.total_occupancy);

        return NextResponse.json<ApiResponse<RoomStats>>({
            success: true,
            data: {
                total_rooms: parseInt(overall.total_rooms),
                total_capacity: totalCapacity,
                total_occupancy: totalOccupancy,
                overall_occupancy_rate: totalCapacity > 0 ? Math.round((totalOccupancy / totalCapacity) * 100 * 100) / 100 : 0,
                rooms_full: parseInt(overall.rooms_full),
                rooms_empty: parseInt(overall.rooms_empty),
                rooms_partial: parseInt(overall.rooms_partial),
                by_type: byTypeResult.rows.map(row => {
                    const cap = parseInt(row.capacity);
                    const occ = parseInt(row.occupancy);
                    return {
                        room_type: row.room_type,
                        count: parseInt(row.count),
                        capacity: cap,
                        occupancy: occ,
                        rate: cap > 0 ? Math.round((occ / cap) * 100 * 100) / 100 : 0
                    };
                }),
                by_floor: byFloorResult.rows.map(row => {
                    const cap = parseInt(row.capacity);
                    const occ = parseInt(row.occupancy);
                    return {
                        floor: row.floor,
                        count: parseInt(row.count),
                        capacity: cap,
                        occupancy: occ,
                        rate: cap > 0 ? Math.round((occ / cap) * 100 * 100) / 100 : 0
                    };
                })
            }
        });
    } catch (error) {
        console.error('Analytics rooms API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
