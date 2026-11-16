import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final String endpoint;

  const NotificationService({this.endpoint = '/api/notifications'});

  bool get isConfigured => endpoint.startsWith('/api/');

  Future<List<AppNotification>> getNotifications() async {
    final response = await ApiClient.get(endpoint);
    final raw = response['data'];

    if (raw is! List) {
      throw const FormatException('Du lieu thong bao khong dung dinh dang');
    }

    return raw
        .map(
          (item) =>
              AppNotification.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await ApiClient.get('$endpoint/unread-count');
    final raw = response['data'];

    if (raw is! Map || raw['unreadCount'] is! num) {
      throw const FormatException('Du lieu so thong bao chua doc khong hop le');
    }

    return (raw['unreadCount'] as num).toInt();
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) {
      throw ArgumentError('Notification ID is required');
    }

    final response = await ApiClient.patch(
      '$endpoint/${Uri.encodeComponent(notificationId)}/read',
      <String, dynamic>{},
    );

    if (response['success'] != true) {
      throw Exception('Khong the danh dau thong bao da doc');
    }
  }

  Future<int> markAllAsRead() async {
    final response = await ApiClient.patch(
      '$endpoint/read-all',
      <String, dynamic>{},
    );

    if (response['success'] != true) {
      throw Exception('Khong the danh dau tat ca thong bao da doc');
    }

    final raw = response['data'];

    if (raw is! Map || raw['modifiedCount'] is! num) {
      throw const FormatException('Du lieu ket qua cap nhat khong hop le');
    }

    return (raw['modifiedCount'] as num).toInt();
  }
}

class NotificationApiNotConfigured implements Exception {
  const NotificationApiNotConfigured();

  @override
  String toString() => 'Chua cau hinh API thong bao';
}
