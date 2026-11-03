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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return loggedIn ? const TaskListScreen() : const LoginScreen();
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
  final confirmPassword = TextEditingController();

  bool register = false;
  bool loading = false;
  bool showPassword = false;

  static const blue = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (register && name.text.trim().isEmpty) {
      showError(context, 'Vui lòng nhập họ và tên');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      showError(context, 'Email không hợp lệ');
      return;
    }

    if (password.text.isEmpty) {
      showError(context, 'Vui lòng nhập mật khẩu');
      return;
    }

    if (register && password.text != confirmPassword.text) {
      showError(context, 'Xác nhận mật khẩu không khớp');
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
            : {'email': email.text.trim(), 'password': password.text},
      );

      if (!mounted) return;

      if (register) {
        setState(() {
          register = false;
          password.clear();
          confirmPassword.clear();
        });

        showSuccess(context, 'Đăng ký thành công! Hãy đăng nhập.');
        return;
      }

      final token = data['token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Không nhận được token đăng nhập');
      }

      await ApiClient.saveToken(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
      );
    } catch (e) {
      showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: isPassword && !showPassword,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: blue, size: 21),
        suffixIcon: isPassword
            ? IconButton(
                tooltip: showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                onPressed: () {
                  setState(() => showPassword = !showPassword);
                },
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF315CEB), Color(0xFF6898FF)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33315CEB),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        size: 43,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'TaskFlow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: navy,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    register
                        ? 'Bắt đầu hành trình làm việc hiệu quả'
                        : 'Sắp xếp công việc, kết nối đội nhóm',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 27),
                  Container(
                    padding: const EdgeInsets.all(23),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFE8EDF5)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080E214A),
                          blurRadius: 25,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          register ? 'Tạo tài khoản' : 'Chào mừng trở lại!',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          register
                              ? 'Điền thông tin để tham gia TaskFlow.'
                              : 'Đăng nhập để tiếp tục công việc.',
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        if (register) ...[
                          inputField(
                            label: 'Họ và tên',
                            controller: name,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 15),
                        ],
                        inputField(
                          label: 'Địa chỉ email',
                          controller: email,
                          icon: Icons.alternate_email_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),
                        inputField(
                          label: 'Mật khẩu',
                          controller: password,
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        if (register) ...[
                          const SizedBox(height: 15),
                          inputField(
                            label: 'Xác nhận mật khẩu',
                            controller: confirmPassword,
                            icon: Icons.verified_user_outlined,
                            isPassword: true,
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: loading ? null : submit,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        register
                                            ? 'Tạo tài khoản'
                                            : 'Đăng nhập',
                                      ),
                                      const SizedBox(width: 9),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 19,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    register = !register;
                                    password.clear();
                                    confirmPassword.clear();
                                  });
                                },
                          child: Text(
                            register
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký ngay',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 23),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: muted, size: 15),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Quản lý công việc an toàn và hiệu quả',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
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
  final searchController = TextEditingController();

  bool loading = true;
  String scope = 'all';
  String query = '';

  static const blue = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

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

  Future<void> loadTasks() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final endpoint = scope == 'all'
          ? '/api/tasks'
          : '/api/tasks?scope=$scope';

      final data = await ApiClient.get(endpoint);

      if (!mounted) return;

      setState(() {
        tasks = data['data'] as List<dynamic>? ?? [];
      });
    } catch (e) {
      if (mounted) showError(context, e);
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
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    if (mounted) loadTasks();
  }

  Future<void> openDetail(Map<String, dynamic> task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: task['_id'].toString()),
      ),
    );
    if (mounted) loadTasks();
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

  Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF199C77);
      case 'in_progress':
        return blue;
      default:
        return const Color(0xFFF0A33A);
    }
  }

  Color priorityColor(String value) {
    switch (value) {
      case 'high':
        return const Color(0xFFE45656);
      case 'low':
        return const Color(0xFF199C77);
      default:
        return const Color(0xFFE99B30);
    }
  }

  String priorityText(String value) {
    switch (value) {
      case 'high':
        return 'Cao';
      case 'low':
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }

  String formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Chưa đặt hạn';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget metric(String title, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0x25FFFFFF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 7),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget taskCard(Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? 'Không có tên';
    final description = task['description']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'todo';
    final priority = task['priority']?.toString() ?? 'medium';

    final color = statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openDetail(task),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        status == 'completed'
                            ? Icons.task_alt_rounded
                            : Icons.assignment_outlined,
                        color: color,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: muted),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    pill(statusText(status), color),
                    pill(
                      'Ưu tiên: ${priorityText(priority)}',
                      priorityColor(priority),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFEDF0F6), height: 1),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 17, color: muted),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Hạn hoàn thành: ${formatDate(task['dueDate'])}',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = tasks.where((item) {
      if (item is! Map) return false;

      final title = item['title']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';

      final keyword = query.trim().toLowerCase();

      return title.contains(keyword) || description.contains(keyword);
    }).toList();

    final completed = tasks
        .where((t) => t is Map && t['status'] == 'completed')
        .length;

    final progress = tasks
        .where((t) => t is Map && t['status'] == 'in_progress')
        .length;

    final pending = tasks.length - completed - progress;

    final percentage = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('TaskFlow'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Hồ sơ cá nhân',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        onPressed: openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo công việc'),
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 12, 17, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF315CEB), Color(0xFF6898FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20315CEB),
                    blurRadius: 20,
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
                        size: 19,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'TỔNG QUAN CÔNG VIỆC',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    '${tasks.length} công việc',
                    style: const TextStyle(
                      fontSize: 29,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Đã hoàn thành ${(percentage * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      color: Colors.white,
                      backgroundColor: const Color(0x55FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 23),
                  Row(
                    children: [
                      metric(
                        'Cần làm',
                        pending,
                        Icons.pending_actions_outlined,
                      ),
                      const SizedBox(width: 9),
                      metric('Đang làm', progress, Icons.timelapse_rounded),
                      const SizedBox(width: 9),
                      metric(
                        'Hoàn thành',
                        completed,
                        Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Công việc của bạn',
              style: TextStyle(
                color: navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Theo dõi và quản lý tiến độ mỗi ngày',
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 19),
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
              initialValue: scope,
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
                if (value != null) {
                  scope = value;
                  loadTasks();
                }
              },
            ),
            const SizedBox(height: 19),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách công việc',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${visibleTasks.length} mục',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(45),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibleTasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5EBF5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, color: blue, size: 48),
                    const SizedBox(height: 13),
                    Text(
                      query.isEmpty
                          ? 'Chưa có công việc nào'
                          : 'Không tìm thấy công việc',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thử tìm kiếm khác hoặc tạo công việc mới.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: openCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo công việc'),
                    ),
                  ],
                ),
              )
            else
              ...visibleTasks.map(
                (item) => taskCard(Map<String, dynamic>.from(item as Map)),
              ),
          ],
        ),
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
  final _formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();

  static const blue = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

  String priority = 'medium';
  DateTime? startDate;
  DateTime? dueDate;
  bool saving = false;

  bool get editing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;
    if (task == null) return;

    title.text = task['title']?.toString() ?? '';
    description.text = task['description']?.toString() ?? '';

    final existingPriority = task['priority']?.toString();
    if (['low', 'medium', 'high'].contains(existingPriority)) {
      priority = existingPriority!;
    }

    startDate = _parseDate(task['startDate']);
    dueDate = _parseDate(task['dueDate']);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn ngày';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _chooseDate(bool isStart) async {
    final current = isStart ? startDate : dueDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'CHỌN NGÀY BẮT ĐẦU' : 'CHỌN HẠN HOÀN THÀNH',
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isStart) {
        startDate = selected;
      } else {
        dueDate = selected;
      }
    });
  }

  Future<void> saveTask() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (startDate != null &&
        dueDate != null &&
        DateUtils.dateOnly(dueDate!).isBefore(DateUtils.dateOnly(startDate!))) {
      showError(context, 'Hạn hoàn thành phải từ ngày bắt đầu trở đi');
      return;
    }

    setState(() => saving = true);

    try {
      final body = <String, dynamic>{
        'title': title.text.trim(),
        'description': description.text.trim(),
        'priority': priority,
        'startDate': startDate == null
            ? null
            : DateUtils.dateOnly(startDate!).toIso8601String(),
        'dueDate': dueDate == null
            ? null
            : DateUtils.dateOnly(dueDate!).toIso8601String(),
      };

      if (editing) {
        await ApiClient.put('/api/tasks/${widget.task!['_id']}', body);
      } else {
        await ApiClient.post('/api/tasks', body);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _section({
    required IconData icon,
    required String heading,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF4)),
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
                child: Icon(icon, color: blue, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          child,
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required bool isStart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE2E9F3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => _chooseDate(isStart),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: blue,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: date == null ? muted : navy,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (date != null)
                IconButton(
                  tooltip: 'Bỏ chọn ngày',
                  icon: const Icon(Icons.close_rounded, size: 19),
                  onPressed: () {
                    setState(() {
                      if (isStart) {
                        startDate = null;
                      } else {
                        dueDate = null;
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priorityOption({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected = priority == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFFE6EAF2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? color : navy,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_circle, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: Text(
          editing ? 'Chỉnh sửa công việc' : 'Tạo công việc',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxWidth < 600;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 24,
              18,
              compact ? 14 : 24,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF315CEB), Color(0xFF6790F8)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              editing
                                  ? Icons.edit_note_rounded
                                  : Icons.add_task_rounded,
                              size: 34,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 13),
                            Text(
                              editing ? 'Cập nhật công việc' : 'Công việc mới',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              editing
                                  ? 'Điều chỉnh thông tin và thời hạn.'
                                  : 'Thiết lập nội dung và kế hoạch thực hiện.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _section(
                        icon: Icons.description_outlined,
                        heading: 'Thông tin công việc',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: title,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                labelText: 'Tên công việc *',
                                hintText: 'Ví dụ: Thiết kế giao diện',
                                prefixIcon: Icon(Icons.assignment_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên công việc';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: description,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả công việc',
                                hintText: 'Nhập nội dung cần thực hiện...',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _section(
                        icon: Icons.flag_outlined,
                        heading: 'Mức độ ưu tiên',
                        child: LayoutBuilder(
                          builder: (context, size) {
                            final narrow = size.maxWidth < 470;

                            final options = [
                              _priorityOption(
                                value: 'low',
                                label: 'Thấp',
                                icon: Icons.keyboard_arrow_down,
                                color: const Color(0xFF159B78),
                              ),
                              _priorityOption(
                                value: 'medium',
                                label: 'Trung bình',
                                icon: Icons.remove_rounded,
                                color: const Color(0xFFE59A28),
                              ),
                              _priorityOption(
                                value: 'high',
                                label: 'Cao',
                                icon: Icons.priority_high_rounded,
                                color: const Color(0xFFDF5454),
                              ),
                            ];

                            if (narrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final option in options) ...[
                                    option,
                                    const SizedBox(height: 9),
                                  ],
                                ],
                              );
                            }

                            return Row(
                              children: [
                                for (var i = 0; i < options.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 9),
                                  Expanded(child: options[i]),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _section(
                        icon: Icons.event_available_outlined,
                        heading: 'Thời gian thực hiện',
                        child: LayoutBuilder(
                          builder: (context, size) {
                            final start = _dateField(
                              label: 'Ngày bắt đầu',
                              date: startDate,
                              isStart: true,
                            );

                            final due = _dateField(
                              label: 'Hạn hoàn thành',
                              date: dueDate,
                              isStart: false,
                            );

                            if (size.maxWidth < 520) {
                              return Column(
                                children: [
                                  start,
                                  const SizedBox(height: 17),
                                  due,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: start),
                                const SizedBox(width: 16),
                                Expanded(child: due),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: saving ? null : saveTask,
                          icon: saving
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  editing
                                      ? Icons.save_outlined
                                      : Icons.add_task_rounded,
                                ),
                          label: Text(
                            saving
                                ? 'Đang lưu...'
                                : editing
                                ? 'Lưu thay đổi'
                                : 'Tạo công việc',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// CHI TIET, XOA, CAP NHAT TRANG THAI

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() =>
      _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const blue = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

  Map<String, dynamic>? task;
  String? myId;
  bool loading = true;
  bool changingStatus = false;

  bool get isOwner {
    final creator = task?['createdBy'];
    final id = creator is Map
        ? creator['_id']?.toString()
        : creator?.toString();
    return myId != null && id == myId;
  }

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  String nameOf(dynamic user) {
    if (user is Map) {
      return user['fullName']?.toString() ??
          user['email']?.toString() ??
          'Người dùng';
    }
    return 'Chưa phân công';
  }

  String dateOf(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return 'Chưa thiết lập';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Đã hoàn thành';
      case 'in_progress':
        return 'Đang thực hiện';
      default:
        return 'Chưa thực hiện';
    }
  }

  String priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Cao';
      case 'low':
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }

  Color statusColor(String value) {
    switch (value) {
      case 'completed':
        return const Color(0xFF129B73);
      case 'in_progress':
        return blue;
      default:
        return const Color(0xFFE5A03B);
    }
  }

  Future<void> loadDetail() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final me = await ApiClient.get('/api/auth/me');
      final result = await ApiClient.get(
        '/api/tasks/${widget.taskId}',
      );

      if (!mounted) return;

      final user = me['data'];
      setState(() {
        myId = user is Map
            ? (user['_id'] ?? user['id'])?.toString()
            : null;
        task = Map<String, dynamic>.from(result['data']);
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> changeStatus(String value) async {
    if (changingStatus) return;
    setState(() => changingStatus = true);

    try {
      await ApiClient.patch(
        '/api/tasks/${widget.taskId}/status',
        {'status': value},
      );
      await loadDetail();
      if (mounted) {
        showSuccess(context, 'Cập nhật trạng thái thành công');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => changingStatus = false);
    }
  }

  Future<void> editTask() async {
    if (task == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );

    if (changed == true) await loadDetail();
  }

  Future<void> deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa công việc'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.delete('/api/tasks/${widget.taskId}');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> openAssignment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentScreen(taskId: widget.taskId),
      ),
    );
    if (mounted) await loadDetail();
  }

  Future<void> openSharing() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharingScreen(taskId: widget.taskId),
      ),
    );
    if (mounted) await loadDetail();
  }

  Widget section(
      String title,
      IconData icon,
      Widget child,
      ) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7ECF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: blue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  Widget infoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: muted, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loading ? null : loadDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? Center(
        child: OutlinedButton.icon(
          onPressed: loadDetail,
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại công việc'),
        ),
      )
          : LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxWidth < 600;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 24,
              17,
              compact ? 14 : 24,
              35,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(23),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF315CEB),
                              Color(0xFF678FF8),
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.assignment_turned_in_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              data['title']?.toString() ??
                                  'Công việc',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    statusLabel(status),
                                  ),
                                  backgroundColor:
                                  Colors.white,
                                  labelStyle: TextStyle(
                                    color: statusColor(status),
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    'Ưu tiên: ${priorityLabel(data['priority']?.toString() ?? 'medium')}',
                                  ),
                                  backgroundColor:
                                  const Color(0xFFEAF0FF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      section(
                        'Mô tả công việc',
                        Icons.description_outlined,
                        Text(
                          data['description']
                              ?.toString()
                              .trim()
                              .isNotEmpty ==
                              true
                              ? data['description'].toString()
                              : 'Chưa có mô tả công việc.',
                          style: const TextStyle(
                            color: navy,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      section(
                        'Thông tin thực hiện',
                        Icons.info_outline_rounded,
                        Column(
                          children: [
                            infoRow(
                              Icons.person_outline,
                              'Người tạo',
                              nameOf(data['createdBy']),
                            ),
                            infoRow(
                              Icons.flag_outlined,
                              'Mức độ ưu tiên',
                              priorityLabel(
                                data['priority']
                                    ?.toString() ??
                                    'medium',
                              ),
                            ),
                            infoRow(
                              Icons.event_outlined,
                              'Ngày bắt đầu',
                              dateOf(data['startDate']),
                            ),
                            infoRow(
                              Icons.event_available_outlined,
                              'Hạn hoàn thành',
                              dateOf(data['dueDate']),
                            ),
                            infoRow(
                              Icons.star_outline,
                              'Phụ trách chính',
                              nameOf(data['primaryAssigneeId']),
                            ),
                            infoRow(
                              Icons.groups_outlined,
                              'Người được giao',
                              assignees.isEmpty
                                  ? 'Chưa giao cho ai'
                                  : assignees
                                  .map(nameOf)
                                  .join(', '),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      section(
                        'Cập nhật trạng thái',
                        Icons.track_changes_outlined,
                        DropdownButtonFormField<String>(
                          key: ValueKey(status),
                          initialValue: [
                            'todo',
                            'in_progress',
                            'completed',
                          ].contains(status)
                              ? status
                              : 'todo',
                          decoration: const InputDecoration(
                            labelText: 'Trạng thái hiện tại',
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
                            if (value != null &&
                                value != status) {
                              changeStatus(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: editTask,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Chỉnh sửa công việc'),
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(height: 11),
                        OutlinedButton.icon(
                          onPressed: openAssignment,
                          icon: const Icon(
                            Icons.group_add_outlined,
                          ),
                          label: const Text('Giao công việc'),
                        ),
                        const SizedBox(height: 11),
                        OutlinedButton.icon(
                          onPressed: openSharing,
                          icon: const Icon(
                            Icons.share_outlined,
                          ),
                          label: const Text(
                            'Quản lý chia sẻ',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: deleteTask,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Xóa công việc',
                            style: TextStyle(
                              color: Colors.red,
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


// GIAO VIEC NHIEU NGUOI

class AssignmentScreen extends StatefulWidget {
  final String taskId;

  const AssignmentScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<AssignmentScreen> createState() =>
      _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  static const blue = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

  final emailController = TextEditingController();
  final List<Map<String, dynamic>> selectedUsers = [];

  Map<String, dynamic>? foundUser;
  String? primaryId;
  String? searchMessage;

  bool searching = false;
  bool saving = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String userId(Map<String, dynamic> user) {
    return (user['_id'] ?? user['id'] ?? '').toString();
  }

  String userName(Map<String, dynamic> user) {
    return user['fullName']?.toString() ??
        user['email']?.toString() ??
        'Người dùng';
  }

  bool get validEmail => RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(emailController.text.trim());

  Future<void> searchUser() async {
    if (!validEmail) {
      showError(context, 'Nhập email hợp lệ để tìm tài khoản');
      return;
    }

    setState(() {
      searching = true;
      foundUser = null;
      searchMessage = null;
    });

    try {
      final email = emailController.text.trim().toLowerCase();

      final result = await ApiClient.get(
        '/api/users/search?q=${Uri.encodeQueryComponent(email)}',
      );

      final raw = result['data'];

      final List<dynamic> users;
      if (raw is List) {
        users = raw;
      } else if (raw is Map && raw['users'] is List) {
        users = raw['users'] as List;
      } else {
        users = [];
      }

      Map<String, dynamic>? match;

      for (final item in users) {
        if (item is! Map) continue;
        final user = Map<String, dynamic>.from(item);

        if (user['email']
            ?.toString()
            .trim()
            .toLowerCase() ==
            email) {
          match = user;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        foundUser = match;
        searchMessage = match == null
            ? 'Không tìm thấy tài khoản với email này.'
            : null;
      });
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void addUser() {
    final user = foundUser;
    if (user == null) return;

    final id = userId(user);
    if (id.isEmpty) {
      showError(context, 'Tài khoản không có ID hợp lệ');
      return;
    }

    if (selectedUsers.any((item) => userId(item) == id)) {
      showError(context, 'Người này đã được chọn');
      return;
    }

    setState(() {
      selectedUsers.add(user);
      primaryId ??= id;
      foundUser = null;
      emailController.clear();
      searchMessage = null;
    });
  }

  void removeUser(String id) {
    setState(() {
      selectedUsers.removeWhere(
            (user) => userId(user) == id,
      );

      if (primaryId == id) {
        primaryId = selectedUsers.isEmpty
            ? null
            : userId(selectedUsers.first);
      }
    });
  }

  Future<void> save() async {
    if (selectedUsers.isEmpty) {
      showError(context, 'Chọn ít nhất một người được giao');
      return;
    }

    if (primaryId == null ||
        !selectedUsers.any(
              (user) => userId(user) == primaryId,
        )) {
      showError(context, 'Hãy chọn người phụ trách chính');
      return;
    }

    setState(() => saving = true);

    try {
      await ApiClient.post(
        '/api/tasks/${widget.taskId}/assignees',
        {
          'userIds': selectedUsers.map(userId).toList(),
          'primaryAssigneeId': primaryId,
        },
      );

      if (!mounted) return;
      showSuccess(context, 'Giao công việc thành công');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget userCard(Map<String, dynamic> user) {
    final id = userId(user);
    final primary = primaryId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primary
            ? const Color(0xFFF0F4FF)
            : const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: primary
              ? const Color(0xFF9CB5FF)
              : const Color(0xFFE5EBF3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE4ECFF),
                child: Text(
                  userName(user).isEmpty
                      ? '?'
                      : userName(user)[0].toUpperCase(),
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName(user),
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user['email']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Bỏ chọn thành viên',
                onPressed: () => removeUser(id),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          RadioListTile<String>(
            value: id,
            groupValue: primaryId,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              primary
                  ? 'Người phụ trách chính'
                  : 'Đặt làm người phụ trách chính',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onChanged: (value) {
              setState(() => primaryId = value);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Giao công việc'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
      ),
      body: LayoutBuilder(
        builder: (context, viewport) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: 750),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(23),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF315CEB),
                              Color(0xFF6790F8),
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(22),
                        ),
                        child: const Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.groups_2_outlined,
                              color: Colors.white,
                              size: 35,
                            ),
                            SizedBox(height: 13),
                            Text(
                              'Phân công thành viên',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'Tìm tài khoản bằng email, chọn '
                                  'nhiều người thực hiện và xác định '
                                  'người phụ trách chính.',
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 17),
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(19),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Tìm thành viên',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Nhập email đã đăng ký trên TaskManager.',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 17),
                              TextField(
                                controller: emailController,
                                keyboardType:
                                TextInputType.emailAddress,
                                onChanged: (_) {
                                  setState(() {
                                    foundUser = null;
                                    searchMessage = null;
                                  });
                                },
                                onSubmitted: (_) => searchUser(),
                                decoration: const InputDecoration(
                                  labelText: 'Email thành viên',
                                  hintText: 'example@gmail.com',
                                  prefixIcon:
                                  Icon(Icons.alternate_email),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed:
                                searching ? null : searchUser,
                                icon: searching
                                    ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child:
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Icon(Icons.search),
                                label: const Text('Tìm tài khoản'),
                              ),
                              if (searchMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  searchMessage!,
                                  style: const TextStyle(
                                    color: muted,
                                  ),
                                ),
                              ],
                              if (foundUser != null) ...[
                                const SizedBox(height: 15),
                                userCardPreview(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(19),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Đã chọn ${selectedUsers.length} thành viên',
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Chọn dấu tròn bên dưới tên để đặt '
                                    'người phụ trách chính.',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 15),
                              if (selectedUsers.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                      'Chưa có thành viên được chọn',
                                      style: TextStyle(color: muted),
                                    ),
                                  ),
                                )
                              else
                                ...selectedUsers.map(userCard),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 19),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                          ),
                          onPressed: saving ? null : save,
                          icon: saving
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            saving
                                ? 'Đang giao việc...'
                                : 'Xác nhận giao việc',
                          ),
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
    );
  }

  Widget userCardPreview() {
    final user = foundUser!;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            userName(user),
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user['email']?.toString() ?? '',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: addUser,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Thêm vào danh sách giao việc'),
          ),
        ],
      ),
    );
  }
}


// CHIA SE CONG VIEC VIEWER / EDITOR

class SharingScreen extends StatefulWidget {
  final String taskId;

  const SharingScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<SharingScreen> createState() =>
      _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  static const blue = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

  final emailController = TextEditingController();

  List<dynamic> shares = [];
  Map<String, dynamic>? foundUser;
  String permission = 'viewer';
  String? searchMessage;

  bool loading = true;
  bool searching = false;
  bool saving = false;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    loadShares();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String userName(dynamic user) {
    if (user is Map) {
      return user['fullName']?.toString() ??
          user['email']?.toString() ??
          'Người dùng';
    }
    return 'Người dùng';
  }

  String userEmail(dynamic user) {
    if (user is Map) {
      return user['email']?.toString() ?? '';
    }
    return '';
  }

  String userId(Map<String, dynamic> user) {
    return (user['_id'] ?? user['id'] ?? '').toString();
  }

  Future<void> loadShares() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final response = await ApiClient.get(
        '/api/tasks/${widget.taskId}/shares',
      );

      if (!mounted) return;

      setState(() {
        shares = response['data'] is List
            ? response['data'] as List
            : [];
      });
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> searchUser() async {
    final email = emailController.text.trim().toLowerCase();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
      showError(context, 'Email không hợp lệ');
      return;
    }

    setState(() {
      searching = true;
      foundUser = null;
      searchMessage = null;
    });

    try {
      final result = await ApiClient.get(
        '/api/users/search?q=${Uri.encodeQueryComponent(email)}',
      );

      final raw = result['data'];
      final List<dynamic> users;

      if (raw is List) {
        users = raw;
      } else if (raw is Map && raw['users'] is List) {
        users = raw['users'] as List;
      } else {
        users = [];
      }

      Map<String, dynamic>? match;

      for (final item in users) {
        if (item is! Map) continue;

        final candidate = Map<String, dynamic>.from(item);

        if (userEmail(candidate).trim().toLowerCase() ==
            email) {
          match = candidate;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        foundUser = match;
        searchMessage = match == null
            ? 'Không tìm thấy tài khoản với email này.'
            : null;
      });
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> addShares() async {
    final user = foundUser;
    if (user == null) {
      showError(context, 'Hãy tìm và chọn tài khoản trước');
      return;
    }

    final id = userId(user);
    if (id.isEmpty) {
      showError(context, 'Không tìm thấy ID người dùng');
      return;
    }

    setState(() => saving = true);

    try {
      await ApiClient.post(
        '/api/tasks/${widget.taskId}/shares',
        {
          'userIds': [id],
          'permission': permission,
        },
      );

      if (!mounted) return;

      emailController.clear();
      setState(() {
        foundUser = null;
        searchMessage = null;
      });

      showSuccess(context, 'Chia sẻ công việc thành công');
      await loadShares();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> changePermission(
      String shareId,
      String value,
      ) async {
    if (processing) return;
    setState(() => processing = true);

    try {
      await ApiClient.patch(
        '/api/tasks/${widget.taskId}/shares/$shareId',
        {'permission': value},
      );

      if (!mounted) return;
      showSuccess(context, 'Đã cập nhật quyền truy cập');
      await loadShares();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> removeShare(String shareId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thu hồi quyền truy cập?'),
        content: const Text(
          'Người dùng này sẽ không còn quyền chia sẻ '
              'đối với công việc. Nếu họ cũng được giao việc, '
              'quyền từ vai trò được giao có thể vẫn còn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed != true || processing) return;

    setState(() => processing = true);

    try {
      await ApiClient.delete(
        '/api/tasks/${widget.taskId}/shares/$shareId',
      );

      if (!mounted) return;
      showSuccess(context, 'Đã thu hồi quyền chia sẻ');
      await loadShares();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Widget permissionOption(
      String value,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final selected = permission == value;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => setState(() => permission = value),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF0F4FF)
              : const Color(0xFFF9FAFD),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? blue
                : const Color(0xFFE5EBF3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? blue : muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget shareCard(Map<String, dynamic> share) {
    final id = share['_id']?.toString() ?? '';
    final user = share['userId'];
    final current = share['permission'] == 'editor'
        ? 'editor'
        : 'viewer';

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE6EBF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE6EDFF),
                child: Text(
                  userName(user)[0].toUpperCase(),
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName(user),
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail(user),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                current == 'editor'
                    ? Icons.edit_outlined
                    : Icons.visibility_outlined,
                color: blue,
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('$id-$current'),
                  initialValue: current,
                  decoration: const InputDecoration(
                    labelText: 'Quyền truy cập',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Viewer - Chỉ xem'),
                    ),
                    DropdownMenuItem(
                      value: 'editor',
                      child: Text('Editor - Chỉnh sửa'),
                    ),
                  ],
                  onChanged: processing
                      ? null
                      : (value) {
                    if (value != null && value != current) {
                      changePermission(id, value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 9),
              IconButton(
                tooltip: 'Thu hồi quyền',
                onPressed:
                processing ? null : () => removeShare(id),
                icon: const Icon(
                  Icons.person_remove_outlined,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Quản lý chia sẻ'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loading ? null : loadShares,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(23),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF315CEB),
                          Color(0xFF6790F8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 35,
                        ),
                        SizedBox(height: 13),
                        Text(
                          'Chia sẻ và phân quyền',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Mời người khác tham gia công việc '
                              'và lựa chọn quyền xem hoặc chỉnh sửa.',
                          style: TextStyle(
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(19),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Thêm người được chia sẻ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: emailController,
                            keyboardType:
                            TextInputType.emailAddress,
                            onChanged: (_) {
                              setState(() {
                                foundUser = null;
                                searchMessage = null;
                              });
                            },
                            onSubmitted: (_) => searchUser(),
                            decoration: const InputDecoration(
                              labelText: 'Email người nhận',
                              hintText: 'example@gmail.com',
                              prefixIcon:
                              Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 11),
                          OutlinedButton.icon(
                            onPressed: searching ? null : searchUser,
                            icon: searching
                                ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.search),
                            label: const Text('Tìm tài khoản'),
                          ),
                          if (searchMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              searchMessage!,
                              style: const TextStyle(color: muted),
                            ),
                          ],
                          if (foundUser != null) ...[
                            const SizedBox(height: 13),
                            Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName(foundUser),
                                    style: const TextStyle(
                                      color: navy,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userEmail(foundUser),
                                    style: const TextStyle(
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const Text(
                            'Chọn quyền truy cập',
                            style: TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 11),
                          permissionOption(
                            'viewer',
                            'Viewer - Chỉ xem',
                            'Có thể xem nội dung và tiến độ, '
                                'không được chỉnh sửa.',
                            Icons.visibility_outlined,
                          ),
                          const SizedBox(height: 10),
                          permissionOption(
                            'editor',
                            'Editor - Được chỉnh sửa',
                            'Có thể chỉnh sửa công việc; '
                                'không mặc nhiên được xóa hoặc chia sẻ.',
                            Icons.edit_outlined,
                          ),
                          const SizedBox(height: 19),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: saving || foundUser == null
                                  ? null
                                  : addShares,
                              style: FilledButton.styleFrom(
                                backgroundColor: blue,
                              ),
                              icon: saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.person_add_alt_1,
                              ),
                              label: Text(
                                saving
                                    ? 'Đang chia sẻ...'
                                    : 'Xác nhận chia sẻ',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(19),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Danh sách được chia sẻ (${shares.length})',
                            style: const TextStyle(
                              color: navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.all(25),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (shares.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'Chưa chia sẻ với ai',
                                  style: TextStyle(color: muted),
                                ),
                              ),
                            )
                          else
                            ...shares.whereType<Map>().map(
                                  (item) => shareCard(
                                Map<String, dynamic>.from(item),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

