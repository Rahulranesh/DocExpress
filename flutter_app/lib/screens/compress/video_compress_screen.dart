import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class VideoCompressScreen extends ConsumerStatefulWidget {
  const VideoCompressScreen({super.key});

  @override
  ConsumerState<VideoCompressScreen> createState() =>
      _VideoCompressScreenState();
}

class _VideoCompressScreenState extends ConsumerState<VideoCompressScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  int _selectedFileSize = 0;
  bool _isProcessing = false;
  double _progress = 0.0;

  // Compression settings
  String _quality = 'medium';
  String _resolution = 'original';
  int _bitrate = 2000; // kbps
  bool _removeAudio = false;

  final Map<String, _QualityPreset> _qualityPresets = {
    'high': _QualityPreset(
      label: 'High',
      description: 'Best quality, larger file',
      icon: Icons.high_quality_rounded,
      color: Colors.green,
      compressionRatio: 0.8,
    ),
    'medium': _QualityPreset(
      label: 'Medium',
      description: 'Balanced quality and size',
      icon: Icons.hd_rounded,
      color: Colors.blue,
      compressionRatio: 0.5,
    ),
    'low': _QualityPreset(
      label: 'Low',
      description: 'Smallest file, lower quality',
      icon: Icons.sd_rounded,
      color: Colors.orange,
      compressionRatio: 0.3,
    ),
  };

  final List<String> _resolutionOptions = [
    'original',
    '1080p',
    '720p',
    '480p',
    '360p',
  ];

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.first.path;
          _selectedFileName = result.files.first.name;
          _selectedFileSize = result.files.first.size;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick video: $e', isSuccess: false);
    }
  }

  Future<void> _compressVideo() async {
    if (_selectedFilePath == null) {
      _showSnackBar('Please select a video first', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      // Simulate compression progress
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _progress = i / 100;
          });
        }
      }

      // Call actual compression API
      await ref.read(compressionRepositoryProvider).compressVideo(
        filePath: _selectedFilePath!,
        options: {
          'quality': _quality,
          'resolution': _resolution,
          'bitrate': _bitrate,
          'removeAudio': _removeAudio,
        },
      );

      _showSnackBar('Video compressed successfully!', isSuccess: true);

      if (mounted) {
        context.go(AppRoutes.jobs);
      }
    } catch (e) {
      _showSnackBar('Compression failed: $e', isSuccess: false);
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

  int _estimateCompressedSize() {
    if (_selectedFileSize == 0) return 0;
    final preset = _qualityPresets[_quality]!;
    return (_selectedFileSize * preset.compressionRatio).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compress Video',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _isProcessing
          ? _buildProcessingView(theme, isDark)
          : _buildMainContent(theme, isDark),
      bottomNavigationBar: !_isProcessing ? _buildBottomBar(theme, isDark) : null,
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
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_settings_rounded,
                size: 64,
                color: Colors.purple,
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
            const SizedBox(height: 32),
            Text(
              'Compressing Video...',
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
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedFileName != null)
              Text(
                _selectedFileName!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

          // Quality presets
          if (_selectedFilePath != null) ...[
            _buildQualityPresets(theme, isDark),
            const SizedBox(height: 24),

            // Advanced settings
            _buildAdvancedSettings(theme, isDark),
            const SizedBox(height: 24),

            // Estimated result
            _buildEstimatedResult(theme, isDark),
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
              Icons.video_settings_rounded,
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
                  'Video Compression',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reduce video file size while maintaining quality',
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
    return GestureDetector(
      onTap: _pickVideo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedFilePath != null
                ? Colors.purple
                : isDark
                    ? AppTheme.darkDivider
                    : AppTheme.lightDivider,
            width: _selectedFilePath != null ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedFilePath != null
                    ? Icons.videocam_rounded
                    : Icons.video_call_rounded,
                size: 48,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFileName ?? 'Select a Video',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilePath != null
                  ? '${_formatFileSize(_selectedFileSize)} • Tap to change'
                  : 'Tap to select a video file',
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

  Widget _buildQualityPresets(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality Preset',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _qualityPresets.entries.map((entry) {
            final isSelected = _quality == entry.key;
            final preset = entry.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _quality = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: entry.key != 'low' ? 8 : 0,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? preset.color.withOpacity(0.1)
                        : isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? preset.color
                          : isDark
                              ? AppTheme.darkDivider
                              : AppTheme.lightDivider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        preset.icon,
                        color: isSelected
                            ? preset.color
                            : isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preset.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? preset.color
                              : isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildAdvancedSettings(ThemeData theme, bool isDark) {
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
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Advanced Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Resolution
          Text(
            'Resolution',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _resolutionOptions.map((res) {
              final isSelected = _resolution == res;
              return ChoiceChip(
                label: Text(res == 'original' ? 'Original' : res),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _resolution = res);
                },
                selectedColor: Colors.purple.withOpacity(0.2),
                checkmarkColor: Colors.purple,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Bitrate slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bitrate',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_bitrate kbps',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _bitrate.toDouble(),
            min: 500,
            max: 8000,
            divisions: 15,
            activeColor: Colors.purple,
            onChanged: (value) {
              setState(() {
                _bitrate = value.toInt();
              });
            },
          ),
          const SizedBox(height: 8),

          // Remove audio toggle
          SwitchListTile(
            title: const Text('Remove Audio'),
            subtitle: const Text('Strip audio track from video'),
            value: _removeAudio,
            onChanged: (value) {
              setState(() {
                _removeAudio = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.purple,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildEstimatedResult(ThemeData theme, bool isDark) {
    final estimatedSize = _estimateCompressedSize();
    final savings = _selectedFileSize - estimatedSize;
    final savingsPercent = _selectedFileSize > 0
        ? ((savings / _selectedFileSize) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated Result',
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
                child: _ResultItem(
                  label: 'Original',
                  value: _formatFileSize(_selectedFileSize),
                  icon: Icons.videocam_rounded,
                  color: Colors.grey,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResultItem(
                  label: 'Compressed',
                  value: _formatFileSize(estimatedSize),
                  icon: Icons.video_settings_rounded,
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.savings_rounded,
                  color: Colors.green,
                  size: 18,
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
        child: PrimaryButton(
          text: 'Compress Video',
          icon: Icons.compress_rounded,
          onPressed: _selectedFilePath != null ? _compressVideo : null,
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _QualityPreset {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final double compressionRatio;

  const _QualityPreset({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.compressionRatio,
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

    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}
