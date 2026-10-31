
import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadProfile() async {
    try {
      final response = await ApiClient.get('/api/auth/me');
      final user = Map<String, dynamic>.from(response['data']);

      nameController.text = user['fullName']?.toString() ?? '';
      emailController.text = user['email']?.toString() ?? '';
    } catch (e) {
      notify('Không tải được hồ sơ: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      notify('Vui lòng nhập họ tên và email');
      return;
    }

    setState(() => saving = true);

    try {
      await ApiClient.put('/api/auth/me', {
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
      });

      notify('Cập nhật hồ sơ thành công');
    } catch (e) {
      notify('Cập nhật thất bại: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> changePassword() async {
    if (newPasswordController.text.length < 8) {
      notify('Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }

    if (newPasswordController.text !=
        confirmPasswordController.text) {
      notify('Xác nhận mật khẩu không khớp');
      return;
    }

    setState(() => saving = true);

    try {
      await ApiClient.put('/api/auth/change-password', {
        'currentPassword': currentPasswordController.text,
        'newPassword': newPasswordController.text,
      });

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      notify('Đổi mật khẩu thành công');
    } catch (e) {
      notify('Đổi mật khẩu thất bại: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 42,
                  child: Icon(Icons.person, size: 46),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: saving ? null : saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu thông tin'),
                ),
                const Divider(height: 48),
                const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: saving ? null : changePassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Đổi mật khẩu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
