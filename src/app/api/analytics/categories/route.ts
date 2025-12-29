/**
 * Analytics - Categories API (App Router)
 * ========================================
 * Get complaint statistics by category.
 */

import { NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

interface CategoryStats {
    category: string;
    total_complaints: number;
    open_count: number;
    resolved_count: number;
    percentage: number;
    avg_resolution_hours: number | null;
}

/**
 * GET /api/analytics/categories
 */
export async function GET() {
    try {
        const result = await query(`
            SELECT 
                category,
                COUNT(*) as total_complaints,
                COUNT(*) FILTER (WHERE status IN ('open', 'assigned', 'in_progress')) as open_count,
                COUNT(*) FILTER (WHERE status IN ('resolved', 'closed')) as resolved_count,
                AVG(
                    EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
                ) FILTER (WHERE resolved_at IS NOT NULL) as avg_resolution_hours
            FROM complaints
            GROUP BY category
            ORDER BY total_complaints DESC
        `);

        // Calculate total for percentage
        const totalComplaints = result.rows.reduce((sum, row) => sum + parseInt(String(row.total_complaints)), 0);

        return NextResponse.json<ApiResponse<CategoryStats[]>>({
            success: true,
            data: result.rows.map(row => {
                const total = parseInt(String(row.total_complaints));
                return {
                    category: row.category,
                    total_complaints: total,
                    open_count: parseInt(String(row.open_count)),
                    resolved_count: parseInt(String(row.resolved_count)),
                    percentage: totalComplaints > 0 ? Math.round((total / totalComplaints) * 100) : 0,
                    avg_resolution_hours: row.avg_resolution_hours ? parseFloat(String(row.avg_resolution_hours)) : null
                };
            })
        });
    } catch (error) {
        console.error('Analytics categories API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
