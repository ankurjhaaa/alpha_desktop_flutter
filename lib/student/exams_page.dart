import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/student_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'exam_taking_page.dart';
import 'leaderboard_page.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  List<dynamic> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/exams'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _exams = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) SnackbarHelper.showError(context, 'Failed to fetch exams.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) SnackbarHelper.showError(context, 'Network error.');
    }
  }

  void _handleExamClick(Map<String, dynamic> exam) {
    if (exam['is_completed']) {
      // Go to leaderboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LeaderboardPage(
            paperId: exam['id'],
            paperTitle: exam['title'],
          ),
        ),
      );
      return;
    }

    // Check date
    if (exam['exam_date'] != null) {
      final today = DateTime.now();
      final examDateStr = exam['exam_date'] as String;
      final examDate = DateTime.parse(examDateStr);
      
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final examMidnight = DateTime(examDate.year, examDate.month, examDate.day);

      if (todayMidnight.isBefore(examMidnight)) {
        SnackbarHelper.showError(context, 'This exam is locked until $examDateStr');
        return;
      }
    }

    if (exam['requires_password']) {
      _showPasswordDialog(exam);
    } else {
      _startExam(exam['id']);
    }
  }

  void _showPasswordDialog(Map<String, dynamic> exam) {
    final pwdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Enter Exam Password'),
        content: TextField(
          controller: pwdController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pwdController.text.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token');

              try {
                final response = await http.post(
                  Uri.parse('http://127.0.0.1:8000/api/student/exams/${exam["id"]}/verify'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({'password': pwdController.text}),
                );

                if (response.statusCode == 200) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    final data = jsonDecode(response.body);
                    _navigateToExam(exam['id'], data['questions']);
                  }
                } else {
                  if (context.mounted) SnackbarHelper.showError(context, 'Invalid Password');
                }
              } catch (e) {
                if (context.mounted) SnackbarHelper.showError(context, 'Network Error');
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Future<void> _startExam(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/student/exams/$id/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          final data = jsonDecode(response.body);
          _navigateToExam(id, data['questions']);
        }
      } else {
        if (mounted) SnackbarHelper.showError(context, 'Failed to start exam.');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Network Error');
    }
  }

  void _navigateToExam(int paperId, List<dynamic> questions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamTakingPage(
          paperId: paperId,
          questions: questions,
        ),
      ),
    ).then((_) => _fetchExams()); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StudentLayout(
      title: 'Exams',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              Colors.purpleAccent.withOpacity(0.05),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _exams.isEmpty
                ? const Center(child: Text('No exams available for your batches.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Exams',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unlock and complete your pending exams.',
                          style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 40),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth > 800;
                            final crossAxisCount = isDesktop ? 3 : 1;
                            final width = (constraints.maxWidth - (32 * (crossAxisCount - 1))) / crossAxisCount;

                            return Wrap(
                              spacing: 32,
                              runSpacing: 32,
                              children: _exams.map((exam) {
                                return SizedBox(
                                  width: width,
                                  child: _buildExamCard(exam, theme),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam, ThemeData theme) {
    final isCompleted = exam['is_completed'] == true;
    
    bool isLocked = false;
    if (!isCompleted && exam['exam_date'] != null) {
      final today = DateTime.now();
      final examDate = DateTime.parse(exam['exam_date']);
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final examMidnight = DateTime(examDate.year, examDate.month, examDate.day);
      isLocked = todayMidnight.isBefore(examMidnight);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.withOpacity(0.1) 
                        : (isLocked ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : (isLocked ? 'Locked' : 'Available'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : (isLocked ? Colors.red : Colors.blue),
                    ),
                  ),
                ),
                if (exam['requires_password'] && !isCompleted && !isLocked)
                  Icon(Icons.lock, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              exam['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              exam['description'] ?? 'No description provided.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  exam['exam_date'] ?? 'No Date',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Score', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        Text('${exam["score"]}/${exam["total_questions"]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Percentage', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        Text('${exam["percentage"]}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _handleExamClick(exam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? theme.colorScheme.surface : theme.colorScheme.primary,
                  foregroundColor: isCompleted ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isCompleted ? BorderSide(color: theme.colorScheme.primary) : BorderSide.none,
                  ),
                ),
                child: Text(
                  isCompleted ? 'View Leaderboard' : (isLocked ? 'Locked' : 'Start Exam'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
