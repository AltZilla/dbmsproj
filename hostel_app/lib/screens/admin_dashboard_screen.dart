import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import 'admin/admin_students_screen.dart';
import 'admin/admin_rooms_screen.dart';
import 'admin/admin_complaints_screen.dart';
import 'admin/admin_payments_screen.dart';
import 'admin/admin_allocations_screen.dart';
import 'admin/admin_hostels_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);
    try {
      _stats = await _api.getDashboardStats();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.navbarGradient),
        ),
        title: const Text('Admin Portal'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage hostel operations and view system overview',
                style: TextStyle(color: AppTheme.gray500, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Stats
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    value: _loading
                        ? '...'
                        : '${_stats['totalStudents'] ?? 0}',
                    label: 'Total Students',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    ),
                    icon: Icons.people,
                  ),
                  _StatCard(
                    value: _loading
                        ? '...'
                        : '${_stats['totalRooms'] ?? 0}',
                    label: 'Total Rooms',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                    ),
                    icon: Icons.hotel,
                  ),
                  _StatCard(
                    value: _loading
                        ? '...'
                        : '${_stats['openComplaints'] ?? 0}',
                    label: 'Open Complaints',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                    ),
                    icon: Icons.warning_amber_rounded,
                  ),
                  _StatCard(
                    value: _loading
                        ? '...'
                        : '${_stats['pendingPayments'] ?? 0}',
                    label: 'Pending Payments',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
                    ),
                    icon: Icons.credit_card,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.gray800,
                    ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                emoji: '👥',
                title: 'Students',
                subtitle: 'Add and manage students',
                onTap: () => _navigateTo(const AdminStudentsScreen()),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '🏠',
                title: 'Rooms',
                subtitle: 'Manage rooms & assignments',
                onTap: () => _navigateTo(const AdminRoomsScreen()),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '🔑',
                title: 'Allocations',
                subtitle: 'View allocation history',
                onTap: () => _navigateTo(const AdminAllocationsScreen()),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '🔧',
                title: 'Complaints',
                subtitle: 'Maintenance requests',
                onTap: () => _navigateTo(const AdminComplaintsScreen()),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '💳',
                title: 'Payments',
                subtitle: 'Fee tracking & records',
                onTap: () => _navigateTo(const AdminPaymentsScreen()),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '🏢',
                title: 'Hostels',
                subtitle: 'Manage hostel blocks',
                onTap: () => _navigateTo(const AdminHostelsScreen()),
              ),
              const SizedBox(height: 32),

              // DB Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🗄️ Database Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF312E81),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This system uses PostgreSQL with normalized tables, triggers, and SQL views for analytics.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.gray600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '8 Tables',
                        '4 Triggers',
                        '9 Views',
                        '15+ APIs',
                      ]
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFC7D2FE)),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final LinearGradient gradient;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.gray900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
