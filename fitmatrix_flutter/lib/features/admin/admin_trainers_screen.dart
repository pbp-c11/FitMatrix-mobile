import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/trainer.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminTrainerQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final adminTrainerStatusProvider = StateProvider.autoDispose<_AdminStatusFilter>(
  (ref) => _AdminStatusFilter.all,
);

final adminTrainersProvider = FutureProvider.autoDispose<List<Trainer>>((ref) {
  final query = ref.watch(adminTrainerQueryProvider);
  return ref.read(apiServiceProvider).fetchTrainers(query: query);
});

enum _AdminStatusFilter { all, active, inactive }
enum _TrainerAction { view, toggleActive }

class AdminTrainersScreen extends ConsumerWidget {
  const AdminTrainersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final trainers = ref.watch(adminTrainersProvider);
    final queryController = TextEditingController(text: ref.watch(adminTrainerQueryProvider));
    final statusFilter = ref.watch(adminTrainerStatusProvider);

    return MatrixScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
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
                  'Manage trainers',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MatrixButton(
                label: 'New',
                icon: Icons.add,
                variant: MatrixButtonVariant.ghost,
                onPressed: () => context.go('/admin/trainers/new'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MatrixCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(labelText: 'Search by name / specialties'),
                    onSubmitted: (_) => ref.read(adminTrainerQueryProvider.notifier).state =
                        queryController.text.trim(),
                  ),
                ),
                const SizedBox(width: 10),
                MatrixButton(
                  label: 'Filter',
                  onPressed: () => ref.read(adminTrainerQueryProvider.notifier).state =
                      queryController.text.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: statusFilter == _AdminStatusFilter.all,
                onSelected: (_) => ref.read(adminTrainerStatusProvider.notifier).state =
                    _AdminStatusFilter.all,
              ),
              ChoiceChip(
                label: const Text('Active'),
                selected: statusFilter == _AdminStatusFilter.active,
                onSelected: (_) => ref.read(adminTrainerStatusProvider.notifier).state =
                    _AdminStatusFilter.active,
              ),
              ChoiceChip(
                label: const Text('Inactive'),
                selected: statusFilter == _AdminStatusFilter.inactive,
                onSelected: (_) => ref.read(adminTrainerStatusProvider.notifier).state =
                    _AdminStatusFilter.inactive,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: trainers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load trainers: $err')),
              data: (items) => RefreshIndicator(
                onRefresh: () async => ref.refresh(adminTrainersProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _filterTrainers(items, statusFilter).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final filtered = _filterTrainers(items, statusFilter);
                    final trainer = filtered[index];
                    return MatrixCard(
                      onTap: () => context.go(
                        '/admin/trainers/${trainer.id}/edit',
                        extra: trainer,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        trainer.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontWeight: FontWeight.w800),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(trainer.isActive ? 'ACTIVE' : 'INACTIVE'),
                                      backgroundColor: trainer.isActive
                                          ? MatrixColors.mint.withAlpha(128)
                                          : const Color(0xFFFFE4E4),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trainer.specialties,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: MatrixColors.muted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rating ${trainer.ratingAvg.toStringAsFixed(1)} • Likes ${trainer.likes}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: MatrixColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<_TrainerAction>(
                            tooltip: 'Actions',
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _TrainerAction.view,
                                child: Text('View in app'),
                              ),
                              PopupMenuItem(
                                value: _TrainerAction.toggleActive,
                                child: Text(trainer.isActive ? 'Deactivate' : 'Activate'),
                              ),
                            ],
                            onSelected: (action) async {
                              final api = ref.read(apiServiceProvider);
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);

                              if (action == _TrainerAction.view) {
                                router.go('/trainers/${trainer.id}');
                                return;
                              }

                              try {
                                await api.toggleTrainerActive(trainer.id);
                                ref.invalidate(adminTrainersProvider);
                              } catch (err) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to update trainer: $err')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Trainer> _filterTrainers(List<Trainer> items, _AdminStatusFilter filter) {
  if (filter == _AdminStatusFilter.active) {
    return items.where((t) => t.isActive).toList(growable: false);
  }
  if (filter == _AdminStatusFilter.inactive) {
    return items.where((t) => !t.isActive).toList(growable: false);
  }
  return items;
}
