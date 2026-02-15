import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'profile_screen.dart';
import 'room_screen.dart';
import 'payments_screen.dart';
import 'complaints_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadStudents();
    });
  }

  void _showStudentSelector(BuildContext context, StudentProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentSelectorModal(
        students: provider.students,
        currentStudentId: provider.selectedStudent?.id,
        onSelect: (id) {
          provider.selectStudent(id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NumberFormat needs the intl package. Ensure it is added to pubspec.yaml
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.navbarGradient,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Text('🏠 ', style: TextStyle(fontSize: 24)),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFC4B5FD), Color(0xFFF0ABFC)],
              ).createShader(bounds),
              child: const Text(
                'HostelMS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x33FFC107),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x4DFFC107)),
            ),
            child: const Text(
              'Demo Mode',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 0),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedStudent == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary600),
            );
          }

          if (provider.error != null && provider.selectedStudent == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.gray400),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadStudents(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final student = provider.selectedStudent;
          if (student == null) {
            return const Center(child: Text('No student data available'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.selectStudent(student.id),
            color: AppTheme.primary600,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Selector
                  if (provider.students.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showStudentSelector(context, provider),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB), // amber-50
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
                        ),
                        child: Row(
                          children: [
                            const Text('👤 ', style: TextStyle(fontSize: 18)),
                            const Text(
                              'Viewing as: ',
                              style: TextStyle(
                                color: Color(0xFF78350F), // amber-900
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFCD34D)), // amber-300
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student.fullName,
                                        style: const TextStyle(
                                          color: Color(0xFF78350F), // amber-900
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Color(0xFF78350F)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Welcome Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary500.withValues(alpha: 0.2), // shadow-indigo-500/20 approximately
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back, ${student.firstName}!',
                                    style: const TextStyle(
                                      fontSize: 30, // 3xl
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${student.registrationNumber} • ${student.email}',
                                    style: TextStyle(
                                      color: Colors.blue.shade100, // text-blue-100
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (student.roomNumber != null) ...[
                                    Text(
                                      student.roomNumber!,
                                      style: const TextStyle(
                                        fontSize: 30, // 3xl
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      student.hostelName ?? '',
                                      style: TextStyle(
                                        color: Colors.indigo.shade100, // text-indigo-100
                                        fontSize: 14, // text-sm
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      'No room assigned',
                                      style: TextStyle(
                                        color: Colors.indigo.shade100,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          currencyFormat.format(student.totalPaid),
                          'Total Paid',
                          AppTheme.success600, // text-green-600
                          Colors.green, // bg-green-500
                          isZeroGray: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          currencyFormat.format(student.totalPending),
                          'Pending Amount',
                          student.totalPending > 0
                              ? AppTheme.error600 // text-red-600
                              : AppTheme.gray900, // text-gray-900
                          student.totalPending > 0
                              ? Colors.red // bg-red-500
                              : Colors.grey.shade300, // bg-gray-200
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          student.activeComplaints.toString(),
                          'Active Complaints',
                          student.activeComplaints > 0
                              ? AppTheme.warning600 // text-amber-600
                              : AppTheme.gray900, // text-gray-900
                          student.activeComplaints > 0
                              ? Colors.amber // bg-amber-500
                              : Colors.grey.shade300, // bg-gray-200
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.w600, // font-semibold
                      color: AppTheme.gray800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16, // gap-4
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                    children: [
                      _buildQuickAction(
                        context,
                        icon: '👤',
                        title: 'My Profile',
                        subtitle: 'View & edit your details',
                        bgColor: const Color(0xFFEFF6FF), // blue-50
                        borderColor: Colors.blue.shade100,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(studentId: student.id),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        icon: '🏠',
                        title: 'Room Details',
                        subtitle: 'View room & roommates',
                        bgColor: const Color(0xFFFAF5FF), // purple-50
                        borderColor: Colors.purple.shade100,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomScreen(studentId: student.id),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        icon: '💳',
                        title: 'Payments',
                        subtitle: 'View fee history & dues',
                        bgColor: const Color(0xFFF0FDF4), // green-50
                        borderColor: Colors.green.shade100,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentsScreen(studentId: student.id),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        icon: '🔧',
                        title: 'Complaints',
                        subtitle: 'Raise & track issues',
                        bgColor: const Color(0xFFFFFBEB), // amber-50
                        borderColor: Colors.amber.shade100,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComplaintsScreen(studentId: student.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Information Cards
                  _buildInfoCard(
                        '🏠',
                        'Room Information',
                        student.roomNumber != null
                            ? Column(
                                children: [
                                  _buildInfoRow('Room Number', student.roomNumber!),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1, color: AppTheme.gray100),
                                  ),
                                  _buildInfoRow('Hostel', student.hostelName ?? 'N/A'),
                                ],
                              )
                            : const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No room allocated yet.\nPlease contact the hostel office.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.gray500),
                                  ),
                                ),
                              ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(
                        '💰',
                        'Payment Summary',
                        Column(
                          children: [
                            _buildInfoRow(
                              'Total Paid',
                              currencyFormat.format(student.totalPaid),
                              valueColor: AppTheme.success600,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: AppTheme.gray100),
                            ),
                            _buildInfoRow(
                              'Pending',
                              currencyFormat.format(student.totalPending),
                              valueColor: student.totalPending > 0
                                  ? AppTheme.error600
                                  : AppTheme.success600,
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color textColor, Color barColor, {bool isZeroGray = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20, // text-2xl is usually 24, but Next.js card is tight. 20 fits better on mobile row of 3.
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12, // text-sm
                    fontWeight: FontWeight.w500,
                    color: isZeroGray && textColor == AppTheme.gray900 ? AppTheme.gray500 : textColor,
                  ),
                ),
              ],
            ),
          ),
          // Left bar
          Positioned(
            left: 0,
            top: 0, 
            bottom: 0,
            child: Container(
              width: 4,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
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
      ),
    );
  }

  Widget _buildInfoCard(String icon, String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB), // bg-gray-50/50
              border: Border(
                bottom: BorderSide(color: AppTheme.gray100),
              ),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.gray500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: valueColor ?? AppTheme.gray900,
          ),
        ),
      ],
    );
  }
}

class _StudentSelectorModal extends StatefulWidget {
  final List<Student> students;
  final int? currentStudentId;
  final ValueChanged<int> onSelect;

  const _StudentSelectorModal({
    required this.students,
    required this.currentStudentId,
    required this.onSelect,
  });

  @override
  State<_StudentSelectorModal> createState() => _StudentSelectorModalState();
}

class _StudentSelectorModalState extends State<_StudentSelectorModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<Student> _filteredStudents;

  @override
  void initState() {
    super.initState();
    _filteredStudents = widget.students;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = widget.students;
      } else {
        _filteredStudents = widget.students.where((s) {
          final q = query.toLowerCase();
          return s.fullName.toLowerCase().contains(q) ||
              s.registrationNumber.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const Text(
            'Select Student',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Search by name or reg no.',
              prefixIcon: const Icon(Icons.search, color: AppTheme.gray400),
              filled: true,
              fillColor: AppTheme.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 48, color: AppTheme.gray300),
                        const SizedBox(height: 8),
                        Text(
                          'No students found',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isSelected = student.id == widget.currentStudentId;

                      return InkWell(
                        onTap: () => widget.onSelect(student.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFFBEB) : null,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: const Color(0xFFFDE68A))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFEF3C7)
                                      : AppTheme.gray100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    student.firstName.substring(0, 1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFFD97706)
                                          : AppTheme.gray600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF92400E)
                                            : AppTheme.gray900,
                                      ),
                                    ),
                                    Text(
                                      student.registrationNumber,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? const Color(0xFFB45309)
                                            : AppTheme.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFFF59E0B)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
