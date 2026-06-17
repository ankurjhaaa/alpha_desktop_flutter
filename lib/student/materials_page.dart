import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alpha_desktop_flutter/core/utils/snackbar_helper.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../layout/student_layout.dart';
import 'package:alpha_desktop_flutter/core/constants/api_constants.dart';

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  List<dynamic> _materials = [];
  bool _isLoading = false;
  
  String _searchQuery = '';
  String _selectedBatch = 'All';
  List<String> _uniqueBatches = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/materials'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Set<String> batches = {'All'};
        for (var m in data) {
          if (m['batch'] != null && m['batch']['name'] != null) {
            batches.add(m['batch']['name']);
          }
        }
        
        setState(() {
          _materials = data;
          _uniqueBatches = batches.toList();
          if (!_uniqueBatches.contains(_selectedBatch)) {
            _selectedBatch = 'All';
          }
        });
      } else {
        SnackbarHelper.showError(context, 'Failed to load study materials');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error while loading materials');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _showPdfFullScreen(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: SfPdfViewer.network(
                  url,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageFullScreen(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Study Materials',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchMaterials,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Tabs & Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                final filterChips = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _uniqueBatches.map((batchName) {
                    final isSelected = _selectedBatch == batchName;
                    return ChoiceChip(
                      label: Text(batchName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedBatch = batchName);
                        }
                      },
                    );
                  }).toList(),
                );

                final searchBox = SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search materials...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase());
                    },
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      filterChips,
                      const SizedBox(height: 16),
                      searchBox,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: filterChips),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: searchBox),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final filteredMaterials = _materials.where((m) {
                        final matchesBatch = _selectedBatch == 'All' || (m['batch'] != null && m['batch']['name'] == _selectedBatch);
                        final matchesSearch = _searchQuery.isEmpty ||
                            (m['title']?.toLowerCase() ?? '').contains(_searchQuery) ||
                            (m['description']?.toLowerCase() ?? '').contains(_searchQuery);
                        return matchesBatch && matchesSearch;
                      }).toList();

                      if (filteredMaterials.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'No matching materials found',
                                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              ),
                            ],
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
                                  : () => _showPdfFullScreen(material['file_url'], material['title']),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left side thumbnail
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
                                  // Right side details
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
