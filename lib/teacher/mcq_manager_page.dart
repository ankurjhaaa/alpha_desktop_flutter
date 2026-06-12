import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'mcq_question_manager_page.dart';
import 'mcq_paper_results_page.dart';

class McqManagerPage extends StatefulWidget {
  const McqManagerPage({super.key});

  @override
  State<McqManagerPage> createState() => _McqManagerPageState();
}

class _McqManagerPageState extends State<McqManagerPage> {
  List<dynamic> _papers = [];
  List<dynamic> _batches = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String? _selectedCourseId;
  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final coursesRes = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final batchesRes = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final papersUri = Uri.parse('http://127.0.0.1:8000/api/mcq_papers')
          .replace(
            queryParameters: {
              if (_searchQuery.isNotEmpty) 'search': _searchQuery,
              if (_statusFilter != 'all')
                'is_active': _statusFilter == 'active' ? 'true' : 'false',
              if (_selectedCourseId != null) 'course_id': _selectedCourseId,
              if (_selectedBatchId != null) 'batch_id': _selectedBatchId,
            },
          );

      final papersRes = await http.get(
        papersUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (coursesRes.statusCode == 200 &&
          batchesRes.statusCode == 200 &&
          papersRes.statusCode == 200) {
        setState(() {
          _courses = jsonDecode(coursesRes.body);
          _batches = jsonDecode(batchesRes.body);

          List<dynamic> fetchedPapers = jsonDecode(papersRes.body);
          // Sort by latest (descending ID)
          fetchedPapers.sort((a, b) => b['id'].compareTo(a['id']));
          _papers = fetchedPapers;

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) SnackbarHelper.showError(context, 'Failed to fetch data.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        SnackbarHelper.showError(context, 'Network error while fetching data.');
    }
  }

  Future<void> _deletePaper(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this paper? All its questions will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/api/mcq_papers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _fetchData();
        SnackbarHelper.showSuccess(context, 'Paper deleted successfully.');
      } else {
        SnackbarHelper.showError(context, 'Failed to delete paper.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while deleting paper.');
    }
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    final actionText = currentStatus ? 'Deactivate' : 'Activate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Confirm $actionText'),
        content: Text(
          'Are you sure you want to ${actionText.toLowerCase()} this paper?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: currentStatus ? Colors.red : Colors.green,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/mcq_papers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_active': !currentStatus}),
      );

      if (response.statusCode == 200) {
        _fetchData();
        SnackbarHelper.showSuccess(
          context,
          'Paper ${currentStatus ? 'deactivated' : 'activated'} successfully.',
        );
      } else {
        SnackbarHelper.showError(context, 'Failed to update status.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while updating status.');
    }
  }

  void _showPaperModal({Map<String, dynamic>? paper}) {
    final isEdit = paper != null;
    final titleController = TextEditingController(
      text: isEdit ? paper['title'] : '',
    );
    final descController = TextEditingController(
      text: isEdit ? paper['description'] : '',
    );
    final dateController = TextEditingController(
      text: isEdit ? (paper['exam_date'] ?? '') : '',
    );
    final passwordController = TextEditingController(
      text: isEdit ? (paper['exam_password'] ?? '') : '',
    );
    int? selectedBatchId = isEdit
        ? paper['batch_id']
        : (_batches.isNotEmpty ? _batches.first['id'] : null);
    bool isActive = isEdit
        ? (paper['is_active'] == 1 || paper['is_active'] == true)
        : true;

    if (_batches.isEmpty) {
      SnackbarHelper.showError(context, 'Please create a batch first!');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                        Text(
                          isEdit ? 'Edit MCQ Paper' : 'Create MCQ Paper',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Batch',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedBatchId,
                      isExpanded: true,
                      items: _batches.map<DropdownMenuItem<int>>((b) {
                        return DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text(
                            '${b['name']} (${b['course']?['name'] ?? 'Course'})',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedBatchId = val;
                        });
                      },
                      decoration: InputDecoration(
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
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Paper Title',
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
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateController,
                            readOnly: true,
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                // format as yyyy-mm-dd
                                dateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Exam Date (Optional)',
                              suffixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Exam Password (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                      child: SwitchListTile(
                        title: const Text('Is Active'),
                        value: isActive,
                        onChanged: (val) {
                          setModalState(() {
                            isActive = val;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
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
                        const SizedBox(width: 16),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.isEmpty ||
                                  selectedBatchId == null)
                                return;

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token');

                              final url = isEdit
                                  ? 'http://127.0.0.1:8000/api/mcq_papers/${paper['id']}'
                                  : 'http://127.0.0.1:8000/api/mcq_papers';

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
                                    'batch_id': selectedBatchId,
                                    'title': titleController.text,
                                    'description': descController.text,
                                    'is_active': isActive,
                                    'exam_date': dateController.text.isNotEmpty ? dateController.text : null,
                                    'exam_password': passwordController.text.isNotEmpty ? passwordController.text : null,
                                  }),
                                );

                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  if (mounted) Navigator.pop(context);
                                  _fetchData();
                                  SnackbarHelper.showSuccess(
                                    context,
                                    isEdit
                                        ? 'Paper updated successfully.'
                                        : 'Paper created successfully.',
                                  );
                                } else {
                                  SnackbarHelper.showError(
                                    context,
                                    'Failed to save paper. Check inputs.',
                                  );
                                }
                              } catch (e) {
                                SnackbarHelper.showError(
                                  context,
                                  'Network error while saving paper.',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 18,
                              ),
                              minimumSize: const Size(160, 54),
                            ),
                            child: Text(
                              isEdit ? 'Save Changes' : 'Create Paper',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
    return TeacherLayout(
      title: 'MCQ Papers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MCQ Paper Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create question papers and assign them to batches. Click a paper to manage its questions.',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      height: 48,
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedCourseId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          hintText: 'All Courses',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Courses'),
                          ),
                          ..._courses.map(
                            (c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(c['name']),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseId = val;
                            _selectedBatchId = null;
                          });
                          _fetchData();
                        },
                      ),
                    ),
                    if (_selectedCourseId != null)
                      SizedBox(
                        height: 48,
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedBatchId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            hintText: 'All Batches',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Batches'),
                            ),
                            ..._batches
                                .where(
                                  (b) =>
                                      b['course_id'].toString() ==
                                      _selectedCourseId,
                                )
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b['id'].toString(),
                                    child: Text(b['name']),
                                  ),
                                ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedBatchId = val);
                            _fetchData();
                          },
                        ),
                      ),
                    SizedBox(
                      height: 48,
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _statusFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Statuses'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active Only'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive Only'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _statusFilter = val);
                            _fetchData();
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search papers...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                          _fetchData();
                        },
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaperModal(),
                          icon: const Icon(Icons.note_add),
                          label: const Text('New Paper'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _papers.isEmpty
                ? const Center(child: Text('No MCQ papers found.'))
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
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                                headingRowColor: WidgetStateProperty.all(
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.05),
                                ),
                                dataRowColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                dividerThickness: 1,
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                headingTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                dataRowMinHeight: 80,
                                dataRowMaxHeight: 90,
                                columns: const [
                                  DataColumn(label: Text('S.No')),
                                  DataColumn(label: Text('Paper Title')),
                                  DataColumn(label: Text('Batch')),
                                  DataColumn(label: Text('Exam Date')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _papers.asMap().entries.map<DataRow>((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final paper = entry.value;
                                  final isActive =
                                      paper['is_active'] == 1 ||
                                      paper['is_active'] == true;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${index + 1}')),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              paper['title'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (paper['description'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Text(
                                                  paper['description'].length >
                                                          50
                                                      ? '${paper['description'].substring(0, 50)}...'
                                                      : paper['description'],
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            paper['batch'] != null
                                                ? paper['batch']['name']
                                                : 'No Batch',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          paper['exam_date'] ?? 'Not set',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: paper['exam_date'] != null
                                                ? Theme.of(context).colorScheme.onSurface
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          McqQuestionManagerPage(
                                                            paper: paper,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.list_alt,
                                                  size: 16,
                                                ),
                                                label: const Text('Questions'),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  elevation: 0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  // TODO: Import McqPaperResultsPage and navigate
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          McqPaperResultsPage(
                                                            paperId: paper['id'],
                                                            paperTitle: paper['title'],
                                                          ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.bar_chart,
                                                  size: 16,
                                                ),
                                                label: const Text('Results'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.purple.withOpacity(0.1),
                                                  foregroundColor: Colors.purple,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  elevation: 0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: Icon(
                                                  isActive
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                  size: 20,
                                                ),
                                                color: isActive
                                                    ? Colors.green
                                                    : Colors.grey,
                                                tooltip: isActive
                                                    ? 'Mark Inactive'
                                                    : 'Mark Active',
                                                onPressed: () => _toggleStatus(
                                                  paper['id'],
                                                  isActive,
                                                ),
                                                splashRadius: 20,
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                ),
                                                color: Colors.blue,
                                                tooltip: 'Edit Paper',
                                                onPressed: () =>
                                                    _showPaperModal(
                                                      paper: paper,
                                                    ),
                                                splashRadius: 20,
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                ),
                                                color: Colors.red,
                                                tooltip: 'Delete Paper',
                                                onPressed: () =>
                                                    _deletePaper(paper['id']),
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
}
