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

    // Check date
    // Check date and time constraints
    if (exam['start_time'] != null) {
      final startTime = DateTime.parse(exam['start_time'] as String).toLocal();
      if (DateTime.now().isBefore(startTime)) {
        SnackbarHelper.showError(context, 'This exam is locked until ${startTime.toString().substring(0, 16)}');
        return;
      }
    } else if (exam['exam_date'] != null) {
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
                        const Text(
                          'Available Exams',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unlock and complete your pending exams.',
                          style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 32),
                        
                        // Filter Tabs & Search
                        Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...['All', 'Pending', 'Completed'].map((status) {
                                      final isSelected = _selectedStatus == status;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: ChoiceChip(
                                          label: Text(status),
                                          selected: isSelected,
                                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() => _selectedStatus = status);
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                    Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                                    ..._uniqueBatches.map((batchName) {
                                      final isSelected = _selectedBatch == batchName;
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 12.0),
                                        child: ChoiceChip(
                                          label: Text(batchName),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() => _selectedBatch = batchName);
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 300,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search exams...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val.toLowerCase());
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        
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
                  child: Text(
                    isLocked ? 'Locked' : 'Start Exam',
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
