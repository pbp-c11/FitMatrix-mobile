import 'package:fitmatrix_flutter/data/models/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/session_slot.dart';
import '../../data/models/trainer.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final trainerDetailProvider = FutureProvider.family<Trainer, int>((ref, id) {
  return ref.read(apiServiceProvider).fetchTrainerDetail(id);
});

final trainerSlotsProvider =
    FutureProvider.family<List<SessionSlot>, int>((ref, id) {
  return ref.read(apiServiceProvider).fetchTrainerSlots(id);
});

final bookingsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.read(apiServiceProvider).fetchBookings();
});

class TrainerDetailScreen extends ConsumerWidget {
  const TrainerDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainer = ref.watch(trainerDetailProvider(id));

    return MatrixScaffold(
      body: trainer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Unable to load trainer: $err')),
        data: (data) => _TrainerBody(trainer: data),
      ),
    );
  }
}

class _TrainerBody extends ConsumerWidget {
  const _TrainerBody({required this.trainer});
  final Trainer trainer;

  static const double _maxWidth = 900; 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(trainerSlotsProvider(trainer.id));
    final auth = ref.watch(authControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              /// TRAINER INFO
              MatrixCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trainer.specialties,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: MatrixColors.muted),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(
                            'Rp ${trainer.pricePerSession.toStringAsFixed(0)} / session',
                          ),
                        ),
                        if (trainer.place != null)
                          Chip(
                            label: Text(trainer.place!.name),
                            backgroundColor:
                                MatrixColors.mint.withAlpha(90),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(trainer.bio ?? trainer.specialties),

                  
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// UPCOMING AVAILABILITY
              MatrixCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming availability',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    slots.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          Text('Failed to load slots: $err'),
                      data: (items) => Column(
                        children: items.map((slot) {
                          final dateText = DateFormat(
                                  'MMM d, yyyy • HH:mm')
                              .format(slot.start.toLocal());

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${slot.place?.name ?? ''} • ${slot.seatsLeft} seats left',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color:
                                                    MatrixColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: MatrixButton(
                                    label: 'Book',
                                    variant: MatrixButtonVariant.ghost,
                                    onPressed: auth.state.isAuthenticated
                                        ? () async {
                                            await _book(context, ref, slot.id);
                                            ref.invalidate(trainerDetailProvider);
                                            ref.invalidate(trainerSlotsProvider);
                                            ref.invalidate(bookingsProvider);
                                          }
                                        : () => ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Login to book a session'),
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _book(
      BuildContext context, WidgetRef ref, int slotId) async {
    await ref.read(apiServiceProvider).bookSlot(slotId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session booked.')),
      );
    }
  }
}
