import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load on next frame to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedOnce) {
        _loadNotes();
        _hasLoadedOnce = true;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadNotes() {
    ref.read(notesListProvider.notifier).loadNotes(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notesListProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(notesListProvider.notifier).search(query);
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Note',
      message: 'Are you sure you want to delete "${note.title}"?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      final success =
          await ref.read(notesListProvider.notifier).deleteNote(note.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notesState = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color:
                        isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                  ),
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: _onSearch,
              )
            : const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _onSearch('');
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'all') {
                ref.read(notesListProvider.notifier).filterByTag(null);
              } else if (value == 'pinned') {
                // Filter pinned notes
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Notes'),
              ),
              const PopupMenuItem(
                value: 'pinned',
                child: Text('Pinned Only'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(notesListProvider.notifier).loadNotes(refresh: true);
        },
        child: _buildBody(notesState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.openNoteEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
    );
  }

  Widget _buildBody(NotesListState state) {
    if (state.isLoading && state.notes.isEmpty) {
      return _buildLoadingState();
    }

    if (state.error != null && state.notes.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: _loadNotes,
      );
    }

    if (state.notes.isEmpty) {
      return EmptyState(
        icon: Icons.note_outlined,
        title: 'No notes yet',
        subtitle: 'Tap the button below to create your first note',
        action: PrimaryButton(
          text: 'Create Note',
          icon: Icons.add,
          isExpanded: false,
          onPressed: () => context.openNoteEditor(),
        ),
      );
    }

    return _buildNotesList(state);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerLoading(
            height: 100,
            borderRadius: AppTheme.radiusMd,
          ),
        );
      },
    );
  }

  Widget _buildNotesList(NotesListState state) {
    // Separate pinned and unpinned notes
    final pinnedNotes = state.notes.where((n) => n.pinned).toList();
    final unpinnedNotes = state.notes.where((n) => !n.pinned).toList();

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Pinned section
        if (pinnedNotes.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Icon(Icons.push_pin,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Pinned',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = pinnedNotes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NoteCard(
                      note: note,
                      onTap: () => context.openNoteEditor(noteId: note.id),
                      onDelete: () => _deleteNote(note),
                      onTogglePin: () {
                        ref.read(notesListProvider.notifier).togglePin(note.id);
                      },
                    )
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideX(begin: 0.1),
                  );
                },
                childCount: pinnedNotes.length,
              ),
            ),
          ),
        ],

        // Unpinned section
        if (unpinnedNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Other Notes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              pinnedNotes.isEmpty ? 16 : 0,
              16,
              16,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = unpinnedNotes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NoteCard(
                      note: note,
                      onTap: () => context.openNoteEditor(noteId: note.id),
                      onDelete: () => _deleteNote(note),
                      onTogglePin: () {
                        ref.read(notesListProvider.notifier).togglePin(note.id);
                      },
                    )
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideX(begin: 0.1),
                  );
                },
                childCount: unpinnedNotes.length,
              ),
            ),
          ),
        ],

        // Loading more indicator
        if (state.isLoadingMore)
          const SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;

  const _NoteCard({
    required this.note,
    this.onTap,
    this.onDelete,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onTogglePin?.call(),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            icon: note.pinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: note.pinned ? 'Unpin' : 'Pin',
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ],
      ),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (note.pinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.push_pin,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                Expanded(
                  child: Text(
                    note.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color:
                      isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                ),
              ],
            ),

            // Content preview
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Tags and date
            const SizedBox(height: 12),
            Row(
              children: [
                // Tags
                if (note.tags.isNotEmpty) ...[
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: note.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ] else
                  const Spacer(),

                // Date
                Text(
                  _formatDate(note.updatedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
