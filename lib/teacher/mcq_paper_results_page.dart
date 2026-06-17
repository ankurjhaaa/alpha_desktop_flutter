import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'student_exam_answers_page.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class McqPaperResultsPage extends StatefulWidget {
  final int paperId;
  final String paperTitle;

  const McqPaperResultsPage({
    super.key,
    required this.paperId,
    required this.paperTitle,
  });

  @override
  State<McqPaperResultsPage> createState() => _McqPaperResultsPageState();
}

class _McqPaperResultsPageState extends State<McqPaperResultsPage> {
  List<dynamic> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/mcq_papers/${widget.paperId}/results'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeResult(int userId, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Result?'),
        content: Text('Are you sure you want to delete the exam result for $studentName? They will be able to take the exam again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.baseUrl + '/mcq_papers/${widget.paperId}/results/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result revoked successfully')));
        }
        _fetchResults();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to revoke result')));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TeacherLayout(
      title: 'Results: ${widget.paperTitle}',
      onBackPressed: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results for ${widget.paperTitle}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_results.length} student(s) have submitted this exam.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _fetchResults,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_edu,
                              size: 80,
                              color: theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No submissions yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          final int score = result['score'] ?? 0;
                          final int total = result['total_questions'] ?? 1;
                          final double percentage = double.tryParse(result['percentage'].toString()) ?? 0.0;
                          
                          Color scoreColor = Colors.orange;
                          if (percentage >= 80) scoreColor = Colors.green;
                          if (percentage < 40) scoreColor = Colors.red;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.1),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                child: Text(
                                  result['student_name'].toString()[0].toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              title: Text(
                                result['student_name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Email: ${result['student_email']}\nSubmitted: ${result['submitted_at'].toString().split('T')[0]}',
                                  style: TextStyle(height: 1.4, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$score / $total',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: scoreColor,
                                        ),
                                      ),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: scoreColor.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Tooltip(
                                    message: 'Revoke Exam Result',
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                                      onPressed: () => _revokeResult(result['user_id'], result['student_name']),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentExamAnswersPage(
                                            paperId: widget.paperId,
                                            userId: result['user_id'],
                                            studentName: result['student_name'],
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    ),
                                    child: const Text('View Answers'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
