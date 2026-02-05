import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  final List<String> _selectedImages = [];
  bool _isProcessing = false;
  String _pdfName = 'converted';
  String _pageSize = 'A4';
  String _orientation = 'portrait';
  double _quality = 80;
  bool _fitToPage = true;

  final List<String> _pageSizes = ['A4', 'A5', 'Letter', 'Legal'];
  final List<String> _orientations = ['portrait', 'landscape'];

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null && !_selectedImages.contains(file.path)) {
              _selectedImages.add(file.path!);
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

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select at least one image', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final conversionRepo = ref.read(conversionRepositoryProvider);

      // Convert images to PDF locally using file paths
      final result = await conversionRepo.imagesToPdf(
        filePaths: _selectedImages,
        pageSize: _pageSize,
        title: _pdfName,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (result.success) {
          // Show success dialog with options
          final dialogResult = await ConversionSuccessDialog.show(
            context,
            title: 'Conversion Complete!',
            message: result.message,
          );

          if (!mounted) return;

          switch (dialogResult) {
            case 'view_job':
            case 'history':
              context.go('/files');
              break;
            case 'stay':
              // Clear selection for next conversion
              setState(() {
                _selectedImages.clear();
              });
              break;
          }
        } else {
          _showSnackBar(result.message, isSuccess: false);
        }
      }
    } on Exception catch (e) {
      _showSnackBar('Failed to start conversion: ${_getErrorMessage(e)}',
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

  void _showOptionsSheet() {
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
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
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

                      // Title
                      Text(
                        'PDF Options',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Output name
                      Text(
                        'Output Name',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter PDF name',
                          suffixText: '.pdf',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _pdfName = value.isEmpty ? 'converted' : value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Page size
                      Text(
                        'Page Size',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _pageSizes.map((size) {
                          final isSelected = _pageSize == size;
                          return ChoiceChip(
                            label: Text(size),
                            selected: isSelected,
                            onSelected: (selected) {
                              setSheetState(() {
                                _pageSize = size;
                              });
                              setState(() {});
                            },
                            selectedColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Orientation
                      Text(
                        'Orientation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _orientations.map((orientation) {
                          final isSelected = _orientation == orientation;
                          return ChoiceChip(
                            label: Text(
                              orientation[0].toUpperCase() +
                                  orientation.substring(1),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setSheetState(() {
                                _orientation = orientation;
                              });
                              setState(() {});
                            },
                            selectedColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Quality slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quality',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_quality.toInt()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _quality,
                        min: 10,
                        max: 100,
                        divisions: 9,
                        onChanged: (value) {
                          setSheetState(() {
                            _quality = value;
                          });
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      // Fit to page toggle
                      SwitchListTile(
                        title: const Text('Fit to page'),
                        subtitle:
                            const Text('Resize images to fit page dimensions'),
                        value: _fitToPage,
                        onChanged: (value) {
                          setSheetState(() {
                            _fitToPage = value;
                          });
                          setState(() {});
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 20),

                      // Done button
                      PrimaryButton(
                        text: 'Done',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 16),
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
          'Image to PDF',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              onPressed: _showOptionsSheet,
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Options',
            ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Container(
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
                        'Convert Images to PDF',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select images and arrange them in order',
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
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

          // Selected images count
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''} selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImages.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear all'),
                  ),
                ],
              ),
            ),

          // Images list or empty state
          Expanded(
            child: _selectedImages.isEmpty
                ? _buildEmptyState(theme, isDark)
                : _buildImagesList(theme, isDark),
          ),

          // Bottom action bar
          _buildBottomBar(theme, isDark),
        ],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'No images selected',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to select images\nfrom your device',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Select Images',
              icon: Icons.add_rounded,
              onPressed: _pickImages,
              isExpanded: false,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesList(ThemeData theme, bool isDark) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedImages.length,
      onReorder: _reorderImages,
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
        final imagePath = _selectedImages[index];
        final fileName = imagePath.split('/').last;

        return Container(
          key: ValueKey('image_${index}_$imagePath'),
          child: _ImageListItem(
            imagePath: imagePath,
            fileName: fileName,
            index: index,
            isDark: isDark,
            onRemove: () => _removeImage(index),
          ),
        );
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
        child: Row(
          children: [
            // Add more button
            Expanded(
              child: SecondaryButton(
                text: 'Add Images',
                icon: Icons.add_photo_alternate_rounded,
                onPressed: _pickImages,
              ),
            ),
            const SizedBox(width: 12),
            // Convert button
            Expanded(
              flex: 2,
              child: PrimaryButton(
                text: 'Convert to PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: _selectedImages.isEmpty ? null : _convertToPdf,
                isLoading: _isProcessing,
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _ImageListItem extends StatelessWidget {
  final String imagePath;
  final String fileName;
  final int index;
  final bool isDark;
  final VoidCallback onRemove;

  const _ImageListItem({
    required this.imagePath,
    required this.fileName,
    required this.index,
    required this.isDark,
    required this.onRemove,
  });

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
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.grey.withOpacity(0.2),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // File name
          Expanded(
            child: Text(
              fileName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
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
