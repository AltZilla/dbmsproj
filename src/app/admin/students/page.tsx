'use client';

/**
 * Students Management Page
 * =========================
 * List, add, edit, and manage students with pagination and search.
 */

import { useEffect, useState } from 'react';
import Link from 'next/link';

interface Student {
    id: number;
    registration_number: string;
    first_name: string;
    last_name: string;
    email: string;
    phone: string;
    gender: string;
    department: string;
    year_of_study: number;
    is_active: boolean;
    address?: string;
    guardian_name?: string;
    guardian_phone?: string;
    date_of_birth?: string;
}

interface PaginationMeta {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
}

export default function StudentsPage() {
    const [students, setStudents] = useState<Student[]>([]);
    const [pagination, setPagination] = useState<PaginationMeta | null>(null);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [showAddForm, setShowAddForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
    const [selectedStudent, setSelectedStudent] = useState<Student | null>(null);
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

    // Form state
    const [formData, setFormData] = useState({
        registration_number: '',
        first_name: '',
        last_name: '',
        email: '',
        phone: '',
        gender: 'male',
        department: '',
        year_of_study: 1,
        address: '',
        guardian_name: '',
        guardian_phone: '',
        date_of_birth: ''
    });

    async function fetchStudents(page = 1) {
        setLoading(true);
        try {
            const params = new URLSearchParams({
                page: page.toString(),
                limit: '10'
            });
            if (search) params.append('search', search);

            const res = await fetch(`/api/students?${params}`);
            const data = await res.json();

            if (data.success) {
                setStudents(data.data);
                setPagination(data.pagination);
            }
        } catch (error) {
            console.error('Failed to fetch students:', error);
        } finally {
            setLoading(false);
        }
    }

    useEffect(() => {
        fetchStudents();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    async function handleSearch(e: React.FormEvent) {
        e.preventDefault();
        fetchStudents(1);
    }

    function resetForm() {
        setFormData({
            registration_number: '',
            first_name: '',
            last_name: '',
            email: '',
            phone: '',
            gender: 'male',
            department: '',
            year_of_study: 1,
            address: '',
            guardian_name: '',
            guardian_phone: '',
            date_of_birth: ''
        });
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        try {
            const res = await fetch('/api/students', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            const data = await res.json();

            if (data.success) {
                setMessage({ type: 'success', text: 'Student added successfully!' });
                setShowAddForm(false);
                resetForm();
                fetchStudents();
            } else {
                setMessage({ type: 'error', text: data.error || 'Failed to add student' });
            }
        } catch {
            setMessage({ type: 'error', text: 'An error occurred' });
        }

        setTimeout(() => setMessage(null), 5000);
    }

    async function handleEditSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (!selectedStudent) return;

        try {
            const res = await fetch(`/api/students/${selectedStudent.id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    first_name: formData.first_name,
                    last_name: formData.last_name,
                    email: formData.email,
                    phone: formData.phone || null,
                    department: formData.department || null,
                    year_of_study: formData.year_of_study,
                    address: formData.address || null,
                    guardian_name: formData.guardian_name || null,
                    guardian_phone: formData.guardian_phone || null,
                    date_of_birth: formData.date_of_birth || null
                })
            });
            const data = await res.json();

            if (data.success) {
                setMessage({ type: 'success', text: 'Student updated successfully!' });
                setShowEditForm(false);
                setSelectedStudent(null);
                resetForm();
                fetchStudents();
            } else {
                setMessage({ type: 'error', text: data.error || 'Failed to update student' });
            }
        } catch {
            setMessage({ type: 'error', text: 'An error occurred' });
        }

        setTimeout(() => setMessage(null), 5000);
    }

    async function handleDeactivate() {
        if (!selectedStudent) return;

        try {
            const res = await fetch(`/api/students/${selectedStudent.id}`, {
                method: 'DELETE'
            });
            const data = await res.json();

            if (data.success) {
                setMessage({ type: 'success', text: 'Student deactivated successfully!' });
                setShowDeleteConfirm(false);
                setSelectedStudent(null);
                fetchStudents();
            } else {
                setMessage({ type: 'error', text: data.error || 'Failed to deactivate student' });
            }
        } catch {
            setMessage({ type: 'error', text: 'An error occurred' });
        }

        setTimeout(() => setMessage(null), 5000);
    }

    function openEditModal(student: Student) {
        setSelectedStudent(student);
        setFormData({
            registration_number: student.registration_number,
            first_name: student.first_name,
            last_name: student.last_name,
            email: student.email,
            phone: student.phone || '',
            gender: student.gender,
            department: student.department || '',
            year_of_study: student.year_of_study || 1,
            address: student.address || '',
            guardian_name: student.guardian_name || '',
            guardian_phone: student.guardian_phone || '',
            date_of_birth: student.date_of_birth || ''
        });
        setShowEditForm(true);
    }

    function openDeleteModal(student: Student) {
        setSelectedStudent(student);
        setShowDeleteConfirm(true);
    }

    return (
        <div className="max-w-7xl mx-auto px-6 py-8">
            <Link href="/admin" className="inline-flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition-colors font-medium">
                <span className="mr-2">←</span> Back to Dashboard
            </Link>

            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-indigo-950 mb-1">Students Management</h1>
                    <p className="text-gray-500">Add and manage hostel residents</p>
                </div>
                <button
                    className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors shadow-sm flex items-center gap-2"
                    onClick={() => setShowAddForm(true)}
                >
                    <span>+</span> Add Student
                </button>
            </div>

            {message && (
                <div className={`p-4 rounded-lg mb-6 ${message.type === 'success' ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'}`}>
                    {message.text}
                </div>
            )}

            {/* Search */}
            <form onSubmit={handleSearch} className="flex gap-3 mb-6">
                <input
                    type="text"
                    className="flex-1 max-w-md px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                    placeholder="Search by name, email, or registration number..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                />
                <button type="submit" className="px-4 py-2 bg-white border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors">
                    Search
                </button>
            </form>

            {/* Students Table */}
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                {loading ? (
                    <div className="min-h-[200px] flex items-center justify-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-4 border-indigo-200 border-t-indigo-600"></div>
                    </div>
                ) : students.length === 0 ? (
                    <div className="text-center py-12">
                        <div className="text-4xl mb-3 opacity-50">👥</div>
                        <p className="text-gray-500 font-medium">No students found</p>
                    </div>
                ) : (
                    <>
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-gray-50/50 border-b border-gray-200 text-xs uppercase text-gray-500 font-medium">
                                        <th className="px-6 py-3">Reg. Number</th>
                                        <th className="px-6 py-3">Name</th>
                                        <th className="px-6 py-3">Email</th>
                                        <th className="px-6 py-3">Gender</th>
                                        <th className="px-6 py-3">Department</th>
                                        <th className="px-6 py-3">Year</th>
                                        <th className="px-6 py-3">Status</th>
                                        <th className="px-6 py-3 text-center">Actions</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100">
                                    {students.map((student) => (
                                        <tr key={student.id} className="hover:bg-gray-50/50 transition-colors text-sm text-gray-900">
                                            <td className="px-6 py-3 font-medium text-gray-900">{student.registration_number}</td>
                                            <td className="px-6 py-3">{student.first_name} {student.last_name}</td>
                                            <td className="px-6 py-3 text-gray-500">{student.email}</td>
                                            <td className="px-6 py-3 capitalize">{student.gender}</td>
                                            <td className="px-6 py-3 text-gray-500">{student.department || '-'}</td>
                                            <td className="px-6 py-3 text-gray-500">{student.year_of_study || '-'}</td>
                                            <td className="px-6 py-3">
                                                <span className={`px-2 py-1 rounded-full text-xs font-semibold ${student.is_active
                                                    ? 'bg-green-50 text-green-700 border border-green-200'
                                                    : 'bg-red-50 text-red-700 border border-red-200'
                                                    }`}>
                                                    {student.is_active ? 'Active' : 'Inactive'}
                                                </span>
                                            </td>
                                            <td className="px-6 py-3">
                                                <div className="flex items-center justify-center gap-2">
                                                    <Link
                                                        href={`/student?id=${student.id}`}
                                                        className="p-1.5 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                                                        title="View Student Portal"
                                                    >
                                                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                        </svg>
                                                    </Link>
                                                    <button
                                                        onClick={() => openEditModal(student)}
                                                        className="p-1.5 text-gray-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                                                        title="Edit Student"
                                                    >
                                                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                                        </svg>
                                                    </button>
                                                    {student.is_active && (
                                                        <button
                                                            onClick={() => openDeleteModal(student)}
                                                            className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                            title="Deactivate Student"
                                                        >
                                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                                                            </svg>
                                                        </button>
                                                    )}
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        {/* Pagination */}
                        {pagination && pagination.totalPages > 1 && (
                            <div className="flex justify-center items-center gap-4 p-4 border-t border-gray-100">
                                <button
                                    className="px-3 py-1 text-sm border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                                    disabled={pagination.page === 1}
                                    onClick={() => fetchStudents(pagination.page - 1)}
                                >
                                    Previous
                                </button>
                                <span className="text-sm text-gray-600 font-medium">
                                    Page {pagination.page} of {pagination.totalPages} <span className="text-gray-400">({pagination.total} total)</span>
                                </span>
                                <button
                                    className="px-3 py-1 text-sm border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                                    disabled={pagination.page === pagination.totalPages}
                                    onClick={() => fetchStudents(pagination.page + 1)}
                                >
                                    Next
                                </button>
                            </div>
                        )}
                    </>
                )}
            </div>

            {/* Add Student Modal */}
            {showAddForm && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => setShowAddForm(false)}>
                    <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
                        <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50 sticky top-0">
                            <h2 className="text-lg font-bold text-gray-900">Add New Student</h2>
                            <button onClick={() => setShowAddForm(false)} className="text-gray-400 hover:text-gray-600 transition-colors">✕</button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div className="p-6 space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Registration Number *</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                        value={formData.registration_number}
                                        onChange={(e) => setFormData({ ...formData, registration_number: e.target.value })}
                                        required
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">First Name *</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.first_name}
                                            onChange={(e) => setFormData({ ...formData, first_name: e.target.value })}
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Last Name *</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.last_name}
                                            onChange={(e) => setFormData({ ...formData, last_name: e.target.value })}
                                            required
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                                    <input
                                        type="email"
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                        value={formData.email}
                                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                        required
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.phone}
                                            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Gender *</label>
                                        <select
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white"
                                            value={formData.gender}
                                            onChange={(e) => setFormData({ ...formData, gender: e.target.value })}
                                        >
                                            <option value="male">Male</option>
                                            <option value="female">Female</option>
                                            <option value="other">Other</option>
                                        </select>
                                    </div>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Department</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.department}
                                            onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Year of Study</label>
                                        <select
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white"
                                            value={formData.year_of_study}
                                            onChange={(e) => setFormData({ ...formData, year_of_study: parseInt(e.target.value) })}
                                        >
                                            {[1, 2, 3, 4, 5, 6].map((year) => (
                                                <option key={year} value={year}>Year {year}</option>
                                            ))}
                                        </select>
                                    </div>
                                </div>
                            </div>
                            <div className="px-6 py-4 bg-gray-50 flex justify-end gap-3 rounded-b-2xl border-t border-gray-100">
                                <button type="button" className="px-4 py-2 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-white transition-colors" onClick={() => setShowAddForm(false)}>
                                    Cancel
                                </button>
                                <button type="submit" className="px-4 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors shadow-sm">
                                    Add Student
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Edit Student Modal */}
            {showEditForm && selectedStudent && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => { setShowEditForm(false); setSelectedStudent(null); }}>
                    <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
                        <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50 sticky top-0">
                            <h2 className="text-lg font-bold text-gray-900">Edit Student</h2>
                            <button onClick={() => { setShowEditForm(false); setSelectedStudent(null); }} className="text-gray-400 hover:text-gray-600 transition-colors">✕</button>
                        </div>
                        <form onSubmit={handleEditSubmit}>
                            <div className="p-6 space-y-4">
                                <div className="bg-indigo-50 rounded-lg p-3 border border-indigo-100">
                                    <div className="text-sm text-indigo-600 font-medium">Registration Number</div>
                                    <div className="text-lg font-bold text-indigo-900">{selectedStudent.registration_number}</div>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">First Name *</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.first_name}
                                            onChange={(e) => setFormData({ ...formData, first_name: e.target.value })}
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Last Name *</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.last_name}
                                            onChange={(e) => setFormData({ ...formData, last_name: e.target.value })}
                                            required
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                                    <input
                                        type="email"
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                        value={formData.email}
                                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                        required
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.phone}
                                            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Date of Birth</label>
                                        <input
                                            type="date"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.date_of_birth}
                                            onChange={(e) => setFormData({ ...formData, date_of_birth: e.target.value })}
                                        />
                                    </div>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Department</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.department}
                                            onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Year of Study</label>
                                        <select
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white"
                                            value={formData.year_of_study}
                                            onChange={(e) => setFormData({ ...formData, year_of_study: parseInt(e.target.value) })}
                                        >
                                            {[1, 2, 3, 4, 5, 6].map((year) => (
                                                <option key={year} value={year}>Year {year}</option>
                                            ))}
                                        </select>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
                                    <textarea
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                        rows={2}
                                        value={formData.address}
                                        onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Guardian Name</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.guardian_name}
                                            onChange={(e) => setFormData({ ...formData, guardian_name: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Guardian Phone</label>
                                        <input
                                            type="text"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                            value={formData.guardian_phone}
                                            onChange={(e) => setFormData({ ...formData, guardian_phone: e.target.value })}
                                        />
                                    </div>
                                </div>
                            </div>
                            <div className="px-6 py-4 bg-gray-50 flex justify-end gap-3 rounded-b-2xl border-t border-gray-100">
                                <button type="button" className="px-4 py-2 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-white transition-colors" onClick={() => { setShowEditForm(false); setSelectedStudent(null); }}>
                                    Cancel
                                </button>
                                <button type="submit" className="px-4 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors shadow-sm">
                                    Save Changes
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Delete Confirmation Modal */}
            {showDeleteConfirm && selectedStudent && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => { setShowDeleteConfirm(false); setSelectedStudent(null); }}>
                    <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden" onClick={(e) => e.stopPropagation()}>
                        <div className="p-6 text-center">
                            <div className="text-5xl mb-4">⚠️</div>
                            <h2 className="text-xl font-bold text-gray-900 mb-2">Deactivate Student?</h2>
                            <p className="text-gray-500 mb-2">
                                Are you sure you want to deactivate <strong>{selectedStudent.first_name} {selectedStudent.last_name}</strong>?
                            </p>
                            <p className="text-sm text-gray-400 mb-6">
                                This will also end any active room allocations. The student can be reactivated later.
                            </p>
                            <div className="flex gap-3 justify-center">
                                <button
                                    onClick={() => { setShowDeleteConfirm(false); setSelectedStudent(null); }}
                                    className="px-6 py-2 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors"
                                >
                                    Cancel
                                </button>
                                <button
                                    onClick={handleDeactivate}
                                    className="px-6 py-2 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 transition-colors shadow-sm"
                                >
                                    Deactivate
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
