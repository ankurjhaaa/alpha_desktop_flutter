import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      title: 'Dashboard',
      child: const _TeacherDashboardContent(),
    );
  }
}

class _TeacherDashboardContent extends StatefulWidget {
  const _TeacherDashboardContent({Key? key}) : super(key: key);

  @override
  State<_TeacherDashboardContent> createState() =>
      _TeacherDashboardContentState();
}

class _TeacherDashboardContentState extends State<_TeacherDashboardContent> {
  bool _isLoading = true;
  int _totalStudents = 0;
  int _activeCourses = 0;
  int _activeBatches = 0;
  int _totalMcqPapers = 0;
  List<dynamic> _recentStudents = [];
  List<dynamic> _upcomingBatches = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final coursesRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final batchesRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final studentsRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/students'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final mcqRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/mcq_papers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (coursesRes.statusCode == 200 &&
          batchesRes.statusCode == 200 &&
          studentsRes.statusCode == 200 &&
          mcqRes.statusCode == 200) {
        final courses = jsonDecode(coursesRes.body) as List;
        final batches = jsonDecode(batchesRes.body) as List;
        final students = jsonDecode(studentsRes.body) as List;
        final mcqs = jsonDecode(mcqRes.body) as List;

        setState(() {
          _activeCourses = courses
              .where((c) => c['is_active'] == 1 || c['is_active'] == true)
              .length;
          _activeBatches = batches
              .where((b) => b['is_active'] == 1 || b['is_active'] == true)
              .length;
          _totalStudents = students.length;
          _totalMcqPapers = mcqs.length;

          // Take top 3 for upcoming batches
          _upcomingBatches = batches.take(3).toList();
          // Take the last 4 students for recent activity
          _recentStudents = students.reversed.take(4).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back, Teacher!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your live summary for today.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ElevatedButton.icon(
                  onPressed: _fetchDashboardData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isDesktop ? 4 : 2;
              final width =
                  (constraints.maxWidth - (24 * (crossAxisCount - 1))) /
                  crossAxisCount;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      context,
                      'Total Students',
                      _totalStudents.toString(),
                      Icons.people_alt,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      context,
                      'Active Courses',
                      _activeCourses.toString(),
                      Icons.class_,
                      Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      context,
                      'Active Batches',
                      _activeBatches.toString(),
                      Icons.group_work,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      context,
                      'Total MCQ Papers',
                      _totalMcqPapers.toString(),
                      Icons.quiz,
                      Colors.purple,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildRecentActivity(context)),
              if (isDesktop) const SizedBox(width: 32),
              if (isDesktop)
                Expanded(flex: 4, child: _buildUpcomingSchedule(context)),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 32),
          if (!isDesktop) _buildUpcomingSchedule(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withOpacity(0.2)
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Flexible(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    children: const [
                      Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Enrollments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (_recentStudents.isEmpty)
              const Center(
                child: Text(
                  "No recent students found.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ..._recentStudents.map((student) {
              return Column(
                children: [
                  _buildActivityItem(
                    context,
                    'New student ${student['name']} joined.',
                    student['email'],
                    Icons.person_add,
                    Colors.blue,
                  ),
                  if (student != _recentStudents.last)
                    const Divider(height: 32),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String text,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSchedule(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Upcoming Batches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_upcomingBatches.isEmpty)
              const Center(
                child: Text(
                  "No upcoming batches scheduled.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ..._upcomingBatches.map((batch) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildScheduleItem(
                  context,
                  batch['name'],
                  batch['schedule_time'] ?? 'TBD',
                  batch['course'] != null
                      ? batch['course']['name']
                      : 'General Course',
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    String subject,
    String time,
    String courseName,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? primary.withOpacity(0.05) : primary.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.class_,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    Text(
                      courseName,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
