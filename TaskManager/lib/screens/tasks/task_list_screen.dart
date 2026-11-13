import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../widgets/task_card.dart';
import '../../widgets/loading_view.dart';
import '../profile/profile_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = const TaskService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> tasks = [];

  bool loading = true;
  String scope = 'all';
  String? selectedStatus;
  String? selectedPriority;
  String query = '';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> loadTasks() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await _taskService.getTasks(
        scope: scope,
        status: selectedStatus,
        priority: selectedPriority,
      );

      if (!mounted) return;

      setState(() {
        tasks = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });

      showMessage(errorMessage!, error: true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có muốn đăng xuất khỏi TaskFlow không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.clearToken();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> openCreate() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TaskCreateScreen()),
    );

    if (changed == true && mounted) {
      await loadTasks();
    }
  }

  Future<void> openDetail(Map<String, dynamic> task) async {
    final id = (task['_id'] ?? task['id'])?.toString();

    if (id == null || id.isEmpty) {
      showMessage('Không tìm thấy mã công việc', error: true);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id)),
    );

    if (mounted) await loadTasks();
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  List<Map<String, dynamic>> get visibleTasks {
    final keyword = query.trim().toLowerCase();

    if (keyword.isEmpty) return tasks;

    return tasks.where((task) {
      final title = task['title']?.toString().toLowerCase() ?? '';

      final description = task['description']?.toString().toLowerCase() ?? '';

      return title.contains(keyword) || description.contains(keyword);
    }).toList();
  }

  int get completedCount {
    return tasks.where((task) => task['status'] == TaskValues.completed).length;
  }

  int get progressCount {
    return tasks
        .where((task) => task['status'] == TaskValues.inProgress)
        .length;
  }

  int get pendingCount {
    return tasks.length - completedCount - progressCount;
  }

  double get completionRate {
    if (tasks.isEmpty) return 0;

    return completedCount / tasks.length;
  }

  Widget metric({
    required String label,
    required int count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x25FFFFFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget dashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20315CEB),
            blurRadius: 19,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.space_dashboard_outlined,
                color: Colors.white70,
                size: 19,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TỔNG QUAN CÔNG VIỆC',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            '${tasks.length} công việc',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Đã hoàn thành ${(completionRate * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: completionRate,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: const Color(0x55FFFFFF),
            ),
          ),
          const SizedBox(height: 23),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 310;

              final items = [
                metric(
                  label: 'Cần làm',
                  count: pendingCount,
                  icon: Icons.pending_actions_outlined,
                ),
                metric(
                  label: 'Đang làm',
                  count: progressCount,
                  icon: Icons.timelapse_rounded,
                ),
                metric(
                  label: 'Hoàn thành',
                  count: completedCount,
                  icon: Icons.check_circle_outline,
                ),
              ];

              if (narrow) {
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      items[i],
                      if (i < items.length - 1) const SizedBox(height: 9),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(child: items[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget filters() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() => query = value);
            },
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm công việc...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            key: ValueKey(scope),
            initialValue: scope,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Hiển thị theo',
              prefixIcon: Icon(Icons.filter_list_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả công việc')),
              DropdownMenuItem(
                value: 'created',
                child: Text('Công việc tôi tạo'),
              ),
              DropdownMenuItem(
                value: 'assigned',
                child: Text('Được giao cho tôi'),
              ),
              DropdownMenuItem(value: 'shared', child: Text('Được chia sẻ')),
            ],
            onChanged: (value) {
              if (value == null || value == scope) return;

              setState(() => scope = value);
              loadTasks();
            },
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            key: ValueKey('status_${selectedStatus ?? 'all'}'),
            initialValue: selectedStatus ?? 'all',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              prefixIcon: Icon(Icons.timelapse_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
              DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('Đang thực hiện'),
              ),
              DropdownMenuItem(
                value: 'completed',
                child: Text('Đã hoàn thành'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              final next = value == 'all' ? null : value;
              if (next == selectedStatus) return;
              setState(() => selectedStatus = next);
              loadTasks();
            },
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            key: ValueKey('priority_${selectedPriority ?? 'all'}'),
            initialValue: selectedPriority ?? 'all',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Mức độ ưu tiên',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả mức độ')),
              DropdownMenuItem(value: 'low', child: Text('Thấp')),
              DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
              DropdownMenuItem(value: 'high', child: Text('Cao')),
            ],
            onChanged: (value) {
              if (value == null) return;
              final next = value == 'all' ? null : value;
              if (next == selectedPriority) return;
              setState(() => selectedPriority = next);
              loadTasks();
            },
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: AppColors.primary, size: 49),
          const SizedBox(height: 13),
          Text(
            query.trim().isEmpty
                ? 'Chưa có công việc nào'
                : 'Không tìm thấy công việc',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn có thể thay đổi bộ lọc hoặc tạo công việc mới.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 17),
          FilledButton.icon(
            onPressed: openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Tạo công việc'),
          ),
        ],
      ),
    );
  }

  Widget errorState() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 37,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Không tải được danh sách',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = visibleTasks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: const Text(
          'TaskFlow',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loading ? null : loadTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Thông tin cá nhân',
            onPressed: openProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo công việc'),
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxWidth < 600;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 24,
                16,
                compact ? 14 : 24,
                110,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        dashboardHeader(),
                        const SizedBox(height: 25),
                        const Text(
                          'Công việc của bạn',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Theo dõi và quản lý tiến độ mỗi ngày',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 19),
                        filters(),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Danh sách công việc',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '${filtered.length} mục',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        if (loading)
                          const LoadingView(message: 'Đang tải công việc...')
                        else if (errorMessage != null)
                          errorState()
                        else if (filtered.isEmpty)
                            emptyState()
                          else
                            ...filtered.map(
                                  (task) => TaskCard(
                                task: task,
                                onTap: () => openDetail(task),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
