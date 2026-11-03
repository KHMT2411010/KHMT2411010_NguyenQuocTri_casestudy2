import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../tasks/task_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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

  Future<void> login() async {
    if (loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => loading = true);

    try {
      final response = await ApiClient.post('/api/auth/login', {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      final token = response['token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Không nhận được token đăng nhập');
      }

      await ApiClient.saveToken(token);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
        (_) => false,
      );
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openRegister() async {
    if (loading) return;

    final registered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );

    if (!mounted) return;

    if (registered == true) {
      passwordController.clear();
      showMessage('Đăng ký thành công! Hãy đăng nhập.');
    }
  }

  Widget buildHeader() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
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
        const SizedBox(height: 18),
        const Text(
          'TaskFlow',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Sắp xếp công việc, kết nối đội nhóm',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ],
    );
  }

  Widget buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080E214A),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chào mừng trở lại!',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đăng nhập để tiếp tục công việc.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AppValidators.email,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ email',
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: Color(0xFFF8FAFF),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: !showPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => login(),
              validator: (value) =>
                  AppValidators.requiredText(value, fieldName: 'mật khẩu'),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                suffixIcon: IconButton(
                  tooltip: showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: loading ? null : login,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(
                  loading ? 'Đang đăng nhập...' : 'Đăng nhập',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 13),
            TextButton(
              onPressed: loading ? null : openRegister,
              child: const Text(
                'Chưa có tài khoản? Đăng ký ngay',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(),
                  const SizedBox(height: 27),
                  buildLoginForm(),
                  const SizedBox(height: 23),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.muted,
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Quản lý công việc an toàn và hiệu quả',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
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
