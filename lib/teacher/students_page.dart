import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import '../layout/teacher_layout.dart';
import 'student_view_page.dart';
import 'teacher_dashboard.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';
import '../core/utils/modal_helper.dart';

class StudentsPage extends StatefulWidget {
  final String? initialBatchId;
  const StudentsPage({super.key, this.initialBatchId});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> _students = [];
  List<dynamic> _batches = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _courseFilter;
  String? _batchFilter;
  List<dynamic> _courses = [];
  List<dynamic> _allBatches = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialBatchId != null) {
      _batchFilter = widget.initialBatchId;
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

      final allBatchesRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final studentUri = Uri.parse(ApiConstants.baseUrl + '/students')
          .replace(
            queryParameters: {
              if (_searchQuery.isNotEmpty) 'search': _searchQuery,
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

      if (!mounted) return;

      if (coursesRes.statusCode == 200 &&
          batchesRes.statusCode == 200 &&
          studentsRes.statusCode == 200 &&
          allBatchesRes.statusCode == 200) {
        setState(() {
          _courses = jsonDecode(coursesRes.body);
          _batches = jsonDecode(batchesRes.body);
          _students = jsonDecode(studentsRes.body);
          _allBatches = jsonDecode(allBatchesRes.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Failed to fetch data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
        Uri.parse(ApiConstants.baseUrl + '/students/$id'),
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


  void _showStudentModal({Map<String, dynamic>? student}) {
    final pageContext = context;
    final isEdit = student != null;
    final nameController = TextEditingController(
      text: isEdit ? student['name'] : '',
    );
    final emailController = TextEditingController(
      text: isEdit ? student['email'] : '',
    );
    final passwordController = TextEditingController();
    
    final fatherNameController = TextEditingController(text: isEdit ? student['father_name'] : '');
    final phoneController = TextEditingController(text: isEdit ? student['phone'] : '');
    final registrationIdController = TextEditingController(text: isEdit ? student['registration_id'] : '');
    final addressController = TextEditingController(text: isEdit ? student['address'] : '');
    String? dob = isEdit ? student['dob'] : null;
    String? gender = isEdit ? student['gender'] : null;
    int? selectedBatchId;
    if (isEdit && student['batches'] != null && (student['batches'] as List).isNotEmpty) {
      selectedBatchId = student['batches'][0]['id'];
    }

    XFile? selectedImage;
    Uint8List? selectedImageBytes;

    ModalHelper.showRightSideModal(
      context: context,
      title: isEdit ? 'Edit Student' : 'Add New Student',
      contentBuilder: (context, setModalState) {
        final today = DateTime.now();
        final todayDateOnly = DateTime(today.year, today.month, today.day);
        final nonExpiredBatches = _allBatches.where((batch) {
          if (selectedBatchId != null && batch['id'] == selectedBatchId) {
            return true;
          }
          if (batch['end_date'] == null) return true;
          final endDate = DateTime.tryParse(batch['end_date']);
          if (endDate == null) return true;
          return !endDate.isBefore(todayDateOnly);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: selectedImageBytes != null
                        ? MemoryImage(selectedImageBytes!)
                        : (isEdit && student['profile_image'] != null && student['profile_image'].toString().startsWith('http')
                            ? NetworkImage(student['profile_image']) as ImageProvider
                            : null),
                    child: selectedImageBytes == null && (!isEdit || student['profile_image'] == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () async {
                        final typeGroup = const XTypeGroup(
                          label: 'images',
                          extensions: ['jpg', 'png', 'jpeg'],
                        );
                        final result = await openFile(acceptedTypeGroups: [typeGroup]);
                        if (result != null) {
                          final bytes = await result.readAsBytes();
                          setModalState(() {
                            selectedImage = result;
                            selectedImageBytes = bytes;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // --- Required Fields ---
                    Text(
                      'Required Fields',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
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
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
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
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
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
                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    // --- Additional Details ---
                    Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: fatherNameController,
                            decoration: InputDecoration(
                              labelText: "Father's Name",
                              prefixIcon: const Icon(Icons.family_restroom, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: registrationIdController,
                            decoration: InputDecoration(
                              labelText: 'Admission Number',
                              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            value: gender,
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) => setModalState(() => gender = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dob != null ? DateTime.parse(dob!) : DateTime.now().subtract(const Duration(days: 365 * 18)),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  dob = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',
                                prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                                suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: Text(
                                dob ?? 'Select Date',
                                style: TextStyle(
                                  color: dob != null ? null : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Select Batch (Optional)',
                        prefixIcon: const Icon(Icons.class_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      value: selectedBatchId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('None (No Batch)'),
                        ),
                        ...nonExpiredBatches.map<DropdownMenuItem<int>>((batch) {
                          final courseName = batch['course'] != null ? batch['course']['name'] : 'Unknown Course';
                          return DropdownMenuItem<int>(
                            value: batch['id'],
                            child: Text("${batch['name']} ($courseName)"),
                          );
                        }).toList(),
                      ],
                      onChanged: (val) => setModalState(() => selectedBatchId = val),
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
                  print('--- SAVE BUTTON CLICKED ---');
                  print('Name: \${nameController.text}, Email: \${emailController.text}, isEdit: \$isEdit');
                  if (nameController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    print('--- FAILED: Name or email is empty ---');
                    if (pageContext.mounted) {
                      showDialog(
                        context: pageContext,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Validation Error'),
                          content: const Text('Please fill in all required fields.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                        ),
                      );
                    }
                    return;
                  }
                  if (!isEdit && passwordController.text.isEmpty) {
                    print('--- FAILED: Password empty for new student ---');
                    if (pageContext.mounted) {
                      showDialog(
                        context: pageContext,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Validation Error'),
                          content: const Text('Password is required for new students.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                        ),
                      );
                    }
                    return;
                  }

                  final prefs =
                      await SharedPreferences.getInstance();
                  final token = prefs.getString('auth_token');

                  final url = isEdit
                      ? ApiConstants.baseUrl + '/students/${student['id']}'
                      : ApiConstants.baseUrl + '/students';

                  final requestMethod = isEdit
                      ? http.put
                      : http.post;

                  final Map<String, dynamic> bodyData = {
                    'name': nameController.text,
                    'email': emailController.text,
                    'is_active': '1',
                    'father_name': fatherNameController.text.isEmpty ? null : fatherNameController.text,
                    'phone': phoneController.text.isEmpty ? null : phoneController.text,
                    'registration_id': registrationIdController.text.isEmpty ? null : registrationIdController.text,
                    'address': addressController.text.isEmpty ? null : addressController.text,
                    'dob': dob,
                    'gender': gender,
                  };

                  if (passwordController.text.isNotEmpty) {
                    bodyData['password'] = passwordController.text;
                  }
                  
                  print('--- API CALL: \$url ---');
                  print('Body: \$bodyData');

                  try {
                    var request = http.MultipartRequest(
                      isEdit ? 'POST' : 'POST',
                      Uri.parse(url),
                    );
                    
                    request.headers['Authorization'] = 'Bearer $token';
                    request.headers['Accept'] = 'application/json';

                    if (isEdit) {
                      request.fields['_method'] = 'PUT';
                    }

                    bodyData.forEach((key, value) {
                      if (value != null) {
                        request.fields[key] = value.toString();
                      }
                    });

                    if (selectedBatchId != null) {
                      request.fields['batch_ids[0]'] = selectedBatchId.toString();
                    }

                    if (selectedImageBytes != null) {
                      request.files.add(
                        http.MultipartFile.fromBytes(
                          'profile_image',
                          selectedImageBytes!,
                          filename: selectedImage!.name,
                        ),
                      );
                    }

                    print('--- SENDING REQUEST ---');
                    final streamedResponse = await request.send();
                    final response = await http.Response.fromStream(streamedResponse);
                    print('--- RESPONSE: \${response.statusCode} ---');
                    print('--- BODY: \${response.body} ---');

                    if (response.statusCode == 201 || response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
                      _fetchData();
                      if (pageContext.mounted) {
                        SnackbarHelper.showSuccess(
                          pageContext,
                          isEdit
                              ? 'Student updated successfully.'
                              : 'Student registered successfully.',
                        );
                      }
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
                      if (pageContext.mounted) {
                        showDialog(
                          context: pageContext,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Validation Error'),
                            content: Text(errorMsg),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                          ),
                        );
                      }
                    } else {
                      if (pageContext.mounted) {
                        showDialog(
                          context: pageContext,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Error'),
                            content: const Text('Failed to save student. Email might already exist.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (pageContext.mounted) {
                      showDialog(
                        context: pageContext,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Network Error'),
                          content: Text('Error: $e'), // Added the actual exception to see what's wrong
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                        ),
                      );
                    }
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      title: 'Students',
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
                      setState(() {
                        _courseFilter = val;
                        _batchFilter = null; // Reset batch filter when course changes
                      });
                      _fetchData();
                    },
                  ),
                );

                final batchFilter = SizedBox(
                  height: 48,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _batches.any((b) => b['id'].toString() == _batchFilter) ? _batchFilter : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      hintText: 'All Batches',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Batches')),
                      ..._batches.map((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name']))),
                    ],
                    onChanged: (val) {
                      setState(() => _batchFilter = val);
                      _fetchData();
                    },
                  ),
                );


                final searchBox = SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search students...',
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
                      onPressed: () => _showStudentModal(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('New Student'),
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
                      batchFilter,
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
                    Expanded(flex: 1, child: batchFilter),
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
                                  DataColumn(label: Text('Student Name')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Batch')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _students.map<DataRow>((student) {
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
                                              backgroundImage: student['profile_image'] != null && student['profile_image'].toString().startsWith('http')
                                                  ? NetworkImage(student['profile_image'])
                                                  : null,
                                              child: student['profile_image'] == null
                                                  ? Text(
                                                      student['name'][0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontSize: 10,
                                                      ),
                                                    )
                                                  : null,
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
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: (student['batches'] as List?)?.map((b) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              b['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          )).toList() ?? [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text('No Batch', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                            )
                                          ],
                                        ),
                                      ),

                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(Icons.person, size: 20),
                                                color: Theme.of(context).colorScheme.primary,
                                                tooltip: 'View Profile',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => StudentViewPage(studentId: student['id']),
                                                    ),
                                                  ).then((_) => _fetchData());
                                                },
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
