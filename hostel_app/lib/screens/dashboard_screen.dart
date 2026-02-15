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

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _bottomNavIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadStudents();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
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

  void _onBottomNavTap(int index, Student student) {
    if (index == 0) return; // Already on Home
    Widget screen;
    switch (index) {
      case 1:
        screen = RoomScreen(studentId: student.id);
        break;
      case 2:
        screen = PaymentsScreen(studentId: student.id);
        break;
      case 3:
        screen = ComplaintsScreen(studentId: student.id);
        break;
      case 4:
        screen = ProfileScreen(studentId: student.id);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      setState(() => _bottomNavIndex = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.navbarGradient),
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
                  const Icon(Icons.error_outline,
                      size: 64, color: AppTheme.gray400),
                  const SizedBox(height: 16),
                  Text('Failed to load data',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(provider.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
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

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.selectStudent(student.id),
                  color: AppTheme.primary600,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student Selector
                          if (provider.students.isNotEmpty)
                            _buildStudentSelector(student, provider),

                          // Payment Due Alert Banner
                          if (student.totalPending > 0)
                            _buildPaymentAlert(student, currencyFormat),

                          // Welcome Header
                          _buildWelcomeHeader(student, dateFormat),
                          const SizedBox(height: 24),

                          // Quick Stats
                          _buildStatsRow(student, currencyFormat),
                          const SizedBox(height: 32),

                          // Quick Actions
                          _buildSectionTitle('Quick Actions', Icons.bolt),
                          const SizedBox(height: 16),
                          _buildQuickActionsGrid(student),
                          const SizedBox(height: 32),

                          // Room Information
                          _buildRoomInfoCard(student),
                          const SizedBox(height: 20),

                          // Payment Summary
                          _buildPaymentSummaryCard(student, currencyFormat),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Navigation
              _buildBottomNav(student),
            ],
          );
        },
      ),
    );
  }

  // ===== STUDENT SELECTOR =====
  Widget _buildStudentSelector(Student student, StudentProvider provider) {
    return GestureDetector(
      onTap: () => _showStudentSelector(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  student.firstName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Viewing as: ',
                style: TextStyle(
                    color: Color(0xFF78350F), fontWeight: FontWeight.w500)),
            Expanded(
              child: Text(
                student.fullName,
                style: const TextStyle(
                    color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.unfold_more, color: Color(0xFFD97706), size: 20),
          ],
        ),
      ),
    );
  }

  // ===== PAYMENT ALERT BANNER =====
  Widget _buildPaymentAlert(Student student, NumberFormat fmt) {
    final isOverdue = student.totalPending > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverdue
              ? [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]
              : [const Color(0xFFFEF9C3), const Color(0xFFFEF08A)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFFDE047),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverdue
                  ? const Color(0xFFDC2626).withOpacity(0.1)
                  : const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOverdue ? Icons.warning_rounded : Icons.info_outline,
              color:
                  isOverdue ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Due',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isOverdue
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmt.format(student.totalPending)} pending',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentsScreen(studentId: student.id),
                ),
              ),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('View',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== WELCOME HEADER =====
  Widget _buildWelcomeHeader(Student student, DateFormat dateFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dateFormat.format(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()} ${_getGreetingEmoji()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.firstName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            student.registrationNumber,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Room badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.meeting_room_rounded,
                        color: Colors.white.withOpacity(0.6), size: 20),
                    const SizedBox(height: 6),
                    if (student.roomNumber != null) ...[
                      Text(
                        student.roomNumber!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        student.hostelName ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ] else
                      Text(
                        'No room',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== STATS ROW =====
  Widget _buildStatsRow(Student student, NumberFormat currencyFormat) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: currencyFormat.format(student.totalPaid),
            label: 'Total Paid',
            icon: Icons.check_circle_rounded,
            gradient: const [Color(0xFF059669), Color(0xFF10B981)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: currencyFormat.format(student.totalPending),
            label: 'Pending',
            icon: Icons.schedule_rounded,
            gradient: student.totalPending > 0
                ? const [Color(0xFFDC2626), Color(0xFFEF4444)]
                : const [Color(0xFF9CA3AF), Color(0xFFD1D5DB)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: student.activeComplaints.toString(),
            label: 'Complaints',
            icon: Icons.report_problem_rounded,
            gradient: student.activeComplaints > 0
                ? const [Color(0xFFD97706), Color(0xFFF59E0B)]
                : const [Color(0xFF9CA3AF), Color(0xFFD1D5DB)],
          ),
        ),
      ],
    );
  }

  // ===== SECTION TITLE =====
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.gray800,
          ),
        ),
      ],
    );
  }

  // ===== QUICK ACTIONS GRID =====
  Widget _buildQuickActionsGrid(Student student) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.55,
      children: [
        _QuickActionCard(
          icon: Icons.person_rounded,
          title: 'My Profile',
          subtitle: 'View & edit details',
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          bgColor: const Color(0xFFEFF6FF),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ProfileScreen(studentId: student.id))),
        ),
        _QuickActionCard(
          icon: Icons.meeting_room_rounded,
          title: 'Room Details',
          subtitle: 'Room & roommates',
          gradientColors: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          bgColor: const Color(0xFFFAF5FF),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => RoomScreen(studentId: student.id))),
        ),
        _QuickActionCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Payments',
          subtitle: 'Fee history & dues',
          gradientColors: const [Color(0xFF059669), Color(0xFF34D399)],
          bgColor: const Color(0xFFF0FDF4),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PaymentsScreen(studentId: student.id))),
        ),
        _QuickActionCard(
          icon: Icons.build_rounded,
          title: 'Complaints',
          subtitle: 'Raise & track issues',
          gradientColors: const [Color(0xFFD97706), Color(0xFFFBBF24)],
          bgColor: const Color(0xFFFFFBEB),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ComplaintsScreen(studentId: student.id))),
        ),
      ],
    );
  }

  // ===== ROOM INFO CARD =====
  Widget _buildRoomInfoCard(Student student) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.08),
                  const Color(0xFF7C3AED).withOpacity(0.03),
                ],
              ),
              border: const Border(
                  bottom: BorderSide(color: AppTheme.gray100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.meeting_room_rounded,
                      color: Color(0xFF7C3AED), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Room Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Body
          student.roomNumber != null
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _buildInfoRow(
                          Icons.tag, 'Room Number', student.roomNumber!),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: AppTheme.gray100),
                      ),
                      _buildInfoRow(Icons.apartment, 'Hostel',
                          student.hostelName ?? 'N/A'),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.meeting_room_outlined,
                          size: 48, color: AppTheme.gray300),
                      const SizedBox(height: 12),
                      const Text(
                        'No room allocated yet',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray400,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Contact the hostel office for allocation.',
                        style:
                            TextStyle(color: AppTheme.gray400, fontSize: 13),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // ===== PAYMENT SUMMARY CARD =====
  Widget _buildPaymentSummaryCard(Student student, NumberFormat fmt) {
    final total = student.totalPaid + student.totalPending;
    final paidPercent = total > 0 ? student.totalPaid / total : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF059669).withOpacity(0.08),
                  const Color(0xFF059669).withOpacity(0.03),
                ],
              ),
              border: const Border(
                  bottom: BorderSide(color: AppTheme.gray100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF059669),
                      size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(paidPercent * 100).toStringAsFixed(0)}% paid',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray600,
                          ),
                        ),
                        Text(
                          fmt.format(total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 10,
                        child: LinearProgressIndicator(
                          value: paidPercent,
                          backgroundColor: const Color(0xFFFEE2E2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF059669)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Amounts
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF059669), size: 22),
                            const SizedBox(height: 6),
                            Text(
                              fmt.format(student.totalPaid),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('Paid',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.gray500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: student.totalPending > 0
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              student.totalPending > 0
                                  ? Icons.schedule_rounded
                                  : Icons.check_circle_outline,
                              color: student.totalPending > 0
                                  ? const Color(0xFFDC2626)
                                  : AppTheme.gray400,
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              fmt.format(student.totalPending),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: student.totalPending > 0
                                    ? const Color(0xFFDC2626)
                                    : AppTheme.gray400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('Pending',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.gray500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== INFO ROW =====
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.gray400),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: AppTheme.gray500, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.gray900,
          ),
        ),
      ],
    );
  }

  // ===== BOTTOM NAV =====
  Widget _buildBottomNav(Student student) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0, student),
              _buildNavItem(
                  Icons.meeting_room_rounded, 'Room', 1, student),
              _buildNavItem(
                  Icons.account_balance_wallet_rounded, 'Payments', 2, student),
              _buildNavItem(Icons.build_rounded, 'Complaints', 3, student),
              _buildNavItem(Icons.person_rounded, 'Profile', 4, student),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, Student student) {
    final isActive = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _bottomNavIndex = index);
        _onBottomNavTap(index, student);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary600.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.primary600 : AppTheme.gray400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary600 : AppTheme.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== STAT CARD =====
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray100),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: gradient[0],
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== QUICK ACTION CARD =====
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              // Gradient icon circle
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.gray400),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTheme.gray300),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ STUDENT SELECTOR MODAL ============
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
                      final isSelected =
                          student.id == widget.currentStudentId;

                      return InkWell(
                        onTap: () => widget.onSelect(student.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFFBEB)
                                : null,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
