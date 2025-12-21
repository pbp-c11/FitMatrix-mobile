import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/booking.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  return ref.read(apiServiceProvider).fetchBookings();
});

final adminBookingQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final adminBookingFilterProvider = StateProvider.autoDispose<_AdminBookingFilter>(
  (ref) => _AdminBookingFilter.all,
);

enum _AdminBookingFilter { all, booked, completed, cancelled }

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final query = ref.watch(adminBookingQueryProvider);
    final filter = ref.watch(adminBookingFilterProvider);
    final queryController = TextEditingController(text: query);

    final bookings = ref.watch(adminBookingsProvider);
    return MatrixScaffold(
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Unable to load bookings: $err')),
        data: (items) {
          final filtered = _filterBookings(items, filter: filter, query: query);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminBookingsProvider.future),
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
                        'All bookings',
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: queryController,
                          decoration: const InputDecoration(
                            labelText: 'Search by user / trainer / place',
                          ),
                          onSubmitted: (_) => ref.read(adminBookingQueryProvider.notifier).state =
                              queryController.text.trim(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      MatrixButton(
                        label: 'Search',
                        onPressed: () => ref.read(adminBookingQueryProvider.notifier).state =
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
                      selected: filter == _AdminBookingFilter.all,
                      onSelected: (_) => ref.read(adminBookingFilterProvider.notifier).state =
                          _AdminBookingFilter.all,
                    ),
                    ChoiceChip(
                      label: const Text('Booked'),
                      selected: filter == _AdminBookingFilter.booked,
                      onSelected: (_) => ref.read(adminBookingFilterProvider.notifier).state =
                          _AdminBookingFilter.booked,
                    ),
                    ChoiceChip(
                      label: const Text('Completed'),
                      selected: filter == _AdminBookingFilter.completed,
                      onSelected: (_) => ref.read(adminBookingFilterProvider.notifier).state =
                          _AdminBookingFilter.completed,
                    ),
                    ChoiceChip(
                      label: const Text('Cancelled'),
                      selected: filter == _AdminBookingFilter.cancelled,
                      onSelected: (_) => ref.read(adminBookingFilterProvider.notifier).state =
                          _AdminBookingFilter.cancelled,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${filtered.length} booking${filtered.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                    ),
                    const Spacer(),
                    if (query.isNotEmpty || filter != _AdminBookingFilter.all)
                      TextButton(
                        onPressed: () {
                          ref.read(adminBookingQueryProvider.notifier).state = '';
                          ref.read(adminBookingFilterProvider.notifier).state = _AdminBookingFilter.all;
                        },
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (filtered.isEmpty)
                  const MatrixCard(
                    child: Text('No bookings found.'),
                  )
                else
                  ...filtered.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AdminBookingCard(booking: booking),
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

class _AdminBookingCard extends ConsumerWidget {
  const _AdminBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = booking.slot;
    final userLabel = booking.user != null
        ? '${booking.user!.displayName} (@${booking.user!.username})'
        : 'Member';
    final placeLabel = slot.place != null ? slot.place!.name : '';
    final trainerLabel = slot.trainer != null ? slot.trainer!.name : '';
    final when = slot.start.toLocal().toString().substring(0, 16);

    final canCancel = booking.status != 'CANCELLED';

    return MatrixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  userLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$trainerLabel • $placeLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            when,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              MatrixButton(
                label: 'Cancel',
                variant: MatrixButtonVariant.ghost,
                onPressed: canCancel
                    ? () async {
                        final api = ref.read(apiServiceProvider);
                        final messenger = ScaffoldMessenger.of(context);

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Cancel booking?'),
                            content: const Text('This will mark the booking as cancelled.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Keep'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Cancel booking'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        try {
                          await api.cancelBooking(booking.id);
                          ref.invalidate(adminBookingsProvider);
                          messenger.showSnackBar(const SnackBar(content: Text('Booking cancelled')));
                        } catch (err) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to cancel booking: $err')),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color background;
    switch (status) {
      case 'CANCELLED':
        background = const Color(0xFFFFE4E4);
        break;
      case 'COMPLETED':
        background = MatrixColors.mint.withAlpha(89);
        break;
      default:
        background = MatrixColors.mint.withAlpha(128);
    }
    return Chip(label: Text(status), backgroundColor: background);
  }
}

List<Booking> _filterBookings(
  List<Booking> items, {
  required _AdminBookingFilter filter,
  required String query,
}) {
  Iterable<Booking> filtered = items;

  if (filter == _AdminBookingFilter.booked) {
    filtered = filtered.where((b) => b.status == 'BOOKED');
  } else if (filter == _AdminBookingFilter.completed) {
    filtered = filtered.where((b) => b.status == 'COMPLETED');
  } else if (filter == _AdminBookingFilter.cancelled) {
    filtered = filtered.where((b) => b.status == 'CANCELLED');
  }

  final q = query.trim().toLowerCase();
  if (q.isEmpty) return filtered.toList(growable: false);

  bool contains(String value) => value.toLowerCase().contains(q);

  return filtered.where((booking) {
    final user = booking.user;
    final slot = booking.slot;
    return contains(user?.displayName ?? '') ||
        contains(user?.username ?? '') ||
        contains(user?.email ?? '') ||
        contains(slot.trainer?.name ?? '') ||
        contains(slot.place?.name ?? '');
  }).toList(growable: false);
}
