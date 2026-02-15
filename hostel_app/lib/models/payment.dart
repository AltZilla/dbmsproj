class Payment {
  final int id;
  final int? studentId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final String paymentStatus;
  final String? paymentMethod;
  final String? receiptNumber;
  final String? semester;
  final String? notes;
  final String? studentName;
  final String? registrationNumber;
  final int? daysOverdue;

  Payment({
    required this.id,
    this.studentId,
    required this.amount,
    required this.dueDate,
    this.paymentDate,
    required this.paymentStatus,
    this.paymentMethod,
    this.receiptNumber,
    this.semester,
    this.notes,
    this.studentName,
    this.registrationNumber,
    this.daysOverdue,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      studentId: json['student_id'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      dueDate: DateTime.parse(json['due_date']),
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      receiptNumber: json['receipt_number'],
      semester: json['semester'],
      notes: json['notes'],
      studentName: json['student_name'],
      registrationNumber: json['registration_number'],
      daysOverdue: json['days_overdue'],
    );
  }

  bool get isPending =>
      ['pending', 'overdue', 'partial'].contains(paymentStatus);
}
