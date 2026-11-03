
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

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email.text.trim())) {
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
            : {
          'email': email.text.trim(),
          'password': password.text,
        },
      );

      if (!mounted) return;

      if (register) {
        setState(() {
          register = false;
          password.clear();
          confirmPassword.clear();
        });

        showSuccess(
          context,
          'Đăng ký thành công! Hãy đăng nhập.',
        );
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
          tooltip: showPassword
              ? 'Ẩn mật khẩu'
              : 'Hiện mật khẩu',
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
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 28,
            ),
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
                          colors: [
                            Color(0xFF315CEB),
                            Color(0xFF6898FF),
                          ],
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
                    style: const TextStyle(
                      color: muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 27),
                  Container(
                    padding: const EdgeInsets.all(23),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFFE8EDF5),
                      ),
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
                          register
                              ? 'Tạo tài khoản'
                              : 'Chào mừng trở lại!',
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
                          style: const TextStyle(
                            color: muted,
                            fontSize: 13,
                          ),
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
                              mainAxisAlignment:
                              MainAxisAlignment.center,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 23),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: muted,
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Quản lý công việc an toàn và hiệu quả',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
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
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
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
    if (mounted) loadTasks();
  }

  Future<void> openDetail(Map<String, dynamic> task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          taskId: task['_id'].toString(),
        ),
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

  Widget metric(
      String title,
      int count,
      IconData icon,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
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
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
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
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: muted,
                    ),
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
                const Divider(
                  color: Color(0xFFEDF0F6),
                  height: 1,
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 17,
                      color: muted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Hạn hoàn thành: ${formatDate(task['dueDate'])}',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
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
      final description =
          item['description']?.toString().toLowerCase() ?? '';

      final keyword = query.trim().toLowerCase();

      return title.contains(keyword) ||
          description.contains(keyword);
    }).toList();

    final completed = tasks.where(
          (t) => t is Map && t['status'] == 'completed',
    ).length;

    final progress = tasks.where(
          (t) => t is Map && t['status'] == 'in_progress',
    ).length;

    final pending = tasks.length - completed - progress;

    final percentage = tasks.isEmpty
        ? 0.0
        : completed / tasks.length;

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
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
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
                  colors: [
                    Color(0xFF315CEB),
                    Color(0xFF6898FF),
                  ],
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
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
                      metric(
                        'Đang làm',
                        progress,
                        Icons.timelapse_rounded,
                      ),
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
              style: TextStyle(
                color: muted,
                fontSize: 13,
              ),
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
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(45),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (visibleTasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5EBF5),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      color: blue,
                      size: 48,
                    ),
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
                    (item) => taskCard(
                  Map<String, dynamic>.from(item as Map),
                ),
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
