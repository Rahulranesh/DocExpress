import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class PdfCompressScreen extends ConsumerStatefulWidget {
  const PdfCompressScreen({super.key});

  @override
  ConsumerState<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends ConsumerState<PdfCompressScreen> {
  final List<_PdfFile> _selectedFiles = [];
  bool _isCompressing = false;
  double _progress = 0.0;
  String _compressionLevel = 'medium';
  bool _removeImages = false;
  bool _downsampleImages = true;
  int _imageQuality = 75;

  final List<_CompressionOption> _compressionOptions = [
    const _CompressionOption(
      id: 'low',
      title: 'Low',
      description: 'Best quality, larger size',
      reduction: '~20%',
      icon: Icons.high_quality_rounded,
      color: Colors.green,
    ),
    const _CompressionOption(
      id: 'medium',
      title: 'Medium',
      description: 'Balanced quality and size',
      reduction: '~50%',
      icon: Icons.tune_rounded,
      color: Colors.orange,
    ),
    const _CompressionOption(
      id: 'high',
      title: 'High',
      description: 'Smallest size, lower quality',
      reduction: '~80%',
      icon: Icons.compress_rounded,
      color: Colors.red,
    ),
  ];

  Future<void> _pickFiles() async {
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
              _selectedFiles.add(_PdfFile(
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

  Future<void> _startCompression() async {
    if (_selectedFiles.isEmpty) {
      _showSnackBar('Please select at least one PDF', isSuccess: false);
      return;
    }

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
    });

    try {
      final compressionRepo = ref.read(compressionRepositoryProvider);
      int successCount = 0;

      for (int i = 0; i < _selectedFiles.length; i++) {
        // Compress PDF locally using file path
        final result = await compressionRepo.compressPdf(
          filePath: _selectedFiles[i].path,
          quality: _getQualityValue(),
        );

        if (result.success) {
          successCount++;
        }

        if (mounted) {
          setState(() {
            _progress = (i + 1) / _selectedFiles.length;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isCompressing = false;
        });

        if (successCount > 0) {
          // Show success dialog
          final dialogResult = await ConversionSuccessDialog.show(
            context,
            title: 'Compression Complete!',
            message: '$successCount of ${_selectedFiles.length} PDFs compressed successfully.',
          );

          if (!mounted) return;

          switch (dialogResult) {
            case 'view_job':
            case 'history':
              context.go('/files');
              break;
            case 'stay':
              setState(() {
                _selectedFiles.clear();
              });
              break;
          }
        } else {
          _showSnackBar('Compression failed for all files', isSuccess: false);
        }
      }
    } on Exception catch (e) {
      _showSnackBar('Compression failed: ${_getErrorMessage(e)}',
          isSuccess: false);
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  int _getQualityValue() {
    switch (_compressionLevel) {
      case 'low':
        return 90;
      case 'high':
        return 50;
      case 'medium':
      default:
        return 75;
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int _getTotalSize() {
    return _selectedFiles.fold(0, (sum, file) => sum + file.size);
  }

  int _getEstimatedSize() {
    final total = _getTotalSize();
    switch (_compressionLevel) {
      case 'low':
        return (total * 0.8).toInt();
      case 'medium':
        return (total * 0.5).toInt();
      case 'high':
        return (total * 0.2).toInt();
      default:
        return total;
    }
  }

  void _showAdvancedOptions() {
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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkDivider
                                : AppTheme.lightDivider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Advanced Options',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Downsample images
                      SwitchListTile(
                        title: const Text('Downsample Images'),
                        subtitle: const Text(
                          'Reduce image resolution for smaller file size',
                        ),
                        value: _downsampleImages,
                        onChanged: (value) {
                          setSheetState(() {
                            _downsampleImages = value;
                          });
                          setState(() {});
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      const Divider(),

                      // Remove images
                      SwitchListTile(
                        title: const Text('Remove Images'),
                        subtitle: const Text(
                          'Remove all images from PDF (text only)',
                        ),
                        value: _removeImages,
                        onChanged: (value) {
                          setSheetState(() {
                            _removeImages = value;
                          });
                          setState(() {});
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      const Divider(),

                      // Image quality
                      if (_downsampleImages && !_removeImages) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Image Quality',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_imageQuality%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _imageQuality.toDouble(),
                          min: 10,
                          max: 100,
                          divisions: 18,
                          onChanged: (value) {
                            setSheetState(() {
                              _imageQuality = value.toInt();
                            });
                            setState(() {});
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Smaller',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            Text(
                              'Better Quality',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      PrimaryButton(
                        text: 'Apply',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compress PDF',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (_selectedFiles.isNotEmpty && !_isCompressing)
            IconButton(
              onPressed: _showAdvancedOptions,
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Advanced options',
            ),
        ],
      ),
      body: _isCompressing
          ? _buildCompressingView(theme, isDark)
          : _buildMainContent(theme, isDark),
      bottomNavigationBar:
          !_isCompressing ? _buildBottomBar(theme, isDark) : null,
    );
  }

  Widget _buildCompressingView(ThemeData theme, bool isDark) {
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
                Icons.compress_rounded,
                size: 64,
                color: Colors.red,
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 600.ms,
                ),
            const SizedBox(height: 32),
            Text(
              'Compressing...',
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
                color: Colors.red,
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

  Widget _buildMainContent(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          _buildInfoCard(theme, isDark),
          const SizedBox(height: 24),

          // File selection
          _buildFileSelection(theme, isDark),
          const SizedBox(height: 24),

          // Compression level
          if (_selectedFiles.isNotEmpty) ...[
            _buildCompressionOptions(theme, isDark),
            const SizedBox(height: 24),

            // Compression preview
            _buildCompressionPreview(theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    return Container(
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
              Icons.picture_as_pdf_rounded,
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
                  'PDF Compression',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reduce PDF file size while maintaining readability',
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

  Widget _buildFileSelection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PDF Files',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedFiles.isNotEmpty)
              TextButton.icon(
                onPressed: _clearAllFiles,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
              ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 12),
        if (_selectedFiles.isEmpty)
          _buildDropZone(theme, isDark)
        else
          _buildFileList(theme, isDark),
      ],
    );
  }

  Widget _buildDropZone(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select PDF files',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to choose files to compress',
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

  Widget _buildFileList(ThemeData theme, bool isDark) {
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
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red,
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
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                    if (index < _selectedFiles.length - 1)
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppTheme.darkDivider
                            : AppTheme.lightDivider,
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
          label: const Text('Add More PDFs'),
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

  Widget _buildCompressionOptions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compression Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
        const SizedBox(height: 12),
        Row(
          children: _compressionOptions.map((option) {
            final isSelected = _compressionLevel == option.id;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _compressionLevel = option.id;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: option.id != 'high' ? 12 : 0,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? option.color.withOpacity(0.1)
                        : isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? option.color
                          : isDark
                              ? AppTheme.darkDivider
                              : AppTheme.lightDivider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        option.icon,
                        color: isSelected
                            ? option.color
                            : isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? option.color : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.reduction,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? option.color
                              : isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildCompressionPreview(ThemeData theme, bool isDark) {
    final originalSize = _getTotalSize();
    final estimatedSize = _getEstimatedSize();
    final savings = originalSize - estimatedSize;
    final savingsPercent =
        originalSize > 0 ? ((savings / originalSize) * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
            'Estimated Results',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultItem(
                  label: 'Original',
                  value: _formatFileSize(originalSize),
                  icon: Icons.folder_open_rounded,
                  color: Colors.grey,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResultItem(
                  label: 'Estimated',
                  value: _formatFileSize(estimatedSize),
                  icon: Icons.folder_zip_rounded,
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.savings_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save ~${_formatFileSize(savings)} ($savingsPercent%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
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
          text: 'Compress PDFs',
          icon: Icons.compress_rounded,
          onPressed: _selectedFiles.isNotEmpty ? _startCompression : null,
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _PdfFile {
  final String path;
  final String name;
  final int size;

  const _PdfFile({
    required this.path,
    required this.name,
    required this.size,
  });
}

class _CompressionOption {
  final String id;
  final String title;
  final String description;
  final String reduction;
  final IconData icon;
  final Color color;

  const _CompressionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.reduction,
    required this.icon,
    required this.color,
  });
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _ResultItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
