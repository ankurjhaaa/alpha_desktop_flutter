import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';
import '../core/utils/modal_helper.dart';
import 'batch_manager_page.dart';
import 'teacher_dashboard.dart';

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
    final topicInputController = TextEditingController();
    final List<String> topicsList = isEdit
        ? (course['topics'] as List?)?.map((t) => t['title'].toString()).toList() ?? []
        : [];

    ModalHelper.showRightSideModal(
      context: context,
      title: isEdit ? 'Edit Course' : 'Add New Course',
      contentBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Course Topics / Chapters',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: topicInputController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Introduction to CSS',
                      labelText: 'Add Topic Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        setModalState(() {
                          topicsList.add(val.trim());
                          topicInputController.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final val = topicInputController.text;
                      if (val.trim().isNotEmpty) {
                        setModalState(() {
                          topicsList.add(val.trim());
                          topicInputController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topicsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No topics added yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topicsList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        topicsList[index],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      trailing: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () {
                            setModalState(() {
                              topicsList.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                        'topics': topicsList,
                      }),
                    );

                    if (response.statusCode == 201 ||
                        response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
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
        );
      },
    );
  }

  void _showTopicsModal(Map<String, dynamic> course) {
    final topicInputController = TextEditingController();
    final List<String> topicsList = (course['topics'] as List?)
            ?.map((t) => t['title'].toString())
            .toList() ??
        [];

    ModalHelper.showRightSideModal(
      context: context,
      title: 'Course Topics - ${course['name']}',
      contentBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add or remove topics for this course. Click "Save Changes" at the bottom to apply.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: topicInputController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Introduction to CSS',
                      labelText: 'Topic Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        setModalState(() {
                          topicsList.add(val.trim());
                          topicInputController.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final val = topicInputController.text;
                      if (val.trim().isNotEmpty) {
                        setModalState(() {
                          topicsList.add(val.trim());
                          topicInputController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Topics / Chapters List (${topicsList.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (topicsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No topics added yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topicsList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        topicsList[index],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      trailing: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () {
                            setModalState(() {
                              topicsList.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');
                  final url = ApiConstants.baseUrl + '/courses/${course['id']}';

                  try {
                    final response = await http.put(
                      Uri.parse(url),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'name': course['name'],
                        'description': course['description'],
                        'is_active': true,
                        'topics': topicsList,
                      }),
                    );

                    if (response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
                      _fetchCourses();
                      SnackbarHelper.showSuccess(
                        context,
                        'Topics updated successfully.',
                      );
                    } else if (response.statusCode == 422) {
                      final data = jsonDecode(response.body);
                      String errorMsg = data['message'] ?? 'Validation error.';
                      if (data['errors'] != null) {
                        final errors = data['errors'] as Map<String, dynamic>;
                        if (errors.isNotEmpty) {
                          errorMsg = errors.values.first[0];
                        }
                      }
                      SnackbarHelper.showError(context, errorMsg);
                    } else {
                      SnackbarHelper.showError(
                        context,
                        'Failed to save topics.',
                      );
                    }
                  } catch (e) {
                    SnackbarHelper.showError(
                      context,
                      'Network error while saving topics.',
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
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
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
      title: 'Courses',
      onBackPressed: () => Navigator.pop(context),
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
                                  DataColumn(label: Text('Course Name')),
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('Topics / Chapters')),
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
                                        ElevatedButton.icon(
                                          onPressed: () => _showTopicsModal(course),
                                          icon: const Icon(Icons.list_alt, size: 16),
                                          label: Text('View Topics (${(course['topics'] as List?)?.length ?? 0})'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                            foregroundColor: Theme.of(context).colorScheme.primary,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),

                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: TextButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context, animation, secondaryAnimation) => BatchManagerPage(initialCourseId: course['id'].toString()),
                                                      transitionDuration: Duration.zero,
                                                      reverseTransitionDuration: Duration.zero,
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.link, size: 16, color: Colors.green),
                                                label: const Text(
                                                  'View Batches',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
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
