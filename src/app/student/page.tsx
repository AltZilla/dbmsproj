'use client';

/**
 * Student Portal Dashboard
 * =========================
 * Main student portal page showing room, payments, and complaints overview.
 * Uses a demo student for demonstration purposes.
 */

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface StudentData {
    id: number;
    registration_number: string;
    full_name: string;
    email: string;
    room_number: string | null;
    hostel_name: string | null;
    total_paid: number;
    total_pending: number;
    active_complaints: number;
}

function StudentPortalContent() {
    const searchParams = useSearchParams();
    const urlId = searchParams.get('id');

    const [student, setStudent] = useState<StudentData | null>(null);
    const [loading, setLoading] = useState(true);
    const [selectedStudentId, setSelectedStudentId] = useState<number>(urlId ? parseInt(urlId) : 1);
    const [students, setStudents] = useState<Array<{ id: number; name: string }>>([]);

    useEffect(() => {
        // Fetch list of students for demo selection
        async function fetchStudents() {
            try {
                const res = await fetch('/api/students?limit=50');
                const data = await res.json();
                if (data.success && data.data.length > 0) {
                    setStudents(data.data.map((s: { id: number; first_name: string; last_name: string }) => ({
                        id: s.id,
                        name: `${s.first_name} ${s.last_name}`
                    })));

                    // Only auto-select first student if no ID in URL
                    if (!urlId) {
                        setSelectedStudentId(data.data[0].id);
                    }
                }
            } catch (error) {
                console.error('Failed to fetch students:', error);
            }
        }
        fetchStudents();
    }, [urlId]);

    useEffect(() => {
        async function fetchStudentData() {
            if (!selectedStudentId) return;

            setLoading(true);
            try {
                const res = await fetch(`/api/students/${selectedStudentId}`);
                const data = await res.json();

                if (data.success) {
                    setStudent({
                        id: data.data.id,
                        registration_number: data.data.registration_number,
                        full_name: `${data.data.first_name} ${data.data.last_name}`,
                        email: data.data.email,
                        room_number: data.data.room_number,
                        hostel_name: data.data.hostel_name,
                        total_paid: parseFloat(data.data.total_paid) || 0,
                        total_pending: parseFloat(data.data.total_pending) || 0,
                        active_complaints: parseInt(data.data.active_complaints) || 0
                    });
                }
            } catch (error) {
                console.error('Failed to fetch student data:', error);
            } finally {
                setLoading(false);
            }
        }

        fetchStudentData();
    }, [selectedStudentId]);

    if (loading && !student) {
        return (
            <div className="max-w-6xl mx-auto px-6 py-8">
                <div className="min-h-[200px] flex items-center justify-center">
                    <div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div>
                </div>
            </div>
        );
    }

    return (
        <div className="max-w-6xl mx-auto px-6 py-8">
            {/* Demo Mode Selector */}
            <div className="flex items-center gap-3 p-4 bg-amber-50 rounded-xl border border-amber-200 mb-8 w-fit text-sm text-amber-900 font-medium">
                <span className="text-lg">👤</span>
                <span>Viewing as:</span>
                <select
                    className="p-2 bg-white border border-amber-300 rounded-lg outline-none focus:ring-2 focus:ring-amber-400"
                    value={selectedStudentId}
                    onChange={(e) => setSelectedStudentId(parseInt(e.target.value))}
                >
                    {students.map((s) => (
                        <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                </select>
            </div>

            {student && (
                <>
                    {/* Welcome Header */}
                    <div className="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-2xl p-8 mb-8 text-white flex flex-col md:flex-row justify-between md:items-center gap-6 shadow-lg shadow-indigo-500/20">
                        <div>
                            <h1 className="text-3xl font-bold mb-2">Welcome back, {student.full_name.split(' ')[0]}!</h1>
                            <p className="text-blue-100 opacity-90">
                                {student.registration_number} • {student.email}
                            </p>
                        </div>
                        <div className="text-left md:text-right bg-white/10 p-4 rounded-xl backdrop-blur-sm border border-white/10">
                            {student.room_number ? (
                                <>
                                    <span className="block text-3xl font-bold">{student.room_number}</span>
                                    <span className="block text-sm text-indigo-100">{student.hostel_name}</span>
                                </>
                            ) : (
                                <span className="block text-sm text-indigo-100">No room assigned</span>
                            )}
                        </div>
                    </div>

                    {/* Quick Stats */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-12">
                        <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 relative overflow-hidden">
                            <div className="text-2xl font-bold text-gray-900 leading-none mb-1">₹{student.total_paid.toLocaleString()}</div>
                            <div className="text-sm text-green-600 font-medium">Total Paid</div>
                            <div className="absolute top-0 left-0 w-1 h-full bg-green-500"></div>
                        </div>
                        <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 relative overflow-hidden">
                            <div className={`text-2xl font-bold leading-none mb-1 ${student.total_pending > 0 ? 'text-red-600' : 'text-gray-900'}`}>
                                ₹{student.total_pending.toLocaleString()}
                            </div>
                            <div className={`text-sm font-medium ${student.total_pending > 0 ? 'text-red-600' : 'text-gray-500'}`}>Pending Amount</div>
                            <div className={`absolute top-0 left-0 w-1 h-full ${student.total_pending > 0 ? 'bg-red-500' : 'bg-gray-200'}`}></div>
                        </div>
                        <div className="bg-white rounded-xl p-6 shadow-sm border border-slate-100 relative overflow-hidden">
                            <div className={`text-2xl font-bold leading-none mb-1 ${student.active_complaints > 0 ? 'text-amber-600' : 'text-gray-900'}`}>
                                {student.active_complaints}
                            </div>
                            <div className={`text-sm font-medium ${student.active_complaints > 0 ? 'text-amber-600' : 'text-gray-500'}`}>Active Complaints</div>
                            <div className={`absolute top-0 left-0 w-1 h-full ${student.active_complaints > 0 ? 'bg-amber-500' : 'bg-gray-200'}`}></div>
                        </div>
                    </div>

                    {/* Quick Actions */}
                    <h2 className="text-xl font-semibold text-gray-800 mb-6">Quick Actions</h2>
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
                        <Link href={`/student/profile?id=${student.id}`} className="flex items-center gap-4 p-5 bg-white rounded-xl shadow-sm border border-gray-200 hover:-translate-y-1 hover:shadow-md hover:border-indigo-200 transition-all group">
                            <div className="text-2xl bg-blue-50 w-12 h-12 flex items-center justify-center rounded-full group-hover:bg-blue-100 transition-colors">👤</div>
                            <div>
                                <h3 className="font-medium text-gray-900">My Profile</h3>
                                <p className="text-xs text-gray-500">View & edit your details</p>
                            </div>
                        </Link>
                        <Link href={`/student/room?id=${student.id}`} className="flex items-center gap-4 p-5 bg-white rounded-xl shadow-sm border border-gray-200 hover:-translate-y-1 hover:shadow-md hover:border-indigo-200 transition-all group">
                            <div className="text-2xl bg-purple-50 w-12 h-12 flex items-center justify-center rounded-full group-hover:bg-purple-100 transition-colors">🏠</div>
                            <div>
                                <h3 className="font-medium text-gray-900">Room Details</h3>
                                <p className="text-xs text-gray-500">View room & roommates</p>
                            </div>
                        </Link>
                        <Link href={`/student/payments?id=${student.id}`} className="flex items-center gap-4 p-5 bg-white rounded-xl shadow-sm border border-gray-200 hover:-translate-y-1 hover:shadow-md hover:border-indigo-200 transition-all group">
                            <div className="text-2xl bg-green-50 w-12 h-12 flex items-center justify-center rounded-full group-hover:bg-green-100 transition-colors">💳</div>
                            <div>
                                <h3 className="font-medium text-gray-900">Payments</h3>
                                <p className="text-xs text-gray-500">View fee history & dues</p>
                            </div>
                        </Link>
                        <Link href={`/student/complaints?id=${student.id}`} className="flex items-center gap-4 p-5 bg-white rounded-xl shadow-sm border border-gray-200 hover:-translate-y-1 hover:shadow-md hover:border-indigo-200 transition-all group">
                            <div className="text-2xl bg-amber-50 w-12 h-12 flex items-center justify-center rounded-full group-hover:bg-amber-100 transition-colors">🔧</div>
                            <div>
                                <h3 className="font-medium text-gray-900">Complaints</h3>
                                <p className="text-xs text-gray-500">Raise & track issues</p>
                            </div>
                        </Link>
                    </div>


                    {/* Information Cards */}
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                            <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50">
                                <h3 className="font-semibold text-gray-900">🏠 Room Information</h3>
                            </div>
                            <div className="p-6">
                                {student.room_number ? (
                                    <div className="space-y-4">
                                        <div className="flex justify-between items-center pb-3 border-b border-gray-50">
                                            <span className="text-sm text-gray-500">Room Number</span>
                                            <span className="font-semibold text-gray-900">{student.room_number}</span>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-gray-500">Hostel</span>
                                            <span className="font-semibold text-gray-900">{student.hostel_name}</span>
                                        </div>
                                    </div>
                                ) : (
                                    <div className="text-center py-8 text-gray-500">
                                        No room allocated yet. Please contact the hostel office.
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                            <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50">
                                <h3 className="font-semibold text-gray-900">💰 Payment Summary</h3>
                            </div>
                            <div className="p-6 space-y-4">
                                <div className="flex justify-between items-center pb-3 border-b border-gray-50">
                                    <span className="text-sm text-gray-500">Total Paid</span>
                                    <span className="font-bold text-green-600">₹{student.total_paid.toLocaleString()}</span>
                                </div>
                                <div className="flex justify-between items-center">
                                    <span className="text-sm text-gray-500">Pending</span>
                                    <span className={`font-bold ${student.total_pending > 0 ? 'text-red-600' : 'text-green-600'}`}>
                                        ₹{student.total_pending.toLocaleString()}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
}

export default function StudentPortal() {
    return (
        <Suspense fallback={<div className="max-w-6xl mx-auto px-6 py-8"><div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div></div>}>
            <StudentPortalContent />
        </Suspense>
    );
}

