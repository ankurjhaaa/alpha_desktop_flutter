import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/services/settings_service.dart';
import '../core/utils/snackbar_helper.dart';
import '../layout/teacher_layout.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  final Map<String, TextEditingController> _controllers = {
    'company_name': TextEditingController(),
    'company_email': TextEditingController(),
    'company_phone': TextEditingController(),
    'company_address': TextEditingController(),
    'logo_url': TextEditingController(),
    'signature_url': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/settings'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _controllers['company_name']?.text = data['company_name'] ?? '';
          _controllers['company_email']?.text = data['company_email'] ?? '';
          _controllers['company_phone']?.text = data['company_phone'] ?? '';
          _controllers['company_address']?.text = data['company_address'] ?? '';
          _controllers['logo_url']?.text = data['logo_url'] ?? '';
          _controllers['signature_url']?.text = data['signature_url'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final Map<String, String> data = {};
      _controllers.forEach((key, controller) {
        data[key] = controller.text;
      });

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Settings updated successfully.');
          SettingsService.fetchAndCacheSettings(); // update cache
        }
      } else {
        if (mounted) SnackbarHelper.showError(context, 'Failed to update settings.');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'An error occurred.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, String key, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _controllers[key],
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      title: 'Settings',
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Global Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Configure the branding and global details used across the platform and PDFs.'),
                    const SizedBox(height: 32),
                    _buildTextField('Company Name', 'company_name'),
                    _buildTextField('Company Email', 'company_email'),
                    _buildTextField('Company Phone', 'company_phone'),
                    _buildTextField('Company Address', 'company_address', maxLines: 2),
                    const Divider(height: 48),
                    const Text('Media URLs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField('Logo URL', 'logo_url'),
                    _buildTextField('Signature URL', 'signature_url'),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Icon(Icons.save),
                        label: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
