import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/student_layout.dart';
import '../core/utils/snackbar_helper.dart';

class LeaderboardPage extends StatefulWidget {
  final int paperId;
  final String paperTitle;

  const LeaderboardPage({
    super.key,
    required this.paperId,
    required this.paperTitle,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
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

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/exams/${widget.paperId}/leaderboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _leaderboard = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarHelper.showError(context, 'Failed to load leaderboard.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Network Error.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard - \${widget.paperTitle}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
              ? const Center(child: Text('No results found for this exam yet.', style: TextStyle(fontSize: 16)))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.emoji_events, size: 64, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Leaderboard',
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Top performers for \${widget.paperTitle}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                            ),
                            const SizedBox(height: 56),
                            ..._leaderboard.asMap().entries.map((entry) {
                              final index = entry.key;
                              final result = entry.value;
                              final rank = index + 1;
                              final isTop3 = rank <= 3;
                              
                              Color rankColor;
                              Color rankBgColor;
                              if (rank == 1) {
                                rankColor = const Color(0xFFFFD700);
                                rankBgColor = const Color(0xFFFFD700).withOpacity(0.15);
                              } else if (rank == 2) {
                                rankColor = const Color(0xFFC0C0C0);
                                rankBgColor = const Color(0xFFC0C0C0).withOpacity(0.15);
                              } else if (rank == 3) {
                                rankColor = const Color(0xFFCD7F32);
                                rankBgColor = const Color(0xFFCD7F32).withOpacity(0.15);
                              } else {
                                rankColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
                                rankBgColor = Theme.of(context).colorScheme.surface;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(isTop3 ? 24 : 16),
                                  boxShadow: isTop3 ? [
                                    BoxShadow(
                                      color: rankColor.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )
                                  ] : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                  border: Border.all(
                                    color: isTop3 ? rankColor.withOpacity(0.3) : Theme.of(context).dividerColor.withOpacity(0.05),
                                    width: isTop3 ? 2 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: isTop3 ? 24 : 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: isTop3 ? 56 : 40,
                                        height: isTop3 ? 56 : 40,
                                        decoration: BoxDecoration(
                                          color: rankBgColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '#$rank',
                                            style: TextStyle(
                                              color: isTop3 ? rankColor : Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isTop3 ? 20 : 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              result['student_name'] ?? 'Unknown User',
                                              style: TextStyle(
                                                fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                                                fontSize: isTop3 ? 20 : 16,
                                              ),
                                            ),
                                            if (isTop3) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.stars, size: 14, color: rankColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Top Performer',
                                                    style: TextStyle(color: rankColor, fontSize: 12, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: isTop3 ? 16 : 12, vertical: isTop3 ? 8 : 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${result["percentage"]}%',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isTop3 ? 18 : 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${result["score"]} / ${result["total_questions"]}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
