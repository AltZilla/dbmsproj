/**
 * Analytics - Resolution API (App Router)
 * ========================================
 * Get complaint resolution time statistics.
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

interface ResolutionStats {
    total_complaints: number;
    resolved_complaints: number;
    avg_resolution_hours: number | null;
    min_resolution_hours: number | null;
    max_resolution_hours: number | null;
    by_category: {
        category: string;
        avg_hours: number | null;
        count: number;
    }[];
    by_priority: {
        priority: number;
        avg_hours: number | null;
        count: number;
    }[];
}

/**
 * GET /api/analytics/resolution
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const hostelId = searchParams.get('hostel_id');
        const days = parseInt(searchParams.get('days') || '30');

        let hostelFilter = '';
        const params: (string | number)[] = [days];

        if (hostelId) {
            hostelFilter = `AND r.hostel_id = $2`;
            params.push(parseInt(hostelId));
        }

        // Overall stats
        const overallResult = await query<{
            total_complaints: string;
            resolved_complaints: string;
            avg_resolution_hours: string | null;
            min_resolution_hours: string | null;
            max_resolution_hours: string | null;
        }>(`
            SELECT 
                COUNT(*) as total_complaints,
                COUNT(*) FILTER (WHERE c.status IN ('resolved', 'closed')) as resolved_complaints,
                AVG(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600) 
                    FILTER (WHERE c.resolved_at IS NOT NULL) as avg_resolution_hours,
                MIN(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600) 
                    FILTER (WHERE c.resolved_at IS NOT NULL) as min_resolution_hours,
                MAX(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600) 
                    FILTER (WHERE c.resolved_at IS NOT NULL) as max_resolution_hours
            FROM complaints c
            INNER JOIN rooms r ON c.room_id = r.id
            WHERE c.created_at >= CURRENT_DATE - INTERVAL '1 day' * $1
            ${hostelFilter}
        `, params);

        // By category
        const categoryResult = await query<{
            category: string;
            avg_hours: string | null;
            count: string;
        }>(`
            SELECT 
                c.category,
                AVG(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600) 
                    FILTER (WHERE c.resolved_at IS NOT NULL) as avg_hours,
                COUNT(*) FILTER (WHERE c.resolved_at IS NOT NULL) as count
            FROM complaints c
            INNER JOIN rooms r ON c.room_id = r.id
            WHERE c.created_at >= CURRENT_DATE - INTERVAL '1 day' * $1
            ${hostelFilter}
            GROUP BY c.category
            ORDER BY count DESC
        `, params);

        // By priority
        const priorityResult = await query<{
            priority: number;
            avg_hours: string | null;
            count: string;
        }>(`
            SELECT 
                c.priority,
                AVG(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600) 
                    FILTER (WHERE c.resolved_at IS NOT NULL) as avg_hours,
                COUNT(*) FILTER (WHERE c.resolved_at IS NOT NULL) as count
            FROM complaints c
            INNER JOIN rooms r ON c.room_id = r.id
            WHERE c.created_at >= CURRENT_DATE - INTERVAL '1 day' * $1
            ${hostelFilter}
            GROUP BY c.priority
            ORDER BY c.priority ASC
        `, params);

        const overall = overallResult.rows[0];
        const totalComplaints = parseInt(overall.total_complaints);
        const resolvedComplaints = parseInt(overall.resolved_complaints);

        return NextResponse.json({
            success: true,
            data: {
                overall: {
                    total_complaints: totalComplaints,
                    resolved_complaints: resolvedComplaints,
                    avg_resolution_hours: overall.avg_resolution_hours ? parseFloat(overall.avg_resolution_hours) : null,
                    avg_assignment_hours: null,
                    resolution_rate: totalComplaints > 0 ? Math.round((resolvedComplaints / totalComplaints) * 100) : 0,
                    sla_compliance_rate: 100
                },
                by_category: categoryResult.rows.map(row => ({
                    category: row.category,
                    resolved_count: parseInt(row.count),
                    avg_resolution_hours: row.avg_hours ? parseFloat(row.avg_hours) : null
                }))
            }
        });
    } catch (error) {
        console.error('Analytics resolution API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
