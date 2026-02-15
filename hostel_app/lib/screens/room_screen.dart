import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RoomScreen extends StatefulWidget {
  final int studentId;

  const RoomScreen({super.key, required this.studentId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final ApiService _apiService = ApiService();
  Allocation? _allocation;
  RoomDetails? _roomDetails;
  List<Allocation> _roommates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current allocation for student
      final allocations = await _apiService.getAllocations(
        studentId: widget.studentId,
        isActive: true,
      );

      if (allocations.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final allocation = allocations.first;
      setState(() => _allocation = allocation);

      // Get roommates
      final allRoomAllocations = await _apiService.getAllocations(
        roomId: allocation.roomId,
        isActive: true,
      );
      setState(() {
        _roommates = allRoomAllocations
            .where((a) => a.studentId != widget.studentId)
            .toList();
      });

      // Get room details
      final roomDetails = await _apiService.getRoom(allocation.roomId);
      if (roomDetails != null) {
        setState(() => _roomDetails = roomDetails);
      }
    } catch (e) {
      debugPrint('Error loading room data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('My Room'),
        backgroundColor: AppTheme.primary900,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary600),
            )
          : _allocation == null
              ? _buildNoRoomState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.primary600,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room Details Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gray200),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.gray50.withValues(alpha: 0.5),
                                  border: Border(
                                    bottom: BorderSide(color: AppTheme.gray100),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Room Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailItem(
                                            'Room Number',
                                            _allocation!.roomNumber,
                                            isLarge: true,
                                            valueColor: AppTheme.primary900,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildDetailItem(
                                            'Hostel Block',
                                            _allocation!.hostelName,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    if (_roomDetails != null) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDetailItem(
                                              'Floor',
                                              _roomDetails!.floor.toString(),
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildDetailItem(
                                              'Room Type',
                                              _roomDetails!.roomType
                                                  .split('_')
                                                  .map((w) => w[0].toUpperCase() + w.substring(1))
                                                  .join(' '),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDetailItem(
                                              'Rent per Year',
                                              '₹${_roomDetails!.rentAmount.toStringAsFixed(0)}',
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildDetailItem(
                                              'Check-in Date',
                                              _formatDate(_allocation!.allocationDate),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _buildAmenities(),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Roommates Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gray200),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.gray50.withValues(alpha: 0.5),
                                  border: Border(
                                    bottom: BorderSide(color: AppTheme.gray100),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Roommates',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: _roommates.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            children: [
                                              Text(
                                                '🛏️',
                                                style: TextStyle(
                                                  fontSize: 40,
                                                  color: Colors.grey.withValues(alpha: 0.5),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'No roommates assigned yet.',
                                                style: TextStyle(
                                                  color: AppTheme.gray500,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: _roommates.map((roommate) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.gray100),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary100,
                                                    borderRadius: BorderRadius.circular(24),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      roommate.studentName.isNotEmpty
                                                          ? roommate.studentName[0].toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.primary600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        roommate.studentName,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: AppTheme.gray900,
                                                        ),
                                                      ),
                                                      const Text(
                                                        'STUDENT',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          letterSpacing: 0.5,
                                                          color: AppTheme.gray500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoRoomState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏠',
                style: TextStyle(
                  fontSize: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Room Allocated',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have not been assigned a room yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isLarge = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 22 : 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    if (_roomDetails == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_roomDetails!.hasAc)
              _buildAmenityChip('AC', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
            if (_roomDetails!.hasAttachedBathroom)
              _buildAmenityChip('Attached Bath', const Color(0xFFDCFCE7), const Color(0xFF065F46)),
            if (!_roomDetails!.hasAc && !_roomDetails!.hasAttachedBathroom)
              const Text(
                'Standard',
                style: TextStyle(color: AppTheme.gray500),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
