import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/models/trainer.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final trainerQueryProvider = StateProvider<String>((ref) => '');

final trainersProvider = FutureProvider.autoDispose<List<Trainer>>((ref) {
  final query = ref.watch(trainerQueryProvider);
  return ref.read(apiServiceProvider).fetchTrainers(query: query);
});

class TrainerListScreen extends ConsumerWidget {
  const TrainerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainers = ref.watch(trainersProvider);
    final queryController = TextEditingController(text: ref.watch(trainerQueryProvider));

    return MatrixScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Find a trainer aligned with your focus.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          MatrixCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(labelText: 'Search trainer'),
                    onSubmitted: (_) =>
                        ref.read(trainerQueryProvider.notifier).state = queryController.text.trim(),
                  ),
                ),
                const SizedBox(width: 10),
                MatrixButton(
                  label: 'Filter',
                  onPressed: () =>
                      ref.read(trainerQueryProvider.notifier).state = queryController.text.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: trainers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Unable to load trainers: $err')),
              data: (items) => ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                final trainer = items[index];
                final nextFmt = DateFormat("MMM d, HH:mm"); // Dec 21, 10:00

                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 170), 
                  child: MatrixCard(
                    onTap: () => context.go('/trainers/${trainer.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trainer.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    trainer.specialties,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: MatrixColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text('Rp ${trainer.pricePerSession.toStringAsFixed(0)}'),
                              backgroundColor: MatrixColors.mint.withAlpha(102),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (trainer.place != null)
                              Chip(
                                label: Text(trainer.place!.name),
                                backgroundColor: MatrixColors.mint.withAlpha(80),
                              ),
                            if (trainer.nextAvailable != null)
                              Chip(
                                label: Text(
                                  'Next ${nextFmt.format(trainer.nextAvailable!.toLocal())}',
                                ),
                              ),
                            if (trainer.endDate != null)
                              Chip(
                                label: Text(
                                  'Until ${DateFormat("MMM d, yyyy").format(trainer.endDate!.toLocal())}',
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Align(alignment: Alignment.centerRight,
                        child: MatrixButton(
                            label: 'Details',
                            variant: MatrixButtonVariant.ghost,
                            onPressed: () => context.go('/trainers/${trainer.id}'))
                        ),
                      ],
                    ),
                  ),
                );
              },

              ),
            ),
          ),
        ],
      ),
    );
  }
}
