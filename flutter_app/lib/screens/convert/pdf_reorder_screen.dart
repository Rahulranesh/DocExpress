import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class PdfReorderScreen extends ConsumerStatefulWidget {
  const PdfReorderScreen({super.key});

  @override
  ConsumerState<PdfReorderScreen> createState() => _PdfReorderScreenState();
}

class _PdfReorderScreenState extends ConsumerState<PdfReorderScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isLoading = false;
  bool _isProcessing = false;
  List<_PdfPage> _pages = [];

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.first.path;
          _selectedFileName = result.files.first.name;
          _isLoading = true;
        });

        // Simulate loading PDF pages - in production, use a PDF library
        await _loadPdfPages();
      }
    } catch (e) {
      _showSnackBar('Failed to pick PDF: $e', isSuccess: false);
    }
  }

  Future<void> _loadPdfPages() async {
    // Simulate loading PDF pages - in production, use pdf_render or similar
    await Future.delayed(const Duration(seconds: 1));

    // Generate mock pages (in production, get actual page count from PDF)
    final pageCount = 8; // Mock page count
    setState(() {
      _pages = List.generate(
        pageCount,
        (index) => _PdfPage(
          originalIndex: index,
          currentIndex: index,
          pageNumber: index + 1,
        ),
      );
      _isLoading = false;
    });
  }

  void _reorderPages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);

      // Update current indices
      for (int i = 0; i < _pages.length; i++) {
        _pages[i] = _pages[i].copyWith(currentIndex: i);
      }
    });
  }

  void _resetOrder() {
    setState(() {
      _pages.sort((a, b) => a.originalIndex.compareTo(b.originalIndex));
      for (int i = 0; i < _pages.length; i++) {
        _pages[i] = _pages[i].copyWith(currentIndex: i);
      }
    });
  }

  void _reverseOrder() {
    setState(() {
      _pages = _pages.reversed.toList();
      for (int i = 0; i < _pages.length; i++) {
        _pages[i] = _pages[i].copyWith(currentIndex: i);
      }
    });
  }

  Future<void> _savePdf() async {
    if (_selectedFilePath == null || _pages.isEmpty) {
      _showSnackBar('Please select a PDF first', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final filesRepo = ref.read(filesRepositoryProvider);
      final conversionRepo = ref.read(conversionRepositoryProvider);

      // Step 1: Upload the file
      final file = File(_selectedFilePath!);
      final uploadedFile = await filesRepo.uploadFile(file);

      // Step 2: Reorder using server file ID
      // Backend expects 1-indexed page numbers, so add 1 to each index
      final pageOrder = _pages.map((p) => p.originalIndex + 1).toList();
      await conversionRepo.reorderPdfPages(
        fileId: uploadedFile.id,
        pageOrder: pageOrder,
      );

      _showSnackBar('PDF pages reordering started!', isSuccess: true);

      if (mounted) {
        context.go('/jobs');
      }
    } on Exception catch (e) {
      _showSnackBar('Failed to reorder PDF: ${_getErrorMessage(e)}',
          isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('No internet')) {
      return 'No internet connection. Please check your network.';
    }
    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (error.toString().contains('401')) {
      return 'Session expired. Please login again.';
    }
    return error
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('ApiException: ', '');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reorder PDF Pages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (_pages.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'reset':
                    _resetOrder();
                    break;
                  case 'reverse':
                    _reverseOrder();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.restore_rounded),
                      SizedBox(width: 12),
                      Text('Reset Order'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reverse',
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert_rounded),
                      SizedBox(width: 12),
                      Text('Reverse Order'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          _buildInfoCard(theme, isDark),

          // Content
          Expanded(
            child: _buildContent(theme, isDark),
          ),
        ],
      ),
      bottomNavigationBar:
          _pages.isNotEmpty ? _buildBottomBar(theme, isDark) : null,
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.reorder_rounded,
              color: Colors.purple,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reorder PDF Pages',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag and drop pages to rearrange them',
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
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (_selectedFilePath == null) {
      return _buildEmptyState(theme, isDark);
    }

    if (_isLoading) {
      return _buildLoadingState(theme, isDark);
    }

    return _buildPagesList(theme, isDark);
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
                Icons.picture_as_pdf_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'Select a PDF',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Choose a PDF file to reorder its pages',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Select PDF',
              icon: Icons.folder_open_rounded,
              onPressed: _pickPdf,
              isExpanded: false,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading PDF pages...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagesList(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedFileName ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _pickPdf,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Page count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_pages.length} pages • Drag to reorder',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pages grid
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pages.length,
            onReorder: _reorderPages,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final double elevation =
                      Tween<double>(begin: 0, end: 8).evaluate(animation);
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Container(
                key: ValueKey('page_$index\_${page.originalIndex}'),
                child: _PageItem(
                  page: page,
                  index: index,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    // Check if order has changed
    bool hasChanges = false;
    for (int i = 0; i < _pages.length; i++) {
      if (_pages[i].originalIndex != i) {
        hasChanges = true;
        break;
      }
    }

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasChanges)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Page order has been modified',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            PrimaryButton(
              text: 'Save Reordered PDF',
              icon: Icons.save_rounded,
              isLoading: _isProcessing,
              onPressed: hasChanges ? _savePdf : null,
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _PdfPage {
  final int originalIndex;
  final int currentIndex;
  final int pageNumber;

  const _PdfPage({
    required this.originalIndex,
    required this.currentIndex,
    required this.pageNumber,
  });

  _PdfPage copyWith({
    int? originalIndex,
    int? currentIndex,
    int? pageNumber,
  }) {
    return _PdfPage(
      originalIndex: originalIndex ?? this.originalIndex,
      currentIndex: currentIndex ?? this.currentIndex,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }
}

class _PageItem extends StatelessWidget {
  final _PdfPage page;
  final int index;
  final bool isDark;

  const _PageItem({
    super.key,
    required this.page,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChanged = page.originalIndex != index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasChanged
              ? theme.colorScheme.primary.withOpacity(0.5)
              : isDark
                  ? AppTheme.darkDivider
                  : AppTheme.lightDivider,
          width: hasChanged ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_handle_rounded,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(width: 12),

          // Page thumbnail placeholder
          Container(
            width: 50,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.article_rounded,
                  color: Colors.red.withOpacity(0.5),
                  size: 24,
                ),
                Positioned(
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${page.pageNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Page info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${page.pageNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasChanged)
                  Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Moved from position ${page.originalIndex + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Original position',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Position indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: hasChanged
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: hasChanged
                      ? theme.colorScheme.primary
                      : isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
