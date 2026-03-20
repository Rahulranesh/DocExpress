import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/app_logo.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _lastTap;

  @override
  void initState() {
    super.initState();
    _lastTap = DateTime.now();
    _loadData();
  }

  bool _isDebounced() {
    final now = DateTime.now();
    final isDebounced = now.difference(_lastTap).inMilliseconds < 300;
    if (!isDebounced) {
      _lastTap = now;
    }
    return isDebounced;
  }

  Future<void> _loadData() async {
    // Refresh data when screen loads
    ref.read(jobsListProvider.notifier).loadJobs(refresh: true);
    ref.read(filesListProvider.notifier).loadFiles(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    // Watch palette to trigger rebuild on palette change
    ref.watch(colorPaletteProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 290,
              floating: false,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              theme.colorScheme.primary.withOpacity(0.3),
                              theme.scaffoldBackgroundColor,
                            ]
                          : [
                              theme.colorScheme.primary.withOpacity(0.15),
                              theme.scaffoldBackgroundColor,
                            ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo Banner
                          Row(
                            children: [
                              const AppLogo(size: 40, showText: true)
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideX(begin: -0.1),
                              const Spacer(),
                              // Palette picker
                              GestureDetector(
                                onTap: () => _showPalettePicker(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? AppTheme.darkSurface
                                        : Colors.white,
                                    boxShadow: AppTheme.shadowSm(isDark),
                                  ),
                                  child: Icon(
                                    Icons.palette_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 150.ms, duration: 400.ms),
                              const SizedBox(width: 10),
                              // Profile avatar
                              GestureDetector(
                                onTap: () => context.openProfile(),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary
                                            .withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isDark
                                        ? AppTheme.darkSurface
                                        : Colors.white,
                                    child: Text(
                                      _getInitials(user?.name),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms, duration: 400.ms),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Greeting
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary,
                                      ),
                                    ).animate().fadeIn(
                                        delay: 250.ms, duration: 400.ms),
                                    const SizedBox(height: 2),
                                    Text(
                                      user?.name ?? 'User',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).animate().fadeIn(
                                        delay: 300.ms, duration: 400.ms),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Welcome Banner inside App Bar
                          const WelcomeBanner()
                              .animate()
                              .fadeIn(delay: 350.ms, duration: 450.ms)
                              .slideY(begin: 0.06, end: 0),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Actions
                  _buildSectionHeader(context, 'Quick Actions'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),

                  const SizedBox(height: 28),

                  // Recent Jobs
                  _buildSectionHeader(
                    context,
                    'Recent Activity',
                    actionText: 'See All',
                    onAction: () => context.goToJobs(),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentJobs(context),

                  const SizedBox(height: 28),

                  // Storage Stats
                  _buildSectionHeader(
                    context,
                    'Storage',
                    actionText: 'Manage',
                    onAction: () => context.goToFiles(),
                  ),
                  const SizedBox(height: 12),
                  _buildStorageStats(context),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.openScan(),
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan'),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionText),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = [
      _QuickAction(
        icon: Icons.document_scanner_rounded,
        label: 'Scan to PDF',
        color: colorScheme.primary,
        onTap: () => context.openScan(),
      ),
      _QuickAction(
        icon: Icons.note_add_rounded,
        label: 'New Note',
        color: colorScheme.primary,
        onTap: () => context.openNoteEditor(),
      ),
      _QuickAction(
        icon: Icons.transform_rounded,
        label: 'Convert',
        color: colorScheme.primary,
        onTap: () => context.goToConvert(),
      ),
      _QuickAction(
        icon: Icons.compress_rounded,
        label: 'Compress',
        color: colorScheme.primary,
        onTap: () => context.openCompressHub(),
      ),
      _QuickAction(
        icon: Icons.merge_type_rounded,
        label: 'Merge PDF',
        color: colorScheme.primary,
        onTap: () => context.openPdfMerge(),
      ),
      _QuickAction(
        icon: Icons.call_split_rounded,
        label: 'Split PDF',
        color: colorScheme.primary,
        onTap: () => context.openPdfSplit(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return QuickActionCard(
          icon: action.icon,
          label: action.label,
          color: action.color,
          onTap: action.onTap,
        ).animate(delay: (100 * index).ms).fadeIn().scale(
              begin: const Offset(0.8, 0.8),
              duration: 300.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }

  Widget _buildRecentJobs(BuildContext context) {
    final recentJobsAsync = ref.watch(recentJobsProvider);

    return recentJobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start by scanning or converting a document',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn();
        }

        return Column(
          children: jobs.take(3).map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _JobListItem(
                job: job,
                onTap: () => context.openJobDetail(job.id),
              ),
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ShimmerLoading(
              height: 72,
              borderRadius: AppTheme.radiusMd,
            ),
          ),
        ),
      ),
      error: (error, stack) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to load recent activity',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(recentJobsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageStats(BuildContext context) {
    final fileStatsAsync = ref.watch(fileStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return fileStatsAsync.when(
      data: (stats) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cloud_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.formattedTotalSize,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stats.totalFiles} files',
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.image_outlined,
                    label: 'Images',
                    count: stats.byType['image']?.count ?? 0,
                    color: theme.colorScheme.primary,
                  ),
                  _StatItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDFs',
                    count: stats.byType['pdf']?.count ?? 0,
                    color: theme.colorScheme.primary,
                  ),
                  _StatItem(
                    icon: Icons.videocam_outlined,
                    label: 'Videos',
                    count: stats.byType['video']?.count ?? 0,
                    color: theme.colorScheme.primary,
                  ),
                  _StatItem(
                    icon: Icons.description_outlined,
                    label: 'Docs',
                    count: stats.byType['document']?.count ?? 0,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn();
      },
      loading: () => const ShimmerLoading(
        height: 160,
        borderRadius: AppTheme.radiusMd,
      ),
      error: (error, stack) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to load storage stats',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(fileStatsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPalettePicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose Color Theme',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick a color palette that matches your style',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, _) {
                    final currentPalette = ref.watch(colorPaletteProvider);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: ColorPalette.values.length,
                      itemBuilder: (context, index) {
                        final palette = ColorPalette.values[index];
                        final paletteColors = AppTheme.palettes[palette]!;
                        final isSelected = palette == currentPalette;

                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(colorPaletteProvider.notifier)
                                .setPalette(palette);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? paletteColors.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: paletteColors.primary
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : AppTheme.shadowSm(isDark),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    paletteColors.primary,
                                    paletteColors.secondary,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    paletteColors.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      paletteColors.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _JobListItem extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const _JobListItem({
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getTypeColor(job.type, context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(job.type),
              color: _getTypeColor(job.type, context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.typeLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(job.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status
          _buildStatusChip(job.status),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildStatusChip(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return StatusChip.pending();
      case JobStatus.running:
        return StatusChip.running();
      case JobStatus.completed:
        return StatusChip.completed();
      case JobStatus.failed:
        return StatusChip.failed();
    }
  }

  Color _getTypeColor(String type, BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('IMAGE')) return Icons.image;
    if (type.contains('PDF')) return Icons.picture_as_pdf;
    if (type.contains('VIDEO')) return Icons.videocam;
    if (type.contains('COMPRESS')) return Icons.compress;
    return Icons.transform;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
