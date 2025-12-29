'use client';

import { useState, useEffect } from 'react';
import { DataTable, Column } from '@/components/ui/DataTable';
import { Room, Hostel, PaginatedResponse } from '@/lib/types';
// import styles from './page.module.css';

interface RoomFormData {
    hostel_id: string;
    room_number: string;
    floor: string;
    room_type: 'single' | 'double' | 'triple' | 'dormitory';
    capacity: string;
    rent_amount: string;
    has_ac: boolean;
    has_attached_bathroom: boolean;
}

const initialFormData: RoomFormData = {
    hostel_id: '',
    room_number: '',
    floor: '',
    room_type: 'double',
    capacity: '2',
    rent_amount: '',
    has_ac: false,
    has_attached_bathroom: false
};

export default function RoomsPage() {
    const [rooms, setRooms] = useState<Room[]>([]);
    const [hostels, setHostels] = useState<Hostel[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [formData, setFormData] = useState<RoomFormData>(initialFormData);

    // Filters
    const [filterHostel, setFilterHostel] = useState('');
    const [filterType, setFilterType] = useState('');
    const [page, setPage] = useState(1);
    const [pagination, setPagination] = useState({ totalPages: 1, limit: 10 });

    const fetchRooms = async () => {
        setLoading(true);
        try {
            const params = new URLSearchParams({
                page: page.toString(),
                limit: pagination.limit.toString()
            });
            if (filterHostel) params.append('hostel_id', filterHostel);
            if (filterType) params.append('room_type', filterType);

            const res = await fetch(`/api/rooms?${params}`);
            const data: PaginatedResponse<Room> = await res.json();

            if (data.success) {
                setRooms(data.data);
                setPagination(prev => ({ ...prev, totalPages: data.pagination.totalPages }));
            }
        } catch (error) {
            console.error('Failed to fetch rooms:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchHostels = async () => {
        try {
            const res = await fetch('/api/hostels?limit=100');
            const data = await res.json();
            if (data.success) {
                setHostels(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch hostels:', error);
        }
    };

    useEffect(() => {
        fetchHostels();
    }, []);

    useEffect(() => {
        fetchRooms();
    }, [page, filterHostel, filterType]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);

        try {
            const payload = {
                ...formData,
                hostel_id: parseInt(formData.hostel_id),
                floor: parseInt(formData.floor),
                capacity: parseInt(formData.capacity),
                rent_amount: parseFloat(formData.rent_amount)
            };

            const res = await fetch('/api/rooms', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const data = await res.json();

            if (data.success) {
                setShowModal(false);
                setFormData(initialFormData);
                fetchRooms();
            } else {
                alert(data.error || 'Failed to create room');
            }
        } catch (error) {
            console.error('Error creating room:', error);
            alert('An error occurred');
        } finally {
            setSubmitting(false);
        }
    };

    const columns: Column<Room>[] = [
        {
            header: 'Room No.',
            accessor: 'room_number',
            className: 'font-medium'
        },
        {
            header: 'Hostel',
            accessor: (room) => room.hostel_name || '-'
        },
        {
            header: 'Floor',
            accessor: 'floor'
        },
        {
            header: 'Type',
            accessor: (room) => (
                <span style={{ textTransform: 'capitalize' }}>{room.room_type}</span>
            )
        },
        {
            header: 'Capacity',
            accessor: (room) => (
                <span>
                    {room.current_occupancy} / {room.capacity}
                </span>
            )
        },
        {
            header: 'Rent (₹)',
            accessor: (room) => parseFloat(room.rent_amount.toString()).toLocaleString()
        },
        {
            header: 'Status',
            accessor: (room) => {
                if (!room.is_available) {
                    return <span className='badge badge-pending'>Maintenance</span>;
                }
                if (room.current_occupancy >= room.capacity) {
                    return <span className='badge badge-overdue'>Full</span>;
                }
                return <span className='badge badge-resolved'>Available</span>;
            }
        },
        {
            header: 'Amenities',
            accessor: (room) => (
                <div className="flex gap-1">
                    {room.has_ac && <span className="text-xs bg-blue-100 text-blue-700 px-1 rounded">AC</span>}
                    {room.has_attached_bathroom && <span className="text-xs bg-green-100 text-green-700 px-1 rounded">Bath</span>}
                </div>
            )
        }
    ];

    return (
        <div className="bg-gray-50 min-h-screen">
            <div className="container">
                <div className="page-header">
                    <div>
                        <h1 className="page-title">Manage Rooms</h1>
                        <p className="page-subtitle">Overview of all hostel rooms and occupancy</p>
                    </div>
                    <button className="btn btn-primary" onClick={() => setShowModal(true)}>
                        <span>+</span> Add Room
                    </button>
                </div>

                <div className="filters-bar">
                    <select
                        className="form-select"
                        style={{ maxWidth: '200px' }}
                        value={filterHostel}
                        onChange={(e) => setFilterHostel(e.target.value)}
                    >
                        <option value="">All Hostels</option>
                        {hostels.map(h => (
                            <option key={h.id} value={h.id}>{h.name}</option>
                        ))}
                    </select>

                    <select
                        className="form-select"
                        style={{ maxWidth: '150px' }}
                        value={filterType}
                        onChange={(e) => setFilterType(e.target.value)}
                    >
                        <option value="">All Types</option>
                        <option value="single">Single</option>
                        <option value="double">Double</option>
                        <option value="triple">Triple</option>
                        <option value="dormitory">Dormitory</option>
                    </select>
                </div>

                {loading ? (
                    <div className="flex justify-center p-12"><div className="spinner"></div></div>
                ) : (
                    <>
                        <DataTable
                            columns={columns}
                            data={rooms}
                            emptyMessage="No rooms found matching your criteria"
                        />

                        <div className="pagination">
                            <button
                                className="btn btn-secondary btn-sm"
                                disabled={page === 1}
                                onClick={() => setPage(p => p - 1)}
                            >
                                Previous
                            </button>
                            <span className="self-center font-medium">
                                Page {page} of {pagination.totalPages}
                            </span>
                            <button
                                className="btn btn-secondary btn-sm"
                                disabled={page === pagination.totalPages}
                                onClick={() => setPage(p => p + 1)}
                            >
                                Next
                            </button>
                        </div>
                    </>
                )}
            </div>

            {/* Add Room Modal */}
            {showModal && (
                <div className="modal-overlay">
                    <div className="modal">
                        <div className="modal-header">
                            <h2 className="modal-title">Add New Room</h2>
                            <button className="btn-close" onClick={() => setShowModal(false)}>×</button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div className="modal-body">
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="form-group">
                                        <label className="form-label">Hostel *</label>
                                        <select
                                            className="form-select"
                                            required
                                            value={formData.hostel_id}
                                            onChange={(e) => setFormData({ ...formData, hostel_id: e.target.value })}
                                        >
                                            <option value="">Select Hostel</option>
                                            {hostels.map(h => (
                                                <option key={h.id} value={h.id}>{h.name}</option>
                                            ))}
                                        </select>
                                    </div>
                                    <div className="form-group">
                                        <label className="form-label">Room Number *</label>
                                        <input
                                            className="form-input"
                                            required
                                            type="text"
                                            placeholder="e.g. A-101"
                                            value={formData.room_number}
                                            onChange={(e) => setFormData({ ...formData, room_number: e.target.value })}
                                        />
                                    </div>
                                    <div className="form-group">
                                        <label className="form-label">Floor *</label>
                                        <input
                                            className="form-input"
                                            required
                                            type="number"
                                            min="0"
                                            value={formData.floor}
                                            onChange={(e) => setFormData({ ...formData, floor: e.target.value })}
                                        />
                                    </div>
                                    <div className="form-group">
                                        <label className="form-label">Room Type</label>
                                        <select
                                            className="form-select"
                                            value={formData.room_type}
                                            onChange={(e) => setFormData({
                                                ...formData,
                                                room_type: e.target.value as 'single' | 'double' | 'triple' | 'dormitory'
                                            })}
                                        >
                                            <option value="single">Single</option>
                                            <option value="double">Double</option>
                                            <option value="triple">Triple</option>
                                            <option value="dormitory">Dormitory</option>
                                        </select>
                                    </div>
                                    <div className="form-group">
                                        <label className="form-label">Capacity *</label>
                                        <input
                                            className="form-input"
                                            required
                                            type="number"
                                            min="1"
                                            max="10"
                                            value={formData.capacity}
                                            onChange={(e) => setFormData({ ...formData, capacity: e.target.value })}
                                        />
                                    </div>
                                    <div className="form-group">
                                        <label className="form-label">Annual Rent (₹) *</label>
                                        <input
                                            className="form-input"
                                            required
                                            type="number"
                                            min="0"
                                            step="1000"
                                            value={formData.rent_amount}
                                            onChange={(e) => setFormData({ ...formData, rent_amount: e.target.value })}
                                        />
                                    </div>
                                    <div className="form-check col-span-2">
                                        <input
                                            type="checkbox"
                                            id="has_ac"
                                            checked={formData.has_ac}
                                            onChange={(e) => setFormData({ ...formData, has_ac: e.target.checked })}
                                        />
                                        <label htmlFor="has_ac" className="form-label mb-0">Air Conditioning</label>
                                    </div>
                                    <div className="form-check col-span-2">
                                        <input
                                            type="checkbox"
                                            id="has_bath"
                                            checked={formData.has_attached_bathroom}
                                            onChange={(e) => setFormData({ ...formData, has_attached_bathroom: e.target.checked })}
                                        />
                                        <label htmlFor="has_bath" className="form-label mb-0">Attached Bathroom</label>
                                    </div>
                                </div>
                            </div>
                            <div className="modal-footer">
                                <button
                                    type="button"
                                    className="btn btn-secondary"
                                    onClick={() => setShowModal(false)}
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    className="btn btn-primary"
                                    disabled={submitting}
                                >
                                    {submitting ? 'Creating...' : 'Create Room'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
