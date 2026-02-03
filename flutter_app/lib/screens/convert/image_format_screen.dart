import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class ImageFormatScreen extends ConsumerStatefulWidget {
  const ImageFormatScreen({super.key});

  @override
  ConsumerState<ImageFormatScreen> createState() => _ImageFormatScreenState();
}

class _ImageFormatScreenState extends ConsumerState<ImageFormatScreen> {
  final List<String> _selectedFiles = [];
  String _targetFormat = 'png';
  int _quality = 85;
  bool _isConverting = false;
  double _progress = 0.0;

  final List<_FormatOption> _formatOptions = [
    _FormatOption('png', 'PNG', 'Lossless compression, supports transparency',
        Icons.image_rounded, Colors.blue),
    _FormatOption('jpg', 'JPG', 'Best for photos, smaller file size',
        Icons.photo_rounded, Colors.orange),
    _FormatOption('webp', 'WebP', 'Modern format, excellent compression',
        Icons.web_rounded, Colors.green),
    _FormatOption('gif', 'GIF', 'Supports animation, limited colors',
        Icons.gif_rounded, Colors.purple),
    _FormatOption('tiff', 'TIFF', 'High quality, professional use',
        Icons.high_quality_rounded, Colors.teal),
  ];

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(
            result.files
                .where((f) => f.path != null)
                .map((f) => f.path!)
                .toList(),
          );
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick files: $e', isError: true);
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
      _showSnackBar('Please select at least one image', isError: true);
      return;
    }

    setState(() {
      _isConverting = true;
      _progress = 0.0;
    });

    try {
      final filesRepo = ref.read(filesRepositoryProvider);
      final conversionRepo = ref.read(conversionRepositoryProvider);

      for (int i = 0; i < _selectedFiles.length; i++) {
        // Upload file first to get server file ID
        final file = File(_selectedFiles[i]);
        final uploadedFile = await filesRepo.uploadFile(file);

        // Call actual conversion API with server file ID
        await conversionRepo.convertImageFormat(
          fileId: uploadedFile.id,
          targetFormat: _targetFormat,
          quality: _quality,
        );

        setState(() {
          _progress = (i + 1) / _selectedFiles.length;
        });
      }

      _showSnackBar('Conversion completed successfully!', isError: false);

      // Navigate to jobs to see results
      if (mounted) {
        context.go('/jobs');
      }
    } catch (e) {
      _showSnackBar('Conversion failed: ${_getErrorMessage(e)}', isError: true);
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return error.toString();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
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
          'Convert Image Format',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _isConverting
          ? _buildConvertingView(theme, isDark)
          : _buildMainContent(theme, isDark),
      bottomNavigationBar:
          _isConverting ? null : _buildBottomBar(theme, isDark),
    );
  }

  Widget _buildConvertingView(ThemeData theme, bool isDark) {
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
                Icons.swap_horiz_rounded,
                size: 64,
                color: theme.colorScheme.primary,
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
          // File selection area
          _buildFileSelectionArea(theme, isDark),
          const SizedBox(height: 24),

          // Target format selection
          _buildFormatSelection(theme, isDark),
          const SizedBox(height: 24),

          // Quality slider (for lossy formats)
          if (_targetFormat == 'jpg' || _targetFormat == 'webp')
            _buildQualitySlider(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildFileSelectionArea(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Source Images',
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
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 12),

        // Drop zone or file list
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
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 48,
                color: theme.colorScheme.primary,
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
              'Supports PNG, JPG, WebP, GIF, BMP, TIFF',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
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
                final path = entry.value;
                final fileName = path.split('/').last;
                return Column(
                  children: [
                    ListTile(
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
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
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
                        color: isDark
                            ? AppTheme.darkDivider
                            : AppTheme.lightDivider,
                      ),
                  ],
                );
              }),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickFiles,
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

  Widget _buildFormatSelection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Format',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemCount: _formatOptions.length,
          itemBuilder: (context, index) {
            final option = _formatOptions[index];
            final isSelected = _targetFormat == option.format;
            return _FormatCard(
              option: option,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () {
                setState(() {
                  _targetFormat = option.format;
                });
              },
            ).animate().fadeIn(
                  delay: (250 + index * 50).ms,
                  duration: 300.ms,
                );
          },
        ),
      ],
    );
  }

  Widget _buildQualitySlider(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quality',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_quality%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _quality >= 80
              ? 'High quality, larger file size'
              : _quality >= 50
                  ? 'Balanced quality and size'
                  : 'Lower quality, smaller file size',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
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
            onChanged: (value) {
              setState(() {
                _quality = value.toInt();
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Smallest',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            Text(
              'Best Quality',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            if (_selectedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedFiles.length} image(s) will be converted to ${_targetFormat.toUpperCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            PrimaryButton(
              text: 'Convert Images',
              icon: Icons.swap_horiz_rounded,
              onPressed: _selectedFiles.isNotEmpty ? _startConversion : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption {
  final String format;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _FormatOption(
    this.format,
    this.label,
    this.description,
    this.icon,
    this.color,
  );
}

class _FormatCard extends StatelessWidget {
  final _FormatOption option;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FormatCard({
    required this.option,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option.icon,
                  color: option.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
