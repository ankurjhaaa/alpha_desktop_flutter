import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/student_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'exams_page.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<dynamic> _batches = [];
  List<dynamic> _exams = [];

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
      // Fetch profile (which includes batches)
      final profileRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/student/profile'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      // Fetch exams
      final examsRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/student/exams'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (mounted) {
        setState(() {
          if (profileRes.statusCode == 200) {
            _profile = jsonDecode(profileRes.body);
            _batches = _profile?['batches'] ?? [];
          }
          if (examsRes.statusCode == 200) {
            _exams = jsonDecode(examsRes.body);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Network error while loading dashboard.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Student Dashboard',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _StudentDashboardContent(
              profile: _profile,
              batches: _batches,
              exams: _exams,
            ),
    );
  }
}

class _StudentDashboardContent extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final List<dynamic> batches;
  final List<dynamic> exams;

  const _StudentDashboardContent({
    required this.profile,
    required this.batches,
    required this.exams,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final completedExams = exams.where((e) => e['is_completed'] == true).toList();
    final pendingExams = exams.where((e) => e['is_completed'] != true).toList();
    
    double avgPercentage = 0;
    if (completedExams.isNotEmpty) {
      avgPercentage = completedExams.fold<double>(0, (sum, e) => sum + (double.tryParse(e['percentage'].toString()) ?? 0)) / completedExams.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${profile?['name'] ?? 'Student'}!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your learning overview.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isDesktop ? 4 : 2;
              final width = (constraints.maxWidth - (24 * (crossAxisCount - 1))) / crossAxisCount;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(width: width, child: _buildStatCard(context, 'Enrolled Batches', '${batches.length}', Icons.class_, Colors.blue)),
                  SizedBox(width: width, child: _buildStatCard(context, 'Exams Taken', '${completedExams.length}', Icons.task_alt, Colors.green)),
                  SizedBox(width: width, child: _buildStatCard(context, 'Pending Exams', '${pendingExams.length}', Icons.timer, Colors.orange)),
                  SizedBox(width: width, child: _buildStatCard(context, 'Avg. Score', completedExams.isEmpty ? 'N/A' : '${avgPercentage.toStringAsFixed(1)}%', Icons.trending_up, Colors.purple)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Main content area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enrolled Batches
              Expanded(
                flex: 7,
                child: _buildEnrolledBatches(context, theme),
              ),
              if (isDesktop) const SizedBox(width: 24),
              if (isDesktop)
                Expanded(
                  flex: 4,
                  child: _buildUpcomingExams(context, theme),
                ),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 24),
          if (!isDesktop) _buildUpcomingExams(context, theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
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

  Widget _buildEnrolledBatches(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Batches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (batches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'You are not enrolled in any batches yet.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ),
              )
            else
              ...batches.asMap().entries.map((entry) {
                final index = entry.key;
                final batch = entry.value;
                final pivot = batch['pivot'];
                
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 32),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.class_, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(batch['name'] ?? 'Unknown Batch', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 4),
                              if (batch['course'] != null)
                                Text(
                                  'Course: ${batch['course']['name']}',
                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                                ),
                              if (batch['schedule_time'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  batch['schedule_time'],
                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (pivot?['status'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(pivot['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (pivot['status'] as String).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(pivot['status']),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExams(BuildContext context, ThemeData theme) {
    final pendingExams = exams.where((e) => e['is_completed'] != true).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upcoming Exams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const ExamsPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pendingExams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No pending exams. You are all caught up!',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ),
              )
            else
              ...pendingExams.take(5).map((exam) {
                bool isLocked = false;
                if (exam['exam_date'] != null) {
                  final today = DateTime.now();
                  final examDate = DateTime.parse(exam['exam_date']);
                  isLocked = DateTime(today.year, today.month, today.day).isBefore(DateTime(examDate.year, examDate.month, examDate.day));
                }
                final color = isLocked ? Colors.red : Colors.blue;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(isLocked ? Icons.lock : Icons.quiz, color: color, size: 22),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exam['title'] ?? 'Exam', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              isLocked ? 'Locked until ${exam['exam_date']}' : 'Available Now',
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLocked ? 'LOCKED' : 'READY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      case 'unpaid': return Colors.red;
      default: return Colors.grey;
    }
  }
}
