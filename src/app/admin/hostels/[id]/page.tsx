'use client';

import { useState, useEffect, use } from 'react';
import Link from 'next/link';

interface HostelStats {
    hostel_id: number;
    hostel_name: string;
    total_rooms: number;
    total_capacity: number;
    total_occupancy: number;
    occupancy_rate: number;
    active_complaints: number;
    complaints_per_room: number;
    open_complaints: number;
    resolved_complaints: number;
}

interface Room {
    id: number;
    room_number: string;
    floor: number;
    room_type: string;
    capacity: number;
    current_occupancy: number;
    rent_amount: string;
    is_available: boolean;
    has_ac: boolean;
    has_attached_bathroom: boolean;
}

export default function HostelDetailsPage({ params }: { params: Promise<{ id: string }> }) {
    const resolvedParams = use(params);
    const hostelId = parseInt(resolvedParams.id);

    const [hostel, setHostel] = useState<HostelStats | null>(null);
    const [rooms, setRooms] = useState<Room[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchData = async () => {
            try {
                // Fetch hostel stats
                const hostelRes = await fetch('/api/analytics/hostels');
                const hostelData = await hostelRes.json();

                if (hostelData.success) {
                    const currentHostel = hostelData.data.find(
                        (h: HostelStats) => h.hostel_id === hostelId
                    );
                    setHostel(currentHostel || null);
                }

                // Fetch rooms
                const roomsRes = await fetch(`/api/rooms?hostel_id=${hostelId}&limit=100`);
                const roomsData = await roomsRes.json();

                if (roomsData.success) {
                    setRooms(roomsData.data);
                }
            } catch (error) {
                console.error('Failed to fetch details:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchData();
    }, [hostelId]);

    if (loading) {
        return (
            <div className="min-h-screen bg-gray-50 flex justify-center items-center">
                <div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div>
            </div>
        );
    }

    if (!hostel) {
        return (
            <div className="min-h-screen bg-gray-50 p-8">
                <div className="text-center mt-12">
                    <h2 className="text-2xl font-bold text-gray-800">Hostel not found</h2>
                    <Link href="/admin/hostels" className="text-indigo-600 hover:underline mt-4 inline-block font-medium">
                        ← Back to Hostels
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="bg-gray-50 min-h-screen">
            <div className="max-w-7xl mx-auto px-6 py-8">
                <div className="mb-6">
                    <Link href="/admin/hostels" className="inline-flex items-center text-sm text-gray-500 hover:text-indigo-600 font-medium transition-colors">
                        <span className="mr-1">←</span> Back to Hostels
                    </Link>
                </div>

                <div className="mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 mb-1">{hostel.hostel_name}</h1>
                    <p className="text-gray-500 flex items-center gap-2">
                        <span className="inline-block w-2 h-2 rounded-full bg-gray-300"></span>
                        {hostel.total_rooms} Rooms
                        <span className="inline-block w-2 h-2 rounded-full bg-gray-300"></span>
                        {hostel.total_capacity} Bed Capacity
                    </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 relative overflow-hidden">
                        <div className="text-sm font-medium text-gray-500 mb-1">Current Occupancy</div>
                        <div className="text-3xl font-bold text-gray-900">
                            {hostel.total_occupancy} <span className="text-sm font-medium text-gray-400">/ {hostel.total_capacity}</span>
                        </div>
                        <div className="mt-4 h-2 bg-gray-100 rounded-full overflow-hidden">
                            <div
                                className="h-full bg-indigo-600 rounded-full"
                                style={{ width: `${Math.min(hostel.occupancy_rate, 100)}%` }}
                            />
                        </div>
                    </div>
                    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 relative overflow-hidden">
                        <div className="text-sm font-medium text-gray-500 mb-1">Active Issues</div>
                        <div className={`text-3xl font-bold ${hostel.open_complaints > 0 ? 'text-amber-600' : 'text-green-600'}`}>
                            {hostel.open_complaints}
                        </div>
                        <p className="text-xs text-gray-400 mt-1">Pending maintenance requests</p>
                    </div>
                    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 relative overflow-hidden">
                        <div className="text-sm font-medium text-gray-500 mb-1">Resolved Issues</div>
                        <div className="text-3xl font-bold text-green-600">{hostel.resolved_complaints}</div>
                        <p className="text-xs text-gray-400 mt-1">Total resolved complaints</p>
                    </div>
                </div>

                <div>
                    <div className="flex justify-between items-end mb-6">
                        <div>
                            <h2 className="text-xl font-bold text-gray-900">Room List</h2>
                            <p className="text-sm text-gray-500 mt-1">
                                Detailed status of all rooms in {hostel.hostel_name}
                            </p>
                        </div>
                        <div className="text-sm font-medium bg-white px-3 py-1 rounded-lg border border-gray-200 text-gray-600 shadow-sm">
                            Total: {rooms.length} rooms
                        </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                        {rooms.map(room => (
                            <div key={room.id} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md hover:border-indigo-100 transition-all group">
                                <div className="bg-gray-50/50 px-5 py-3 border-b border-gray-100 flex justify-between items-center group-hover:bg-indigo-50/30 transition-colors">
                                    <span className="font-bold text-gray-900">Room {room.room_number}</span>
                                    <span className="text-xs font-semibold text-gray-500 bg-white border border-gray-200 px-2 py-1 rounded capitalize shadow-sm">{room.room_type}</span>
                                </div>
                                <div className="p-5">
                                    <div className="flex items-center gap-2 mb-4">
                                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${room.capacity > room.current_occupancy
                                            ? 'bg-green-50 text-green-700 border-green-100'
                                            : 'bg-red-50 text-red-700 border-red-100'
                                            }`}>
                                            <span className={`w-1.5 h-1.5 rounded-full ${room.capacity > room.current_occupancy ? 'bg-green-500' : 'bg-red-500'}`}></span>
                                            {room.capacity > room.current_occupancy ? 'Available' : 'Full'}
                                        </span>
                                        {room.has_ac && (
                                            <span className="text-xs px-2 py-1 rounded-full bg-blue-50 text-blue-700 font-semibold border border-blue-100">AC</span>
                                        )}
                                    </div>
                                    <div className="grid grid-cols-3 gap-4">
                                        <div className="text-center p-2 rounded-lg bg-gray-50/50">
                                            <div className="font-bold text-gray-900">{room.current_occupancy}/{room.capacity}</div>
                                            <div className="text-[10px] uppercase tracking-wider font-semibold text-gray-400 mt-0.5">Occupancy</div>
                                        </div>
                                        <div className="text-center p-2 rounded-lg bg-gray-50/50">
                                            <div className="font-bold text-gray-900">₹{room.rent_amount}</div>
                                            <div className="text-[10px] uppercase tracking-wider font-semibold text-gray-400 mt-0.5">Rent/Year</div>
                                        </div>
                                        <div className="text-center p-2 rounded-lg bg-gray-50/50">
                                            <div className="font-bold text-gray-900">{room.floor}</div>
                                            <div className="text-[10px] uppercase tracking-wider font-semibold text-gray-400 mt-0.5">Floor</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}

