import 'package:flutter/material.dart';

import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class AssignmentScreen extends StatefulWidget {
  final String taskId;

  const AssignmentScreen({super.key, required this.taskId});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final UserService _userService = const UserService();
  final TaskService _taskService = const TaskService();

  final emailController = TextEditingController();

  final List<Map<String, dynamic>> selectedUsers = [];
  final Set<String> initialAssignedIds = {};

  Map<String, dynamic>? foundUser;
  String? primaryId;
  String? searchMessage;

  bool loadingAssignees = true;
  String? assigneesLoadError;

  bool searching = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadExistingAssignees();
  }

  Future<void> loadExistingAssignees() async {
    try {
      final assignees = await _taskService.getAssignees(widget.taskId);
      final task = await _taskService.getTaskById(widget.taskId);

      if (!mounted) return;

      final primary = task['primaryAssigneeId'];

      String? loadedPrimaryId;

      if (primary is Map) {
        loadedPrimaryId = (primary['_id'] ?? primary['id'])?.toString();
      } else if (primary != null) {
        loadedPrimaryId = primary.toString();
      }

      setState(() {
        initialAssignedIds
          ..clear()
          ..addAll(assignees.map(userId));

        selectedUsers
          ..clear()
          ..addAll(assignees);

        primaryId = assignees.any((user) => userId(user) == loadedPrimaryId)
            ? loadedPrimaryId
            : null;

        loadingAssignees = false;
        assigneesLoadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingAssignees = false;
        assigneesLoadError =
            'Không thể tải danh sách người được phân công: $error';
      });
    }
  }

  @override
  void dispose() {
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

  String userName(Map<String, dynamic> user) {
    return UserService.getName(user);
  }

  String userEmail(Map<String, dynamic> user) {
    return user['email']?.toString() ?? '';
  }

  Future<void> searchUser() async {
    if (searching || saving) return;

    final email = emailController.text.trim();

    final validationError = AppValidators.email(email);

    if (validationError != null) {
      showMessage(validationError, error: true);
      return;
    }

    setState(() {
      searching = true;
      foundUser = null;
      searchMessage = null;
    });

    try {
      final result = await _userService.findByEmail(email);

      if (!mounted) return;

      setState(() {
        foundUser = result;
        searchMessage = result == null
            ? 'Không tìm thấy tài khoản có email này.'
            : null;
      });
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => searching = false);
      }
    }
  }

  void addUser() {
    final user = foundUser;
    if (user == null || saving) return;

    final id = userId(user);

    if (id.isEmpty) {
      showMessage('Không tìm thấy mã tài khoản hợp lệ', error: true);
      return;
    }

    final alreadySelected = selectedUsers.any((item) => userId(item) == id);

    if (alreadySelected) {
      showMessage('Thành viên này đã có trong danh sách', error: true);
      return;
    }

    setState(() {
      selectedUsers.add(user);

      primaryId ??= id;

      foundUser = null;
      searchMessage = null;
      emailController.clear();
    });

    showMessage('Đã thêm thành viên');
  }

  void removeUser(String id) {
    if (saving) return;

    setState(() {
      selectedUsers.removeWhere((user) => userId(user) == id);

      if (primaryId == id) {
        primaryId = selectedUsers.isEmpty ? null : userId(selectedUsers.first);
      }
    });
  }

  Future<void> saveAssignment() async {
    if (saving) return;

    if (selectedUsers.isEmpty) {
      showMessage('Vui lòng chọn ít nhất một người thực hiện', error: true);
      return;
    }

    final ids = selectedUsers.map(userId).toList();

    if (primaryId == null || !ids.contains(primaryId)) {
      showMessage('Vui lòng chọn người phụ trách chính', error: true);
      return;
    }

    final removedIds = initialAssignedIds.difference(ids.toSet()).toList();

    setState(() => saving = true);

    try {
      await _taskService.assignTask(
        taskId: widget.taskId,
        userIds: ids,
        primaryAssigneeId: primaryId!,
      );

      for (final removedId in removedIds) {
        await _taskService.removeAssignee(widget.taskId, removedId);
      }

      if (!mounted) return;

      showMessage('Giao công việc thành công');
      Navigator.pop(context, true);
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.groups_2_outlined, color: Colors.white, size: 35),
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
            'Tìm tài khoản bằng email, chọn nhiều người '
            'thực hiện và chỉ định người phụ trách chính.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget buildSection({
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
            blurRadius: 15,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
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

  Widget buildUserPreview() {
    final user = foundUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFDCE6FF),
                child: Text(
                  userName(user).isNotEmpty
                      ? userName(user)[0].toUpperCase()
                      : '?',
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
                      userName(user),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail(user),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 13),
          FilledButton.tonalIcon(
            onPressed: saving ? null : addUser,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Thêm vào danh sách'),
          ),
        ],
      ),
    );
  }

  Widget buildSelectedUser(Map<String, dynamic> user) {
    final id = userId(user);
    final isPrimary = primaryId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFF0F4FF) : const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isPrimary ? const Color(0xFF9CB5FF) : AppColors.border,
          width: isPrimary ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE4ECFF),
                child: Text(
                  userName(user).isNotEmpty
                      ? userName(user)[0].toUpperCase()
                      : '?',
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
                      userName(user),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Bỏ chọn thành viên',
                onPressed: saving ? null : () => removeUser(id),
                icon: const Icon(Icons.close_rounded, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 7),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: saving ? null : () => setState(() => primaryId = id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: Row(
                children: [
                  Icon(
                    isPrimary ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isPrimary ? AppColors.warning : AppColors.muted,
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      isPrimary
                          ? 'Người phụ trách chính'
                          : 'Chọn làm người phụ trách chính',
                      style: TextStyle(
                        color: isPrimary ? AppColors.primary : AppColors.navy,
                        fontSize: 13,
                        fontWeight: isPrimary
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isPrimary)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                ],
              ),
            ),
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
          'Giao công việc',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
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
                      buildHeader(),
                      const SizedBox(height: 17),
                      buildSection(
                        title: 'Tìm thành viên',
                        icon: Icons.person_search_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Nhập email của tài khoản đã đăng ký.',
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
                                        height: 18,
                                        width: 18,
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
                            if (foundUser != null) ...[
                              const SizedBox(height: 15),
                              buildUserPreview(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildSection(
                        title: 'Danh sách thực hiện (${selectedUsers.length})',
                        icon: Icons.groups_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Một người sẽ được chỉ định '
                              'là phụ trách chính.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (loadingAssignees)
                              const Center(child: CircularProgressIndicator())
                            else if (assigneesLoadError != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assigneesLoadError!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        loadingAssignees = true;
                                        assigneesLoadError = null;
                                      });
                                      loadExistingAssignees();
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Thử lại'),
                                  ),
                                ],
                              )
                            else if (selectedUsers.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(23),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFD),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.group_add_outlined,
                                      size: 37,
                                      color: AppColors.muted,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Chưa có thành viên được chọn',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...selectedUsers.map(buildSelectedUser),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed:
                              (saving ||
                                  loadingAssignees ||
                                  assigneesLoadError != null)
                              ? null
                              : saveAssignment,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: saving
                              ? const SizedBox(
                                  height: 19,
                                  width: 19,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            saving ? 'Đang giao việc...' : 'Xác nhận giao việc',
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
}
