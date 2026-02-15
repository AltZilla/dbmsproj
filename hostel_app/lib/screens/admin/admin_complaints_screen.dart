import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/complaint.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final ApiService _api = ApiService();
  List<Complaint> _complaints = [];
  bool _loading = true;
  String _filterStatus = '';
  String _filterCategory = '';

  final _statuses = ['', 'open', 'in_progress', 'resolved', 'closed'];
  final _categories = [
    '',
    'electrical',
    'plumbing',
    'furniture',
    'cleaning',
    'pest_control',
    'internet',
    'security',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _loading = true);
    try {
      _complaints = await _api.getAllComplaints(
        status: _filterStatus.isNotEmpty ? _filterStatus : null,
        category: _filterCategory.isNotEmpty ? _filterCategory : null,
      );
    } catch (_) {
      _showError('Failed to load complaints');
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
      case 'open':
        return const Color(0xFFF59E0B);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'resolved':
        return const Color(0xFF22C55E);
      case 'closed':
        return AppTheme.gray500;
      default:
        return AppTheme.gray400;
    }
  }

  Color _priorityColor(int p) {
    if (p >= 4) return AppTheme.error500;
    if (p >= 3) return AppTheme.warning500;
    return AppTheme.success500;
  }

  String _priorityLabel(int p) {
    if (p >= 4) return 'Urgent';
    if (p >= 3) return 'High';
    if (p >= 2) return 'Medium';
    return 'Low';
  }

  // ========== DETAIL MODAL ==========
  void _showDetailModal(Complaint c) {
    String selectedStatus = c.status;

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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Complaint Details',
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
                const Divider(),
                const SizedBox(height: 8),

                // Title & Category
                Row(
                  children: [
                    Text(
                      Complaint.getCategoryIcon(c.category),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info rows
                _detailRow('Category', c.category.replaceAll('_', ' ')),
                _detailRow(
                    'Priority', _priorityLabel(c.priority),
                    color: _priorityColor(c.priority)),
                if (c.studentName != null)
                  _detailRow('Student', c.studentName!),
                if (c.roomNumber != null)
                  _detailRow(
                      'Room', '${c.hostelName ?? ''} - ${c.roomNumber}'),
                _detailRow('Submitted',
                    '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}'),
                const SizedBox(height: 12),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.gray700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: Text(
                    c.description.isNotEmpty ? c.description : 'No description',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.gray700, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),

                // Update Status
                const Text(
                  'Update Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.gray700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _statuses
                      .where((s) => s.isNotEmpty)
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final res = await _api.updateComplaint(c.id, {
                        'status': selectedStatus,
                      });
                      if (res['success'] == true) {
                        Navigator.pop(ctx);
                        _showSuccess('Status updated');
                        _fetchComplaints();
                      } else {
                        _showError(res['error'] ?? 'Failed to update');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Update Status'),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? AppTheme.gray800,
              ),
            ),
          ),
        ],
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
        title: const Text('Complaints'),
      ),
      body: Column(
        children: [
          // Filters
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
                    items: _statuses
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.isEmpty
                                  ? 'All Status'
                                  : s.replaceAll('_', ' ').toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _filterStatus = val ?? '');
                      _fetchComplaints();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.isEmpty
                                  ? 'All Categories'
                                  : c.replaceAll('_', ' ').toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _filterCategory = val ?? '');
                      _fetchComplaints();
                    },
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: AppTheme.gray300),
                            const SizedBox(height: 16),
                            Text('No complaints found',
                                style: TextStyle(color: AppTheme.gray500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchComplaints,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _complaints.length,
                          itemBuilder: (ctx, i) {
                            final c = _complaints[i];
                            return GestureDetector(
                              onTap: () => _showDetailModal(c),
                              child: Container(
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
                                        Text(
                                          Complaint.getCategoryIcon(c.category),
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            c.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppTheme.gray900,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _statusColor(c.status)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            c.status
                                                .replaceAll('_', ' ')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: _statusColor(c.status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (c.studentName != null) ...[
                                          Icon(Icons.person,
                                              size: 14,
                                              color: AppTheme.gray400),
                                          const SizedBox(width: 4),
                                          Text(
                                            c.studentName!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray500,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _priorityColor(c.priority)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _priorityLabel(c.priority),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _priorityColor(c.priority),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.gray400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
