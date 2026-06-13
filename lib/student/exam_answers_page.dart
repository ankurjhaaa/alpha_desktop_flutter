import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/student_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class ExamAnswersPage extends StatefulWidget {
  final int paperId;
  final String paperTitle;

  const ExamAnswersPage({
    super.key,
    required this.paperId,
    required this.paperTitle,
  });

  @override
  State<ExamAnswersPage> createState() => _ExamAnswersPageState();
}

class _ExamAnswersPageState extends State<ExamAnswersPage> {
  Map<String, dynamic>? _result;
  List<dynamic> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnswers();
  }

  Future<void> _fetchAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/student/exams/${widget.paperId}/answers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          final data = jsonDecode(response.body);
          setState(() {
            _result = data['result'];
            _questions = data['questions'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarHelper.showError(context, 'Failed to load answers.');
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
      title: 'Exam Answers',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('Could not load exam answers.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back to Exams'),
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
                        // Back button + Header
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Back to Exams',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Review Answers',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.paperTitle,
                                    style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_result!['score']}/${_result!['total_questions']}',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                  Text(
                                    '${_result!['percentage']}%',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Questions
                        ..._questions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final question = entry.value;
                          final rawAnswers = _result!['student_answers'];
                          Map<dynamic, dynamic> studentAnswers = {};
                          if (rawAnswers is Map) {
                            studentAnswers = rawAnswers;
                          } else if (rawAnswers is String) {
                            try {
                              studentAnswers = jsonDecode(rawAnswers);
                            } catch (_) {}
                          }
                          
                          final selectedOption = studentAnswers[question['id'].toString()];
                          String? correctOptionStr = question['correct_option']?.toString().toLowerCase().trim();
                          if (correctOptionStr != null) {
                            correctOptionStr = correctOptionStr.replaceAll('option_', '').replaceAll('option ', '');
                          }

                          final isCorrect = selectedOption?.toString().toLowerCase().trim() == correctOptionStr;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          question['question_text'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (selectedOption != null)
                                      Icon(
                                        isCorrect ? Icons.check_circle : Icons.cancel,
                                        color: isCorrect ? Colors.green : Colors.red,
                                        size: 28,
                                      )
                                    else
                                      Icon(
                                        Icons.help_outline,
                                        color: Colors.orange,
                                        size: 28,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ...['A', 'B', 'C', 'D'].map((optKey) {
                                  final text = question['option_${optKey.toLowerCase()}'];
                                  if (text == null || text.isEmpty) return const SizedBox.shrink();

                                  final isSelected = selectedOption?.toString().toLowerCase().trim() == optKey.toLowerCase();
                                  final isActualCorrect = correctOptionStr == optKey.toLowerCase();

                                  Color bgColor = theme.scaffoldBackgroundColor;
                                  Color borderColor = theme.dividerColor.withOpacity(0.1);
                                  Color textColor = theme.colorScheme.onSurface;

                                  if (isActualCorrect) {
                                    bgColor = Colors.green.withOpacity(0.1);
                                    borderColor = Colors.green;
                                    textColor = Colors.green;
                                  } else if (isSelected && !isCorrect) {
                                    bgColor = Colors.red.withOpacity(0.1);
                                    borderColor = Colors.red;
                                    textColor = Colors.red;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '$optKey.',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            text,
                                            style: TextStyle(color: textColor, fontWeight: isSelected || isActualCorrect ? FontWeight.w600 : FontWeight.normal),
                                          ),
                                        ),
                                        if (isActualCorrect)
                                          const Icon(Icons.check, color: Colors.green, size: 20)
                                        else if (isSelected && !isCorrect)
                                          const Icon(Icons.close, color: Colors.red, size: 20),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
    );
  }
}
