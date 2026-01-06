// lib/screens/series/series_screen.dart
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io'; // ✅ for saving binary files
import 'dart:ui'; // for BackdropFilter (glass search)
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // ✅ open local files safely

import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';
import '../main_navigation_screen.dart';

class SeriesScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const SeriesScreen({super.key, this.onRefresh});

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

  // ✅ Download state management
  bool _isDownloading = false;
  String? _downloadingFileName;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    fetch();
    _searchController.addListener(_filter);
  }

  Future<void> fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Debug: Fetching files...');
      final list = await _authService.getFiles(); // no params

      print('✅ Debug: Got ${list.length} items from API');

      if (list.isNotEmpty) {
        print('🔍 Debug: First item keys: ${list.first.keys}');
        print('🔍 Debug: First item: ${list.first}');
      } else {
        print('⚠️ Debug: API returned empty list');
      }

      _tree = _normalizeItems(list, parentPath: '');
      _filteredTree = _tree;

      print('✅ Debug: Normalized tree has ${_tree.length} items');
      if (_tree.isNotEmpty) {
        print('🔍 Debug: First tree item: ${_tree.first}');
      }

      // build flat index for fast, reliable nested search
      _flatIndex = _flattenTree(_tree);
      print('✅ Debug: Flat index has ${_flatIndex.length} items');

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Debug: Error in fetch: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load files. $e';
      });
    }
  }

  List<Map<String, dynamic>> _normalizeItems(List<Map<String, dynamic>> items, {required String parentPath}) {
    final out = <Map<String, dynamic>>[];

    for (final item in items) {
      // Skip if name is just "/" - this seems to be the root
      final rawName = (item['Name'] ?? item['name'] ?? '').toString().trim();
      if (rawName == '/' || rawName.isEmpty) {
        // Handle root folder specially - get its children
        final childrenRaw = (item['Children'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (childrenRaw.isNotEmpty) {
          // Process children with empty parent path
          final children = _normalizeItems(childrenRaw, parentPath: '');
          out.addAll(children);
        }
        continue;
      }

      // ✅ Check for 'Children' field from API
      final hasChildren = item['Children'] != null && (item['Children'] as List).isNotEmpty;
      final isFolder = hasChildren || (item['Extension'] == null && (item['Length'] == null || item['Length'] == 0));

      final path = parentPath.isEmpty ? rawName : '$parentPath/$rawName';

      if (isFolder) {
        final childrenRaw = (item['Children'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        out.add({
          'title': rawName,
          'name': rawName,
          'isFolder': true,
          'path': path,
          'children': _normalizeItems(childrenRaw, parentPath: path),
        });
      } else {
        // ✅ Build proper download URL
        String downloadUrl = '';
        if (item['Path'] != null) {
          downloadUrl = _buildDownloadUrl(item['Path'].toString());
        } else if (item['path'] != null) {
          downloadUrl = _buildDownloadUrl(item['path'].toString());
        } else {
          downloadUrl = _buildDownloadUrl(path);
        }

        out.add({
          'title': rawName,
          'name': rawName,
          'isFolder': false,
          'path': path,
          'url': downloadUrl,
          'extension': (item['Extension'] ?? '').toString(),
          'length': item['Length'] ?? item['length'] ?? 0,
          'lastModified': item['LastModified'] ?? item['lastModified'] ?? '',
        });
      }
    }
    return out;
  }

  // ✅ FIX: Update download URL builder
  String _buildDownloadUrl(String path) {
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return 'https://jpapi.inspirertechnologies.com/api/filedownloads/download?fileName=$cleanPath';
  }

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

  Future<void> _downloadAndOpen(String _ignoredUrl, String fileNameOrPath) async {
    // ✅ Start download state
    setState(() {
      _isDownloading = true;
      _downloadingFileName = fileNameOrPath.split('/').last;
      _downloadProgress = 0.0;
    });

    try {
      print('🔍 Debug: Starting download for: $fileNameOrPath');
      final result = await _authService.downloadFile(fileNameOrPath);

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${result.filename}';

      print('✅ Debug: Save path = $savePath');

      if (result.hasUrl) {
        // Show initial download message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${result.filename}...')),
        );

        // Download with progress tracking
        await _dio.download(
          result.url!,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _downloadProgress = received / total;
              });
            }
          },
        );
        print('✅ Debug: Downloaded via URL');
      } else if (result.hasBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saving ${result.filename}...')),
        );
        final file = File(savePath);
        await file.writeAsBytes(result.bytes!, flush: true);
        print('✅ Debug: Saved bytes directly, size = ${result.bytes!.length}');
      } else {
        throw Exception('No data returned for download.');
      }

      // ✅ Reset download state before opening file
      setState(() {
        _isDownloading = false;
        _downloadingFileName = null;
        _downloadProgress = 0.0;
      });

      // ✅ Open local file via FileProvider-safe API
      final mime = _inferMimeType(result.filename);
      print('🔍 Debug: Opening file with mime: $mime');

      final openRes = await OpenFilex.open(savePath, type: mime);
      print('✅ Debug: Open result = ${openRes.type}, message = ${openRes.message}');

      if (openRes.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(openRes.message.isNotEmpty ? openRes.message : 'No app found to open this file.')),
        );
      }
    } catch (e) {
      // ✅ Reset download state on error
      setState(() {
        _isDownloading = false;
        _downloadingFileName = null;
        _downloadProgress = 0.0;
      });

      print('❌ Debug: Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
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

  // ✅ Download progress dialog
  Widget _buildDownloadDialog() {
    return AlertDialog(
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Theme-colored circular progress indicator
          CircularProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED3237)),
            backgroundColor: const Color(0xFFED3237).withOpacity(0.2),
            strokeWidth: 4,
          ),
          const SizedBox(height: 20),
          const Text(
            'Downloading...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFED3237),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _downloadingFileName ?? 'File',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (_downloadProgress > 0)
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFED3237),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    // Responsive scaling factors - same as HomeScreen
    final double scale = width / 430;
    double responsive(double size) => size * scale;

    final bool isVerySmall = width < 350;

    final Widget content;
    if (_isLoading) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF871C1F)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading resources...',
              style: TextStyle(color: Color(0xFF871C1F)),
            ),
          ],
        ),
      );
    } else if (_errorMessage != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED3237),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else if (_isSearching) {
      // 🔎 Flat search-results view
      if (_searchResults.isEmpty) {
        content = const Center(
          child: Text(
            'No matches found',
            style: TextStyle(color: Colors.grey),
          ),
        );
      } else {
        content = ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _searchResults.length,
          itemBuilder: (context, i) {
            final n = _searchResults[i];
            final isFolder = n['isFolder'] == true;
            final title = (n['title'] ?? n['name'] ?? '').toString();
            final path = (n['path'] ?? '').toString();
            final isPDF = title.toLowerCase().endsWith('.pdf');

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4), // ✅ FURTHER REDUCED GAP
              child: Card(
                elevation: 1.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: ListTile(
                  dense: true,
                  minLeadingWidth: 16,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // ✅ COMPACT
                  // In the search results section, update the leading icon:
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isFolder
                          ? Color(0xFFED3237).withOpacity(0.1) // ✅ RED for folders
                          : (isPDF ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      isFolder ? Icons.folder :
                      isPDF ? Icons.picture_as_pdf : Icons.insert_drive_file,
                      color: isFolder ? Color(0xFFED3237) : // ✅ RED for folders
                      isPDF ? Colors.red : Colors.blue,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    path,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isPDF
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  )
                      : null,
                  onTap: () {
                    if (isFolder) {
                      _openFolderByPath(path);
                    } else {
                      _downloadAndOpen(n['url'] ?? '', path);
                    }
                  },
                ),
              ),
            );
          },
        );
      }
    } else {
      // 🌳 Normal tree view (HIERARCHICAL)
      content = _filteredTree.isEmpty
          ? const Center(
        child: Text(
          'No resources available',
          style: TextStyle(color: Colors.grey),
        ),
      )
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
      drawer: const AppDrawer(),
      body: Stack(
        children: [

          // ================= LOGO BANNERS =================
          Positioned(
            top: media.padding.top + responsive(10),
            left: responsive(16),
            right: responsive(16),
            child: Visibility(
              visible: !isVerySmall,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/insp.png',
                    width: responsive(90),
                    height: responsive(35),
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/stem.png',
                    width: responsive(60),
                    height: responsive(44),
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/javed.png',
                    width: responsive(70),
                    height: responsive(38),
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          // ================= VECTOR 7 (TOP RIGHT → LEFT FLOW) =================
          Positioned(
            top: responsive(-60),
            right: responsive(-220),
            child: Opacity(
              opacity: 0.99,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(-1.0, 1.0)
                  ..rotateZ(27.37 * math.pi / 180),
                child: SizedBox(
                  width: responsive(847.9),
                  height: responsive(347.6),
                  child: Image.asset(
                    'assets/images/Vector7.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
          // ================= VECTOR 8 (BOTTOM LEFT SUPPORT) =================
          Positioned(
            top: responsive(520),
            left: responsive(-200),
            child: Opacity(
              opacity: 0.99,
              child: Transform.rotate(
                angle: -12.24 * math.pi / 180,
                child: SizedBox(
                  width: responsive(847.9),
                  height: responsive(347.6),
                  child: Image.asset(
                    'assets/images/vector8.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),

          // ================= MAIN CONTENT =================
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive(16),
              media.padding.top + responsive(115),
              responsive(16),
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _glassSearchBar(),
                const SizedBox(height: 12),

                Text(
                  'Resources',
                  style: GoogleFonts.poppins(
                    fontSize: responsive(22),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF871C1F),
                  ),
                ),
                const SizedBox(height: 4),

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

          // ✅ Download progress overlay
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: Center(
                child: _buildDownloadDialog(),
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

  @override
  Widget build(BuildContext context) {
    final isFolder = node['isFolder'] == true;
    final title = (node['title'] ?? node['name'] ?? 'Untitled').toString().trim();

    if (title.isEmpty) {
      return const SizedBox();
    }

    final url = (node['url'] ?? '').toString();
    final path = (node['path'] ?? title).toString();
    final children = (node['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (isFolder) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4), // ✅ FURTHER REDUCED GAP
        child: Card(
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Row(
                children: [
                  // ✅ CHANGED: Folder icon from amber to red
                  Icon(Icons.folder, color: Color(0xFF871C1F), size: 20), // RED FOLDER
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              iconColor: Colors.grey[700],
              collapsedIconColor: Colors.grey[700],
              tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // ✅ COMPACT
              childrenPadding: const EdgeInsets.only(left: 12), // ✅ REDUCED INDENT
              backgroundColor: Colors.grey[50],
              collapsedBackgroundColor: Colors.transparent,
              children: children
                  .map((c) => _Node(node: c, onFileTap: onFileTap, inferType: inferType))
                  .toList(),
            ),
          ),
        ),
      );
    } else {
      // ✅ FILE ITEM - CLEAR AND VISIBLE WITH COMPACT DESIGN
      final isPDF = title.toLowerCase().endsWith('.pdf');
      final icon = isPDF ? Icons.picture_as_pdf : Icons.insert_drive_file;
      final color = isPDF ? Colors.red : Colors.grey;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4), // ✅ FURTHER REDUCED GAP
        child: Card(
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: () => onFileTap(url, path),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // ✅ COMPACT
              child: Row(
                children: [
                  // File icon
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 8),
                  // File info - FIXED: Wrap in Expanded to prevent overflow
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ BOOK/FILE NAME - CLEAR AND VISIBLE
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        // File path (subtle) - shows folder hierarchy
                        Text(
                          _getShortPath(path),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // PDF indicator
                  if (isPDF)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  // Helper to shorten path for display
  String _getShortPath(String fullPath) {
    final parts = fullPath.split('/');
    if (parts.length <= 3) return fullPath;
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }
}