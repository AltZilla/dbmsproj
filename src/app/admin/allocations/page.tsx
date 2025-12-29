'use client';

import { useState, useEffect } from 'react';
import { DataTable } from '@/components/ui/DataTable';

interface Allocation {
    id: number;
    student_id: number;
    room_id: number;
    allocation_date: string;
    expected_checkout: string | null;
    is_active: boolean;
    student_name: string;
    registration_number: string;
    room_number: string;
    hostel_name: string;
}

interface Student {
    id: number;
    first_name: string;
    last_name: string;
    registration_number: string;
}

interface Room {
    id: number;
    room_number: string;
    hostel_name: string;
    available_beds: number;
}

export default function AllocationsPage() {
    const [allocations, setAllocations] = useState<Allocation[]>([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [students, setStudents] = useState<Student[]>([]);
    const [rooms, setRooms] = useState<Room[]>([]);

    // Form state
    const [selectedStudent, setSelectedStudent] = useState('');
    const [selectedRoom, setSelectedRoom] = useState('');
    const [expectedCheckout, setExpectedCheckout] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState('');

    const fetchAllocations = async () => {
        try {
            const res = await fetch('/api/allocations?limit=50&is_active=true');
            const data = await res.json();
            if (data.success) {
                setAllocations(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch allocations:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAllocations();
    }, []);

    const openModal = async () => {
        setIsModalOpen(true);
        // Fetch students and available rooms
        try {
            const [studentsRes, roomsRes] = await Promise.all([
                fetch('/api/students?limit=100&is_active=true'), // Assuming is_active filter or just list all
                fetch('/api/rooms?available=true&has_vacancy=true&limit=100')
            ]);

            const studentsData = await studentsRes.json();
            const roomsData = await roomsRes.json();

            if (studentsData.success) setStudents(studentsData.data);
            if (roomsData.success) setRooms(roomsData.data);
        } catch (err) {
            console.error('Failed to load form data', err);
        }
    };

    const handleAllocate = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSubmitting(true);

        try {
            const res = await fetch('/api/allocations', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    student_id: parseInt(selectedStudent),
                    room_id: parseInt(selectedRoom),
                    expected_checkout: expectedCheckout || undefined
                })
            });

            const data = await res.json();
            if (data.success) {
                setIsModalOpen(false);
                fetchAllocations(); // Refresh list
                setSelectedStudent('');
                setSelectedRoom('');
                setExpectedCheckout('');
            } else {
                setError(data.error || 'Failed to create allocation');
            }
        } catch (err) {
            setError('An error occurred. Please try again.');
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="page-wrapper">
            <div className="container main-content">
                <div className="flex justify-between items-center" style={{ marginBottom: 'var(--space-8)' }}>
                    <div>
                        <h1>Room Allocations</h1>
                        <p className="card-subtitle">Manage student room assignments</p>
                    </div>
                    <button
                        onClick={openModal}
                        className="btn btn-primary"
                    >
                        + New Allocation
                    </button>
                </div>

                {loading ? (
                    <div className="loading-container">
                        <div className="spinner"></div>
                    </div>
                ) : (
                    <DataTable<Allocation>
                        columns={[
                            {
                                header: 'Student',
                                accessor: (row) => (
                                    <>
                                        <div className="font-medium" style={{ color: 'var(--gray-900)' }}>{row.student_name}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>{row.registration_number}</div>
                                    </>
                                )
                            },
                            {
                                header: 'Hostel / Room',
                                accessor: (row) => (
                                    <>
                                        <div>{row.hostel_name}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>Room {row.room_number}</div>
                                    </>
                                )
                            },
                            {
                                header: 'Allocated On',
                                accessor: (row) => (
                                    <span>
                                        {new Date(row.allocation_date).toLocaleDateString()}
                                    </span>
                                )
                            },
                            {
                                header: 'Checkout Due',
                                accessor: (row) => (
                                    <span>
                                        {row.expected_checkout
                                            ? new Date(row.expected_checkout).toLocaleDateString()
                                            : <span style={{ color: 'var(--gray-400)' }}>Not set</span>}
                                    </span>
                                )
                            },
                            {
                                header: 'Status',
                                accessor: (row) => (
                                    <span className={`badge ${row.is_active ? 'badge-paid' : 'badge-closed'}`}>
                                        {row.is_active ? 'Active' : 'Inactive'}
                                    </span>
                                )
                            }
                        ]}
                        data={allocations}
                        emptyMessage="No active allocations found"
                    />
                )}

                {isModalOpen && (
                    <div className="modal-overlay">
                        <div className="modal" style={{ maxWidth: '500px' }}>
                            <div className="modal-header">
                                <h2 className="card-title">Allocate Room</h2>
                            </div>

                            <div className="modal-body">
                                {error && (
                                    <div className="alert alert-error">
                                        {error}
                                    </div>
                                )}

                                <form onSubmit={handleAllocate}>
                                    <div className="form-group">
                                        <label className="form-label">Student</label>
                                        <select
                                            className="form-select"
                                            value={selectedStudent}
                                            onChange={(e) => setSelectedStudent(e.target.value)}
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

                                    <div className="form-group">
                                        <label className="form-label">Room</label>
                                        <select
                                            className="form-select"
                                            value={selectedRoom}
                                            onChange={(e) => setSelectedRoom(e.target.value)}
                                            required
                                        >
                                            <option value="">Select Room</option>
                                            {rooms.map(r => (
                                                <option key={r.id} value={r.id}>
                                                    {r.hostel_name} - {r.room_number} ({r.available_beds} beds left)
                                                </option>
                                            ))}
                                            {rooms.length === 0 && <option disabled>No vacancies available</option>}
                                        </select>
                                    </div>

                                    <div className="form-group">
                                        <label className="form-label">Expected Checkout (Optional)</label>
                                        <input
                                            type="date"
                                            className="form-input"
                                            value={expectedCheckout}
                                            onChange={(e) => setExpectedCheckout(e.target.value)}
                                        />
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
                                            {submitting ? 'Allocating...' : 'Allocate Room'}
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
