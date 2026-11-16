import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/task_share_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';

class SharingScreen extends StatefulWidget {
  final String taskId;

  const SharingScreen({super.key, required this.taskId});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final UserService _userService = const UserService();
  final TaskShareService _shareService = const TaskShareService();

  final emailController = TextEditingController();

  List<Map<String, dynamic>> shares = [];
  Map<String, dynamic>? foundUser;
  final List<Map<String, dynamic>> searchResults = [];
  Timer? _searchTimer;
  int _searchGeneration = 0;

  String permission = 'viewer';
  String? searchMessage;

  bool loading = true;
  String? sharesLoadError;
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
    _searchTimer?.cancel();
    _searchGeneration++;
    emailController.dispose();
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

  String userId(Map<String, dynamic> user) {
    return UserService.getId(user);
  }

  String userName(dynamic user) {
    if (user is Map) {
      return (user['fullName'] ?? user['email'] ?? 'Người dùng').toString();
    }

    return 'Người dùng';
  }

  String userEmail(dynamic user) {
    if (user is Map) {
      return user['email']?.toString() ?? '';
    }

    return '';
  }

  Future<void> loadShares() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      sharesLoadError = null;
    });

    try {
      final result = await _shareService.getShares(widget.taskId);

      if (!mounted) return;

      setState(() {
        shares = result;
        sharesLoadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      setState(() {
        sharesLoadError = message;
      });

      showMessage(message, error: true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchGeneration++;

    final keyword = value.trim();

    setState(() {
      foundUser = null;
      searchResults.clear();
      searchMessage = null;
      searching = false;
    });

    if (keyword.length < 2 || saving || processing) return;

    _searchTimer = Timer(const Duration(milliseconds: 350), () => searchUser());
  }

  Future<void> searchUser() async {
    if (saving || processing) return;

    _searchTimer?.cancel();

    final keyword = emailController.text.trim();
    final generation = ++_searchGeneration;

    if (keyword.length < 2) {
      setState(() {
        searching = false;
        foundUser = null;
        searchResults.clear();
        searchMessage = 'Vui lòng nhập ít nhất 2 ký tự.';
      });
      return;
    }

    setState(() {
      searching = true;
      foundUser = null;
      searchResults.clear();
      searchMessage = null;
    });

    try {
      final users = await _userService.searchUsers(keyword);

      if (!mounted || generation != _searchGeneration) return;
      if (emailController.text.trim() != keyword) return;

      setState(() {
        searchResults.addAll(users);
        searchMessage = users.isEmpty
            ? 'Không tìm thấy tài khoản phù hợp.'
            : null;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;

      setState(() {
        searchResults.clear();
        searchMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => searching = false);
      }
    }
  }

  void selectSearchUser(Map<String, dynamic> user) {
    if (saving || processing) return;

    final id = userId(user);
    final email = userEmail(user).trim();

    if (id.isEmpty || email.isEmpty) {
      showMessage('Tài khoản không hợp lệ', error: true);
      return;
    }

    _searchTimer?.cancel();
    _searchGeneration++;

    emailController.text = email;

    setState(() {
      foundUser = user;
      searchResults.clear();
      searchMessage = null;
      searching = false;
    });
  }

  Future<void> addShare() async {
    if (saving || foundUser == null) return;

    final enteredEmail = emailController.text.trim().toLowerCase();
    final selectedEmail = userEmail(foundUser!).trim().toLowerCase();

    if (enteredEmail != selectedEmail) {
      showMessage(
        'Email đã thay đổi. Vui lòng tìm lại tài khoản trước khi chia sẻ.',
        error: true,
      );
      return;
    }

    final id = userId(foundUser!);

    if (id.isEmpty) {
      showMessage('Tài khoản không có mã người dùng hợp lệ', error: true);
      return;
    }

    final alreadyShared = shares.any((share) {
      final user = share['userId'];

      final existingId = user is Map
          ? (user['_id'] ?? user['id'])?.toString()
          : user?.toString();

      return existingId == id;
    });

    if (alreadyShared) {
      showMessage(
        'Người này đã được chia sẻ. '
        'Bạn có thể thay đổi quyền ở danh sách bên dưới.',
        error: true,
      );
      return;
    }

    setState(() => saving = true);

    try {
      await _shareService.addShares(
        taskId: widget.taskId,
        userIds: [id],
        permission: permission,
      );

      if (!mounted) return;

      emailController.clear();

      setState(() {
        foundUser = null;
        searchMessage = null;
        permission = 'viewer';
      });

      showMessage('Chia sẻ công việc thành công');
      await loadShares();
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> changePermission(String shareId, String value) async {
    if (processing) return;

    setState(() => processing = true);

    try {
      await _shareService.changePermission(
        taskId: widget.taskId,
        shareId: shareId,
        permission: value,
      );

      if (!mounted) return;

      showMessage('Đã cập nhật quyền truy cập');
      await loadShares();
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> removeShare(String shareId) async {
    if (processing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Thu hồi quyền chia sẻ?'),
        content: const Text(
          'Người này sẽ mất quyền truy cập thông qua '
          'chia sẻ. Nếu họ đồng thời được giao việc, '
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

    if (confirmed != true || !mounted) return;

    setState(() => processing = true);

    try {
      await _shareService.removeShare(taskId: widget.taskId, shareId: shareId);

      if (!mounted) return;

      showMessage('Đã thu hồi quyền chia sẻ');
      await loadShares();
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Widget section({
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
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
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

  Widget permissionOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = permission == value;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: saving ? null : () => setState(() => permission = value),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F4FF) : const Color(0xFFF9FAFD),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: searchResults.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = searchResults[index];
          final name = userName(user);
          final email = userEmail(user);

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF0FF),
              child: Icon(Icons.person_outline, color: AppColors.primary),
            ),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
            ),
            onTap: () => selectSearchUser(user),
          );
        },
      ),
    );
  }

  Widget foundUserCard() {
    final user = foundUser;
    if (user == null) return const SizedBox.shrink();

    final name = userName(user);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFDDE7FF),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail(user),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppColors.success),
        ],
      ),
    );
  }

  Widget shareCard(Map<String, dynamic> share) {
    final id = (share['_id'] ?? share['id'] ?? '').toString();
    final user = share['userId'];
    final name = userName(user);
    final email = userEmail(user);
    final currentPermission = share['permission']?.toString() == 'editor'
        ? 'editor'
        : 'viewer';

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE4ECFF),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty ? 'Thông tin email chưa có' : email,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                currentPermission == 'editor'
                    ? Icons.edit_outlined
                    : Icons.visibility_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('$id-$currentPermission'),
                  initialValue: currentPermission,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Quyền truy cập',
                    isDense: true,
                    prefixIcon: Icon(Icons.shield_outlined),
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
                  onChanged: processing || id.isEmpty
                      ? null
                      : (value) {
                          if (value != null && value != currentPermission) {
                            changePermission(id, value);
                          }
                        },
                ),
              ),
              const SizedBox(width: 7),
              IconButton(
                tooltip: 'Thu hồi quyền chia sẻ',
                onPressed: processing || id.isEmpty
                    ? null
                    : () => removeShare(id),
                icon: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.danger,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: const Text(
          'Quản lý chia sẻ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới danh sách',
            onPressed: loading || processing ? null : loadShares,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxWidth < 600;

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 24,
              18,
              compact ? 14 : 24,
              36,
            ),
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
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            SizedBox(height: 8),
                            Text(
                              'Cho phép người khác xem hoặc '
                              'chỉnh sửa công việc theo quyền '
                              'bạn lựa chọn.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 17),
                      section(
                        title: 'Thêm người được chia sẻ',
                        icon: Icons.person_add_alt_1_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Nhập từ 2 ký tự tên hoặc email để xem danh sách gợi ý.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.search,
                              onChanged: _onSearchChanged,
                              onSubmitted: (_) => searchUser(),
                              decoration: const InputDecoration(
                                labelText: 'Tên hoặc email người nhận',
                                hintText: 'Nhập tên hoặc email...',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: searching || saving
                                    ? null
                                    : searchUser,
                                icon: searching
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.search_rounded),
                                label: Text(
                                  searching ? 'Đang tìm...' : 'Tìm tài khoản',
                                ),
                              ),
                            ),
                            if (searchMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                searchMessage!,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ],
                            if (searchResults.isNotEmpty &&
                                foundUser == null) ...[
                              const SizedBox(height: 12),
                              buildSearchSuggestions(),
                            ],
                            if (foundUser != null) ...[
                              const SizedBox(height: 15),
                              foundUserCard(),
                            ],
                            const SizedBox(height: 21),
                            const Text(
                              'Quyền truy cập',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            permissionOption(
                              value: 'viewer',
                              title: 'Viewer – Chỉ xem',
                              description:
                                  'Được theo dõi nội dung và '
                                  'tiến độ, không được sửa.',
                              icon: Icons.visibility_outlined,
                            ),
                            const SizedBox(height: 10),
                            permissionOption(
                              value: 'editor',
                              title: 'Editor – Chỉnh sửa',
                              description:
                                  'Được chỉnh sửa trong phạm vi '
                                  'backend cho phép; không tự '
                                  'động có quyền xóa hoặc chia sẻ.',
                              icon: Icons.edit_outlined,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: FilledButton.icon(
                                onPressed:
                                    saving || processing || foundUser == null
                                    ? null
                                    : addShare,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                icon: saving
                                    ? const SizedBox(
                                        width: 19,
                                        height: 19,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.person_add_rounded),
                                label: Text(
                                  saving
                                      ? 'Đang chia sẻ...'
                                      : 'Xác nhận chia sẻ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      section(
                        title: 'Danh sách đã chia sẻ (${shares.length})',
                        icon: Icons.groups_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (loading)
                              const Padding(
                                padding: EdgeInsets.all(25),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (sharesLoadError != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Không thể tải danh sách chia sẻ: $sharesLoadError',
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: loadShares,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Thử lại'),
                                  ),
                                ],
                              )
                            else if (shares.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 25),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_outline_rounded,
                                      color: AppColors.muted,
                                      size: 39,
                                    ),
                                    SizedBox(height: 11),
                                    Text(
                                      'Chưa chia sẻ với ai',
                                      style: TextStyle(color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...shares.map(shareCard),
                          ],
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
}
