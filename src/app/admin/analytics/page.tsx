'use client';

/**
 * Analytics Dashboard
 * ====================
 * Comprehensive analytics page with charts showing:
 * - Complaint category breakdown
 * - Hostel-wise complaint count
 * - Resolution time metrics
 * - Monthly trends
 * 
 * Uses Recharts library for data visualization.
 */

import { useEffect, useState } from 'react';
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
    PieChart, Pie, Cell, LineChart, Line
} from 'recharts';

// Color palette for charts
const COLORS = ['#6366f1', '#8b5cf6', '#a855f7', '#d946ef', '#ec4899', '#f43f5e', '#f97316', '#eab308'];

interface CategoryStats {
    category: string;
    total_complaints: number;
    percentage: number;
    open_count: number;
    resolved_count: number;
    [key: string]: string | number;
}

interface HostelStats {
    hostel_name: string;
    total_complaints: number;
    open_complaints: number;
    resolved_complaints: number;
    complaints_per_room: number;
    [key: string]: string | number;
}

interface ResolutionStats {
    overall: {
        total_complaints: number;
        resolved_complaints: number;
        avg_resolution_hours: number | null;
        resolution_rate: number;
        sla_compliance_rate: number;
    };
    by_category: Array<{
        category: string;
        resolved_count: number;
        avg_resolution_hours: number | null;
    }>;
}

interface MonthlyTrend {
    month: string;
    total_complaints: number;
    resolution_rate: number;
}

export default function AnalyticsPage() {
    const [categoryStats, setCategoryStats] = useState<CategoryStats[]>([]);
    const [hostelStats, setHostelStats] = useState<HostelStats[]>([]);
    const [resolutionStats, setResolutionStats] = useState<ResolutionStats | null>(null);
    const [monthlyTrends, setMonthlyTrends] = useState<MonthlyTrend[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchAnalytics() {
            try {
                const [catRes, hostelRes, resRes, trendRes] = await Promise.all([
                    fetch('/api/analytics/categories'),
                    fetch('/api/analytics/hostels'),
                    fetch('/api/analytics/resolution'),
                    fetch('/api/analytics/trends?months=6')
                ]);

                const catData = await catRes.json();
                const hostelData = await hostelRes.json();
                const resData = await resRes.json();
                const trendData = await trendRes.json();

                if (catData.success && catData.data) setCategoryStats(catData.data);

                if (hostelData.success && hostelData.data) setHostelStats(hostelData.data);
                if (resData.success && resData.data) setResolutionStats(resData.data);
                if (trendData.success && Array.isArray(trendData.data)) {
                    // Format month labels
                    const formatted = trendData.data.map((item: MonthlyTrend & { month: string }) => ({
                        ...item,
                        month: new Date(item.month).toLocaleDateString('en-US', { month: 'short', year: '2-digit' })
                    }));
                    setMonthlyTrends(formatted);
                }
            } catch (error) {
                console.error('Failed to fetch analytics:', error);
            } finally {
                setLoading(false);
            }
        }

        fetchAnalytics();
    }, []);

    function formatCategory(cat: string) {
        return cat.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
    }

    if (loading) {
        return (
            <div className="max-w-7xl mx-auto px-6 py-8">
                <div className="min-h-[400px] flex items-center justify-center">
                    <div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div>
                </div>
            </div>
        );
    }

    return (
        <div className="max-w-7xl mx-auto px-6 py-8">
            <div className="mb-8">
                <h1 className="text-3xl font-bold text-indigo-950 mb-1">Maintenance Analytics</h1>
                <p className="text-gray-500">Insights and reports on hostel maintenance operations</p>
            </div>

            {/* Summary Stats */}
            {resolutionStats && resolutionStats.overall && (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 relative overflow-hidden">
                        <div className="text-3xl font-bold text-gray-900 leading-none mb-2">{resolutionStats.overall.total_complaints || 0}</div>
                        <div className="text-sm font-medium text-gray-500">Total Complaints</div>
                        <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">📄</div>
                        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 to-indigo-500"></div>
                    </div>
                    <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 relative overflow-hidden">
                        <div className="text-3xl font-bold text-green-600 leading-none mb-2">{resolutionStats.overall.resolution_rate || 0}%</div>
                        <div className="text-sm font-medium text-gray-500">Resolution Rate</div>
                        <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">✅</div>
                        <div className="absolute top-0 left-0 w-full h-1 bg-green-500"></div>
                    </div>
                    <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 relative overflow-hidden">
                        <div className="text-3xl font-bold text-gray-900 leading-none mb-2">
                            {resolutionStats.overall.avg_resolution_hours
                                ? `${resolutionStats.overall.avg_resolution_hours.toFixed(1)}h`
                                : 'N/A'}
                        </div>
                        <div className="text-sm font-medium text-gray-500">Avg Resolution Time</div>
                        <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">⏱️</div>
                        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-violet-500 to-purple-500"></div>
                    </div>
                    <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 relative overflow-hidden">
                        <div className="text-3xl font-bold text-indigo-600 leading-none mb-2">{resolutionStats.overall.sla_compliance_rate || 0}%</div>
                        <div className="text-sm font-medium text-gray-500">SLA Compliance</div>
                        <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">🎯</div>
                        <div className="absolute top-0 left-0 w-full h-1 bg-indigo-500"></div>
                    </div>
                </div>
            )}

            {/* Charts Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
                {/* Category Pie Chart */}
                <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col">
                    <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50">
                        <div>
                            <div className="font-semibold text-gray-900">Complaints by Category</div>
                            <div className="text-xs text-gray-500">Distribution of complaint types</div>
                        </div>
                    </div>
                    <div className="min-h-[300px] flex items-center justify-center p-4">
                        {categoryStats.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <PieChart>
                                    <Pie
                                        data={categoryStats}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={50}
                                        outerRadius={90}
                                        paddingAngle={2}
                                        dataKey="total_complaints"
                                        nameKey="category"
                                        fill="#6366f1"
                                        // eslint-disable-next-line @typescript-eslint/no-explicit-any
                                        label={(props: any) => `${formatCategory(props.category)} (${props.percentage}%)`}

                                    >
                                        {categoryStats.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                        ))}
                                    </Pie>
                                    <Tooltip
                                        // eslint-disable-next-line @typescript-eslint/no-explicit-any
                                        formatter={(value: any) => [String(value), 'Complaints']}
                                        labelFormatter={(label) => formatCategory(String(label))}
                                    />
                                    <Legend formatter={(value) => formatCategory(value)} />
                                </PieChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="text-gray-400">No data available</div>
                        )}
                    </div>

                </div>

                {/* Hostel Bar Chart */}
                <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col">
                    <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50">
                        <div>
                            <div className="font-semibold text-gray-900">Complaints by Hostel</div>
                            <div className="text-xs text-gray-500">Hostel-wise complaint comparison</div>
                        </div>
                    </div>
                    <div className="min-h-[300px] flex items-center justify-center p-4">
                        {hostelStats.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart data={hostelStats} layout="vertical">
                                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                                    <XAxis type="number" />
                                    <YAxis dataKey="hostel_name" type="category" width={100} tick={{ fontSize: 12 }} />
                                    <Tooltip />
                                    <Legend />
                                    <Bar dataKey="open_complaints" name="Open" fill="#f59e0b" stackId="a" />
                                    <Bar dataKey="resolved_complaints" name="Resolved" fill="#22c55e" stackId="a" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="text-gray-400">No data available</div>
                        )}
                    </div>
                </div>

                {/* Monthly Trend Line Chart */}
                <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col">
                    <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50">
                        <div>
                            <div className="font-semibold text-gray-900">Monthly Trend</div>
                            <div className="text-xs text-gray-500">Complaints over time</div>
                        </div>
                    </div>
                    <div className="min-h-[300px] flex items-center justify-center p-4">
                        {monthlyTrends.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <LineChart data={monthlyTrends}>
                                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                                    <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                                    <YAxis yAxisId="left" />
                                    <YAxis yAxisId="right" orientation="right" domain={[0, 100]} />
                                    <Tooltip />
                                    <Legend />
                                    <Line
                                        yAxisId="left"
                                        type="monotone"
                                        dataKey="total_complaints"
                                        name="Complaints"
                                        stroke="#6366f1"
                                        strokeWidth={2}
                                        dot={{ fill: '#6366f1' }}
                                    />
                                    <Line
                                        yAxisId="right"
                                        type="monotone"
                                        dataKey="resolution_rate"
                                        name="Resolution %"
                                        stroke="#22c55e"
                                        strokeWidth={2}
                                        dot={{ fill: '#22c55e' }}
                                    />
                                </LineChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="text-gray-400">No data available</div>
                        )}
                    </div>
                </div>

                {/* Resolution Time by Category */}
                <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col">
                    <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50">
                        <div>
                            <div className="font-semibold text-gray-900">Resolution Time by Category</div>
                            <div className="text-xs text-gray-500">Average hours to resolve</div>
                        </div>
                    </div>
                    <div className="min-h-[300px] flex items-center justify-center p-4">
                        {resolutionStats && resolutionStats.by_category && resolutionStats.by_category.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart
                                    data={resolutionStats.by_category.filter(c => c.avg_resolution_hours !== null)}
                                >
                                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                                    <XAxis
                                        dataKey="category"
                                        tick={{ fontSize: 11 }}
                                        // eslint-disable-next-line @typescript-eslint/no-explicit-any
                                        tickFormatter={(value: any) => formatCategory(value).substring(0, 8)}
                                    />
                                    <YAxis label={{ value: 'Hours', angle: -90, position: 'insideLeft' }} />
                                    <Tooltip
                                        // eslint-disable-next-line @typescript-eslint/no-explicit-any
                                        formatter={(value: any) => [`${Number(value).toFixed(1)} hours`, 'Avg Time']}
                                        labelFormatter={(label) => formatCategory(String(label))}
                                    />
                                    <Bar
                                        dataKey="avg_resolution_hours"
                                        name="Avg Resolution Time"
                                        fill="#8b5cf6"
                                        radius={[4, 4, 0, 0]}
                                    />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="text-gray-400">No resolution data available</div>
                        )}
                    </div>
                </div>
            </div>

            {/* Category Details Table */}
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50">
                    <div>
                        <div className="font-semibold text-gray-900">Category Breakdown</div>
                        <div className="text-xs text-gray-500">Detailed statistics by complaint category</div>
                    </div>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-gray-50/50 border-b border-gray-200 text-xs uppercase text-gray-500 font-medium">
                                <th className="px-6 py-3">Category</th>
                                <th className="px-6 py-3">Total</th>
                                <th className="px-6 py-3">Open</th>
                                <th className="px-6 py-3">Resolved</th>
                                <th className="px-6 py-3">% of Total</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {categoryStats.map((cat) => (
                                <tr key={cat.category} className="hover:bg-gray-50/50 transition-colors text-sm text-gray-900">
                                    <td className="px-6 py-3 capitalize font-medium">{cat.category.replace('_', ' ')}</td>
                                    <td className="px-6 py-3 font-bold">{cat.total_complaints}</td>
                                    <td className="px-6 py-3">
                                        <span className="px-2 py-1 bg-amber-50 text-amber-700 rounded-lg text-xs font-semibold">{cat.open_count}</span>
                                    </td>
                                    <td className="px-6 py-3">
                                        <span className="px-2 py-1 bg-green-50 text-green-700 rounded-lg text-xs font-semibold">{cat.resolved_count}</span>
                                    </td>
                                    <td className="px-6 py-3 text-gray-500">{cat.percentage}%</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

