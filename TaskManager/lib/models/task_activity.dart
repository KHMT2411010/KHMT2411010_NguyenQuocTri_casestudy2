class TaskActivity {
  final String id;
  final String taskId;
  final String? userId;
  final String? actorName;
  final String? actorEmail;
  final String action;
  final String? description;
  final DateTime? createdAt;

  const TaskActivity({
    required this.id,
    required this.taskId,
    required this.action,
    this.userId,
    this.actorName,
    this.actorEmail,
    this.description,
    this.createdAt,
  });

  static String _readId(dynamic value) {
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }

    return value?.toString() ?? '';
  }

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    return TaskActivity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      taskId: _readId(json['taskId']),
      userId: json['userId'] == null ? null : _readId(json['userId']),
      actorName: json['userId'] is Map
          ? json['userId']['fullName']?.toString()
          : null,
      actorEmail: json['userId'] is Map
          ? json['userId']['email']?.toString()
          : null,
      action: (json['action'] ?? '').toString(),
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'taskId': taskId,
      'userId': userId,
      'actorName': actorName,
      'actorEmail': actorEmail,
      'action': action,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
