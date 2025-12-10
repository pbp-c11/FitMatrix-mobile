import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/models/booking.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final bookingsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.read(apiServiceProvider).fetchBookings();
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    return MatrixScaffold(
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Unable to load bookings: $err')),
        data: (items) {
          final upcoming = items.where((b) => b.isUpcoming).toList();
          final past = items.where((b) => !b.isUpcoming).toList();
          return ListView(
  children: [
    const SizedBox(height: 12),

    Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: MatrixColors.ink,
          onPressed: () => context.go('/profile'),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'My bookings',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),

    const SizedBox(height: 12),
    _BookingSection(
      title: 'Upcoming sessions',
      bookings: upcoming,
      onCancel: (id) async {
        await ref.read(apiServiceProvider).cancelBooking(id);
        ref.invalidate(bookingsProvider);
      },
    ),
    const SizedBox(height: 16),
    _BookingSection(title: 'Past sessions', bookings: past),
  ],
);
        },
      ),
    );
  }
}

class _BookingSection extends StatelessWidget {
  const _BookingSection({
    required this.title,
    required this.bookings,
    this.onCancel,
  });
  final String title;
  final List<Booking> bookings;
  final ValueChanged<int>? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (bookings.isEmpty)
          const Text('No sessions yet.', style: TextStyle(color: MatrixColors.muted))
        else
          ...bookings.map((booking) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MatrixCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.slot.trainer?.name ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${booking.slot.place?.name ?? ''} • ${booking.slot.start.toLocal().toString().substring(0, 16)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: MatrixColors.muted),
                            ),
                            Text(
                              booking.status,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: MatrixColors.muted),
                            ),
                          ],
                        ),
                      ),
                      if (onCancel != null && booking.isUpcoming)
                        MatrixButton(
                          label: 'Cancel',
                          variant: MatrixButtonVariant.ghost,
                          onPressed: () => onCancel!(booking.id),
                        ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
