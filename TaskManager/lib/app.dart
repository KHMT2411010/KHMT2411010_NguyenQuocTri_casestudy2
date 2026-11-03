import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'screens/assignment/assign_task_screen.dart';
import 'screens/sharing/task_sharing_screen.dart';

import 'services/auth_service.dart';
import 'utils/constants.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

        scaffoldBackgroundColor: AppColors.background,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.navy,
          centerTitle: false,
          elevation: 0,
          surfaceTintColor: Colors.white,
          titleTextStyle: TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFF),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AppColors.border),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AppColors.border),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),

      home: const AuthGate(),

      // Những route cần dùng chung giữa nhiều màn hình.
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const LoginScreen(),
            );

          case '/tasks':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const TaskListScreen(),
            );

          case '/assignment':
            final taskId = settings.arguments;

            if (taskId is! String || taskId.isEmpty) {
              return _errorRoute(settings, 'Thiếu mã công việc để giao việc.');
            }

            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => AssignmentScreen(taskId: taskId),
            );

          case '/sharing':
            final taskId = settings.arguments;

            if (taskId is! String || taskId.isEmpty) {
              return _errorRoute(settings, 'Thiếu mã công việc để chia sẻ.');
            }

            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SharingScreen(taskId: taskId),
            );

          default:
            return null;
        }
      },
    );
  }

  static Route<void> _errorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Không thể mở màn hình')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

// Kiểm tra phiên đăng nhập khi khởi động ứng dụng.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = const AuthService();

  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final valid = await _authService.hasValidSession();

    if (!mounted) return;

    setState(() {
      loggedIn = valid;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (loggedIn) {
      return const TaskListScreen();
    }

    return const LoginScreen();
  }
}
