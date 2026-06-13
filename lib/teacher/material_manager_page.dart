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
  String _searchQuery = '';

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

  void _showEditModal(dynamic material) {
    final titleController = TextEditingController(text: material['title']);
    final descController = TextEditingController(text: material['description'] ?? '');
    bool isSaving = false;
    PlatformFile? newFile;

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
                          'Edit Material',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (!isSaving)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    // File Replacement UI
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: isSaving ? null : () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              withData: true, // Need bytes for web
                            );
                            if (result != null) {
                              setModalState(() => newFile = result.files.first);
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Replace Document / Image'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            newFile != null ? newFile!.name : 'Keep existing file',
                            style: TextStyle(
                              color: newFile != null ? Colors.green : Colors.grey,
                              fontWeight: newFile != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (newFile != null && !isSaving)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () => setModalState(() => newFile = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (titleController.text.trim().isEmpty) {
                                  SnackbarHelper.showError(context, 'Title is required');
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('auth_token');

                                try {
                                  if (newFile == null) {
                                    // Standard JSON PUT
                                    final response = await http.put(
                                      Uri.parse('http://127.0.0.1:8000/api/materials/${material['id']}'),
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Accept': 'application/json',
                                        'Content-Type': 'application/json'
                                      },
                                      body: jsonEncode({
                                        'title': titleController.text.trim(),
                                        'description': descController.text.trim(),
                                      }),
                                    );

                                    if (response.statusCode == 200) {
                                      Navigator.pop(context);
                                      _fetchData();
                                      SnackbarHelper.showSuccess(context, 'Material updated successfully');
                                    } else {
                                      final body = jsonDecode(response.body);
                                      SnackbarHelper.showError(context, body['message'] ?? 'Failed to update material');
                                    }
                                  } else {
                                    // Multipart POST with _method=PUT
                                    var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/api/materials/${material['id']}'));
                                    request.headers['Authorization'] = 'Bearer $token';
                                    request.headers['Accept'] = 'application/json';
                                    
                                    request.fields['_method'] = 'PUT';
                                    request.fields['title'] = titleController.text.trim();
                                    request.fields['description'] = descController.text.trim();

                                    request.files.add(http.MultipartFile.fromBytes(
                                      'file',
                                      newFile!.bytes!,
                                      filename: newFile!.name,
                                    ));

                                    var response = await request.send();
                                    var responseData = await response.stream.bytesToString();

                                    if (response.statusCode == 200) {
                                      Navigator.pop(context);
                                      _fetchData();
                                      SnackbarHelper.showSuccess(context, 'Material and file updated successfully');
                                    } else {
                                      final body = jsonDecode(responseData);
                                      SnackbarHelper.showError(context, body['message'] ?? 'Failed to update material');
                                    }
                                  }
                                } catch (e) {
                                  SnackbarHelper.showError(context, 'Network error during update');
                                } finally {
                                  if (mounted) setModalState(() => isSaving = false);
                                }
                              },
                        child: isSaving
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes'),
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

  void _showImageFullScreen(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search materials by title or description...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase());
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final filteredMaterials = _materials.where((m) {
                        final matchesSearch = _searchQuery.isEmpty ||
                            (m['title']?.toLowerCase() ?? '').contains(_searchQuery) ||
                            (m['description']?.toLowerCase() ?? '').contains(_searchQuery);
                        return matchesSearch;
                      }).toList();

                      if (filteredMaterials.isEmpty) {
                        return Center(
                          child: Text(
                            'No materials found',
                            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(32),
                        itemCount: filteredMaterials.length,
                        itemBuilder: (context, index) {
                          final material = filteredMaterials[index];
                          final isImage = material['file_url'].toString().toLowerCase().endsWith('.jpg') ||
                                          material['file_url'].toString().toLowerCase().endsWith('.png') ||
                                          material['file_url'].toString().toLowerCase().endsWith('.jpeg');
                          
                          String formattedDate = '';
                          if (material['created_at'] != null) {
                            try {
                              final date = DateTime.parse(material['created_at']);
                              formattedDate = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                            } catch (e) {
                              formattedDate = '';
                            }
                          }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                            ),
                            child: InkWell(
                              onTap: isImage
                                  ? () => _showImageFullScreen(material['file_url'], material['title'])
                                  : () {
                                      SnackbarHelper.showSuccess(context, 'Document opened (Simulated)');
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 140,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                    ),
                                    child: isImage
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                                child: Image.network(material['file_url'], fit: BoxFit.cover),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                                  color: Colors.black.withOpacity(0.3),
                                                ),
                                              ),
                                              const Center(
                                                child: Icon(Icons.zoom_in, color: Colors.white, size: 32),
                                              ),
                                            ],
                                          )
                                        : const Center(
                                            child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  material['title'],
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (formattedDate.isNotEmpty)
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              material['batch'] != null ? material['batch']['name'] : 'Unknown Batch',
                                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (material['description'] != null && material['description'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              material['description'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.4),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _showEditModal(material),
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          tooltip: 'Edit Material',
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteMaterial(material['id']),
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete Material',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),
          ),
        ],
      ),
    );
  }
}
