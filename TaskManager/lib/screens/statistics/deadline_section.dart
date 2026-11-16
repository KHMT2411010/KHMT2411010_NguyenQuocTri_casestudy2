import 'package:flutter/material.dart';

import '../../services/deadline_service.dart';
import '../../utils/constants.dart';
import '../tasks/task_detail_screen.dart';

class DeadlineSection extends StatefulWidget {
  const DeadlineSection({super.key});

  @override
  State<DeadlineSection> createState() => _DeadlineSectionState();
}

class _DeadlineSectionState extends State<DeadlineSection> {
  final DeadlineService _service = const DeadlineService();

  late Future<DeadlineSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.load();
  }

  void _reload() {
    setState(() {
      _future = _service.load();
    });
  }

  String _formatDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();

    if (date == null) {
      return 'Không có thời hạn';
    }

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String _statusLabel(dynamic raw) {
    switch (raw?.toString()) {
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Chưa bắt đầu';
    }
  }

  Widget _taskTile(
    BuildContext context,
    Map<String, dynamic> task, {
    required bool isOverdue,
  }) {
    final taskId = (task['_id'] ?? task['id'] ?? '').toString();
    final title = (task['title'] ?? 'Công việc').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? const Color(0xFFFFE5E5)
              : const Color(0xFFFFF1D6),
          child: Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
            color: isOverdue ? Colors.red : Colors.orange,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Hạn: ${_formatDate(task['dueDate'])}\n'
            'Trạng thái: ${_statusLabel(task['status'])}',
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: taskId.isEmpty
            ? null
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TaskDetailScreen(taskId: taskId),
                  ),
                );

                if (mounted) {
                  _reload();
                }
              },
      ),
    );
  }

  Widget _group(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> tasks,
    required bool isOverdue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isOverdue
                  ? Icons.error_outline_rounded
                  : Icons.access_time_rounded,
              color: isOverdue ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            Text(
              '${tasks.length} công việc',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Không có công việc nào trong nhóm này.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...tasks.map(
            (task) => _taskTile(context, task, isOverdue: isOverdue),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeadlineSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              const Text('Không thể tải danh sách thời hạn.'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          );
        }

        final data = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _group(
              context,
              title: 'Công việc sắp đến hạn (24 giờ)',
              tasks: data.upcoming,
              isOverdue: false,
            ),
            const SizedBox(height: 22),
            _group(
              context,
              title: 'Công việc đã quá hạn',
              tasks: data.overdue,
              isOverdue: true,
            ),
          ],
        );
      },
    );
  }
}
