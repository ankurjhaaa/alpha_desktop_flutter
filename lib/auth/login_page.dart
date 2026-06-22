import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../core/widgets/custom_textfield.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/theme_toggle_button.dart';
import '../student/student_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + '/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_role', role);
        await prefs.setString('user_name', data['user']['name'] ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? '');

        if (role == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherDashboard()),
          );
        } else if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown role')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8),
      body: Stack(
        children: [
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildHeroSection(context, isDark),
                ),
                Expanded(
                  flex: 5,
                  child: _buildFormSection(context, isDark),
                ),
              ],
            )
          else
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildMobileHero(context, isDark),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: _buildFormSection(context, isDark, isMobile: true),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 24,
            right: 24,
            child: ThemeToggleButton(controller: themeController),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1A1A2E), const Color(0xFF0F172A)]
            : [primaryColor, const Color(0xFF0A2E6B)], // Deep pure blue gradient
        ),
      ),
      child: Stack(
        children: [
          // Decorative Abstract Circles
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Hero Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 64,
                      width: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 48, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Alpha Graphics\nPortal',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your ultimate gateway to interactive learning. Access tailored test series, track your progress, and achieve academic excellence.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFeatureRow(Icons.menu_book_rounded, 'Comprehensive Test Series'),
                  const SizedBox(height: 16),
                  _buildFeatureRow(Icons.insights_rounded, 'In-Depth Performance Analytics'),
                  const SizedBox(height: 16),
                  _buildFeatureRow(Icons.laptop_chromebook_rounded, 'Interactive Live Classes'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHero(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1A1A2E), const Color(0xFF0F172A)]
            : [primaryColor, const Color(0xFF0A2E6B)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 64,
              width: 64,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 48, color: primaryColor),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to access your portal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 20),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context, bool isDark, {bool isMobile = false}) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? 480 : 540),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 60,
                  offset: const Offset(0, 30),
                ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 32 : 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your credentials to continue',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              CustomTextField(
                label: 'Email Address',
                hintText: 'name@example.com',
                controller: _emailController,
                prefixIcon: Icons.email_rounded,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Password',
                hintText: '••••••••',
                isPassword: true,
                controller: _passwordController,
                prefixIcon: Icons.lock_rounded,
                suffixIcon: Icons.visibility_rounded,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In to Dashboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
