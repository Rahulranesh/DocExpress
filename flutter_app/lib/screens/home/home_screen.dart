import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
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
                              AppTheme.primaryDark.withOpacity(0.3),
                              theme.scaffoldBackgroundColor,
                            ]
                          : [
                              AppTheme.primaryLight.withOpacity(0.15),
                              theme.scaffoldBackgroundColor,
                            ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary,
                                      ),
                                    ).animate().fadeIn(duration: 400.ms),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.name ?? 'User',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                                  ],
                                ),
                              ),
                              // Profile avatar
                              GestureDetector(
                                onTap: () => context.openProfile(),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryDark,
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isDark
                                        ? AppTheme.darkSurface
                                        : Colors.white,
                                    child: Text(
                                      _getInitials(user?.name),
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                            ],
                          ),
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
    final actions = [
      _QuickAction(
        icon: Icons.document_scanner_rounded,
        label: 'Scan to PDF',
        color: AppTheme.primaryColor,
        onTap: () => context.openScan(),
      ),
      _QuickAction(
        icon: Icons.note_add_rounded,
        label: 'New Note',
        color: AppTheme.successColor,
        onTap: () => context.openNoteEditor(),
      ),
      _QuickAction(
        icon: Icons.transform_rounded,
        label: 'Convert',
        color: AppTheme.secondaryColor,
        onTap: () => context.goToConvert(),
      ),
      _QuickAction(
        icon: Icons.compress_rounded,
        label: 'Compress',
        color: AppTheme.accentColor,
        onTap: () => context.openCompressHub(),
      ),
      _QuickAction(
        icon: Icons.merge_type_rounded,
        label: 'Merge PDF',
        color: Colors.purple,
        onTap: () => context.openPdfMerge(),
      ),
      _QuickAction(
        icon: Icons.call_split_rounded,
        label: 'Split PDF',
        color: Colors.teal,
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
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_outlined,
                      color: AppTheme.primaryColor,
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
                    color: Colors.purple,
                  ),
                  _StatItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDFs',
                    count: stats.byType['pdf']?.count ?? 0,
                    color: Colors.red,
                  ),
                  _StatItem(
                    icon: Icons.videocam_outlined,
                    label: 'Videos',
                    count: stats.byType['video']?.count ?? 0,
                    color: Colors.blue,
                  ),
                  _StatItem(
                    icon: Icons.description_outlined,
                    label: 'Docs',
                    count: stats.byType['document']?.count ?? 0,
                    color: Colors.orange,
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
              color: _getTypeColor(job.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(job.type),
              color: _getTypeColor(job.type),
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

  Color _getTypeColor(String type) {
    if (type.contains('IMAGE')) return Colors.purple;
    if (type.contains('PDF')) return Colors.red;
    if (type.contains('VIDEO')) return Colors.blue;
    if (type.contains('COMPRESS')) return Colors.orange;
    return AppTheme.primaryColor;
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
