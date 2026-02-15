import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ComplaintsScreen extends StatefulWidget {
  final int studentId;

  const ComplaintsScreen({super.key, required this.studentId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ApiService _apiService = ApiService();
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  int? _roomId;
  String? _message;
  bool _isSuccess = false;
  String? _formError;

  // Form state
  bool _showForm = false;
  String _category = 'electrical';
  String _title = '';
  String _description = '';
  int _priority = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get student to find room
      final student = await _apiService.getStudent(widget.studentId);
      if (student != null) {
        setState(() => _roomId = student.roomId);
      }

      // Get complaints
      final complaints = await _apiService.getComplaints(widget.studentId);
      setState(() => _complaints = complaints);
    } catch (e) {
      debugPrint('Error loading complaints: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (_roomId == null) {
      setState(() {
        _formError = 'You must be assigned to a room before raising a complaint.';
      });
      return;
    }

    if (_title.isEmpty || _description.isEmpty) {
      setState(() {
        _formError = 'Please fill in all required fields.';
      });
      return;
    }

    try {
      final success = await _apiService.createComplaint(
        studentId: widget.studentId,
        roomId: _roomId!,
        category: _category,
        title: _title,
        description: _description,
        priority: _priority,
      );

      if (success) {
        setState(() {
          _showForm = false;
          _isSuccess = true;
          _message = 'Complaint raised successfully!';
          _title = '';
          _description = '';
          _category = 'electrical';
          _priority = 3;
        });
        await _loadData();
      } else {
        setState(() {
          _formError = 'Failed to raise complaint. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _formError = 'An error occurred: $e';
      });
    }

    // Clear message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'open': (const Color(0xFFFEF3C7), const Color(0xFF92400E), const Color(0xFFFDE68A)),
      'assigned': (const Color(0xFFDBEAFE), const Color(0xFF1E40AF), const Color(0xFFBFDBFE)),
      'in_progress': (const Color(0xFFE0E7FF), const Color(0xFF3730A3), const Color(0xFFC7D2FE)),
      'resolved': (const Color(0xFFD1FAE5), const Color(0xFF065F46), const Color(0xFFA7F3D0)),
      'closed': (AppTheme.gray100, AppTheme.gray600, AppTheme.gray200),
    };

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('My Complaints'),
        backgroundColor: AppTheme.primary900,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() {
          _showForm = true;
          _formError = null;
        }),
        backgroundColor: AppTheme.primary600,
        icon: const Icon(Icons.add),
        label: const Text('Raise Complaint'),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary600),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.primary600,
                  child: _complaints.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '✅',
                                    style: TextStyle(
                                      fontSize: 64,
                                      color: Colors.grey.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No complaints',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.gray900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Everything looks good! No active maintenance requests.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.gray500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _complaints.length + (_message != null ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_message != null && index == 0) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: _isSuccess
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isSuccess
                                        ? const Color(0xFFA7F3D0)
                                        : const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _isSuccess
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                              );
                            }

                            final complaintIndex = _message != null ? index - 1 : index;

                            
                            final complaint = _complaints[complaintIndex];
                            final colors = statusColors[complaint.status] ?? 
                                (AppTheme.gray100, AppTheme.gray600, AppTheme.gray200);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gray50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.gray100),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              Complaint.getCategoryIcon(complaint.category),
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              complaint.category.replaceAll('_', ' ').toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.gray700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.$1,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: colors.$3),
                                        ),
                                        child: Text(
                                          complaint.status.replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colors.$2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    complaint.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.gray900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    complaint.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.gray600,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: complaint.priority <= 2
                                                  ? AppTheme.error500
                                                  : const Color(0xFF60A5FA),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Priority: P${complaint.priority}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Created: ${DateFormat('MMM d, yyyy').format(complaint.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray500,
                                            ),
                                          ),
                                          if (complaint.resolvedAt != null)
                                            Text(
                                              'Resolved: ${DateFormat('MMM d, yyyy').format(complaint.resolvedAt!)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.success600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

          // Raise Complaint Modal
          if (_showForm)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFAFB),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            border: Border(
                              bottom: BorderSide(color: AppTheme.gray100),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Raise a Complaint',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _showForm = false),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_formError != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(
                                    _formError!,
                                    style: const TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              const Text(
                                'Category *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _category,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'electrical', child: Text('⚡ Electrical')),
                                  DropdownMenuItem(value: 'plumbing', child: Text('🚿 Plumbing')),
                                  DropdownMenuItem(value: 'furniture', child: Text('🪑 Furniture')),
                                  DropdownMenuItem(value: 'cleaning', child: Text('🧹 Cleaning')),
                                  DropdownMenuItem(value: 'pest_control', child: Text('🐛 Pest Control')),
                                  DropdownMenuItem(value: 'internet', child: Text('📶 Internet')),
                                  DropdownMenuItem(value: 'security', child: Text('🔒 Security')),
                                  DropdownMenuItem(value: 'other', child: Text('📝 Other')),
                                ],
                                onChanged: (value) => setState(() => _category = value!),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Title *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Brief description of the issue',
                                ),
                                onChanged: (value) => _title = value,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Description *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Provide more details about the issue...',
                                ),
                                onChanged: (value) => _description = value,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Priority',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                value: _priority,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1 - Urgent (Safety issue)')),
                                  DropdownMenuItem(value: 2, child: Text('2 - High')),
                                  DropdownMenuItem(value: 3, child: Text('3 - Medium (Default)')),
                                  DropdownMenuItem(value: 4, child: Text('4 - Low')),
                                  DropdownMenuItem(value: 5, child: Text('5 - When possible')),
                                ],
                                onChanged: (value) => setState(() => _priority = value!),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppTheme.gray50,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                            border: Border(
                              top: BorderSide(color: AppTheme.gray100),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _showForm = false),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitComplaint,
                                  child: const Text('Submit'),
                                ),
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
}
