class Student {
  final int id;
  final String registrationNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? guardianName;
  final String? guardianPhone;
  final String? address;
  final bool isActive;
  final String? roomNumber;
  final String? hostelName;
  final int? roomId;
  final double totalPaid;
  final double totalPending;
  final int activeComplaints;

  Student({
    required this.id,
    required this.registrationNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.guardianName,
    this.guardianPhone,
    this.address,
    this.isActive = true,
    this.roomNumber,
    this.hostelName,
    this.roomId,
    this.totalPaid = 0,
    this.totalPending = 0,
    this.activeComplaints = 0,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      registrationNumber: json['registration_number'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      guardianName: json['guardian_name'],
      guardianPhone: json['guardian_phone'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
      roomNumber: json['room_number'],
      hostelName: json['hostel_name'],
      roomId: json['room_id'],
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0,
      totalPending: double.tryParse(json['total_pending']?.toString() ?? '0') ?? 0,
      activeComplaints: int.tryParse(json['active_complaints']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'address': address,
      'is_active': isActive,
    };
  }
}
