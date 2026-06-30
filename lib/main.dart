import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme_controller.dart';
import 'theme/app_theme.dart';
import 'auth/login_page.dart';
import 'teacher/teacher_dashboard.dart';
import 'student/student_dashboard.dart';
import 'core/services/settings_service.dart';

import 'core/widgets/app_zoom_scaler.dart';

final ThemeController themeController = ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fetch global settings
  SettingsService.fetchAndCacheSettings();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final role = prefs.getString('user_role');

  Widget initialPage = const LoginPage();
  if (token != null && token.isNotEmpty) {
    if (role == 'teacher') {
      initialPage = const TeacherDashboard();
    } else if (role == 'student') {
      initialPage = const StudentDashboard();
    }
  }

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Alpha App',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: initialPage,
          builder: (context, child) {
            return Stack(
              children: [
                AppZoomScaler(child: child!),
                IgnorePointer(
                  child: Opacity(
                    opacity: 0.05, // very light opacity
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/watermark.png'),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
