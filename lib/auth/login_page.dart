import 'package:flutter/material.dart';
import '../main.dart';
import '../core/widgets/custom_textfield.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/theme_toggle_button.dart';
import '../student/student_dashboard.dart';
import '../teacher/teacher_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    final email = _emailController.text.trim();
    
    if (email == 'teacher@gmail.com') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
      );
    } else if (email == 'student@gmail.com') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use teacher@gmail.com or student@gmail.com to login.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: _buildLeftContent(context),
                      ),
                      Expanded(
                        flex: 9,
                        child: _buildRightContent(context),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildLeftContent(context),
                        _buildRightContent(context),
                      ],
                    ),
                  ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: ThemeToggleButton(controller: themeController),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = textColor.withOpacity(0.7);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 800 ? 80.0 : 32.0,
        vertical: 48.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.1),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Icon(Icons.computer, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to',
            style: TextStyle(fontSize: 28, color: subtitleColor, fontWeight: FontWeight.w500),
          ),
          Text(
            'Alpha Graphics',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your gateway to interactive learning and creative excellence with our Test Series App. Sign in to access your personalized dashboard, practice with tailored test series, track your progress, and explore endless possibilities for academic and competitive success.',
            style: TextStyle(fontSize: 16, color: subtitleColor, height: 1.6),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.purpleAccent),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your data is secured with enterprise-grade encryption',
                    style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightContent(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your account to continue',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  label: 'Email Address',
                  hintText: 'Enter your email',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Password',
                  hintText: '••••••••',
                  isPassword: true,
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: Icons.visibility_outlined,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Teacher Login',
                  icon: Icons.person_outline,
                  onPressed: () {
                    _emailController.text = 'teacher@gmail.com';
                    _login();
                  },
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Student Login',
                  icon: Icons.school_outlined,
                  onPressed: () {
                    _emailController.text = 'student@gmail.com';
                    _login();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
