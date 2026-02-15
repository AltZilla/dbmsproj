import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/room.dart';

class AdminHostelsScreen extends StatefulWidget {
  const AdminHostelsScreen({super.key});

  @override
  State<AdminHostelsScreen> createState() => _AdminHostelsScreenState();
}

class _AdminHostelsScreenState extends State<AdminHostelsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _hostels = [];
  Map<int, List<RoomDetails>> _hostelRooms = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      _hostels = await _api.getHostels();
      final allRooms = await _api.getRooms(limit: 500);

      _hostelRooms = {};
      for (final r in allRooms) {
        _hostelRooms.putIfAbsent(r.hostelId, () => []).add(r);
      }
    } catch (_) {
      _showError('Failed to load hostels');
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

  // ========== ADD HOSTEL ==========
  void _showCreateHostelModal() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final wardenCtrl = TextEditingController();
    final wardenPhoneCtrl = TextEditingController();
    String gender = 'male';
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
                        'Add Hostel',
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

                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Hostel Name'),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(
                        labelText: 'Gender Allowed'),
                    items: ['male', 'female', 'any']
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                  g[0].toUpperCase() + g.substring(1)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) gender = val;
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: wardenCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Warden Name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: wardenPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'Warden Phone'),
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
                              if (nameCtrl.text.isEmpty) {
                                _showError('Name is required');
                                return;
                              }
                              setModalState(() => submitting = true);

                              final body = <String, dynamic>{
                                'name': nameCtrl.text,
                                'gender_allowed': gender,
                              };
                              if (addressCtrl.text.isNotEmpty) {
                                body['address'] = addressCtrl.text;
                              }
                              if (wardenCtrl.text.isNotEmpty) {
                                body['warden_name'] = wardenCtrl.text;
                              }
                              if (wardenPhoneCtrl.text.isNotEmpty) {
                                body['warden_phone'] = wardenPhoneCtrl.text;
                              }

                              final res = await _api.createHostel(body);
                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                _showSuccess('Hostel created!');
                                _fetchData();
                              } else {
                                _showError(res['error'] ??
                                    'Failed to create hostel');
                              }
                              setModalState(() => submitting = false);
                            },
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(submitting
                          ? 'Creating...'
                          : 'Create Hostel'),
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

  // ========== HOSTEL DETAIL ==========
  void _showHostelDetail(Map<String, dynamic> hostel) {
    final hostelId = hostel['id'] as int;
    final rooms = _hostelRooms[hostelId] ?? [];
    final totalRooms = rooms.length;
    final totalCapacity = rooms.fold<int>(0, (s, r) => s + r.capacity);
    final totalOccupancy =
        rooms.fold<int>(0, (s, r) => s + r.currentOccupancy);
    final occupancyPct =
        totalCapacity > 0 ? (totalOccupancy / totalCapacity * 100) : 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.gray50,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration:
                  const BoxDecoration(gradient: AppTheme.navbarGradient),
            ),
            title: Text(hostel['name'] ?? 'Hostel'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostel['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hostel['address'] != null)
                        Text(
                          hostel['address'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray500,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statTile('Rooms', '$totalRooms'),
                          _statTile('Capacity', '$totalCapacity'),
                          _statTile('Occupied', '$totalOccupancy'),
                          _statTile('Rate',
                              '${occupancyPct.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Occupancy bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: totalCapacity > 0
                              ? totalOccupancy / totalCapacity
                              : 0,
                          minHeight: 8,
                          backgroundColor: AppTheme.gray200,
                          color: occupancyPct > 90
                              ? AppTheme.error500
                              : occupancyPct > 60
                                  ? const Color(0xFFF59E0B)
                                  : AppTheme.success500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Warden info
                if (hostel['warden_name'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primary100,
                          child: Icon(Icons.person,
                              color: AppTheme.primary600),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warden',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.gray400,
                              ),
                            ),
                            Text(
                              hostel['warden_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gray900,
                              ),
                            ),
                            if (hostel['warden_phone'] != null)
                              Text(
                                hostel['warden_phone'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.gray500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Room list
                Text(
                  'Rooms ($totalRooms)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray800,
                  ),
                ),
                const SizedBox(height: 8),

                if (rooms.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Text(
                      'No rooms in this hostel',
                      style:
                          TextStyle(color: AppTheme.gray500),
                    ),
                  )
                else
                  ...rooms.map((r) {
                    final status = !r.isAvailable
                        ? 'maintenance'
                        : r.currentOccupancy >= r.capacity
                            ? 'full'
                            : r.currentOccupancy > 0
                                ? 'partial'
                                : 'empty';
                    Color sColor;
                    switch (status) {
                      case 'full':
                        sColor = AppTheme.error500;
                        break;
                      case 'partial':
                        sColor = const Color(0xFFF59E0B);
                        break;
                      case 'empty':
                        sColor = AppTheme.success500;
                        break;
                      default:
                        sColor = AppTheme.gray500;
                    }

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
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: sColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room ${r.roomNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                                Text(
                                  'Floor ${r.floor} · ${r.roomType} · ${r.currentOccupancy}/${r.capacity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${r.rentAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.gray800,
                                ),
                              ),
                              Row(
                                children: [
                                  if (r.hasAc)
                                    const Text('❄️',
                                        style:
                                            TextStyle(fontSize: 12)),
                                  if (r.hasAttachedBathroom)
                                    const Text('🚿',
                                        style:
                                            TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.gray500,
          ),
        ),
      ],
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
        title: const Text('Hostels'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateHostelModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Hostel'),
        backgroundColor: AppTheme.primary600,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hostels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment,
                          size: 64, color: AppTheme.gray300),
                      const SizedBox(height: 16),
                      Text('No hostels found',
                          style:
                              TextStyle(color: AppTheme.gray500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _hostels.length,
                    itemBuilder: (ctx, i) {
                      final h = _hostels[i];
                      final hostelId = h['id'] as int;
                      final rooms = _hostelRooms[hostelId] ?? [];
                      final totalRooms = rooms.length;
                      final totalCapacity =
                          rooms.fold<int>(0, (s, r) => s + r.capacity);
                      final totalOccupancy = rooms.fold<int>(
                          0, (s, r) => s + r.currentOccupancy);
                      final occupancy = totalCapacity > 0
                          ? (totalOccupancy / totalCapacity * 100)
                          : 0.0;

                      return GestureDetector(
                        onTap: () => _showHostelDetail(h),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppTheme.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('🏢',
                                      style:
                                          TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                        if (h['address'] != null)
                                          Text(
                                            h['address'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppTheme.gray500,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary100,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (h['gender_allowed'] ??
                                              'any')
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _miniStat('Rooms', '$totalRooms'),
                                  _miniStat(
                                      'Capacity', '$totalCapacity'),
                                  _miniStat(
                                      'Occupied', '$totalOccupancy'),
                                  _miniStat('Rate',
                                      '${occupancy.toStringAsFixed(0)}%'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalCapacity > 0
                                      ? totalOccupancy / totalCapacity
                                      : 0,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.gray200,
                                  color: occupancy > 90
                                      ? AppTheme.error500
                                      : occupancy > 60
                                          ? const Color(0xFFF59E0B)
                                          : AppTheme.success500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.gray500,
          ),
        ),
      ],
    );
  }
}
