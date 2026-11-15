import 'api_client.dart';

class TaskService {
  const TaskService();

  // B1 + B6: Lay danh sach va loc cong viec.
  Future<List<Map<String, dynamic>>> getTasks({
    String scope = 'all',
    String? status,
    String? priority,
  }) async {
    const validScopes = ['all', 'created', 'assigned', 'shared'];

    const validStatuses = ['todo', 'in_progress', 'completed'];

    const validPriorities = ['low', 'medium', 'high'];

    if (!validScopes.contains(scope)) {
      throw ArgumentError('Bộ lọc vai trò không hợp lệ');
    }

    if (status != null && !validStatuses.contains(status)) {
      throw ArgumentError('Trạng thái không hợp lệ');
    }

    if (priority != null && !validPriorities.contains(priority)) {
      throw ArgumentError('Mức độ ưu tiên không hợp lệ');
    }

    final params = <String, String>{};

    if (scope != 'all') {
      params['scope'] = scope;
    }

    if (status != null) {
      params['status'] = status;
    }

    if (priority != null) {
      params['priority'] = priority;
    }

    final query = Uri(queryParameters: params).query;

    final endpoint = query.isEmpty ? '/api/tasks' : '/api/tasks?$query';


    final response = await ApiClient.get(endpoint);
    final data = response['data'];


    if (data is! List) {
      throw const FormatException('Dữ liệu danh sách công việc không hợp lệ');
    }

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // Lấy chi tiết công việc.
  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    final response = await ApiClient.get('/api/tasks/$taskId');

    return Map<String, dynamic>.from(response['data'] as Map);
  }

  // Tạo công việc.
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/api/tasks', data);

    return Map<String, dynamic>.from(response['data'] as Map);
  }

  // Chỉnh sửa công việc.
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.put('/api/tasks/$taskId', data);

    return Map<String, dynamic>.from(response['data'] as Map);
  }

  // Cập nhật trạng thái.
  Future<void> updateStatus(String taskId, String status) async {
    const validStatuses = ['todo', 'in_progress', 'completed'];

    if (!validStatuses.contains(status)) {
      throw ArgumentError('Trạng thái công việc không hợp lệ');
    }

    await ApiClient.patch('/api/tasks/$taskId/status', {'status': status});
  }

  // Xóa công việc.
  Future<void> deleteTask(String taskId) async {
    await ApiClient.delete('/api/tasks/$taskId');
  }

  // Xem danh sách người được giao.
  Future<List<Map<String, dynamic>>> getAssignees(String taskId) async {
    final response = await ApiClient.get('/api/tasks/$taskId/assignees');

    final data = response['data'];

    if (data is! List) {
      throw const FormatException('Dữ liệu người được giao không hợp lệ');
    }

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // Giao việc cho nhiều người.
  Future<void> assignTask({
    required String taskId,
    required List<String> userIds,
    required String primaryAssigneeId,
  }) async {
    if (userIds.isEmpty) {
      throw ArgumentError('Phải chọn ít nhất một người');
    }

    if (!userIds.contains(primaryAssigneeId)) {
      throw ArgumentError(
        'Người phụ trách chính phải thuộc danh sách được giao',
      );
    }

    await ApiClient.post('/api/tasks/$taskId/assignees', {
      'userIds': userIds,
      'primaryAssigneeId': primaryAssigneeId,
    });
  }

  // Hủy giao việc.
  Future<void> removeAssignee(String taskId, String userId) async {
    await ApiClient.delete('/api/tasks/$taskId/assignees/$userId');
  }
}
