import 'package:flutter/material.dart';

import '../utils/constants.dart';

class LoadingView extends StatelessWidget {
  final String message;
  final bool fullScreen;

  const LoadingView({
    super.key,
    this.message = 'Đang tải dữ liệu...',
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 35,
          height: 35,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: content),
      );
    }

    return Center(
      child: Padding(padding: const EdgeInsets.all(30), child: content),
    );
  }
}
