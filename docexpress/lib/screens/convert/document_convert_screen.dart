import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class DocumentConvertScreen extends ConsumerStatefulWidget {
  final String conversionType;
  final String title;

  const DocumentConvertScreen({
    super.key,
    required this.conversionType,
    required this.title,
  });

  @override
  ConsumerState<DocumentConvertScreen> createState() =>
      _DocumentConvertScreenState();
}

class _DocumentConvertScreenState extends ConsumerState<DocumentConvertScreen> {
  final List<_SelectedFile> _selectedFiles = [];
  bool _isProcessing = false;
  double _progress = 0.0;

  // Get conversion info based on type
  _ConversionInfo get _conversionInfo {
    switch (widget.conversionType.toUpperCase()) {
      case 'DOCX_TO_PDF':
        return _ConversionInfo(
          sourceType: 'DOCX',
          targetType: 'PDF',
          sourceExtensions: ['docx', 'doc'],
          icon: Icons.description_rounded,
          color: Colors.blue,
          description: 'Convert Word documents to PDF format',
        );
      case 'PDF_TO_DOCX':
        return _ConversionInfo(
          sourceType: 'PDF',
          targetType: 'DOCX',
          sourceExtensions: ['pdf'],
          icon: Icons.picture_as_pdf_rounded,
          color: Colors.red,
          description: 'Convert PDF files to Word documents',
        );
      case 'PPTX_TO_PDF':
        return _ConversionInfo(
          sourceType: 'PPTX',
          targetType: 'PDF',
          sourceExtensions: ['pptx', 'ppt'],
          icon: Icons.slideshow_rounded,
          color: Colors.orange,
          description: 'Convert PowerPoint presentations to PDF',
        );
      case 'PDF_TO_PPTX':
        return _ConversionInfo(
          sourceType: 'PDF',
          targetType: 'PPTX',
          sourceExtensions: ['pdf'],
          icon: Icons.picture_as_pdf_rounded,
          color: Colors.red,
          description: 'Convert PDF files to PowerPoint presentations',
        );
      case 'IMAGE_TO_TXT':
      case 'OCR':
        return _ConversionInfo(
          sourceType: 'Image',
          targetType: 'Text',
          sourceExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'tiff', 'webp'],
          icon: Icons.text_fields_rounded,
          color: Colors.teal,
          description: 'Extract text from images using OCR',
        );
      case 'IMAGE_TO_PPTX':
        return _ConversionInfo(
          sourceType: 'Images',
          targetType: 'PPTX',
          sourceExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'webp'],
          icon: Icons.slideshow_rounded,
          color: Colors.deepOrange,
          description: 'Create a presentation from images',
        );
      case 'IMAGE_TO_DOCX':
        return _ConversionInfo(
          sourceType: 'Images',
          targetType: 'DOCX',
          sourceExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'webp'],
          icon: Icons.article_rounded,
          color: Colors.indigo,
          description: 'Create a Word document from images',
        );
      case 'IMAGE_MERGE':
        return _ConversionInfo(
          sourceType: 'Images',
          targetType: 'Image',
          sourceExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'webp'],
          icon: Icons.collections_rounded,
          color: Colors.purple,
          description: 'Merge multiple images into one',
        );
      case 'PDF_TO_TXT':
        return _ConversionInfo(
          sourceType: 'PDF',
          targetType: 'Text',
          sourceExtensions: ['pdf'],
          icon: Icons.text_snippet_rounded,
          color: Colors.teal,
          description: 'Extract text content from PDF files',
        );
      case 'PDF_EXTRACT_IMAGES':
        return _ConversionInfo(
          sourceType: 'PDF',
          targetType: 'Images',
          sourceExtensions: ['pdf'],
          icon: Icons.photo_library_rounded,
          color: Colors.blue,
          description: 'Extract all images from PDF files',
        );
      default:
        return _ConversionInfo(
          sourceType: 'File',
          targetType: 'File',
          sourceExtensions: ['*'],
          icon: Icons.swap_horiz_rounded,
          color: Colors.grey,
          description: 'Convert files',
        );
    }
  }

  Future<void> _pickFiles() async {
    try {
      final info = _conversionInfo;
      FileType fileType = FileType.custom;
      List<String>? allowedExtensions = info.sourceExtensions;

      // Handle image types
      if (info.sourceExtensions.contains('jpg') ||
          info.sourceExtensions.contains('png')) {
        fileType = FileType.image;
        allowedExtensions = null;
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _selectedFiles.add(_SelectedFile(
                path: file.path!,
                name: file.name,
                size: file.size,
              ));
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick files: $e', isSuccess: false);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  Future<void> _startConversion() async {
    if (_selectedFiles.isEmpty) {
      _showSnackBar('Please select at least one file', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      final paths = _selectedFiles.map((f) => f.path).toList();

      // Simulate progress
      for (int i = 0; i < _selectedFiles.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _progress = (i + 1) / _selectedFiles.length;
        });
      }

      // Call actual conversion
      await ref.read(conversionRepositoryProvider).convertDocument(
            fileIds: paths,
            conversionType: widget.conversionType,
          );

      _showSnackBar('Conversion completed successfully!', isSuccess: true);

      if (mounted) {
        context.go(AppRoutes.jobs);
      }
    } catch (e) {
      _showSnackBar('Conversion failed: $e', isSuccess: false);
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
    final info = _conversionInfo;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (_selectedFiles.isNotEmpty && !_isProcessing)
            TextButton.icon(
              onPressed: _clearAllFiles,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingView(theme, isDark, info)
          : _buildMainContent(theme, isDark, info),
      bottomNavigationBar: !_isProcessing ? _buildBottomBar(theme, isDark, info) : null,
    );
  }

  Widget _buildProcessingView(
      ThemeData theme, bool isDark, _ConversionInfo info) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                info.icon,
                size: 64,
                color: info.color,
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
            const SizedBox(height: 32),
            Text(
              'Converting...',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}% complete',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor:
                    isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                borderRadius: BorderRadius.circular(4),
                color: info.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_progress * _selectedFiles.length).ceil()} of ${_selectedFiles.length} files',
              style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildMainContent(
      ThemeData theme, bool isDark, _ConversionInfo info) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          _buildInfoCard(theme, isDark, info),
          const SizedBox(height: 24),

          // File selection area
          _buildFileSelectionArea(theme, isDark, info),
          const SizedBox(height: 24),

          // Conversion summary
          if (_selectedFiles.isNotEmpty)
            _buildConversionSummary(theme, isDark, info),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark, _ConversionInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            info.color.withOpacity(0.1),
            info.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: info.color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              info.icon,
              color: info.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        info.sourceType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: info.color,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: info.color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        info.targetType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: info.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  info.description,
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

  Widget _buildFileSelectionArea(
      ThemeData theme, bool isDark, _ConversionInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source Files',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 12),

        if (_selectedFiles.isEmpty)
          _buildDropZone(theme, isDark, info)
        else
          _buildFileList(theme, isDark, info),
      ],
    );
  }

  Widget _buildDropZone(ThemeData theme, bool isDark, _ConversionInfo info) {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: info.color.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 48,
                color: info.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to select ${info.sourceType} files',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported: ${info.sourceExtensions.join(", ").toUpperCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildFileList(ThemeData theme, bool isDark, _ConversionInfo info) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ),
          child: Column(
            children: [
              ..._selectedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: info.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          info.icon,
                          color: info.color,
                        ),
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _formatFileSize(file.size),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => _removeFile(index),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                    if (index < _selectedFiles.length - 1)
                      Divider(
                        height: 1,
                        color:
                            isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                      ),
                  ],
                );
              }),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add More Files'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionSummary(
      ThemeData theme, bool isDark, _ConversionInfo info) {
    final totalSize = _selectedFiles.fold<int>(0, (sum, f) => sum + f.size);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.file_copy_rounded,
                  label: 'Files',
                  value: '${_selectedFiles.length}',
                  color: info.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.storage_rounded,
                  label: 'Total Size',
                  value: _formatFileSize(totalSize),
                  color: info.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.output_rounded,
                  label: 'Output',
                  value: info.targetType,
                  color: info.color,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark, _ConversionInfo info) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          text: 'Start Conversion',
          icon: Icons.play_arrow_rounded,
          onPressed: _selectedFiles.isNotEmpty ? _startConversion : null,
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _ConversionInfo {
  final String sourceType;
  final String targetType;
  final List<String> sourceExtensions;
  final IconData icon;
  final Color color;
  final String description;

  const _ConversionInfo({
    required this.sourceType,
    required this.targetType,
    required this.sourceExtensions,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _SelectedFile {
  final String path;
  final String name;
  final int size;

  const _SelectedFile({
    required this.path,
    required this.name,
    required this.size,
  });
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
