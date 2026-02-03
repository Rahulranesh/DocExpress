import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isGridView = true;
  bool _hasLoadedOnce = false;

  final List<String> _filterOptions = [
    'all',
    'images',
    'documents',
    'pdfs',
    'videos',
    'others',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load on next frame to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedOnce) {
        _loadFiles();
        _hasLoadedOnce = true;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    debugPrint('📂 FilesScreen: Loading files...');
    await ref.read(filesListProvider.notifier).loadFiles(refresh: true);
    debugPrint('📂 FilesScreen: Files load complete');
  }

  Future<void> _uploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            await ref.read(filesListProvider.notifier).uploadFile(file.path!);
          }
        }
        _showSnackBar('Files uploaded successfully!', isSuccess: true);
      }
    } catch (e) {
      _showSnackBar('Failed to upload files: $e', isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<FileModel> _filterFiles(List<FileModel> files) {
    var filtered = files;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((f) =>
              f.originalName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'images':
        filtered = filtered.where((f) => f.isImage).toList();
        break;
      case 'documents':
        filtered = filtered.where((f) => f.isDocument).toList();
        break;
      case 'pdfs':
        filtered = filtered.where((f) => f.isPdf).toList();
        break;
      case 'videos':
        filtered = filtered.where((f) => f.isVideo).toList();
        break;
      case 'others':
        filtered = filtered
            .where((f) => !f.isImage && !f.isDocument && !f.isPdf && !f.isVideo)
            .toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filesState = ref.watch(filesListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(theme, isDark),

            // Search and filter bar
            _buildSearchAndFilterBar(theme, isDark),

            // Tab bar
            _buildTabBar(theme, isDark),

            // File list/grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFiles,
                color: theme.colorScheme.primary,
                child: _buildFileContent(filesState, theme, isDark),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadFiles,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text('Upload'),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Files',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
              const SizedBox(height: 4),
              Consumer(
                builder: (context, ref, child) {
                  final filesState = ref.watch(filesListProvider);
                  final count = filesState.files.length;
                  return Text(
                    '$count files',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                icon: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                ),
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _showSortOptions(context);
                },
                icon: const Icon(Icons.sort_rounded),
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? filter : 'all';
                    });
                  },
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  backgroundColor:
                      isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isDark
                            ? AppTheme.darkDivider
                            : AppTheme.lightDivider,
                  ),
                )
                    .animate()
                    .fadeIn(delay: (100 + index * 50).ms, duration: 300.ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Recent'),
          Tab(text: 'Favorites'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildFileContent(
      FilesListState filesState, ThemeData theme, bool isDark) {
    if (filesState.isLoading && filesState.files.isEmpty) {
      return _buildLoadingState(isDark);
    }

    if (filesState.error != null && filesState.files.isEmpty) {
      return _buildErrorState(filesState.error!, theme);
    }

    final filteredFiles = _filterFiles(filesState.files);

    if (filteredFiles.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    return TabBarView(
      key: const PageStorageKey<String>('files_tab_view'),
      controller: _tabController,
      children: [
        _buildFileListOrGrid(filteredFiles, theme, isDark),
        _buildFileListOrGrid(
          filteredFiles..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          theme,
          isDark,
        ),
        _buildFileListOrGrid(
          filteredFiles.where((f) => f.isFavorite).toList(),
          theme,
          isDark,
        ),
      ],
    );
  }

  Widget _buildFileListOrGrid(
      List<FileModel> files, ThemeData theme, bool isDark) {
    if (files.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          return _FileGridItem(
            file: files[index],
            onTap: () => _openFileOptions(files[index]),
            onMoreTap: () => _showFileActions(files[index]),
          ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(
                begin: 0.1,
                duration: 300.ms,
              );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _FileListItem(
          file: files[index],
          onTap: () => _openFileOptions(files[index]),
          onMoreTap: () => _showFileActions(files[index]),
        ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideX(
              begin: 0.1,
              duration: 300.ms,
            );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _isGridView
          ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return ShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 16,
                );
              },
            )
          : ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return ShimmerBox(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                );
              },
            ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: _loadFiles,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'No files yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Upload your first file to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Upload Files',
              icon: Icons.cloud_upload_rounded,
              onPressed: _uploadFiles,
              isExpanded: false,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sort by',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Date (Newest first)'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sort logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Date (Oldest first)'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded),
                title: const Text('Name (A-Z)'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded),
                title: const Text('Name (Z-A)'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_usage_rounded),
                title: const Text('Size (Largest first)'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openFileOptions(FileModel file) {
    // Open file preview or actions
    _showFileActions(file);
  }

  void _showFileActions(FileModel file) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getFileTypeColor(file).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getFileTypeIcon(file),
                          color: _getFileTypeColor(file),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.originalName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatFileSize(file.size)} • ${DateFormat('MMM dd, yyyy').format(file.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: const Text('Open'),
                  onTap: () {
                    Navigator.pop(context);
                    _openFile(file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('Download'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadFile(file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareFile(file);
                  },
                ),
                ListTile(
                  leading: Icon(
                    file.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                  title: Text(file.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFavorite(file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(file);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_rounded,
                    color: AppTheme.errorColor,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(file);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFile(FileModel file) async {
    try {
      _showSnackBar('Downloading file...', isSuccess: true);
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${file.originalName}';

      final repository = ref.read(filesRepositoryProvider);
      await repository.downloadFile(file.id, savePath);

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        _showSnackBar('Could not open file: ${result.message}',
            isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Failed to open file: $e', isSuccess: false);
    }
  }

  Future<void> _downloadFile(FileModel file) async {
    try {
      _showSnackBar('Downloading...', isSuccess: true);

      // Get downloads directory - use app documents for reliability
      Directory dir;
      if (Platform.isAndroid) {
        // Use external storage directory on Android
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          // Create a Downloads folder in the app's external directory
          dir = Directory('${extDir.path}/Downloads');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        final downloadsDir = await getDownloadsDirectory();
        dir = downloadsDir ?? await getApplicationDocumentsDirectory();
      }

      final savePath = '${dir.path}/${file.originalName}';
      final repository = ref.read(filesRepositoryProvider);
      await repository.downloadFile(file.id, savePath);

      _showSnackBar('File saved to Downloads', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to download: $e', isSuccess: false);
    }
  }

  Future<void> _shareFile(FileModel file) async {
    try {
      _showSnackBar('Preparing file...', isSuccess: true);
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${file.originalName}';

      final repository = ref.read(filesRepositoryProvider);
      await repository.downloadFile(file.id, savePath);

      await Share.shareXFiles(
        [XFile(savePath)],
        text: 'Sharing ${file.originalName}',
      );
    } catch (e) {
      _showSnackBar('Failed to share: $e', isSuccess: false);
    }
  }

  Future<void> _toggleFavorite(FileModel file) async {
    final success =
        await ref.read(filesListProvider.notifier).toggleFavorite(file.id);
    if (success) {
      _showSnackBar(
        file.isFavorite ? 'Removed from favorites' : 'Added to favorites',
        isSuccess: true,
      );
    } else {
      _showSnackBar('Failed to update favorite', isSuccess: false);
    }
  }

  void _showRenameDialog(FileModel file) {
    final controller = TextEditingController(text: file.originalName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rename File'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter new name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  return;
                }
                Navigator.pop(context);
                final success = await ref
                    .read(filesListProvider.notifier)
                    .renameFile(file.id, newName);
                if (success) {
                  _showSnackBar('File renamed successfully', isSuccess: true);
                } else {
                  _showSnackBar('Failed to rename file', isSuccess: false);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(FileModel file) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete File'),
          content: Text(
            'Are you sure you want to delete "${file.originalName}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref
                    .read(filesListProvider.notifier)
                    .deleteFile(file.id);
                if (success) {
                  _showSnackBar('File deleted successfully', isSuccess: true);
                } else {
                  _showSnackBar('Failed to delete file', isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'images':
        return 'Images';
      case 'documents':
        return 'Documents';
      case 'pdfs':
        return 'PDFs';
      case 'videos':
        return 'Videos';
      case 'others':
        return 'Others';
      default:
        return filter;
    }
  }

  IconData _getFileTypeIcon(FileModel file) {
    if (file.isImage) return Icons.image_rounded;
    if (file.isPdf) return Icons.picture_as_pdf_rounded;
    if (file.isVideo) return Icons.videocam_rounded;
    if (file.isDocument) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileTypeColor(FileModel file) {
    if (file.isImage) return Colors.blue;
    if (file.isPdf) return Colors.red;
    if (file.isVideo) return Colors.purple;
    if (file.isDocument) return Colors.orange;
    return Colors.grey;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Grid item widget for files
class _FileGridItem extends StatelessWidget {
  final FileModel file;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _FileGridItem({
    required this.file,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getFileColor().withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getFileIcon(),
                        size: 48,
                        color: _getFileColor(),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onMoreTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (file.isFavorite)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // File info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.originalName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(file.size),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    if (file.isImage) return Icons.image_rounded;
    if (file.isPdf) return Icons.picture_as_pdf_rounded;
    if (file.isVideo) return Icons.videocam_rounded;
    if (file.isDocument) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor() {
    if (file.isImage) return Colors.blue;
    if (file.isPdf) return Colors.red;
    if (file.isVideo) return Colors.purple;
    if (file.isDocument) return Colors.orange;
    return Colors.grey;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// List item widget for files
class _FileListItem extends StatelessWidget {
  final FileModel file;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _FileListItem({
    required this.file,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // File icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getFileColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getFileIcon(),
                color: _getFileColor(),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.originalName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (file.isFavorite)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatFileSize(file.size)} • ${DateFormat('MMM dd, yyyy').format(file.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // More button
            IconButton(
              onPressed: onMoreTap,
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    if (file.isImage) return Icons.image_rounded;
    if (file.isPdf) return Icons.picture_as_pdf_rounded;
    if (file.isVideo) return Icons.videocam_rounded;
    if (file.isDocument) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor() {
    if (file.isImage) return Colors.blue;
    if (file.isPdf) return Colors.red;
    if (file.isVideo) return Colors.purple;
    if (file.isDocument) return Colors.orange;
    return Colors.grey;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
