
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

  static const primary = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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

      if (mounted) setState(() {});
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

  Widget sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool password = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: password,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE4EAF2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE4EAF2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF315CEB),
                        Color(0xFF5987FA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                          color: Color(0x33FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameController.text.isEmpty
                                  ? 'Người dùng'
                                  : nameController.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              emailController.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                sectionCard(
                  icon: Icons.badge_outlined,
                  title: 'Thông tin cá nhân',
                  subtitle:
                  'Quản lý tên và email sử dụng trong ứng dụng.',
                  children: [
                    field(
                      controller: nameController,
                      label: 'Họ và tên',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    field(
                      controller: emailController,
                      label: 'Địa chỉ email',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: saving ? null : saveProfile,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          saving
                              ? 'Đang xử lý...'
                              : 'Lưu thông tin',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                sectionCard(
                  icon: Icons.shield_outlined,
                  title: 'Bảo mật tài khoản',
                  subtitle:
                  'Thay đổi mật khẩu để bảo vệ tài khoản.',
                  children: [
                    field(
                      controller: currentPasswordController,
                      label: 'Mật khẩu hiện tại',
                      icon: Icons.lock_outline,
                      password: true,
                    ),
                    const SizedBox(height: 14),
                    field(
                      controller: newPasswordController,
                      label: 'Mật khẩu mới',
                      icon: Icons.key_outlined,
                      password: true,
                    ),
                    const SizedBox(height: 14),
                    field(
                      controller: confirmPasswordController,
                      label: 'Xác nhận mật khẩu mới',
                      icon: Icons.verified_user_outlined,
                      password: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: FilledButton.tonalIcon(
                        onPressed: saving ? null : changePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Đổi mật khẩu'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
}
