'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface Allocation {
    id: number;
    student_id: number;
    room_id: number;
    student_name: string;
    room_number: string;
    hostel_name: string;
    allocation_date: string;
    expected_checkout: string | null;
}

interface RoomDetails {
    id: number;
    room_number: string;
    floor: number;
    room_type: string;
    capacity: number;
    rent_amount: string;
    has_ac: boolean;
    has_attached_bathroom: boolean;
    hostel_name: string;
}

function StudentRoomContent() {
    const searchParams = useSearchParams();
    const studentId = parseInt(searchParams.get('id') || '1');

    const [loading, setLoading] = useState(true);
    const [allocation, setAllocation] = useState<Allocation | null>(null);
    const [roomDetails, setRoomDetails] = useState<RoomDetails | null>(null);
    const [roommates, setRoommates] = useState<Allocation[]>([]);

    useEffect(() => {
        const fetchData = async () => {
            try {
                // 1. Get current allocation for student
                const allocRes = await fetch(`/api/allocations?student_id=${studentId}&is_active=true`);
                const allocData = await allocRes.json();

                if (!allocData.success || allocData.data.length === 0) {
                    setLoading(false);
                    return;
                }

                const currentAlloc = allocData.data[0];
                setAllocation(currentAlloc);

                // 2. Get roommates (allocations for same room)
                const roommatesRes = await fetch(`/api/allocations?room_id=${currentAlloc.room_id}&is_active=true`);
                const roommatesData = await roommatesRes.json();

                if (roommatesData.success) {
                    setRoommates(roommatesData.data.filter((a: Allocation) => a.student_id !== studentId));
                }

                // 3. Get extra room info (rent, amenities)
                const allRoomsRes = await fetch(`/api/rooms?limit=100`);
                const allRoomsData = await allRoomsRes.json();
                if (allRoomsData.success) {
                    const foundRoom = allRoomsData.data.find((r: any) => r.id === currentAlloc.room_id);
                    if (foundRoom) setRoomDetails(foundRoom);
                }

            } catch (error) {
                console.error('Failed to fetch room details:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchData();
    }, [studentId]);

    if (loading) return <div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div>;

    if (!allocation) {
        return (
            <div className="max-w-7xl mx-auto px-6 py-8">
                <Link href={`/student?id=${studentId}`} className="inline-flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition-colors font-medium">
                    <span className="mr-2">←</span> Back to Dashboard
                </Link>
                <div className="bg-white rounded-xl p-12 text-center border border-gray-200 shadow-sm">
                    <div className="text-5xl mb-4 grayscale opacity-50">🏠</div>
                    <h2 className="text-xl font-bold text-gray-900 mb-1">No Room Allocated</h2>
                    <p className="text-gray-500">You have not been assigned a room yet.</p>
                </div>
            </div>
        );
    }

    return (
        <div className="max-w-7xl mx-auto px-6 py-8">
            <Link href={`/student?id=${studentId}`} className="inline-flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition-colors font-medium">
                <span className="mr-2">←</span> Back to Dashboard
            </Link>
            <div className="mb-8">
                <h1 className="text-3xl font-bold text-gray-900 mb-1">My Room</h1>
                <p className="text-gray-500">Current accommodation details</p>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mb-8">
                <div className="bg-gray-50/50 px-6 py-4 border-b border-gray-100">
                    <h2 className="text-lg font-bold text-gray-900">Room Details</h2>
                </div>
                <div className="p-6">
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        <div>
                            <span className="block text-sm font-medium text-gray-500 mb-1">Room Number</span>
                            <div className="text-2xl font-bold text-indigo-900">{allocation.room_number}</div>
                        </div>
                        <div>
                            <span className="block text-sm font-medium text-gray-500 mb-1">Hostel Block</span>
                            <div className="text-lg font-semibold text-gray-900">{allocation.hostel_name}</div>
                        </div>
                        {roomDetails && (
                            <>
                                <div>
                                    <span className="block text-sm font-medium text-gray-500 mb-1">Floor</span>
                                    <div className="text-lg font-semibold text-gray-900">{roomDetails.floor}</div>
                                </div>
                                <div>
                                    <span className="block text-sm font-medium text-gray-500 mb-1">Room Type</span>
                                    <div className="text-lg font-semibold text-gray-900 capitalize">{roomDetails.room_type}</div>
                                </div>
                                <div>
                                    <span className="block text-sm font-medium text-gray-500 mb-1">Rent per Year</span>
                                    <div className="text-lg font-semibold text-gray-900">₹{roomDetails.rent_amount}</div>
                                </div>
                                <div>
                                    <span className="block text-sm font-medium text-gray-500 mb-1">Amenities</span>
                                    <div className="flex flex-wrap gap-2 mt-1">
                                        {roomDetails.has_ac && <span className="inline-flex px-2 py-1 bg-blue-50 text-blue-700 rounded text-xs font-semibold border border-blue-100">AC</span>}
                                        {roomDetails.has_attached_bathroom && <span className="inline-flex px-2 py-1 bg-green-50 text-green-700 rounded text-xs font-semibold border border-green-100">Attached Bath</span>}
                                        {!roomDetails.has_ac && !roomDetails.has_attached_bathroom && <span className="text-sm text-gray-500">Standard</span>}
                                    </div>
                                </div>
                            </>
                        )}
                        <div>
                            <span className="block text-sm font-medium text-gray-500 mb-1">Check-in Date</span>
                            <div className="text-lg font-semibold text-gray-900">{new Date(allocation.allocation_date).toLocaleDateString()}</div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                <div className="bg-gray-50/50 px-6 py-4 border-b border-gray-100">
                    <h2 className="text-lg font-bold text-gray-900">Roommates</h2>
                </div>
                <div className="p-6">
                    {roommates.length === 0 ? (
                        <div className="text-center py-8">
                            <span className="text-4xl block mb-2 opacity-30">🛏️</span>
                            <p className="text-gray-500 font-medium">No roommates assigned yet.</p>
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                            {roommates.map(roommate => (
                                <div key={roommate.id} className="flex items-center gap-4 p-4 rounded-xl border border-gray-100 hover:border-indigo-100 hover:shadow-sm hover:bg-gray-50/50 transition-all">
                                    <div className="w-12 h-12 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center text-lg font-bold">
                                        {roommate.student_name.charAt(0)}
                                    </div>
                                    <div>
                                        <div className="font-bold text-gray-900">{roommate.student_name}</div>
                                        <div className="text-xs text-gray-500 font-medium uppercase tracking-wide">Student</div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

export default function StudentRoomPage() {
    return (
        <div className="min-h-screen bg-gray-50">
            <Suspense fallback={<div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div>}>
                <StudentRoomContent />
            </Suspense>
        </div>
    );
}

