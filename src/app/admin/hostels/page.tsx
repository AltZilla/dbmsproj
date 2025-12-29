'use client';

/**
 * Hostels Management Page
 * ========================
 * Admin page for viewing and managing hostels.
 */

import { useState, useEffect } from 'react';
import Link from 'next/link';

interface Hostel {
    id: number;
    name: string;
    address: string | null;
    gender_allowed: 'male' | 'female' | 'other';
    total_rooms: number;
    warden_name: string | null;
    warden_contact: string | null;
}

interface RoomStats {
    hostel_id: number;
    total_capacity: number;
    current_occupancy: number;
}

export default function HostelsPage() {
    const [hostels, setHostels] = useState<Hostel[]>([]);
    const [roomStats, setRoomStats] = useState<Map<number, RoomStats>>(new Map());
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchData() {
            try {
                const hostelsRes = await fetch('/api/hostels');
                const hostelsData = await hostelsRes.json();

                if (hostelsData.success) {
                    setHostels(hostelsData.data);
                }

                // Fetch room stats for each hostel
                const roomsRes = await fetch('/api/rooms?limit=200');
                const roomsData = await roomsRes.json();

                if (roomsData.success) {
                    const stats = new Map<number, RoomStats>();

                    for (const room of roomsData.data) {
                        const hostelId = room.hostel_id;
                        if (!stats.has(hostelId)) {
                            stats.set(hostelId, {
                                hostel_id: hostelId,
                                total_capacity: 0,
                                current_occupancy: 0
                            });
                        }
                        const current = stats.get(hostelId)!;
                        current.total_capacity += room.capacity;
                        current.current_occupancy += room.current_occupancy;
                    }

                    setRoomStats(stats);
                }
            } catch (error) {
                console.error('Failed to fetch hostels:', error);
            } finally {
                setLoading(false);
            }
        }

        fetchData();
    }, []);

    const genderBadge = (gender: string) => {
        const config: Record<string, string> = {
            male: 'bg-blue-100 text-blue-800 border-blue-200',
            female: 'bg-pink-100 text-pink-800 border-pink-200',
            other: 'bg-purple-100 text-purple-800 border-purple-200'
        };
        return config[gender] || 'bg-gray-100 text-gray-800 border-gray-200';
    };

    if (loading) {
        return (
            <div className="max-w-7xl mx-auto px-6 py-8">
                <div className="min-h-[400px] flex items-center justify-center">
                    <div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div>
                </div>
            </div>
        );
    }

    return (
        <div className="max-w-7xl mx-auto px-6 py-8">
            <Link href="/admin" className="inline-flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition-colors font-medium">
                <span className="mr-2">←</span> Back to Dashboard
            </Link>

            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900 mb-1">Hostels</h1>
                    <p className="text-gray-500">Manage hostel blocks and view occupancy</p>
                </div>
            </div>

            {hostels.length === 0 ? (
                <div className="bg-white rounded-xl p-12 text-center border border-gray-200 shadow-sm">
                    <div className="text-5xl mb-4 grayscale opacity-50">🏢</div>
                    <h3 className="text-lg font-medium text-gray-900 mb-1">No hostels found</h3>
                    <p className="text-gray-500">Add hostels to get started.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {hostels.map((hostel) => {
                        const stats = roomStats.get(hostel.id);
                        const occupancyRate = stats && stats.total_capacity > 0
                            ? Math.round((stats.current_occupancy / stats.total_capacity) * 100)
                            : 0;

                        return (
                            <div key={hostel.id} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md hover:border-indigo-100 transition-all">
                                <div className="p-6">
                                    <div className="flex justify-between items-start mb-4">
                                        <h3 className="text-xl font-bold text-gray-900">{hostel.name}</h3>
                                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize border ${genderBadge(hostel.gender_allowed)}`}>
                                            {hostel.gender_allowed}
                                        </span>
                                    </div>

                                    {hostel.address && (
                                        <p className="text-sm text-gray-500 mb-4">{hostel.address}</p>
                                    )}

                                    <div className="space-y-3">
                                        <div className="flex justify-between items-center text-sm">
                                            <span className="text-gray-500">Total Rooms</span>
                                            <span className="font-semibold text-gray-900">{hostel.total_rooms}</span>
                                        </div>

                                        {stats && (
                                            <>
                                                <div className="flex justify-between items-center text-sm">
                                                    <span className="text-gray-500">Occupancy</span>
                                                    <span className="font-semibold text-gray-900">
                                                        {stats.current_occupancy} / {stats.total_capacity}
                                                    </span>
                                                </div>

                                                <div className="w-full bg-gray-100 rounded-full h-2">
                                                    <div
                                                        className={`h-2 rounded-full transition-all ${occupancyRate > 90 ? 'bg-red-500' :
                                                                occupancyRate > 75 ? 'bg-amber-500' : 'bg-green-500'
                                                            }`}
                                                        style={{ width: `${occupancyRate}%` }}
                                                    ></div>
                                                </div>
                                            </>
                                        )}

                                        {hostel.warden_name && (
                                            <div className="pt-3 border-t border-gray-100">
                                                <div className="text-xs text-gray-500 uppercase tracking-wide mb-1">Warden</div>
                                                <div className="font-medium text-gray-900">{hostel.warden_name}</div>
                                                {hostel.warden_contact && (
                                                    <div className="text-sm text-gray-500">{hostel.warden_contact}</div>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
