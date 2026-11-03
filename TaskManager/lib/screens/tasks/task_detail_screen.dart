import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = const TaskService();

  Map<String, dynamic>? task;
  String? myId;
  bool loading = true;
  bool changingStatus = false;
  bool deleting = false;
  String? errorMessage;

  bool get isOwner {
    final creator = task?['createdBy'];
    final creatorId = _extractId(creator);
    return myId != null && creatorId == myId;
  }

  String _extractId(dynamic value) {
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }
    return value?.toString() ?? '';
  }

  String _personName(dynamic value) {
    if (value is Map) {
      final name = value['fullName']?.toString().trim();
      final email = value['email']?.toString().trim();

      if (name != null && name.isNotEmpty) return name;
      if (email != null && email.isNotEmpty) return email;
      return 'Người dùng';
    }

    if (value == null) return 'Chưa phân công';

    final id = value.toString();
    return id.isEmpty ? 'Chưa phân công' : 'Thành viên';
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final me = await ApiClient.get('/api/auth/me');
      final result = await _taskService.getTaskById(widget.taskId);

      if (!mounted) return;

      final rawUser = me['data'];

      setState(() {
        myId = _extractId(rawUser);
        task = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> changeStatus(String status) async {
    if (changingStatus) return;

    setState(() => changingStatus = true);

    try {
      await _taskService.updateStatus(widget.taskId, status);

      await loadDetail();

      _showMessage('Cập nhật trạng thái thành công');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() => changingStatus = false);
      }
    }
  }

  Future<void> editTask() async {
    final current = task;
    if (current == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: current)),
    );

    if (changed == true && mounted) {
      await loadDetail();
    }
  }

  Future<void> deleteTask() async {
    if (!isOwner || deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa công việc?'),
        content: const Text(
          'Công việc sẽ bị xóa khỏi hệ thống. '
          'Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa công việc'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => deleting = true);

    try {
      await _taskService.deleteTask(widget.taskId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  // Hai route này được đăng ký khi hoàn thiện app.dart.
  Future<void> openAssignment() async {
    await Navigator.pushNamed(context, '/assignment', arguments: widget.taskId);

    if (mounted) await loadDetail();
  }

  Future<void> openSharing() async {
    await Navigator.pushNamed(context, '/sharing', arguments: widget.taskId);

    if (mounted) await loadDetail();
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080E214A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    final buttonStyle = primary
        ? FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 17),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 17),
          );

    if (primary) {
      return FilledButton.icon(
        style: buttonStyle,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
      );
    }

    return OutlinedButton.icon(
      style: buttonStyle,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 45,
            ),
            const SizedBox(height: 13),
            Text(
              errorMessage ?? 'Không tìm thấy công việc',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.navy),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: loadDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = task;
    final status = data?['status']?.toString() ?? 'todo';

    final assignees = data?['assigneeIds'] is List
        ? data!['assigneeIds'] as List
        : <dynamic>[];

    final description = data?['description']?.toString().trim() ?? '';

    final primary = data?['primaryAssigneeId'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loading ? null : loadDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const LoadingView(message: 'Đang tải thông tin công việc...')
          : errorMessage != null || data == null
          ? _errorView()
          : LayoutBuilder(
              builder: (context, viewport) {
                final compact = viewport.maxWidth < 600;

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : 24,
                    18,
                    compact ? 14 : 24,
                    38,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(23),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.assignment_turned_in_outlined,
                                    size: 34,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    data['title']?.toString() ?? 'Công việc',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 9,
                                    runSpacing: 9,
                                    children: [
                                      StatusBadge(status: status),
                                      PriorityBadge(
                                        priority:
                                            data['priority']?.toString() ??
                                            'medium',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 17),
                            _section(
                              icon: Icons.description_outlined,
                              title: 'Mô tả công việc',
                              child: Text(
                                description.isEmpty
                                    ? 'Chưa có mô tả công việc.'
                                    : description,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _section(
                              icon: Icons.info_outline,
                              title: 'Thông tin thực hiện',
                              child: Column(
                                children: [
                                  _infoRow(
                                    icon: Icons.person_outline,
                                    label: 'Người tạo',
                                    value: _personName(data['createdBy']),
                                  ),
                                  _infoRow(
                                    icon: Icons.event_outlined,
                                    label: 'Ngày bắt đầu',
                                    value: AppDateFormatter.format(
                                      data['startDate'],
                                    ),
                                  ),
                                  _infoRow(
                                    icon: Icons.event_available_outlined,
                                    label: 'Hạn hoàn thành',
                                    value: AppDateFormatter.format(
                                      data['dueDate'],
                                    ),
                                  ),
                                  _infoRow(
                                    icon: Icons.star_outline,
                                    label: 'Người phụ trách chính',
                                    value: _personName(primary),
                                  ),
                                  _infoRow(
                                    icon: Icons.groups_outlined,
                                    label: 'Người được giao',
                                    value: assignees.isEmpty
                                        ? 'Chưa giao cho ai'
                                        : assignees.map(_personName).join(', '),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _section(
                              icon: Icons.track_changes_outlined,
                              title: 'Trạng thái công việc',
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(status),
                                initialValue:
                                    const [
                                      'todo',
                                      'in_progress',
                                      'completed',
                                    ].contains(status)
                                    ? status
                                    : 'todo',
                                decoration: const InputDecoration(
                                  labelText: 'Trạng thái hiện tại',
                                  prefixIcon: Icon(Icons.flag_circle_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'todo',
                                    child: Text('Chưa thực hiện'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Text('Đang thực hiện'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text('Đã hoàn thành'),
                                  ),
                                ],
                                onChanged: changingStatus
                                    ? null
                                    : (value) {
                                        if (value != null && value != status) {
                                          changeStatus(value);
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: 20),
                            _actionButton(
                              icon: Icons.edit_outlined,
                              title: 'Chỉnh sửa công việc',
                              onPressed: editTask,
                              primary: true,
                            ),
                            if (isOwner) ...[
                              const SizedBox(height: 11),
                              _actionButton(
                                icon: Icons.group_add_outlined,
                                title: 'Giao công việc',
                                onPressed: openAssignment,
                              ),
                              const SizedBox(height: 11),
                              _actionButton(
                                icon: Icons.share_outlined,
                                title: 'Quản lý chia sẻ',
                                onPressed: openSharing,
                              ),
                              const SizedBox(height: 14),
                              TextButton.icon(
                                onPressed: deleting ? null : deleteTask,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                ),
                                label: Text(
                                  deleting ? 'Đang xóa...' : 'Xóa công việc',
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
