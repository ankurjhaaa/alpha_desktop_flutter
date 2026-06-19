import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/snackbar_helper.dart';
import '../core/utils/modal_helper.dart';
import '../layout/teacher_layout.dart';

class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  bool _isLoading = false;
  List<dynamic> _courses = [];
  List<dynamic> _topics = [];
  List<dynamic> _questions = [];

  int? _selectedCourseId;
  int? _selectedTopicId;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/courses'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        setState(() => _courses = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTopics(int courseId) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/topics?course_id=$courseId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _topics = jsonDecode(res.body);
          _selectedTopicId = null;
          _questions = [];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchQuestions() async {
    if (_selectedCourseId == null || _selectedTopicId == null) return;
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/question-bank?course_id=$_selectedCourseId&topic_id=$_selectedTopicId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        setState(() => _questions = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImportJsonModal() {
    if (_selectedCourseId == null || _selectedTopicId == null) {
      SnackbarHelper.showError(context, 'Please select Course and Topic first.');
      return;
    }

    final TextEditingController jsonController = TextEditingController();
    bool isSubmitting = false;

    ModalHelper.showRightSideModal(
      context: context,
      title: 'Import JSON Questions',
      contentBuilder: (context, setModalStateOuter) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Paste your JSON array here:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        const format = '[\n  {\n    "question": "Sample?",\n    "options": ["A", "B", "C", "D"],\n    "correct_answer": "A"\n  }\n]';
                        Clipboard.setData(const ClipboardData(text: format));
                        SnackbarHelper.showSuccess(context, 'JSON format copied to clipboard!');
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Format'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonController,
                  minLines: 15,
                  maxLines: 25,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: '[\n  {\n    "question": "Sample?",\n    "options": ["A", "B", "C", "D"],\n    "correct_answer": "A"\n  }\n]',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
      actionBuilder: (context, setModalState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (jsonController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Please paste JSON data.');
                  return;
                }

                setModalState(() => isSubmitting = true);

                try {
                  final jsonData = jsonDecode(jsonController.text.trim());

                  if (jsonData is! List) {
                    SnackbarHelper.showError(context, 'Invalid JSON format. Expected an array of questions.');
                    setModalState(() => isSubmitting = false);
                    return;
                  }

                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');
                  final res = await http.post(
                    Uri.parse('${ApiConstants.baseUrl}/question-bank/import'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Accept': 'application/json',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'course_id': _selectedCourseId,
                      'topic_id': _selectedTopicId,
                      'questions': jsonData,
                    }),
                  );

                  if (res.statusCode == 200) {
                    final data = jsonDecode(res.body);
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackbarHelper.showSuccess(context, data['message'] ?? 'Import successful');
                      _fetchQuestions();
                    }
                  } else {
                    if (context.mounted) {
                      SnackbarHelper.showError(context, 'Failed to import. Check format.');
                    }
                  }
                } catch (e) {
                  if (context.mounted) SnackbarHelper.showError(context, 'Error parsing JSON file. Make sure it is a valid JSON array.');
                } finally {
                  if (context.mounted) setModalState(() => isSubmitting = false);
                }
              },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Import Questions'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteQuestion(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      try {
        final res = await http.delete(
          Uri.parse('${ApiConstants.baseUrl}/question-bank/$id'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        );
        if (res.statusCode == 204) {
          if (mounted) {
            SnackbarHelper.showSuccess(context, 'Question deleted successfully');
            _fetchQuestions();
          }
        } else {
          if (mounted) SnackbarHelper.showError(context, 'Failed to delete question');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  void _showEditQuestionModal(Map<String, dynamic> q) {
    final TextEditingController questionController = TextEditingController(text: q['question_text']);
    
    // Ensure we have 4 options
    List<dynamic> options = q['options'] ?? [];
    while (options.length < 4) {
      options.add('');
    }
    
    final TextEditingController optionAController = TextEditingController(text: options[0].toString());
    final TextEditingController optionBController = TextEditingController(text: options[1].toString());
    final TextEditingController optionCController = TextEditingController(text: options[2].toString());
    final TextEditingController optionDController = TextEditingController(text: options[3].toString());
    
    String correctOptionRaw = (q['correct_answer'] ?? 'A').toString();
    String correctOption = 'A';
    if (['A', 'B', 'C', 'D', 'a', 'b', 'c', 'd'].contains(correctOptionRaw)) {
      correctOption = correctOptionRaw.toUpperCase();
    } else {
      int index = options.indexWhere((opt) => opt.toString() == correctOptionRaw);
      if (index >= 0 && index < 4) {
        correctOption = ['A', 'B', 'C', 'D'][index];
      }
    }
    bool isSubmitting = false;

    ModalHelper.showRightSideModal(
      context: context,
      title: 'Edit Question',
      contentBuilder: (context, setModalStateOuter) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionAController,
                  decoration: const InputDecoration(labelText: 'Option A', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionBController,
                  decoration: const InputDecoration(labelText: 'Option B', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionCController,
                  decoration: const InputDecoration(labelText: 'Option C', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionDController,
                  decoration: const InputDecoration(labelText: 'Option D', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: correctOption,
                  decoration: const InputDecoration(labelText: 'Correct Option', border: OutlineInputBorder()),
                  items: ['A', 'B', 'C', 'D'].map((opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text('Option $opt'),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => correctOption = val);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
      actionBuilder: (context, setModalState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (questionController.text.trim().isEmpty || 
                    optionAController.text.trim().isEmpty || 
                    optionBController.text.trim().isEmpty || 
                    optionCController.text.trim().isEmpty || 
                    optionDController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Please fill all fields');
                  return;
                }

                setModalState(() => isSubmitting = true);

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');
                  final res = await http.put(
                    Uri.parse('${ApiConstants.baseUrl}/question-bank/${q['id']}'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Accept': 'application/json',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'question_text': questionController.text.trim(),
                      'options': [
                        optionAController.text.trim(),
                        optionBController.text.trim(),
                        optionCController.text.trim(),
                        optionDController.text.trim(),
                      ],
                      'correct_answer': correctOption,
                    }),
                  );

                  if (res.statusCode == 200) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackbarHelper.showSuccess(context, 'Question updated successfully');
                      _fetchQuestions();
                    }
                  } else {
                    if (context.mounted) SnackbarHelper.showError(context, 'Failed to update question');
                  }
                } catch (e) {
                  if (context.mounted) SnackbarHelper.showError(context, 'Error updating question');
                } finally {
                  if (context.mounted) setModalState(() => isSubmitting = false);
                }
              },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showAddQuestionModal() {
    final TextEditingController questionController = TextEditingController();
    final TextEditingController optionAController = TextEditingController();
    final TextEditingController optionBController = TextEditingController();
    final TextEditingController optionCController = TextEditingController();
    final TextEditingController optionDController = TextEditingController();
    
    String correctOption = 'A';
    bool isSubmitting = false;

    ModalHelper.showRightSideModal(
      context: context,
      title: 'Add Question Manually',
      contentBuilder: (context, setModalStateOuter) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionAController,
                  decoration: const InputDecoration(labelText: 'Option A', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionBController,
                  decoration: const InputDecoration(labelText: 'Option B', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionCController,
                  decoration: const InputDecoration(labelText: 'Option C', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionDController,
                  decoration: const InputDecoration(labelText: 'Option D', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: correctOption,
                  decoration: const InputDecoration(labelText: 'Correct Option', border: OutlineInputBorder()),
                  items: ['A', 'B', 'C', 'D'].map((opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text('Option $opt'),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => correctOption = val);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
      actionBuilder: (context, setModalState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (questionController.text.trim().isEmpty || 
                    optionAController.text.trim().isEmpty || 
                    optionBController.text.trim().isEmpty || 
                    optionCController.text.trim().isEmpty || 
                    optionDController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Please fill all fields');
                  return;
                }

                setModalState(() => isSubmitting = true);

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');
                  final res = await http.post(
                    Uri.parse('${ApiConstants.baseUrl}/question-bank'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Accept': 'application/json',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'course_id': _selectedCourseId,
                      'topic_id': _selectedTopicId,
                      'question_text': questionController.text.trim(),
                      'options': [
                        optionAController.text.trim(),
                        optionBController.text.trim(),
                        optionCController.text.trim(),
                        optionDController.text.trim(),
                      ],
                      'correct_answer': correctOption,
                    }),
                  );

                  if (res.statusCode == 201) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackbarHelper.showSuccess(context, 'Question added successfully');
                      _fetchQuestions();
                    }
                  } else {
                    if (context.mounted) SnackbarHelper.showError(context, 'Failed to add question');
                  }
                } catch (e) {
                  if (context.mounted) SnackbarHelper.showError(context, 'Error adding question');
                } finally {
                  if (context.mounted) setModalState(() => isSubmitting = false);
                }
              },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Question'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      title: 'Question Bank',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                    ),
                    items: _courses.map((c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']),
                        )).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCourseId = val);
                      if (val != null) _fetchTopics(val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedTopicId,
                    decoration: const InputDecoration(
                      labelText: 'Select Topic',
                      border: OutlineInputBorder(),
                    ),
                    items: _topics.map((t) => DropdownMenuItem<int>(
                          value: t['id'],
                          child: Text(t['title']),
                        )).toList(),
                    onChanged: (val) {
                      setState(() => _selectedTopicId = val);
                      if (val != null) _fetchQuestions();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: (_selectedCourseId != null && _selectedTopicId != null && !_isLoading) ? _showAddQuestionModal : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Manual'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: (_selectedCourseId != null && _selectedTopicId != null && !_isLoading) ? _showImportJsonModal : null,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import JSON'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_questions.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No questions found. Please select course/topic or import questions.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    final List<dynamic> options = q['options'] ?? [];
                    final String correctAnswer = q['correct_answer'] ?? 'A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 14, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q['question_text'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Edit',
                                      onPressed: () => _showEditQuestionModal(q),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteQuestion(q['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 40.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...List.generate(options.length, (i) {
                                    final bool isCorrect = (correctAnswer.toUpperCase() == ['A', 'B', 'C', 'D'][i]) || (correctAnswer == options[i].toString());
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        '${['A', 'B', 'C', 'D'][i]}. ${options[i]}',
                                        style: TextStyle(
                                          color: isCorrect ? Colors.green : null,
                                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Correct Answer: $correctAnswer',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
    );
  }
}
