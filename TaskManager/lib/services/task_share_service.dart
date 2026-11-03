import 'api_client.dart';

class TaskShareService {
  const TaskShareService();

  Future<List<Map<String, dynamic>>> getShares(String taskId) async {
    final response = await ApiClient.get('/api/tasks/$taskId/shares');

    final data = response['data'];

    if (data is! List) {
      throw const FormatException('Dữ liệu chia sẻ không hợp lệ');
    }

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> addShares({
    required String taskId,
    required List<String> userIds,
    required String permission,
  }) async {
    if (userIds.isEmpty) {
      throw ArgumentError('Phải chọn ít nhất một người được chia sẻ');
    }

    if (!['viewer', 'editor'].contains(permission)) {
      throw ArgumentError('Quyền chia sẻ không hợp lệ');
    }

    await ApiClient.post('/api/tasks/$taskId/shares', {
      'userIds': userIds,
      'permission': permission,
    });
  }

  Future<void> changePermission({
    required String taskId,
    required String shareId,
    required String permission,
  }) async {
    if (!['viewer', 'editor'].contains(permission)) {
      throw ArgumentError('Quyền chia sẻ không hợp lệ');
    }

    await ApiClient.patch('/api/tasks/$taskId/shares/$shareId', {
      'permission': permission,
    });
  }

  Future<void> removeShare({
    required String taskId,
    required String shareId,
  }) async {
    await ApiClient.delete('/api/tasks/$taskId/shares/$shareId');
  }
}
