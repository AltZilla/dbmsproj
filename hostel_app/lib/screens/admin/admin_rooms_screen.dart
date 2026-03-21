import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/room.dart';
import '../../models/student.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  List<RoomDetails> _rooms = [];
  List<Map<String, dynamic>> _hostels = [];
  bool _loading = true;

  // Table filters
  int? _filterHostelId;
  String _filterType = '';

  // Grid state
  int? _selectedHostelId;
  RoomDetails? _selectedRoom;
  List<Allocation> _roomAllocations = [];
  bool _sidebarLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchRooms();
      }
    });
    _fetchHostels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHostels() async {
    try {
      _hostels = await _api.getHostels();
      if (_hostels.isNotEmpty) {
        _selectedHostelId ??= _hostels.first['id'];
      }
    } catch (_) {}
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      if (_tabController.index == 0) {
        // Table view
        _rooms = await _api.getRooms(
          hostelId: _filterHostelId,
          roomType: _filterType.isNotEmpty ? _filterType : null,
        );
      } else {
        // Grid view
        _rooms = await _api.getRooms(hostelId: _selectedHostelId);
        _selectedRoom = null;
      }
    } catch (_) {
      _showError('Failed to load rooms');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchRoomDetails(RoomDetails room) async {
    setState(() {
      _selectedRoom = room;
      _sidebarLoading = true;
    });
    try {
      _roomAllocations = await _api.getAllocations(
        roomId: room.id,
        isActive: true,
      );
    } catch (_) {}
    if (mounted) setState(() => _sidebarLoading = false);
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

  String _getRoomStatus(RoomDetails r) {
    if (!r.isAvailable) return 'maintenance';
    if (r.currentOccupancy >= r.capacity) return 'full';
    if (r.currentOccupancy > 0) return 'partial';
    return 'empty';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'full':
        return AppTheme.error500;
      case 'partial':
        return const Color(0xFFF59E0B);
      case 'empty':
        return AppTheme.success500;
      case 'maintenance':
        return AppTheme.gray500;
      default:
        return AppTheme.gray400;
    }
  }

  // ========== CREATE ROOM MODAL ==========
  void _showCreateRoomModal() {
    int? hostelId;
    final roomNumCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    String roomType = 'double';
    final capacityCtrl = TextEditingController(text: '2');
    final rentCtrl = TextEditingController();
    bool hasAc = false;
    bool hasBath = false;
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
                        'Add Room',
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
                    decoration:
                        const InputDecoration(labelText: 'Hostel'),
                    items: _hostels
                        .map((h) => DropdownMenuItem(
                              value: h['id'] as int,
                              child: Text(h['name'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (val) => hostelId = val,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: roomNumCtrl, // This is now room sequence
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Room Sequence (e.g. 1, 2)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: floorCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Floor'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: roomType,
                          decoration:
                              const InputDecoration(labelText: 'Type'),
                          items: ['single', 'double', 'triple', 'dormitory']
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                        t[0].toUpperCase() + t.substring(1)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                roomType = val;
                                capacityCtrl.text = val == 'single'
                                    ? '1'
                                    : val == 'double'
                                        ? '2'
                                        : val == 'triple'
                                            ? '3'
                                            : '6';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: capacityCtrl,
                          readOnly: true, // Auto-filled based on type
                          decoration:
                              const InputDecoration(labelText: 'Capacity'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: rentCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Rent Amount (₹)'),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('AC', style: TextStyle(fontSize: 14)),
                          value: hasAc,
                          onChanged: (val) =>
                              setModalState(() => hasAc = val ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Bathroom',
                              style: TextStyle(fontSize: 14)),
                          value: hasBath,
                          onChanged: (val) =>
                              setModalState(() => hasBath = val ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (hostelId == null ||
                                  roomNumCtrl.text.isEmpty) {
                                _showError('Fill required fields');
                                return;
                              }
                              setModalState(() => submitting = true);
                              final res = await _api.createRoom({
                                'hostel_id': hostelId,
                                'room_sequence': int.tryParse(roomNumCtrl.text) ?? 0,
                                'floor': int.tryParse(floorCtrl.text) ?? 0,
                                'room_type': roomType,
                                'capacity':
                                    int.tryParse(capacityCtrl.text) ?? 2,
                                'rent_amount':
                                    double.tryParse(rentCtrl.text) ?? 0,
                                'has_ac': hasAc,
                                'has_attached_bathroom': hasBath,
                              });
                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                _showSuccess('Room created!');
                                _fetchRooms();
                              } else {
                                _showError(
                                    res['error'] ?? 'Failed to create room');
                              }
                              setModalState(() => submitting = false);
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child:
                          Text(submitting ? 'Creating...' : 'Create Room'),
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

  // ========== ASSIGN STUDENT MODAL ==========
  void _showAssignStudentModal() async {
    if (_selectedRoom == null) return;

    List<Student> students = [];
    try {
      students = await _api.getStudents(limit: 200);
      // Filter: only unassigned students
      final allocs = await _api.getAllocations(isActive: true, limit: 500);
      final allocatedIds = allocs.map((a) => a.studentId).toSet();
      students = students.where((s) => !allocatedIds.contains(s.id)).toList();
    } catch (_) {}

    if (!mounted) return;

    int? selectedStudentId;
    final checkoutCtrl = TextEditingController();

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
                  Text(
                    'Assign Student to Room ${_selectedRoom!.roomNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                      onPressed: () async {
                        if (selectedStudentId == null) {
                          _showError('Select a student');
                          return;
                        }
                        final body = <String, dynamic>{
                          'student_id': selectedStudentId,
                          'room_id': _selectedRoom!.id,
                        };
                        if (checkoutCtrl.text.isNotEmpty) {
                          body['expected_checkout'] = checkoutCtrl.text;
                        }
                        final res = await _api.createAllocation(body);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          _showSuccess('Student assigned!');
                          _fetchRoomDetails(_selectedRoom!);
                          _fetchRooms();
                        } else {
                          _showError(
                              res['error'] ?? 'Failed to assign');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Assign Student'),
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

  // ========== REMOVE STUDENT ==========
  void _removeStudent(Allocation alloc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Student'),
        content: Text(
            'Remove ${alloc.studentName} from this room?'),
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
                _showSuccess('Student removed');
                if (_selectedRoom != null) _fetchRoomDetails(_selectedRoom!);
                _fetchRooms();
              } else {
                _showError('Failed to remove');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error500,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // =================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.navbarGradient),
        ),
        title: const Text('Rooms'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.table_chart), text: 'Table'),
            Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoomModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
        backgroundColor: AppTheme.primary600,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTableView(),
          _buildGridView(),
        ],
      ),
    );
  }

  // ============ TABLE VIEW ============
  Widget _buildTableView() {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _filterHostelId,
                  decoration: const InputDecoration(
                    labelText: 'Hostel',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Hostels')),
                    ..._hostels.map((h) => DropdownMenuItem(
                          value: h['id'] as int,
                          child: Text(h['name'] ?? ''),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _filterHostelId = val);
                    _fetchRooms();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: ['', 'single', 'double', 'triple', 'dormitory']
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.isEmpty
                                ? 'All Types'
                                : t[0].toUpperCase() + t.substring(1)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _filterType = val ?? '');
                    _fetchRooms();
                  },
                ),
              ),
            ],
          ),
        ),

        // Table
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rooms.isEmpty
                  ? const Center(child: Text('No rooms found'))
                  : RefreshIndicator(
                      onRefresh: _fetchRooms,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rooms.length,
                        itemBuilder: (ctx, i) {
                          final r = _rooms[i];
                          final status = _getRoomStatus(r);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.gray200),
                            ),
                            child: Row(
                              children: [
                                // Room info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            r.roomNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: AppTheme.gray900,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: _statusColor(status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${r.hostelName} · Floor ${r.floor} · ${r.roomType}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.gray500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Occupancy
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${r.currentOccupancy}/${r.capacity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: AppTheme.gray800,
                                      ),
                                    ),
                                    Text(
                                      '₹${r.rentAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // Amenity badges
                                Column(
                                  children: [
                                    if (r.hasAc)
                                      const Text('❄️',
                                          style: TextStyle(fontSize: 14)),
                                    if (r.hasAttachedBathroom)
                                      const Text('🚿',
                                          style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ============ GRID VIEW ============
  Widget _buildGridView() {
    // Group rooms by floor
    final roomsByFloor = <int, List<RoomDetails>>{};
    for (final r in _rooms) {
      roomsByFloor.putIfAbsent(r.floor, () => []).add(r);
    }
    final sortedFloors = roomsByFloor.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        // Hostel selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: DropdownButtonFormField<int>(
            value: _selectedHostelId,
            decoration: const InputDecoration(
              labelText: 'Select Hostel',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _hostels
                .map((h) => DropdownMenuItem(
                      value: h['id'] as int,
                      child: Text(
                          '${h['name']} (${h['gender_allowed'] ?? ''})'),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedHostelId = val;
                _selectedRoom = null;
              });
              _fetchRooms();
            },
          ),
        ),

        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem('Available', AppTheme.success500),
              _legendItem('Partial', const Color(0xFFF59E0B)),
              _legendItem('Full', AppTheme.error500),
              _legendItem('Maint.', AppTheme.gray500),
            ],
          ),
        ),

        // Grid + Sidebar
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rooms.isEmpty
                  ? const Center(child: Text('No rooms in this hostel'))
                  : Row(
                      children: [
                        // Grid
                        Expanded(
                          flex: _selectedRoom != null ? 3 : 1,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedFloors.map((floor) {
                                final floorRooms = roomsByFloor[floor]!
                                  ..sort((a, b) =>
                                      a.roomNumber.compareTo(b.roomNumber));
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Floor $floor · ${floorRooms.length} rooms',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.gray700,
                                        ),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          floorRooms.map((room) {
                                        final status =
                                            _getRoomStatus(room);
                                        final isSelected =
                                            _selectedRoom?.id == room.id;
                                        return GestureDetector(
                                          onTap: () =>
                                              _fetchRoomDetails(room),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            width: 76,
                                            padding:
                                                const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withOpacity(
                                                      isSelected
                                                          ? 0.25
                                                          : 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                              border: Border.all(
                                                color: isSelected
                                                    ? _statusColor(
                                                        status)
                                                    : _statusColor(
                                                            status)
                                                        .withOpacity(
                                                            0.3),
                                                width:
                                                    isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  room.roomNumber,
                                                  style:
                                                      const TextStyle(
                                                    fontWeight:
                                                        FontWeight
                                                            .w700,
                                                    fontSize: 13,
                                                    color: AppTheme
                                                        .gray900,
                                                  ),
                                                ),
                                                Text(
                                                  '${room.currentOccupancy}/${room.capacity}',
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme
                                                        .gray500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // Sidebar
                        if (_selectedRoom != null)
                          Container(
                            width: MediaQuery.of(context).size.width * 0.42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                left: BorderSide(color: AppTheme.gray200),
                              ),
                            ),
                            child: _buildSidebar(),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    final room = _selectedRoom!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Room ${room.roomNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedRoom = null),
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Info
          _infoRow('Type', room.roomType),
          _infoRow('Floor', '${room.floor}'),
          _infoRow('Occupancy', '${room.currentOccupancy}/${room.capacity}'),
          _infoRow('Rent', '₹${room.rentAmount.toStringAsFixed(0)}'),
          if (room.hasAc || room.hasAttachedBathroom)
            _infoRow(
                'Amenities',
                [
                  if (room.hasAc) '❄️ AC',
                  if (room.hasAttachedBathroom) '🚿 Bath',
                ].join(', ')),

          const Divider(height: 24),

          // Occupants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Occupants',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.gray800,
                ),
              ),
              if (room.currentOccupancy < room.capacity && room.isAvailable)
                GestureDetector(
                  onTap: _showAssignStudentModal,
                  child: const Text(
                    '+ Add',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_sidebarLoading)
            const Center(child: CircularProgressIndicator())
          else if (_roomAllocations.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('👤',
                      style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  const Text(
                    'No students',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.gray500),
                  ),
                  if (room.isAvailable) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showAssignStudentModal,
                      child: const Text('Assign First Student'),
                    ),
                  ],
                ],
              ),
            )
          else
            ..._roomAllocations.map((alloc) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary100,
                        child: Text(
                          alloc.studentName.isNotEmpty
                              ? alloc.studentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alloc.studentName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gray900,
                              ),
                            ),
                            Text(
                              alloc.registrationNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeStudent(alloc),
                        child: const Icon(Icons.close,
                            size: 18, color: AppTheme.error500),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.gray600),
        ),
      ],
    );
  }
}
