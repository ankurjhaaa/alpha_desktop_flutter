import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class StudentExamAnswersPage extends StatefulWidget {
  final int paperId;
  final int userId;
  final String studentName;

  const StudentExamAnswersPage({
    super.key,
    required this.paperId,
    required this.userId,
    required this.studentName,
  });

  @override
  State<StudentExamAnswersPage> createState() => _StudentExamAnswersPageState();
}

class _StudentExamAnswersPageState extends State<StudentExamAnswersPage> {
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
        Uri.parse(ApiConstants.baseUrl + '/mcq_papers/${widget.paperId}/results/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data['result'];
          _questions = data['questions'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TeacherLayout(
      title: '${widget.studentName}\'s Attempt',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? const Center(child: Text('Failed to load answers.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reviewing ${widget.studentName}\'s Answers',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Score: ${_result!['score']} / ${_result!['total_questions']} (${double.parse(_result!['percentage'].toString()).toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
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
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Q${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        question['question_text'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          height: 1.5,
                                        ),
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
                                    const Icon(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$optKey.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            color: isSelected || isActualCorrect ? textColor : theme.colorScheme.onSurface,
                                            fontWeight: isSelected || isActualCorrect ? FontWeight.w600 : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          isCorrect ? Icons.check : Icons.close,
                                          color: textColor,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
