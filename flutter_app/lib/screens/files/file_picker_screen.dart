import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class FilePickerScreen extends ConsumerStatefulWidget {
  final List<String>? allowedTypes;
  final bool allowMultiple;

  const FilePickerScreen({
    super.key,
    this.allowedTypes,
    this.allowMultiple = false,
  });

  @override
  ConsumerState<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends ConsumerState<FilePickerScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedFileIds = {};
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadFiles();
    // Set initial filter based on allowed types
    if (widget.allowedTypes != null && widget.allowedTypes!.length == 1) {
      _selectedFilter = widget.allowedTypes!.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    ref.read(filesListProvider.notifier).loadFiles(refresh: true);
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

    // Apply allowed types filter
    if (widget.allowedTypes != null && widget.allowedTypes!.isNotEmpty) {
      filtered = filtered.where((f) {
        for (final type in widget.allowedTypes!) {
          if (_matchesType(f, type)) return true;
        }
        return false;
      }).toList();
    }

    // Apply category filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((f) => _matchesType(f, _selectedFilter)).toList();
    }

    return filtered;
  }

  bool _matchesType(FileModel file, String type) {
    switch (type.toLowerCase()) {
      case 'images':
      case 'image':
        return file.isImage;
      case 'documents':
      case 'document':
        return file.isDocument;
      case 'pdfs':
      case 'pdf':
        return file.isPdf;
      case 'videos':
      case 'video':
        return file.isVideo;
      default:
        return true;
    }
  }

  void _toggleSelection(FileModel file) {
    setState(() {
      if (_selectedFileIds.contains(file.id)) {
        _selectedFileIds.remove(file.id);
      } else {
        if (!widget.allowMultiple) {
          _selectedFileIds.clear();
        }
        _selectedFileIds.add(file.id);
      }
    });
  }

  void _confirmSelection() {
    final filesState = ref.read(filesListProvider);
    final selectedFiles = filesState.files
        .where((f) => _selectedFileIds.contains(f.id))
        .toList();
    context.pop(selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filesState = ref.watch(filesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.allowMultiple ? 'Select Files' : 'Select a File',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          if (_selectedFileIds.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                widget.allowMultiple
                    ? 'Select (${_selectedFileIds.length})'
                    : 'Select',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Filter chips
          if (widget.allowedTypes == null || widget.allowedTypes!.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('all', 'All', theme, isDark),
                    const SizedBox(width: 8),
                    if (_shouldShowFilter('images'))
                      _buildFilterChip('images', 'Images', theme, isDark),
                    if (_shouldShowFilter('pdfs'))
                      _buildFilterChip('pdfs', 'PDFs', theme, isDark),
                    if (_shouldShowFilter('documents'))
                      _buildFilterChip('documents', 'Documents', theme, isDark),
                    if (_shouldShowFilter('videos'))
                      _buildFilterChip('videos', 'Videos', theme, isDark),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // File list
          Expanded(
            child: _buildFileContent(filesState, theme, isDark),
          ),
        ],
      ),
      bottomNavigationBar: _selectedFileIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: PrimaryButton(
                  text: widget.allowMultiple
                      ? 'Confirm Selection (${_selectedFileIds.length})'
                      : 'Confirm Selection',
                  onPressed: _confirmSelection,
                  icon: Icons.check_rounded,
                ),
              ),
            ).animate().slideY(begin: 1, duration: 300.ms)
          : null,
    );
  }

  bool _shouldShowFilter(String type) {
    if (widget.allowedTypes == null) return true;
    return widget.allowedTypes!
        .any((t) => t.toLowerCase().contains(type.toLowerCase()));
  }

  Widget _buildFilterChip(
      String value, String label, ThemeData theme, bool isDark) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
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
      ),
    );
  }

  Widget _buildFileContent(
      FilesListState filesState, ThemeData theme, bool isDark) {
    if (filesState.isLoading && filesState.files.isEmpty) {
      return _buildLoadingState();
    }

    if (filesState.error != null && filesState.files.isEmpty) {
      return _buildErrorState(filesState.error!, theme);
    }

    final filteredFiles = _filterFiles(filesState.files);

    if (filteredFiles.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredFiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final file = filteredFiles[index];
          final isSelected = _selectedFileIds.contains(file.id);
          return _FilePickerItem(
            file: file,
            isSelected: isSelected,
            onTap: () => _toggleSelection(file),
          ).animate().fadeIn(delay: (index * 30).ms, duration: 200.ms);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return const ShimmerBox(
          width: double.infinity,
          height: 72,
          borderRadius: 12,
        );
      },
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load files',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            SecondaryButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: _loadFiles,
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
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No files found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload some files first to select them here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePickerItem extends StatelessWidget {
  final FileModel file;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilePickerItem({
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : isDark
                  ? AppTheme.darkSurface
                  : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isDark
                    ? AppTheme.darkDivider
                    : AppTheme.lightDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : isDark
                          ? AppTheme.darkDivider
                          : AppTheme.lightDivider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // File icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getFileColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFileIcon(),
                color: _getFileColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // File info
            Expanded(
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
                  const SizedBox(height: 2),
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
