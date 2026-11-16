import 'task_service.dart';

class DeadlineSummary {
  final List<Map<String, dynamic>> upcoming;
  final List<Map<String, dynamic>> overdue;

  const DeadlineSummary({required this.upcoming, required this.overdue});
}

class DeadlineService {
  final TaskService _taskService;

  const DeadlineService({TaskService taskService = const TaskService()})
    : _taskService = taskService;

  DeadlineSummary calculate(
    List<Map<String, dynamic>> tasks, {
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final upcomingLimit = now.add(const Duration(hours: 24));

    final upcoming = <Map<String, dynamic>>[];
    final overdue = <Map<String, dynamic>>[];

    for (final task in tasks) {
      if (task['status']?.toString() == 'completed') {
        continue;
      }

      final dueDate = DateTime.tryParse(task['dueDate']?.toString() ?? '')
          ?.toLocal();

      if (dueDate == null) {
        continue;
      }

      if (dueDate.isBefore(now)) {
        overdue.add(task);
      } else if (!dueDate.isAfter(upcomingLimit)) {
        upcoming.add(task);
      }
    }

    int compareDueDates(Map<String, dynamic> a, Map<String, dynamic> b) {
      final dateA = DateTime.parse(a['dueDate'].toString());

      final dateB = DateTime.parse(b['dueDate'].toString());

      return dateA.compareTo(dateB);
    }

    upcoming.sort(compareDueDates);
    overdue.sort(compareDueDates);

    return DeadlineSummary(upcoming: upcoming, overdue: overdue);
  }

  Future<DeadlineSummary> load() async {
    final tasks = await _taskService.getTasks(scope: 'all');

    return calculate(tasks);
  }
}
