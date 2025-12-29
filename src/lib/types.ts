/**
 * API Response Types
 * ==================
 * Type definitions for API responses used throughout the application.
 */

// Standard API response wrapper
export interface ApiResponse<T> {
    success: boolean;
    data?: T;
    error?: string;
    message?: string;
}

// Pagination metadata
export interface PaginationMeta {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
}

// Paginated response
export interface PaginatedResponse<T> {
    success: boolean;
    data: T[];
    pagination: PaginationMeta;
}

// Entity types matching database schema
export interface Hostel {
    id: number;
    name: string;
    address: string | null;
    gender_allowed: 'male' | 'female' | 'other';
    total_rooms: number;
    warden_name: string | null;
    warden_contact: string | null;
    created_at: Date;
    updated_at: Date;
}

export interface Room {
    id: number;
    hostel_id: number;
    room_number: string;
    floor: number;
    room_type: 'single' | 'double' | 'triple' | 'dormitory';
    capacity: number;
    current_occupancy: number;
    rent_amount: number;
    has_ac: boolean;
    has_attached_bathroom: boolean;
    is_available: boolean;
    created_at: Date;
    updated_at: Date;
    // Joined fields
    hostel_name?: string;
}

export interface Student {
    id: number;
    registration_number: string;
    first_name: string;
    last_name: string;
    email: string;
    phone: string | null;
    gender: 'male' | 'female' | 'other';
    date_of_birth: Date | null;
    address: string | null;
    guardian_name: string | null;
    guardian_phone: string | null;
    department: string | null;
    year_of_study: number | null;
    is_active: boolean;
    created_at: Date;
    updated_at: Date;
}

export interface Allocation {
    id: number;
    student_id: number;
    room_id: number;
    allocation_date: Date;
    expected_checkout: Date | null;
    actual_checkout: Date | null;
    is_active: boolean;
    notes: string | null;
    created_at: Date;
    updated_at: Date;
    // Joined fields
    student_name?: string;
    room_number?: string;
    hostel_name?: string;
}

export interface MaintenanceStaff {
    id: number;
    name: string;
    email: string | null;
    phone: string;
    specialization: string | null;
    is_available: boolean;
    hostel_id: number | null;
    created_at: Date;
    updated_at: Date;
}

export interface Complaint {
    id: number;
    student_id: number;
    room_id: number;
    category: 'electrical' | 'plumbing' | 'furniture' | 'cleaning' | 'pest_control' | 'internet' | 'security' | 'other';
    title: string;
    description: string;
    status: 'open' | 'assigned' | 'in_progress' | 'resolved' | 'closed';
    priority: number;
    assigned_staff_id: number | null;
    resolution_notes: string | null;
    created_at: Date;
    assigned_at: Date | null;
    resolved_at: Date | null;
    closed_at: Date | null;
    updated_at: Date;
    // Joined fields
    student_name?: string;
    room_number?: string;
    hostel_name?: string;
    staff_name?: string;
}

export interface Payment {
    id: number;
    student_id: number;
    allocation_id: number | null;
    amount: number;
    payment_date: Date | null;
    due_date: Date;
    payment_status: 'pending' | 'paid' | 'overdue' | 'partial';
    payment_method: string | null;
    transaction_id: string | null;
    receipt_number: string | null;
    semester: string | null;
    notes: string | null;
    created_at: Date;
    updated_at: Date;
    // Joined fields
    student_name?: string;
}

// Analytics types
export interface CategoryStats {
    category: string;
    total_complaints: number;
    percentage: number;
    open_count: number;
    assigned_count: number;
    in_progress_count: number;
    resolved_count: number;
    closed_count: number;
}

export interface RoomComplaintSummary {
    room_id: number;
    room_number: string;
    hostel_name: string;
    floor: number;
    room_type: string;
    capacity: number;
    current_occupancy: number;
    total_complaints: number;
    active_complaints: number;
    resolved_complaints: number;
    most_common_category: string | null;
    last_complaint_date: Date | null;
}

export interface HostelComplaintSummary {
    hostel_id: number;
    hostel_name: string;
    warden_name: string | null;
    total_rooms: number;
    total_capacity: number;
    total_occupancy: number;
    total_complaints: number;
    open_complaints: number;
    resolved_complaints: number;
    complaints_per_room: number;
    complaints_per_student: number;
}

export interface ResolutionTimeStats {
    category: string;
    resolved_count: number;
    avg_resolution_hours: number | null;
    avg_assignment_hours: number | null;
    min_resolution_hours: number | null;
    max_resolution_hours: number | null;
    sla_breaches: number;
}

export interface MonthlyTrend {
    month: Date;
    total_complaints: number;
    electrical: number;
    plumbing: number;
    furniture: number;
    cleaning: number;
    pest_control: number;
    internet: number;
    security: number;
    other: number;
    resolution_rate: number;
}
