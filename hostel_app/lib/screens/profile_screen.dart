import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final int studentId;

  const ProfileScreen({super.key, required this.studentId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Student? _student;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _message;
  bool _isSuccess = false;

  // Form controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    setState(() => _isLoading = true);
    try {
      final student = await _apiService.getStudent(widget.studentId);
      if (student != null) {
        setState(() {
          _student = student;
          _emailController.text = student.email;
          _phoneController.text = student.phone ?? '';
          _guardianNameController.text = student.guardianName ?? '';
          _guardianPhoneController.text = student.guardianPhone ?? '';
          _addressController.text = student.address ?? '';
        });
      }
    } catch (e) {
      setState(() => _message = 'Failed to load profile');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final success = await _apiService.updateStudent(widget.studentId, {
        'email': _emailController.text,
        'phone': _phoneController.text,
        'guardian_name': _guardianNameController.text,
        'guardian_phone': _guardianPhoneController.text,
        'address': _addressController.text,
      });

      if (success) {
        setState(() {
          _isEditing = false;
          _isSuccess = true;
          _message = 'Profile updated successfully';
        });
        await _loadStudent();
      } else {
        setState(() {
          _isSuccess = false;
          _message = 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'An error occurred';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelEdit() {
    if (_student != null) {
      setState(() {
        _isEditing = false;
        _emailController.text = _student!.email;
        _phoneController.text = _student!.phone ?? '';
        _guardianNameController.text = _student!.guardianName ?? '';
        _guardianPhoneController.text = _student!.guardianPhone ?? '';
        _addressController.text = _student!.address ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.primary900,
      ),
      body: _isLoading && _student == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary600),
            )
          : _student == null
              ? const Center(child: Text('Student not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Status Message
                      if (_message != null)
                        Container(
                          width: double.infinity,
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isSuccess
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Profile Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.gray100),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppTheme.primary500, Color(0xFF9333EA)],
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary500.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${_student!.firstName[0]}${_student!.lastName[0]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _student!.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _student!.registrationNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.gray500,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _student!.isActive
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _student!.isActive
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                _student!.isActive ? 'ACTIVE STUDENT' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: _student!.isActive
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Personal Details Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.gray100),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.gray50.withValues(alpha: 0.5),
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.gray100),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Personal Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.gray900,
                                    ),
                                  ),
                                  if (!_isEditing)
                                    TextButton(
                                      onPressed: () => setState(() => _isEditing = true),
                                      child: const Text('Edit Details'),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildField(
                                    'Email Address',
                                    _emailController,
                                    enabled: _isEditing,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildField(
                                    'Phone Number',
                                    _phoneController,
                                    enabled: _isEditing,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildReadOnlyField(
                                    'Date of Birth',
                                    _student!.dateOfBirth != null
                                        ? DateTime.parse(_student!.dateOfBirth!)
                                            .toString()
                                            .split(' ')[0]
                                        : 'N/A',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildReadOnlyField(
                                    'Gender',
                                    _student!.gender?.toUpperCase() ?? 'N/A',
                                  ),
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Guardian Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildField(
                                    'Guardian Name',
                                    _guardianNameController,
                                    enabled: _isEditing,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildField(
                                    'Guardian Phone',
                                    _guardianPhoneController,
                                    enabled: _isEditing,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildField(
                                    'Permanent Address',
                                    _addressController,
                                    enabled: _isEditing,
                                    maxLines: 3,
                                  ),
                                  if (_isEditing) ...[
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _cancelEdit,
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _saveProfile,
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Text('Save Changes'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
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
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : AppTheme.gray50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.gray300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.gray200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.gray50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
        ),
      ],
    );
  }
}
