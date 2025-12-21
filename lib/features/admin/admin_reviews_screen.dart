import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/trainer_review.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminTrainerReviewsProvider = FutureProvider.autoDispose<List<TrainerReview>>((ref) {
  return ref.read(apiServiceProvider).fetchTrainerReviews();
});

final adminReviewQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final adminReviewVisibilityProvider = StateProvider.autoDispose<_ReviewVisibilityFilter>(
  (ref) => _ReviewVisibilityFilter.all,
);

enum _ReviewVisibilityFilter { all, visible, hidden }

class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final query = ref.watch(adminReviewQueryProvider);
    final visibility = ref.watch(adminReviewVisibilityProvider);
    final queryController = TextEditingController(text: query);

    final reviews = ref.watch(adminTrainerReviewsProvider);
    return MatrixScaffold(
      body: reviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load reviews: $err')),
        data: (items) {
          final filtered = _filterReviews(items, query: query, visibility: visibility);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminTrainerReviewsProvider.future),
            child: ListView(
              padding: const EdgeInsets.only(top: 14, bottom: 20),
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      color: MatrixColors.ink,
                      onPressed: () => context.go('/admin'),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Trainer reviews',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MatrixCard(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      labelText: 'Search by trainer / user / comment',
                    ),
                    onSubmitted: (_) => ref.read(adminReviewQueryProvider.notifier).state =
                        queryController.text.trim(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: visibility == _ReviewVisibilityFilter.all,
                      onSelected: (_) => ref.read(adminReviewVisibilityProvider.notifier).state =
                          _ReviewVisibilityFilter.all,
                    ),
                    ChoiceChip(
                      label: const Text('Visible'),
                      selected: visibility == _ReviewVisibilityFilter.visible,
                      onSelected: (_) => ref.read(adminReviewVisibilityProvider.notifier).state =
                          _ReviewVisibilityFilter.visible,
                    ),
                    ChoiceChip(
                      label: const Text('Hidden'),
                      selected: visibility == _ReviewVisibilityFilter.hidden,
                      onSelected: (_) => ref.read(adminReviewVisibilityProvider.notifier).state =
                          _ReviewVisibilityFilter.hidden,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${filtered.length} review${filtered.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                    ),
                    const Spacer(),
                    if (query.isNotEmpty || visibility != _ReviewVisibilityFilter.all)
                      TextButton(
                        onPressed: () {
                          ref.read(adminReviewQueryProvider.notifier).state = '';
                          ref.read(adminReviewVisibilityProvider.notifier).state =
                              _ReviewVisibilityFilter.all;
                        },
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (filtered.isEmpty)
                  const MatrixCard(child: Text('No reviews found.'))
                else
                  ...filtered.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(review: review),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final TrainerReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    return MatrixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.trainer?.name ?? 'Trainer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.user != null
                          ? '${review.user!.displayName} (@${review.user!.username})'
                          : 'Member',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('${review.rating}/5'),
                backgroundColor: MatrixColors.mint.withAlpha(128),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(review.isVisible ? 'VISIBLE' : 'HIDDEN'),
                backgroundColor: review.isVisible
                    ? MatrixColors.mint.withAlpha(89)
                    : const Color(0xFFFFE4E4),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment.isNotEmpty ? review.comment : '(No comment)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  review.createdAt.toLocal().toString().substring(0, 16),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await api.toggleTrainerReviewVisible(review.id);
                    ref.invalidate(adminTrainerReviewsProvider);
                  } catch (err) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to toggle review: $err')),
                    );
                  }
                },
                child: Text(review.isVisible ? 'Hide' : 'Show'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<TrainerReview> _filterReviews(
  List<TrainerReview> items, {
  required String query,
  required _ReviewVisibilityFilter visibility,
}) {
  Iterable<TrainerReview> filtered = items;

  if (visibility == _ReviewVisibilityFilter.visible) {
    filtered = filtered.where((r) => r.isVisible);
  } else if (visibility == _ReviewVisibilityFilter.hidden) {
    filtered = filtered.where((r) => !r.isVisible);
  }

  final q = query.trim().toLowerCase();
  if (q.isEmpty) return filtered.toList(growable: false);

  bool contains(String value) => value.toLowerCase().contains(q);

  return filtered.where((review) {
    return contains(review.trainer?.name ?? '') ||
        contains(review.user?.displayName ?? '') ||
        contains(review.user?.username ?? '') ||
        contains(review.comment);
  }).toList(growable: false);
}
