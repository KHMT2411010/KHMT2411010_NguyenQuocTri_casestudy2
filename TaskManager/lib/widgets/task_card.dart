import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = task['title']?.toString() ?? 'Không có tên công việc';

    final description = task['description']?.toString() ?? '';

    final status = task['status']?.toString() ?? 'todo';
    final priority = task['priority']?.toString() ?? 'medium';
    final myRole = task['myRole']?.toString();

    String? roleLabel;
    Color roleColor = AppColors.primary;

    switch (myRole) {
      case 'owner':
        roleLabel = 'Owner';
        roleColor = const Color(0xFF2563EB);
        break;
      case 'assignee':
        roleLabel = 'Assignee';
        roleColor = const Color(0xFF15803D);
        break;
      case 'editor':
        roleLabel = 'Editor';
        roleColor = const Color(0xFF7C3AED);
        break;
      case 'viewer':
        roleLabel = 'Viewer';
        roleColor = const Color(0xFF64748B);
        break;
    }

    final color = TaskValues.statusColor(status);

    final dueDate = AppDateFormatter.format(
      task['dueDate'],
      fallback: 'Chưa đặt hạn',
    );

    final overdue =
        status != 'completed' && AppDateFormatter.isOverdue(task['dueDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 47,
                      height: 47,
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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 15),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(status: status),
                    PriorityBadge(priority: priority),

                    if (roleLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: roleColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              roleLabel,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 15),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Icon(
                      overdue
                          ? Icons.warning_amber_rounded
                          : Icons.event_outlined,
                      size: 18,
                      color: overdue ? AppColors.danger : AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        overdue
                            ? 'Quá hạn: $dueDate'
                            : 'Hạn hoàn thành: $dueDate',
                        style: TextStyle(
                          color: overdue ? AppColors.danger : AppColors.muted,
                          fontSize: 12,
                          fontWeight: overdue
                              ? FontWeight.w700
                              : FontWeight.w500,
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
