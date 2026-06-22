import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class StudentViewPage extends StatefulWidget {
  final int studentId;

  const StudentViewPage({super.key, required this.studentId});

  @override
  State<StudentViewPage> createState() => _StudentViewPageState();
}

class _StudentViewPageState extends State<StudentViewPage> {
  Map<String, dynamic>? _student;
  bool _isLoading = true;
  List<dynamic> _allBatches = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
    _fetchBatches();
  }

  Future<void> _fetchStudentDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/students/${widget.studentId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _student = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarHelper.showError(context, 'Failed to load student details.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Network Error.');
      }
    }
  }

  Future<void> _fetchBatches() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allBatches = jsonDecode(response.body);
          });
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _attachBatch(int batchId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + '/students/${widget.studentId}/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'batch_id': batchId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Batch enrolled successfully!');
          _fetchStudentDetails();
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, 'Failed to enroll in batch.');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Network Error.');
      }
    }
  }

  void _showEnrollBatchModal() {
    int? selectedBatchId;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enroll in Batch', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Select Batch',
                        prefixIcon: const Icon(Icons.class_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      value: selectedBatchId,
                      items: _allBatches.map((b) {
                        return DropdownMenuItem<int>(
                          value: b['id'] as int,
                          child: Text(b['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedBatchId = val),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              minimumSize: const Size(120, 54),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : () async {
                              if (selectedBatchId == null) {
                                SnackbarHelper.showError(context, 'Please select a batch.');
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              await _attachBatch(
                                selectedBatchId!,
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              minimumSize: const Size(140, 54),
                            ),
                            child: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Enroll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      case 'unpaid': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TeacherLayout(
      title: 'Student Profile',
      onBackPressed: () => Navigator.pop(context),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _student == null
              ? const Center(child: Text('Student not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 64,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              backgroundImage: _student!['profile_image'] != null && _student!['profile_image'].toString().startsWith('http')
                                  ? NetworkImage(_student!['profile_image'])
                                  : null,
                              child: _student!['profile_image'] == null
                                  ? Text(
                                      _student!['name'][0].toUpperCase(),
                                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _student!['name'],
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _student!['email'],
                                    style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                  if (_student!['registration_id'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Admission No: ${_student!['registration_id']}',
                                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final isActive = _student!['is_active'] == 1 || _student!['is_active'] == true;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Profile Details Grid
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 600;
                                final items = [
                                  _buildInfoItem(theme, "Father's Name", _student!['father_name'], Icons.family_restroom),
                                  _buildInfoItem(theme, 'Phone', _student!['phone'], Icons.phone_outlined),
                                  _buildInfoItem(theme, 'Date of Birth', _formatDate(_student!['dob']), Icons.cake_outlined),
                                  _buildInfoItem(theme, 'Gender', _student!['gender'], Icons.person_outline),
                                  _buildInfoItem(theme, 'Address', _student!['address'], Icons.location_on_outlined),
                                  _buildInfoItem(theme, 'Joined', _formatDate(_student!['created_at']), Icons.calendar_today),
                                ];

                                if (isWide) {
                                  return Column(
                                    children: [
                                      for (int i = 0; i < items.length; i += 3)
                                        Padding(
                                          padding: EdgeInsets.only(bottom: i + 3 < items.length ? 16 : 0),
                                          child: Row(
                                            children: [
                                              for (int j = i; j < i + 3 && j < items.length; j++) ...[
                                                if (j > i) const SizedBox(width: 16),
                                                Expanded(child: items[j]),
                                              ],
                                              // fill remaining if row incomplete
                                              if (i + 3 > items.length)
                                                for (int k = 0; k < i + 3 - items.length; k++) ...[
                                                  const SizedBox(width: 16),
                                                  const Expanded(child: SizedBox()),
                                                ],
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                }
                                return Column(
                                  children: items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: item,
                                  )).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Enrolled Batches Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enrolled Batches',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ElevatedButton.icon(
                              onPressed: _showEnrollBatchModal,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Enroll in Batch'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if ((_student!['batches'] as List?)?.isEmpty ?? true)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.class_outlined, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                              const SizedBox(height: 12),
                              Text(
                                'No batches enrolled yet.',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      else
                        // Batch Table
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.05),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('Batch Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    Expanded(flex: 2, child: Text('Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    Expanded(flex: 2, child: Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    Expanded(flex: 2, child: Text('End Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  ],
                                ),
                              ),
                              // Rows
                              ...(_student!['batches'] as List).asMap().entries.map((entry) {
                                final index = entry.key;
                                final batch = entry.value;
                                final pivot = batch['pivot'];
                                final isLast = index == (_student!['batches'] as List).length - 1;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: index.isEven ? theme.colorScheme.surface : theme.scaffoldBackgroundColor,
                                    border: Border(bottom: isLast ? BorderSide.none : BorderSide(color: theme.dividerColor.withOpacity(0.05))),
                                    borderRadius: isLast
                                        ? const BorderRadius.only(
                                            bottomLeft: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Icon(Icons.class_, size: 18, color: theme.colorScheme.primary),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                batch['name'] ?? 'N/A',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          batch['course'] != null ? batch['course']['name'] : 'N/A',
                                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          batch['start_date'] ?? 'N/A',
                                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          batch['end_date'] ?? 'N/A',
                                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String label, dynamic value, IconData icon) {
    final displayValue = (value == null || value.toString().isEmpty) ? 'Not Provided' : value.toString();
    final bool hasValue = value != null && value.toString().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary.withOpacity(0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue ? null : theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
