import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/place.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminPlaceQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final adminPlaceStatusProvider = StateProvider.autoDispose<_AdminStatusFilter>(
  (ref) => _AdminStatusFilter.all,
);

final adminPlacesProvider = FutureProvider.autoDispose<List<Place>>((ref) {
  final query = ref.watch(adminPlaceQueryProvider);
  return ref.read(apiServiceProvider).fetchPlaces(query: query);
});

enum _AdminStatusFilter { all, active, inactive }
enum _PlaceAction { view, toggleActive, delete }

class AdminPlacesScreen extends ConsumerWidget {
  const AdminPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final places = ref.watch(adminPlacesProvider);
    final queryController = TextEditingController(text: ref.watch(adminPlaceQueryProvider));
    final statusFilter = ref.watch(adminPlaceStatusProvider);

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
                  'Manage places',
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
                onPressed: () => context.go('/admin/places/new'),
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
                    decoration: const InputDecoration(labelText: 'Search by name / city'),
                    onSubmitted: (_) => ref.read(adminPlaceQueryProvider.notifier).state =
                        queryController.text.trim(),
                  ),
                ),
                const SizedBox(width: 10),
                MatrixButton(
                  label: 'Filter',
                  onPressed: () => ref.read(adminPlaceQueryProvider.notifier).state =
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
                onSelected: (_) => ref.read(adminPlaceStatusProvider.notifier).state =
                    _AdminStatusFilter.all,
              ),
              ChoiceChip(
                label: const Text('Active'),
                selected: statusFilter == _AdminStatusFilter.active,
                onSelected: (_) => ref.read(adminPlaceStatusProvider.notifier).state =
                    _AdminStatusFilter.active,
              ),
              ChoiceChip(
                label: const Text('Inactive'),
                selected: statusFilter == _AdminStatusFilter.inactive,
                onSelected: (_) => ref.read(adminPlaceStatusProvider.notifier).state =
                    _AdminStatusFilter.inactive,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: places.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load places: $err')),
              data: (items) => RefreshIndicator(
                onRefresh: () async => ref.refresh(adminPlacesProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _filterPlaces(items, statusFilter).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final filtered = _filterPlaces(items, statusFilter);
                    final place = filtered[index];
                    return MatrixCard(
                      onTap: () => context.go(
                        '/admin/places/${place.slug}/edit',
                        extra: place,
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
                                        place.name,
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
                                      label: Text(place.isActive ? 'ACTIVE' : 'INACTIVE'),
                                      backgroundColor: place.isActive
                                          ? MatrixColors.mint.withAlpha(128)
                                          : const Color(0xFFFFE4E4),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${place.city} • ${place.facilityType} • ${place.priceDisplay}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: MatrixColors.muted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rating ${place.ratingAvg.toStringAsFixed(1)} • Likes ${place.likes}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: MatrixColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<_PlaceAction>(
                            tooltip: 'Actions',
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _PlaceAction.view,
                                child: Text('View in app'),
                              ),
                              PopupMenuItem(
                                value: _PlaceAction.toggleActive,
                                child: Text(place.isActive ? 'Deactivate' : 'Activate'),
                              ),
                              const PopupMenuItem(
                                value: _PlaceAction.delete,
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (action) async {
                            final api = ref.read(apiServiceProvider);

                            if (action == _PlaceAction.view) {
                              if (!context.mounted) return;
                              context.go('/places/${place.slug}');
                              return;
                            }

                            if (action == _PlaceAction.toggleActive) {
                              try {
                                await api.togglePlaceActive(place.slug);
                                ref.invalidate(adminPlacesProvider);
                              } catch (err) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update place: $err')),
                                );
                              }
                              return;
                            }

                            // DELETE
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete place?'),
                                content: Text('Delete "${place.name}" permanently?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            try {
                              await api.deletePlace(place.slug);
                              ref.invalidate(adminPlacesProvider);

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Place deleted')),
                              );
                            } catch (err) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete place: $err')),
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

List<Place> _filterPlaces(List<Place> items, _AdminStatusFilter filter) {
  if (filter == _AdminStatusFilter.active) {
    return items.where((p) => p.isActive).toList(growable: false);
  }
  if (filter == _AdminStatusFilter.inactive) {
    return items.where((p) => !p.isActive).toList(growable: false);
  }
  return items;
}
