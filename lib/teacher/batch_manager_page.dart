import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';
import '../core/utils/modal_helper.dart';
import 'students_page.dart';
import 'mcq_manager_page.dart';
import 'material_manager_page.dart';
import 'teacher_dashboard.dart';

class BatchManagerPage extends StatefulWidget {
  final String? initialCourseId;
  const BatchManagerPage({super.key, this.initialCourseId});

  @override
  State<BatchManagerPage> createState() => _BatchManagerPageState();
}

class _BatchManagerPageState extends State<BatchManagerPage> {
  List<dynamic> _batches = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _courseFilter;

  @override
  void initState() {
    super.initState();
    if (widget.initialCourseId != null) {
      _courseFilter = widget.initialCourseId;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final coursesRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final batchUri = Uri.parse(ApiConstants.baseUrl + '/batches').replace(
        queryParameters: {
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
          if (_courseFilter != null) 'course_id': _courseFilter,
        },
      );

      final batchesRes = await http.get(
        batchUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (coursesRes.statusCode == 200 && batchesRes.statusCode == 200) {
        setState(() {
          _courses = jsonDecode(coursesRes.body);
          _batches = jsonDecode(batchesRes.body);
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

  Future<void> _deleteBatch(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this batch? All related papers and students may be affected.',
        ),
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
        Uri.parse(ApiConstants.baseUrl + '/batches/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _fetchData();
        SnackbarHelper.showSuccess(context, 'Batch deleted successfully.');
      } else {
        SnackbarHelper.showError(context, 'Failed to delete batch.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while deleting batch.');
    }
  }


  void _showBatchModal({Map<String, dynamic>? batch}) {
    final isEdit = batch != null;
    final nameController = TextEditingController(
      text: isEdit ? batch['name'] : '',
    );
    final scheduleController = TextEditingController(
      text: isEdit ? batch['schedule_time'] : '',
    );
    int? selectedCourseId = isEdit
        ? batch['course_id']
        : (_courses.isNotEmpty ? _courses.first['id'] : null);
    String? startDate = isEdit ? batch['start_date'] : null;
    String? endDate = isEdit ? batch['end_date'] : null;

    if (_courses.isEmpty) {
      SnackbarHelper.showError(context, 'Please create a course first!');
      return;
    }

    ModalHelper.showRightSideModal(
      context: context,
      title: isEdit ? 'Edit Batch' : 'Add New Batch',
      contentBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    const Text(
                      'Select Course',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedCourseId,
                      isExpanded: true,
                      items: _courses.map<DropdownMenuItem<int>>((course) {
                        return DropdownMenuItem<int>(
                          value: course['id'],
                          child: Text(course['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedCourseId = val;
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
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Batch Name (e.g. Morning Batch 2026)',
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
                      controller: scheduleController,
                      decoration: InputDecoration(
                        labelText: 'Schedule (e.g. 10 AM - 12 PM)',
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
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate != null ? DateTime.parse(startDate!) : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: Text(
                                startDate ?? 'Select Date',
                                style: TextStyle(
                                  color: startDate != null ? null : Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate != null ? DateTime.parse(endDate!) : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  endDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: Text(
                                endDate ?? 'Select Date',
                                style: TextStyle(
                                  color: endDate != null ? null : Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      selectedCourseId == null) {
                    SnackbarHelper.showError(
                      context,
                      'Please fill in the batch name and select a course.',
                    );
                    return;
                  }

                  final prefs =
                      await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');

                  final url = isEdit
                      ? ApiConstants.baseUrl + '/batches/${batch['id']}'
                      : ApiConstants.baseUrl + '/batches';

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
                        'course_id': selectedCourseId,
                        'name': nameController.text,
                        'schedule_time': scheduleController.text,
                        'start_date': startDate,
                        'end_date': endDate,
                        'is_active': true,
                        'is_hidden': false,
                      }),
                    );

                    if (response.statusCode == 201 ||
                        response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
                      _fetchData();
                      SnackbarHelper.showSuccess(
                        context,
                        isEdit
                            ? 'Batch updated successfully.'
                            : 'Batch added successfully.',
                      );
                    } else if (response.statusCode == 422) {
                      final data = jsonDecode(response.body);
                      String errorMsg =
                          data['message'] ?? 'Validation error.';
                      if (data['errors'] != null) {
                        final errors =
                            data['errors'] as Map<String, dynamic>;
                        if (errors.isNotEmpty) {
                          errorMsg = errors.values.first[0];
                        }
                      }
                      SnackbarHelper.showError(context, errorMsg);
                    } else {
                      SnackbarHelper.showError(
                        context,
                        'Failed to save batch. Check inputs.',
                      );
                    }
                  } catch (e) {
                    SnackbarHelper.showError(
                      context,
                      'Network error while saving batch.',
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
                  isEdit ? 'Save Changes' : 'Create Batch',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
      title: 'Batches',
      onBackPressed: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                final courseFilter = SizedBox(
                  height: 48,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _courses.any((c) => c['id'].toString() == _courseFilter) ? _courseFilter : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      hintText: 'All Courses',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Courses')),
                      ..._courses.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))),
                    ],
                    onChanged: (val) {
                      setState(() => _courseFilter = val);
                      _fetchData();
                    },
                  ),
                );



                final searchBox = SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search batches...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                      _fetchData();
                    },
                  ),
                );

                final actionBtn = SizedBox(
                  height: 48,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton.icon(
                      onPressed: () => _showBatchModal(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Batch'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      ),
                    ),
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      courseFilter,
                      const SizedBox(height: 16),
                      searchBox,
                      const SizedBox(height: 16),
                      actionBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 1, child: courseFilter),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: searchBox),
                    const SizedBox(width: 16),
                    actionBtn,
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _batches.isEmpty
                ? const Center(child: Text('No batches found.'))
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
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Batch Name')),
                                  DataColumn(label: Text('Course')),
                                  DataColumn(label: Text('Schedule')),
                                  DataColumn(label: Text('Start Date')),
                                  DataColumn(label: Text('End Date')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _batches.map<DataRow>((batch) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(batch['id'].toString())),
                                      DataCell(
                                        Text(
                                          batch['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            batch['course'] != null
                                                ? batch['course']['name']
                                                : 'Unknown',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(batch['schedule_time'] ?? '-'),
                                      ),
                                      DataCell(
                                        Text(batch['start_date'] ?? '-'),
                                      ),
                                      DataCell(
                                        Text(batch['end_date'] ?? '-'),
                                      ),

                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.people,
                                                  color: Colors.purple,
                                                  size: 20,
                                                ),
                                                tooltip: 'View Students',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context, animation, secondaryAnimation) => StudentsPage(initialBatchId: batch['id'].toString()),
                                                      transitionDuration: Duration.zero,
                                                      reverseTransitionDuration: Duration.zero,
                                                    ),
                                                  );
                                                },
                                                splashRadius: 20,
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.quiz,
                                                  color: Colors.orange,
                                                  size: 20,
                                                ),
                                                tooltip: 'View MCQ Papers',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context, animation, secondaryAnimation) => McqManagerPage(initialBatchId: batch['id'].toString()),
                                                      transitionDuration: Duration.zero,
                                                      reverseTransitionDuration: Duration.zero,
                                                    ),
                                                  );
                                                },
                                                splashRadius: 20,
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.library_books,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                tooltip: 'View Materials',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context, animation, secondaryAnimation) => MaterialManagerPage(initialBatchId: batch['id'].toString()),
                                                      transitionDuration: Duration.zero,
                                                      reverseTransitionDuration: Duration.zero,
                                                    ),
                                                  );
                                                },
                                                splashRadius: 20,
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                                tooltip: 'Edit Batch',
                                                onPressed: () =>
                                                    _showBatchModal(
                                                      batch: batch,
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
                                                tooltip: 'Delete Batch',
                                                onPressed: () =>
                                                    _deleteBatch(batch['id']),
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
