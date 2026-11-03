import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';

class TaskCreateScreen extends StatelessWidget {
  const TaskCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: const Text(
          'Tạo công việc',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: TaskEditorFields(
        heading: 'Công việc mới',
        description: 'Thiết lập thông tin và kế hoạch thực hiện.',
        buttonText: 'Tạo công việc',
        onSave: (payload) async {
          await ApiClient.post('/api/tasks', payload);
        },
      ),
    );
  }
}

/// Biểu mẫu dùng chung cho Tạo và Chỉnh sửa.
/// Đặt trong file có sẵn để không phải tạo thêm file mới.
class TaskEditorFields extends StatefulWidget {
  final String heading;
  final String description;
  final String buttonText;
  final Map<String, dynamic>? initialTask;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const TaskEditorFields({
    super.key,
    required this.heading,
    required this.description,
    required this.buttonText,
    required this.onSave,
    this.initialTask,
  });

  @override
  State<TaskEditorFields> createState() => _TaskEditorFieldsState();
}

class _TaskEditorFieldsState extends State<TaskEditorFields> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String priority = TaskValues.medium;
  DateTime? startDate;
  DateTime? dueDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadInitialValues();
  }

  void loadInitialValues() {
    final task = widget.initialTask;
    if (task == null) return;

    titleController.text = task['title']?.toString() ?? '';
    descriptionController.text = task['description']?.toString() ?? '';

    final savedPriority = task['priority']?.toString();

    if ([
      TaskValues.low,
      TaskValues.medium,
      TaskValues.high,
    ].contains(savedPriority)) {
      priority = savedPriority!;
    }

    startDate = AppDateFormatter.parse(task['startDate']);
    dueDate = AppDateFormatter.parse(task['dueDate']);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> pickDate(bool start) async {
    final current = start ? startDate : dueDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: start ? 'CHỌN NGÀY BẮT ĐẦU' : 'CHỌN HẠN HOÀN THÀNH',
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (start) {
        startDate = selected;
      } else {
        dueDate = selected;
      }
    });
  }

  Future<void> submit() async {
    if (saving) return;

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!AppDateFormatter.isValidRange(startDate, dueDate)) {
      showMessage('Hạn hoàn thành không được trước ngày bắt đầu', error: true);
      return;
    }

    final payload = <String, dynamic>{
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'priority': priority,
      'startDate': startDate == null
          ? null
          : DateUtils.dateOnly(startDate!).toIso8601String(),
      'dueDate': dueDate == null
          ? null
          : DateUtils.dateOnly(dueDate!).toIso8601String(),
    };

    setState(() => saving = true);

    try {
      await widget.onSave(payload);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080E214A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          child,
        ],
      ),
    );
  }

  Widget priorityOption(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    final selected = priority == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? color : AppColors.navy,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_circle, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget dateField(String label, DateTime? date, bool start) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE2E9F3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => pickDate(start),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            AppDateFormatter.format(
                              date,
                              fallback: 'Chưa chọn ngày',
                            ),
                            style: TextStyle(
                              color: date == null
                                  ? AppColors.muted
                                  : AppColors.navy,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (date != null)
                IconButton(
                  tooltip: 'Bỏ chọn ngày',
                  icon: const Icon(Icons.close_rounded, size: 19),
                  onPressed: () {
                    setState(() {
                      if (start) {
                        startDate = null;
                      } else {
                        dueDate = null;
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) {
        final compact = viewport.maxWidth < 600;

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24,
            18,
            compact ? 14 : 24,
            36,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 34,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 13),
                          Text(
                            widget.heading,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            widget.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    buildSection(
                      icon: Icons.description_outlined,
                      title: 'Thông tin công việc',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: titleController,
                            maxLength: 200,
                            decoration: const InputDecoration(
                              labelText: 'Tên công việc *',
                              hintText: 'Ví dụ: Thiết kế giao diện',
                              prefixIcon: Icon(Icons.assignment_outlined),
                            ),
                            validator: AppValidators.taskTitle,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Mô tả công việc',
                              hintText: 'Nhập nội dung cần thực hiện...',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildSection(
                      icon: Icons.flag_outlined,
                      title: 'Mức độ ưu tiên',
                      child: LayoutBuilder(
                        builder: (context, size) {
                          final options = [
                            priorityOption(
                              TaskValues.low,
                              'Thấp',
                              AppColors.success,
                              Icons.keyboard_arrow_down,
                            ),
                            priorityOption(
                              TaskValues.medium,
                              'Trung bình',
                              AppColors.warning,
                              Icons.remove_rounded,
                            ),
                            priorityOption(
                              TaskValues.high,
                              'Cao',
                              AppColors.danger,
                              Icons.priority_high_rounded,
                            ),
                          ];

                          if (size.maxWidth < 470) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final option in options) ...[
                                  option,
                                  const SizedBox(height: 9),
                                ],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              for (var i = 0; i < options.length; i++) ...[
                                if (i != 0) const SizedBox(width: 9),
                                Expanded(child: options[i]),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildSection(
                      icon: Icons.event_available_outlined,
                      title: 'Thời gian thực hiện',
                      child: LayoutBuilder(
                        builder: (context, size) {
                          final start = dateField(
                            'Ngày bắt đầu',
                            startDate,
                            true,
                          );

                          final due = dateField(
                            'Hạn hoàn thành',
                            dueDate,
                            false,
                          );

                          if (size.maxWidth < 520) {
                            return Column(
                              children: [
                                start,
                                const SizedBox(height: 17),
                                due,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: start),
                              const SizedBox(width: 16),
                              Expanded(child: due),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: saving ? null : submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: saving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          saving ? 'Đang lưu...' : widget.buttonText,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
