import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/payment.dart';
import '../../models/student.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final ApiService _api = ApiService();
  List<Payment> _payments = [];
  bool _loading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _loading = true);
    try {
      _payments = await _api.getAllPayments(
        status: _filterStatus != 'all' ? _filterStatus : null,
      );
    } catch (_) {
      _showError('Failed to load payments');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error500),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.success600),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppTheme.success600;
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'overdue':
        return AppTheme.error500;
      case 'partial':
        return const Color(0xFF3B82F6);
      default:
        return AppTheme.gray500;
    }
  }

  // ========== MARK AS PAID ==========
  void _confirmMarkAsPaid(Payment p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Paid'),
        content: Text(
            'Mark payment of ₹${p.amount.toStringAsFixed(0)} for ${p.studentName ?? 'student'} as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final today = DateTime.now();
              final todayStr =
                  '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              final receipt =
                  'RCP-${today.year}-${today.millisecondsSinceEpoch.toString().substring(7)}';

              final success = await _api.updatePayment(p.id, {
                'payment_status': 'paid',
                'payment_date': todayStr,
                'receipt_number': receipt,
              });
              if (success) {
                _showSuccess('Payment marked as paid');
                _fetchPayments();
              } else {
                _showError('Failed to update payment');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success600,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ========== ISSUE PAYMENT MODAL ==========
  void _showIssuePaymentModal() async {
    List<Student> students = [];
    try {
      students = await _api.getStudents(limit: 100);
    } catch (_) {}

    if (!mounted) return;

    int? selectedStudentId;
    final amountCtrl = TextEditingController();
    final dueDateCtrl = TextEditingController(
        text:
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}');
    final semesterCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Issue Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Student Dropdown
                  DropdownButtonFormField<int>(
                    decoration:
                        const InputDecoration(labelText: 'Select Student'),
                    items: students
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                  '${s.registrationNumber} - ${s.fullName}'),
                            ))
                        .toList(),
                    onChanged: (val) => selectedStudentId = val,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Amount (₹)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: semesterCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Semester',
                              hintText: 'e.g. Fall 2024'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: dueDateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (selectedStudentId == null ||
                                  amountCtrl.text.isEmpty) {
                                _showError(
                                    'Please select a student and enter amount');
                                return;
                              }
                              setModalState(() => submitting = true);
                              final body = <String, dynamic>{
                                'student_id': selectedStudentId,
                                'amount':
                                    double.tryParse(amountCtrl.text) ?? 0,
                                'due_date': dueDateCtrl.text,
                                'payment_status': 'pending',
                              };
                              if (semesterCtrl.text.isNotEmpty) {
                                body['semester'] = semesterCtrl.text;
                              }
                              if (notesCtrl.text.isNotEmpty) {
                                body['notes'] = notesCtrl.text;
                              }

                              final res = await _api.createPayment(body);
                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                _showSuccess('Payment issued');
                                _fetchPayments();
                              } else {
                                _showError(
                                    res['error'] ?? 'Failed to issue payment');
                              }
                              setModalState(() => submitting = false);
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(submitting ? 'Issuing...' : 'Issue Payment'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.navbarGradient),
        ),
        title: const Text('Payments'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssuePaymentModal,
        icon: const Icon(Icons.add),
        label: const Text('Issue Payment'),
        backgroundColor: AppTheme.primary600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['all', 'pending', 'paid', 'overdue', 'partial']
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s == 'all'
                                  ? 'All Status'
                                  : s[0].toUpperCase() + s.substring(1)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _filterStatus = val ?? 'all');
                      _fetchPayments();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card,
                                size: 64, color: AppTheme.gray300),
                            const SizedBox(height: 16),
                            Text('No payments found',
                                style: TextStyle(color: AppTheme.gray500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPayments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payments.length,
                          itemBuilder: (ctx, i) {
                            final p = _payments[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.gray200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.studentName ?? 'Student',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: AppTheme.gray900,
                                              ),
                                            ),
                                            if (p.registrationNumber != null)
                                              Text(
                                                p.registrationNumber!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.gray500,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(p.paymentStatus)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          p.paymentStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                _statusColor(p.paymentStatus),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // Amount
                                      Text(
                                        '₹${p.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.gray900,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Due date
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Due',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.gray400,
                                            ),
                                          ),
                                          Text(
                                            '${p.dueDate.day}/${p.dueDate.month}/${p.dueDate.year}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: (p.daysOverdue != null &&
                                                      p.daysOverdue! > 0 &&
                                                      p.paymentStatus !=
                                                          'paid')
                                                  ? AppTheme.error500
                                                  : AppTheme.gray700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (p.semester != null) ...[
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Semester',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.gray400,
                                              ),
                                            ),
                                            Text(
                                              p.semester!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.gray700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const Spacer(),
                                      if (p.isPending)
                                        SizedBox(
                                          height: 32,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _confirmMarkAsPaid(p),
                                            icon: const Icon(Icons.check,
                                                size: 16),
                                            label: const Text('Paid',
                                                style:
                                                    TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.success600,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (p.daysOverdue != null &&
                                      p.daysOverdue! > 0 &&
                                      p.paymentStatus != 'paid')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${p.daysOverdue} days overdue',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.error500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
