import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF315CEB);
  static const primaryLight = Color(0xFF6790F8);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);
  static const background = Color(0xFFF5F7FC);
  static const surface = Colors.white;
  static const border = Color(0xFFE7ECF5);

  static const success = Color(0xFF159B78);
  static const warning = Color(0xFFE59A28);
  static const danger = Color(0xFFDF5454);
}

class TaskValues {
  static const todo = 'todo';
  static const inProgress = 'in_progress';
  static const completed = 'completed';

  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';

  static const viewer = 'viewer';
  static const editor = 'editor';

  static String statusLabel(String value) {
    switch (value) {
      case todo:
        return 'Chưa thực hiện';
      case inProgress:
        return 'Đang thực hiện';
      case completed:
        return 'Đã hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  static String priorityLabel(String value) {
    switch (value) {
      case low:
        return 'Thấp';
      case medium:
        return 'Trung bình';
      case high:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }

  static Color statusColor(String value) {
    switch (value) {
      case completed:
        return AppColors.success;
      case inProgress:
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  static Color priorityColor(String value) {
    switch (value) {
      case low:
        return AppColors.success;
      case high:
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }
}
