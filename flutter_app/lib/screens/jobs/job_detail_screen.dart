import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    await ref.read(jobDetailProvider(widget.jobId).notifier).loadJob();
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

  Future<void> _downloadResult() async {
    try {
      _showSnackBar('Downloading...', isSuccess: true);
      // TODO: Implement download
    } catch (e) {
      _showSnackBar('Download failed: $e', isSuccess: false);
    }
  }

  Future<void> _retryJob() async {
    try {
      await ref.read(jobDetailProvider(widget.jobId).notifier).retryJob();
      _showSnackBar('Job restarted!', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to retry: $e', isSuccess: false);
    }
  }

  Future<void> _deleteJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Job'),
          content: const Text(
            'Are you sure you want to delete this job? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(jobsListProvider.notifier).deleteJob(widget.jobId);
        _showSnackBar('Job deleted', isSuccess: true);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobState = ref.watch(jobDetailProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'retry':
                  _retryJob();
                  break;
                case 'delete':
                  _deleteJob();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'retry',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded),
                    SizedBox(width: 12),
                    Text('Retry'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: AppTheme.errorColor),
                    const SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobDetails,
        child: _buildContent(jobState, theme, isDark),
      ),
    );
  }

  Widget _buildContent(JobDetailState state, ThemeData theme, bool isDark) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, theme);
    }

    final job = state.job;
    if (job == null) {
      return _buildErrorState('Job not found', theme);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          _buildStatusCard(job, theme, isDark),
          const SizedBox(height: 24),

          // Job info
          _buildJobInfo(job, theme, isDark),
          const SizedBox(height: 24),

          // Input files
          _buildInputFiles(job, theme, isDark),
          const SizedBox(height: 24),

          // Output files (if completed)
          if (job.status == 'completed' && job.outputs.isNotEmpty)
            _buildOutputFiles(job, theme, isDark),

          // Error info (if failed)
          if (job.status == 'failed' && job.error != null)
            _buildErrorInfo(job, theme, isDark),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Job job, ThemeData theme, bool isDark) {
    final statusInfo = _getStatusInfo(job.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusInfo.color.withOpacity(0.15),
            statusInfo.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusInfo.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusInfo.icon,
              color: statusInfo.color,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          // Status text
          Text(
            statusInfo.label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusInfo.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusInfo.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),

          // Progress bar (if processing)
          if (job.status == 'processing' && job.progress != null) ...[
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${(job.progress! * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusInfo.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: job.progress,
                  backgroundColor: statusInfo.color.withOpacity(0.2),
                  color: statusInfo.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildJobInfo(Job job, ThemeData theme, bool isDark) {
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
          Text(
            'Job Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.category_rounded,
            label: 'Type',
            value: _formatJobType(job.type),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.fingerprint_rounded,
            label: 'Job ID',
            value: job.id,
            isDark: isDark,
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Created',
            value: DateFormat('MMM dd, yyyy • HH:mm').format(job.createdAt),
            isDark: isDark,
          ),
          if (job.completedAt != null) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Completed',
              value: DateFormat('MMM dd, yyyy • HH:mm').format(job.completedAt!),
              isDark: isDark,
            ),
          ],
          if (job.options != null && job.options!.isNotEmpty) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.settings_rounded,
              label: 'Options',
              value: _formatOptions(job.options!),
              isDark: isDark,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildInputFiles(Job job, ThemeData theme, bool isDark) {
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
                Icons.input_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Input Files',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${job.inputs.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...job.inputs.map((input) => _FileItem(
                fileName: input,
                icon: Icons.insert_drive_file_rounded,
                color: Colors.blue,
                isDark: isDark,
              )),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildOutputFiles(Job job, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.output_rounded,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Output Files',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _downloadResult,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...job.outputs.map((output) => _FileItem(
                fileName: output,
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                isDark: isDark,
                onDownload: _downloadResult,
              )),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildErrorInfo(Job job, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Error Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job.error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Retry Job',
            icon: Icons.refresh_rounded,
            onPressed: _retryJob,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
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
            SecondaryButton(
              text: 'Go Back',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusInfo(
          label: 'Pending',
          description: 'Job is waiting to be processed',
          icon: Icons.schedule_rounded,
          color: Colors.orange,
        );
      case 'processing':
        return _StatusInfo(
          label: 'Processing',
          description: 'Job is currently being processed',
          icon: Icons.hourglass_top_rounded,
          color: Colors.blue,
        );
      case 'completed':
        return _StatusInfo(
          label: 'Completed',
          description: 'Job finished successfully',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        );
      case 'failed':
        return _StatusInfo(
          label: 'Failed',
          description: 'Job encountered an error',
          icon: Icons.error_rounded,
          color: AppTheme.errorColor,
        );
      default:
        return _StatusInfo(
          label: status,
          description: 'Unknown status',
          icon: Icons.help_outline_rounded,
          color: Colors.grey,
        );
    }
  }

  String _formatJobType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  String _formatOptions(Map<String, dynamic> options) {
    return options.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
}

class _StatusInfo {
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _StatusInfo({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FileItem extends StatelessWidget {
  final String fileName;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onDownload;

  const _FileItem({
    required this.fileName,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName.split('/').last,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDownload != null)
            IconButton(
              onPressed: onDownload,
              icon: Icon(
                Icons.download_rounded,
                color: color,
              ),
              style: IconButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }
}
