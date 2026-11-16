import '../models/task_activity.dart';
import 'api_client.dart';

class TaskActivityService {
  const TaskActivityService();

  Future<List<TaskActivity>> getTaskActivities(String taskId) async {
    final id = taskId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Mã công việc không hợp lệ');
    }

    final response = await ApiClient.get('/api/tasks/$id/activities');

    final data = response['data'];

    if (data is! List) {
      throw const FormatException('Dữ liệu lịch sử hoạt động không hợp lệ');
    }

    return data.map((item) {
      if (item is! Map) {
        throw const FormatException('Một bản ghi lịch sử không hợp lệ');
      }

      return TaskActivity.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}
