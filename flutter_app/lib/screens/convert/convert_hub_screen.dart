import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class ConvertHubScreen extends ConsumerStatefulWidget {
  const ConvertHubScreen({super.key});

  @override
  ConsumerState<ConvertHubScreen> createState() => _ConvertHubScreenState();
}

class _ConvertHubScreenState extends ConsumerState<ConvertHubScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(theme, isDark),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: _buildSearchBar(theme, isDark),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildCategories(theme, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Convert',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
          const SizedBox(height: 4),
          Text(
            'Transform your files with powerful tools',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search tools...',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear_rounded),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
    );
  }

  List<Widget> _buildCategories(ThemeData theme, bool isDark) {
    final categories = [
      _ConversionCategory(
        title: 'Image Tools',
        icon: Icons.image_rounded,
        color: Colors.blue,
        tools: [
          _ConversionTool(
            title: 'Image to PDF',
            description: 'Convert images to PDF document',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.red,
            onTap: () => context.openImageToPdf(),
          ),
          _ConversionTool(
            title: 'Format Conversion',
            description: 'Convert between image formats',
            icon: Icons.swap_horiz_rounded,
            color: Colors.blue,
            onTap: () => context.openImageFormat(),
          ),
          _ConversionTool(
            title: 'Transform Image',
            description: 'Resize, rotate, crop images',
            icon: Icons.transform_rounded,
            color: Colors.purple,
            onTap: () => context.openImageTransform(),
          ),
          _ConversionTool(
            title: 'Image OCR',
            description: 'Extract text from images',
            icon: Icons.text_fields_rounded,
            color: Colors.teal,
            onTap: () => context.openImageOcr(),
          ),
          _ConversionTool(
            title: 'Merge Images',
            description: 'Combine multiple images into one',
            icon: Icons.collections_rounded,
            color: Colors.orange,
            onTap: () => context.openMergeImages(),
          ),
          _ConversionTool(
            title: 'Images to PPTX',
            description: 'Create presentation from images',
            icon: Icons.slideshow_rounded,
            color: Colors.deepOrange,
            onTap: () => context.openImageToPptx(),
          ),
          _ConversionTool(
            title: 'Images to DOCX',
            description: 'Create document from images',
            icon: Icons.article_rounded,
            color: Colors.indigo,
            onTap: () => context.openImageToDocx(),
          ),
        ],
      ),
      _ConversionCategory(
        title: 'PDF Tools',
        icon: Icons.picture_as_pdf_rounded,
        color: Colors.red,
        tools: [
          _ConversionTool(
            title: 'Merge PDFs',
            description: 'Combine multiple PDFs into one',
            icon: Icons.merge_rounded,
            color: Colors.red,
            onTap: () => context.openPdfMerge(),
          ),
          _ConversionTool(
            title: 'Split PDF',
            description: 'Split PDF into separate pages',
            icon: Icons.call_split_rounded,
            color: Colors.pink,
            onTap: () => context.openPdfSplit(),
          ),
          _ConversionTool(
            title: 'Reorder Pages',
            description: 'Rearrange PDF pages',
            icon: Icons.reorder_rounded,
            color: Colors.purple,
            onTap: () => context.openPdfReorder(),
          ),
        ],
      ),
      _ConversionCategory(
        title: 'Document Tools',
        icon: Icons.description_rounded,
        color: Colors.orange,
        tools: [
          _ConversionTool(
            title: 'DOCX to PDF',
            description: 'Convert Word documents to PDF',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.red,
            onTap: () => context.openDocumentConvert(
              type: 'DOCX_TO_PDF',
              title: 'DOCX to PDF',
            ),
          ),
          _ConversionTool(
            title: 'PPTX to PDF',
            description: 'Convert presentations to PDF',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.deepOrange,
            onTap: () => context.openDocumentConvert(
              type: 'PPTX_TO_PDF',
              title: 'PPTX to PDF',
            ),
          ),
          _ConversionTool(
            title: 'PDF to PPTX',
            description: 'Convert PDF to presentation',
            icon: Icons.slideshow_rounded,
            color: Colors.orange,
            onTap: () => context.openDocumentConvert(
              type: 'PDF_TO_PPTX',
              title: 'PDF to PPTX',
            ),
          ),
        ],
      ),
      _ConversionCategory(
        title: 'Compression',
        icon: Icons.compress_rounded,
        color: Colors.green,
        tools: [
          _ConversionTool(
            title: 'Compress Image',
            description: 'Reduce image file size',
            icon: Icons.photo_size_select_small_rounded,
            color: Colors.blue,
            onTap: () => context.openCompressImage(),
          ),
          _ConversionTool(
            title: 'Compress Video',
            description: 'Reduce video file size',
            icon: Icons.video_file_rounded,
            color: Colors.purple,
            onTap: () => context.openCompressVideo(),
          ),
          _ConversionTool(
            title: 'Compress PDF',
            description: 'Reduce PDF file size',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.red,
            onTap: () => context.openCompressPdf(),
          ),
        ],
      ),
    ];

    // Filter categories and tools based on search query
    if (_searchQuery.isEmpty) {
      return categories
          .asMap()
          .entries
          .map((entry) => _buildCategorySection(
                entry.value,
                theme,
                isDark,
                entry.key,
              ))
          .toList();
    }

    final filteredCategories = <_ConversionCategory>[];
    for (final category in categories) {
      final filteredTools = category.tools
          .where((tool) =>
              tool.title.toLowerCase().contains(_searchQuery) ||
              tool.description.toLowerCase().contains(_searchQuery))
          .toList();

      if (filteredTools.isNotEmpty) {
        filteredCategories.add(_ConversionCategory(
          title: category.title,
          icon: category.icon,
          color: category.color,
          tools: filteredTools,
        ));
      }
    }

    if (filteredCategories.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tools found',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filteredCategories
        .asMap()
        .entries
        .map((entry) => _buildCategorySection(
              entry.value,
              theme,
              isDark,
              entry.key,
            ))
        .toList();
  }

  Widget _buildCategorySection(
    _ConversionCategory category,
    ThemeData theme,
    bool isDark,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.tools.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (200 + index * 100).ms, duration: 300.ms),

        // Tools grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: category.tools.length,
          itemBuilder: (context, toolIndex) {
            final tool = category.tools[toolIndex];
            return _ToolCard(
              tool: tool,
              isDark: isDark,
            )
                .animate()
                .fadeIn(
                  delay: (250 + index * 100 + toolIndex * 50).ms,
                  duration: 300.ms,
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  duration: 300.ms,
                );
          },
        ),
      ],
    );
  }
}

class _ConversionCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_ConversionTool> tools;

  const _ConversionCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.tools,
  });
}

class _ConversionTool {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConversionTool({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ToolCard extends StatelessWidget {
  final _ConversionTool tool;
  final bool isDark;

  const _ToolCard({
    required this.tool,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tool.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tool.icon,
                  color: tool.color,
                  size: 24,
                ),
              ),
              const Spacer(),
              // Title
              Text(
                tool.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                tool.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
