import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/student.dart';
import '../models/complaint.dart';
import '../models/payment.dart';
import '../models/room.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => ApiConfig.baseUrl;

  // ============ HTTP HELPERS ============

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _put(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'))
          .timeout(ApiConfig.timeout);

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Public raw GET for fetching pagination metadata, etc.
  Future<Map<String, dynamic>> getRaw(String endpoint) async {
    return await _get(endpoint);
  }

  // ============ DASHBOARD STATS ============

  Future<Map<String, int>> getDashboardStats() async {
    final stats = <String, int>{
      'totalStudents': 0,
      'totalRooms': 0,
      'openComplaints': 0,
      'pendingPayments': 0,
    };

    try {
      final results = await Future.wait([
        _get('/api/students?limit=1'),
        _get('/api/rooms?limit=1'),
        _get('/api/complaints?status=open&limit=1'),
        _get('/api/payments?status=pending&limit=1'),
      ]);

      stats['totalStudents'] = results[0]['pagination']?['total'] ?? 0;
      stats['totalRooms'] = results[1]['pagination']?['total'] ?? 0;
      stats['openComplaints'] = results[2]['pagination']?['total'] ??
          (results[2]['data'] as List?)?.length ??
          0;
      stats['pendingPayments'] = results[3]['pagination']?['total'] ??
          (results[3]['data'] as List?)?.length ??
          0;
    } catch (_) {}

    return stats;
  }

  // ============ STUDENTS API ============

  Future<Map<String, dynamic>> getStudentsRaw({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return await _get('/api/students?$queryString');
  }

  Future<List<Student>> getStudents({int limit = 50}) async {
    final data = await _get('/api/students?limit=$limit');
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Student.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Student?> getStudent(int id) async {
    final data = await _get('/api/students/$id');
    if (data['success'] == true) {
      return Student.fromJson(data['data']);
    }
    return null;
  }

  Future<Map<String, dynamic>> createStudent(
      Map<String, dynamic> studentData) async {
    return await _post('/api/students', studentData);
  }

  Future<Map<String, dynamic>> updateStudentData(
      int id, Map<String, dynamic> updates) async {
    return await _put('/api/students/$id', updates);
  }

  Future<bool> updateStudent(int id, Map<String, dynamic> updates) async {
    final data = await _put('/api/students/$id', updates);
    return data['success'] == true;
  }

  Future<Map<String, dynamic>> deactivateStudent(int id) async {
    return await _delete('/api/students/$id');
  }

  // ============ COMPLAINTS API ============

  Future<List<Complaint>> getComplaints(int studentId) async {
    final data = await _get('/api/complaints?student_id=$studentId');
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Complaint.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<Complaint>> getAllComplaints({
    String? status,
    String? category,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (category != null && category.isNotEmpty) params['category'] = category;
    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _get('/api/complaints?$queryString');
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Complaint.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<bool> createComplaint({
    required int studentId,
    required int roomId,
    required String category,
    required String title,
    required String description,
    required int priority,
  }) async {
    final data = await _post('/api/complaints', {
      'student_id': studentId,
      'room_id': roomId,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
    });
    return data['success'] == true;
  }

  Future<Map<String, dynamic>> getComplaintDetail(int id) async {
    return await _get('/api/complaints/$id');
  }

  Future<Map<String, dynamic>> updateComplaint(
      int id, Map<String, dynamic> updates) async {
    return await _put('/api/complaints/$id', updates);
  }

  // ============ PAYMENTS API ============

  Future<List<Payment>> getPayments(int studentId, {int limit = 50}) async {
    final data =
        await _get('/api/payments?student_id=$studentId&limit=$limit');
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Payment.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<Payment>> getAllPayments({
    String? status,
    bool? overdue,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (status != null && status != 'all') params['status'] = status;
    if (overdue == true) params['overdue'] = 'true';
    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _get('/api/payments?$queryString');
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Payment.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createPayment(
      Map<String, dynamic> paymentData) async {
    return await _post('/api/payments', paymentData);
  }

  Future<bool> updatePayment(int id, Map<String, dynamic> updates) async {
    final data = await _put('/api/payments/$id', updates);
    return data['success'] == true;
  }

  Future<Map<String, dynamic>> updatePaymentRaw(
      int id, Map<String, dynamic> updates) async {
    return await _put('/api/payments/$id', updates);
  }

  // ============ ALLOCATIONS API ============

  Future<List<Allocation>> getAllocations({
    int? studentId,
    int? roomId,
    bool? isActive,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (studentId != null) params['student_id'] = studentId.toString();
    if (roomId != null) params['room_id'] = roomId.toString();
    if (isActive != null) params['is_active'] = isActive.toString();

    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _get('/api/allocations?$queryString');

    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Allocation.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createAllocation(
      Map<String, dynamic> allocationData) async {
    return await _post('/api/allocations', allocationData);
  }

  Future<Map<String, dynamic>> deleteAllocation(int id) async {
    return await _delete('/api/allocations/$id');
  }

  // ============ ROOMS API ============

  Future<List<RoomDetails>> getRooms({
    int? hostelId,
    String? roomType,
    int limit = 100,
    int page = 1,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'page': page.toString(),
    };
    if (hostelId != null) params['hostel_id'] = hostelId.toString();
    if (roomType != null && roomType.isNotEmpty) {
      params['room_type'] = roomType;
    }
    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _get('/api/rooms?$queryString');
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => RoomDetails.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<RoomDetails?> getRoom(int id) async {
    final data = await _get('/api/rooms?limit=100');
    if (data['success'] == true) {
      final rooms = data['data'] as List;
      final room = rooms.firstWhere(
        (r) => r['id'] == id,
        orElse: () => null,
      );
      if (room != null) {
        return RoomDetails.fromJson(room);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> createRoom(
      Map<String, dynamic> roomData) async {
    return await _post('/api/rooms', roomData);
  }

  // ============ HOSTELS API ============

  Future<List<Map<String, dynamic>>> getHostels() async {
    final data = await _get('/api/hostels?limit=100');
    if (data['success'] == true) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createHostel(
      Map<String, dynamic> hostelData) async {
    return await _post('/api/hostels', hostelData);
  }
}
