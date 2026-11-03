import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final String? endpoint;

  const NotificationService({this.endpoint});

  bool get isConfigured => endpoint != null && endpoint!.startsWith('/api/');

  Future<List<AppNotification>> getNotifications() async {
    if (!isConfigured) {
      throw const NotificationApiNotConfigured();
    }

    final response = await ApiClient.get(endpoint!);
    final raw = response['data'];

    final List<dynamic> items;

    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw['notifications'] is List) {
      items = raw['notifications'] as List;
    } else {
      throw const FormatException('Dữ liệu thông báo không đúng định dạng');
    }

    return items
        .map(
          (item) =>
              AppNotification.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}

class NotificationApiNotConfigured implements Exception {
  const NotificationApiNotConfigured();

  @override
  String toString() => 'Chưa xác nhận API thông báo của backend';
}
