import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: ref.read(sessionQueryProvider));
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final auth = ref.watch(authControllerProvider);

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1200
        ? 3
        : width >= 900
            ? 3
            : width >= 650
                ? 2
                : 1;

    final dateFmt = DateFormat('MMM d, yyyy • HH:mm');

    return MatrixScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),

          MatrixCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trainer sessions',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: MatrixColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sessions',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse live availability across trainers and studios. '
                    'Filter by trainer name or location to plan your training stack.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: MatrixColors.muted),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Search bar row
          MatrixCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: 'Search sessions',
                      hintText: 'Trainer, place, city...',
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 10),
                MatrixButton(
                  label: 'Filter',
                  onPressed: _applyFilter,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: sessions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Unable to load sessions: $err')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No sessions found',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: MatrixColors.muted),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 18),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: crossAxisCount == 1 ? 2.1 : 1.45,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final slot = items[index];
                    return _SessionGridCard(
                      slot: slot,
                      dateText: dateFmt.format(slot.start.toLocal()),
                      canBook: slot.seatsLeft > 0 && auth.state.isAuthenticated,
                      onBook: () => _book(context, slot.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter() {
    ref.read(sessionQueryProvider.notifier).state = _queryController.text.trim();
  }

  Future<void> _book(BuildContext context, int slotId) async {
    await ref.read(apiServiceProvider).bookSlot(slotId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session booked')),
    );
    ref.invalidate(sessionsProvider);
  }
}

class _SessionGridCard extends StatelessWidget {
  const _SessionGridCard({
    required this.slot,
    required this.dateText,
    required this.canBook,
    required this.onBook,
  });

  final SessionSlot slot;
  final String dateText;
  final bool canBook;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final trainerName = slot.trainer?.name ?? '';
    final placeName = slot.place?.name ?? '';
    final city = slot.place?.city ?? '';

    return MatrixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE
          Text(
            dateText,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: MatrixColors.muted),
          ),
          const SizedBox(height: 10),

          Text(
            trainerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),

          Text(
            '$placeName • $city',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: MatrixColors.muted),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${slot.seatsLeft} left',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: MatrixColors.muted),
                ),
              ),

              MatrixButton(
                label: slot.seatsLeft > 0 ? 'Book' : 'Full',
                variant: MatrixButtonVariant.ghost,
                dense: true,
                onPressed: canBook ? onBook : null,
              ),

            ],
          ),
        ],
      ),
    );
  }
}

