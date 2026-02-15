import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.navbarGradient,
          ),
        ),
        title: const Text('Analytics'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View hostel statistics and insights',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Complaint Categories
            Text(
              'Complaints by Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gray800,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                children: [
                  _buildCategoryBar('Electrical', 35, const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  _buildCategoryBar('Plumbing', 28, const Color(0xFF3B82F6)),
                  const SizedBox(height: 12),
                  _buildCategoryBar('Furniture', 18, const Color(0xFF8B5CF6)),
                  const SizedBox(height: 12),
                  _buildCategoryBar('Cleaning', 12, const Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  _buildCategoryBar('Internet', 7, const Color(0xFFEC4899)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Resolution Stats
            Text(
              'Resolution Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gray800,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Avg Resolution',
                    '2.3 days',
                    Icons.timer,
                    AppTheme.primary500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Resolution Rate',
                    '87%',
                    Icons.check_circle,
                    AppTheme.success500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Total Complaints',
                    '156',
                    Icons.report,
                    AppTheme.warning500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Pending',
                    '21',
                    Icons.pending_actions,
                    AppTheme.error500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hostel Occupancy
            Text(
              'Hostel Occupancy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gray800,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                children: [
                  _buildOccupancyRow('Block A', 45, 50),
                  const SizedBox(height: 16),
                  _buildOccupancyRow('Block B', 38, 50),
                  const SizedBox(height: 16),
                  _buildOccupancyRow('Block C', 42, 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.gray700,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
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
      ),
    );
  }

  Widget _buildOccupancyRow(String hostel, int occupied, int total) {
    final percentage = (occupied / total * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hostel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              '$occupied / $total ($percentage%)',
              style: const TextStyle(
                color: AppTheme.gray500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: occupied / total,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary500,
                    percentage > 80 ? AppTheme.warning500 : AppTheme.primary400,
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
