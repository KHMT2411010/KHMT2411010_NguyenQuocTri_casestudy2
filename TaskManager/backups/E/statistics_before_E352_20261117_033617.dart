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

  Widget _statCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 15),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(TaskStatistics stats) {
    final percent = (stats.completionRate * 100).toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 650
            ? (constraints.maxWidth - 24) / 3
            : (constraints.maxWidth - 12) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng quan công việc',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Theo dõi tiến độ và tình trạng công việc.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'Tổng công việc',
                          value: stats.total,
                          icon: Icons.assignment_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'Hoàn thành',
                          value: stats.completed,
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'Đang thực hiện',
                          value: stats.inProgress,
                          icon: Icons.pending_actions_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'Chưa bắt đầu',
                          value: stats.pending,
                          icon: Icons.schedule_outlined,
                          color: Colors.blueGrey,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'Quá hạn',
                          value: stats.overdue,
                          icon: Icons.warning_amber_rounded,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'Ưu tiên cao',
                          value: stats.highPriority,
                          icon: Icons.priority_high_rounded,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Th\u1ed1ng k\u00ea ph\u00e2n c\u00f4ng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'C\u00f4ng vi\u1ec7c \u0111\u00e3 t\u1ea1o',
                          value: stats.created,
                          icon: Icons.note_add_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'C\u00f4ng vi\u1ec7c \u0111\u00e3 giao',
                          value: stats.delegated,
                          icon: Icons.outbox_outlined,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          label: 'C\u00f4ng vi\u1ec7c \u0111ang ph\u1ee5 tr\u00e1ch',
                          value: stats.assigned,
                          icon: Icons.person_outline_rounded,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DeadlineSection(key: ValueKey(_deadlineRefreshVersion)),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tiến độ hoàn thành',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 15),
                          LinearProgressIndicator(
                            value: stats.completionRate,
                            minHeight: 11,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${stats.completed}/${stats.total} công việc ($percent%)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
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
