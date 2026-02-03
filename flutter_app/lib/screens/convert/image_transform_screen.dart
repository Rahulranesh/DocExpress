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

class ImageTransformScreen extends ConsumerStatefulWidget {
  const ImageTransformScreen({super.key});

  @override
  ConsumerState<ImageTransformScreen> createState() =>
      _ImageTransformScreenState();
}

class _ImageTransformScreenState extends ConsumerState<ImageTransformScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isProcessing = false;

  // Transform options
  String _transformType = 'resize';
  int _resizeWidth = 800;
  int _resizeHeight = 600;
  bool _maintainAspectRatio = true;
  int _rotationAngle = 0;
  int _cropX = 0;
  int _cropY = 0;
  int _cropWidth = 100;
  int _cropHeight = 100;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.first.path;
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isSuccess: false);
    }
  }

  Future<void> _processImage() async {
    if (_selectedFilePath == null) {
      _showSnackBar('Please select an image first', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // For now, use a simple approach - create transform operations
      final operations = <TransformOperation>[];

      switch (_transformType) {
        case 'resize':
          operations.add(TransformOperation(
            type: 'resize',
            options: {
              'width': _resizeWidth,
              'height': _resizeHeight,
              'maintainAspectRatio': _maintainAspectRatio,
            },
          ));
          break;
        case 'rotate':
          operations.add(TransformOperation(
            type: 'rotate',
            options: {'angle': _rotationAngle},
          ));
          break;
        case 'crop':
          operations.add(TransformOperation(
            type: 'crop',
            options: {
              'x': _cropX,
              'y': _cropY,
              'width': _cropWidth,
              'height': _cropHeight,
            },
          ));
          break;
      }

      // Upload file first to get server file ID
      final filesRepo = ref.read(filesRepositoryProvider);
      final file = File(_selectedFilePath!);
      final uploadedFile = await filesRepo.uploadFile(file);

      await ref.read(conversionRepositoryProvider).transformImage(
            fileId: uploadedFile.id,
            operations: operations,
          );

      _showSnackBar('Image transformed successfully!', isSuccess: true);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showSnackBar('Failed to transform image: ${_getErrorMessage(e)}',
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
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return error.toString();
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
          'Transform Image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File selection
            _buildFileSelectionArea(theme, isDark),
            const SizedBox(height: 24),

            // Transform type selector
            _buildTransformTypeSelector(theme, isDark),
            const SizedBox(height: 24),

            // Options based on transform type
            _buildTransformOptions(theme, isDark),

            const SizedBox(height: 32),

            // Process button
            PrimaryButton(
              text: 'Transform Image',
              icon: Icons.transform_rounded,
              isLoading: _isProcessing,
              onPressed: _selectedFilePath != null ? _processImage : null,
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionArea(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedFilePath != null
                ? theme.colorScheme.primary
                : isDark
                    ? AppTheme.darkDivider
                    : AppTheme.lightDivider,
            width: _selectedFilePath != null ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            // Show actual image preview when selected
            if (_selectedFilePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: double.infinity,
                  ),
                  child: Image.file(
                    File(_selectedFilePath!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.withOpacity(0.2),
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
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
              _selectedFileName ?? 'Select an Image',
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
                  ? 'Tap to change image'
                  : 'Tap to select an image file',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildTransformTypeSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transform Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TransformTypeOption(
                title: 'Resize',
                icon: Icons.photo_size_select_large_rounded,
                isSelected: _transformType == 'resize',
                onTap: () => setState(() => _transformType = 'resize'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TransformTypeOption(
                title: 'Rotate',
                icon: Icons.rotate_right_rounded,
                isSelected: _transformType == 'rotate',
                onTap: () => setState(() => _transformType = 'rotate'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TransformTypeOption(
                title: 'Crop',
                icon: Icons.crop_rounded,
                isSelected: _transformType == 'crop',
                onTap: () => setState(() => _transformType = 'crop'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildTransformOptions(ThemeData theme, bool isDark) {
    switch (_transformType) {
      case 'resize':
        return _buildResizeOptions(theme, isDark);
      case 'rotate':
        return _buildRotateOptions(theme, isDark);
      case 'crop':
        return _buildCropOptions(theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildResizeOptions(ThemeData theme, bool isDark) {
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
            'Resize Options',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Width slider
          Text(
            'Width: $_resizeWidth px',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _resizeWidth.toDouble(),
            min: 100,
            max: 4000,
            divisions: 39,
            onChanged: (value) {
              setState(() {
                _resizeWidth = value.toInt();
                if (_maintainAspectRatio) {
                  _resizeHeight = (_resizeWidth * 0.75).toInt();
                }
              });
            },
          ),

          const SizedBox(height: 12),

          // Height slider
          Text(
            'Height: $_resizeHeight px',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _resizeHeight.toDouble(),
            min: 100,
            max: 4000,
            divisions: 39,
            onChanged: _maintainAspectRatio
                ? null
                : (value) {
                    setState(() {
                      _resizeHeight = value.toInt();
                    });
                  },
          ),

          const SizedBox(height: 12),

          // Maintain aspect ratio
          SwitchListTile(
            title: const Text('Maintain Aspect Ratio'),
            value: _maintainAspectRatio,
            onChanged: (value) {
              setState(() {
                _maintainAspectRatio = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),

          // Preset sizes
          Text(
            'Presets',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(
                label: '640×480',
                onTap: () => setState(() {
                  _resizeWidth = 640;
                  _resizeHeight = 480;
                }),
              ),
              _PresetChip(
                label: '1280×720',
                onTap: () => setState(() {
                  _resizeWidth = 1280;
                  _resizeHeight = 720;
                }),
              ),
              _PresetChip(
                label: '1920×1080',
                onTap: () => setState(() {
                  _resizeWidth = 1920;
                  _resizeHeight = 1080;
                }),
              ),
              _PresetChip(
                label: '2560×1440',
                onTap: () => setState(() {
                  _resizeWidth = 2560;
                  _resizeHeight = 1440;
                }),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildRotateOptions(ThemeData theme, bool isDark) {
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
            'Rotation Options',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Rotation angle display
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: _rotationAngle * 3.14159 / 180,
                child: Icon(
                  Icons.image_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Angle slider
          Text(
            'Angle: $_rotationAngle°',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _rotationAngle.toDouble(),
            min: 0,
            max: 360,
            divisions: 72,
            onChanged: (value) {
              setState(() {
                _rotationAngle = value.toInt();
              });
            },
          ),

          const SizedBox(height: 16),

          // Quick rotation buttons
          Text(
            'Quick Rotate',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RotateButton(
                angle: 90,
                icon: Icons.rotate_90_degrees_cw_rounded,
                onTap: () => setState(() => _rotationAngle = 90),
                isSelected: _rotationAngle == 90,
              ),
              _RotateButton(
                angle: 180,
                icon: Icons.rotate_right_rounded,
                onTap: () => setState(() => _rotationAngle = 180),
                isSelected: _rotationAngle == 180,
              ),
              _RotateButton(
                angle: 270,
                icon: Icons.rotate_90_degrees_ccw_rounded,
                onTap: () => setState(() => _rotationAngle = 270),
                isSelected: _rotationAngle == 270,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildCropOptions(ThemeData theme, bool isDark) {
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
            'Crop Options',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Position X
          Text(
            'Start X: $_cropX px',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _cropX.toDouble(),
            min: 0,
            max: 1000,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                _cropX = value.toInt();
              });
            },
          ),

          // Position Y
          Text(
            'Start Y: $_cropY px',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _cropY.toDouble(),
            min: 0,
            max: 1000,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                _cropY = value.toInt();
              });
            },
          ),

          // Crop Width
          Text(
            'Width: $_cropWidth px',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _cropWidth.toDouble(),
            min: 50,
            max: 2000,
            divisions: 39,
            onChanged: (value) {
              setState(() {
                _cropWidth = value.toInt();
              });
            },
          ),

          // Crop Height
          Text(
            'Height: $_cropHeight px',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _cropHeight.toDouble(),
            min: 50,
            max: 2000,
            divisions: 39,
            onChanged: (value) {
              setState(() {
                _cropHeight = value.toInt();
              });
            },
          ),

          const SizedBox(height: 16),

          // Aspect ratio presets
          Text(
            'Aspect Ratio Presets',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(
                label: '1:1',
                onTap: () => setState(() {
                  _cropWidth = 500;
                  _cropHeight = 500;
                }),
              ),
              _PresetChip(
                label: '4:3',
                onTap: () => setState(() {
                  _cropWidth = 800;
                  _cropHeight = 600;
                }),
              ),
              _PresetChip(
                label: '16:9',
                onTap: () => setState(() {
                  _cropWidth = 1600;
                  _cropHeight = 900;
                }),
              ),
              _PresetChip(
                label: '3:2',
                onTap: () => setState(() {
                  _cropWidth = 900;
                  _cropHeight = 600;
                }),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }
}

class _TransformTypeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TransformTypeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _RotateButton extends StatelessWidget {
  final int angle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _RotateButton({
    required this.angle,
    required this.icon,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              '$angle°',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
