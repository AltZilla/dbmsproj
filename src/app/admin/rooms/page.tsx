'use client';

/**
 * Unified Room Management
 * =======================
 * Combines room management (table view) and room assignment (grid view) into one page.
 * Features a tabbed interface for switching between views.
 */

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { DataTable, Column } from '@/components/ui/DataTable';
import { Room, Hostel, PaginatedResponse } from '@/lib/types';

// ============ TYPES ============

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

interface Student {
    id: number;
    first_name: string;
    last_name: string;
    registration_number: string;
    email: string;
    gender: 'male' | 'female' | 'other';
    department: string | null;
}

interface Allocation {
    id: number;
    student_id: number;
    room_id: number;
    allocation_date: string;
    expected_checkout: string | null;
    is_active: boolean;
    student_name: string;
    registration_number: string;
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

type ViewMode = 'table' | 'grid';

export default function RoomsPage() {
    // View mode
    const [viewMode, setViewMode] = useState<ViewMode>('table');

    // Shared state
    const [rooms, setRooms] = useState<Room[]>([]);
    const [hostels, setHostels] = useState<Hostel[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [formData, setFormData] = useState<RoomFormData>(initialFormData);

    // Table view state
    const [filterHostel, setFilterHostel] = useState('');
    const [filterType, setFilterType] = useState('');
    const [page, setPage] = useState(1);
    const [pagination, setPagination] = useState({ totalPages: 1, limit: 10 });

    // Grid view state
    const [selectedHostel, setSelectedHostel] = useState<number | null>(null);
    const [selectedRoom, setSelectedRoom] = useState<Room | null>(null);
    const [roomAllocations, setRoomAllocations] = useState<Allocation[]>([]);
    const [unassignedStudents, setUnassignedStudents] = useState<Student[]>([]);
    const [sidebarLoading, setSidebarLoading] = useState(false);

    // Assignment modal states
    const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
    const [isMoveModalOpen, setIsMoveModalOpen] = useState(false);
    const [selectedStudent, setSelectedStudent] = useState<string>('');
    const [selectedStudentToMove, setSelectedStudentToMove] = useState<Allocation | null>(null);
    const [targetRoom, setTargetRoom] = useState<string>('');
    const [expectedCheckout, setExpectedCheckout] = useState('');

    // Messages
    const [error, setError] = useState('');
    const [successMessage, setSuccessMessage] = useState('');

    // ============ DATA FETCHING ============

    const fetchHostels = async () => {
        try {
            const res = await fetch('/api/hostels?limit=100');
            const data = await res.json();
            if (data.success) {
                setHostels(data.data);
                if (data.data.length > 0 && !selectedHostel) {
                    setSelectedHostel(data.data[0].id);
                }
            }
        } catch (error) {
            console.error('Failed to fetch hostels:', error);
        }
    };

    // Fetch rooms for table view
    const fetchRoomsTable = async () => {
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

    // Fetch rooms for grid view
    const fetchRoomsGrid = async () => {
        if (!selectedHostel) return;
        setLoading(true);
        try {
            const res = await fetch(`/api/rooms?hostel_id=${selectedHostel}&limit=100`);
            const data = await res.json();
            if (data.success) {
                setRooms(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch rooms:', error);
        } finally {
            setLoading(false);
        }
    };

    // Fetch room details and allocations
    const fetchRoomDetails = useCallback(async (room: Room) => {
        setSidebarLoading(true);
        setSelectedRoom(room);
        try {
            const res = await fetch(`/api/allocations?room_id=${room.id}&is_active=true&limit=20`);
            const data = await res.json();
            if (data.success) {
                setRoomAllocations(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch room allocations:', error);
        } finally {
            setSidebarLoading(false);
        }
    }, []);

    // Fetch unassigned students for assignment
    const fetchUnassignedStudents = async () => {
        try {
            const studentsRes = await fetch('/api/students?active=true&limit=200');
            const studentsData = await studentsRes.json();

            const allocationsRes = await fetch('/api/allocations?is_active=true&limit=500');
            const allocationsData = await allocationsRes.json();

            if (studentsData.success) {
                const allocatedStudentIds = new Set(
                    allocationsData.success
                        ? allocationsData.data.map((a: Allocation) => a.student_id)
                        : []
                );

                const currentHostel = hostels.find(h => h.id === selectedHostel);
                const unassigned = studentsData.data.filter((s: Student) => {
                    const isUnassigned = !allocatedStudentIds.has(s.id);
                    const genderMatch = !currentHostel ||
                        currentHostel.gender_allowed === 'other' ||
                        s.gender === currentHostel.gender_allowed;
                    return isUnassigned && genderMatch;
                });

                setUnassignedStudents(unassigned);
            }
        } catch (error) {
            console.error('Failed to fetch students:', error);
        }
    };

    // ============ EFFECTS ============

    useEffect(() => {
        fetchHostels();
    }, []);

    useEffect(() => {
        if (viewMode === 'table') {
            fetchRoomsTable();
        }
    }, [viewMode, page, filterHostel, filterType]);

    useEffect(() => {
        if (viewMode === 'grid' && selectedHostel) {
            fetchRoomsGrid();
            setSelectedRoom(null);
        }
    }, [viewMode, selectedHostel]);

    useEffect(() => {
        if (successMessage) {
            const timer = setTimeout(() => setSuccessMessage(''), 3000);
            return () => clearTimeout(timer);
        }
    }, [successMessage]);

    useEffect(() => {
        if (error) {
            const timer = setTimeout(() => setError(''), 5000);
            return () => clearTimeout(timer);
        }
    }, [error]);

    // ============ HANDLERS ============

    const handleSubmitRoom = async (e: React.FormEvent) => {
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
                setSuccessMessage('Room created successfully!');
                if (viewMode === 'table') {
                    fetchRoomsTable();
                } else {
                    fetchRoomsGrid();
                }
            } else {
                setError(data.error || 'Failed to create room');
            }
        } catch (err) {
            console.error('Error creating room:', err);
            setError('An error occurred');
        } finally {
            setSubmitting(false);
        }
    };

    const handleAssignStudent = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedRoom || !selectedStudent) return;

        setSubmitting(true);
        setError('');

        try {
            const res = await fetch('/api/allocations', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    student_id: parseInt(selectedStudent),
                    room_id: selectedRoom.id,
                    expected_checkout: expectedCheckout || undefined
                })
            });

            const data = await res.json();
            if (data.success) {
                setSuccessMessage('Student assigned successfully!');
                setIsAssignModalOpen(false);
                setSelectedStudent('');
                setExpectedCheckout('');
                fetchRoomDetails(selectedRoom);
                fetchRoomsGrid();
            } else {
                setError(data.error || 'Failed to assign student');
            }
        } catch (err) {
            setError('An error occurred. Please try again.');
        } finally {
            setSubmitting(false);
        }
    };

    const handleRemoveStudent = async (allocation: Allocation) => {
        if (!confirm(`Are you sure you want to remove ${allocation.student_name} from this room?`)) {
            return;
        }

        try {
            const res = await fetch(`/api/allocations/${allocation.id}`, {
                method: 'DELETE'
            });

            const data = await res.json();
            if (data.success) {
                setSuccessMessage('Student removed successfully!');
                if (selectedRoom) {
                    fetchRoomDetails(selectedRoom);
                }
                fetchRoomsGrid();
            } else {
                setError(data.error || 'Failed to remove student');
            }
        } catch (err) {
            setError('An error occurred');
        }
    };

    const handleMoveStudent = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedStudentToMove || !targetRoom) return;

        setSubmitting(true);
        setError('');

        try {
            await fetch(`/api/allocations/${selectedStudentToMove.id}`, {
                method: 'DELETE'
            });

            const res = await fetch('/api/allocations', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    student_id: selectedStudentToMove.student_id,
                    room_id: parseInt(targetRoom),
                    expected_checkout: expectedCheckout || undefined
                })
            });

            const data = await res.json();
            if (data.success) {
                setSuccessMessage('Student moved successfully!');
                setIsMoveModalOpen(false);
                setSelectedStudentToMove(null);
                setTargetRoom('');
                setExpectedCheckout('');
                if (selectedRoom) {
                    fetchRoomDetails(selectedRoom);
                }
                fetchRoomsGrid();
            } else {
                setError(data.error || 'Failed to move student');
            }
        } catch (err) {
            setError('An error occurred');
        } finally {
            setSubmitting(false);
        }
    };

    const openAssignModal = () => {
        setIsAssignModalOpen(true);
        fetchUnassignedStudents();
    };

    const openMoveModal = (allocation: Allocation) => {
        setSelectedStudentToMove(allocation);
        setIsMoveModalOpen(true);
    };

    // ============ GRID HELPERS ============

    const getRoomStatus = (room: Room) => {
        if (!room.is_available) return 'maintenance';
        if (room.current_occupancy >= room.capacity) return 'full';
        if (room.current_occupancy > 0) return 'partial';
        return 'empty';
    };

    const getRoomStatusColor = (status: string) => {
        switch (status) {
            case 'full': return 'room-full';
            case 'partial': return 'room-partial';
            case 'empty': return 'room-empty';
            case 'maintenance': return 'room-maintenance';
            default: return '';
        }
    };

    const roomsByFloor = rooms.reduce((acc, room) => {
        const floor = room.floor;
        if (!acc[floor]) acc[floor] = [];
        acc[floor].push(room);
        return acc;
    }, {} as Record<number, Room[]>);

    const sortedFloors = Object.keys(roomsByFloor).map(Number).sort((a, b) => b - a);

    const availableRoomsForMove = rooms.filter(r =>
        r.id !== selectedRoom?.id &&
        r.is_available &&
        r.current_occupancy < r.capacity
    );

    // ============ TABLE COLUMNS ============

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

    // ============ RENDER ============

    return (
        <div className="room-management-page">
            {/* Header */}
            <div className="page-header-unified">
                <div>
                    <div className="breadcrumb">
                        <Link href="/admin">Admin</Link>
                        <span>/</span>
                        <span>Rooms</span>
                    </div>
                    <h1 className="page-title">Room Management</h1>
                    <p className="page-subtitle">Manage rooms and assignments in one place</p>
                </div>
                <div className="header-actions">
                    <button className="btn btn-primary" onClick={() => setShowModal(true)}>
                        <span>+</span> Add Room
                    </button>
                </div>
            </div>

            {/* View Toggle Tabs */}
            <div className="view-tabs">
                <button
                    className={`view-tab ${viewMode === 'table' ? 'active' : ''}`}
                    onClick={() => setViewMode('table')}
                >
                    <span className="tab-icon">📋</span>
                    <span className="tab-label">Table View</span>
                </button>
                <button
                    className={`view-tab ${viewMode === 'grid' ? 'active' : ''}`}
                    onClick={() => setViewMode('grid')}
                >
                    <span className="tab-icon">🏠</span>
                    <span className="tab-label">Grid View</span>
                </button>
            </div>

            {/* Messages */}
            {successMessage && (
                <div className="alert alert-success">{successMessage}</div>
            )}
            {error && (
                <div className="alert alert-error">{error}</div>
            )}

            {/* ============ TABLE VIEW ============ */}
            {viewMode === 'table' && (
                <div className="table-view-container">
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
            )}

            {/* ============ GRID VIEW ============ */}
            {viewMode === 'grid' && (
                <div className="grid-view-container">
                    {/* Hostel Selector */}
                    <div className="grid-controls">
                        <select
                            className="form-select hostel-select"
                            value={selectedHostel || ''}
                            onChange={(e) => setSelectedHostel(parseInt(e.target.value))}
                        >
                            {hostels.map(h => (
                                <option key={h.id} value={h.id}>
                                    {h.name} ({h.gender_allowed})
                                </option>
                            ))}
                        </select>
                    </div>

                    <div className="assignment-container">
                        {/* Room Grid */}
                        <div className="room-grid-container">
                            {/* Legend */}
                            <div className="room-legend">
                                <div className="legend-item">
                                    <span className="legend-color room-empty"></span>
                                    <span>Available</span>
                                </div>
                                <div className="legend-item">
                                    <span className="legend-color room-partial"></span>
                                    <span>Partially Occupied</span>
                                </div>
                                <div className="legend-item">
                                    <span className="legend-color room-full"></span>
                                    <span>Full</span>
                                </div>
                                <div className="legend-item">
                                    <span className="legend-color room-maintenance"></span>
                                    <span>Maintenance</span>
                                </div>
                            </div>

                            {loading ? (
                                <div className="loading-container">
                                    <div className="spinner"></div>
                                </div>
                            ) : rooms.length === 0 ? (
                                <div className="empty-state">
                                    <div className="empty-state-icon">🏠</div>
                                    <p>No rooms found in this hostel</p>
                                </div>
                            ) : (
                                <div className="floors-container">
                                    {sortedFloors.map(floor => (
                                        <div key={floor} className="floor-section">
                                            <div className="floor-header">
                                                <span className="floor-label">Floor {floor}</span>
                                                <span className="floor-count">{roomsByFloor[floor].length} rooms</span>
                                            </div>
                                            <div className="room-grid">
                                                {roomsByFloor[floor]
                                                    .sort((a, b) => a.room_number.localeCompare(b.room_number))
                                                    .map(room => {
                                                        const status = getRoomStatus(room);
                                                        const isSelected = selectedRoom?.id === room.id;
                                                        return (
                                                            <div
                                                                key={room.id}
                                                                className={`room-card ${getRoomStatusColor(status)} ${isSelected ? 'selected' : ''}`}
                                                                onClick={() => fetchRoomDetails(room)}
                                                            >
                                                                <div className="room-number">{room.room_number}</div>
                                                                <div className="room-occupancy">
                                                                    <span className="occupancy-current">{room.current_occupancy}</span>
                                                                    <span className="occupancy-divider">/</span>
                                                                    <span className="occupancy-capacity">{room.capacity}</span>
                                                                </div>
                                                                <div className="room-type">{room.room_type}</div>
                                                                <div className="room-amenities">
                                                                    {room.has_ac && <span title="Air Conditioning">❄️</span>}
                                                                    {room.has_attached_bathroom && <span title="Attached Bathroom">🚿</span>}
                                                                </div>
                                                            </div>
                                                        );
                                                    })}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>

                        {/* Room Details Sidebar */}
                        <div className={`room-sidebar ${selectedRoom ? 'open' : ''}`}>
                            {selectedRoom ? (
                                <>
                                    <div className="sidebar-header">
                                        <div className="sidebar-title">
                                            <h2>Room {selectedRoom.room_number}</h2>
                                            <span className={`badge ${selectedRoom.is_available ? 'badge-resolved' : 'badge-pending'}`}>
                                                {selectedRoom.is_available ? 'Available' : 'Maintenance'}
                                            </span>
                                        </div>
                                        <button
                                            className="btn-close"
                                            onClick={() => setSelectedRoom(null)}
                                        >
                                            ×
                                        </button>
                                    </div>

                                    <div className="sidebar-content">
                                        {/* Room Info */}
                                        <div className="room-info-section">
                                            <div className="info-grid">
                                                <div className="info-item">
                                                    <span className="info-label">Type</span>
                                                    <span className="info-value capitalize">{selectedRoom.room_type}</span>
                                                </div>
                                                <div className="info-item">
                                                    <span className="info-label">Floor</span>
                                                    <span className="info-value">{selectedRoom.floor}</span>
                                                </div>
                                                <div className="info-item">
                                                    <span className="info-label">Capacity</span>
                                                    <span className="info-value">{selectedRoom.current_occupancy} / {selectedRoom.capacity}</span>
                                                </div>
                                                <div className="info-item">
                                                    <span className="info-label">Rent</span>
                                                    <span className="info-value">₹{selectedRoom.rent_amount.toLocaleString()}</span>
                                                </div>
                                            </div>
                                            <div className="amenities-row">
                                                {selectedRoom.has_ac && (
                                                    <span className="amenity-tag">❄️ AC</span>
                                                )}
                                                {selectedRoom.has_attached_bathroom && (
                                                    <span className="amenity-tag">🚿 Attached Bath</span>
                                                )}
                                            </div>
                                        </div>

                                        {/* Current Occupants */}
                                        <div className="occupants-section">
                                            <div className="section-header-small">
                                                <h3>Current Occupants</h3>
                                                {selectedRoom.current_occupancy < selectedRoom.capacity && selectedRoom.is_available && (
                                                    <button
                                                        className="btn btn-primary btn-sm"
                                                        onClick={openAssignModal}
                                                    >
                                                        + Add Student
                                                    </button>
                                                )}
                                            </div>

                                            {sidebarLoading ? (
                                                <div className="loading-container small">
                                                    <div className="spinner small"></div>
                                                </div>
                                            ) : roomAllocations.length === 0 ? (
                                                <div className="empty-occupants">
                                                    <span className="empty-icon">👤</span>
                                                    <p>No students assigned</p>
                                                    {selectedRoom.is_available && (
                                                        <button
                                                            className="btn btn-primary btn-sm"
                                                            onClick={openAssignModal}
                                                        >
                                                            Assign First Student
                                                        </button>
                                                    )}
                                                </div>
                                            ) : (
                                                <div className="occupants-list">
                                                    {roomAllocations.map(allocation => (
                                                        <div key={allocation.id} className="occupant-card">
                                                            <div className="occupant-avatar">
                                                                {allocation.student_name.charAt(0).toUpperCase()}
                                                            </div>
                                                            <div className="occupant-info">
                                                                <div className="occupant-name">{allocation.student_name}</div>
                                                                <div className="occupant-reg">{allocation.registration_number}</div>
                                                                <div className="occupant-date">
                                                                    Since {new Date(allocation.allocation_date).toLocaleDateString()}
                                                                </div>
                                                            </div>
                                                            <div className="occupant-actions">
                                                                <button
                                                                    className="action-btn move"
                                                                    title="Move to another room"
                                                                    onClick={() => openMoveModal(allocation)}
                                                                >
                                                                    ↔️
                                                                </button>
                                                                <button
                                                                    className="action-btn remove"
                                                                    title="Remove from room"
                                                                    onClick={() => handleRemoveStudent(allocation)}
                                                                >
                                                                    ✕
                                                                </button>
                                                            </div>
                                                        </div>
                                                    ))}
                                                </div>
                                            )}
                                        </div>

                                        {/* Vacant Beds Indicator */}
                                        {selectedRoom.is_available && selectedRoom.current_occupancy < selectedRoom.capacity && (
                                            <div className="vacant-beds-indicator">
                                                <span className="vacant-count">
                                                    {selectedRoom.capacity - selectedRoom.current_occupancy}
                                                </span>
                                                <span className="vacant-label">
                                                    bed{selectedRoom.capacity - selectedRoom.current_occupancy > 1 ? 's' : ''} available
                                                </span>
                                            </div>
                                        )}
                                    </div>
                                </>
                            ) : (
                                <div className="sidebar-empty">
                                    <div className="empty-icon">🏠</div>
                                    <p>Select a room to view details</p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {/* ============ ADD ROOM MODAL ============ */}
            {showModal && (
                <div className="modal-overlay">
                    <div className="modal">
                        <div className="modal-header">
                            <h2 className="modal-title">Add New Room</h2>
                            <button className="btn-close" onClick={() => setShowModal(false)}>×</button>
                        </div>
                        <form onSubmit={handleSubmitRoom}>
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

            {/* ============ ASSIGN STUDENT MODAL ============ */}
            {isAssignModalOpen && (
                <div className="modal-overlay">
                    <div className="modal" style={{ maxWidth: '500px' }}>
                        <div className="modal-header">
                            <h2 className="modal-title">
                                Assign Student to Room {selectedRoom?.room_number}
                            </h2>
                            <button
                                className="btn-close"
                                onClick={() => setIsAssignModalOpen(false)}
                            >
                                ×
                            </button>
                        </div>
                        <form onSubmit={handleAssignStudent}>
                            <div className="modal-body">
                                <div className="form-group">
                                    <label className="form-label">Select Student</label>
                                    <select
                                        className="form-select"
                                        value={selectedStudent}
                                        onChange={(e) => setSelectedStudent(e.target.value)}
                                        required
                                    >
                                        <option value="">Choose a student...</option>
                                        {unassignedStudents.map(s => (
                                            <option key={s.id} value={s.id}>
                                                {s.registration_number} - {s.first_name} {s.last_name}
                                                {s.department ? ` (${s.department})` : ''}
                                            </option>
                                        ))}
                                    </select>
                                    {unassignedStudents.length === 0 && (
                                        <p className="form-hint">No unassigned students available for this hostel</p>
                                    )}
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
                            </div>
                            <div className="modal-footer">
                                <button
                                    type="button"
                                    className="btn btn-secondary"
                                    onClick={() => setIsAssignModalOpen(false)}
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    className="btn btn-primary"
                                    disabled={submitting || !selectedStudent}
                                >
                                    {submitting ? 'Assigning...' : 'Assign Student'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* ============ MOVE STUDENT MODAL ============ */}
            {isMoveModalOpen && selectedStudentToMove && (
                <div className="modal-overlay">
                    <div className="modal" style={{ maxWidth: '500px' }}>
                        <div className="modal-header">
                            <h2 className="modal-title">
                                Move {selectedStudentToMove.student_name}
                            </h2>
                            <button
                                className="btn-close"
                                onClick={() => {
                                    setIsMoveModalOpen(false);
                                    setSelectedStudentToMove(null);
                                }}
                            >
                                ×
                            </button>
                        </div>
                        <form onSubmit={handleMoveStudent}>
                            <div className="modal-body">
                                <div className="move-info">
                                    <p>
                                        Moving <strong>{selectedStudentToMove.student_name}</strong>
                                        from Room <strong>{selectedRoom?.room_number}</strong>
                                    </p>
                                </div>

                                <div className="form-group">
                                    <label className="form-label">Target Room</label>
                                    <select
                                        className="form-select"
                                        value={targetRoom}
                                        onChange={(e) => setTargetRoom(e.target.value)}
                                        required
                                    >
                                        <option value="">Select a room...</option>
                                        {availableRoomsForMove.map(r => (
                                            <option key={r.id} value={r.id}>
                                                {r.room_number} - {r.room_type}
                                                ({r.capacity - r.current_occupancy} beds available)
                                            </option>
                                        ))}
                                    </select>
                                    {availableRoomsForMove.length === 0 && (
                                        <p className="form-hint">No rooms with available space in this hostel</p>
                                    )}
                                </div>

                                <div className="form-group">
                                    <label className="form-label">New Expected Checkout (Optional)</label>
                                    <input
                                        type="date"
                                        className="form-input"
                                        value={expectedCheckout}
                                        onChange={(e) => setExpectedCheckout(e.target.value)}
                                    />
                                </div>
                            </div>
                            <div className="modal-footer">
                                <button
                                    type="button"
                                    className="btn btn-secondary"
                                    onClick={() => {
                                        setIsMoveModalOpen(false);
                                        setSelectedStudentToMove(null);
                                    }}
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    className="btn btn-primary"
                                    disabled={submitting || !targetRoom}
                                >
                                    {submitting ? 'Moving...' : 'Move Student'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            <style jsx>{`
                .room-management-page {
                    min-height: 100vh;
                    background: var(--gray-50);
                    padding: var(--space-6);
                }

                .page-header-unified {
                    display: flex;
                    justify-content: space-between;
                    align-items: flex-start;
                    margin-bottom: var(--space-6);
                    flex-wrap: wrap;
                    gap: var(--space-4);
                }

                .breadcrumb {
                    display: flex;
                    align-items: center;
                    gap: var(--space-2);
                    font-size: 0.875rem;
                    color: var(--gray-500);
                    margin-bottom: var(--space-2);
                }

                .breadcrumb a {
                    color: var(--primary-600);
                }

                .breadcrumb a:hover {
                    text-decoration: underline;
                }

                /* View Tabs */
                .view-tabs {
                    display: flex;
                    gap: var(--space-2);
                    margin-bottom: var(--space-6);
                    padding: var(--space-1);
                    background: white;
                    border-radius: var(--radius-xl);
                    box-shadow: var(--shadow-sm);
                    width: fit-content;
                }

                .view-tab {
                    display: flex;
                    align-items: center;
                    gap: var(--space-2);
                    padding: var(--space-3) var(--space-5);
                    border: none;
                    background: transparent;
                    border-radius: var(--radius-lg);
                    cursor: pointer;
                    font-weight: 500;
                    color: var(--gray-500);
                    transition: all 0.2s ease;
                }

                .view-tab:hover {
                    background: var(--gray-50);
                    color: var(--gray-700);
                }

                .view-tab.active {
                    background: var(--gradient-primary);
                    color: white;
                    box-shadow: var(--shadow-md);
                }

                .tab-icon {
                    font-size: 1.125rem;
                }

                .tab-label {
                    font-size: 0.875rem;
                }

                /* Table View */
                .table-view-container {
                    background: white;
                    border-radius: var(--radius-xl);
                    padding: var(--space-6);
                    box-shadow: var(--shadow-md);
                }

                /* Grid View */
                .grid-view-container {
                    display: flex;
                    flex-direction: column;
                    gap: var(--space-6);
                }

                .grid-controls {
                    display: flex;
                    justify-content: flex-end;
                }

                .hostel-select {
                    min-width: 200px;
                    font-weight: 500;
                }

                .assignment-container {
                    display: grid;
                    grid-template-columns: 1fr 380px;
                    gap: var(--space-6);
                    align-items: start;
                }

                @media (max-width: 1024px) {
                    .assignment-container {
                        grid-template-columns: 1fr;
                    }

                    .room-sidebar {
                        position: fixed;
                        bottom: 0;
                        left: 0;
                        right: 0;
                        max-height: 70vh;
                        z-index: 40;
                        transform: translateY(100%);
                        transition: transform 0.3s ease;
                    }

                    .room-sidebar.open {
                        transform: translateY(0);
                    }
                }

                /* Room Grid */
                .room-grid-container {
                    background: white;
                    border-radius: var(--radius-xl);
                    padding: var(--space-6);
                    box-shadow: var(--shadow-md);
                }

                .room-legend {
                    display: flex;
                    gap: var(--space-6);
                    margin-bottom: var(--space-6);
                    padding-bottom: var(--space-4);
                    border-bottom: 1px solid var(--gray-100);
                    flex-wrap: wrap;
                }

                .legend-item {
                    display: flex;
                    align-items: center;
                    gap: var(--space-2);
                    font-size: 0.875rem;
                    color: var(--gray-600);
                }

                .legend-color {
                    width: 16px;
                    height: 16px;
                    border-radius: var(--radius-sm);
                }

                .room-empty {
                    background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
                    border: 1px solid #6ee7b7;
                }

                .room-partial {
                    background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
                    border: 1px solid #fbbf24;
                }

                .room-full {
                    background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
                    border: 1px solid #a5b4fc;
                }

                .room-maintenance {
                    background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
                    border: 1px solid #fca5a5;
                }

                .floors-container {
                    display: flex;
                    flex-direction: column;
                    gap: var(--space-8);
                }

                .floor-header {
                    display: flex;
                    align-items: center;
                    gap: var(--space-3);
                    margin-bottom: var(--space-4);
                }

                .floor-label {
                    font-weight: 600;
                    font-size: 1rem;
                    color: var(--gray-800);
                }

                .floor-count {
                    font-size: 0.875rem;
                    color: var(--gray-500);
                }

                .room-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
                    gap: var(--space-3);
                }

                .room-card {
                    padding: var(--space-4);
                    border-radius: var(--radius-lg);
                    cursor: pointer;
                    transition: all 0.2s ease;
                    text-align: center;
                    position: relative;
                }

                .room-card:hover {
                    transform: translateY(-2px);
                    box-shadow: var(--shadow-md);
                }

                .room-card.selected {
                    box-shadow: 0 0 0 3px var(--primary-200), var(--shadow-md);
                }

                .room-number {
                    font-weight: 700;
                    font-size: 1.125rem;
                    color: var(--gray-800);
                    margin-bottom: var(--space-1);
                }

                .room-occupancy {
                    font-size: 0.875rem;
                    color: var(--gray-600);
                    margin-bottom: var(--space-1);
                }

                .occupancy-current {
                    font-weight: 600;
                }

                .occupancy-divider {
                    margin: 0 2px;
                }

                .room-type {
                    font-size: 0.75rem;
                    color: var(--gray-500);
                    text-transform: capitalize;
                }

                .room-amenities {
                    display: flex;
                    justify-content: center;
                    gap: var(--space-1);
                    margin-top: var(--space-2);
                    font-size: 0.875rem;
                }

                /* Sidebar */
                .room-sidebar {
                    background: white;
                    border-radius: var(--radius-xl);
                    box-shadow: var(--shadow-lg);
                    overflow: hidden;
                    position: sticky;
                    top: var(--space-6);
                }

                .sidebar-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: flex-start;
                    padding: var(--space-5);
                    background: linear-gradient(135deg, var(--primary-600) 0%, var(--primary-700) 100%);
                    color: white;
                }

                .sidebar-title h2 {
                    color: white;
                    font-size: 1.25rem;
                    margin-bottom: var(--space-2);
                }

                .sidebar-header .btn-close {
                    color: white;
                    opacity: 0.8;
                }

                .sidebar-header .btn-close:hover {
                    opacity: 1;
                }

                .sidebar-content {
                    padding: var(--space-5);
                }

                .room-info-section {
                    margin-bottom: var(--space-6);
                }

                .info-grid {
                    display: grid;
                    grid-template-columns: repeat(2, 1fr);
                    gap: var(--space-4);
                    margin-bottom: var(--space-4);
                }

                .info-item {
                    display: flex;
                    flex-direction: column;
                    gap: var(--space-1);
                }

                .info-label {
                    font-size: 0.75rem;
                    color: var(--gray-500);
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }

                .info-value {
                    font-weight: 600;
                    color: var(--gray-800);
                }

                .capitalize {
                    text-transform: capitalize;
                }

                .amenities-row {
                    display: flex;
                    gap: var(--space-2);
                }

                .amenity-tag {
                    display: inline-flex;
                    align-items: center;
                    gap: var(--space-1);
                    padding: var(--space-1) var(--space-2);
                    background: var(--gray-100);
                    border-radius: var(--radius-md);
                    font-size: 0.75rem;
                    color: var(--gray-700);
                }

                .occupants-section {
                    border-top: 1px solid var(--gray-100);
                    padding-top: var(--space-5);
                }

                .section-header-small {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: var(--space-4);
                }

                .section-header-small h3 {
                    font-size: 0.875rem;
                    font-weight: 600;
                    color: var(--gray-700);
                }

                .occupants-list {
                    display: flex;
                    flex-direction: column;
                    gap: var(--space-3);
                }

                .occupant-card {
                    display: flex;
                    align-items: center;
                    gap: var(--space-3);
                    padding: var(--space-3);
                    background: var(--gray-50);
                    border-radius: var(--radius-lg);
                    transition: background 0.2s ease;
                }

                .occupant-card:hover {
                    background: var(--gray-100);
                }

                .occupant-avatar {
                    width: 40px;
                    height: 40px;
                    border-radius: var(--radius-full);
                    background: var(--gradient-primary);
                    color: white;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: 600;
                    flex-shrink: 0;
                }

                .occupant-info {
                    flex: 1;
                    min-width: 0;
                }

                .occupant-name {
                    font-weight: 600;
                    color: var(--gray-800);
                    font-size: 0.875rem;
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                }

                .occupant-reg {
                    font-size: 0.75rem;
                    color: var(--gray-500);
                }

                .occupant-date {
                    font-size: 0.7rem;
                    color: var(--gray-400);
                }

                .occupant-actions {
                    display: flex;
                    gap: var(--space-1);
                }

                .action-btn {
                    width: 28px;
                    height: 28px;
                    border: none;
                    border-radius: var(--radius-md);
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 0.875rem;
                    transition: all 0.2s ease;
                }

                .action-btn.move {
                    background: var(--primary-100);
                    color: var(--primary-600);
                }

                .action-btn.move:hover {
                    background: var(--primary-200);
                }

                .action-btn.remove {
                    background: var(--error-500);
                    color: white;
                }

                .action-btn.remove:hover {
                    background: var(--error-600);
                }

                .empty-occupants {
                    text-align: center;
                    padding: var(--space-6);
                    color: var(--gray-500);
                }

                .empty-occupants .empty-icon {
                    font-size: 2rem;
                    opacity: 0.5;
                    margin-bottom: var(--space-2);
                    display: block;
                }

                .empty-occupants p {
                    margin-bottom: var(--space-4);
                }

                .vacant-beds-indicator {
                    margin-top: var(--space-5);
                    padding: var(--space-4);
                    background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
                    border-radius: var(--radius-lg);
                    text-align: center;
                }

                .vacant-count {
                    font-size: 2rem;
                    font-weight: 700;
                    color: #065f46;
                    display: block;
                }

                .vacant-label {
                    font-size: 0.875rem;
                    color: #065f46;
                }

                .sidebar-empty {
                    padding: var(--space-12) var(--space-6);
                    text-align: center;
                    color: var(--gray-400);
                }

                .sidebar-empty .empty-icon {
                    font-size: 3rem;
                    margin-bottom: var(--space-4);
                }

                .loading-container {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 200px;
                }

                .loading-container.small {
                    min-height: 100px;
                }

                .spinner.small {
                    width: 24px;
                    height: 24px;
                }

                .empty-state {
                    text-align: center;
                    padding: var(--space-12);
                    color: var(--gray-500);
                }

                .empty-state-icon {
                    font-size: 3rem;
                    margin-bottom: var(--space-4);
                    opacity: 0.5;
                }

                /* Move Modal Info */
                .move-info {
                    padding: var(--space-4);
                    background: var(--gray-50);
                    border-radius: var(--radius-lg);
                    margin-bottom: var(--space-4);
                }

                .move-info p {
                    margin: 0;
                    color: var(--gray-700);
                }

                .form-hint {
                    font-size: 0.75rem;
                    color: var(--gray-500);
                    margin-top: var(--space-2);
                }
            `}</style>
        </div>
    );
}
