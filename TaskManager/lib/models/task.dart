import 'user.dart';

class AppTask {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;

  final DateTime? startDate;
  final DateTime? dueDate;

  final String? createdById;
  final AppUser? creator;

  final List<String> assigneeIds;
  final List<AppUser> assignees;

  final String? primaryAssigneeId;
  final AppUser? primaryAssignee;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.startDate,
    this.dueDate,
    this.createdById,
    this.creator,
    this.assigneeIds = const [],
    this.assignees = const [],
    this.primaryAssigneeId,
    this.primaryAssignee,
    this.createdAt,
    this.updatedAt,
  });

  static String? _readId(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final id = value['_id'] ?? value['id'];
      return id?.toString();
    }

    return value.toString();
  }

  static AppUser? _readUser(dynamic value) {
    if (value is Map) {
      return AppUser.fromJson(Map<String, dynamic>.from(value));
    }

    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory AppTask.fromJson(Map<String, dynamic> json) {
    final rawAssignees = json['assigneeIds'];

    final members = rawAssignees is List ? rawAssignees : <dynamic>[];

    final creatorData = json['createdBy'];
    final primaryData = json['primaryAssigneeId'];

    return AppTask(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'todo').toString(),
      priority: (json['priority'] ?? 'medium').toString(),

      startDate: _readDate(json['startDate']),
      dueDate: _readDate(json['dueDate']),

      createdById: _readId(creatorData),
      creator: _readUser(creatorData),

      assigneeIds: members.map(_readId).whereType<String>().toList(),

      assignees: members.map(_readUser).whereType<AppUser>().toList(),

      primaryAssigneeId: _readId(primaryData),
      primaryAssignee: _readUser(primaryData),

      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  bool get isCompleted => status == 'completed';

  bool get isInProgress => status == 'in_progress';

  bool get isPending => status == 'todo';

  bool get isHighPriority => priority == 'high';

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final deadline = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    return deadline.isBefore(today);
  }

  String get statusLabel {
    switch (status) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return priority;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'createdBy': createdById,
      'assigneeIds': assigneeIds,
      'primaryAssigneeId': primaryAssigneeId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
