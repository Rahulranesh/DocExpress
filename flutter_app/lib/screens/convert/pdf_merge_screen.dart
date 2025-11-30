import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class PdfMergeScreen extends ConsumerStatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  ConsumerState<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends ConsumerState<PdfMergeScreen> {
  final List<_PdfFile> _selectedPdfs = [];
  bool _isProcessing = false;
  String _outputName = 'merged';

  Future<void> _pickPdfs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _selectedPdfs.add(_PdfFile(
                path: file.path!,
                name: file.name,
                size: file.size,
              ));
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick PDFs: $e', isSuccess: false);
    }
  }

  void _removePdf(int index) {
    setState(() {
      _selectedPdfs.removeAt(index);
    });
  }

  void _reorderPdfs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedPdfs.removeAt(oldIndex);
      _selectedPdfs.insert(newIndex, item);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedPdfs.clear();
    });
  }

  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) {
      _showSnackBar('Please select at least 2 PDFs to merge', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final paths = _selectedPdfs.map((f) => f.path).toList();

      await ref.read(conversionRepositoryProvider).mergePdfs(
        fileIds: paths,
      );

      _showSnackBar('PDFs merged successfully!', isSuccess: true);

      if (mounted) {
        context.go(AppRoutes.jobs);
      }
    } catch (e) {
      _showSnackBar('Failed to merge PDFs: $e', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showOutputNameDialog() {
    final controller = TextEditingController(text: _outputName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Output File Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter file name',
              suffixText: '.pdf',
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
              onPressed: () {
                setState(() {
                  _outputName = controller.text.isEmpty ? 'merged' : controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Merge PDFs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (_selectedPdfs.isNotEmpty)
            IconButton(
              onPressed: _showOutputNameDialog,
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Output name',
            ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          _buildInfoBanner(theme, isDark),

          // Selected PDFs count and clear button
          if (_selectedPdfs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedPdfs.length} PDF${_selectedPdfs.length > 1 ? 's' : ''} selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear all'),
                  ),
                ],
              ),
            ),

          // PDF list or empty state
          Expanded(
            child: _selectedPdfs.isEmpty
                ? _buildEmptyState(theme, isDark)
                : _buildPdfList(theme, isDark),
          ),

          // Bottom action bar
          _buildBottomBar(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.merge_rounded,
              color: Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merge PDF Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag to reorder • Files merge in order shown',
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 64,
                color: Colors.red,
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'No PDFs selected',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Select at least 2 PDF files to merge them\ninto a single document',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Select PDFs',
              icon: Icons.add_rounded,
              onPressed: _pickPdfs,
              isExpanded: false,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfList(ThemeData theme, bool isDark) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedPdfs.length,
      onReorder: _reorderPdfs,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final pdf = _selectedPdfs[index];
        return _PdfListItem(
          key: ValueKey(pdf.path),
          pdf: pdf,
          index: index,
          isDark: isDark,
          onRemove: () => _removePdf(index),
        ).animate().fadeIn(delay: (index * 50).ms, duration: 200.ms);
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
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
            // Output name display
            if (_selectedPdfs.length >= 2)
              GestureDetector(
                onTap: _showOutputNameDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.output_rounded,
                        size: 16,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Output: $_outputName.pdf',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                // Add more button
                Expanded(
                  child: SecondaryButton(
                    text: 'Add PDFs',
                    icon: Icons.add_rounded,
                    onPressed: _pickPdfs,
                  ),
                ),
                const SizedBox(width: 12),
                // Merge button
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Merge PDFs',
                    icon: Icons.merge_rounded,
                    onPressed: _selectedPdfs.length >= 2 ? _mergePdfs : null,
                    isLoading: _isProcessing,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _PdfFile {
  final String path;
  final String name;
  final int size;

  _PdfFile({
    required this.path,
    required this.name,
    required this.size,
  });
}

class _PdfListItem extends StatelessWidget {
  final _PdfFile pdf;
  final int index;
  final bool isDark;
  final VoidCallback onRemove;

  const _PdfListItem({
    super.key,
    required this.pdf,
    required this.index,
    required this.isDark,
    required this.onRemove,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
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

          // Page number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // PDF icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.red,
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
                  pdf.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(pdf.size),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              color: AppTheme.errorColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.errorColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
