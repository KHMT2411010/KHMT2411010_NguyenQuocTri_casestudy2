import 'api_client.dart';

class AuthService {
  const AuthService();

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await ApiClient.post('/api/auth/register', {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  Future<void> login({required String email, required String password}) async {
    final response = await ApiClient.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    final token = response['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const FormatException('Không nhận được token đăng nhập');
    }

    await ApiClient.saveToken(token);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiClient.get('/api/auth/me');
    final raw = response['data'];

    if (raw is! Map) {
      throw const FormatException('Thông tin tài khoản không hợp lệ');
    }

    return Map<String, dynamic>.from(raw);
  }

  Future<bool> hasValidSession() async {
    final token = await ApiClient.getToken();

    if (token == null || token.isEmpty) return false;

    try {
      await getProfile();
      return true;
    } catch (_) {
      await ApiClient.clearToken();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
  }
}
