/**
 * Auto-Allocate API Route
 * ========================
 * Automatically allocates unallocated students to available rooms.
 * 
 * DBMS CONCEPTS DEMONSTRATED:
 * - COMPLEX TRANSACTIONS: Batch inserts within BEGIN/COMMIT/ROLLBACK
 * - SUBQUERIES: Find unallocated students via NOT EXISTS
 * - JOINs: Cross-table gender matching (students → hostels → rooms)
 * - TRIGGERS: Existing trg_check_room_capacity fires for each allocation
 * 
 * Endpoint:
 * - POST /api/allocations/auto-allocate
 */

import { NextResponse } from 'next/server';
import { getClient } from '@/lib/db';

interface UnallocatedStudent {
    id: number;
    first_name: string;
    last_name: string;
    gender: string;
    registration_number: string;
}

interface AvailableRoom {
    id: number;
    room_number: string;
    hostel_name: string;
    gender_allowed: string;
    capacity: number;
    current_occupancy: number;
}

interface AllocationResult {
    student_id: number;
    student_name: string;
    registration_number: string;
    room_id: number;
    room_number: string;
    hostel_name: string;
}

export async function POST() {
    const client = await getClient();

    try {
        await client.query('BEGIN');

        // Step 1: Find all active students who do NOT have an active allocation
        const unallocatedResult = await client.query<UnallocatedStudent>(
            `SELECT s.id, s.first_name, s.last_name, s.gender, s.registration_number
             FROM students s
             WHERE s.is_active = TRUE
               AND NOT EXISTS (
                   SELECT 1 FROM allocations a
                   WHERE a.student_id = s.id AND a.is_active = TRUE
               )
             ORDER BY s.year_of_study DESC, s.id ASC`
        );

        const unallocatedStudents = unallocatedResult.rows;

        if (unallocatedStudents.length === 0) {
            await client.query('ROLLBACK');
            return NextResponse.json({
                success: true,
                message: 'No unallocated students found',
                data: {
                    allocated: 0,
                    failed: 0,
                    total_unallocated: 0,
                    results: [],
                    failures: [],
                }
            });
        }

        // Step 2: Fetch all available rooms (with capacity) along with hostel gender info
        // We re-fetch this after each allocation to get updated occupancy
        const allocated: AllocationResult[] = [];
        const failures: { student_name: string; registration_number: string; reason: string }[] = [];

        const now = new Date();
        const month = now.getMonth();
        const year = now.getFullYear();
        const semester = month < 6 ? `Spring ${year}` : `Fall ${year}`;
        const dueDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        const dueDateStr = dueDate.toISOString().split('T')[0];

        for (const student of unallocatedStudents) {
            // Find a matching room: gender match + has capacity + is available
            // Re-query each time because previous allocations change occupancy (via trigger)
            const roomResult = await client.query<AvailableRoom & { rent_amount: number }>(
                `SELECT r.id, r.room_number, r.rent_amount, h.name as hostel_name, 
                        h.gender_allowed, r.capacity, r.current_occupancy
                 FROM rooms r
                 INNER JOIN hostels h ON r.hostel_id = h.id
                 WHERE r.is_available = TRUE
                   AND r.current_occupancy < r.capacity
                   AND (h.gender_allowed = $1 OR h.gender_allowed = 'other')
                 ORDER BY r.current_occupancy ASC, r.id ASC
                 LIMIT 1`,
                [student.gender]
            );

            if (roomResult.rows.length === 0) {
                failures.push({
                    student_name: `${student.first_name} ${student.last_name}`,
                    registration_number: student.registration_number,
                    reason: `No available ${student.gender} rooms with capacity`,
                });
                continue;
            }

            const room = roomResult.rows[0];

            // Create the allocation — the existing trigger will handle occupancy update
            const allocResult = await client.query<{ id: number }>(
                `INSERT INTO allocations (student_id, room_id, allocation_date, is_active, notes)
                 VALUES ($1, $2, CURRENT_DATE, TRUE, 'Auto-allocated')
                 RETURNING id`,
                [student.id, room.id]
            );

            // Create pending payment for room fee
            if (room.rent_amount > 0) {
                await client.query(
                    `INSERT INTO payments (
                      student_id, allocation_id, amount, due_date,
                      payment_status, semester, notes
                    ) VALUES ($1, $2, $3, $4, 'pending', $5, $6)`,
                    [
                        student.id,
                        allocResult.rows[0].id,
                        room.rent_amount,
                        dueDateStr,
                        semester,
                        'Room fee — auto-generated on allocation',
                    ]
                );
            }

            allocated.push({
                student_id: student.id,
                student_name: `${student.first_name} ${student.last_name}`,
                registration_number: student.registration_number,
                room_id: room.id,
                room_number: room.room_number,
                hostel_name: room.hostel_name,
            });
        }

        // Step 3: Commit the transaction — all allocations succeed together
        await client.query('COMMIT');

        return NextResponse.json({
            success: true,
            message: `Auto-allocation complete: ${allocated.length} allocated, ${failures.length} failed`,
            data: {
                allocated: allocated.length,
                failed: failures.length,
                total_unallocated: unallocatedStudents.length,
                results: allocated,
                failures: failures,
            }
        });
    } catch (error) {
        // ROLLBACK on any error — no partial allocations
        await client.query('ROLLBACK');
        console.error('Auto-allocate error:', error);
        return NextResponse.json(
            { success: false, error: error instanceof Error ? error.message : 'Auto-allocation failed' },
            { status: 500 }
        );
    } finally {
        client.release();
    }
}
