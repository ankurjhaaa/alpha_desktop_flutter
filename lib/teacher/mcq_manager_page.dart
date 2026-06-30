import 'package:flutter/material.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import 'mcq_question_manager_page.dart';
import 'mcq_paper_results_page.dart';
import 'teacher_dashboard.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';
import '../core/utils/modal_helper.dart';
class McqManagerPage extends StatefulWidget {
  final String? initialBatchId;
  const McqManagerPage({super.key, this.initialBatchId});

  @override
  State<McqManagerPage> createState() => _McqManagerPageState();
}

class _McqManagerPageState extends State<McqManagerPage> {
  List<dynamic> _papers = [];
  List<dynamic> _batches = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCourseId;
  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    if (widget.initialBatchId != null) {
      _selectedBatchId = widget.initialBatchId;
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

      final batchesRes = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final papersUri = Uri.parse(ApiConstants.baseUrl + '/mcq_papers')
          .replace(
            queryParameters: {
              if (_searchQuery.isNotEmpty) 'search': _searchQuery,
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
        Uri.parse(ApiConstants.baseUrl + '/mcq_papers/$id'),
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

  Future<void> _showImportQuestionsDialog(Map<String, dynamic> paper) async {
    final startController = TextEditingController();
    final endController = TextEditingController();
    bool isSubmitting = false;

    if (paper['topic_id'] == null) {
      SnackbarHelper.showError(context, 'This exam has no topic assigned. Edit the exam to assign a topic before importing.');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Import Questions from Bank'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the range of questions to import from the selected topic.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Start Number (e.g. 1)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'End Number (e.g. 50)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final start = int.tryParse(startController.text);
                    final end = int.tryParse(endController.text);

                    if (start == null || end == null || start < 1 || end < start) {
                      SnackbarHelper.showError(context, 'Please enter valid start and end numbers.');
                      return;
                    }

                    setState(() => isSubmitting = true);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('auth_token');

                    try {
                      final response = await http.post(
                        Uri.parse('${ApiConstants.baseUrl}/mcq_papers/${paper['id']}/import-questions'),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Accept': 'application/json',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          'start_number': start,
                          'end_number': end,
                        }),
                      );

                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        if (context.mounted) {
                          Navigator.pop(context);
                          SnackbarHelper.showSuccess(context, data['message'] ?? 'Import successful.');
                        }
                      } else {
                        final data = jsonDecode(response.body);
                        if (context.mounted) {
                          SnackbarHelper.showError(context, data['message'] ?? 'Failed to import questions.');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        SnackbarHelper.showError(context, 'Network error during import.');
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() => isSubmitting = false);
                      }
                    }
                  },
                  child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Import'),
                ),
              ],
            );
          }
        );
      }
    );
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
    
    String formatTimeAmPm(DateTime dt) {
      int h = dt.hour;
      int m = dt.minute;
      String ampm = h >= 12 ? 'PM' : 'AM';
      h = h % 12;
      if (h == 0) h = 12;
      return "${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')} $ampm";
    }

    String formatTimeRaw(DateTime dt) {
      return "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:00";
    }

    String? rawStartTime = isEdit ? paper['start_time'] : null;
    String? rawEndTime = isEdit ? paper['end_time'] : null;

    final startTimeController = TextEditingController();
    if (rawStartTime != null && rawStartTime.isNotEmpty) {
      try {
        startTimeController.text = formatTimeAmPm(DateTime.parse(rawStartTime));
      } catch (_) {
        startTimeController.text = rawStartTime;
      }
    }

    final endTimeController = TextEditingController();
    if (rawEndTime != null && rawEndTime.isNotEmpty) {
      try {
        endTimeController.text = formatTimeAmPm(DateTime.parse(rawEndTime));
      } catch (_) {
        endTimeController.text = rawEndTime;
      }
    }

    final invigilatorsController = TextEditingController(
      text: isEdit ? (paper['invigilators'] ?? '') : '',
    );
    final studentSearchController = TextEditingController();
    int? selectedBatchId = isEdit
        ? paper['batch_id']
        : (_batches.isNotEmpty ? _batches.first['id'] : null);

    if (_batches.isEmpty) {
      SnackbarHelper.showError(context, 'Please create a batch first!');
      return;
    }

    bool _isLoadingStudents = false;
    List<dynamic> _batchStudents = [];
    List<int> _selectedStudentIds = isEdit && paper['selected_student_ids'] != null 
        ? List<int>.from(paper['selected_student_ids'].map((x) => int.parse(x.toString())))
        : [];

    int? selectedTopicId = isEdit ? paper['topic_id'] : null;
    List<dynamic> _modalTopics = [];
    bool _isLoadingTopics = false;

    Future<void> _fetchTopicsForCourse(int courseId, StateSetter setModalState) async {
      setModalState(() => _isLoadingTopics = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      try {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/topics?course_id=$courseId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (res.statusCode == 200) {
          setModalState(() {
            _modalTopics = jsonDecode(res.body);
            _isLoadingTopics = false;
          });
        } else {
          setModalState(() => _isLoadingTopics = false);
        }
      } catch (e) {
        setModalState(() => _isLoadingTopics = false);
      }
    }

    Future<void> _fetchStudentsForBatch(int batchId, StateSetter setModalState) async {
      setModalState(() => _isLoadingStudents = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      try {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/students?batch_id=$batchId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (res.statusCode == 200) {
          final students = jsonDecode(res.body);
          setModalState(() {
            _batchStudents = students;
            if (!isEdit) {
               _selectedStudentIds = _batchStudents.map((s) => s['id'] as int).toList();
            }
            _isLoadingStudents = false;
          });
        } else {
          setModalState(() => _isLoadingStudents = false);
        }
      } catch (e) {
        setModalState(() => _isLoadingStudents = false);
      }
    }

    ModalHelper.showRightSideModal(
      context: context,
      title: isEdit ? 'Edit MCQ Paper' : 'Create MCQ Paper',
      contentBuilder: (context, setModalStateOuter) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Fetch initial students if batch is already selected and we haven't fetched yet
            if (selectedBatchId != null && _batchStudents.isEmpty && !_isLoadingStudents) {
               _fetchStudentsForBatch(selectedBatchId!, setModalState);
               final batch = _batches.firstWhere((b) => b['id'] == selectedBatchId, orElse: () => null);
               if (batch != null && batch['course_id'] != null) {
                 _fetchTopicsForCourse(batch['course_id'], setModalState);
               }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        if (val != null && val != selectedBatchId) {
                          setModalState(() {
                            selectedBatchId = val;
                            _selectedStudentIds.clear(); 
                            selectedTopicId = null;
                            _modalTopics = [];
                          });
                          _fetchStudentsForBatch(val, setModalState);
                          final batch = _batches.firstWhere((b) => b['id'] == val, orElse: () => null);
                          if (batch != null && batch['course_id'] != null) {
                            _fetchTopicsForCourse(batch['course_id'], setModalState);
                          }
                        }
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
                    const Text(
                      'Select Topic (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingTopics)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<int>(
                        value: selectedTopicId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('No Topic'),
                          ),
                          ..._modalTopics.map<DropdownMenuItem<int>>((t) {
                            return DropdownMenuItem<int>(
                              value: t['id'],
                              child: Text(t['title']),
                            );
                          }).toList()
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            selectedTopicId = val;
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
                                setModalState(() {
                                  dateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                  startTimeController.clear();
                                  endTimeController.clear();
                                  rawStartTime = null;
                                  rawEndTime = null;
                                });
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? baseDate;
                              if (dateController.text.isNotEmpty) {
                                try {
                                  baseDate = DateTime.parse(dateController.text);
                                } catch (_) {}
                              }
                              
                              if (baseDate == null) {
                                baseDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                              }

                              if (baseDate != null) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (BuildContext context, Widget? child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedTime != null) {
                                  final dt = DateTime(baseDate.year, baseDate.month, baseDate.day, pickedTime.hour, pickedTime.minute);
                                  setModalState(() {
                                    rawStartTime = formatTimeRaw(dt);
                                    startTimeController.text = formatTimeAmPm(dt);
                                  });
                                }
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Start Time (Optional)',
                              suffixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? baseDate;
                              if (dateController.text.isNotEmpty) {
                                try {
                                  baseDate = DateTime.parse(dateController.text);
                                } catch (_) {}
                              }
                              
                              if (baseDate == null) {
                                baseDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                              }

                              if (baseDate != null) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (BuildContext context, Widget? child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedTime != null) {
                                  final dt = DateTime(baseDate.year, baseDate.month, baseDate.day, pickedTime.hour, pickedTime.minute);
                                  setModalState(() {
                                    rawEndTime = formatTimeRaw(dt);
                                    endTimeController.text = formatTimeAmPm(dt);
                                  });
                                }
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'End Time (Optional)',
                              suffixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: invigilatorsController,
                      decoration: InputDecoration(
                        labelText: 'Invigilators (Comma separated names)',
                        prefixIcon: const Icon(Icons.people_outline),
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
                    const Text(
                      'Eligible Students',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoadingStudents)
                            const Center(child: CircularProgressIndicator())
                          else if (_batchStudents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No students found in this batch.'),
                            )
                          else ...[
                            TextField(
                              controller: studentSearchController,
                              onChanged: (val) => setModalState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search by name, email, phone, admission no...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final query = studentSearchController.text.toLowerCase();
                                final filteredStudents = _batchStudents.where((student) {
                                  if (query.isEmpty) return true;
                                  final name = (student['name'] ?? '').toString().toLowerCase();
                                  final email = (student['email'] ?? '').toString().toLowerCase();
                                  final phone = (student['phone'] ?? student['mobile_number'] ?? student['mobile'] ?? '').toString().toLowerCase();
                                  final admissionNo = (student['admission_no'] ?? student['admission_number'] ?? '').toString().toLowerCase();
                                  return name.contains(query) || email.contains(query) || phone.contains(query) || admissionNo.contains(query);
                                }).toList();

                                if (filteredStudents.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No students matched your search.'),
                                  );
                                }

                                return Column(
                                  children: [
                                    CheckboxListTile(
                                      title: const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
                                      value: filteredStudents.every((s) => _selectedStudentIds.contains(s['id'] as int)),
                                      onChanged: (bool? value) {
                                        setModalState(() {
                                          if (value == true) {
                                            for (var s in filteredStudents) {
                                              if (!_selectedStudentIds.contains(s['id'] as int)) {
                                                _selectedStudentIds.add(s['id'] as int);
                                              }
                                            }
                                          } else {
                                            for (var s in filteredStudents) {
                                              _selectedStudentIds.remove(s['id'] as int);
                                            }
                                          }
                                        });
                                      },
                                      controlAffinity: ListTileControlAffinity.leading,
                                      dense: true,
                                    ),
                                    const Divider(height: 1),
                                    ...filteredStudents.map((student) {
                                      final studentId = student['id'] as int;
                                      return CheckboxListTile(
                                        title: Text('${student['name']} (${student['email']})'),
                                        subtitle: Text([
                                          if (student['admission_no'] != null) 'Admn: ${student['admission_no']}',
                                          if (student['phone'] != null) 'Ph: ${student['phone']}'
                                        ].join(' | ')),
                                        value: _selectedStudentIds.contains(studentId),
                                        onChanged: (bool? value) {
                                          setModalState(() {
                                            if (value == true) {
                                              _selectedStudentIds.add(studentId);
                                            } else {
                                              _selectedStudentIds.remove(studentId);
                                            }
                                          });
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                        dense: true,
                                      );
                                    }).toList(),
                                  ],
                                );
                              }
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
              ],
            );
          },
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
                      ? ApiConstants.baseUrl + '/mcq_papers/${paper['id']}'
                      : ApiConstants.baseUrl + '/mcq_papers';

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
                        'topic_id': selectedTopicId,
                        'title': titleController.text,
                        'description': descController.text,
                        'exam_date': dateController.text.isEmpty ? null : dateController.text,
                        'exam_password': passwordController.text.isEmpty ? null : passwordController.text,
                        'start_time': rawStartTime,
                        'end_time': rawEndTime,
                        'invigilators': invigilatorsController.text.isEmpty ? null : invigilatorsController.text,
                        'selected_student_ids': _selectedStudentIds,
                        'is_active': 1,
                      }),
                    );

                    if (response.statusCode == 201 ||
                        response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      title: 'MCQ Papers',
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
                    value: _courses.any((c) => c['id'].toString() == _selectedCourseId) ? _selectedCourseId : null,
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
                        _selectedCourseId = val;
                        _selectedBatchId = null;
                      });
                      _fetchData();
                    },
                  ),
                );

                final batchFilter = _selectedCourseId != null
                    ? SizedBox(
                        height: 48,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _batches.where((b) => b['course_id'].toString() == _selectedCourseId).any((b) => b['id'].toString() == _selectedBatchId) ? _selectedBatchId : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            hintText: 'All Batches',
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Batches')),
                            ..._batches
                                .where((b) => b['course_id'].toString() == _selectedCourseId)
                                .map((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name']))),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedBatchId = val);
                            _fetchData();
                          },
                        ),
                      )
                    : const SizedBox.shrink();


                final searchBox = SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search papers...',
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

                final actionBtn = MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaperModal(),
                      icon: const Icon(Icons.note_add),
                      label: const Text('New Paper'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      courseFilter,
                      if (_selectedCourseId != null) ...[
                        const SizedBox(height: 16),
                        batchFilter,
                      ],
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
                    if (_selectedCourseId != null) ...[
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: batchFilter),
                    ],
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
                : _papers.isEmpty
                ? const Center(child: Text('No Questions Paper found.'))
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
                                  DataColumn(label: Text('S.No')),
                                  DataColumn(label: Text('Paper Title')),
                                  DataColumn(label: Text('Batch')),
                                  DataColumn(label: Text('Exam Date')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _papers.asMap().entries.map<DataRow>((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final paper = entry.value;
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
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  _showImportQuestionsDialog(paper);
                                                },
                                                icon: const Icon(
                                                  Icons.cloud_download,
                                                  size: 16,
                                                ),
                                                label: const Text('Import Bank'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                                  foregroundColor: Colors.orange,
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
