import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/snackbar_helper.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class FeedbackManagerPage extends StatefulWidget {
  const FeedbackManagerPage({super.key});

  @override
  State<FeedbackManagerPage> createState() => _FeedbackManagerPageState();
}

class _FeedbackManagerPageState extends State<FeedbackManagerPage> {
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_currentPage < _lastPage && !_isLoadingMore) {
        _fetchFeedbacks(page: _currentPage + 1);
      }
    }
  }

  Future<void> _fetchFeedbacks({int page = 1}) async {
    if (page == 1) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/feedbacks?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (page == 1) {
            _feedbacks = data['data'];
          } else {
            _feedbacks.addAll(data['data']);
          }
          _currentPage = data['current_page'];
          _lastPage = data['last_page'];
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        if (mounted) SnackbarHelper.showError(context, 'Failed to fetch feedbacks');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) SnackbarHelper.showError(context, 'Network error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TeacherLayout(
      title: 'Student Feedbacks',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Feedbacks',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage and review all feedbacks submitted by students.',
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 32),
                    if (_feedbacks.isEmpty)
                      const Expanded(child: Center(child: Text('No feedbacks available.')))
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _feedbacks.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _feedbacks.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final fb = _feedbacks[index];
                            final user = fb['user'] ?? {};
                            final batch = fb['batch'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left side: Student details
                                    Container(
                                      width: 250,
                                      decoration: BoxDecoration(
                                        border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['name'] ?? 'Unknown User',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.email, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  user['email'] ?? 'No Email',
                                                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                              const SizedBox(width: 8),
                                              Text(
                                                user['phone_number'] ?? 'No Phone',
                                                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // Right side: Feedback content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: List.generate(5, (starIndex) {
                                                  return Icon(
                                                    starIndex < fb['rating'] ? Icons.star : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 24,
                                                  );
                                                }),
                                              ),
                                              Text(
                                                DateTime.parse(fb['created_at']).toLocal().toString().split(' ')[0],
                                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                              ),
                                            ],
                                          ),
                                          if (batch != null) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Batch: ${batch['name']}',
                                                style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          Text(
                                            fb['message'] ?? '',
                                            style: const TextStyle(fontSize: 16, height: 1.5),
                                          ),
                                        ],
                                      ),
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
              ),
      ),
    );
  }
}
