import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;

  // Data from API
  List<Map<String, dynamic>> _categoryStats = [];
  List<Map<String, dynamic>> _hostelStats = [];
  Map<String, dynamic>? _resolutionOverall;
  List<Map<String, dynamic>> _resolutionByCategory = [];
  List<Map<String, dynamic>> _monthlyTrends = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getRaw('/api/analytics/categories'),
        _api.getRaw('/api/analytics/hostels'),
        _api.getRaw('/api/analytics/resolution'),
        _api.getRaw('/api/analytics/trends?months=6'),
      ]);

      final catData = results[0];
      final hostelData = results[1];
      final resData = results[2];
      final trendData = results[3];

      setState(() {
        if (catData['success'] == true && catData['data'] != null) {
          _categoryStats =
              List<Map<String, dynamic>>.from(catData['data'] as List);
        }

        if (hostelData['success'] == true && hostelData['data'] != null) {
          _hostelStats =
              List<Map<String, dynamic>>.from(hostelData['data'] as List);
        }

        if (resData['success'] == true && resData['data'] != null) {
          final data = resData['data'] as Map<String, dynamic>;
          _resolutionOverall = data['overall'] as Map<String, dynamic>?;
          if (data['by_category'] != null) {
            _resolutionByCategory =
                List<Map<String, dynamic>>.from(data['by_category'] as List);
          }
        }

        if (trendData['success'] == true && trendData['data'] != null) {
          _monthlyTrends =
              List<Map<String, dynamic>>.from(trendData['data'] as List);
        }

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatCategory(String cat) {
    return cat
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 2),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary600),
            )
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchAnalytics,
                  color: AppTheme.primary600,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Resolution Summary Stats
                        _buildResolutionSummary(),
                        const SizedBox(height: 24),

                        // Complaint Categories
                        _buildCategorySection(),
                        const SizedBox(height: 24),

                        // Hostel Occupancy & Complaints
                        _buildHostelSection(),
                        const SizedBox(height: 24),

                        // Monthly Trends
                        _buildMonthlyTrendsSection(),
                        const SizedBox(height: 24),

                        // Resolution by Category
                        _buildResolutionByCategorySection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error500),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gray500, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            'Live hostel statistics and insights',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionSummary() {
    final overall = _resolutionOverall;
    if (overall == null) {
      return const SizedBox.shrink();
    }

    final totalComplaints = (overall['total_complaints'] ?? 0);
    final resolvedComplaints = (overall['resolved_complaints'] ?? 0);
    final resolutionRate = (overall['resolution_rate'] ?? 0);
    final avgHours = overall['avg_resolution_hours'];
    final pendingComplaints = totalComplaints - resolvedComplaints;

    String avgResolutionText;
    if (avgHours != null && avgHours is num && avgHours > 0) {
      final days = (avgHours / 24).toStringAsFixed(1);
      avgResolutionText = '$days days';
    } else {
      avgResolutionText = 'N/A';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                avgResolutionText,
                Icons.timer,
                AppTheme.primary500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Resolution Rate',
                '$resolutionRate%',
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
                '$totalComplaints',
                Icons.report,
                AppTheme.warning500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Pending',
                '$pendingComplaints',
                Icons.pending_actions,
                AppTheme.error500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    if (_categoryStats.isEmpty) {
      return _buildEmptyCard('Complaints by Category', 'No complaint data available');
    }

    // Calculate total for percentage if not provided
    final total = _categoryStats.fold<int>(
      0,
      (sum, cat) => sum + ((cat['total_complaints'] ?? 0) as num).toInt(),
    );

    final categoryColors = [
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            children: _categoryStats.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final name = _formatCategory(cat['category'] ?? 'Unknown');
              final count = ((cat['total_complaints'] ?? 0) as num).toInt();
              final percentage = total > 0
                  ? (cat['percentage'] ?? (count / total * 100)).toDouble()
                  : 0.0;
              final color = categoryColors[idx % categoryColors.length];

              return Padding(
                padding: EdgeInsets.only(top: idx > 0 ? 12 : 0),
                child: _buildCategoryBar(name, percentage.round(), color,
                    count: count),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHostelSection() {
    if (_hostelStats.isEmpty) {
      return _buildEmptyCard('Hostel Statistics', 'No hostel data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hostel Statistics',
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
            children: _hostelStats.asMap().entries.map((entry) {
              final idx = entry.key;
              final hostel = entry.value;
              final name = hostel['hostel_name'] ?? 'Unknown';
              final totalComplaints =
                  ((hostel['total_complaints'] ?? 0) as num).toInt();
              final openComplaints =
                  ((hostel['open_complaints'] ?? 0) as num).toInt();
              final resolvedComplaints =
                  ((hostel['resolved_complaints'] ?? 0) as num).toInt();

              return Padding(
                padding: EdgeInsets.only(top: idx > 0 ? 16 : 0),
                child: _buildHostelRow(
                  name,
                  totalComplaints,
                  openComplaints,
                  resolvedComplaints,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendsSection() {
    if (_monthlyTrends.isEmpty) {
      return _buildEmptyCard('Monthly Trends', 'No trend data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trends',
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
              // Table header
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Month',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray700,
                          fontSize: 12,
                        )),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Complaints',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray700,
                          fontSize: 12,
                        )),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Resolution Rate',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray700,
                          fontSize: 12,
                        )),
                  ),
                ],
              ),
              const Divider(height: 20),
              ..._monthlyTrends.map((trend) {
                final monthStr = trend['month'] ?? '';
                String displayMonth = monthStr;
                try {
                  final date = DateTime.parse(monthStr);
                  final months = [
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];
                  displayMonth = '${months[date.month - 1]} ${date.year}';
                } catch (_) {}

                final totalComplaints =
                    ((trend['total_complaints'] ?? 0) as num).toInt();
                final resRate =
                    ((trend['resolution_rate'] ?? 0) as num).toDouble();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          displayMonth,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$totalComplaints',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: resRate >= 70
                                    ? AppTheme.success500.withOpacity(0.1)
                                    : resRate >= 40
                                        ? AppTheme.warning500.withOpacity(0.1)
                                        : AppTheme.error500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${resRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: resRate >= 70
                                      ? AppTheme.success600
                                      : resRate >= 40
                                          ? AppTheme.warning600
                                          : AppTheme.error600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionByCategorySection() {
    if (_resolutionByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avg Resolution Time by Category',
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
            children: _resolutionByCategory.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final category =
                  _formatCategory(item['category'] ?? 'Unknown');
              final avgHours = item['avg_resolution_hours'];
              final resolvedCount =
                  ((item['resolved_count'] ?? 0) as num).toInt();

              String timeText;
              if (avgHours != null && avgHours is num && avgHours > 0) {
                if (avgHours >= 24) {
                  timeText = '${(avgHours / 24).toStringAsFixed(1)} days';
                } else {
                  timeText = '${avgHours.toStringAsFixed(1)} hrs';
                }
              } else {
                timeText = 'N/A';
              }

              return Padding(
                padding: EdgeInsets.only(top: idx > 0 ? 12 : 0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        timeText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$resolvedCount resolved',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppTheme.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============ Reusable Widgets ============

  Widget _buildEmptyCard(String title, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.gray800,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 40, color: AppTheme.gray400),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: AppTheme.gray500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar(String label, int percentage, Color color,
      {int? count}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            if (count != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray500,
                    fontSize: 12,
                  ),
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
            widthFactor: (percentage / 100).clamp(0.0, 1.0),
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

  Widget _buildHostelRow(
    String hostel,
    int totalComplaints,
    int openComplaints,
    int resolvedComplaints,
  ) {
    final resolvedRate = totalComplaints > 0
        ? (resolvedComplaints / totalComplaints * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hostel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
            ),
            Text(
              '$totalComplaints total',
              style: const TextStyle(
                color: AppTheme.gray500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Stacked bar: resolved + open
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: totalComplaints > 0
              ? Row(
                  children: [
                    Flexible(
                      flex: resolvedComplaints,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.success500,
                          borderRadius: BorderRadius.horizontal(
                            left: const Radius.circular(5),
                            right: openComplaints == 0
                                ? const Radius.circular(5)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                    if (openComplaints > 0)
                      Flexible(
                        flex: openComplaints,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.warning500,
                            borderRadius: BorderRadius.horizontal(
                              left: resolvedComplaints == 0
                                  ? const Radius.circular(5)
                                  : Radius.zero,
                              right: const Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    // Remaining space (if any) to represent proportion
                    if (totalComplaints > 0 &&
                        (resolvedComplaints + openComplaints) < totalComplaints)
                      Flexible(
                        flex: totalComplaints -
                            resolvedComplaints -
                            openComplaints,
                        child: const SizedBox(),
                      ),
                  ],
                )
              : const SizedBox(),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildLegendDot(AppTheme.success500, 'Resolved: $resolvedComplaints'),
            const SizedBox(width: 16),
            _buildLegendDot(AppTheme.warning500, 'Open: $openComplaints'),
            const Spacer(),
            Text(
              '$resolvedRate% resolved',
              style: TextStyle(
                color: resolvedRate >= 70
                    ? AppTheme.success600
                    : resolvedRate >= 40
                        ? AppTheme.warning600
                        : AppTheme.error600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.gray500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
