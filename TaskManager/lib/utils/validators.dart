class AppValidators {
  const AppValidators._();

  static String? requiredText(String? value, {String fieldName = 'Thông tin'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }

    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Vui lòng nhập email';
    }

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);

    if (!valid) {
      return 'Địa chỉ email không hợp lệ';
    }

    return null;
  }

  static String? taskTitle(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Vui lòng nhập tên công việc';
    }

    if (text.length > 200) {
      return 'Tên công việc không được quá 200 ký tự';
    }

    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }

    if (value != originalPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }

    return null;
  }

  static bool isValidEmail(String value) {
    return email(value) == null;
  }
}
