import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import '../notifications/notification_screen.dart';
import '../../utils/constants.dart';
import '../../widgets/task_card.dart';
import '../../widgets/loading_view.dart';
import '../profile/profile_screen.dart';
import '../statistics/statistics_screen.dart';
import '../statistics/statistics_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // B7 - Sap xep danh sach cong viec.
  String selectedSortBy = 'createdAt';
  String selectedSortOrder = 'desc';
  String currentUserName = 'Tài khoản';

  Future<void> loadCurrentUser() async {
    try {
      final response = await ApiClient.get('/api/auth/me');
      final user = response['data'];

      if (user is! Map) return;

      final name = (user['fullName'] ?? user['name'] ?? 'Tài khoản')
          .toString()
          .trim();

      if (!mounted) return;

      setState(() {
        currentUserName = name.isEmpty ? 'Tài khoản' : name;
      });
    } catch (error) {
      debugPrint('Khong tai duoc ten tai khoan: $error');
    }
  }

  Future<void> loadAssigneeOptions() async {
    try {
      // Lay tat ca cong viec ma tai khoan co quyen xem.
      // Khong phu thuoc bo loc trang thai, uu tien hien tai.
      final allTasks = await _taskService.getTasks(scope: 'all');

      // Lay ID cua tai khoan dang dang nhap.
      final meResponse = await ApiClient.get('/api/auth/me');
      final meData = meResponse['data'];

      final String? currentUserId = meData is Map
          ? (meData['_id'] ?? meData['id'])?.toString()
          : null;

      final users = <String, String>{};

      for (final task in allTasks) {
        final assignees = task['assigneeIds'];

        if (assignees is! List) continue;

        for (final item in assignees) {
          if (item is! Map) continue;

          final id = (item['_id'] ?? item['id'])?.toString().trim();

          final name = item['fullName']?.toString().trim();

          if (id == null || id.isEmpty) continue;
          if (name == null || name.isEmpty) continue;

          // Khong hien lai tai khoan hien tai vi da co "Toi phu trach".
          if (id == currentUserId) continue;

          users[id] = name;
        }
      }

      final options = users.entries.map((entry) {
        return <String, String>{'id': entry.key, 'name': entry.value};
      }).toList();

      options.sort(
        (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
          (b['name'] ?? '').toLowerCase(),
        ),
      );

      if (!mounted) return;

      setState(() {
        assigneeOptions = options;
      });
    } catch (error) {
      debugPrint('Khong tai duoc nguoi phu trach: $error');
    }
  }

  final TaskService _taskService = const TaskService();
  final NotificationService _notificationService = const NotificationService();

  int unreadNotificationCount = 0;

  Future<void> loadUnreadNotifications() async {
    try {
      final count = await _notificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        unreadNotificationCount = count;
      });
    } catch (error) {
      debugPrint('Khong tai duoc so thong bao: $error');
    }
  }

  Future<void> openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationScreen()));

    if (!mounted) return;

    await loadUnreadNotifications();
    await loadTasks();
  }

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> tasks = [];

  bool loading = true;
  String scope = 'all';
  String? selectedStatus;
  String? selectedPriority;
  String? selectedAssignee;
  List<Map<String, String>> assigneeOptions = [];
  String query = '';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    loadAssigneeOptions();
    loadTasks();
    loadUnreadNotifications();
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
        assigneeId: selectedAssignee,
        sortBy: selectedSortBy,
        sortOrder: selectedSortOrder,
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
    if (mounted) {
      await loadAssigneeOptions();
      await loadTasks();
    }
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
    final filterFields = <Widget>[
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
          DropdownMenuItem(value: 'created', child: Text('Công việc tôi tạo')),
          DropdownMenuItem(value: 'assigned', child: Text('Được giao cho tôi')),
          DropdownMenuItem(value: 'shared', child: Text('Được chia sẻ')),
        ],
        onChanged: (value) {
          if (value == null || value == scope) return;
          setState(() => scope = value);
          loadTasks();
        },
      ),

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
          DropdownMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
          DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
        ],
        onChanged: (value) {
          if (value == null) return;
          final next = value == 'all' ? null : value;
          if (next == selectedStatus) return;
          setState(() => selectedStatus = next);
          loadTasks();
        },
      ),

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

      DropdownButtonFormField<String>(
        key: ValueKey('assignee_${selectedAssignee ?? 'all'}'),
        initialValue: selectedAssignee ?? 'all',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Người được giao phụ trách',
          prefixIcon: Icon(Icons.people_outline),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: 'all',
            child: Text('Tất cả người phụ trách'),
          ),
          const DropdownMenuItem<String>(
            value: 'me',
            child: Text('Tôi phụ trách'),
          ),
          ...assigneeOptions.map((user) {
            return DropdownMenuItem<String>(
              value: user['id']!,
              child: Text(
                '${user['name']} phụ trách',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (value) {
          if (value == null) return;
          final next = value == 'all' ? null : value;
          if (next == selectedAssignee) return;
          setState(() => selectedAssignee = next);
          loadTasks();
        },
      ),

      DropdownButtonFormField<String>(
        key: ValueKey('sortBy_$selectedSortBy'),
        initialValue: selectedSortBy,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Sắp xếp theo',
          prefixIcon: Icon(Icons.sort_rounded),
        ),
        items: const [
          DropdownMenuItem(value: 'createdAt', child: Text('Thời gian tạo')),
          DropdownMenuItem(value: 'dueDate', child: Text('Hạn hoàn thành')),
          DropdownMenuItem(value: 'priority', child: Text('Mức độ ưu tiên')),
        ],
        onChanged: (value) {
          if (value == null || value == selectedSortBy) return;
          setState(() => selectedSortBy = value);
          loadTasks();
        },
      ),

      DropdownButtonFormField<String>(
        key: ValueKey('sortOrder_$selectedSortOrder'),
        initialValue: selectedSortOrder,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Thứ tự sắp xếp',
          prefixIcon: Icon(Icons.swap_vert_rounded),
        ),
        items: const [
          DropdownMenuItem(value: 'desc', child: Text('Giảm dần')),
          DropdownMenuItem(value: 'asc', child: Text('Tăng dần')),
        ],
        onChanged: (value) {
          if (value == null || value == selectedSortOrder) return;
          setState(() => selectedSortOrder = value);
          loadTasks();
        },
      ),
    ];

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
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns = constraints.maxWidth >= 620;

              if (!useTwoColumns) {
                return Column(
                  children: [
                    for (var i = 0; i < filterFields.length; i++) ...[
                      filterFields[i],
                      if (i < filterFields.length - 1)
                        const SizedBox(height: 13),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < filterFields.length; i += 2) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: filterFields[i]),
                        const SizedBox(width: 13),
                        Expanded(child: filterFields[i + 1]),
                      ],
                    ),
                    if (i < filterFields.length - 2) const SizedBox(height: 13),
                  ],
                ],
              );
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
    final narrowHeader = MediaQuery.sizeOf(context).width < 650;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        titleSpacing: 12,

        title: narrowHeader
            ? TextButton.icon(
                onPressed: openProfile,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: const Icon(
                  Icons.account_circle_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
                label: Text(
                  currentUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173A70),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : const Text(
                'TaskFlow',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),

        actions: [
          IconButton(
            tooltip: 'Thông báo trong ứng dụng',
            onPressed: openNotifications,
            icon: Badge(
              isLabelVisible: unreadNotificationCount > 0,
              label: Text(
                unreadNotificationCount > 99
                    ? '99+'
                    : '$unreadNotificationCount',
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 25),
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loading ? null : loadTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),

          if (!narrowHeader)
            TextButton.icon(
              onPressed: openProfile,
              icon: const Icon(
                Icons.account_circle_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  currentUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173A70),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(right: 12, left: 6),
            child: IconButton(
              tooltip: 'Đăng xuất',
              onPressed: logout,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE5F1FF), Color(0xFFF2F8FF), Colors.white],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: RefreshIndicator(
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
      ),
    );
  }
}
