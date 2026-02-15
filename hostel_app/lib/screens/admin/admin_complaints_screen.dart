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

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  // ========== DETAIL MODAL ==========
  void _showDetailModal(Complaint c) {
    String selectedStatus = c.status;
    final noteController = TextEditingController();
    List<Map<String, dynamic>> history = [];
    bool historyLoading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          // Fetch complaint history on first build
          if (historyLoading) {
            _api.getComplaintDetail(c.id).then((data) {
              if (data['success'] == true && data['data'] != null) {
                final historyData = data['data']['history'];
                if (historyData is List) {
                  setModalState(() {
                    history = historyData
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();
                    historyLoading = false;
                  });
                } else {
                  setModalState(() => historyLoading = false);
                }
              } else {
                setModalState(() => historyLoading = false);
              }
            }).catchError((_) {
              setModalState(() => historyLoading = false);
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.gray300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
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
                  ),
                  const Divider(),
                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
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
                        _detailRow(
                            'Category', c.category.replaceAll('_', ' ')),
                        _detailRow('Priority', _priorityLabel(c.priority),
                            color: _priorityColor(c.priority)),
                        if (c.studentName != null)
                          _detailRow('Student', c.studentName!),
                        if (c.roomNumber != null)
                          _detailRow('Room',
                              '${c.hostelName ?? ''} - ${c.roomNumber}'),
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
                            c.description.isNotEmpty
                                ? c.description
                                : 'No description',
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.gray700,
                                height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ========== HISTORY / LOGS SECTION ==========
                        Row(
                          children: [
                            const Icon(Icons.history,
                                size: 18, color: AppTheme.gray600),
                            const SizedBox(width: 6),
                            const Text(
                              'Status History',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.gray800,
                              ),
                            ),
                            const Spacer(),
                            if (historyLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!historyLoading && history.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.gray50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.gray200),
                            ),
                            child: const Center(
                              child: Text(
                                'No history available',
                                style: TextStyle(
                                    color: AppTheme.gray400, fontSize: 13),
                              ),
                            ),
                          ),
                        if (!historyLoading && history.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.gray200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final log = history[i];
                                final oldStatus =
                                    (log['old_status'] as String?) ?? '—';
                                final newStatus =
                                    (log['new_status'] as String?) ?? '—';
                                final notes =
                                    (log['notes'] as String?) ?? '';
                                final changedBy =
                                    (log['changed_by'] as String?) ??
                                        'system';
                                DateTime? changedAt;
                                if (log['changed_at'] != null) {
                                  changedAt = DateTime.tryParse(
                                      log['changed_at'].toString());
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Status transition row
                                      Row(
                                        children: [
                                          _statusChip(oldStatus),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Icon(
                                                Icons.arrow_forward,
                                                size: 14,
                                                color: AppTheme.gray400),
                                          ),
                                          _statusChip(newStatus),
                                          const Spacer(),
                                          // Changed by badge
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: changedBy == 'admin'
                                                  ? const Color(0xFFEDE9FE)
                                                  : AppTheme.gray100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              changedBy,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: changedBy == 'admin'
                                                    ? const Color(
                                                        0xFF7C3AED)
                                                    : AppTheme.gray500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Timestamp
                                      if (changedAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(changedAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.gray400,
                                          ),
                                        ),
                                      ],
                                      // Notes
                                      if (notes.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          width: double.infinity,
                                          padding:
                                              const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEFCE8),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: const Color(
                                                    0xFFFDE68A)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                  Icons
                                                      .sticky_note_2_outlined,
                                                  size: 14,
                                                  color: Color(0xFFD97706)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  notes,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Color(0xFF92400E),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 20),

                        // ========== UPDATE STATUS SECTION ==========
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
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          items: _statuses
                              .where((s) => s.isNotEmpty)
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                        s.replaceAll('_', ' ').toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedStatus = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // ========== ADMIN NOTE FIELD ==========
                        const Text(
                          'Admin Note (optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.gray700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Add a note about this status change...',
                            hintStyle:
                                const TextStyle(color: AppTheme.gray400),
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppTheme.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppTheme.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final updates = <String, dynamic>{
                                'status': selectedStatus,
                              };
                              if (noteController.text.trim().isNotEmpty) {
                                updates['admin_note'] =
                                    noteController.text.trim();
                              }
                              final res =
                                  await _api.updateComplaint(c.id, updates);
                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                _showSuccess('Status updated');
                                _fetchComplaints();
                              } else {
                                _showError(
                                    res['error'] ?? 'Failed to update');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Update Status'),
                          ),
                        ),
                        SizedBox(
                            height:
                                MediaQuery.of(ctx).viewInsets.bottom + 24),
                      ],
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

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status == '—' ? '—' : status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _statusColor(status),
        ),
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
