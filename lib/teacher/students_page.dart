import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> _students = [];
  List<dynamic> _batches = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String? _courseFilter;
  String? _batchFilter;
  List<dynamic> _courses = [];

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

      final batchUri = Uri.parse('http://127.0.0.1:8000/api/batches').replace(
        queryParameters: {
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

      final studentUri = Uri.parse('http://127.0.0.1:8000/api/students')
          .replace(
            queryParameters: {
              if (_searchQuery.isNotEmpty) 'search': _searchQuery,
              if (_statusFilter != 'all')
                'is_active': _statusFilter == 'active' ? 'true' : 'false',
              if (_courseFilter != null) 'course_id': _courseFilter,
              if (_batchFilter != null) 'batch_id': _batchFilter,
            },
          );

      final studentsRes = await http.get(
        studentUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (coursesRes.statusCode == 200 &&
          batchesRes.statusCode == 200 &&
          studentsRes.statusCode == 200) {
        setState(() {
          _courses = jsonDecode(coursesRes.body);
          _batches = jsonDecode(batchesRes.body);
          _students = jsonDecode(studentsRes.body);
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

  Future<void> _deleteStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this student?'),
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
        Uri.parse('http://127.0.0.1:8000/api/students/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _fetchData();
        SnackbarHelper.showSuccess(context, 'Student deleted successfully.');
      } else {
        SnackbarHelper.showError(context, 'Failed to delete student.');
      }
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Network error while deleting student.',
      );
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
          'Are you sure you want to ${actionText.toLowerCase()} this item?',
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
              style: TextButton.styleFrom(
                foregroundColor: currentStatus ? Colors.red : Colors.green,
              ),
              child: Text(actionText),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/students/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_active': !currentStatus}),
      );

      if (response.statusCode == 200) {
        // Find fetch method (e.g. _fetchCourses)

        _fetchData();
        SnackbarHelper.showSuccess(
          context,
          'Status ${currentStatus ? "deactivated" : "activated"} successfully.',
        );
      } else {
        SnackbarHelper.showError(context, 'Failed to update status.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while updating status.');
    }
  }

  void _showStudentModal({Map<String, dynamic>? student}) {
    final isEdit = student != null;
    final nameController = TextEditingController(
      text: isEdit ? student['name'] : '',
    );
    final emailController = TextEditingController(
      text: isEdit ? student['email'] : '',
    );
    final passwordController = TextEditingController();
    int? selectedBatchId = isEdit
        ? student['batch_id']
        : (_batches.isNotEmpty ? _batches.first['id'] : null);
    bool isActive = isEdit
        ? (student['is_active'] == 1 || student['is_active'] == true)
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
                          isEdit ? 'Edit Student' : 'Add New Student',
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
                        labelText: 'Full Name',
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
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: isEdit
                            ? 'New Password (leave blank to keep)'
                            : 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Batch',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedBatchId,
                      isExpanded: true,
                      items: _batches.map<DropdownMenuItem<int>>((batch) {
                        return DropdownMenuItem<int>(
                          value: batch['id'],
                          child: Text(
                            '${batch['name']} (${batch['course']['name'] ?? 'Course'})',
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
                                  emailController.text.isEmpty ||
                                  selectedBatchId == null) {
                                SnackbarHelper.showError(
                                  context,
                                  'Please fill in all required fields.',
                                );
                                return;
                              }
                              if (!isEdit && passwordController.text.isEmpty) {
                                SnackbarHelper.showError(
                                  context,
                                  'Password is required for new students.',
                                );
                                return;
                              }

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token');

                              final url = isEdit
                                  ? 'http://127.0.0.1:8000/api/students/${student['id']}'
                                  : 'http://127.0.0.1:8000/api/students';

                              final requestMethod = isEdit
                                  ? http.put
                                  : http.post;

                              final Map<String, dynamic> bodyData = {
                                'name': nameController.text,
                                'email': emailController.text,
                                'batch_id': selectedBatchId,
                                'is_active': isActive,
                              };

                              if (passwordController.text.isNotEmpty) {
                                bodyData['password'] = passwordController.text;
                              }

                              try {
                                final response = await requestMethod(
                                  Uri.parse(url),
                                  headers: {
                                    'Authorization': 'Bearer $token',
                                    'Accept': 'application/json',
                                    'Content-Type': 'application/json',
                                  },
                                  body: jsonEncode(bodyData),
                                );

                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  if (mounted) Navigator.pop(context);
                                  _fetchData();
                                  SnackbarHelper.showSuccess(
                                    context,
                                    isEdit
                                        ? 'Student updated successfully.'
                                        : 'Student registered successfully.',
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
                                    'Failed to save student. Email might already exist.',
                                  );
                                }
                              } catch (e) {
                                SnackbarHelper.showError(
                                  context,
                                  'Network error while saving student.',
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
                              isEdit ? 'Save Changes' : 'Register Student',
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
      title: 'Students',
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
                        'Student Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Register students and assign them to batches.',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      height: 48,
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _courseFilter,
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
                            _courseFilter = val;
                            _batchFilter =
                                null; // Reset batch filter when course changes
                          });
                          _fetchData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _batchFilter,
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
                          ..._batches.map(
                            (b) => DropdownMenuItem(
                              value: b['id'].toString(),
                              child: Text(b['name']),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _batchFilter = val);
                          _fetchData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      width: 150,
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
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search students...',
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
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 48,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ElevatedButton.icon(
                          onPressed: () => _showStudentModal(),
                          icon: const Icon(Icons.person_add),
                          label: const Text('New Student'),
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
                : _students.isEmpty
                ? const Center(child: Text('No students found.'))
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
                                  DataColumn(label: Text('Student Name')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Batch')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _students.map<DataRow>((student) {
                                  final isActive =
                                      student['is_active'] == 1 ||
                                      student['is_active'] == true;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(student['id'].toString())),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.1),
                                              child: Text(
                                                student['name'][0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              student['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(student['email'])),
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
                                            student['batch'] != null
                                                ? student['batch']['name']
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
                                                  student['id'],
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
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                                tooltip: 'Edit Student',
                                                onPressed: () =>
                                                    _showStudentModal(
                                                      student: student,
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
                                                tooltip: 'Delete Student',
                                                onPressed: () => _deleteStudent(
                                                  student['id'],
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
}
