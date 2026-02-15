class Allocation {
  final int id;
  final int studentId;
  final int roomId;
  final String studentName;
  final String roomNumber;
  final String hostelName;
  final DateTime allocationDate;
  final DateTime? expectedCheckout;
  final bool isActive;
  final String registrationNumber;

  Allocation({
    required this.id,
    required this.studentId,
    required this.roomId,
    required this.studentName,
    required this.roomNumber,
    required this.hostelName,
    required this.allocationDate,
    this.expectedCheckout,
    this.isActive = true,
    this.registrationNumber = '',
  });

  factory Allocation.fromJson(Map<String, dynamic> json) {
    return Allocation(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      roomId: json['room_id'] as int,
      studentName: json['student_name'] ?? '',
      roomNumber: json['room_number'] ?? '',
      hostelName: json['hostel_name'] ?? '',
      allocationDate: DateTime.parse(json['allocation_date']),
      expectedCheckout: json['expected_checkout'] != null
          ? DateTime.parse(json['expected_checkout'])
          : null,
      isActive: json['is_active'] ?? true,
      registrationNumber: json['registration_number'] ?? '',
    );
  }
}

class RoomDetails {
  final int id;
  final int hostelId;
  final String roomNumber;
  final int floor;
  final String roomType;
  final int capacity;
  final int currentOccupancy;
  final double rentAmount;
  final bool hasAc;
  final bool hasAttachedBathroom;
  final bool isAvailable;
  final String hostelName;

  RoomDetails({
    required this.id,
    this.hostelId = 0,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    required this.capacity,
    this.currentOccupancy = 0,
    required this.rentAmount,
    required this.hasAc,
    required this.hasAttachedBathroom,
    this.isAvailable = true,
    required this.hostelName,
  });

  factory RoomDetails.fromJson(Map<String, dynamic> json) {
    return RoomDetails(
      id: json['id'] as int,
      hostelId: json['hostel_id'] ?? 0,
      roomNumber: json['room_number'] ?? '',
      floor: json['floor'] ?? 0,
      roomType: json['room_type'] ?? 'single',
      capacity: json['capacity'] ?? 1,
      currentOccupancy: json['current_occupancy'] ?? 0,
      rentAmount:
          double.tryParse(json['rent_amount']?.toString() ?? '0') ?? 0,
      hasAc: json['has_ac'] ?? false,
      hasAttachedBathroom: json['has_attached_bathroom'] ?? false,
      isAvailable: json['is_available'] ?? true,
      hostelName: json['hostel_name'] ?? '',
    );
  }
}
