import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class CourseManagerPage extends StatefulWidget {
  const CourseManagerPage({super.key});

  @override
  State<CourseManagerPage> createState() => _CourseManagerPageState();
}

class _CourseManagerPageState extends State<CourseManagerPage> {
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final uri = Uri.parse(ApiConstants.baseUrl + '/courses').replace(
        queryParameters: {
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
          _courses = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted)
          SnackbarHelper.showError(
            context,
            'Failed to fetch courses. Please try again.',
          );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        SnackbarHelper.showError(
          context,
          'Network error. Please check your connection.',
        );
    }
  }

  Future<void> _deleteCourse(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this course?'),
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
        Uri.parse(ApiConstants.baseUrl + '/courses/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _fetchCourses();
        SnackbarHelper.showSuccess(context, 'Course deleted successfully.');
      } else if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        SnackbarHelper.showError(
          context,
          data['message'] ?? 'Cannot delete course. Active batches exist.',
        );
      } else {
        SnackbarHelper.showError(context, 'Failed to delete course.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while deleting.');
    }
  }


  void _showCourseModal({Map<String, dynamic>? course}) {
    final isEdit = course != null;
    final nameController = TextEditingController(
      text: isEdit ? course['name'] : '',
    );
    final descController = TextEditingController(
      text: isEdit ? course['description'] : '',
    );

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
                          isEdit ? 'Edit Course' : 'Add New Course',
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
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Course Name',
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
                              if (nameController.text.isEmpty) {
                                SnackbarHelper.showError(context, 'Please fill in the course name.');
                                return;
                              }

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token');

                              final url = isEdit
                                  ? ApiConstants.baseUrl + '/courses/${course['id']}'
                                  : ApiConstants.baseUrl + '/courses';

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
                                    'name': nameController.text,
                                    'description': descController.text,
                                    'is_active': true,
                                  }),
                                );

                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  if (mounted) Navigator.pop(context);
                                  _fetchCourses();
                                  SnackbarHelper.showSuccess(
                                    context,
                                    isEdit
                                        ? 'Course updated successfully.'
                                        : 'Course added successfully.',
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
                                    'Failed to save course. Check inputs.',
                                  );
                                }
                              } catch (e) {
                                SnackbarHelper.showError(
                                  context,
                                  'Network error while saving course.',
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
                              isEdit ? 'Save Changes' : 'Create Course',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
      title: 'Courses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;


                final searchBox = SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                      _fetchCourses();
                    },
                  ),
                );

                final actionBtn = SizedBox(
                  height: 48,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCourseModal(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Course'),
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
                      searchBox,
                      const SizedBox(height: 16),
                      actionBtn,
                    ],
                  );
                }

                return Row(
                  children: [
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
                : _courses.isEmpty
                ? const Center(child: Text('No courses found.'))
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
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Course Name')),
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _courses.map<DataRow>((course) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(course['id'].toString())),
                                      DataCell(
                                        Text(
                                          course['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 300,
                                          child: Text(
                                            course['description'] ?? '-',
                                            overflow: TextOverflow.ellipsis,
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
                                                tooltip: 'Edit Course',
                                                onPressed: () =>
                                                    _showCourseModal(
                                                      course: course,
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
                                                tooltip: 'Delete Course',
                                                onPressed: () =>
                                                    _deleteCourse(course['id']),
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
