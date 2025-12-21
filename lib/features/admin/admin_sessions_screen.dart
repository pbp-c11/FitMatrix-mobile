import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/session_slot.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminSessionQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final adminSessionStatusProvider = StateProvider.autoDispose<_AdminStatusFilter>(
  (ref) => _AdminStatusFilter.all,
);

final adminSessionsProvider = FutureProvider.autoDispose<List<SessionSlot>>((ref) {
  final query = ref.watch(adminSessionQueryProvider);
  return ref.read(apiServiceProvider).fetchSessions(query: query);
});

enum _AdminStatusFilter { all, active, inactive }
enum _SessionAction { viewTrainer, viewPlace, toggleActive }

class AdminSessionsScreen extends ConsumerWidget {
  const AdminSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final sessions = ref.watch(adminSessionsProvider);
    final queryController = TextEditingController(text: ref.watch(adminSessionQueryProvider));
    final statusFilter = ref.watch(adminSessionStatusProvider);

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
                  'Session slots',
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
                onPressed: () => context.go('/admin/sessions/new'),
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
                    decoration: const InputDecoration(labelText: 'Search sessions'),
                    onSubmitted: (_) => ref.read(adminSessionQueryProvider.notifier).state =
                        queryController.text.trim(),
                  ),
                ),
                const SizedBox(width: 10),
                MatrixButton(
                  label: 'Filter',
                  onPressed: () => ref.read(adminSessionQueryProvider.notifier).state =
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
                onSelected: (_) => ref.read(adminSessionStatusProvider.notifier).state =
                    _AdminStatusFilter.all,
              ),
              ChoiceChip(
                label: const Text('Active'),
                selected: statusFilter == _AdminStatusFilter.active,
                onSelected: (_) => ref.read(adminSessionStatusProvider.notifier).state =
                    _AdminStatusFilter.active,
              ),
              ChoiceChip(
                label: const Text('Inactive'),
                selected: statusFilter == _AdminStatusFilter.inactive,
                onSelected: (_) => ref.read(adminSessionStatusProvider.notifier).state =
                    _AdminStatusFilter.inactive,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: sessions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load sessions: $err')),
              data: (items) => RefreshIndicator(
                onRefresh: () async => ref.refresh(adminSessionsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _filterSlots(items, statusFilter).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final filtered = _filterSlots(items, statusFilter);
                    final slot = filtered[index];
                    final start = slot.start.toLocal().toString().substring(0, 16);
                    final end = slot.end.toLocal().toString().substring(0, 16);
                    return MatrixCard(
                      onTap: () => context.go(
                        '/admin/sessions/${slot.id}/edit',
                        extra: slot,
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
                                        '${slot.trainer?.name ?? 'Trainer'} • ${slot.place?.name ?? 'Place'}',
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
                                      label: Text(slot.isActive ? 'ACTIVE' : 'INACTIVE'),
                                      backgroundColor: slot.isActive
                                          ? MatrixColors.mint.withAlpha(128)
                                          : const Color(0xFFFFE4E4),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$start - $end',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: MatrixColors.muted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Capacity ${slot.capacity} • Seats left ${slot.seatsLeft}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: MatrixColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<_SessionAction>(
                            tooltip: 'Actions',
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _SessionAction.viewTrainer,
                                child: Text('View trainer'),
                              ),
                              const PopupMenuItem(
                                value: _SessionAction.viewPlace,
                                child: Text('View place'),
                              ),
                              PopupMenuItem(
                                value: _SessionAction.toggleActive,
                                child: Text(slot.isActive ? 'Deactivate' : 'Activate'),
                              ),
                            ],
                            onSelected: (action) async {
                              final api = ref.read(apiServiceProvider);
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);

                              if (action == _SessionAction.viewTrainer &&
                                  slot.trainer?.id != null) {
                                router.go('/trainers/${slot.trainer!.id}');
                                return;
                              }
                              if (action == _SessionAction.viewPlace &&
                                  slot.place?.slug != null) {
                                router.go('/places/${slot.place!.slug}');
                                return;
                              }

                              try {
                                await api.updateSessionSlot(
                                  slot.id,
                                  {'is_active': !slot.isActive},
                                );
                                ref.invalidate(adminSessionsProvider);
                              } catch (err) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to update slot: $err')),
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

List<SessionSlot> _filterSlots(List<SessionSlot> items, _AdminStatusFilter filter) {
  if (filter == _AdminStatusFilter.active) {
    return items.where((s) => s.isActive).toList(growable: false);
  }
  if (filter == _AdminStatusFilter.inactive) {
    return items.where((s) => !s.isActive).toList(growable: false);
  }
  return items;
}
