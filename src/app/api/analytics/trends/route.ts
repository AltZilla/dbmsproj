/**
 * Analytics - Trends API (App Router)
 * =====================================
 * Get complaint trends aggregated by month.
 */

import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

interface MonthlyTrend {
    month: string;
    total_complaints: number;
    resolution_rate: number;
}

/**
 * GET /api/analytics/trends?months=6
 */
export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const months = parseInt(searchParams.get('months') || '6');

        const result = await query<{
            month: string;
            total_complaints: string;
            resolution_rate: string;
        }>(`
            SELECT 
                TO_CHAR(DATE_TRUNC('month', created_at), 'YYYY-MM-01') as month,
                COUNT(*) as total_complaints,
                CASE 
                    WHEN COUNT(*) > 0 
                    THEN ROUND(COUNT(*) FILTER (WHERE status IN ('resolved', 'closed'))::numeric / COUNT(*) * 100, 2)
                    ELSE 0 
                END as resolution_rate
            FROM complaints
            WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month' * $1)
            GROUP BY DATE_TRUNC('month', created_at)
            ORDER BY DATE_TRUNC('month', created_at)
        `, [months]);

        return NextResponse.json<ApiResponse<MonthlyTrend[]>>({
            success: true,
            data: result.rows.map(row => ({
                month: row.month,
                total_complaints: parseInt(row.total_complaints),
                resolution_rate: parseFloat(row.resolution_rate)
            }))
        });
    } catch (error) {
        console.error('Analytics trends API error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Internal server error' },
            { status: 500 }
        );
    }
}
