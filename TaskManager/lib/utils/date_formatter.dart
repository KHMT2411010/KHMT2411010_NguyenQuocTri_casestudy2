class AppDateFormatter {
  const AppDateFormatter._();

  static DateTime? parse(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }

  static String format(dynamic value, {String fallback = 'Chưa thiết lập'}) {
    final date = parse(value);

    if (date == null) return fallback;

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  static String formatDateTime(
    dynamic value, {
    String fallback = 'Chưa có thông tin',
  }) {
    final date = parse(value);

    if (date == null) return fallback;

    final local = date.toLocal();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute - ${format(local)}';
  }

  static bool isOverdue(dynamic value) {
    final date = parse(value);

    if (date == null) return false;

    final local = date.toLocal();
    final now = DateTime.now();

    final deadline = DateTime(local.year, local.month, local.day);

    final today = DateTime(now.year, now.month, now.day);

    return deadline.isBefore(today);
  }

  static bool isValidRange(DateTime? startDate, DateTime? dueDate) {
    if (startDate == null || dueDate == null) {
      return true;
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    return !due.isBefore(start);
  }
}
