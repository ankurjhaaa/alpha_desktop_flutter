import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../auth/login_page.dart';
import '../core/widgets/theme_toggle_button.dart';
import '../teacher/teacher_dashboard.dart';
import '../teacher/course_manager_page.dart';
import '../teacher/batch_manager_page.dart';
import '../teacher/students_page.dart';
import '../teacher/mcq_manager_page.dart';
import '../teacher/material_manager_page.dart';
import '../teacher/feedback_manager_page.dart';
import '../teacher/global_leaderboard_page.dart';

class TeacherLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onBackPressed;

  const TeacherLayout({super.key, required this.child, required this.title, this.onBackPressed});

  @override
  State<TeacherLayout> createState() => _TeacherLayoutState();
}

class _TeacherLayoutState extends State<TeacherLayout> {
  String _userName = 'Teacher';
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
        _userName = prefs.getString('user_name') ?? 'Teacher';
        _userEmail = prefs.getString('user_email') ?? '';
      });
    }
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');

    if (!context.mounted) return;
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
                    'T',
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
        Expanded(
          child: widget.child,
        ),
        // Footer Bar
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
    final title = widget.title;
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'isActive': title == 'Dashboard', 'page': const TeacherDashboard()},
      {'title': 'Courses', 'icon': Icons.menu_book_outlined, 'activeIcon': Icons.menu_book, 'isActive': title == 'Courses', 'page': const CourseManagerPage()},
      {'title': 'Batches', 'icon': Icons.layers_outlined, 'activeIcon': Icons.layers, 'isActive': title == 'Batches', 'page': const BatchManagerPage()},
      {'title': 'Students', 'icon': Icons.people_outline, 'activeIcon': Icons.people, 'isActive': title == 'Students', 'page': const StudentsPage()},
      {'title': 'MCQ Papers', 'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment, 'isActive': title == 'MCQ Papers', 'page': const McqManagerPage()},
      {'title': 'Leaderboard', 'icon': Icons.leaderboard_outlined, 'activeIcon': Icons.leaderboard, 'isActive': title.contains('Leaderboard'), 'page': const TeacherGlobalLeaderboardPage()},
      {'title': 'Study Materials', 'icon': Icons.library_books_outlined, 'activeIcon': Icons.library_books, 'isActive': title == 'Study Materials', 'page': const MaterialManagerPage()},
      {'title': 'Student Feedbacks', 'icon': Icons.feedback_outlined, 'activeIcon': Icons.feedback, 'isActive': title == 'Student Feedbacks', 'page': const FeedbackManagerPage()},
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
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.computer, size: 60, color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'T',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _userEmail.isNotEmpty ? _userEmail : 'Teacher Portal',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation1, animation2) => item['page'],
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
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
              onTap: () => _logout(context),
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
