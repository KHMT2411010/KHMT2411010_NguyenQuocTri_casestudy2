
import 'api_client.dart';

class UserService {
  const UserService();

  Future<List<Map<String, dynamic>>> searchUsers(
      String keyword,
      ) async {
    final q = keyword.trim();

    if (q.isEmpty) return [];

    final response = await ApiClient.get(
      '/api/users/search?q=${Uri.encodeQueryComponent(q)}',
    );

    final raw = response['data'];

    List<dynamic> users = [];

    if (raw is List) {
      users = raw;
    } else if (raw is Map && raw['users'] is List) {
      users = raw['users'] as List;
    }

    return users
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Tìm chính xác tài khoản theo email.
  Future<Map<String, dynamic>?> findByEmail(
      String email,
      ) async {
    final normalized = email.trim().toLowerCase();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(normalized)) {
      throw ArgumentError('Email không hợp lệ');
    }

    final users = await searchUsers(normalized);

    for (final user in users) {
      final candidate =
      user['email']?.toString().trim().toLowerCase();

      if (candidate == normalized) {
        return user;
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> getUserById(
      String userId,
      ) async {
    final response = await ApiClient.get('/api/users/$userId');

    return Map<String, dynamic>.from(response['data'] as Map);
  }

  static String getId(Map<String, dynamic> user) {
    return (user['_id'] ?? user['id'] ?? '').toString();
  }

  static String getName(Map<String, dynamic> user) {
    return user['fullName']?.toString() ??
        user['email']?.toString() ??
        'Người dùng';
  }
}
