import 'package:flutter/material.dart';
import '../theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  final ThemeController controller;

  const ThemeToggleButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isDark = controller.isDarkMode;
        return IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: controller.toggleTheme,
          tooltip: 'Toggle Theme',
        );
      },
    );
  }
}
