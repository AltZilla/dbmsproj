/**
 * Analytics - Trends API (App Router)
 * =====================================
 * Get complaint trends aggregated by month.
 */

import { NextRequest, NextResponse } from 'next/server';
import { getAnalyticsDateFilter, getAnalyticsRangeMeta } from '@/lib/analytics';
import { query } from '@/lib/db';
import { ApiResponse } from '@/lib/types';

interface MonthlyTrend {
    period_start: string;
    label: string;
    total_complaints: number;
    resolution_rate: number;
}

/**
 * GET /api/analytics/trends?months=6
 */
export async function GET(request: NextRequest) {
    try {
        const range = getAnalyticsRangeMeta(request.nextUrl.searchParams);
        const bucketExpression = `DATE_TRUNC('${range.bucket}', created_at)`;
        const labelExpression = range.bucket === 'day'
            ? `TO_CHAR(${bucketExpression}, 'Mon DD')`
            : range.bucket === 'week'
                ? `'Week of ' || TO_CHAR(${bucketExpression}, 'Mon DD')`
                : `TO_CHAR(${bucketExpression}, 'Mon YY')`;
        const dateFilter = getAnalyticsDateFilter('created_at', range.interval);

        const result = await query<{
            period_start: string;
            label: string;
            total_complaints: string;
            resolution_rate: string;
        }>(`
            SELECT 
                TO_CHAR(${bucketExpression}, 'YYYY-MM-DD') as period_start,
                ${labelExpression} as label,
                COUNT(*) as total_complaints,
                CASE 
                    WHEN COUNT(*) > 0 
                    THEN ROUND(COUNT(*) FILTER (WHERE status IN ('resolved', 'closed'))::numeric / COUNT(*) * 100, 2)
                    ELSE 0 
                END as resolution_rate
            FROM complaints
            WHERE ${dateFilter}
            GROUP BY ${bucketExpression}
            ORDER BY ${bucketExpression}
        `);

        return NextResponse.json<ApiResponse<MonthlyTrend[]>>({
            success: true,
            data: result.rows.map(row => ({
                period_start: row.period_start,
                label: row.label,
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
