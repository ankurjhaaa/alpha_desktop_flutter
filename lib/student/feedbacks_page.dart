import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/snackbar_helper.dart';
import '../layout/student_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class FeedbacksPage extends StatefulWidget {
  const FeedbacksPage({super.key});

  @override
  State<FeedbacksPage> createState() => _FeedbacksPageState();
}

class _FeedbacksPageState extends State<FeedbacksPage> {
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _enrolledBatches = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
    _fetchProfile();
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

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/student/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _enrolledBatches = data['batches'] ?? [];
          });
        }
      }
    } catch (_) {}
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
        Uri.parse(ApiConstants.baseUrl + '/student/feedbacks?page=$page'),
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

  void _showGiveFeedbackModal() {
    int selectedRating = 0;
    int? selectedBatchId;
    final messageController = TextEditingController();
    bool isSaving = false;

    String getRatingText(int rating) {
      switch (rating) {
        case 1: return "Poor";
        case 2: return "Fair";
        case 3: return "Average";
        case 4: return "Good";
        case 5: return "Excellent!";
        default: return "Select Rating";
      }
    }

    Color getRatingColor(int rating) {
      switch (rating) {
        case 1: return Colors.red;
        case 2: return Colors.orange;
        case 3: return Colors.amber;
        case 4: return Colors.lightGreen;
        case 5: return Colors.green;
        default: return Colors.grey;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Give Feedback',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (!isSaving)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < selectedRating ? Icons.star : Icons.star_border,
                                  color: index < selectedRating ? getRatingColor(selectedRating) : Colors.grey,
                                  size: 40,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    selectedRating = index + 1;
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getRatingText(selectedRating),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selectedRating > 0 ? getRatingColor(selectedRating) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_enrolledBatches.isNotEmpty) ...[
                      Text(
                        'Select Batch (Optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _enrolledBatches.map((batch) {
                          final isSelected = selectedBatchId == batch['id'];
                          return ChoiceChip(
                            label: Text(batch['name']),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                            onSelected: (selected) {
                              setModalState(() {
                                selectedBatchId = selected ? batch['id'] : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Your Feedback',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        hintText: 'Share your experience...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isSaving ? null : () async {
                          if (selectedRating == 0) {
                            SnackbarHelper.showError(context, 'Please select a rating');
                            return;
                          }
                          if (messageController.text.trim().isEmpty) {
                            SnackbarHelper.showError(context, 'Please enter a message');
                            return;
                          }

                          setModalState(() => isSaving = true);
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('auth_token');

                          try {
                            final response = await http.post(
                              Uri.parse(ApiConstants.baseUrl + '/student/feedbacks'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Accept': 'application/json',
                                'Content-Type': 'application/json'
                              },
                              body: jsonEncode({
                                'rating': selectedRating,
                                'message': messageController.text.trim(),
                                if (selectedBatchId != null) 'batch_id': selectedBatchId,
                              }),
                            );

                            if (response.statusCode == 201) {
                              Navigator.pop(context);
                              _fetchFeedbacks();
                              SnackbarHelper.showSuccess(context, 'Feedback submitted successfully!');
                            } else {
                              SnackbarHelper.showError(context, 'Failed to submit feedback');
                            }
                          } catch (e) {
                            SnackbarHelper.showError(context, 'Network error');
                          } finally {
                            if (mounted) setModalState(() => isSaving = false);
                          }
                        },
                        child: isSaving
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StudentLayout(
      title: 'Feedbacks',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showGiveFeedbackModal,
          icon: const Icon(Icons.add_comment),
          label: const Text('Give Feedback'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (_feedbacks.isEmpty)
                      const Expanded(child: Center(child: Text('No feedbacks submitted yet.')))
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(5, (starIndex) {
                                            return Icon(
                                              starIndex < fb['rating'] ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                              size: 20,
                                            );
                                          }),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateTime.parse(fb['created_at']).toLocal().toString().split(' ')[0],
                                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                        ),
                                      ],
                                    ),
                                    if (fb['batch'] != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Batch: ${fb['batch']['name']}',
                                          style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Text(fb['message'], style: const TextStyle(fontSize: 16)),
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
