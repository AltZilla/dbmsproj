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

    Student? selectedStudent;
    RoomDetails? selectedRoom;
    DateTime? checkoutDate;
    String studentSearch = '';
    String roomSearch = '';
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final filteredStudents = studentSearch.isEmpty
              ? students
              : students
                  .where((s) =>
                      s.fullName
                          .toLowerCase()
                          .contains(studentSearch.toLowerCase()) ||
                      s.registrationNumber
                          .toLowerCase()
                          .contains(studentSearch.toLowerCase()))
                  .toList();

          final filteredRooms = roomSearch.isEmpty
              ? rooms
              : rooms
                  .where((r) =>
                      r.roomNumber
                          .toLowerCase()
                          .contains(roomSearch.toLowerCase()) ||
                      r.hostelName
                          .toLowerCase()
                          .contains(roomSearch.toLowerCase()))
                  .toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: AppTheme.gray200, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.vpn_key,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New Allocation',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.gray900)),
                            Text('Assign a student to a room',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray500)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close,
                            color: AppTheme.gray400),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Step 1: Student ──
                        _sectionLabel('1', 'Select Student',
                            '${students.length} unallocated'),

                        if (selectedStudent != null)
                          _selectedChip(
                            icon: Icons.person,
                            label: selectedStudent!.fullName,
                            subtitle: selectedStudent!.registrationNumber,
                            color: AppTheme.primary600,
                            onClear: () =>
                                setModalState(() => selectedStudent = null),
                          )
                        else ...[
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by name or reg number...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppTheme.gray200)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppTheme.gray200)),
                              filled: true,
                              fillColor: AppTheme.gray50,
                            ),
                            onChanged: (val) =>
                                setModalState(() => studentSearch = val),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints:
                                const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: AppTheme.gray200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: filteredStudents.isEmpty
                                ? const Center(
                                    child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No students found',
                                        style: TextStyle(
                                            color: AppTheme.gray400)),
                                  ))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filteredStudents.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final s = filteredStudents[i];
                                      return ListTile(
                                        dense: true,
                                        visualDensity:
                                            VisualDensity.compact,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              AppTheme.primary100,
                                          child: Text(
                                            s.firstName.isNotEmpty
                                                ? s.firstName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color:
                                                    AppTheme.primary700),
                                          ),
                                        ),
                                        title: Text(s.fullName,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w500)),
                                        subtitle: Text(
                                          '${s.registrationNumber}  ·  ${s.gender ?? ''}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.gray500),
                                        ),
                                        trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: AppTheme.gray300),
                                        onTap: () => setModalState(() {
                                          selectedStudent = s;
                                          studentSearch = '';
                                        }),
                                      );
                                    },
                                  ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Step 2: Room ──
                        _sectionLabel('2', 'Select Room',
                            '${rooms.length} available'),

                        if (selectedRoom != null)
                          _selectedChip(
                            icon: Icons.meeting_room,
                            label:
                                '${selectedRoom!.hostelName} — ${selectedRoom!.roomNumber}',
                            subtitle:
                                '${selectedRoom!.roomType}  ·  ${selectedRoom!.currentOccupancy}/${selectedRoom!.capacity} occupied  ·  ₹${selectedRoom!.rentAmount.toStringAsFixed(0)}',
                            color: AppTheme.success600,
                            onClear: () =>
                                setModalState(() => selectedRoom = null),
                          )
                        else ...[
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by hostel or room...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppTheme.gray200)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppTheme.gray200)),
                              filled: true,
                              fillColor: AppTheme.gray50,
                            ),
                            onChanged: (val) =>
                                setModalState(() => roomSearch = val),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints:
                                const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: AppTheme.gray200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: filteredRooms.isEmpty
                                ? const Center(
                                    child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No rooms found',
                                        style: TextStyle(
                                            color: AppTheme.gray400)),
                                  ))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filteredRooms.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final r = filteredRooms[i];
                                      final spotsLeft =
                                          r.capacity - r.currentOccupancy;
                                      return ListTile(
                                        dense: true,
                                        visualDensity:
                                            VisualDensity.compact,
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: spotsLeft > 1
                                                ? AppTheme.success500
                                                    .withOpacity(0.1)
                                                : Colors.orange
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              r.roomNumber,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: spotsLeft > 1
                                                    ? AppTheme.success600
                                                    : Colors.orange[800],
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(r.hostelName,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w500)),
                                        subtitle: Row(
                                          children: [
                                            Text(
                                              '${r.roomType}  ·  $spotsLeft spot${spotsLeft != 1 ? 's' : ''} left',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppTheme.gray500),
                                            ),
                                            if (r.hasAc)
                                              const Text(' · ❄️',
                                                  style: TextStyle(
                                                      fontSize: 11)),
                                            if (r.hasAttachedBathroom)
                                              const Text(' · 🚿',
                                                  style: TextStyle(
                                                      fontSize: 11)),
                                          ],
                                        ),
                                        trailing: Text(
                                          '₹${r.rentAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.gray600),
                                        ),
                                        onTap: () => setModalState(() {
                                          selectedRoom = r;
                                          roomSearch = '';
                                        }),
                                      );
                                    },
                                  ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Step 3: Checkout date ──
                        _sectionLabel('3', 'Expected Checkout', 'optional'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx2,
                              initialDate: checkoutDate ??
                                  DateTime.now()
                                      .add(const Duration(days: 180)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 4)),
                            );
                            if (picked != null) {
                              setModalState(() => checkoutDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: AppTheme.gray200),
                              borderRadius: BorderRadius.circular(10),
                              color: AppTheme.gray50,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    size: 18, color: AppTheme.gray400),
                                const SizedBox(width: 10),
                                Text(
                                  checkoutDate != null
                                      ? '${checkoutDate!.day}/${checkoutDate!.month}/${checkoutDate!.year}'
                                      : 'Tap to pick a date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: checkoutDate != null
                                        ? AppTheme.gray800
                                        : AppTheme.gray400,
                                  ),
                                ),
                                const Spacer(),
                                if (checkoutDate != null)
                                  GestureDetector(
                                    onTap: () => setModalState(
                                        () => checkoutDate = null),
                                    child: const Icon(Icons.close,
                                        size: 16,
                                        color: AppTheme.gray400),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Summary & Submit ──
                        if (selectedStudent != null &&
                            selectedRoom != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary50,
                                  AppTheme.primary100.withOpacity(0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppTheme.primary200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primary200,
                                  child: Text(
                                    selectedStudent!.firstName.isNotEmpty
                                        ? selectedStudent!.firstName[0]
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary800),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(selectedStudent!.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppTheme.gray900)),
                                      Text(
                                          selectedStudent!
                                              .registrationNumber,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.gray500)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward,
                                    size: 18,
                                    color: AppTheme.primary400),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          '${selectedRoom!.hostelName} — ${selectedRoom!.roomNumber}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppTheme.gray900)),
                                      Text(selectedRoom!.roomType,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.gray500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (submitting ||
                                    selectedStudent == null ||
                                    selectedRoom == null)
                                ? null
                                : () async {
                                    setModalState(
                                        () => submitting = true);
                                    final body = <String, dynamic>{
                                      'student_id':
                                          selectedStudent!.id,
                                      'room_id': selectedRoom!.id,
                                    };
                                    if (checkoutDate != null) {
                                      body['expected_checkout'] =
                                          '${checkoutDate!.year}-${checkoutDate!.month.toString().padLeft(2, '0')}-${checkoutDate!.day.toString().padLeft(2, '0')}';
                                    }
                                    final res = await _api
                                        .createAllocation(body);
                                    if (res['success'] == true) {
                                      Navigator.pop(ctx);
                                      _showSuccess(
                                          'Allocation created!');
                                      _fetchAllocations();
                                    } else {
                                      _showError(res['error'] ??
                                          'Failed to create allocation');
                                    }
                                    setModalState(
                                        () => submitting = false);
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              disabledBackgroundColor:
                                  AppTheme.gray200,
                            ),
                            child: submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text('Create Allocation'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String step, String title, String badge) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.primary600,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.gray800)),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.gray500)),
        ),
      ],
    );
  }

  Widget _selectedChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: color)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.gray500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ========== AUTO-ALLOCATE ==========
  Future<void> _autoAllocate() async {
    // Confirm first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Auto-Allocate Rooms'),
        content: const Text(
          'This will automatically assign rooms to all unallocated students based on gender matching and room availability.\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Auto-Allocate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final res = await _api.autoAllocate();
      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final allocated = data['allocated'] as int;
        final failed = data['failed'] as int;
        final results = (data['results'] as List?) ?? [];
        final failures = (data['failures'] as List?) ?? [];

        _fetchAllocations();

        // Show results dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  allocated > 0
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: allocated > 0
                      ? AppTheme.success600
                      : AppTheme.warning600,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Auto-Allocation Results')),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _summaryChip(
                              '$allocated', 'Allocated',
                              AppTheme.success600),
                          _summaryChip(
                              '$failed', 'Failed',
                              failed > 0
                                  ? AppTheme.error500
                                  : AppTheme.gray400),
                        ],
                      ),
                    ),

                    // Allocated list
                    if (results.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('✅ Allocated',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      ...results.map((r) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${r['student_name']} → ${r['hostel_name']} ${r['room_number']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          )),
                    ],

                    // Failures list
                    if (failures.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('❌ Not Allocated',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.error500)),
                      const SizedBox(height: 6),
                      ...failures.map((f) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${f['student_name']}: ${f['reason']}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.gray600),
                            ),
                          )),
                    ],

                    if (results.isEmpty && failures.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'All students already have rooms assigned.',
                          style: TextStyle(color: AppTheme.gray500),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        _showError(res['error'] ?? 'Auto-allocation failed');
        setState(() => _loading = false);
      }
    } catch (e) {
      _showError('Auto-allocation error: $e');
      setState(() => _loading = false);
    }
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.gray500)),
      ],
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
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _autoAllocate,
            icon: const Icon(Icons.auto_fix_high, color: Colors.white),
            label: const Text('Auto-Allocate',
                style: TextStyle(color: Colors.white)),
          ),
        ],
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
