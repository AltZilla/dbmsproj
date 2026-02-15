import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/room.dart';
import '../../models/student.dart';

class AdminAllocationsScreen extends StatefulWidget {
  const AdminAllocationsScreen({super.key});

  @override
  State<AdminAllocationsScreen> createState() =>
      _AdminAllocationsScreenState();
}

class _AdminAllocationsScreenState extends State<AdminAllocationsScreen> {
  final ApiService _api = ApiService();
  List<Allocation> _allocations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllocations();
  }

  Future<void> _fetchAllocations() async {
    setState(() => _loading = true);
    try {
      _allocations = await _api.getAllocations(isActive: true, limit: 200);
    } catch (_) {
      _showError('Failed to load allocations');
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

  // ========== CREATE ALLOCATION ==========
  void _showCreateAllocationModal() async {
    List<Student> students = [];
    List<RoomDetails> rooms = [];
    try {
      students = await _api.getStudents(limit: 200);
      rooms = await _api.getRooms(limit: 200);

      // Filter to only unassigned students
      final activeAllocs =
          await _api.getAllocations(isActive: true, limit: 500);
      final allocatedIds = activeAllocs.map((a) => a.studentId).toSet();
      students =
          students.where((s) => !allocatedIds.contains(s.id)).toList();

      // Filter to rooms with available capacity
      rooms = rooms
          .where(
              (r) => r.currentOccupancy < r.capacity && r.isAvailable)
          .toList();
    } catch (_) {}

    if (!mounted) return;

    int? selectedStudentId;
    int? selectedRoomId;
    final checkoutCtrl = TextEditingController();
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
                        'New Allocation',
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

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                        labelText: 'Select Student'),
                    isExpanded: true,
                    items: students
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.registrationNumber} - ${s.fullName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => selectedStudentId = val,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                        labelText: 'Select Room'),
                    isExpanded: true,
                    items: rooms
                        .map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                '${r.hostelName} - ${r.roomNumber} (${r.currentOccupancy}/${r.capacity})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => selectedRoomId = val,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: checkoutCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Expected Checkout (Optional)',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (selectedStudentId == null ||
                                  selectedRoomId == null) {
                                _showError(
                                    'Please select student and room');
                                return;
                              }
                              setModalState(() => submitting = true);
                              final body = <String, dynamic>{
                                'student_id': selectedStudentId,
                                'room_id': selectedRoomId,
                              };
                              if (checkoutCtrl.text.isNotEmpty) {
                                body['expected_checkout'] =
                                    checkoutCtrl.text;
                              }
                              final res =
                                  await _api.createAllocation(body);
                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                _showSuccess('Allocation created!');
                                _fetchAllocations();
                              } else {
                                _showError(res['error'] ??
                                    'Failed to create allocation');
                              }
                              setModalState(() => submitting = false);
                            },
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(submitting
                          ? 'Creating...'
                          : 'Create Allocation'),
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

  // ========== END ALLOCATION ==========
  void _confirmEndAllocation(Allocation alloc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Allocation'),
        content: Text(
            'End allocation for ${alloc.studentName} from Room ${alloc.roomNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _api.deleteAllocation(alloc.id);
              if (res['success'] == true) {
                _showSuccess('Allocation ended');
                _fetchAllocations();
              } else {
                _showError('Failed to end allocation');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error500,
            ),
            child: const Text('End Allocation'),
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
          decoration:
              const BoxDecoration(gradient: AppTheme.navbarGradient),
        ),
        title: const Text('Allocations'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAllocationModal,
        icon: const Icon(Icons.add),
        label: const Text('New Allocation'),
        backgroundColor: AppTheme.primary600,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allocations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_outlined,
                          size: 64, color: AppTheme.gray300),
                      const SizedBox(height: 16),
                      Text('No active allocations',
                          style:
                              TextStyle(color: AppTheme.gray500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllocations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allocations.length,
                    itemBuilder: (ctx, i) {
                      final alloc = _allocations[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.gray200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primary100,
                              child: Text(
                                alloc.studentName.isNotEmpty
                                    ? alloc.studentName[0]
                                        .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alloc.studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppTheme.gray900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alloc.registrationNumber,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.gray500,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.room,
                                          size: 14,
                                          color: AppTheme.gray400),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${alloc.hostelName} - Room ${alloc.roomNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 12,
                                          color: AppTheme.gray400),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Since ${alloc.allocationDate.day}/${alloc.allocationDate.month}/${alloc.allocationDate.year}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.gray400,
                                        ),
                                      ),
                                      if (alloc.expectedCheckout !=
                                          null) ...[
                                        const Text(' · ',
                                            style: TextStyle(
                                                color:
                                                    AppTheme.gray400)),
                                        Text(
                                          'Out ${alloc.expectedCheckout!.day}/${alloc.expectedCheckout!.month}/${alloc.expectedCheckout!.year}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.gray400,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _confirmEndAllocation(alloc),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.error500),
                              tooltip: 'End Allocation',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
