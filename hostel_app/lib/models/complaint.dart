class Complaint {
  final int id;
  final int? studentId;
  final int? roomId;
  final String title;
  final String description;
  final String category;
  final String status;
  final int priority;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String? studentName;
  final String? registrationNumber;
  final String? roomNumber;
  final String? hostelName;

  Complaint({
    required this.id,
    this.studentId,
    this.roomId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.assignedAt,
    this.resolvedAt,
    this.closedAt,
    this.studentName,
    this.registrationNumber,
    this.roomNumber,
    this.hostelName,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      studentId: json['student_id'],
      roomId: json['room_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'other',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 3,
      createdAt: DateTime.parse(json['created_at']),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'])
          : null,
      studentName: json['student_name'],
      registrationNumber: json['registration_number'],
      roomNumber: json['room_number'],
      hostelName: json['hostel_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
    };
  }

  static String getCategoryIcon(String category) {
    switch (category) {
      case 'electrical':
        return '⚡';
      case 'plumbing':
        return '🚿';
      case 'furniture':
        return '🪑';
      case 'cleaning':
        return '🧹';
      case 'pest_control':
        return '🐛';
      case 'internet':
        return '📶';
      case 'security':
        return '🔒';
      default:
        return '📝';
    }
  }
}
