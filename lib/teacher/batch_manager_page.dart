import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class BatchManagerPage extends StatefulWidget {
  const BatchManagerPage({super.key});

  @override
  State<BatchManagerPage> createState() => _BatchManagerPageState();
}

class _BatchManagerPageState extends State<BatchManagerPage> {
  List<dynamic> _batches = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive
  String? _courseFilter;

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
        Uri.parse(ApiConstants.baseUrl + '/courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final batchUri = Uri.parse(ApiConstants.baseUrl + '/batches').replace(
        queryParameters: {
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
          if (_statusFilter != 'all')
            'is_active': _statusFilter == 'active' ? 'true' : 'false',
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

  Future<void> _toggleStatus(int id, bool currentStatus, String field) async {
    final actionText = currentStatus ? 'Deactivate' : 'Activate';
    final actionField = field == 'is_active'
        ? actionText
        : (currentStatus ? 'Hide' : 'Unhide');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Confirm $actionField'),
        content: Text(
          'Are you sure you want to ${actionField.toLowerCase()} this batch?',
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
              child: Text(actionField),
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
        Uri.parse(ApiConstants.baseUrl + '/batches/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({field: !currentStatus}),
      );

      if (response.statusCode == 200) {
        _fetchData();
      } else {
        SnackbarHelper.showError(context, 'Failed to update status.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while updating status.');
    }
  }

  void _showBatchModal({Map<String, dynamic>? batch}) {
    final isEdit = batch != null;
    final nameController = TextEditingController(
      text: isEdit ? batch['name'] : '',
    );
    final feeController = TextEditingController(
      text: isEdit ? batch['fee'].toString() : '',
    );
    final scheduleController = TextEditingController(
      text: isEdit ? batch['schedule_time'] : '',
    );
    int? selectedCourseId = isEdit
        ? batch['course_id']
        : (_courses.isNotEmpty ? _courses.first['id'] : null);
    bool isActive = isEdit
        ? (batch['is_active'] == 1 || batch['is_active'] == true)
        : true;
    bool isHidden = isEdit
        ? (batch['is_hidden'] == 1 || batch['is_hidden'] == true)
        : false;

    if (_courses.isEmpty) {
      SnackbarHelper.showError(context, 'Please create a course first!');
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
                          isEdit ? 'Edit Batch' : 'Add New Batch',
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: feeController,
                            decoration: InputDecoration(
                              labelText: 'Fee',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
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
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                      child: SwitchListTile(
                        title: const Text('Is Hidden (Archived)'),
                        value: isHidden,
                        onChanged: (val) {
                          setModalState(() {
                            isHidden = val;
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
                                    'fee': feeController.text,
                                    'schedule_time': scheduleController.text,
                                    'is_active': isActive,
                                    'is_hidden': isHidden,
                                  }),
                                );

                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  if (mounted) Navigator.pop(context);
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
      title: 'Batches',
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
                        'Batch Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organize students into specific time slots under their respective courses.',
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
                          setState(() => _courseFilter = val);
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
                          hintText: 'Search batches...',
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
                          onPressed: () => _showBatchModal(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Batch'),
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
                                  DataColumn(label: Text('Batch Name')),
                                  DataColumn(label: Text('Course')),
                                  DataColumn(label: Text('Fee')),
                                  DataColumn(label: Text('Schedule')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Visibility')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _batches.map<DataRow>((batch) {
                                  final isActive =
                                      batch['is_active'] == 1 ||
                                      batch['is_active'] == true;
                                  final isHidden =
                                      batch['is_hidden'] == 1 ||
                                      batch['is_hidden'] == true;

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
                                      DataCell(Text('₹ ${batch['fee']}')),
                                      DataCell(
                                        Text(batch['schedule_time'] ?? '-'),
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isHidden
                                                ? Colors.orange.withOpacity(0.1)
                                                : Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isHidden ? 'Hidden' : 'Visible',
                                            style: TextStyle(
                                              color: isHidden
                                                  ? Colors.orange
                                                  : Colors.blue,
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
                                                  batch['id'],
                                                  isActive,
                                                  'is_active',
                                                ),
                                                splashRadius: 20,
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: Icon(
                                                  isHidden
                                                      ? Icons.lock
                                                      : Icons.lock_open,
                                                  size: 20,
                                                ),
                                                color: isHidden
                                                    ? Colors.orange
                                                    : Colors.grey,
                                                tooltip: isHidden
                                                    ? 'Unhide'
                                                    : 'Hide',
                                                onPressed: () => _toggleStatus(
                                                  batch['id'],
                                                  isHidden,
                                                  'is_hidden',
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
