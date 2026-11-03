import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> register() async {
    if (loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => loading = true);

    try {
      await ApiClient.post('/api/auth/register', {
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      if (!mounted) return;

      // Quay lại màn hình đăng nhập.
      // LoginScreen sẽ hiển thị thông báo thành công.
      Navigator.pop(context, true);
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 37,
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'TaskFlow',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Bắt đầu hành trình làm việc hiệu quả',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ],
    );
  }

  Widget buildRegisterForm() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080E214A),
            blurRadius: 23,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tạo tài khoản',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Điền thông tin để tham gia TaskFlow.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 23),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  AppValidators.requiredText(value, fieldName: 'họ và tên'),
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: Color(0xFFF8FAFF),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: 15),
            TextFormField(
              controller: passwordController,
              obscureText: !showPassword,
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: 15),
            TextFormField(
              controller: confirmController,
              obscureText: !showConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => register(),
              validator: (value) =>
                  AppValidators.confirmPassword(value, passwordController.text),
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                prefixIcon: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                suffixIcon: IconButton(
                  tooltip: showConfirmPassword
                      ? 'Ẩn mật khẩu'
                      : 'Hiện mật khẩu',
                  onPressed: () {
                    setState(() {
                      showConfirmPassword = !showConfirmPassword;
                    });
                  },
                  icon: Icon(
                    showConfirmPassword
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
                onPressed: loading ? null : register,
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_rounded),
                label: Text(
                  loading ? 'Đang đăng ký...' : 'Tạo tài khoản',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 13),
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context, false),
              child: const Text(
                'Đã có tài khoản? Đăng nhập',
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Đăng ký'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(),
                  const SizedBox(height: 25),
                  buildRegisterForm(),
                  const SizedBox(height: 23),
                  const Text(
                    'Quản lý công việc an toàn và hiệu quả',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
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
