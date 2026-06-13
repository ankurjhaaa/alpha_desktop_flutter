import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/snackbar_helper.dart';
import 'exam_result_page.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class ExamTakingPage extends StatefulWidget {
  final int paperId;
  final List<dynamic> questions;

  const ExamTakingPage({
    super.key,
    required this.paperId,
    required this.questions,
  });

  @override
  State<ExamTakingPage> createState() => _ExamTakingPageState();
}

class _ExamTakingPageState extends State<ExamTakingPage> {
  // Map of question ID to selected option (A, B, C, D)
  final Map<int, String> _answers = {};
  bool _isSubmitting = false;

  int _currentIndex = 0;

  void _submitExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: const Text('Are you sure you want to submit your answers? You cannot change them after submission.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + '/student/exams/${widget.paperId}/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'answers': _answers.map((key, value) => MapEntry(key.toString(), value)),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ExamResultPage(result: result),
            ),
          );
        }
      } else {
        if (mounted) SnackbarHelper.showError(context, 'Failed to submit exam.');
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Network Error.');
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam')),
        body: const Center(child: Text('No questions found for this exam.')),
      );
    }

    final question = widget.questions[_currentIndex];
    final qId = question['id'] as int;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${widget.questions.length}'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back accidentally
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitExam,
            child: const Text('Finish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${_currentIndex + 1} of ${widget.questions.length}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${(((_currentIndex + 1) / widget.questions.length) * 100).toInt()}% Completed',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (_currentIndex + 1) / widget.questions.length,
                              minHeight: 8,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            question['question_text'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.4),
                          ),
                          const SizedBox(height: 48),
                          ...['A', 'B', 'C', 'D'].map((optionLetter) {
                            final optionText = question['option_${optionLetter.toLowerCase()}'];
                            if (optionText == null || optionText.toString().isEmpty) return const SizedBox();

                            final isSelected = _answers[qId] == optionLetter;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _answers[qId] = optionLetter;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Theme.of(context).dividerColor.withOpacity(0.1),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.08) 
                                        : Theme.of(context).colorScheme.surface,
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ] : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).scaffoldBackgroundColor,
                                          border: Border.all(
                                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            optionLetter,
                                            style: TextStyle(
                                              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _currentIndex > 0
                                    ? () => setState(() => _currentIndex--)
                                    : null,
                                icon: const Icon(Icons.arrow_back, size: 20),
                                label: const Text('Previous'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              if (_currentIndex < widget.questions.length - 1)
                                ElevatedButton.icon(
                                  onPressed: () => setState(() => _currentIndex++),
                                  icon: const Icon(Icons.arrow_forward, size: 20),
                                  label: const Text('Next'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _submitExam,
                                  icon: const Icon(Icons.check_circle, size: 20),
                                  label: const Text('Submit Exam'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
