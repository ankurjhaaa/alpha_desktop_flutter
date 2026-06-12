import 'package:flutter/material.dart';
import 'core/theme_controller.dart';
import 'theme/app_theme.dart';
import 'auth/login_page.dart';

final ThemeController themeController = ThemeController();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: const LoginPage(),
        );
      },
    );
  }
}
