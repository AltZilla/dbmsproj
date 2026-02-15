import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PaymentsScreen extends StatefulWidget {
  final int studentId;

  const PaymentsScreen({super.key, required this.studentId});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _apiService = ApiService();
  List<Payment> _payments = [];
  bool _isLoading = true;
  double _totalPaid = 0;
  double _totalPending = 0;

  // Payment modal state
  bool _showPaymentModal = false;
  Set<int> _selectedPaymentIds = {};
  bool _isProcessing = false;
  bool _paymentSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final payments = await _apiService.getPayments(widget.studentId);
      setState(() {
        _payments = payments;
        _totalPaid = payments
            .where((p) => p.paymentStatus == 'paid')
            .fold(0, (sum, p) => sum + p.amount);
        _totalPending = payments
            .where((p) => p.isPending)
            .fold(0, (sum, p) => sum + p.amount);
      });
    } catch (e) {
      debugPrint('Error loading payments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Payment> get _pendingPayments => _payments.where((p) => p.isPending).toList();

  double get _selectedAmount => _pendingPayments
      .where((p) => _selectedPaymentIds.contains(p.id))
      .fold(0, (sum, p) => sum + p.amount);

  void _showPayNowModal() {
    setState(() {
      _showPaymentModal = true;
      _selectedPaymentIds = _pendingPayments.map((p) => p.id).toSet();
      _paymentSuccess = false;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentIds.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      for (final payment in _pendingPayments.where((p) => _selectedPaymentIds.contains(p.id))) {
        await _apiService.updatePayment(payment.id, {
          'payment_status': 'paid',
          'payment_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'receipt_number': 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        });
      }

      setState(() {
        _paymentSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _showPaymentModal = false;
        _paymentSuccess = false;
        _selectedPaymentIds.clear();
      });
      
      await _loadPayments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Payments & Dues'),
        backgroundColor: AppTheme.primary900,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary600),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  color: AppTheme.primary600,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD1FAE5)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Paid',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.gray500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${NumberFormat('#,##0').format(_totalPaid)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.success600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _totalPending > 0
                                        ? const Color(0xFFFDE68A)
                                        : AppTheme.gray100,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Pending',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.gray500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${NumberFormat('#,##0').format(_totalPending)}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _totalPending > 0
                                            ? AppTheme.warning600
                                            : AppTheme.success600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pay Now Button
                        if (_totalPending > 0)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showPayNowModal,
                              child: const Text('Pay Now'),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Payments Table
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gray200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAFAFB),
                                  border: Border(
                                    bottom: BorderSide(color: AppTheme.gray200),
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'DATE / DUE DATE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.gray500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'DESCRIPTION / SEM',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.gray500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'AMOUNT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.gray500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'STATUS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.gray500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'RECEIPT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.gray500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Table Body
                              if (_payments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'No current payment records found',
                                    style: TextStyle(
                                      color: AppTheme.gray500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ..._payments.map((payment) => _buildPaymentRow(payment)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

          // Payment Modal
          if (_showPaymentModal)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Modal Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary600, Color(0xFF9333EA)],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            _paymentSuccess ? '✅ Payment Successful!' : 'Complete Payment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Modal Body
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _paymentSuccess
                              ? Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    const Text(
                                      '🎉',
                                      style: TextStyle(fontSize: 64),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Your payment has been processed successfully!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Redirecting...',
                                      style: TextStyle(color: AppTheme.gray500),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                )
                              : Column(
                                  children: [
                                    // Selected Amount
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppTheme.primary50,
                                            Color(0xFFF3E8FF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.primary100),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Selected Amount',
                                            style: TextStyle(
                                              color: AppTheme.gray500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${NumberFormat('#,##0').format(_selectedAmount)}',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary600,
                                            ),
                                          ),
                                          Text(
                                            '${_selectedPaymentIds.length} of ${_pendingPayments.length} items selected',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Select buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Select Payments:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.gray700,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () => setState(() {
                                                _selectedPaymentIds = _pendingPayments.map((p) => p.id).toSet();
                                              }),
                                              child: const Text('Select All'),
                                            ),
                                            const Text('|', style: TextStyle(color: AppTheme.gray300)),
                                            TextButton(
                                              onPressed: () => setState(() {
                                                _selectedPaymentIds.clear();
                                              }),
                                              child: const Text('Clear', style: TextStyle(color: AppTheme.gray500)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Payment items
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: _pendingPayments.map((payment) {
                                            final isSelected = _selectedPaymentIds.contains(payment.id);
                                            return GestureDetector(
                                              onTap: () => setState(() {
                                                if (isSelected) {
                                                  _selectedPaymentIds.remove(payment.id);
                                                } else {
                                                  _selectedPaymentIds.add(payment.id);
                                                }
                                              }),
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? AppTheme.primary50 : Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isSelected ? AppTheme.primary300 : AppTheme.gray200,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Checkbox(
                                                      value: isSelected,
                                                      activeColor: AppTheme.primary600,
                                                      onChanged: (value) => setState(() {
                                                        if (value ?? false) {
                                                          _selectedPaymentIds.add(payment.id);
                                                        } else {
                                                          _selectedPaymentIds.remove(payment.id);
                                                        }
                                                      }),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            payment.semester ?? 'Fee Payment',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w500,
                                                              color: AppTheme.gray900,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Due: ${DateFormat('dd/MM/yyyy').format(payment.dueDate)}',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color: AppTheme.gray500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      '₹${NumberFormat('#,##0').format(payment.amount)}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected ? AppTheme.primary600 : AppTheme.gray900,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Demo warning
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text('⚠️'),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'This is a demo payment. No actual transaction will occur.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _isProcessing
                                                ? null
                                                : () => setState(() => _showPaymentModal = false),
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isProcessing || _selectedPaymentIds.isEmpty
                                                ? null
                                                : _processPayment,
                                            child: _isProcessing
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text('Pay ₹${NumberFormat('#,##0').format(_selectedAmount)}'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(Payment payment) {
    final statusColors = {
      'paid': (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      'pending': (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'overdue': (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'partial': (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
    };

    final colors = statusColors[payment.paymentStatus] ?? 
        (AppTheme.gray100, AppTheme.gray600);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.gray100),
        ),
      ),
      child: Row(
        children: [
          // Date / Due Date
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(
                    payment.paymentDate ?? payment.dueDate,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  payment.paymentDate != null ? 'Paid on' : 'Due by',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ),
          // Description / Sem + Notes
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.semester ?? 'Fee Payment',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.gray500,
                    ),
                  ),
              ],
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              '₹${NumberFormat('#,##0').format(payment.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.$1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payment.paymentStatus.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.$2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Receipt Number
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                payment.receiptNumber ?? '-',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppTheme.gray500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
