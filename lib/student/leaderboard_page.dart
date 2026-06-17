import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/student_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

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
        Uri.parse(ApiConstants.baseUrl + '/student/exams/${widget.paperId}/leaderboard'),
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

    return StudentLayout(
      title: 'Leaderboard - ${widget.paperTitle}',
      onBackPressed: () => Navigator.pop(context),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text('No results found for this exam yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back to Exams'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      // Leaderboard Table
                      Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 56, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                const SizedBox(width: 24),
                                const Expanded(child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                const SizedBox(width: 80, child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                const SizedBox(width: 80, child: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.end)),
                              ],
                            ),
                          ),
                          // Rows
                          ..._leaderboard.asMap().entries.map((entry) {
                            final index = entry.key;
                            final result = entry.value;
                            final rank = index + 1;

                            Color rankColor;
                            IconData? rankIcon;
                            if (rank == 1) {
                              rankColor = const Color(0xFFFFD700);
                              rankIcon = Icons.emoji_events;
                            } else if (rank == 2) {
                              rankColor = const Color(0xFFC0C0C0);
                              rankIcon = Icons.emoji_events;
                            } else if (rank == 3) {
                              rankColor = const Color(0xFFCD7F32);
                              rankIcon = Icons.emoji_events;
                            } else {
                              rankColor = theme.colorScheme.onSurface.withOpacity(0.5);
                              rankIcon = null;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: rank <= 3
                                    ? rankColor.withOpacity(0.04)
                                    : (index.isEven ? theme.colorScheme.surface : theme.scaffoldBackgroundColor),
                                border: Border(
                                  left: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                                  right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                                  bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                                ),
                                borderRadius: index == _leaderboard.length - 1
                                    ? const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    child: Row(
                                      children: [
                                        if (rankIcon != null)
                                          Icon(rankIcon, size: 20, color: rankColor)
                                        else
                                          Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rankColor)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: rankColor.withOpacity(rank <= 3 ? 0.15 : 0.08),
                                          child: Text(
                                            (result['student_name'] ?? 'U')[0].toUpperCase(),
                                            style: TextStyle(
                                              color: rank <= 3 ? rankColor : theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            result['student_name'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w500,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '${result["score"]} / ${result["total_questions"]}',
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${result["percentage"]}%',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
