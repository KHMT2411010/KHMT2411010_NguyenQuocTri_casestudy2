import 'task_service.dart';

class TaskStatistics {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;
  final int highPriority;
  final int created;
  final int delegated;
  final int assigned;

  const TaskStatistics({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
    required this.highPriority,
    this.created = 0,
    this.delegated = 0,
    this.assigned = 0,
  });

  double get completionRate {
    if (total == 0) return 0;
    return completed / total;
  }

  double get progressRate {
    if (total == 0) return 0;
    return inProgress / total;
  }
}

class StatisticsService {
  final TaskService _taskService;

  const StatisticsService({this._taskService = const TaskService()});

  TaskStatistics calculate(List<Map<String, dynamic>> tasks) {
    int pending = 0;
    int inProgress = 0;
    int completed = 0;
    int overdue = 0;
    int highPriority = 0;

    final now = DateTime.now();

    for (final task in tasks) {
      final status = task['status']?.toString() ?? 'todo';
      final priority = task['priority']?.toString() ?? 'medium';

      switch (status) {
        case 'completed':
          completed++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        default:
          pending++;
      }

      if (priority == 'high') highPriority++;

      final dueDate = DateTime.tryParse(task['dueDate']?.toString() ?? '')
          ?.toLocal();

      if (dueDate != null && status != 'completed') {
        if (dueDate.isBefore(now)) {
          overdue++;
        }
      }
    }

    return TaskStatistics(
      total: tasks.length,
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      overdue: overdue,
      highPriority: highPriority,
    );
  }

  Future<TaskStatistics> load({String scope = 'all'}) async {
    final tasks = await _taskService.getTasks(scope: scope);
    final base = calculate(tasks);

    final createdTasks = await _taskService.getTasks(scope: 'created');

    final assignedTasks = await _taskService.getTasks(scope: 'assigned');

    final delegated = createdTasks.where((task) {
      final assignees = task['assigneeIds'];
      return assignees is List && assignees.isNotEmpty;
    }).length;

    return TaskStatistics(
      total: base.total,
      pending: base.pending,
      inProgress: base.inProgress,
      completed: base.completed,
      overdue: base.overdue,
      highPriority: base.highPriority,
      created: createdTasks.length,
      delegated: delegated,
      assigned: assignedTasks.length,
    );
  }
}
