'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface Student {
    id: number;
    first_name: string;
    last_name: string;
    registration_number: string;
    email: string;
    phone: string;
    date_of_birth: string;
    gender: string;
    guardian_name: string;
    guardian_phone: string;
    address: string;
    is_active: boolean;
}

function StudentProfileContent() {
    const searchParams = useSearchParams();
    const studentId = searchParams.get('id') || '1'; // Default to demo student 1

    const [student, setStudent] = useState<Student | null>(null);
    const [loading, setLoading] = useState(true);
    const [editing, setEditing] = useState(false);
    const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null);

    // Form state
    const [formData, setFormData] = useState({
        email: '',
        phone: '',
        guardian_name: '',
        guardian_phone: '',
        address: ''
    });

    useEffect(() => {
        const fetchStudent = async () => {
            try {
                const res = await fetch(`/api/students/${studentId}`);
                const data = await res.json();
                if (data.success) {
                    setStudent(data.data);
                    setFormData({
                        email: data.data.email || '',
                        phone: data.data.phone || '',
                        guardian_name: data.data.guardian_name || '',
                        guardian_phone: data.data.guardian_phone || '',
                        address: data.data.address || ''
                    });
                }

            } catch (error) {
                console.error('Failed to fetch profile:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchStudent();
    }, [studentId]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setStatus(null);

        try {
            const res = await fetch(`/api/students/${studentId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            const data = await res.json();

            if (data.success) {
                setStudent({ ...student!, ...formData });
                setStatus({ type: 'success', message: 'Profile updated successfully' });
                setEditing(false);
            } else {
                setStatus({ type: 'error', message: data.error || 'Failed to update profile' });
            }
        } catch (err) {
            setStatus({ type: 'error', message: 'An error occurred' });
        }
    };

    if (loading) return <div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div>;
    if (!student) return <div className="max-w-4xl mx-auto px-6 py-8 text-center text-gray-500">Student not found</div>;

    const initials = `${student.first_name[0]}${student.last_name[0]}`;

    return (
        <div className="max-w-4xl mx-auto px-6 py-8">
            <Link href={`/student?id=${studentId}`} className="inline-flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition-colors font-medium">
                <span className="mr-2">←</span> Back to Dashboard
            </Link>
            <div className="text-center mb-10">
                <h1 className="text-3xl font-bold text-gray-900 mb-2">My Profile</h1>
                <p className="text-gray-500">Manage your personal information</p>
            </div>

            {status && (
                <div className={`p-4 rounded-lg mb-6 text-center shadow-sm ${status.type === 'success' ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'}`}>
                    {status.message}
                </div>
            )}

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-6">
                <div className="p-8">
                    <div className="flex flex-col items-center text-center">
                        <div className="w-24 h-24 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 text-white flex items-center justify-center text-3xl font-bold mb-4 shadow-lg mx-auto">
                            {initials}
                        </div>
                        <h2 className="text-2xl font-bold text-gray-900">
                            {student.first_name} {student.last_name}
                        </h2>
                        <p className="text-gray-500 font-mono mt-1">{student.registration_number}</p>
                        <span className={`mt-3 px-3 py-1 rounded-full text-xs font-semibold uppercase tracking-wide border ${student.is_active ? 'bg-green-50 text-green-700 border-green-100' : 'bg-red-50 text-red-700 border-red-100'
                            }`}>
                            {student.is_active ? 'Active Student' : 'Inactive'}
                        </span>
                    </div>
                </div>
            </div>

            <form onSubmit={handleSubmit}>
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-6">
                    <div className="bg-gray-50/50 px-8 py-5 border-b border-gray-100">
                        <div className="flex justify-between items-center">
                            <h3 className="text-lg font-bold text-gray-900">Personal Details</h3>
                            {!editing && (
                                <button
                                    type="button"
                                    onClick={() => setEditing(true)}
                                    className="text-indigo-600 hover:text-indigo-700 text-sm font-medium hover:underline"
                                >
                                    Edit Details
                                </button>
                            )}
                        </div>
                    </div>
                    <div className="p-8">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
                            <div>
                                <label className="block text-sm font-medium text-gray-500 mb-1.5">Email Address</label>
                                {editing ? (
                                    <input
                                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                        type="email"
                                        value={formData.email}
                                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                    />
                                ) : (
                                    <div className="text-gray-900 font-medium text-lg border-b border-gray-100 pb-1">{student.email}</div>
                                )}
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-500 mb-1.5">Phone Number</label>
                                {editing ? (
                                    <input
                                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                        type="tel"
                                        value={formData.phone}
                                        onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                    />
                                ) : (
                                    <div className="text-gray-900 font-medium text-lg border-b border-gray-100 pb-1">{student.phone || '-'}</div>
                                )}
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-500 mb-1.5">Date of Birth</label>
                                <div className="text-gray-900 font-medium text-lg border-b border-gray-100 pb-1">
                                    {new Date(student.date_of_birth).toLocaleDateString()}
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-500 mb-1.5">Gender</label>
                                <div className="text-gray-900 font-medium text-lg border-b border-gray-100 pb-1 capitalize">
                                    {student.gender}
                                </div>
                            </div>
                        </div>

                        <div className="mt-8 pt-8 border-t border-gray-100">
                            <h4 className="text-lg font-bold text-gray-900 mb-6">Guardian Information</h4>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
                                <div>
                                    <label className="block text-sm font-medium text-gray-500 mb-1.5">Guardian Name</label>
                                    {editing ? (
                                        <input
                                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            type="text"
                                            value={formData.guardian_name}
                                            onChange={(e) => setFormData({ ...formData, guardian_name: e.target.value })}
                                        />
                                    ) : (
                                        <div className="text-gray-900 font-medium text-lg border-b border-gray-100 pb-1">{student.guardian_name}</div>
                                    )}
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-500 mb-1.5">Guardian Phone</label>
                                    {editing ? (
                                        <input
                                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            type="tel"
                                            value={formData.guardian_phone}
                                            onChange={(e) => setFormData({ ...formData, guardian_phone: e.target.value })}
                                        />
                                    ) : (
                                        <div className="text-gray-900 font-medium text-lg border-b border-gray-100 pb-1">{student.guardian_phone}</div>
                                    )}
                                </div>
                                <div className="col-span-full">
                                    <label className="block text-sm font-medium text-gray-500 mb-1.5">Permanent Address</label>
                                    {editing ? (
                                        <textarea
                                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.address}
                                            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                                            rows={3}
                                        />
                                    ) : (
                                        <div className="text-gray-900 font-medium text-lg border-b border-gray-100 pb-1">{student.address}</div>
                                    )}
                                </div>
                            </div>
                        </div>

                        {editing && (
                            <div className="flex justify-end gap-3 mt-8 pt-6 border-t border-gray-100">
                                <button
                                    type="button"
                                    onClick={() => {
                                        setEditing(false);
                                        // Reset form
                                        setFormData({
                                            email: student.email || '',
                                            phone: student.phone || '',
                                            guardian_name: student.guardian_name || '',
                                            guardian_phone: student.guardian_phone || '',
                                            address: student.address || ''
                                        });
                                    }}

                                    className="px-6 py-2.5 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 font-medium transition-colors"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    className="px-6 py-2.5 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors shadow-sm"
                                >
                                    Save Changes
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            </form>
        </div>
    );
}

export default function StudentProfilePage() {
    return (
        <div className="min-h-screen bg-gray-50">
            <Suspense fallback={<div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div>}>
                <StudentProfileContent />
            </Suspense>
        </div>
    );
}

