import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/session_slot.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final sessionQueryProvider = StateProvider<String>((ref) => '');

final sessionsProvider = FutureProvider.autoDispose<List<SessionSlot>>((ref) {
  final query = ref.watch(sessionQueryProvider);
  return ref.read(apiServiceProvider).fetchSessions(query: query);
});

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final queryController = TextEditingController(text: ref.watch(sessionQueryProvider));
    final auth = ref.watch(authControllerProvider);

    return MatrixScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Trainer sessions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          MatrixCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(labelText: 'Search sessions'),
                    onSubmitted: (_) =>
                        ref.read(sessionQueryProvider.notifier).state = queryController.text.trim(),
                  ),
                ),
                const SizedBox(width: 10),
                MatrixButton(
                  label: 'Filter',
                  onPressed: () =>
                      ref.read(sessionQueryProvider.notifier).state = queryController.text.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: sessions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Unable to load sessions: $err')),
              data: (items) => ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final slot = items[index];
                  return MatrixCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.trainer?.name ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${slot.place?.name ?? ''} • ${slot.place?.city ?? ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: MatrixColors.muted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${slot.start.toLocal().toString().substring(0, 16)}',
                              ),
                              Text('${slot.seatsLeft} seats left',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: MatrixColors.muted)),
                            ],
                          ),
                        ),
                        MatrixButton(
                          label: slot.seatsLeft > 0 ? 'Book' : 'Full',
                          variant: MatrixButtonVariant.ghost,
                          onPressed: (slot.seatsLeft > 0 && auth.state.isAuthenticated)
                              ? () => _book(context, ref, slot.id)
                              : null,
                        ),
                      ],
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

  Future<void> _book(BuildContext context, WidgetRef ref, int slotId) async {
    await ref.read(apiServiceProvider).bookSlot(slotId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session booked')),
      );
      ref.invalidate(sessionsProvider);
    }
  }
}
