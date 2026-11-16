import 'package:flutter/material.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final NotificationService service;

  const NotificationScreen({
    super.key,
    this.service = const NotificationService(),
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> notifications = [];
  bool loading = true;
  bool busy = false;
  bool showUnreadOnly = false;
  String? error;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final items = await widget.service.getNotifications();
      final count = await widget.service.getUnreadCount();

      if (!mounted) return;

      setState(() {
        notifications = items;
        unreadCount = count;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showError(Object e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> markAllRead() async {
    if (busy || unreadCount == 0) return;

    setState(() => busy = true);

    try {
      await widget.service.markAllAsRead();
      await load();
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openNotification(AppNotification item) async {
    if (busy) return;

    setState(() => busy = true);

    try {
      if (!item.isRead) {
        await widget.service.markAsRead(item.id);
        await load();
      }

      if (!mounted) return;

      final taskId = item.taskId;
      if (taskId != null && taskId.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(taskId: taskId),
          ),
        );

        if (mounted) await load();
      }
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  IconData iconFor(String? type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind_rounded;
      case 'task_shared':
        return Icons.people_alt_rounded;
      case 'task_updated':
        return Icons.edit_note_rounded;
      case 'task_completed':
        return Icons.task_alt_rounded;
      case 'task_reminder':
        return Icons.alarm_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget notificationCard(AppNotification item) {
    final unread = !item.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      color: unread ? const Color(0xFFF0F5FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: unread ? const Color(0xFFC9D9FF) : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: busy ? null : () => openNotification(item),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unread
                      ? const Color(0xFFDDE8FF)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconFor(item.type),
                  color: unread ? AppColors.primary : AppColors.muted,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isEmpty ? 'Thông báo' : item.title,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppDateFormatter.formatDateTime(item.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    if (item.taskId != null && item.taskId!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem công việc',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget emptyView(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = showUnreadOnly
        ? notifications.where((item) => !item.isRead).toList()
        : notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo trong ứng dụng'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loading || busy ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? emptyView(error!, Icons.error_outline_rounded)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trung tâm thông báo',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            unreadCount == 0
                                ? 'Bạn đã xem hết thông báo mới.'
                                : 'Bạn có $unreadCount thông báo chưa đọc.',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Tất cả'),
                                selected: !showUnreadOnly,
                                onSelected: (_) {
                                  setState(() => showUnreadOnly = false);
                                },
                              ),
                              FilterChip(
                                label: const Text('Chưa đọc'),
                                selected: showUnreadOnly,
                                onSelected: (_) {
                                  setState(() => showUnreadOnly = true);
                                },
                              ),
                            ],
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: busy ? null : markAllRead,
                              icon: const Icon(Icons.done_all_rounded),
                              label: const Text('Đánh dấu tất cả đã đọc'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: load,
                    child: visible.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 280,
                                child: emptyView(
                                  showUnreadOnly
                                      ? 'Không có thông báo chưa đọc.'
                                      : 'Bạn chưa có thông báo nào.',
                                  Icons.notifications_none_rounded,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              return Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 780,
                                  ),
                                  child: notificationCard(visible[index]),
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
