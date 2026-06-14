import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/student_layout.dart';
import '../core/utils/snackbar_helper.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/student/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _profile = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarHelper.showError(context, 'Failed to load profile.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Network Error.');
      }
    }
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

    return StudentLayout(
      title: 'My Profile',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Could not load profile.'))
              : Container(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // Profile Header
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
                              radius: 36,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                (_profile!['name'] ?? 'S')[0].toUpperCase(),
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile!['name'] ?? 'Student',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _profile!['email'] ?? '',
                                    style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                  if (_profile!['registration_id'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Admission No: ${_profile!['registration_id']}',
                                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Personal Info Grid
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
                                  _buildInfoItem(theme, "Father's Name", _profile!['father_name'], Icons.family_restroom),
                                  _buildInfoItem(theme, 'Phone', _profile!['phone'], Icons.phone_outlined),
                                  _buildInfoItem(theme, 'Date of Birth', _formatDate(_profile!['dob']), Icons.cake_outlined),
                                  _buildInfoItem(theme, 'Gender', _profile!['gender'], Icons.person_outline),
                                  _buildInfoItem(theme, 'Address', _profile!['address'], Icons.location_on_outlined),
                                  _buildInfoItem(theme, 'Member Since', _formatDate(_profile!['created_at']), Icons.calendar_today),
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

                      // Enrolled Batches
                      const Text('My Enrolled Batches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      if ((_profile!['batches'] as List?)?.isEmpty ?? true)
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
                                'You are not enrolled in any batches.',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              // Table Header
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
                                    Expanded(flex: 2, child: Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    Expanded(flex: 1, child: Text('Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),
                              // Rows
                              ...(_profile!['batches'] as List).asMap().entries.map((entry) {
                                final index = entry.key;
                                final batch = entry.value;
                                final pivot = batch['pivot'];
                                final isLast = index == (_profile!['batches'] as List).length - 1;

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
                                          batch['schedule_time'] ?? 'N/A',
                                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          batch['fee'] != null ? '₹${batch['fee']}' : 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(pivot?['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (pivot?['status'] ?? 'unpaid').toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(pivot?['status']),
                                              ),
                                            ),
                                          ),
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
