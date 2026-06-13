import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import '../layout/teacher_layout.dart';

class MaterialManagerPage extends StatefulWidget {
  const MaterialManagerPage({super.key});

  @override
  State<MaterialManagerPage> createState() => _MaterialManagerPageState();
}

class _MaterialManagerPageState extends State<MaterialManagerPage> {
  List<dynamic> _materials = [];
  List<dynamic> _batches = [];
  List<dynamic> _courses = [];
  bool _isLoading = false;

  String? _selectedCourseId;
  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final coursesRes = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/courses'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (coursesRes.statusCode == 200) {
        _courses = jsonDecode(coursesRes.body);
      }

      await _fetchBatches(token!);
      await _fetchData();
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to load initial data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBatches(String token) async {
    String url = 'http://127.0.0.1:8000/api/batches';
    if (_selectedCourseId != null) {
      url += '?course_id=$_selectedCourseId';
    }
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        _batches = jsonDecode(res.body);
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to load batches');
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    String url = 'http://127.0.0.1:8000/api/materials';
    if (_selectedBatchId != null) {
      url += '?batch_id=$_selectedBatchId';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _materials = jsonDecode(response.body);
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to load materials');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMaterial(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/api/materials/$id'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 204) {
        _fetchData();
        SnackbarHelper.showSuccess(context, 'Material deleted successfully');
      } else {
        SnackbarHelper.showError(context, 'Failed to delete material');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while deleting material');
    }
  }

  void _showUploadModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int? selectedBatchId = _batches.isNotEmpty ? _batches.first['id'] : null;
    PlatformFile? selectedFile;
    bool isUploading = false;

    if (_batches.isEmpty) {
      SnackbarHelper.showError(context, 'Please create a batch first!');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        const Text(
                          'Upload Material',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (!isUploading)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      value: selectedBatchId,
                      decoration: const InputDecoration(labelText: 'Select Batch', border: OutlineInputBorder()),
                      items: _batches.map((b) => DropdownMenuItem<int>(
                        value: b['id'],
                        child: Text(b['name']),
                      )).toList(),
                      onChanged: isUploading ? null : (val) => setModalState(() => selectedBatchId = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      enabled: !isUploading,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      enabled: !isUploading,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.withOpacity(0.05),
                      ),
                      child: Column(
                        children: [
                          if (selectedFile != null)
                            Text('Selected: ${selectedFile!.name}', style: const TextStyle(fontWeight: FontWeight.bold))
                          else
                            const Text('No file selected', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final result = await FilePicker.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                                      withData: true,
                                    );
                                    if (result != null) {
                                      setModalState(() => selectedFile = result.files.first);
                                    }
                                  },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Choose File'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                                if (titleController.text.trim().isEmpty) {
                                  SnackbarHelper.showError(context, 'Title is required');
                                  return;
                                }
                                if (selectedFile == null) {
                                  SnackbarHelper.showError(context, 'Please select a file');
                                  return;
                                }

                                setModalState(() => isUploading = true);

                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('auth_token');

                                try {
                                  var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/api/materials'));
                                  request.headers['Authorization'] = 'Bearer $token';
                                  request.headers['Accept'] = 'application/json';
                                  
                                  request.fields['batch_id'] = selectedBatchId.toString();
                                  request.fields['title'] = titleController.text.trim();
                                  request.fields['description'] = descController.text.trim();

                                  request.files.add(http.MultipartFile.fromBytes(
                                    'file',
                                    selectedFile!.bytes!,
                                    filename: selectedFile!.name,
                                  ));

                                  var streamedResponse = await request.send();
                                  var response = await http.Response.fromStream(streamedResponse);

                                  if (response.statusCode == 201) {
                                    Navigator.pop(context);
                                    _fetchData();
                                    SnackbarHelper.showSuccess(context, 'Material uploaded successfully');
                                  } else {
                                    final body = jsonDecode(response.body);
                                    SnackbarHelper.showError(context, body['message'] ?? 'Failed to upload material');
                                  }
                                } catch (e) {
                                  SnackbarHelper.showError(context, 'Network error during upload');
                                } finally {
                                  if (mounted) setModalState(() => isUploading = false);
                                }
                              },
                        child: isUploading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Upload Material'),
                      ),
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
      title: 'Study Materials',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study Materials Management',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload and manage study materials for your batches.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showUploadModal,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload Material'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(labelText: 'Filter by Course', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Courses')),
                      ..._courses.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))),
                    ],
                    onChanged: (val) async {
                      setState(() {
                        _selectedCourseId = val;
                        _selectedBatchId = null;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('auth_token');
                      await _fetchBatches(token!);
                      _fetchData();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBatchId,
                    decoration: const InputDecoration(labelText: 'Filter by Batch', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Batches')),
                      ..._batches.map((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name']))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBatchId = val);
                      _fetchData();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _materials.isEmpty
                    ? Center(
                        child: Text(
                          'No materials found',
                          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(32),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: _materials.length,
                        itemBuilder: (context, index) {
                          final material = _materials[index];
                          final isImage = material['file_url'].toString().toLowerCase().endsWith('.jpg') ||
                                          material['file_url'].toString().toLowerCase().endsWith('.png') ||
                                          material['file_url'].toString().toLowerCase().endsWith('.jpeg');
                          
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: isImage
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: Image.network(material['file_url'], fit: BoxFit.cover),
                                          )
                                        : const Center(
                                            child: Icon(Icons.picture_as_pdf, size: 64, color: Colors.redAccent),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        material['title'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        material['batch'] != null ? material['batch']['name'] : 'Unknown Batch',
                                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      if (material['description'] != null && material['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          material['description'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _deleteMaterial(material['id']),
                                          icon: const Icon(Icons.delete, size: 16),
                                          label: const Text('Delete'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
