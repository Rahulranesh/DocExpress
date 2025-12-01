import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    ref.read(jobsListProvider.notifier).loadJobs(refresh: true);
  }

  List<Job> _filterJobs(List<Job> jobs, String? statusFilter) {
    var filtered = jobs;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((j) =>
              j.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              j.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply status filter
    if (statusFilter != null && statusFilter != 'all') {
      filtered = filtered.where((j) => j.status == statusFilter).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobsState = ref.watch(jobsListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(theme, isDark),

            // Search bar
            _buildSearchBar(theme, isDark),

            // Tab bar
            _buildTabBar(theme, isDark),

            // Job list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadJobs,
                color: theme.colorScheme.primary,
                child: _buildJobContent(jobsState, theme, isDark),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
              const SizedBox(height: 4),
              Consumer(
                builder: (context, ref, child) {
                  final jobsState = ref.watch(jobsListProvider);
                  final count = jobsState.jobs.length;
                  return Text(
                    '$count jobs',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _loadJobs,
                icon: const Icon(Icons.refresh_rounded),
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showClearHistoryDialog(theme, isDark),
                icon: const Icon(Icons.delete_sweep_rounded),
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  foregroundColor: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search jobs...',
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
      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Completed'),
          Tab(text: 'Processing'),
          Tab(text: 'Failed'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildJobContent(JobsListState jobsState, ThemeData theme, bool isDark) {
    if (jobsState.isLoading && jobsState.jobs.isEmpty) {
      return _buildLoadingState(isDark);
    }

    if (jobsState.error != null && jobsState.jobs.isEmpty) {
      return _buildErrorState(jobsState.error!, theme);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildJobList(_filterJobs(jobsState.jobs, null), theme, isDark),
        _buildJobList(
            _filterJobs(jobsState.jobs, 'completed'), theme, isDark),
        _buildJobList(
            _filterJobs(jobsState.jobs, 'processing'), theme, isDark),
        _buildJobList(_filterJobs(jobsState.jobs, 'failed'), theme, isDark),
      ],
    );
  }

  Widget _buildJobList(List<Job> jobs, ThemeData theme, bool isDark) {
    if (jobs.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _JobCard(
          job: job,
          isDark: isDark,
          onTap: () => context.openJobDetail(job.id),
          onRetry: job.status == 'failed'
              ? () => _retryJob(job)
              : null,
          onDownload: job.status == 'completed'
              ? () => _downloadJobResult(job)
              : null,
        ).animate().fadeIn(delay: (index * 50).ms, duration: 200.ms).slideX(
              begin: 0.1,
              duration: 200.ms,
            );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ShimmerBox(
          width: double.infinity,
          height: 100,
          borderRadius: 16,
        );
      },
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load jobs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: _loadJobs,
              isExpanded: false,
            ),
          ],
        ),
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
                Icons.history_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'No jobs found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Your conversion and compression jobs\nwill appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            SecondaryButton(
              text: 'Start Converting',
              icon: Icons.transform_rounded,
              onPressed: () => context.goToConvert(),
              isExpanded: false,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  void _retryJob(Job job) async {
    try {
      await ref.read(jobsListProvider.notifier).retryJob(job.id);
      _showSnackBar('Job retry started', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to retry job: $e', isSuccess: false);
    }
  }

  void _downloadJobResult(Job job) async {
    try {
      // Implement download logic
      _showSnackBar('Download started', isSuccess: true);
    } catch (e) {
      _showSnackBar('Download failed: $e', isSuccess: false);
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

  void _showClearHistoryDialog(ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear History'),
          content: const Text(
            'Are you sure you want to clear all job history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(jobsListProvider.notifier).clearAllJobs();
                _showSnackBar('History cleared', isSuccess: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onDownload;

  const _JobCard({
    required this.job,
    required this.isDark,
    required this.onTap,
    this.onRetry,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
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
            // Header row
            Row(
              children: [
                // Job type icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getJobColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getJobIcon(),
                    color: _getJobColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Job info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getJobTitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
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

                // Status badge
                _StatusBadge(status: job.status.toString()),
              ],
            ),

            // Progress bar for processing jobs
            if (job.status.toString().contains('processing')) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: job.progress ?? 0.0,
                backgroundColor:
                    isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                '${((job.progress ?? 0.0) * 100).toInt()}% complete',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],

            // Action buttons
            if (job.status == 'completed' || job.status == 'failed') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onDownload != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.successColor,
                          side: BorderSide(color: AppTheme.successColor),
                        ),
                      ),
                    ),
                  if (onRetry != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getJobTitle() {
    switch (job.type.toUpperCase()) {
      case 'IMAGE_TO_PDF':
        return 'Image to PDF';
      case 'PDF_MERGE':
        return 'Merge PDFs';
      case 'PDF_SPLIT':
        return 'Split PDF';
      case 'PDF_REORDER':
        return 'Reorder PDF';
      case 'IMAGE_COMPRESS':
        return 'Compress Images';
      case 'VIDEO_COMPRESS':
        return 'Compress Video';
      case 'PDF_COMPRESS':
        return 'Compress PDF';
      case 'IMAGE_FORMAT':
        return 'Convert Image Format';
      case 'IMAGE_TRANSFORM':
        return 'Transform Image';
      case 'DOCX_TO_PDF':
        return 'DOCX to PDF';
      case 'PDF_TO_DOCX':
        return 'PDF to DOCX';
      case 'OCR':
        return 'OCR - Extract Text';
      default:
        return job.type.replaceAll('_', ' ');
    }
  }

  IconData _getJobIcon() {
    switch (job.type.toUpperCase()) {
      case 'IMAGE_TO_PDF':
        return Icons.picture_as_pdf_rounded;
      case 'PDF_MERGE':
        return Icons.merge_rounded;
      case 'PDF_SPLIT':
        return Icons.call_split_rounded;
      case 'PDF_REORDER':
        return Icons.reorder_rounded;
      case 'IMAGE_COMPRESS':
        return Icons.photo_size_select_small_rounded;
      case 'VIDEO_COMPRESS':
        return Icons.video_settings_rounded;
      case 'PDF_COMPRESS':
        return Icons.compress_rounded;
      case 'IMAGE_FORMAT':
        return Icons.swap_horiz_rounded;
      case 'IMAGE_TRANSFORM':
        return Icons.transform_rounded;
      case 'DOCX_TO_PDF':
      case 'PDF_TO_DOCX':
        return Icons.description_rounded;
      case 'OCR':
        return Icons.text_fields_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  Color _getJobColor() {
    switch (job.type.toUpperCase()) {
      case 'IMAGE_TO_PDF':
      case 'PDF_MERGE':
      case 'PDF_SPLIT':
      case 'PDF_REORDER':
      case 'PDF_COMPRESS':
        return Colors.red;
      case 'IMAGE_COMPRESS':
      case 'IMAGE_FORMAT':
      case 'IMAGE_TRANSFORM':
        return Colors.blue;
      case 'VIDEO_COMPRESS':
        return Colors.purple;
      case 'DOCX_TO_PDF':
      case 'PDF_TO_DOCX':
        return Colors.orange;
      case 'OCR':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.successColor;
        icon = Icons.check_circle_rounded;
        label = 'Completed';
        break;
      case 'processing':
        color = Colors.blue;
        icon = Icons.pending_rounded;
        label = 'Processing';
        break;
      case 'failed':
        color = AppTheme.errorColor;
        icon = Icons.error_rounded;
        label = 'Failed';
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule_rounded;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_rounded;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
