import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
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
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark 
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF0F172A)],
              )
            : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.03) : primaryColor.withOpacity(0.03),
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
                  color: isDark ? Colors.white.withOpacity(0.04) : primaryColor.withOpacity(0.04),
                ),
              ),
            ),
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
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final size = MediaQuery.of(context).size;
    final double scale = (size.height / 1000).clamp(0.5, 0.9);
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 64.0 * scale, vertical: 64.0 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isDark ? null : [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 280 * scale,
                        width: 280 * scale,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 120 * scale, color: primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 56 * scale),
                  Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    'Alpha Graphics',
                    style: TextStyle(
                      fontSize: 72 * scale,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      height: 1.1,
                      letterSpacing: -2.0,
                    ),
                  ),
                  SizedBox(height: 24 * scale),
                  Text(
                    'Your gateway to interactive learning and creative excellence with our Test Series App. Sign in to access your personalized dashboard, practice with tailored test series, track your progress, and explore endless possibilities for academic and competitive success.',
                    style: TextStyle(
                      fontSize: 26 * scale,
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 56 * scale),
                  _buildFeatureRow(context, Icons.menu_book_rounded, 'Comprehensive Test Series', scale),
                  SizedBox(height: 24 * scale),
                  _buildFeatureRow(context, Icons.insights_rounded, 'In-Depth Performance Analytics', scale),
                  SizedBox(height: 24 * scale),
                  _buildFeatureRow(context, Icons.laptop_chromebook_rounded, 'Interactive Online Exam', scale),
                ],
              ),
            ),
          );
  }

  Widget _buildMobileHero(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 100),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                height: 160,
                width: 160,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 80, color: primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to access your portal',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text, double scale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12 * scale),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : primaryColor.withOpacity(0.1)),
          ),
          child: Icon(icon, color: isDark ? Colors.white : primaryColor, size: 28 * scale),
        ),
        SizedBox(width: 24 * scale),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
              fontSize: 22 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context, bool isDark, {bool isMobile = false}) {
    final size = MediaQuery.of(context).size;
    final double scale = isMobile ? 1.0 : (size.height / 1000).clamp(0.5, 0.9);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 24.0 * scale),
        child: Container(
          constraints: BoxConstraints(maxWidth: isMobile ? 560 : 680 * scale),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48 * scale),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: isDark ? 24.0 : 0.0, sigmaY: isDark ? 24.0 : 0.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? null : Colors.white,
                  gradient: isDark ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                    ],
                  ) : null,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 40 : 72 * scale, 
              vertical: isMobile ? 64 : 110 * scale,
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 42 * scale,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please enter your credentials to access your account',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 56 * scale),
              CustomTextField(
                label: 'Email Address',
                hintText: 'name@example.com',
                controller: _emailController,
                prefixIcon: Icons.email_rounded,
              ),
              SizedBox(height: 32 * scale),
              CustomTextField(
                label: 'Password',
                hintText: '••••••••',
                isPassword: true,
                controller: _passwordController,
                prefixIcon: Icons.lock_rounded,
                suffixIcon: Icons.visibility_rounded,
              ),
              SizedBox(height: 24 * scale),
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
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 56 * scale),
              SizedBox(
                width: double.infinity,
                height: 64 * scale,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In to Dashboard',
                              style: TextStyle(
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Icon(Icons.arrow_forward_rounded, size: 24 * scale),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        ),
        ),
      ),
      ),
    );
  }
}
