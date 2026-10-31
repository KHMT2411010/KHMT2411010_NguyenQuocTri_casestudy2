
import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'screens/profile/profile_screen.dart';

void showError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString().replaceFirst('Exception: ', '')),
      backgroundColor: Colors.red.shade700,
    ),
  );
}

void showSuccess(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// KIEM TRA DANG NHAP
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    try {
      final token = await ApiClient.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiClient.get('/api/auth/me');
        loggedIn = true;
      }
    } catch (_) {
      await ApiClient.clearToken();
      loggedIn = false;
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return loggedIn
        ? const TaskListScreen()
        : const LoginScreen();
  }
}

// DANG NHAP VA DANG KY
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool register = false;
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      showError(context, 'Vui lòng nhập email và mật khẩu');
      return;
    }

    if (register && name.text.trim().isEmpty) {
      showError(context, 'Vui lòng nhập họ tên');
      return;
    }

    setState(() => loading = true);

    try {
      final data = await ApiClient.post(
        register ? '/api/auth/register' : '/api/auth/login',
        register
            ? {
          'fullName': name.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
        }
            : {
          'email': email.text.trim(),
          'password': password.text,
        },
      );

      await ApiClient.saveToken(data['token'].toString());

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TaskListScreen(),
        ),
      );
    } catch (e) {
      showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.task_alt,
                      size: 65,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      register ? 'Đăng ký tài khoản' : 'Đăng nhập',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (register) ...[
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : submit,
                        child: Text(
                          loading
                              ? 'Đang xử lý...'
                              : register ? 'Đăng ký' : 'Đăng nhập',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() => register = !register),
                      child: Text(
                        register
                            ? 'Đã có tài khoản? Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// DANH SACH CONG VIEC
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<dynamic> tasks = [];
  bool loading = true;
  String scope = 'all';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => loading = true);

    try {
      final endpoint = scope == 'all'
          ? '/api/tasks'
          : '/api/tasks?scope=$scope';

      final data = await ApiClient.get(endpoint);

      if (mounted) {
        setState(() {
          tasks = data['data'] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  Future<void> openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskFormScreen(),
      ),
    );
    loadTasks();
  }

  Future<void> openDetail(Map<String, dynamic> task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: task['_id'].toString()),
      ),
    );
    loadTasks();
  }

  String statusText(String value) {
    switch (value) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý công việc'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Hồ sơ cá nhân',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: scope,
              decoration: const InputDecoration(
                labelText: 'Lọc công việc',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Tất cả công việc'),
                ),
                DropdownMenuItem(
                  value: 'created',
                  child: Text('Công việc tôi tạo'),
                ),
                DropdownMenuItem(
                  value: 'assigned',
                  child: Text('Được giao cho tôi'),
                ),
                DropdownMenuItem(
                  value: 'shared',
                  child: Text('Được chia sẻ'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  scope = value;
                  loadTasks();
                }
              },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: loadTasks,
              child: tasks.isEmpty
                  ? ListView(
                children: const [
                  SizedBox(height: 140),
                  Center(
                    child: Text('Chưa có công việc nào'),
                  ),
                ],
              )
                  : ListView.builder(
                itemCount: tasks.length,
                padding: const EdgeInsets.fromLTRB(
                  12, 0, 12, 90,
                ),
                itemBuilder: (context, index) {
                  final task = Map<String, dynamic>.from(
                    tasks[index],
                  );
                  final title =
                      task['title']?.toString() ?? '';
                  final status =
                      task['status']?.toString() ?? 'todo';
                  final priority =
                      task['priority']?.toString() ?? 'medium';

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        status == 'completed'
                            ? Icons.check_circle
                            : Icons.assignment_outlined,
                        color: status == 'completed'
                            ? Colors.green
                            : Colors.blue,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${statusText(status)} • $priority',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () => openDetail(task),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// THEM VA CHINH SUA CONG VIEC
class TaskFormScreen extends StatefulWidget {
  final Map<String, dynamic>? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final title = TextEditingController();
  final description = TextEditingController();

  String priority = 'medium';
  DateTime? dueDate;
  bool saving = false;

  bool get editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;

    if (task != null) {
      title.text = task['title']?.toString() ?? '';
      description.text = task['description']?.toString() ?? '';
      priority = task['priority']?.toString() ?? 'medium';

      final date = task['dueDate']?.toString();
      if (date != null && date.isNotEmpty) {
        dueDate = DateTime.tryParse(date);
      }
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) setState(() => dueDate = date);
  }

  Future<void> saveTask() async {
    if (title.text.trim().isEmpty) {
      showError(context, 'Vui lòng nhập tên công việc');
      return;
    }

    setState(() => saving = true);

    try {
      final body = <String, dynamic>{
        'title': title.text.trim(),
        'description': description.text.trim(),
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
      };

      if (editing) {
        await ApiClient.put(
          '/api/tasks/${widget.task!['_id']}',
          body,
        );
      } else {
        await ApiClient.post('/api/tasks', body);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Chỉnh sửa công việc' : 'Thêm công việc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Tên công việc *',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả công việc',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(
                labelText: 'Mức độ ưu tiên',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'low',
                  child: Text('Thấp'),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  child: Text('Trung bình'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text('Cao'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => priority = value);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: chooseDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                dueDate == null
                    ? 'Chọn hạn hoàn thành'
                    : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
              ),
            ),
            if (dueDate != null)
              TextButton(
                onPressed: () => setState(() => dueDate = null),
                child: const Text('Bỏ hạn hoàn thành'),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : saveTask,
              icon: const Icon(Icons.save),
              label: Text(
                saving ? 'Đang lưu...' : 'Lưu công việc',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CHI TIET, XOA, CAP NHAT TRANG THAI
class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? task;
  String? myId;
  bool loading = true;

  bool get isOwner {
    final creator = task?['createdBy'];
    if (creator is Map) {
      return creator['_id']?.toString() == myId;
    }
    return creator?.toString() == myId;
  }

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    setState(() => loading = true);

    try {
      final me = await ApiClient.get('/api/auth/me');
      final result = await ApiClient.get(
        '/api/tasks/${widget.taskId}',
      );

      if (mounted) {
        setState(() {
          myId = (me['data']?['id'] ?? me['data']?['_id'])
              ?.toString();
          task = Map<String, dynamic>.from(result['data']);
        });
      }
    } catch (e) {
      showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> changeStatus(String value) async {
    try {
      await ApiClient.patch(
        '/api/tasks/${widget.taskId}/status',
        {'status': value},
      );
      await loadDetail();
    } catch (e) {
      showError(context, e);
    }
  }

  Future<void> editTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );
    loadDetail();
  }

  Future<void> deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa công việc này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.delete('/api/tasks/${widget.taskId}');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          IconButton(
            onPressed: loadDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : task == null
          ? const Center(child: Text('Không tìm thấy công việc'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            task!['title']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            task!['description']?.toString() ?? '',
          ),
          const SizedBox(height: 16),
          Text(
            'Ưu tiên: ${task!['priority']}',
          ),
          const SizedBox(height: 8),
          Text(
            'Hạn hoàn thành: ${task!['dueDate'] ?? 'Chưa có'}',
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            key: ValueKey(task!['status']),
            initialValue: task!['status']?.toString() ?? 'todo',
            decoration: const InputDecoration(
              labelText: 'Trạng thái công việc',
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
                child: Text('Hoàn thành'),
              ),
            ],
            onChanged: (value) {
              if (value != null) changeStatus(value);
            },
          ),
          const SizedBox(height: 24),
          // Backend kiem tra quyen chinh thuc
          OutlinedButton.icon(
            onPressed: editTask,
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa'),
          ),
          const SizedBox(height: 8),
          if (isOwner) ...[
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignmentScreen(
                      taskId: widget.taskId,
                    ),
                  ),
                );
                loadDetail();
              },
              icon: const Icon(Icons.group_add),
              label: const Text('Giao công việc'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharingScreen(
                      taskId: widget.taskId,
                    ),
                  ),
                );
                loadDetail();
              },
              icon: const Icon(Icons.share),
              label: const Text('Quản lý chia sẻ'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: deleteTask,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Xóa công việc',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// GIAO VIEC NHIEU NGUOI
class AssignmentScreen extends StatefulWidget {
  final String taskId;
  const AssignmentScreen({super.key, required this.taskId});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final userIds = TextEditingController();
  final primaryId = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    userIds.dispose();
    primaryId.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final ids = userIds.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (ids.isEmpty) {
      showError(context, 'Hãy nhập ID người được giao');
      return;
    }

    setState(() => saving = true);

    try {
      await ApiClient.post(
        '/api/tasks/${widget.taskId}/assignees',
        {
          'userIds': ids,
          if (primaryId.text.trim().isNotEmpty)
            'primaryAssigneeId': primaryId.text.trim(),
        },
      );

      if (!mounted) return;
      showSuccess(context, 'Giao việc thành công');
      Navigator.pop(context, true);
    } catch (e) {
      showError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao công việc')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Nhập ID của các tài khoản đã đăng ký.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: userIds,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Danh sách User ID',
              hintText: 'ID_1, ID_2, ID_3',
              helperText: 'Phân cách nhiều ID bằng dấu phẩy',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: primaryId,
            decoration: const InputDecoration(
              labelText: 'ID người phụ trách chính',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.send),
            label: const Text('Xác nhận giao việc'),
          ),
        ],
      ),
    );
  }
}

// CHIA SE CONG VIEC VIEWER / EDITOR
class SharingScreen extends StatefulWidget {
  final String taskId;
  const SharingScreen({super.key, required this.taskId});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final userIds = TextEditingController();
  String permission = 'viewer';
  List<dynamic> shares = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadShares();
  }

  @override
  void dispose() {
    userIds.dispose();
    super.dispose();
  }

  Future<void> loadShares() async {
    setState(() => loading = true);

    try {
      final result = await ApiClient.get(
        '/api/tasks/${widget.taskId}/shares',
      );

      if (mounted) {
        setState(() {
          shares = result['data'] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addShares() async {
    final ids = userIds.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (ids.isEmpty) {
      showError(context, 'Nhập ít nhất một User ID');
      return;
    }

    try {
      await ApiClient.post(
        '/api/tasks/${widget.taskId}/shares',
        {
          'userIds': ids,
          'permission': permission,
        },
      );

      userIds.clear();
      if (!mounted) return;
      showSuccess(context, 'Chia sẻ thành công');
      loadShares();
    } catch (e) {
      showError(context, e);
    }
  }

  Future<void> changePermission(
      String shareId,
      String value,
      ) async {
    try {
      await ApiClient.patch(
        '/api/tasks/${widget.taskId}/shares/$shareId',
        {'permission': value},
      );
      loadShares();
    } catch (e) {
      showError(context, e);
    }
  }

  Future<void> removeShare(String shareId) async {
    try {
      await ApiClient.delete(
        '/api/tasks/${widget.taskId}/shares/$shareId',
      );
      loadShares();
    } catch (e) {
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ công việc')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: userIds,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ID người được chia sẻ',
              helperText: 'Có thể nhập nhiều ID, cách nhau dấu phẩy',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: permission,
            decoration: const InputDecoration(
              labelText: 'Quyền chia sẻ',
            ),
            items: const [
              DropdownMenuItem(
                value: 'viewer',
                child: Text('Viewer - Chỉ xem'),
              ),
              DropdownMenuItem(
                value: 'editor',
                child: Text('Editor - Được chỉnh sửa'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => permission = value);
              }
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: addShares,
            icon: const Icon(Icons.person_add),
            label: const Text('Thêm người chia sẻ'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Danh sách được chia sẻ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (shares.isEmpty)
            const Text('Chưa chia sẻ với ai')
          else
            ...shares.map((item) {
              final share = Map<String, dynamic>.from(item);
              final user = share['userId'];
              final name = user is Map
                  ? user['fullName']?.toString() ?? 'Người dùng'
                  : user.toString();
              final email = user is Map
                  ? user['email']?.toString() ?? ''
                  : '';
              final id = share['_id'].toString();
              final currentPermission =
                  share['permission']?.toString() ?? 'viewer';

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email),
                      DropdownButton<String>(
                        value: currentPermission,
                        items: const [
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Text('Viewer'),
                          ),
                          DropdownMenuItem(
                            value: 'editor',
                            child: Text('Editor'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            changePermission(id, value);
                          }
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.person_remove,
                      color: Colors.red,
                    ),
                    onPressed: () => removeShare(id),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
