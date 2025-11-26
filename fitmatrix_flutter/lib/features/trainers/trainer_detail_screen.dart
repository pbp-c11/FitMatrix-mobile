import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/review.dart';
import '../../data/models/session_slot.dart';
import '../../data/models/trainer.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final trainerDetailProvider = FutureProvider.family<Trainer, int>((ref, id) {
  return ref.read(apiServiceProvider).fetchTrainerDetail(id);
});

final trainerSlotsProvider = FutureProvider.family<List<SessionSlot>, int>((ref, id) {
  return ref.read(apiServiceProvider).fetchTrainerSlots(id);
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
        error: (err, _) => Center(child: Text('Unable to load trainer: $err')),
        data: (data) => _TrainerBody(trainer: data),
      ),
    );
  }
}

class _TrainerBody extends ConsumerWidget {
  const _TrainerBody({required this.trainer});
  final Trainer trainer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(trainerSlotsProvider(trainer.id));
    final auth = ref.watch(authControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trainer.name,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(trainer.specialties,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MatrixColors.muted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text('Rating ${trainer.ratingAvg.toStringAsFixed(1)}')),
                    Chip(label: Text('${trainer.likes} likes')),
                    Chip(label: Text('Rp ${trainer.pricePerSession.toStringAsFixed(0)} / session')),
                  ],
                ),
                const SizedBox(height: 10),
                Text(trainer.bio ?? trainer.specialties),
                const SizedBox(height: 12),
                Row(
                  children: [
                    MatrixButton(
                      label: 'Save trainer',
                      variant: MatrixButtonVariant.ghost,
                      onPressed: () {
                        ref.read(apiServiceProvider).toggleWishlist('trainer', trainer.id);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Trainer saved')));
                      },
                    ),
                    const SizedBox(width: 10),
                    if (trainer.calendlyUrl != null)
                      MatrixButton(
                        label: 'Calendly',
                        onPressed: () {},
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upcoming availability', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                slots.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Failed to load slots: $err'),
                  data: (items) => Column(
                    children: items
                        .map((slot) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                  '${slot.start.toLocal().toString().substring(0, 16)} at ${slot.place?.name ?? ''}'),
                              subtitle: Text('${slot.seatsLeft} seats left'),
                              trailing: MatrixButton(
                                label: 'Book',
                                variant: MatrixButtonVariant.ghost,
                                onPressed: auth.state.isAuthenticated
                                    ? () => _book(context, ref, slot.id)
                                    : () => ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Login to book a session')),
                                        ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent feedback', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _book(BuildContext context, WidgetRef ref, int slotId) async {
    await ref.read(apiServiceProvider).bookSlot(slotId);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Session booked.')));
    }
  }
}
