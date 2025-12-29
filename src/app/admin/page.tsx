'use client';

/**
 * Admin Dashboard
 * ================
 * Main admin portal page with system overview and quick actions.
 */

import { useEffect, useState } from 'react';
import Link from 'next/link';
// import styles from './page.module.css';

interface DashboardStats {
    totalStudents: number;
    totalRooms: number;
    occupiedBeds: number;
    totalCapacity: number;
    openComplaints: number;
    pendingPayments: number;
}

export default function AdminDashboard() {
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchStats() {
            try {
                // Fetch various stats in parallel
                const [studentsRes, roomsRes, complaintsRes, paymentsRes] = await Promise.all([
                    fetch('/api/students?limit=1'),
                    fetch('/api/rooms?limit=1'),
                    fetch('/api/complaints?status=open&limit=1'),
                    fetch('/api/payments?status=pending&limit=1')
                ]);

                const students = await studentsRes.json();
                const rooms = await roomsRes.json();
                const complaints = await complaintsRes.json();
                const payments = await paymentsRes.json();

                setStats({
                    totalStudents: students.pagination?.total || 0,
                    totalRooms: rooms.pagination?.total || 0,
                    occupiedBeds: 0, // Would come from a dedicated endpoint
                    totalCapacity: 0,
                    openComplaints: complaints.pagination?.total || 0,
                    pendingPayments: payments.pagination?.total || 0
                });
            } catch (error) {
                console.error('Failed to fetch stats:', error);
            } finally {
                setLoading(false);
            }
        }

        fetchStats();
    }, []);

    const menuItems = [
        { href: '/admin/students', icon: '👥', title: 'Students', description: 'Add and manage students' },
        { href: '/admin/rooms', icon: '🏠', title: 'Rooms', description: 'Manage room inventory' },
        { href: '/admin/allocations', icon: '🔑', title: 'Allocations', description: 'Room assignments' },
        { href: '/admin/complaints', icon: '🔧', title: 'Complaints', description: 'Maintenance requests' },
        { href: '/admin/payments', icon: '💳', title: 'Payments', description: 'Fee tracking' },
        { href: '/admin/analytics', icon: '📊', title: 'Analytics', description: 'Reports & insights' }
    ];

    return (
        <div className="max-w-7xl mx-auto px-6 py-8">
            <div className="flex flex-col gap-1 mb-8">
                <h1 className="text-3xl font-bold text-indigo-950">Admin Dashboard</h1>
                <p className="text-gray-500">Manage hostel operations and view system overview</p>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
                <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 flex flex-col items-start relative overflow-hidden">
                    <div className="text-3xl font-bold text-gray-900 leading-none mb-2 z-10">{loading ? '...' : stats?.totalStudents}</div>
                    <div className="text-sm font-medium text-gray-500 z-10">Total Students</div>
                    <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">👥</div>
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 to-indigo-500"></div>
                </div>
                <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 flex flex-col items-start relative overflow-hidden">
                    <div className="text-3xl font-bold text-gray-900 leading-none mb-2 z-10">{loading ? '...' : stats?.totalRooms}</div>
                    <div className="text-sm font-medium text-gray-500 z-10">Total Rooms</div>
                    <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">🏠</div>
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-indigo-500 to-purple-500"></div>
                </div>
                <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 flex flex-col items-start relative overflow-hidden">
                    <div className="text-3xl font-bold text-gray-900 leading-none mb-2 z-10 text-amber-600">{loading ? '...' : stats?.openComplaints}</div>
                    <div className="text-sm font-medium text-gray-500 z-10">Open Complaints</div>
                    <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">⚠️</div>
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-amber-400 to-orange-500"></div>
                </div>
                <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 flex flex-col items-start relative overflow-hidden">
                    <div className="text-3xl font-bold text-gray-900 leading-none mb-2 z-10 text-red-600">{loading ? '...' : stats?.pendingPayments}</div>
                    <div className="text-sm font-medium text-gray-500 z-10">Pending Payments</div>
                    <div className="absolute top-0 right-0 p-4 opacity-5 text-4xl">💳</div>
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-red-400 to-rose-500"></div>
                </div>
            </div>

            {/* Quick Actions */}
            <h2 className="text-xl font-semibold text-gray-800 mb-6">Quick Actions</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-12">
                {menuItems.map((item) => (
                    <Link key={item.href} href={item.href} className="flex items-center gap-4 p-5 bg-white rounded-xl shadow-sm border border-gray-200 hover:-translate-y-1 hover:shadow-md hover:border-indigo-200 transition-all group">
                        <span className="text-2xl opacity-80 group-hover:scale-110 transition-transform">{item.icon}</span>
                        <div>
                            <h3 className="font-semibold text-gray-900 group-hover:text-indigo-700 transition-colors">{item.title}</h3>
                            <p className="text-sm text-gray-500">{item.description}</p>
                        </div>
                    </Link>
                ))}
            </div>

            {/* Info Section */}
            <div className="bg-gradient-to-br from-indigo-50 to-purple-50 rounded-2xl p-8 border border-indigo-100">
                <h3 className="text-lg font-semibold text-indigo-900 mb-2">🗄️ Database Information</h3>
                <p className="text-gray-600 text-sm mb-4 leading-relaxed">
                    This system uses PostgreSQL with normalized tables, triggers for data integrity,
                    and SQL views for analytics. All queries are parameterized to prevent SQL injection.
                </p>
                <div className="flex flex-wrap gap-2">
                    {['8 Tables', '4 Triggers', '9 Views', '15+ API Endpoints'].map((tag) => (
                        <span key={tag} className="px-3 py-1 bg-white text-indigo-600 text-xs font-medium rounded-full border border-indigo-200 shadow-sm">
                            {tag}
                        </span>
                    ))}
                </div>
            </div>
        </div>
    );
}

