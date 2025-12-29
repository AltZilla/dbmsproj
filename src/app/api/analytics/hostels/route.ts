/**
 * Analytics - Hostels API (App Router)
 * =====================================
 * Get hostel occupancy and complaint statistics.
 */

import { NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

interface HostelStats {
    hostel_id: number;
    hostel_name: string;
    total_rooms: string;
    total_capacity: string;
    total_occupancy: string;
    occupancy_rate: string;
    active_complaints: string;
    pending_payments: string;
    total_complaints: string;
    open_complaints: string;
    resolved_complaints: string;
}

/**
 * GET /api/analytics/hostels
 */
export async function GET() {
    try {
        const result = await query<HostelStats>(`
            SELECT 
                h.id as hostel_id,
                h.name as hostel_name,
                COUNT(DISTINCT r.id) as total_rooms,
                COALESCE(SUM(r.capacity), 0) as total_capacity,
                COALESCE(SUM(r.current_occupancy), 0) as total_occupancy,
                CASE 
                    WHEN SUM(r.capacity) > 0 
                    THEN ROUND((SUM(r.current_occupancy)::numeric / SUM(r.capacity)) * 100, 2)
                    ELSE 0 
                END as occupancy_rate,
                COALESCE((
                    SELECT COUNT(*) 
                    FROM complaints c 
                    INNER JOIN rooms cr ON c.room_id = cr.id 
                    WHERE cr.hostel_id = h.id
                ), 0) as total_complaints,
                COALESCE((
                    SELECT COUNT(*) 
                    FROM complaints c 
                    INNER JOIN rooms cr ON c.room_id = cr.id 
                    WHERE cr.hostel_id = h.id AND c.status IN ('open', 'assigned', 'in_progress')
                ), 0) as open_complaints,
                COALESCE((
                    SELECT COUNT(*) 
                    FROM complaints c 
                    INNER JOIN rooms cr ON c.room_id = cr.id 
                    WHERE cr.hostel_id = h.id AND c.status IN ('resolved', 'closed')
                ), 0) as resolved_complaints
            FROM hostels h
            LEFT JOIN rooms r ON r.hostel_id = h.id
            GROUP BY h.id, h.name
            ORDER BY h.name
        `);

        return NextResponse.json({
            success: true,
            data: result.rows.map(row => {
                const totalComplaints = parseInt(String(row.total_complaints));
                const totalRooms = parseInt(String(row.total_rooms));

                return {
                    hostel_name: row.hostel_name,
                    total_complaints: totalComplaints,
                    open_complaints: parseInt(String(row.open_complaints)),
                    resolved_complaints: parseInt(String(row.resolved_complaints)),
                    complaints_per_room: totalRooms > 0 ? parseFloat((totalComplaints / totalRooms).toFixed(2)) : 0
                };
            })
        });
    } catch (error) {
        console.error('Analytics hostels API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
