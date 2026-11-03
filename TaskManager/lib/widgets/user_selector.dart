import 'package:flutter/material.dart';

class AssignmentMember {
  final String id;
  final String fullName;
  final String email;

  const AssignmentMember({
    required this.id,
    required this.fullName,
    required this.email,
  });
}

class UserSelector extends StatefulWidget {
  final List<AssignmentMember> members;
  final List<String> selectedIds;
  final String? primaryId;
  final ValueChanged<List<String>> onSelectionChanged;
  final ValueChanged<String?> onPrimaryChanged;

  const UserSelector({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.primaryId,
    required this.onSelectionChanged,
    required this.onPrimaryChanged,
  });

  @override
  State<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends State<UserSelector> {
  String search = '';

  static const blue = Color(0xFF315CEB);
  static const navy = Color(0xFF17233F);
  static const muted = Color(0xFF78869B);

  @override
  Widget build(BuildContext context) {
    final filtered = widget.members.where((member) {
      final keyword = search.trim().toLowerCase();

      return member.fullName.toLowerCase().contains(keyword) ||
          member.email.toLowerCase().contains(keyword);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Container(
          padding: EdgeInsets.all(compact ? 14 : 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7ECF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups_2_outlined, color: blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chọn người được giao',
                      style: TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn một hoặc nhiều thành viên và chỉ định người phụ trách chính.',
                style: TextStyle(color: muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) {
                  setState(() => search = value);
                },
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5EAF3)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Danh sách thành viên',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.selectedIds.length} đã chọn',
                    style: const TextStyle(
                      color: blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25),
                  child: Center(
                    child: Text(
                      'Không tìm thấy thành viên',
                      style: TextStyle(color: muted),
                    ),
                  ),
                )
              else
                ...filtered.map((member) {
                  final selected = widget.selectedIds.contains(member.id);
                  final isPrimary = widget.primaryId == member.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF0F4FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF9CB5FF)
                            : const Color(0xFFE8EDF5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE4ECFF),
                              child: Text(
                                member.fullName.isNotEmpty
                                    ? member.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    member.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: selected,
                              activeColor: blue,
                              onChanged: (value) {
                                final ids = List<String>.from(
                                  widget.selectedIds,
                                );

                                if (value == true) {
                                  if (!ids.contains(member.id)) {
                                    ids.add(member.id);
                                  }
                                } else {
                                  ids.remove(member.id);

                                  if (isPrimary) {
                                    widget.onPrimaryChanged(null);
                                  }
                                }

                                widget.onSelectionChanged(ids);
                              },
                            ),
                          ],
                        ),
                        if (selected)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                widget.onPrimaryChanged(
                                  isPrimary ? null : member.id,
                                );
                              },
                              icon: Icon(
                                isPrimary
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                              ),
                              label: Text(
                                isPrimary
                                    ? 'Người phụ trách chính'
                                    : 'Đặt làm phụ trách chính',
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
