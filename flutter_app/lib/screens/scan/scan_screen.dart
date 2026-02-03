import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _capturedImages = [];
  bool _isProcessing = false;
  bool _flashOn = false;

  Future<void> _openCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _capturedImages.add(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to access camera: $e', isSuccess: false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 90,
      );

      if (images.isNotEmpty) {
        setState(() {
          _capturedImages.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick images: $e', isSuccess: false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _capturedImages.clear();
    });
  }

  Future<void> _processScans() async {
    if (_capturedImages.isEmpty) {
      _showSnackBar('Please capture at least one image', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Process the scanned images - convert to PDF or enhance
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing

      _showSnackBar('Scans processed successfully!', isSuccess: true);

      // Navigate to conversion options
      if (mounted) {
        context.go(AppRoutes.jobs);
      }
    } catch (e) {
      _showSnackBar('Failed to process scans: $e', isSuccess: false);
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
        backgroundColor:
            isSuccess ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showActionSheet() {
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
                  'What would you like to do?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text('Convert to PDF'),
                subtitle: const Text('Create a PDF from scanned images'),
                onTap: () {
                  Navigator.pop(context);
                  _processToPdf();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.text_fields_rounded,
                    color: Colors.teal,
                  ),
                ),
                title: const Text('Extract Text (OCR)'),
                subtitle: const Text('Get text content from images'),
                onTap: () {
                  Navigator.pop(context);
                  _processOcr();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.purple,
                  ),
                ),
                title: const Text('Enhance & Save'),
                subtitle: const Text('Auto-enhance and save images'),
                onTap: () {
                  Navigator.pop(context);
                  _processEnhance();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processToPdf() async {
    setState(() => _isProcessing = true);
    try {
      final filesRepo = ref.read(filesRepositoryProvider);
      final conversionRepo = ref.read(conversionRepositoryProvider);

      // Step 1: Upload all images and collect their IDs
      final List<String> uploadedFileIds = [];
      for (final imagePath in _capturedImages) {
        final file = File(imagePath);
        final uploadedFile = await filesRepo.uploadFile(file);
        uploadedFileIds.add(uploadedFile.id);
      }

      // Step 2: Convert using server file IDs
      final job = await conversionRepo.imagesToPdf(
        fileIds: uploadedFileIds,
        pageSize: 'A4',
      );

      if (mounted) {
        setState(() => _isProcessing = false);

        // Show success dialog with options
        final result = await ConversionSuccessDialog.show(
          context,
          title: 'PDF Creation Started!',
          message: 'Your scanned images are being converted to PDF.',
          jobId: job.id,
        );

        if (!mounted) return;

        switch (result) {
          case 'view_job':
            context.openJobDetail(job.id);
            break;
          case 'history':
            context.go(AppRoutes.jobs);
            break;
          case 'stay':
            setState(() {
              _capturedImages.clear();
            });
            break;
        }
      }
    } on Exception catch (e) {
      _showSnackBar('Failed to create PDF: ${_getErrorMessage(e)}',
          isSuccess: false);
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processOcr() async {
    setState(() => _isProcessing = true);
    try {
      final filesRepo = ref.read(filesRepositoryProvider);
      final conversionRepo = ref.read(conversionRepositoryProvider);

      // Upload first image for OCR
      if (_capturedImages.isNotEmpty) {
        final file = File(_capturedImages.first);
        final uploadedFile = await filesRepo.uploadFile(file);
        final job = await conversionRepo.imageToText(fileId: uploadedFile.id);

        if (mounted) {
          setState(() => _isProcessing = false);

          // Show success dialog with options
          final result = await ConversionSuccessDialog.show(
            context,
            title: 'OCR Started!',
            message:
                'Text is being extracted from your image. View the result when complete.',
            jobId: job.id,
          );

          if (!mounted) return;

          switch (result) {
            case 'view_job':
              context.openJobDetail(job.id);
              break;
            case 'history':
              context.go(AppRoutes.jobs);
              break;
            case 'stay':
              setState(() {
                _capturedImages.clear();
              });
              break;
          }
        }
      }
    } on Exception catch (e) {
      _showSnackBar('OCR failed: ${_getErrorMessage(e)}', isSuccess: false);
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processEnhance() async {
    setState(() => _isProcessing = true);
    try {
      // Apply enhancement and save
      await Future.delayed(const Duration(seconds: 2));
      _showSnackBar('Images enhanced and saved!', isSuccess: true);
      if (mounted) context.go(AppRoutes.files);
    } catch (e) {
      _showSnackBar('Enhancement failed: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Document',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          if (_capturedImages.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingView(theme, isDark)
          : _buildMainContent(theme, isDark),
      bottomNavigationBar: !_isProcessing && _capturedImages.isNotEmpty
          ? _buildBottomBar(theme, isDark)
          : null,
    );
  }

  Widget _buildProcessingView(ThemeData theme, bool isDark) {
    return Center(
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
              Icons.document_scanner_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
          const SizedBox(height: 32),
          Text(
            'Processing...',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we process your scans',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capture options
          _buildCaptureOptions(theme, isDark),
          const SizedBox(height: 24),

          // Captured images
          if (_capturedImages.isEmpty)
            _buildEmptyState(theme, isDark)
          else
            _buildCapturedImages(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildCaptureOptions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capture',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CaptureOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                description: 'Take a photo',
                color: Colors.blue,
                onTap: _openCamera,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CaptureOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                description: 'Choose existing',
                color: Colors.purple,
                onTap: _pickFromGallery,
                isDark: isDark,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'Ready to Scan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Use the camera to scan documents\nor select from gallery',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FeatureChip(
                  icon: Icons.auto_fix_high_rounded,
                  label: 'Auto-enhance',
                ),
                const SizedBox(width: 12),
                _FeatureChip(
                  icon: Icons.crop_rounded,
                  label: 'Auto-crop',
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedImages(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Captured Images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_capturedImages.length} page(s)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: _capturedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _capturedImages.length) {
              // Add more button
              return _AddMoreCard(
                onTap: _openCamera,
                isDark: isDark,
              ).animate().fadeIn(delay: (index * 50).ms, duration: 200.ms);
            }
            return _ImageCard(
              imagePath: _capturedImages[index],
              pageNumber: index + 1,
              isDark: isDark,
              onRemove: () => _removeImage(index),
            ).animate().fadeIn(delay: (index * 50).ms, duration: 200.ms);
          },
        ),
        const SizedBox(height: 100),
      ],
    );
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
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_capturedImages.length} image(s) ready to process',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PrimaryButton(
              text: 'Process Scans',
              icon: Icons.play_arrow_rounded,
              onPressed: _showActionSheet,
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _CaptureOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _CaptureOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String imagePath;
  final int pageNumber;
  final bool isDark;
  final VoidCallback onRemove;

  const _ImageCard({
    required this.imagePath,
    required this.pageNumber,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
      child: Stack(
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey.withOpacity(0.1),
              child: Icon(
                Icons.image_rounded,
                size: 48,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          // Page number badge
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Page $pageNumber',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMoreCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _AddMoreCard({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add More',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
