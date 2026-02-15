import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Student> _students = [];
  Student? _selectedStudent;
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  Student? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _apiService.getStudents();
      if (_students.isNotEmpty && _selectedStudent == null) {
        await selectStudent(_students.first.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectStudent(int studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedStudent = await _apiService.getStudent(studentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudentProfile(Map<String, dynamic> updates) async {
    if (_selectedStudent == null) return false;
    
    try {
      final success = await _apiService.updateStudent(_selectedStudent!.id, updates);
      if (success) {
        await selectStudent(_selectedStudent!.id);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
