import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';
import '../core/utils/modal_helper.dart';

class McqQuestionManagerPage extends StatefulWidget {
  final Map<String, dynamic> paper;

  const McqQuestionManagerPage({super.key, required this.paper});

  @override
  State<McqQuestionManagerPage> createState() => _McqQuestionManagerPageState();
}

class _McqQuestionManagerPageState extends State<McqQuestionManagerPage> {
  List<dynamic> _questions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final uri = Uri.parse(ApiConstants.baseUrl + '/mcq_questions').replace(
        queryParameters: {
          'mcq_paper_id': widget.paper['id'].toString(),
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _questions = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted)
          SnackbarHelper.showError(context, 'Failed to fetch questions.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        SnackbarHelper.showError(
          context,
          'Network error while fetching questions.',
        );
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.baseUrl + '/mcq_questions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _fetchQuestions();
        SnackbarHelper.showSuccess(context, 'Question deleted successfully.');
      } else {
        SnackbarHelper.showError(context, 'Failed to delete question.');
      }
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Network error while deleting question.',
      );
    }
  }


  void _showQuestionModal({Map<String, dynamic>? question}) {
    final isEdit = question != null;
    final questionTextController = TextEditingController(
      text: isEdit ? question['question_text'] : '',
    );
    final optionAController = TextEditingController(
      text: isEdit ? question['option_a'] : '',
    );
    final optionBController = TextEditingController(
      text: isEdit ? question['option_b'] : '',
    );
    final optionCController = TextEditingController(
      text: isEdit ? question['option_c'] : '',
    );
    final optionDController = TextEditingController(
      text: isEdit ? question['option_d'] : '',
    );
    String selectedOption = isEdit ? question['correct_option'] : 'a';

    ModalHelper.showRightSideModal(
      context: context,
      title: isEdit ? 'Edit Question' : 'Add Question',
      contentBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    TextField(
                      controller: questionTextController,
                      decoration: InputDecoration(
                        labelText: 'Question Text',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: optionAController,
                      decoration: InputDecoration(
                        labelText: 'Option A',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: optionBController,
                      decoration: InputDecoration(
                        labelText: 'Option B',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: optionCController,
                      decoration: InputDecoration(
                        labelText: 'Option C',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: optionDController,
                      decoration: InputDecoration(
                        labelText: 'Option D',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedOption,
                      decoration: InputDecoration(
                        labelText: 'Correct Option',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'a', child: Text('Option A')),
                        DropdownMenuItem(value: 'b', child: Text('Option B')),
                        DropdownMenuItem(value: 'c', child: Text('Option C')),
                        DropdownMenuItem(value: 'd', child: Text('Option D')),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedOption = val);
                      },
                    ),
                    const SizedBox(height: 32),
          ],
        );
      },
      actionBuilder: (context, setModalState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  minimumSize: const Size(120, 54),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () async {
                  if (questionTextController.text.isEmpty) return;

                  final prefs =
                      await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');

                  final url = isEdit
                      ? ApiConstants.baseUrl + '/mcq_questions/${question['id']}'
                      : ApiConstants.baseUrl + '/mcq_questions';

                  final requestMethod = isEdit
                      ? http.put
                      : http.post;

                  try {
                    final response = await requestMethod(
                      Uri.parse(url),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'mcq_paper_id': widget.paper['id'],
                        'question_text':
                            questionTextController.text,
                        'option_a': optionAController.text,
                        'option_b': optionBController.text,
                        'option_c': optionCController.text,
                        'option_d': optionDController.text,
                        'correct_option': selectedOption,
                        'is_active': true,
                      }),
                    );

                    if (response.statusCode == 201 ||
                        response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
                      _fetchQuestions();
                      SnackbarHelper.showSuccess(
                        context,
                        isEdit
                            ? 'Question updated.'
                            : 'Question created.',
                      );
                    } else {
                      SnackbarHelper.showError(
                        context,
                        'Failed to save question. Check inputs.',
                      );
                    }
                  } catch (e) {
                    SnackbarHelper.showError(
                      context,
                      'Network error while saving question.',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  minimumSize: const Size(120, 54),
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Save Question',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showJsonImportModal() {
    final jsonController = TextEditingController();

    ModalHelper.showRightSideModal(
      context: context,
      title: 'Import Questions via JSON',
      contentBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a JSON array of questions here. Each question must have:\n'
              '"question_text", "option_a", "option_b", "option_c", "option_d", "correct_option" (a/b/c/d).',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jsonController,
              decoration: InputDecoration(
                labelText: 'JSON Data',
                hintText: '[\n  {\n    "question_text": "Sample Question",\n    "option_a": "A",\n    "option_b": "B",\n    "option_c": "C",\n    "option_d": "D",\n    "correct_option": "a"\n  }\n]',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 15,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
      actionBuilder: (context, setModalState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  minimumSize: const Size(120, 54),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () async {
                  if (jsonController.text.trim().isEmpty) return;

                  List<dynamic> jsonList;
                  try {
                    jsonList = jsonDecode(jsonController.text);
                    if (jsonList is! List) {
                      throw const FormatException('Expected a JSON array.');
                    }
                  } catch (e) {
                    SnackbarHelper.showError(context, 'Invalid JSON format. Expected an array of objects.');
                    return;
                  }

                  // Validate each question
                  for (int i = 0; i < jsonList.length; i++) {
                    final item = jsonList[i];
                    if (item is! Map) {
                      SnackbarHelper.showError(context, 'Item at index $i is not an object.');
                      return;
                    }
                    final requiredKeys = ['question_text', 'option_a', 'option_b', 'option_c', 'option_d', 'correct_option'];
                    for (final key in requiredKeys) {
                      if (!item.containsKey(key) || item[key] == null || item[key].toString().trim().isEmpty) {
                        SnackbarHelper.showError(context, 'Question $i is missing required key: $key');
                        return;
                      }
                    }
                    final correct = item['correct_option'].toString().toLowerCase().trim();
                    if (!['a', 'b', 'c', 'd'].contains(correct)) {
                      SnackbarHelper.showError(context, 'Question $i has invalid correct_option. Must be a, b, c, or d.');
                      return;
                    }
                    
                    item['correct_option'] = correct;
                    item['mcq_paper_id'] = widget.paper['id'];
                    item['is_active'] = true;
                  }

                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');

                  try {
                    final response = await http.post(
                      Uri.parse(ApiConstants.baseUrl + '/mcq_questions/bulk'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({'questions': jsonList}),
                    );

                    if (response.statusCode == 201 || response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
                      _fetchQuestions();
                      SnackbarHelper.showSuccess(context, 'Successfully imported ${jsonList.length} questions.');
                    } else {
                      SnackbarHelper.showError(context, 'Failed to import questions. Server returned: ${response.statusCode}');
                    }
                  } catch (e) {
                    SnackbarHelper.showError(context, 'Network error while importing questions.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  minimumSize: const Size(120, 54),
                ),
                child: const Text(
                  'Import JSON',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      title: 'Questions: ${widget.paper['title']}',
      onBackPressed: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                final descriptionText = Text(
                  widget.paper['description'] ?? 'Manage questions here.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                );


                final searchBox = SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search questions...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                      _fetchQuestions();
                    },
                  ),
                );

                final actionBtn = SizedBox(
                  height: 48,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton.icon(
                      onPressed: () => _showQuestionModal(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                );

                final jsonBtn = SizedBox(
                  height: 48,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: OutlinedButton.icon(
                      onPressed: () => _showJsonImportModal(),
                      icon: const Icon(Icons.data_object),
                      label: const Text('Import JSON'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      descriptionText,
                      const SizedBox(height: 16),
                      searchBox,
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: jsonBtn),
                          const SizedBox(width: 8),
                          Expanded(child: actionBtn),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: descriptionText,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: searchBox),
                          const SizedBox(width: 8),
                          jsonBtn,
                          const SizedBox(width: 8),
                          actionBtn,
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                ? const Center(child: Text('No questions added yet.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: Theme.of(context).brightness == Brightness.light
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Theme.of(context).brightness == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                                dataRowColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                dividerThickness: 1,
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                    width: 1,
                                  ),
                                ),
                                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                                columns: const [
                                  DataColumn(label: Text('Q.No')),
                                  DataColumn(label: Text('Question Text')),
                                  DataColumn(label: Text('Options')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _questions.asMap().entries.map<DataRow>((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final question = entry.value;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${index + 1}')),
                                      DataCell(
                                        SizedBox(
                                          width: 300,
                                          child: Text(
                                            question['question_text'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _buildMiniOption(
                                                'A',
                                                question['option_a'],
                                                question['correct_option'] ==
                                                    'a',
                                              ),
                                              const SizedBox(height: 4),
                                              _buildMiniOption(
                                                'B',
                                                question['option_b'],
                                                question['correct_option'] ==
                                                    'b',
                                              ),
                                              const SizedBox(height: 4),
                                              _buildMiniOption(
                                                'C',
                                                question['option_c'],
                                                question['correct_option'] ==
                                                    'c',
                                              ),
                                              const SizedBox(height: 4),
                                              _buildMiniOption(
                                                'D',
                                                question['option_d'],
                                                question['correct_option'] ==
                                                    'd',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [

                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                                tooltip: 'Edit Question',
                                                onPressed: () =>
                                                    _showQuestionModal(
                                                      question: question,
                                                    ),
                                                splashRadius: 20,
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                tooltip: 'Delete Question',
                                                onPressed: () =>
                                                    _deleteQuestion(
                                                      question['id'],
                                                    ),
                                                splashRadius: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniOption(String label, String text, bool isCorrect) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCorrect
                ? Colors.green.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            border: Border.all(
              color: isCorrect ? Colors.green : Colors.grey.withOpacity(0.5),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isCorrect
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
