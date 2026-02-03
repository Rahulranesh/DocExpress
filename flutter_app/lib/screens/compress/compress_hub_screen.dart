import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class CompressHubScreen extends ConsumerWidget {
  const CompressHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            // Compression options
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats card
                  _buildStatsCard(theme, isDark),
                  const SizedBox(height: 24),

                  // Compression tools
                  Text(
                    'Compression Tools',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 16),

                  // Image compression
                  _CompressionCard(
                    title: 'Compress Images',
                    description:
                        'Reduce image file size while maintaining quality',
                    icon: Icons.photo_size_select_small_rounded,
                    color: Colors.blue,
                    stats: 'Supports JPG, PNG, WebP',
                    onTap: () => context.openCompressImage(),
                    isDark: isDark,
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 300.ms)
                      .slideX(begin: 0.1),
                  const SizedBox(height: 12),

                  // PDF compression
                  _CompressionCard(
                    title: 'Compress PDFs',
                    description: 'Optimize PDF documents for sharing',
                    icon: Icons.picture_as_pdf_rounded,
                    color: Colors.red,
                    stats: 'Reduce up to 80% file size',
                    onTap: () => context.openCompressPdf(),
                    isDark: isDark,
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 300.ms)
                      .slideX(begin: 0.1),

                  const SizedBox(height: 32),

                  // Tips section
                  _buildTipsSection(theme, isDark),

                  const SizedBox(height: 100),
                ]),
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
            'Compress',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
          const SizedBox(height: 4),
          Text(
            'Reduce file sizes without losing quality',
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

  Widget _buildStatsCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.15),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.compress_rounded,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Compression',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-powered compression for best results',
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Files Compressed',
                  value: '124',
                  icon: Icons.folder_zip_rounded,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.green.withOpacity(0.3),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Space Saved',
                  value: '2.4 GB',
                  icon: Icons.storage_rounded,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.green.withOpacity(0.3),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Avg. Reduction',
                  value: '65%',
                  icon: Icons.trending_down_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 300.ms,
        );
  }

  Widget _buildTipsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compression Tips',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _TipCard(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Best for sharing',
          description: 'Use medium quality for email attachments',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _TipCard(
          icon: Icons.high_quality_rounded,
          title: 'Preserve quality',
          description: 'Choose high quality for important documents',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _TipCard(
          icon: Icons.speed_rounded,
          title: 'Quick compression',
          description: 'Low quality is fastest and smallest',
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CompressionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String stats;
  final VoidCallback onTap;
  final bool isDark;

  const _CompressionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.stats,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stats,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
        ],
      ),
    );
  }
}
