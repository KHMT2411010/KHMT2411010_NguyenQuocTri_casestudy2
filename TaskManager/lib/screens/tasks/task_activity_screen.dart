import 'package:flutter/material.dart';

import '../../models/task_activity.dart';
import '../../services/task_activity_service.dart';

class TaskActivityScreen extends StatefulWidget {
  final String taskId;

  const TaskActivityScreen({super.key, required this.taskId});

  @override
  State<TaskActivityScreen> createState() => _TaskActivityScreenState();
}

class _TaskActivityScreenState extends State<TaskActivityScreen> {
  final TaskActivityService _service = const TaskActivityService();

  List<TaskActivity> activities = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await _service.getTaskActivities(widget.taskId);

      if (!mounted) return;

      setState(() {
        activities = result;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String actionTitle(String action) {
    switch (action) {
      case 'task_created':
        return 'Tạo công việc';
      case 'task_updated':
        return 'Chỉnh sửa công việc';
      case 'task_status_changed':
        return 'Thay đổi trạng thái';
      case 'task_deleted':
        return 'Xóa công việc';
      case 'assignee_added':
        return 'Giao công việc';
      case 'assignee_updated':
        return 'Cập nhật phân công';
      case 'assignee_removed':
        return 'Hủy phân công';
      case 'share_created':
        return 'Chia sẻ công việc';
      case 'share_updated':
        return 'Thay đổi quyền chia sẻ';
      case 'share_removed':
        return 'Thu hồi chia sẻ';
      default:
        return 'Hoạt động công việc';
    }
  }

  IconData actionIcon(String action) {
    switch (action) {
      case 'task_created':
        return Icons.add_task_rounded;
      case 'task_updated':
        return Icons.edit_note_rounded;
      case 'task_status_changed':
        return Icons.change_circle_outlined;
      case 'task_deleted':
        return Icons.delete_outline_rounded;
      case 'assignee_added':
        return Icons.person_add_alt_1_rounded;
      case 'assignee_updated':
        return Icons.manage_accounts_outlined;
      case 'assignee_removed':
        return Icons.person_remove_outlined;
      case 'share_created':
        return Icons.share_outlined;
      case 'share_updated':
        return Icons.admin_panel_settings_outlined;
      case 'share_removed':
        return Icons.link_off_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color actionColor(String action) {
    if (action == 'task_deleted' ||
        action == 'assignee_removed' ||
        action == 'share_removed') {
      return const Color(0xFFDC2626);
    }

    if (action == 'task_status_changed' || action == 'share_updated') {
      return const Color(0xFF0D9488);
    }

    return const Color(0xFF2563EB);
  }

  String formatDate(DateTime? value) {
    if (value == null) return 'Không rõ thời gian';

    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(local.hour)}:${two(local.minute)} '
        '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  String actorName(TaskActivity activity) {
    final name = activity.actorName?.trim();

    if (name != null && name.isNotEmpty) return name;

    final email = activity.actorEmail?.trim();

    if (email != null && email.isNotEmpty) return email;

    return 'Người dùng';
  }

  Widget activityCard(TaskActivity activity, bool isLast) {
    final color = actionColor(activity.action);
    final description = activity.description?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  actionIcon(activity.action),
                  color: color,
                  size: 22,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 94,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  color: const Color(0xFFE2E8F0),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionTitle(activity.action),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 17,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        actorName(activity),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDate(activity.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget centerMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF64748B)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: loadActivities,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      body = centerMessage(
        icon: Icons.error_outline_rounded,
        title: 'Không tải được lịch sử',
        message: errorMessage!,
      );
    } else if (activities.isEmpty) {
      body = centerMessage(
        icon: Icons.history_toggle_off_rounded,
        title: 'Chưa có lịch sử hoạt động',
        message: 'Các thay đổi của công việc sẽ được hiển thị tại đây.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: loadActivities,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return activityCard(
              activities[index],
              index == activities.length - 1,
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Lịch sử hoạt động',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới lịch sử',
            onPressed: loading ? null : loadActivities,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: body,
    );
  }
}
