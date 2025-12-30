'use client';

/**
 * Student Complaints Page
 * ========================
 * View complaints and raise new maintenance requests.
 */

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface Complaint {
    id: number;
    title: string;
    description: string;
    category: string;
    status: string;
    priority: number;
    created_at: string;
    resolved_at: string | null;
}

const categoryIcons: Record<string, string> = {
    electrical: '⚡',
    plumbing: '🚿',
    furniture: '🪑',
    cleaning: '🧹',
    pest_control: '🐛',
    internet: '📶',
    security: '🔒',
    other: '📝'
};

const statusConfig: Record<string, string> = {
    open: 'bg-amber-100 text-amber-800 border-amber-200',
    assigned: 'bg-blue-100 text-blue-800 border-blue-200',
    in_progress: 'bg-indigo-100 text-indigo-800 border-indigo-200',
    resolved: 'bg-green-100 text-green-800 border-green-200',
    closed: 'bg-gray-100 text-gray-800 border-gray-200'
};

function ComplaintsContent() {
    const searchParams = useSearchParams();
    const studentId = parseInt(searchParams.get('id') || '1');
    const [roomId, setRoomId] = useState<number>(0);

    const [complaints, setComplaints] = useState<Complaint[]>([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

    const [formData, setFormData] = useState({
        category: 'electrical',
        title: '',
        description: '',
        priority: 3
    });

    // Fetch room ID for the student
    useEffect(() => {
        async function fetchRoom() {
            try {
                const res = await fetch(`/api/students/${studentId}`);
                const data = await res.json();
                if (data.success && data.data.room_id) {
                    setRoomId(data.data.room_id);
                }
            } catch (err) {
                console.error("Failed to fetch student's room", err);
            }
        }
        fetchRoom();
    }, [studentId]);

    const fetchComplaints = async () => {
        setLoading(true);
        try {
            const res = await fetch(`/api/complaints?student_id=${studentId}`);
            const data = await res.json();
            if (data.success) {
                setComplaints(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch complaints:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchComplaints();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [studentId]);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();

        // Check if student has a room assigned
        if (!roomId) {
            setMessage({ type: 'error', text: 'You must be assigned to a room before raising a complaint. Please contact the hostel administrator.' });
            return;
        }

        try {
            const res = await fetch('/api/complaints', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    student_id: studentId,
                    room_id: roomId,
                    ...formData
                })
            });
            const data = await res.json();

            if (data.success) {
                setMessage({ type: 'success', text: 'Complaint raised successfully! We will look into it.' });
                setShowForm(false);
                setFormData({ category: 'electrical', title: '', description: '', priority: 3 });
                fetchComplaints();
            } else {
                setMessage({ type: 'error', text: data.error || 'Failed to raise complaint' });
            }
        } catch (error) {
            setMessage({ type: 'error', text: 'An error occurred' });
        }

        setTimeout(() => setMessage(null), 5000);
    }

    function formatDate(dateString: string) {
        return new Date(dateString).toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });
    }

    return (
        <div className="max-w-7xl mx-auto px-6 py-8">
            <Link href={`/student?id=${studentId}`} className="inline-flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition-colors font-medium">
                <span className="mr-2">←</span> Back to Dashboard
            </Link>

            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900 mb-1">My Complaints</h1>
                    <p className="text-gray-500">View and raise maintenance requests</p>
                </div>
                <button
                    className="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-lg text-sm font-medium transition-colors shadow-sm flex items-center gap-2"
                    onClick={() => setShowForm(true)}
                >
                    <span className="text-lg">+</span> Raise Complaint
                </button>
            </div>

            {message && (
                <div className={`p-4 rounded-lg mb-6 ${message.type === 'success' ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'}`}>
                    {message.text}
                </div>
            )}

            {/* Complaints List */}
            <div>
                {loading ? (
                    <div className="min-h-[200px] flex items-center justify-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-4 border-indigo-200 border-t-indigo-600"></div>
                    </div>
                ) : complaints.length === 0 ? (
                    <div className="bg-white rounded-xl p-12 text-center border border-gray-200 shadow-sm">
                        <div className="text-5xl mb-4 grayscale opacity-50">✅</div>
                        <h3 className="text-lg font-medium text-gray-900 mb-1">No complaints</h3>
                        <p className="text-gray-500">Everything looks good! No active maintenance requests.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {complaints.map((complaint) => (
                            <div key={complaint.id} className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md hover:border-indigo-100 transition-all group flex flex-col h-full">
                                <div className="flex justify-between items-start mb-4">
                                    <span className="inline-flex items-center gap-2 px-2.5 py-1 bg-gray-50 text-gray-700 rounded-lg text-xs font-semibold uppercase tracking-wide border border-gray-100">
                                        <span className="text-base">{categoryIcons[complaint.category]}</span>
                                        {complaint.category.replace('_', ' ')}
                                    </span>
                                    <span className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize border ${statusConfig[complaint.status] || 'bg-gray-100 text-gray-800 border-gray-200'}`}>
                                        {complaint.status.replace('_', ' ')}
                                    </span>
                                </div>
                                <h3 className="text-lg font-bold text-gray-900 mb-2 leading-tight group-hover:text-indigo-600 transition-colors">{complaint.title}</h3>
                                <p className="text-gray-600 text-sm mb-6 flex-grow leading-relaxed">{complaint.description}</p>
                                <div className="flex items-center justify-between pt-4 border-t border-gray-50 text-xs text-gray-500 mt-auto">
                                    <div className="flex items-center gap-2">
                                        <span className={`inline-block w-2 h-2 rounded-full ${complaint.priority <= 2 ? 'bg-red-500' : 'bg-blue-400'}`}></span>
                                        Priority: P{complaint.priority}
                                    </div>
                                    <div className="text-right">
                                        <div>Created: {formatDate(complaint.created_at)}</div>
                                        {complaint.resolved_at && (
                                            <div className="text-green-600 font-medium mt-0.5">Resolved: {formatDate(complaint.resolved_at)}</div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Raise Complaint Modal */}
            {showForm && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => setShowForm(false)}>
                    <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden transform transition-all" onClick={(e) => e.stopPropagation()}>
                        <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                            <h2 className="text-lg font-bold text-gray-900">Raise a Complaint</h2>
                            <button onClick={() => setShowForm(false)} className="text-gray-400 hover:text-gray-600 transition-colors">✕</button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div className="p-6 space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Category *</label>
                                    <select
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white"
                                        value={formData.category}
                                        onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                                    >
                                        <option value="electrical">⚡ Electrical</option>
                                        <option value="plumbing">🚿 Plumbing</option>
                                        <option value="furniture">🪑 Furniture</option>
                                        <option value="cleaning">🧹 Cleaning</option>
                                        <option value="pest_control">🐛 Pest Control</option>
                                        <option value="internet">📶 Internet</option>
                                        <option value="security">🔒 Security</option>
                                        <option value="other">📝 Other</option>
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Title *</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                                        placeholder="Brief description of the issue"
                                        value={formData.title}
                                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                        required
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Description *</label>
                                    <textarea
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all min-h-[100px]"
                                        placeholder="Provide more details about the issue..."
                                        value={formData.description}
                                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                        required
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Priority</label>
                                    <select
                                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white"
                                        value={formData.priority}
                                        onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) })}
                                    >
                                        <option value={1}>1 - Urgent (Safety issue)</option>
                                        <option value={2}>2 - High</option>
                                        <option value={3}>3 - Medium (Default)</option>
                                        <option value={4}>4 - Low</option>
                                        <option value={5}>5 - When possible</option>
                                    </select>
                                </div>
                            </div>
                            <div className="px-6 py-4 bg-gray-50 flex justify-end gap-3 rounded-b-2xl border-t border-gray-100">
                                <button type="button" className="px-4 py-2 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-white transition-colors" onClick={() => setShowForm(false)}>
                                    Cancel
                                </button>
                                <button type="submit" className="px-4 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors shadow-sm">
                                    Submit Complaint
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}

export default function StudentComplaintsPage() {
    return (
        <Suspense fallback={<div className="max-w-7xl mx-auto px-6 py-8"><div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div></div>}>
            <ComplaintsContent />
        </Suspense>
    );
}
