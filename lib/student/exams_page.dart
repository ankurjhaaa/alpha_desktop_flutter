import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/student_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'exam_taking_page.dart';
import 'leaderboard_page.dart';
import 'exam_answers_page.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  List<dynamic> _exams = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedStatus = 'All'; // All, Pending, Completed
  String _selectedBatch = 'All';
  List<String> _uniqueBatches = ['All'];

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
        Uri.parse(ApiConstants.baseUrl + '/student/exams'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedExams = jsonDecode(response.body);
        fetchedExams.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
        
        final Set<String> batches = {'All'};
        for (var e in fetchedExams) {
          if (e['batch'] != null && e['batch']['name'] != null) {
            batches.add(e['batch']['name']);
          }
        }

        setState(() {
          _exams = fetchedExams;
          _uniqueBatches = batches.toList();
          if (!_uniqueBatches.contains(_selectedBatch)) {
            _selectedBatch = 'All';
          }
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



    if (exam['end_time'] != null) {
      final endTime = DateTime.parse(exam['end_time'] as String).toLocal();
      if (DateTime.now().isAfter(endTime)) {
        SnackbarHelper.showError(context, 'This exam has already ended.');
        return;
      }
    }

    if (exam['requires_password']) {
      _showPasswordDialog(exam);
    } else {
      _startExam(exam);
    }
  }

  void _showPasswordDialog(Map<String, dynamic> exam) {
    final pwdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  const Text('Enter Exam Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This exam is password protected. Please enter the password provided by your teacher.',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: pwdController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (pwdController.text.isEmpty) return;
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('auth_token');

                      try {
                        final response = await http.post(
                          Uri.parse(ApiConstants.baseUrl + '/student/exams/${exam["id"]}/verify'),
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
                            _navigateToExam(exam, data['questions']);
                          }
                        } else {
                          if (context.mounted) SnackbarHelper.showError(context, 'Invalid Password');
                        }
                      } catch (e) {
                        if (context.mounted) SnackbarHelper.showError(context, 'Network Error');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startExam(Map<String, dynamic> exam) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + '/student/exams/${exam['id']}/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          final data = jsonDecode(response.body);
          _navigateToExam(exam, data['questions']);
        }
      } else {
        if (mounted) SnackbarHelper.showError(context, 'Failed to start exam.');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Network Error');
    }
  }

  void _navigateToExam(Map<String, dynamic> exam, List<dynamic> questions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamTakingPage(
          paperId: exam['id'],
          questions: questions,
          examData: exam,
        ),
      ),
    ).then((_) => _fetchExams()); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StudentLayout(
      title: 'Exams',
      child: SizedBox(
        width: double.infinity,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (context) {
                  final filteredExams = _exams.where((exam) {
                    final isCompleted = exam['is_completed'] == true;
                    
                    // Status Filter
                    bool matchesStatus = true;
                    if (_selectedStatus == 'Pending') {
                      matchesStatus = !isCompleted;
                    } else if (_selectedStatus == 'Completed') {
                      matchesStatus = isCompleted;
                    }

                    // Batch Filter
                    final matchesBatch = _selectedBatch == 'All' || (exam['batch'] != null && exam['batch']['name'] == _selectedBatch);

                    // Search Filter
                    final matchesSearch = _searchQuery.isEmpty ||
                        (exam['title']?.toLowerCase() ?? '').contains(_searchQuery) ||
                        (exam['description']?.toLowerCase() ?? '').contains(_searchQuery);
                        
                    return matchesStatus && matchesBatch && matchesSearch;
                  }).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Tabs & Search
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 800;

                            final filterChips = Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...['All', 'Pending', 'Completed'].map((status) {
                                  final isSelected = _selectedStatus == status;
                                  return ChoiceChip(
                                    label: Text(status),
                                    selected: isSelected,
                                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedStatus = status);
                                      }
                                    },
                                  );
                                }).toList(),
                                if (!isMobile)
                                  Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
                                ..._uniqueBatches.map((batchName) {
                                  final isSelected = _selectedBatch == batchName;
                                  return ChoiceChip(
                                    label: Text(batchName),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedBatch = batchName);
                                      }
                                    },
                                  );
                                }).toList(),
                              ],
                            );

                            final searchBox = SizedBox(
                              height: 48,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search exams...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val.toLowerCase());
                                },
                              ),
                            );

                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  filterChips,
                                  const SizedBox(height: 16),
                                  searchBox,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(flex: 3, child: filterChips),
                                const SizedBox(width: 16),
                                Expanded(flex: 1, child: searchBox),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        if (filteredExams.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(64.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No matching exams found',
                                    style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth > 800;
                              final crossAxisCount = isDesktop ? 3 : 1;
                              final width = (constraints.maxWidth - (32 * (crossAxisCount - 1))) / crossAxisCount;

                              return Wrap(
                                spacing: 32,
                                runSpacing: 32,
                                children: filteredExams.map((exam) {
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
                  );
                }
              ),
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam, ThemeData theme) {
    final isCompleted = exam['is_completed'] == true;
    


    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                if (exam['requires_password'] && !isCompleted)
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
            if (isCompleted)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExamAnswersPage(
                                paperId: exam['id'],
                                paperTitle: exam['title'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface,
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                        child: const Text('View Answers', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _handleExamClick(exam),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _handleExamClick(exam),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Start Exam',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
