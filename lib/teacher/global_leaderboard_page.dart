import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class TeacherGlobalLeaderboardPage extends StatefulWidget {
  const TeacherGlobalLeaderboardPage({super.key});

  @override
  State<TeacherGlobalLeaderboardPage> createState() => _TeacherGlobalLeaderboardPageState();
}

class _TeacherGlobalLeaderboardPageState extends State<TeacherGlobalLeaderboardPage> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/leaderboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _leaderboard = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) SnackbarHelper.showError(context, 'Failed to load leaderboard');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) SnackbarHelper.showError(context, 'Network error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return TeacherLayout(
      title: 'Global Leaderboard',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Leaderboard',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Top 10 students based on total exams taken and average marks.',
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 32),
                    if (_leaderboard.isEmpty)
                      const Center(child: Text('No leaderboard data available.'))
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _leaderboard.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                          itemBuilder: (context, index) {
                            final entry = _leaderboard[index];
                            final isTop3 = index < 3;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTop3
                                      ? (index == 0
                                          ? Colors.amber
                                          : (index == 1 ? Colors.grey[400] : Colors.orange[300]))
                                      : theme.colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isTop3 ? Colors.white : theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                entry['student_name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                '${entry['total_exams']} Exams Taken',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${entry['average_marks']}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'Avg Score',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
