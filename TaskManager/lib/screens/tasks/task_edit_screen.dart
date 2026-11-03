import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../utils/constants.dart';
import 'task_create_screen.dart';

class TaskEditScreen extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskEditScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskId = (task['_id'] ?? task['id'])?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: const Text(
          'Chỉnh sửa công việc',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: TaskEditorFields(
        heading: 'Cập nhật công việc',
        description: 'Điều chỉnh nội dung, mức độ ưu tiên và thời hạn.',
        buttonText: 'Lưu thay đổi',
        initialTask: task,
        onSave: (payload) async {
          if (taskId == null || taskId.isEmpty) {
            throw Exception('Không tìm thấy mã công việc');
          }

          await ApiClient.put('/api/tasks/$taskId', payload);
        },
      ),
    );
  }
}
