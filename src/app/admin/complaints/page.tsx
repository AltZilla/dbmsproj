'use client';

/**
 * Complaints Management Page
 * ===========================
 * View and manage maintenance complaints with status updates.
 */

import { useEffect, useState } from 'react';

interface Complaint {
    id: number;
    title: string;
    description: string;
    category: string;
    status: string;
    priority: number;
    student_name: string;
    room_number: string;
    hostel_name: string;
    staff_name: string | null;
    created_at: string;
}

const statusColors: Record<string, string> = {
    open: 'badge-open',
    assigned: 'badge-assigned',
    in_progress: 'badge-in-progress',
    resolved: 'badge-resolved',
    closed: 'badge-closed'
};

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

export default function ComplaintsPage() {
    const [complaints, setComplaints] = useState<Complaint[]>([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('');
    const [categoryFilter, setCategoryFilter] = useState('');
    const [selectedComplaint, setSelectedComplaint] = useState<Complaint | null>(null);

    async function fetchComplaints() {
        setLoading(true);
        try {
            const params = new URLSearchParams({ limit: '20' });
            if (statusFilter) params.append('status', statusFilter);
            if (categoryFilter) params.append('category', categoryFilter);

            const res = await fetch(`/api/complaints?${params}`);
            const data = await res.json();

            if (data.success) {
                setComplaints(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch complaints:', error);
        } finally {
            setLoading(false);
        }
    }

    useEffect(() => {
        fetchComplaints();
    }, [statusFilter, categoryFilter]);

    async function updateStatus(id: number, newStatus: string) {
        try {
            const res = await fetch(`/api/complaints/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status: newStatus })
            });
            const data = await res.json();

            if (data.success) {
                fetchComplaints();
                setSelectedComplaint(null);
            }
        } catch (error) {
            console.error('Failed to update status:', error);
        }
    }

    function formatDate(dateString: string) {
        return new Date(dateString).toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    return (
        <div className="container">
            <div style={{ marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.75rem', fontWeight: 700, color: '#1e1b4b', marginBottom: '0.25rem' }}>
                    Maintenance Complaints
                </h1>
                <p style={{ color: '#6b7280', margin: 0 }}>Track and manage maintenance requests</p>
            </div>

            {/* Filters */}
            <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem', flexWrap: 'wrap' }}>
                <select
                    className="form-select"
                    style={{ width: 'auto', minWidth: '150px' }}
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                >
                    <option value="">All Statuses</option>
                    <option value="open">Open</option>
                    <option value="assigned">Assigned</option>
                    <option value="in_progress">In Progress</option>
                    <option value="resolved">Resolved</option>
                    <option value="closed">Closed</option>
                </select>
                <select
                    className="form-select"
                    style={{ width: 'auto', minWidth: '150px' }}
                    value={categoryFilter}
                    onChange={(e) => setCategoryFilter(e.target.value)}
                >
                    <option value="">All Categories</option>
                    <option value="electrical">Electrical</option>
                    <option value="plumbing">Plumbing</option>
                    <option value="furniture">Furniture</option>
                    <option value="cleaning">Cleaning</option>
                    <option value="pest_control">Pest Control</option>
                    <option value="internet">Internet</option>
                    <option value="security">Security</option>
                    <option value="other">Other</option>
                </select>
            </div>

            {/* Complaints List */}
            <div className="card">
                {loading ? (
                    <div className="loading-container">
                        <div className="spinner"></div>
                    </div>
                ) : complaints.length === 0 ? (
                    <div className="empty-state">
                        <div className="empty-state-icon">🔧</div>
                        <p>No complaints found</p>
                    </div>
                ) : (
                    <div className="table-container">
                        <table className="table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Category</th>
                                    <th>Title</th>
                                    <th>Room</th>
                                    <th>Student</th>
                                    <th>Priority</th>
                                    <th>Status</th>
                                    <th>Created</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {complaints.map((complaint) => (
                                    <tr key={complaint.id}>
                                        <td>#{complaint.id}</td>
                                        <td>
                                            <span title={complaint.category}>
                                                {categoryIcons[complaint.category] || '📝'}{' '}
                                                <span style={{ textTransform: 'capitalize' }}>
                                                    {complaint.category.replace('_', ' ')}
                                                </span>
                                            </span>
                                        </td>
                                        <td>
                                            <strong style={{ color: '#1e1b4b' }}>{complaint.title}</strong>
                                        </td>
                                        <td>{complaint.room_number} ({complaint.hostel_name})</td>
                                        <td>{complaint.student_name}</td>
                                        <td>
                                            <span className={`priority-${complaint.priority}`}>
                                                P{complaint.priority}
                                            </span>
                                        </td>
                                        <td>
                                            <span className={`badge ${statusColors[complaint.status]}`}>
                                                {complaint.status.replace('_', ' ')}
                                            </span>
                                        </td>
                                        <td style={{ whiteSpace: 'nowrap' }}>{formatDate(complaint.created_at)}</td>
                                        <td>
                                            <button
                                                className="btn btn-secondary btn-sm"
                                                onClick={() => setSelectedComplaint(complaint)}
                                            >
                                                View
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Complaint Detail Modal */}
            {selectedComplaint && (
                <div className="modal-overlay" onClick={() => setSelectedComplaint(null)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '600px' }}>
                        <div className="modal-header">
                            <h2>Complaint #{selectedComplaint.id}</h2>
                        </div>
                        <div className="modal-body">
                            <div style={{ marginBottom: '1.5rem' }}>
                                <span className={`badge ${statusColors[selectedComplaint.status]}`} style={{ marginRight: '0.5rem' }}>
                                    {selectedComplaint.status.replace('_', ' ')}
                                </span>
                                <span className={`priority-${selectedComplaint.priority}`}>
                                    Priority {selectedComplaint.priority}
                                </span>
                            </div>

                            <h3 style={{ marginBottom: '0.5rem', color: '#1e1b4b' }}>
                                {categoryIcons[selectedComplaint.category]} {selectedComplaint.title}
                            </h3>
                            <p style={{ color: '#6b7280', marginBottom: '1.5rem' }}>
                                {selectedComplaint.description}
                            </p>

                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
                                <div>
                                    <strong style={{ color: '#374151', fontSize: '0.875rem' }}>Room</strong>
                                    <p style={{ margin: 0, color: '#6b7280' }}>
                                        {selectedComplaint.room_number} - {selectedComplaint.hostel_name}
                                    </p>
                                </div>
                                <div>
                                    <strong style={{ color: '#374151', fontSize: '0.875rem' }}>Reported By</strong>
                                    <p style={{ margin: 0, color: '#6b7280' }}>{selectedComplaint.student_name}</p>
                                </div>
                                <div>
                                    <strong style={{ color: '#374151', fontSize: '0.875rem' }}>Assigned To</strong>
                                    <p style={{ margin: 0, color: '#6b7280' }}>{selectedComplaint.staff_name || 'Not assigned'}</p>
                                </div>
                                <div>
                                    <strong style={{ color: '#374151', fontSize: '0.875rem' }}>Created</strong>
                                    <p style={{ margin: 0, color: '#6b7280' }}>{formatDate(selectedComplaint.created_at)}</p>
                                </div>
                            </div>

                            {/* Status Update Buttons */}
                            <div>
                                <strong style={{ display: 'block', marginBottom: '0.75rem', color: '#374151', fontSize: '0.875rem' }}>
                                    Update Status
                                </strong>
                                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                                    {['open', 'assigned', 'in_progress', 'resolved', 'closed'].map((status) => (
                                        <button
                                            key={status}
                                            className={`btn btn-sm ${selectedComplaint.status === status ? 'btn-primary' : 'btn-secondary'}`}
                                            onClick={() => updateStatus(selectedComplaint.id, status)}
                                            disabled={selectedComplaint.status === status}
                                        >
                                            {status.replace('_', ' ')}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        </div>
                        <div className="modal-footer">
                            <button className="btn btn-secondary" onClick={() => setSelectedComplaint(null)}>
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
