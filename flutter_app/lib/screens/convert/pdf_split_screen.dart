import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class PdfSplitScreen extends ConsumerStatefulWidget {
  const PdfSplitScreen({super.key});

  @override
  ConsumerState<PdfSplitScreen> createState() => _PdfSplitScreenState();
}

class _PdfSplitScreenState extends ConsumerState<PdfSplitScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  int _totalPages = 0;
  bool _isProcessing = false;
  bool _isLoadingPdf = false;

  // Split options
  String _splitMode = 'range'; // 'range', 'single', 'interval'
  int _startPage = 1;
  int _endPage = 1;
  int _intervalPages = 1;
  final List<int> _selectedPages = [];

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
          _isLoadingPdf = true;
        });

        // Simulate loading PDF info (in real app, call API to get page count)
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _totalPages = 10; // This would come from the API
          _endPage = _totalPages;
          _isLoadingPdf = false;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick PDF: $e', isSuccess: false);
    }
  }

  void _togglePageSelection(int page) {
    setState(() {
      if (_selectedPages.contains(page)) {
        _selectedPages.remove(page);
      } else {
        _selectedPages.add(page);
      }
      _selectedPages.sort();
    });
  }

  Future<void> _splitPdf() async {
    if (_selectedFilePath == null) {
      _showSnackBar('Please select a PDF first', isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final conversionRepo = ref.read(conversionRepositoryProvider);

      // Determine pages based on split mode
      List<int>? pages;
      int? splitStartPage;
      int? splitEndPage;

      switch (_splitMode) {
        case 'range':
          splitStartPage = _startPage;
          splitEndPage = _endPage;
          break;
        case 'single':
          pages = List<int>.from(_selectedPages);
          break;
        case 'interval':
          // Generate page list from interval
          pages = [];
          for (int i = 1; i <= _totalPages; i += _intervalPages) {
            pages.add(i);
          }
          break;
      }

      // Split PDF locally
      final result = await conversionRepo.splitPdf(
        filePath: _selectedFilePath,
        pages: pages,
        startPage: splitStartPage,
        endPage: splitEndPage,
      );

      if (!result.success) {
        throw Exception(result.message);
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show success dialog with options
        final dialogResult = await ConversionSuccessDialog.show(
          context,
          title: 'PDF Split Complete!',
          message: 'Your PDF has been split. View the result in Files.',
          jobId: result.fileId,
        );

        if (!mounted) return;

        switch (dialogResult) {
          case 'view_job':
          case 'history':
            context.go(AppRoutes.files);
            break;
          case 'stay':
            setState(() {
              _selectedFilePath = null;
              _selectedFileName = null;
            });
            break;
        }
      }
    } on Exception catch (e) {
      _showSnackBar('Failed to split PDF: ${_getErrorMessage(e)}',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Split PDF',
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
            // Info card
            _buildInfoCard(theme, isDark),
            const SizedBox(height: 24),

            // File selection
            _buildFileSelection(theme, isDark),
            const SizedBox(height: 24),

            // Split options (only show if file is selected)
            if (_selectedFilePath != null && !_isLoadingPdf) ...[
              _buildSplitModeSelector(theme, isDark),
              const SizedBox(height: 24),
              _buildSplitOptions(theme, isDark),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _selectedFilePath != null && !_isLoadingPdf
          ? _buildBottomBar(theme, isDark)
          : null,
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withOpacity(0.1),
            Colors.pink.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.pink.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.call_split_rounded,
              color: Colors.pink,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split PDF Document',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Extract specific pages or split by range',
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
      onTap: _pickPdf,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
          ),
        ),
        child: _isLoadingPdf
            ? Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedFilePath != null
                          ? Icons.picture_as_pdf_rounded
                          : Icons.upload_file_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFileName ?? 'Select a PDF',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFilePath != null
                        ? '$_totalPages pages • Tap to change'
                        : 'Tap to select a PDF file',
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

  Widget _buildSplitModeSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Mode',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SplitModeOption(
                title: 'Range',
                description: 'Extract page range',
                icon: Icons.linear_scale_rounded,
                isSelected: _splitMode == 'range',
                onTap: () => setState(() => _splitMode = 'range'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SplitModeOption(
                title: 'Select',
                description: 'Pick specific pages',
                icon: Icons.touch_app_rounded,
                isSelected: _splitMode == 'single',
                onTap: () => setState(() => _splitMode = 'single'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SplitModeOption(
                title: 'Interval',
                description: 'Split every N pages',
                icon: Icons.splitscreen_rounded,
                isSelected: _splitMode == 'interval',
                onTap: () => setState(() => _splitMode = 'interval'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildSplitOptions(ThemeData theme, bool isDark) {
    switch (_splitMode) {
      case 'range':
        return _buildRangeOptions(theme, isDark);
      case 'single':
        return _buildSingleOptions(theme, isDark);
      case 'interval':
        return _buildIntervalOptions(theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRangeOptions(ThemeData theme, bool isDark) {
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
            'Page Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Start page
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Page',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkDivider
                              : AppTheme.lightDivider,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _startPage > 1
                                ? () => setState(() => _startPage--)
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Expanded(
                            child: Text(
                              '$_startPage',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _startPage < _endPage
                                ? () => setState(() => _startPage++)
                                : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward_rounded,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Page',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkDivider
                              : AppTheme.lightDivider,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _endPage > _startPage
                                ? () => setState(() => _endPage--)
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Expanded(
                            child: Text(
                              '$_endPage',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _endPage < _totalPages
                                ? () => setState(() => _endPage++)
                                : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Will extract ${_endPage - _startPage + 1} pages',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildSingleOptions(ThemeData theme, bool isDark) {
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
                'Select Pages',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedPages.length == _totalPages) {
                      _selectedPages.clear();
                    } else {
                      _selectedPages.clear();
                      _selectedPages.addAll(
                        List.generate(_totalPages, (i) => i + 1),
                      );
                    }
                  });
                },
                child: Text(
                  _selectedPages.length == _totalPages
                      ? 'Deselect All'
                      : 'Select All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Page grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _totalPages,
            itemBuilder: (context, index) {
              final page = index + 1;
              final isSelected = _selectedPages.contains(page);
              return GestureDetector(
                onTap: () => _togglePageSelection(page),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isDark
                            ? AppTheme.darkBackground
                            : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isDark
                              ? AppTheme.darkDivider
                              : AppTheme.lightDivider,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          if (_selectedPages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedPages.length} page(s) selected: ${_selectedPages.join(", ")}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildIntervalOptions(ThemeData theme, bool isDark) {
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
            'Split Interval',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Split the PDF into multiple files, each containing the specified number of pages',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Interval selector
          Text(
            'Pages per file: $_intervalPages',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _intervalPages.toDouble(),
              min: 1,
              max: _totalPages.toDouble(),
              divisions: _totalPages - 1 > 0 ? _totalPages - 1 : 1,
              onChanged: (value) {
                setState(() {
                  _intervalPages = value.toInt();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Result preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_copy_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Will create ${(_totalPages / _intervalPages).ceil()} PDF file(s)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    bool canProceed = false;
    switch (_splitMode) {
      case 'range':
        canProceed = _startPage <= _endPage;
        break;
      case 'single':
        canProceed = _selectedPages.isNotEmpty;
        break;
      case 'interval':
        canProceed = _intervalPages > 0;
        break;
    }

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
          text: 'Split PDF',
          icon: Icons.call_split_rounded,
          isLoading: _isProcessing,
          onPressed: canProceed ? _splitPdf : null,
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms);
  }
}

class _SplitModeOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SplitModeOption({
    required this.title,
    required this.description,
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
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
