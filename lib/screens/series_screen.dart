// lib/screens/series/series_screen.dart
import 'dart:convert';
import 'dart:io'; // ✅ for saving binary files
import 'dart:ui'; // for BackdropFilter (glass search)
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:url_launcher/url_launcher.dart'; // ❌ not needed for local files
import 'package:open_filex/open_filex.dart'; // ✅ open local files safely

import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final AuthService _authService = AuthService();
  final Dio _dio = Dio();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _tree = [];
  List<Map<String, dynamic>> _filteredTree = [];

  // 🔎 Flat index + results for robust nested search
  List<Map<String, dynamic>> _flatIndex = [];
  List<Map<String, dynamic>> _searchResults = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(_filter);
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _authService.getFiles(); // no params
      _tree = _normalizeItems(list, parentPath: '');
      _filteredTree = _tree;

      // build flat index for fast, reliable nested search
      _flatIndex = _flattenTree(_tree);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load files. $e';
      });
    }
  }

  List<Map<String, dynamic>> _normalizeItems(List<Map<String, dynamic>> items, {required String parentPath}) {
    final out = <Map<String, dynamic>>[];
    for (final item in items) {
      final name = (item['name'] ?? '').toString();
      final isFolder = item['children'] != null;
      final path = parentPath.isEmpty ? name : '$parentPath/$name';

      if (isFolder) {
        final childrenRaw = (item['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        out.add({
          'title': name,
          'name': name,
          'isFolder': true,
          'path': path,
          'children': _normalizeItems(childrenRaw, parentPath: path),
        });
      } else {
        out.add({
          'title': name,
          'name': name,
          'isFolder': false,
          'path': path,
          'url': _buildDownloadUrl(path), // add real download endpoint if any
          'extension': (item['extension'] ?? '').toString(),
          'length': item['length'],
          'lastModified': item['lastModified'],
        });
      }
    }
    return out;
  }

  // Example download URL builder (keep '' if none)
  String _buildDownloadUrl(String path) => '';

  // ------------------ Search ------------------

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  void _filter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredTree = _tree;
      });
      return;
    }

    bool matches(Map<String, dynamic> n) {
      final title = (n['title'] ?? n['name'] ?? '').toString().toLowerCase();
      final path = (n['path'] ?? '').toString().toLowerCase();
      return title.contains(q) || path.contains(q);
    }

    final hits = _flatIndex.where(matches).toList();

    // Sort: files before folders, then shorter paths, then title
    hits.sort((a, b) {
      final af = (a['isFolder'] == true) ? 1 : 0;
      final bf = (b['isFolder'] == true) ? 1 : 0;
      final c1 = af.compareTo(bf); // files (0) before folders (1)
      if (c1 != 0) return c1;
      final ap = (a['path'] ?? '').toString();
      final bp = (b['path'] ?? '').toString();
      final c2 = ap.length.compareTo(bp.length);
      if (c2 != 0) return c2;
      final at = (a['title'] ?? a['name'] ?? '').toString().toLowerCase();
      final bt = (b['title'] ?? b['name'] ?? '').toString().toLowerCase();
      return at.compareTo(bt);
    });

    setState(() {
      _searchResults = hits;
    });
  }

  List<Map<String, dynamic>> _flattenTree(List<Map<String, dynamic>> nodes) {
    final out = <Map<String, dynamic>>[];
    void walk(List<Map<String, dynamic>> xs) {
      for (final n in xs) {
        out.add(n);
        if (n['isFolder'] == true) {
          final children = (n['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          walk(children);
        }
      }
    }

    walk(nodes);
    return out;
  }

  Map<String, dynamic>? _findNodeByPath(List<Map<String, dynamic>> nodes, String path) {
    for (final n in nodes) {
      if ((n['path'] ?? '') == path) return n;
      if (n['isFolder'] == true) {
        final child = _findNodeByPath(
          (n['children'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          path,
        );
        if (child != null) return child;
      }
    }
    return null;
  }

  void _openFolderByPath(String path) {
    final node = _findNodeByPath(_tree, path);
    if (node == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder not found.')),
      );
      return;
    }

    // Clear search and focus the UI into the found folder
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _filteredTree = [node];
    });
  }

  // ------------------ Download & Open ------------------

  // ✅ Uses POST /api/filedownloads/download and opens with OpenFilex
  //    Pass RELATIVE PATH (node['path']) as fileName to backend.
  Future<void> _downloadAndOpen(String _ignoredUrl, String fileNameOrPath) async {
    try {
      final result = await _authService.downloadFile(fileNameOrPath);

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${result.filename}';

      if (result.hasUrl) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${result.filename}...')),
        );
        await _dio.download(result.url!, savePath);
      } else if (result.hasBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saving ${result.filename}...')),
        );
        final file = File(savePath);
        await file.writeAsBytes(result.bytes!, flush: true);
      } else {
        throw Exception('No data returned for download.');
      }

      // ✅ Open local file via FileProvider-safe API
      final mime = _inferMimeType(result.filename);
      final openRes = await OpenFilex.open(savePath, type: mime);

      if (openRes.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(openRes.message.isNotEmpty ? openRes.message : 'No app found to open this file.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  String _inferMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx')) return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    return '*/*';
  }

  // Icons/colors used in search-results (parent level helpers)
  IconData _iconForType(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'word':
        return Icons.article;
      case 'excel':
        return Icons.table_chart;
      case 'powerpoint':
        return Icons.slideshow;
      case 'text':
        return Icons.text_snippet;
      case 'archive':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.amber;
      case 'audio':
        return Colors.purple;
      case 'video':
        return Colors.indigo;
      case 'word':
        return Colors.blue;
      case 'excel':
        return Colors.green;
      case 'powerpoint':
        return Colors.orange;
      case 'text':
        return Colors.grey;
      case 'archive':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // ------------------ UI ------------------

  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  Widget _glassSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Search files or folders...',
              hintStyle: TextStyle(color: Colors.black54),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = Center(child: Text(_errorMessage!));
    } else if (_isSearching) {
      // 🔎 Flat search-results view
      if (_searchResults.isEmpty) {
        content = const Center(child: Text('No matches'));
      } else {
        content = ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _searchResults.length,
          itemBuilder: (context, i) {
            final n = _searchResults[i];
            final isFolder = n['isFolder'] == true;
            final title = (n['title'] ?? n['name'] ?? '').toString();
            final path = (n['path'] ?? '').toString();
            final type = isFolder ? 'folder' : _inferTypeFromName(title);

            return ListTile(
              dense: true,
              minLeadingWidth: 20,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              leading: Icon(
                isFolder ? Icons.folder : _iconForType(type),
                color: isFolder ? Colors.amber : _colorForType(type),
                size: 18,
              ),
              title: Text(title, style: const TextStyle(fontSize: 13.5)),
              subtitle: Text(path, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              onTap: () {
                if (isFolder) {
                  _openFolderByPath(path);
                } else {
                  // ⬇️ Use RELATIVE PATH for accurate download
                  _downloadAndOpen(n['url'] ?? '', path);
                }
              },
            );
          },
        );
      }
    } else {
      // 🌳 Normal tree view
      content = _filteredTree.isEmpty
          ? const Center(child: Text('No files found'))
          : ListView(
              padding: EdgeInsets.zero,
              children: _filteredTree
                  .map((n) => _Node(
                        node: n,
                        onFileTap: _downloadAndOpen,
                        inferType: _inferTypeFromName,
                      ))
                  .toList(),
            );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Image.asset('assets/images/background.jpeg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _glassSearchBar(),
                const SizedBox(height: 16),
                const Text('Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      dividerColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      textTheme: Theme.of(context).textTheme.copyWith(
                            titleMedium: const TextStyle(fontSize: 13.5),
                          ),
                    ),
                    child: ListTileTheme(
                      dense: true,
                      tileColor: Colors.transparent,
                      selectedTileColor: Colors.transparent,
                      minLeadingWidth: 20,
                      horizontalTitleGap: 8,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _inferTypeFromName(String nameOrUrl) {
    final lower = nameOrUrl.toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : '';
    switch (ext) {
      case 'pdf':
        return 'pdf';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return 'image';
      case 'mp3':
      case 'wav':
        return 'audio';
      case 'mp4':
        return 'video';
      case 'doc':
      case 'docx':
        return 'word';
      case 'xls':
      case 'xlsx':
        return 'excel';
      case 'ppt':
      case 'pptx':
        return 'powerpoint';
      case 'txt':
        return 'text';
      case 'zip':
      case 'rar':
        return 'archive';
      default:
        return 'unknown';
    }
  }
}

class _Node extends StatelessWidget {
  final Map<String, dynamic> node;
  final Future<void> Function(String url, String nameOrPath) onFileTap;
  final String Function(String) inferType;

  const _Node({
    required this.node,
    required this.onFileTap,
    required this.inferType,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'word':
        return Icons.article;
      case 'excel':
        return Icons.table_chart;
      case 'powerpoint':
        return Icons.slideshow;
      case 'text':
        return Icons.text_snippet;
      case 'archive':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.amber;
      case 'audio':
        return Colors.purple;
      case 'video':
        return Colors.indigo;
      case 'word':
        return Colors.blue;
      case 'excel':
        return Colors.green;
      case 'powerpoint':
        return Colors.orange;
      case 'text':
        return Colors.grey;
      case 'archive':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFolder = node['isFolder'] == true;
    final title = (node['title'] ?? node['name'] ?? 'Untitled').toString();
    final url = (node['url'] ?? '').toString();
    final path = (node['path'] ?? title).toString();
    final children = (node['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (isFolder) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.folder, color: Colors.amber, size: 22),
          title: Text(title, style: const TextStyle(fontSize: 13.5)),
          iconColor: Colors.grey[700],
          collapsedIconColor: Colors.grey[700],
          tilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          childrenPadding: const EdgeInsets.only(left: 14),
          shape: const Border(),
          collapsedShape: const Border(),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          children: children
              .map((c) => _Node(node: c, onFileTap: onFileTap, inferType: inferType))
              .toList(),
        ),
      );
    } else {
      final type = inferType(url.isNotEmpty ? url : title);
      return ListTile(
        dense: true,
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        leading: Icon(_iconForType(type), color: _colorForType(type), size: 18),
        title: Text(title, style: const TextStyle(fontSize: 13.5)),
        // ⬇️ Pass RELATIVE PATH so server can locate nested files
        onTap: () => onFileTap(url, path),
      );
    }
  }
}