import 'package:flutter/material.dart';

import '../../services/statistics_service.dart';
import 'deadline_section.dart';
import '../../utils/constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _service = const StatisticsService();

  late Future<TaskStatistics> _future;
  int _deadlineRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _future = _service.load();
  }

  void _refresh() {
    setState(() {
      _future = _service.load();
      _deadlineRefreshVersion++;
    });
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 14),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(TaskStatistics stats) {
    final rate = stats.completionRate.clamp(0.0, 1.0);
    final percent = (rate * 100).toStringAsFixed(1);

    return Card(
      color: AppColors.navy,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_rounded, color: Colors.white, size: 23),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tiến độ hoàn thành',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${stats.completed}/${stats.total} công việc đã hoàn thành',
              style: const TextStyle(color: Color(0xFFD7E5F5), fontSize: 13),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 11,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF57D9A3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(TaskStatistics stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = (constraints.maxWidth - 32).clamp(0.0, 1000.0);

        final columns = availableWidth >= 760
            ? 3
            : availableWidth >= 300
            ? 2
            : 1;

        const gap = 12.0;

        final cardWidth = (availableWidth - (columns - 1) * gap) / columns;

        Widget buildCard({
          required String label,
          required int value,
          required IconData icon,
          required Color color,
        }) {
          return SizedBox(
            width: cardWidth,
            child: _statCard(
              label: label,
              value: value,
              icon: icon,
              color: color,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tổng quan hiệu suất',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Theo dõi công việc, tiến độ và các nhiệm vụ cần chú ý.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  _progressCard(stats),

                  const SizedBox(height: 26),

                  _sectionHeading(
                    'Tổng quan công việc',
                    'Tình trạng hiện tại của các công việc.',
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      buildCard(
                        label: 'Tổng công việc',
                        value: stats.total,
                        icon: Icons.assignment_outlined,
                        color: Colors.blue,
                      ),
                      buildCard(
                        label: 'Hoàn thành',
                        value: stats.completed,
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      buildCard(
                        label: 'Đang thực hiện',
                        value: stats.inProgress,
                        icon: Icons.pending_actions_outlined,
                        color: Colors.orange,
                      ),
                      buildCard(
                        label: 'Chưa bắt đầu',
                        value: stats.pending,
                        icon: Icons.schedule_outlined,
                        color: Colors.blueGrey,
                      ),
                      buildCard(
                        label: 'Quá hạn',
                        value: stats.overdue,
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      buildCard(
                        label: 'Ưu tiên cao',
                        value: stats.highPriority,
                        icon: Icons.priority_high_rounded,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  _sectionHeading(
                    'Thống kê phân công',
                    'Công việc đã tạo, đã giao và đang phụ trách.',
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      buildCard(
                        label: 'Công việc đã tạo',
                        value: stats.created,
                        icon: Icons.note_add_outlined,
                        color: Colors.blue,
                      ),
                      buildCard(
                        label: 'Công việc đã giao',
                        value: stats.delegated,
                        icon: Icons.outbox_outlined,
                        color: Colors.teal,
                      ),
                      buildCard(
                        label: 'Đang phụ trách',
                        value: stats.assigned,
                        icon: Icons.person_outline_rounded,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  _sectionHeading(
                    'Theo dõi thời hạn',
                    'Các công việc sắp đến hạn và đã quá hạn.',
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DeadlineSection(
                        key: ValueKey(_deadlineRefreshVersion),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê công việc'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        actions: [
          IconButton(
            tooltip: 'Làm mới thống kê',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<TaskStatistics>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text('Không thể tải dữ liệu thống kê.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildStatistics(snapshot.data!);
        },
      ),
    );
  }
}
