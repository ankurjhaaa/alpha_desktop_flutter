import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../auth/login_page.dart';
import '../core/widgets/theme_toggle_button.dart';
import '../core/widgets/app_zoom_scaler.dart';
import '../student/student_dashboard.dart';
import '../student/exams_page.dart';
import '../student/my_profile_page.dart';
import '../student/leaderboard_page.dart';
import '../student/global_leaderboard_page.dart';
import '../student/materials_page.dart';
import '../student/feedbacks_page.dart';
import '../student/about_page.dart';

class StudentLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onBackPressed;

  const StudentLayout({super.key, required this.child, required this.title, this.onBackPressed});

  @override
  State<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends State<StudentLayout> {
  String _userName = 'Student';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Student';
        _userEmail = prefs.getString('user_email') ?? '';
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    Widget contentArea(BuildContext ctx) => Column(
      children: [
        // Navbar
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              if (widget.onBackPressed != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBackPressed,
                )
              else if (!isDesktop)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              if (widget.onBackPressed != null && !isDesktop)
                const SizedBox(width: 8)
              else if (widget.onBackPressed != null)
                const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              ThemeToggleButton(controller: themeController),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Page Content
        Expanded(child: widget.child),
        // Footer Bar
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Text(
                    'Developed by Brotytics Technologies',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final scaler = AppZoomScaler.of(context);
                    if (scaler == null) return const SizedBox.shrink();
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: scaler.zoomOut,
                          child: Icon(Icons.remove, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: scaler.resetZoom,
                          child: Text(
                            '${(scaler.scale * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: scaler.zoomIn,
                          child: Icon(Icons.add, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 16),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context, theme),
            Expanded(child: Builder(builder: (ctx) => contentArea(ctx))),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: _buildSidebar(context, theme, isDrawer: true),
      ),
      body: Builder(builder: (ctx) => contentArea(ctx)),
    );
  }

  Widget _buildSidebar(BuildContext context, ThemeData theme, {bool isDrawer = false}) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'isActive': widget.title == 'Student Dashboard', 'page': const StudentDashboard()},
      {'title': 'Exams', 'icon': Icons.quiz_outlined, 'activeIcon': Icons.quiz, 'isActive': widget.title == 'Exams', 'page': const ExamsPage()},
      {'title': 'Study Materials', 'icon': Icons.library_books_outlined, 'activeIcon': Icons.library_books, 'isActive': widget.title == 'Study Materials', 'page': const MaterialsPage()},
      {'title': 'Feedbacks', 'icon': Icons.feedback_outlined, 'activeIcon': Icons.feedback, 'isActive': widget.title == 'Feedbacks', 'page': const FeedbacksPage()},
      {'title': 'Leaderboard', 'icon': Icons.leaderboard_outlined, 'activeIcon': Icons.leaderboard, 'isActive': widget.title.contains('Leaderboard'), 'page': const GlobalLeaderboardPage()},
      {'title': 'My Profile', 'icon': Icons.person_outline, 'activeIcon': Icons.person, 'isActive': widget.title == 'My Profile', 'page': const MyProfilePage()},
      {'title': 'About Us', 'icon': Icons.info_outline, 'activeIcon': Icons.info, 'isActive': widget.title == 'About Us', 'page': const StudentAboutPage()},
    ];

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 60, color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alpha Graphics',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = item['isActive'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (isDrawer) Navigator.pop(context); // close drawer
                      if (!isSelected && item['page'] != null) {
                        if (item['title'] == 'Dashboard') {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        } else {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => item['page'],
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item['activeIcon'] : item['icon'],
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 22,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item['title'],
                            style: TextStyle(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.error, size: 22),
                    const SizedBox(width: 16),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
