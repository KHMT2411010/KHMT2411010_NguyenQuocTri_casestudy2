class AppNotification {
  final String id;
  final String title;
  final String message;
  final String? type;
  final String? taskId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.taskId,
    this.isRead = false,
    this.createdAt,
  });

  static String? _idOf(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return (value['_id'] ?? value['id'])?.toString();
    }

    return value.toString();
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: json['type']?.toString(),
      taskId: _idOf(json['taskId']),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'message': message,
      'type': type,
      'taskId': taskId,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
