import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/student.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final ApiService _api = ApiService();
  List<Student> _students = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  final int _limit = 10;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getStudentsRaw(
        page: _page,
        limit: _limit,
        search: _search.isNotEmpty ? _search : null,
      );
      if (data['success'] == true) {
        setState(() {
          _students = (data['data'] as List)
              .map((j) => Student.fromJson(j))
              .toList();
          _totalPages = data['pagination']?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      _showError('Failed to load students');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error500,
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.success600,
      ),
    );
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _page = 1;
    });
    _fetchStudents();
  }

  // ========== ADD STUDENT MODAL ==========
  void _showAddStudentModal() {
    final formKey = GlobalKey<FormState>();
    final data = <String, String>{
      'registration_number': '',
      'first_name': '',
      'last_name': '',
      'email': '',
      'phone': '',
      'gender': 'male',
      'date_of_birth': '',
      'guardian_name': '',
      'guardian_phone': '',
      'address': '',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentFormModal(
        title: 'Add New Student',
        formKey: formKey,
        data: data,
        onSubmit: (formData) async {
          final res = await _api.createStudent(formData);
          if (res['success'] == true) {
            if (mounted) Navigator.pop(ctx);
            _showSuccess('Student added successfully!');
            _fetchStudents();
          } else {
            _showError(res['error'] ?? 'Failed to add student');
          }
        },
      ),
    );
  }

  // ========== EDIT STUDENT MODAL ==========
  void _showEditStudentModal(Student student) {
    final formKey = GlobalKey<FormState>();
    final data = <String, String>{
      'registration_number': student.registrationNumber,
      'first_name': student.firstName,
      'last_name': student.lastName,
      'email': student.email,
      'phone': student.phone ?? '',
      'gender': student.gender ?? 'male',
      'date_of_birth': student.dateOfBirth ?? '',
      'guardian_name': student.guardianName ?? '',
      'guardian_phone': student.guardianPhone ?? '',
      'address': student.address ?? '',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentFormModal(
        title: 'Edit Student',
        formKey: formKey,
        data: data,
        isEdit: true,
        onSubmit: (formData) async {
          final res = await _api.updateStudentData(student.id, formData);
          if (res['success'] == true) {
            if (mounted) Navigator.pop(ctx);
            _showSuccess('Student updated successfully!');
            _fetchStudents();
          } else {
            _showError(res['error'] ?? 'Failed to update student');
          }
        },
      ),
    );
  }

  // ========== DEACTIVATE ==========
  void _confirmDeactivate(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deactivate Student'),
        content: Text(
            'Are you sure you want to deactivate ${student.fullName}? This will mark them as inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await _api.deactivateStudent(student.id);
                if (res['success'] == true) {
                  _showSuccess('Student deactivated');
                  _fetchStudents();
                } else {
                  _showError(res['error'] ?? 'Failed to deactivate');
                }
              } catch (_) {
                _showError('An error occurred');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error500,
            ),
            child: const Text('Deactivate'),
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
        title: const Text('Students'),
      ),

      body: Column(
        children: [
          // Search & Add
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                    ),
                    onSubmitted: _onSearch,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddStudentModal,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: AppTheme.gray300),
                            const SizedBox(height: 16),
                            Text('No students found',
                                style: TextStyle(color: AppTheme.gray500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _students.length,
                          itemBuilder: (ctx, i) {
                            final s = _students[i];
                            return _StudentCard(
                              student: s,
                              onEdit: () => _showEditStudentModal(s),
                              onDeactivate: () => _confirmDeactivate(s),
                            );
                          },
                        ),
                      ),
          ),

          // Pagination
          if (!_loading && _students.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.gray200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _page > 1
                        ? () {
                            setState(() => _page--);
                            _fetchStudents();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                  ),
                  Text(
                    'Page $_page of $_totalPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _page < _totalPages
                        ? () {
                            setState(() => _page++);
                            _fetchStudents();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============ STUDENT CARD WIDGET ============

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary100,
              child: Text(
                student.firstName.isNotEmpty
                    ? student.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppTheme.primary700,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.gray900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: student.isActive
                              ? AppTheme.success500.withOpacity(0.1)
                              : AppTheme.error500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: student.isActive
                                ? AppTheme.success600
                                : AppTheme.error600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.registrationNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray500,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray400,
                    ),
                  ),
                  if (student.roomNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.room, size: 14, color: AppTheme.gray400),
                          const SizedBox(width: 4),
                          Text(
                            '${student.hostelName ?? ''} - Room ${student.roomNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.gray400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'deactivate') onDeactivate();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: AppTheme.primary600),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18, color: AppTheme.error500),
                      SizedBox(width: 8),
                      Text('Deactivate'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ STUDENT FORM MODAL ============

class _StudentFormModal extends StatefulWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final Map<String, String> data;
  final bool isEdit;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _StudentFormModal({
    required this.title,
    required this.formKey,
    required this.data,
    this.isEdit = false,
    required this.onSubmit,
  });

  @override
  State<_StudentFormModal> createState() => _StudentFormModalState();
}

class _StudentFormModalState extends State<_StudentFormModal> {
  late Map<String, String> _data;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: widget.formKey,
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  _buildField('Registration Number', 'registration_number',
                      required: true),
                  Row(
                    children: [
                      Expanded(
                          child: _buildField('First Name', 'first_name',
                              required: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildField('Last Name', 'last_name',
                              required: true)),
                    ],
                  ),
                  _buildField('Email', 'email',
                      required: true, type: TextInputType.emailAddress),
                  _buildField('Phone', 'phone', type: TextInputType.phone),
                  _buildDropdown('Gender', 'gender', [
                    'male',
                    'female',
                    'other',
                  ]),
                  _buildDatePicker('Date of Birth', 'date_of_birth'),
                  _buildField('Guardian Name', 'guardian_name'),
                  _buildField('Guardian Phone', 'guardian_phone',
                      type: TextInputType.phone),
                  _buildField('Address', 'address', maxLines: 2),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () async {
                                  if (widget.formKey.currentState!.validate()) {
                                    setState(() => _submitting = true);
                                    await widget.onSubmit(
                                      Map<String, dynamic>.from(_data)
                                        ..removeWhere(
                                            (k, v) => v.isEmpty),
                                    );
                                    if (mounted) {
                                      setState(() => _submitting = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _submitting
                                ? 'Saving...'
                                : (widget.isEdit
                                    ? 'Update Student'
                                    : 'Add Student'),
                          ),
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
    );
  }

  Widget _buildDatePicker(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          DateTime initial = DateTime(2002, 1, 1);
          if (_data[key] != null && _data[key]!.isNotEmpty) {
            final parsed = DateTime.tryParse(_data[key]!);
            if (parsed != null) initial = parsed;
          }
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(1990),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.primary600,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _data[key] =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            });
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: TextEditingController(text: _data[key]),
            decoration: InputDecoration(
              labelText: label,
              hintText: 'Select date',
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String key,
      {bool required = false,
      TextInputType? type,
      String? hint,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: _data[key],
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        validator: required
            ? (val) =>
                val == null || val.isEmpty ? '$label is required' : null
            : null,
        onChanged: (val) => _data[key] = val,
      ),
    );
  }

  Widget _buildDropdown(String label, String key, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _data[key]?.isNotEmpty == true ? _data[key] : options.first,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e[0].toUpperCase() + e.substring(1)),
                ))
            .toList(),
        onChanged: (val) {
          if (val != null) _data[key] = val;
        },
      ),
    );
  }
}
