'use client';

import { useState, useEffect } from 'react';
import { DataTable } from '@/components/ui/DataTable';

interface Payment {
    id: number;
    student_id: number;
    amount: string;
    due_date: string;
    payment_date: string | null;
    payment_status: 'pending' | 'paid' | 'overdue' | 'partial';
    payment_method: string | null;
    receipt_number: string | null;
    semester: string | null;
    student_name: string;
    registration_number: string;
    days_overdue: number | null;
    notes?: string | null;
}

interface Student {
    id: number;
    first_name: string;
    last_name: string;
    registration_number: string;
}

export default function PaymentsPage() {
    const [payments, setPayments] = useState<Payment[]>([]);
    const [loading, setLoading] = useState(true);
    const [filterStatus, setFilterStatus] = useState('all');
    const [filterOverdue, setFilterOverdue] = useState(false);

    // Modal & Form State
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [students, setStudents] = useState<Student[]>([]);
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        student_id: '',
        amount: '',
        due_date: '',
        payment_date: '',
        payment_status: 'pending',
        semester: '',
        notes: ''
    });

    const fetchPayments = async () => {
        setLoading(true);
        try {
            const params = new URLSearchParams({ limit: '50' });
            if (filterStatus !== 'all') params.append('status', filterStatus);
            if (filterOverdue) params.append('overdue', 'true');

            const res = await fetch(`/api/payments?${params}`);
            const data = await res.json();
            if (data.success) {
                setPayments(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch payments:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchPayments();
    }, [filterStatus, filterOverdue]);

    const openModal = async () => {
        setIsModalOpen(true);
        // Reset form
        setFormData({
            student_id: '',
            amount: '',
            due_date: new Date().toISOString().split('T')[0],
            payment_date: '',
            payment_status: 'pending',
            semester: '',
            notes: ''
        });

        // Fetch students
        try {
            const res = await fetch('/api/students?limit=100&is_active=true');
            const data = await res.json();
            if (data.success) setStudents(data.data);
        } catch (err) {
            console.error('Failed to load students', err);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSubmitting(true);

        try {
            const res = await fetch('/api/payments', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    student_id: parseInt(formData.student_id),
                    amount: parseFloat(formData.amount),
                    due_date: formData.due_date,
                    payment_date: formData.payment_date || undefined,
                    payment_status: formData.payment_status,
                    semester: formData.semester || undefined,
                    notes: formData.notes || undefined
                })
            });

            const data = await res.json();
            if (data.success) {
                setIsModalOpen(false);
                fetchPayments(); // Refresh list
            } else {
                setError(data.error || 'Failed to issue payment request');
            }
        } catch (err) {
            setError('An error occurred. Please try again.');
        } finally {
            setSubmitting(false);
        }
    };

    const handleMarkAsPaid = async (payment: Payment) => {
        if (!confirm(`Mark payment of ₹${payment.amount} for ${payment.student_name} as paid?`)) {
            return;
        }

        try {
            const today = new Date().toISOString().split('T')[0];
            const receiptNumber = `RCP-${new Date().getFullYear()}-${Date.now().toString().slice(-6)}`;

            const res = await fetch(`/api/payments/${payment.id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    payment_status: 'paid',
                    payment_date: today,
                    receipt_number: receiptNumber
                })
            });

            const data = await res.json();
            if (data.success) {
                fetchPayments(); // Refresh the list
            } else {
                alert(data.error || 'Failed to update payment');
            }
        } catch {
            alert('An error occurred while updating the payment');
        }
    };

    return (
        <div className="page-wrapper">
            <div className="container main-content">
                <div className="flex justify-between items-center" style={{ marginBottom: 'var(--space-8)' }}>
                    <div>
                        <h1>Payment Records</h1>
                        <p className="card-subtitle">Issue and manage student fee requests</p>
                    </div>
                    <button
                        onClick={openModal}
                        className="btn btn-primary"
                    >
                        + Issue Payment to Student
                    </button>
                </div>

                <div className="flex gap-4" style={{ marginBottom: 'var(--space-6)' }}>
                    <select
                        className="form-select"
                        style={{ width: '200px' }}
                        value={filterStatus}
                        onChange={(e) => setFilterStatus(e.target.value)}
                    >
                        <option value="all">All Status</option>
                        <option value="pending">Pending</option>
                        <option value="paid">Paid</option>
                        <option value="overdue">Overdue</option>
                        <option value="partial">Partial</option>
                    </select>

                    <label className="flex items-center gap-2 cursor-pointer bg-white px-4 rounded-lg border border-gray-200" style={{ padding: '0 1rem', height: 'var(--space-10)' }}>
                        <input
                            type="checkbox"
                            checked={filterOverdue}
                            onChange={(e) => setFilterOverdue(e.target.checked)}
                        />
                        <span style={{ fontSize: '0.875rem', fontWeight: 500 }}>Show Overdue Only</span>
                    </label>
                </div>

                {loading ? (
                    <div className="loading-container">
                        <div className="spinner"></div>
                    </div>
                ) : (
                    <DataTable<Payment>
                        columns={[
                            {
                                header: 'Student',
                                accessor: (payment) => (
                                    <>
                                        <div className="font-medium" style={{ color: 'var(--gray-900)' }}>{payment.student_name}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>{payment.registration_number}</div>
                                    </>
                                )
                            },
                            {
                                header: 'Amount',
                                accessor: (payment) => (
                                    <>
                                        <div style={{ fontWeight: 600, color: 'var(--gray-900)' }}>₹{payment.amount}</div>
                                        {payment.payment_date && (
                                            <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>
                                                Paid: {new Date(payment.payment_date).toLocaleDateString()}
                                            </div>
                                        )}
                                    </>
                                )
                            },
                            {
                                header: 'Due Date',
                                accessor: (payment) => (
                                    <>
                                        <div style={{ color: payment.days_overdue && payment.days_overdue > 0 && payment.payment_status !== 'paid' ? 'var(--error-600)' : 'inherit', fontWeight: payment.days_overdue && payment.days_overdue > 0 && payment.payment_status !== 'paid' ? 600 : 400 }}>
                                            {new Date(payment.due_date).toLocaleDateString()}
                                        </div>
                                        {payment.days_overdue && payment.days_overdue > 0 && payment.payment_status !== 'paid' && (
                                            <div style={{ fontSize: '0.75rem', color: 'var(--error-500)' }}>{payment.days_overdue} days overdue</div>
                                        )}
                                    </>
                                )
                            },
                            {
                                header: 'Type/Sem',
                                accessor: (payment) => (
                                    <>
                                        <div>{payment.semester || '-'}</div>
                                        {payment.notes && <div style={{ fontSize: '0.75rem', color: 'var(--gray-400)', maxWidth: '150px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{payment.notes}</div>}
                                    </>
                                )
                            },
                            {
                                header: 'Status',
                                accessor: (payment) => (
                                    <span className={`badge badge-${payment.payment_status}`}>
                                        {payment.payment_status}
                                    </span>
                                )
                            },
                            {
                                header: 'Receipt',
                                accessor: (payment) => (
                                    <span style={{ fontSize: '0.75rem', color: 'var(--gray-500)', fontFamily: 'var(--font-mono)' }}>
                                        {payment.receipt_number || '-'}
                                    </span>
                                )
                            },
                            {
                                header: 'Actions',
                                accessor: (payment) => (
                                    <div className="flex gap-2">
                                        {payment.payment_status !== 'paid' && (
                                            <button
                                                onClick={() => handleMarkAsPaid(payment)}
                                                className="btn btn-sm"
                                                style={{
                                                    padding: '4px 12px',
                                                    fontSize: '0.75rem',
                                                    backgroundColor: 'var(--success-600)',
                                                    color: 'white',
                                                    border: 'none',
                                                    borderRadius: '6px',
                                                    cursor: 'pointer',
                                                    fontWeight: 500
                                                }}
                                                title="Mark as Paid"
                                            >
                                                ✓ Paid
                                            </button>
                                        )}
                                    </div>
                                )
                            }
                        ]}
                        data={payments}
                        emptyMessage="No payments found matching filters"
                    />
                )}

                {isModalOpen && (
                    <div className="modal-overlay">
                        <div className="modal" style={{ maxWidth: '600px' }}>
                            <div className="modal-header">
                                <h2 className="card-title">Issue Payment to Student</h2>
                            </div>

                            <div className="modal-body">
                                {error && (
                                    <div className="alert alert-error">
                                        {error}
                                    </div>
                                )}

                                <form onSubmit={handleSubmit}>
                                    <div className="form-group">
                                        <label className="form-label">Student</label>
                                        <select
                                            className="form-select"
                                            value={formData.student_id}
                                            onChange={(e) => setFormData({ ...formData, student_id: e.target.value })}
                                            required
                                        >
                                            <option value="">Select Student</option>
                                            {students.map(s => (
                                                <option key={s.id} value={s.id}>
                                                    {s.registration_number} - {s.first_name} {s.last_name}
                                                </option>
                                            ))}
                                        </select>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4" style={{ marginBottom: 'var(--space-4)' }}>
                                        <div className="form-group">
                                            <label className="form-label">Amount (₹)</label>
                                            <input
                                                type="number"
                                                className="form-input"
                                                value={formData.amount}
                                                onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                                                required
                                                min="1"
                                            />
                                        </div>
                                        <div className="form-group">
                                            <label className="form-label">Semester</label>
                                            <input
                                                type="text"
                                                className="form-input"
                                                placeholder="e.g. Fall 2024"
                                                value={formData.semester}
                                                onChange={(e) => setFormData({ ...formData, semester: e.target.value })}
                                            />
                                        </div>
                                    </div>

                                    <div className="form-group">
                                        <label className="form-label">Due Date</label>
                                        <input
                                            type="date"
                                            className="form-input"
                                            value={formData.due_date}
                                            onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
                                            required
                                        />
                                    </div>

                                    <div className="form-group">
                                        <label className="form-label">Notes</label>
                                        <textarea
                                            className="form-textarea"
                                            value={formData.notes}
                                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                                        ></textarea>
                                    </div>

                                    <div className="modal-footer">
                                        <button
                                            type="button"
                                            onClick={() => setIsModalOpen(false)}
                                            className="btn btn-secondary"
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            disabled={submitting}
                                            className="btn btn-primary"
                                        >
                                            {submitting ? 'Issuing...' : 'Issue Payment'}
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

