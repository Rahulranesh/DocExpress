import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class ImageCompressScreen extends ConsumerStatefulWidget {
  const ImageCompressScreen({super.key});

  @override
  ConsumerState<ImageCompressScreen> createState() =>
      _ImageCompressScreenState();
}

class _ImageCompressScreenState extends ConsumerState<ImageCompressScreen> {
  final List<_ImageFile> _selectedImages = [];
  bool _isProcessing = false;
  double _progress = 0.0;

  // Compression options
  int _quality = 70;
  String _compressionLevel = 'medium'; // 'low', 'medium', 'high'
  bool _preserveMetadata = false;
  bool _resizeIfLarger = true;
  int _maxWidth = 1920;
  int _maxHeight = 1080;

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _selectedImages.add(_ImageFile(
                path: file.path!,
                name: file.name,
                size: file.size,
              ));
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick images: $e', isSuccess: false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  Future<void> _compressImages() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select at least one image', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      final compressionRepo = ref.read(compressionRepositoryProvider);
      final totalSteps = _selectedImages.length * 2; // Simulated steps for progress
      int currentStep = 0;
      String? lastJobId;

      // Compress each image locally
      for (final image in _selectedImages) {
        // Step 1: Compress the image directly using local processing
        final result = await compressionRepo.compressImage(
          filePath: image.path,
          quality: _quality,
          maxWidth: _resizeIfLarger ? _maxWidth : null,
          maxHeight: _resizeIfLarger ? _maxHeight : null,
        );
        currentStep += 2; // Count as 2 steps (upload+compress combined)
        lastJobId = result.outputPath; // Use output path as job reference

        if (mounted) {
          setState(() {
            _progress = currentStep / totalSteps;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show success dialog with options
        final result = await ConversionSuccessDialog.show(
          context,
          title: 'Compression Complete!',
          message: 'Your images have been compressed successfully.',
          jobId: lastJobId,
        );

        if (!mounted) return;

        switch (result) {
          case 'view_job':
            // For offline mode, open files screen instead
            context.go(AppRoutes.files);
            break;
          case 'history':
            context.go(AppRoutes.files);
            break;
          case 'stay':
            setState(() {
              _selectedImages.clear();
            });
            break;
        }
      }
    } on Exception catch (e) {
      _showSnackBar('Compression failed: ${_getErrorMessage(e)}',
          isSuccess: false);
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

  void _setCompressionLevel(String level) {
    setState(() {
      _compressionLevel = level;
      switch (level) {
        case 'low':
          _quality = 85;
          break;
        case 'medium':
          _quality = 70;
          break;
        case 'high':
          _quality = 50;
          break;
      }
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int _estimateCompressedSize() {
    final totalSize = _selectedImages.fold<int>(0, (sum, f) => sum + f.size);
    final ratio = _quality / 100;
    return (totalSize * ratio * 0.8).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compress Images',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (_selectedImages.isNotEmpty && !_isProcessing)
            TextButton.icon(
              onPressed: _clearAllImages,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingView(theme, isDark)
          : _buildMainContent(theme, isDark),
      bottomNavigationBar:
          !_isProcessing ? _buildBottomBar(theme, isDark) : null,
    );
  }

  Widget _buildProcessingView(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compress_rounded,
                size: 64,
                color: Colors.blue,
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(0.9, 0.9),
                  duration: 800.ms,
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
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_progress * _selectedImages.length).ceil()} of ${_selectedImages.length} images',
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

          // File selection area
          _buildFileSelectionArea(theme, isDark),
          const SizedBox(height: 24),

          // Compression options (only show if files selected)
          if (_selectedImages.isNotEmpty) ...[
            _buildCompressionLevelSelector(theme, isDark),
            const SizedBox(height: 24),
            _buildQualitySlider(theme, isDark),
            const SizedBox(height: 24),
            _buildAdvancedOptions(theme, isDark),
            const SizedBox(height: 24),
            _buildEstimation(theme, isDark),
          ],

          const SizedBox(height: 100),
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
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_size_select_small_rounded,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Compression',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reduce file size while maintaining visual quality',
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

  Widget _buildFileSelectionArea(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Text(
                '${_selectedImages.length} selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 12),
        if (_selectedImages.isEmpty)
          _buildDropZone(theme, isDark)
        else
          _buildImageList(theme, isDark),
      ],
    );
  }

  Widget _buildDropZone(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to select images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supports JPG, PNG, WebP, GIF',
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

  Widget _buildImageList(ThemeData theme, bool isDark) {
    final totalSize = _selectedImages.fold<int>(0, (sum, f) => sum + f.size);

    return Column(
      children: [
        // Total size info
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storage_rounded,
                size: 18,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Total size: ${_formatFileSize(totalSize)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Image list
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _selectedImages.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
            itemBuilder: (context, index) {
              final image = _selectedImages[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  image.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _formatFileSize(image.size),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () => _removeImage(index),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.errorColor,
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

        const SizedBox(height: 12),

        // Add more button
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add More Images'),
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

  Widget _buildCompressionLevelSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compression Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CompressionLevelOption(
                title: 'Low',
                description: 'Best quality',
                icon: Icons.high_quality_rounded,
                isSelected: _compressionLevel == 'low',
                onTap: () => _setCompressionLevel('low'),
                isDark: isDark,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompressionLevelOption(
                title: 'Medium',
                description: 'Balanced',
                icon: Icons.tune_rounded,
                isSelected: _compressionLevel == 'medium',
                onTap: () => _setCompressionLevel('medium'),
                isDark: isDark,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompressionLevelOption(
                title: 'High',
                description: 'Smallest size',
                icon: Icons.compress_rounded,
                isSelected: _compressionLevel == 'high',
                onTap: () => _setCompressionLevel('high'),
                isDark: isDark,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildQualitySlider(ThemeData theme, bool isDark) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quality',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_quality%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _quality.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _quality = value.toInt();
                  // Update compression level based on quality
                  if (_quality >= 80) {
                    _compressionLevel = 'low';
                  } else if (_quality >= 60) {
                    _compressionLevel = 'medium';
                  } else {
                    _compressionLevel = 'high';
                  }
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Smaller file',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Text(
                'Better quality',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }

  Widget _buildAdvancedOptions(ThemeData theme, bool isDark) {
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
            'Advanced Options',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Preserve metadata
          SwitchListTile(
            title: const Text('Preserve Metadata'),
            subtitle: const Text('Keep EXIF data, GPS info, etc.'),
            value: _preserveMetadata,
            onChanged: (value) {
              setState(() {
                _preserveMetadata = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),

          Divider(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),

          // Resize option
          SwitchListTile(
            title: const Text('Resize if Larger'),
            subtitle: Text('Max: ${_maxWidth}x$_maxHeight px'),
            value: _resizeIfLarger,
            onChanged: (value) {
              setState(() {
                _resizeIfLarger = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),

          if (_resizeIfLarger) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ResizePreset(
                    label: 'HD',
                    value: '1280×720',
                    isSelected: _maxWidth == 1280,
                    onTap: () => setState(() {
                      _maxWidth = 1280;
                      _maxHeight = 720;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResizePreset(
                    label: 'Full HD',
                    value: '1920×1080',
                    isSelected: _maxWidth == 1920,
                    onTap: () => setState(() {
                      _maxWidth = 1920;
                      _maxHeight = 1080;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResizePreset(
                    label: '4K',
                    value: '3840×2160',
                    isSelected: _maxWidth == 3840,
                    onTap: () => setState(() {
                      _maxWidth = 3840;
                      _maxHeight = 2160;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }

  Widget _buildEstimation(ThemeData theme, bool isDark) {
    final totalSize = _selectedImages.fold<int>(0, (sum, f) => sum + f.size);
    final estimatedSize = _estimateCompressedSize();
    final savings = totalSize - estimatedSize;
    final savingsPercent = totalSize > 0 ? (savings / totalSize * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated Results',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    Text(
                      _formatFileSize(totalSize),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.green,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Compressed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '~${_formatFileSize(estimatedSize)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.savings_rounded,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save ~${_formatFileSize(savings)} (${savingsPercent.toStringAsFixed(0)}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms, duration: 300.ms);
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
          text: 'Compress Images',
          icon: Icons.compress_rounded,
          onPressed: _selectedImages.isNotEmpty ? _compressImages : null,
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _ImageFile {
  final String path;
  final String name;
  final int size;

  const _ImageFile({
    required this.path,
    required this.name,
    required this.size,
  });
}

class _ResizePreset extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ResizePreset({
    required this.label,
    required this.value,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CompressionLevelOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? color;

  const _CompressionLevelOption({
    required this.title,
    required this.description,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.isDark = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (color ?? Colors.blue)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? (color ?? Colors.blue).withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
            ],
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
