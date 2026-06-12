import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/teacher_layout.dart';
import '../core/utils/snackbar_helper.dart';

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
  int? _selectedBatchId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  String _paymentStatus = 'unpaid';
  bool _isAddingBatch = false;

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
        Uri.parse('http://127.0.0.1:8000/api/students/${widget.studentId}'),
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
        Uri.parse('http://127.0.0.1:8000/api/batches'),
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

  Future<void> _attachBatch() async {
    if (_student == null || _selectedBatchId == null) {
      SnackbarHelper.showError(context, 'Please select a batch.');
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    setState(() => _isAddingBatch = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/students/${widget.studentId}/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'batch_id': _selectedBatchId,
          'amount_paid': _amountController.text.isNotEmpty ? double.tryParse(_amountController.text) : null,
          'transaction_id': _transactionController.text.isNotEmpty ? _transactionController.text : null,
          'status': _paymentStatus,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Batch enrolled successfully!');
          Navigator.of(context).pop();
          _fetchStudentDetails();
          // Reset form
          _selectedBatchId = null;
          _amountController.clear();
          _transactionController.clear();
          _paymentStatus = 'unpaid';
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
    } finally {
      if (mounted) {
        setState(() => _isAddingBatch = false);
      }
    }
  }

  void _showAddBatchModal() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Enroll in Batch'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Select Batch'),
                      value: _selectedBatchId,
                      items: _allBatches.map((b) {
                        return DropdownMenuItem<int>(
                          value: b['id'] as int,
                          child: Text(b['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedBatchId = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Payment Status'),
                      value: _paymentStatus,
                      items: const [
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'partial', child: Text('Partial')),
                        DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                      ],
                      onChanged: (val) => setModalState(() => _paymentStatus = val!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _transactionController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction ID (Optional)',
                        prefixIcon: Icon(Icons.receipt),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isAddingBatch ? null : () {
                    if (_selectedBatchId == null) {
                      SnackbarHelper.showError(context, 'Please select a batch.');
                      return;
                    }
                    _attachBatch();
                  },
                  child: _isAddingBatch
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enroll'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  Widget _buildProfileItem(String label, dynamic value, IconData icon) {
    final theme = Theme.of(context);
    final displayValue = (value == null || value.toString().isEmpty) ? 'Not Provided' : value.toString();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary.withOpacity(0.7), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 4),
            Text(displayValue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TeacherLayout(
      title: 'Student Details',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _student == null
              ? const Center(child: Text('Student not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Student Profile',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Student Header Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                _student!['name'][0].toUpperCase(),
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _student!['name'],
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _student!['email'],
                                    style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  ),
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
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isActive ? 'Active Student' : 'Inactive Account',
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
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
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                        child: Wrap(
                          spacing: 48,
                          runSpacing: 24,
                          children: [
                            _buildProfileItem('Father\'s Name', _student!['father_name'], Icons.family_restroom),
                            _buildProfileItem('Phone', _student!['phone'], Icons.phone),
                            _buildProfileItem('Registration ID', _student!['registration_id'], Icons.badge),
                            _buildProfileItem('DOB', _student!['dob'], Icons.cake),
                            _buildProfileItem('Gender', _student!['gender'], Icons.person_outline),
                            _buildProfileItem('Address', _student!['address'], Icons.location_on),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Batches Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enrolled Batches',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddBatchModal,
                            icon: const Icon(Icons.add),
                            label: const Text('Manage Batches'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      if ((_student!['batches'] as List?)?.isEmpty ?? true)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                          child: Center(
                            child: Text(
                              'This student is not enrolled in any batches yet.',
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: (_student!['batches'] as List).map((batch) {
                            final pivot = batch['pivot'];
                            final enrolledDate = _formatDate(pivot?['created_at']);
                            
                            return Container(
                              width: 300,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.class_, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          batch['name'],
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (batch['course'] != null) ...[
                                    Text(
                                      'Course: ${batch['course']['name']}',
                                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.dividerColor.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Enrolled: $enrolledDate',
                                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Amount: \${pivot?['amount_paid'] ?? 'N/A'}", 
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(pivot?['status']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          (pivot?['status'] ?? 'Unpaid').toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(pivot?['status'])),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (pivot?['transaction_id'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text("Txn ID: \${pivot['transaction_id']}", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
    );
  }
}
