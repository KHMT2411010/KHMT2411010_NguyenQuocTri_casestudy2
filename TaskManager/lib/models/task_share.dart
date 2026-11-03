import 'user.dart';

enum SharePermission {
  viewer,
  editor;

  String get value => name;

  String get label {
    switch (this) {
      case SharePermission.viewer:
        return 'Chỉ xem';
      case SharePermission.editor:
        return 'Được chỉnh sửa';
    }
  }

  static SharePermission fromValue(dynamic value) {
    if (value?.toString() == 'editor') {
      return SharePermission.editor;
    }

    return SharePermission.viewer;
  }
}

class TaskShare {
  final String id;
  final String taskId;
  final String userId;
  final AppUser? user;
  final SharePermission permission;
  final String? sharedById;
  final DateTime? createdAt;

  const TaskShare({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.permission,
    this.user,
    this.sharedById,
    this.createdAt,
  });

  static String _getId(dynamic value) {
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }

    return value?.toString() ?? '';
  }

  factory TaskShare.fromJson(Map<String, dynamic> json) {
    final rawUser = json['userId'];

    return TaskShare(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      taskId: _getId(json['taskId']),
      userId: _getId(rawUser),

      user: rawUser is Map
          ? AppUser.fromJson(Map<String, dynamic>.from(rawUser))
          : null,

      permission: SharePermission.fromValue(json['permission']),

      sharedById: json['sharedBy'] == null ? null : _getId(json['sharedBy']),

      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  bool get canView => true;

  bool get canEdit => permission == SharePermission.editor;

  String get displayName => user?.displayName ?? 'Người dùng';

  String get email => user?.email ?? '';

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'taskId': taskId,
      'userId': userId,
      'permission': permission.value,
      'sharedBy': sharedById,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
